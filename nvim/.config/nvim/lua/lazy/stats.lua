-- Stub for snacks.nvim dashboard. We don't use lazy.nvim (plugins come from
-- nix + lz.n), but snacks's default dashboard has a "startup" footer that
-- calls `require("lazy.stats").stats()` to display "loaded N plugins". Return
-- zeroed-out data so the dashboard renders without erroring.
return {
  stats = function()
    return {
      count = 0,
      loaded = 0,
      startuptime = 0,
      times = {},
    }
  end,
}
