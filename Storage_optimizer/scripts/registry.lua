--- Evidence postavených Storage optimizerů ve storage.movers (klíč = unit_number).
local tiers = require("scripts.tiers")

local M = {}

--- Založí záznam pro novou entitu.
--- @param entity LuaEntity
--- @param batch integer|nil ručně nastavená velikost dávky (nil = Auto)
--- @return table mover
function M.add(entity, batch)
  local mover = {
    entity = entity,
    unit_number = entity.unit_number,
    interval = tiers.interval(entity.name),
    batch = batch,
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
