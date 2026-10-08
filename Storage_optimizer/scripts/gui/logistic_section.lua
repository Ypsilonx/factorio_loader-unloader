--- Boční panel „Logistická síť“ (jako nativní, jen v dosahu logistické sítě nebo při zapnutém připojení):
--- připojení a podmínka zapnutí/vypnutí. Podmínku vyhodnocuje engine (skript čte `disabled`).
local common = require("scripts.gui.common")
local circuit_section = require("scripts.gui.circuit_section")

local M = {}

--- Postaví panel do bočního sloupce.
function M.build(side)
  local frame = side.add({ type = "frame", name = "so_logistic", direction = "vertical",
                          caption = { "storage-optimizer-gui.logistic-title" } })
  frame.style.width = circuit_section.WIDTH
  local content = frame.add({ type = "frame", name = "so_content", direction = "vertical",
                              style = "inside_shallow_frame_with_padding" })
  content.style.horizontally_stretchable = true
  content.add({ type = "checkbox", name = "so_connect", state = false, style = "caption_checkbox",
                caption = { "storage-optimizer-gui.logistic-connect" }, tags = { so = "logistic_connect" } })
  common.add_condition_row(content, "so_condition", "logistic_condition")
end

--- Naplní panel z control behavior.
function M.fill(side, mover)
  local content = side.so_logistic.so_content
  local behavior = mover.entity.get_control_behavior()
  content.so_connect.state = behavior and behavior.connect_to_logistic_network or false
  common.fill_condition_row(content.so_condition, behavior and behavior.logistic_condition)
end

--- Panel je vidět v dosahu sítě nebo když je připojení zapnuté (aby šlo vypnout i mimo dosah).
function M.refresh(side, mover)
  local frame = side.so_logistic
  local entity = mover.entity
  local behavior = entity.get_control_behavior()
  local connected = behavior and behavior.connect_to_logistic_network or false
  frame.visible = connected or common.in_logistic_network(entity)
  if not frame.visible then return end
  common.set_condition_enabled(frame.so_content.so_condition, connected, behavior and behavior.logistic_condition)
end

--- Zapíše podmínku z řádku do control behavior.
local function write_condition(event, mover)
  mover.entity.get_or_create_control_behavior().logistic_condition = common.read_condition_row(event.element.parent)
end

--- Obsluha událostí podle tagu `so`.
M.handlers = {
  logistic_connect = function(event, mover)
    mover.entity.get_or_create_control_behavior().connect_to_logistic_network = event.element.state
  end,
  logistic_condition_first = write_condition,
  logistic_condition_comparator = write_condition,
  logistic_condition_second = write_condition,
  logistic_condition_constant = write_condition,
}

return M
