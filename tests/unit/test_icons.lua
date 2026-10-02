---@diagnostic disable: lowercase-global
--- Jednotkový test vrstev ikony tieru (data.raw nahrazený testovací tabulkou).
local A = require("assert")

data = { raw = { item = { ["transport-belt"] = { icon = "__base__/graphics/icons/transport-belt.png", icon_size = 64 } } } }
local icons = require("prototypes.icons")

return {
  { "ikona tieru: základ a obarvené šipky, bez ikonky pásu", function()
    local layers = icons.tier_icons("transport-belt", { r = 1, g = 0.85, b = 0.25 })
    A.eq(#layers, 2, "počet vrstev")
    A.truthy(layers[2].tint, "šipky obarvené barvou tieru")
  end },
}
