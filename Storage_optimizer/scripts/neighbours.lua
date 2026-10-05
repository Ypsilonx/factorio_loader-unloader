--- Hledání zdroje a cíle kolem Storage optimizeru: bedny a sklady (i logistické a nekonečné),
--- montážní stroje, pece a nákladní vagóny.
local M = {}

--- Inventář podle typu entity a role: zdroj bere z výstupu, cíl plní vstup. Bedny mají jeden inventář.
--- Stroje mají v 2.0 společné inventáře crafter_input / crafter_output; palivo se záměrně nepoužívá.
local INVENTORIES = {
  ["container"] = { source = defines.inventory.chest, target = defines.inventory.chest },
  ["logistic-container"] = { source = defines.inventory.chest, target = defines.inventory.chest },
  ["infinity-container"] = { source = defines.inventory.chest, target = defines.inventory.chest },
  ["assembling-machine"] = { source = defines.inventory.crafter_output, target = defines.inventory.crafter_input },
  ["furnace"] = { source = defines.inventory.crafter_output, target = defines.inventory.crafter_input },
  ["cargo-wagon"] = { source = defines.inventory.cargo_wagon, target = defines.inventory.cargo_wagon },
  ["infinity-cargo-wagon"] = { source = defines.inventory.cargo_wagon, target = defines.inventory.cargo_wagon },
}

--- Typy vagónů: jsou sousedem jen když stojí a optimizer je musí každý cyklus hledat znovu (odjedou).
M.WAGON_TYPES = { ["cargo-wagon"] = true, ["infinity-cargo-wagon"] = true }

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

--- Najde entitu se známým inventářem, jejíž hranice obsahuje daný bod; jedoucí vagón se nepočítá.
--- @return LuaEntity|nil
local function entity_at(surface, position)
  local found = surface.find_entities_filtered({ position = position, type = M.TYPES, limit = 1 })[1]
  if found and M.WAGON_TYPES[found.type] and found.speed ~= 0 then return nil end
  return found
end

--- Přepočítá zdroj a cíl podle aktuální pozice a směru entity.
--- mover.wagon = některá strana je vagón → run() sousedy přepočítá každý cyklus (vlak může odjet).
function M.refresh(mover)
  local entity = mover.entity
  local v = TO_SOURCE[entity.direction]
  local p = entity.position
  local from = entity_at(entity.surface, { p.x + v[1], p.y + v[2] })
  local to = entity_at(entity.surface, { p.x - v[1], p.y - v[2] })
  mover.direction = entity.direction
  mover.source = from and from.get_inventory(INVENTORIES[from.type].source) or nil
  mover.target = to and to.get_inventory(INVENTORIES[to.type].target) or nil
  mover.wagon = (from and M.WAGON_TYPES[from.type] or to and M.WAGON_TYPES[to.type]) and true or nil
end

--- Má entita platný zdroj i cíl?
function M.complete(mover)
  return mover.source ~= nil and mover.source.valid and mover.target ~= nil and mover.target.valid
end

return M
