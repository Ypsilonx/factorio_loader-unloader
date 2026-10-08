--- Vlastní okno Storage optimizeru místo nativního okna inserteru (to by ukazovalo volby, které optimizer
--- nepoužívá, např. „Číst obsah ruky“). Rozložení napodobuje nativní okno: vlevo hlavní okno (stav, náhled,
--- filtry, velikost a počet stacků, zbytky), vpravo boční panely „Připojení obvodu“ a „Logistická síť“.
--- Části jsou v scripts/gui/.
--- Nastavení filtrů a podmínek zůstává v entitě (engine je přenáší v blueprintech a vyhodnocuje),
--- okno je jen čte a zapisuje. Dokud je okno otevřené, obnovuje se stav, energie a hodnoty signálů.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")
local overview_section = require("scripts.gui.overview_section")
local transfer_section = require("scripts.gui.transfer_section")
local filters_section = require("scripts.gui.filters_section")
local circuit_section = require("scripts.gui.circuit_section")
local logistic_section = require("scripts.gui.logistic_section")

local M = {}

local WINDOW = "so_window"
--- Panely u nativního okna z verzí do 0.3.x (při změně konfigurace se odstraní).
local LEGACY_FRAMES = { "storage_optimizer_panel", "storage_optimizer_circuit" }

--- Jak často se otevřená okna obnovují (ticky). Laditelná hodnota.
M.REFRESH_TICKS = 15
--- Mezera mezi hlavním oknem a bočními panely a mezi panely navzájem (px; 0 = přilepené jako nativní okno).
--- Laditelná hodnota.
M.PANEL_SPACING = 0

--- Části okna v pořadí zobrazení: { kam patří ("body" = hlavní okno, "side" = boční sloupec), modul }.
local SECTIONS = {
  { "body", overview_section },
  { "body", filters_section },
  { "body", transfer_section },
  { "side", circuit_section },
  { "side", logistic_section },
}

--- Obsluha všech sekcí podle tagu `so` prvku.
local HANDLERS = {}
for _, section in ipairs(SECTIONS) do
  for action, handler in pairs(section[2].handlers) do HANDLERS[action] = handler end
end

--- Otevřené okno hráče (nebo nil).
local function window(player)
  local frame = player.gui.screen[WINDOW]
  return (frame and frame.valid) and frame or nil
end

--- Přidá titulek hlavního okna: název budovy, plocha pro přetažení (táhne celé okno) a křížek.
local function add_titlebar(frame, caption, drag_target)
  local bar = frame.add({ type = "flow", name = "so_titlebar", direction = "horizontal" })
  bar.drag_target = drag_target
  bar.style.horizontal_spacing = 8
  bar.add({ type = "label", caption = caption, style = "frame_title", ignored_by_interaction = true })
  local drag = bar.add({ type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true })
  drag.style.height = 24
  drag.style.horizontally_stretchable = true
  bar.add({ type = "sprite-button", name = "so_close", sprite = "utility/close", style = "frame_action_button",
            tags = { so = "close" } })
end

--- Rodiče částí okna: { body = tělo hlavního okna, side = boční sloupec }.
local function parts(frame)
  local row = frame.so_row
  return { body = row.so_main.so_body, side = row.so_side }
end

--- Obnoví proměnlivé části okna.
local function refresh_window(frame, mover)
  local parents = parts(frame)
  for _, section in ipairs(SECTIONS) do section[2].refresh(parents[section[1]], mover) end
end

--- Zavře okno hráče a zapamatuje si jeho polohu.
function M.close(player)
  local frame = window(player)
  if frame then
    storage.gui_location = storage.gui_location or {}
    storage.gui_location[player.index] = frame.location
    frame.destroy()
  end
  if storage.gui_target then storage.gui_target[player.index] = nil end
end

