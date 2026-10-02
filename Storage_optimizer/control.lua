-- Storage Optimizer – napojení událostí na moduly; logika je ve scripts/.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")
local neighbours = require("scripts.neighbours")
local scheduler = require("scripts.scheduler")
local transfer = require("scripts.transfer")
local indicator = require("scripts.indicator")
local persistence = require("scripts.persistence")
local gui = require("scripts.gui")
require("scripts.remote")

--- Založí chybějící tabulky ve storage (nová hra i starší uložená pozice).
local function init_storage()
  storage.movers = storage.movers or {}
  storage.schedule = storage.schedule or {}
  if not (storage.buffer and storage.buffer.valid) then storage.buffer = game.create_inventory(1) end
end

--- Přepočte sousedy a natočí šipku.
local function refresh(mover)
  neighbours.refresh(mover)
  indicator.update_arrow(mover)
end

--- Probudí entitu: přepočte sousedy a má-li zdroj i cíl, naplánuje ji na příští tick.
local function wake(mover)
  refresh(mover)
  if neighbours.complete(mover) then
    scheduler.schedule(mover, game.tick + 1)
  else
    indicator.set(mover, "no_chest")
  end
end

--- Zpracuje entitu v jejím ticku a naplánuje další cyklus; bez zdroje/cíle ji z plánu vyřadí.
local function run(mover)
  local entity = mover.entity
  if not entity.valid then
    indicator.destroy(mover)
    registry.remove(mover.unit_number)
    return
  end
  if entity.direction ~= mover.direction or not neighbours.complete(mover) then refresh(mover) end
  if not neighbours.complete(mover) then
    indicator.set(mover, "no_chest")
    return
  end
  indicator.set(mover, transfer.process(mover))
  scheduler.schedule(mover, game.tick + mover.interval)
end

--- Postavení entity (hráč, robot, platforma, skript): optimizer se zaeviduje, bedna probudí sousedy.
local function on_built(event)
  local entity = event.entity
  if tiers.is_mover(entity.name) then
    local settings = persistence.settings_from_tags(event.tags) or persistence.take_replaced(entity)
    local mover = registry.add(entity, settings)
    -- Engine entitu nepočítá (úspora UPS); podmínky a filtry ze sítě vyhodnocuje dál.
    entity.disabled_by_script = true
    -- Řídicí signál velikosti stacku je enginový výchozí signal-S, počtu stacků signal-N (registry.STACKS_SIGNAL).
    indicator.create(mover)
    wake(mover)
    return
  end
  local box = entity.bounding_box
  local area = { { box.left_top.x - 1, box.left_top.y - 1 }, { box.right_bottom.x + 1, box.right_bottom.y + 1 } }
  for _, other in pairs(entity.surface.find_entities_filtered({ area = area, name = tiers.names() })) do
    local mover = registry.get(other.unit_number)
    if mover and not mover.scheduled_tick then wake(mover) end
  end
end

--- Odstranění optimizeru; při vytěžení si zapamatuje nastavení pro rychlou výměnu tieru ve stejném ticku.
local function on_removed(event)
  local entity = event.entity
  local mover = registry.remove(entity.unit_number)
  if not mover then return end
  indicator.destroy(mover)
  if event.name ~= defines.events.on_entity_died and event.name ~= defines.events.script_raised_destroy then
    persistence.remember_replaced(entity, mover)
  end
end

--- Otočení nebo převrácení hráčem: naplánovaná entita změnu zjistí sama, nečinnou je třeba probudit.
local function on_rotated(event)
  local mover = registry.get(event.entity.unit_number)
  if not mover then return end
  indicator.update_arrow(mover)
  if not mover.scheduled_tick then wake(mover) end
end

--- Po změně modů/nastavení: přepočet intervalů, úklid neplatných záznamů a nový plán.
local function on_configuration_changed()
  init_storage()
  scheduler.clear()
  for unit_number, mover in pairs(storage.movers) do
    if mover.entity.valid then
      mover.interval = tiers.interval(mover.entity.name)
      mover.entity.disabled_by_script = true
      if not (mover.light and mover.light.valid) then indicator.create(mover) end
      wake(mover)
    else
      indicator.destroy(mover)
      storage.movers[unit_number] = nil
    end
  end
  gui.rebuild_all()
end

local mover_filters = {}
for _, name in ipairs(tiers.names()) do mover_filters[#mover_filters + 1] = { filter = "name", name = name } end
-- Postavení bedny nebo stroje probudí sousední optimizery, které na zdroj/cíl čekají.
local built_filters = {}
for _, entity_type in ipairs(neighbours.TYPES) do built_filters[#built_filters + 1] = { filter = "type", type = entity_type } end
for _, f in ipairs(mover_filters) do built_filters[#built_filters + 1] = f end

for _, id in ipairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(id, on_built, built_filters)
end

for _, id in ipairs({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_space_platform_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(id, on_removed, mover_filters)
end

script.on_event({ defines.events.on_player_rotated_entity, defines.events.on_player_flipped_entity }, on_rotated)
script.on_event(defines.events.on_tick, function(event) scheduler.run(event.tick, run) end)
script.on_event(defines.events.on_player_setup_blueprint, persistence.on_setup_blueprint)
script.on_event(defines.events.on_entity_settings_pasted, persistence.on_pasted)
script.on_event(defines.events.on_player_created, function(event) gui.ensure(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_gui_opened, gui.on_opened)
script.on_event(defines.events.on_gui_text_changed, gui.on_text_changed)
script.on_event(defines.events.on_gui_checked_state_changed, gui.on_checked_state_changed)
script.on_event(defines.events.on_gui_elem_changed, gui.on_elem_changed)
-- Obnova otevřených panelů; bez otevřeného okna jen jedna kontrola prázdné tabulky.
script.on_nth_tick(gui.REFRESH_TICKS, gui.refresh)
script.on_init(function()
  init_storage()
  gui.rebuild_all()
end)
script.on_configuration_changed(on_configuration_changed)
