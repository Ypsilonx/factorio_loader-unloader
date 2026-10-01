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
| Interval žlutého tieru (120 t = 2 s), výkon (50 kW → 100 kJ za dávku) | `Storage_optimizer/prototypes/tiers.lua` – `BASE_INTERVAL`, `BASE_POWER_KW` |
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
| `idle` – jen bedny | 0,148 | 0 |
| `mover` – Storage optimizer (žlutý tier) | 0,225 | 2 500 000 |
| `loader` – 2× vanilla loader-1x1 | 0,274 | 744 000 |
| `mover-nochest` – optimizery bez beden (cena entit bez skriptu) | 0,136 | 0 |

Entita je pro engine vypnutá (`disabled_by_script`), takže sama nestojí nic; celá cena je skriptová
logika (~0,08–0,1 ms na 1000 kusů při plné práci). Engine přitom dál vyhodnocuje podmínku sítě a propisuje
filtry ze signálů. Před touto optimalizací (rameno jen „uspané“) stál optimizer 0,350 ms/tick.

**Energie:** vypnutá entita neodebírá `drain`, proto si skript bere energii za přesun ze zásobníku entity
(`buffer_capacity` = 100 kJ) a elektrická síť ho dobíjí. Prázdný zásobník = stav „bez proudu“.

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
   thumbnail je `Storage_optimizer/thumbnail.png` (144×144).

### Formát changelog.txt

Factorio vyžaduje přesný formát: oddělovač z **99 pomlček**, řádek `Version: x.y.z`, řádek `Date: …`,
kategorie odsazená 2 mezerami (`  Features:`), položky odsazené 4 mezerami s `- `.

## Grafika (Blender)

Model a všechny sprity vytváří skript `blender/build_sprites.py` – procedurálně, takže jde kdykoli
přegenerovat. Pomocné moduly: `so_materials.py` (materiály s patinou: rez v koutech a ve šmouhách,
odřené hrany, škrábance, špína u země, oprýskaná barva, slzičkový plech), `so_model.py` (geometrie:
podvozek, bočnice se šrouby, deska, převodovka s žebry, ústí s gumovým závěsem) a `so_render.py`
(kamera, světla, render vrstev, skládání pixelů). Výsledná scéna se ukládá jako kopie do
`blender/storage_optimizer.blend`. Materiály používají uzly jen pro Cycles (Ambient Occlusion, Bevel).

**Přegenerování:** v Blenderu *Scripting → Open* `blender/build_sprites.py` → *Run Script*
(nebo přes Blender MCP). Trvá asi minutu (Cycles, 2× převzorkování). Kořen repozitáře se bere z proměnné prostředí `SO_ROOT`,
výchozí hodnota je na začátku skriptu (`ROOT`).

**Výstupy:**

| Soubor | Obsah |
|---|---|
| `Storage_optimizer/graphics/entity/storage-optimizer-base.png` | základ bloku, 4 směry N, E, S, W po 128×128 px |
| `…/storage-optimizer-mask.png` | jen šipky ve stupních šedi – hra je obarví barvou tieru (`tint`) |
| `…/storage-optimizer-shadow.png` | stín (`draw_as_shadow`) |
| `Storage_optimizer/graphics/icons/storage-optimizer-{base,mask}.png` | ikona 64×64 |
| `Storage_optimizer/thumbnail.png` | náhled pro mod portál 144×144 |
| `blender/renders/preview.png` | kontrolní náhled všech směrů a tierů na terénu (není v gitu) |

**Kde ladit vzhled:**

| Co | Kde |
|---|---|
| Barvy dílů (podvozek, bočnice, deska, převodovka, šipky) | `blender/so_model.py` – funkce `materials` |
| Míra rzi, odření a oprýskání | parametry `rust`, `wear`, `chipping` tamtéž |
| Barva rzi, holého kovu a špíny | `blender/so_materials.py` – `RUST`, `RUST_DARK`, `BARE_METAL`, `GRIME` |
| Tvar a rozměry dílů | `blender/so_model.py` – funkce `build` a `mouth` |
| Světlo (směr stínu, síla), kvalita renderu | `blender/so_render.py` – `setup_camera_and_lights`, `SAMPLES`, `SUPERSAMPLE` |
| Barvy tierů ve hře | `Storage_optimizer/prototypes/entity.lua` – `TINTS` (pro náhled je zrcadlí `PREVIEW_TINTS` ve skriptu) |

Promítání odpovídá hře: ortografická kamera pod 45° a model roztažený v ose Y o √2, takže dlaždice
vychází čtvercová; 2 dlaždice = 128 px, ve hře `scale = 0.5`. Rozměry souborů hlídá jednotkový test
`tests/unit/test_graphics.lua` (headless Factorio sprity nenačítá).
