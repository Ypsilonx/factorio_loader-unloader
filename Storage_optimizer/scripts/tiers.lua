--- Runtime přístup k parametrům tierů zapsaným v data stage do mod-data.
local M = {}

--- Kopie dat načtená jednou při načtení skriptu (stejná u všech hráčů → deterministická).
local DATA = prototypes.mod_data["storage-optimizer-tiers"].data

--- Vrátí tabulku { [jméno entity] = { tier, interval, energy, extra_stack_energy, max_stacks } }.
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

--- Cena přesunu v joulech: pevná cena (včetně prvního stacku) + každý další stack.
--- @param name string jméno entity tieru
--- @param stacks integer počet stacků v přesunu
function M.cost(name, stacks)
  local tier = DATA[name]
  return tier.energy + tier.extra_stack_energy * (stacks - 1)
end

--- Pevná cena přesunu a cena každého dalšího stacku v kJ (pro texty v GUI).
--- @return number, number
function M.energy_kj(name)
  local tier = DATA[name]
  return tier.energy / 1000, tier.extra_stack_energy / 1000
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
