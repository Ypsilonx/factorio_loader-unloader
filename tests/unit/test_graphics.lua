---@diagnostic disable: undefined-global
--- Kontrola grafiky: headless Factorio sprity nenačítá, takže chybějící soubor nebo špatný rozměr
--- by se projevil až ve hře. Rozměry musí odpovídat prototypes/entity.lua a prototypes/icons.lua.
local A = require("assert")

--- Přečte šířku a výšku PNG z hlavičky IHDR.
--- @return integer|nil šířka, integer|nil výška
local function png_size(path)
  local file = io.open(path, "rb")
  if not file then return nil, nil end
  local header = file:read(24)
  file:close()
  return string.unpack(">I4I4", header, 17)
end

--- Selže, pokud soubor chybí nebo nemá očekávaný rozměr.
local function expect(path, width, height)
  local w, h = png_size("Storage_optimizer/" .. path)
  A.truthy(w, "soubor existuje: " .. path)
  A.eq(w .. "x" .. h, width .. "x" .. height, "rozměr " .. path)
end

return {
  { "sprity entity: 4 směry po 128×128", function()
    for _, layer in ipairs({ "base", "mask", "shadow" }) do
      expect("graphics/entity/storage-optimizer-" .. layer .. ".png", 512, 128)
    end
  end },
  { "ikony 64×64", function()
    for _, layer in ipairs({ "base", "mask" }) do
      expect("graphics/icons/storage-optimizer-" .. layer .. ".png", 64, 64)
    end
  end },
  { "thumbnail 144×144", function() expect("thumbnail.png", 144, 144) end },
}
