---@diagnostic disable: lowercase-global
--- Test okna Storage optimizeru bez hry: herní GUI prvky (LuaGuiElement) nahrazuje jednoduchá napodobenina,
--- takže se ověří, že scripts/gui.lua a sekce v scripts/gui/ okno staví, plní, obnovují, obsluhují události
--- a zapisují nastavení do entity. (Headless Factorio nemá hráče, okno se v integračních testech nevytvoří.)
local A = require("assert")

--- Napodobenina LuaGuiElement: děti dostupné podle jména, add/destroy/get_mod, tags, style a běžné vlastnosti.
local function element(spec, parent)
  local e = {}
  for key, value in pairs(spec) do e[key] = value end
  e.parent, e.enabled, e.visible, e.valid = parent, true, true, true
  e.text, e.style, e.children, e.tags = "", {}, {}, spec.tags or {}
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
  quality = {
    normal = { level = 0, hidden = false, localised_name = "normal" },
    uncommon = { level = 1, hidden = false, localised_name = "uncommon" },
    ["quality-unknown"] = { level = 0, hidden = true, localised_name = "?" },
  },
}
defines = {
  wire_connector_id = { circuit_red = 1, circuit_green = 2 },
  controllers = { character = 1, god = 0 },
}
script = { mod_name = "Storage_optimizer" }
storage = { movers = {} }

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
  get_circuit_network = function(id) return id == 1 and {} or nil end,
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

--- Otevře okno jako událost on_gui_opened a vrátí jeho tělo.
local function open()
  gui.on_opened({ entity = entity, player_index = 1 })
  return player.gui.screen.so_window.so_body
end

--- Nastaví hodnotu prvku a pošle událost změny (jako hra).
local function change(target, field, value)
  target[field] = value
  gui.on_changed({ element = target, player_index = 1 })
end

