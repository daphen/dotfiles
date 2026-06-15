return {
  "A7Lavinraj/fyler.nvim",
  dependencies = { "nvim-mini/mini.icons" },
  branch = "stable",
  keys = {
    { "<leader>t", function() require("fyler").open({ kind = "float" }) end, desc = "Open Fyler" },
  },
  opts = {
    track_current_buffer = true,
    close_on_select = true,
    win = {
      border = "rounded",
      kind = "float",
      kind_presets = {
        float = {
          height = "0.8rel",
          width = "0.8rel",
          top = "0.1rel",
          left = "0.1rel",
        },
      },
    },
  },
}
