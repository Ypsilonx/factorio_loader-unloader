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
    if mover then mover.batch = (batch and batch >= 1) and math.floor(batch) or nil end
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
