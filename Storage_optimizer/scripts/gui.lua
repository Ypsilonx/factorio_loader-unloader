--- Boční panely u nativního okna inserteru:
---   1. „Storage optimizer“ – tier, trasa, stav, velikost stacku, počet stacků;
---   2. „Připojení obvodu – Storage optimizer“ – počet stacků ze sítě (jen u budovy připojené drátem).
--- Dokud má hráč okno otevřené, panely se obnovují (stav, hodnota signálu, zešednutí polí řízených sítí).
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")
local transfer = require("scripts.transfer")

local M = {}

local FRAME = "storage_optimizer_panel"
local CIRCUIT_FRAME = "storage_optimizer_circuit"

--- Jak často se otevřené panely obnovují (ticky). Laditelná hodnota.
M.REFRESH_TICKS = 15

--- Přidá do relative GUI rámeček ukotvený vpravo od okna inserteru (jen pro entity tohoto modu).
local function anchored_frame(relative, name, caption)
  if relative[name] then relative[name].destroy() end
  local frame = relative.add({
    type = "frame",
    name = name,
    direction = "vertical",
    caption = caption,
    anchor = {
      gui = defines.relative_gui_type.inserter_gui,
      position = defines.relative_gui_position.right,
      names = tiers.names(),
    },
  })
  return frame.add({ type = "frame", name = "so_inner", direction = "vertical", style = "inside_shallow_frame_with_padding" })
end

--- Vytvoří (znovu) oba panely hráče.
function M.ensure(player)
  local inner = anchored_frame(player.gui.relative, FRAME, { "storage-optimizer-gui.title" })
  inner.add({ type = "label", name = "so_tier" })
  inner.add({ type = "label", name = "so_route" })
  inner.add({ type = "label", name = "so_state" })
  inner.add({ type = "line" })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.batch" }, style = "caption_label" })
  inner.add({ type = "textfield", name = "so_batch", numeric = true, allow_decimal = false, allow_negative = false })
  inner.add({ type = "label", name = "so_batch_hint" })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.stacks" }, style = "caption_label" })
  inner.add({ type = "textfield", name = "so_stacks", numeric = true, allow_decimal = false, allow_negative = false })
  inner.add({ type = "label", name = "so_stacks_hint" })

  -- Obdoba nativní volby „Nastavit velikost štosu“ pro počet stacků (do nativního okna ji přidat nejde).
  local circuit = anchored_frame(player.gui.relative, CIRCUIT_FRAME, { "storage-optimizer-gui.circuit-title" })
  circuit.add({
    type = "checkbox",
    name = "so_stacks_circuit",
    state = false,
    caption = { "storage-optimizer-gui.stacks-circuit" },
    tooltip = { "storage-optimizer-gui.stacks-circuit-tooltip" },
    style = "caption_checkbox",
  })
  local row = circuit.add({ type = "flow", name = "so_signal_row", direction = "horizontal" })
  row.style.vertical_align = "center"
  row.add({ type = "label", caption = { "storage-optimizer-gui.stacks-signal" } })
  row.add({ type = "choose-elem-button", name = "so_stacks_signal", elem_type = "signal" })
  row.add({ type = "label", name = "so_stacks_value", style = "caption_label" })
end

--- Znovu vytvoří panely všech hráčů (po změně konfigurace se mohou změnit jména tierů).
function M.rebuild_all()
  for _, player in pairs(game.players) do M.ensure(player) end
end

--- Lokalizovaný název bedny, které patří inventář (nebo „nic“).
local function owner_name(inventory)
  if inventory and inventory.valid then return inventory.entity_owner.localised_name end
  return { "storage-optimizer-gui.none" }
end

--- Je entita připojená k obvodové síti (červeným nebo zeleným drátem)?
local function wired(entity)
  return entity.get_circuit_network(defines.wire_connector_id.circuit_red) ~= nil
    or entity.get_circuit_network(defines.wire_connector_id.circuit_green) ~= nil
end

