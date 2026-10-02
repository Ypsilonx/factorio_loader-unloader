--- Obecné kontroly tierů, které platí s jakoukoli sadou modů (spouští je i varianta „mods“ s overhaul mody).
local H = require("helpers")

--- Jednokrokový test bez setupu.
local function check(name, fn)
  return { name = name, steps = { { ticks = 1, run = fn } } }
end

return {
  check("kompatibilita: tiery vznikly a každý recept je dostupný", function()
    local tiers = prototypes.mod_data["storage-optimizer-tiers"].data
    local names = {}
    for name in pairs(tiers) do
      names[#names + 1] = name
      local recipe = prototypes.recipe[name]
      H.truthy(recipe, "recept " .. name)
      H.truthy(recipe.enabled or prototypes.technology[name], "výzkum nebo recept od začátku " .. name)
    end
    H.truthy(#names > 0, "aspoň jeden tier")
    table.sort(names)
    log("SO-TEST INFO tiery: " .. table.concat(names, ", "))
  end),
  check("kompatibilita: suroviny jsou dostupné nejpozději s výzkumem tieru", function()
    H.eq(H.unreachable_tier_ingredients(), "", "nedostupné suroviny")
  end),
}
