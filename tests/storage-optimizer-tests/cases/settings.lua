--- Integrační testy filtrů, velikosti dávky a obvodové sítě.
local H = require("helpers")

local BELT = "so-test-belt"

--- Rozložení zdroj (0,0) – optimizer (0,1) – cíl (0,2) s napájením.
local function layout(ctx, items, source_name)
  H.power(ctx)
  ctx.a = H.chest(ctx, source_name or "steel-chest", 0, 0, items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, "steel-chest", 0, 2)
end

local MIXED = { { name = "iron-plate", count = 200 }, { name = "copper-plate", count = 200 } }

return {
  {
    name = "filtr povolit",
    setup = function(ctx)
      layout(ctx, MIXED)
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "copper-plate" })
      ctx.m.inserter_filter_mode = "whitelist"
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "filtr zakázat",
    setup = function(ctx)
      layout(ctx, MIXED)
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "iron-plate" })
      ctx.m.inserter_filter_mode = "blacklist"
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "ruční velikost dávky",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 700 } })
      remote.call("storage-optimizer", "set_batch", ctx.m.unit_number, 300)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 600, "dvě dávky po 300")
      H.eq(H.count(ctx.a, "iron-plate"), 100, "zbytek")
    end } },
  },
  {
    name = "dávka větší než cíl",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 4800 } })
      remote.call("storage-optimizer", "set_batch", ctx.m.unit_number, 100000)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl")
      H.eq(H.count(ctx.a, "iron-plate"), 4800, "zdroj")
      H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number), "waiting", "stav")
    end } },
  },
  {
    name = "velikost dávky ze signálu",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 100 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "signal-S", count = 30 } })
      H.wire(cc, ctx.m)
      ctx.m.get_control_behavior().circuit_set_stack_size = true
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 90, "tři dávky po 30")
      H.eq(H.count(ctx.a, "iron-plate"), 10, "zbytek")
    end } },
  },
  {
    name = "zapnutí a vypnutí sítí",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 500 } })
      ctx.cc = H.combinator(ctx, 2, 1, { { name = "copper-plate", count = 1 } })
      H.wire(ctx.cc, ctx.m)
      local cb = ctx.m.get_control_behavior()
      cb.circuit_enable_disable = true
      cb.circuit_condition = { first_signal = { type = "item", name = "copper-plate" }, comparator = ">", constant = 5 }
    end,
    steps = {
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 0, "vypnuto")
        H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number), "disabled", "stav")
        H.set_signal(ctx.cc, 1, { name = "copper-plate", count = 10 })
      end },
      { ticks = 60, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "zapnuto") end },
    },
  },
  {
    name = "filtry ze signálů",
    setup = function(ctx)
      layout(ctx, MIXED)
      local cc = H.combinator(ctx, 2, 1, { { name = "copper-plate", count = 1 } })
      H.wire(cc, ctx.m)
      ctx.m.get_control_behavior().circuit_set_filters = true
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "filtr podle kvality",
    requires = "quality",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 200 }, { name = "iron-plate", count = 200, quality = "uncommon" } })
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "iron-plate", quality = "uncommon", comparator = "=" })
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate", "uncommon"), 200, "uncommon")
      H.eq(H.count(ctx.b, "iron-plate", "normal"), 0, "normal")
    end } },
  },
}
