--- Testy vygenerovaných prototypů.
local H = require("helpers")

--- Interval tieru z mod-data.
local function interval(name)
  return prototypes.mod_data["storage-optimizer-tiers"].data[name].interval
end

--- Vrátí true, pokud nějaký výzkum odemyká recept.
local function unlocked_by_some_tech(recipe)
  for _, tech in pairs(prototypes.technology) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe then return true end
    end
  end
  return false
end

--- Jednokrokový test bez setupu.
local function check(name, fn, requires)
  return { name = name, requires = requires, steps = { { ticks = 1, run = fn } } }
end

return {
  check("tiery z vanilla pásů", function()
    for _, belt in ipairs({ "transport-belt", "fast-transport-belt", "express-transport-belt" }) do
      local name = "storage-optimizer-" .. belt
      H.truthy(prototypes.entity[name], "entita " .. name)
      H.truthy(prototypes.item[name], "předmět " .. name)
      H.truthy(prototypes.recipe[name], "recept " .. name)
      H.eq(prototypes.entity[name].type, "inserter", "typ " .. name)
    end
  end),
  check("intervaly vanilla tierů", function()
    H.eq(interval("storage-optimizer-transport-belt"), 60, "žlutý")
    H.eq(interval("storage-optimizer-fast-transport-belt"), 30, "červený")
    H.eq(interval("storage-optimizer-express-transport-belt"), 20, "modrý")
  end),
  check("tier z pásu cizího modu", function()
    H.truthy(prototypes.entity["storage-optimizer-so-test-belt"], "entita testovacího pásu")
    H.eq(interval("storage-optimizer-so-test-belt"), 8, "interval testovacího pásu (7,5 → 8)")
  end),
  check("skrytý pás nemá tier", function()
    H.eq(prototypes.entity["storage-optimizer-so-test-hidden-belt"], nil, "skrytý pás")
  end),
  check("upgrade řetěz", function()
    local first = prototypes.entity["storage-optimizer-transport-belt"]
    H.eq(first.next_upgrade and first.next_upgrade.name, "storage-optimizer-fast-transport-belt", "next_upgrade")
  end),
  check("recepty odemyká výzkum", function()
    H.truthy(unlocked_by_some_tech("storage-optimizer-transport-belt"), "žlutý tier")
    H.truthy(unlocked_by_some_tech("storage-optimizer-fast-transport-belt"), "červený tier")
  end),
  check("mod nepřidává vlastní signály (výchozí jsou vanilla S a N)", function()
    H.eq(prototypes.virtual_signal["storage-optimizer-batch"], nil, "bez vlastního signálu velikosti")
    H.eq(prototypes.virtual_signal["storage-optimizer-stacks"], nil, "bez vlastního signálu počtu")
  end),
  check("styly a ukotvení GUI panelu existují", function()
    -- Headless hra nemá hráče, panel se nevytvoří; aspoň ověřit, že engine zná vše, co gui.lua používá.
    for _, style in ipairs({ "inside_shallow_frame_with_padding", "caption_label", "caption_checkbox" }) do
      H.truthy(prototypes.style[style], "styl " .. style)
    end
    H.truthy(defines.relative_gui_type.inserter_gui, "relative_gui_type.inserter_gui")
    H.truthy(defines.relative_gui_position.right, "relative_gui_position.right")
  end),
  check("turbo tier (Space Age)", function()
    H.eq(interval("storage-optimizer-turbo-transport-belt"), 15, "turbo")
  end, "space-age"),
}
