# Stav projektu

Aktualizováno: 2026-11-11

## Cíl

Není stanovený – 0.5.0 (Factorio 2.1) vydaná, další milník čeká na rozhodnutí.

## Hotovo

- 0.5.3 vydaná 2026-11-11: barva šipek podle pásu (`prototypes/colors.lua`: tint ikony → známé ikony vanilla/SA →
  barva v názvu ikony → nepoužitá barva), v alt režimu malá průhledná šipka u kraje (dřív zakrývala filtr).
  Testy: unit 56/0, vanilla 56/0, space-age 60/0, mods Bob 2/0, snímky ze hry, ruční kontrola savu.
- 0.5.2 vydaná 2026-11-09: skrytá závislost `(?) DoubleSpeedBelts` (tiery vždy ze zdvojených rychlostí pásů),
  portál zmiňuje One More Tier + DSB. Testy: unit 50/0, vanilla 56/0, space-age 60/0, mods SA+OMT+DSB 2/0.
- 2026-11-07 portál (`publish.sh --details-only`): název „Storage Optimizer – UPS-friendly stack inserter & loader“,
  krátký popis s klíčovými slovy, badges v `docs/mod-portal.md`, tagy + trains, circuit-network. Ve hře se název
  projeví až s další verzí (title v `info.json` je už upravený).
- 0.5.1 vydaná 2026-10-23: tipy a triky ve hře (`prototypes/tips.lua`), banner Buy Me a Coffee na portálu.
  Testy: unit 50/0, vanilla 56/0, space-age 60/0.
- 0.5.0 vydaná 2026-10-23 (pro 2.1; 2.0 zůstává na 0.4.2): `factorio_version` 2.1, oprava pádu s Pyanodonem 3.1 (`inherit_metatable`
  v `data-final-fixes.lua`), `recycler` a závislosti `+` v `run-tests.sh`. Testy: unit 50/0, vanilla 56/0,
  space-age 60/0, mods Py 3.1 / Bob's 3.0 / Tenebris / Arig+Hyarion (verze pro 2.1), perf zapsaný v docs.
- 0.4.2 vydaná 2026-10-18: strom tierů místo řetězu podle rychlosti (`tiers.lua: link_tree`) – hlášení hráče
  s UBSA + Planetaris Arig/Hyarion. Testy: unit 50/0, vanilla 56/0, space-age 60/0, mods Py / Bob's /
  Tenebris / UBSA / Arig+Hyarion+UBSA (řetězy porovnány před/po).
- 0.4.1 vydaná 2026-10-17: řetěz tierů přes nejdřív dostupný pás, stejně rychlé varianty bokem (`variant_of`) –
  hlášení hráče s Tenebris Prime.
- 0.4.0 vydaná na mod portálu: vlastní okno místo nativního, přesun zbytků,
  energie 50 kJ + 5 kJ za další stack.
- Dřív vydáno 0.2.0–0.3.1: tiery ze všech pásů s vlastním výzkumem, stroje, vagóny, nekonečné bedny, signály S/N,
  publikace přes API (`tools/publish.sh`).

## Rozpracováno

- 0.5.0 vydaná bez předchozí ruční kontroly ve hře – kontrola (okno, stín drátů, blueprint) proběhne dodatečně.

. Odpovědět hráči, kterému se pletly barvy tierů s mody pásů: opraveno v 0.5.3.
. Odpovědět hráči na One More Tier + Double Speed Belts (text připraven v session 2026-11-09), vyšlo v 0.5.2.
1. Kontrola tipů 0.5.1 ve hře (en i cs, ikony vagónu a signálů S/N).
2. Zpětná vazba z kontroly 0.5.0 ve hře, případná oprava 0.5.1.
3. Odpovědět hráči ve vlákně o plnění strojů (text připraven v session 2026-11-07).
4. Odpovědět hráči ve vlákně „Compatibility Issue: Tenebris Prime“ (opraveno v 0.4.2).
5. UBSA zatím nemá verzi pro 2.1 – otestovat strom tierů s UBSA, až vyjde.

## Otevřené otázky / slepé uličky

- ❌ Ikona pásu v alt režimu – střed patří ikoně filtru, hodně hráčů má alt režim zapnutý trvale.
- Co dál po 0.4.x? Odloženo: čtení přesunů do obvodové sítě. ROADMAP.md se založí, až budou plány.
- Odloženo, přibalit k další větší verzi: volba „neplnit stroje víc, než potřebují“ (hlášení hráče 2026-11).
  Dnes cíl-stroj bere až plný stack (`get_insertable_count` v `transfer.lua:120`), takže při rozjezdu stroje hamstrují
  a vzdálenější hladoví; za běhu tok = spotřeba. Návrh: checkbox (výchozí vypnutý), `room` omezit na ~2× suroviny
  receptu. Zamítnuto: přeskakování intervalů (zlomky nevyřeší, příčinu neodstraní). Obejití dnes: síť, stroj
  *Read contents* → podmínka optimizeru *předmět < 10*.
- ❌ Rameno inserteru namířené na vlastní políčko – engine entitu dál počítá (~0,107 ms/tick na 1000 ks). Řešení `disabled_by_script`.
- ❌ Velikost dávky v `inserter_stack_size_override` – engine ji omezí na 0–255. Řešení: `storage` + tagy blueprintu.
- ❌ Nativní okno inserteru + boční panel (do 0.3.x) – ukazovalo volby, které mod ignoruje. Nahrazeno vlastním oknem.
- ❌ Energie 100 kJ za stack – při 1000 budovách stovky MW. Nyní 50 kJ za přesun + 5 kJ za další stack.
- ❌ Shoda rychlostí pásů řešená abecedou – svítící pás Tenebris (`bioluminescent-…`) se stal tierem 1 a celý řetěz
  čekal na `bioinfusor`. Řešení: řetěz přes pás dostupný nejdřív.
- ❌ Řetěz hlavních tierů jen podle rychlosti – pás z jiné větve výzkumu (hyper z Arig za Hyarionem, turbo za
  Vulcanem) zamkl všechny rychlejší tiery (UBSA). Řešení: strom. Samotný uzávěr prerekvizit nestačí – Pyanodon
  je doplňuje až v `pypostprocessing` po nás, proto i kritérium „pás je surovinou receptu“.
