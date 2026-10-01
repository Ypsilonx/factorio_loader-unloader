# Storage Optimizer – funkční jádro (v0.1.0) – implementační plán

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Funkční mod `Storage_optimizer` pro Factorio 2.0: entita 1×1, která bez pásů přesouvá celé dávky mezi bednami, s automatickými tiery z pásů, filtry, obvodovou sítí, blueprinty, bočním GUI panelem, testy a dokumentací. Finální grafika z Blenderu a thumbnail jsou **samostatný navazující plán**.

**Architecture:** Entita je prototyp typu `inserter`, jehož rameno míří na vlastní políčko (engine ho uspí). Přesuny dělá skript: plánovač podle ticků (`storage.schedule[tick]`) zpracuje každou entitu jen jednou za interval jejího tieru; přesun jde po slotech přes pomocný inventář, takže zachová kvalitu, čerstvost i data předmětů. Nastavení (filtry, režim, podmínka sítě, signál dávky) leží v nativních polích inserteru; velikost dávky v `storage` + tagy blueprintu.

**Tech Stack:** Lua (Factorio 2.0.77 API), sumneko.lua + FMTK ve VSCode, lokální Lua 5.3 pro jednotkové testy čisté logiky, headless Factorio (`--create` + `--benchmark`) pro integrační testy, Git Bash skripty.

**Spec:** `docs/superpowers/specs/2026-10-01-storage-optimizer-design.md` (+ dodatek doplněný v Task 1)

## Global Constraints

- Interní název modu `Storage_optimizer`, titul „Storage Optimizer“, autor `Ypsilonx`, licence MIT, verze `0.1.0`.
- `factorio_version` = `"2.0"`, závislost `"base >= 2.0.0"`; musí fungovat bez i se Space Age.
- Prototypy tierů se jmenují `storage-optimizer-<jméno pásu>`; signál `storage-optimizer-batch`; mod-data `storage-optimizer-tiers`.
- Interval: `max(1, round(120 × (0.03125 / rychlost_pásu) × násobič))` ticků; drain: `50 kW × (rychlost_pásu / 0.03125) × násobič`.
- Cíle/zdroje pouze typy `container` a `logistic-container`.
- Pravidlo „všechno, nebo nic“: přesun jen celé dávky a jen pokud se celá vejde do cíle; nejvýše jedna dávka za cyklus.
- Žádná práce v každém ticku kromě jednoho vyhledání v `storage.schedule`.
- Komentáře a docstringy v kódu česky (každá funkce má stručný docstring), PEP-8 analogicky pro Lua: 2 mezery odsazení, `snake_case`.
- Lokalizace: `locale/en` (povinná) + `locale/cs`, se shodnou sadou klíčů.
- Commit jen tam, kde to plán říká (uživatel schválil plán = schválil tyto commity); push nikdy.

## Review Focus

1. **Soused, který není bedna** (fabrika, pás, jiný optimizer) – entita musí hlásit stav `no_chest` a nesmí spadnout. → test „soused není bedna“ v Task 5.
2. **Logistické bedny** (pasivní/požadavkové) jako zdroj i cíl – musí fungovat stejně jako běžná bedna. → test „logistická bedna“ v Task 5.
3. **Dávka větší než kapacita cíle** (např. 100 000) – entita čeká se stavem `waiting`, nic se neztratí. → test „dávka větší než cíl“ v Task 6.
4. **Předměty se stack size 1 a vlastními daty** (brnění s mřížkou) – přesunou se celé, data zůstanou. → test „předmět s daty“ v Task 5.
5. **Rychlá výměna tieru / upgrade planner** – ručně nastavená dávka se nesmí ztratit. Headless nelze simulovat hráče → ruční kontrola v Task 8 a v checklistu `docs/development.md`.

---

## Mapa souborů

```
Storage_optimizer/                 mod (junction do %APPDATA%/Factorio/mods)
  info.json, changelog.txt, settings.lua, data.lua, data-final-fixes.lua, control.lua
  prototypes/tiers.lua             čistá logika: výběr pásů, interval, drain (testováno mimo hru)
  prototypes/icons.lua             vrstvy ikony tieru
  prototypes/entity.lua            entita tieru (inserter bez pohybu)
  prototypes/item.lua              předmět tieru
  prototypes/recipe.lua            recept + odemčení výzkumem
  prototypes/signal.lua            virtuální signál „Velikost dávky“
  scripts/tiers.lua                runtime čtení mod-data (interval, seznam jmen)
  scripts/filters.lua              čistá logika filtrů (testováno mimo hru)
  scripts/registry.lua             storage.movers
  scripts/neighbours.lua           hledání zdroje a cíle
  scripts/scheduler.lua            plánovač podle ticků
  scripts/transfer.lua             jeden cyklus přesunu
  scripts/indicator.lua            ikonka stavu + šipka v alt režimu
  scripts/persistence.lua          blueprint tagy, copy-paste, rychlá výměna
  scripts/gui.lua                  boční panel u okna inserteru
  scripts/remote.lua               remote rozhraní (API pro mody a testy)
  locale/en/locale.cfg, locale/cs/locale.cfg
tests/unit/                        jednotkové testy (lua 5.3): run.lua, assert.lua, test_*.lua
tests/storage-optimizer-tests/     testovací mod: data.lua, control.lua, runner.lua, helpers.lua, cases/*.lua
tests/perf/so-perf/                výkonový scénář
tools/run-unit.sh, tools/run-tests.sh, tools/run-perf.sh, tools/link-mod.sh, tools/package.sh
.vscode/tasks.json
docs/user-guide.md, docs/mod-portal.md, docs/development.md
README.md, LICENSE
```

---

### Task 1: Kostra modu, testovací infrastruktura a smoke test

**Files:**
- Create: `Storage_optimizer/info.json`, `Storage_optimizer/changelog.txt`, `Storage_optimizer/settings.lua`, `Storage_optimizer/data.lua`, `Storage_optimizer/data-final-fixes.lua`, `Storage_optimizer/control.lua`, `Storage_optimizer/locale/en/locale.cfg`, `Storage_optimizer/locale/cs/locale.cfg`
- Create: `tests/unit/run.lua`, `tests/unit/assert.lua`
- Create: `tests/storage-optimizer-tests/info.json`, `.../data.lua`, `.../control.lua`, `.../runner.lua`, `.../helpers.lua`, `.../cases/smoke.lua`
- Create: `tools/run-unit.sh`, `tools/run-tests.sh`, `tools/link-mod.sh`, `.vscode/tasks.json`, `LICENSE`
- Modify: `.gitignore`, `docs/superpowers/specs/2026-10-01-storage-optimizer-design.md` (dodatek)

**Interfaces:**
- Produces: `tools/run-tests.sh <vanilla|space-age>` (exit 0 = vše prošlo; výstup řádky `SO-TEST …`), `tools/run-unit.sh` (exit 0 = vše prošlo; řádek `UNIT pass=N fail=M`).
- Produces (testovací mod): `runner.register(list)`; test = `{ name = string, requires = string|nil, setup = fun(ctx), steps = { { ticks = integer, run = fun(ctx) } } }`; `ctx = { surface = LuaSurface, origin = {x, y}, … }` (testy si do ctx ukládají vlastní pole).
- Produces (helpers `H`): `H.place(ctx, name, dx, dy, extra?) → LuaEntity`, `H.power(ctx)`, `H.chest(ctx, name, dx, dy, items?) → LuaEntity`, `H.mover(ctx, belt, dx, dy, direction?) → LuaEntity`, `H.count(entity, name, quality?) → integer`, `H.combinator(ctx, dx, dy, signals) → LuaEntity`, `H.set_signal(cc, slot, signal)`, `H.wire(a, b)`, `H.eq(actual, expected, what)`, `H.truthy(value, what)`.

- [ ] **Step 1: Zapsat dodatek do specifikace**

Na konec `docs/superpowers/specs/2026-10-01-storage-optimizer-design.md` připojit:

```markdown
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
```

- [ ] **Step 2: Vytvořit metadata modu**

`Storage_optimizer/info.json`:
```json
{
  "name": "Storage_optimizer",
  "version": "0.1.0",
  "title": "Storage Optimizer",
  "author": "Ypsilonx",
  "factorio_version": "2.0",
  "description": "Moves whole stacks between chests without belts. One building instead of loader + belt + unloader. Built for UPS.",
  "dependencies": ["base >= 2.0.0"]
}
```

`Storage_optimizer/changelog.txt` – první řádek musí mít **přesně 99 pomlček**, proto generovat příkazem:
```bash
cd "D:/61_Programing/factorio_loader-unloader"
{ printf -- '-%.0s' $(seq 1 99); printf '\n'; cat <<'EOF'
Version: 0.1.0
Date: 2026-10-01
  Features:
    - First release: one building that moves whole stacks between chests without belts.
EOF
} > Storage_optimizer/changelog.txt
head -1 Storage_optimizer/changelog.txt | tr -d '\n' | wc -c
```
Expected: `99`

`LICENSE`:
```
MIT License

Copyright (c) 2026 Ypsilonx

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Vytvořit settings.lua, prázdné stage soubory a základ lokalizace**

`Storage_optimizer/settings.lua`:
```lua
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
```

`Storage_optimizer/data.lua`:
```lua
-- Data stage: prototypy nezávislé na ostatních modech (doplňuje Task 3).
```

`Storage_optimizer/data-final-fixes.lua`:
```lua
-- Generování tierů po načtení všech modů (doplňuje Task 3).
```

`Storage_optimizer/control.lua`:
```lua
-- Storage Optimizer – napojení událostí (doplňuje Task 5).
```

`Storage_optimizer/locale/en/locale.cfg`:
```ini
[mod-name]
Storage_optimizer=Storage Optimizer

[mod-description]
Storage_optimizer=Moves whole stacks between chests without belts. One building instead of loader + belt + unloader. Built for UPS.

[mod-setting-name]
storage-optimizer-interval-multiplier=Transfer interval multiplier
storage-optimizer-power-multiplier=Power consumption multiplier

[mod-setting-description]
storage-optimizer-interval-multiplier=Multiplies the time between two transfers for every tier. 2 = half as fast, 0.5 = twice as fast.
storage-optimizer-power-multiplier=Multiplies the electricity drain of every tier. 0 = no consumption.
```

`Storage_optimizer/locale/cs/locale.cfg`:
```ini
[mod-name]
Storage_optimizer=Storage Optimizer

[mod-description]
Storage_optimizer=Přesouvá celé stacky mezi bednami bez pásů. Jedna budova místo loaderu, pásu a unloaderu. Šetří UPS.

[mod-setting-name]
storage-optimizer-interval-multiplier=Násobič intervalu přesunu
storage-optimizer-power-multiplier=Násobič spotřeby energie

[mod-setting-description]
storage-optimizer-interval-multiplier=Násobí čas mezi dvěma přesuny u všech tierů. 2 = poloviční rychlost, 0,5 = dvojnásobná.
storage-optimizer-power-multiplier=Násobí odběr elektřiny všech tierů. 0 = bez spotřeby.
```

- [ ] **Step 4: Vytvořit runner jednotkových testů**

`tests/unit/assert.lua`:
```lua
--- Pomocné aserce pro jednotkové testy mimo hru.
local A = {}

--- Selže, pokud se hodnoty nerovnají.
--- @param actual any
--- @param expected any
--- @param what string popis kontrolované hodnoty
function A.eq(actual, expected, what)
  if actual ~= expected then
    error(string.format("%s: čekáno %s, dostáno %s", what, tostring(expected), tostring(actual)), 2)
  end
end

--- Selže, pokud hodnota není pravdivá.
function A.truthy(value, what)
  if not value then error(what .. ": čekána pravdivá hodnota", 2) end
end

return A
```

`tests/unit/run.lua`:
```lua
--- Runner jednotkových testů čisté Lua logiky modu (spouští se z kořene repozitáře: lua tests/unit/run.lua).
package.path = "Storage_optimizer/?.lua;tests/unit/?.lua;" .. package.path

--- Seznam testovacích sad; každá vrací pole { "název", funkce }.
local SUITES = {}

local pass, fail = 0, 0
for _, suite in ipairs(SUITES) do
  for _, case in ipairs(require(suite)) do
    local ok, err = pcall(case[2])
    if ok then
      pass = pass + 1
    else
      fail = fail + 1
      print("FAIL " .. suite .. " :: " .. case[1] .. ": " .. tostring(err))
    end
  end
end
print(string.format("UNIT pass=%d fail=%d", pass, fail))
os.exit(fail == 0 and 0 or 1)
```

`tools/run-unit.sh`:
```bash
#!/usr/bin/env bash
# Spustí jednotkové testy čisté logiky modu v lokální Lua.
set -euo pipefail
cd "$(dirname "$0")/.."
lua tests/unit/run.lua
```

- [ ] **Step 5: Ověřit runner jednotkových testů**

Run: `bash tools/run-unit.sh`
Expected: `UNIT pass=0 fail=0`, exit 0.

- [ ] **Step 6: Vytvořit testovací mod (runner, helpers, smoke test)**

`tests/storage-optimizer-tests/info.json`:
```json
{
  "name": "storage-optimizer-tests",
  "version": "0.1.0",
  "title": "Storage Optimizer – tests",
  "author": "Ypsilonx",
  "factorio_version": "2.0",
  "dependencies": ["Storage_optimizer"]
}
```

`tests/storage-optimizer-tests/data.lua`:
```lua
-- Testovací prototypy (doplňuje Task 3).
```

`tests/storage-optimizer-tests/helpers.lua`:
```lua
--- Pomocné funkce pro integrační testy: stavění entit, napájení, signály a aserce.
local H = {}

--- Postaví entitu na dlaždici (dx, dy) relativně k počátku testu; vyvolá script_raised_built.
--- @return LuaEntity
function H.place(ctx, name, dx, dy, extra)
  local spec = {
    name = name,
    position = { ctx.origin.x + dx + 0.5, ctx.origin.y + dy + 0.5 },
    force = "player",
    raise_built = true,
  }
  for key, value in pairs(extra or {}) do spec[key] = value end
  local entity = ctx.surface.create_entity(spec)
  if not entity then error("nelze postavit " .. name, 2) end
  return entity
end

--- Napájí výřez testu: neomezený zdroj a rozvodna pokrývající okolí počátku (±9 dlaždic od (-3, -3)).
function H.power(ctx)
  local source = H.place(ctx, "electric-energy-interface", -6, -6)
  source.power_production = 1e9
  source.electric_buffer_size = 1e10
  H.place(ctx, "substation", -3, -3)
