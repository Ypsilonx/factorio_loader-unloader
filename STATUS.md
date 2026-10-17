# Stav projektu

Aktualizováno: 2026-10-17

## Cíl

Není stanovený – 0.4.1 vydaná, další milník čeká na rozhodnutí (viz otevřené otázky).

## Hotovo

- 0.4.1 vydaná 2026-10-17: řetěz tierů přes nejdřív dostupný pás, stejně rychlé varianty bokem (`variant_of`) –
  hlášení hráče s Tenebris Prime. Testy: unit 46/0, vanilla 56/0, space-age 60/0, mods pymodpack / Bob's
  (tiery beze změny), tenebris-prime 1.3.10.
- 0.4.0 vydaná na mod portálu: vlastní okno místo nativního, přesun zbytků,
  energie 50 kJ + 5 kJ za další stack.
- Dřív vydáno 0.2.0–0.3.1: tiery ze všech pásů s vlastním výzkumem, stroje, vagóny, nekonečné bedny, signály S/N,
  publikace přes API (`tools/publish.sh`).
- Audit dokumentace 2026-10-17: spec v `docs/specs/` přepsaný na stav 0.4.0, CLAUDE.md bez duplicit se skillem,
  opravené README a development.md.

## Rozpracováno

- Nic.

## Další krok

1. Odpovědět hráči na portálu (Tenebris Prime).
2. Rozhodnout obsah další verze (viz otevřené otázky).

## Otevřené otázky / slepé uličky

- Co dál po 0.4.0? Odloženo: čtení přesunů do obvodové sítě. ROADMAP.md se založí, až budou plány.
- ❌ Rameno inserteru namířené na vlastní políčko – engine entitu dál počítá (~0,107 ms/tick na 1000 ks). Řešení `disabled_by_script`.
- ❌ Velikost dávky v `inserter_stack_size_override` – engine ji omezí na 0–255. Řešení: `storage` + tagy blueprintu.
- ❌ Nativní okno inserteru + boční panel (do 0.3.x) – ukazovalo volby, které mod ignoruje. Nahrazeno vlastním oknem.
- ❌ Energie 100 kJ za stack – při 1000 budovách stovky MW. Nyní 50 kJ za přesun + 5 kJ za další stack.
- ❌ Shoda rychlostí pásů řešená abecedou – svítící pás Tenebris (`bioluminescent-…`) se stal tierem 1 a celý řetěz
  čekal na `bioinfusor`. Řešení: řetěz přes pás dostupný nejdřív.
