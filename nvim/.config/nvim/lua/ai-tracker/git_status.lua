local M = {}
local uv = vim.loop or vim.uv

local state = {
	timer = nil,
	cwd = nil,
	poll_ms = 2000,
	touched = {},   -- path -> { ts, code, source = "git" }
	last_set = {},  -- path -> code (snapshot from previous poll, for diffing)
	in_flight = false,
}

local function process_output(stdout)
	local current = {}
	for line in stdout:gmatch("[^\n]+") do
		if #line >= 4 then
			local code = line:sub(1, 2)
			local path = line:sub(4)
			if code:match("^R") then
				local arrow = path:find(" %-> ")
				if arrow then path = path:sub(arrow + 4) end
			end
			current[path] = code
		end
	end
	local now = os.time()
	for path, code in pairs(current) do
		if not state.last_set[path] then
			state.touched[path] = { ts = now, code = code, source = "git" }
		end
	end
	state.last_set = current
end

local function poll()
	if not state.cwd or state.in_flight then return end
	state.in_flight = true
	vim.system(
		{ "git", "status", "--porcelain" },
		{ cwd = state.cwd, text = true },
		function(result)
			state.in_flight = false
			if result.code == 0 then
				vim.schedule(function() process_output(result.stdout or "") end)
			end
		end
	)
end

function M.setup(opts)
	opts = opts or {}
	state.cwd = vim.fn.getcwd()
	local r = vim.fn.systemlist({ "git", "-C", state.cwd, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error ~= 0 or not r[1] or r[1] == "" then return end
	state.cwd = r[1]
	state.poll_ms = opts.poll_ms or 2000

	if state.timer then
		pcall(function() state.timer:stop() end)
		pcall(function() state.timer:close() end)
	end
	state.timer = uv.new_timer()
	if state.timer then
		state.timer:start(state.poll_ms, state.poll_ms, vim.schedule_wrap(poll))
	end
	poll()
end

function M.touched_files()
	local out = {}
	for path, meta in pairs(state.touched) do
		out[#out + 1] = { path = path, source = meta.source, code = meta.code, ts = meta.ts }
	end
	table.sort(out, function(a, b) return a.ts > b.ts end)
	return out
end

function M.clear()
	state.touched = {}
	state.last_set = {}
end

function M.rebaseline()
	-- Mark current state as "already seen" so only NEW changes from now on count.
	state.last_set = {}
	state.touched = {}
	poll()
end

function M.status()
	local n = 0
	for _ in pairs(state.touched) do n = n + 1 end
	return { cwd = state.cwd, count = n, poll_ms = state.poll_ms }
end

function M.stop()
	if state.timer then
		pcall(function() state.timer:stop() end)
		pcall(function() state.timer:close() end)
		state.timer = nil
	end
end

return M
