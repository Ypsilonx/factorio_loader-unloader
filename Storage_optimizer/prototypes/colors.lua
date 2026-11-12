--- Barvy šipek tierů podle barvy pásu (čistá logika bez herního API).
--- Prototyp pásu barvu jako číslo nenese – je jen v obrázku. Odhaduje se proto z ikony pásu v pořadí:
--- tint kterékoli vrstvy ikony (přichycený na paletu) → známá cesta ikony → barva v názvu souboru
--- (např. Bob: purple-transport-belt.png) → nepoužitá barva z palety, aby se ani tiery neznámých modů nepletly.
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

--- Ikony pásů, které nemají tint ani barvu v názvu souboru. Barva zjištěná z obrázku ikony
--- (postup v docs/development.md → Barvy šipek); jen mody, které jdou ve Factoriu 2.1 načíst.
M.KNOWN_ICONS = {
  ["__base__/graphics/icons/transport-belt.png"] = "yellow",
  ["__base__/graphics/icons/fast-transport-belt.png"] = "red",
  ["__base__/graphics/icons/express-transport-belt.png"] = "blue",
  ["__space-age__/graphics/icons/turbo-transport-belt.png"] = "green",
  -- One More Tier: převzatá vanilla cesta, jen s prefixem modu
  ["__one-more-tier__/graphics/icons/transport-belt.png"] = "purple",
  ["__space-exploration-graphics__/graphics/icons/transport-belt.png"] = "white",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-01.png"] = "yellow",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-02.png"] = "red",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-03.png"] = "blue",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-04.png"] = "pink",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-05.png"] = "green",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-06.png"] = "brown",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-07.png"] = "purple",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-08.png"] = "white",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-09.png"] = "orange",
  ["__5dim_transport__/graphics/icon/transport-belt/transport-belt-icon-10.png"] = "blue",
  ["__nullius__/graphics/icons/entity/belt4.png"] = "green",
  ["__factorioplus__/graphics/icons/basic-transport-belt.png"] = "black",
  ["__factorioplus__/graphics/icons/turbo-transport-belt.png"] = "green",
  ["__factorioplus__/graphics/icons/supersonic-transport-belt.png"] = "purple",
  ["__prismatic-belts__/graphics/icons/base/transport-belt.png"] = "yellow",
  ["__prismatic-belts__/graphics/icons/base/fast-transport-belt.png"] = "red",
  ["__prismatic-belts__/graphics/icons/base/express-transport-belt.png"] = "blue",
  ["__prismatic-belts__/graphics/icons/space-age/turbo-transport-belt.png"] = "green",
  ["__ultimateCore__/graphics/umr_belt/umr_transport_belt_icon.png"] = "purple",
  -- Omnienergy dává základnímu pásu ikonu splitteru
  ["__omnimatter_energy__/graphics/icons/basic-splitter.png"] = "black",
  ["__AdvancedBeltsSA__/graphics/icons/extreme-belt.png"] = "cyan",
  ["__AdvancedBeltsSA__/graphics/icons/ultimate-belt.png"] = "orange",
  ["__AdvancedBeltsSA__/graphics/icons/high-speed-belt.png"] = "pink",
  ["__LithiumBattery__/graphics/belt/icons/promethium-transport-belt.png"] = "pink",
  ["__more-belts__/graphics/icons/ddi-transport-belt-mk4.png"] = "green",
  ["__more-belts__/graphics/icons/ddi-transport-belt-mk5.png"] = "blue",
  ["__more-belts__/graphics/icons/ddi-transport-belt-mk6.png"] = "red",
  ["__more-belts__/graphics/icons/ddi-transport-belt-mk7.png"] = "purple",
  ["__more-belts__/graphics/icons/ddi-transport-belt-mk8.png"] = "pink",
  ["__iper-belt__/graphics/icons/iper-transport-belt.png"] = "blue",
}

--- Slova v názvu souboru ikony → barva palety.
M.WORDS = {
  yellow = "yellow", red = "red", blue = "blue", green = "green", purple = "purple", violet = "purple",
  white = "white", black = "black", grey = "black", gray = "black", orange = "orange", cyan = "cyan",
  pink = "pink", magenta = "pink", brown = "brown", wood = "brown", wooden = "brown",
}

--- Pořadí, ve kterém se rozdávají nepoužité barvy pásům s neznámou barvou.
M.FALLBACK = { "yellow", "red", "blue", "green", "purple", "orange", "cyan", "pink", "white", "brown", "black" }

--- Barvy palety, na které se přichytí sytý tint (podle odstínu); hnědá by s oranžovou splývala.
local CHROMATIC = { "yellow", "red", "blue", "green", "purple", "orange", "cyan", "pink" }

--- Převede barvu Factoria (pole nebo r/g/b, rozsah 0–1 i 0–255) na { r, g, b } v rozsahu 0–1.
--- @param c table
--- @return table
local function normalize(c)
  local r, g, b = c.r or c[1] or 0, c.g or c[2] or 0, c.b or c[3] or 0
  if r > 1 or g > 1 or b > 1 then r, g, b = r / 255, g / 255, b / 255 end
  return { r = r, g = g, b = b }
end

--- Odstín (0–360), sytost a jas barvy { r, g, b }.
--- @param c table
--- @return number, number, number
local function hsv(c)
  local max, min = math.max(c.r, c.g, c.b), math.min(c.r, c.g, c.b)
  local d = max - min
  if d == 0 then return 0, 0, max end
  local h
  if max == c.r then h = ((c.g - c.b) / d) % 6
  elseif max == c.g then h = (c.b - c.r) / d + 2
  else h = (c.r - c.g) / d + 4 end
  return h * 60, d / max, max
end

--- Přichytí libovolný tint na barvu palety: málo sytý podle jasu na šedou/bílou, jinak nejbližší odstín.
--- Raw tint by šipky mohl zhasnout (SE má tint 0,0,0) nebo barvit jinak než zbytek tierů.
--- @param tint table barva Factoria
--- @return table barva palety
function M.snap(tint)
  local h, s, v = hsv(normalize(tint))
  if s < 0.25 then return M.PALETTE[v < 0.6 and "black" or "white"] end
  local best, best_d
  for _, name in ipairs(CHROMATIC) do
    local d = math.abs(hsv(M.PALETTE[name]) - h)
    d = math.min(d, 360 - d)
    if not best_d or d < best_d then best, best_d = name, d end
  end
  return M.PALETTE[best]
end

--- Vrstvy ikony prototypu (`icons`, jinak `icon` jako jediná vrstva).
--- @param proto table prototyp pásu
--- @return table[] vrstvy { icon, tint }
function M.icon_layers(proto)
  if proto.icons and proto.icons[1] then return proto.icons end
  if proto.icon then return { { icon = proto.icon } } end
  return {}
end

--- Barva pásu odhadnutá z jeho ikony, nebo nil, když ji nejde zjistit.
--- @param proto table prototyp pásu
--- @return table|nil barva { r, g, b }
function M.belt_color(proto)
  local layers = M.icon_layers(proto)
  for _, layer in ipairs(layers) do
    -- Průhledný tint (alfa 0) je jen zvýraznění, ne barva pásu (Artisanal Reskins).
    if layer.tint and (layer.tint.a or layer.tint[4] or 1) > 0 then return M.snap(layer.tint) end
  end
  local icon = layers[1] and layers[1].icon
  if not icon then return nil end
  local known = M.KNOWN_ICONS[icon]
  if known then return M.PALETTE[known] end
  local file = icon:match("([^/]+)%.png$") or ""
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
    result[i] = M.belt_color(belts[i])
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
