local VAULT = vim.fn.expand("~") .. "/personal/notes/storage"

-- Snacks-based "vault notes by recency" picker. Independent of
-- obsidian.nvim — pure snacks, available at startup.
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

-- Markdown list auto-continue + checkbox toggle. obsidian.nvim's own
-- mappings are disabled (mappings = {} below) so they don't fight these.
local function t(keys)
	return vim.api.nvim_replace_termcodes(keys, true, true, true)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
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

		-- gf follows wikilinks; obsidian.nvim is loaded by the ft trigger.
		vim.keymap.set("n", "gf", "<cmd>Obsidian follow_link<cr>", { buffer = true, desc = "Obsidian: follow link" })
	end,
})

return {
	{
		"obsidian.nvim",
		ft = { "markdown" },
		keys = {
			{ "<leader>oo", "<cmd>Obsidian open<cr>",         desc = "Obsidian: open in app" },
			{ "<leader>oR", "<cmd>VaultRecent<cr>",           desc = "Vault: all notes by recency" },
			{ "<leader>on", "<cmd>Obsidian new<cr>",          desc = "Obsidian: new note" },
			{ "<leader>od", "<cmd>Obsidian today<cr>",        desc = "Obsidian: today's journal" },
			{ "<leader>oy", "<cmd>Obsidian yesterday<cr>",    desc = "Obsidian: yesterday's journal" },
			{ "<leader>ot", "<cmd>Obsidian tomorrow<cr>",     desc = "Obsidian: tomorrow's journal" },
			{ "<leader>os", "<cmd>Obsidian search<cr>",       desc = "Obsidian: full-text search" },
			{ "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: quick switch" },
			{ "<leader>ob", "<cmd>Obsidian backlinks<cr>",    desc = "Obsidian: show backlinks" },
			{ "<leader>oT", "<cmd>Obsidian tags<cr>",         desc = "Obsidian: list tags" },
			{ "<leader>or", "<cmd>Obsidian rename<cr>",       desc = "Obsidian: rename + update links" },
		},
		after = function()
			require("obsidian").setup({
				workspaces = {
					{ name = "personal", path = "~/personal/notes/storage" },
				},
				ui = { enable = false },
				-- Disable obsidian's auto-mappings so its <CR> handler doesn't
				-- fight the list-continue map above.
				mappings = {},
				new_notes_location = "notes_subdir",
				notes_subdir = "inbox",
				daily_notes = {
					folder = "journal",
					date_format = "%Y-%m-%d",
					default_tags = { "daily" },
				},
				preferred_link_style = "wiki",
				wiki_link_func = "use_alias_only",
				completion = { nvim_cmp = true, min_chars = 2 },
				picker = { name = "snacks.pick" },
				note_frontmatter_func = function(note)
					return {
						type = note.metadata and note.metadata.type or "note",
						status = note.metadata and note.metadata.status or "active",
						tags = note.tags,
						created = os.date("%Y-%m-%d"),
					}
				end,
				follow_url_func = function(url)
					vim.fn.jobstart({ "xdg-open", url })
				end,
			})
		end,
	},
}
