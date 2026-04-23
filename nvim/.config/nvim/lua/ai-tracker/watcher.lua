---@class AITrackerWatcher
local M = {}

local uv = vim.uv or vim.loop

local state = {
	fs_event = nil,
	poll_timer = nil,
	debounce_timer = nil,
	byte_offset = 0,
	path = nil,
	debounce_ms = 150,
	poll_fallback_ms = 5000,
	on_batch = nil,
	running = false,
}

--- Read newly-appended JSONL entries starting at state.byte_offset.
--- Handles partial trailing lines (doesn't parse until a newline arrives).
---@return table[] Parsed entries
local function read_new_entries()
	local path = vim.fn.expand(state.path)
	local stat = uv.fs_stat(path)
	if not stat then
		state.byte_offset = 0
		return {}
	end

	-- Truncation: log was cleared.
	if stat.size < state.byte_offset then
		state.byte_offset = 0
	end

	if stat.size == state.byte_offset then return {} end

	local fd = uv.fs_open(path, "r", 438)
	if not fd then return {} end

	local to_read = stat.size - state.byte_offset
	local chunk = uv.fs_read(fd, to_read, state.byte_offset)
	uv.fs_close(fd)

	if not chunk or chunk == "" then return {} end

	-- Only consume up to the last newline; leave partial trailing line for next flush.
	local last_nl_pos
	local search_start = 1
	while true do
		local p = chunk:find("\n", search_start, true)
		if not p then break end
		last_nl_pos = p
		search_start = p + 1
	end

	if not last_nl_pos then return {} end

	local complete = chunk:sub(1, last_nl_pos)
	state.byte_offset = state.byte_offset + last_nl_pos

	local entries = {}
	for line in complete:gmatch("[^\n]+") do
		if line ~= "" then
			local ok, entry = pcall(vim.json.decode, line)
			if ok and entry then table.insert(entries, entry) end
		end
	end
	return entries
end

local function flush()
	local entries = read_new_entries()
	if #entries > 0 and state.on_batch then
		local ok, err = pcall(state.on_batch, entries)
		if not ok then vim.notify("AI Tracker watcher on_batch error: " .. tostring(err), vim.log.levels.ERROR) end
	end
end

local function schedule_flush()
	if not state.debounce_timer then state.debounce_timer = uv.new_timer() end
	state.debounce_timer:stop()
	state.debounce_timer:start(state.debounce_ms, 0, vim.schedule_wrap(flush))
end

local function bind_fs_event()
	if state.fs_event then
		pcall(function()
			state.fs_event:stop()
			state.fs_event:close()
		end)
		state.fs_event = nil
	end

	local path = vim.fn.expand(state.path)
	if not uv.fs_stat(path) then
		-- File doesn't exist yet; poll_timer will retry.
		return
	end

	state.fs_event = uv.new_fs_event()
	local ok = pcall(function()
		state.fs_event:start(path, {}, function(err, _fname, _events)
			if err then return end
			schedule_flush()
		end)
	end)
	if not ok and state.fs_event then
		pcall(function() state.fs_event:close() end)
		state.fs_event = nil
	end
end

--- Start watching the log file for new entries.
---@param opts { path: string, debounce_ms?: number, poll_fallback_ms?: number, on_batch: fun(entries: table[]) }
function M.start(opts)
	if state.running then M.stop() end

	state.path = opts.path
	state.debounce_ms = opts.debounce_ms or 150
	state.poll_fallback_ms = opts.poll_fallback_ms or 5000
	state.on_batch = opts.on_batch
	state.running = true

	-- Skip historical entries — start from current EOF.
	local stat = uv.fs_stat(vim.fn.expand(state.path))
	state.byte_offset = stat and stat.size or 0

	bind_fs_event()

	-- Polling safety net: catches missed events and rebinds if the file was deleted/recreated.
	state.poll_timer = uv.new_timer()
	state.poll_timer:start(
		state.poll_fallback_ms,
		state.poll_fallback_ms,
		vim.schedule_wrap(function()
			local s = uv.fs_stat(vim.fn.expand(state.path))
			if s and s.size ~= state.byte_offset then schedule_flush() end
			if not state.fs_event and s then bind_fs_event() end
		end)
	)

	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,
		callback = function() M.stop() end,
	})
end

function M.stop()
	state.running = false
	if state.debounce_timer then
		pcall(function()
			state.debounce_timer:stop()
			state.debounce_timer:close()
		end)
		state.debounce_timer = nil
	end
	if state.poll_timer then
		pcall(function()
			state.poll_timer:stop()
			state.poll_timer:close()
		end)
		state.poll_timer = nil
	end
	if state.fs_event then
		pcall(function()
			state.fs_event:stop()
			state.fs_event:close()
		end)
		state.fs_event = nil
	end
end

return M
