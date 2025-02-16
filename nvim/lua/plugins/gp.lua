return {
	"robitx/gp.nvim",
	config = function()
		local config = {
			providers = {
				openai = {
					endpoint = "https://openrouter.ai/api/v1/chat/completions",
					secret = os.getenv("LLM_KEY"),
					additional_request_headers = {
						["HTTP-Referer"] = "http://localhost:8080",
						["X-Title"] = "Neovim",
					},
				},
			},
			agents = {
				{
					name = "ChatGPT4o",
					disable = true,
				},
				{
					name = "ChatGPT4o-mini",
					disable = true,
				},
				{
					name = "ChatGPT4",
					disable = true,
				},
				{
					name = "ChatGPT3-5",
					disable = true,
				},
				{
					name = "ChatGPTMini",
					disable = true,
				},
				{
					name = "claude",
					provider = "openai",
					chat = true,
					command = true,
					model = { model = "anthropic/claude-3.5-sonnet" },
					system_prompt = "You are a helpful AI assistant specialized in explaining and working with code.",
				},
			},
			default_agent = "claude",
			chat_agent = "claude",
			command_agent = "claude",
			style_popup_border = "rounded",
			style_popup_prefix = "  ",
			chat_dir = vim.fn.stdpath("state") .. "/gp/chats",
		}
		require("gp").setup(config)

		-- Normal mode mappings
		vim.keymap.set("n", "<C-g>g", "<cmd>GpChatToggle vsplit<cr>") -- Toggle chat
		vim.keymap.set("n", "<C-g>n", "<cmd>GpChatNew vsplit<cr>") -- New chat
		vim.keymap.set("n", "<C-g>q", "<cmd>GpStop<cr>") -- Close current chat
		vim.keymap.set("n", "<C-g>f", "<cmd>GpChatFinder<cr>") -- Chat finder

		-- Visual mode mappings
		vim.keymap.set("v", "<C-g>n", ":'<,'>GpChatNew popup<cr>") -- New chat with selection
		vim.keymap.set("v", "<C-g>g", ":'<,'>GpChatPaste<cr>") -- Paste selection into current chat
	end,
}
