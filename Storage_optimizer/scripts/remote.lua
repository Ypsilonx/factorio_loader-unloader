--- Veřejné rozhraní pro ostatní mody a testy: remote.call("storage-optimizer", <funkce>, …).
local registry = require("scripts.registry")

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
