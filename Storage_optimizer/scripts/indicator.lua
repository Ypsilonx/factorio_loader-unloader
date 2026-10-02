--- Vizuální indikace: ikonka stavu (mění se jen při změně stavu) a šipka směru v alt režimu.
local M = {}

--- Sprite ikonky pro každý stav.
local SPRITES = {
  working = "utility/status_working",
  waiting = "utility/status_yellow",
  no_power = "utility/status_not_working",
  disabled = "utility/status_not_working",
  no_chest = "utility/status_not_working",
}

--- Barva diody stavu v okně entity.
local DIODES = {
  working = defines.entity_status_diode.green,
  waiting = defines.entity_status_diode.yellow,
  no_power = defines.entity_status_diode.red,
  disabled = defines.entity_status_diode.red,
  no_chest = defines.entity_status_diode.red,
}

--- Zobrazí stav modu v nativním okně entity místo enginového „Vypnuto skriptem“ (entita je pro engine vypnutá).
local function apply_status(mover)
  mover.entity.custom_status = { diode = DIODES[mover.state], label = { "storage-optimizer-state." .. mover.state } }
end

--- Orientace šipky (0–1) ze směru entity; šipka míří k cíli, tj. opačně než ke zdroji.
function M.orientation(direction)
  return (direction / 16 + 0.5) % 1
end

--- Vytvoří ikonku stavu a šipku pro novou entitu.
function M.create(mover)
  local entity = mover.entity
  mover.state = "no_chest"
  apply_status(mover)
  mover.light = rendering.draw_sprite({
    sprite = SPRITES.no_chest,
    target = { entity = entity, offset = { 0.25, -0.25 } },
    surface = entity.surface,
    x_scale = 0.35,
    y_scale = 0.35,
    render_layer = "entity-info-icon",
  })
  mover.arrow = rendering.draw_sprite({
    sprite = "utility/indication_arrow",
    target = entity,
    surface = entity.surface,
    orientation = M.orientation(entity.direction),
    only_in_alt_mode = true,
    render_layer = "entity-info-icon",
  })
end

--- Nastaví stav; vykreslení se mění jen při skutečné změně.
function M.set(mover, state)
  if mover.state == state then return end
  mover.state = state
  apply_status(mover)
  if mover.light and mover.light.valid then mover.light.sprite = SPRITES[state] end
end

--- Natočí šipku podle aktuálního směru entity.
function M.update_arrow(mover)
  if mover.arrow and mover.arrow.valid then mover.arrow.orientation = M.orientation(mover.entity.direction) end
end

--- Odstraní vykreslené objekty entity.
function M.destroy(mover)
  for _, key in ipairs({ "light", "arrow" }) do
    local object = mover[key]
    if object and object.valid then object.destroy() end
  end
end

return M
