-- nvim-treesitter 0.10+ (main branch) removed the `configs` module.
-- Grammars are pre-installed by nix via `nvim-treesitter.withAllGrammars`,
-- so we only need to enable highlighting + indentation per buffer.
return {
  "nvim-treesitter",
  lazy = false,
  after = function()
    -- Enable treesitter highlighting + indent for any filetype that has a
    -- parser available. Parsers come from the nix-baked grammar set.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local ok = pcall(vim.treesitter.start, args.buf)
        if ok then
          -- Enable treesitter-based indentation
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })

    -- Incremental selection — uses the neovim built-in API available in 0.10+
    vim.keymap.set("n", "<CR>", function()
      vim.cmd("normal! v")
      vim.treesitter.start()
    end, { desc = "Init incremental selection" })

    -- Placeholder for TS playground — module was removed from nvim-treesitter.main
    -- vim.keymap.set("n", "<leader>T", ":Inspect<CR>", { desc = "TS inspect (built-in)" })
    vim.keymap.set("n", "<leader>T", ":InspectTree<CR>", { desc = "Open TreeSitter inspect tree" })
  end,
}
