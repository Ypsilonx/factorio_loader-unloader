-- Regrese: recepty tierů vytvořené v našem data-final-fixes musí převzít metatabulku ostatních receptů
-- (Pyanodon 3.1 na ně volá `recipe:has_category` a bez ní hra při načítání spadne).
local expected = getmetatable(data.raw["recipe"]["so-test-belt"])
for name, recipe in pairs(data.raw["recipe"]) do
  if name:find("^storage%-optimizer%-") and getmetatable(recipe) ~= expected then
    error("SO-TEST: recept " .. name .. " nemá metatabulku ostatních receptů")
  end
end
