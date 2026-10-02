--- Runtime přístup k parametrům tierů zapsaným v data stage do mod-data.
local M = {}

--- Kopie dat načtená jednou při načtení skriptu (stejná u všech hráčů → deterministická).
local DATA = prototypes.mod_data["storage-optimizer-tiers"].data

--- Vrátí tabulku { [jméno entity] = { tier, interval, energy } }.
function M.all()
  return DATA
end

--- Je entita s tímto jménem Storage optimizer?
function M.is_mover(name)
  return DATA[name] ~= nil
end

--- Interval přesunu tieru v tickách.
function M.interval(name)
  return DATA[name].interval
end

--- Energie za jeden přesun v joulech.
function M.energy(name)
  return DATA[name].energy
end

--- Maximální počet stacků za jeden přesun (startup nastavení).
function M.max_stacks(name)
  return DATA[name].max_stacks
end

--- Seřazená jména všech tierů (pro event filtry a GUI).
function M.names()
  local names = {}
  for name in pairs(DATA) do names[#names + 1] = name end
  table.sort(names)
  return names
end

return M
