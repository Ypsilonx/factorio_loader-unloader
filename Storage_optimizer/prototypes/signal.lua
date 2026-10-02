-- Virtuální signály modu pro obvodovou síť: „Velikost dávky“ (výchozí signál nativní volby
-- „Nastavit velikost stacku“) a „Počet stacků“ (počet stacků za přesun; použije se, je-li > 0).

--- Vytvoří virtuální signál s ikonou převzatou z vanilla písmenného signálu.
local function signal(name, letter)
  local base = data.raw["virtual-signal"]["signal-" .. letter]
  return {
    type = "virtual-signal",
    name = name,
    icon = base.icon,
    icons = base.icons,
    icon_size = base.icon_size,
    subgroup = base.subgroup,
    order = "z[" .. name .. "]",
  }
end

data:extend({
  signal("storage-optimizer-batch", "S"),
  signal("storage-optimizer-stacks", "N"),
})
