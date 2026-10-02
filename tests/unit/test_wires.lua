--- Jednotkové testy výpočtu bodů pro dráty obvodové sítě (projekce modelu z Blenderu do souřadnic hry).
local A = require("assert")
local wires = require("prototypes.wires")

--- Porovná čísla na 3 desetinná místa.
local function near(actual, expected, what)
  A.eq(math.floor(actual * 1000 + 0.5), math.floor(expected * 1000 + 0.5), what)
end

return {
  { "projekce bodu pro směr sever", function()
    -- Model: x doprava, y ke zdroji (sever = nahoru na obrazovce), z výška. Hra: y roste dolů.
    local v = wires.project({ 0.2, 0.3, 0.4 }, 0)
    near(v[1], 0.2, "x")
    near(v[2], -(0.3 + wires.HEIGHT * 0.4), "y = -(y + výška)")
  end },
  { "otočení modelu pro směr východ (zdroj na východě)", function()
    -- Při směru východ míří strana zdroje (+y modelu) na východ (+x obrazovky).
    local v = wires.project({ 0.0, 0.3, 0.0 }, -90)
    near(v[1], 0.3, "x")
    near(v[2], 0.0, "y")
  end },
  { "stín je posunutý doprava podle slunce", function()
    local s = wires.shadow({ 0.0, 0.0, 0.5 }, 0)
    A.truthy(s[1] > 0.4, "stín vpravo")
  end },
  { "konektor pro 4 směry s červeným i zeleným bodem", function()
    local defs = wires.connector()
    A.eq(#defs, 4, "počet směrů")
    for i, def in ipairs(defs) do
      A.truthy(def.points.wire.red and def.points.wire.green, "body drátů " .. i)
      A.truthy(def.points.shadow.red and def.points.shadow.green, "body stínu " .. i)
    end
  end },
}
