--- Barvy šipek tierů podle barvy pásu (čistá logika bez herního API).
--- Prototyp pásu barvu jako číslo nenese – je jen v obrázku. Odhaduje se proto z ikony pásu v pořadí:
--- tint ikony → známá cesta ikony (vanilla, Space Age) → barva v názvu souboru (např. Bob: purple-transport-belt.png)
--- → nepoužitá barva z palety, aby se ani tiery neznámých modů nepletly.
local M = {}

--- Paleta barev šipek; maska šipek je ve stupních šedi, takže tmavé barvy musí zůstat dost světlé.
M.PALETTE = {
  yellow = { r = 1.0, g = 0.85, b = 0.25 },
  red = { r = 1.0, g = 0.35, b = 0.3 },
  blue = { r = 0.35, g = 0.65, b = 1.0 },
  green = { r = 0.55, g = 1.0, b = 0.45 },
  purple = { r = 0.8, g = 0.45, b = 1.0 },
  white = { r = 1.0, g = 1.0, b = 1.0 },
  black = { r = 0.75, g = 0.75, b = 0.75 },
  orange = { r = 1.0, g = 0.55, b = 0.15 },
  cyan = { r = 0.3, g = 1.0, b = 0.95 },
  pink = { r = 1.0, g = 0.5, b = 0.8 },
  brown = { r = 0.7, g = 0.5, b = 0.3 },
}

--- Ikony pásů, které barvu v názvu nemají (vanilla, Space Age).
M.KNOWN_ICONS = {
  ["__base__/graphics/icons/transport-belt.png"] = "yellow",
  ["__base__/graphics/icons/fast-transport-belt.png"] = "red",
  ["__base__/graphics/icons/express-transport-belt.png"] = "blue",
  ["__space-age__/graphics/icons/turbo-transport-belt.png"] = "green",
}

--- Slova v názvu souboru ikony → barva palety.
M.WORDS = {
  yellow = "yellow", red = "red", blue = "blue", green = "green", purple = "purple", violet = "purple",
  white = "white", black = "black", grey = "black", gray = "black", orange = "orange", cyan = "cyan",
  pink = "pink", brown = "brown",
}

--- Pořadí, ve kterém se rozdávají nepoužité barvy pásům s neznámou barvou.
M.FALLBACK = { "yellow", "red", "blue", "green", "purple", "orange", "cyan", "pink", "white", "brown", "black" }

--- Převede barvu Factoria (pole nebo r/g/b, rozsah 0–1 i 0–255) na { r, g, b } v rozsahu 0–1.
--- @param c table
--- @return table
local function normalize(c)
  local r, g, b = c.r or c[1] or 0, c.g or c[2] or 0, c.b or c[3] or 0
  if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
  return { r = r, g = g, b = b }
end

--- První vrstva ikony prototypu (`icons[1]`, jinak `icon`).
--- @param proto table prototyp pásu
--- @return table|nil { icon, tint }
function M.icon_layer(proto)
  if proto.icons and proto.icons[1] then return proto.icons[1] end
  if proto.icon then return { icon = proto.icon } end
end

--- Barva pásu odhadnutá z jeho ikony, nebo nil, když ji nejde zjistit.
--- @param layer table|nil první vrstva ikony pásu
--- @return table|nil barva { r, g, b }
function M.belt_color(layer)
  if not layer or not layer.icon then return nil end
  if layer.tint then return normalize(layer.tint) end
  local known = M.KNOWN_ICONS[layer.icon]
  if known then return M.PALETTE[known] end
  local file = layer.icon:match("([^/]+)%.png$") or ""
  for word in file:lower():gmatch("[^%-_%.]+") do
    if M.WORDS[word] then return M.PALETTE[M.WORDS[word]] end
  end
end

--- Přidělí barvy tierům v daném pořadí: známá barva pásu, jinak první barva palety, kterou zatím nikdo nemá
--- (když dojdou, opakují se od začátku). Pořadí `belts` musí být stabilní (seřazené tiery), aby se barvy
--- neměnily mezi spuštěními.
--- @param belts table[] prototypy pásů tierů
--- @return table[] barvy ve stejném pořadí
function M.assign(belts)
  local result, used = {}, {}
  for i = 1, #belts do
    result[i] = M.belt_color(M.icon_layer(belts[i]))
    if result[i] then used[result[i]] = true end
  end
  local next_free = 1
  for i = 1, #belts do
    if not result[i] then
      while next_free <= #M.FALLBACK and used[M.PALETTE[M.FALLBACK[next_free]]] do next_free = next_free + 1 end
      local name = M.FALLBACK[next_free] or M.FALLBACK[(i - 1) % #M.FALLBACK + 1]
      result[i] = M.PALETTE[name]
      used[result[i]] = true
    end
  end
  return result
end

return M
