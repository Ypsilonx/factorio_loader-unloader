# Storage_optimizer – návrh (specifikace)

- **Datum:** 2026-10-01
- **Autor modu:** Ypsilonx
- **Licence:** MIT
- **Cílová verze hry:** Factorio 2.0 (testováno na 2.0.77), funguje se Space Age i bez něj
- **Interní název modu:** `Storage_optimizer` (po publikaci neměnný), titul „Storage Optimizer“

## 1. Cíl

Jedna entita 1×1, která **bez pásů** přesouvá **celé dávky (stacky)** předmětů z jedné bedny/skladu
do druhé. Nahrazuje dvojici loader + unloader + pás. Hlavní priorita je **šetřit UPS** ve velkých
továrnách – žádné animace, žádná práce v každém ticku.

### Co hráč dostane
- Entitu postavenou mezi dvěma bednami: bere ze zdroje (za sebou), dává do cíle (před sebe).
  Rotace (R) prohodí směr. Vždy jen jeden směr.
- Přesun proběhne **jen celou dávkou** a **jen pokud se celá vejde do cíle** („všechno, nebo nic“).
- **Velikost dávky:** `Auto` (= stack size daného předmětu) nebo pevné číslo (např. 5000).
- **Filtry:** 5 slotů, režim povolit/zakázat; prázdný filtr = cokoliv.
- **Obvodová síť** (každá funkce zvlášť zapínatelná): zapnout/vypnout podmínkou, velikost dávky
  ze signálu, filtry ze signálů.
- **Tiery** generované automaticky ze všech pásů ve hře (vanilla, Space Age i libovolné mody).
- Elektrická spotřeba rostoucí s tierem. Vizuálně jen stav „jede / nejede“.

### Mimo rozsah verze 0.1
- Fabriky, vagóny, raketová sila a jiné cíle než `container` / `logistic-container`.
- Čtení přesunů do obvodové sítě (lze doplnit později bez přestavby).
- Speciální chování při nedostatku proudu (low power) – entita buď má proud, nebo stojí.

## 2. Klíčová rozhodnutí

| Rozhodnutí | Volba | Důvod |
|---|---|---|
| Přesun | vlastní skript nad `LuaInventory` | engine inserter má strop ruky ~256 ks (`stack_size_bonus` je `uint8`) |
| Typ prototypu | `inserter` s vyřazeným vlastním pohybem | zdarma rotace, elektřina, dráty, 5 filtrů, podmínka sítě, blueprinty, copy-paste, upgrade planner |
| Cíle | `container`, `logistic-container` | zadání v0.1; sklady z modů jsou stejného typu |
| Pravidlo přesunu | všechno, nebo nic | předvídatelné chování, nevznikají rozdělené zbytky |
| Tiery | automaticky z `data.raw["transport-belt"]` | kompatibilita s libovolným modem bez údržby |
| Energie | elektrická, konstantní odběr (`drain`) škálovaný tierem | jednoduché, levné na UPS |
| Grafika | dočasně odvozená ze základní hry → finálně vlastní model z Blenderu | logika se dá ladit dřív, než je model hotový |

## 3. Prototypy (data stage)

### 3.1 Generování tierů – `data-final-fixes.lua`
Běží až po všech ostatních modech, aby viděl i jejich pásy.

1. Projde `data.raw["transport-belt"]`. Vyřadí pás, pokud:
   - má příznak `hidden` (nebo `flags` obsahuje `"hidden"`),
   - neexistuje recept, jehož výsledkem je předmět stavějící tento pás,
   - recept není dostupný od začátku (`enabled ~= false`) **a** žádný výzkum ho neodemyká.
2. Zbylé pásy seřadí podle `speed` vzestupně. Pořadí = číslo tieru.
3. Pro každý pás vytvoří: `inserter` entitu, `item`, `recipe` a přidá `unlock-recipe` efekt.