--- Obnoví proměnlivé části panelů (stav, hodnota signálu, zešednutí polí). Textová pole nepřepisuje,
--- aby hráči nemazala rozepsanou hodnotu.
local function refresh_dynamic(player, mover)
  local frame, circuit = player.gui.relative[FRAME], player.gui.relative[CIRCUIT_FRAME]
  if not (frame and circuit) then return end
  local entity = mover.entity
  local inner = frame.so_inner
  local info = tiers.all()[entity.name]
  inner.so_tier.caption = { "storage-optimizer-gui.tier", info.tier, string.format("%.2f", info.interval / 60) }
  inner.so_route.caption = { "storage-optimizer-gui.route", owner_name(mover.source), owner_name(mover.target) }
  inner.so_state.caption = { "storage-optimizer-gui.state", { "storage-optimizer-state." .. (mover.state or "no_chest") } }

  -- Velikost stacku řídí nativní volba „Nastavit velikost štosu“.
  local behavior = entity.get_control_behavior()
  local batch_from_circuit = behavior and behavior.circuit_set_stack_size or false
  inner.so_batch.enabled = not batch_from_circuit
  inner.so_batch_hint.caption = batch_from_circuit and { "storage-optimizer-gui.batch-circuit" }
    or { "storage-optimizer-gui.batch-hint" }

  -- Počet stacků řídí naše volba „Počet stacků ze sítě“.
  local count, value = transfer.stack_count(mover)
  inner.so_stacks.enabled = not mover.stacks_circuit
  inner.so_stacks_hint.caption = mover.stacks_circuit
    and { "storage-optimizer-gui.stacks-effective", count, tiers.max_stacks(entity.name) }
    or { "storage-optimizer-gui.stacks-hint", tiers.max_stacks(entity.name),
      string.format("%.0f", tiers.cost(entity.name, count) / 1000), tiers.energy_kj(entity.name) }

  circuit.visible = wired(entity)
  local row = circuit.so_inner.so_signal_row
  row.so_stacks_signal.enabled = mover.stacks_circuit == true
  row.so_stacks_value.caption = value and ("= " .. value) or ""
end

--- Naplní panely údaji o otevřené entitě a zapamatuje si, kterou entitu hráč upravuje.
function M.update(player, mover)
  local frame, circuit = player.gui.relative[FRAME], player.gui.relative[CIRCUIT_FRAME]
  -- Panel ze starší verze modu (bez on_configuration_changed, např. při vývoji) se přestaví.
  if not (frame and circuit and frame.so_inner and frame.so_inner.so_batch_hint) then
    M.ensure(player)
    frame, circuit = player.gui.relative[FRAME], player.gui.relative[CIRCUIT_FRAME]
  end
  frame.so_inner.so_batch.text = mover.batch and tostring(mover.batch) or ""
  frame.so_inner.so_stacks.text = tostring(mover.stacks or 1)
  circuit.so_inner.so_stacks_circuit.state = mover.stacks_circuit == true
  circuit.so_inner.so_signal_row.so_stacks_signal.elem_value = mover.stacks_signal or registry.STACKS_SIGNAL
  refresh_dynamic(player, mover)
  storage.gui_target = storage.gui_target or {}
  storage.gui_target[player.index] = mover.unit_number
end

--- Periodické obnovení otevřených panelů; hráče, kteří okno zavřeli, vyřadí.
function M.refresh()
  if not (storage.gui_target and next(storage.gui_target)) then return end
  for player_index, unit_number in pairs(storage.gui_target) do
    local player = game.get_player(player_index)
    local mover = registry.get(unit_number)
    if player and mover and mover.entity.valid and player.opened == mover.entity then
      refresh_dynamic(player, mover)
    else
      storage.gui_target[player_index] = nil
    end
  end
end

--- Otevření okna entity: pokud jde o optimizer, naplní panely.
function M.on_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and tiers.is_mover(entity.name)) then return end
  local mover = registry.get(entity.unit_number)
  if mover then M.update(game.get_player(event.player_index), mover) end
end

--- Optimizer, jehož panel má hráč otevřený, pokud událost patří prvku tohoto modu s daným jménem (jinak nil).
local function target(event, names)
  local element = event.element
  if not (element and element.valid and names[element.name] and element.get_mod() == script.mod_name) then return nil end
  local unit_number = storage.gui_target and storage.gui_target[event.player_index]
  return unit_number and registry.get(unit_number)
end

--- Změna textu v panelu: velikost stacku (prázdné, 0 nebo nečíslo = Auto) nebo počet stacků (omezený limitem).
function M.on_text_changed(event)
  local mover = target(event, { so_batch = true, so_stacks = true })
  if not mover then return end
  local element = event.element
  if element.name == "so_batch" then
    mover.batch = registry.clean_batch(element.text)
  else
    mover.stacks = registry.clean_stacks(mover.entity.name, element.text)
  end
end

--- Zaškrtnutí „Počet stacků ze sítě“: uloží volbu a hned zešedne / povolí ruční pole.
function M.on_checked_state_changed(event)
  local mover = target(event, { so_stacks_circuit = true })
  if not mover then return end
  mover.stacks_circuit = event.element.state or nil
  refresh_dynamic(game.get_player(event.player_index), mover)
end

--- Výběr řídicího signálu počtu stacků; smazání výběru vrátí výchozí signál „Počet stacků“.
function M.on_elem_changed(event)
  local mover = target(event, { so_stacks_signal = true })
  if not mover then return end
  mover.stacks_signal = registry.clean_signal(event.element.elem_value)
  if not mover.stacks_signal then event.element.elem_value = registry.STACKS_SIGNAL end
  refresh_dynamic(game.get_player(event.player_index), mover)
end

return M
