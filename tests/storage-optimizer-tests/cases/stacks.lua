--- Integrační testy počtu stacků za jeden přesun (násobek dávky, limit, energie, signál, blueprint).
local H = require("helpers")

local BELT = "so-test-belt"
local MOVER = "storage-optimizer-" .. BELT

--- Rozložení zdroj (0,0) – optimizer (0,1) – cíl (0,2) s napájením; vrací rozvodnu.
local function layout(ctx, items)
  local pole = H.power(ctx)
  ctx.a = H.chest(ctx, "steel-chest", 0, 0, items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, "steel-chest", 0, 2)
  return pole
end

--- Nastaví počet stacků přes remote rozhraní.
local function set_stacks(ctx, count)
  remote.call("storage-optimizer", "set_stacks", ctx.m.unit_number, count)
end

return {
  {
    name = "přesun 3 stacků naráz",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 700 } })
      set_stacks(ctx, 3)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 600, "dva přesuny po 3 × 100")
      H.eq(H.count(ctx.a, "iron-plate"), 100, "zbytek menší než 3 stacky")
    end } },
  },
  {
    name = "všechno, nebo nic pro celý násobek",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 250 } })
      set_stacks(ctx, 3)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "250 < 300 → nic")
      H.eq(H.count(ctx.a, "iron-plate"), 250, "zdroj beze změny")
    end } },
  },
  {
    name = "limit 20 stacků",
    setup = function(ctx)
      layout(ctx, {})
      set_stacks(ctx, 50)
    end,
    steps = { { ticks = 1, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_stacks", ctx.m.unit_number), 20, "omezeno na 20")
    end } },
  },
  {
    name = "zásobník energie na dva přesuny po 20 stacích",
    steps = { { ticks = 1, run = function()
      H.eq(prototypes.entity[MOVER].electric_energy_source_prototype.buffer_capacity, 290000, "2 × 145 kJ")
    end } },
  },
  {
    name = "energie za přesun: pevná cena + další stacky",
    setup = function(ctx)
      ctx.pole = layout(ctx, {})
      set_stacks(ctx, 3)
    end,
    steps = {
      { ticks = 60, run = function(ctx)
        -- Zásobník je plný; odpojit proud a dát přesně na jeden přesun.
        ctx.pole.destroy()
        ctx.before = ctx.m.energy
        ctx.a.insert({ name = "iron-plate", count = 300 })
      end },
      { ticks = 40, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 300, "jeden přesun 3 stacků")
        H.eq(math.floor(ctx.before - ctx.m.energy + 0.5), 60000, "spotřeba 50 kJ + 2 × 5 kJ")
      end },
    },
  },
  {
    name = "počet stacků ze signálu (zapnuto v panelu)",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 300 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "signal-N", count = 2 } })
      H.wire(cc, ctx.m)
      remote.call("storage-optimizer", "set_stacks_circuit", ctx.m.unit_number, true)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 200, "jeden přesun 2 stacků, zbytek 100 nestačí")
    end } },
  },
  {
    name = "efektivní počet stacků pro zobrazení v panelu",
    setup = function(ctx)
      layout(ctx, {})
      set_stacks(ctx, 3)
      ctx.cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "signal-N", count = 5 } })
      H.wire(ctx.cc, ctx.m)
    end,
    steps = {
      { ticks = 2, run = function(ctx)
        local count, signal = remote.call("storage-optimizer", "get_effective_stacks", ctx.m.unit_number)
        H.eq(count, 3, "bez zapnutí platí ruční nastavení")
        H.eq(signal, nil, "hodnota signálu se nezobrazuje")
        remote.call("storage-optimizer", "set_stacks_circuit", ctx.m.unit_number, true)
      end },
      { ticks = 2, run = function(ctx)
        local count, signal = remote.call("storage-optimizer", "get_effective_stacks", ctx.m.unit_number)
        H.eq(count, 5, "ze signálu")
        H.eq(signal, 5, "hodnota signálu")
        H.set_signal(ctx.cc, 1, { type = "virtual", name = "signal-N", count = 0 })
      end },
      { ticks = 2, run = function(ctx)
        local count, signal = remote.call("storage-optimizer", "get_effective_stacks", ctx.m.unit_number)
        H.eq(count, 3, "signál 0 → ruční nastavení")
        H.eq(signal, 0, "hodnota signálu 0")
      end },
    },
  },
  {
    name = "výchozí řídicí signály jsou S a N",
    setup = function(ctx) layout(ctx, {}) end,
    steps = { { ticks = 1, run = function(ctx)
      local behavior = ctx.m.get_or_create_control_behavior()
      H.eq(behavior.circuit_stack_control_signal.name, "signal-S", "velikost stacku: S")
      local _, signal = remote.call("storage-optimizer", "get_stacks_circuit", ctx.m.unit_number)
      H.eq(signal.name, "signal-N", "počet stacků: N")
    end } },
  },
  {
    name = "signál počtu stacků se bez zapnutí ignoruje",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 300 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "signal-N", count = 2 } })
      H.wire(cc, ctx.m)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 300, "po 1 stacku → přesune vše")
    end } },
  },
  {
    name = "vlastní řídicí signál počtu stacků",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 700 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "signal-A", count = 3 } })
      H.wire(cc, ctx.m)
      remote.call("storage-optimizer", "set_stacks_circuit", ctx.m.unit_number, true, { type = "virtual", name = "signal-A" })
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 600, "dva přesuny po 3 stacích")
    end } },
  },
  {
    name = "počet stacků z tagů blueprintu",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 500 } })
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
      local ghost = ctx.surface.create_entity({
        name = "entity-ghost",
        inner_name = MOVER,
        position = { ctx.origin.x + 0.5, ctx.origin.y + 1.5 },
        force = "player",
        tags = { so_stacks = 4, so_stacks_circuit = true, so_stacks_signal = { type = "virtual", name = "signal-B" } },
      })
      local _, entity = ghost.revive({ raise_revive = true })
      ctx.m = entity
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_stacks", ctx.m.unit_number), 4, "počet stacků z tagu")
      H.eq(H.count(ctx.b, "iron-plate"), 400, "jeden přesun 4 stacků")
      local circuit, signal = remote.call("storage-optimizer", "get_stacks_circuit", ctx.m.unit_number)
      H.eq(circuit, true, "počet stacků ze sítě z tagu")
      H.eq(signal and signal.name, "signal-B", "řídicí signál z tagu")
    end } },
  },
}
