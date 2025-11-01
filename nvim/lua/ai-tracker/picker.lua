---@class AITrackerPicker
local M = {}

local utils = require("ai-tracker.utils")

--- Transform change entries to Snacks picker items
---@param changes table[] Array of change entries
---@param filter_file? string Optional file path to filter by
---@return table[] Array of picker items
function M.to_picker_items(changes, filter_file)
	local items = {}

	for _, change in ipairs(changes) do
		-- Filter by current file if requested
		if filter_file and change.file_path ~= filter_file then goto continue end

		-- Skip if no file path or invalid data
		if not change.file_path or not change.timestamp then goto continue end

		-- Ensure line_number is valid
		local line_number = tonumber(change.line_number) or 1

		-- Create readable display text
		local time_ago = utils.time_ago(change.timestamp)
		local project_name, relative_path = utils.format_path(change.file_path)
		local file_name = vim.fn.fnamemodify(change.file_path, ":t")
		local tool_icon = utils.get_tool_icon(change.tool)

		-- Truncate prompt for display
		local prompt_short = utils.truncate(change.prompt or "No prompt", 60)

		-- Build display text
		local text_parts = {}

		-- Time indicator
		table.insert(text_parts, string.format("[%s]", time_ago))



		-- Tool icon
		if tool_icon ~= "" then table.insert(text_parts, tool_icon) end

		-- File location
		if project_name ~= "" then
			table.insert(text_parts, string.format("[%s]", project_name))
			table.insert(text_parts, string.format("%s:%d", relative_path, line_number))
		else
			table.insert(text_parts, string.format("%s:%d", file_name, line_number))
		end



		local text = table.concat(text_parts, " ")

		-- Create picker item
		-- Snacks expects: { text, file, line, col, pos }
		local file_path = vim.fn.expand(change.file_path)
		table.insert(items, {
			text = text,
			file = file_path,
			filename = file_path, -- Some pickers expect this
			line = line_number,
			lnum = line_number, -- Alternative field name
			col = 1,
			pos = { line_number, 1 }, -- Position as array
			-- Store full change data for custom actions
			_change = change,
			_ai_tracker = true, -- Mark as our item
		})

		::continue::
	end

	return items
end

--- Group changes by prompt
---@param changes table[] Array of change entries
---@return table[] Array of grouped items
function M.group_by_prompt(changes)
	local groups = {}
	local prompt_map = {}

	for _, change in ipairs(changes) do
		local prompt = change.prompt or "Unknown prompt"
		if not prompt_map[prompt] then
			prompt_map[prompt] = {
				prompt = prompt,
				timestamp = change.timestamp,
				changes = {},
			}
			table.insert(groups, prompt_map[prompt])
		end
		table.insert(prompt_map[prompt].changes, change)
	end

	return groups
end

