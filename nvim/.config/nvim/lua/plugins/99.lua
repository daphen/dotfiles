return {
    "ThePrimeagen/99",
    config = function()
        local _99 = require("99")

        local cwd = vim.uv.cwd()
        local basename = vim.fs.basename(cwd) or "nvim"

        _99.setup({
            model = "anthropic/claude-sonnet-4-5",

            logger = {
                level = _99.DEBUG,
                path = "/tmp/" .. basename .. ".99.debug",
                print_on_error = true,
            },

            completion = {
                source = "cmp",
                custom_rules = {
                    vim.fn.expand("~/.config/nvim/rules/"),
                },
            },

            md_files = {
                "AGENT.md",
            },
        })

        -- Fill in function body (with prompt window)
        vim.keymap.set("n", "<C-g>f", function()
            _99.fill_in_function_prompt()
        end, { desc = "99: Fill in function" })

        -- Visual selection actions (with prompt window)
        vim.keymap.set("v", "<C-g>v", function()
            _99.visual_prompt()
        end, { desc = "99: Visual action" })

        -- Stop all requests
        vim.keymap.set("n", "<C-g>s", function()
            _99.stop_all_requests()
        end, { desc = "99: Stop all requests" })

        -- View logs (useful for debugging)
        vim.keymap.set("n", "<C-g>l", function()
            _99.view_logs()
        end, { desc = "99: View logs" })
    end,
}
