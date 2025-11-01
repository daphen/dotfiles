---@class AITrackerUtils
local M = {}

--- Parse ISO 8601 timestamp to Unix timestamp
---@param iso_string string ISO 8601 timestamp
---@return number Unix timestamp
function M.parse_iso_timestamp(iso_string)
	-- Parse format: 2025-01-24T10:30:00.000Z
	local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
	local year, month, day, hour, min, sec = iso_string:match(pattern)

	if not year then return os.time() end

	-- Convert to numbers with fallback values to avoid nil
	return os.time({
		year = tonumber(year) or 2024,
		month = tonumber(month) or 1,
		day = tonumber(day) or 1,
		hour = tonumber(hour) or 0,
		min = tonumber(min) or 0,
		sec = tonumber(sec) or 0,
	})
end

--- Convert timestamp to human-readable "time ago" format
---@param timestamp string ISO 8601 timestamp
---@return string Human-readable time ago string
function M.time_ago(timestamp)
	local then_time = M.parse_iso_timestamp(timestamp)
	-- Get current UTC time
	local now_utc = tostring(os.date("!%Y-%m-%dT%H:%M:%S"))
	local now_time = M.parse_iso_timestamp(now_utc)
	local diff = now_time - then_time

	if diff < 60 then
		return "just now"
	elseif diff < 3600 then
		local mins = math.floor(diff / 60)
		return mins == 1 and "1 min ago" or mins .. " mins ago"
	elseif diff < 86400 then
		local hours = math.floor(diff / 3600)
		return hours == 1 and "1 hour ago" or hours .. " hours ago"
	elseif diff < 604800 then
		local days = math.floor(diff / 86400)
		return days == 1 and "1 day ago" or days .. " days ago"
	else
		local weeks = math.floor(diff / 604800)
		return weeks == 1 and "1 week ago" or weeks .. " weeks ago"
	end
end

--- Read and parse JSONL file (with deduplication)
---@param file_path string Path to JSONL file
---@return table[] Array of parsed JSON objects
function M.read_jsonl(file_path)
	local entries = {}
	local seen = {} -- Track seen entries for deduplication
	local file = io.open(vim.fn.expand(file_path), "r")

	if not file then return entries end

	for line in file:lines() do
		if line and line ~= "" then
			local ok, entry = pcall(vim.json.decode, line)
			if ok and entry then
				-- Create a deduplication key
				local key = string.format(
					"%s|%s|%s|%s",
					entry.file_path or "",
					entry.line_number or 0,
					entry.tool or "",
					-- Round timestamp to nearest second for deduplication
					entry.timestamp and entry.timestamp:sub(1, 19) or ""
				)

				-- Only add if we haven't seen this exact change
				if not seen[key] then
					seen[key] = true
					table.insert(entries, entry)
				end
			end
		end
	end

	file:close()
	return entries
end

--- Write a line to JSONL file (append mode)
---@param file_path string Path to JSONL file
---@param entry table Entry to write as JSON
function M.append_jsonl(file_path, entry)
	-- Ensure directory exists
	local dir = vim.fn.fnamemodify(file_path, ":h")
	vim.fn.mkdir(dir, "p")

	-- Append JSON line
	local json_line = vim.json.encode(entry)
	local file = io.open(vim.fn.expand(file_path), "a")

	if file then
		file:write(json_line .. "\n")
		file:close()
	end
end

--- Truncate string to max length with ellipsis
---@param str string String to truncate
---@param max_len number Maximum length
---@return string Truncated string
function M.truncate(str, max_len)
	if not str then return "" end

	if #str <= max_len then return str end

	return str:sub(1, max_len - 3) .. "..."
end

--- Get relative path from cwd
---@param abs_path string Absolute file path
---@return string Relative path
function M.relative_path(abs_path)
	local cwd = vim.fn.getcwd()
	if abs_path:sub(1, #cwd) == cwd then return abs_path:sub(#cwd + 2) end
	return abs_path
end

--- Format file path for display (with project context)
---@param file_path string Absolute file path
---@return string, string Project name, relative path
function M.format_path(file_path)
	-- Try to find project root
	local ok, main_utils = pcall(require, "utils")
	if ok and main_utils and main_utils.find_root_with_markers then
		local root_markers = { "package.json", ".git", "tsconfig.json", "Cargo.toml", "pyproject.toml" }
		local project_root = main_utils.find_root_with_markers(file_path, root_markers)

		if project_root then
			local project_name = vim.fn.fnamemodify(project_root, ":t")
			local relative = file_path:sub(#project_root + 2)
			return project_name, relative
		end
	end

	-- Fallback to filename
	return "", vim.fn.fnamemodify(file_path, ":t")
end

--- Count lines in a string
---@param str string String to count lines in
---@return number Number of lines
function M.count_lines(str)
	if not str then return 0 end
	local count = 1
	for _ in str:gmatch("\n") do
		count = count + 1
	end
	return count
end

--- Get icon for tool type
---@param tool string Tool name (edit, write)
---@return string Icon
function M.get_tool_icon(tool)
	local icons = {
		edit = "",
		write = "",
	}
	return icons[tool] or ""
end

return M