end

--- Postaví bednu a vloží do ní předměty (pole ItemStackDefinition).
function H.chest(ctx, name, dx, dy, items)
  local chest = H.place(ctx, name, dx, dy)
  for _, item in ipairs(items or {}) do chest.insert(item) end
  return chest
end

--- Postaví Storage optimizer tieru odpovídajícího pásu (výchozí směr sever = zdroj na severu).
function H.mover(ctx, belt, dx, dy, direction)
  return H.place(ctx, "storage-optimizer-" .. belt, dx, dy, { direction = direction or defines.direction.north })
end

--- Počet kusů předmětu dané kvality v bedně.
function H.count(entity, name, quality)
  return entity.get_inventory(defines.inventory.chest).get_item_count({ name = name, quality = quality or "normal" })
end

--- Nastaví jeden slot konstantního kombinátoru (signal = { type?, name, count }).
function H.set_signal(combinator, slot, signal)
  local section = combinator.get_control_behavior().get_section(1)
  section.set_slot(slot, {
    value = { type = signal.type or "item", name = signal.name, quality = "normal", comparator = "=" },
    min = signal.count,
  })
end

--- Postaví konstantní kombinátor se zadanými signály.
function H.combinator(ctx, dx, dy, signals)
  local combinator = H.place(ctx, "constant-combinator", dx, dy)
  for slot, signal in ipairs(signals) do H.set_signal(combinator, slot, signal) end
  return combinator
end

--- Propojí dvě entity červeným drátem.
function H.wire(a, b)
  local red = defines.wire_connector_id.circuit_red
  a.get_wire_connector(red, true).connect_to(b.get_wire_connector(red, true))
end

--- Selže, pokud se hodnoty nerovnají.
function H.eq(actual, expected, what)
  if actual ~= expected then
    error(string.format("%s: čekáno %s, dostáno %s", what, tostring(expected), tostring(actual)), 0)
  end
end

--- Selže, pokud hodnota není pravdivá.
function H.truthy(value, what)
  if not value then error(what .. ": čekána pravdivá hodnota", 0) end
end

return H
```

`tests/storage-optimizer-tests/runner.lua`:
```lua
--- Minimalistický runner integračních testů: testy běží paralelně, každý na vlastním výřezu povrchu.
--- Výsledky jdou do logu s prefixem SO-TEST, souhrn řádkem „SO-TEST DONE pass=… fail=… skip=…“.
local M = {}

--- Registrované testy (definované v kódu, ve storage je jen jejich stav podle indexu).
local cases = {}

--- Přidá seznam testů.
function M.register(list)
  for _, case in ipairs(list) do cases[#cases + 1] = case end
end

--- Zaloguje výsledek a započítá ho do souhrnu.
local function finish(state, result, message)
  state.done = true
  storage.summary[result] = storage.summary[result] + 1
  log("SO-TEST " .. string.upper(result) .. " " .. cases[state.index].name .. (message and (": " .. message) or ""))
end

--- Vytvoří povrch s laboratorními dlaždicemi a spustí setup všech testů.
function M.on_init()
  local surface = game.create_surface("so-test")
  surface.generate_with_lab_tiles = true
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  storage.summary = { pass = 0, fail = 0, skip = 0 }
  storage.tests = {}
  for index, case in ipairs(cases) do
    local origin = { x = ((index - 1) % 8) * 24 - 96, y = math.floor((index - 1) / 8) * 24 - 96 }
    local state = { index = index, step = 1, ctx = { surface = surface, origin = origin } }
    storage.tests[index] = state
    if case.requires and not script.active_mods[case.requires] then
      finish(state, "skip", "chybí mod " .. case.requires)
    else
      local ok, err = pcall(case.setup or function() end, state.ctx)
      if ok then
        state.due = game.tick + case.steps[1].ticks
      else
        finish(state, "fail", "setup: " .. tostring(err))
      end
    end
  end
end

--- Spustí kroky, které jsou v tomto ticku na řadě; po dokončení všech testů zaloguje souhrn.
function M.on_tick(event)
  if storage.finished then return end
  local all_done = true
  for _, state in ipairs(storage.tests) do
    if not state.done then
      all_done = false
      if state.due == event.tick then
        local case = cases[state.index]
        local ok, err = pcall(case.steps[state.step].run, state.ctx)
        if not ok then
          finish(state, "fail", tostring(err))
        elseif state.step == #case.steps then
          finish(state, "pass")
        else
          state.step = state.step + 1
          state.due = event.tick + case.steps[state.step].ticks
        end
      end
    end
  end
  if all_done then
    storage.finished = true
    local s = storage.summary
    log(string.format("SO-TEST DONE pass=%d fail=%d skip=%d", s.pass, s.fail, s.skip))
  end
end

return M
```

`tests/storage-optimizer-tests/cases/smoke.lua`:
```lua
--- Kouřový test: mod se načte a testovací infrastruktura funguje.
local H = require("helpers")

return {
  {
    name = "mod je aktivní",
    steps = {
      { ticks = 1, run = function() H.truthy(script.active_mods["Storage_optimizer"], "Storage_optimizer aktivní") end },
    },
  },
}
```

`tests/storage-optimizer-tests/control.lua`:
```lua
-- Headless integrační testy modu Storage_optimizer (spouští tools/run-tests.sh).
local runner = require("runner")

runner.register(require("cases.smoke"))

script.on_init(runner.on_init)
script.on_event(defines.events.on_tick, runner.on_tick)
```

- [ ] **Step 7: Vytvořit skript integračních testů**

`tools/run-tests.sh`:
```bash
#!/usr/bin/env bash
# Spustí integrační testy v headless Factoriu: vytvoří mapu s modem a testovacím modem,
# odsimuluje ticky a vyhodnotí řádky SO-TEST z logu.
# Použití: tools/run-tests.sh [vanilla|space-age]   (cestu k Factoriu lze změnit proměnnou FACTORIO_EXE)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_EXE:-C:/STEAM/steamapps/common/Factorio/bin/x64/factorio.exe}"
VARIANT="${1:-vanilla}"
RUN="$ROOT/.test-run/$VARIANT"
RUN_W="$(cygpath -m "$RUN")"

rm -rf "$RUN"
mkdir -p "$RUN/mods" "$RUN/write-data"
cp -r "$ROOT/Storage_optimizer" "$RUN/mods/Storage_optimizer"
cp -r "$ROOT/tests/storage-optimizer-tests" "$RUN/mods/storage-optimizer-tests"

SA=false
[ "$VARIANT" = "space-age" ] && SA=true
cat > "$RUN/mods/mod-list.json" <<EOF
{"mods":[
  {"name":"base","enabled":true},
  {"name":"elevated-rails","enabled":$SA},
  {"name":"quality","enabled":$SA},
  {"name":"space-age","enabled":$SA},
  {"name":"Storage_optimizer","enabled":true},
  {"name":"storage-optimizer-tests","enabled":true}
]}
EOF
# Oddělená write-data složka, aby testy nepřepisovaly log a konfiguraci hráče.
cat > "$RUN/config.ini" <<EOF
[path]
read-data=__PATH__executable__/../../data
write-data=$RUN_W/write-data
EOF

ARGS=(--config "$RUN_W/config.ini" --mod-directory "$RUN_W/mods")
"$FACTORIO" "${ARGS[@]}" --create "$RUN_W/test.zip" > "$RUN/create.log" 2>&1 || true
if [ ! -f "$RUN/test.zip" ]; then
  echo "Vytvoření mapy selhalo:"; grep -A12 -E "Error|error" "$RUN/create.log" | head -40
  exit 1
fi
"$FACTORIO" "${ARGS[@]}" --benchmark "$RUN_W/test.zip" --benchmark-ticks 1500 --disable-audio > "$RUN/bench.log" 2>&1 || true
grep -E "SO-TEST|Error" "$RUN/bench.log" | sed 's/.*SO-TEST/SO-TEST/'
grep -q "SO-TEST DONE pass=[0-9]* fail=0 " "$RUN/bench.log"
```

`tools/link-mod.sh`:
```bash
#!/usr/bin/env bash
# Vytvoří junction %APPDATA%/Factorio/mods/Storage_optimizer → složka modu v repozitáři,
# aby hra načítala rozpracovanou verzi přímo z repozitáře (pro ruční hraní a FMTK debugger).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINK="$APPDATA/Factorio/mods/Storage_optimizer"
if [ -e "$LINK" ]; then echo "Už existuje: $LINK"; exit 0; fi
cmd //c mklink /J "$(cygpath -w "$LINK")" "$(cygpath -w "$ROOT/Storage_optimizer")"
```

`.gitignore` – doplnit řádky:
```
# Běhy testů a sestavené balíčky
.test-run/
dist/
```

- [ ] **Step 8: Spustit smoke test**

Run: `bash tools/run-tests.sh vanilla`
Expected: obsahuje `SO-TEST PASS mod je aktivní` a `SO-TEST DONE pass=1 fail=0 skip=0`, exit 0.
Pokud Factorio odmítne `--config` (chyba v `create.log`), odstranit `--config` z `ARGS`, zapsat to do komentáře ve skriptu a spustit znovu.

Run: `bash tools/run-tests.sh space-age`
Expected: `SO-TEST DONE pass=1 fail=0 skip=0`, exit 0.

- [ ] **Step 9: VSCode úlohy**

Zjistit cestu ke Git Bash: `where bash` (v PowerShellu) – použít tu z `Git\bin`, ne `System32\bash.exe` (WSL). `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "options": { "shell": { "executable": "C:\\Program Files\\Git\\bin\\bash.exe", "args": ["-c"] } },
  "tasks": [
    { "label": "Unit testy", "type": "shell", "command": "tools/run-unit.sh", "group": "test", "problemMatcher": [] },
    { "label": "Integrační testy (vanilla)", "type": "shell", "command": "tools/run-tests.sh vanilla", "group": "test", "problemMatcher": [] },
    { "label": "Integrační testy (Space Age)", "type": "shell", "command": "tools/run-tests.sh space-age", "group": "test", "problemMatcher": [] }
  ]
}
```
(Pokud `where bash` ukáže jinou cestu ke Git Bash, použít ji.)

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Kostra modu Storage_optimizer a testovací infrastruktura"
```

---

### Task 2: Výpočet tierů (čistá logika)

**Files:**
- Create: `Storage_optimizer/prototypes/tiers.lua`
- Test: `tests/unit/test_tiers.lua`
- Modify: `tests/unit/run.lua` (seznam `SUITES`)

**Interfaces:**
- Produces: `tiers.YELLOW_SPEED = 0.03125`, `tiers.BASE_INTERVAL = 120`, `tiers.BASE_DRAIN_KW = 50`,
  `tiers.interval_ticks(speed, multiplier) → integer`, `tiers.drain_kw(speed, multiplier) → number`,
  `tiers.find_unlocking_tech(raw, recipe_name) → string|nil`,
  `tiers.collect(raw) → { { belt = string, speed = number, item = string, recipe = string, tech = string|nil } }` seřazené podle `speed`.

- [ ] **Step 1: Napsat padající testy**

`tests/unit/test_tiers.lua`:
```lua
--- Jednotkové testy výběru pásů a výpočtu parametrů tierů.
local A = require("assert")
local tiers = require("prototypes.tiers")

--- Sestaví testovací náhradu data.raw s pásy zadanými jako { jméno = { speed, hidden?, enabled?, tech? } }.
local function fake_raw(belts)
  local raw = { ["transport-belt"] = {}, item = {}, recipe = {}, technology = {} }
  for name, b in pairs(belts) do
    raw["transport-belt"][name] = { name = name, speed = b.speed, hidden = b.hidden }
    raw.item[name] = { name = name, place_result = name }
    raw.recipe[name] = { name = name, enabled = b.enabled, results = { { type = "item", name = name, amount = 1 } } }
    if b.tech then
      raw.technology[b.tech] = { name = b.tech, effects = { { type = "unlock-recipe", recipe = name } } }
    end
  end
  return raw
end

return {
  { "interval vanilla pásů", function()
    A.eq(tiers.interval_ticks(0.03125, 1), 120, "žlutý")
    A.eq(tiers.interval_ticks(0.0625, 1), 60, "červený")
    A.eq(tiers.interval_ticks(0.09375, 1), 40, "modrý")
    A.eq(tiers.interval_ticks(0.125, 1), 30, "turbo")
  end },
  { "interval s násobičem a spodní mez", function()
    A.eq(tiers.interval_ticks(0.03125, 2), 240, "násobič 2")
    A.eq(tiers.interval_ticks(100, 0.1), 1, "minimum 1 tick")
  end },
  { "drain škáluje s rychlostí", function()
    A.eq(tiers.drain_kw(0.03125, 1), 50, "žlutý")
    A.eq(tiers.drain_kw(0.0625, 1), 100, "červený")
    A.eq(tiers.drain_kw(0.0625, 0), 0, "násobič 0")
  end },
  { "řazení podle rychlosti", function()
    local list = tiers.collect(fake_raw({
      fast = { speed = 0.0625, tech = "t2" },
      slow = { speed = 0.03125 },
      express = { speed = 0.09375, tech = "t3" },
    }))
    A.eq(#list, 3, "počet")
    A.eq(list[1].belt, "slow", "1.")
    A.eq(list[2].belt, "fast", "2.")
    A.eq(list[3].belt, "express", "3.")
    A.eq(list[2].tech, "t2", "výzkum")
    A.eq(list[1].tech, nil, "pás dostupný od začátku nemá výzkum")
  end },
  { "vyřazení skrytých a nedostupných pásů", function()
    local list = tiers.collect(fake_raw({
      ok = { speed = 0.03125 },
      hidden = { speed = 0.0625, hidden = true },
      locked = { speed = 0.09375, enabled = false },
    }))
    A.eq(#list, 1, "zbyde jen dostupný")
    A.eq(list[1].belt, "ok", "jméno")
  end },
  { "pás bez předmětu nebo receptu se vyřadí", function()
    local raw = fake_raw({ a = { speed = 0.03125 } })
    raw["transport-belt"].orphan = { name = "orphan", speed = 0.0625 }
    A.eq(#tiers.collect(raw), 1, "orphan vynechán")
  end },
}
```

`tests/unit/run.lua` – změnit řádek se seznamem:
```lua
local SUITES = { "test_tiers" }
```

- [ ] **Step 2: Ověřit, že testy padají**

Run: `bash tools/run-unit.sh`
Expected: chyba `module 'prototypes.tiers' not found`, exit ≠ 0.

