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
    name = "zásobník energie na 20 stacků",
    steps = { { ticks = 1, run = function()
      H.eq(prototypes.entity[MOVER].electric_energy_source_prototype.buffer_capacity, 2000000, "2 MJ")
    end } },
  },
  {
    name = "energie za přesun × počet stacků",
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
        H.eq(math.floor(ctx.before - ctx.m.energy + 0.5), 300000, "spotřeba 3 × 100 kJ")
      end },
    },
  },
  {
    name = "počet stacků ze signálu",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 500 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "storage-optimizer-stacks", count = 2 } })
      H.wire(cc, ctx.m)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 400, "dva přesuny po 2 stacích")
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
        tags = { so_stacks = 4 },
      })
      local _, entity = ghost.revive({ raise_revive = true })
      ctx.m = entity
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_stacks", ctx.m.unit_number), 4, "počet stacků z tagu")
      H.eq(H.count(ctx.b, "iron-plate"), 400, "jeden přesun 4 stacků")
    end } },
  },
}