--- Show AI changes in Snacks picker (grouped by file for performance)
---@param changes table[] Array of change entries
---@param opts? table Options (title, filter_file, limit, group_by_file)
function M.show(changes, opts)
	opts = opts or {}
	local group_by_file = opts.group_by_file ~= false -- Default to true
	local limit = opts.limit or 100 -- Default limit for performance

	-- Sort by timestamp (newest first)
	table.sort(changes, function(a, b) return (a.timestamp or "") > (b.timestamp or "") end)

	local items = {}

	if group_by_file then
		-- Group changes by file for better performance
		local file_groups = {}
		local file_order = {} -- Track order of first occurrence

		-- Limit to recent changes for performance
		local changes_to_process = {}
		for i = 1, math.min(#changes, limit) do
			table.insert(changes_to_process, changes[i])
		end

		-- Group by file
		for _, change in ipairs(changes_to_process) do
			local file_path = change.file_path
			if file_path and (not opts.filter_file or file_path == opts.filter_file) then
				if not file_groups[file_path] then
					file_groups[file_path] = {
						file_path = file_path,
						changes = {},
						lines = {},
						latest_timestamp = change.timestamp,
						session_ids = {},
						prompts = {},
					}
					table.insert(file_order, file_path)
				end

				local group = file_groups[file_path]
				table.insert(group.changes, change)
				group.lines[change.line_number or 1] = true
				group.session_ids[change.session_id] = true

				-- Track unique prompts
				if change.prompt and change.prompt ~= "" then
					local prompt_short = utils.truncate(change.prompt, 30)
					group.prompts[prompt_short] = true
				end
			end
		end

		-- Sort file_order by latest timestamp (newest first)
		table.sort(file_order, function(a, b) return (file_groups[a].latest_timestamp or "") > (file_groups[b].latest_timestamp or "") end)

		-- Convert groups to picker items
		for _, file_path in ipairs(file_order) do
			local group = file_groups[file_path]
			local time_ago = utils.time_ago(group.latest_timestamp)
			local project_name, relative_path = utils.format_path(file_path)
			local file_name = vim.fn.fnamemodify(file_path, ":t")

			-- Collect line numbers
			local line_nums = {}
			for line, _ in pairs(group.lines) do
				table.insert(line_nums, tonumber(line) or 1)
			end
			table.sort(line_nums)

			-- Format line ranges (e.g., "1-5, 10, 15-20")
			local line_ranges = {}
			local i = 1
			while i <= #line_nums do
				local start = line_nums[i]
				local finish = start

				-- Find consecutive lines
				while i < #line_nums and line_nums[i + 1] == finish + 1 do
					i = i + 1
					finish = line_nums[i]
				end

				if start == finish then
					table.insert(line_ranges, tostring(start))
				else
					table.insert(line_ranges, string.format("%d-%d", start, finish))
				end
				i = i + 1
			end

			-- Build display text
			local text_parts = {}
			table.insert(text_parts, string.format("[%s]", time_ago))
			table.insert(text_parts, string.format("(%d)", #group.changes))

			if project_name ~= "" then
				table.insert(text_parts, string.format("[%s]", project_name))
				table.insert(text_parts, relative_path)
			else
				table.insert(text_parts, file_name)
			end

			table.insert(text_parts, ":")
			table.insert(text_parts, table.concat(line_ranges, ", "))

			local text = table.concat(text_parts, " ")

			-- Use the first line number for navigation
			local first_line = line_nums[1] or 1

			table.insert(items, {
				text = text,
				file = vim.fn.expand(file_path),
				filename = vim.fn.expand(file_path),
				line = first_line,
				lnum = first_line,
				col = 1,
				pos = { first_line, 1 },
				_group = group,
				_ai_tracker = true,
			})
		end

		-- Don't notify - it's annoying
	else
		-- Original behavior - show all individual changes (limited)
		local changes_to_show = {}
		for i = 1, math.min(#changes, limit) do
			table.insert(changes_to_show, changes[i])
		end
		items = M.to_picker_items(changes_to_show, opts.filter_file)

		-- Don't notify - it's annoying
	end

	if #items == 0 then
		vim.notify("No AI changes found", vim.log.levels.INFO)
		return
	end

	-- Show in Snacks picker
	Snacks.picker.pick({
		source = opts.title or "AI Changes (by file)",
		items = items,
		format = "text", -- Use Snacks' default text formatter for proper highlighting
	})
end

--- Show grouped view (by prompt)
---@param changes table[] Array of change entries
function M.show_grouped(changes)
	local groups = M.group_by_prompt(changes)

	-- Sort groups by timestamp (newest first)
	table.sort(groups, function(a, b) return (a.timestamp or "") > (b.timestamp or "") end)

	-- Create items for prompts
	local items = {}
	for _, group in ipairs(groups) do
		local time_ago = utils.time_ago(group.timestamp)
		local file_count = #group.changes
		local prompt_short = utils.truncate(group.prompt, 80)

		table.insert(items, {
			text = string.format("[%s] %s (%d file%s)", time_ago, prompt_short, file_count, file_count == 1 and "" or "s"),
			_group = group,
		})
	end

	if #items == 0 then
		vim.notify("No AI changes found", vim.log.levels.INFO)
		return
	end

	-- Show picker with custom confirm action
	Snacks.picker.pick({
		source = "AI Changes (grouped by prompt)",
		items = items,
		preview = false, -- No preview for group view
		format = "text", -- Use text format instead of file format for groups
		on_confirm = function(item)
			-- When user selects a prompt group, show all changes for that prompt
			if item and item._group then M.show(item._group.changes, {
				title = string.format("Changes for: %s", utils.truncate(item._group.prompt, 50)),
			}) end
		end,
	})
end

--- Show changes grouped by session
---@param changes table[] Array of change entries
function M.show_sessions(changes)
	local sessions = {}
	local session_map = {}

	-- Group by session
	for _, change in ipairs(changes) do
		local session = change.session_id or "unknown"
		if not session_map[session] then
			session_map[session] = {
				session_id = session,
				timestamp = change.timestamp,
				changes = {},
				files = {},
			}
			table.insert(sessions, session_map[session])
		end
		table.insert(session_map[session].changes, change)
		-- Track unique files
		session_map[session].files[change.file_path] = true
	end

	-- Count unique files per session
	for _, session in ipairs(sessions) do
		local file_count = 0
		for _ in pairs(session.files) do
			file_count = file_count + 1
		end
		session.file_count = file_count
	end

	-- Sort by timestamp (newest first)
	table.sort(sessions, function(a, b) return (a.timestamp or "") > (b.timestamp or "") end)

	-- Create items for sessions
	local items = {}
	for _, session in ipairs(sessions) do
		local time_ago = utils.time_ago(session.timestamp)
		local change_count = #session.changes
		local file_count = session.file_count

		-- Extract session identifier
		local session_display = tostring(session.session_id)
		if string.match(session.session_id, "^opencode%-") then
			-- For opencode sessions, show timestamp and short random ID
			local parts = vim.split(session.session_id, "-")
			if #parts >= 3 then
				local timestamp = tonumber(parts[2])
				if timestamp then
					local date = os.date("%m/%d %H:%M", timestamp / 1000)
					session_display = string.format("OpenCode %s [%s]", date, parts[3]:sub(1, 7))
				end
			end
		else
			-- For other sessions, just show first 15 chars
			session_display = session_display:sub(1, 15)
		end

		table.insert(items, {
			text = string.format("[%s] %s - %d changes in %d file%s", time_ago, session_display, change_count, file_count, file_count == 1 and "" or "s"),
			_session = session,
		})
	end

	if #items == 0 then
		vim.notify("No sessions found", vim.log.levels.INFO)
		return
	end

	-- Show picker
	Snacks.picker.pick({
		source = "AI Changes (by session)",
		items = items,
		preview = false,
		format = "text",
		on_confirm = function(item)
			if item and item._session then M.show(item._session.changes, {
				title = string.format("Session %s", tostring(item._session.session_id):sub(1, 8)),
			}) end
		end,
	})
end

--- Show which files were changed by each prompt
---@param changes table[] Array of change entries
function M.show_prompt_files(changes)
	local prompts = {}
	local prompt_map = {}

	-- Group by prompt and track files
	for _, change in ipairs(changes) do
		local prompt = change.prompt or "Unknown prompt"
		if not prompt_map[prompt] then
			prompt_map[prompt] = {
				prompt = prompt,
				timestamp = change.timestamp,
				files = {},
				changes = {},
			}
			table.insert(prompts, prompt_map[prompt])
		end

		-- Track unique files for this prompt
		if not prompt_map[prompt].files[change.file_path] then prompt_map[prompt].files[change.file_path] = {
			path = change.file_path,
			changes = {},
		} end
		table.insert(prompt_map[prompt].files[change.file_path].changes, change)
		table.insert(prompt_map[prompt].changes, change)
	end

	-- Sort by timestamp (newest first)
	table.sort(prompts, function(a, b) return (a.timestamp or "") > (b.timestamp or "") end)

	-- Create hierarchical items
	local items = {}
	for _, prompt_group in ipairs(prompts) do
		local time_ago = utils.time_ago(prompt_group.timestamp)
		local file_count = 0
		local file_list = {}

		for path, file_info in pairs(prompt_group.files) do
			file_count = file_count + 1
			local _, relative_path = utils.format_path(path)
			table.insert(file_list, relative_path or vim.fn.fnamemodify(path, ":t"))
		end

		-- Sort file list
		table.sort(file_list)

		-- Main prompt item
		table.insert(items, {
			text = string.format("[%s] %s (%d file%s)", time_ago, utils.truncate(prompt_group.prompt, 60), file_count, file_count == 1 and "" or "s"),
			_prompt_group = prompt_group,
			_expandable = true,
		})

		-- Add file items (indented)
		for _, file in ipairs(file_list) do
			table.insert(items, {
				text = string.format("    → %s", file),
				_is_file = true,
				_parent_prompt = prompt_group.prompt,
			})
		end
	end

	if #items == 0 then
		vim.notify("No prompts found", vim.log.levels.INFO)
		return
	end

	-- Show picker
	Snacks.picker.pick({
		source = "Prompts & Files Changed",
		items = items,
		preview = false,
		format = "text",
		on_confirm = function(item)
			if item and item._prompt_group then M.show(item._prompt_group.changes, {
				title = string.format("Changes for: %s", utils.truncate(item._prompt_group.prompt, 50)),
			}) end
		end,
	})
end

--- Show diff for a change in a floating window
---@param change table Change entry
function M.show_diff(change)
	local lines = {}

	-- Header
	table.insert(lines, "# AI Change Details")
	table.insert(lines, "")
	table.insert(lines, "**File:** " .. change.file_path)
	table.insert(lines, "**Line:** " .. change.line_number)
	table.insert(lines, "**Time:** " .. utils.time_ago(change.timestamp))
	table.insert(lines, "**Tool:** " .. change.tool)
	table.insert(lines, "")
	table.insert(lines, "**Prompt:**")
	table.insert(lines, change.prompt or "No prompt")
	table.insert(lines, "")

	-- Show diff based on tool type
	if change.tool == "edit" and change.old_string and change.new_string then
		table.insert(lines, "**Changes:**")
		table.insert(lines, "```diff")
		table.insert(lines, "- " .. change.old_string:gsub("\n", "\n- "))
		table.insert(lines, "+ " .. change.new_string:gsub("\n", "\n+ "))
		table.insert(lines, "```")
	elseif change.tool == "write" and change.git_diff then
		table.insert(lines, "**Git Diff:**")
		table.insert(lines, "```diff")
		table.insert(lines, change.git_diff)
		table.insert(lines, "```")
	elseif change.is_new_file then
		table.insert(lines, "*New file created*")
	end

	-- Show in floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "markdown"
	vim.bo[buf].buftype = "nofile"

	local width = math.min(100, vim.o.columns - 10)
	local height = math.min(30, vim.o.lines - 10)

	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		style = "minimal",
		border = "rounded",
		title = " AI Change Details ",
		title_pos = "center",
	})

	-- Keymaps to close
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
	vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end

return M
