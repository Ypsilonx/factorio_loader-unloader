-- Testovací prototypy: rychlý pás „z cizího modu“, skrytý pás a velký sklad 3×3.

--- Přidá pás se stejnojmenným předmětem a receptem dostupným od začátku.
local function add_belt(name, speed, hidden)
  local belt = table.deepcopy(data.raw["transport-belt"]["transport-belt"])
  belt.name = name
  belt.speed = speed
  belt.hidden = hidden
  belt.next_upgrade = nil
  belt.related_underground_belt = nil
  belt.minable = { mining_time = 0.1, result = name }
  local item = table.deepcopy(data.raw["item"]["transport-belt"])
  item.name = name
  item.place_result = name
  data:extend({
    belt,
    item,
    { type = "recipe", name = name, enabled = true, ingredients = {}, results = { { type = "item", name = name, amount = 1 } } },
  })
end

add_belt("so-test-belt", 0.25, false)
add_belt("so-test-hidden-belt", 0.125, true)

local warehouse = table.deepcopy(data.raw["container"]["steel-chest"])
warehouse.name = "so-test-warehouse"
warehouse.inventory_size = 200
warehouse.collision_box = { { -1.35, -1.35 }, { 1.35, 1.35 } }
warehouse.selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }
warehouse.fast_replaceable_group = nil
warehouse.next_upgrade = nil
warehouse.minable = { mining_time = 0.1, result = "steel-chest" }
data:extend({ warehouse })
