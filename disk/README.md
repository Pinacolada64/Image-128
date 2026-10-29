# disk/

Data files `asm/build.sh` writes to `build/image128.d81` as they are.

| File | On the disk as | From | What it is |
|---|---|---|---|
| `e.lightbar.prg` | `e.lightbar` | Image BBS 3.0 release, D2 (2023-12-31) | the lightbar's 64 three-letter labels, loaded by `im` line 3110 (`&,7,dv%,8`, into `bartbl`) |
| `e.ecs.main.prg` | `e.ecs.main` | Image BBS 3.0 release, D2 (2023-12-31) | the Extended Command Set's main definitions, loaded by `im` line 3106 (`&,42,4`) |
| `e.printmodes.prg` | `e.printmodes` | Image BBS 3.0 release, D2 (2023-12-31) | the MCI print modes, line 3108 (`&,7,dv%,7`, into `pmodetbl`) |
| `e.alarms.prg` | `e.alarms` | Image BBS 3.0 release, D2 (2023-12-31) | the alarm table, line 3112 (`&,7,dv%,9`, into `alarmtb`) |
| `nm.times.prg` | `nm.times` | Image BBS 3.0 release, D2 (2023-12-31) | the network alarm table, line 3116 (`&,7,dv%,12`, into `netalrm`) |
| `e.fkeys.seq` | `e.fkeys` (SEQ) | Image BBS 3.0 release, D2 (2023-12-31) | the sysop's function key macros (`f1$`-`f8$`), lines 3118-3126 |
| `e.lightdefs.seq` | `e.lightdefs` (SEQ) | Image BBS 3.0 release, D2 (2023-12-31) | the checkmarks the BBS starts with: 8 lines (pages) of 16 digits, read by `im` lines 3250-3258 |
| `today.Jan.seq` ... `today.Dec.seq` | `today.Jan` ... `today.Dec` (SEQ) | Image BBS 3.0 release, D2 (2023-12-31), with three fixes (below) | Today in History: the facts `i/lo/today` picks today's from (format: PROGRAMMING.md, "Today in History files"; edit them with `tools/today.py`) |

The 3.0 originals are on `master d2 2023-12-31.d81` in the ImageBBS3
repo (`Larry Hedman/master-release-2023-12-31/`).

Fixed in `today.*` (`tools/today.py check` finds them in the originals):

- `today.Mar`: `R0315` (Beware the Ides of March!) had `S` in column 10,
  which isn't a weekday, so it never showed; now a space.
- `today.Aug`: `S0838` (Lea and Perrins begin making Worcester Sauce),
  no such day; now `S0830`, where it sits in the file (between the 29th
  and the 30th).
- `today.Aug`: `B0808` (Rudi Gernreich) was 81 characters, one more than
  `&,2,2` reads; now wrapped onto a `C` line.
- `today.Dec` keeps the zeros the original has after its `^` line (the
  maker stops at the `^`).
