--- Sdílené stavební prvky okna Storage optimizeru: řádek podmínky (obvodová i logistická síť), řádek
--- „ze sítě + signál + hodnota“ a testy připojení k sítím.
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

--- Leží entita v dosahu logistické sítě své síly?
function M.in_logistic_network(entity)
  return entity.surface.find_logistic_network_by_position(entity.position, entity.force) ~= nil
end

--- Součet signálu z červené a zelené sítě (nil = žádný signál).
function M.signal_value(entity, signal)
  if not signal then return nil end
  return entity.get_signal(signal, RED, GREEN)
end

--- Přidá řádek „☐ ze sítě [signál] = hodnota“ pro parametr řízený signálem.
--- @param parent LuaGuiElement
--- @param name string jméno řádku
--- @param action string prefix akcí (`<action>_circuit`, `<action>_signal`)
--- @param tooltip LocalisedString vysvětlení zaškrtávátka
--- @return LuaGuiElement flow řádku (dítě `so_circuit`, `so_signal`, `so_value`)
function M.add_circuit_row(parent, name, action, tooltip)
  local row = parent.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  row.add({
    type = "checkbox", name = "so_circuit", state = false, caption = { "storage-optimizer-gui.from-circuit" },
    tooltip = tooltip, tags = { so = action .. "_circuit" },
  })
  row.add({ type = "choose-elem-button", name = "so_signal", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action .. "_signal" } })
  row.add({ type = "label", name = "so_value", style = "caption_label" })
  return row
end

--- Přidá řádek podmínky: [signál] [porovnání] [signál nebo konstanta].
--- @param parent LuaGuiElement
--- @param name string jméno řádku
--- @param action string prefix akcí (`<action>_first`, `_comparator`, `_second`, `_constant`)
--- @return LuaGuiElement flow řádku
function M.add_condition_row(parent, name, action)
  local row = parent.add({ type = "flow", name = name, direction = "horizontal" })
  row.style.vertical_align = "center"
  row.add({ type = "choose-elem-button", name = "so_first", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action .. "_first" } })
  row.add({ type = "drop-down", name = "so_comparator", items = M.COMPARATORS, selected_index = 1,
            tags = { so = action .. "_comparator" } })
  row.add({ type = "choose-elem-button", name = "so_second", elem_type = "signal", style = "slot_button_in_shallow_frame",
            tags = { so = action .. "_second" }, tooltip = { "storage-optimizer-gui.second-signal-tooltip" } })
  local constant = row.add({ type = "textfield", name = "so_constant", numeric = true, allow_decimal = false,
                             allow_negative = true, tags = { so = action .. "_constant" } })
  constant.style.width = 80
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
  row.so_constant.enabled = condition.second_signal == nil
end

--- Povolí / zakáže všechny prvky řádku podmínky.
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
