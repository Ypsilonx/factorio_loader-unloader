--- Integrační testy přepínače „Přesouvat i zbytky“ (neúplný přesun, místo v cíli, poměrná energie, blueprint).
local H = require("helpers")

local BELT = "so-test-belt"
local MOVER = "storage-optimizer-" .. BELT

--- Rozložení zdroj (0,0) – optimizer (0,1) – cíl (0,2) s napájením; 3 stacky za přesun, zbytky zapnuté.
--- @return LuaEntity rozvodna
local function layout(ctx, items, target)
  local pole = H.power(ctx)
  ctx.a = H.chest(ctx, "steel-chest", 0, 0, items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, target or "steel-chest", 0, 2)
  remote.call("storage-optimizer", "set_stacks", ctx.m.unit_number, 3)
  remote.call("storage-optimizer", "set_leftovers", ctx.m.unit_number, true)
  return pole
end

return {
  {
    name = "zbytky: zdroj se vyprázdní",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 250 } })
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 250, "250 < 300, přesto přesunuto vše")
      H.eq(H.count(ctx.a, "iron-plate"), 0, "zdroj prázdný")
    end } },
  },
  {
    name = "zbytky: celé přesuny mají přednost, zbytek dojede",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 700 } })
    end,
    steps = { { ticks = 200, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 700, "2 × 300 + zbytek 100")
      H.eq(H.count(ctx.a, "iron-plate"), 0, "zdroj prázdný")
    end } },
  },
  {
    name = "zbytky: cíl s místem jen na část přesunu",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 500 } }, "wooden-chest")
      -- Dřevěná bedna má 16 slotů; 15 obsadit mědí → místo na jeden stack železa.
      ctx.b.insert({ name = "copper-plate", count = 1500 })
    end,
    steps = { { ticks = 120, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 100, "doplněn jen volný slot")
      H.eq(H.count(ctx.a, "iron-plate"), 400, "zbytek zůstal ve zdroji")
    end } },
  },
  {
    name = "zbytky: vypnuté = všechno, nebo nic",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 250 } })
      remote.call("storage-optimizer", "set_leftovers", ctx.m.unit_number, false)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "250 < 300 → nic")
      H.eq(remote.call("storage-optimizer", "get_leftovers", ctx.m.unit_number), false, "přepínač vypnutý")
    end } },
  },
  {
    name = "zbytky: poměrná energie neúplného přesunu",
    setup = function(ctx)
      ctx.pole = layout(ctx, {})
    end,
    steps = {
      { ticks = 60, run = function(ctx)
        -- Zásobník je plný; odpojit proud a dát 1,5 stacku.
        ctx.pole.destroy()
        ctx.before = ctx.m.energy
        ctx.a.insert({ name = "iron-plate", count = 150 })
      end },
      { ticks = 40, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 150, "přesunut zbytek 1,5 stacku")
        H.eq(math.floor(ctx.before - ctx.m.energy + 0.5), 52500, "50 kJ + 0,5 × 5 kJ")
      end },
    },
  },
  {
    name = "zbytky z tagů blueprintu",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 50 } })
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
      local ghost = ctx.surface.create_entity({
        name = "entity-ghost",
        inner_name = MOVER,
        position = { ctx.origin.x + 0.5, ctx.origin.y + 1.5 },
        force = "player",
        tags = { so_leftovers = true },
      })
      local _, entity = ghost.revive({ raise_revive = true })
      ctx.m = entity
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_leftovers", ctx.m.unit_number), true, "zbytky z tagu")
      H.eq(H.count(ctx.b, "iron-plate"), 50, "neúplný stack přesunut")
    end } },
  },
}
