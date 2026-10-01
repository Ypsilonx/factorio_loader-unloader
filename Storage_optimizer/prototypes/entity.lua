--- Entita tieru: prototyp typu inserter s vyřazeným vlastním pohybem ramene.
local M = {}

local EMPTY = { filename = "__core__/graphics/empty.png", size = 1 }

--- Barvy tierů (dočasné odlišení do grafiky z Blenderu); při více tierech se cyklí.
M.TINTS = {
  { r = 1.0, g = 0.85, b = 0.25 },
  { r = 1.0, g = 0.35, b = 0.3 },
  { r = 0.35, g = 0.65, b = 1.0 },
  { r = 0.55, g = 1.0, b = 0.45 },
  { r = 0.8, g = 0.45, b = 1.0 },
  { r = 1.0, g = 1.0, b = 1.0 },
}

--- Barva tieru podle jeho pořadí.
function M.tint(tier)
  return M.TINTS[(tier - 1) % #M.TINTS + 1]
end

--- Lokalizovaný název tieru: „Storage optimizer (<název pásu>)“.
function M.localised_name(belt)
  local proto = data.raw["transport-belt"][belt]
  return { "entity-name.storage-optimizer", proto.localised_name or { "entity-name." .. belt } }
end

--- Vytvoří entitu tieru.
--- @param info table položka z tiers.collect doplněná o name, tier, interval, drain_kw
--- @param icons table[] vrstvy ikony
function M.create(info, icons)
  local e = table.deepcopy(data.raw["inserter"]["fast-inserter"])
  e.name = info.name
  e.icon = nil
  e.icons = icons
  e.localised_name = M.localised_name(info.belt)
  e.localised_description = { "entity-description.storage-optimizer" }
  e.minable = { mining_time = 0.1, result = info.name }
  e.placeable_by = nil
  e.next_upgrade = nil
  e.fast_replaceable_group = "storage-optimizer"
  e.filter_count = 5
  e.stack_size_bonus = 0
  e.bulk = false
  e.allow_custom_vectors = false
  -- Rameno míří na vlastní políčko: engine nenajde zdroj ani cíl a inserter usne (ověřeno spikem).
  e.pickup_position = { 0, 0 }
  e.insert_position = { 0, 0 }
  e.energy_per_movement = "1J"
  e.energy_per_rotation = "1J"
  e.energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    drain = string.format("%.3fkW", info.drain_kw),
  }
  e.hand_base_picture = EMPTY
  e.hand_closed_picture = EMPTY
  e.hand_open_picture = EMPTY
  e.hand_base_shadow = EMPTY
  e.hand_closed_shadow = EMPTY
  e.hand_open_shadow = EMPTY
  if e.platform_picture and e.platform_picture.sheet then
    e.platform_picture.sheet.tint = M.tint(info.tier)
  end
  e.custom_tooltip_fields = {
    {
      name = { "storage-optimizer.interval" },
      value = { "storage-optimizer.seconds", string.format("%.2f", info.interval / 60) },
    },
  }
  data:extend({ e })
end

return M
