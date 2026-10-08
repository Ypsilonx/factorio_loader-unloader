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
  check("recepty odemyká vlastní výzkum tieru", function()
    for _, belt in ipairs({ "transport-belt", "fast-transport-belt", "express-transport-belt" }) do
      local name = "storage-optimizer-" .. belt
      H.truthy(prototypes.technology[name], "výzkum " .. name)
      H.truthy(unlocked_by_some_tech(name), "recept " .. name)
    end
    local t1 = prototypes.technology["storage-optimizer-transport-belt"].prerequisites
    H.truthy(t1["fast-inserter"], "tier 1 vyžaduje fast-inserter")
    H.eq(t1["bulk-inserter"], nil, "tier 1 nečeká na bulk-inserter (ten přichází s červeným pásem)")
    H.eq(#prototypes.technology["storage-optimizer-transport-belt"].research_unit_ingredients, 1,
      "tier 1 jen za červenou vědu")
    local t2 = prototypes.technology["storage-optimizer-fast-transport-belt"].prerequisites
    H.truthy(t2["storage-optimizer-transport-belt"], "tier 2 vyžaduje výzkum tieru 1")
    H.truthy(t2["bulk-inserter"], "tier 2 vyžaduje bulk-inserter")
  end),
  check("mod nepřidává vlastní signály (výchozí jsou vanilla S a N)", function()
    H.eq(prototypes.virtual_signal["storage-optimizer-batch"], nil, "bez vlastního signálu velikosti")
    H.eq(prototypes.virtual_signal["storage-optimizer-stacks"], nil, "bez vlastního signálu počtu")
  end),
  check("styly, sprity a události okna existují", function()
    -- Headless hra nemá hráče, okno se nevytvoří; aspoň ověřit, že engine zná vše, co scripts/gui* používá.
    for _, style in ipairs({ "inside_shallow_frame_with_padding", "caption_label", "caption_checkbox", "frame_title",
                             "draggable_space_header", "frame_action_button", "slot_button_in_shallow_frame" }) do
      H.truthy(prototypes.style[style], "styl " .. style)
    end
    H.truthy(helpers.is_valid_sprite_path("utility/close"), "sprite utility/close")
    for _, event in ipairs({ "on_gui_opened", "on_gui_closed", "on_gui_click", "on_gui_text_changed",
                             "on_gui_checked_state_changed", "on_gui_elem_changed",
                             "on_gui_selection_state_changed", "on_gui_switch_state_changed" }) do
      H.truthy(defines.events[event], "událost " .. event)
    end
  end),
  check("turbo tier (Space Age)", function()
    H.eq(interval("storage-optimizer-turbo-transport-belt"), 15, "turbo")
  end, "space-age"),
}
