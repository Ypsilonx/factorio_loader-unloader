--- Jednotkové testy odhadu barvy šipek podle pásu.
local A = require("assert")
local colors = require("prototypes.colors")
local P = colors.PALETTE

--- Testovací prototyp pásu s danou ikonou.
local function belt(icon, tint)
  if tint then return { icons = { { icon = icon, tint = tint } } } end
  return { icon = icon }
end

return {
  { "vanilla a Space Age podle známé cesty ikony", function()
    local c = colors.assign({
      belt("__base__/graphics/icons/transport-belt.png"),
      belt("__base__/graphics/icons/fast-transport-belt.png"),
      belt("__base__/graphics/icons/express-transport-belt.png"),
      belt("__space-age__/graphics/icons/turbo-transport-belt.png"),
    })
    A.eq(c[1], P.yellow, "žlutý")
    A.eq(c[2], P.red, "červený")
    A.eq(c[3], P.blue, "modrý")
    A.eq(c[4], P.green, "turbo")
  end },
  { "Bob: barva z názvu souboru, i když turbo předefinuje na fialový", function()
    A.eq(colors.belt_color({ icon = "__boblogistics__/graphics/icons/black-transport-belt.png" }), P.black, "basic")
    A.eq(colors.belt_color({ icon = "__boblogistics__/graphics/icons/purple-transport-belt.png" }), P.purple, "turbo")
    A.eq(colors.belt_color({ icon = "__boblogistics__/graphics/icons/green-transport-belt.png" }), P.green, "ultimate")
  end },
  { "tint ikony má přednost, rozsah 0–255 se převede", function()
    local c = colors.belt_color({ icon = "__base__/graphics/icons/transport-belt.png", tint = { 255, 0, 51 } })
    A.eq(c.r, 1, "r")
    A.eq(c.g, 0, "g")
    A.eq(c.b, 0.2, "b")
  end },
  { "neznámé pásy dostanou nepoužité barvy, každý jinou", function()
    local c = colors.assign({
      belt("__base__/graphics/icons/transport-belt.png"),
      belt("__mod__/graphics/icons/hyper-belt.png"),
      belt("__mod__/graphics/icons/mega-belt.png"),
    })
    A.eq(c[1], P.yellow, "známý žlutý")
    A.eq(c[2], P.red, "první volná barva")
    A.eq(c[3], P.blue, "druhá volná barva")
  end },
  { "slovo uvnitř jiného slova se nepočítá", function()
    A.eq(colors.belt_color({ icon = "__mod__/graphics/icons/redstone-belt.png" }), nil, "redstone není red")
  end },
  { "po vyčerpání palety se barvy opakují bez pádu", function()
    local list = {}
    for i = 1, #colors.FALLBACK + 3 do list[i] = belt("__mod__/graphics/icons/belt-" .. i .. ".png") end
    local c = colors.assign(list)
    for i = 1, #list do A.truthy(c[i], "barva " .. i) end
  end },
}
