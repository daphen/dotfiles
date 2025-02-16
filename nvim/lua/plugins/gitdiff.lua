return {
	{
		"gitdiff",
		dir = vim.fn.expand("$HOME/Documents/personal projects/gitdiff"),
		dependencies = {
			"MunifTanjim/nui.nvim",
		},
		lazy = false,
		config = function()
			print("Expanded path: " .. vim.fn.expand("~/Documents/personal projects/gitdiff"))

			local ok, gitdiff = pcall(require, "gitdiff")
			if not ok then
				vim.notify("Failed to load gitdiff: " .. gitdiff, vim.log.levels.ERROR)
				return
			end

			-- Create command to show merge tool
			vim.api.nvim_create_user_command("ShowMergeTool", function()
				gitdiff.show_merge_tool() -- Changed from show_diff_windows to show_merge_tool
			end, {})

			-- Create keymap
			vim.keymap.set("n", "<leader>gm", function()
				gitdiff.show_merge_tool() -- Changed from show_diff_windows to show_merge_tool
			end, {
				desc = "Show Merge Tool",
			})
		end,
	},
}