**Pojmenování:** `storage-optimizer-<jméno pásu>` (např. `storage-optimizer-fast-transport-belt`).
Lokalizovaný název: `{"entity-name.storage-optimizer", <lokalizovaný název pásu>}`.

**Interval přesunu (ticky):**
```
interval = max(1, round(120 × (rychlost_žlutého / rychlost_pásu) × násobič_rychlosti))
```
`rychlost_žlutého = 0.03125` (konstanta, aby výsledek nezávisel na tom, zda mod žlutý pás upravil).
Vanilla: žlutý 120 t (2 s), červený 60 t (1 s), modrý 40 t (0,67 s), Space Age turbo 30 t (0,5 s).

**Spotřeba:** `drain = 50 kW × (rychlost_pásu / rychlost_žlutého) × násobič_spotřeby`.

**Recept (laditelné v `prototypes/tiers.lua`):**
- Tier 1: 2× `fast-inserter`, 2× pás tieru, 5× `electronic-circuit`.
- Tier N: 1× předchozí tier, 2× pás tieru, 5× `electronic-circuit`.

**Výzkum:** stejný, který odemyká recept pásu. Pokud je pás dostupný od začátku, použije se
výzkum odemykající `fast-inserter`; pokud ani ten neexistuje, je recept dostupný od začátku.

**Upgrade:** `next_upgrade` a společná `fast_replaceable_group` řetězí tiery (upgrade planner,
přestavění přímo přes starší tier).

**Ikona:** základní ikona modu + ikona pásu jako překryv v rohu (vrstvy `icons`).

**Sdílená tabulka pro runtime:** interval každého tieru se nedá přečíst z prototypu inserteru,
proto se zapíše do prototypu `mod-data` s názvem `storage-optimizer-tiers`
(`data = { [jméno entity] = { tier, interval } }`); `control` ho čte přes
`prototypes.mod_data["storage-optimizer-tiers"].data`. Interval se zobrazí i v tooltipu
(`custom_tooltip_fields`).

### 3.2 Entita (typ `inserter`)
- `collision_box` / `selection_box` 1×1, `filter_count = 5`, `stack_size_bonus = 0`.
- `circuit_wire_max_distance` a konektory jako u inserteru.
- `energy_source = { type = "electric", usage_priority = "secondary-input", drain = ... }`,
  `energy_per_movement` a `energy_per_rotation` = minimum (rameno se nepohybuje).
- **Vyřazení vlastního pohybu:** `pickup_position` i `insert_position` míří na vlastní políčko,
  takže engine inserter nikdy nenajde zdroj ani cíl a usne (žádná zátěž UPS).
  Zdroj a cíl počítá skript z `entity.direction`.
  *Ověřuje fáze 0 (spike); záložní varianta: `disabled_by_script`.*
- Grafika ramene prázdná; plošina = dočasně obarvená plošina inserteru, později model z Blenderu.

### 3.3 Signál
Vlastní `virtual-signal` `storage-optimizer-batch` („Velikost dávky“) jako výchozí signál
pro nastavení dávky z obvodové sítě.

### 3.4 Startup nastavení (`settings.lua`)
| Název | Typ | Výchozí | Rozsah |
|---|---|---|---|
| `storage-optimizer-speed-multiplier` | double | 1.0 | 0.1 – 10 (větší = pomalejší) |
| `storage-optimizer-power-multiplier` | double | 1.0 | 0 – 10 |

## 4. Runtime (control stage)

### 4.1 Ukládání nastavení
Všechna nastavení jsou v nativních polích entity, takže blueprinty, copy-paste a upgrade fungují bez
vlastního kódu:

| Nastavení | Kde |
|---|---|
| Filtry (5) | `entity.set_filter(i, …)` / `get_filter` |
| Povolit/zakázat | `entity.inserter_filter_mode` |
| Velikost dávky | `entity.inserter_stack_size_override` (0 = Auto) |
| Zapnout/vypnout podmínkou | `control_behavior.circuit_enable_disable` + `circuit_condition` |
| Dávka ze signálu | `control_behavior.circuit_set_stack_size` + `circuit_stack_control_signal` |
| Filtry ze signálů | `control_behavior.circuit_set_filters` |

