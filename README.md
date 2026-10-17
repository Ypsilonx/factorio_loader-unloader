# Storage Optimizer

Mod do Factoria 2.0: jedna budova 1×1, která bez pásů přesouvá celé stacky mezi bednami, vagóny,
montážními stroji a pecemi. Nahrazuje sestavu unloader → pás → loader, tiery se generují automaticky
ze všech pásů ve hře.

Hlavní vlastnosti: přesun 1–20 celých stacků najednou („všechno, nebo nic“, volitelně i zbytky),
50 kJ za přesun + 5 kJ za další stack, 5 filtrů a ovládání obvodovou i logistickou sítí, vlastní okno,
přenos nastavení v blueprintech, vlastní grafika z Blenderu
a minimální zátěž UPS (entitu engine vůbec nepočítá, skript ji zpracuje jen jednou za interval).

- [Uživatelská příručka](docs/user-guide.md)
- [Vývoj, testy, publikace](docs/development.md)
- [Popis pro mod portál (EN)](docs/mod-portal.md)

## Rychlý start vývoje

```bash
bash tools/link-mod.sh             # propojí mod do složky modů Factoria
bash tools/run-unit.sh             # jednotkové testy
bash tools/run-tests.sh vanilla    # integrační testy v headless Factoriu
```

## Licence

MIT © 2026 Ypsilonx
