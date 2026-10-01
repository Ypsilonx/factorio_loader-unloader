# Vývoj modu Storage Optimizer

## Prostředí

- **VSCode** s rozšířeními `sumneko.lua` (jazykový server) a `justarandomgeek.factoriomod-debug` (FMTK:
  typy API, debugger, balení). Po otevření projektu spusť příkaz **Factorio: Select Version** a vyber
  instalaci hry – FMTK vygeneruje typy pro napovídání.
- Nechtěná rozšíření (`.vscode/extensions.json` → `unwantedRecommendations`): další Lua jazykové servery
  (`gccfeli.vscode-lua`, `trixnz.vscode-lua`, `keyring.lua`, `changnet.lua-tags`) se hádají se sumneko
  a hlásí falešné chyby; `actboy168.lua-debug` nahrazuje debugger FMTK. Python není potřeba.
- **Lua 5.3** v PATH (jen pro jednotkové testy čisté logiky), **Git Bash** pro skripty v `tools/`.

## Struktura

```
Storage_optimizer/            samotný mod
  prototypes/tiers.lua        výběr pásů, interval, spotřeba (čistá logika)
  prototypes/entity|item|recipe|icons|signal.lua   prototypy tierů
  scripts/registry.lua        evidence postavených optimizerů (storage.movers)
  scripts/neighbours.lua      hledání zdrojové a cílové bedny
  scripts/scheduler.lua       plánovač podle ticků (storage.schedule)
  scripts/transfer.lua        jeden cyklus přesunu
  scripts/filters.lua         logika filtrů (čistá logika)
  scripts/indicator.lua       ikonka stavu a šipka v alt režimu
  scripts/persistence.lua     blueprint tagy, copy-paste, výměna tieru
  scripts/gui.lua             boční panel u okna inserteru
  scripts/remote.lua          remote rozhraní "storage-optimizer"
tests/unit/                   jednotkové testy (lua 5.3)
tests/storage-optimizer-tests/  testovací mod pro headless integrační testy
tests/perf/so-perf/           výkonový scénář
tools/                        skripty: testy, výkon, junction, balení
```

## Kde ladit hodnoty

| Co | Kde |
|---|---|
| Interval žlutého tieru (120 t = 2 s), spotřeba (50 kW) | `Storage_optimizer/prototypes/tiers.lua` – `BASE_INTERVAL`, `BASE_DRAIN_KW` |
| Suroviny receptů | `Storage_optimizer/prototypes/recipe.lua` – funkce `ingredients` |
| Barvy tierů (dočasná grafika) | `Storage_optimizer/prototypes/entity.lua` – `TINTS` |
| Cesta k Factoriu | proměnná `FACTORIO_EXE` (výchozí hodnota v `tools/run-tests.sh` a `tools/run-perf.sh`) |
| Cesta ke Git Bash pro VSCode úlohy | `.vscode/tasks.json` – `options.shell.executable` |

## Testy

Všechny jsou i jako VSCode úlohy (*Terminal → Run Task*).

```bash
bash tools/run-unit.sh                 # jednotkové testy čisté logiky (tiery, filtry, lokalizace)
bash tools/run-tests.sh vanilla        # integrační testy v headless Factoriu bez Space Age
bash tools/run-tests.sh space-age      # totéž se Space Age (kvalita, zkáza, turbo pás)
bash tools/run-perf.sh                 # výkonové srovnání (PERF_N=počet dvojic, PERF_MODES=režimy)
```

Integrační testy používají oddělenou `write-data` složku v `.test-run/`, takže nepřepisují log ani
nastavení hry. Výsledek je řádek `SO-TEST DONE pass=… fail=… skip=…`.

### Výsledky výkonového testu (1000 dvojic beden, 3600 ticků, Factorio 2.0.77)

| Režim | ms/tick | Přesunuto kusů za 50 s |
|---|---|---|
| `idle` – jen bedny | 0,131 | 0 |
| `mover` – Storage optimizer (žlutý tier) | 0,350 | 2 500 000 |
| `loader` – 2× vanilla loader-1x1 | 0,259 | 744 000 |
| `mover-nochest` – optimizery bez beden (cena entit bez skriptu) | 0,238 | 0 |

Samotná entita (inserter s uspaným ramenem) stojí ~0,107 ms na 1000 kusů; skriptová logika ~0,11 ms.
Pokus s `disabled_by_script` ukázal, že úplné vypnutí entity enginem cenu entit srazí na ~0
(0,135 ms) – kandidát na další optimalizaci.

## Ruční hraní a ladění

```bash
bash tools/link-mod.sh     # junction %APPDATA%/Factorio/mods/Storage_optimizer → repozitář (jednou)
```

Pak ve hře povol mod. Ladění s breakpointy: *Run and Debug → Factorio Mod Debug* (FMTK).

## Checklist ruční kontroly před vydáním

- [ ] Panel vpravo se ukáže u optimizeru, **ne** u obyčejného inserteru.
- [ ] Velikost dávky 300 → přesouvá po 300; smazání pole → Auto.
- [ ] Blueprint s nastavenou dávkou → postavený optimizer má stejnou dávku.
- [ ] Ctrl+C / Ctrl+V zachová dávku.
- [ ] Shift+pravý klik / Shift+levý klik zkopíruje dávku mezi optimizery.
- [ ] Ruční přestavění tieru přes starší tier zachová dávku.
- [ ] Upgrade planner s roboty zachová dávku.
- [ ] Šipka v alt režimu míří k cíli ve všech 4 směrech.
- [ ] Barvy indikátoru: zelená (pracuje), žlutá (čeká), červená (bez proudu / bez bedny / vypnuto sítí).
- [ ] Otočení klávesou R a převrácení (F/G) prohodí zdroj a cíl.

## Publikace

1. Zvýšit `version` v `Storage_optimizer/info.json` a přidat sekci do `changelog.txt`.
2. `bash tools/package.sh` → `dist/Storage_optimizer_<verze>.zip`.
3. Nahrát zip na <https://mods.factorio.com>, popis z `docs/mod-portal.md`, licence MIT,
   thumbnail 144×144 (z navazujícího grafického plánu).

### Formát changelog.txt

Factorio vyžaduje přesný formát: oddělovač z **99 pomlček**, řádek `Version: x.y.z`, řádek `Date: …`,
kategorie odsazená 2 mezerami (`  Features:`), položky odsazené 4 mezerami s `- `.
