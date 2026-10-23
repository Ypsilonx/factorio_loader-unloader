--- Tipy a triky (nativní okno nápovědy). Texty jsou v locale.
--- Bez `trigger`: `starting_status` je ukáže od začátku hry (výchozí „locked“ by je skryl).
--- Texty nepoužívají ikony tierů ([entity=…]) – jejich jména závisí na pásech ve hře a s overhaul mody by
--- se ikona nemusela najít.
data:extend({
  { type = "tips-and-tricks-item-category", name = "storage-optimizer", order = "z-[storage-optimizer]" },
  { type = "tips-and-tricks-item", name = "storage-optimizer", category = "storage-optimizer", order = "a",
    is_title = true, starting_status = "suggested" },
  { type = "tips-and-tricks-item", name = "storage-optimizer-direction", category = "storage-optimizer",
    order = "b", indent = 1, starting_status = "unlocked" },
  { type = "tips-and-tricks-item", name = "storage-optimizer-transfer", category = "storage-optimizer",
    order = "c", indent = 1, starting_status = "unlocked" },
  { type = "tips-and-tricks-item", name = "storage-optimizer-machines", category = "storage-optimizer",
    order = "d", indent = 1, starting_status = "unlocked" },
  { type = "tips-and-tricks-item", name = "storage-optimizer-tiers", category = "storage-optimizer",
    order = "e", indent = 1, starting_status = "unlocked" },
  { type = "tips-and-tricks-item", name = "storage-optimizer-circuit", category = "storage-optimizer",
    order = "f", indent = 1, starting_status = "unlocked" },
})
