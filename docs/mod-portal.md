# Storage Optimizer

**One building instead of unloader + belt + loader.** Storage Optimizer moves **whole stacks** from one chest
or warehouse straight into another – no belts, no inserters, and built from the ground up to be gentle on UPS.

```
before:  [chest] → unloader → belt → loader → [chest]
now:     [chest] → Storage Optimizer → [chest]
```

## Features

- **Whole-stack transfers** – one full batch per cycle, and only when the whole batch fits into the target
  ("all or nothing"). No half stacks left behind.
- **No belts needed** – place it between two chests or warehouses, press R to reverse the direction.
- **Tiers from any belt mod** – every belt in the game (vanilla, Space Age, or any belt mod) automatically
  gets its own tier with a matching speed, recipe and technology.
- **Custom batch size** – Auto (one stack of the item) or any amount, e.g. 5000. Not limited to 255.
- **Filters and circuit control** – 5 filters with whitelist/blacklist and quality comparison;
  enable/disable by condition, batch size from a signal, filters from signals.
- **Blueprint support** – the batch size survives blueprints, copy-paste and tier upgrades.
- **Quality, spoilage and item data are preserved.**
- **UPS-friendly** – the building is never updated by the engine; the script touches it only once per
  transfer interval. Benchmark (1000 pairs of chests, Factorio 2.0.77): **0.225 ms/tick** and 2 500 000 items
  moved, vs **0.274 ms/tick** and 744 000 items with two vanilla loaders per pair.
- **Power per batch** – 100 kJ per transferred batch; an idle building uses no power.

## How to use

1. Research the belt of the tier you want (the first tier comes with *Fast inserter*).
2. Place the Storage Optimizer between two chests. It takes from the chest **behind** it and puts into the
   chest **in front** of it (the arrow is visible in Alt mode).
3. Open it to set filters and circuit conditions (native inserter window) and the batch size
   (panel on the right).

## Compatibility

- Factorio 2.0, with or without Space Age.
- Works with any mod that adds belts (tiers are generated automatically) and any mod that adds chests or
  warehouses of type `container` / `logistic-container`.

## Known limitations

- Version 0.1 works only with chests and warehouses (no assembling machines, wagons, …).
- The native inserter window shows its own status line (always "Disabled by script" – that is how the mod
  saves UPS) and the *Override stack size* slider – both are ignored. The real status and batch size are in the panel on the right.

## License

MIT
