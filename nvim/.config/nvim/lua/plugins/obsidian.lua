local VAULT = vim.fn.expand("~") .. "/personal/notes/storage"

local function open_vault_recent_picker()
	local uv = vim.loop or vim.uv
	local files = vim.fn.systemlist({ "find", VAULT, "-type", "f", "-name", "*.md", "-not", "-path", "*/.obsidian/*", "-not", "-path", "*/templates/*" })
	if #files == 0 then
		vim.notify("Vault is empty", vim.log.levels.WARN)
		return
	end
	local entries = {}
	for _, full in ipairs(files) do
		local st = uv.fs_stat(full)
		local mtime = st and (st.mtime.sec * 1000 + math.floor((st.mtime.nsec or 0) / 1e6)) or 0
		local rel = full:sub(#VAULT + 2)
		table.insert(entries, { file = full, text = rel, mtime = mtime })
	end
	table.sort(entries, function(a, b) return a.mtime > b.mtime end)

	-- Use require() instead of the Snacks global — setup() in snacks.lua is
	-- wrapped in vim.schedule, so the global may not exist when keybinds
	-- fire. The picker submodule is reachable via require independent of
	-- setup state.
	require("snacks").picker.pick({
		title = "Vault notes (recency, " .. #entries .. " files)",
		layout = {
			layout = {
				backdrop = false,
				width = 0.85,
				height = 0.9,
				box = "vertical",
				border = "rounded",
				title = "{title}",
				title_pos = "center",
				{ win = "preview", title = "{preview}", height = 0.7, border = "bottom" },
				{ win = "input", height = 1, border = "bottom" },
				{ win = "list", border = "none" },
			},
		},
		finder = function() return entries end,
		format = function(item)
			local age_s = math.max(0, math.floor((os.time() * 1000 - item.mtime) / 1000))
			local age
			if age_s < 60 then age = age_s .. "s"
			elseif age_s < 3600 then age = math.floor(age_s / 60) .. "m"
			elseif age_s < 86400 then age = math.floor(age_s / 3600) .. "h"
			else age = math.floor(age_s / 86400) .. "d" end
			return {
				{ string.format("%5s  ", age), "SnacksPickerDelim" },
				{ item.text, "SnacksPickerFile" },
			}
		end,
		preview = function(ctx)
			ctx.preview:reset()
			if not ctx.item or not ctx.item.file then return false end
			local ok, lines = pcall(vim.fn.readfile, ctx.item.file)
			if not ok then return false end
			ctx.preview:set_lines(lines)
			ctx.preview:highlight({ ft = "markdown" })
		end,
		confirm = function(picker, item)
			picker:close()
			if item and item.file then vim.cmd("edit " .. vim.fn.fnameescape(item.file)) end
		end,
	})
end

vim.api.nvim_create_user_command("VaultRecent", open_vault_recent_picker, {})

-- Auto-continue markdown lists. Enter on "- [ ] foo" inserts a fresh
-- "- [ ] " on the next line. Enter on an empty "- [ ] " breaks out of the
-- list (replaces the empty marker with a plain newline).
local function t(keys)
	return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		-- Insert mode: continue lists on Enter.
		vim.keymap.set("i", "<CR>", function()
			local line = vim.api.nvim_get_current_line()
			if line:match("^%s*- %[[%sx]%]%s*$") then
				return t("<C-u><CR>")
			end
			local box_indent = line:match("^(%s*)- %[[%sx]%] ")
			if box_indent then
				return t("<CR>") .. box_indent .. "- [ ] "
			end
			if line:match("^%s*- %s*$") then
				return t("<C-u><CR>")
			end
			local bullet_indent = line:match("^(%s*)- ")
			if bullet_indent then
				return t("<CR>") .. bullet_indent .. "- "
			end
			return t("<CR>")
		end, { buffer = true, expr = true, desc = "Continue markdown lists" })

		-- <leader>x toggles a checkbox done/undone on the current line.
		-- (<CR> is owned by treesitter's incremental selection.)
		vim.keymap.set("n", "<leader>x", function()
			local line = vim.api.nvim_get_current_line()
			local prefix, state, rest = line:match("^(.-)%- %[([%sx])%] (.*)$")
			if not state then
				vim.notify("No checkbox on this line", vim.log.levels.INFO)
				return
			end
			local new_state = state == "x" and " " or "x"
			vim.api.nvim_set_current_line(prefix .. "- [" .. new_state .. "] " .. rest)
		end, { buffer = true, desc = "Toggle checkbox done/undone" })
	end,
})

return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	event = {
		"BufReadPre " .. VAULT .. "/**.md",
		"BufNewFile " .. VAULT .. "/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/personal/notes/storage",
			},
		},

		-- Skip obsidian.nvim's wikilink/UI concealing — needs conceallevel
		-- 1/2 and we use Obsidian app for visual rendering anyway.
		ui = { enable = false },

		-- Disable obsidian.nvim's auto-mappings (binds <CR> to a "smart
		-- action" that toggles checkboxes etc — fights our list-continue
		-- mapping). User keybinds in `keys = {...}` below still apply.
		mappings = {},

		-- frontmatter convention — keep aligned with the categorisation
		-- scheme in SYSTEM.md / the obsidian app config.
		new_notes_location = "notes_subdir",
		notes_subdir = "inbox",
		daily_notes = {
			folder = "journal",
			date_format = "%Y-%m-%d",
			default_tags = { "daily" },
		},

		-- wikilinks: prefer markdown-style links so files stay portable
		-- and the vault works fine outside Obsidian-flavoured tools.
		preferred_link_style = "wiki",
		wiki_link_func = "use_alias_only",

		-- completion via nvim-cmp when wikilinking
		completion = {
			nvim_cmp = true,
			min_chars = 2,
		},

		-- open files from Obsidian's "tags" or "links" picker in nvim
		picker = {
			name = "snacks.pick",
		},

		-- generate sensible frontmatter on new notes
		note_frontmatter_func = function(note)
			return {
				type = note.metadata and note.metadata.type or "note",
				status = note.metadata and note.metadata.status or "active",
				tags = note.tags,
				created = os.date("%Y-%m-%d"),
			}
		end,

		-- open `obsidian://` URIs in the real Obsidian app when desired
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url })
		end,
	},
	keys = {
		{ "<leader>oo", "<cmd>ObsidianOpen<cr>",        desc = "Obsidian: open in app" },
		{ "<leader>oR", "<cmd>VaultRecent<cr>",         desc = "Vault: all notes by recency" },
		{ "<leader>on", "<cmd>ObsidianNew<cr>",         desc = "Obsidian: new note" },
		{ "<leader>od", "<cmd>ObsidianToday<cr>",       desc = "Obsidian: today's journal" },
		{ "<leader>oy", "<cmd>ObsidianYesterday<cr>",   desc = "Obsidian: yesterday's journal" },
		{ "<leader>ot", "<cmd>ObsidianTomorrow<cr>",    desc = "Obsidian: tomorrow's journal" },
		{ "<leader>os", "<cmd>ObsidianSearch<cr>",      desc = "Obsidian: full-text search" },
		{ "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
		{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>",   desc = "Obsidian: show backlinks" },
		{ "<leader>oT", "<cmd>ObsidianTags<cr>",        desc = "Obsidian: list tags" },
		{ "<leader>or", "<cmd>ObsidianRename<cr>",      desc = "Obsidian: rename + update links" },
		{ "gf",         "<cmd>ObsidianFollowLink<cr>",  desc = "Obsidian: follow link under cursor", ft = "markdown" },
	},
}