- [ ] **Step 3: Implementace**

`Storage_optimizer/prototypes/tiers.lua`:
```lua
--- Čistá logika výběru pásů a výpočtu parametrů tierů.
--- Nepoužívá globály Factoria, aby šla testovat mimo hru (tests/unit/test_tiers.lua).
local M = {}

--- Rychlost žlutého pásu ve vanille (dlaždice/tick) – referenční bod všech výpočtů.
M.YELLOW_SPEED = 0.03125
--- Interval přesunu tieru se žlutou rychlostí v tickách (120 t = 2 s). Laditelná hodnota.
M.BASE_INTERVAL = 120
--- Odběr tieru se žlutou rychlostí v kW. Laditelná hodnota.
M.BASE_DRAIN_KW = 50

--- Spočítá interval přesunu v tickách.
--- @param speed number rychlost pásu
--- @param multiplier number násobič z nastavení (větší = pomalejší)
--- @return integer interval, nejméně 1
function M.interval_ticks(speed, multiplier)
  local raw = M.BASE_INTERVAL * (M.YELLOW_SPEED / speed) * multiplier
  return math.max(1, math.floor(raw + 0.5))
end

--- Spočítá odběr energie tieru v kW.
--- @param speed number rychlost pásu
--- @param multiplier number násobič z nastavení
--- @return number
function M.drain_kw(speed, multiplier)
  return M.BASE_DRAIN_KW * (speed / M.YELLOW_SPEED) * multiplier
end

--- Vrátí klíče tabulky seřazené abecedně (deterministické pořadí i mimo Factorio).
local function sorted_keys(t)
  local keys = {}
  for key in pairs(t or {}) do keys[#keys + 1] = key end
  table.sort(keys)
  return keys
end

--- Najde předmět, který staví danou entitu.
local function find_place_item(raw, entity_name)
  for _, name in ipairs(sorted_keys(raw.item)) do
    if raw.item[name].place_result == entity_name then return name end
  end
end

--- Najde recept, jehož výsledkem je daný předmět.
local function find_recipe(raw, item_name)
  for _, name in ipairs(sorted_keys(raw.recipe)) do
    for _, result in ipairs(raw.recipe[name].results or {}) do
      if result.name == item_name then return name end
    end
  end
end

--- Najde výzkum, který odemyká daný recept.
--- @return string|nil jméno výzkumu
function M.find_unlocking_tech(raw, recipe_name)
  for _, name in ipairs(sorted_keys(raw.technology)) do
    for _, effect in ipairs(raw.technology[name].effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then return name end
    end
  end
end

--- Projde všechny pásy a vrátí použitelné (neskryté, s předmětem a receptem dostupným od začátku
--- nebo přes výzkum), seřazené podle rychlosti.
--- @param raw table data.raw nebo jeho testovací náhrada
--- @return table[] { belt, speed, item, recipe, tech } – tech = nil znamená recept dostupný od začátku
function M.collect(raw)
  local result = {}
  for _, name in ipairs(sorted_keys(raw["transport-belt"])) do
    local belt = raw["transport-belt"][name]
    local item = not belt.hidden and find_place_item(raw, name)
    local recipe = item and find_recipe(raw, item)
    if recipe then
      local tech = M.find_unlocking_tech(raw, recipe)
      if tech or raw.recipe[recipe].enabled ~= false then
        result[#result + 1] = { belt = name, speed = belt.speed, item = item, recipe = recipe, tech = tech }
      end
    end
  end
  table.sort(result, function(a, b)
    if a.speed ~= b.speed then return a.speed < b.speed end
    return a.belt < b.belt
  end)
  return result
end

return M
```

- [ ] **Step 4: Ověřit, že testy prochází**

Run: `bash tools/run-unit.sh`
Expected: `UNIT pass=6 fail=0`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add Storage_optimizer/prototypes/tiers.lua tests/unit
git commit -m "Výpočet tierů z pásů (čistá logika + jednotkové testy)"
```

---

### Task 3: Generování prototypů (entita, předmět, recept, výzkum, signál, mod-data)

**Files:**
- Create: `Storage_optimizer/prototypes/icons.lua`, `entity.lua`, `item.lua`, `recipe.lua`, `signal.lua`
- Modify: `Storage_optimizer/data.lua`, `Storage_optimizer/data-final-fixes.lua`, `Storage_optimizer/locale/en/locale.cfg`, `Storage_optimizer/locale/cs/locale.cfg`
- Modify: `tests/storage-optimizer-tests/data.lua`, `tests/storage-optimizer-tests/control.lua`
- Test: `tests/storage-optimizer-tests/cases/prototypes.lua`

**Interfaces:**
- Consumes: `prototypes/tiers.lua` (Task 2).
- Produces: pro každý tier prototypy `inserter`, `item` a `recipe` se jménem `storage-optimizer-<pás>`; `mod-data` `storage-optimizer-tiers` s `data = { [jméno] = { tier = integer, interval = integer } }`; virtuální signál `storage-optimizer-batch`; testovací prototypy `so-test-belt` (rychlost 0.25 → tier s intervalem 15 t), `so-test-hidden-belt`, `so-test-warehouse` (3×3, 200 slotů).

- [ ] **Step 1: Testovací prototypy a padající testy**

`tests/storage-optimizer-tests/data.lua`:
```lua
-- Testovací prototypy: rychlý pás „z cizího modu“, skrytý pás a velký sklad 3×3.

--- Přidá pás se stejnojmenným předmětem a receptem dostupným od začátku.
local function add_belt(name, speed, hidden)
  local belt = table.deepcopy(data.raw["transport-belt"]["transport-belt"])
  belt.name = name
  belt.speed = speed
  belt.hidden = hidden
  belt.next_upgrade = nil
  belt.related_underground_belt = nil
  belt.minable = { mining_time = 0.1, result = name }
  local item = table.deepcopy(data.raw["item"]["transport-belt"])
  item.name = name
  item.place_result = name
  data:extend({
    belt,
    item,
    { type = "recipe", name = name, enabled = true, ingredients = {}, results = { { type = "item", name = name, amount = 1 } } },
  })
end

add_belt("so-test-belt", 0.25, false)
add_belt("so-test-hidden-belt", 0.125, true)

local warehouse = table.deepcopy(data.raw["container"]["steel-chest"])
warehouse.name = "so-test-warehouse"
warehouse.inventory_size = 200
warehouse.collision_box = { { -1.35, -1.35 }, { 1.35, 1.35 } }
warehouse.selection_box = { { -1.5, -1.5 }, { 1.5, 1.5 } }
warehouse.fast_replaceable_group = nil
warehouse.next_upgrade = nil
warehouse.minable = { mining_time = 0.1, result = "steel-chest" }
data:extend({ warehouse })
```

`tests/storage-optimizer-tests/cases/prototypes.lua`:
```lua
--- Testy vygenerovaných prototypů.
local H = require("helpers")

--- Interval tieru z mod-data.
local function interval(name)
  return prototypes.mod_data["storage-optimizer-tiers"].data[name].interval
end

