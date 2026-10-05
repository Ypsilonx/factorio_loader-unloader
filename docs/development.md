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
  prototypes/research.lua     suroviny receptu a výzkum tieru s prerekvizitami (čistá logika)
  prototypes/entity|item|recipe|icons|signal.lua   prototypy tierů
  prototypes/wires.lua        body drátů obvodové sítě (projekce svorkovnice z Blenderu, čistá logika)
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
| Interval žlutého tieru (60 t = 1 s), cena přesunu (20 kJ + 5 kJ za další stack), rezerva zásobníku (2×) | `Storage_optimizer/prototypes/tiers.lua` – `BASE_INTERVAL`, `ENERGY_PER_TRANSFER_KJ`, `ENERGY_PER_EXTRA_STACK_KJ`, `BUFFER_RESERVE` |
| Malá ikonka pásu v rohu ikony (vypnuto) | `Storage_optimizer/prototypes/icons.lua` – `SHOW_BELT_OVERLAY` |
| Limit počtu stacků za přesun (výchozí 20) | startup nastavení `storage-optimizer-max-stacks` (`Storage_optimizer/settings.lua`) |
| Suroviny receptů (úrovně a náhrady za předměty, které mod odstranil), počet pásů v receptu | `Storage_optimizer/prototypes/research.lua` – `LEVELS`, `BELTS_PER_TIER` |
| Hranice úrovní surovin podle rychlosti pásu (násobky žlutého: do 1×, do 2×, rychlejší) | `Storage_optimizer/prototypes/research.lua` – `LEVEL_SPEEDS` |
| Cena výzkumu tieru (násobek nejdražší přímé prerekvizity, výchozí 1,5×) | `Storage_optimizer/prototypes/research.lua` – `TECH_COUNT_MULTIPLIER` |
| Barvy tierů (dočasná grafika) | `Storage_optimizer/prototypes/entity.lua` – `TINTS` |
| Cesta k Factoriu | proměnná `FACTORIO_EXE` (výchozí hodnota v `tools/run-tests.sh` a `tools/run-perf.sh`) |
| Cesta ke Git Bash pro VSCode úlohy | `.vscode/tasks.json` – `options.shell.executable` |

## Testy

Všechny jsou i jako VSCode úlohy (*Terminal → Run Task*).

```bash
bash tools/run-unit.sh                 # jednotkové testy (tiery, filtry, lokalizace, grafika, dráty, signály, GUI)
bash tools/run-tests.sh vanilla        # integrační testy v headless Factoriu bez Space Age
bash tools/run-tests.sh space-age      # totéž se Space Age (kvalita, zkáza, turbo pás)
bash tools/run-tests.sh mods pymodpack # kompatibilita s jinými mody (jen obecné kontroly z cases/compat.lua)
bash tools/run-perf.sh                 # výkonové srovnání (PERF_N=počet dvojic, PERF_MODES=režimy)
```

**GUI:** headless Factorio nemá hráče, takže integrační testy panely nevytvoří. Pokrývá je jednotkový test
`tests/unit/test_gui.lua` s napodobeninou herních GUI prvků (stavba, plnění, obnova, obsluha událostí)
a `tests/unit/test_gui_names.lua` (jména prvků nesmí kolidovat s vlastnostmi `LuaGuiElement`).
Vykreslení a vzhled je nutné ověřit ručně ve hře.

Integrační testy používají oddělenou `write-data` složku v `.test-run/`, takže nepřepisují log ani
nastavení hry. Výsledek je řádek `SO-TEST DONE pass=… fail=… skip=…`.

**Kompatibilita s jinými mody:** `tools/run-tests.sh mods <mod>…` vezme mody v nejvyšší verzi ze složky
`MODS_SOURCE` (výchozí `%APPDATA%/Factorio/mods`) i s povinnými závislostmi a spustí jen obecné kontroly
(`cases/compat.lua`): tiery vznikly, každý recept má výzkum a všechny suroviny tieru jdou vyrobit nejpozději
po jeho výzkumu. Herní testy se vynechají, protože počítají s vanilla bednami a rozvodnami. Vygenerované
suroviny a prerekvizity každého tieru jsou v logu (`.test-run/mods/write-data/factorio-current.log`, řádky
`recipe.lua`). Ověřeno (2026-10-02): `pymodpack` (Pyanodon 3.0, 4 tiery) a `boblogistics bobinserters
bobplates bobelectronics bobtech bobassembly` (7 tierů).

### Výsledky výkonového testu (1000 dvojic beden, 3600 ticků, Factorio 2.0.77)

Aktuální stav (žlutý tier 1 s, 1 stack za přesun):

| Režim | ms/tick | Přesunuto kusů za 50 s |
|---|---|---|
| `idle` – jen bedny | 0,138 | 0 |
| `mover` – Storage optimizer (žlutý tier) | 0,293 | 4 800 000 (všechny zdroje vyprázdněné) |
| `loader` – 2× vanilla loader-1x1 | 0,261 | 744 000 |

Historie: s intervalem 2 s stál `mover` 0,225 ms/tick (2 500 000 kusů); před vypnutím entity pro engine
0,350 ms/tick. `mover-nochest` (optimizery bez beden) 0,136 ms/tick = entita sama nestojí nic.

Entita je pro engine vypnutá (`disabled_by_script`), takže celá cena je skriptová logika – úměrná počtu
kontrol za sekundu (kratší interval = víc kontrol). Engine přitom dál vyhodnocuje podmínku sítě a propisuje
filtry ze signálů.

**Energie:** vypnutá entita neodebírá `drain`, proto si skript bere energii za přesun ze zásobníku entity
(`buffer_capacity` = 2 × nejdražší přesun, dobíjení = nejdražší přesun za interval) a elektrická síť ho dobíjí. Nedostatek energie = stav „bez proudu“.

