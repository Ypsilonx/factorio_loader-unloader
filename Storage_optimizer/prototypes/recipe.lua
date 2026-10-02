--- Recept tieru a jeho vlastní výzkum. Suroviny a cena výzkumu se ladí v prototypes/research.lua.
local research = require("prototypes.research")
local entity = require("prototypes.entity")

local M = {}

--- Vytvoří recept tieru a výzkum, který ho odemyká (bez výzkumu, pokud je vše potřebné dostupné od začátku).
--- Předchozí tier musí být už přidaný do data.raw – jeho výzkum se stává prerekvizitou.
--- @param info table položka z tiers.collect doplněná o name, tier, previous
--- @param icons table[] vrstvy ikony tieru
function M.create(info, icons)
  local ingredients = research.ingredients(data.raw, info.speed, info.item, info.previous)
  local tech = research.technology(data.raw, info.tech, ingredients, info.item)
  data:extend({
    {
      type = "recipe",
      name = info.name,
      enabled = tech == nil,
      energy_required = 1,
      ingredients = ingredients,
      results = { { type = "item", name = info.name, amount = 1 } },
    },
  })
  if not tech then return end
  data:extend({
    {
      type = "technology",
      name = info.name,
      icons = icons,
      localised_name = { "technology-name.storage-optimizer", entity.localised_name(info.belt) },
      localised_description = { "technology-description.storage-optimizer" },
      prerequisites = tech.prerequisites,
      unit = tech.unit,
      research_trigger = tech.research_trigger,
      effects = { { type = "unlock-recipe", recipe = info.name } },
    },
  })
  log(string.format("%s: suroviny %s, prerekvizity %s", info.name,
    serpent.line(ingredients, { comment = false }), table.concat(tech.prerequisites, ", ")))
end

return M
