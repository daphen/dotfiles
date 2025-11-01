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
		local function get_scrollbar()
			local sbar_chars = {
				"▔",
				"🮂",
				"🬂",
				"🮃",
				"▀",
				"▄",
				"▃",
				"🬭",
				"▂",
				"▁",
			}

			local cur_line = vim.api.nvim_win_get_cursor(0)[1]
			local lines = vim.api.nvim_buf_line_count(0)

			local i = math.floor((cur_line - 1) / lines * #sbar_chars) + 1
			if i > #sbar_chars then i = #sbar_chars end
			local sbar = string.rep(sbar_chars[i], 2)

			-- Just return the raw characters
			return sbar
		end

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

		-- Define a custom theme that removes background colors from sections
		-- Define dark and light themes
		local dark_theme = {
			normal = {
				a = { fg = "#EDEDED", bg = "NONE" },
				b = { fg = "#EDEDED", bg = "NONE" },
				c = { fg = "#EDEDED", bg = "NONE" },
				x = { fg = "#EDEDED", bg = "NONE" },
				y = { fg = "#EDEDED", bg = "NONE" },
				z = { fg = "#ED333B", bg = "#1B1B1B" },
			},
		}

		local light_theme = {
			normal = {
				a = { fg = "#2D4A3D", bg = "NONE" },
				b = { fg = "#2D4A3D", bg = "NONE" },
				c = { fg = "#2D4A3D", bg = "NONE" },
				x = { fg = "#2D4A3D", bg = "NONE" },
				y = { fg = "#2D4A3D", bg = "NONE" },
				z = { fg = "#ED333B", bg = "#F9F2DF" },
			},
		}

		-- Function to determine current theme based on background
		local function get_theme()
			-- Force a refresh of background detection
			local bg = vim.fn.eval("&background")
			if bg == "dark" then
				return dark_theme
			else
				return light_theme
			end
		end

		require("lualine").setup({
			options = {
				theme = get_theme(),
				globalstatus = true,
				icons_enabled = true,
				component_separators = { left = "│", right = "│" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {},
				lualine_b = {
					{ "fancy_branch", padding = { left = 0, right = 2 } },
					{
						"filename",
					},
					{
						"fancy_diagnostics",
						sources = { "nvim_lsp" },
						symbols = { error = " ", warn = " ", info = " " },
						diagnostics_color = {
							error = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.error }
							end,
							warn = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.warning }
							end,
							info = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.info }
							end,
						},
					},
					{
						"diagnostics",
						sources = { "nvim_lsp" },
						symbols = { error = "E:", warn = "W:", info = "I:" },
						diagnostics_color = {
							error = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.error }
							end,
							warn = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.warning }
							end,
							info = function() 
								local colors = require("theme.colors").get_colors()
								return { fg = colors.info }
							end,
						},
					},
					{ "fancy_searchcount" },
				},
				lualine_c = {
					{
						"macro_recording",
						fmt = function(str) return string.upper(str) end,
						color = { fg = "#121214", bg = "#ED333B", gui = "bold" },
						padding = { left = 2, right = 2 },
					},
				},
				lualine_x = {
					"filetype",
					"fancy_diff",
					{
						function() return get_project_root() end,
						padding = { left = 0, right = 0 },
					},
				},
				lualine_y = {},
				lualine_z = {
					{
						function() return " " end, -- Return a single space
						padding = { left = 0, right = 0 },
						color = { bg = "NONE" }, -- Transparent background
					},
					{
						get_scrollbar,
						padding = { left = 0, right = 0 },
						separator = "",
					},
				},
			},
			extensions = { "lazy" },
		})

		vim.api.nvim_create_autocmd("OptionSet", {
			pattern = "background",
			callback = function()
				vim.defer_fn(function()
					require("lualine").setup({
						options = {
							theme = get_theme(),
							globalstatus = true,
							icons_enabled = true,
							component_separators = { left = "│", right = "│" },
							section_separators = { left = "", right = "" },
							disabled_filetypes = {
								statusline = {},
								winbar = {},
							},
						},
						sections = {
							lualine_a = {},
							lualine_b = {
								{ "fancy_branch", padding = { left = 0, right = 2 } },
								{ "filename" },
								{
									"fancy_diagnostics",
									sources = { "nvim_lsp" },
									symbols = { error = "󰅚 ", warn = "󰀪 ", info = "󰋽 " },
									diagnostics_color = {
										error = function() 
											local colors = require("theme.colors").get_colors()
											return { fg = colors.error }
										end,
										warn = function() 
											local colors = require("theme.colors").get_colors()
											return { fg = colors.warning }
										end,
										info = function() 
											local colors = require("theme.colors").get_colors()
											return { fg = colors.info }
										end,
									},
								},
								{ "fancy_searchcount" },
							},
							lualine_c = {
								{
									"macro_recording",
									fmt = function(str) return string.upper(str) end,
									color = { fg = "#121214", bg = "#ED333B", gui = "bold" },
									padding = { left = 2, right = 2 },
								},
							},
							lualine_x = {
								"filetype",
								"fancy_diff",
								{
									function() return get_project_root() end,
									padding = { left = 0, right = 0 },
								},
							},
							lualine_y = {},
							lualine_z = {
								{
									function() return " " end,
									padding = { left = 0, right = 0 },
									color = { bg = "NONE" },
								},
								{
									get_scrollbar,
									padding = { left = 0, right = 0 },
									separator = "",
								},
							},
						},
						extensions = { "lazy" },
					})
				end, 50)
			end,
		})
	end,
}