## Ruční hraní a ladění

```bash
bash tools/link-mod.sh     # junction %APPDATA%/Factorio/mods/Storage_optimizer → repozitář (jednou)
```

Pak ve hře povol mod. Ladění s breakpointy: *Run and Debug → Factorio Mod Debug* (FMTK).

## Checklist ruční kontroly před vydáním

- [ ] Panel vpravo se ukáže u optimizeru, **ne** u obyčejného inserteru.
- [ ] Velikost dávky 300 → přesouvá po 300; smazání pole → Auto.
- [ ] Počet stacků 5 → přesouvá po 5 stacích; 50 → ořízne se na 20; panel ukazuje nápovědu „1–20“.
- [ ] Rámeček „Připojení obvodu – Storage optimizer“ se ukáže jen po připojení drátu.
- [ ] Bez zaškrtnutí „Počet stacků ze sítě“ se signál ignoruje; po zaškrtnutí ho řídicí signál
      (výchozí „Počet stacků“, i vlastní vybraný) přebije; vedle výběru je vidět aktuální hodnota;
      smazání výběru signálu vrátí výchozí.
- [ ] Pole „Počet stacků“ zešedne při zapnutém „Počet stacků ze sítě“, „Velikost stacku“ při zapnutém
      nativním „Nastavit velikost štosu“; hodnoty se v otevřeném okně průběžně obnovují.
- [ ] Výchozí řídicí signály jsou S (velikost stacku) a N (počet stacků).
- [ ] Montážní stroj jako cíl: suroviny receptu se doplní do vstupu, stroj bez receptu nic nepřijme.
- [ ] Montážní stroj / pec jako zdroj: odebírají se hotové výrobky; palivo pece optimizer neplní.
- [ ] Vagón: vlak zastaví ve stanici → optimizer vykládá/nakládá; po odjezdu stav „Chybí zdroj nebo cíl“, nic
      se nepřesune do jedoucího vagónu. Logistické a nekonečné bedny jako zdroj i cíl.
- [ ] Blueprint s nastavenou dávkou a počtem stacků → postavený optimizer má stejné hodnoty.
- [ ] Ctrl+C / Ctrl+V zachová dávku i počet stacků.
- [ ] Shift+pravý klik / Shift+levý klik zkopíruje dávku i počet stacků mezi optimizery.
- [ ] Ruční přestavění tieru přes starší tier zachová dávku i počet stacků.
- [ ] Upgrade planner s roboty zachová dávku i počet stacků.
- [ ] Postavení mnoha optimizerů naráz nezpůsobí výpadek elektrické sítě (omezené dobíjení zásobníku).
- [ ] Šipka v alt režimu míří k cíli ve všech 4 směrech.
- [ ] Barvy indikátoru: zelená (pracuje), žlutá (čeká), červená (bez proudu / bez bedny / vypnuto sítí).
- [ ] Otočení klávesou R a převrácení (F/G) prohodí zdroj a cíl.

## Publikace

1. Zvýšit `version` v `Storage_optimizer/info.json` a přidat sekci do `changelog.txt`.
2. `bash tools/package.sh` → `dist/Storage_optimizer_<verze>.zip`.
3. `bash tools/publish.sh` – sestaví zip a nahraje ho přes Mod upload API (`--details` navíc přepíše popis
   na portálu obsahem `docs/mod-portal.md` a krátký popis z `info.json`). Klíč z <https://factorio.com/profile>
   (oprávnění *ModPortal: Upload Mods*, pro `--details` i *Edit Mods*) v proměnné `FACTORIO_API_KEY` nebo
   v souboru `~/.factorio-api-key` – nikdy ne v repozitáři. Skript odmítne verzi, která už na portálu je,
   nebo chybí v changelogu.
4. První vydání a změny licence nebo thumbnailu se dělají ručně na <https://mods.factorio.com> (licence MIT,
   thumbnail `Storage_optimizer/thumbnail.png` 144×144).

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

**Přegenerování** (trvá asi minutu – Cycles, 2× převzorkování):

- bez okna Blenderu: `"C:/STEAM/steamapps/common/Blender/blender.exe" -b --factory-startup --python blender/build_sprites.py`
- v Blenderu: *Scripting → Open* `blender/build_sprites.py` → *Run Script* (nebo přes Blender MCP).

Kořen repozitáře se bere z proměnné prostředí `SO_ROOT`, výchozí hodnota je na začátku skriptu (`ROOT`).

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
| Tvar a rozměry dílů | `blender/so_model.py` – funkce `build`, `mouth` a `terminal` (svorkovnice drátů) |
| Světlo (směr stínu, síla), kvalita renderu | `blender/so_render.py` – `setup_camera_and_lights`, `SAMPLES`, `SUPERSAMPLE` |
| Barvy tierů ve hře | `Storage_optimizer/prototypes/entity.lua` – `TINTS` (pro náhled je zrcadlí `PREVIEW_TINTS` ve skriptu) |

Promítání odpovídá hře: ortografická kamera pod 45° a model roztažený v ose Y o √2, takže dlaždice
vychází čtvercová; 2 dlaždice = 128 px, ve hře `scale = 0.5`. Rozměry souborů hlídá jednotkový test
`tests/unit/test_graphics.lua` (headless Factorio sprity nenačítá).

**Dráty obvodové sítě:** body, kam hra kreslí červený a zelený drát, počítá `Storage_optimizer/prototypes/wires.lua`
ze stejné projekce jako render. **Při posunu svorkovnice** v `so_model.py` (funkce `terminal`) je nutné upravit
i `TERMINAL` ve `wires.lua`; při změně směru slunce v `so_render.py` i `SHADOW_X` / `SHADOW_Y`.
