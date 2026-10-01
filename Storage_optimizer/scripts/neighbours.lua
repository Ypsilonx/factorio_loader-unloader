--- Hledání zdrojové a cílové bedny kolem Storage optimizeru.
local M = {}

--- Typy entit, se kterými optimizer pracuje.
M.CONTAINER_TYPES = { "container", "logistic-container" }

--- Vektor ke zdroji pro 4 hlavní směry (2.0 má 16 směrů: sever 0, východ 4, jih 8, západ 12).
--- Odpovídá vanilla inserteru: při směru sever bere ze severu (ověřeno spikem).
local TO_SOURCE = {
  [0] = { 0, -1 },
  [4] = { 1, 0 },
  [8] = { 0, 1 },
  [12] = { -1, 0 },
}

--- Najde inventář bedny, jejíž hranice obsahuje daný bod (funguje i pro sklady N×N).
local function inventory_at(surface, position)
  local found = surface.find_entities_filtered({ position = position, type = M.CONTAINER_TYPES, limit = 1 })[1]
  return found and found.get_inventory(defines.inventory.chest) or nil
end

--- Přepočítá zdroj a cíl podle aktuální pozice a směru entity.
function M.refresh(mover)
  local entity = mover.entity
  local v = TO_SOURCE[entity.direction]
  local p = entity.position
  mover.direction = entity.direction
  mover.source = inventory_at(entity.surface, { p.x + v[1], p.y + v[2] })
  mover.target = inventory_at(entity.surface, { p.x - v[1], p.y - v[2] })
end

--- Má entita platný zdroj i cíl?
function M.complete(mover)
  return mover.source ~= nil and mover.source.valid and mover.target ~= nil and mover.target.valid
end

return M
