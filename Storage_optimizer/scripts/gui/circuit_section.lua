--- Sekce okna „Obvodová síť“ (jen u budovy připojené drátem): podmínka zapnutí/vypnutí a filtry ze sítě.
--- Nastavení drží engine v control behavior entity a podmínku sám vyhodnocuje (skript čte `disabled`).
--- Velikost a počet stacků ze signálu jsou v sekci přesunu u svých polí.
local common = require("scripts.gui.common")

local M = {}

--- Postaví sekci do rodiče.
--- @return LuaGuiElement rámeček sekce
function M.build(parent)
  local frame = parent.add({ type = "frame", name = "so_circuit", direction = "vertical",
                             style = "inside_shallow_frame_with_padding" })
  frame.add({ type = "label", caption = { "storage-optimizer-gui.circuit-title" }, style = "caption_label" })
  frame.add({ type = "checkbox", name = "so_enable", state = false, caption = { "storage-optimizer-gui.circuit-enable" },
              tags = { so = "circuit_enable" } })
  common.add_condition_row(frame, "so_condition", "circuit_condition")
  frame.add({ type = "checkbox", name = "so_set_filters", state = false,
              caption = { "storage-optimizer-gui.circuit-set-filters" },
              tooltip = { "storage-optimizer-gui.circuit-set-filters-tooltip" }, tags = { so = "circuit_set_filters" } })
  return frame
end

--- Naplní sekci z control behavior.
function M.fill(frame, mover)
  local behavior = mover.entity.get_control_behavior()
  frame.so_enable.state = behavior and behavior.circuit_enable_disable or false
  common.fill_condition_row(frame.so_condition, behavior and behavior.circuit_condition)
  frame.so_set_filters.state = behavior and behavior.circuit_set_filters or false
end

--- Sekce je vidět jen s drátem; podmínka se upravuje jen při zapnutém „Zapnout/vypnout“.
function M.refresh(frame, mover)
  local entity = mover.entity
  frame.visible = common.wired(entity)
  if not frame.visible then return end
  local behavior = entity.get_control_behavior()
  local enabled = behavior and behavior.circuit_enable_disable or false
  common.set_condition_enabled(frame.so_condition, enabled, behavior and behavior.circuit_condition)
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
}

return M
