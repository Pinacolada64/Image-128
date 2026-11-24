# Pull Request Catalog

A running index of pull requests and feature branches: identifier (PR number
and/or tip commit), name, and a short summary of what the change adds or fixes.

- **PR data** comes from GitHub (`gh pr list --state all`); it is independent of
  which local branch this file lives on. Branches merged before PR #2 were
  merged into master locally (Merged branches, below).
- **Branch data** comes from the branches on GitHub (`origin/*`) against
  origin/master; a local master can be behind it. "On" names the unmerged
  branches a branch is stacked on, whose commits it carries too; "local" means
  not pushed to GitHub.
- When a branch gets a PR, is merged or is pushed, move its row and update its
  tip, the same way as TADA's PULL_REQUESTS.md.
- Merge dates from #6 on are GitHub's (UTC), a day ahead of the Pacific
  evening a PR was merged in.

Sections: Open PRs → Feature branches (no PR) → Direct commits to master →
Merged PRs → Merged branches (newest first).

Seeded 2026-11-17; updated 2026-11-24 against origin/master at `12f9f9a`
(all 42 PRs merged).

---

## Open PRs

None.

---

## Feature branches (no PR)

| Branch | Tip | On | Summary |
|--------|-----|----|---------|
| `empire` | `a25794c` | | Empire 6 for Image 128 (from Image 1.2's, `games/empire6/`): the game playable through a turn, many 1.2 bugs fixed, word wrap and comma'd numbers, Empire II's quests and five new stats (horses, timber, spices, cannons, forts), `i.empire` on C64List 4.06 for BASIC 7.0 (`tools/to406.py`), `sub.plural`/`sub.count_noun`, the Centipede-to-Image table (`games/empire6/centipede-to-image.md`); its own `TODO`. Work in progress. |
| `lo-on-banners` | `fdc64ed` | | `i/lo.on`: the three reversed banners fill the line in 40 and 80 columns. |
| `amp27-levels` | `de145f9` | | `&,27`/`&,28` levels: a PROGRAMMING.md section with diagrams, the `arrays27` stand-in test; docs PDFs' SVG figures through prawn-svg. |
| `visual-esc` | `2f38c04` | | C128 Esc codes: the console checked (esctest), `i.test esc` for callers; `++ visual`: Esc I / Esc D insert and delete a line; EP option 11 (C128 Esc Codes, `uf$` flag 5); `tools/ep11_test.py`; PROGRAMMING.md: `uf$`, the caller's terminal settings. Now on master alone (`visual-editor` is merged). |
| `test-calls-more` | `ec2a00c` | | `i.test calls`: a test or demo of every `&` call; the handlers in four `i/` sub-modules (more than #26 has). |
| `docs-idle-10min` | `d5dab67` | | SYSOP_COMMANDS.md: the idle screen's 10-minute checks; when Prime Time is checked. |
| `docs-vice-features` | `3115b6e` | | DEBUG_TECHNIQUES.md, "Using features in VICE": the x128 switches the start scripts and tools pass, a table and a command line for each feature (machine and autostart, JiffyDOS ROMs, drives, DS12C887 RTC, SwiftLink and tcpser, Lt. Kernal, debugging). SYSOP_COMMANDS.md, "Running the BBS in VICE": the sysop's view (start-image-128.sh's switches, what to set in IM to match, settings, start-setup.sh, errors). Based on master at 2a57549 (Lt. Kernal and DST tools). |
| `docs-port-from-31` | `b6ab7e5` | | IMAGE_3_1.md: what Image 128 adds to 3.0, and 3.1's changes still to port; built as a PDF. Conflicts with master in the Makefile's `DOCS :=` line (keep both `STATUS_LINE.md` and `IMAGE_3_1.md`). |
| `lightbar-checks` | `ea0eac9` | | Which lightbar checkmarks are free (PROGRAMMING.md); check 49 goes to the status line's 40-column P=/V= swap; Em3 is "emulate 1.3"; page 4's first label becomes Prg. |
| `todo-clock-set-color` | `c6e14bb` | | TODO: the boot frame's colour after "...Clock Set." (sub.clocks clobbers c). Fixed by #31: delete. |
| `ansi-cup` | `d1718c5` | `ansi-esc` | &,70: one CUP (Esc[row;colH) for an ANSI caller. Superseded by #11 (merged): delete. |
| `ansi-esc` | `7c18c07` | | outmod: Esc passes through in ANSI; PROGRAMMING.md: what ASCII/ANSI callers get. Superseded by #11 (merged): delete. |
| `remote-overlay` | `712a574` | | ++ remote: Image 2.0's remote.s, fixed and ported, runs a plain BASIC program as a door; DOOR runs i.remote door; tests/doors, door_test.py. Now on master alone (`visual-editor` is merged). |
| `merge-master` | `121ff32` | | Merge of ltk-copy (network, visual-editor, chatmode, Lt. Kernal setup) toward master; TODO: new user setup asks for the U/D protocol and the editor. Its branches are merged (#16); only the TODO item is its own. |
| `ecs-branch-fix` | `36a00d9` | | ecs: the definitions scan goes on to the next definition again. |
| `lo-misc` | `0c961ab` | | i/lo.misc: the system password and log menus reworked (work in progress). |
| `new-user` | `ada4c93` | | i/lo.new: redesign started (work in progress); sub.param1 menus printed by the module, option 10 the editor; editor for ASCII callers; DATA_FILES.md: s.m.protos' format. Now on master alone (`network` is merged). |
| `ltk-clock` | `bcd9d0a` | | ++ ltk clock: swr.ml relocated, the Lt. Kernal (DS1216 SmartWatch) clock on the 128; a DS1216 joyport device for VICE 3.8. Now on master alone (`visual-editor` is merged). |
| `zmodem` | `828fd35` | | PORTING_NOTES.md: ZMODEM, a possibility for the 128. Now on master alone (`xmodem-1k` is merged, #28). |
| `serial-registry` | `b29ef87` | | Serial number at logon ("S# A0001"); tools/serial.py; owners DB design. Moves bsnpre/bsnval to `$0af5`. |
| `lightbar` | `db31ca4` | `editor-scale` | 2024 lightbar work: '64 3.0-style labels, theming, monochrome theme, clock seconds on the screen mask, opening instructions, Help key detection. Against master it would add only asm/lightbar.asm, tests/clock-basic.lbl, tests/print-cols.asm and c64list-to-vice-labels.py. Local and origin have diverged from `7c5d01e`: local has `c6f7b02` (notes about lightbar slots), origin has `31a53bd` and `db31ca4` (clock display fixes). |
| `clocks-ultimate-write` | `985c34d` | | No commits of its own yet (created at `visual-editor`'s tip, now merged; checked out in Image-128-vdc). Local. |
| `editor-scale` | `2dfd9ba` | | 2023: tests/print-cols.asm, `.# Scale` printing a ruler as wide as the caller's terminal (work in progress). On GitHub only, no local branch. |

---

## Direct commits to master (no PR)

| Commit | Summary |
|--------|---------|
| `11eaf32`..`b5c05d0` | `chatmode`'s ++ chatmode, &,13, lockinit, LTK and logon/logoff commits, cherry-picked onto master and adapted to it (11 commits), ending with the Lt. Kernal chat TODO items (++ chatmode, the parked notice, Lt. Kernal in x128). |

---

## Merged PRs

| PR | Merge commit | Branch | Tip | Summary |
|----|--------------|--------|-----|---------|
| [#43](https://github.com/Pinacolada64/Image-128/pull/43) | `12f9f9a` | `pr-catalog-41-42` | `05b0add` | This catalog: #41 and #42. Merged 2026-11-24 |
| [#42](https://github.com/Pinacolada64/Image-128/pull/42) | `25b459f` | `todo-widest-array` | `e4358c7` | modules/TODO.md: `&,15,8` on any string array (`&,15,8,s,n,tt$(0)` or `,bb$(0)`, the user's idea), so `sub.columns` can list more than `tt$()`; how, and what `columns.lbl`'s own printing would need. Merged 2026-11-24 |
| [#41](https://github.com/Pinacolada64/Image-128/pull/41) | `0ff448f` | `pr-catalog-38-40` | `9ca040e` | This catalog: #38-#40. Merged 2026-11-24 |
| [#40](https://github.com/Pinacolada64/Image-128/pull/40) | `ef548a4` | `output-bench` | `1075129` | `i.test calls` 77: the same 1000 characters printed five ways (`print`, `&` plain, with colors, with MCI, with word wrap), timed at 1 MHz and 2 MHz, with a warning first in 40 columns (FAST blanks the VIC); PORTING_NOTES.md "How fast `&` output is": the screen editor is 64-72% of plain `&`, FAST x2.2, 80 columns slower than 40 (199 against 281 characters a second). No speedups made. Merged 2026-11-24 |
| [#39](https://github.com/Pinacolada64/Image-128/pull/39) | `b1ff6c3` | `columns-using` | `c5e2af3` | `columns.lbl` with `PRINT USING` and `&,15,9` tried and found slower (17.7 against 16.7 s; recorded in its comments); kept: `tools/basic7.py` reads `{include:}`d files, `&,15,9` keeps 255 characters (was 128), `sub.param1`'s `xor` accident given its space. Merged 2026-11-24 |
| [#38](https://github.com/Pinacolada64/Image-128/pull/38) | `d765b76` | `pr-catalog-35-37` | `1760814` | This catalog: #35-#37. Merged 2026-11-24 |
| [#36](https://github.com/Pinacolada64/Image-128/pull/36) | `fa65efe` | `docs-gaps` | `a9ea425` | Docs filled in and one manual: SYSOP_COMMANDS.md (the boot screen, the modem's escape character S2 and `J`, the file transfer protocols, Image Terminal's phone book settings), PROGRAMMING.md (`i.test calls`, `i.test clocks`); new chapters `NEW_IN_128.md` (New in Image 128), `INSTALLING.md` (setting up: `RUN "BOOT 128"`, 40/80 columns fixed at boot, the parts, the file copy, and what it doesn't copy yet: System, Etcetera and REL files), `VISUAL_EDITOR.md` (`++ visual`, alpha) and `PRINT_USING.md` (a tutorial on `PRINT USING`, `PUDEF` and `&,15,9`, each result checked in x128); `make manual`: one PDF of them all (76 pages); modules/TODO.md: switching 40/80 columns while running. Merged 2026-11-24 |
| [#37](https://github.com/Pinacolada64/Image-128/pull/37) | `fee1804` | `print-using` | `0ce4e3c` | `&,15,9`: what BASIC prints on the screen caught in `a$` (`&,15,9,1[,s$]`), so BASIC 7.0's `PRINT USING` formats for `&` output (`asm/using.asm`, a test in `out`; buffer $3f80-$3fff); `tools/basic7.py`: a 4.04 module that uses BASIC 7.0's keywords is built from a 4.06 copy (`to406.py`'s conversion, `{number:}` for numeric labels), and keywords hidden in crunched code stop the build; `i.test calls` 76. Merged 2026-11-24 |
| [#35](https://github.com/Pinacolada64/Image-128/pull/35) | `65e3358` | `docs-catalog` | `fe90ba2` | This catalog brought up to #34 against `85c9771`; PROGRAMMING.md's "Lists in columns" for `columns.lbl` (#30). Merged 2026-11-24 |
| [#11](https://github.com/Pinacolada64/Image-128/pull/11) | `85c9771` | `ansi-esc-cup` | `a4f819f` | `ansi-esc` and `ansi-cup` rebased onto master: outmod lets Esc through for ANSI callers (flag 18), so modules can send `Esc[L`, `Esc[K`...; `&,70` sends one `Esc[row;colH` instead of Home, Downs and Rights; PROGRAMMING.md, "What an ASCII or ANSI caller gets"; `tests/standin/ansiout.bas`, `tools/ansiout.py`; TODO: `AT` to show an ANSI test page. Master merged in first (PROGRAMMING.md: both sides' sections kept); built and booted. Merged 2026-11-24. |
| [#29](https://github.com/Pinacolada64/Image-128/pull/29) | `43f5ddf` | `punter` | `2543a46` | `++ punter` for the 128: assembled, built, tried between two x128s (`tools/punterpair.py`): Punter, Relaxed Punter, Image 1.3 Punter. Master merged in after #28 (both overlays kept in build.sh, DATA_FILES.md, TODO, the stand-in README); built with both. Merged 2026-11-24. |
| [#28](https://github.com/Pinacolada64/Image-128/pull/28) | `ffa9fcb` | `xmodem-1k` | `7f30742` | `++ xmodem` for the 128, with Xmodem-1K offered (`xmodem21` in `s.m.protos`, falling back to 128 bytes when the receiver asks for checksums); `tools/xmodem_test.py` in 40 and 80 columns. Merged 2026-11-24. |
| [#26](https://github.com/Pinacolada64/Image-128/pull/26) | `43daad6` | `test-calls` | `0cc2582` | `i.test calls`: 3.0's `&` call tester for Image 128, with demos of the new functions. Merged 2026-11-24. |
| [#20](https://github.com/Pinacolada64/Image-128/pull/20) | `2514843` | `em-path-status` | `15137f9` | `i.EM`, `i.NM_utils`: a failed load of `++ path` is seen (`gosub 5` after `gosub 28`). Merged 2026-11-24. |
| [#12](https://github.com/Pinacolada64/Image-128/pull/12) | `cf3fc61` | `term-phonebook-settings` | `683789d` | i.t: each phone book entry keeps a graphics mode (PETASCII/ASCII/ANSI) and BPS rate (300-38400), asked after its number in `E`, in `s%(24,n)` (0 = not set, as older e.phone files have). Dialing sets the mode before the modem is used (3372) and the rate before each `atdt` (3600); flag 16 restored on connect. Merged 2026-11-24. |
| [#10](https://github.com/Pinacolada64/Image-128/pull/10) | `3c65d55` | `pull-request-catalog` | `3b13cd3` | This catalog, and `make docs` builds it as a PDF; carries `pdf-table-autowidth` (tables sized to their contents). Merged 2026-11-24. |
| [#9](https://github.com/Pinacolada64/Image-128/pull/9) | `2554530` | `border-color` | `5c42284` | Border color on events (error red, new user green, feedback blue, failed login light blue) only while the lightbar's right `Dbg` is on: `im 128` line 24, called as `a=`*color*`:gosub 24` instead of `poke 53280`; PROGRAMMING.md and SYSOP_COMMANDS.md. Merged 2026-11-24. |
| [#7](https://github.com/Pinacolada64/Image-128/pull/7) | `209b648` | `ltk-primetime-test` | `a312d63` | `tools/ltk_primetime.py`: IM's Prime Time screen tried on a configured system on VICE's Lt. Kernal (60 minutes, `12P`, `12A`, `1p`, `13`, saved, the Misc. Features line); `ltk_copy.py --images DIR`. Merged 2026-11-24. |
| [#34](https://github.com/Pinacolada64/Image-128/pull/34) | `1a1c70d` | `btmvar-x` | `c0ecc18` | `&,9`: the variable's number kept in `.x` for `usevar` (`btmvar` set the window's address through `.x` since 11/16, so `&,9` showed another variable; the computer type after logon came out blank). Merged 2026-11-24. |
| [#33](https://github.com/Pinacolada64/Image-128/pull/33) | `39726d8` | `version-128` | `5eb2be4` | Image's own version on screen: "Image BBS 128 v1.0" / "Image 128 v1.0" for "V3.0" in the menu headers, the macro editor, Auto-Maintenance and `VE`; other programs' versions left as they are. Merged 2026-11-24. |
| [#32](https://github.com/Pinacolada64/Image-128/pull/32) | `e9d1862` | `blocks-free-escq` | `02aed19` | The boot's blocks-free list: Esc Q after each count; each drive's device,drive and type (`sub.sysdos` im=2's bus scan: 1541/1571/1581, CMD HD/FD, RAMLink, RAMDrive, Lt. Kernal). Merged 2026-11-24. |
| [#31](https://github.com/Pinacolada64/Image-128/pull/31) | `fbedf58` | `clock-set-color` | `0e0512d` | The boot frame after "Clock Set." in its own colour: `c=$8f` again before `gosub 3405` (`sub.clocks` uses `c` as a temporary). Merged 2026-11-24. |
| [#30](https://github.com/Pinacolada64/Image-128/pull/30) | `fb0b486` | `sub-columns` | `e9498ea` | `columns.lbl`: `sub.columns`' routine as an include, which `sub.info` and `sub.param1` call themselves (no load of `sub.columns`, no reload of the caller); item numbers padded by MCI; `s.timezones` colored in the file (`tools/dstfiles.py`), so `sub.info` doesn't join colors on for every zone. The time zone list: 17.8 s to its first pause before, 12-13 s after. Merged 2026-11-24. |
| [#27](https://github.com/Pinacolada64/Image-128/pull/27) | `98862ab` | `amp-call-fixes` | `e0803ca` | `&,20`, `&,21` and `&,26`: fixes found by `i.test calls`. Merged 2026-11-21. |
| [#25](https://github.com/Pinacolada64/Image-128/pull/25) | `34fc877` | `ml-under-io` | `0f0219b` | `&,15,7` and `&,15,8` run from bank 0's RAM under I/O (`$d000`, `cfg_io`). Merged 2026-11-20. |
| [#24](https://github.com/Pinacolada64/Image-128/pull/24) | `3fda0a6` | `and15-widest` | `1653d8c` | `&,15,8,s,n`: the widest visible width among `tt$(1)`-`tt$(n)`, for `sub.columns`. Merged 2026-11-20. |
| [#23](https://github.com/Pinacolada64/Image-128/pull/23) | `40ed6cb` | `sub-columns` | `143fa15` | `sub.columns`: lists in 1-4 columns for `ll%`; time zones and protocols use it. Merged 2026-11-20. |
| [#22](https://github.com/Pinacolada64/Image-128/pull/22) | `7e2342f` | `and15-center` | `7fca081` | `&,15,7`: center a string for `ll%`; the MCI tab counts the caller's columns. Merged 2026-11-20. |
| [#21](https://github.com/Pinacolada64/Image-128/pull/21) | `275b410` | `ml-akstr-rebuild` | `14e42cf` | `ak$` follows `ll%` (the ML's `akfix`); console logins use `sw` for `ll%`. Merged 2026-11-20. |
| [#19](https://github.com/Pinacolada64/Image-128/pull/19) | `520a111` | `tools-modem-option` | `253e5ce` | `ltk_bbs2.py`, `visual_wf.py`: `--modem`, a SwiftLink with tcpser as its modem. Merged 2026-11-19. |
| [#18](https://github.com/Pinacolada64/Image-128/pull/18) | `846d3ce` | `chatmode-lk-check` | `2ae0bbd` | `++ chatmode`: load it only with a Lt. Kernal configured (`lk%`); `lq%` gone. Merged 2026-11-19. |
| [#17](https://github.com/Pinacolada64/Image-128/pull/17) | `875a1fd` | `build-parallel` | `3f3c87a` | `build.sh`: compile in parallel, JOBS at a time (574 s to 50 s). Merged 2026-11-19. |
| [#6](https://github.com/Pinacolada64/Image-128/pull/6) | `215a602` | `prime-indicator` | `75b47b2` | `PRIME` down the screen's right edge, column `sw-1` (39 or 79), in `sub.display`, `i/lo.idle` and `i/lo.on`; `status.asm`'s 80-column row 19 stops at column 78 so `Buf` doesn't wipe it. Merged 2026-11-19. |
| [#16](https://github.com/Pinacolada64/Image-128/pull/16) | `1d5c049` | `ltk-bbs-latest` | `40908a4` | Lt. Kernal BBS: `chatmode-bbs-test` merged with master (boot from the Lt. Kernal, `++ chatmode`, LTK); brought in `network`, `visual-editor`, `chatmode`, `ltk-copy` and `chatmode-bbs-test` (Merged branches). Merged 2026-11-18. |
| [#15](https://github.com/Pinacolada64/Image-128/pull/15) | `78d1019` | `ltk-copy-im128` | `7b88491` | `ltk_copy.py`: "im 128" copies the real `im`, not the stand-in. Merged 2026-11-18. |
| [#14](https://github.com/Pinacolada64/Image-128/pull/14) | `002e508` | `im-modem-flag-dispatch` | `c6a661d` | IM modem: flags 1-12 open their own prompt, not flag 13's S2. Merged 2026-11-18. |
| [#13](https://github.com/Pinacolada64/Image-128/pull/13) | `9f1998b` | `docs-dcd-dsr` | `1f6c8e8` | Docs: carrier detect in VICE is Dsr on, Dcd off, no tcpser `-I`. Merged 2026-11-18. |
| [#5](https://github.com/Pinacolada64/Image-128/pull/5) | `52f2cf4` | `prime-time-wrap` | `c2d0a83` | Prime Time can run past midnight (`im 128` line 84: an end before the start runs into the next morning); SYSOP_COMMANDS.md to match. Merged 2026-11-17, after #4. |
| [#4](https://github.com/Pinacolada64/Image-128/pull/4) | `db89726` | `docs-im-sysop` | `c5034e9` | SYSOP_COMMANDS.md: IM, the Configuration Editor: running it, the main menu `A`–`Q`, Misc. Features `A`–`O`, Prime Time (`12A`/`12P`, the `Tsr` checkmark). Merged 2026-11-17. |
| [#8](https://github.com/Pinacolada64/Image-128/pull/8) | `ba51bd4` | `status-line` | `adada09` | Status line rework (28 commits): `draw_status_line` (`asm/status.asm`) for 40 and 80 columns, RX/TX windows moved there; 80 columns' row 22 `C= N= U= I= P= V= L= M=`, the system box, `&,9`'s window at columns 64–79; 40 columns' `V=`, check 49's `P= V=` swap, `Prg` and `Dbg` labels; STATUS_LINE.md, built as a PDF. Merged 2026-11-17. |
| [#3](https://github.com/Pinacolada64/Image-128/pull/3) | `7d89fe7` | `ltk-copy-files` | `4a0c176` | `tools/ltk_copy.py`: copy files onto an LU of VICE's Lt. Kernal (`tests/standin/ltkcopy.bas` with `++ copier`, compared after; `--save` writes back only changed images, keeping the old ones). Merged 2026-11-17. |
| [#2](https://github.com/Pinacolada64/Image-128/pull/2) | `d0d9b62` | `im-prime-time` | `5f9e218` | Prime Time in IM shown as ` 60, 1A-9A` from `p1%`-`p3%`; `12A`/`12P` typed and shown right (`12P` was stored as 24 and never matched); `i.IM` 3365 split. Merged 2026-11-17. |

---

## Merged branches

| Branch | Merged as | Tip | Summary |
|--------|-----------|-----|---------|
| `pdf-table-autowidth` | in #10 | `754e283` | `tools/autowidth.lua`: `make docs`' tables get columns as wide as their contents need (from TADA's filter), instead of pandoc's widths from the dashes in the table's separator line; 0.2 em to spare in each column, so a word never breaks at its hyphen. Merged 2026-11-24. |
| `chatmode-bbs-test` | in #16 | `71f8e1f` | ++ chatmode in the whole BBS on two Lt. Kernal stations: ltk_bbs2.py (--user2, online at logon, offline after logoff); e.ecs.main: LTK's letters shifted. Merged 2026-11-18. |
| `ltk-copy` | in #16 | `4f40444` | Setup on the Lt. Kernal: boot from an LU, drives on LUs, the copy's dir read with &,8; i_su.config.lbl moved to modules/; tests/standin/ltkdos.bas. Merged 2026-11-18. |
| `chatmode` | in #16 | `56fddb3` | ++ chatmode: chat between Lt. Kernal stations, with a transcript (from Image 2.0's chatmode.asm); &,13's locks between stations; lockinit fix; ECS command LTK; logon/logoff mark the station online (also cherry-picked earlier: Direct commits). Merged 2026-11-18. |
| `visual-editor` | `c303598`, then in #16 | `985c34d` | ++ visual: the visual editor, ported from 3.0, with paging and dot commands (`c303598`, 2026-11-09); then word wrap, End of Text marker, Up/Down and Ctrl-V stop at the end of the text, help from s.visual; sub.param1 menus in one or two columns; tools/visual_wf.py (#16, 2026-11-18). |
| `network` | in #16 | `11f98bd` | Mail file names keep 14 characters of the handle; i.rename mail for 3.0's 13-character names; NETWORK.md: nm.origin; im line 9's Area field (begin/bend); & symbols output as quoter tokens; anagram fixes; TODO items. Merged 2026-11-18. |
| `ultimate-set-time` | `bcb1fcf`, `87d1590` | `7e83cab` | sub.clocks im=16 writes the BBS clock to an Ultimate (UCI SET_TIME `$27`), from the on...goto list; i.test clocks ported from ImageBBS3 with the Ultimate's read and write, and how to run it; PROGRAMMING.md and SYSOP_COMMANDS.md. Merged 2026-11-17 (twice: the second brings the on...goto fix). |
| `dst-status` | `2a57549` | `d88df38` | DST Rules (IM, I, H): the clock's DST state, F (flags) and C (check); SYSOP_COMMANDS.md: the menu path, set back for southern rules. Merged 2026-11-16. |
| `dst-setback-flag` | `75fcb77` | `4f2624d` | DST: set the clock back once only (e.data record 46's set-back flag); im 3155's d1$ for the boot's DST check; tools/dst_test.py. Merged 2026-11-16. |
| `setup-menu` | fast-forward | `5f971bf` | Setup: copy the system files to the drives chosen (sub.su.copy), failures to setup.log; ++ copier between two drives; strrest fix. |
| `net-overlays` | fast-forward | `2d8576c` | ++ net at 2 MHz in 80 columns; ++ net, ++ copier and ++ 2 counters on the VDC (&,72); i.SB crunched; mHz checkmarks. |
| `alarm-weekdays` | fast-forward | `c47fb17` | Alarms by weekday, each checkmark shown with its label; docs for alarms and daylight saving time. |
| `daylight-saving-time` | fast-forward | `8f74146` | Daylight saving time: rules per time zone, and the clock changed for it; IM Misc. Features H: DST Rules editor; sub.info time zone list. |
| `vdc-display` | fast-forward | `760564b` | i.IM H: Lightbar Labels, an editor for the lightbar's 64 labels; docs for IM H. |
