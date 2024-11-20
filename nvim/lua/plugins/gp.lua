return {
	"robitx/gp.nvim",
	config = function()
		local conf = {
			default_provider = "ollama",
			default_command_agent = "qwen2.5-coder:7b",
			default_chat_agent = "qwen2.5-coder:7b",
			command_prompt_prefix_template = "Prompt:",

			providers = {
				ollama = {
					disable = false,
					endpoint = "http://localhost:11434/v1/chat/completions",
				},
			},
			agents = {
				{
					provider = "ollama",
					name = "qwen2.5-coder:7b",
					chat = true,
					command = true,
					model = "qwen2.5-coder:7b",
					system_prompt = "You are a general AI assistant.",
				},
			},
			hooks = {
				-- example of making :%GpChatNew a dedicated command which
				-- opens new chat with the entire current buffer as a context
				BufferChatNew = function(gp, _)
					-- call GpChatNew command in range mode on whole buffer
					vim.api.nvim_command("%" .. gp.config.cmd_prefix .. "ChatToggle popup")
				end,
			},
		}
		require("gp").setup(conf)

		vim.keymap.set({ "n", "i" }, "<C-g>g", "<cmd>GpBufferChatNew<cr>")
		vim.keymap.set("v", "<C-g><C-g>", ":<C-u>'<,'>GpRewrite<cr>")
	end,
}
