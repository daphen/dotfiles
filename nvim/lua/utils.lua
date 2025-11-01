local M = {}

function M.current_path()
	return vim.fn.expand("%:p")
end

function M.find_root_with_markers(starting_path, root_markers)
	local path = vim.fn.fnamemodify(starting_path, ":p:h")
	local sep = package.config:sub(1, 1)

	while path and #path > 1 do
		for _, marker in ipairs(root_markers) do
			local marker_path = path .. sep .. marker
			if vim.fn.isdirectory(marker_path) ~= 0 or vim.fn.filereadable(marker_path) ~= 0 then
				return path
			end
		end
		path = vim.fn.fnamemodify(path, ":h")
	end
	return nil
end

-- Get project root with git priority (useful for monorepos)
-- Returns git root if available, otherwise falls back to closest project marker
function M.get_project_root_git_priority(starting_path)
	-- First try to find git root (for monorepo support)
	local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
	if vim.v.shell_error == 0 and git_root ~= "" then
		return git_root
	end
	
	-- Fallback to finding project markers if not in git repo
	local root_markers = { "package.json", "tsconfig.json", "Cargo.toml", "pyproject.toml", "go.mod" }
	return M.find_root_with_markers(starting_path, root_markers)
end

function M.root_has_file(starting_path, root_markers, target_files)
	local root_path = M.find_root_with_markers(starting_path, root_markers)
	if root_path then
		local sep = package.config:sub(1, 1)
		for _, file in ipairs(target_files) do
			local file_path = root_path .. sep .. file
			if vim.fn.filereadable(file_path) ~= 0 then
				return true
			end
		end
	end
	return false
end

return M