**Riziko:** engine může `inserter_stack_size_override` omezit na velikost ruky. Pokud to fáze 0
potvrdí, velikost dávky se uloží do `storage` a do blueprintů se přenese přes tagy
(`on_player_setup_blueprint`, `on_built_entity` → `tags`, `on_entity_settings_pasted`).

### 4.2 Registr (`scripts/registry.lua`)
`storage.movers[unit_number] = { entity, source, target, interval, state, light }`
- `source` / `target` jsou **inventáře** (`LuaInventory`) sousedních beden, nebo `nil`.
- Zdroj = políčko za entitou, cíl = políčko před ní (podle `entity.direction`, stejně jako šipka
  u inserteru).
- Přepočet sousedů: při postavení entity, při její rotaci (`on_player_rotated_entity`), při postavení
  nebo zániku bedny/skladu v sousedství.
- Hledání dotčených entit při změně bedny: `surface.find_entities_filtered` v obdélníku = hranice
  bedny rozšířené o 1 políčko (funguje i pro velké sklady N×N).
- Všechny události používají **event filtry** (jen naše entity / jen kontejnery), aby se handler
  nespouštěl pro nic jiného.
- Zánik vlastní entity: události vytěžení, zničení a `script_raised_destroy`.

### 4.3 Plánovač (`scripts/scheduler.lua`) – jádro úspory UPS
- `storage.schedule[tick] = { unit_number, … }`.
- `on_tick` zpracuje pouze seznam pro aktuální tick (prázdný tick = jedno vyhledání v tabulce).
- Po zpracování se entita přeplánuje na `tick + interval`. Nově postavené entity se rozloží
  přirozeně podle okamžiku postavení.
- Entita bez zdroje nebo cíle **v plánu není** – vrátí se do něj až při změně sousedů.
- Neplatná entita (zničená mezi ticky) se při zpracování tiše vyřadí.

### 4.4 Jeden přesun (`scripts/transfer.lua`)
1. Bez proudu (`entity.status == no_power`) → stav „bez proudu“, konec.
2. Podmínka sítě zapnutá a nesplněná (`control_behavior.disabled`) → stav „vypnuto sítí“, konec.
3. Velikost dávky: signál ze sítě (pokud zapnuto a > 0) → jinak override → jinak `Auto`.
4. `source.get_contents()` (agregované položky `{name, quality, count}`). Projde je počínaje
   **rotujícím ukazatelem** (aby jeden předmět nevyhladověl ostatní) a vybere první, který:
   - projde filtrem (včetně porovnání kvality podle filtru),
   - `count ≥ dávka` (dávka u `Auto` = `prototypes.item[name].stack_size`),
   - `target.get_insertable_count({name, quality}) ≥ dávka`.
5. Přesune dávku **po slotech** (`find_item_stack` → vložení stacku do cíle → snížení počtu ve
   zdroji), takže se zachová kvalita, čerstvost (spoilage) i data předmětu.
6. Nic nevyhovuje → stav „čeká“ (zdroj nemá celou dávku / cíl nemá místo).

Za jeden cyklus se přesune **nejvýše jedna dávka**.

### 4.5 Indikace stavu
Jeden sprite/světlo přes `rendering` vytvořené při postavení. Mění se **jen při změně stavu**
(viditelnost, barva: zelená = přesunuje, žlutá = čeká, červená = bez proudu/vypnuto).
Žádné překreslování v každém ticku.

### 4.6 GUI (`scripts/gui/`)
Otevře se místo nativního okna inserteru (`on_gui_opened` → `player.opened = vlastní okno`).
- Hlavička: název tieru, interval, stav, zdroj → cíl.
- Filtry: 5× `choose-elem-button` (item-with-quality), přepínač povolit/zakázat.
- Velikost dávky: `Auto` / číselné pole.
- Obvodová síť (jen pokud je připojen drát): zaškrtávátka a výběr podmínky / signálu.
- GUI pouze zapisuje do nativních polí z 4.1; stav čte z registru. Zavírá se klávesou E/Esc.

