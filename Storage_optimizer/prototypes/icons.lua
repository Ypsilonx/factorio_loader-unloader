--- Ikony tierů: základ z Blenderu a šipky obarvené podle tieru.
local M = {}

local PATH = "__Storage_optimizer__/graphics/icons/storage-optimizer-"

--- Malá ikonka pásu v rohu ikony (rozliší tiery i u modů s více než 6 pásy, kde se barvy opakují).
--- Vypnuto: tier ukazuje barva šipek a jméno pásu v názvu. Zapnutí: true.
M.SHOW_BELT_OVERLAY = false

--- Sestaví vrstvy ikony tieru.
--- @param belt_item string jméno předmětu pásu
--- @param tint table barva tieru
--- @return table[] IconData
function M.tier_icons(belt_item, tint)
  local layers = {
    { icon = PATH .. "base.png", icon_size = 64 },
    { icon = PATH .. "mask.png", icon_size = 64, tint = tint },
  }
  if M.SHOW_BELT_OVERLAY then
    local belt = data.raw["item"][belt_item]
    local overlay = belt.icons and belt.icons[1] or { icon = belt.icon, icon_size = belt.icon_size }
    layers[3] = { icon = overlay.icon, icon_size = overlay.icon_size or 64, tint = overlay.tint, scale = 0.25,
                  shift = { -8, -8 } }
  end
  return layers
end

return M
