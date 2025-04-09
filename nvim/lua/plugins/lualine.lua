return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"meuter/lualine-so-fancy.nvim",
		"yavorski/lualine-macro-recording.nvim",
	},
	lazy = false,
	event = { "BufReadPost", "BufNewFile", "VeryLazy" },
	config = function()
		-- local icons = require("config.icons")

		-- Function to find project root based on package.json
		local function get_project_root()
			local function find_package_json(path)
				local package_json = path .. "/package.json"
				local f = io.open(package_json, "r")
				if f then
					f:close()
					return path
				end

				-- Try parent directory if not at filesystem root
				local parent = path:match("(.+)/[^/]+$")
				if parent and parent ~= path then return find_package_json(parent) end

				return nil
			end

			local current_file = vim.fn.expand("%:p:h")
			local root_dir = find_package_json(current_file)

			if root_dir then
				-- Extract just the folder name from the full path
				local folder_name = root_dir:match("([^/]+)$")
				return " " .. folder_name .. " "
			else
				return ""
			end
		end

		-- Set the StatusLine highlight for consistent background
		vim.api.nvim_set_hl(0, "StatusLine", { bg = "#121214" })
		vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "#121214" })

		require("lualine").setup({
			options = {
				-- theme = custom_theme,
				theme = "auto",
				globalstatus = true,
				icons_enabled = true,
				-- component_separators = { left = "│", right = "│" },
				component_separators = { left = "│", right = "│" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					{ "fancy_mode", width = 8 },
				},
				lualine_b = {
					{ "fancy_branch" },
					{
						"filename",
						symbols = {
							modified = "  ",
							readonly = "  ",
							unnamed = "  ",
						},
					},
					{
						"fancy_diagnostics",
						sources = { "nvim_lsp" },
						symbols = { error = " ", warn = " ", info = " " },
					},
					{ "fancy_searchcount" },
					{
						"macro_recording",
						fmt = function(str) return string.upper(str) end,
						color = { fg = "#121214", bg = "#FF995E", gui = "bold" },
						padding = { left = 2, right = 2 },
					},
				},
				lualine_c = {},
				lualine_x = {
					"filetype",
					"fancy_diff",
					"progress",
				},
				lualine_y = {},
				lualine_z = {
					{
						function() return get_project_root() end,
					},
				},
			},
			extensions = { "lazy" },
		})
	end,
}

-- local custom_theme = {
-- 	normal = {
-- 		a = { fg = "#121214", bg = "#899AA6", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#FF995E", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#121214", bg = "#899AA6", bold = true },
-- 	},
-- 	insert = {
-- 		a = { fg = "#121214", bg = "#FF995E", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#FF995E", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#121214", bg = "#FF995E", bold = true },
-- 	},
-- 	visual = {
-- 		a = { fg = "#121214", bg = "#E6E7A3", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#54C0A3", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#121214", bg = "#E6E7A3", bold = true },
-- 	},
-- 	replace = {
-- 		a = { fg = "#121214", bg = "#f7768e", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#FF995E", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#121214", bg = "#f7768e", bold = true },
-- 	},
-- 	command = {
-- 		a = { fg = "#121214", bg = "#698893", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#FF995E", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#121214", bg = "#698893", bold = true },
-- 	},
-- 	inactive = {
-- 		a = { fg = "#DBDBD9", bg = "#121214", bold = true },
-- 		b = { fg = "#DBDBD9", bg = "#121214" },
-- 		c = { fg = "#FF995E", bg = "#121214", bold = true },
-- 		x = { fg = "#DBDBD9", bg = "#121214" },
-- 		z = { fg = "#DBDBD9", bg = "#121214", bold = true },
-- 	},
-- }
