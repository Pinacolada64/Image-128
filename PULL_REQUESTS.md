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

Sections: Open PRs → Feature branches (no PR) → Direct commits to master →
Merged PRs → Merged branches (newest first).

Seeded 2026-11-17; updated 2026-11-17 against origin/master at `ba51bd4`.

---

## Open PRs

| PR | Branch | Tip | On | Summary |
|----|--------|-----|----|---------|
| [#9](https://github.com/Pinacolada64/Image-128/pull/9) | `border-color` | `5c42284` | | Border color on events (error red, new user green, feedback blue, failed login light blue) only while the lightbar's right `Dbg` is on: `im 128` line 24, `if a% then begin:color 4,a+1:bend`, called as `a=`*color*`:gosub 24` instead of `poke 53280`; PROGRAMMING.md and SYSOP_COMMANDS.md (its section after `IM` H, clear of #4/#5). Master merged in; `dd81599` was pushed with conflict markers in equates.asm, `7bbfc8e` takes them out (squash merge keeps them out of master). Not run in x128 yet. |
| [#7](https://github.com/Pinacolada64/Image-128/pull/7) | `ltk-primetime-test` | `a312d63` | | `tools/ltk_primetime.py`: IM's Prime Time screen tried on a configured system on VICE's Lt. Kernal (60 minutes, `12P`, `12A`, `1p`, `13`, saved, the Misc. Features line); `ltk_copy.py --images DIR`. |
| [#6](https://github.com/Pinacolada64/Image-128/pull/6) | `prime-indicator` | `75b47b2` | | `PRIME` down the screen's right edge, column `sw-1` (39 or 79), in `sub.display`, `i/lo.idle` and `i/lo.on`; master (#8) merged in, and `status.asm`'s 80-column row 19 stops at column 78 so `Buf` doesn't wipe it. |
| [#5](https://github.com/Pinacolada64/Image-128/pull/5) | `prime-time-wrap` | `c2d0a83` | `docs-im-sysop` | Prime Time can run past midnight (`im 128` line 84: an end before the start runs into the next morning); SYSOP_COMMANDS.md to match. Merge #4 first. |
| [#4](https://github.com/Pinacolada64/Image-128/pull/4) | `docs-im-sysop` | `c5034e9` | | SYSOP_COMMANDS.md: IM, the Configuration Editor: running it, the main menu `A`–`Q`, Misc. Features `A`–`O`, Prime Time (`12A`/`12P`, the `Tsr` checkmark). |

---

## Feature branches (no PR)

| Branch | Tip | On | Summary |
|--------|-----|----|---------|
| `pull-request-catalog` | (this file) | | This catalog, and `make docs` builds it as a PDF. |
| `docs-vice-features` | `3115b6e` | | DEBUG_TECHNIQUES.md, "Using features in VICE": the x128 switches the start scripts and tools pass, a table and a command line for each feature (machine and autostart, JiffyDOS ROMs, drives, DS12C887 RTC, SwiftLink and tcpser, Lt. Kernal, debugging). SYSOP_COMMANDS.md, "Running the BBS in VICE": the sysop's view (start-image-128.sh's switches, what to set in IM to match, settings, start-setup.sh, errors). Based on master at 2a57549 (Lt. Kernal and DST tools). |
| `pdf-table-autowidth` | `754e283` | | `tools/autowidth.lua`: `make docs`' tables get columns as wide as their contents need (from TADA's filter), instead of pandoc's widths from the dashes in the table's separator line; 0.2 em to spare in each column, so a word never breaks at its hyphen. |
| `docs-port-from-31` | `b6ab7e5` | | IMAGE_3_1.md: what Image 128 adds to 3.0, and 3.1's changes still to port; built as a PDF. Conflicts with master in the Makefile's `DOCS :=` line (keep both `STATUS_LINE.md` and `IMAGE_3_1.md`). |
| `lightbar-checks` | `ea0eac9` | | Which lightbar checkmarks are free (PROGRAMMING.md); check 49 goes to the status line's 40-column P=/V= swap; Em3 is "emulate 1.3"; page 4's first label becomes Prg. |
| `todo-clock-set-color` | `c6e14bb` | | TODO: the boot frame's colour after "...Clock Set." (sub.clocks clobbers c). |
| `ansi-cup` | `d1718c5` | `ansi-esc` | &,70: one CUP (Esc[row;colH) for an ANSI caller. |
| `ansi-esc` | `7c18c07` | `visual-editor` | outmod: Esc passes through in ANSI; PROGRAMMING.md: what ASCII/ANSI callers get. |
| `visual-esc` | `f52a870` | `visual-editor` | C128 Esc codes: the console checked (esctest), i.test esc for callers; ++ visual: Esc I / Esc D insert and delete a line; EP option 11 (C128 Esc Codes); tools/ep11_test.py. |
| `remote-overlay` | `712a574` | `visual-editor` | ++ remote: Image 2.0's remote.s, fixed and ported, runs a plain BASIC program as a door; DOOR runs i.remote door; tests/doors, door_test.py. |
| `term-phonebook-settings` | `683789d` | | i.t: graphics mode and BPS rate for each phone book entry. |
| `chatmode` | `56fddb3` | `visual-editor` | ++ chatmode: chat between Lt. Kernal stations, with a transcript (from Image 2.0's chatmode.asm); &,13's locks between stations; lockinit fix; ECS command LTK; logon/logoff mark the station online. Its own work is on master as cherry-picks adapted to a master without network and visual-editor under it (see Direct commits); the branch itself stays unmerged because of those two. |
| `chatmode-bbs-test` | `71f8e1f` | `chatmode`, `ltk-copy` | ++ chatmode in the whole BBS on two Lt. Kernal stations: ltk_bbs2.py (--user2, online at logon, offline after logoff); e.ecs.main: LTK's letters shifted. |
| `ltk-copy` | `4f40444` | `visual-editor` | Setup on the Lt. Kernal: boot from an LU, drives on LUs, the copy's dir read with &,8; i_su.config.lbl moved to modules/; tests/standin/ltkdos.bas. Carries chatmode (merged in). |
| `merge-master` | `121ff32` | `ltk-copy` | Merge of ltk-copy (network, visual-editor, chatmode, Lt. Kernal setup) toward master; TODO: new user setup asks for the U/D protocol and the editor. |
| `ecs-branch-fix` | `36a00d9` | | ecs: the definitions scan goes on to the next definition again. |
| `lo-misc` | `0c961ab` | | i/lo.misc: the system password and log menus reworked (work in progress). |
| `new-user` | `ada4c93` | `network` | i/lo.new: redesign started (work in progress); sub.param1 menus printed by the module, option 10 the editor; editor for ASCII callers; DATA_FILES.md: s.m.protos' format. |
| `visual-editor` | `985c34d` | `network` | ++ visual after its first merge (c303598): word wrap, End of Text marker, Up/Down and Ctrl-V stop at the end of the text, help from s.visual; sub.param1 menus in one or two columns; tools/visual_wf.py. |
| `ltk-clock` | `bcd9d0a` | `visual-editor` | ++ ltk clock: swr.ml relocated, the Lt. Kernal (DS1216 SmartWatch) clock on the 128; a DS1216 joyport device for VICE 3.8. |
| `network` | `11f98bd` | | Mail file names keep 14 characters of the handle; i.rename mail for 3.0's 13-character names; NETWORK.md: nm.origin; im line 9's Area field (begin/bend); & symbols output as quoter tokens; anagram fixes; TODO items. The whole network → visual-editor stack conflicts with master (mostly `disk/e.lightbar.prg`, `modules/TODO.md`, `asm/equates.asm`). |
| `xmodem-1k` | `012ccf8` | `network` | PORTING_NOTES.md: Xmodem-1K, a possibility for the 128. |
| `zmodem` | `828fd35` | `xmodem-1k` | PORTING_NOTES.md: ZMODEM, a possibility for the 128. |
| `serial-registry` | `b29ef87` | | Serial number at logon ("S# A0001"); tools/serial.py; owners DB design. Moves bsnpre/bsnval to `$0af5`. |
| `lightbar` | `db31ca4` | `editor-scale` | 2024 lightbar work: '64 3.0-style labels, theming, monochrome theme, clock seconds on the screen mask, opening instructions, Help key detection. Against master it would add only asm/lightbar.asm, tests/clock-basic.lbl, tests/print-cols.asm and c64list-to-vice-labels.py. Local and origin have diverged from `7c5d01e`: local has `c6f7b02` (notes about lightbar slots), origin has `31a53bd` and `db31ca4` (clock display fixes). |
| `clocks-ultimate-write` | `985c34d` | `visual-editor` | No commits of its own yet (created at `visual-editor`'s tip; checked out in Image-128-vdc). Local. |
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
| [#8](https://github.com/Pinacolada64/Image-128/pull/8) | `ba51bd4` | `status-line` | `adada09` | Status line rework (28 commits): `draw_status_line` (`asm/status.asm`) for 40 and 80 columns, RX/TX windows moved there; 80 columns' row 22 `C= N= U= I= P= V= L= M=`, the system box, `&,9`'s window at columns 64–79; 40 columns' `V=`, check 49's `P= V=` swap, `Prg` and `Dbg` labels; STATUS_LINE.md, built as a PDF. Merged 2026-11-17. |
| [#3](https://github.com/Pinacolada64/Image-128/pull/3) | `7d89fe7` | `ltk-copy-files` | `4a0c176` | `tools/ltk_copy.py`: copy files onto an LU of VICE's Lt. Kernal (`tests/standin/ltkcopy.bas` with `++ copier`, compared after; `--save` writes back only changed images, keeping the old ones). Merged 2026-11-17. |
| [#2](https://github.com/Pinacolada64/Image-128/pull/2) | `d0d9b62` | `im-prime-time` | `5f9e218` | Prime Time in IM shown as ` 60, 1A-9A` from `p1%`-`p3%`; `12A`/`12P` typed and shown right (`12P` was stored as 24 and never matched); `i.IM` 3365 split. Merged 2026-11-17. |

---

## Merged branches

| Branch | Merged as | Tip | Summary |
|--------|-----------|-----|---------|
| `ultimate-set-time` | `bcb1fcf`, `87d1590` | `7e83cab` | sub.clocks im=16 writes the BBS clock to an Ultimate (UCI SET_TIME `$27`), from the on...goto list; i.test clocks ported from ImageBBS3 with the Ultimate's read and write, and how to run it; PROGRAMMING.md and SYSOP_COMMANDS.md. Merged 2026-11-17 (twice: the second brings the on...goto fix). |
| `dst-status` | `2a57549` | `d88df38` | DST Rules (IM, I, H): the clock's DST state, F (flags) and C (check); SYSOP_COMMANDS.md: the menu path, set back for southern rules. Merged 2026-11-16. |
| `dst-setback-flag` | `75fcb77` | `4f2624d` | DST: set the clock back once only (e.data record 46's set-back flag); im 3155's d1$ for the boot's DST check; tools/dst_test.py. Merged 2026-11-16. |
| `visual-editor` | `c303598` | `a9ff89d` | ++ visual: the visual editor, ported from 3.0, with paging and dot commands. Merged 2026-11-09; the branch has gone on since (above). |
| `setup-menu` | fast-forward | `5f971bf` | Setup: copy the system files to the drives chosen (sub.su.copy), failures to setup.log; ++ copier between two drives; strrest fix. |
| `net-overlays` | fast-forward | `2d8576c` | ++ net at 2 MHz in 80 columns; ++ net, ++ copier and ++ 2 counters on the VDC (&,72); i.SB crunched; mHz checkmarks. |
| `alarm-weekdays` | fast-forward | `c47fb17` | Alarms by weekday, each checkmark shown with its label; docs for alarms and daylight saving time. |
| `daylight-saving-time` | fast-forward | `8f74146` | Daylight saving time: rules per time zone, and the clock changed for it; IM Misc. Features H: DST Rules editor; sub.info time zone list. |
| `vdc-display` | fast-forward | `760564b` | i.IM H: Lightbar Labels, an editor for the lightbar's 64 labels; docs for IM H. |
