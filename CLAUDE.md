# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Mod do Factoria 2.0 (Lua) „Storage Optimizer“: budova 1×1, která bez pásů přesouvá celé stacky mezi bednami
a stroji. Dokumentace projektu je česky (komentáře, docstringy, docs/), lokalizace hry v `locale/en` i `locale/cs`.
Podrobnosti k ladění hodnot, grafice a publikaci jsou v `docs/development.md` – při změně tam popsaného chování
ho aktualizuj.

## Příkazy

Skripty v `tools/` jsou bash – spouštět přes Git Bash (Bash tool), ne PowerShell.

```bash
bash tools/run-unit.sh               # jednotkové testy čisté logiky (lua 5.3 v PATH), výstup "UNIT pass=… fail=…"
bash tools/run-tests.sh vanilla      # integrační testy v headless Factoriu (bez Space Age)
bash tools/run-tests.sh space-age    # totéž se Space Age (kvalita, zkáza, turbo pás)
bash tools/run-tests.sh mods pymodpack   # kompatibilita s mody z %APPDATA%/Factorio/mods (i se závislostmi)
bash tools/run-perf.sh               # výkonové srovnání; PERF_N=počet dvojic, PERF_MODES="idle mover loader"
bash tools/package.sh                # dist/Storage_optimizer_<verze>.zip pro mod portál (verze z info.json)
bash tools/publish.sh [--details]   # nahrání verze na mod portál přes API (klíč FACTORIO_API_KEY nebo ~/.factorio-api-key)
bash tools/link-mod.sh               # junction %APPDATA%/Factorio/mods/Storage_optimizer → repozitář
```

- Cesta k Factoriu: proměnná `FACTORIO_EXE` (výchozí `C:/STEAM/steamapps/common/Factorio/bin/x64/factorio.exe`).
- Jediný unit test: runner nemá filtr – dočasně zúžit seznam `SUITES` v `tests/unit/run.lua`, nebo nová sada
  se musí do `SUITES` přidat, jinak se nespustí.
- Integrační test: nový soubor v `tests/storage-optimizer-tests/cases/` je nutné zaregistrovat v
  `tests/storage-optimizer-tests/control.lua`. Úspěch = řádek `SO-TEST DONE pass=… fail=0 …`; logy v `.test-run/<varianta>/`.
- Lint: `.luacheckrc` (globály Factoria; `tests/unit` je lua53, mod lua52).
- Grafika: `"C:/STEAM/steamapps/common/Blender/blender.exe" -b --factory-startup --python blender/build_sprites.py`.

## Architektura

**Data stage → runtime přes mod-data.** `data.lua` definuje jen prototypy nezávislé na jiných modech; tiery se
generují v `data-final-fixes.lua` ze **všech pásů ve hře** (`prototypes/tiers.lua: collect(data.raw)`), jeden tier
na pás, propojené `next_upgrade`. Parametry tierů (interval, energie, max_stacks) se zapisují do prototypu
`mod-data` `storage-optimizer-tiers`, který runtime čte v `scripts/tiers.lua` (`prototypes.mod_data`). Runtime proto
nikdy nepočítá parametry z pásů znovu – změna výpočtu patří do `prototypes/tiers.lua`.
Recept a **vlastní výzkum každého tieru** skládá `prototypes/research.lua` (čistá logika): suroviny podle rychlosti
pásu s náhradami za chybějící předměty, prerekvizity = výzkum pásu + výzkumy všech surovin (vč. předchozího tieru).
Kvůli overhaul modům nikdy nepřipojovat recept k cizímu výzkumu natvrdo – kompatibilitu ověřuje
`tools/run-tests.sh mods <mod>…`.

**Entita je prototyp `inserter`** (kvůli nativnímu GUI, podmínkám obvodové sítě a filtrům), ale po postavení se
nastaví `disabled_by_script = true` – engine ji nepočítá, veškerý přesun dělá skript. Engine dál vyhodnocuje
podmínku sítě a filtry ze signálů, skript je čte z `control_behavior`. Vypnutá entita neodebírá `drain`, proto si
`transfer.lua` bere energii přímo ze zásobníku entity (`buffer_capacity`).

**UPS model – plánovač místo on_tick pro všechny.** `scripts/scheduler.lua` drží `storage.schedule[tick] = {unit_number…}`;
`control.lua` v `on_tick` zpracuje jen entity naplánované na daný tick a po cyklu je přeplánuje o `interval`.
Entita bez zdroje/cíle se z plánu vyřadí a probudí ji až postavení bedny/stroje v okolí (`on_built` s filtry
typů z `neighbours.TYPES`) nebo otočení. `mover.scheduled_tick` brání dvojímu naplánování – při ručním plánování
ho respektuj. `on_configuration_changed` celý plán zahodí a postaví znovu.

**Stav ve `storage`:** `storage.movers[unit_number]` (registry – entita, nastavení dávky/stacků, sousedé, indikátor),
`storage.schedule`, `storage.buffer` (pomocný inventář). Nastavení optimizeru putuje přes blueprint tagy,
copy-paste a výměnu tieru (`scripts/persistence.lua` – při vytěžení si nastavení zapamatuje pro náhradu ve stejném ticku).

**Čistá logika vs. herní API.** Moduly bez závislosti na herním API (`prototypes/tiers.lua`, `prototypes/wires.lua`,
`prototypes/icons.lua`, `scripts/filters.lua`) se testují v `tests/unit/` čistou Lua 5.3. GUI (`scripts/gui.lua`)
headless Factorio neumí (nemá hráče) – testuje se v `tests/unit/test_gui.lua` s napodobeninou `LuaGuiElement`;
jména prvků nesmí kolidovat s vlastnostmi `LuaGuiElement` (`test_gui_names.lua`). Integrační testy
(`tests/storage-optimizer-tests/`) jsou samostatný mod: každý case má `setup` a `steps` s počtem ticků, běží
paralelně na vlastním výřezu povrchu `so-test`; `requires` = test se přeskočí bez daného modu (Space Age).

**Grafika je generovaná z Blenderu** (`blender/build_sprites.py` + `so_*.py`) – PNG neupravovat ručně, ale přegenerovat.
Body drátů obvodové sítě (`prototypes/wires.lua`) se počítají ze stejné projekce jako render: posun svorkovnice
v `so_model.py` (`terminal`) vyžaduje úpravu `TERMINAL` ve `wires.lua`, změna směru slunce v `so_render.py`
úpravu `SHADOW_X`/`SHADOW_Y`. Rozměry spritů hlídá `tests/unit/test_graphics.lua`.

## Konvence

- Nové texty pro hráče vždy do obou lokalizací (`locale/en`, `locale/cs`) – kontroluje `test_locale.lua`.
- `changelog.txt` má striktní formát Factoria: oddělovač 99 pomlček, `Version: x.y.z`, `Date: …`, kategorie
  odsazená 2 mezerami, položky 4 mezerami s `- `.
- Vydání: zvýšit `version` v `Storage_optimizer/info.json` + sekce v changelogu, pak `tools/publish.sh`
  (balí přes `tools/package.sh`). Mění-li se chování z pohledu savu, přidat `Storage_optimizer/migrations/`.
