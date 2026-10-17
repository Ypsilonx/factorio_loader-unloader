# Stav projektu

Aktualizováno: 2026-10-17

## Cíl

Vydat 0.4.0 na mod portál – hotovo, až bude verze na portálu a projde ruční checklist z `docs/development.md`.

## Hotovo

- 0.4.0 připravená v repu (info.json, changelog, popis portálu): vlastní okno místo nativního, přesun zbytků,
  energie 50 kJ + 5 kJ za další stack.
- Dřív vydáno 0.2.0–0.3.1: tiery ze všech pásů s vlastním výzkumem, stroje, vagóny, nekonečné bedny, signály S/N,
  publikace přes API (`tools/publish.sh`).
- Testy 2026-10-17: unit 45/0, vanilla 56/0 (4 skip = Space Age). Kompatibilita (pymodpack, Bob's) ověřena 2026-10-08.

## Rozpracováno

- Nic.

## Další krok

1. Ověřit, zda je 0.4.0 na portálu; pokud ne: ruční checklist ve hře → `space-age` testy → `tools/publish.sh --details`.

## Otevřené otázky / slepé uličky

- Je 0.4.0 publikovaná? Z gitu to nejde poznat (tagy verzí se nepoužívají).
- Co dál po 0.4.0? Odloženo: čtení přesunů do obvodové sítě. ROADMAP.md se založí, až budou plány.
- ❌ Rameno inserteru namířené na vlastní políčko – engine entitu dál počítá (~0,107 ms/tick na 1000 ks). Řešení `disabled_by_script`.
- ❌ Velikost dávky v `inserter_stack_size_override` – engine ji omezí na 0–255. Řešení: `storage` + tagy blueprintu.
- ❌ Nativní okno inserteru + boční panel (do 0.3.x) – ukazovalo volby, které mod ignoruje. Nahrazeno vlastním oknem.
- ❌ Energie 100 kJ za stack – při 1000 budovách stovky MW. Nyní 50 kJ za přesun + 5 kJ za další stack.
