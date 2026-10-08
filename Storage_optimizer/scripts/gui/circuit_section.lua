--- Boční panel „Připojení obvodu“ (jako nativní, jen u budovy připojené drátem): Připojeno k,
--- Povolit/Zakázat s podmínkou, Nastavit filtry, Nastavit velikost stacku a Nastavit počet stacků s řídicím signálem.
--- Podmínku, filtry a signál velikosti stacku drží a vyhodnocuje engine (control behavior entity);
--- počet stacků ze signálu je vlastní volba modu (mover.stacks_circuit / stacks_signal).
local registry = require("scripts.registry")
local transfer = require("scripts.transfer")
local common = require("scripts.gui.common")

local M = {}

--- Šířka panelu v pixelech. Laditelná hodnota.
M.WIDTH = 260

--- Přidá zaškrtávátko s tučným popiskem (nadpis volby jako v nativním panelu).
local function add_option(parent, name, caption, tooltip, action)
  parent.add({ type = "checkbox", name = name, state = false, caption = caption, tooltip = tooltip,
               style = "caption_checkbox", tags = { so = action } })
end

--- Postaví panel do bočního sloupce.
function M.build(side)
  local frame = side.add({ type = "frame", name = "so_circuit", direction = "vertical",
                          caption = { "storage-optimizer-gui.circuit-title" } })
  frame.style.width = M.WIDTH
  local connected = frame.add({ type = "frame", name = "so_connected", style = "subheader_frame" })
  connected.style.horizontally_stretchable = true
  connected.add({ type = "label", name = "so_networks" })
  local content = frame.add({ type = "frame", name = "so_content", direction = "vertical",
                              style = "inside_shallow_frame_with_padding" })
  content.style.horizontally_stretchable = true

  add_option(content, "so_enable", { "storage-optimizer-gui.circuit-enable" }, nil, "circuit_enable")
  common.add_condition_row(content, "so_condition", "circuit_condition")
  common.add_line(content)
  add_option(content, "so_set_filters", { "storage-optimizer-gui.circuit-set-filters" },
    { "storage-optimizer-gui.circuit-set-filters-tooltip" }, "circuit_set_filters")
  common.add_line(content)
  add_option(content, "so_batch_circuit", { "storage-optimizer-gui.batch-circuit" },
    { "storage-optimizer-gui.batch-circuit-tooltip" }, "batch_circuit")
  common.add_signal_row(content, "so_batch_signal", "batch_signal")
  common.add_line(content)
  add_option(content, "so_stacks_circuit", { "storage-optimizer-gui.stacks-circuit" },
    { "storage-optimizer-gui.stacks-circuit-tooltip" }, "stacks_circuit")
  common.add_signal_row(content, "so_stacks_signal", "stacks_signal")
end

--- Naplní panel z control behavior a nastavení optimizeru.
function M.fill(side, mover)
  local content = side.so_circuit.so_content
  local behavior = mover.entity.get_control_behavior()
  content.so_enable.state = behavior and behavior.circuit_enable_disable or false
  common.fill_condition_row(content.so_condition, behavior and behavior.circuit_condition)
  content.so_set_filters.state = behavior and behavior.circuit_set_filters or false
  content.so_batch_circuit.state = behavior and behavior.circuit_set_stack_size or false
  content.so_batch_signal.so_signal.elem_value = behavior and behavior.circuit_stack_control_signal
  content.so_stacks_circuit.state = mover.stacks_circuit == true
  content.so_stacks_signal.so_signal.elem_value = mover.stacks_signal or registry.STACKS_SIGNAL
end

--- Panel je vidět jen s drátem; volby bez zaškrtnutí mají zamčené podřízené prvky.
function M.refresh(side, mover)
  local frame = side.so_circuit
  local entity = mover.entity
  frame.visible = common.wired(entity)
  if not frame.visible then return end
  frame.so_connected.so_networks.caption = { "storage-optimizer-gui.connected-to", common.network_ids(entity) }
  local content = frame.so_content
  local behavior = entity.get_control_behavior()
  local enabled = behavior and behavior.circuit_enable_disable or false
  common.set_condition_enabled(content.so_condition, enabled, behavior and behavior.circuit_condition)

  local batch_circuit = behavior and behavior.circuit_set_stack_size or false
  local batch_row = content.so_batch_signal
  batch_row.so_signal.enabled = batch_circuit
  local batch_value = batch_circuit and common.signal_value(entity, behavior.circuit_stack_control_signal)
  batch_row.so_value.caption = batch_value and ("= " .. batch_value) or ""

  local stacks_row = content.so_stacks_signal
  stacks_row.so_signal.enabled = mover.stacks_circuit == true
  local _, value = transfer.stack_count(mover)
  stacks_row.so_value.caption = value and ("= " .. value) or ""
end

--- Zapíše podmínku z řádku do control behavior.
local function write_condition(event, mover)
  mover.entity.get_or_create_control_behavior().circuit_condition = common.read_condition_row(event.element.parent)
end

--- Obsluha událostí podle tagu `so`.
M.handlers = {
  circuit_enable = function(event, mover)
    mover.entity.get_or_create_control_behavior().circuit_enable_disable = event.element.state
  end,
  circuit_condition_first = write_condition,
  circuit_condition_comparator = write_condition,
  circuit_condition_second = write_condition,
  circuit_condition_constant = write_condition,
  circuit_set_filters = function(event, mover)
    mover.entity.get_or_create_control_behavior().circuit_set_filters = event.element.state
  end,
  --- Velikost stacku ze sítě = nativní „Nastavit velikost štosu“ (engine ji drží v control behavior).
  batch_circuit = function(event, mover)
    mover.entity.get_or_create_control_behavior().circuit_set_stack_size = event.element.state
  end,
  --- Signál velikosti stacku; smazání výběru vrátí výchozí signál enginu.
  batch_signal = function(event, mover)
    local behavior = mover.entity.get_or_create_control_behavior()
    behavior.circuit_stack_control_signal = event.element.elem_value
    event.element.elem_value = behavior.circuit_stack_control_signal
  end,
  --- Počet stacků ze sítě (vlastní volba modu).
  stacks_circuit = function(event, mover)
    mover.stacks_circuit = event.element.state or nil
  end,
  --- Signál počtu stacků; smazání výběru vrátí výchozí signál N.
  stacks_signal = function(event, mover)
    mover.stacks_signal = registry.clean_signal(event.element.elem_value)
    if not mover.stacks_signal then event.element.elem_value = registry.STACKS_SIGNAL end
  end,
}

return M
