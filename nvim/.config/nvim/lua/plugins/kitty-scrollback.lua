return {
  'mikesmithgh/kitty-scrollback.nvim',
  lazy = true,
  cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth' },
  event = { 'User KittyScrollbackLaunch' },
  config = function()
    require('kitty-scrollback').setup({
      {
        callbacks = {
          after_ready = function()
            vim.o.number = true
            vim.o.relativenumber = true
          end,
        },
      },
    })
  end,
}
