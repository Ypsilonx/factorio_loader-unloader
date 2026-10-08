--- Sekce okna „Filtry“: zapnutí filtrů, povolit/zakázat a sloty předmětů (s kvalitou, je-li ve hře víc kvalit).
--- Filtry se ukládají přímo do entity (use_filters, inserter_filter_mode, set_filter) – přenos v blueprintech
--- a kopírování nastavení tak zajišťuje engine.
local common = require("scripts.gui.common")

local M = {}

--- Viditelné kvality seřazené podle úrovně (načtené líně; prototypy se za běhu nemění).
local qualities

--- Vrátí seznam jmen viditelných kvalit.
local function quality_list()
  if not qualities then
    qualities = {}
    for name, quality in pairs(prototypes.quality) do
      if not quality.hidden then qualities[#qualities + 1] = name end
    end
    table.sort(qualities, function(a, b) return prototypes.quality[a].level < prototypes.quality[b].level end)
  end
  return qualities
end

--- Položky rozbalovacího seznamu kvality: „libovolná“ a pak kvality s ikonou.
local function quality_items()
  local items = { { "storage-optimizer-gui.any-quality" } }
  for _, name in ipairs(quality_list()) do
    items[#items + 1] = { "", "[quality=" .. name .. "] ", prototypes.quality[name].localised_name }
  end
  return items
end

--- Postaví sekci do rodiče.
--- @param slots integer počet slotů filtru entity
--- @return LuaGuiElement rámeček sekce
function M.build(parent, slots)
  local frame = parent.add({ type = "frame", name = "so_filters", direction = "vertical",
                             style = "inside_shallow_frame_with_padding" })
  local head = frame.add({ type = "flow", name = "so_head", direction = "horizontal" })
  head.style.vertical_align = "center"
  head.add({ type = "checkbox", name = "so_use", state = false, caption = { "storage-optimizer-gui.use-filters" },
             style = "caption_checkbox", tags = { so = "filters_use" } })
  head.add({ type = "empty-widget" }).style.horizontally_stretchable = true
  head.add({ type = "switch", name = "so_mode", switch_state = "left",
             left_label_caption = { "storage-optimizer-gui.whitelist" },
             right_label_caption = { "storage-optimizer-gui.blacklist" }, tags = { so = "filters_mode" } })
  frame.add({ type = "label", name = "so_circuit_note", caption = { "storage-optimizer-gui.filters-circuit" } })

  local with_quality = #quality_list() > 1
  for slot = 1, slots do
    local row = frame.add({ type = "flow", name = "so_slot_" .. slot, direction = "horizontal" })
    row.style.vertical_align = "center"
    row.add({ type = "choose-elem-button", name = "so_item", elem_type = "item", style = "slot_button_in_shallow_frame",
              tags = { so = "filter_item", slot = slot } })
    if with_quality then
      row.add({ type = "drop-down", name = "so_comparator", items = common.COMPARATORS, selected_index = 3,
                tags = { so = "filter_quality", slot = slot } })
      row.add({ type = "drop-down", name = "so_quality", items = quality_items(), selected_index = 1,
                tags = { so = "filter_quality", slot = slot } })
    end
  end
  return frame
end

--- Index kvality v rozbalovacím seznamu (1 = libovolná).
local function quality_index(name)
  if not name then return 1 end
  for index, quality in ipairs(quality_list()) do
    if quality == name then return index + 1 end
  end
  return 1
end

--- Naplní sekci z filtrů entity.
function M.fill(frame, mover)
  local entity = mover.entity
  frame.so_head.so_use.state = entity.use_filters
  frame.so_head.so_mode.switch_state = entity.inserter_filter_mode == "blacklist" and "right" or "left"
  for slot = 1, entity.filter_slot_count do
    local row = frame["so_slot_" .. slot]
    local filter = entity.get_filter(slot)
    row.so_item.elem_value = filter and filter.name
    if row.so_quality then
      row.so_quality.selected_index = quality_index(filter and filter.quality)
      local comparator = filter and filter.comparator or "="
      for index, value in ipairs(common.COMPARATORS) do
        if value == comparator then row.so_comparator.selected_index = index end
      end
    end
  end
end

--- Obnoví zešednutí: filtry ze sítě zamknou ruční úpravy (engine je přepisuje podle signálů).
function M.refresh(frame, mover)
  local entity = mover.entity
  local behavior = entity.get_control_behavior()
  local from_circuit = common.wired(entity) and behavior and behavior.circuit_set_filters or false
  frame.so_circuit_note.visible = from_circuit
  frame.so_head.so_use.enabled = not from_circuit
  local editable = not from_circuit and entity.use_filters
  frame.so_head.so_mode.enabled = editable or from_circuit
  for slot = 1, entity.filter_slot_count do
    local row = frame["so_slot_" .. slot]
    if from_circuit then
      -- Filtry ze sítě se jen zobrazují (mění se s každou změnou signálů).
      local filter = entity.get_filter(slot)
      row.so_item.elem_value = filter and filter.name
    end
    row.so_item.enabled = editable
    if row.so_quality then
      row.so_quality.enabled = editable
      row.so_comparator.enabled = editable and row.so_quality.selected_index > 1
    end
  end
end

--- Zapíše filtr jednoho slotu z prvků řádku do entity.
local function write_slot(entity, row, slot)
  local item = row.so_item.elem_value
  if not item then
    entity.set_filter(slot, nil)
    return
  end
  local filter = { name = item }
  if row.so_quality and row.so_quality.selected_index > 1 then
    filter.quality = quality_list()[row.so_quality.selected_index - 1]
    filter.comparator = common.COMPARATORS[row.so_comparator.selected_index]
  end
  entity.set_filter(slot, filter)
end

--- Obsluha událostí podle tagu `so`.
M.handlers = {
  --- Zapnutí / vypnutí filtrů.
  filters_use = function(event, mover)
    mover.entity.use_filters = event.element.state
  end,
  --- Povolit (vlevo) / zakázat (vpravo).
  filters_mode = function(event, mover)
    mover.entity.inserter_filter_mode = event.element.switch_state == "right" and "blacklist" or "whitelist"
  end,
  --- Předmět nebo kvalita slotu.
  filter_item = function(event, mover)
    write_slot(mover.entity, event.element.parent, event.element.tags.slot)
  end,
  filter_quality = function(event, mover)
    write_slot(mover.entity, event.element.parent, event.element.tags.slot)
  end,
}

return M
