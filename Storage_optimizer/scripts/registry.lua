--- Evidence postavených Storage optimizerů ve storage.movers (klíč = unit_number).
local tiers = require("scripts.tiers")

local M = {}

--- Normalizuje velikost dávky z hranice systému (GUI, remote): < 1 nebo nečíslo = Auto (nil).
function M.clean_batch(value)
  value = tonumber(value)
  return (value and value >= 1) and math.floor(value) or nil
end

--- Normalizuje počet stacků na rozsah 1..max tieru; 1 nebo neplatná hodnota = výchozí (nil).
function M.clean_stacks(name, value)
  value = tonumber(value)
  if not value or value < 2 then return nil end
  return math.min(math.floor(value), tiers.max_stacks(name))
end

--- Výchozí řídicí signál počtu stacků.
M.STACKS_SIGNAL = { type = "virtual", name = "signal-N" }

--- Normalizuje řídicí signál z hranice systému (GUI, remote, tagy): neplatný = výchozí (nil).
function M.clean_signal(signal)
  if type(signal) ~= "table" or type(signal.name) ~= "string" then return nil end
  return { type = signal.type or "item", name = signal.name }
end

--- Založí záznam pro novou entitu.
--- @param entity LuaEntity
--- @param settings table|nil { batch = velikost stacku (nil = Auto), stacks = počet stacků (nil = 1),
---   stacks_circuit = počet stacků ze sítě (nil = ne), stacks_signal = řídicí signál (nil = výchozí),
---   leftovers = přesouvat i zbytky (nil = ne) }
--- @return table mover
function M.add(entity, settings)
  settings = settings or {}
  local mover = {
    entity = entity,
    unit_number = entity.unit_number,
    interval = tiers.interval(entity.name),
    batch = settings.batch,
    stacks = M.clean_stacks(entity.name, settings.stacks),
    stacks_circuit = settings.stacks_circuit == true or nil,
    stacks_signal = M.clean_signal(settings.stacks_signal),
    leftovers = settings.leftovers == true or nil,
    cursor = 1,
  }
  storage.movers[entity.unit_number] = mover
  return mover
end

--- Vrátí záznam podle unit_number.
function M.get(unit_number)
  return storage.movers[unit_number]
end

--- Odebere záznam a vrátí ho (nebo nil).
function M.remove(unit_number)
  local mover = storage.movers[unit_number]
  storage.movers[unit_number] = nil
  return mover
end

return M