### 4.7 Migrace a načtení
- `on_init`: založí `storage`.
- `on_configuration_changed`: přepočte intervaly všech registrovaných entit (změna nastavení
  nebo přidání/odebrání modu s pásy), odstraní neplatné záznamy, znovu postaví plán.
- `on_load`: nic (žádné lokální reference mimo `storage`).

## 5. Struktura repozitáře

```
Storage_optimizer/            ← samotný mod (junction do %APPDATA%/Factorio/mods)
  info.json
  changelog.txt
  thumbnail.png                 ← 144×144
  settings.lua
  data.lua                      ← signál, společné části
  data-final-fixes.lua          ← generování tierů
  control.lua                   ← jen napojení událostí
  prototypes/
    tiers.lua                   ← výběr pásů, výpočet intervalu/spotřeby, recepty (laditelné hodnoty)
    entity.lua  item.lua  recipe.lua  technology.lua  signal.lua
  scripts/
    registry.lua  scheduler.lua  transfer.lua  neighbours.lua  indicator.lua
    gui/ main.lua  filters.lua  circuit.lua
  locale/en/locale.cfg
  locale/cs/locale.cfg
  graphics/ icons/  entity/
  tests/                        ← testy pro mod factorio-test (načítají se jen s ním)
docs/
  superpowers/specs/            ← tato specifikace
  user-guide.md                 ← uživatelská dokumentace (CZ)
  mod-portal.md                 ← popis pro mod portál (EN)
  development.md                ← vývojové prostředí, ladění, balení, publikace
blender/                        ← zdrojový .blend a renderovací skript
README.md
LICENSE                         ← MIT, Ypsilonx
```

## 6. Testování
- **Automatické testy ve hře:** mod `factorio-test` (volitelná skrytá závislost `(?) factorio-test`).
  Pokrytí: výběr a řazení tierů, výpočet intervalu, pravidlo všechno-nebo-nic, filtry
  (povolit/zakázat, kvalita), rotace prohodí zdroj/cíl, změna sousedů, neplatné entity,
  nastavení přes síť, zachování nastavení přes blueprint.
- **Ruční test:** FMTK debugger, scénář s vanillou, se Space Age a s jedním modem s dalšími pásy.
- **Výkon:** srovnání UPS (`show-time-usage`) s 1 000 entitami proti ekvivalentu loader + pás + unloader.

## 7. Fáze implementace
0. **Spike (zahodí se):** inserter s pozicemi na vlastním políčku – usne? Funguje `control_behavior.disabled`,
   `circuit_set_filters`? Omezuje engine `inserter_stack_size_override`? Výsledek rozhodne 3.2 a 4.1.
1. Kostra modu + generování tierů + dočasná grafika.
2. Registr, sousedé, plánovač, přesun (bez GUI, nastavení přes nativní okno nebo konzoli).
3. Vlastní GUI.
4. Obvodová síť.
5. Grafika z Blenderu (model, render 4 směrů + stín + světlo stavu, ikony, thumbnail).
6. Publikace: lokalizace, dokumentace, changelog, `fmtk package`, kontrola na čisté instalaci.

## 8. Publikace – požadavky mod portálu
- `info.json`: `name`, `version` (0.1.0), `title`, `author` = Ypsilonx, `factorio_version` = "2.0",
  `description`, `dependencies` = `["base >= 2.0", "(?) factorio-test"]`.
- `changelog.txt` v přesném formátu Factoria (oddělovač z 99 pomlček, `Version:`, `Date:`, kategorie).
- `thumbnail.png` 144×144, licence MIT v repozitáři a v nastavení portálu.
- Lokalizace: angličtina (povinně pro portál) + čeština.

