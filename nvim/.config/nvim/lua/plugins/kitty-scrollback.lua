return {
  'mikesmithgh/kitty-scrollback.nvim',
  config = function()
    require('kitty-scrollback').setup({
      {
        status_window = { enabled = false },
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
