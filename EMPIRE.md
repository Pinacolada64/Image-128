# Empire 6

## Introduction

Empire is a game of ruling a medieval realm, a year a turn: buy and sell
land and grain, feed the people and the army, build markets, mills and
palaces, raise soldiers, sail to colonies, and attack the other rulers on
the board, until one is Emperor. Empire 6 is the Image BBS version, and
this is its port to Image BBS 128 (the `empire` branch, 11/2026; work in
progress, not yet in `master`).

**Where it came from.** Empire 5.1 ran on Image BBS 1.2. Empire 6.0 is
its rework for Image 1.2 (2010-2014, the changelog below), kept in
[Pinacolada64/ImageBBS](https://github.com/Pinacolada64/ImageBBS)
(`v1.2/games/empire6`), and copied unchanged into `games/empire6/` here
as the starting point. The port brings in ideas and texts from Empire II
("Empire Deluxe", the Centipede 128 BBS game): its quests, its stats for
horses, timber, spices, cannons and forts, and its stories
(`games/empire6/centipede-to-image.md`).

## Playing

The sysop puts `i.empire` on a menu command (or runs it with `R`, class
3, `empire`). It offers the Empire wall ("Read Empire wall?"); a new
ruler is asked their name. Then:

1. **The menu** (`i/emp.startturn`): `I` Instructions, `N` Empire News,
   `O` Other Rulers, `P` (or `C`) Play Empire, `T` Town Activities, `Y`
   Your Stats, `Q` Quit; `M` Maintenance for the sysop.
2. **The year** (`i/emp.trading`): the weather (poor to fantastic), land
   and grain to buy or sell at the year's prices, the harvest, the season
   (from Image's clock), feeding the people and the army (Return gives
   what they need, or all there is), the census, and investments:
   soldiers, markets, mills, palaces, foundries, shipyards, nobles,
   diplomats, ships.
3. **The colony** (`i/emp.colony`), with ships: serfs, grain and exports
   carried, the colonists fed, storms, pirates and the natives.
4. **Combat** (`i/emp.combat`): attack another ruler, soldiers and
   nobles against theirs.
5. **A quest** (`i/emp.quests`), each turn after combat, as in Empire
   II: nine of them,
   each with its story and payout: Raid the Pirates' Camp, Mystery of the
   Haunted Cave, Rescue the Maiden's Sister, The Quest of the Gods,
   Eradicate the Evil Cult, Search for the Island of Spice, Quest for the
   Legendary Bird City, Look for the Mountain Side Ship, Seek Arch-Mage
   Zircon's Help.
6. **The end of the year** (`i/emp.endturn`): taxes, pay, the rank
   (Lord, Prince, King, Emperor), and another year or not.

The Town (`T`) has Lucifer's Den, Warrior Promotion, the Realtor's
Advice, the Slave Market, the tax rate, Utopia's Auction, warriors to buy
and train, and Your Status. A ruler has a few turns a call; the game
remembers them across the call (`emp6mem`, below).

**Your Status** (`Y`) shows the 21 stats, one column on a 40-column
screen and two at 80 (`ll%`).

## Changes from Empire 5.1

### In Empire 6.0 (Image 1.2)

From `games/empire6/changelog.txt`:

- Numbers with commas (`{:sub.comma_value}`), an integer `a%` for MCI
  output (`&"... {pound}%a ..."` instead of `str$()`), and
  `def fn r(x)` for the random numbers (79 `rnd`s)
- Return at the feeding prompts gives the amount needed
- The game split into modules ("mini-plus" files, `+.emp6.*`), loaded
  and run by `{:sub.load_lmp}`, each ending in `return`; trading split
  from the turn's start (it was too big)
- The wall writer moved to `startup`, its file renamed (`e.emp6.wall`
  in the code; the changelog says `e.emp6wall`) so an Empire 5.1 wall
  isn't overwritten; `e.emperor` renamed `e.emp6 config`;
  new players made in `startup`
- Maintenance reached in local mode too (not only access level 9); the
  reset moved into it
- In combat, a dropped carrier saves both rulers' stats
- "This year's harvest is ... bushels"; "Colonies", not "Colonys"

### In the Image 128 port (11/2026)

- **Image 128's module scheme**: `i.empire` resident at lines 3000-3999,
  its modules `i/emp.*` at 4000, loaded by Image (`im` line 72) when
  needed; a module that needs another returns a request in `tw`
  (Programming, below)
- **The player file** grows from 100-byte records of 16 numbers (which
  big values overran) to 200 bytes: a name and 21 numbers, with Empire
  II's **horses, timber, spices, cannons and forts** (fields 17-21)
- **Quests** from Empire II, with the payouts its code gives (not its
  docs'), and its stories as `s.emp6.*` files
- **Your Status** formatted with `PRINT USING` (through `&,15,9`), in one
  or two columns by the caller's width
- **The season** at the feeding, from Image's clock, turned around south
  of the equator (the BBS's DST rule)
- **Plurals** done once (`{:sub.plural}`, `{:sub.count_noun}`): "1 ship
  is", "3 ships are"
- **40/80 columns**: the text word-wraps (`lp=1`) instead of the 1.2
  version's `l$` line breaks
- **Debug mode**: the lightbar's `Dbg` checkmark (`db`)
- About 70 fixes, each marked `' 128:` in the code, among them: the
  year's weather (`wc`) was never set, so prices divided by zero; an
  investment's number was never kept, so anything bought gave free
  soldiers; `tr` (the tax rate) was used for `tr%` (the time left), so at
  0% tax the game ended; `on -(tr%<1) goto` gave ?illegal quantity;
  losses could come out negative (`fn r()` is at least 1); `a%` overflowed
  past 32,767; a module's `goto` into `i.empire` leaked the BASIC stack;
  `{:sub.comma_value}` dropped a minus sign; a short ration read as a
  full one

## Modules

| Module | Lines | Does |
|---|---|---|
| `i.empire` | 3000-3999 | the resident part: the turn loop, the shared subroutines (below), stats in and out, ranks, Your Status, the news |
| `i/emp.startup` | 4000- | the wall and the news, a new ruler's realm, the sysop's first run |
| `i/emp.startturn` | 4000- | the turn's menu |
| `i/emp.trading` | 4000- | the year: weather, prices, land and grain, harvest, season, feeding, census, investments |
| `i/emp.colony` | 4000- | the colony: cargo, colonists, exports, the voyage's dangers |
| `i/emp.combat` | 4000- | attacking another ruler |
| `i/emp.quests` | 4000- | Empire II's quests, after a battle |
| `i/emp.endturn` | 4000- | the year's end: taxes, pay, rank |
| `i/emp.town` | 4000- | the Town's shops and services |
| `i/emp.maint` | 4000- | the sysop's maintenance: rulers' stats, the config, the reset |
| `i/emp.tourney` | 4000- | the joust, ported but not yet reached from the game |

Sources: `modules/i.empire.lbl`, `modules/i_emp.<name>.lbl` (`_` for
`/`); the Image 1.2 originals in `games/empire6/` (`Empire6.lbl`,
`plus_emp6_<name>.lbl`).

## Data files

| File | Drive | Kind | Holds |
|---|---|---|---|
| `e.empire6` | 3 | REL, 200 bytes | a ruler a record: name, land, soldiers, serfs, nobles, grain, tax rate, money, palaces, markets, mills, foundries, shipyards, diplomats, ships, colonies, training, horses, timber, spices, cannons, forts |
| `e.emp6 config` | 3 | SEQ | the land an Emperor needs (`ln`), the auto-reset (`mp`), the BBS credit exchange and its rate (`en`, `nn`) |
| `e.empnews6` | 3 | SEQ | the news (`{:sub.log_event}` appends) |
| `e.emp6.wall` | 3 | SEQ | the Empire wall |
| `s.emp6.win1`-`win8`, `s.emp6.zircon`, `s.emp6.rage` | 1 | SEQ | the quests' stories (from Empire II, rewrapped for 39 columns: `disk/README.md`) |

`asm/build.sh` puts the `s.emp6.*` files on `image128.d81`.

## Programming

### Lines, modules and jumps

`i.empire` is at 3000-3999 and stays in memory; a module (`i/emp.*`) is
loaded at 4000 by `{:sub.load_lmp}` (`a$="name":gosub` it: `im` line 72
loads `i/emp.name` unless it's there already) and returns. A module
can't load another (Image 128's nested reload: `modules/TODO.md`), so it
returns with a request in `tw`: from `startturn`, 1 the Town, 2 quit, 3
maintenance; `i.empire` acts on it.

The modules jump to `i.empire`'s lines by number, so **those lines can't
move**. `modules/emp6-includes.lbl` names them (each is its Image 1.2
number plus 3000); C64List 4.04 can't name a line in another file, so the
modules write the number with its first digit as a raw byte, `{$33}010`
for 3010. After changing `i.empire`, build and run
`tools/empcheck.py`: it checks each named line is still where the table
says (37 of them), and exits 1 if one moved. Room to grow is between
them (Your Status has 3071-3089).

### C64List and BASIC 7.0

`i.empire` is built with C64List 4.06 (`{include:..\Basic70.bas}`), so
it uses BASIC 7.0 (`instr`, `do`/`loop`, `print using`). The modules use
the preface (4.04); one that uses a BASIC 7.0 keyword is built from a
4.06 copy automatically (`tools/basic7.py`, PROGRAMMING.md). To move a
module to 4.06 for good: `tools/to406.py`.

### Shared subroutines in `i.empire`

| Line | Name | Does |
|---|---|---|
| 3005 | `sub.load_lmp` | load and run `i/emp.<a$>` |
| 3010 | `sub.comma_value` | print `x` with commas (`z$`; `j` right-justifies) |
| 3015 | `sub.str_to_int` | `an`, `an$` as a whole number without its sign |
| 3020 | `sub.any_key` | "(Press any key)" |
| 3025 | `sub.open_playerlog` | open `e.empire6` |
| 3030 | `save_stats_quit` | save, then quit (`goto`) |
| 3035 | `sub.save_your_stats` | write the ruler's record (`g3`) |
| 3040 | `sub.load_your_stats` | read it |
| 3050 | `sub.other_rulers` | the list of rulers |
| 3060 | `sub.rank` | the rank's name in `d2$` |
| 3070 | `sub.request_your_status` | Your Status if `an$` is `Y` |
| 3071 | `sub.your_status` | Your Status |
| 3090 | `sub.log_event` | `tt$` to the news |
| 3092 | `sub.read_config` | `e.emp6 config` into `ln`, `mp`, `en`, `nn` |
| 3115 | `sub.title` | the rank's title in `d2$` (from `tz`), as `sub.rank` |
| 3200 | `sub.plural` | `a$` ("ship" or "colony/colonies") for `pz` items, with `vb$`/`hv$` ("is"/"are", "has"/"have") |
| 3210 | `sub.count_noun` | the count and the noun: "3 ships" |

### Variables and memory

`games/empire6/variables.txt` lists the game's variables:

| Variable | Purpose |
|---|---|
| `la` | land |
| `pn` | money |
| `gr` | grain |
| `sf` | serfs |
| `wa` | soldiers |
| `nb` | nobles |
| `tr` | tax rate |
| `f%(1-6)` | the buildings |
| `yc` | ships |
| `i8` | colonies |
| `z9` | training |

Table: Existing Player Data from v5.1

| Variable | Purpose |
|---|---|
| `hs` | horses |
| `tb` | timber |
| `sp` | spices |
| `cn` | cannons |
| `fo` | forts |

Table: Added in the Image 128 port

New code uses names ending in 9 (`k9`, `c9$`...), which the game doesn't, and `tt$()`, Image's scratch
array.

> This is quite likely going to be converted over to Image 3.0 structs.

`db` is debug mode (`if db then ...`).

`emp6mem` (`$0a6e`, 2670-2686, `asm/equates.asm`) keeps what lasts
across a call: +0 the turns played, +1 the ruler they're for, +2 how many
rulers they've attacked, +3 on their numbers (up to 14, `emp6max`). On
the C64 this was the cassette buffer (899-915); on the 128 899-901 are
CHRGET's, so it moved.

### Output

Text goes out with `&` (MCI, word wrap with `lp=1`, symbols as the quoter
tokens: CLAUDE.md); numbers with `{:sub.comma_value}`, or `print using`
caught with `&,15,9` (PRINT_USING.md) when they line up in columns.

### Testing

In x128, a configured system with Empire on it: `build/empire-test.d81`
(not in git; `build/empire-test-before-1124.d81` is its copy before the
11/24 update). Write a built module onto it with c1541 (`-delete` then
`-write`, `i_emp.x.prg` as `i/emp.x`), boot, and run Empire (`R`, 3,
`empire`). DEBUG_TECHNIQUES.md has the x128 tools.

## Plans

The `TODO` file has Empire's plans, among them: Lt. Kernal multiplayer
and the network (attacks, alliances, news and a wall between boards),
alliances, trade and a market between players, spies, sieges, houses,
seasons and a winner, crops and farmers, the hunt, a fishing fleet,
islands as in Empire II (a second record per ruler), the royal vault and
heists, a royal tournament with jousting, courtship and marriage with
the game's own suitors (`games/empire6/suitors.md`), a court wizard and
a court jester (`games/empire6/jester.md`), Honor and the royal granary,
Your Status in a module of its own, and help for each prompt.
