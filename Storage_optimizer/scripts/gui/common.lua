--- Sdílené stavební prvky okna Storage optimizeru (napodobují nativní okno inserteru): řádek podmínky
--- (obvodová i logistická síť), řádek „Řídicí signál [signál] = hodnota“ a testy připojení k sítím.
--- Interaktivní prvky nesou tag `so` = jméno akce; okno (scripts/gui.lua) podle něj volá obsluhu sekce.
local M = {}

local RED = defines.wire_connector_id.circuit_red
local GREEN = defines.wire_connector_id.circuit_green

--- Porovnání v pořadí rozbalovacího seznamu (stejné jako v nativním okně).
M.COMPARATORS = { ">", "<", "=", "≥", "≤", "≠" }
--- Zápisy porovnání, které engine také přijímá, převedené na tvar ze seznamu.
local COMPARATOR_ALIASES = { [">="] = "≥", ["<="] = "≤", ["!="] = "≠" }

--- Je entita připojená k obvodové síti (červeným nebo zeleným drátem)?
function M.wired(entity)
  return entity.get_circuit_network(RED) ~= nil or entity.get_circuit_network(GREEN) ~= nil
end

--- Čísla připojených sítí jako rich text („Připojeno k:“ v nativním okně): červená a zelená.
--- @return string
function M.network_ids(entity)
  local parts = {}
  local red, green = entity.get_circuit_network(RED), entity.get_circuit_network(GREEN)
  if red then parts[#parts + 1] = "[color=red]" .. red.network_id .. "[/color]" end
  if green then parts[#parts + 1] = "[color=green]" .. green.network_id .. "[/color]" end
  return table.concat(parts, " ")
end

--- Leží entita v dosahu logistické sítě své síly?
function M.in_logistic_network(entity)
  return entity.surface.find_logistic_network_by_position(entity.position, entity.force) ~= nil
end

--- Součet signálu z červené a zelené sítě (nil = žádný signál).
function M.signal_value(entity, signal)
  if not signal then return nil end
  return entity.get_signal(signal, RED, GREEN)
end

--- Přidá vodorovnou čáru oddělující sekce (jako v nativním okně).
function M.add_line(parent)
  parent.add({ type = "line", direction = "horizontal" })
end

--- Přidá řádek „Řídicí signál [signál] = hodnota“ (jako u nativního „Nastavit velikost štosu“).
--- @param parent LuaGuiElement
--- @param name string jméno řádku
--- @param action string akce tlačítka signálu
--- @return LuaGuiElement flow řádku (děti `so_signal`, `so_value`)
function M.add_signal_row(parent, name, action)
  local row = parent.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  row.style.left_margin = 24
  row.add({ type = "label", caption = { "storage-optimizer-gui.control-signal" } })
  row.add({ type = "empty-widget" }).style.horizontally_stretchable = true
  row.add({ type = "label", name = "so_value", style = "caption_label" })
  row.add({ type = "choose-elem-button", name = "so_signal", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action } })
  return row
end

--- Přidá řádek podmínky: [signál] [porovnání] [signál] [číslo].
--- @param parent LuaGuiElement
--- @param name string jméno řádku
--- @param action string prefix akcí (`<action>_first`, `_comparator`, `_second`, `_constant`)
--- @return LuaGuiElement flow řádku
function M.add_condition_row(parent, name, action)
  local row = parent.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  row.style.left_margin = 24
  row.add({ type = "choose-elem-button", name = "so_first", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action .. "_first" } })
  row.add({ type = "drop-down", name = "so_comparator", items = M.COMPARATORS, selected_index = 2,
            style = "circuit_condition_comparator_dropdown", tags = { so = action .. "_comparator" } })
  row.add({ type = "choose-elem-button", name = "so_second", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action .. "_second" }, tooltip = { "storage-optimizer-gui.second-signal-tooltip" } })
  local constant = row.add({ type = "textfield", name = "so_constant", numeric = true, allow_decimal = false,
                             allow_negative = true, tags = { so = action .. "_constant" } })
  constant.style.width = 60
  constant.style.horizontal_align = "center"
  return row
end

--- Index porovnání v seznamu (neznámé = „<“, výchozí podmínka enginu).
local function comparator_index(comparator)
  comparator = COMPARATOR_ALIASES[comparator] or comparator
  for index, value in ipairs(M.COMPARATORS) do
    if value == comparator then return index end
  end
  return 2
end

--- Naplní řádek podmínky z CircuitConditionDefinition (při otevření okna).
function M.fill_condition_row(row, condition)
  condition = condition or {}
  row.so_first.elem_value = condition.first_signal
  row.so_comparator.selected_index = comparator_index(condition.comparator)
  row.so_second.elem_value = condition.second_signal
  row.so_constant.text = tostring(condition.constant or 0)
end

--- Povolí / zakáže prvky řádku podmínky; číslo platí jen bez druhého signálu.
function M.set_condition_enabled(row, enabled, condition)
  row.so_first.enabled = enabled
  row.so_comparator.enabled = enabled
  row.so_second.enabled = enabled
  row.so_constant.enabled = enabled and not (condition and condition.second_signal)
end

--- Sestaví novou podmínku z hodnot řádku (po změně kteréhokoliv prvku).
--- @return table CircuitCondition
function M.read_condition_row(row)
  return {
    first_signal = row.so_first.elem_value,
    comparator = M.COMPARATORS[row.so_comparator.selected_index] or "<",
    second_signal = row.so_second.elem_value,
    constant = tonumber(row.so_constant.text) or 0,
  }
end

return M
