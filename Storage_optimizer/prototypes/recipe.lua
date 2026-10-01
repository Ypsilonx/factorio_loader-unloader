--- Recept tieru a jeho odemčení výzkumem. Suroviny jsou laditelné zde.
local tiers = require("prototypes.tiers")

local M = {}

--- Suroviny tieru: první tier z rychlých inserterů, další z předchozího tieru.
local function ingredients(info)
  local first
  if info.previous then
    first = { type = "item", name = info.previous, amount = 1 }
  else
    first = { type = "item", name = "fast-inserter", amount = 2 }
  end
  return {
    first,
    { type = "item", name = info.item, amount = 2 },
    { type = "item", name = "electronic-circuit", amount = 5 },
  }
end

--- Vytvoří recept a přidá ho do výzkumu pásu (u pásu dostupného od začátku do výzkumu rychlého inserteru).
function M.create(info)
  local tech = info.tech or tiers.find_unlocking_tech(data.raw, "fast-inserter")
  data:extend({
    {
      type = "recipe",
      name = info.name,
      enabled = tech == nil,
      energy_required = 1,
      ingredients = ingredients(info),
      results = { { type = "item", name = info.name, amount = 1 } },
    },
  })
  if tech then
    local technology = data.raw["technology"][tech]
    technology.effects = technology.effects or {}
    table.insert(technology.effects, { type = "unlock-recipe", recipe = info.name })
  end
end

return M
