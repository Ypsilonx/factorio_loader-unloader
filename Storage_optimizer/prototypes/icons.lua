--- Ikony tierů: základ z Blenderu, šipky obarvené podle tieru a ikona pásu v rohu.
local M = {}

local PATH = "__Storage_optimizer__/graphics/icons/storage-optimizer-"

--- Sestaví vrstvy ikony tieru.
--- @param belt_item string jméno předmětu pásu
--- @param tint table barva tieru
--- @return table[] IconData
function M.tier_icons(belt_item, tint)
  local belt = data.raw["item"][belt_item]
  local overlay = belt.icons and belt.icons[1] or { icon = belt.icon, icon_size = belt.icon_size }
  return {
    { icon = PATH .. "base.png", icon_size = 64 },
    { icon = PATH .. "mask.png", icon_size = 64, tint = tint },
    { icon = overlay.icon, icon_size = overlay.icon_size or 64, tint = overlay.tint, scale = 0.25, shift = { -8, -8 } },
  }
end

return M
