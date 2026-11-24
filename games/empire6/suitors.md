# Empire 6: suitors (the game's own nobles)

A plan for the TODO item "suitors from the game's own nobility" (user,
11/24/2026), with the courtship and marriage item: a list of unmarried
nobles a ruler can court, of the gender opposite the ruler's (a ruler who
chose "they" may court from either list). Not written yet.

## Each suitor's state

| State | Flag | Means |
|---|---|---|
| free | 0 | can be courted; any ruler |
| courted | 1 | a ruler has courted them past the first gift: others may still try, and the one with the most courtship points can propose (rivals in the news) |
| married | 2 | the spouse is a ruler (by player number); taken |
| widowed | 3 | the spouse died: the ruler's kingdom fell, or the ruler was deleted (AutoMaint's weeding). Free again after a mourning time (30 days from the date kept), keeping a share of the dowry, which makes them a richer match the second time |

Suitors can die too (old age, plague, a battle beside their spouse): then
the ruler is the one widowed, in the news, and a free suitor's place is
filled by a new one.

## A record (proposed)

A REL file, `e.emp6.suitors` on drive 3, one record per suitor, written
at a game reset (`i/emp.maint`) and read by the town (where courting
happens):

| Field | What |
|---|---|
| given name | from the pools below |
| seat | "of Ravenmoor": the house's lands |
| gender | `M` or `F` |
| state | 0-3, above |
| ruler | the courting ruler (1) or spouse (2, 3): player number |
| points | the leading suitor's courtship points |
| date | when married, or widowed (mourning ends 30 days later) |
| trait | one word, for the texts: fair, wise, wealthy, pious, brave... |
| dowry | what their house gives: gold, land, grain or goods, and how much |

About 12 of each gender for a board's game; more on a busy one. A
season's reset (the seasons item) deals a new list, with the widowed
and the still-free kept on.

## Names to deal from

At a reset, `i/emp.maint` pairs a random given name with a random seat,
neither used twice, so each game's suitors differ. Invented for Empire 6:
period given names, made-up seats.

**Ladies' given names (24):** Aveline, Isolde, Rosamund, Elspeth, Maud,
Gwendolyn, Sibylla, Cecily, Eleanora, Melisande, Juliana, Beatrix, Odile,
Annora, Clemence, Matilda, Edith, Alys, Petronella, Isabeau, Joan,
Margery, Rohesia, Lettice

**Lords' given names (24):** Aldric, Bertram, Cedric, Edmund, Gareth,
Hugo, Leofric, Osric, Roland, Tristan, Godfrey, Percival, Anselm,
Baldwin, Everard, Rupert, Geoffrey, Walter, Ranulf, Ivo, Fulk, Gervase,
Hamon, Aymer

**Seats (32):** Ravenmoor, Thornmere, Greywater, Corran Vale, Redmarch,
Wyncrest, Brackenholt, Silverbrook, Duncairn, Stonereach, Fallowmere,
Marrowgate, Hollin Ford, Kestrel Hill, Westerfold, Highcombe, Ironvale,
Larkspur, Blackwater, Oakhurst, Wendmere, Greyholm, Ambermoor,
Thistledown, Rookwood, Saltmere, Dunmere, Harrowdale, Copperbeck,
Wolfsden, Mistlecombe, Ebonford

(A name with its title and seat is at most 31 characters, "Lady Petronella
of Kestrel Hill", so it fits a 40-column line with room to spare; with the
trait after it, it can reach 44 ("..., the learned"), so a line that adds
the trait is word-wrapped, `lp=1`.)

## A dealt list (an example)

What one reset might give:

| # | Lady | Trait | Dowry | | Lord | Trait | Dowry |
|---|---|---|---|---|---|---|---|
| 1 | Aveline of Thornmere | fair | 4,000 gold | | Aldric of Ravenmoor | brave | 2,000 acres |
| 2 | Isolde of Greywater | wise | 1,500 acres | | Bertram of Highcombe | wealthy | 9,000 gold |
| 3 | Rosamund of Kestrel Hill | pious | 20,000 bushels | | Cedric of Ironvale | stern | 40 cannons |
| 4 | Elspeth of Corran Vale | witty | 2,500 gold | | Edmund of Larkspur | gentle | 15,000 bushels |
| 5 | Maud of Redmarch | wealthy | 12,000 gold | | Gareth of Blackwater | bold | 300 soldiers |
| 6 | Sibylla of Wyncrest | learned | 6 diplomats | | Leofric of Oakhurst | wise | 1,200 acres |
| 7 | Cecily of Brackenholt | merry | 50 horses | | Osric of Wendmere | proud | 3 ships |
| 8 | Melisande of Duncairn | fair | 3,000 acres | | Roland of Greyholm | valiant | 500 soldiers |
| 9 | Juliana of Stonereach | shrewd | a market | | Tristan of Ambermoor | gallant | 5,000 gold |
| 10 | Beatrix of Fallowmere | kind | 25,000 bushels | | Godfrey of Thistledown | pious | 80 timber |
| 11 | Odile of Marrowgate | proud | 30 spices | | Anselm of Rookwood | learned | a mill |
| 12 | Clemence of Westerfold | gentle | 7,000 gold | | Baldwin of Saltmere | wealthy | 11,000 gold |
