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
    A.eq(tiers.interval_ticks(0.03125, 1), 120, "žlutý")
    A.eq(tiers.interval_ticks(0.0625, 1), 60, "červený")
    A.eq(tiers.interval_ticks(0.09375, 1), 40, "modrý")
    A.eq(tiers.interval_ticks(0.125, 1), 30, "turbo")
  end },
  { "interval s násobičem a spodní mez", function()
    A.eq(tiers.interval_ticks(0.03125, 2), 240, "násobič 2")
    A.eq(tiers.interval_ticks(100, 0.1), 1, "minimum 1 tick")
  end },
  { "energie za přesun: 50 kW × 2 s, nezávisle na tieru", function()
    A.eq(tiers.energy_per_transfer_kj(1), 100, "výchozí")
    A.eq(tiers.energy_per_transfer_kj(2), 200, "násobič spotřeby 2")
    A.eq(tiers.energy_per_transfer_kj(0), 0, "násobič spotřeby 0")
  end },
  { "zásobník pojme nejdražší přesun (max. počet stacků)", function()
    A.eq(tiers.buffer_kj(100, 20), 2000, "100 kJ × 20 stacků")
    A.eq(tiers.buffer_kj(0, 20), 0.001, "nulová spotřeba → minimální zásobník")
  end },
  { "dobíjení zásobníku stihne plné vytížení za jeden interval", function()
    A.eq(tiers.input_flow_kw(100, 20, 120), 1000, "2000 kJ za 2 s")
    A.eq(tiers.input_flow_kw(100, 20, 30), 4000, "2000 kJ za 0,5 s")
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
