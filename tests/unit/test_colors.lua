--- Jednotkové testy odhadu barvy šipek podle pásu.
local A = require("assert")
local colors = require("prototypes.colors")
local P = colors.PALETTE

--- Testovací prototyp pásu s danou ikonou; další argumenty = vrstvy { icon, tint } za základní ikonou.
local function belt(icon, ...)
  local extra = { ... }
  if #extra == 0 then return { icon = icon } end
  local icons = { { icon = icon } }
  for _, layer in ipairs(extra) do icons[#icons + 1] = layer end
  return { icons = icons }
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
  { "One More Tier je fialový i bez Space Age (dřív dostal volnou zelenou)", function()
    local c = colors.assign({
      belt("__base__/graphics/icons/transport-belt.png"),
      belt("__base__/graphics/icons/fast-transport-belt.png"),
      belt("__base__/graphics/icons/express-transport-belt.png"),
      belt("__one-more-tier__/graphics/icons/transport-belt.png"),
    })
    A.eq(c[4], P.purple, "omt")
  end },
  { "Bob: barva z názvu souboru, i když turbo předefinuje na fialový", function()
    A.eq(colors.belt_color(belt("__boblogistics__/graphics/icons/black-transport-belt.png")), P.black, "basic")
    A.eq(colors.belt_color(belt("__boblogistics__/graphics/icons/purple-transport-belt.png")), P.purple, "turbo")
    A.eq(colors.belt_color(belt("__boblogistics__/graphics/icons/green-transport-belt.png")), P.green, "ultimate")
  end },
  { "Wooden Logistics: slovo wood je hnědá", function()
    A.eq(colors.belt_color(belt("__wood-logistics__/graphics/icons/wood-transport-belt.png")), P.brown, "wood")
  end },
  { "tint na pozdější vrstvě se přichytí na paletu (SE deep space, Renai, Artisanal Reskins)", function()
    local glow = "__space-exploration-graphics__/graphics/icons/deep-space-transport-belt-glow.png"
    local base = "__space-exploration-graphics__/graphics/icons/deep-space-transport-belt.png"
    A.eq(colors.belt_color(belt(base, { icon = glow, tint = { r = 0, g = 0, b = 0 } })), P.black, "černý tint nezhasne")
    A.eq(colors.belt_color(belt(base, { icon = glow, tint = { r = 1, g = 1, b = 1 } })), P.white, "bílý")
    A.eq(colors.belt_color(belt(base, { icon = glow, tint = { r = 0, g = 1, b = 1 } })), P.cyan, "cyan")
    A.eq(colors.belt_color(belt(base, { icon = glow, tint = { r = 1, g = 0, b = 0 } })), P.red, "červený")
    A.eq(colors.belt_color(belt("__RenaiTransportation__/graphics/icons/BeltRampBase.png",
      { icon = "x.png", tint = { 255, 208, 0 } })), P.yellow, "rozsah 0–255")
    local mask = "__reskins-assets-base__/graphics/icons/transport-belt-mask.png"
    A.eq(colors.belt_color(belt("__reskins-assets-base__/graphics/icons/transport-belt-base.png",
      { icon = mask, tint = { r = 0.4, g = 0.9, b = 0.36, a = 1 } },
      { icon = "highlights.png", tint = { 1, 1, 1, 0 } })), P.green, "reskin ultimate")
  end },
  { "průhledný tint (alfa 0) barvu neurčuje", function()
    A.eq(colors.belt_color(belt("__base__/graphics/icons/transport-belt.png",
      { icon = "highlights.png", tint = { 1, 1, 1, 0 } })), P.yellow, "podle známé ikony")
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
    A.eq(colors.belt_color(belt("__mod__/graphics/icons/redstone-belt.png")), nil, "redstone není red")
  end },
  { "po vyčerpání palety se barvy opakují bez pádu", function()
    local list = {}
    for i = 1, #colors.FALLBACK + 3 do list[i] = belt("__mod__/graphics/icons/belt-" .. i .. ".png") end
    local c = colors.assign(list)
    for i = 1, #list do A.truthy(c[i], "barva " .. i) end
  end },
}