--- Vrátí true, pokud nějaký výzkum odemyká recept.
local function unlocked_by_some_tech(recipe)
  for _, tech in pairs(prototypes.technology) do
    for _, effect in ipairs(tech.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe then return true end
    end
  end
  return false
end

--- Jednokrokový test bez setupu.
local function check(name, fn, requires)
  return { name = name, requires = requires, steps = { { ticks = 1, run = fn } } }
end

return {
  check("tiery z vanilla pásů", function()
    for _, belt in ipairs({ "transport-belt", "fast-transport-belt", "express-transport-belt" }) do
      local name = "storage-optimizer-" .. belt
      H.truthy(prototypes.entity[name], "entita " .. name)
      H.truthy(prototypes.item[name], "předmět " .. name)
      H.truthy(prototypes.recipe[name], "recept " .. name)
      H.eq(prototypes.entity[name].type, "inserter", "typ " .. name)
    end
  end),
  check("intervaly vanilla tierů", function()
    H.eq(interval("storage-optimizer-transport-belt"), 120, "žlutý")
    H.eq(interval("storage-optimizer-fast-transport-belt"), 60, "červený")
    H.eq(interval("storage-optimizer-express-transport-belt"), 40, "modrý")
  end),
  check("tier z pásu cizího modu", function()
    H.truthy(prototypes.entity["storage-optimizer-so-test-belt"], "entita testovacího pásu")
    H.eq(interval("storage-optimizer-so-test-belt"), 15, "interval testovacího pásu")
  end),
  check("skrytý pás nemá tier", function()
    H.eq(prototypes.entity["storage-optimizer-so-test-hidden-belt"], nil, "skrytý pás")
  end),
  check("upgrade řetěz", function()
    local first = prototypes.entity["storage-optimizer-transport-belt"]
    H.eq(first.next_upgrade and first.next_upgrade.name, "storage-optimizer-fast-transport-belt", "next_upgrade")
  end),
  check("recepty odemyká výzkum", function()
    H.truthy(unlocked_by_some_tech("storage-optimizer-transport-belt"), "žlutý tier")
    H.truthy(unlocked_by_some_tech("storage-optimizer-fast-transport-belt"), "červený tier")
  end),
  check("signál velikosti dávky", function()
    H.truthy(prototypes.virtual_signal["storage-optimizer-batch"], "virtuální signál")
  end),
  check("turbo tier (Space Age)", function()
    H.eq(interval("storage-optimizer-turbo-transport-belt"), 30, "turbo")
  end, "space-age"),
}
```

`tests/storage-optimizer-tests/control.lua` – přidat za registraci smoke testů:
```lua
runner.register(require("cases.prototypes"))
```

- [ ] **Step 2: Ověřit, že testy padají**

Run: `bash tools/run-tests.sh vanilla`
Expected: řádky `SO-TEST FAIL tiery z vanilla pásů …` (prototyp neexistuje / `mod_data` chybí), exit ≠ 0.

- [ ] **Step 3: Implementace prototypů**

`Storage_optimizer/prototypes/signal.lua`:
```lua
-- Virtuální signál „Velikost dávky“ – výchozí signál pro nastavení dávky z obvodové sítě.
local base = data.raw["virtual-signal"]["signal-S"]

data:extend({
  {
    type = "virtual-signal",
    name = "storage-optimizer-batch",
    icon = base.icon,
    icons = base.icons,
    icon_size = base.icon_size,
    subgroup = base.subgroup,
    order = "z[storage-optimizer-batch]",
  },
})
```

`Storage_optimizer/data.lua`:
```lua
-- Data stage: prototypy nezávislé na ostatních modech.
require("prototypes.signal")
```

`Storage_optimizer/prototypes/icons.lua`:
```lua
--- Ikony tierů (dočasné, než bude grafika z Blenderu): tónovaný rychlý inserter + ikona pásu v rohu.
local M = {}

--- Sestaví vrstvy ikony tieru.
--- @param belt_item string jméno předmětu pásu
--- @param tint table barva tieru
--- @return table[] IconData
function M.tier_icons(belt_item, tint)
  local base = data.raw["item"]["fast-inserter"]
  local belt = data.raw["item"][belt_item]
  local overlay = belt.icons and belt.icons[1] or { icon = belt.icon, icon_size = belt.icon_size }
  return {
    { icon = base.icon, icon_size = base.icon_size or 64, tint = tint },
    { icon = overlay.icon, icon_size = overlay.icon_size or 64, tint = overlay.tint, scale = 0.25, shift = { -8, -8 } },
  }
end

return M
```

`Storage_optimizer/prototypes/entity.lua`:
```lua
--- Entita tieru: prototyp typu inserter s vyřazeným vlastním pohybem ramene.
local M = {}

local EMPTY = { filename = "__core__/graphics/empty.png", size = 1 }

--- Barvy tierů (dočasné odlišení do grafiky z Blenderu); při více tierech se cyklí.
M.TINTS = {
  { r = 1.0, g = 0.85, b = 0.25 },
  { r = 1.0, g = 0.35, b = 0.3 },
  { r = 0.35, g = 0.65, b = 1.0 },
  { r = 0.55, g = 1.0, b = 0.45 },
  { r = 0.8, g = 0.45, b = 1.0 },
  { r = 1.0, g = 1.0, b = 1.0 },
}

--- Barva tieru podle jeho pořadí.
function M.tint(tier)
  return M.TINTS[(tier - 1) % #M.TINTS + 1]
end

--- Lokalizovaný název tieru: „Storage optimizer (<název pásu>)“.
function M.localised_name(belt)
  local proto = data.raw["transport-belt"][belt]
  return { "entity-name.storage-optimizer", proto.localised_name or { "entity-name." .. belt } }
end

--- Vytvoří entitu tieru.
--- @param info table položka z tiers.collect doplněná o name, tier, interval, drain_kw
--- @param icons table[] vrstvy ikony
function M.create(info, icons)
  local e = table.deepcopy(data.raw["inserter"]["fast-inserter"])
  e.name = info.name
  e.icon = nil
  e.icons = icons
  e.localised_name = M.localised_name(info.belt)
  e.localised_description = { "entity-description.storage-optimizer" }
  e.minable = { mining_time = 0.1, result = info.name }
  e.placeable_by = nil
  e.next_upgrade = nil
  e.fast_replaceable_group = "storage-optimizer"
  e.filter_count = 5
  e.stack_size_bonus = 0
  e.bulk = false
  e.allow_custom_vectors = false
  -- Rameno míří na vlastní políčko: engine nenajde zdroj ani cíl a inserter usne (ověřeno spikem).
  e.pickup_position = { 0, 0 }
  e.insert_position = { 0, 0 }
  e.energy_per_movement = "1J"
  e.energy_per_rotation = "1J"
  e.energy_source = {
    type = "electric",
    usage_priority = "secondary-input",
    drain = string.format("%.3fkW", info.drain_kw),
  }
  e.hand_base_picture = EMPTY
  e.hand_closed_picture = EMPTY
  e.hand_open_picture = EMPTY
  e.hand_base_shadow = EMPTY
  e.hand_closed_shadow = EMPTY
  e.hand_open_shadow = EMPTY
  if e.platform_picture and e.platform_picture.sheet then
    e.platform_picture.sheet.tint = M.tint(info.tier)
  end
  e.custom_tooltip_fields = {
    {
      name = { "storage-optimizer.interval" },
      value = { "storage-optimizer.seconds", string.format("%.2f", info.interval / 60) },
    },
  }
  data:extend({ e })
end

return M
```

`Storage_optimizer/prototypes/item.lua`:
```lua
--- Předmět tieru (staví entitu stejného jména).
local entity = require("prototypes.entity")

local M = {}

--- Vytvoří předmět tieru.
function M.create(info, icons)
  data:extend({
    {
      type = "item",
      name = info.name,
      icons = icons,
      localised_name = entity.localised_name(info.belt),
      localised_description = { "entity-description.storage-optimizer" },
      subgroup = "inserter",
      order = string.format("z[storage-optimizer]-%03d", info.tier),
      place_result = info.name,
      stack_size = 50,
    },
  })
end

return M
```

`Storage_optimizer/prototypes/recipe.lua`:
```lua
--- Recept tieru a jeho odemčení výzkumem. Suroviny jsou laditelné zde.
local tiers = require("prototypes.tiers")

local M = {}

--- Suroviny tieru: první tier z rychlých inserterů, další z předchozího tieru.
local function ingredients(info)
  local first
  if info.previous then
    first = { type = "item", name = info.previous, amount = 1 }
  else
    first = { type = "item", name = "fast-inserter", amount = 2 }
  end
  return {
    first,
    { type = "item", name = info.item, amount = 2 },
    { type = "item", name = "electronic-circuit", amount = 5 },
  }
end

--- Vytvoří recept a přidá ho do výzkumu pásu (u pásu dostupného od začátku do výzkumu rychlého inserteru).
function M.create(info)
  local tech = info.tech or tiers.find_unlocking_tech(data.raw, "fast-inserter")
  data:extend({
    {
      type = "recipe",
      name = info.name,
      enabled = tech == nil,
      energy_required = 1,
      ingredients = ingredients(info),
      results = { { type = "item", name = info.name, amount = 1 } },
    },
  })
  if tech then
    local technology = data.raw["technology"][tech]
    technology.effects = technology.effects or {}
    table.insert(technology.effects, { type = "unlock-recipe", recipe = info.name })
  end
end

return M
```

`Storage_optimizer/data-final-fixes.lua`:
```lua
-- Generování tierů až po načtení všech modů, aby se zahrnuly i pásy z jiných modů.
local tiers = require("prototypes.tiers")
local icons = require("prototypes.icons")
local entity = require("prototypes.entity")
local item = require("prototypes.item")
local recipe = require("prototypes.recipe")

local interval_multiplier = settings.startup["storage-optimizer-interval-multiplier"].value
local power_multiplier = settings.startup["storage-optimizer-power-multiplier"].value

local list = tiers.collect(data.raw)
local runtime = {}
local previous

for index, info in ipairs(list) do
  info.tier = index
  info.name = "storage-optimizer-" .. info.belt
  info.interval = tiers.interval_ticks(info.speed, interval_multiplier)
  info.drain_kw = tiers.drain_kw(info.speed, power_multiplier)
  info.previous = previous
  local layers = icons.tier_icons(info.item, entity.tint(index))
  entity.create(info, layers)
  item.create(info, layers)
  recipe.create(info)
  runtime[info.name] = { tier = index, interval = info.interval }
  previous = info.name
end

for index = 1, #list - 1 do
  data.raw["inserter"][list[index].name].next_upgrade = list[index + 1].name
end

data:extend({ { type = "mod-data", name = "storage-optimizer-tiers", data = runtime } })
```

Do obou `locale.cfg` přidat sekce. `locale/en/locale.cfg`:
```ini
[entity-name]
storage-optimizer=Storage optimizer (__1__)

[entity-description]
storage-optimizer=Moves one full batch (stack) from the chest behind it to the chest in front of it. Only whole batches, and only when the target has room for all of it.

[virtual-signal-name]
storage-optimizer-batch=Batch size

[storage-optimizer]
interval=Transfer interval
seconds=__1__ s
```
`locale/cs/locale.cfg`:
```ini
[entity-name]
storage-optimizer=Storage optimizer (__1__)

[entity-description]
storage-optimizer=Přesouvá jednu celou dávku (stack) z bedny za sebou do bedny před sebou. Jen celé dávky a jen pokud se celá vejde do cíle.

[virtual-signal-name]
storage-optimizer-batch=Velikost dávky

[storage-optimizer]
interval=Interval přesunu
seconds=__1__ s
```

- [ ] **Step 4: Ověřit, že testy prochází (vanilla i Space Age)**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST DONE pass=8 fail=0 skip=1` (turbo přeskočen), exit 0.

Run: `bash tools/run-tests.sh space-age`
Expected: `SO-TEST DONE pass=9 fail=0 skip=0`, exit 0.

Pokud data stage spadne na testovacím pásu (např. kontrola animace pásu u rychlosti 0.25), snížit rychlost `so-test-belt` na `0.1875` a očekávaný interval v testu na `20`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Generování tierů z pásů: entita, předmět, recept, výzkum, signál"
```

---

### Task 4: Filtry (čistá logika)

**Files:**
- Create: `Storage_optimizer/scripts/filters.lua`
- Test: `tests/unit/test_filters.lua`
- Modify: `tests/unit/run.lua`

**Interfaces:**
- Produces: `filters.passes(list, mode, name, quality, levels) → boolean`; `list` = pole ItemFilter `{ name, quality?, comparator? }` (bez nil), `mode` = `"whitelist"|"blacklist"`, `levels` = `{ [jméno kvality] = úroveň }`.

- [ ] **Step 1: Padající testy**

`tests/unit/test_filters.lua`:
```lua
--- Jednotkové testy logiky filtrů.
local A = require("assert")
local filters = require("scripts.filters")

local LEVELS = { normal = 0, uncommon = 1, rare = 2, epic = 3, legendary = 5 }

return {
  { "prázdný filtr pustí vše", function()
    A.eq(filters.passes({}, "whitelist", "iron-plate", "normal", LEVELS), true, "whitelist")
    A.eq(filters.passes({}, "blacklist", "iron-plate", "normal", LEVELS), true, "blacklist")
  end },
  { "whitelist", function()
    local list = { { name = "copper-plate" } }
    A.eq(filters.passes(list, "whitelist", "copper-plate", "normal", LEVELS), true, "měď")
    A.eq(filters.passes(list, "whitelist", "iron-plate", "normal", LEVELS), false, "železo")
  end },
  { "blacklist", function()
    local list = { { name = "iron-plate" } }
    A.eq(filters.passes(list, "blacklist", "iron-plate", "normal", LEVELS), false, "železo")
    A.eq(filters.passes(list, "blacklist", "copper-plate", "normal", LEVELS), true, "měď")
  end },
  { "filtr bez kvality pustí každou kvalitu", function()
    A.eq(filters.passes({ { name = "iron-plate" } }, "whitelist", "iron-plate", "rare", LEVELS), true, "rare")
  end },
  { "porovnání kvality", function()
    local eq = { { name = "iron-plate", quality = "uncommon", comparator = "=" } }
    A.eq(filters.passes(eq, "whitelist", "iron-plate", "uncommon", LEVELS), true, "= shoda")
    A.eq(filters.passes(eq, "whitelist", "iron-plate", "normal", LEVELS), false, "= neshoda")
    local ge = { { name = "iron-plate", quality = "rare", comparator = "≥" } }
    A.eq(filters.passes(ge, "whitelist", "iron-plate", "legendary", LEVELS), true, "≥ vyšší")
    A.eq(filters.passes(ge, "whitelist", "iron-plate", "uncommon", LEVELS), false, "≥ nižší")
    local ne = { { name = "iron-plate", quality = "normal", comparator = "!=" } }
    A.eq(filters.passes(ne, "whitelist", "iron-plate", "epic", LEVELS), true, "!=")
  end },
}
```

`tests/unit/run.lua`:
```lua
local SUITES = { "test_tiers", "test_filters" }
```

- [ ] **Step 2: Ověřit pád**

Run: `bash tools/run-unit.sh`
Expected: `module 'scripts.filters' not found`, exit ≠ 0.

- [ ] **Step 3: Implementace**

`Storage_optimizer/scripts/filters.lua`:
```lua
--- Čistá logika filtrů předmětů (bez API Factoria; úrovně kvality se předávají parametrem).
local M = {}

--- Porovnání úrovní kvality podle komparátoru filtru (Factorio připouští obě varianty zápisu).
local COMPARE = {
  ["="] = function(a, b) return a == b end,
  ["!="] = function(a, b) return a ~= b end,
  ["≠"] = function(a, b) return a ~= b end,
  [">"] = function(a, b) return a > b end,
  ["<"] = function(a, b) return a < b end,
  [">="] = function(a, b) return a >= b end,
  ["≥"] = function(a, b) return a >= b end,
  ["<="] = function(a, b) return a <= b end,
  ["≤"] = function(a, b) return a <= b end,
}

--- Odpovídá předmět jednomu filtru?
local function match(filter, name, quality, levels)
  if filter.name ~= name then return false end
  if not filter.quality then return true end
  return COMPARE[filter.comparator or "="](levels[quality], levels[filter.quality])
end

--- Rozhodne, zda předmět projde sadou filtrů. Prázdná sada pustí vše.
--- @param list table[] ItemFilter bez prázdných slotů
--- @param mode string "whitelist" | "blacklist"
--- @param name string jméno předmětu
--- @param quality string jméno kvality
--- @param levels table { [kvalita] = úroveň }
--- @return boolean
function M.passes(list, mode, name, quality, levels)
  if #list == 0 then return true end
  local hit = false
  for _, filter in ipairs(list) do
    if match(filter, name, quality, levels) then
      hit = true
      break
    end
  end
  if mode == "blacklist" then return not hit end
  return hit
end

return M
```

- [ ] **Step 4: Ověřit průchod**

Run: `bash tools/run-unit.sh`
Expected: `UNIT pass=11 fail=0`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add Storage_optimizer/scripts/filters.lua tests/unit
git commit -m "Logika filtrů s porovnáním kvality (jednotkové testy)"
```

---

### Task 5: Runtime jádro – registr, sousedé, plánovač, přesun, indikace, remote API

**Files:**
- Create: `Storage_optimizer/scripts/tiers.lua`, `registry.lua`, `neighbours.lua`, `scheduler.lua`, `transfer.lua`, `indicator.lua`, `remote.lua`
- Modify: `Storage_optimizer/control.lua`
- Test: `tests/storage-optimizer-tests/cases/transfer.lua`; Modify: `tests/storage-optimizer-tests/control.lua`

**Interfaces:**
- Consumes: mod-data `storage-optimizer-tiers` (Task 3).
- Produces:
  - `scripts.tiers`: `all() → { [jméno] = { tier, interval } }`, `is_mover(name) → boolean`, `interval(name) → integer`, `names() → string[]` (seřazené).
  - `scripts.registry`: `add(entity, batch|nil) → mover`, `get(unit_number) → mover|nil`, `remove(unit_number) → mover|nil`.
    Mover = `{ entity, unit_number, interval, batch, state, cursor, direction, source, target, scheduled_tick, light, arrow }`.
  - `scripts.neighbours`: `CONTAINER_TYPES`, `refresh(mover)`, `complete(mover) → boolean`.
  - `scripts.scheduler`: `schedule(mover, tick)`, `run(tick, handler)`, `clear()`.
  - `scripts.transfer`: `process(mover) → "working"|"waiting"|"no_power"` (Task 6 přidá `"disabled"`).
  - `scripts.indicator`: `create(mover)`, `set(mover, state)`, `update_arrow(mover)`, `destroy(mover)`, `orientation(direction) → number`.
  - Remote `storage-optimizer`: `get_batch(un)`, `set_batch(un, batch|nil)`, `get_state(un)`, `count()`.
  - Stavy: `working`, `waiting`, `no_power`, `disabled`, `no_chest`.

- [ ] **Step 1: Padající integrační testy**

`tests/storage-optimizer-tests/cases/transfer.lua`:
```lua
--- Integrační testy přesunu. Většina používá testovací pás (interval 15 t), aby byly rychlé.
--- Rozložení: zdroj (0,0) – optimizer (0,1) se směrem sever – cíl (0,2).
local H = require("helpers")

local BELT = "so-test-belt"

--- Stav entity přes remote rozhraní modu.
local function state(entity)
  return remote.call("storage-optimizer", "get_state", entity.unit_number)
end

--- Standardní rozložení s napájením; vrací (zdroj, optimizer, cíl).
local function layout(ctx, source_items, target_name)
  H.power(ctx)
  ctx.a = H.chest(ctx, "iron-chest", 0, 0, source_items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, target_name or "iron-chest", 0, 2)
end

return {
  {
    name = "přesun celých dávek",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 250 } }) end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 200, "cíl")
      H.eq(H.count(ctx.a, "iron-plate"), 50, "zbytek ve zdroji")
      H.eq(state(ctx.m), "waiting", "stav")
    end } },
  },
  {
    name = "všechno, nebo nic",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 300 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      -- Dřevěná bedna (16 slotů): 15 slotů kamene + 50 železa → místo jen pro 50 železa.
      ctx.b = H.chest(ctx, "wooden-chest", 0, 2, { { name = "stone", count = 750 }, { name = "iron-plate", count = 50 } })
    end,
    steps = {
      { ticks = 100, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 50, "cíl beze změny")
        H.eq(H.count(ctx.a, "iron-plate"), 300, "zdroj beze změny")
        ctx.b.get_inventory(defines.inventory.chest).remove({ name = "iron-plate", count = 50 })
      end },
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 100, "po uvolnění místa jedna dávka")
        H.eq(H.count(ctx.a, "iron-plate"), 200, "zdroj")
      end },
    },
  },
  {
    name = "bez proudu",
    setup = function(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "iron-chest", 0, 2)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl")
      H.eq(state(ctx.m), "no_power", "stav")
    end } },
  },
  {
    name = "probuzení po postavení cílové bedny",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
    end,
    steps = {
      { ticks = 30, run = function(ctx)
        H.eq(state(ctx.m), "no_chest", "stav bez cíle")
        ctx.b = H.chest(ctx, "iron-chest", 0, 2)
      end },
      { ticks = 40, run = function(ctx) H.eq(H.count(ctx.b, "iron-plate"), 100, "cíl po probuzení") end },
    },
  },
  {
    name = "zánik a obnova cílové bedny",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 1000 } }) end,
    steps = {
      { ticks = 40, run = function(ctx)
        H.truthy(H.count(ctx.b, "iron-plate") > 0, "něco přesunuto")
        ctx.b.destroy({ raise_destroy = true })
      end },
      { ticks = 40, run = function(ctx)
        H.eq(state(ctx.m), "no_chest", "stav po zániku")
        ctx.b = H.chest(ctx, "iron-chest", 0, 2)
      end },
      { ticks = 40, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "přesun po obnově") end },
    },
  },
  {
    name = "velký sklad 3×3 postavený později",
    setup = function(ctx)
      H.power(ctx)
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "iron-chest", 0, 2)
    end,
    steps = {
      { ticks = 20, run = function(ctx)
        -- Střed skladu na (0,-1) → pokrývá dlaždice x -1..1, y -2..0 včetně zdrojové (0,0).
        ctx.a = H.chest(ctx, "so-test-warehouse", 0, -1, { { name = "iron-plate", count = 500 } })
      end },
      { ticks = 40, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "přesun ze skladu") end },
    },
  },
  {
    name = "rotace prohodí zdroj a cíl",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 200 } }) end,
    steps = {
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 200, "tam")
        ctx.m.rotate()
        ctx.m.rotate()
      end },
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.a, "iron-plate"), 200, "zpět")
        H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl prázdný")
      end },
    },
  },
  {
    name = "zbourání optimizeru",
    setup = function(ctx) layout(ctx, {}) end,
    steps = {
      { ticks = 5, run = function(ctx)
        ctx.before = remote.call("storage-optimizer", "count")
        ctx.m.destroy({ raise_destroy = true })
      end },
      { ticks = 5, run = function(ctx)
        H.eq(remote.call("storage-optimizer", "count"), ctx.before - 1, "počet v registru")
      end },
    },
  },
  {
    name = "soused není bedna",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "iron-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      H.place(ctx, "transport-belt", 0, 2)
    end,
    steps = { { ticks = 30, run = function(ctx)
      H.eq(state(ctx.m), "no_chest", "stav")
      H.eq(H.count(ctx.a, "iron-plate"), 100, "zdroj beze změny")
    end } },
  },
  {
    name = "logistická bedna",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "passive-provider-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.m = H.mover(ctx, BELT, 0, 1)
      ctx.b = H.chest(ctx, "storage-chest", 0, 2)
    end,
    steps = { { ticks = 40, run = function(ctx) H.eq(H.count(ctx.b, "iron-plate"), 100, "cíl") end } },
  },
  {
    name = "předmět s daty (brnění s mřížkou)",
    setup = function(ctx)
      layout(ctx, {})
      local inv = ctx.a.get_inventory(defines.inventory.chest)
      inv.insert({ name = "modular-armor", count = 1 })
      inv[1].grid.put({ name = "solar-panel-equipment" })
    end,
    steps = { { ticks = 40, run = function(ctx)
      local stack = ctx.b.get_inventory(defines.inventory.chest).find_item_stack("modular-armor")
      H.truthy(stack, "brnění v cíli")
      H.eq(stack.grid and stack.grid.count("solar-panel-equipment"), 1, "vybavení zachováno")
    end } },
  },
  {
    name = "zachování kvality",
    requires = "quality",
    setup = function(ctx) layout(ctx, { { name = "iron-plate", count = 100, quality = "uncommon" } }) end,
    steps = { { ticks = 40, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate", "uncommon"), 100, "uncommon v cíli")
      H.eq(H.count(ctx.b, "iron-plate", "normal"), 0, "žádné normal")
    end } },
  },
  {
    name = "zachování čerstvosti",
    requires = "space-age",
    setup = function(ctx) layout(ctx, { { name = "yumako", count = 50, spoil_percent = 0.5 } }) end,
    steps = { { ticks = 40, run = function(ctx)
      local stack = ctx.b.get_inventory(defines.inventory.chest).find_item_stack("yumako")
      H.truthy(stack, "yumako v cíli")
      H.truthy(stack.spoil_percent > 0.45, "čerstvost zachována (" .. tostring(stack.spoil_percent) .. ")")
    end } },
  },
}
```

`tests/storage-optimizer-tests/control.lua` – přidat:
```lua
runner.register(require("cases.transfer"))
```

- [ ] **Step 2: Ověřit pád**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST FAIL přesun celých dávek …` (remote rozhraní neexistuje / nic se nepřesune), exit ≠ 0.

- [ ] **Step 3: Implementace modulů**

`Storage_optimizer/scripts/tiers.lua`:
```lua
--- Runtime přístup k parametrům tierů zapsaným v data stage do mod-data.
local M = {}

--- Kopie dat načtená jednou při načtení skriptu (stejná u všech hráčů → deterministická).
local DATA = prototypes.mod_data["storage-optimizer-tiers"].data

--- Vrátí tabulku { [jméno entity] = { tier, interval } }.
function M.all()
  return DATA
end

--- Je entita s tímto jménem Storage optimizer?
function M.is_mover(name)
  return DATA[name] ~= nil
end

--- Interval přesunu tieru v tickách.
function M.interval(name)
  return DATA[name].interval
end

--- Seřazená jména všech tierů (pro event filtry a GUI).
function M.names()
  local names = {}
  for name in pairs(DATA) do names[#names + 1] = name end
  table.sort(names)
  return names
end

return M
```

`Storage_optimizer/scripts/registry.lua`:
```lua
--- Evidence postavených Storage optimizerů ve storage.movers (klíč = unit_number).
local tiers = require("scripts.tiers")

local M = {}

--- Založí záznam pro novou entitu.
--- @param entity LuaEntity
--- @param batch integer|nil ručně nastavená velikost dávky (nil = Auto)
--- @return table mover
function M.add(entity, batch)
  local mover = {
    entity = entity,
    unit_number = entity.unit_number,
    interval = tiers.interval(entity.name),
    batch = batch,
    cursor = 1,
  }
  storage.movers[entity.unit_number] = mover
  return mover
end

--- Vrátí záznam podle unit_number.
function M.get(unit_number)
  return storage.movers[unit_number]
end

--- Odebere záznam a vrátí ho (nebo nil).
function M.remove(unit_number)
  local mover = storage.movers[unit_number]
  storage.movers[unit_number] = nil
  return mover
end

return M
```

`Storage_optimizer/scripts/neighbours.lua`:
```lua
--- Hledání zdrojové a cílové bedny kolem Storage optimizeru.
local M = {}

--- Typy entit, se kterými optimizer pracuje.
M.CONTAINER_TYPES = { "container", "logistic-container" }

--- Vektor ke zdroji pro 4 hlavní směry (2.0 má 16 směrů: sever 0, východ 4, jih 8, západ 12).
--- Odpovídá vanilla inserteru: při směru sever bere ze severu (ověřeno spikem).
local TO_SOURCE = {
  [0] = { 0, -1 },
  [4] = { 1, 0 },
  [8] = { 0, 1 },
  [12] = { -1, 0 },
}

--- Najde inventář bedny, jejíž hranice obsahuje daný bod (funguje i pro sklady N×N).
local function inventory_at(surface, position)
  local found = surface.find_entities_filtered({ position = position, type = M.CONTAINER_TYPES, limit = 1 })[1]
  return found and found.get_inventory(defines.inventory.chest) or nil
end

--- Přepočítá zdroj a cíl podle aktuální pozice a směru entity.
function M.refresh(mover)
  local entity = mover.entity
  local v = TO_SOURCE[entity.direction]
  local p = entity.position
  mover.direction = entity.direction
  mover.source = inventory_at(entity.surface, { p.x + v[1], p.y + v[2] })
  mover.target = inventory_at(entity.surface, { p.x - v[1], p.y - v[2] })
end

--- Má entita platný zdroj i cíl?
function M.complete(mover)
  return mover.source ~= nil and mover.source.valid and mover.target ~= nil and mover.target.valid
end

return M
```

`Storage_optimizer/scripts/scheduler.lua`:
```lua
--- Plánovač: každý optimizer se zpracuje jen v ticku, kdy je na řadě (jádro úspory UPS).
--- storage.schedule[tick] = { unit_number, … }; mover.scheduled_tick brání dvojímu naplánování.
local M = {}

--- Zařadí entitu ke zpracování v daném ticku (pokud už naplánovaná není).
function M.schedule(mover, tick)
  if mover.scheduled_tick then return end
  local bucket = storage.schedule[tick]
  if not bucket then
    bucket = {}
    storage.schedule[tick] = bucket
  end
  bucket[#bucket + 1] = mover.unit_number
  mover.scheduled_tick = tick
end

--- Vyjme seznam pro daný tick a pro každou stále evidovanou entitu zavolá handler.
--- @param tick integer
--- @param handler fun(mover: table)
function M.run(tick, handler)
  local bucket = storage.schedule[tick]
  if not bucket then return end
  storage.schedule[tick] = nil
  for _, unit_number in ipairs(bucket) do
    local mover = storage.movers[unit_number]
    if mover and mover.scheduled_tick == tick then
      mover.scheduled_tick = nil
      handler(mover)
    end
  end
end

--- Zahodí celý plán (po změně konfigurace se postaví znovu).
function M.clear()
  storage.schedule = {}
  for _, mover in pairs(storage.movers) do mover.scheduled_tick = nil end
end

return M
```

`Storage_optimizer/scripts/transfer.lua`:
```lua
--- Jeden cyklus přesunu: kontroly a přesun nejvýše jedné celé dávky.
local M = {}

--- Přesune přesně `count` kusů po slotech přes pomocný slot storage.buffer
--- (zachová kvalitu, čerstvost i data předmětů).
local function move(source, target, name, quality, count)
  local slot = storage.buffer[1]
  local id = { name = name, quality = quality }
  local remaining = count
  while remaining > 0 do
    local stack = source.find_item_stack(id)
    if not stack then return end
    local take = math.min(remaining, stack.count)
    slot.transfer_stack(stack, take)
    local inserted = target.insert(slot)
    if inserted < slot.count then
      -- Pojistka proti ztrátě předmětů: co se nevešlo, vrátit do zdroje.
      slot.count = slot.count - inserted
      source.insert(slot)
      slot.clear()
      return
    end
    slot.clear()
    remaining = remaining - take
  end
end

--- Provede jeden cyklus pro entitu se známým zdrojem a cílem.
--- @return string stav: "working" | "waiting" | "no_power"
function M.process(mover)
  local entity = mover.entity
  if entity.status == defines.entity_status.no_power then return "no_power" end
  local contents = mover.source.get_contents()
  local n = #contents
  for k = 0, n - 1 do
    -- Rotující ukazatel, aby jeden předmět nevyhladověl ostatní.
    local index = (mover.cursor + k - 1) % n + 1
    local entry = contents[index]
    local need = mover.batch or prototypes.item[entry.name].stack_size
    if entry.count >= need
      and mover.target.get_insertable_count({ name = entry.name, quality = entry.quality }) >= need then
      move(mover.source, mover.target, entry.name, entry.quality, need)
      mover.cursor = index % n + 1
      return "working"
    end
  end
  return "waiting"
end

return M
```

`Storage_optimizer/scripts/indicator.lua`:
```lua
--- Vizuální indikace: ikonka stavu (mění se jen při změně stavu) a šipka směru v alt režimu.
local M = {}

--- Sprite ikonky pro každý stav.
local SPRITES = {
  working = "utility/status_working",
  waiting = "utility/status_yellow",
  no_power = "utility/status_not_working",
  disabled = "utility/status_not_working",
  no_chest = "utility/status_not_working",
}

--- Orientace šipky (0–1) ze směru entity; šipka míří k cíli, tj. opačně než ke zdroji.
function M.orientation(direction)
  return (direction / 16 + 0.5) % 1
end

--- Vytvoří ikonku stavu a šipku pro novou entitu.
function M.create(mover)
  local entity = mover.entity
  mover.state = "no_chest"
  mover.light = rendering.draw_sprite({
    sprite = SPRITES.no_chest,
    target = { entity = entity, offset = { 0.25, -0.25 } },
    surface = entity.surface,
    x_scale = 0.35,
    y_scale = 0.35,
    render_layer = "entity-info-icon",
  })
  mover.arrow = rendering.draw_sprite({
    sprite = "utility/indication_arrow",
    target = entity,
    surface = entity.surface,
    orientation = M.orientation(entity.direction),
    only_in_alt_mode = true,
    render_layer = "entity-info-icon",
  })
end

--- Nastaví stav; vykreslení se mění jen při skutečné změně.
function M.set(mover, state)
  if mover.state == state then return end
  mover.state = state
  if mover.light and mover.light.valid then mover.light.sprite = SPRITES[state] end
end

--- Natočí šipku podle aktuálního směru entity.
function M.update_arrow(mover)
  if mover.arrow and mover.arrow.valid then mover.arrow.orientation = M.orientation(mover.entity.direction) end
end

--- Odstraní vykreslené objekty entity.
function M.destroy(mover)
  for _, key in ipairs({ "light", "arrow" }) do
    local object = mover[key]
    if object and object.valid then object.destroy() end
  end
end

return M
```

`Storage_optimizer/scripts/remote.lua`:
```lua
--- Veřejné rozhraní pro ostatní mody a testy: remote.call("storage-optimizer", <funkce>, …).
local registry = require("scripts.registry")

remote.add_interface("storage-optimizer", {
  --- Ručně nastavená velikost dávky (nil = Auto).
  get_batch = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and mover.batch
  end,
  --- Nastaví velikost dávky (nil nebo hodnota < 1 = Auto).
  set_batch = function(unit_number, batch)
    local mover = registry.get(unit_number)
    if mover then mover.batch = (batch and batch >= 1) and math.floor(batch) or nil end
  end,
  --- Aktuální stav: working | waiting | no_power | disabled | no_chest.
  get_state = function(unit_number)
    local mover = registry.get(unit_number)
    return mover and mover.state
  end,
  --- Počet evidovaných optimizerů.
  count = function()
    return table_size(storage.movers)
  end,
})
```

`Storage_optimizer/control.lua` (celý soubor):
```lua
-- Storage Optimizer – napojení událostí na moduly; logika je ve scripts/.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")
local neighbours = require("scripts.neighbours")
local scheduler = require("scripts.scheduler")
local transfer = require("scripts.transfer")
local indicator = require("scripts.indicator")
require("scripts.remote")

--- Založí chybějící tabulky ve storage (nová hra i starší uložená pozice).
local function init_storage()
  storage.movers = storage.movers or {}
  storage.schedule = storage.schedule or {}
  if not (storage.buffer and storage.buffer.valid) then storage.buffer = game.create_inventory(1) end
end

--- Přepočte sousedy a natočí šipku.
local function refresh(mover)
  neighbours.refresh(mover)
  indicator.update_arrow(mover)
end

--- Probudí entitu: přepočte sousedy a má-li zdroj i cíl, naplánuje ji na příští tick.
local function wake(mover)
  refresh(mover)
  if neighbours.complete(mover) then
    scheduler.schedule(mover, game.tick + 1)
  else
    indicator.set(mover, "no_chest")
  end
end

--- Zpracuje entitu v jejím ticku a naplánuje další cyklus; bez zdroje/cíle ji z plánu vyřadí.
local function run(mover)
  local entity = mover.entity
  if not entity.valid then
    indicator.destroy(mover)
    registry.remove(mover.unit_number)
    return
  end
  if entity.direction ~= mover.direction or not neighbours.complete(mover) then refresh(mover) end
  if not neighbours.complete(mover) then
    indicator.set(mover, "no_chest")
    return
  end
  indicator.set(mover, transfer.process(mover))
  scheduler.schedule(mover, game.tick + mover.interval)
end

--- Postavení entity (hráč, robot, platforma, skript): optimizer se zaeviduje, bedna probudí sousedy.
local function on_built(event)
  local entity = event.entity
  if tiers.is_mover(entity.name) then
    local mover = registry.add(entity, nil)
    indicator.create(mover)
    wake(mover)
    return
  end
  local box = entity.bounding_box
  local area = { { box.left_top.x - 1, box.left_top.y - 1 }, { box.right_bottom.x + 1, box.right_bottom.y + 1 } }
  for _, other in pairs(entity.surface.find_entities_filtered({ area = area, name = tiers.names() })) do
    local mover = registry.get(other.unit_number)
    if mover and not mover.scheduled_tick then wake(mover) end
  end
end

--- Odstranění optimizeru (vytěžení, zničení, skript).
local function on_removed(event)
  local mover = registry.remove(event.entity.unit_number)
  if mover then indicator.destroy(mover) end
end

--- Otočení nebo převrácení hráčem: naplánovaná entita změnu zjistí sama, nečinnou je třeba probudit.
local function on_rotated(event)
  local mover = registry.get(event.entity.unit_number)
  if not mover then return end
  indicator.update_arrow(mover)
  if not mover.scheduled_tick then wake(mover) end
end

--- Po změně modů/nastavení: přepočet intervalů, úklid neplatných záznamů a nový plán.
local function on_configuration_changed()
  init_storage()
  scheduler.clear()
  for unit_number, mover in pairs(storage.movers) do
    if mover.entity.valid then
      mover.interval = tiers.interval(mover.entity.name)
      if not (mover.light and mover.light.valid) then indicator.create(mover) end
      wake(mover)
    else
      indicator.destroy(mover)
      storage.movers[unit_number] = nil
    end
  end
end

local mover_filters = {}
for _, name in ipairs(tiers.names()) do mover_filters[#mover_filters + 1] = { filter = "name", name = name } end
local built_filters = { { filter = "type", type = "container" }, { filter = "type", type = "logistic-container" } }
for _, f in ipairs(mover_filters) do built_filters[#built_filters + 1] = f end

for _, id in ipairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}) do
  script.on_event(id, on_built, built_filters)
end

for _, id in ipairs({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_space_platform_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}) do
  script.on_event(id, on_removed, mover_filters)
end

script.on_event({ defines.events.on_player_rotated_entity, defines.events.on_player_flipped_entity }, on_rotated)
script.on_event(defines.events.on_tick, function(event) scheduler.run(event.tick, run) end)
script.on_init(init_storage)
script.on_configuration_changed(on_configuration_changed)
```

- [ ] **Step 4: Ověřit průchod (vanilla i Space Age)**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST DONE pass=19 fail=0 skip=3`, exit 0.

Run: `bash tools/run-tests.sh space-age`
Expected: `SO-TEST DONE pass=22 fail=0 skip=0`, exit 0.

Pokud test „rotace“ selže kvůli směru (`entity.rotate()` u 2.0 inserteru otáčí o 90°), ověřit `ctx.m.direction` po dvou rotacích logem a upravit počet volání tak, aby výsledný směr byl `defines.direction.south`.
Pokud test „předmět s daty“ selže na `grid.put` (vanilla nemá `solar-panel-equipment` v daném tvaru), použít `personal-roboport-equipment`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Runtime jádro: plánovač, přesun celých dávek, indikace stavu, remote API"
```

---

### Task 6: Filtry, velikost dávky a obvodová síť

**Files:**
- Modify: `Storage_optimizer/scripts/transfer.lua` (celý soubor níže), `Storage_optimizer/control.lua` (`on_built`)
- Test: `tests/storage-optimizer-tests/cases/settings.lua`; Modify: `tests/storage-optimizer-tests/control.lua`

**Interfaces:**
- Consumes: `scripts.filters.passes` (Task 4), remote `set_batch`/`get_state` (Task 5).
- Produces: `transfer.process` vrací navíc `"disabled"`; nový optimizer má výchozí signál dávky `{ type = "virtual", name = "storage-optimizer-batch" }`.

- [ ] **Step 1: Padající testy**

`tests/storage-optimizer-tests/cases/settings.lua`:
```lua
--- Integrační testy filtrů, velikosti dávky a obvodové sítě.
local H = require("helpers")

local BELT = "so-test-belt"

--- Rozložení zdroj (0,0) – optimizer (0,1) – cíl (0,2) s napájením.
local function layout(ctx, items, source_name)
  H.power(ctx)
  ctx.a = H.chest(ctx, source_name or "steel-chest", 0, 0, items)
  ctx.m = H.mover(ctx, BELT, 0, 1)
  ctx.b = H.chest(ctx, "steel-chest", 0, 2)
end

local MIXED = { { name = "iron-plate", count = 200 }, { name = "copper-plate", count = 200 } }

return {
  {
    name = "filtr povolit",
    setup = function(ctx)
      layout(ctx, MIXED)
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "copper-plate" })
      ctx.m.inserter_filter_mode = "whitelist"
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "filtr zakázat",
    setup = function(ctx)
      layout(ctx, MIXED)
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "iron-plate" })
      ctx.m.inserter_filter_mode = "blacklist"
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "ruční velikost dávky",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 700 } })
      remote.call("storage-optimizer", "set_batch", ctx.m.unit_number, 300)
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 600, "dvě dávky po 300")
      H.eq(H.count(ctx.a, "iron-plate"), 100, "zbytek")
    end } },
  },
  {
    name = "dávka větší než cíl",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 4800 } })
      remote.call("storage-optimizer", "set_batch", ctx.m.unit_number, 100000)
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 0, "cíl")
      H.eq(H.count(ctx.a, "iron-plate"), 4800, "zdroj")
      H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number), "waiting", "stav")
    end } },
  },
  {
    name = "velikost dávky ze signálu",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 100 } })
      local cc = H.combinator(ctx, 2, 1, { { type = "virtual", name = "storage-optimizer-batch", count = 30 } })
      H.wire(cc, ctx.m)
      ctx.m.get_control_behavior().circuit_set_stack_size = true
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate"), 90, "tři dávky po 30")
      H.eq(H.count(ctx.a, "iron-plate"), 10, "zbytek")
    end } },
  },
  {
    name = "zapnutí a vypnutí sítí",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 500 } })
      ctx.cc = H.combinator(ctx, 2, 1, { { name = "copper-plate", count = 1 } })
      H.wire(ctx.cc, ctx.m)
      local cb = ctx.m.get_control_behavior()
      cb.circuit_enable_disable = true
      cb.circuit_condition = { first_signal = { type = "item", name = "copper-plate" }, comparator = ">", constant = 5 }
    end,
    steps = {
      { ticks = 60, run = function(ctx)
        H.eq(H.count(ctx.b, "iron-plate"), 0, "vypnuto")
        H.eq(remote.call("storage-optimizer", "get_state", ctx.m.unit_number), "disabled", "stav")
        H.set_signal(ctx.cc, 1, { name = "copper-plate", count = 10 })
      end },
      { ticks = 60, run = function(ctx) H.truthy(H.count(ctx.b, "iron-plate") >= 100, "zapnuto") end },
    },
  },
  {
    name = "filtry ze signálů",
    setup = function(ctx)
      layout(ctx, MIXED)
      local cc = H.combinator(ctx, 2, 1, { { name = "copper-plate", count = 1 } })
      H.wire(cc, ctx.m)
      ctx.m.get_control_behavior().circuit_set_filters = true
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "copper-plate"), 200, "měď")
      H.eq(H.count(ctx.b, "iron-plate"), 0, "železo")
    end } },
  },
  {
    name = "filtr podle kvality",
    requires = "quality",
    setup = function(ctx)
      layout(ctx, { { name = "iron-plate", count = 200 }, { name = "iron-plate", count = 200, quality = "uncommon" } })
      ctx.m.use_filters = true
      ctx.m.set_filter(1, { name = "iron-plate", quality = "uncommon", comparator = "=" })
    end,
    steps = { { ticks = 60, run = function(ctx)
      H.eq(H.count(ctx.b, "iron-plate", "uncommon"), 200, "uncommon")
      H.eq(H.count(ctx.b, "iron-plate", "normal"), 0, "normal")
    end } },
  },
}
```

`tests/storage-optimizer-tests/control.lua` – přidat:
```lua
runner.register(require("cases.settings"))
```

- [ ] **Step 2: Ověřit pád**

Run: `bash tools/run-tests.sh vanilla`
Expected: FAIL u „filtr povolit“, „filtr zakázat“, „velikost dávky ze signálu“, „zapnutí a vypnutí sítí“, „filtry ze signálů“; exit ≠ 0.

- [ ] **Step 3: Implementace**

`Storage_optimizer/scripts/transfer.lua` (celý soubor):
```lua
--- Jeden cyklus přesunu: kontroly (proud, síť), výběr předmětu podle filtrů a přesun nejvýše jedné celé dávky.
local filters = require("scripts.filters")