return {
  { "okno se otevře místo nativního a naplní", function()
    local body = open()
    local window = player.gui.screen.so_window
    A.eq(player.opened, window, "hráč má otevřené naše okno")
    A.eq(storage.gui_target[1], 1, "okno patří optimizeru")
    A.eq(window.auto_center, true, "první otevření uprostřed")
    local transfer = body.so_transfer
    A.eq(transfer.so_stacks.so_field.text, "3", "ruční počet stacků")
    A.eq(transfer.so_batch.so_field.text, "", "prázdná velikost stacku = podle materiálu")
    A.eq(transfer.so_leftovers.state, false, "zbytky vypnuté")
    A.eq(transfer.so_energy.so_bar.value, 0.5, "pruh energie")
    A.eq(transfer.so_stacks_circuit.visible, true, "řádek „ze sítě“ u budovy s drátem")
    A.eq(transfer.so_stacks_circuit.so_signal.elem_value.name, "signal-N", "výchozí signál počtu stacků")
    A.eq(body.so_circuit.visible, true, "sekce obvodové sítě s drátem")
    A.eq(body.so_logistic.visible, false, "mimo logistickou síť skrytá")
  end },
  { "obyčejná entita okno neotevře", function()
    gui.close(player)
    gui.on_opened({ entity = { valid = true, name = "inserter" }, player_index = 1 })
    A.eq(player.gui.screen.so_window, nil, "bez okna")
  end },
  { "velikost a počet stacků: ručně i ze sítě", function()
    local transfer = open().so_transfer
    change(transfer.so_stacks.so_field, "text", "50")
    A.eq(mover.stacks, 20, "počet stacků omezený limitem")
    change(transfer.so_batch.so_field, "text", "300")
    A.eq(mover.batch, 300, "ruční velikost stacku")
    change(transfer.so_batch.so_field, "text", "")
    A.eq(mover.batch, nil, "prázdné = podle materiálu")

    change(transfer.so_stacks_circuit.so_circuit, "state", true)
    A.eq(mover.stacks_circuit, true, "počet stacků ze sítě")
    A.eq(transfer.so_stacks.so_field.enabled, false, "ruční pole zešedlo")
    A.eq(transfer.so_stacks_circuit.so_value.caption, "= 5", "hodnota signálu")
    change(transfer.so_stacks_circuit.so_signal, "elem_value", nil)
    A.eq(mover.stacks_signal, nil, "smazání signálu → výchozí")
    A.eq(transfer.so_stacks_circuit.so_signal.elem_value.name, "signal-N", "tlačítko ukazuje N")

    change(transfer.so_batch_circuit.so_circuit, "state", true)
    A.eq(behavior.circuit_set_stack_size, true, "velikost stacku ze sítě v entitě")
    A.eq(transfer.so_batch.so_field.enabled, false, "pole velikosti zešedlo")
    A.eq(transfer.so_batch_circuit.so_value.caption, "= 5", "hodnota signálu S")

    change(transfer.so_leftovers, "state", true)
    A.eq(mover.leftovers, true, "zbytky zapnuté")
  end },
  { "bez drátu zmizí řádky „ze sítě“ i sekce obvodu", function()
    entity.get_circuit_network = function() return nil end
    gui.refresh()
    local body = player.gui.screen.so_window.so_body
    A.eq(body.so_transfer.so_stacks_circuit.visible, false, "řádek skrytý")
    A.eq(body.so_transfer.so_stacks.so_field.enabled, true, "bez drátu platí ruční pole")
    A.eq(body.so_circuit.visible, false, "sekce obvodu skrytá")
    entity.get_circuit_network = function(id) return id == 1 and {} or nil end
  end },
  { "filtry: zapnutí, režim, předmět a kvalita", function()
    local section = open().so_filters
    A.eq(section.so_slot_1.so_item.enabled, false, "bez zapnutí filtrů sloty zamčené")
    change(section.so_head.so_use, "state", true)
    A.eq(entity.use_filters, true, "filtry zapnuté")
    change(section.so_head.so_mode, "switch_state", "right")
    A.eq(entity.inserter_filter_mode, "blacklist", "zakázat")

    local row = section.so_slot_2
    change(row.so_item, "elem_value", "iron-plate")
    A.eq(filters[2].name, "iron-plate", "předmět ve slotu")
    A.eq(filters[2].quality, nil, "libovolná kvalita")
    A.eq(row.so_comparator.enabled, false, "porovnání jen u konkrétní kvality")
    row.so_comparator.selected_index = 4
    change(row.so_quality, "selected_index", 3)
    A.eq(filters[2].quality, "uncommon", "kvalita")
    A.eq(filters[2].comparator, "≥", "porovnání kvality")
    change(row.so_item, "elem_value", nil)
    A.eq(filters[2], nil, "prázdný slot")
  end },
  { "filtry ze sítě zamknou sloty", function()
    behavior.circuit_set_filters = true
    gui.refresh()
    local section = player.gui.screen.so_window.so_body.so_filters
    A.eq(section.so_circuit_note.visible, true, "poznámka o síti")
    A.eq(section.so_slot_1.so_item.enabled, false, "sloty zamčené")
    behavior.circuit_set_filters = false
  end },
  { "podmínka obvodové sítě se zapíše do entity", function()
    local section = open().so_circuit
    change(section.so_enable, "state", true)
    A.eq(behavior.circuit_enable_disable, true, "zapnout/vypnout")
    local row = section.so_condition
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
  { "logistická síť: sekce v dosahu a připojení", function()
    logistic_network = {}
    local section = open().so_logistic
    A.eq(section.visible, true, "v dosahu sítě")
    A.eq(section.so_condition.so_first.enabled, false, "podmínka zamčená bez připojení")
    change(section.so_connect, "state", true)
    A.eq(behavior.connect_to_logistic_network, true, "připojeno")
    A.eq(section.so_condition.so_first.enabled, true, "podmínka povolená")
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
    local window = player.gui.screen
    open()
    gui.on_click({ element = window.so_window.so_titlebar.so_close, player_index = 1 })
    A.eq(window.so_window, nil, "křížek")
    open()
    player.can_reach_entity = function() return false end
    gui.refresh()
    A.eq(window.so_window, nil, "mimo dosah")
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
