--- Integrační test obnovy velikosti dávky z tagů (stavba z blueprintu = oživení ducha s tagy).
local H = require("helpers")

return {
  {
    name = "dávka z tagů blueprintu",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
      local ghost = ctx.surface.create_entity({
        name = "entity-ghost",
        inner_name = "storage-optimizer-so-test-belt",
        position = { ctx.origin.x + 0.5, ctx.origin.y + 1.5 },
        force = "player",
        tags = { so_batch = 40 },
      })
      local _, entity = ghost.revive({ raise_revive = true })
      ctx.m = entity
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_batch", ctx.m.unit_number), 40, "dávka z tagu")
      H.eq(H.count(ctx.b, "iron-plate"), 80, "dvě dávky po 40")
    end } },
  },
}