local M = {}

local RED = defines.wire_connector_id.circuit_red
local GREEN = defines.wire_connector_id.circuit_green

--- Úrovně kvality { [jméno] = úroveň }, načtené líně při prvním použití.
local quality_levels

--- Vrátí úrovně kvality.
local function levels()
  if not quality_levels then
    quality_levels = {}
    for name, quality in pairs(prototypes.quality) do quality_levels[name] = quality.level end
  end
  return quality_levels
end

--- Načte aktivní filtry entity; filtry jsou aktivní při zapnutém use_filters nebo při filtrech ze sítě.
local function read_filters(entity, behavior)
  local list = {}
  if not (entity.use_filters or (behavior and behavior.circuit_set_filters)) then return list end
  for i = 1, entity.filter_slot_count do
    local filter = entity.get_filter(i)
    if filter then list[#list + 1] = filter end
  end
  return list
end

--- Velikost dávky: signál ze sítě (je-li zapnutý a > 0) → ruční nastavení → nil (Auto).
local function batch_size(mover, behavior)
  if behavior and behavior.circuit_set_stack_size and behavior.circuit_stack_control_signal then
    local value = mover.entity.get_signal(behavior.circuit_stack_control_signal, RED, GREEN)
    if value > 0 then return value end
  end
  return mover.batch
end

--- Přesune přesně `count` kusů po slotech přes pomocný slot storage.buffer
--- (zachová kvalitu, čerstvost i data předmětů).
local function move(source, target, name, quality, count)
  local slot = storage.buffer[1]
  local id = { name = name, quality = quality }
  local remaining = count
  while remaining > 0 do
    local stack = source.find_item_stack(id)
    if not stack then return end
    local take = math.min(remaining, stack.count)
    slot.transfer_stack(stack, take)
    local inserted = target.insert(slot)
    if inserted < slot.count then
      -- Pojistka proti ztrátě předmětů: co se nevešlo, vrátit do zdroje.
      slot.count = slot.count - inserted
      source.insert(slot)
      slot.clear()
      return
    end
    slot.clear()
    remaining = remaining - take
  end
end

--- Provede jeden cyklus pro entitu se známým zdrojem a cílem.
--- @return string stav: "working" | "waiting" | "no_power" | "disabled"
function M.process(mover)
  local entity = mover.entity
  if entity.status == defines.entity_status.no_power then return "no_power" end
  local behavior = entity.get_control_behavior()
  if behavior and behavior.disabled then return "disabled" end
  local batch = batch_size(mover, behavior)
  local active = read_filters(entity, behavior)
  local mode = entity.inserter_filter_mode
  local lv = levels()
  local contents = mover.source.get_contents()
  local n = #contents
  for k = 0, n - 1 do
    -- Rotující ukazatel, aby jeden předmět nevyhladověl ostatní.
    local index = (mover.cursor + k - 1) % n + 1
    local entry = contents[index]
    if filters.passes(active, mode, entry.name, entry.quality, lv) then
      local need = batch or prototypes.item[entry.name].stack_size
      if entry.count >= need
        and mover.target.get_insertable_count({ name = entry.name, quality = entry.quality }) >= need then
        move(mover.source, mover.target, entry.name, entry.quality, need)
        mover.cursor = index % n + 1
        return "working"
      end
    end
  end
  return "waiting"
end

return M
```

`Storage_optimizer/control.lua` – nad `local function init_storage` přidat konstantu a v `on_built` větev optimizeru nahradit:
```lua
--- Výchozí signál pro nastavení velikosti dávky ze sítě.
local BATCH_SIGNAL = { type = "virtual", name = "storage-optimizer-batch" }
```
```lua
  if tiers.is_mover(entity.name) then
    local mover = registry.add(entity, nil)
    local behavior = entity.get_or_create_control_behavior()
    if not behavior.circuit_stack_control_signal then behavior.circuit_stack_control_signal = BATCH_SIGNAL end
    indicator.create(mover)
    wake(mover)
    return
  end
```

- [ ] **Step 4: Ověřit průchod**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST DONE pass=26 fail=0 skip=4`, exit 0.

Run: `bash tools/run-tests.sh space-age`
Expected: `SO-TEST DONE pass=30 fail=0 skip=0`, exit 0.

Run: `bash tools/run-unit.sh`
Expected: `UNIT pass=11 fail=0`.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Filtry, velikost dávky a ovládání obvodovou sítí"
```

---

### Task 7: Přenos velikosti dávky (blueprinty, copy-paste, rychlá výměna tieru)

**Files:**
- Create: `Storage_optimizer/scripts/persistence.lua`
- Modify: `Storage_optimizer/control.lua`
- Test: `tests/storage-optimizer-tests/cases/persistence.lua`; Modify: `tests/storage-optimizer-tests/control.lua`

**Interfaces:**
- Consumes: `registry.get`, `tiers.is_mover`.
- Produces: `persistence.TAG = "so_batch"`, `batch_from_tags(tags) → integer|nil`, `on_setup_blueprint(event)`, `on_pasted(event)`, `remember_replaced(entity, batch)`, `take_replaced(entity) → integer|nil`.

- [ ] **Step 1: Padající test**

`tests/storage-optimizer-tests/cases/persistence.lua`:
```lua
--- Integrační test obnovy velikosti dávky z tagů (stavba z blueprintu = oživení ducha s tagy).
local H = require("helpers")

return {
  {
    name = "dávka z tagů blueprintu",
    setup = function(ctx)
      H.power(ctx)
      ctx.a = H.chest(ctx, "steel-chest", 0, 0, { { name = "iron-plate", count = 100 } })
      ctx.b = H.chest(ctx, "steel-chest", 0, 2)
      local ghost = ctx.surface.create_entity({
        name = "entity-ghost",
        inner_name = "storage-optimizer-so-test-belt",
        position = { ctx.origin.x + 0.5, ctx.origin.y + 1.5 },
        force = "player",
        tags = { so_batch = 40 },
      })
      local _, entity = ghost.revive({ raise_revive = true })
      ctx.m = entity
    end,
    steps = { { ticks = 100, run = function(ctx)
      H.eq(remote.call("storage-optimizer", "get_batch", ctx.m.unit_number), 40, "dávka z tagu")
      H.eq(H.count(ctx.b, "iron-plate"), 80, "dvě dávky po 40")
    end } },
  },
}
```

`tests/storage-optimizer-tests/control.lua` – přidat:
```lua
runner.register(require("cases.persistence"))
```

- [ ] **Step 2: Ověřit pád**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST FAIL dávka z tagů blueprintu: dávka z tagu: čekáno 40, dostáno nil`.

- [ ] **Step 3: Implementace**

`Storage_optimizer/scripts/persistence.lua`:
```lua
--- Přenos ručně nastavené velikosti dávky: blueprinty (tagy), kopírování nastavení, rychlá výměna tieru.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

--- Klíč tagu v blueprintu.
M.TAG = "so_batch"

--- Vrátí velikost dávky z tagů stavěné entity (nebo nil).
function M.batch_from_tags(tags)
  return tags and tags[M.TAG] or nil
end

--- Při vytvoření blueprintu zapíše dávku každého optimizeru do tagů.
function M.on_setup_blueprint(event)
  local blueprint = event.record or event.stack
  if not blueprint then return end
  if blueprint.object_name == "LuaItemStack" and not blueprint.valid_for_read then return end
  for index, entity in pairs(event.mapping.get()) do
    if entity.valid and tiers.is_mover(entity.name) then
      local mover = registry.get(entity.unit_number)
      if mover and mover.batch then blueprint.set_blueprint_entity_tag(index, M.TAG, mover.batch) end
    end
  end
end

--- Shift+pravý/levý klik: zkopíruje dávku mezi dvěma optimizery.
function M.on_pasted(event)
  local source, destination = event.source, event.destination
  if not (tiers.is_mover(source.name) and tiers.is_mover(destination.name)) then return end
  local from, to = registry.get(source.unit_number), registry.get(destination.unit_number)
  if from and to then to.batch = from.batch end
end

--- Klíč pozice pro spárování vytěžené a nově postavené entity.
local function key(entity)
  local p = entity.position
  return entity.surface.index .. ":" .. p.x .. ":" .. p.y
end

--- Zapamatuje si dávku vytěžené entity; platí jen do konce aktuálního ticku (rychlá výměna tieru).
function M.remember_replaced(entity, batch)
  if not batch then return end
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then
    cache = { tick = game.tick, entries = {} }
    storage.replaced = cache
  end
  cache.entries[key(entity)] = batch
end

--- Vyzvedne dávku entity vytěžené ve stejném ticku na stejné pozici (nebo nil).
function M.take_replaced(entity)
  local cache = storage.replaced
  if not cache or cache.tick ~= game.tick then return nil end
  local k = key(entity)
  local batch = cache.entries[k]
  cache.entries[k] = nil
  return batch
end

return M
```

`Storage_optimizer/control.lua` – úpravy:
1. K importům přidat `local persistence = require("scripts.persistence")`.
2. V `on_built` nahradit `local mover = registry.add(entity, nil)` za:
```lua
    local batch = persistence.batch_from_tags(event.tags) or persistence.take_replaced(entity)
    local mover = registry.add(entity, batch)
```
3. `on_removed` nahradit:
```lua
--- Odstranění optimizeru; při vytěžení si zapamatuje dávku pro rychlou výměnu tieru ve stejném ticku.
local function on_removed(event)
  local entity = event.entity
  local mover = registry.remove(entity.unit_number)
  if not mover then return end
  indicator.destroy(mover)
  if event.name ~= defines.events.on_entity_died and event.name ~= defines.events.script_raised_destroy then
    persistence.remember_replaced(entity, mover.batch)
  end
end
```
4. Na konec registrací událostí přidat:
```lua
script.on_event(defines.events.on_player_setup_blueprint, persistence.on_setup_blueprint)
script.on_event(defines.events.on_entity_settings_pasted, persistence.on_pasted)
```

- [ ] **Step 4: Ověřit průchod**

Run: `bash tools/run-tests.sh vanilla`
Expected: `SO-TEST DONE pass=27 fail=0 skip=4`, exit 0.

Run: `bash tools/run-tests.sh space-age`
Expected: `SO-TEST DONE pass=31 fail=0 skip=0`, exit 0.

- [ ] **Step 5: Ruční kontrola (Review Focus 5)** – provede uživatel po Task 8 (potřebuje GUI pro nastavení dávky); položky jsou v checklistu `docs/development.md` (Task 10): blueprint, Ctrl+C/Ctrl+V, Shift+klik kopírování, ruční přestavění tieru přes starší, upgrade planner s roboty.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Přenos velikosti dávky přes blueprinty, kopírování a výměnu tieru"
```

---

### Task 8: Boční GUI panel

**Files:**
- Create: `Storage_optimizer/scripts/gui.lua`
- Modify: `Storage_optimizer/control.lua`, `Storage_optimizer/scripts/persistence.lua` (`on_pasted` neměnit – panel se aktualizuje při otevření), oba `locale.cfg`

**Interfaces:**
- Consumes: `tiers.all`, `tiers.names`, `registry.get`.
- Produces: `gui.ensure(player)`, `gui.rebuild_all()`, `gui.on_opened(event)`, `gui.on_text_changed(event)`; `storage.gui_target[player_index] = unit_number`.

- [ ] **Step 1: Implementace panelu**

`Storage_optimizer/scripts/gui.lua`:
```lua
--- Boční panel u nativního okna inserteru: tier, trasa, stav a velikost dávky.
local tiers = require("scripts.tiers")
local registry = require("scripts.registry")

local M = {}

local FRAME = "storage_optimizer_panel"

--- Vytvoří (znovu) panel hráče ukotvený vpravo od okna inserteru, jen pro entity tohoto modu.
function M.ensure(player)
  local relative = player.gui.relative
  if relative[FRAME] then relative[FRAME].destroy() end
  local frame = relative.add({
    type = "frame",
    name = FRAME,
    direction = "vertical",
    caption = { "storage-optimizer-gui.title" },
    anchor = {
      gui = defines.relative_gui_type.inserter_gui,
      position = defines.relative_gui_position.right,
      names = tiers.names(),
    },
  })
  local inner = frame.add({ type = "frame", name = "inner", direction = "vertical", style = "inside_shallow_frame_with_padding" })
  inner.add({ type = "label", name = "tier" })
  inner.add({ type = "label", name = "route" })
  inner.add({ type = "label", name = "state" })
  inner.add({ type = "line" })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.batch" }, style = "caption_label" })
  inner.add({ type = "textfield", name = "so_batch", numeric = true, allow_decimal = false, allow_negative = false })
  inner.add({ type = "label", caption = { "storage-optimizer-gui.batch-hint" } })
end

--- Znovu vytvoří panely všech hráčů (po změně konfigurace se mohou změnit jména tierů).
function M.rebuild_all()
  for _, player in pairs(game.players) do M.ensure(player) end
end

--- Lokalizovaný název bedny, které patří inventář (nebo „nic“).
local function owner_name(inventory)
  if inventory and inventory.valid then return inventory.entity_owner.localised_name end
  return { "storage-optimizer-gui.none" }
end

--- Naplní panel údaji o otevřené entitě a zapamatuje si, kterou entitu hráč upravuje.
function M.update(player, mover)
  local frame = player.gui.relative[FRAME]
  if not frame then return end
  local inner = frame.inner
  local info = tiers.all()[mover.entity.name]
  inner.tier.caption = { "storage-optimizer-gui.tier", info.tier, string.format("%.2f", info.interval / 60) }
  inner.route.caption = { "storage-optimizer-gui.route", owner_name(mover.source), owner_name(mover.target) }
  inner.state.caption = { "storage-optimizer-gui.state", { "storage-optimizer-state." .. (mover.state or "no_chest") } }
  inner.so_batch.text = mover.batch and tostring(mover.batch) or ""
  storage.gui_target = storage.gui_target or {}
  storage.gui_target[player.index] = mover.unit_number
end

--- Otevření okna entity: pokud jde o optimizer, naplní panel.
function M.on_opened(event)
  local entity = event.entity
  if not (entity and entity.valid and tiers.is_mover(entity.name)) then return end
  local mover = registry.get(entity.unit_number)
  if mover then M.update(game.get_player(event.player_index), mover) end
end

--- Změna textu velikosti dávky: prázdné, 0 nebo nečíslo = Auto.
function M.on_text_changed(event)
  local element = event.element
  if element.name ~= "so_batch" or element.get_mod() ~= script.mod_name then return end
  local unit_number = storage.gui_target and storage.gui_target[event.player_index]
  local mover = unit_number and registry.get(unit_number)
  if not mover then return end
  local value = tonumber(element.text)
  mover.batch = (value and value >= 1) and math.floor(value) or nil
end

return M
```

`Storage_optimizer/control.lua` – úpravy:
1. Import `local gui = require("scripts.gui")`.
2. `script.on_init(init_storage)` nahradit:
```lua
script.on_init(function()
  init_storage()
  gui.rebuild_all()
end)
```
3. Na konec `on_configuration_changed` přidat `gui.rebuild_all()`.
4. Registrace:
```lua
script.on_event(defines.events.on_player_created, function(event) gui.ensure(game.get_player(event.player_index)) end)
script.on_event(defines.events.on_gui_opened, gui.on_opened)
script.on_event(defines.events.on_gui_text_changed, gui.on_text_changed)
```

Lokalizace – `locale/en/locale.cfg` přidat:
```ini
[storage-optimizer-gui]
title=Storage optimizer
tier=Tier __1__, one batch every __2__ s
route=__1__ → __2__
none=nothing
state=Status: __1__
batch=Batch size
batch-hint=Empty = Auto (one stack of the item)

[storage-optimizer-state]
working=Working
waiting=Waiting – source lacks a full batch or target has no room
no_power=No power
disabled=Disabled by circuit network
no_chest=Missing source or target chest
```
`locale/cs/locale.cfg` přidat:
```ini
[storage-optimizer-gui]
title=Storage optimizer
tier=Tier __1__, jedna dávka každých __2__ s
route=__1__ → __2__
none=nic
state=Stav: __1__
batch=Velikost dávky
batch-hint=Prázdné = Auto (jeden stack předmětu)

[storage-optimizer-state]
working=Pracuje
waiting=Čeká – zdroj nemá celou dávku nebo cíl nemá místo
no_power=Bez proudu
disabled=Vypnuto obvodovou sítí
no_chest=Chybí zdrojová nebo cílová bedna
```

- [ ] **Step 2: Regrese testů**

Run: `bash tools/run-tests.sh vanilla && bash tools/run-tests.sh space-age && bash tools/run-unit.sh`
Expected: `fail=0` ve všech třech, exit 0.

- [ ] **Step 3: Ruční ověření ve hře (uživatel)**

Run: `bash tools/link-mod.sh` (jednorázově), pak ve hře povolit mod a založit hru v editoru (`/editor`).
Zkontrolovat a výsledek zapsat do odpovědi:
- Otevření optimizeru ukáže vpravo panel s tierem, trasou „Iron chest → Iron chest“ a stavem.
- Zadání `300` → přesouvá po 300; smazání pole → Auto.
- Panel se **neukáže** u obyčejného inserteru.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Boční GUI panel s tierem, stavem a velikostí dávky"
```

---

### Task 9: Výkonový test (UPS)

**Files:**
- Create: `tests/perf/so-perf/info.json`, `tests/perf/so-perf/control.lua`, `tools/run-perf.sh`
- Modify: `.vscode/tasks.json`

**Interfaces:**
- Produces: `tools/run-perf.sh` vypíše tabulku `režim | ms/tick | přesunuto kusů` pro režimy `idle`, `mover`, `loader` (proměnná `PERF_N`, výchozí 1000).

- [ ] **Step 1: Scénář**

`tests/perf/so-perf/info.json`:
```json
{
  "name": "so-perf",
  "version": "0.1.0",
  "title": "Storage Optimizer – perf",
  "author": "Ypsilonx",
  "factorio_version": "2.0",
  "dependencies": ["Storage_optimizer"]
}
```

`tests/perf/so-perf/control.lua`:
```lua
-- Výkonový scénář: N dvojic beden propojených Storage optimizerem, dvojicí loaderů, nebo nijak (základ).
-- Soubory mode.lua a count.lua generuje tools/run-perf.sh.
local MODE = require("mode")
local N = require("count")

--- Postaví entitu na povrchu testu.
local function place(surface, spec)
  spec.force = "player"
  spec.raise_built = true
  local entity = surface.create_entity(spec)
  assert(entity, "nelze postavit " .. spec.name)
  return entity
end

script.on_init(function()
  local surface = game.create_surface("so-perf")
  surface.generate_with_lab_tiles = true
  surface.request_to_generate_chunks({ 0, 0 }, 8)
  surface.force_generate_chunk_requests()
  storage.targets = {}
  for i = 0, N - 1 do
    -- Sloupce po 3 dlaždicích (mezera pro rozvodny), řady po 6 dlaždicích.
    local column, row = i % 50, math.floor(i / 50)
    local x, y = column * 3 - 75, row * 6 - 60
    local source = place(surface, { name = "steel-chest", position = { x + 0.5, y + 0.5 } })
    source.insert({ name = "iron-plate", count = 4800 })
    local target_y = y + 2.5
    if MODE == "mover" then
      place(surface, { name = "storage-optimizer-transport-belt", position = { x + 0.5, y + 1.5 }, direction = defines.direction.north })
    elseif MODE == "loader" then
      place(surface, { name = "loader-1x1", position = { x + 0.5, y + 1.5 }, direction = defines.direction.south, type = "output" })
      place(surface, { name = "loader-1x1", position = { x + 0.5, y + 2.5 }, direction = defines.direction.south, type = "input" })
      target_y = y + 3.5
    end
    storage.targets[#storage.targets + 1] = place(surface, { name = "steel-chest", position = { x + 0.5, target_y } })
    if column % 6 == 0 and row % 3 == 0 then
      place(surface, { name = "substation", position = { x + 2, y + 5 } })
    end
    if column == 1 and row == 0 then
      local power = place(surface, { name = "electric-energy-interface", position = { x + 2, y + 5 } })
      power.power_production = 1e9
      power.electric_buffer_size = 1e10
    end
  end
end)

script.on_nth_tick(3600, function()
  local total = 0
  for _, target in pairs(storage.targets) do total = total + target.get_item_count("iron-plate") end
  log("SO-PERF moved=" .. total)
end)
```

`tools/run-perf.sh`:
```bash
#!/usr/bin/env bash
# Výkonové srovnání: N dvojic beden bez spojení (idle), se Storage optimizerem (mover)
# a s dvojicí vanilla loaderů (loader). Vypíše průměrný čas ticku a počet přesunutých kusů.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FACTORIO="${FACTORIO_EXE:-C:/STEAM/steamapps/common/Factorio/bin/x64/factorio.exe}"
N="${PERF_N:-1000}"
TICKS=3600

printf "%-8s | %10s | %s\n" "režim" "ms/tick" "přesunuto kusů"
for MODE in idle mover loader; do
  RUN="$ROOT/.test-run/perf-$MODE"
  RUN_W="$(cygpath -m "$RUN")"
  rm -rf "$RUN"
  mkdir -p "$RUN/mods" "$RUN/write-data"
  cp -r "$ROOT/Storage_optimizer" "$RUN/mods/Storage_optimizer"
  cp -r "$ROOT/tests/perf/so-perf" "$RUN/mods/so-perf"
  echo "return \"$MODE\"" > "$RUN/mods/so-perf/mode.lua"
  echo "return $N" > "$RUN/mods/so-perf/count.lua"
  cat > "$RUN/mods/mod-list.json" <<EOF
{"mods":[{"name":"base","enabled":true},{"name":"elevated-rails","enabled":false},{"name":"quality","enabled":false},{"name":"space-age","enabled":false},{"name":"Storage_optimizer","enabled":true},{"name":"so-perf","enabled":true}]}
EOF
  cat > "$RUN/config.ini" <<EOF
[path]
read-data=__PATH__executable__/../../data
write-data=$RUN_W/write-data
EOF
  ARGS=(--config "$RUN_W/config.ini" --mod-directory "$RUN_W/mods")
  "$FACTORIO" "${ARGS[@]}" --create "$RUN_W/perf.zip" > "$RUN/create.log" 2>&1 || true
  [ -f "$RUN/perf.zip" ] || { echo "Vytvoření mapy ($MODE) selhalo"; grep -A12 Error "$RUN/create.log"; exit 1; }
  "$FACTORIO" "${ARGS[@]}" --benchmark "$RUN_W/perf.zip" --benchmark-ticks $TICKS --disable-audio > "$RUN/bench.log" 2>&1 || true
  MS=$(grep -oE "Performed [0-9]+ updates in [0-9.]+ ms" "$RUN/bench.log" | grep -oE "[0-9.]+ ms" | grep -oE "[0-9.]+")
  MOVED=$(grep -oE "SO-PERF moved=[0-9]+" "$RUN/bench.log" | tail -1 | grep -oE "[0-9]+$" || echo "?")
  printf "%-8s | %10.4f | %s\n" "$MODE" "$(echo "$MS / $TICKS" | bc -l)" "$MOVED"
done
```

`.vscode/tasks.json` – do pole `tasks` přidat:
```json
{ "label": "Výkonový test", "type": "shell", "command": "tools/run-perf.sh", "group": "test", "problemMatcher": [] }
```

- [ ] **Step 2: Spustit a ověřit smysluplnost**

Run: `bash tools/run-perf.sh`
Expected: tři řádky. `mover` má `přesunuto kusů` > 0 (≈ 1000 × 30 dávek × 100 = 3 000 000 po 60 s, pokud mají bedny místo), `loader` > 0, `idle` = 0.
- Pokud `bc` chybí, nahradit výpočet `awk "BEGIN { printf \"%.4f\", $MS / $TICKS }"`.
- Pokud `loader` přesune 0 kusů, prohodit `type = "output"`/`"input"` (nebo směr na `north`) a spustit znovu – cílem je funkční srovnání, ne konkrétní orientace.
- Výsledky (tabulku) zapsat do `docs/development.md` v Task 10.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "Výkonový test: srovnání s vanilla loadery"
```

---

### Task 10: Dokumentace, kontrola lokalizace a balíček pro publikaci

**Files:**
- Create: `README.md`, `docs/user-guide.md`, `docs/mod-portal.md`, `docs/development.md`, `tools/package.sh`, `tests/unit/test_locale.lua`
- Modify: `tests/unit/run.lua`, `Storage_optimizer/changelog.txt`, `.vscode/tasks.json`

**Interfaces:**
- Consumes: vše předchozí.
- Produces: `tools/package.sh` → `dist/Storage_optimizer_<verze>.zip` (kořenová složka `Storage_optimizer_<verze>/`), ověřený načtením v headless Factoriu.

- [ ] **Step 1: Test shodnosti lokalizací (padající, dokud by chyběl klíč)**

`tests/unit/test_locale.lua`:
```lua
--- Kontrola, že angličtina a čeština mají přesně stejnou sadu klíčů.
local A = require("assert")

--- Načte locale.cfg a vrátí množinu klíčů „sekce.klíč“.
local function keys(path)
  local set, section = {}, ""
  for line in io.lines(path) do
    local header = line:match("^%[(.+)%]$")
    if header then
      section = header
    else
      local key = line:match("^([^#;=][^=]*)=")
      if key then set[section .. "." .. key] = true end
    end
  end
  return set
end

return {
  { "en a cs mají stejné klíče", function()
    local en = keys("Storage_optimizer/locale/en/locale.cfg")
    local cs = keys("Storage_optimizer/locale/cs/locale.cfg")
    for key in pairs(en) do A.truthy(cs[key], "chybí v cs: " .. key) end
    for key in pairs(cs) do A.truthy(en[key], "chybí v en: " .. key) end
  end },
}
```

`tests/unit/run.lua`:
```lua
local SUITES = { "test_tiers", "test_filters", "test_locale" }
```

Run: `bash tools/run-unit.sh`
Expected: `UNIT pass=12 fail=0` (pokud selže, doplnit chybějící klíč do příslušného `locale.cfg`).

- [ ] **Step 2: Uživatelská dokumentace** – `docs/user-guide.md` (česky), obsah v tomto pořadí:
  1. Co mod dělá (1 odstavec) a srovnání „loader + pás + unloader → 1 budova“.
  2. Postavení: zdroj = bedna za šipkou, cíl = bedna před šipkou; šipka viditelná v alt režimu (Alt); R otočí směr.
  3. Pravidla přesunu: jen celé dávky, jen pokud se celá vejde, max 1 dávka za interval; pouze bedny/sklady (`container`, `logistic-container`).
  4. Tiery: tabulka vanilla (žlutý 2 s / 50 kW, červený 1 s / 100 kW, modrý 0,67 s / 150 kW, turbo 0,5 s / 200 kW) + věta, že mody s pásy přidají tiery automaticky.
  5. Nastavení: velikost dávky v bočním panelu (prázdné = Auto); filtry 5 slotů + povolit/zakázat v nativním okně; obvodová síť – zapnout/vypnout podmínkou, „Nastavit velikost stacku“ = velikost dávky (výchozí signál „Velikost dávky“, hodnota není omezena na 255), „Nastavit filtry“.
  6. Upozornění: posuvník „Override stack size“ a stav v nativním okně inserteru se ignorují – platí panel vpravo.
  7. Indikátor stavu: zelená = pracuje, žlutá = čeká, červená = bez proudu / vypnuto / chybí bedna.
  8. Startup nastavení (násobič intervalu, násobič spotřeby) a kde je najít (Nastavení → Mody → Startup).

- [ ] **Step 3: Popis pro mod portál** – `docs/mod-portal.md` (anglicky, markdown portálu): krátké shrnutí, sekce *Features* (odrážky: whole-stack transfers, no belts, tiers from any belt mod, filters + circuit control, custom batch size above 255, blueprint support, quality & spoilage preserved, UPS-friendly scheduler + výsledek perf testu z Task 9), *How to use*, *Compatibility* (Factorio 2.0, with/without Space Age, any belt mod), *Known limitations* (only chests/warehouses in 0.1, native inserter GUI shows its own status and stack-size slider – ignored), *License* MIT.

- [ ] **Step 4: Vývojářská dokumentace** – `docs/development.md` (česky):
  1. Prostředí: VSCode + `sumneko.lua` + FMTK (`Factorio: Select Version`), nechtěná rozšíření a proč.
  2. Struktura repozitáře (mapa souborů z tohoto plánu).
  3. Kde ladit hodnoty: `Storage_optimizer/prototypes/tiers.lua` (`BASE_INTERVAL`, `BASE_DRAIN_KW`), `prototypes/recipe.lua` (`ingredients`), `prototypes/entity.lua` (`TINTS`), cesta k Factoriu `FACTORIO_EXE` v `tools/run-tests.sh` a `tools/run-perf.sh`, Git Bash v `.vscode/tasks.json`.
  4. Testy: `tools/run-unit.sh`, `tools/run-tests.sh vanilla|space-age`, `tools/run-perf.sh` + tabulka výsledků perf testu z Task 9.
  5. Ruční hraní a ladění: `tools/link-mod.sh`, FMTK debugger (Run and Debug → Factorio Mod Debug).
  6. **Checklist ruční kontroly před vydáním:** panel u optimizeru (ne u inserteru); velikost dávky 300 / prázdné = Auto; blueprint s dávkou → postavení zachová dávku; Ctrl+C/Ctrl+V; Shift+pravý/levý klik kopírování; přestavění tieru přes starší tier zachová dávku; upgrade planner s roboty zachová dávku; šipka v alt režimu míří k cíli ve všech 4 směrech; barvy indikátoru (zelená/žlutá/červená); ruční R a převrácení (F/G).
  7. Publikace: `tools/package.sh`, nahrání zipu na mods.factorio.com, popis z `docs/mod-portal.md`, licence MIT, thumbnail z navazujícího grafického plánu.
  8. Formát `changelog.txt` (99 pomlček, `Version:`, `Date:`, kategorie 2 mezery, položky 4 mezery + `- `).

- [ ] **Step 5: README** – `README.md` (česky, krátce): co to je, odkazy na `docs/user-guide.md`, `docs/development.md`, `docs/mod-portal.md`; rychlý start vývoje (3 příkazy: link, unit testy, integrační testy); licence MIT © 2026 Ypsilonx.

- [ ] **Step 6: Changelog verze 0.1.0** – nahradit sekci verze (první řádek s 99 pomlčkami ponechat):
```
Version: 0.1.0
Date: 2026-10-01
  Features:
    - One building that moves whole stacks between chests and warehouses without belts.
    - Tiers are generated automatically from every belt in the game (vanilla, Space Age and belt mods).
    - Batch size: Auto (one stack of the item) or any custom amount, also from the circuit network.
    - 5 item filters with whitelist/blacklist and quality comparison, filters from the circuit network.
    - Enable/disable by circuit condition.
    - Batch size is kept in blueprints, copy-paste and when replacing a tier.
    - Quality, spoilage and item data are preserved.
  Optimizations:
    - Each building is processed only once per transfer interval; idle buildings cost nothing.
```

- [ ] **Step 7: Balicí skript**

`tools/package.sh`:
```bash
#!/usr/bin/env bash
# Sestaví zip modu pro mod portál: dist/Storage_optimizer_<verze>.zip s kořenovou složkou Storage_optimizer_<verze>/.
# Používá PowerShell 7 (Compress-Archive v pwsh zapisuje cesty s lomítky, jak Factorio vyžaduje).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(grep -oE '"version"[^"]*"[^"]+"' "$ROOT/Storage_optimizer/info.json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
NAME="Storage_optimizer_$VERSION"
STAGE="$ROOT/dist/stage"
rm -rf "$STAGE" "$ROOT/dist/$NAME.zip"
mkdir -p "$STAGE"
cp -r "$ROOT/Storage_optimizer" "$STAGE/$NAME"
pwsh -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$STAGE/$NAME")' -DestinationPath '$(cygpath -w "$ROOT/dist/$NAME.zip")'"
rm -rf "$STAGE"
echo "$ROOT/dist/$NAME.zip"
```

- [ ] **Step 8: Ověřit balíček načtením ve hře**

Run:
```bash
bash tools/package.sh
unzip -l dist/Storage_optimizer_0.1.0.zip | head -8
```
Expected: cesty začínají `Storage_optimizer_0.1.0/` a používají `/`.

Ověřit, že Factorio zip načte – dočasně v `tools/run-tests.sh` nahradit `cp -r "$ROOT/Storage_optimizer" …` za `cp "$ROOT/dist/Storage_optimizer_0.1.0.zip" "$RUN/mods/"`, spustit `bash tools/run-tests.sh vanilla` (Expected: `fail=0`) a změnu vrátit (`git checkout tools/run-tests.sh`).

- [ ] **Step 9: Finální regrese**

Run: `bash tools/run-unit.sh && bash tools/run-tests.sh vanilla && bash tools/run-tests.sh space-age`
Expected: vše `fail=0`, exit 0.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "Dokumentace, kontrola lokalizace a balíček pro publikaci"
```

---

## Navazující plán (mimo tento dokument)

**Grafika z Blenderu a vydání:** 3D model 1×1, render 4 směrů (Sprite4Way) + stín + světlo stavu, ikony tierů, `thumbnail.png` 144×144, náhrada dočasné grafiky v `prototypes/entity.lua` a `prototypes/icons.lua`, ruční checklist, nahrání na mod portál.
