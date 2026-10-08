--- Sekce okna „Přesun“: tier, trasa, stav, energie, velikost stacku a počet stacků (ručně nebo ze signálu)
--- a přepínač „Přesouvat i zbytky“.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")
local transfer = require("scripts.transfer")
local common = require("scripts.gui.common")

local M = {}

--- Lokalizovaný název vlastníka inventáře (bedna, vagón, stroj) nebo „nic“.
local function owner_name(inventory)
  if inventory and inventory.valid then return inventory.entity_owner.localised_name end
  return { "storage-optimizer-gui.none" }
end

--- Přidá řádek s popiskem a číselným polem.
local function add_number_row(parent, name, caption, action)
  local row = parent.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  local label = row.add({ type = "label", caption = caption })
  label.style.width = 150
  local field = row.add({ type = "textfield", name = "so_field", numeric = true, allow_decimal = false,
                          allow_negative = false, tags = { so = action } })
  field.style.width = 80
  return row
end

--- Postaví sekci do rodiče.
--- @return LuaGuiElement rámeček sekce
function M.build(parent)
  local frame = parent.add({ type = "frame", name = "so_transfer", direction = "vertical",
                             style = "inside_shallow_frame_with_padding" })
  frame.add({ type = "label", name = "so_tier" })
  frame.add({ type = "label", name = "so_route" })
  frame.add({ type = "label", name = "so_status" })
  local energy = frame.add({ type = "flow", name = "so_energy", direction = "horizontal" })
  energy.style.vertical_align = "center"
  energy.add({ type = "label", caption = { "storage-optimizer-gui.energy" } })
  local bar = energy.add({ type = "progressbar", name = "so_bar", value = 0 })
  bar.style.horizontally_stretchable = true
  frame.add({ type = "line" })

  add_number_row(frame, "so_batch", { "storage-optimizer-gui.batch" }, "batch")
  common.add_circuit_row(frame, "so_batch_circuit", "batch", { "storage-optimizer-gui.batch-circuit-tooltip" })
  frame.add({ type = "label", name = "so_batch_hint" })

  add_number_row(frame, "so_stacks", { "storage-optimizer-gui.stacks" }, "stacks")
  common.add_circuit_row(frame, "so_stacks_circuit", "stacks", { "storage-optimizer-gui.stacks-circuit-tooltip" })
  frame.add({ type = "label", name = "so_stacks_hint" })

  frame.add({ type = "line" })
  frame.add({ type = "checkbox", name = "so_leftovers", state = false, caption = { "storage-optimizer-gui.leftovers" },
              tooltip = { "storage-optimizer-gui.leftovers-tooltip" }, tags = { so = "leftovers" } })
  return frame
end

--- Naplní editovatelné prvky z nastavení (jen při otevření – rozepsaný text se pak nepřepisuje).
function M.fill(frame, mover)
  local behavior = mover.entity.get_control_behavior()
  frame.so_batch.so_field.text = mover.batch and tostring(mover.batch) or ""
  frame.so_stacks.so_field.text = tostring(mover.stacks or 1)
  frame.so_batch_circuit.so_circuit.state = behavior and behavior.circuit_set_stack_size or false
  frame.so_batch_circuit.so_signal.elem_value = behavior and behavior.circuit_stack_control_signal
  frame.so_stacks_circuit.so_circuit.state = mover.stacks_circuit == true
  frame.so_stacks_circuit.so_signal.elem_value = mover.stacks_signal or registry.STACKS_SIGNAL
  frame.so_leftovers.state = mover.leftovers == true
end

--- Obnoví proměnlivé části: stav, energie, hodnoty signálů, zešednutí polí řízených sítí.
function M.refresh(frame, mover)
  local entity = mover.entity
  local info = tiers.all()[entity.name]
  frame.so_tier.caption = { "storage-optimizer-gui.tier", info.tier, string.format("%.2f", info.interval / 60) }
  frame.so_route.caption = { "storage-optimizer-gui.route", owner_name(mover.source), owner_name(mover.target) }
  frame.so_status.caption = { "storage-optimizer-gui.state", { "storage-optimizer-state." .. (mover.state or "no_chest") } }
  local buffer = entity.electric_buffer_size
  frame.so_energy.so_bar.value = (buffer and buffer > 0) and math.min(entity.energy / buffer, 1) or 0

  local wired = common.wired(entity)
  local behavior = entity.get_control_behavior()
  local batch_circuit = wired and behavior and behavior.circuit_set_stack_size or false
  local batch_row = frame.so_batch_circuit
  batch_row.visible = wired
  batch_row.so_signal.enabled = batch_circuit
  local batch_value = batch_circuit and common.signal_value(entity, behavior.circuit_stack_control_signal)
  batch_row.so_value.caption = batch_value and ("= " .. batch_value) or ""
  frame.so_batch.so_field.enabled = not batch_circuit
  frame.so_batch_hint.caption = { "storage-optimizer-gui.batch-hint" }

  local stacks_circuit = wired and mover.stacks_circuit == true
  local count, value = transfer.stack_count(mover)
  local stacks_row = frame.so_stacks_circuit
  stacks_row.visible = wired
  stacks_row.so_signal.enabled = stacks_circuit
  stacks_row.so_value.caption = (stacks_circuit and value) and ("= " .. value) or ""
  frame.so_stacks.so_field.enabled = not stacks_circuit
  local base, extra = tiers.energy_kj(entity.name)
  frame.so_stacks_hint.caption = { "storage-optimizer-gui.stacks-hint", count, tiers.max_stacks(entity.name),
    string.format("%.0f", tiers.cost(entity.name, count) / 1000), base, extra }
end

--- Obsluha událostí podle tagu `so` (volá okno; po ní se okno obnoví).
M.handlers = {
  --- Velikost stacku: prázdné, 0 nebo nečíslo = podle materiálu.
  batch = function(event, mover)
    mover.batch = registry.clean_batch(event.element.text)
  end,
  --- Počet stacků (omezený limitem tieru).
  stacks = function(event, mover)
    mover.stacks = registry.clean_stacks(mover.entity.name, event.element.text)
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
  --- Přesouvat i zbytky (neúplný přesun, když zdroj nemá celou dávku nebo cíl nemá místo).
  leftovers = function(event, mover)
    mover.leftovers = event.element.state or nil
  end,
}

return M
