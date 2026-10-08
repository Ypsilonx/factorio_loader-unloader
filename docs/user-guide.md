# Storage Optimizer – uživatelská příručka

## Co mod dělá

Storage Optimizer je jedna budova 1×1, která přesouvá **celé stacky** předmětů z jedné bedny nebo skladu
do druhé, **bez pásů** – až 20 stacků najednou. Nahrazuje sestavu „unloader → pás → loader“ a díky tomu,
že se zpracuje jen jednou za interval svého tieru, šetří výkon (UPS) i ve velkých továrnách.

```
dřív:   [bedna] → unloader → pás → loader → [bedna]
teď:    [bedna] → Storage optimizer → [bedna]
```

**Pojmy:** *přesun* = **velikost stacku × počet stacků**. Velikost stacku je standardně stack předmětu
(prázdné pole, např. 100 železných plátů), počet stacků nastavuješ 1–20 (limit lze zvýšit v nastavení modu).

## Postavení a směr

- **Zdroj** je bedna **za** optimizerem (strana s převodovkou), **cíl** je bedna **před** ním (kam míří
  šipky na horní desce) – stejně jako u inserteru.
- Při stavění a po najetí myší ukazují směr i indikátory „odkud → kam“ jako u inserteru. V **alt režimu**
  (klávesa Alt) je navíc vidět šipka mířící k cíli.
- Klávesa **R** otočí optimizer, tím se prohodí zdroj a cíl. Vždy platí jen jeden směr.
- **Dráty obvodové sítě** se připojují ke svorkovnici na převodovce (červený a zelený izolátor).
- Funguje s **bednami a sklady** (typy `container`, `logistic-container` a `infinity-container`, včetně
  logistických beden, nekonečné bedny a velkých skladů z jiných modů), s **nákladními vagóny** a s **montážními stroji a pecemi** (i z modů):
  - **stroj jako cíl** – optimizer plní jeho **vstup** surovinami receptu, např. jednorázově
    „železné pláty × 2 stacky“ jako zásobu. Stroj bez receptu nepřijme nic (optimizer čeká).
  - **stroj jako zdroj** – optimizer bere hotové **výrobky** z výstupu (po celých přesunech).
  - **Palivo neřeší** – uhlí do pece dál dává inserter; předměty, které nejsou surovinou receptu, zůstanou ve zdroji.
- **Vagón** se počítá jen, když stojí (ve stanici nebo zastavený ručně); zastavení vlaku ve stanici optimizer
  probudí, po odjezdu se sám uspí. Optimizer postav vedle koleje tak, aby zdroj/cíl ležel na vagónu.
- Pásy, cisterny a jiné budovy ignoruje.

## Pravidla přesunu

- Přesun proběhne **jen celý**: ve zdroji musí být všechny kusy (velikost stacku × počet stacků)
  a v cíli na ně musí být místo („všechno, nebo nic“). Jinak optimizer čeká.
- Se zapnutým **„Přesouvat i zbytky“** se přesune, kolik jde: nejvýš celý přesun, jinak tolik, kolik je ve
  zdroji a kolik se vejde do cíle. Bedna nebo vagón se tak vyprázdní úplně. Neúplný přesun stojí 50 kJ
  + poměrnou část za stacky navíc (např. 2,5 stacku = 50 + 1,5 × 5 kJ).
- Za jeden interval proběhne **nejvýše jeden přesun**. Má-li zdroj více druhů předmětů, střídá je.
- Zachová **kvalitu**, **čerstvost** (zkáza ve Space Age) i **data předmětů** (např. brnění s vybavením).

## Tiery

Každý pás ve hře dává jeden tier. Rychlejší pás = rychlejší optimizer.

Energie se platí **za přesun: 50 kJ + 5 kJ za každý další stack** (u všech tierů). Přesun 5 stacků
tedy stojí 70 kJ, 20 stacků 145 kJ – větší přesun je na kus levnější. Optimizer, který nic nepřesouvá,
nespotřebovává nic.

| Tier (pás) | Interval přesunu | Výkon při plné práci: 1 stack | 5 stacků | 20 stacků |
|---|---|---|---|---|
| Žlutý pás | 1 s | 50 kW | 70 kW | 145 kW |
| Červený pás | 0,5 s | 100 kW | 140 kW | 290 kW |
| Modrý pás | 0,33 s | 150 kW | 210 kW | 435 kW |
| Turbo pás (Space Age) | 0,25 s | 200 kW | 280 kW | 580 kW |

Zásobník energie pojme dva nejdražší přesuny, takže pruh energie v okně při práci jen mírně kolísá.
Bez proudu (nebo při jeho nedostatku) optimizer čeká, dokud síť nedobije energii na další přesun.

