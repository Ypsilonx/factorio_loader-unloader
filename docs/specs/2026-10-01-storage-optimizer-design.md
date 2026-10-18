# Storage Optimizer – návrh

Aktuální stav návrhu (verze 0.4.0). Popisuje, **proč** je mod postavený tak, jak je; dřívější podoby návrhu
jsou v historii gitu. Při změně klíčového rozhodnutí tento soubor přepiš (ne dodatek na konec).

## Cíl

Jedna budova 1×1, která **bez pásů** přesouvá celé stacky mezi bednami, vagóny, montážními stroji a pecemi.
Nahrazuje sestavu unloader → pás → loader. Hlavní priorita je **UPS** ve velkých továrnách.

**Co hráč dostane:** zdroj za budovou, cíl před ní (R/F/G prohodí směr); přesun = velikost stacku × počet
stacků (1–20, limit nastavitelný); pravidlo „všechno, nebo nic“ s volitelným přesunem zbytků; 5 filtrů
s kvalitou; ovládání obvodovou i logistickou sítí; tier pro každý pás ve hře včetně modů; nastavení se přenáší
blueprinty, kopírováním i výměnou tieru.

**Mimo rozsah:** čtení přesunů do obvodové sítě, plnění paliva pecí, jedoucí vagóny.

## Klíčová rozhodnutí

| Rozhodnutí | Volba | Důvod |
|---|---|---|
| Přesun | skript nad `LuaInventory` po slotech přes pomocný inventář | ruka inserteru má strop ~256 ks (`stack_size_bonus` je `uint8`); po slotech se zachová kvalita, čerstvost i data předmětu |
| Typ prototypu | `inserter`, za běhu `disabled_by_script = true` | zdarma rotace, dráty, 5 filtrů, podmínka sítě, blueprinty, copy-paste, upgrade planner; engine entitu nepočítá (měřeno: 0,107 ms/tick na 1000 kusů ušetřeno), ale dál vyhodnocuje podmínku sítě a filtry ze signálů |
| Plánování | `storage.schedule[tick]`, každá entita jednou za interval tieru; bez zdroje/cíle mimo plán | žádná práce v každém ticku; nečinnou entitu probudí stavba souseda nebo rotace |
| Zdroje a cíle | bedny (i logistické, nekonečné), vagóny ve stanici, `assembling-machine`/`furnace` (vstup/výstup, ne palivo) | typy podle role v `scripts/neighbours.lua` (`INVENTORIES`), event filtry odvozené odtud |
| Pravidlo přesunu | všechno, nebo nic; volba „Přesouvat i zbytky“ (výchozí vypnuto) | předvídatelné chování; zbytky umožní bednu nebo vagón úplně vyprázdnit |
| Tiery | v `data-final-fixes` ze všech pásů ve hře (skryté a nedostupné vynechá), hlavní tiery tvoří strom: tier se vyrábí z nejrychlejšího pomalejšího tieru, jehož pás je surovinou receptu nového pásu nebo jehož výzkum je v uzávěru prerekvizit; `next_upgrade` vede do potomka dostupného nejdřív; ze stejně rychlých pásů je hlavní ten dostupný nejdřív, ostatní jsou varianty bokem | kompatibilita s libovolným modem bez údržby; řazení jen podle rychlosti zamykalo pásy z jiné větve výzkumu (UBSA za turbem/Vulcanem, za hyper pásem Planetaris) a kosmetické varianty (Tenebris Prime) za pozdní výzkum; surovina receptu pokryje Pyanodon, který prerekvizity doplní až po nás |
| Interval | žlutý pás 60 ticků (`BASE_INTERVAL`), ostatní úměrně rychlosti pásu × startup násobič | rychlejší pás = rychlejší tier |
| Energie | 50 kJ za přesun + 5 kJ za každý další stack, ze zásobníku entity (`buffer_capacity` = 2× nejdražší přesun, dobíjení = nejdražší přesun za interval) | vypnutá entita neodebírá `drain`; velké přesuny jsou na kus levnější; omezené dobíjení nesrazí síť při hromadné stavbě |
| Recept a výzkum | vlastní výzkum každého tieru; suroviny podle rychlosti pásu s náhradami (`prototypes/research.lua`), prerekvizity = výzkum pásu + výzkumy surovin | overhaul mody (Pyanodon, Bob's) přeskládají strom – natvrdo připojený recept by se odemkl dřív, než jdou suroviny vyrobit |
| Parametry pro runtime | `mod-data` `storage-optimizer-tiers` | runtime nepočítá z pásů znovu (determinismus, jedno místo pravdy) |
| Nastavení | filtry a podmínky v nativních polích entity; velikost stacku, počet stacků, signál počtu a zbytky v `storage.movers` + tagy `so_*` | engine omezuje `inserter_stack_size_override` na 0–255 |
| Signály | velikost stacku `signal-S`, počet stacků `signal-N` (volitelně, s vlastním výběrem) | vlastní virtuální signály byly zbytečné; hráč kolizi v síti řeší výběrem jiného signálu |
| GUI | **vlastní okno místo nativního okna inserteru**, rozložením podobné nativnímu, s bočními panely Připojení obvodu a Logistická síť | nativní okno ukazovalo volby, které mod ignoruje (čtení ruky, override stack size, priorita zkázy), a vlastní volby by stejně musely do bočního panelu |
| Indikace | ikonka stavu přes `rendering` a `custom_status`, mění se jen při změně stavu | žádné překreslování každý tick |
| Testy | unit testy čisté logiky (Lua 5.3) + vlastní headless runner (vanilla, Space Age, cizí mody) + výkonový scénář | bez externích závislostí (factorio-test), GUI přes napodobeninu `LuaGuiElement` |
| Grafika | procedurální model v Blenderu, sprity přegenerovatelné skriptem | jednotný vzhled, body drátů ze stejné projekce (`prototypes/wires.lua`) |

## Struktura

Mapa modulů je v `docs/development.md` → Struktura, architektura stručně v `CLAUDE.md`.

## Startup nastavení

| Název | Výchozí | Rozsah |
|---|---|---|
| `storage-optimizer-interval-multiplier` | 1,0 | 0,1–10 (větší = pomalejší) |
| `storage-optimizer-power-multiplier` | 1,0 | 0–10 |
| `storage-optimizer-max-stacks` | 20 | 1–100 |
