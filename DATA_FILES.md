# Data Files

The files Image BBS 128 keeps on its disks besides its programs (`im 128`,
the ML, and the `i.`, `i/` and `sub.` modules): screens, tables, settings
and logs. They're Image 3.0's, and work the same way; the Image 3.0
manual's appendix "Data Files" lists them too.

This file says what each one is for. How some are laid out inside is
elsewhere: the `today.` files in PROGRAMMING.md ("Today in History
files"), and `e.data`, `e.menu` _n_, `s.m.protos` and `nm.P.count` in the
Image 3.0 Programmer's Reference Guide, appendix "File Formats".

## Where they are

A file's prefix says which of Image's drives it's on (`IM`, System
Drives):

| Prefix | Drive | Holds |
|---|---|---|
| `s.` | 1, System | screens, help menus |
| `f.`, `nm.log` | 2, E-Mail | mail waiting at login, the network log |
| `e.`, `today.`, `nm.times` | 3, Etcetera | tables, settings, logs |
| `d.` | 4, Directory | General Files libraries |
| `u.` | 6, User | the user records |

`bd.data` is on the boot disk: it says where the Etcetera drive is (where
`e.data` is), and holds the main prompt's text.

On the test setup (`start-image-128.sh`), drive 1 is device 9,
`build/s_files.d81`, and the other drives are device 8,
`build/setup-test.d81`, with the programs.

- **In the repo:** `disk/` has the tables the BBS loads at boot
  (`e.lightbar`, `e.lightdefs`, `e.printmodes`, `e.alarms`, `nm.times`,
  `e.ecs.main`, `e.fkeys`) and the twelve `today.` files, which
  `asm/build.sh` writes to `build/image128.d81` (`disk/README.md`).
- **Not in the repo:** the `s.` screens and the other shipped `e.` files.
  They're on the 3.0 release's `MASTER D2` disk; copy what you need with
  c1541, giving `,s` for a SEQ file (without it c1541 says "file not
  found"):
  `c1541 "MASTER D2 231231.d81" -read "s.welcome 1 80,s" "s.welcome 1 80"`,
  then `c1541 build/s_files.d81 -write "s.welcome 1 80" "s.welcome 1 80,s"`.
  Detach the disk in x128 first, and run `tools/diskcheck.py` on it before
  and after.
- **Created as the BBS runs:** the rest (marked _created_ below).

## Screens: `s.` files

Most screens come in versions for each kind of terminal, and for 80
columns: Image adds the caller's terminal mode (`nl`) to the name (`0`
ASCII, `1` Commodore colour and graphics, `2` ANSI), then `80` for an
80-column caller. `s.welcome 1 80` is the welcome screen for a Commodore
caller in 80 columns. The 128's console is 80 columns, so a local login
shows the `80` versions. Below, _n_ stands for the mode, and `[80]` for
the optional `80`. A screen that isn't on the disk is skipped.

### On the way in and out

| File | Shown | By |
|---|---|---|
| `s.login` _n_ `[80]` | before the Login Options menu | `i.lo` (3116) |
| `s.detect` _n_ `[80]` | after the terminal is detected, if "Use s.detect Files" is on (`i.LB`, option G) | `i.lo` (3562) |
| `s.lines/screen` | asks how many lines the caller's screen has, when that isn't set | `i/lo.on` (4030) |
| `s.welcome` _n_ `[80]` | after logging in, before the login modules | `i/lo.on` (4184) |
| `s.start 0`, `1`, `2` | never: `i/lo.on` (4183) asks C/G callers for `s.start` and the weekday's digit (`s.start4`), not these names | |
| `s.mail` | at login, when mail is waiting | `i/lo.mail` |
| `s.new user` | a new user's application, first | `i/lo.new` (4014) |
| `s.nu welcome` | the welcome letter `i.VF` sends a user it validates | `i.VF` (3154) |
| `s.end` _n_ `[80]` | at logoff, after "Bye" | `i.lo` (3202) |
| `s.logon help` | Help at the Login Options menu | `i/lo!help` |
| `s.tchkmail` | mailed to an account after a failed login on it | `i/lo!telecheck` |
| `s.errmail` | mailed to a caller whose call caused an error | `im 128` |

