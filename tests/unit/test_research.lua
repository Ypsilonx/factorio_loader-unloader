--- Jednotkové testy surovin receptu a výzkumu tierů (prerekvizity, náhrady chybějících předmětů, cena).
local A = require("assert")
local research = require("prototypes.research")
local tiers = require("prototypes.tiers")

--- Rychlost žlutého pásu.
local Y = tiers.YELLOW_SPEED

--- Testovací data.raw ve tvaru vanilla 2.0 (zkrácený strom výzkumů).
--- @param drop table|nil množina předmětů, které „mod odstranil“
local function vanilla(drop)
  drop = drop or {}
  local raw = { item = {}, recipe = {}, technology = {} }
  --- Přidá předmět s receptem; tech = výzkum, který recept odemyká (nil = od začátku).
  local function item(name, tech)
    if drop[name] then return end
    raw.item[name] = { name = name }
    raw.recipe[name] = { name = name, enabled = tech == nil, results = { { type = "item", name = name, amount = 1 } } }
    if tech then
      local effects = raw.technology[tech].effects
      effects[#effects + 1] = { type = "unlock-recipe", recipe = name }
    end
  end
  --- Přidá výzkum.
  local function tech(name, prerequisites, packs, count)
    local ingredients = {}
    for i = 1, packs do ingredients[i] = { "pack-" .. i, 1 } end
    raw.technology[name] = { name = name, prerequisites = prerequisites, effects = {},
                             unit = { count = count, time = 30, ingredients = ingredients } }
  end
  tech("steel-processing", {}, 1, 50)
  tech("fast-inserter", {}, 1, 30)
  tech("logistics-2", {}, 2, 200)
  tech("advanced-circuit", { "logistics-2" }, 2, 200)
  tech("bulk-inserter", { "fast-inserter", "logistics-2", "advanced-circuit" }, 2, 150)
  tech("processing-unit", { "advanced-circuit" }, 3, 300)
  tech("logistics-3", { "logistics-2" }, 4, 300)
  item("transport-belt")
  item("iron-plate")
  item("electronic-circuit")
  item("inserter")
  item("steel-plate", "steel-processing")
  item("fast-inserter", "fast-inserter")
  item("fast-transport-belt", "logistics-2")
  item("advanced-circuit", "advanced-circuit")
  item("bulk-inserter", "bulk-inserter")
  item("processing-unit", "processing-unit")
  item("express-transport-belt", "logistics-3")
  return raw
end

--- Najde surovinu podle jména.
local function amount(ingredients, name)
  for _, ingredient in ipairs(ingredients) do
    if ingredient.name == name then return ingredient.amount end
  end
end

--- Množina prvků pole.
local function set(list)
  local s = {}
  for _, value in ipairs(list) do s[value] = true end
  return s
end

--- Přidá do raw hotový tier (předmět, recept a výzkum) tak, jak to dělá recipe.lua.
local function add_tier(raw, name, ingredients, tech)
  raw.item[name] = { name = name }
  raw.recipe[name] = { name = name, enabled = tech == nil, results = { { type = "item", name = name, amount = 1 } } }
  if tech then
    raw.technology[name] = { name = name, prerequisites = tech.prerequisites, unit = tech.unit,
                             effects = { { type = "unlock-recipe", recipe = name } } }
  end
end

return {
  { "suroviny tieru 1: bulk inserter, ocel, obvody, pásy", function()
    local list = research.ingredients(vanilla(), Y, "transport-belt", nil)
    A.eq(amount(list, "transport-belt"), 2, "pásy")
    A.eq(amount(list, "bulk-inserter"), 1, "bulk inserter")
    A.eq(amount(list, "steel-plate"), 5, "ocel")
    A.eq(amount(list, "electronic-circuit"), 10, "obvody")
  end },
  { "vyšší tier obsahuje předchozí, nejrychlejší pásy poslední úroveň", function()
    local list = research.ingredients(vanilla(), 8 * Y, "express-transport-belt", "storage-optimizer-x")
    A.eq(amount(list, "storage-optimizer-x"), 1, "předchozí tier")
    A.eq(amount(list, "processing-unit"), 5, "poslední úroveň")
  end },
  { "úroveň surovin podle rychlosti pásu, ne pořadí tieru (Bob's basic pás)", function()
    A.eq(research.level(Y / 2), 1, "basic (0,5×)")
    A.eq(research.level(Y), 1, "žlutý")
    A.eq(research.level(2 * Y), 2, "červený")
    A.eq(research.level(2 * Y + 1e-9), 2, "červený se zaokrouhlením")
    A.eq(research.level(3 * Y), 3, "modrý")
    A.eq(research.level(4 * Y), 3, "turbo")
  end },
  { "chybějící předmět nahradí další kandidát, žádný kandidát = vynechat", function()
    local raw = vanilla({ ["bulk-inserter"] = true, ["steel-plate"] = true })
    local list = research.ingredients(raw, Y, "transport-belt", nil)
    A.eq(amount(list, "bulk-inserter"), nil, "odstraněný bulk inserter")
    A.eq(amount(list, "fast-inserter"), 1, "náhrada fast inserter")
    A.eq(amount(list, "iron-plate"), 5, "náhrada železo")
    raw.item["electronic-circuit"] = nil
    A.eq(amount(research.ingredients(raw, Y, "transport-belt", nil), "electronic-circuit"), nil, "bez náhrady")
  end },
  { "stejné předměty se sloučí", function()
    local list = research.ingredients(vanilla(), Y, "steel-plate", nil)
    A.eq(amount(list, "steel-plate"), 7, "2 jako „pás“ + 5 jako ocel")
    local names = 0
    for _, ingredient in ipairs(list) do
      if ingredient.name == "steel-plate" then names = names + 1 end
    end
    A.eq(names, 1, "jediná položka")
  end },
  { "tier 1: prerekvizita bulk inserter, nadbytečné vynechá", function()
    local raw = vanilla()
    local tech = research.technology(raw, nil, research.ingredients(raw, Y, "transport-belt", nil), "transport-belt")
    local p = set(tech.prerequisites)
    A.truthy(p["bulk-inserter"], "bulk-inserter")
    A.truthy(p["steel-processing"], "steel-processing (není v bulk-inserter)")
    A.eq(#tech.prerequisites, 2, "jen nezbytné")
    A.eq(tech.unit.count, 225, "1,5 × 150")
    A.eq(#tech.unit.ingredients, 2, "druhy vědy z bulk-inserter")
  end },
  { "tier 2 nejde vyzkoumat dřív než tier 1, i když jeho pás ano", function()
    local raw = vanilla()
    local t1 = research.technology(raw, nil, research.ingredients(raw, Y, "transport-belt", nil), "transport-belt")
    add_tier(raw, "storage-optimizer-transport-belt", {}, t1)
    local ingredients = research.ingredients(raw, 2 * Y, "fast-transport-belt", "storage-optimizer-transport-belt")
    local t2 = research.technology(raw, "logistics-2", ingredients, "fast-transport-belt")
    local p = set(t2.prerequisites)
    A.truthy(p["storage-optimizer-transport-belt"], "výzkum tieru 1")
    A.eq(p["logistics-2"], nil, "logistics-2 plyne z tieru 1")
    A.eq(t2.unit.count, 300, "základ z cizích výzkumů (200), ne z tieru 1")
  end },
  { "vše od začátku = bez výzkumu", function()
    local raw = { item = { a = {}, b = {} }, technology = {},
                  recipe = { a = { enabled = true, results = { { name = "a" } } } } }
    A.eq(research.technology(raw, nil, { { name = "a", amount = 1 }, { name = "b", amount = 1 } }, "a"), nil,
      "bez prerekvizit")
  end },
  { "prerekvizity bez vědy → spouštěč vyrobením pásu", function()
    local raw = { item = { a = {} }, recipe = { a = { results = { { name = "a" } } } },
                  technology = { t = { effects = { { type = "unlock-recipe", recipe = "a" } },
                                       research_trigger = { type = "mine-entity", entity = "x" } } } }
    local tech = research.technology(raw, "t", { { name = "a", amount = 1 } }, "belt")
    A.eq(tech.unit, nil, "bez jednotky")
    A.eq(tech.research_trigger.item, "belt", "vyrobit pás")
  end },
  { "skrytý recept (recyklace) nečiní předmět dostupným od začátku", function()
    local raw = vanilla()
    raw.recipe["x-recycling"] = { hidden = true, enabled = true,
                                  results = { { type = "item", name = "advanced-circuit", amount = 1 } } }
    local _, tech = tiers.item_source(raw, "advanced-circuit")
    A.eq(tech, "advanced-circuit", "výzkum zůstává")
  end },
  { "z alternativních receptů vyhraje výzkum s nejméně prerekvizitami", function()
    local raw = vanilla()
    raw.recipe["advanced-circuit-alt"] = { enabled = false,
                                           results = { { type = "item", name = "advanced-circuit", amount = 1 } } }
    table.insert(raw.technology["fast-inserter"].effects, { type = "unlock-recipe", recipe = "advanced-circuit-alt" })
    local recipe, tech = tiers.item_source(raw, "advanced-circuit")
    A.eq(recipe, "advanced-circuit-alt", "recept")
    A.eq(tech, "fast-inserter", "dřívější výzkum")
  end },
}
