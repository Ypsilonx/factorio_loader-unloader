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
  { "pás bez předmětu nebo receptu se vyřadí", function()
    local raw = fake_raw({ a = { speed = 0.03125 } })
    raw["transport-belt"].orphan = { name = "orphan", speed = 0.0625 }
    A.eq(#tiers.collect(raw), 1, "orphan vynechán")
  end },
}
