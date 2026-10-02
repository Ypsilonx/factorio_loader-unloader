--- Body pro červený a zelený drát: vrcholy izolátorů svorkovnice na převodovce modelu z Blenderu,
--- promítnuté stejně jako render (blender/so_render.py). Čistá logika – testuje tests/unit/test_wires.lua.
---
--- VAZBA NA BLENDER: TERMINAL musí odpovídat poloze izolátorů v blender/so_model.py (funkce terminal),
--- DIRECTIONS natočení v blender/build_sprites.py a SHADOW_* směru slunce v blender/so_render.py.
local M = {}

--- Vrcholy izolátorů v souřadnicích modelu (x doprava, y ke zdroji, z výška; 1 = dlaždice).
M.TERMINAL = {
  red = { 0.175, 0.32, 0.385 },
  green = { 0.245, 0.32, 0.385 },
}

--- Natočení modelu pro směry N, E, S, W (stupně), stejné jako DIRECTIONS v build_sprites.py.
M.DIRECTIONS = { 0, -90, 180, 90 }

--- Kamera pod 45°: výška z se na obrazovce projeví posunem nahoru o z × sin 45°.
M.HEIGHT = math.sqrt(2) / 2
--- Posun stínu na zemi na jednotku výšky (slunce v so_render.py: rotace -12°, -48°).
M.SHADOW_X = 1.111
M.SHADOW_Y = -0.225

--- Otočí bod modelu kolem svislé osy o úhel ve stupních.
local function rotate(point, angle)
  local a = math.rad(angle)
  local x, y = point[1], point[2]
  return x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a)
end

--- Pozice bodu na obrazovce relativně ke středu entity (Factorio: y roste dolů).
--- @param point number[] { x, y, z } v souřadnicích modelu
--- @param angle number natočení modelu ve stupních
--- @return number[] { x, y }
function M.project(point, angle)
  local x, y = rotate(point, angle)
  return { x, -(y + M.HEIGHT * point[3]) }
end

--- Pozice stínu bodu: pata bodu na zemi posunutá podle směru slunce úměrně výšce.
function M.shadow(point, angle)
  local x, y = rotate(point, angle)
  local z = point[3]
  return { x + M.SHADOW_X * z, -(y + M.SHADOW_Y * z) }
end

--- Definice konektoru obvodové sítě pro 4 směry (bez vanilla krabičky – svorkovnice je v modelu).
--- @return table[] CircuitConnectorDefinition × 4 (N, E, S, W)
function M.connector()
  local defs = {}
  for i, angle in ipairs(M.DIRECTIONS) do
    defs[i] = {
      points = {
        wire = { red = M.project(M.TERMINAL.red, angle), green = M.project(M.TERMINAL.green, angle) },
        shadow = { red = M.shadow(M.TERMINAL.red, angle), green = M.shadow(M.TERMINAL.green, angle) },
      },
    }
  end
  return defs
end

return M
