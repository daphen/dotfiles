return {
	-- 	"yetone/avante.nvim",
	-- 	event = "VeryLazy",
	-- 	lazy = false,
	-- 	version = false,
	-- 	opts = {
	-- 		provider = "ollama",
	-- 		vendors = {
	-- 			ollama = {
	-- 				["local"] = true,
	-- 				endpoint = "127.0.0.1:11434/v1",
	-- 				model = "qwen2.5-coder:7b",
	-- 				parse_curl_args = function(opts, code_opts)
	-- 					return {
	-- 						url = opts.endpoint .. "/chat/completions",
	-- 						headers = {
	-- 							["Accept"] = "application/json",
	-- 							["Content-Type"] = "application/json",
	-- 							["x-api-key"] = "ollama",
	-- 						},
	-- 						body = {
	-- 							model = opts.model,
	-- 							messages = require("avante.providers").claude.parse_messages(code_opts),
	-- 							max_tokens = 200000,
	-- 							stream = true,
	-- 						},
	-- 					}
	-- 				end,
	-- 				parse_response_data = function(data_stream, event_state, opts)
	-- 					require("avante.providers").openai.parse_response(data_stream, event_state, opts)
	-- 				end,
	-- 			},
	-- 		},
	-- 	},
	-- 	behaviour = {
	-- 		auto_suggestions = false,
	-- 		auto_apply_diff_after_generation = false,
	-- 		support_paste_from_clipboard = false,
	-- 	},
	-- 	windows = {
	-- 		position = "right",
	-- 		width = 40,
	-- 		wrap = true,
	-- 		sidebar_header = {
	-- 			align = "center",
	-- 			rounded = true,
	-- 		},
	-- 	},
	-- 	build = "make",
	-- 	dependencies = {
	-- 		"nvim-treesitter/nvim-treesitter",
	-- 		"stevearc/dressing.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"MunifTanjim/nui.nvim",
	-- 		"nvim-tree/nvim-web-devicons",
	-- 		{
	-- 			"MeanderingProgrammer/render-markdown.nvim",
	-- 			opts = {
	-- 				file_types = { "markdown", "Avante" },
	-- 			},
	-- 			ft = { "markdown", "Avante" },
	-- 		},
	-- 	},
}