--- Otevře okno optimizeru (nahradí nativní okno entity).
--- @param player LuaPlayer
--- @param mover table záznam optimizeru
function M.open(player, mover)
  M.close(player)
  local entity = mover.entity
  -- Neviditelný rámeček drží hlavní okno a boční panely vedle sebe; přetahuje se a centruje jako celek.
  local frame = player.gui.screen.add({ type = "frame", name = WINDOW, style = "invisible_frame" })
  local row = frame.add({ type = "flow", name = "so_row", direction = "horizontal" })
  row.style.horizontal_spacing = M.PANEL_SPACING
  local main = row.add({ type = "frame", name = "so_main", direction = "vertical" })
  add_titlebar(main, entity.localised_name, frame)
  local body = main.add({ type = "frame", name = "so_body", direction = "vertical", style = "entity_frame" })
  local side = row.add({ type = "flow", name = "so_side", direction = "vertical" })
  side.style.vertical_spacing = M.PANEL_SPACING

  overview_section.build(body)
  filters_section.build(body, entity.filter_slot_count)
  transfer_section.build(body, tiers.max_stacks(entity.name))
  circuit_section.build(side)
  logistic_section.build(side)
  local parents = parts(frame)
  for _, section in ipairs(SECTIONS) do section[2].fill(parents[section[1]], mover) end
  refresh_window(frame, mover)

  local location = storage.gui_location and storage.gui_location[player.index]
  if location then frame.location = location else frame.auto_center = true end
  -- Přiřazení zavře nativní okno entity; E/Esc pak zavírá naše okno (on_gui_closed).
  player.opened = frame
  storage.gui_target = storage.gui_target or {}
  storage.gui_target[player.index] = mover.unit_number
end

--- Otevření okna entity: u optimizeru místo nativního okna otevře vlastní.
function M.on_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and tiers.is_mover(entity.name)) then return end
  local mover = registry.get(entity.unit_number)
  if mover then M.open(game.get_player(event.player_index), mover) end
end

--- Zavření (E, Esc, otevření jiného okna): u našeho okna ho zruší.
function M.on_closed(event)
  local element = event.element
  if element and element.valid and element.name == WINDOW and element.get_mod() == script.mod_name then
    M.close(game.get_player(event.player_index))
  end
end

--- Optimizer, jehož okno má hráč otevřené (nebo nil).
local function opened_mover(player_index)
  local unit_number = storage.gui_target and storage.gui_target[player_index]
  local mover = unit_number and registry.get(unit_number)
  return (mover and mover.entity.valid) and mover or nil
end

--- Prvek tohoto modu s akcí (tag `so`), nebo nil.
local function action_of(element)
  if not (element and element.valid and element.get_mod() == script.mod_name) then return nil end
  return element.tags.so
end

--- Klik: jen křížek okna (ostatní prvky reagují na své vlastní události, ne na klik).
function M.on_click(event)
  if action_of(event.element) == "close" then M.close(game.get_player(event.player_index)) end
end

--- Změna prvku okna (text, zaškrtnutí, signál, výběr, přepínač): uloží nastavení a obnoví okno.
function M.on_changed(event)
  local handler = HANDLERS[action_of(event.element)]
  if not handler then return end
  local player = game.get_player(event.player_index)
  local mover = opened_mover(event.player_index)
  if not mover then
    M.close(player)
    return
  end
  handler(event, mover, player)
  local frame = window(player)
  if frame then refresh_window(frame, mover) end
end

--- Periodické obnovení otevřených oken; zavře okna, jejichž budova zmizela nebo je mimo dosah hráče.
function M.refresh()
  if not (storage.gui_target and next(storage.gui_target)) then return end
  for player_index in pairs(storage.gui_target) do
    local player = game.get_player(player_index)
    local mover = opened_mover(player_index)
    local frame = player and window(player)
    local reachable = mover and (player.controller_type ~= defines.controllers.character
      or player.can_reach_entity(mover.entity))
    if frame and reachable then
      refresh_window(frame, mover)
    elseif player then
      M.close(player)
    else
      storage.gui_target[player_index] = nil
    end
  end
end

--- Po změně konfigurace: zavře okna (struktura se mohla změnit) a odstraní panely starších verzí.
function M.reset_all()
  for _, player in pairs(game.players) do
    M.close(player)
    for _, name in ipairs(LEGACY_FRAMES) do
      local legacy = player.gui.relative[name]
      if legacy then legacy.destroy() end
    end
  end
end

return M
