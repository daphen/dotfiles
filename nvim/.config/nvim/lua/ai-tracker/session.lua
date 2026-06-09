local M = {}
local uv = vim.loop or vim.uv

local state = {
	dir = nil,
	dir_watcher = nil,
	file_path = nil,
	file_watcher = nil,
	offset = 0,
	touched = {}, -- path -> { tool, ts }
}

local TOOLS = {
	Edit = true,
	Write = true,
	MultiEdit = true,
	NotebookEdit = true,
}

local function path_to_hash(cwd)
	return (cwd:gsub("/", "-"):gsub("%.", "-"))
end

local function find_latest_jsonl(dir)
	local handle = uv.fs_scandir(dir)
	if not handle then return nil end
	local latest, latest_mtime = nil, 0
	while true do
		local name, t = uv.fs_scandir_next(handle)
		if not name then break end
		if t == "file" and name:match("%.jsonl$") then
			local full = dir .. "/" .. name
			local stat = uv.fs_stat(full)
			if stat and stat.mtime.sec > latest_mtime then
				latest_mtime = stat.mtime.sec
				latest = full
			end
		end
	end
	return latest
end

local function process_chunk(chunk)
	for line in chunk:gmatch("[^\n]+") do
		if line ~= "" then
			local ok, msg = pcall(vim.json.decode, line)
			if ok and msg and msg.message and type(msg.message.content) == "table" then
				for _, item in ipairs(msg.message.content) do
					if type(item) == "table" and item.type == "tool_use"
						and TOOLS[item.name] and item.input and item.input.file_path then
						state.touched[item.input.file_path] = {
							tool = item.name,
							ts = msg.timestamp,
						}
					end
				end
			end
		end
	end
end

local function read_delta()
	if not state.file_path then return end
	local stat = uv.fs_stat(state.file_path)
	if not stat then return end
	if stat.size < state.offset then state.offset = 0 end
	if stat.size <= state.offset then return end
	local fd = io.open(state.file_path, "rb")
	if not fd then return end
	fd:seek("set", state.offset)
	local chunk = fd:read(stat.size - state.offset)
	fd:close()
	state.offset = stat.size
	if chunk then process_chunk(chunk) end
end

local function attach_to_file(path, replay)
	if state.file_watcher then
		pcall(function() state.file_watcher:stop() end)
		pcall(function() state.file_watcher:close() end)
	end
	state.file_path = path
	state.file_watcher = uv.new_fs_event()
	if not state.file_watcher then return end

	if replay then
		state.offset = 0
	else
		local stat = uv.fs_stat(path)
		state.offset = stat and stat.size or 0
	end

	local w = state.file_watcher
	local on_event
	on_event = function(err)
		if err or state.file_watcher ~= w then return end
		vim.schedule(function()
			read_delta()
			-- Re-arm: inotify watch can drop after file mutations.
			if state.file_watcher == w then
				pcall(function() w:stop() end)
				pcall(function() w:start(state.file_path, {}, on_event) end)
			end
		end)
	end
	w:start(path, {}, on_event)
	if replay then read_delta() end
end

local function attach_to_dir(dir)
	if state.dir_watcher then
		pcall(function() state.dir_watcher:close() end)
	end
	state.dir = dir
	state.dir_watcher = uv.new_fs_event()
	if not state.dir_watcher then return end
	state.dir_watcher:start(dir, {}, function(err)
		if err then return end
		vim.schedule(function()
			local latest = find_latest_jsonl(dir)
			if latest and latest ~= state.file_path then
				attach_to_file(latest, false)
			end
		end)
	end)
end

local function try_attach()
	local hash = path_to_hash(vim.fn.getcwd())
	local dir = vim.fn.expand("~/.claude/projects/" .. hash)
	if not uv.fs_stat(dir) then return false end
	local latest = find_latest_jsonl(dir)
	if latest then attach_to_file(latest, false) end
	attach_to_dir(dir)
	return true
end

function M.setup()
	if try_attach() then return end
	-- Worktree just spawned; Claude may create its projects dir a
	-- moment after nvim runs setup(). Retry at 2s, 10s, 30s.
	for _, delay in ipairs({ 2000, 10000, 30000 }) do
		vim.defer_fn(function()
			if state.dir == nil then try_attach() end
		end, delay)
	end
end

function M.reattach()
	try_attach()
end

function M.touched_files()
	local out = {}
	for path, meta in pairs(state.touched) do
		out[#out + 1] = { path = path, tool = meta.tool, ts = meta.ts }
	end
	table.sort(out, function(a, b) return (a.ts or "") > (b.ts or "") end)
	return out
end

function M.rescan()
	if not state.file_path then return end
	state.touched = {}
	state.offset = 0
	read_delta()
end

function M.clear()
	state.touched = {}
end

function M.status()
	local n = 0
	for _ in pairs(state.touched) do n = n + 1 end
	return {
		dir = state.dir,
		file = state.file_path,
		offset = state.offset,
		count = n,
	}
end

return M
