return {
	{
		-- Dummy plugin entry just to run colorscheme config at startup
		"nvim-lua/plenary.nvim", -- Use an existing dependency as anchor
		lazy = false,
		priority = 1000,
		config = function()
			-- Function to read theme mode from file
			local function read_theme_mode()
				local theme_file = vim.fn.expand("~/.config/theme_mode")
				local file = io.open(theme_file, "r")
				if file then
					local mode = file:read("*line")
					file:close()
					return mode == "light" and "light" or "dark"
				end
				return "dark"
			end

			-- Function to apply theme
			local function apply_theme()
				local theme_mode = read_theme_mode()
				vim.cmd.colorscheme("custom-theme-" .. theme_mode)
			end

			-- Apply initial theme
			apply_theme()

			-- Re-apply theme when LSP attaches to ensure @lsp highlights take effect
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function()
					vim.defer_fn(apply_theme, 10)
				end,
			})

			-- Watch theme_mode file for changes
			local theme_mode_file = vim.fn.expand("~/.config/theme_mode")
			local watch_handle = vim.uv.new_fs_event()
			if watch_handle then
				watch_handle:start(theme_mode_file, {}, vim.schedule_wrap(function(err, fname, events)
					if not err then
						vim.defer_fn(function()
							apply_theme()
						end, 50)
					end
				end))
			end

			-- Additional highlight overrides
			vim.api.nvim_create_autocmd("ColorScheme", {
				pattern = "custom-theme-*",
				callback = function()
					-- Transparent backgrounds (preserve fg colors)
					local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
					local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
					local status_line = vim.api.nvim_get_hl(0, { name = "StatusLine" })
					local status_line_nc = vim.api.nvim_get_hl(0, { name = "StatusLineNC" })

					vim.api.nvim_set_hl(0, "Normal", { fg = normal.fg, bg = "none" })
					vim.api.nvim_set_hl(0, "NormalFloat", { fg = normal_float.fg, bg = "none" })
					vim.api.nvim_set_hl(0, "StatusLine", { fg = status_line.fg, bg = "none" })
					vim.api.nvim_set_hl(0, "StatusLineNC", { fg = status_line_nc.fg, bg = "none" })

					-- Neo-tree transparent backgrounds
					vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
					vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none" })
					vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", { bg = "none" })

					-- Float/border transparent backgrounds
					vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
					vim.api.nvim_set_hl(0, "WinSeparator", { bg = "none" })
				end,
			})
		end,
	},
}
