-- Startup nastavení modu (mění se v menu modů, vyžadují restart hry).
data:extend({
  {
    type = "double-setting",
    name = "storage-optimizer-interval-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0.1,
    maximum_value = 10,
    order = "a",
  },
  {
    type = "double-setting",
    name = "storage-optimizer-power-multiplier",
    setting_type = "startup",
    default_value = 1.0,
    minimum_value = 0,
    maximum_value = 10,
    order = "b",
  },
})
