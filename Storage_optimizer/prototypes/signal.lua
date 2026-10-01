-- Virtuální signál „Velikost dávky“ – výchozí signál pro nastavení dávky z obvodové sítě.
local base = data.raw["virtual-signal"]["signal-S"]

data:extend({
  {
    type = "virtual-signal",
    name = "storage-optimizer-batch",
    icon = base.icon,
    icons = base.icons,
    icon_size = base.icon_size,
    subgroup = base.subgroup,
    order = "z[storage-optimizer-batch]",
  },
})
