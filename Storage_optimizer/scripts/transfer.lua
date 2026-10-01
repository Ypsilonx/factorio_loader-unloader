--- Jeden cyklus přesunu: kontroly a přesun nejvýše jedné celé dávky.
local M = {}

--- Přesune přesně `count` kusů po slotech přes pomocný slot storage.buffer
--- (zachová kvalitu, čerstvost i data předmětů).
local function move(source, target, name, quality, count)
  local slot = storage.buffer[1]
  local id = { name = name, quality = quality }
  local remaining = count
  while remaining > 0 do
    local stack = source.find_item_stack(id)
    if not stack then return end
    local take = math.min(remaining, stack.count)
    slot.transfer_stack(stack, take)
    local inserted = target.insert(slot)
    if inserted < slot.count then
      -- Pojistka proti ztrátě předmětů: co se nevešlo, vrátit do zdroje.
      slot.count = slot.count - inserted
      source.insert(slot)
      slot.clear()
      return
    end
    slot.clear()
    remaining = remaining - take
  end
end

--- Provede jeden cyklus pro entitu se známým zdrojem a cílem.
--- @return string stav: "working" | "waiting" | "no_power"
function M.process(mover)
  local entity = mover.entity
  if entity.status == defines.entity_status.no_power then return "no_power" end
  local contents = mover.source.get_contents()
  local n = #contents
  for k = 0, n - 1 do
    -- Rotující ukazatel, aby jeden předmět nevyhladověl ostatní.
    local index = (mover.cursor + k - 1) % n + 1
    local entry = contents[index]
    local need = mover.batch or prototypes.item[entry.name].stack_size
    if entry.count >= need
      and mover.target.get_insertable_count({ name = entry.name, quality = entry.quality }) >= need then
      move(mover.source, mover.target, entry.name, entry.quality, need)
      mover.cursor = index % n + 1
      return "working"
    end
  end
  return "waiting"
end

return M
