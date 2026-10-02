---@diagnostic disable: lowercase-global
--- Test bočních panelů bez hry: herní GUI prvky (LuaGuiElement) nahrazuje jednoduchá napodobenina,
--- takže se ověří, že gui.lua staví, plní a obnovuje panely se správnými cestami k prvkům.
--- (Headless Factorio nemá hráče, panely se v integračních testech nevytvoří.)
local A = require("assert")

--- Napodobenina LuaGuiElement: děti dostupné podle jména, add/destroy/get_mod, style a běžné vlastnosti.
local function element(spec, parent)
  local e = { type = spec.type, name = spec.name, caption = spec.caption, state = spec.state, parent = parent,
              enabled = true, visible = true, text = "", style = {}, children = {} }
  function e.add(child_spec)
    local child = element(child_spec, e)
    e.children[#e.children + 1] = child
    if child_spec.name then e[child_spec.name] = child end
    return child
  end
  function e.destroy()
    if parent and e.name then parent[e.name] = nil end
  end
  function e.get_mod() return "Storage_optimizer" end
  e.valid = true
  return e
end

local NAME = "storage-optimizer-transport-belt"
prototypes = {
  mod_data = { ["storage-optimizer-tiers"] = { data = { [NAME] = { tier = 1, interval = 60, energy = 20000, extra_stack_energy = 5000, max_stacks = 20 } } } },
}
defines = {
  relative_gui_type = { inserter_gui = 1 },
  relative_gui_position = { right = 1 },
  wire_connector_id = { circuit_red = 1, circuit_green = 2 },
}
script = { mod_name = "Storage_optimizer" }
storage = { movers = {} }

local signal_value = 5
local behavior = { circuit_set_stack_size = false }
local entity = {
  name = NAME, valid = true,
  get_control_behavior = function() return behavior end,
  get_circuit_network = function(id) return id == 1 and {} or nil end,
  get_signal = function() return signal_value end,
}
local mover = { entity = entity, unit_number = 1, state = "working", stacks = 3 }
storage.movers[1] = mover

local function new_player()
  return { index = 1, gui = { relative = element({ type = "root" }) }, opened = entity }
end
local player = new_player()
game = { players = { player }, get_player = function() return player end }

local gui = require("scripts.gui")

--- Rámečky panelů hráče.
local function frames()
  return player.gui.relative.storage_optimizer_panel.so_inner, player.gui.relative.storage_optimizer_circuit
end

return {
  { "panel se postaví a naplní", function()
    gui.ensure(player)
    gui.update(player, mover)
    local main, circuit = frames()
    A.eq(main.so_stacks.text, "3", "ruční počet stacků")
    A.eq(main.so_stacks.enabled, true, "ruční pole povolené")
    A.eq(circuit.visible, true, "rámeček obvodu u budovy s drátem")
    A.eq(circuit.so_inner.so_signal_row.so_stacks_value.caption, "", "bez řízení sítí se hodnota nezobrazuje")
  end },
  { "řízení sítí zešedne pole a ukáže hodnotu signálu", function()
    mover.stacks_circuit = true
    behavior.circuit_set_stack_size = true
    gui.refresh()
    local main, circuit = frames()
    A.eq(main.so_stacks.enabled, false, "počet stacků zešedl")
    A.eq(main.so_batch.enabled, false, "velikost stacku zešedla")
    A.eq(circuit.so_inner.so_signal_row.so_stacks_value.caption, "= 5", "hodnota signálu")
  end },
  { "rámeček obvodu se skryje bez drátu", function()
    entity.get_circuit_network = function() return nil end
    gui.refresh()
    local _, circuit = frames()
    A.eq(circuit.visible, false, "bez drátu skrytý")
    A.eq(player.gui.relative.visible, true, "kořen relative GUI zůstává viditelný")
  end },
  { "obsluha zaškrtávátka, výběru signálu a textových polí", function()
    entity.get_circuit_network = function(id) return id == 1 and {} or nil end
    mover.stacks_circuit = nil
    gui.update(player, mover)
    local main, circuit = frames()
    local checkbox = circuit.so_inner.so_stacks_circuit
    checkbox.state = true
    gui.on_checked_state_changed({ element = checkbox, player_index = 1 })
    A.eq(mover.stacks_circuit, true, "volba uložena")
    A.eq(main.so_stacks.enabled, false, "pole hned zešedlo")

    local chooser = circuit.so_inner.so_signal_row.so_stacks_signal
    chooser.elem_value = { type = "virtual", name = "signal-A" }
    gui.on_elem_changed({ element = chooser, player_index = 1 })
    A.eq(mover.stacks_signal.name, "signal-A", "vlastní signál")
    chooser.elem_value = nil
    gui.on_elem_changed({ element = chooser, player_index = 1 })
    A.eq(mover.stacks_signal, nil, "smazání → výchozí signál")
    A.eq(chooser.elem_value.name, "signal-N", "tlačítko ukazuje výchozí signál N")

    main.so_stacks.text = "50"
    gui.on_text_changed({ element = main.so_stacks, player_index = 1 })
    A.eq(mover.stacks, 20, "počet stacků omezený limitem")
    main.so_batch.text = ""
    gui.on_text_changed({ element = main.so_batch, player_index = 1 })
    A.eq(mover.batch, nil, "prázdná velikost stacku = Auto")
  end },
  { "zastaralý panel ze starší verze se při otevření přestaví", function()
    player = new_player()
    local old = player.gui.relative.add({ type = "frame", name = "storage_optimizer_panel" })
    old.add({ type = "frame", name = "so_inner" }).add({ type = "textfield", name = "so_batch" })
    gui.update(player, mover)
    local main, circuit = frames()
    A.truthy(main.so_batch_hint and circuit, "panel přestavěn na aktuální strukturu")
  end },
}
