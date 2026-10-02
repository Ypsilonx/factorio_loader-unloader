--- Boční panel u nativního okna inserteru: tier, trasa, stav a velikost dávky.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

local FRAME = "storage_optimizer_panel"

--- Vytvoří (znovu) panel hráče ukotvený vpravo od okna inserteru, jen pro entity tohoto modu.
function M.ensure(player)
  local relative = player.gui.relative
  if relative[FRAME] then relative[FRAME].destroy() end
  local frame = relative.add({
    type = "frame",
    name = FRAME,
    direction = "vertical",
    caption = { "storage-optimizer-gui.title" },
    anchor = {
      gui = defines.relative_gui_type.inserter_gui,
      position = defines.relative_gui_position.right,
      names = tiers.names(),
    },
  })
  local inner = frame.add({ type = "frame", name = "inner", direction = "vertical", style = "inside_shallow_frame_with_padding" })
  inner.add({ type = "label", name = "tier" })
  inner.add({ type = "label", name = "route" })
  inner.add({ type = "label", name = "state" })
  inner.add({ type = "line" })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.batch" }, style = "caption_label" })
  inner.add({ type = "textfield", name = "so_batch", numeric = true, allow_decimal = false, allow_negative = false })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.batch-hint" } })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.stacks" }, style = "caption_label" })
  inner.add({ type = "textfield", name = "so_stacks", numeric = true, allow_decimal = false, allow_negative = false })
  inner.add({ type = "label", name = "stacks_hint" })
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

--- Naplní panel údaji o otevřené entitě a zapamatuje si, kterou entitu hráč upravuje.
function M.update(player, mover)
  local frame = player.gui.relative[FRAME]
  if not frame then return end
  local inner = frame.inner
  local info = tiers.all()[mover.entity.name]
  inner.tier.caption = { "storage-optimizer-gui.tier", info.tier, string.format("%.2f", info.interval / 60) }
  inner.route.caption = { "storage-optimizer-gui.route", owner_name(mover.source), owner_name(mover.target) }
  inner.state.caption = { "storage-optimizer-gui.state", { "storage-optimizer-state." .. (mover.state or "no_chest") } }
  inner.so_batch.text = mover.batch and tostring(mover.batch) or ""
  inner.so_stacks.text = tostring(mover.stacks or 1)
  inner.stacks_hint.caption = { "storage-optimizer-gui.stacks-hint", tiers.max_stacks(mover.entity.name) }
  storage.gui_target = storage.gui_target or {}
  storage.gui_target[player.index] = mover.unit_number
end

--- Otevření okna entity: pokud jde o optimizer, naplní panel.
function M.on_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and tiers.is_mover(entity.name)) then return end
  local mover = registry.get(entity.unit_number)
  if mover then M.update(game.get_player(event.player_index), mover) end
end

--- Změna textu v panelu: velikost dávky (prázdné, 0 nebo nečíslo = Auto) nebo počet stacků (omezený limitem).
function M.on_text_changed(event)
  local element = event.element
  if element.get_mod() ~= script.mod_name or (element.name ~= "so_batch" and element.name ~= "so_stacks") then return end
  local unit_number = storage.gui_target and storage.gui_target[event.player_index]
  local mover = unit_number and registry.get(unit_number)
  if not mover then return end
  if element.name == "so_batch" then
    mover.batch = registry.clean_batch(element.text)
  else
    mover.stacks = registry.clean_stacks(mover.entity.name, element.text)
  end
end

return M