In Image 3.0, a missing `s.welcome` screen also skips every login module:
`i/lo.on` line 4192 tests `e%`, which the `e.loginmods` load (4190, a
KERNAL LOAD) doesn't set, so it still holds "file not found" from the
screen. Fixed here 10/29/2026: 4190 ends with `gosub 5`, which reads the
load's own status.

### Sections

| File | Shown | By |
|---|---|---|
| `s.EM` _n_ `[80]` | on entering E-Mail | `i.EM` |
| `s.SB` _n_ `[80]` | on entering the sub-boards | `i.SB` |
| `s.Sig` _s_ _n_ `[80]` | on entering SIG _s_ | `i/MM.load` |
| `s.UD` _n_ `[80]`, `s.UX` _n_ `[80]` | on entering U/D, U/X | `i.UD`, `i.UX` |
| `s.VF` _n_ `[80]` | on entering VF | `i.VF` |
| `s.FF`, `s.GF`, `s.UD`, `s.UX`, `s.VF` | title banners ("Image 3.0 File System"...): `s.` and the section's name | `im 128`, `i.GF` |
| `s.main 40`, `s.main 80` | the main menu: the sections, by their commands | |
| `s.chat 1`, `2`, `3` | in turn, when a chat page isn't answered | `i/C` |
| `s.editor` _n_ | the text editor's banner | `sub.editor` |
| `s.anagram` | the anagram game's instructions | `i/lo-anagram` |
| `s.pool` | the Credit Pool's instructions | `i/lo-cr pool` |
| `s.ps` | about personal signatures | `sub.misc2` |
| `s.nubbslist` | the BBS list | `i.BB` |
| `s.netmenu`, `s.netmenuzz` | the network menu, and its sysop options | `i.LN` |
| `s.today/hist` | Today in History (_created_ by `i/lo/today`; below) | `i/lo-today` |

### Help menus: `s.menu` _x_

