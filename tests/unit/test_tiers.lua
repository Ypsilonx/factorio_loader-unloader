--- Jednotkové testy výběru pásů a výpočtu parametrů tierů.
local A = require("assert")
local tiers = require("prototypes.tiers")

--- Sestaví testovací náhradu data.raw s pásy zadanými jako { jméno = { speed, hidden?, enabled?, tech? } }.
local function fake_raw(belts)
  local raw = { ["transport-belt"] = {}, item = {}, recipe = {}, technology = {} }
  for name, b in pairs(belts) do
    raw["transport-belt"][name] = { name = name, speed = b.speed, hidden = b.hidden }
    raw.item[name] = { name = name, place_result = name }
    raw.recipe[name] = { name = name, enabled = b.enabled, results = { { type = "item", name = name, amount = 1 } } }
    if b.tech then
      raw.technology[b.tech] = { name = b.tech, effects = { { type = "unlock-recipe", recipe = name } } }
    end
  end
  return raw
end

return {
  { "interval vanilla pásů", function()
    A.eq(tiers.interval_ticks(0.03125, 1), 60, "žlutý")
    A.eq(tiers.interval_ticks(0.0625, 1), 30, "červený")
    A.eq(tiers.interval_ticks(0.09375, 1), 20, "modrý")
    A.eq(tiers.interval_ticks(0.125, 1), 15, "turbo")
  end },
  { "interval s násobičem a spodní mez", function()
    A.eq(tiers.interval_ticks(0.03125, 2), 120, "násobič 2")
    A.eq(tiers.interval_ticks(100, 0.1), 1, "minimum 1 tick")
  end },
  { "cena přesunu: 50 kJ + 5 kJ za každý další stack, nezávisle na tieru", function()
    A.eq(tiers.transfer_cost_kj(1, 1), 50, "1 stack")
    A.eq(tiers.transfer_cost_kj(5, 1), 70, "5 stacků")
    A.eq(tiers.transfer_cost_kj(20, 1), 145, "20 stacků")
    A.eq(tiers.transfer_cost_kj(5, 2), 140, "násobič spotřeby 2")
    A.eq(tiers.transfer_cost_kj(5, 0), 0, "násobič spotřeby 0")
  end },
  { "zásobník pojme dva nejdražší přesuny", function()
    A.eq(tiers.buffer_kj(20, 1), 290, "2 × 145 kJ")
    A.eq(tiers.buffer_kj(20, 0), 0.001, "nulová spotřeba → minimální zásobník")
  end },
  { "dobíjení stihne nejdražší přesun každý interval", function()
    A.eq(tiers.input_flow_kw(20, 1, 60), 145, "145 kJ za 1 s")
    A.eq(tiers.input_flow_kw(20, 1, 15), 580, "145 kJ za 0,25 s")
  end },
  { "řazení podle rychlosti", function()
    local list = tiers.collect(fake_raw({
      fast = { speed = 0.0625, tech = "t2" },
      slow = { speed = 0.03125 },
      express = { speed = 0.09375, tech = "t3" },
    }))
    A.eq(#list, 3, "počet")
    A.eq(list[1].belt, "slow", "1.")
    A.eq(list[2].belt, "fast", "2.")
    A.eq(list[3].belt, "express", "3.")
    A.eq(list[2].tech, "t2", "výzkum")
    A.eq(list[1].tech, nil, "pás dostupný od začátku nemá výzkum")
  end },
  { "vyřazení skrytých a nedostupných pásů", function()
    local list = tiers.collect(fake_raw({
      ok = { speed = 0.03125 },
      hidden = { speed = 0.0625, hidden = true },
      locked = { speed = 0.09375, enabled = false },
    }))
    A.eq(#list, 1, "zbyde jen dostupný")
    A.eq(list[1].belt, "ok", "jméno")
  end },
  { "stejně rychlá varianta s pozdějším výzkumem nepředběhne hlavní pás (regrese Tenebris Prime)", function()
    local raw = fake_raw({
      belt = { speed = 0.03125 },
      ["a-glowing-belt"] = { speed = 0.03125, tech = "late" },
      fast = { speed = 0.0625, tech = "t2" },
      ["a-glowing-fast"] = { speed = 0.0625000001, tech = "late-fast" },
    })
    raw.technology["late"].prerequisites = { "t2" }
    raw.technology["late-fast"].prerequisites = { "late" }
    local list = tiers.collect(raw)
    A.eq(#list, 4, "varianty zůstávají jako tiery")
    A.eq(list[1].belt, "belt", "hlavní pás je dostupný od začátku, ne první podle abecedy")
    A.eq(list[1].variant_of, nil, "hlavní pás")
    A.eq(list[2].variant_of, "belt", "varianta visí na hlavním pásu své rychlosti")
    A.eq(list[3].belt, "fast", "druhý hlavní pás")
    A.eq(list[4].variant_of, "fast", "rychlost se shoduje i se zaokrouhlením")
  end },
  { "vanilla: řetěz podle rychlosti, upgrade vede na další tier", function()
    local raw = fake_raw({
      belt = { speed = 0.03125 },
      fast = { speed = 0.0625, tech = "logistics-2" },
      express = { speed = 0.09375, tech = "logistics-3" },
    })
    raw.technology["logistics-3"].prerequisites = { "logistics-2" }
    local list = tiers.collect(raw)
    A.eq(list[1].previous, nil, "první tier bez předchůdce")
    A.eq(list[2].previous, "belt", "fast z belt")
    A.eq(list[3].previous, "fast", "express z fast")
    A.eq(list[1].next_upgrade, "fast", "upgrade belt")
    A.eq(list[2].next_upgrade, "express", "upgrade fast")
    A.eq(list[3].next_upgrade, nil, "poslední bez upgradu")
  end },
  { "rychlejší pás s vlastní větví výzkumu nečeká na cizí pomalejší pás (regrese UBSA + Planetaris)", function()
    -- Turbo je až po Vulcanu, ultra-fast (UBSA) jen za logistics-3, hyper (Arig/Hyarion) za turbem.
    local raw = fake_raw({
      express = { speed = 0.09375, tech = "logistics-3" },
      turbo = { speed = 0.125, tech = "turbo-tech" },
      hyper = { speed = 0.15625, tech = "hyper-tech" },
      ultra = { speed = 0.1875, tech = "ultra-tech" },
      extreme = { speed = 0.28125, tech = "extreme-tech" },
    })
    raw.technology["turbo-tech"].prerequisites = { "logistics-3", "metallurgic-science" }
    raw.technology["metallurgic-science"] = { name = "metallurgic-science" }
    raw.technology["hyper-tech"].prerequisites = { "turbo-tech", "polishing-science" }
    raw.technology["polishing-science"] = { name = "polishing-science" }
    raw.technology["ultra-tech"].prerequisites = { "logistics-3" }
    raw.technology["extreme-tech"].prerequisites = { "ultra-tech" }
    local by_belt = {}
    for _, info in ipairs(tiers.collect(raw)) do by_belt[info.belt] = info end
    A.eq(by_belt.turbo.previous, "express", "turbo z express")
    A.eq(by_belt.hyper.previous, "turbo", "hyper z turbo")
    A.eq(by_belt.ultra.previous, "express", "ultra přeskočí turbo i hyper")
    A.eq(by_belt.extreme.previous, "ultra", "extreme ve větvi UBSA")
    A.eq(by_belt.express.next_upgrade, "ultra", "z větví vede upgrade do dostupné nejdřív")
    A.eq(by_belt.ultra.next_upgrade, "extreme", "upgrade ve větvi UBSA")
    A.eq(by_belt.hyper.next_upgrade, nil, "hyper je konec větve")
  end },
  { "pás bez dřív dostupného pomalejšího tieru začíná vlastní strom", function()
    local raw = fake_raw({
      slow = { speed = 0.03125, tech = "a" },
      fast = { speed = 0.0625, tech = "b" },
    })
    local list = tiers.collect(raw)
    A.eq(list[2].previous, nil, "nezávislé výzkumy → bez předchůdce")
    A.eq(list[1].next_upgrade, nil, "bez upgradu")
  end },
  { "pomalejší pás jako surovina receptu je dostupný dřív i bez prerekvizit (regrese Pyanodon)", function()
    -- Py doplňuje prerekvizity až v pypostprocessing po nás; logistics-3 je v naší fázi bez prerekvizit.
    local raw = fake_raw({
      belt = { speed = 0.03125 },
      fast = { speed = 0.0625, tech = "logistics-2" },
      express = { speed = 0.09375, tech = "logistics-3" },
    })
    raw.recipe.express.ingredients = { { type = "item", name = "fast", amount = 1 },
      { type = "fluid", name = "lubricant", amount = 10 } }
    local list = tiers.collect(raw)
    A.eq(list[3].previous, "fast", "express z fast díky surovině receptu")
    A.eq(list[2].next_upgrade, "express", "upgrade fast")
  end },
  { "pás bez předmětu nebo receptu se vyřadí", function()
    local raw = fake_raw({ a = { speed = 0.03125 } })
    raw["transport-belt"].orphan = { name = "orphan", speed = 0.0625 }
    A.eq(#tiers.collect(raw), 1, "orphan vynechán")
  end },
}
