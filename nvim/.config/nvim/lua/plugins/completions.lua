---@diagnostic disable: undefined-global
return {
  {
    "cmp-nvim-lsp",
  },
  {
    "luasnip",
    after = function()
      local luasnip = require("luasnip")

      -- Tab to jump forward
      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { silent = true })

      -- Shift-Tab to jump backward
      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<S-Tab>", true, false, true), "n", false)
        end
      end, { silent = true })
    end,
  },
  {
    "nvim-cmp",
    after = function()
      local cmp = require("cmp")
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })

      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-p>"] = cmp.mapping.complete({
            config = {
              sources = {
                { name = "luasnip" }
              }
            }
          }),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },
}
