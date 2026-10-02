--- Integrační testy přesunu. Většina používá testovací pás (interval 15 t), aby byly rychlé.
--- Rozložení: zdroj (0,0) – optimizer (0,1) se směrem sever – cíl (0,2).
local H = require("helpers")

local BELT = "so-test-belt"

--- Stav entity přes remote rozhraní modu.
local function state(entity)
  return remote.call("storage-optimizer", "get_state", entity.unit_number)
end

--- Standardní rozložení s napájením; uloží do ctx zdroj (a), optimizer (m) a cíl (b).
local function layout(ctx, source_items, target_name)
  H.power(ctx)
  ctx.a = H.chest(ctx, "iron-chest", 0, 0, source_items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, target_name or "iron-chest", 0, 2)
end

return {
  {
    name = "přesun celých dávek",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 250 } }) end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 200, "cíl")
      H.eq(H.count(ctx.a, "iron-plate"), 50, "zbytek ve zdroji")
      H.eq(state(ctx.m), "waiting", "stav")
    end } },
  },
  {
    name = "všechno, nebo nic",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 300 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      -- Dřevěná bedna (16 slotů): 15 slotů kamene + 50 železa → místo jen pro 50 železa.
      ctx.b = H.chest(ctx, "wooden-chest", 0, 2, { { name = "stone", count = 750 }, { name = "iron-plate", count = 50 } })
    end,
    steps = {
      { ticks = 100, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 50, "cíl beze změny")
        H.eq(H.count(ctx.a, "iron-plate"), 300, "zdroj beze změny")
        ctx.b.get_inventory(defines.inventory.chest).remove({ name = "iron-plate", count = 50 })
      end },
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 100, "po uvolnění místa jedna dávka")
        H.eq(H.count(ctx.a, "iron-plate"), 200, "zdroj")
      end },
    },
  },
  {
    name = "bez proudu",
    setup = function(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "iron-chest", 0, 2)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl")
      H.eq(state(ctx.m), "no_power", "stav")
    end } },
  },
  {
    name = "engine entitu nepočítá (UPS)",
    setup = function(ctx) layout(ctx, {}) end,
    steps = { { ticks = 2, run = function(ctx) H.eq(ctx.m.disabled_by_script, true, "disabled_by_script") end } },
  },
  {
    name = "výpadek proudu zastaví přesun",
    setup = function(ctx)
      ctx.pole = H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 3000 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
    end,
    steps = {
      { ticks = 40, run = function(ctx)
        H.truthy(H.count(ctx.b, "iron-plate") > 0, "s proudem přesouvá")
        ctx.pole.destroy()
      end },
      -- Zásobník pojme energii na 20 stacků (limit z nastavení); po jejím vyčerpání musí přesun stát.
      { ticks = 400, run = function(ctx) ctx.after = H.count(ctx.b, "iron-plate") end },
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), ctx.after, "bez proudu nic dalšího")
        H.eq(state(ctx.m), "no_power", "stav")
      end },
    },
  },
  {
    name = "probuzení po postavení cílové bedny",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
    end,
    steps = {
      { ticks = 30, run = function(ctx)
        H.eq(state(ctx.m), "no_chest", "stav bez cíle")
        ctx.b = H.chest(ctx, "iron-chest", 0, 2)
      end },
      { ticks = 40, run = function(ctx) H.eq(H.count(ctx.b, "iron-plate"), 100, "cíl po probuzení") end },
    },
  },
  {
    name = "zánik a obnova cílové bedny",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 1000 } }) end,
    steps = {
      { ticks = 40, run = function(ctx)
        H.truthy(H.count(ctx.b, "iron-plate") > 0, "něco přesunuto")
        ctx.b.destroy({ raise_destroy = true })
      end },
      { ticks = 40, run = function(ctx)
        H.eq(state(ctx.m), "no_chest", "stav po zániku")
        ctx.b = H.chest(ctx, "iron-chest", 0, 2)
      end },
      { ticks = 40, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "přesun po obnově") end },
    },
  },
  {
    name = "velký sklad 3×3 postavený později",
    setup = function(ctx)
      H.power(ctx)
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "iron-chest", 0, 2)
    end,
    steps = {
      { ticks = 20, run = function(ctx)
        -- Střed skladu na (0,-1) → pokrývá dlaždice x -1..1, y -2..0 včetně zdrojové (0,0).
        ctx.a = H.chest(ctx, "so-test-warehouse", 0, -1, { { name = "iron-plate", count = 500 } })
      end },
      { ticks = 40, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "přesun ze skladu") end },
    },
  },
  {
    name = "rotace prohodí zdroj a cíl",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 200 } }) end,
    steps = {
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 200, "tam")
        ctx.m.rotate()
        ctx.m.rotate()
      end },
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.a, "iron-plate"), 200, "zpět")
        H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl prázdný")
      end },
    },
  },
  {
    name = "zbourání optimizeru",
    setup = function(ctx) layout(ctx, {}) end,
    steps = {
      { ticks = 5, run = function(ctx)
        ctx.before = remote.call("storage-optimizer", "count")
        ctx.m.destroy({ raise_destroy = true })
      end },
      { ticks = 5, run = function(ctx)
        H.eq(remote.call("storage-optimizer", "count"), ctx.before - 1, "počet v registru")
      end },
    },
  },
  {
    name = "soused není bedna",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      H.place(ctx, "transport-belt", 0, 2)
    end,
    steps = { { ticks = 30, run = function(ctx)
      H.eq(state(ctx.m), "no_chest", "stav")
      H.eq(H.count(ctx.a, "iron-plate"), 100, "zdroj beze změny")
    end } },
  },
  {
    name = "logistická bedna",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "passive-provider-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "storage-chest", 0, 2)
    end,
    steps = { { ticks = 40, run = function(ctx) H.eq(H.count(ctx.b, "iron-plate"), 100, "cíl") end } },
  },
  {
    name = "předmět s daty (brnění s mřížkou)",
    setup = function(ctx)
      layout(ctx, {})
      local inv = ctx.a.get_inventory(defines.inventory.chest)
      inv.insert({ name = "modular-armor", count = 1 })
      inv[1].grid.put({ name = "solar-panel-equipment" })
    end,
    steps = { { ticks = 40, run = function(ctx)
      local stack = ctx.b.get_inventory(defines.inventory.chest).find_item_stack("modular-armor")
      H.truthy(stack, "brnění v cíli")
      H.eq(stack.grid and stack.grid.count("solar-panel-equipment"), 1, "vybavení zachováno")
    end } },
  },
  {
    name = "zachování kvality",
    requires = "quality",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 100, quality = "uncommon" } }) end,
    steps = { { ticks = 40, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate", "uncommon"), 100, "uncommon v cíli")
      H.eq(H.count(ctx.b, "iron-plate", "normal"), 0, "žádné normal")
    end } },
  },
  {
    name = "zachování čerstvosti",
    requires = "space-age",
    setup = function(ctx) layout(ctx, { { name = "yumako", count = 50, spoil_percent = 0.5 } }) end,
    steps = { { ticks = 40, run = function(ctx)
      local stack = ctx.b.get_inventory(defines.inventory.chest).find_item_stack("yumako")
      H.truthy(stack, "yumako v cíli")
      H.truthy(stack.spoil_percent > 0.45, "čerstvost zachována (" .. tostring(stack.spoil_percent) .. ")")
    end } },
  },
}
