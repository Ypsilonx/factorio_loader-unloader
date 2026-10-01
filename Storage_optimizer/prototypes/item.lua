--- Předmět tieru (staví entitu stejného jména).
local entity = require("prototypes.entity")

local M = {}

--- Vytvoří předmět tieru.
function M.create(info, icons)
  data:extend({
    {
      type = "item",
      name = info.name,
      icons = icons,
      localised_name = entity.localised_name(info.belt),
      localised_description = { "entity-description.storage-optimizer" },
      subgroup = "inserter",
      order = string.format("z[storage-optimizer]-%03d", info.tier),
      place_result = info.name,
      stack_size = 50,
    },
  })
end

return M
