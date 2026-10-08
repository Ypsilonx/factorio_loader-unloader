--- Přenos ručního nastavení (velikost stacku, počet stacků, počet stacků ze sítě a jeho signál, zbytky):
--- blueprinty (tagy), kopírování nastavení, rychlá výměna tieru.
--- Nastavení se předává jako tabulka se stejnými poli jako záznam optimizeru (viz M.TAGS).
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

--- Klíče tagů v blueprintu podle pole nastavení.
M.TAGS = {
  batch = "so_batch",
  stacks = "so_stacks",
  stacks_circuit = "so_stacks_circuit",
  stacks_signal = "so_stacks_signal",
  leftovers = "so_leftovers",
}

--- Vrátí nastavení z tagů stavěné entity (nebo nil, pokud žádné nemá).
function M.settings_from_tags(tags)
  if not tags then return nil end
  local settings, found = {}, false
  for field, tag in pairs(M.TAGS) do
    if tags[tag] then
      settings[field] = tags[tag]
      found = true
    end
  end
  return found and settings or nil
end

--- Ruční nastavení optimizeru (nebo nil, pokud má vše výchozí).
local function settings_of(mover)
  local settings, found = {}, false
  for field in pairs(M.TAGS) do
    if mover[field] ~= nil then
      settings[field] = mover[field]
      found = true
    end
  end
  return found and settings or nil
end

--- Při vytvoření blueprintu zapíše ruční nastavení každého optimizeru do tagů.
function M.on_setup_blueprint(event)
  local blueprint = event.record or event.stack
  if not blueprint then return end
  if blueprint.object_name == "LuaItemStack" and not blueprint.valid_for_read then return end
  for index, entity in pairs(event.mapping.get()) do
    if entity.valid and tiers.is_mover(entity.name) then
      local mover = registry.get(entity.unit_number)
      for field, tag in pairs(M.TAGS) do
        if mover and mover[field] then blueprint.set_blueprint_entity_tag(index, tag, mover[field]) end
      end
    end
  end
end

--- Shift+pravý/levý klik: zkopíruje ruční nastavení mezi dvěma optimizery.
function M.on_pasted(event)
  local source, destination = event.source, event.destination
  if not (tiers.is_mover(source.name) and tiers.is_mover(destination.name)) then return end
  local from, to = registry.get(source.unit_number), registry.get(destination.unit_number)
  if not (from and to) then return end
  to.batch = from.batch
  to.stacks = registry.clean_stacks(destination.name, from.stacks)
  to.stacks_circuit = from.stacks_circuit
  to.stacks_signal = from.stacks_signal
  to.leftovers = from.leftovers
end

--- Klíč pozice pro spárování vytěžené a nově postavené entity.
local function key(entity)
  local p = entity.position
  return entity.surface.index .. ":" .. p.x .. ":" .. p.y
end

--- Zapamatuje si nastavení vytěžené entity; platí jen do konce aktuálního ticku (rychlá výměna tieru).
function M.remember_replaced(entity, mover)
  local settings = settings_of(mover)
  if not settings then return end
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then
    cache = { tick = game.tick, entries = {} }
    storage.replaced = cache
  end
  cache.entries[key(entity)] = settings
end

--- Vyzvedne nastavení entity vytěžené ve stejném ticku na stejné pozici (nebo nil).
function M.take_replaced(entity)
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then return nil end
  local k = key(entity)
  local settings = cache.entries[k]
  cache.entries[k] = nil
  return settings
end

return M
