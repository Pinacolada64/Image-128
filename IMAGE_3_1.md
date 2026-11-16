# Image 128 and Image 3.1: what each has, and what to port

Image BBS 3.1 (the C64 repository, `ImageBBS3`, branch `docs`) is the
3.0 release of 2023-12-31 with the fixes and features listed in its
`docs/changes-31.adoc`. Image 128 started from the same 3.0 release.
This file compares the two as of 11/15/2026: what Image 128 adds to 3.0,
which of 3.1's changes Image 128 already has, and which it still needs.

How the 128 had to differ from the C64 (BASIC 7's strings, its stack,
the moved pointers) is in `PORTING_NOTES.md`, not here.

## Where the work is

`Image-128` and `Image-128-vdc` are two checkouts of the same
repository (`Pinacolada64/Image-128`), not two projects:

- `Image-128-vdc` has the full tree, on branch `visual-editor`.
- `Image-128` is on branch `lightbar`; most feature branches are
  worktrees under `Image-128/.claude/worktrees/`.

`master` is the trunk. Several branches are well ahead of it and not
merged (see the end of this file); `visual-editor` matters most here,
because four of 3.1's fixes are ported only there.

## What Image 128 adds to 3.0

On `master`:

- **The 128 itself**: BASIC 7 string back-links kept by `putvar`,
  `putarr`, the struct module and `&,28` (`arrays.asm`); garbage
  collection by BASIC 7's own; `sub.stack` and `&,66,1` on BASIC 7's
  run-time stack; error names from `err$()`.
- **80 columns**: the VDC console, a two-page lightbar, the status line,
  `&,72` (VIC screen cells to the VDC), 40/80 column layouts in `im`,
  setup and the IM editors; 2 MHz for `++ net` in 80 columns.
- **New-system setup**: `i/su.config` rewritten as a menu of parts
  (`sub.su.*`): drives found by a bus scan, CMD partitions, clock method,
  copying the system files to the drives chosen.
- **Clocks**: `sub.clocks` at boot, on `Trc` and in Set Time (as 3.1),
  plus time zones and daylight saving rules (`s.timezones`,
  `s.dstrules`, IM Misc. Features H), alarms by weekday with their
  checkmark labels, `++ clock`.
- **IM**: Lightbar Labels editor (IM H), the lightbar help text read by
  `i/IM.lightbar`, Module Editors (as 3.1), `nimodem.dat` profiles
  (as 3.1), modem S2 as flag 13.
- **Idle screen**: keys from a table (`i.edit idlecmds`, 36-byte
  records), `T` to toggle carrier detect, `C`/`D`/`F` run `i.CP`, `i.RF`,
  `i.VF`; the stats box drawn by `i/lo.idle` (as 3.1).
- **Overlays ported**: `++ read`, `++ post`, `++ copier` (two drives),
  `++ visual` (with paging and dot commands), `++ net`, `++ path`,
  `++ netsub`, `++ netlist`, `++ chatmode` (Lt. Kernal stations).
- **Sysop tools**: `i.VL` (variables and arrays from bank 1), `i.MM`
  (memory per bank), `i/lo-sysop info`, `i/lo.logoff`, Today in History
  word-wrapped.
- **Docs and tools**: `PROGRAMMING.md`, `SYSOP_COMMANDS.md`,
  `DATA_FILES.md`, `NETWORK.md`, `DEBUG_TECHNIQUES.md`;
  `tools/diskcheck.py`, `urecord.py`, `today.py`, setup and NetMail
  tests under VICE.

On branches not merged yet: ANSI callers (`ansi-esc`, `ansi-cup`), C128
Esc codes for 128 callers (`visual-esc`), `++ remote` as a door
(`remote-overlay`), Lt. Kernal clock and copy (`ltk-clock`, `ltk-copy`),
the status line rework (`status-line`), the new-user redesign
(`new-user`), serial numbers at logon (`serial-registry`), and notes on
Xmodem-1K and ZMODEM.

## 3.1's changes: what Image 128 has

"Done" means on `master` unless it says `visual-editor`.

| 3.1 change | Image 128 |
|---|---|
| Clock set at boot, on `Trc`, IM K menu, 5-minute timeout, idle Set Time | Done |
| `i/lo.idle2` merged into `i/lo.idle` | Done |
| IM D Module Editors; sub-menus end in Main Menu | Done |
| IM J modem profiles (`nimodem.dat`) | Done |
| IM C Payroll Edit out of range | Done |
| `i.UU` cursor menu | Done |
| Feedback: No is quicker | Done |
| Boot: Reset asks Are You Sure; blocks free lined up | Done |
| `im` revision at boot | Done another way (the build stamp) |
| Ctrl/C= + function key lockup; keys up to 75 characters | Done |
| `++ copier` `&,16,3` (compare) | Done |
| `im` lines 32, 43, 370, 98; no "L:" in `cm$`; jump table 504-564 | Done |
| `i/IM.misc` range checks; `i/SM.make anagra`; `i/lo.misc` Set Time; IM K ?illegal quantity; module load ?file not open | Done |
| Sysop window's Area field clears longer names | `visual-editor` only |
| `sub.param1`: AT+, AT-, ATn, Return keeps the mode | `visual-editor` only |
| `i/MM.sb-post`: no `nm.origin` | `visual-editor` only |
| Mail files keep 14 characters of the handle; `i.rename mail` | `visual-editor` only |
| SuperCPU speed around transfers; `sub.turbo` | Doesn't apply: the 128 uses 2 MHz (`$d030`, lightbar mHz) |

