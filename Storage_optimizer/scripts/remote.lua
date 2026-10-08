--- Veřejné rozhraní pro ostatní mody a testy: remote.call("storage-optimizer", <funkce>, …).
local registry = require("scripts.registry")
local transfer = require("scripts.transfer")

remote.add_interface("storage-optimizer", {
  --- Ručně nastavená velikost dávky (nil = Auto).
  get_batch = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and mover.batch
  end,
  --- Nastaví velikost dávky (nil nebo hodnota < 1 = Auto).
  set_batch = function(unit_number, batch)
    local mover = registry.get(unit_number)
    if mover then mover.batch = registry.clean_batch(batch) end
  end,
  --- Počet stacků za jeden přesun (1 = výchozí).
  get_stacks = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and (mover.stacks or 1)
  end,
  --- Nastaví počet stacků za přesun (omezeno na 1..limit z nastavení modu).
  set_stacks = function(unit_number, stacks)
    local mover = registry.get(unit_number)
    if mover then mover.stacks = registry.clean_stacks(mover.entity.name, stacks) end
  end,
  --- Počet stacků ze sítě: vrátí (zapnuto, řídicí signál).
  get_stacks_circuit = function(unit_number)
    local mover = registry.get(unit_number)
    if not mover then return nil end
    return mover.stacks_circuit == true, mover.stacks_signal or registry.STACKS_SIGNAL
  end,
  --- Zapne/vypne počet stacků ze sítě; signal = SignalID (nil = výchozí „Počet stacků“).
  set_stacks_circuit = function(unit_number, enabled, signal)
    local mover = registry.get(unit_number)
    if not mover then return end
    mover.stacks_circuit = enabled == true or nil
    mover.stacks_signal = registry.clean_signal(signal)
  end,
  --- Přesouvat i zbytky (neúplný přesun).
  get_leftovers = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and mover.leftovers == true
  end,
  --- Zapne/vypne přesun zbytků.
  set_leftovers = function(unit_number, enabled)
    local mover = registry.get(unit_number)
    if mover then mover.leftovers = enabled == true or nil end
  end,
  --- Počet stacků, který se použije při příštím přesunu: vrátí (počet, hodnota řídicího signálu nebo nil).
  get_effective_stacks = function(unit_number)
    local mover = registry.get(unit_number)
    if not mover then return nil end
    return transfer.stack_count(mover)
  end,
  --- Aktuální stav: working | waiting | no_power | disabled | no_chest.
  get_state = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and mover.state
  end,
  --- Počet evidovaných optimizerů.
  count = function()
    return table_size(storage.movers)
  end,
})
