# Storage Optimizer

**One building instead of unloader + belt + loader.** Storage Optimizer moves **whole stacks** from one chest
or warehouse straight into another – up to 20 stacks at once, no belts, no inserters, and built from the
ground up to be gentle on UPS.

```
before:  [chest] → unloader → belt → loader → [chest]
now:     [chest] → Storage Optimizer → [chest]
```

A *transfer* is **stack size × stacks per transfer** – e.g. iron plates 100 × 5 = 500 plates at once.

## Features

- **Whole-stack transfers** – one transfer per cycle, and only when the source holds all items and the
  target has room for all of them ("all or nothing"). No half stacks left behind.
- **Several stacks at once** – 1–20 stacks per transfer (limit configurable); bigger transfers are cheaper
  per item. Can also be driven by any circuit signal you choose ("Stacks per
  transfer from circuit" in the panel – like the native "Set stack size").
- **No belts needed** – place it between two chests, warehouses or machines, press R to reverse the direction.
- **Assembling machines and furnaces** – as a target it fills the machine's input (e.g. a one-off buffer of
  "iron plates × 2 stacks"), as a source it takes the finished products. Fuel is left to inserters.
- **Tiers from any belt mod** – every belt in the game (vanilla, Space Age, or any belt mod) automatically
  gets its own tier with a matching speed, recipe and technology. Yellow tier: one transfer per second,
  faster belts are proportionally faster.
- **Custom stack size** – Auto (the item's stack) or any amount, e.g. 5000. Not limited to 255.
- **Filters and circuit control** – 5 filters with whitelist/blacklist and quality comparison;
  enable/disable by condition, stack size and stack count from signals, filters from signals.
  Wires connect to a terminal on the building's gearbox.
- **Blueprint support** – stack size and stack count survive blueprints, copy-paste and tier upgrades.
- **Quality, spoilage and item data are preserved.**
- **UPS-friendly** – the building is never updated by the engine; the script touches it only once per
  transfer interval. Benchmark: see below.
- **Cheap on power** – 20 kJ per transfer + 5 kJ for each additional stack (e.g. 500 plates for 40 kJ);
  an idle building uses no power, and a small energy reserve keeps power spikes low.
- **Hand-made look** – weathered industrial graphics rendered in Blender, arrows coloured by tier.

## How to use

1. Research the belt of the tier you want (the first tier comes with *Fast inserter*).
2. Place the Storage Optimizer between two chests. It takes from the chest **behind** it (the gearbox side)
   and puts into the chest **in front** of it (where the arrows point).
3. Open it to set filters and circuit conditions (native inserter window), stack size and stacks per
   transfer (panel on the right).

## Compatibility

- Factorio 2.0, with or without Space Age.
- Works with any mod that adds belts (tiers are generated automatically), any mod that adds chests or
  warehouses of type `container` / `logistic-container` and any mod that adds assembling machines or furnaces.
- Default control signals are the plain letters **S** (stack size) and **N** (stacks per transfer);
  any other signal can be chosen.

## Known limitations

- Works with chests, warehouses, assembling machines and furnaces – not with wagons, rocket silos or labs.
- Fuel is not handled (use an inserter for fuel).
- The native inserter window shows the *Override stack size* slider – it is ignored. Stack size and
  stacks per transfer are set in the panel on the right.

## Benchmark

1000 pairs of chests, 3600 ticks, Factorio 2.0.77, yellow tier, 1 stack per transfer:

| Setup | ms/tick | Items moved in 50 s |
|---|---|---|
| chests only (baseline) | 0.138 | 0 |
| **Storage Optimizer** | **0.293** | **4 800 000** (all source chests emptied) |
| 2× vanilla loader per pair | 0.261 | 744 000 |

Per tick it costs about as much as a pair of loaders, but it moves 6.5× more items – far less UPS per item.

## License

MIT
