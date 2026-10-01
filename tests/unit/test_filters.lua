--- Jednotkové testy logiky filtrů.
local A = require("assert")
local filters = require("scripts.filters")

local LEVELS = { normal = 0, uncommon = 1, rare = 2, epic = 3, legendary = 5 }

return {
  { "prázdný filtr pustí vše", function()
    A.eq(filters.passes({}, "whitelist", "iron-plate", "normal", LEVELS), true, "whitelist")
    A.eq(filters.passes({}, "blacklist", "iron-plate", "normal", LEVELS), true, "blacklist")
  end },
  { "whitelist", function()
    local list = { { name = "copper-plate" } }
    A.eq(filters.passes(list, "whitelist", "copper-plate", "normal", LEVELS), true, "měď")
    A.eq(filters.passes(list, "whitelist", "iron-plate", "normal", LEVELS), false, "železo")
  end },
  { "blacklist", function()
    local list = { { name = "iron-plate" } }
    A.eq(filters.passes(list, "blacklist", "iron-plate", "normal", LEVELS), false, "železo")
    A.eq(filters.passes(list, "blacklist", "copper-plate", "normal", LEVELS), true, "měď")
  end },
  { "filtr bez kvality pustí každou kvalitu", function()
    A.eq(filters.passes({ { name = "iron-plate" } }, "whitelist", "iron-plate", "rare", LEVELS), true, "rare")
  end },
  { "porovnání kvality", function()
    local eq = { { name = "iron-plate", quality = "uncommon", comparator = "=" } }
    A.eq(filters.passes(eq, "whitelist", "iron-plate", "uncommon", LEVELS), true, "= shoda")
    A.eq(filters.passes(eq, "whitelist", "iron-plate", "normal", LEVELS), false, "= neshoda")
    local ge = { { name = "iron-plate", quality = "rare", comparator = "≥" } }
    A.eq(filters.passes(ge, "whitelist", "iron-plate", "legendary", LEVELS), true, "≥ vyšší")
    A.eq(filters.passes(ge, "whitelist", "iron-plate", "uncommon", LEVELS), false, "≥ nižší")
    local ne = { { name = "iron-plate", quality = "normal", comparator = "!=" } }
    A.eq(filters.passes(ne, "whitelist", "iron-plate", "epic", LEVELS), true, "!=")
  end },
}
