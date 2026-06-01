-- Picker for files changed vs hunk-nvim/signs.lua's base. <leader>gC and <C-f>.
local function open_changed_files_picker()
	local ok, signs = pcall(require, "hunk-nvim.signs")
	if not ok or not signs.resolve_base then
		vim.notify("hunk-nvim.signs unavailable", vim.log.levels.ERROR)
		return
	end
	local base
	local tok, tracker = pcall(require, "ai-tracker")
	if tok and tracker.resolve_base_cached then
		local repo = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })[1]
		if repo and repo ~= "" then base = tracker.resolve_base_cached(repo) end
	end
	if not base then base = signs.resolve_base() end
	if not base or base == "" then
		vim.notify("Couldn't infer base commit", vim.log.levels.ERROR)
		return
	end
	local files = vim.fn.systemlist("git diff --name-only " .. base)
	-- git diff doesn't show untracked files; query them separately.
	local untracked = vim.fn.systemlist("git ls-files --others --exclude-standard")
	local seen = {}
	for _, f in ipairs(files) do seen[f] = true end
	for _, f in ipairs(untracked) do
		if not seen[f] then table.insert(files, f); seen[f] = true end
	end
	if #files == 0 then
		vim.notify("No changes vs " .. base:sub(1, 8), vim.log.levels.INFO)
		return
	end
	local uv = vim.loop or vim.uv
	local repo_root = vim.fn.systemlist({ "git", "-C", vim.fn.getcwd(), "rev-parse", "--show-toplevel" })[1]
	local mtime_of = {}
	for _, f in ipairs(files) do
		local st = uv.fs_stat((repo_root or ".") .. "/" .. f)
		mtime_of[f] = st and (st.mtime.sec * 1000 + math.floor((st.mtime.nsec or 0) / 1e6)) or 0
	end
	table.sort(files, function(a, b) return mtime_of[a] > mtime_of[b] end)
	Snacks.picker.pick({
		title = "Changed: " .. base:sub(1, 8) .. "..working tree (" .. #files .. " files)",
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
		finder = function()
			return vim.tbl_map(function(f) return { text = f, file = f } end, files)
		end,
		-- Strip the default workspace-package prefix; show plain paths.
		format = function(item)
			return { { item.file or item.text or "", "SnacksPickerFile" } }
		end,
		preview = function(ctx)
			ctx.preview:reset()
			local item = ctx.item
			if not item or not item.file or not repo_root then
				ctx.preview:notify("No file to preview", "warn")
				return false
			end
			local diff = vim.fn.systemlist({
				"git", "-C", repo_root, "diff", base, "--", item.file,
			})
			local ft = "diff"
			if vim.v.shell_error ~= 0 or #diff == 0 then
				-- Untracked: fall back to file contents.
				local ok2, lines = pcall(vim.fn.readfile, repo_root .. "/" .. item.file)
				if ok2 then
					diff = lines
					ft = vim.filetype.match({ filename = item.file }) or ""
				end
			end
			ctx.preview:set_lines(diff or {})
			ctx.preview:highlight({ ft = ft })
		end,
		confirm = function(picker, item)
			picker:close()
			if item and item.file then vim.cmd("edit " .. vim.fn.fnameescape(item.file)) end
		end,
	})
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	config = function()
		local utils = require("utils")
		local root_markers = { "package.json", ".git", "tsconfig.json", "Cargo.toml", "pyproject.toml" }

		local function get_project_context(filepath)
			local project_root = utils.find_root_with_markers(filepath, root_markers)
			if not project_root then return nil, filepath end

			local project_name = vim.fn.fnamemodify(project_root, ":t")
			local relative_path = filepath:sub(#project_root + 2)

			return project_name, relative_path
		end

		require("snacks").setup({
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			indent = { enabled = false },
			input = {
				enabled = true,
				win = {
					relative = "cursor",
					row = 1,
					col = 0,
					border = "rounded",
				},
			},
			words = { enabled = false },
			notifier = { enabled = false },
			quickfile = { enabled = true },
			picker = { enabled = true },
			scope = { enabled = true },
		})

		local default_formatters = require("snacks.picker.format")
		local original_filename = default_formatters.filename

		default_formatters.filename = function(item, picker)
			local ret = {}

			if not item.file then return ret end

			-- Skip custom formatting for AI tracker items - use their pre-formatted text
			if item._ai_tracker then
				return { { item.text, "Normal" } }
			end

			local full_path = Snacks.picker.util.path(item) or item.file
			local project_name, relative_path = get_project_context(full_path)

			if project_name then
				ret[#ret + 1] = { "[", "SnacksPickerDelim", virtual = true }
				ret[#ret + 1] = { project_name, "SnacksPickerLabel", virtual = true }
				ret[#ret + 1] = { "] ", "SnacksPickerDelim", virtual = true }
			end

			local temp_item = vim.deepcopy(item)
			if relative_path then temp_item.file = relative_path end

			local original_result = original_filename(temp_item, picker)
			vim.list_extend(ret, original_result)

			return ret
		end
	end,
	keys = {
		-- {
		-- 	mode = { "n", "t" },
		-- 	"<c-t>",
		-- 	function() Snacks.terminal(nil) end,
		-- 	desc = "Toggle Terminal",
		-- },
		-- term_normal = {
		-- 	"<esc>",
		-- 	function(self)
		-- 		if not self.esc_timer then
		-- 			self.esc_timer = vim.defer_fn(function() self.esc_timer = nil end, 200)
		-- 			return "<esc>"
		-- 		end
		-- 		self.esc_timer = nil
		-- 		return "<C-\\><C-n>"
		-- 	end,
		-- 	mode = "t",
		-- 	expr = true,
		-- 	desc = "Double escape to normal mode",
		-- },
		{ "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
		{ "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
		{ "<leader>nh", function() Snacks.notifier.show_history() end, desc = "Notification History" },
		{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
		{ "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
		{ "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
		{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
		{ "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Find Grep" },
		{ "<leader>fh", function() Snacks.picker.help() end, desc = "Search Help" },
		{ "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Search Diagnostics" },
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find Buffers" },
		{ "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
		{ "<leader>fr", function() Snacks.picker.lsp_references() end, desc = "LSP References" },
		{ "<leader>fj", function() Snacks.picker.jumps() end, desc = "Search Jumplist" },
		{ "<leader>fq", function() Snacks.picker.qflist() end, desc = "Search Quickfix" },
		{ "<leader>fm", function() Snacks.picker.marks() end, desc = "Search Marks" },
		{ "<leader>fw", function() Snacks.picker.lines() end, desc = "Search Current Buffer" },
		{ "<leader>fo", function() Snacks.picker.grep_buffers() end, desc = "Search Open Files" },
		{ "<leader>fs", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
		{ "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
		-- Git pickers pinned to the daphen/* work branch. In Lovable
		-- sandboxes, HEAD jumps between per-session edit/edt-* refs every
		-- time you message the agent — using HEAD-relative pickers shows
		-- only the empty edit branch. Pinning to the work-branch ref
		-- keeps both pickers showing the actual accumulated work
		-- regardless of HEAD.
		{ "<leader>gc", function()
				local work = vim.fn.systemlist(
					"git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/daphen"
				)[1]
				Snacks.picker.git_log({ args = work and { work } or {} })
			end, desc = "Git Commits (daphen branch)",
		},
		{ "<leader>gC", open_changed_files_picker, desc = "Changed files (daphen vs base)" },
		{ "<C-f>", open_changed_files_picker, desc = "Changed files (daphen vs base)", mode = "n" },
		{ "<leader>u", function() Snacks.picker.undo() end, desc = "Undo History" },
		{ "<C-n>", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
		{ "<C-p>", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
	},
}