| File | Menu |
|---|---|
| `s.menu 1` | the sub-systems (the main level's commands) |
| `s.menu 2` | message commands |
| `s.menu 3` | text editor commands |
| `s.menu 4` | the sysop's main-level commands |
| `s.menu 5` | upload/download commands |
| `s.menu 6` | E-Mail commands |
| `s.menu 7` | directory system commands |
| `s.menu 8` | end-of-message commands |
| `s.menu 9` | exchange (U/X) commands |
| `s.menu 10` | the days of the week (AutoMaint Mods) |
| `s.menu 12` | login commands |
| `s.menu t1` ... `t4` | Image Term's menus |

### Settings

| File | Shown | By |
|---|---|---|
| `s.m.info` | Personal Information | `sub.info` |
| `s.timezones` | the time zones to choose from | `sub.info` |
| `s.m.params`, `s.m.modes` | terminal parameters and modes | `sub.param1` |
| `s.m.protos`, `s.protos` | transfer protocols | `sub.protos` |
| `s.m.reledit` | SM's REL file editor | `i/SM.reledit` |
| `s.logon info` | the Login Editor's help | `i/IM.logon` |
| `s.lightdefs` | the lightbar checks' names, for the Lightbar editor | `i.IM` |

`s.config` (a "System Configuration" screen), `s.idle` (Image 2.0's idle
screen commands: `i/lo.idle` draws its own menu) and `s.netapp` (a network
application form) aren't opened by name by any module.

## Tables and settings: `e.` files

### Shipped on the release disk

| File | Type | Holds | Read by |
|---|---|---|---|
| `e.lightbar` | PRG | the lightbar's 64 three-letter labels | `im 128`, at boot |
| `e.lightdefs` | SEQ | the lightbar checks the BBS starts with | `im 128`, at boot; saved by `i/IM.lightbar` |
| `e.printmodes` | PRG | the MCI print modes | `im 128`, at boot |
| `e.alarms` | PRG | the alarm table | `im 128`, at boot; `i/IM.lightbar` |
| `nm.times` | PRG | the network alarm table | `im 128`, at boot; `i/IM.lightbar` |
| `e.ecs.main` | PRG | the Extended Command Set | `im 128`, at boot; `i/IM.ecs` |
| `e.fkeys` | SEQ | the sysop's function key macros | `im 128`, at boot; `i/IM.macros` |
| `e.modem` | PRG | the modem types to choose from | `i/IM.modem` |
| `e.termkeys` | SEQ | Image Term's keys | `i.t` |
| `e.say` | REL | sayings, picked at random (`e.say (small)`: a shorter set) | `im 128`; edited by `i/SM.sayedit` |
| `e.text` | REL | text, by record number | `im 128`; edited by `i/SM.textedit` |
| `e.errmsg` | REL | (not opened by name by any module) | |
| `today.Jan` ... `today.Dec` | SEQ | Today in History facts, a file a month (below) | `i/lo/today` |

### Created

| File | Type | Holds | Written by |
|---|---|---|---|
| `e.data` | REL | the system's settings, a record each | `i/su.config`, `IM` |
| `e.stats` | REL | the statistics (`st()`) | `im 128` |
| `e.daily stats` | REL | each day's statistics | `i/lo.automaint` |
| `e.access` | REL | the access groups | `IM` Access Groups (`i/IM.access`) |
| `e.last` | PRG | the last ten callers | `i/lo.on`, `i/lo.off` |
| `e.log1` ... `e.log7` | SEQ | the call log, one for each day of the week | `im 128`; restarted by `i/lo.automaint` |
| `e.logweek`, `e.logweek.prev` | SEQ | the week's log, and last week's | `i/lo.automaint` |
| `e.idle 1` ... `e.idle 7` | SEQ | idle and used time, one for each day of the week | `i.lo`; reset by `i/lo.automaint` |
| `e.idle cmds` | PRG | the idle screen's own commands | `i.edit idlecmds` |
| `e.loginmods` | PRG | the login modules | `IM` Login Mods (`i/IM.logon`) |
| `e.maintmods` | SEQ | the modules AutoMaint runs | `IM` AutoMaint Mods (`i/IM.logon`) |
| `e.sysoplist` | PRG | the accounts Instant Login offers | `i/IM.logon` |
| `e.macros` | REL | the macros | `IM` Macros Editor (`i/IM.macros`) |
| `e.i.modem` | REL | the modem's settings | `IM` Modem Config (`i/IM.modem`) |
| `e.menu` _n_ | PRG | graphic menus | `i.menuedit` |
| `e.anagram` | REL | the anagram game's words | `i/SM.make anagra` |
| `e.errlog` | SEQ | the errors the BBS has trapped | `im 128` |
| `e.zz log` | SEQ | who turned local maintenance on, and when (SYSOP_COMMANDS.md) | `sub.local` |

## Users, libraries and mail

| File | Drive | Holds |
|---|---|---|
| `u.config` | User | the user records (REL; `tools/urecord.py` reads and fixes one) |
| `u.index` | User | the handles, for finding a user |
| `u.weedinfo` | User | Autoweed's information |
| `u.payroll` | User | the credits paid out (`IM` Payroll Editor) |
| `d.` _library_ | Directory | a General Files library (`d.GF` ...) |
| `f.` _handle_ | E-Mail | mail for a user, shown at login (`i/lo-fmail`) |
| `nm.log` _n_ | E-Mail | the network log, one for each day of the week |
| `nm.P.count` | E-Mail | the dates, times and tracking numbers of network sub-board messages sent from this BBS |

## Today in History: `today.` _Mon_ and `s.today/hist`

Each night, AutoMaint's `i/lo/today` (from AutoMaint Mods) reads this month's
`today.` file from the Etcetera drive, picks out today's facts, and writes
them to `s.today/hist` on the System drive. The login module `i/lo-today`
shows `s.today/hist` to callers, each fact word-wrapped to their screen.
The file format is in PROGRAMMING.md ("Today in History files"), and
`tools/today.py` lists, checks and edits a `today.` file. `disk/` has the
twelve, with three mistakes in the release's fixed (`disk/README.md`).
