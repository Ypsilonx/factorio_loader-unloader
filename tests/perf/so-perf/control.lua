-- Výkonový scénář: N dvojic beden propojených Storage optimizerem, dvojicí loaderů, nebo nijak (základ).
-- Soubory mode.lua a count.lua generuje tools/run-perf.sh.
local MODE = require("mode")
local N = require("count")

--- Postaví entitu na povrchu testu.
local function place(surface, spec)
  spec.force = "player"
  spec.raise_built = true
  local entity = surface.create_entity(spec)
  assert(entity, "nelze postavit " .. spec.name)
  return entity
end

script.on_init(function()
  local surface = game.create_surface("so-perf")
  surface.generate_with_lab_tiles = true
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  storage.targets = {}
  for i = 0, N - 1 do
    -- Sloupce po 3 dlaždicích (mezera pro rozvodny), řady po 6 dlaždicích.
    local column, row = i % 50, math.floor(i / 50)
    local x, y = column * 3 - 75, row * 6 - 60
    local source = place(surface, { name = "steel-chest", position = { x + 0.5, y + 0.5 } })
    source.insert({ name = "iron-plate", count = 4800 })
    local target_y = y + 2.5
    if MODE == "mover" or MODE == "mover-nochest" then
      place(surface, { name = "storage-optimizer-transport-belt", position = { x + 0.5, y + 1.5 }, direction = defines.direction.north })
    elseif MODE == "loader" then
      place(surface, { name = "loader-1x1", position = { x + 0.5, y + 1.5 }, direction = defines.direction.south, type = "output" })
      place(surface, { name = "loader-1x1", position = { x + 0.5, y + 2.5 }, direction = defines.direction.south, type = "input" })
      target_y = y + 3.5
    end
    if MODE ~= "mover-nochest" then
      storage.targets[#storage.targets + 1] = place(surface, { name = "steel-chest", position = { x + 0.5, target_y } })
    end
    if column % 6 == 0 and row % 3 == 0 then
      place(surface, { name = "substation", position = { x + 2, y + 5 } })
    end
    if column == 1 and row == 0 then
      local power = place(surface, { name = "electric-energy-interface", position = { x + 2, y + 5 } })
      power.power_production = 1e9
      power.electric_buffer_size = 1e10
    end
  end
end)

script.on_nth_tick(3000, function()
  local total = 0
  for _, target in pairs(storage.targets) do total = total + target.get_item_count("iron-plate") end
  log("SO-PERF moved=" .. total)
end)
