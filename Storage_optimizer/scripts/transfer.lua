--- Jeden cyklus přesunu: kontroly (proud, síť), výběr předmětu podle filtrů a přesun nejvýše jedné dávky
--- (celé, nebo se zapnutými zbytky i neúplné).
local filters = require("scripts.filters")
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

local RED = defines.wire_connector_id.circuit_red
local GREEN = defines.wire_connector_id.circuit_green

--- Úrovně kvality { [jméno] = úroveň }, načtené líně při prvním použití.
local quality_levels

--- Vrátí úrovně kvality.
local function levels()
  if not quality_levels then
    quality_levels = {}
    for name, quality in pairs(prototypes.quality) do quality_levels[name] = quality.level end
  end
  return quality_levels
end

--- Načte aktivní filtry entity; filtry jsou aktivní při zapnutém use_filters nebo při filtrech ze sítě.
local function read_filters(entity, behavior)
  local list = {}
  if not (entity.use_filters or (behavior and behavior.circuit_set_filters)) then return list end
  for i = 1, entity.filter_slot_count do
    local filter = entity.get_filter(i)
    if filter then list[#list + 1] = filter end
  end
  return list
end

--- Velikost dávky: signál ze sítě (je-li zapnutý a > 0) → ruční nastavení → nil (Auto).
local function batch_size(mover, behavior)
  if behavior and behavior.circuit_set_stack_size and behavior.circuit_stack_control_signal then
    local value = mover.entity.get_signal(behavior.circuit_stack_control_signal, RED, GREEN)
    if value > 0 then return value end
  end
  return mover.batch
end

--- Počet stacků za přesun: řídicí signál ze sítě (je-li zapnutý v panelu a > 0, omezený limitem)
--- → ruční nastavení → 1. Používá ho přesun i panel (zobrazení aktuální hodnoty).
--- @return integer počet stacků
--- @return integer|nil hodnota řídicího signálu (nil, pokud řízení sítí není zapnuté)
function M.stack_count(mover)
  if mover.stacks_circuit then
    local entity = mover.entity
    local value = entity.get_signal(mover.stacks_signal or registry.STACKS_SIGNAL, RED, GREEN)
    if value > 0 then return math.min(value, tiers.max_stacks(entity.name)), value end
    return mover.stacks or 1, value
  end
  return mover.stacks or 1, nil
end

--- Přesune přesně `count` kusů po slotech přes pomocný slot storage.buffer
--- (zachová kvalitu, čerstvost i data předmětů).
local function move(source, target, name, quality, count)
  local slot = storage.buffer[1]
  local id = { name = name, quality = quality }
  local remaining = count
  while remaining > 0 do
    local stack = source.find_item_stack(id)
    if not stack then return end
    local take = math.min(remaining, stack.count)
    slot.transfer_stack(stack, take)
    local inserted = target.insert(slot)
    if inserted < slot.count then
      -- Pojistka proti ztrátě předmětů: co se nevešlo, vrátit do zdroje.
      slot.count = slot.count - inserted
      source.insert(slot)
      slot.clear()
      return
    end
    slot.clear()
    remaining = remaining - take
  end
end

--- Kolik kusů přesunout: celá dávka, nebo (se zapnutými zbytky) tolik, kolik zdroj má a cíl pojme.
--- @param need integer celá dávka (velikost stacku × počet stacků)
--- @param available integer kusů ve zdroji
--- @param room integer kolik kusů cíl pojme
--- @param leftovers boolean|nil přesouvat i neúplnou dávku
--- @return integer počet kusů (0 = nic)
function M.amount(need, available, room, leftovers)
  if available >= need and room >= need then return need end
  if not leftovers then return 0 end
  return math.max(math.min(need, available, room), 0)
end

--- Provede jeden cyklus pro entitu se známým zdrojem a cílem.
--- @return string stav: "working" | "waiting" | "no_power" | "disabled"
function M.process(mover)
  local entity = mover.entity
  local stacks = M.stack_count(mover)
  -- Entita je pro engine vypnutá, status proto proud neukazuje; rozhoduje energie v zásobníku.
  -- Zbytek může stát méně než celý přesun, nejméně ale pevnou cenu za přesun.
  local full_cost = tiers.cost(entity.name, stacks)
  if entity.energy < (mover.leftovers and tiers.cost(entity.name, 1) or full_cost) then return "no_power" end
  local behavior = entity.get_control_behavior()
  if behavior and behavior.disabled then return "disabled" end
  local batch = batch_size(mover, behavior)
  local active = read_filters(entity, behavior)
  local mode = entity.inserter_filter_mode
  -- Filtry řízené sítí bez signálu (nebo ještě nepropsané enginem) neznamenají „cokoliv“, ale „nic“.
  if #active == 0 and mode == "whitelist" and behavior and behavior.circuit_set_filters then return "waiting" end
  local lv = levels()
  local contents = mover.source.get_contents()
  local n = #contents
  for k = 0, n - 1 do
    -- Rotující ukazatel, aby jeden předmět nevyhladověl ostatní.
    local index = (mover.cursor + k - 1) % n + 1
    local entry = contents[index]
    if filters.passes(active, mode, entry.name, entry.quality, lv) then
      local unit = batch or prototypes.item[entry.name].stack_size
      local need = unit * stacks
      local room = mover.target.get_insertable_count({ name = entry.name, quality = entry.quality })
      local count = M.amount(need, entry.count, room, mover.leftovers)
      if count > 0 then
        -- Neúplný přesun platí poměrnou část za stacky navíc (podíl dávky), pevnou cenu vždy celou.
        local cost = count == need and full_cost or tiers.cost(entity.name, count / unit)
        if entity.energy < cost then return "no_power" end
        move(mover.source, mover.target, entry.name, entry.quality, count)
        entity.energy = entity.energy - cost
        mover.cursor = index % n + 1
        return "working"
      end
    end
  end
  return "waiting"
end

return M
