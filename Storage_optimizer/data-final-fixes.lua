-- Generování tierů až po načtení všech modů, aby se zahrnuly i pásy z jiných modů.
local tiers = require("prototypes.tiers")
local icons = require("prototypes.icons")
local entity = require("prototypes.entity")
local item = require("prototypes.item")
local recipe = require("prototypes.recipe")

local interval_multiplier = settings.startup["storage-optimizer-interval-multiplier"].value
local power_multiplier = settings.startup["storage-optimizer-power-multiplier"].value
local max_stacks = settings.startup["storage-optimizer-max-stacks"].value

local list = tiers.collect(data.raw)
local runtime = {}
-- Hlavní tiery (jeden na rychlost) tvoří strom podle výzkumů (tiers.collect); varianta se vyrábí z hlavního
-- tieru své rychlosti.
local tier = 0

for _, info in ipairs(list) do
  info.name = "storage-optimizer-" .. info.belt
  if info.variant_of then
    info.previous = "storage-optimizer-" .. info.variant_of
  else
    tier = tier + 1
    info.previous = info.previous and "storage-optimizer-" .. info.previous
  end
  info.tier = tier
  info.interval = tiers.interval_ticks(info.speed, interval_multiplier)
  info.energy_kj = tiers.transfer_cost_kj(1, power_multiplier)
  info.extra_stack_kj = tiers.transfer_cost_kj(2, power_multiplier) - info.energy_kj
  info.buffer_kj = tiers.buffer_kj(max_stacks, power_multiplier)
  info.input_flow_kw = tiers.input_flow_kw(max_stacks, power_multiplier, info.interval)
  local layers = icons.tier_icons(info.item, entity.tint(tier))
  entity.create(info, layers)
  item.create(info, layers)
  recipe.create(info, layers)
  runtime[info.name] = {
    tier = tier,
    interval = info.interval,
    energy = info.energy_kj * 1000,
    extra_stack_energy = info.extra_stack_kj * 1000,
    max_stacks = max_stacks,
  }
end

for _, info in ipairs(list) do
  if info.next_upgrade then
    data.raw["inserter"][info.name].next_upgrade = "storage-optimizer-" .. info.next_upgrade
  end
end

data:extend({ { type = "mod-data", name = "storage-optimizer-tiers", data = runtime } })
