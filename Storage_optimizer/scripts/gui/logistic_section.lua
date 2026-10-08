--- Sekce okna „Logistická síť“ (jen v dosahu logistické sítě): připojení a podmínka zapnutí/vypnutí.
--- Podmínku vyhodnocuje engine (skript čte `disabled` z control behavior).
local common = require("scripts.gui.common")

local M = {}

--- Postaví sekci do rodiče.
--- @return LuaGuiElement rámeček sekce
function M.build(parent)
  local frame = parent.add({ type = "frame", name = "so_logistic", direction = "vertical",
                             style = "inside_shallow_frame_with_padding" })
  frame.add({ type = "label", caption = { "storage-optimizer-gui.logistic-title" }, style = "caption_label" })
  frame.add({ type = "checkbox", name = "so_connect", state = false,
              caption = { "storage-optimizer-gui.logistic-connect" }, tags = { so = "logistic_connect" } })
  common.add_condition_row(frame, "so_condition", "logistic_condition")
  return frame
end

--- Naplní sekci z control behavior.
function M.fill(frame, mover)
  local behavior = mover.entity.get_control_behavior()
  frame.so_connect.state = behavior and behavior.connect_to_logistic_network or false
  common.fill_condition_row(frame.so_condition, behavior and behavior.logistic_condition)
end

--- Sekce je vidět v dosahu sítě nebo když je připojení už zapnuté (aby šlo vypnout i mimo dosah).
function M.refresh(frame, mover)
  local entity = mover.entity
  local behavior = entity.get_control_behavior()
  local connected = behavior and behavior.connect_to_logistic_network or false
  frame.visible = connected or common.in_logistic_network(entity)
  if not frame.visible then return end
  common.set_condition_enabled(frame.so_condition, connected, behavior and behavior.logistic_condition)
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
