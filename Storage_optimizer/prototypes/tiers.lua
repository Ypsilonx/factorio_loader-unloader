--- Čistá logika výběru pásů a výpočtu parametrů tierů.
--- Nepoužívá globály Factoria, aby šla testovat mimo hru (tests/unit/test_tiers.lua).
local M = {}

--- Rychlost žlutého pásu ve vanille (dlaždice/tick) – referenční bod všech výpočtů.
M.YELLOW_SPEED = 0.03125
--- Interval přesunu tieru se žlutou rychlostí v tickách (60 t = 1 s). Laditelná hodnota.
M.BASE_INTERVAL = 60
--- Pevná cena jednoho přesunu v kJ (zahrnuje první stack, stejná pro všechny tiery). Laditelná hodnota.
M.ENERGY_PER_TRANSFER_KJ = 20
--- Cena každého dalšího stacku v témže přesunu v kJ – velký přesun je na kus levnější. Laditelná hodnota.
M.ENERGY_PER_EXTRA_STACK_KJ = 5
--- Zásobník pojme tolik nejdražších přesunů (rezerva, aby pruh energie neklesal ke dnu). Laditelná hodnota.
M.BUFFER_RESERVE = 2

--- Spočítá interval přesunu v tickách (nejméně 1).
--- @param speed number rychlost pásu
--- @param multiplier number násobič z nastavení (větší = pomalejší)
--- @return integer
function M.interval_ticks(speed, multiplier)
  local raw = M.BASE_INTERVAL * (M.YELLOW_SPEED / speed) * multiplier
  return math.max(1, math.floor(raw + 0.5))
end

--- Spočítá cenu jednoho přesunu v kJ: pevná cena (včetně prvního stacku) + každý další stack.
--- Je stejná pro všechny tiery, rychlejší tier proto při plné práci odebírá úměrně vyšší průměrný výkon.
--- @param stacks integer počet stacků v přesunu (≥ 1)
--- @param multiplier number násobič spotřeby z nastavení
--- @return number
function M.transfer_cost_kj(stacks, multiplier)
  return (M.ENERGY_PER_TRANSFER_KJ + M.ENERGY_PER_EXTRA_STACK_KJ * (stacks - 1)) * multiplier
end

--- Kapacita zásobníku energie v kJ: BUFFER_RESERVE × nejdražší přesun (všechny stacky naráz).
--- @param max_stacks integer maximální počet stacků za přesun
--- @param multiplier number násobič spotřeby z nastavení
--- @return number
function M.buffer_kj(max_stacks, multiplier)
  return math.max(M.transfer_cost_kj(max_stacks, multiplier) * M.BUFFER_RESERVE, 0.001)
end

--- Rychlost dobíjení zásobníku v kW: právě na nejdražší přesun za interval, víc ne.
--- Výkyvy pokryje rezerva v zásobníku a síť nedostává zbytečně vysoké špičky.
--- @return number
function M.input_flow_kw(max_stacks, multiplier, interval_ticks)
  return math.max(M.transfer_cost_kj(max_stacks, multiplier), 0.001) / (interval_ticks / 60)
end

--- Vrátí klíče tabulky seřazené abecedně (deterministické pořadí i mimo Factorio).
local function sorted_keys(t)
  local keys = {}
  for key in pairs(t or {}) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

--- Najde předmět, který staví danou entitu.
local function find_place_item(raw, entity_name)
  for _, name in ipairs(sorted_keys(raw.item)) do
    if raw.item[name].place_result == entity_name then return name end
  end
end

--- Najde recept, jehož výsledkem je daný předmět.
local function find_recipe(raw, item_name)
  for _, name in ipairs(sorted_keys(raw.recipe)) do
    for _, result in ipairs(raw.recipe[name].results or {}) do
      if result.name == item_name then return name end
    end
  end
end

--- Najde výzkum, který odemyká daný recept.
--- @return string|nil jméno výzkumu
function M.find_unlocking_tech(raw, recipe_name)
  for _, name in ipairs(sorted_keys(raw.technology)) do
    for _, effect in ipairs(raw.technology[name].effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then return name end
    end
  end
end

--- Projde všechny pásy a vrátí použitelné (neskryté, s předmětem a receptem dostupným od začátku
--- nebo přes výzkum), seřazené podle rychlosti.
--- @param raw table data.raw nebo jeho testovací náhrada
--- @return table[] { belt, speed, item, recipe, tech } – tech = nil znamená recept dostupný od začátku
function M.collect(raw)
  local result = {}
  for _, name in ipairs(sorted_keys(raw["transport-belt"])) do
    local belt = raw["transport-belt"][name]
    local item = not belt.hidden and find_place_item(raw, name)
    local recipe = item and find_recipe(raw, item)
    if recipe then
      local tech = M.find_unlocking_tech(raw, recipe)
      if tech or raw.recipe[recipe].enabled ~= false then
        result[#result + 1] = { belt = name, speed = belt.speed, item = item, recipe = recipe, tech = tech }
      end
    end
  end
  table.sort(result, function(a, b)
    if a.speed ~= b.speed then return a.speed < b.speed end
    return a.belt < b.belt
  end)
  return result
end

return M
