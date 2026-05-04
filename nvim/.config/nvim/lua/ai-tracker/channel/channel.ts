#!/usr/bin/env bun
//
// ai-tracker channel — pushes user questions about specific code chunks
// from nvim into the running Claude Code session. Real protocol-level
// integration via Claude Code's Channels feature, no keystroke emulation.
//
// Each Claude session spawns its own copy of this script (as an MCP
// subprocess), so the mapping "Claude → channel server → port" is
// unambiguous: process.ppid is the Claude pid that owns this channel.
//
// Setup (one-time):
//   1. Add to ~/.claude.json:
//      {
//        "mcpServers": {
//          "ai-tracker": {
//            "command": "bun",
//            "args": ["/abs/path/to/channel.ts"]
//          }
//        }
//      }
//   2. Start Claude with:
//        claude --dangerously-load-development-channels server:ai-tracker
//      (Pro/Max plans skip the org policy check; the dev flag is needed
//      because this isn't on the Anthropic-maintained allowlist.)

import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { mkdirSync, writeFileSync, unlinkSync, readFileSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'

const CACHE_DIR = join(homedir(), '.cache', 'ai-tracker-pending')
const CHANNELS_DIR = join(CACHE_DIR, 'channels')
const CLAUDE_PID = process.ppid

// --- Niri workspace lookup --------------------------------------------------
// Walk our parent-process chain (Claude → terminal → kitty window known to
// niri) to find the workspace_id Claude is running in. Used so nvim's
// "ask about chunk" picks the channel matching its own niri workspace.

function readPpid(pid: number): number | null {
  try {
    const status = readFileSync(`/proc/${pid}/status`, 'utf-8')
    const m = status.match(/^PPid:\s+(\d+)/m)
    return m ? parseInt(m[1], 10) : null
  } catch {
    return null
  }
}

async function getClaudeWorkspaceId(): Promise<number | null> {
  let proc
  try {
    proc = Bun.spawn(['niri', 'msg', '--json', 'windows'], {
      stdout: 'pipe',
      stderr: 'ignore',
    })
  } catch {
    return null
  }
  const text = await new Response(proc.stdout).text()
  const exitCode = await proc.exited
  if (exitCode !== 0 || !text) return null

  let windows: any[]
  try {
    windows = JSON.parse(text)
  } catch {
    return null
  }
  if (!Array.isArray(windows)) return null

  const pidToWs: Record<number, number> = {}
  for (const w of windows) {
    if (typeof w.pid === 'number' && typeof w.workspace_id === 'number') {
      pidToWs[w.pid] = w.workspace_id
    }
  }

  let cur: number | null = CLAUDE_PID
  let depth = 0
  while (cur && cur !== 1 && depth < 50) {
    if (pidToWs[cur] !== undefined) return pidToWs[cur]
    cur = readPpid(cur)
    depth++
  }
  return null
}

// --- MCP server -------------------------------------------------------------

const mcp = new Server(
  { name: 'ai-tracker', version: '0.1.0' },
  {
    capabilities: { experimental: { 'claude/channel': {} } },
    instructions:
      'Messages from the ai-tracker channel arrive as <channel source="ai-tracker" file="..." lines="...">. ' +
      'They are user questions about a specific code chunk in their editor — read the question, the code, and answer ' +
      'in the conversation as you would any user message. The channel is one-way; no reply tool is exposed.',
  },
)

await mcp.connect(new StdioServerTransport())

// --- HTTP listener for nvim → channel ---------------------------------------
//
// nvim POSTs JSON { question, file?, lines?, content?, filetype? }. We
// format it into a markdown block and push it as a channel notification,
// which Claude receives in its context wrapped in a <channel> tag.

interface AskBody {
  question?: string
  file?: string
  lines?: string
  content?: string
  filetype?: string
}

const server = Bun.serve({
  port: 0, // pick any free port
  hostname: '127.0.0.1',
  async fetch(req) {
    if (req.method !== 'POST') {
      return new Response('only POST is supported', { status: 405 })
    }
    let body: AskBody
    try {
      body = (await req.json()) as AskBody
    } catch {
      return new Response('invalid JSON', { status: 400 })
    }
    if (!body.question || typeof body.question !== 'string') {
      return new Response('missing question', { status: 400 })
    }

    let formatted = body.question
    if (body.content) {
      const ft = body.filetype ?? ''
      formatted += `\n\n\`\`\`${ft}\n${body.content}\n\`\`\``
    }

    // meta keys must be identifiers — letters/digits/underscores only.
    const meta: Record<string, string> = {}
    if (body.file) meta.file = body.file
    if (body.lines) meta.lines = body.lines

    await mcp.notification({
      method: 'notifications/claude/channel',
      params: { content: formatted, meta },
    })
    return new Response('ok')
  },
})

// --- Registry: tell nvim where to find this channel -------------------------

mkdirSync(CHANNELS_DIR, { recursive: true })
const registryPath = join(CHANNELS_DIR, `${CLAUDE_PID}.json`)
const wsId = await getClaudeWorkspaceId()
writeFileSync(
  registryPath,
  JSON.stringify({
    claude_pid: CLAUDE_PID,
    port: server.port,
    niri_workspace_id: wsId,
    started_at: Date.now(),
  }),
)

const cleanup = () => {
  try {
    unlinkSync(registryPath)
  } catch {}
}
process.on('SIGINT', () => {
  cleanup()
  process.exit(0)
})
process.on('SIGTERM', () => {
  cleanup()
  process.exit(0)
})
process.on('beforeExit', cleanup)
process.on('exit', cleanup)
