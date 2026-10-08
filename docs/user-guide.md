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
(Auto, např. 100 železných plátů), počet stacků nastavuješ 1–20.

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
- Za jeden interval proběhne **nejvýše jeden přesun**. Má-li zdroj více druhů předmětů, střídá je.
- Zachová **kvalitu**, **čerstvost** (zkáza ve Space Age) i **data předmětů** (např. brnění s vybavením).

## Tiery

Každý pás ve hře dává jeden tier. Rychlejší pás = rychlejší optimizer.

Energie se platí **za přesun: 20 kJ + 5 kJ za každý další stack** (u všech tierů). Přesun 5 stacků
tedy stojí 40 kJ, 20 stacků 115 kJ – větší přesun je na kus levnější. Optimizer, který nic nepřesouvá,
nespotřebovává nic.

| Tier (pás) | Interval přesunu | Výkon při plné práci: 1 stack | 5 stacků | 20 stacků |
|---|---|---|---|---|
| Žlutý pás | 1 s | 20 kW | 40 kW | 115 kW |
| Červený pás | 0,5 s | 40 kW | 80 kW | 230 kW |
| Modrý pás | 0,33 s | 60 kW | 120 kW | 345 kW |
| Turbo pás (Space Age) | 0,25 s | 80 kW | 160 kW | 460 kW |

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

Po otevření optimizeru se zobrazí nativní okno inserteru a **vpravo od něj panel Storage optimizer**.

- **Velikost stacku** (panel vpravo): prázdné pole = **Auto** (stack předmětu, např. 100 železných plátů),
  nebo libovolné číslo (např. 5000). Hodnota **není omezena na 255** jako u inserteru.
- **Počet stacků za přesun** (panel vpravo): 1–20 (limit lze změnit v nastavení modu).
  Přesun = velikost stacku × počet stacků, např. železo 100 × 5 = 500 kusů. **Přesun stojí 20 kJ + 5 kJ za každý další stack**
  (panel ukazuje cenu aktuálního přesunu).
- **Počet stacků ze sítě** (rámeček **„Připojení obvodu – Storage optimizer“** vpravo, zobrazí se jen u budovy
  připojené drátem; obdoba nativního „Nastavit velikost štosu“, které do nativního okna přidat nejde):
  po zaškrtnutí určuje počet stacků hodnota **řídicího signálu** (výchozí **N**, lze vybrat libovolný).
  Vedle výběru signálu je vidět jeho **aktuální hodnota ze sítě**. Hodnota > 0 nahradí ruční počet stacků
  (nejvýš limit 20); bez signálu nebo při 0 platí ruční nastavení.
- Pole řízená sítí **zešednou**: „Počet stacků“ při zapnutém „Počet stacků ze sítě“, „Velikost stacku“ při
  zapnutém nativním „Nastavit velikost štosu“. Panely se obnovují, dokud je okno otevřené.
- Výchozí řídicí signály jsou klasická písmena **S** (velikost stacku) a **N** (počet stacků). Pokud je
  v téže síti používáš i k něčemu jinému, vyber jiný řídicí signál.
- Pokud stav ukazuje **„Vypnuto obvodovou sítí“**, není splněná podmínka *Povolit/Zakázat* v nativním
  okně (např. signál z podmínky v síti chybí) – optimizer pak nepřesouvá vůbec.
- **Filtry** (nativní okno): 5 slotů, režim povolit/zakázat, volitelně i podle kvality.
  Bez filtrů se přesouvá cokoliv.
- **Obvodová síť** (nativní okno, po připojení drátu):
  - *Zapnout/vypnout* – podmínka, kdy optimizer pracuje.
  - *Nastavit velikost štosu* – hodnota signálu je **velikost stacku**. Výchozí signál je **S**.
    Hodnota 0 nebo žádný signál = použije se ruční nastavení / Auto.
  - *Nastavit filtry* – předměty se signálem v síti se stanou filtry. Bez signálu se nepřesouvá nic.

> **Pozor:** posuvník *Override stack size* v nativním okně inserteru patří inserteru a optimizer ho
> **ignoruje**. Platí velikost stacku a počet stacků z panelu vpravo. Řádek se stavem v nativním okně
> ukazuje stav optimizeru (Pracuje / Čeká / Bez proudu / …).

Velikost stacku, počet stacků i volba „Počet stacků ze sítě“ s řídicím signálem se přenáší
v **blueprintech**, při **kopírování nastavení** (Shift+klik) i při **přestavění na jiný tier**.

## Indikátor stavu

Malá ikonka v rohu budovy (stejnou barvu má i dioda stavu v okně budovy):

| Barva | Význam |
|---|---|
| Zelená | Pracuje – poslední cyklus proběhl přesun |
| Žlutá | Čeká – zdroj nemá celý přesun nebo cíl nemá místo |
| Červená | Bez proudu, vypnuto obvodovou sítí, nebo chybí zdrojová/cílová bedna |

## Nastavení modu (startup)

*Nastavení → Mody → Startup* (vyžaduje restart):

- **Násobič intervalu přesunu** – žlutý tier 1 s; 2 = poloviční rychlost, 0,5 = dvojnásobná.
- **Násobič spotřeby energie** – násobí cenu přesunu (20 kJ + 5 kJ za další stack); 0 = bez spotřeby.
- **Maximální počet stacků za přesun** – výchozí 20. Zásobník energie optimizeru pojme dva nejdražší
  přesuny, takže po výpadku proudu optimizer ještě chvíli dojede z uložené energie.
