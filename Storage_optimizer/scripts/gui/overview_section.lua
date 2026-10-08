--- Horní část hlavního okna (jako v nativním okně): stav s barevnou tečkou, živý náhled budovy,
--- pod ním tier, trasa „zdroj → cíl“, cena přesunu a pruh energie.
local tiers = require("scripts.tiers")
local transfer = require("scripts.transfer")

local M = {}

--- Šířka náhledu budovy v pixelech (jako nativní okno). Laditelná hodnota.
M.PREVIEW_WIDTH = 400
--- Výška náhledu budovy v pixelech. Laditelná hodnota.
M.PREVIEW_HEIGHT = 148

--- Tečka stavu podle stavu optimizeru (stejné sprity jako nativní okna).
local STATUS_SPRITES = {
  working = "utility/status_working",
  waiting = "utility/status_yellow",
}

--- Lokalizovaný název vlastníka inventáře (bedna, vagón, stroj) nebo „nic“.
local function owner_name(inventory)
  if inventory and inventory.valid then return inventory.entity_owner.localised_name end
  return { "storage-optimizer-gui.none" }
end

--- Postaví část do těla okna.
function M.build(body)
  local status = body.add({ type = "flow", name = "so_status_row", direction = "horizontal" })
  status.style.vertical_align = "center"
  status.add({ type = "sprite", name = "so_status_icon", style = "status_image" })
  status.add({ type = "label", name = "so_status" })

  local frame = body.add({ type = "frame", name = "so_preview_frame", style = "deep_frame_in_shallow_frame" })
  local preview = frame.add({ type = "entity-preview", name = "so_preview" })
  preview.style.width = M.PREVIEW_WIDTH
  preview.style.height = M.PREVIEW_HEIGHT

  body.add({ type = "label", name = "so_info" })
  body.add({ type = "label", name = "so_route" })
  local energy = body.add({ type = "flow", name = "so_energy", direction = "horizontal" })
  energy.style.vertical_align = "center"
  energy.add({ type = "label", caption = { "storage-optimizer-gui.energy" } })
  local bar = energy.add({ type = "progressbar", name = "so_bar", value = 0 })
  bar.style.horizontally_stretchable = true
end

--- Napojí náhled na entitu.
function M.fill(body, mover)
  body.so_preview_frame.so_preview.entity = mover.entity
end

--- Obnoví stav, informace a energii.
function M.refresh(body, mover)
  local entity = mover.entity
  local state = mover.state or "no_chest"
  body.so_status_row.so_status_icon.sprite = STATUS_SPRITES[state] or "utility/status_not_working"
  body.so_status_row.so_status.caption = { "storage-optimizer-state." .. state }

  local info = tiers.all()[entity.name]
  local count = transfer.stack_count(mover)
  body.so_info.caption = { "storage-optimizer-gui.info", info.tier, string.format("%.2f", info.interval / 60),
    string.format("%.1f", tiers.cost(entity.name, count) / 1000) }
  body.so_route.caption = { "storage-optimizer-gui.route", owner_name(mover.source), owner_name(mover.target) }
  local buffer = entity.electric_buffer_size
  body.so_energy.so_bar.value = (buffer and buffer > 0) and math.min(entity.energy / buffer, 1) or 0
end

M.handlers = {}

return M
