--- Plánovač: každý optimizer se zpracuje jen v ticku, kdy je na řadě (jádro úspory UPS).
--- storage.schedule[tick] = { unit_number, … }; mover.scheduled_tick brání dvojímu naplánování.
local M = {}

--- Zařadí entitu ke zpracování v daném ticku (pokud už naplánovaná není).
function M.schedule(mover, tick)
  if mover.scheduled_tick then return end
  local bucket = storage.schedule[tick]
  if not bucket then
    bucket = {}
    storage.schedule[tick] = bucket
  end
  bucket[#bucket + 1] = mover.unit_number
  mover.scheduled_tick = tick
end

--- Vyjme seznam pro daný tick a pro každou stále evidovanou entitu zavolá handler.
--- @param tick integer
--- @param handler fun(mover: table)
function M.run(tick, handler)
  local bucket = storage.schedule[tick]
  if not bucket then return end
  storage.schedule[tick] = nil
  for _, unit_number in ipairs(bucket) do
    local mover = storage.movers[unit_number]
    if mover and mover.scheduled_tick == tick then
      mover.scheduled_tick = nil
      handler(mover)
    end
  end
end

--- Zahodí celý plán (po změně konfigurace se postaví znovu).
function M.clear()
  storage.schedule = {}
  for _, mover in pairs(storage.movers) do mover.scheduled_tick = nil end
end

return M
