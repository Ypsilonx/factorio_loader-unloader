# Storage Optimizer – uživatelská příručka

## Co mod dělá

Storage Optimizer je jedna budova 1×1, která přesouvá **celé dávky (stacky)** předmětů z jedné bedny nebo
skladu do druhé, **bez pásů**. Nahrazuje sestavu „unloader → pás → loader“ a díky tomu, že se zpracuje jen
jednou za interval svého tieru, šetří výkon (UPS) i ve velkých továrnách.

```
dřív:   [bedna] → unloader → pás → loader → [bedna]
teď:    [bedna] → Storage optimizer → [bedna]
```

## Postavení a směr

- **Zdroj** je bedna **za** optimizerem, **cíl** je bedna **před** ním – stejně jako u inserteru.
- Směr ukazuje šipka, která je vidět v **alt režimu** (klávesa Alt). Šipka míří k cíli.
- Klávesa **R** otočí optimizer, tím se prohodí zdroj a cíl. Vždy platí jen jeden směr.
- Funguje s **bednami a sklady** (typy `container` a `logistic-container`, včetně logistických beden a velkých
  skladů z jiných modů). Fabriky, pásy a jiné budovy ignoruje.

## Pravidla přesunu

- Přesouvá **jen celé dávky**. Pokud ve zdroji není celá dávka daného předmětu, čeká.
- Přesouvá **jen tehdy, když se celá dávka vejde do cíle** („všechno, nebo nic“).
- Za jeden interval přesune **nejvýše jednu dávku**. Má-li zdroj více druhů předmětů, střídá je.
- Zachová **kvalitu**, **čerstvost** (zkáza ve Space Age) i **data předmětů** (např. brnění s vybavením).

## Tiery

Každý pás ve hře dává jeden tier. Rychlejší pás = rychlejší optimizer.

Energie se platí **za každou přesunutou dávku: 100 kJ** (u všech tierů). Optimizer, který nic
nepřesouvá, nespotřebovává nic; rychlejší tier při plné práci odebírá úměrně víc.

| Tier (pás) | Interval | Výkon při plné práci |
|---|---|---|
| Žlutý pás | 2 s | 50 kW |
| Červený pás | 1 s | 100 kW |
| Modrý pás | 0,67 s | 150 kW |
| Turbo pás (Space Age) | 0,5 s | 200 kW |

Bez proudu (nebo při jeho nedostatku) optimizer čeká, dokud síť nedobije energii na další dávku.

Mody, které přidávají další pásy, přidají **automaticky** i další tiery. Recept tieru obsahuje jeho pás
a odemyká ho stejný výzkum jako pás. Vyšší tier jde postavit přímo přes nižší a funguje i upgrade planner.

## Nastavení

Po otevření optimizeru se zobrazí nativní okno inserteru a **vpravo od něj panel Storage optimizer**.

- **Velikost dávky** (panel vpravo): prázdné pole = **Auto** (jeden stack předmětu, např. 100 železných
  plátů), nebo libovolné číslo (např. 5000). Hodnota **není omezena na 255** jako u inserteru.
- **Počet stacků za přesun** (panel vpravo): kolik stacků se přesune najednou, 1–20 (limit lze změnit
  v nastavení modu). Přesun = velikost stacku × počet stacků, např. železo 100 × 5 = 500 kusů.
  Platí „všechno, nebo nic“ pro celý přesun a **každý stack stojí 100 kJ** (5 stacků = 500 kJ).
  Signál **„Počet stacků“** z obvodové sítě (hodnota > 0) má přednost před ručním nastavením.
- **Filtry** (nativní okno): 5 slotů, režim povolit/zakázat, volitelně i podle kvality.
  Bez filtrů se přesouvá cokoliv.
- **Obvodová síť** (nativní okno, po připojení drátu):
  - *Zapnout/vypnout* – podmínka, kdy optimizer pracuje.
  - *Nastavit velikost stacku* – hodnota signálu je **velikost dávky**. Výchozí signál je
    „Velikost dávky“ z tohoto modu. Hodnota 0 nebo žádný signál = použije se ruční nastavení / Auto.
  - *Nastavit filtry* – předměty se signálem v síti se stanou filtry. Bez signálu se nepřesouvá nic.

> **Pozor:** posuvník *Override stack size* a řádek se stavem v nativním okně inserteru patří
> inserteru a optimizer je **ignoruje** (nativní stav ukazuje trvale „Vypnuto skriptem“ – tím mod
> šetří výkon). Platný stav a velikost dávky ukazuje panel vpravo.

Velikost dávky se přenáší v **blueprintech**, při **kopírování nastavení** (Shift+klik) i při
**přestavění na jiný tier**.

## Indikátor stavu

Malá ikonka v rohu budovy:

| Barva | Význam |
|---|---|
| Zelená | Pracuje – poslední cyklus přesunul dávku |
| Žlutá | Čeká – zdroj nemá celou dávku nebo cíl nemá místo |
| Červená | Bez proudu, vypnuto obvodovou sítí, nebo chybí zdrojová/cílová bedna |

## Nastavení modu (startup)

*Nastavení → Mody → Startup* (vyžaduje restart):

- **Násobič intervalu přesunu** – 2 = poloviční rychlost, 0,5 = dvojnásobná.
- **Násobič spotřeby energie** – násobí 100 kJ za stack; 0 = bez spotřeby.
- **Maximální počet stacků za přesun** – výchozí 20. Zásobník energie optimizeru pojme cenu nejdražšího
  přesunu, takže po výpadku proudu optimizer ještě chvíli dojede z uložené energie.