Mody, které přidávají další pásy, přidají **automaticky** i další tiery. Každý tier má vlastní výzkum
„Storage optimizer (<pás>)“. Vyžaduje výzkum pásu, předchozí tier a výzkumy všech surovin receptu. První
tier se ve vanille odemkne už za červenou vědu (po rychlém inserteru a oceli), červený až s červeným pásem.
Recept obsahuje předchozí tier, 2 pásy a podle rychlosti pásu rychlý inserter, ocel a elektronické obvody
(do žlutého), bulk inserter, pokročilé obvody a ocel (červený) nebo procesory a ocel (rychlejší).
S overhaul mody (Pyanodon, Bob's …) se prerekvizity dopočítají z jejich stromu výzkumů a recept zdraží
jejich dražší meziprodukty. Vyšší tier jde postavit přímo přes nižší a funguje i upgrade planner.
Tier poznáš podle barvy šipek (žlutá, červená, modrá, zelená, …) a podle názvu budovy.

## Nastavení

Kliknutím na optimizer se otevře **okno Storage optimizer**. Rozložením odpovídá nativnímu oknu inserteru,
jen bez voleb, které optimizer nepoužívá (a bez inventáře postavy). Okno jde přetáhnout za titulek
a pamatuje si polohu; zavírá se klávesou E, Esc nebo křížkem.

**Hlavní okno (vlevo):**

- Nahoře **stav** s barevnou tečkou a **živý náhled budovy**, pod ním tier, cena aktuálního přesunu,
  trasa „zdroj → cíl“ a pruh energie.
- **Používat filtry**, **bílá / černá listina** a 5 slotů. Kvalita se vybírá přímo ve slotu:
  *normální* = libovolná kvalita, vyšší kvalita = přesně tato kvalita. Bez filtrů se přesouvá cokoliv.
- **Velikost stacku**: prázdné pole = **stack materiálu** (např. 100 železných plátů), nebo libovolné číslo
  (např. 5000). Hodnota **není omezena na 255** jako u inserteru.
- **Počet stacků za přesun**: posuvník a pole, výchozí 1, ručně 1–20 (limit lze změnit v nastavení modu).
  Přesun = velikost stacku × počet stacků, např. železo 100 × 5 = 500 kusů. **Přesun stojí 50 kJ + 5 kJ za
  každý další stack.**
- **Přesouvat i zbytky**: viz [Pravidla přesunu](#pravidla-přesunu). Vypnuto = jen celé přesuny.

**Připojení obvodu (panel vpravo, jen u budovy připojené drátem):**

- *Připojeno k* – čísla připojených sítí (červená, zelená).
- *Povolit/Zakázat* – podmínka (signál, porovnání, signál nebo číslo), kdy optimizer pracuje.
  Stav **„Vypnuto obvodovou sítí“** znamená, že podmínka není splněná.
- *Nastavit filtry* – předměty se signálem v síti se stanou filtry (sloty se pak jen zobrazují).
  Bez signálu se nepřesouvá nic.
- *Nastavit velikost stacku* / *Nastavit počet stacků* – hodnotu určí **řídicí signál** (výchozí **S** a **N**,
  lze vybrat libovolný); vedle je vidět jeho **aktuální hodnota**. Hodnota > 0 nahradí ruční nastavení
  (počet stacků nejvýš limit), bez signálu nebo při 0 platí ruční nastavení. Pole v hlavním okně zešedne.
  Pokud signály S/N v téže síti používáš i k něčemu jinému, vyber jiný.

**Logistická síť (panel vpravo, jen v dosahu logistické sítě):** *Připojit k logistické síti* a podmínka.

Všechna nastavení okna se přenáší v **blueprintech**, při **kopírování nastavení** (Shift+klik) i při
**přestavění na jiný tier**.

## Indikátor stavu

Malá ikonka v rohu budovy (stejný stav ukazuje i okno budovy):

| Barva | Význam |
|---|---|
| Zelená | Pracuje – poslední cyklus proběhl přesun |
| Žlutá | Čeká – zdroj nemá dost předmětů nebo cíl nemá místo |
| Červená | Bez proudu, vypnuto obvodovou sítí, nebo chybí zdrojová/cílová bedna |

## Nastavení modu (startup)

*Nastavení → Mody → Startup* (vyžaduje restart):

- **Násobič intervalu přesunu** – žlutý tier 1 s; 2 = poloviční rychlost, 0,5 = dvojnásobná.
- **Násobič spotřeby energie** – násobí cenu přesunu (50 kJ + 5 kJ za další stack); 0 = bez spotřeby.
- **Maximální počet stacků za přesun** – výchozí 20. Zásobník energie optimizeru pojme dva nejdražší
  přesuny, takže po výpadku proudu optimizer ještě chvíli dojede z uložené energie.
