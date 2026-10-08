---@diagnostic disable: lowercase-global
--- Test okna Storage optimizeru bez hry: herní GUI prvky (LuaGuiElement) nahrazuje jednoduchá napodobenina,
--- takže se ověří, že scripts/gui.lua a části v scripts/gui/ okno staví, plní, obnovují, obsluhují události
--- a zapisují nastavení do entity. (Headless Factorio nemá hráče, okno se v integračních testech nevytvoří.)
local A = require("assert")

--- Napodobenina LuaGuiElement: děti dostupné podle jména, add/destroy/get_mod, tags, style a běžné vlastnosti.
local function element(spec, parent)
  local e = {}
  for key, value in pairs(spec) do e[key] = value end
  e.parent, e.enabled, e.visible, e.valid = parent, true, true, true
  e.text, e.style, e.children, e.tags = "", {}, {}, spec.tags or {}
  if spec.type == "slider" then e.slider_value = spec.value end
  function e.add(child_spec)
    local child = element(child_spec, e)
    e.children[#e.children + 1] = child
    if child_spec.name then
      assert(not e[child_spec.name], "duplicitní jméno prvku " .. child_spec.name)
      e[child_spec.name] = child
    end
    return child
  end
  function e.destroy()
    e.valid = false
    if parent and e.name then parent[e.name] = nil end
  end
  function e.get_mod() return "Storage_optimizer" end
  return e
end

local NAME = "storage-optimizer-transport-belt"
prototypes = {
  mod_data = { ["storage-optimizer-tiers"] = { data = { [NAME] = {
    tier = 1, interval = 60, energy = 50000, extra_stack_energy = 5000, max_stacks = 20 } } } },
}
defines = {
  wire_connector_id = { circuit_red = 1, circuit_green = 2 },
  controllers = { character = 1, god = 0 },
}
script = { mod_name = "Storage_optimizer" }
storage = { movers = {} }

--- Připojení drátem: jen červená síť číslo 3.
local function red_network(id) return id == 1 and { network_id = 3 } or nil end

local signal_value = 5
local behavior = { circuit_set_stack_size = false, circuit_stack_control_signal = { type = "virtual", name = "signal-S" } }
local filters = {}
local logistic_network = nil
local entity = {
  name = NAME, valid = true, unit_number = 1, localised_name = "Storage optimizer",
  position = { x = 0, y = 0 }, force = "player",
  energy = 145000, electric_buffer_size = 290000,
  filter_slot_count = 5, use_filters = false, inserter_filter_mode = "whitelist",
  get_control_behavior = function() return behavior end,
  get_or_create_control_behavior = function() return behavior end,
  get_circuit_network = red_network,
  get_signal = function() return signal_value end,
  get_filter = function(slot) return filters[slot] end,
  set_filter = function(slot, filter) filters[slot] = filter end,
  surface = { find_logistic_network_by_position = function() return logistic_network end },
}
local mover = { entity = entity, unit_number = 1, state = "working", stacks = 3 }
storage.movers[1] = mover

local player = {
  index = 1, controller_type = 1,
  gui = { screen = element({ type = "root" }), relative = element({ type = "root" }) },
  can_reach_entity = function() return true end,
}
game = { players = { player }, get_player = function() return player end }

local gui = require("scripts.gui")

--- Tělo hlavního okna a boční sloupec otevřeného okna.
local function parts()
  local row = player.gui.screen.so_window.so_row
  return row.so_main.so_body, row.so_side
end

--- Otevře okno jako událost on_gui_opened a vrátí tělo hlavního okna a boční sloupec.
local function open()
  gui.on_opened({ entity = entity, player_index = 1 })
  return parts()
end

--- Nastaví hodnotu prvku a pošle událost změny (jako hra).
local function change(target, field, value)
  target[field] = value
  gui.on_changed({ element = target, player_index = 1 })
end

return {
  { "okno se otevře místo nativního a naplní", function()
    local body, side = open()
    local window = player.gui.screen.so_window
    A.eq(player.opened, window, "hráč má otevřené naše okno")
    A.eq(storage.gui_target[1], 1, "okno patří optimizeru")
    A.eq(window.auto_center, true, "první otevření uprostřed")
    A.eq(body.so_preview_frame.so_preview.entity, entity, "náhled budovy")
    A.eq(body.so_status_row.so_status_icon.sprite, "utility/status_working", "zelená tečka stavu")
    A.eq(body.so_stacks.so_field.text, "3", "ruční počet stacků")
    A.eq(body.so_stacks.so_slider.slider_value, 3, "posuvník počtu stacků")
    A.eq(body.so_batch.so_field.text, "", "prázdná velikost stacku = podle materiálu")
    A.eq(body.so_leftovers.state, false, "zbytky vypnuté")
    A.eq(body.so_energy.so_bar.value, 0.5, "pruh energie")
    A.eq(side.so_circuit.visible, true, "panel obvodu u budovy s drátem")
    A.eq(side.so_circuit.so_connected.so_networks.caption[2], "[color=red]3[/color]", "připojeno k síti 3")
    A.eq(side.so_circuit.so_content.so_stacks_signal.so_signal.elem_value.name, "signal-N", "výchozí signál N")
    A.eq(side.so_logistic.visible, false, "mimo logistickou síť skrytý")
  end },
  { "obyčejná entita okno neotevře", function()
    gui.close(player)
    gui.on_opened({ entity = { valid = true, name = "inserter" }, player_index = 1 })
    A.eq(player.gui.screen.so_window, nil, "bez okna")
  end },
  { "velikost a počet stacků: pole, posuvník a signál", function()
    local body, side = open()
    change(body.so_stacks.so_field, "text", "50")
    A.eq(mover.stacks, 20, "počet stacků omezený limitem")
    A.eq(body.so_stacks.so_slider.slider_value, 20, "posuvník srovnán")
    change(body.so_stacks.so_slider, "slider_value", 7)
    A.eq(mover.stacks, 7, "počet stacků z posuvníku")
    A.eq(body.so_stacks.so_field.text, "7", "pole srovnáno")
    change(body.so_batch.so_field, "text", "300")
    A.eq(mover.batch, 300, "ruční velikost stacku")
    change(body.so_batch.so_field, "text", "")
    A.eq(mover.batch, nil, "prázdné = podle materiálu")

    local content = side.so_circuit.so_content
    change(content.so_stacks_circuit, "state", true)
    A.eq(mover.stacks_circuit, true, "počet stacků ze sítě")
    A.eq(body.so_stacks.so_field.enabled, false, "ruční pole zešedlo")
    A.eq(body.so_stacks.so_slider.enabled, false, "posuvník zešedl")
    A.eq(content.so_stacks_signal.so_value.caption, "= 5", "hodnota signálu")
    change(content.so_stacks_signal.so_signal, "elem_value", nil)
    A.eq(mover.stacks_signal, nil, "smazání signálu → výchozí")
    A.eq(content.so_stacks_signal.so_signal.elem_value.name, "signal-N", "tlačítko ukazuje N")

    change(content.so_batch_circuit, "state", true)
    A.eq(behavior.circuit_set_stack_size, true, "velikost stacku ze sítě v entitě")
    A.eq(body.so_batch.so_field.enabled, false, "pole velikosti zešedlo")
    A.eq(content.so_batch_signal.so_value.caption, "= 5", "hodnota signálu S")

    change(body.so_leftovers, "state", true)
    A.eq(mover.leftovers, true, "zbytky zapnuté")
  end },
  { "bez drátu zmizí panel obvodu a pole se odemknou", function()
    entity.get_circuit_network = function() return nil end
    gui.refresh()
    local body, side = parts()
    A.eq(side.so_circuit.visible, false, "panel obvodu skrytý")
    A.eq(body.so_stacks.so_field.enabled, true, "bez drátu platí ruční počet stacků")
    A.eq(body.so_batch.so_field.enabled, true, "i velikost stacku")
    entity.get_circuit_network = red_network
  end },
  { "filtry: zapnutí, listina, předmět a kvalita", function()
    local body = open()
    local head, slots = body.so_filters.so_head, body.so_filters.so_slots_frame.so_slots
    A.eq(slots.so_slot_1.enabled, false, "bez zapnutí filtrů sloty zamčené")
    change(head.so_use, "state", true)
    A.eq(entity.use_filters, true, "filtry zapnuté")
    A.eq(slots.so_slot_1.enabled, true, "sloty odemčené")
    change(head.so_mode, "switch_state", "right")
    A.eq(entity.inserter_filter_mode, "blacklist", "černá listina")

    change(slots.so_slot_2, "elem_value", { name = "iron-plate", quality = "normal" })
    A.eq(filters[2].name, "iron-plate", "předmět ve slotu")
    A.eq(filters[2].quality, nil, "normální kvalita = libovolná")
    change(slots.so_slot_2, "elem_value", { name = "iron-plate", quality = "uncommon" })
    A.eq(filters[2].quality, "uncommon", "konkrétní kvalita")
    A.eq(filters[2].comparator, "=", "přesně tato kvalita")
    change(slots.so_slot_2, "elem_value", nil)
    A.eq(filters[2], nil, "prázdný slot")
  end },
  { "filtry ze sítě zamknou sloty", function()
    behavior.circuit_set_filters = true
    filters[1] = { name = "copper-plate" }
    gui.refresh()
    local body = parts()
    local row = body.so_filters
    A.eq(row.so_head.so_circuit_note.visible, true, "poznámka o síti")
    A.eq(row.so_slots_frame.so_slots.so_slot_1.enabled, false, "sloty zamčené")
    A.eq(row.so_slots_frame.so_slots.so_slot_1.elem_value.name, "copper-plate", "filtr ze sítě zobrazený")
    behavior.circuit_set_filters = false
    filters[1] = nil
  end },
  { "podmínka obvodové sítě se zapíše do entity", function()
    local _, side = open()
    local content = side.so_circuit.so_content
    change(content.so_enable, "state", true)
    A.eq(behavior.circuit_enable_disable, true, "povolit/zakázat")
    local row = content.so_condition
    row.so_first.elem_value = { type = "item", name = "iron-plate" }
    row.so_comparator.selected_index = 4
    change(row.so_constant, "text", "100")
    local condition = behavior.circuit_condition
    A.eq(condition.first_signal.name, "iron-plate", "první signál")
    A.eq(condition.comparator, "≥", "porovnání")
    A.eq(condition.constant, 100, "konstanta")
    change(row.so_second, "elem_value", { type = "virtual", name = "signal-A" })
    A.eq(behavior.circuit_condition.second_signal.name, "signal-A", "druhý signál")
    A.eq(row.so_constant.enabled, false, "s druhým signálem se konstanta nepoužije")
  end },
  { "logistická síť: panel v dosahu a připojení", function()
    logistic_network = {}
    local _, side = open()
    local content = side.so_logistic.so_content
    A.eq(side.so_logistic.visible, true, "v dosahu sítě")
    A.eq(content.so_condition.so_first.enabled, false, "podmínka zamčená bez připojení")
    change(content.so_connect, "state", true)
    A.eq(behavior.connect_to_logistic_network, true, "připojeno")
    A.eq(content.so_condition.so_first.enabled, true, "podmínka povolená")
    logistic_network = nil
  end },
  { "zavření pamatuje polohu, zmizelá budova okno zavře", function()
    open()
    local window = player.gui.screen.so_window
    window.location = { x = 10, y = 20 }
    gui.on_closed({ element = window, player_index = 1 })
    A.eq(player.gui.screen.so_window, nil, "okno zavřené")
    A.eq(storage.gui_target[1], nil, "cíl zapomenut")
    open()
    A.eq(player.gui.screen.so_window.location.y, 20, "poloha obnovena")
    entity.valid = false
    gui.refresh()
    A.eq(player.gui.screen.so_window, nil, "bez budovy se okno zavře")
    entity.valid = true
  end },
  { "křížek zavře okno, mimo dosah se zavře samo", function()
    local screen = player.gui.screen
    open()
    gui.on_click({ element = screen.so_window.so_row.so_main.so_titlebar.so_close, player_index = 1 })
    A.eq(screen.so_window, nil, "křížek")
    open()
    player.can_reach_entity = function() return false end
    gui.refresh()
    A.eq(screen.so_window, nil, "mimo dosah")
    player.can_reach_entity = function() return true end
  end },
  { "po změně konfigurace zmizí panely starší verze", function()
    player.gui.relative.add({ type = "frame", name = "storage_optimizer_panel" })
    player.gui.relative.add({ type = "frame", name = "storage_optimizer_circuit" })
    open()
    gui.reset_all()
    A.eq(player.gui.relative.storage_optimizer_panel, nil, "starý panel")
    A.eq(player.gui.relative.storage_optimizer_circuit, nil, "starý panel obvodu")
    A.eq(player.gui.screen.so_window, nil, "okno zavřené")
  end },
}
