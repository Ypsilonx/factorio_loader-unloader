-- Generování tierů až po načtení všech modů, aby se zahrnuly i pásy z jiných modů.
local tiers = require("prototypes.tiers")
local icons = require("prototypes.icons")
local entity = require("prototypes.entity")
local item = require("prototypes.item")
local recipe = require("prototypes.recipe")

local interval_multiplier = settings.startup["storage-optimizer-interval-multiplier"].value
local power_multiplier = settings.startup["storage-optimizer-power-multiplier"].value

local list = tiers.collect(data.raw)
local runtime = {}
local previous

for index, info in ipairs(list) do
  info.tier = index
  info.name = "storage-optimizer-" .. info.belt
  info.interval = tiers.interval_ticks(info.speed, interval_multiplier)
  info.drain_kw = tiers.drain_kw(info.speed, power_multiplier)
  info.previous = previous
  local layers = icons.tier_icons(info.item, entity.tint(index))
  entity.create(info, layers)
  item.create(info, layers)
  recipe.create(info)
  runtime[info.name] = { tier = index, interval = info.interval }
  previous = info.name
end

for index = 1, #list - 1 do
  data.raw["inserter"][list[index].name].next_upgrade = list[index + 1].name
end

data:extend({ { type = "mod-data", name = "storage-optimizer-tiers", data = runtime } })
