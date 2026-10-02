--- Hledání zdroje a cíle kolem Storage optimizeru: bedny a sklady, montážní stroje a pece.
local M = {}

--- Inventář podle typu entity a role: zdroj bere z výstupu, cíl plní vstup. Bedny mají jeden inventář.
--- Stroje mají v 2.0 společné inventáře crafter_input / crafter_output; palivo se záměrně nepoužívá.
local INVENTORIES = {
  ["container"] = { source = defines.inventory.chest, target = defines.inventory.chest },
  ["logistic-container"] = { source = defines.inventory.chest, target = defines.inventory.chest },
  ["assembling-machine"] = { source = defines.inventory.crafter_output, target = defines.inventory.crafter_input },
  ["furnace"] = { source = defines.inventory.crafter_output, target = defines.inventory.crafter_input },
}

--- Typy entit, se kterými optimizer pracuje (pro hledání sousedů a event filtry).
M.TYPES = {}
for entity_type in pairs(INVENTORIES) do M.TYPES[#M.TYPES + 1] = entity_type end
table.sort(M.TYPES)

--- Vektor ke zdroji pro 4 hlavní směry (2.0 má 16 směrů: sever 0, východ 4, jih 8, západ 12).
--- Odpovídá vanilla inserteru: při směru sever bere ze severu (ověřeno spikem).
local TO_SOURCE = {
  [0] = { 0, -1 },
  [4] = { 1, 0 },
  [8] = { 0, 1 },
  [12] = { -1, 0 },
}

--- Najde inventář entity (bedny nebo stroje), jejíž hranice obsahuje daný bod, pro danou roli.
--- @param role string "source" | "target"
local function inventory_at(surface, position, role)
  local found = surface.find_entities_filtered({ position = position, type = M.TYPES, limit = 1 })[1]
  return found and found.get_inventory(INVENTORIES[found.type][role]) or nil
end

--- Přepočítá zdroj a cíl podle aktuální pozice a směru entity.
function M.refresh(mover)
  local entity = mover.entity
  local v = TO_SOURCE[entity.direction]
  local p = entity.position
  mover.direction = entity.direction
  mover.source = inventory_at(entity.surface, { p.x + v[1], p.y + v[2] }, "source")
  mover.target = inventory_at(entity.surface, { p.x - v[1], p.y - v[2] }, "target")
end

--- Má entita platný zdroj i cíl?
function M.complete(mover)
  return mover.source ~= nil and mover.source.valid and mover.target ~= nil and mover.target.valid
end

return M
