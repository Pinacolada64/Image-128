# Centipede BBS → Image 128: a translation table for Empire II

Empire II ("Empire Deluxe") is a Centipede 128 BBS game: `mdl.emp.delx.txt`
(the loader) and `mdl.emp.delx1.txt`-`mdl.emp.delx3.txt` (the game, lines
40000-63999), listed in this directory. This table maps what those modules
call in Centipede onto Image 128, as a first step towards bringing Empire II's
features into Empire 6 (`modules/i.empire.lbl`, `modules/i_emp.*.lbl`).

## Sources

All from <https://snowpig.org/centipede/> (downloads page: `dl-centipede.htm`):

- `centfree2.zip`: Centipede 128 (public domain release), a Commodore `.lbr`
  library. Its `OVERLAYS.LBR/OVL.MAIN` is the BASIC core holding the lines
  Empire II calls (section 4); `MANUAL.LBR` is the owner's manual.
- `cprg.zip`: the *Centipede Programmer's Reference Guide* (Adam Fanello,
  1997): `C-ARRAY.TXT` (the same as `centipede-array.txt` here),
  `BASIC.TXT` (Centipede's BASIC 7 extensions), `VARIABLES.TXT`, `MEMORY
  MAP.TXT`, `FILE FORMATS.TXT`. Its readme says it isn't public domain (for a
  licensed Centipede owner), so it isn't copied here: download it from there.
- `game11.zip`: Empire Deluxe as released. Its three modules are the same code
  as `mdl.emp.delx1`-`3.txt` here. It also has `_RAGE` (Zircon's rage text,
  which this directory lacks), `_EMPIRE DOCS` and a readme. (`game4.zip` has
  Empire V3 and `game6.zip` Master Empire, other Centipede Empires.)

Image: `docs/prg-im-routines.adoc`, `docs/prg-ampersand-calls.adoc` and
`docs/prg-variables.adoc` in ImageBBS3, and `PROGRAMMING.md` here for the
128's own calls.

"Uses" is how many times Empire II's three modules use it (0: listed for
completeness).

## 1. Output and input

| Centipede | Uses | Does | Image 128 |
|---|---:|---|---|
| `sys c(.)` (`c(0)`) | 381 | print `a$` and a Return | `&a$+"{f6}"`, or the text itself: `&"...{f6}"` |
| `sys c(1)` | 119 | print `a$` | `&a$`, `&"..."` |
| `draw"..."` | (core) | `print`, to the modem too | `&"..."` |
| `sys c(25)` | 0 | print `a$` + Return, uppercased in upper/graphics mode | `&` (Image handles the caller's case itself) |
| `sys c(26)` | 1 | print `a$`, uppercased in upper/graphics mode | `&` |
| `cr$` | many | chr$(13) | `{f6}` in an `&` string; `r$` in a file |
| `c2$` | 121 | two chr$(13)s | `{f6:2}` |
| Ctrl-P in text | 0 | a Return in 40 columns, a space in 80 | Image 1.2's `{pound}$l`; on Image 128, word wrap (`lp=1:&`) |
| Ctrl-Y in text | 0 | center the rest of the line | `&,15,7` (centering, `PROGRAMMING.md`) |
| `auto on` / `auto off` / `auto` | many | screen pausing on / off / reset its line count | (none needed: Image pauses by itself) |
| `poke c(16),1` | 0 | word wrap on | `lp=1:&"..."` (for that string only) |
| `sys c(17),x,y` | 0 | cursor to column x, line y | `&,70,x,y` (Position Terminal Cursor) |
| `sys c(48),a,x,y` | 0 | print `a$` at x,y on the console with an attribute | `&,69` (Display String on Console) |
| `sys c(4)` / `peek(c(3))` | 0 | get a key without waiting (in `c(3)`) | `&,48` (console only, `peek(198)`); a caller's key waits: `{pound}g1`, `gosub 7` |
| `sys c(8)`, `sys c(8):=v$` | 0 | line input (into `tx$`, or `v$`) | `&,1`, or `{pound}i1` in the prompt; the text in `an$` |
| `sys c(8)+3,x` | 0 | line input, styled (x: case, digits) | `gosub 6` (uppercase input, `an$`); `poke 53252,n` for its length |
| `poke c(6)` / `poke c(7)` | 0 | input's end character / width | `poke 53252,n` (characters allowed) |
| `poke c(23),1` | 8 | uppercase-only input | `gosub 6` (uppercase input) |
| `poke c(23)-1,x` | 0 | digits-only input | (none: take `val(an$)` and check it) |
| `poke c(21),x` | 0 | password input, echoing x | `&,6` (Password Input) |
| `sys c(29),x` | 0 | `a$` to upper / lower / Title Case | `&,15,1` (Title Case); no upper/lower call |
| `p` (`peek(c(2))`) | many | 0 ok, 1 abort (Ctrl-P), 2 Ctrl-V, 3 paused, 4 Ctrl-X, 255 carrier lost | `tr%<1`: time up or carrier lost (as Empire 6 checks after each input); no abort code |
| `peek(c(34))` | 0 | input timed out | `tr%<1` |
| `poke c(12)` / `poke c(28)` | 0 | carrier lost value / check | `&,47` (carchk); `tr%<1` |
| `peek(c(15))` | 0 | last key local (>0) or modem (0) | (none found) |
| `poke c(22)` | 0 | caller in ASCII/ANSI or C/G | (the caller's terminal flags; not needed for `&` output) |
| `sys c(46),x` | 0 | simulate 40 or 80 columns | `ll%`, the caller's width |
| `poke c(30)` | 0 | chat mode flags | `&,56` (chatmode) |
| `poke c(31)` | 0 | output local only | (none found) |
| `poke c(27)` | 0 | copy output to a printer/file | (none found) |
| `sys c(43)` | 0 | play a digitized sound | `&,25` (Sound: SID, not samples) |

## 2. Files and disk

| Centipede | Uses | Does | Image 128 |
|---|---:|---|---|
| `.open`, `.close`, `.print#`, `.input#` | many | the disk command with the modem's interrupts off while it runs (the SwiftLink must be) | plain `open`, `close`, `print#`, `input#`; Image keeps its files on LFN 2 (15 for commands) |
| `mstop` / `mcont` | 0 | SwiftLink off / on around disk I/O | (none: Image's ML handles it) |
| `sys c(5)`, `sys c(5):=v$` | 3 | read a line from file ID `c(35)` (normally 8) into `tx$` | `&,2,2`: a line from LFN 2 into `a$` |
| `sys c(5)+3` | 0 | the same, with its end character | `&,2,2` (no end character) |
| `poke c(35)` / `poke c(36)` | 0 | which file `c(5)` reads / check for `c(6)` | (always LFN 2) |
| `sys c(18),a,x` | 0 | scan file x for chr$(a) or EOF | (none: read lines with `&,2,2`) |
| `sys c(39)` | 0 | show the file open as `c(35)` | `&,3` (Read File from Disk) |
| `sys c(14),s,d` | 0 | copy file s to file d | (none found) |
| `sys c(13)` | 0 | compare filenames `a$` and `tx$` | a string compare |
| `sys c(44),...` | 0 | load or save memory | BASIC 7 `bload` / `bsave` |
| `sys c(49)` | 0 | file size, or blocks free | `gosub 61` (blocks free on `dr`) |
| `sys c(37)` / `sys c(38)` | 0 | save / load the local buffer | (the editor's buffer: `&,54`) |
| `dv`, `dr$` | many | device, prefix of the selected location | `dr=n:gosub 2` sets `dv%` and `dr$` |
| `gosub 480`-`499` | 6 (`481`) | select location `h` (`d(h)`, `h$(h)`): sets `dv`, `dr$`, opens 15 there | `dr=n:gosub 3`; the locations below |

Centipede's locations (`d()`/`h$()`, `VARIABLES.TXT`) for Image's drives:

| Centipede `h` | Holds | Image `dr` |
|---:|---|---|
| 1 (`gosub 481`) | support files (texts, menus) | 1, System (`s.` files) |
| 2 (`gosub 482`) | system files | 3, Etcetera (`e.` files) |
| 4 (`gosub 484`) | help files | 1, System |
| 9 (`gosub 489`) | program files (`mdl.`, `ovl.`) | 5, Plus (`i.`, `i/`, `sub.`) |
| 0 | accounts | 6, User files |
| 6 | e-mail | 2, E-mail |

## 3. Modules and memory

| Centipede | Uses | Does | Image 128 |
|---|---:|---|---|
| `sys c(10),d,x` | 1 (loader) | load the BASIC module in `a$`, level x | `gosub 70` (`i.`, line 3000), `gosub 72` (`i/`, 4000), `gosub 74` (`sub.`, 60000) |
| `goto 9050` | 6 | Empire II's loader (`mdl.emp.delx`, not Centipede): reset the stacks (`sys c(52)`), load the `mdl.` module in `a$` from the program files at level 2 | Empire 6's `a$="name":gosub {:sub.load_lmp}` (`i/emp.`+name, `gosub 72`) |
| `sys c(19)` / `sys c(20)` | 0 | hide / restore the modules in memory | (Image's three levels, `i.` `i/` `sub.`, each replaces its own) |
| `sys c(40),x` | 1 | mark a layer of variables (x=2) or arrays (x=1) to remove later ("killers") | `&,27` (Save Variable Pointers) |
| `sys c(41),x` | 3 | remove x layers of them | `&,28` (Restore Variable Pointers) |
| `sys c(50),a,x,y` | 0 | clear a string array from index y | `&,11` (Clear Array); `gosub 82`, `gosub 83` |
| `sys c(11)` | 0 | pop a RETURN | (none: BASIC 7 has no `pop`; return a code instead, as Empire 6's `tw` does) |
| `sys c(52)` | 1 (loader) | reset the CPU and BASIC stacks | (none) |
| `sys c(42)` | 0 | evaluate the expression in `a$` | (none) |
| `sys c(45),y` | 0 | line y of the program as text | (none) |
| `sys c(32)` / `sys c(33)` | 0 | wedge the BBS in / out | (none: Image's wedge stays in) |
| `sys c(24)` | 0 | terminal mode | `&,10` (Terminal Mode) |
| `sys c(47),l,h` | 0 | count messages | (none: Image's boards differ) |
| `sys c(51),m,s` | 0 | Lt. Kernal dual-port messages | (none) |
| `usr(x)` | many | a random integer, 0 to x-1 | `int(rnd(1)*x)`; Empire 6's `fn r(x)` is `usr(x)+1` |
| `rreg` | (core) | BASIC 7: the registers after a `sys` | the same (BASIC 7) |

## 4. Centipede's BASIC subroutines (`OVL.MAIN`)

| Centipede | Uses | Does | Image 128 |
|---|---:|---|---|
| `gosub 110` | 8 | get a key without waiting (`sys c(4)`): `a$` (chr$(0) if none), `p`; waits while paused | in a loop until a key: `gosub 7` (`a$`, `an$`) |
| `gosub 120` | 0 | wait for a key | `gosub 7` |
| `gosub 995` | 1 | throw away keys typed ahead (loop on 110 until none) | `poke 208,0` (the 128's keyboard buffer); the modem's: (none found) |
| `gosub 3640` | 4 | print the box prompt (`cm$(25)`) | (none: `{pound}g1` and `gosub 7` show Image's own) |
| `gosub 155` | 5 | print a blank line (`a$=cr$`, then 160) | `&"{f6}"` |
| `goto 160` | 23 | print `a$` and a Return (`sys c(25)`), and return | `&a$+"{f6}":return` |
| `gosub 202` / `203` | 15 (203) | open `f$` as file 8: 202 on the support files (481 first), 203 on the selected location; `f$` may end `,s,w` or `,a` | `a$=f$:gosub 4` (on LFN 2, `dr`); to write: `gosub 18` (scratch, then open to write); `e.` files: `gosub 36` (`r`, `w` or `a`) |
| `gosub 505` | 10 | read the drive's status (510), close file 8 | `gosub 5:close 2` |
| `gosub 510` | 6 | read the drive's status: `er` (and `er$`, track, sector); 20 or more: shows "Disk error" and logs it | `gosub 5`: `e%` (`e$`, `t%`, `s%`) |
| `gosub 205` | 13 | show the text file `f$` from the support files, then "Press Any Key" (unless aborted) | `dr=1:a$=...:gosub 14`, then a key (`gosub 7`) |
| `gosub 210` | 36 | show the text file `f$` from the selected location (open, check, `sys c(39)`, close); no pause | `gosub 14` |
| `gosub 300` | 4 | line input, style 1 (no cursor or color); then 320: `i$`, `p` | `gosub 6` (`an$`), or `{pound}i1` |
| `gosub 305` | 1 | print `>`, then 310 | `&">"`, then as 310 |
| `gosub 310` | 2 | line input, free (`sys c(8)`); then 320: `i$`, `p` | `&,1` / `{pound}i1` (`an$`) |
| `gosub 360` | 5 | after an input: print "Timeout!", "Carrier Lost!" or (p=1) "ABORT" (370); return | (Image says its own); then `if tr%<1 then` the quit line (Empire 6: `{$33}030`) |
| `gosub 390` | 5 | trim the spaces from both ends of `i$` | (none: a loop in BASIC if it matters) |
| `gosub 605` | 0 | number input (style 8): `i=val(i$)` | `{pound}i1`, `an=val(an$)` |
| `gosub 610` | 2 | `i$` to a number in `i`: 0 if empty or anything but digits (620 trims it first) | `an=val(an$)` (Empire 6: `{:sub.str_to_int}`) |
| `gosub 1000` / `1010` | 4 (1010) | wait for a key in `kp$`: 1000 Y, N or Return; 1010 prints the box prompt, then Y or N: `a$` | `gosub 94` (`[No]`) or `96` (`[Yes]`): `a` 1 for yes |
| `gosub 1005` | 1 | print "Are you sure (Y/N)? ", then 1010 | `gosub 93` ("Are You Sure?", then 94) |
| `gosub 8004` | 9 | add `a$` (50 characters) to this call's caller log | `gosub 51` (writes `a$` to the daily log) |
| `gosub 8000` | 0 | add `a$` to `d$(10)` and the caller log | `gosub 51` |
| `gosub 3630` | 0 | "TIME LIMIT EXCEEDED!" | (Image's own, at `tr%<1`) |
| `gosub 3675` | 0 | "File Not Found" | (none) |

## 5. Centipede's variables (`VARIABLES.TXT`)

| Centipede | Is | Image 128 |
|---|---|---|
| `na$` | the caller's handle | `na$` |
| `pu` | the caller's upload credits, in blocks (Empire II: `pu=pu+x`, the Emperor's credits, a winner's 500) | `cr`, the caller's credits |
| `pd` | the caller's download credits, in blocks | (`cr` too: Image has one count) |
| `da$` | today's date, MM/DD/YY | `d1$` (11 digits), through `&,15` (Convert Date) to show it |
| `dt$` | today's date in words ("Wednesday Apr 27,1994") | `&,15` (Convert Date) |
| `mc` | columns per line: 38 (40 columns) or 77 (80) | `ll%` (the caller's width) |
| `tm` | the caller's minutes for this call | `tr%` (time left) |
| `dv`, `dr$` | device, prefix of the selected location | `dv%`, `dr$` (`gosub 2`) |
| `h` | the selected location (`d(h)`, `h$(h)`) | `dr` |
| `dx` | the last location's command number (0: none) | (none) |
| `p` | status: see section 1 | `tr%<1` |
| `i$`, `i` | temporaries; line input lands in `i$` (320) | `an$`, `an` |
| `tx$`, `peek(142)` | the line from `sys c(5)` / `sys c(8)`, its length | `a$` (`&,2,2`), `an$` (`&,1`) |
| `er`, `er$` | drive error number, message | `e%`, `e$` (`gosub 5`) |
| `nu$` | chr$(0) (also at a string's start: MCI won't read it) | (none) |
| `cm$(25)` | the box prompt | (none) |
| `lg$`, `lg$()` | this call's caller log | Image's daily log (`gosub 51`) |
| `su$` | a message's subject (Empire II reuses it for text) | (Empire II's own use) |
| `f$` | filename for 202-210 | `a$` |

## 6. Empire II's player stats and Empire 6's

Empire II keeps a player's stats in `x()` (an enemy's in `k()`, a fleet's in
`s()`). From its status screens (`mdl.emp.delx3.txt` 56300-56314) and the
Edit screen (`delx2`):

| `x()` | Empire II | Empire 6 |
|---:|---|---|
| 2 | acres | `la` |
| 3 | gold | `pn` |
| 4 | rating | (rank: `tz`) |
| 5 | palace (x10 %) | `f%(1)` |
| 6 | nobles | `nb` |
| 7 | markets | `f%(2)` |
| 8 | mills | `f%(3)` |
| 9 | foundries | `f%(4)` |
| 10 | shipyards | `f%(5)` |
| 11 | stables | (none) |
| 12 | ships | `yc` |
| 13 | forts | (none) |
| 14 | cannons | (none) |
| 15 | exports, mainland | (none: Empire 6's exports are the colony's) |
| 16 | timber | (none) |
| 17 | grain, mainland | `gr` |
| 18 | grain, colony ("-I") | `yg` |
| 19 | serfs, mainland | `sf` |
| 20 | serfs, colony | `ys` |
| 21 | soldiers, mainland | `wa` |
| 22 | soldiers, colony | (none) |
| 23 | horses, mainland | (none) |
| 24 | horses, colony | (none) |
| 25 | spices | (none) |
| 26 | exports, colony | `ye` |
| 28 | dragons | (none) |
| 29 | turns used | (the turn counter, `emp6mem`) |

Empire 6 has diplomats (`f%(6)`), navigators (`x8`), colonies (`i8`) and
training (`z9`), which Empire II doesn't.

## 7. The quest payouts

Empire II's quests (`mdl.emp.delx3.txt` 50399-50905): pick 1-9 (0 none);
quests 1-8 fail 3 times in 4 (`int(rnd(1)*20)+1>5`); a win shows `win1`-`win8`
and writes "<name> Wins Quest n" to the news. `quest payoffs.txt` lists other
amounts for three of them; the code is what Empire II pays.

| Quest | Empire II pays (code) | `quest payoffs.txt` | Empire 6 |
|---|---|---|---|
| 1 | 30,000 gold, `x(3)` | 90,000 gold | `pn=pn+30000` |
| 2 | 30 horses, `x(23)` | 30 horses | no horses |
| 3 | 15 timber, `x(16)` | 15 tons of timber | no timber |
| 4 | 30,000 grain, `x(17)` | 40,000 bushels | `gr=gr+30000` |
| 5 | 4,000 acres, `x(2)` | 4,000 acres | `la=la+4000` |
| 6 | 20 spices, `x(25)` | 40 tons of spice | no spice |
| 7 | 4 nobles, `x(6)` | 4 nobles | `nb=nb+4` |
| 8 | 6 cannons, `x(14)` | 6 cannons | no cannons |
| 9 | Zircon (below) | lose 2,000 acres, 600 serfs, 4 nobles, 9,000 gold | most of it |

Quest 9, Zircon (`zircon` text), doesn't fail as 1-8 do. 18 times in 40
(`usr(40)+1<19`) he gives one gift from each of three groups of five (in
groups 1 and 2 the fifth is nothing), then three chances at more. Otherwise,
4 times in 30 he's enraged (`rage` text: `_RAGE` in `game11.zip`): acres
-2,000 (100 left at least), gold -9,000 (1,000), nobles -4 (1), serfs -600
(100), all four in Empire 6 (`la`, `pn`, `nb`, `sf`); the other 26 times
"Zircon can't see you now!".

| Group | Gifts | In Empire 6 |
|---|---|---|
| 1 | 8,000 acres; 30,000 gold; 5 nobles; 40,000 grain | all |
| 2 | 1,000 serfs; 4 shipyards; 2 forts + 8 cannons; 50 horses | serfs, shipyards |
| 3 | 4 foundries; 10 markets; 10 mills; 10 spices; 4 ships | all but spices |
| extra | 2 more turns (3 in 20); 10 exports (3 in 20, mainland's `x(15)`); a dragon (3 in 50) | turns (`emp6mem`); exports as the colony's (`ye`) |

So quests 1, 4, 5 and 7, and most of Zircon, pay out in Empire 6 as it is.
Quests 2, 3, 6 and 8 and Zircon's forts, cannons, horses, spices and dragon
need stats Empire 6 hasn't got: either new fields in the player record
(`e.empire6`: a name and 16 stats now), or other prizes in their place.

Empire 6 doesn't reach quests yet: `i/emp.quests` prints "Quests not finished
yet.", and i.empire's line that loads it, between combat and the end of the
turn, is a comment ("not ready yet").
