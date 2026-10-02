--- Čistá logika receptu a výzkumu tierů: suroviny s náhradami pro mody, které předměty odstraní, a vlastní
--- výzkum s prerekvizitami dopočítanými z toho, co recept potřebuje. Díky tomu sedí i na stromy výzkumů
--- přeskládané overhaul mody (Pyanodon, Bob's, Krastorio …).
--- Nepoužívá globály Factoria, aby šla testovat mimo hru (tests/unit/test_research.lua).
local tiers = require("prototypes.tiers")

local M = {}

--- Prefix jmen tierů; jejich výzkumy se nepočítají do základu ceny dalšího tieru (cena by rostla geometricky).
M.PREFIX = "storage-optimizer-"
--- Kolik pásů daného tieru recept obsahuje. Laditelná hodnota.
M.BELTS_PER_TIER = 2
--- Horní meze rychlosti pásu (v násobcích žlutého) pro úrovně surovin: do 1× úroveň 1, do 2× úroveň 2, rychlejší
--- úroveň 3. Podle rychlosti, ne pořadí tieru – mody s pomalejším pásem (Bob's „basic“) by jinak úrovně posunuly.
--- Laditelná hodnota.
M.LEVEL_SPEEDS = { 1, 2 }
--- Suroviny navíc podle úrovně (viz LEVEL_SPEEDS). Každá surovina je
--- { kandidáti, počet } – použije se první kandidát, který ve hře existuje (mod ho mohl odstranit), žádný
--- = surovina se vynechá. Meziprodukty (ne rudy a pláty navíc) zajistí, že overhaul mod recept sám zdraží.
--- Laditelné hodnoty.
M.LEVELS = {
  {
    { { "bulk-inserter", "fast-inserter", "inserter" }, 1 },
    { { "steel-plate", "iron-plate" }, 5 },
    { { "electronic-circuit" }, 10 },
  },
  {
    { { "advanced-circuit", "electronic-circuit" }, 10 },
    { { "steel-plate", "iron-plate" }, 10 },
  },
  {
    { { "processing-unit", "advanced-circuit", "electronic-circuit" }, 5 },
    { { "steel-plate", "iron-plate" }, 10 },
  },
}
--- Násobič počtu jednotek výzkumu proti nejdražší přímé prerekvizitě (mimo vlastní tiery). Laditelná hodnota.
M.TECH_COUNT_MULTIPLIER = 1.5

--- Vrátí klíče množiny seřazené abecedně (deterministické pořadí).
local function sorted(set)
  local list = {}
  for key in pairs(set) do list[#list + 1] = key end
  table.sort(list)
  return list
end

--- Úroveň surovin podle rychlosti pásu.
--- @param speed number rychlost pásu (dlaždice/tick)
--- @return integer index do LEVELS
function M.level(speed)
  for index, limit in ipairs(M.LEVEL_SPEEDS) do
    -- Tolerance kvůli zaokrouhlení rychlostí v modech (např. 0.0625000001).
    if speed <= limit * tiers.YELLOW_SPEED * 1.001 then return index end
  end
  return #M.LEVEL_SPEEDS + 1
end

--- Sestaví suroviny receptu tieru; stejné předměty sloučí (Factorio duplicitní suroviny odmítne).
--- @param raw table data.raw
--- @param speed number rychlost pásu tieru
--- @param belt_item string předmět pásu tieru
--- @param previous string|nil jméno předmětu předchozího tieru
--- @return table[] suroviny ve formátu receptu Factoria
function M.ingredients(raw, speed, belt_item, previous)
  local list, index = {}, {}
  --- Přidá surovinu, případně připočte k už přidané.
  local function add(name, amount)
    if index[name] then
      index[name].amount = index[name].amount + amount
    else
      index[name] = { type = "item", name = name, amount = amount }
      list[#list + 1] = index[name]
    end
  end
  if previous then add(previous, 1) end
  add(belt_item, M.BELTS_PER_TIER)
  for _, spec in ipairs(M.LEVELS[M.level(speed)]) do
    for _, candidate in ipairs(spec[1]) do
      if raw.item[candidate] then
        add(candidate, spec[2])
        break
      end
    end
  end
  return list
end

--- Vybere z výzkumů ten, jehož jednotku převezme výzkum tieru: s nejvíc druhy vědy, při shodě s vyšším
--- počtem. Druhy vědy z jednoho existujícího výzkumu zaručí, že je laboratoř umí zpracovat i v modech
--- s více druhy laboratoří.
--- @return table|nil unit vybraného výzkumu
local function template_unit(raw, techs)
  local best
  for _, name in ipairs(techs) do
    local unit = raw.technology[name].unit
    if unit and unit.count then
      if not best or #unit.ingredients > #best.ingredients
        or (#unit.ingredients == #best.ingredients and unit.count > best.count) then
        best = unit
      end
    end
  end
  return best
end

--- Hloubková kopie tabulky (data stage má table.deepcopy, unit testy ne).
local function copy(t)
  if type(t) ~= "table" then return t end
  local out = {}
  for key, value in pairs(t) do out[key] = copy(value) end
  return out
end

--- Spočítá výzkum tieru: prerekvizity = výzkumy pásu a všech surovin (včetně předchozího tieru),
--- zbavené těch, které už plynou z jiné prerekvizity.
--- @param raw table data.raw (s už přidaným předchozím tierem)
--- @param belt_tech string|nil výzkum pásu tieru
--- @param ingredients table[] suroviny receptu tieru
--- @param trigger_item string předmět, jehož vyrobení výzkum odemkne, když prerekvizity nemají vědu
--- @return table|nil { prerequisites, unit | research_trigger }; nil = recept je dostupný od začátku
function M.technology(raw, belt_tech, ingredients, trigger_item)
  local direct = {}
  if belt_tech then direct[belt_tech] = true end
  for _, ingredient in ipairs(ingredients) do
    local _, tech = tiers.item_source(raw, ingredient.name)
    if tech then direct[tech] = true end
  end
  local names = sorted(direct)
  if #names == 0 then return nil end

  local implied = {}
  for _, name in ipairs(names) do
    for prerequisite in pairs(tiers.tech_closure(raw, name)) do implied[prerequisite] = true end
  end
  local prerequisites, foreign = {}, {}
  for _, name in ipairs(names) do
    if not implied[name] then prerequisites[#prerequisites + 1] = name end
    if name:sub(1, #M.PREFIX) ~= M.PREFIX then foreign[#foreign + 1] = name end
  end

  local result = { prerequisites = prerequisites }
  local base = template_unit(raw, foreign)
  if base then
    result.unit = copy(base)
    local max_count = 0
    for _, name in ipairs(foreign) do
      local unit = raw.technology[name].unit
      if unit and unit.count and unit.count > max_count then max_count = unit.count end
    end
    result.unit.count = math.ceil(max_count * M.TECH_COUNT_MULTIPLIER)
  elseif template_unit(raw, names) then
    -- Jen předchozí tier má vědu (pás i suroviny jsou od začátku): převezme ji beze změny.
    result.unit = copy(template_unit(raw, names))
  else
    -- Prerekvizity bez vědy (spouštěcí výzkumy Space Age, mody): odemkne se vyrobením pásu tieru.
    result.research_trigger = { type = "craft-item", item = trigger_item }
  end
  return result
end

return M
