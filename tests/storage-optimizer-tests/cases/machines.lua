--- Integrační testy montážních strojů a pecí: jako cíl plní vstup, jako zdroj bere z výstupu, palivo nechává být.
--- Rozložení: zdroj (0,0) – optimizer (0,1) se směrem sever – cíl na (0,2) a dál (stroj 3×3 se středem na (0,3)).
local H = require("helpers")

local BELT = "so-test-belt"

--- Počet kusů v inventáři stroje.
local function machine_count(entity, inventory, name)
  return entity.get_inventory(inventory).get_item_count(name)
end

return {
  {
    name = "montážní stroj jako cíl: plní vstup",
    setup = function(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 300 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.f = H.place(ctx, "assembling-machine-2", 0, 3)
      ctx.f.set_recipe("iron-gear-wheel")
      H.power(ctx)
    end,
    steps = { { ticks = 60, run = function(ctx)
      local moved = 300 - H.count(ctx.a, "iron-plate")
      H.truthy(moved >= 100 and moved % 100 == 0, "přesunuto po celých stacích (" .. moved .. ")")
      H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number) ~= "no_chest", true, "stroj uznán jako cíl")
    end } },
  },
  {
    name = "montážní stroj bez receptu: nic se nepřesune ani neztratí",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 300 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.f = H.place(ctx, "assembling-machine-2", 0, 3)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.a, "iron-plate"), 300, "zdroj beze změny")
      H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number), "waiting", "stav čeká")
    end } },
  },
  {
    name = "montážní stroj jako zdroj: bere z výstupu",
    setup = function(ctx)
      ctx.f = H.place(ctx, "assembling-machine-2", 0, -1) -- střed (0,-1) → pokrývá zdrojové políčko (0,0)
      ctx.f.set_recipe("iron-gear-wheel")
      ctx.f.get_inventory(defines.inventory.crafter_output).insert({ name = "iron-gear-wheel", count = 100 })
      ctx.f.get_inventory(defines.inventory.crafter_input).insert({ name = "iron-plate", count = 100 })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
      H.power(ctx)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-gear-wheel"), 100, "výrobky v bedně")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "ze vstupu stroje nic")
    end } },
  },
  {
    name = "pec jako cíl: ruda do vstupu, uhlí do paliva ne",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-ore", count = 50 }, { name = "coal", count = 50 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.f = H.place(ctx, "stone-furnace", 0, 2)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(machine_count(ctx.f, defines.inventory.crafter_input, "iron-ore"), 50, "ruda ve vstupu")
      H.eq(machine_count(ctx.f, defines.inventory.fuel, "coal"), 0, "palivo se neplní")
      H.eq(H.count(ctx.a, "coal"), 50, "uhlí zůstalo v bedně")
    end } },
  },
  {
    name = "pec jako zdroj: bere hotové pláty",
    setup = function(ctx)
      H.power(ctx)
      ctx.f = H.place(ctx, "stone-furnace", 0, -1)
      ctx.f.get_inventory(defines.inventory.crafter_output).insert({ name = "iron-plate", count = 100 })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 100, "pláty v bedně")
    end } },
  },
}
