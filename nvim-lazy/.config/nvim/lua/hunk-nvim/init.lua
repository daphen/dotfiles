-- hunk-nvim: git-driven diff signs in the gutter.
local M = {}

function M.setup(opts)
	pcall(function() require("hunk-nvim.signs").setup(opts or {}) end)
end

return M
