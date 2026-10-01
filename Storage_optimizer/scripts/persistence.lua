--- Přenos ručně nastavené velikosti dávky: blueprinty (tagy), kopírování nastavení, rychlá výměna tieru.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

--- Klíč tagu v blueprintu.
M.TAG = "so_batch"

--- Vrátí velikost dávky z tagů stavěné entity (nebo nil).
function M.batch_from_tags(tags)
  return tags and tags[M.TAG] or nil
end

--- Při vytvoření blueprintu zapíše dávku každého optimizeru do tagů.
function M.on_setup_blueprint(event)
  local blueprint = event.record or event.stack
  if not blueprint then return end
  if blueprint.object_name == "LuaItemStack" and not blueprint.valid_for_read then return end
  for index, entity in pairs(event.mapping.get()) do
    if entity.valid and tiers.is_mover(entity.name) then
      local mover = registry.get(entity.unit_number)
      if mover and mover.batch then blueprint.set_blueprint_entity_tag(index, M.TAG, mover.batch) end
    end
  end
end

--- Shift+pravý/levý klik: zkopíruje dávku mezi dvěma optimizery.
function M.on_pasted(event)
  local source, destination = event.source, event.destination
  if not (tiers.is_mover(source.name) and tiers.is_mover(destination.name)) then return end
  local from, to = registry.get(source.unit_number), registry.get(destination.unit_number)
  if from and to then to.batch = from.batch end
end

--- Klíč pozice pro spárování vytěžené a nově postavené entity.
local function key(entity)
  local p = entity.position
  return entity.surface.index .. ":" .. p.x .. ":" .. p.y
end

--- Zapamatuje si dávku vytěžené entity; platí jen do konce aktuálního ticku (rychlá výměna tieru).
function M.remember_replaced(entity, batch)
  if not batch then return end
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then
    cache = { tick = game.tick, entries = {} }
    storage.replaced = cache
  end
  cache.entries[key(entity)] = batch
end

--- Vyzvedne dávku entity vytěžené ve stejném ticku na stejné pozici (nebo nil).
function M.take_replaced(entity)
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then return nil end
  local k = key(entity)
  local batch = cache.entries[k]
  cache.entries[k] = nil
  return batch
end

return M