## 9. Dodatek – výsledky spike a úpravy při plánování (2026-10-01)

Spike (headless Factorio 2.0.77) ověřil:
- Inserter s `pickup_position = insert_position = {0, 0}` nic nepřesouvá (stav `waiting_for_source_items`), odebírá proud.
- `control_behavior.disabled` i `circuit_set_filters` fungují i na takto „uspaném“ inserteru.
- `inserter_stack_size_override` engine omezuje na **0–255** → velikost dávky je v `storage.movers[…].batch`
  a do blueprintů se přenáší tagem `so_batch` (varianta ze 4.1).
- `LuaInventory.insert` přijímá `spoil_percent`; `get_insertable_count` funguje.

Úpravy oproti specifikaci:
1. **GUI (4.6):** místo vlastního okna se použije nativní okno inserteru (filtry, režim, obvodová síť)
   a vedle něj **boční panel** (`player.gui.relative`) s tierem, trasou, stavem a velikostí dávky.
   Odpovídá pokynu „pro začátek využij inserter pro filtry a další“. Nativní okno ukazuje vlastní stav
   inserteru a posuvník „override stack size“ – v dokumentaci je uvedeno, že se ignorují.
2. **Testy (6):** místo modu factorio-test vlastní headless runner (`tools/run-tests.sh`) + jednotkové testy
   čisté logiky v lokální Lua 5.3. Bez externích závislostí, ověřeno spikem.
3. **Nastavení (3.4):** `storage-optimizer-speed-multiplier` přejmenováno na
   `storage-optimizer-interval-multiplier` (větší = pomalejší, název to říká přímo).
4. **Zánik bedny (4.2):** neřeší se událostí; plánovač při dalším cyklu zjistí neplatný inventář,
   přepočte sousedy a entitu bez zdroje/cíle z plánu vyřadí. Méně handlerů, stejné chování.
5. **Grafika z Blenderu, thumbnail a nahrání na portál** jsou samostatný navazující plán.

## 10. Dodatek – optimalizace UPS (2026-10-01)

Měření ukázalo, že inserter s ramenem na vlastním políčku engine dál počítá (~0,107 ms/tick na 1000 kusů).
Entita má proto za běhu `disabled_by_script = true`: engine ji nepočítá, ale dál vyhodnocuje podmínku sítě
a propisuje filtry ze signálů (ověřeno pokusem). Vypnutá entita neodebírá `drain`, takže se změnil model
energie (3.1, 3.2): **100 kJ za přesunutou dávku** (= 50 kW × 2 s, stejné pro všechny tiery), odebírá se
ze zásobníku entity (`buffer_capacity`), který síť dobíjí; nedostatek energie = stav `no_power`.
Výsledek: 0,225 ms/tick místo 0,350 (loadery 0,274) při 3,4× vyšší propustnosti.

## 11. Dodatek – počet stacků za přesun (2026-10-02)

- **Přesun = velikost stacku × počet stacků.** Velikost stacku zůstává Auto (stack předmětu) nebo ruční
  dávka; počet stacků 1–20 nastavuje hráč v bočním panelu, případně signál `storage-optimizer-stacks`
  (> 0 má přednost). Pravidlo „všechno, nebo nic“ platí pro celý přesun.
- **Energie:** 100 kJ × počet stacků za přesun.
- **Limit:** startup nastavení `storage-optimizer-max-stacks` (výchozí 20, rozsah 1–100). Zásobník entity
  má kapacitu `100 kJ × limit` a dobíjení je omezené na plný zásobník za jeden interval tieru, aby hromadná
  stavba nesrazila síť. Důsledek: po výpadku proudu optimizer dojede z už zaplacené energie v zásobníku.
- **Ukládání:** `mover.stacks` (nil = 1); tag blueprintu `so_stacks`; kopírování nastavení a výměna tieru
  přenášejí dávku i počet stacků; remote `get_stacks` / `set_stacks`.
