--- Řada filtrů hlavního okna (jako v nativním okně): vlevo „Používat filtry“ a přepínač bílá/černá listina,
--- vpravo sloty předmětů. Kvalita se vybírá přímo ve slotu; normální kvalita = libovolná kvalita
--- (filtr bez kvality), vyšší kvalita = přesně tato kvalita.
--- Filtry se ukládají přímo do entity (use_filters, inserter_filter_mode, set_filter) – přenos v blueprintech
--- a kopírování nastavení tak zajišťuje engine.
local common = require("scripts.gui.common")

local M = {}

--- Kvalita, která ve slotu znamená „libovolná kvalita“.
local ANY_QUALITY = "normal"

--- Postaví řadu do těla okna.
--- @param body LuaGuiElement
--- @param slots integer počet slotů filtru entity
function M.build(body, slots)
  common.add_line(body)
  local row = body.add({ type = "flow", name = "so_filters", direction = "horizontal" })
  row.style.vertical_align = "center"
  local left = row.add({ type = "flow", name = "so_head", direction = "vertical" })
  left.add({ type = "checkbox", name = "so_use", state = false, caption = { "storage-optimizer-gui.use-filters" },
             tags = { so = "filters_use" } })
  left.add({ type = "switch", name = "so_mode", switch_state = "left",
             left_label_caption = { "storage-optimizer-gui.whitelist" },
             right_label_caption = { "storage-optimizer-gui.blacklist" }, tags = { so = "filters_mode" } })
  left.add({ type = "label", name = "so_circuit_note", caption = { "storage-optimizer-gui.filters-circuit" } })
  row.add({ type = "empty-widget" }).style.horizontally_stretchable = true
  local frame = row.add({ type = "frame", name = "so_slots_frame", style = "slot_button_deep_frame" })
  local table = frame.add({ type = "table", name = "so_slots", column_count = slots, style = "filter_slot_table" })
  for slot = 1, slots do
    table.add({ type = "choose-elem-button", name = "so_slot_" .. slot, elem_type = "item-with-quality",
                style = "slot_button", tags = { so = "filter_slot", slot = slot } })
  end
end

--- Naplní řadu z filtrů entity.
function M.fill(body, mover)
  local entity = mover.entity
  local head = body.so_filters.so_head
  head.so_use.state = entity.use_filters
  head.so_mode.switch_state = entity.inserter_filter_mode == "blacklist" and "right" or "left"
  M.show_filters(body, entity)
end

--- Zobrazí filtry entity ve slotech.
function M.show_filters(body, entity)
  local slots = body.so_filters.so_slots_frame.so_slots
  for slot = 1, entity.filter_slot_count do
    local filter = entity.get_filter(slot)
    slots["so_slot_" .. slot].elem_value = filter and { name = filter.name, quality = filter.quality or ANY_QUALITY }
  end
end

--- Obnoví zešednutí: filtry ze sítě zamknou ruční úpravy (engine je přepisuje podle signálů).
function M.refresh(body, mover)
  local entity = mover.entity
  local behavior = entity.get_control_behavior()
  local from_circuit = common.wired(entity) and behavior and behavior.circuit_set_filters or false
  local head = body.so_filters.so_head
  head.so_circuit_note.visible = from_circuit
  head.so_use.enabled = not from_circuit
  local editable = not from_circuit and entity.use_filters
  head.so_mode.enabled = editable or from_circuit
  -- Filtry ze sítě se mění s každou změnou signálů, proto se jen zobrazují.
  if from_circuit then M.show_filters(body, entity) end
  local slots = body.so_filters.so_slots_frame.so_slots
  for slot = 1, entity.filter_slot_count do slots["so_slot_" .. slot].enabled = editable end
end

--- Obsluha událostí podle tagu `so`.
M.handlers = {
  --- Zapnutí / vypnutí filtrů.
  filters_use = function(event, mover)
    mover.entity.use_filters = event.element.state
  end,
  --- Bílá (vlevo) / černá (vpravo) listina.
  filters_mode = function(event, mover)
    mover.entity.inserter_filter_mode = event.element.switch_state == "right" and "blacklist" or "whitelist"
  end,
  --- Předmět s kvalitou ve slotu; normální kvalita = libovolná.
  filter_slot = function(event, mover)
    local value = event.element.elem_value
    local filter = nil
    if value then
      filter = { name = value.name }
      if value.quality and value.quality ~= ANY_QUALITY then
        filter.quality = value.quality
        filter.comparator = "="
      end
    end
    mover.entity.set_filter(event.element.tags.slot, filter)
  end,
}

return M
