--- Kouřový test: mod se načte a testovací infrastruktura funguje.
local H = require("helpers")

return {
  {
    name = "mod je aktivní",
    steps = {
      { ticks = 1, run = function() H.truthy(script.active_mods["Storage_optimizer"], "Storage_optimizer aktivní") end },
    },
  },
}
