--- Pomocné funkce pro integrační testy: stavění entit, napájení, signály a aserce.
local H = {}

--- Postaví entitu na dlaždici (dx, dy) relativně k počátku testu; vyvolá script_raised_built.
--- @return LuaEntity
function H.place(ctx, name, dx, dy, extra)
  local spec = {
    name = name,
    position = { ctx.origin.x + dx + 0.5, ctx.origin.y + dy + 0.5 },
    force = "player",
    raise_built = true,
  }
  for key, value in pairs(extra or {}) do spec[key] = value end
  local entity = ctx.surface.create_entity(spec)
  if not entity then error("nelze postavit " .. name, 2) end
  return entity
end

--- Napájí výřez testu: neomezený zdroj a rozvodna pokrývající okolí počátku (±9 dlaždic od (-3, -3)).
function H.power(ctx)
  local source = H.place(ctx, "electric-energy-interface", -6, -6)
  source.power_production = 1e9
  source.electric_buffer_size = 1e10
  H.place(ctx, "substation", -3, -3)
end

--- Postaví bednu a vloží do ní předměty (pole ItemStackDefinition).
function H.chest(ctx, name, dx, dy, items)
  local chest = H.place(ctx, name, dx, dy)
  for _, item in ipairs(items or {}) do chest.insert(item) end
  return chest
end

--- Postaví Storage optimizer tieru odpovídajícího pásu (výchozí směr sever = zdroj na severu).
function H.mover(ctx, belt, dx, dy, direction)
  return H.place(ctx, "storage-optimizer-" .. belt, dx, dy, { direction = direction or defines.direction.north })
end

--- Počet kusů předmětu dané kvality v bedně.
function H.count(entity, name, quality)
  return entity.get_inventory(defines.inventory.chest).get_item_count({ name = name, quality = quality or "normal" })
end

--- Nastaví jeden slot konstantního kombinátoru (signal = { type?, name, count }).
function H.set_signal(combinator, slot, signal)
  local section = combinator.get_control_behavior().get_section(1)
  section.set_slot(slot, {
    value = { type = signal.type or "item", name = signal.name, quality = "normal", comparator = "=" },
    min = signal.count,
  })
end

--- Postaví konstantní kombinátor se zadanými signály.
function H.combinator(ctx, dx, dy, signals)
  local combinator = H.place(ctx, "constant-combinator", dx, dy)
  for slot, signal in ipairs(signals) do H.set_signal(combinator, slot, signal) end
  return combinator
end

--- Propojí dvě entity červeným drátem.
function H.wire(a, b)
  local red = defines.wire_connector_id.circuit_red
  a.get_wire_connector(red, true).connect_to(b.get_wire_connector(red, true))
end

--- Selže, pokud se hodnoty nerovnají.
function H.eq(actual, expected, what)
  if actual ~= expected then
    error(string.format("%s: čekáno %s, dostáno %s", what, tostring(expected), tostring(actual)), 0)
  end
end

--- Selže, pokud hodnota není pravdivá.
function H.truthy(value, what)
  if not value then error(what .. ": čekána pravdivá hodnota", 0) end
end

return H
