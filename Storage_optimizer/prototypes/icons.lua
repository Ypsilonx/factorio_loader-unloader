--- Ikony tierů (dočasné, než bude grafika z Blenderu): tónovaný rychlý inserter + ikona pásu v rohu.
local M = {}

--- Sestaví vrstvy ikony tieru.
--- @param belt_item string jméno předmětu pásu
--- @param tint table barva tieru
--- @return table[] IconData
function M.tier_icons(belt_item, tint)
  local base = data.raw["item"]["fast-inserter"]
  local belt = data.raw["item"][belt_item]
  local overlay = belt.icons and belt.icons[1] or { icon = belt.icon, icon_size = belt.icon_size }
  return {
    { icon = base.icon, icon_size = base.icon_size or 64, tint = tint },
    { icon = overlay.icon, icon_size = overlay.icon_size or 64, tint = overlay.tint, scale = 0.25, shift = { -8, -8 } },
  }
end

return M
