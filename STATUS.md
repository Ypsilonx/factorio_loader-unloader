# Stav projektu

Aktualizováno: 2026-10-17

## Cíl

Není stanovený – 0.4.0 je vydaná, další milník čeká na rozhodnutí (viz otevřené otázky).

## Hotovo

- 0.4.0 vydaná na mod portálu: vlastní okno místo nativního, přesun zbytků,
  energie 50 kJ + 5 kJ za další stack.
- Dřív vydáno 0.2.0–0.3.1: tiery ze všech pásů s vlastním výzkumem, stroje, vagóny, nekonečné bedny, signály S/N,
  publikace přes API (`tools/publish.sh`).
- Testy 2026-10-17: unit 45/0, vanilla 56/0 (4 skip = Space Age). Kompatibilita (pymodpack, Bob's) ověřena 2026-10-08.
- Audit dokumentace 2026-10-17: spec v `docs/specs/` přepsaný na stav 0.4.0, CLAUDE.md bez duplicit se skillem,
  opravené README a development.md.

## Rozpracováno

- Nic.

## Další krok

1. Rozhodnout obsah další verze (viz otevřené otázky).

## Otevřené otázky / slepé uličky

- Co dál po 0.4.0? Odloženo: čtení přesunů do obvodové sítě. ROADMAP.md se založí, až budou plány.
- ❌ Rameno inserteru namířené na vlastní políčko – engine entitu dál počítá (~0,107 ms/tick na 1000 ks). Řešení `disabled_by_script`.
- ❌ Velikost dávky v `inserter_stack_size_override` – engine ji omezí na 0–255. Řešení: `storage` + tagy blueprintu.
- ❌ Nativní okno inserteru + boční panel (do 0.3.x) – ukazovalo volby, které mod ignoruje. Nahrazeno vlastním oknem.
- ❌ Energie 100 kJ za stack – při 1000 budovách stovky MW. Nyní 50 kJ za přesun + 5 kJ za další stack.