## Still to port

Easiest first. Line numbers are the 128's.

| What | 128 now | 3.1 commit(s) | Notes |
|---|---|---|---|
| `i/SM.bu`: back up `e.cr.pool 1` | line 4032 has `e.cr.pool1` | f35d815 | One character. On 3.1's `sm-bu-cr-pool` branch, not `docs` yet |
| `i.lo`: AutoMaint with an empty `e.maintmods` | 3404 `goto 3216` | 22d1809 (the `i.lo` part) | 3216 becomes 3416 |
| Time-per-day limit of two digits | `im` 11 reads one digit | `im` line 11 | `mid$(fl$,a,1-(a=18))` |
| `im` 15: reset the output defaults after showing a file | `close 2:return` | 3.1's `im` line 15 | `goto 12` after the close |
| `im` 28: `cm$=a$+""` | `cm$=a$` | e036cd5 | A copy, not a pointer into the program text; matters more on the 128 |
| `im` 300: back to GF after a module | always `a$="main"` | 775c862 | `if pf then a$="GF"` |
| `sub.modem` loaded once | `i/lo.idle` 4106 loads it before `sub.info` (4112) | b75d1e8 | Run `sub.info` first; a line swap |
| `sub.local`: `ZZ` log date; Local Mode On/Off at the console | 60032 `hr$=d1$:&,15`; 60038 silent | c6f6f0c (`sub.local` part) | The `zq$` save isn't needed: the 128's `im` 370 keeps `an$` |
| `&,1` clears the password flags when input ends | `swap1.asm` `inline` falls into `inline0` with `passmode` set | 576534b | `jsr inline0 / lda #passmode_off / sta passmode / rts`; check swap1's room |
| Modules set `pr$`, `cm$`, `p$` as copies | done in `i.main`, `i.UU`, `i.edit idlecmds` only | b7a1ddf, 013ca9b | `i.CP`, `i.GF`, `i.IM`, `i.SF` and about 60 `p$="..."` literals left; a literal points into bank 0's program text |
| `i/lo.login`: L) Toggle Linefeeds, two options to a line; "Login ID" sentence | old menu (4104-4118); 4170/4172 still break the sentence | b8dc510, 2b7e33c | The `i/lo.on` sentence is done; the menu lines differ from 3.1's |
| General Files Maintenance Options | `i.GF` 3314 `goto 3306`; 3570/3572 save every prompt; `i/GF-maint` 4100 asks Which Option? | c6f6f0c | Moderate |
| `&,9` shows number variables as digits | `swap2.asm` `btmvar` handles strings only | 8b009a9 | Moderate (`intfout`, `numdesc`) |
| `i.UD`: a file's first comment on About; `i/MM.u/d/c` reads with `&,2,2`, writes with `&,14,2` | `get#`/`input#` | 3051c28 to 260077f | On 3.1's `ud-first-comment` branch, not `docs` yet |
| Convert from 1.2/2.0: `d.data` from `bd.data`; 1.2's `e.macros` | `sub.su.convert` needs `d.data` | 4d7ed2c, d400ade | Hard: the 128's setup is rewritten, and its boot file is `bd.data`, so the names are the other way round |
| `i.ED 3.1` (`i_ED-pina-mod`), `im.emul13` | the release's `i.ED` | f49675f, b587e8a, f274589 | Optional |
| `&,5`: version in `lp`, revision in `a%` | 1.0 in `lp`, `a%` not set | 7ce09d3 | Optional: decide what the 128's version number is |
| System error turns the border red only with `Trb` | `im` 4034's border change is a `rem` | — | Optional; the VIC border isn't seen in 80 columns |

Not ported, and probably not needed: 3.1's test programs (`i.tests`,
`i.test ...`, `i.btmvar table`); the 128 has `tests/standin/` and
`i.test esc`. `tagscan` isn't in the 128's ML.

## Branches to merge, on both sides

- **Image 128**: merging `visual-editor` brings in four of 3.1's fixes
  (above). `im-prime-time` and `term-phonebook-settings` (one commit
  each) match the 3.1 branches of the same names; neither side has
  merged them.
- **3.1**: `sm-bu-cr-pool` and `ud-first-comment` hold fixes listed
  above; port them once they're on `docs`, or from the branch.

## The other way: from Image 128 to 3.1

3.1's `TODO.md` lists these, all on Image 128's `master`:

- The Lightbar Labels editor (ff5b4c9; `i/IM.lightbar` 4400-4458, IM H
  item D) and the help text read in `i/IM.lightbar` (4090-4094).
- Alarm editor fixes (90dbbe7, 8f74146: `-` for `--:--`, option 2 goes
  to Off Time) and checkmark labels from `bartbl` (ef095df); alarms by
  weekday.
- Not in 3.1's TODO, but there to take: daylight saving rules
  (3fc4b10, d07c9a6) and `tools/diskcheck.py`.
- Neither has done: resyncing the alarms after a gap.
