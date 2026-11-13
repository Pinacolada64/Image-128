# Programming Image BBS 128 in BASIC

Notes for writing `im` code, modules and test programs that run under
Image BBS 128: things BASIC 7.0 does differently from the C64's BASIC 2,
and how Image's own parts fit around them. Each was tried on an x128
running Image; `tests/standin/gosub.bas` and `tests/standin/mask.bas`
are the programs. What changed in the port itself is in
`PORTING_NOTES.md`; the ML's own BASIC variables (`rc`, `kp%`, `sh`...)
in `BASIC_VARIABLES.md`.

## Where BASIC is

| | 128 | (C64) |
|---|---|---|
| current line, `curlin` | `peek(59)+peek(60)*256` (`$3b`/`$3c`) | 57/58 |
| text pointer, `txtptr` | `$3d`/`$3e` (61/62) | 122/123 |
| BASIC's stack pointer | `peek(125)+peek(126)*256` (`$7d`/`$7e`) | (the CPU's) |

In direct mode the line's high byte is `$ff` (65280 and up). In `.lbl`
files, write the names: `{sym:curlin}`, `{sym:txtptr}`, `{sym:bstkptr}`
(`asm/equates.asm`).

## Errors

### Image's trap: `&,37` on, `&,38` off

`im` turns it on at boot. On an error, Image's trap (`wtrap`,
`asm/wedge.asm`):

- saves the error number in `peek(6)` and its line in
  `peek(7)+peek(8)*256` (`sareg`, `sxreg`/`syreg`; C64 780-782),
- empties both stacks, the CPU's and BASIC 7.0's, as CLR does, and the
  temporary string stack,
- puts BASIC's `bank` back to 15 (see [Reading the variables: `bank`](#reading-the-variables-bank)),
- turns itself off (it puts BASIC's own error vector back), and
- goes to line 2000 (`trapline`).

`im`'s line 2000 prints the error ("[Error#.., Line#..]"), closes the
files, loads `im` again and carries on at 4000, Image's error handler,
which logs it. Since the trap is off once it has fired, an error in the
handler before `im` turns it on again stops the program with BASIC's own
message.

### RESUME doesn't work with Image's trap

BASIC 7.0's `resume`, `resume next` and `resume <line>` need what its own
`trap` saved at the error; Image's trap doesn't save it, and has already
emptied the stacks. Under `&,37`, a `resume` gives `?can't resume error`
(and, the trap being off by then, stops the program).

So, in a handler that Image's trap reached, go on with `goto` to a line
you know. Where a routine really needs to resume, use BASIC 7.0's own:

```
&,38:trap 5000          : rem Image's trap off, BASIC's on
... the code that may fail ...
trap:&,37               : rem BASIC's off, Image's on again
...
5000 ... er, el, err$(er) ...:resume next
```

`er` is the error number, `el` its line and `err$(er)` its message
(BASIC 7.0's: `er` and `el` can't be variables of your own). With both
on, Image's wins.

Each trap sets only its own: after an error Image's trap took, `er` and
`el` are still -1 and 65535 (BASIC's "no error"), so read `peek(6)` and
`peek(7)+peek(8)*256`; after one BASIC's `trap` took, those bytes are
whatever they were. `tests/standin/trap.bas` shows both.

## Daily statistics: `st()` and `e.stats`

`st(x)` holds record `x` of the REL file `e.stats`: im reads them all at
boot (line 3160), `gosub 30` opens the file, `gosub 16` adds `i` to
record `x` and writes it back, `gosub 17` writes `st(x)` as it is. Image
3.0's manual lists records 1-36 (`docs/prg-im-routines.adoc`, "e.stats
records" in the ImageBBS3 repo): feedback, mail, posts and so on, each as
last, log, current and total. Records 37 and 38 are the time used and the
time idle, in total (i.lo line 3080, `st(x+27)` for `x` 10 and 11).

Image BBS 128 adds two (10/27/2026), so `st()` is DIMmed `st(40)`:

| Record | Counts | Reset |
|---|---|---|
| 39 | errors since the last daily maintenance | daily, with records 12-22 (`i/lo.automaint` line 4064) |
| 40 | errors since setup | never |

im's error handler adds one to both (line 4035) after it writes the error
to `e.errlog`. In 80 columns, `sub.display` shows them on the status
area's right half ("Errors today/total"). `i/su.config` has always created
`e.stats` with 40 records, so disks set up before this have both, at 0.
Code that reads all of `st()` reads 40 records: im line 3160,
`i/lo.automaint` line 4032 and `sub.bar` line 60006.

## BASIC 7.0's stack

FOR, GOSUB and DO keep their frames on BASIC 7.0's own stack at
`$0800`-`$09ff`, not on the CPU's (the C64 keeps them on the CPU's).
`$7d`/`$7e` points at the newest frame's first byte; `$09ff` (2559) is
empty.

| Frame | First byte | Size | Then |
|---|---|---|---|
| FOR | `$81` | 18 | the variable's address (bank 1), STEP, sign, TO, line, text pointer |
| GOSUB | `$8d` | 5 | line, text pointer |
| DO | `$eb` | 5 | line, text pointer |

BEGIN/BEND puts nothing there: an unclosed BEGIN block can't leave
garbage.

### What leaves garbage

A frame whose RETURN, NEXT or LOOP never runs stays on the stack:

- a `goto` out of a subroutine, a FOR loop or a DO loop (EXIT leaves a DO
  loop without a trace);
- a GOSUB to a line that doesn't exist, caught with `trap` and `resume
  next`: GOSUB puts its frame on before it looks for the line, and the
  error doesn't take it off. `&,66,1` does the same.
- a DO loop whose LOOP is in the THEN part of an IF: when the IF is
  false, the rest of the line is skipped, LOOP included, and the program
  falls through with the frame still there. Inside a FOR loop, the next
  NEXT finds the DO frame first: `?next without for`. End the loop on a
  line of its own instead (`loop while f`, with the test kept in `f`).

EXIT leaves a DO loop cleanly, but it doesn't use the frame to find the
way out: it looks for the next LOOP *after* it in the program text and
goes on from there. A LOOP before the EXIT (`...:loop:else exit` on one
line) gives `?loop not found`. RETURN from inside a DO or FOR loop takes
their frames off too (tried 10/28/2026, `docs/loop-report.md`).

Each one takes stack space for good. The stack holds about 66 GOSUB
frames (fewer FOR frames, at 18 bytes), and evaluating an expression
needs free room there too, so it usually runs out as `?formula too
complex` (error 25) on an ordinary statement, before GOSUB's own `?out of
memory`; a handler for it can't evaluate anything either until the stack
is cleared. An error that reaches Image's trap clears it, as do CLR and
RUN.

### `sub.stack`: looking at it

`a$="stack":gosub 74` (or `gosub 450`) runs `sub.stack`, which lists the
frames on BASIC 7.0's stack with their lines (a FOR's with its variable),
past the two GOSUBs that called it. If there are more, it offers to clear
them by forcing a `?syntax error` on its own line (63022), which Image's
trap logs and recovers from. Frames from further out (a check run from
inside a module's own FOR loop) look the same as garbage: they're listed,
and cleared too.

## Reading the variables: `bank`

BASIC 7.0 keeps its variables, arrays and strings in bank 1; here they
start at `$4000` (`vartab`). `peek` and `poke` see bank 15 unless told
otherwise, and from `$4000` up bank 15 is BASIC's ROM; a `poke` there goes
to bank 0's RAM, under the ROM, which is where `im`'s program text is.

`bank 1` makes `peek` and `poke` read and write bank 1; `bank 15` sets them
back. The statement only stores the number at `$03d5` (`bnkvar`): `peek`
does `ldx $03d5` and calls the KERNAL's INDFET with it (`$80d8`), and
`poke` and `sys` use it the same way. It doesn't switch any memory itself,
and Image's `&` calls set the MMU for themselves and never read it, so `&`
output works the same in bank 1. A module can set `bank 1` once and stay
there while it looks around.

Go back to `bank 15` before:

- a `poke` to the I/O chips (`poke 53248,...`),
- a `gosub` into `im` (line 94's yes/no prompt reads a key), and
- returning to `im`, whose `peek`, `poke` and `sys` expect bank 15.

If an error stops a module while it's in bank 1, Image's trap sets it
back to 15 (`wtrap`), so `im`'s error handler starts there.

`bank` is a BASIC 7.0 keyword: a module that uses it includes
`Basic70.bas` and is built with C64List 4.06, which can't take
`3_0-preface.lbl`'s numeric assigns, so a jump into `im` is written as
`gosub {$39}4` and `goto {$33}00` (`sub.stack` and `i.VL` do).

### `i.VL`: the variable list

`VL` loads `i.VL` (`im` line 70 with `a$="VL"`), which lists every simple
variable and its value, then asks "View Arrays?" (line 94). It runs the
whole listing in bank 1: `bank 1:gosub 3004:bank 15` on line 3002.

**Simple variables** are 7 bytes each, from `vartab` up to `arytab`: two
name bytes, then five of value. The name bytes' high bits give the type:

| Name bytes | Type | Value |
|---|---|---|
| both under 128 | float | 5 bytes: exponent, mantissa (sign in its top bit) |
| both 128 or more | integer (`%`) | 2 bytes, high byte first |
| first under 128, second 128 or more | string (`$`) | descriptor: length, address low, high |
| first 128 or more, second under 128 | `fn` definition | shown as ` ?` |

The name goes out a character at a time with `&chr$()`, then MCI's tab
(`{pound}{back arrow}04`) lines up the `=`.

**Strings** are read through their own descriptor, one character at a
time, not copied:

- The C64 version poked the descriptor into another variable to print it.
  In BASIC 7.0 that's two descriptors for one string, which its
  back-links can't describe (`PORTING_NOTES.md`), and it was poking bank
  0's program text here.
- The descriptor is read again for each character: `chr$()` makes a
  temporary string, which can start a garbage collection, which moves the
  string and updates the descriptor.
- A string whose address is outside the string area (`fretop` up to
  `memsiz`) was assigned from a literal and points into the program text,
  in bank 0. Bank 0's program and bank 1's strings share addresses, so
  the address alone doesn't say which bank; outside the string area it's
  shown as `(static string in program text)` instead of bank 1's bytes.
- Each character goes out with its own `&`, nothing is added to a
  string, so there's no `?string too long`. Printable characters go out
  as they are, control codes in reverse as `{pound}r1`, the character plus 64,
  `{pound}r0`, and `£` as `{pound:2}` so MCI doesn't take it.

**Arrays** follow, from `arytab` up to `strend`, each one:

| Bytes | |
|---|---|
| 2 | name, typed as above |
| 2 | offset to the next array, low byte first |
| 1 | number of dimensions |
| 2 each | each dimension's size, one more than DIMmed, high byte first, **the last dimension's first** |
| the rest | the elements: float 5 bytes, integer 2, string 3 (its descriptor) |

The first subscript changes fastest. Read from x128 after `dim
q(2,3),r%(4),s$(1)`: `q`'s header is `51 00 45 00 02 00 04 00 03`, and
`q(1,2)` is element 7 (1 + 2×3). `i.VL` shows each array as DIMmed
(`TT$(254)`), then only the elements that aren't 0 or `""`, with their
subscripts. It points `x` 2 bytes before an element so the simple
variables' float and string code reads it.

Making a simple variable moves every array up 7 bytes, so the array walk
makes all the variables it uses (`w=.:e=.:...`) before it reads `arytab`.
A pointer into the arrays is only good until the next new variable.

The abort key (`rc`) stops it between characters, elements and arrays.

## GOSUB and GOTO from the ML: `&,66`

`a%=<line>:&,66,1` is a GOSUB to line `a%` (its RETURN comes back to
the statement after the `&`); `&,66,0` is a GOTO. The line must be under
32768 (`a%` is an integer).

## Writing `&` output

- After THEN, write `then:&"..."`: the wedge only sees `&` at the start
  of a statement, so `then &"..."` is a `?syntax error`.
- With `lp=1` before it, a string is printed with word wrap, and the ML
  ends the line itself unless the string ends with a space; `lp` is back
  to 0 after each string, so set it before each one.
- The 128 screen editor's Esc sequences work in `&` output (11/05/2026),
  in 40 and 80 columns: Esc goes to the editor's own print (`$c72d`), and
  so does the character after it, so the editor runs the sequence on the
  cursor Image uses. Write the Esc as `{$1b}` in the string (or
  `chr$(27)` in `a$`). Clearing:
  - `&"{$1b}q"` clears from the cursor to the end of its line;
  - `&"{$1b}@"` clears from the cursor to the end of the window: the
    editor's window, whose bottom Image keeps at `botline` (row 23, or 15
    with the screen mask on: `setwin`), so the mask's rows stay.

  Put the cursor first with `&,70,column,row`. `im` 3414 clears under the
  boot frame this way (`&,70,0,6:&"{$1b}@"`). Only on the console: a
  caller's terminal doesn't know the 128's Esc codes, so leave them out
  of text that callers see. `tests/standin/escq.bas` and `escq80.bas`
  try both.

## Today in History files: `today.<Mon>` and `s.today/hist`

`i/lo/today` (the maker, `modules/i_lo_today.lbl`) reads this month's
`today.<Mon>` (`today.Jan` ... `today.Dec`, with a PETSCII capital) from
drive 3, picks out today's facts, lists them on the screen, and writes
them to `s.today/hist` on drive 1. `i/lo-today` (`modules/i_lo-today.lbl`)
shows `s.today/hist` to callers. Both are run from the logon and
maintenance lists. The twelve `today.*` files come on the release's
`MASTER D2` disk; `disk/today.<Mon>.seq` are those, fixed (see
`disk/README.md`), and `asm/build.sh` writes them to `build/features.d81`
(11/05/2026; they were on `image128.d81`, which they left too full: setup's
Optional Features part copies them from that disk when it's chosen).

`tools/today.py` lists, checks and edits a `today.<Mon>` file, on a
`.d81` or as a SEQ file (`tools/today.py --help`).

The other data files, what each is for and where it lives, are in
DATA_FILES.md.

### `today.<Mon>`

A SEQ file of lines, each ended by a carriage return:

| Columns | What |
|---|---|
| 1 | `B` born today, `S` happened today, `R` don't forget (a holiday or a reminder) |
| 2-5 | `MMDD`; the maker only compares the day (4-5) |
| 6-9 | the year, right-aligned (` 742`); spaces for `R` |
| 10 | a space: a new fact; `C`: more of the fact above; `1`-`7`: a new fact shown only on that weekday |
| 11- | the text |

- **A fact longer than one line** goes on in `C` lines, with the same type
  and date as its first line: `B10021851 Ferdinand Foch, believed to be
  the leader responsible for` then `B10021851CAllies winning World War
  I.` The text of a `C` line starts in column 11 too; a space is put
  between the lines when they're joined, unless the line before ends in
  one.
- **A line is at most 80 characters**, as `&,2,2` reads no more; the
  release's lines go to 79 (one is 81, and loses its last character).
  `today.py` wraps at 76.
- **The weekday digit** is compared with the first character of `d1$`
  (1 Sunday ... 7 Saturday). A holiday on "the nth weekday of the month"
  is one line for each of the 7 days it can fall on, each with that
  weekday: Thanksgiving, the fourth Thursday in November, is `R1122` to
  `R1128`, each with `5`. `today.py ... sliding 4 Thu "..."` writes such a
  set; `sliding last Mon` the last week (Memorial Day).
- **A weekday fact must fit on one line.** Its `C` lines have no weekday,
  so on the other weekdays the maker keeps them and joins them onto
  whatever fact came before.
- **A line starting with `*` is a comment**: the release uses them for
  headers (`*MMDDYYYY Birthdays`, `*updated 03/22/88 MAC`). The maker
  skips them (line 4029). The release's maker had no such test and
  skipped them only because their columns 4-5 never match a day: there,
  a comment with a day in columns 4-5 and a space, `C` or weekday in
  column 10 would show as a fact, which `today.py check` warns about.
  **`^`** ends the file: the maker stops there.
- **The order**: in the release, the `B` facts by date, then `S` and `R`
  day by day. The maker doesn't need it (it reads the whole file and
  keeps today's), except that `C` lines follow their fact.
- **At most 20 lines of one type on one day**, `C` lines included: the
  maker keeps them in `dim zt$(3,20)`, and a 21st stops it with `?bad
  subscript`. The release has at most 12.
- Text is mixed case: capitals are PETSCII `$c1`-`$da`, as C64List's
  `{alpha:alt}` writes them, and so are the `B`/`S`/`R` and `C` in
  columns 1 and 10.

`today.py check` finds three mistakes in the release files, fixed in
`disk/`: `R0315` (Beware the Ides of March!) has `S` in column 10, which
isn't a weekday, so it never shows; `S0838` (Lea and Perrins) has no such
day; and `B0808` (Rudi Gernreich) is 81 characters.

### `s.today/hist`

What the maker writes for the day: a heading and a blank line, then for
each type that has facts today, a purple title ("Famous people born on
this date..."), a blank line and the facts, with a blank line before
the second and third titles. A fact's first line is `{white} ` + the
year + `,` (a space for `R`) + ` {yellow}` + the text; each `C` line
becomes 7 spaces + `{yellow}` + the text. `i/lo-today` joins those back
onto the fact before them, and prints each fact word-wrapped with
`lp=1:&`; the maker's own lists on the screen do the same (4084-4096).
A fact stays in pieces in the file, since `&,2,2` reads at most 80
characters and a joined fact can run to about 215.

## Time zones and daylight saving time

The BBS's clock shows local time, and moves an hour for daylight saving
time by itself (SYSOP_COMMANDS.md, "Daylight saving time"). Three things
describe it: the time zones (`s.timezones`), the rules (`s.dstrules`), both
on the System drive and written by `tools/dstfiles.py`, and the BBS's state
(`e.data` records 45 and 46).

### A time zone: `s.timezones`

A line per zone; `sub.info` lists them. A zone is kept as its first 11
characters: in `e.data` record 45 (`tz$`) for the BBS, and in
`mid$(uf$,6)` for a caller.

```
PST0400UPDT(US/CA) Pacific Time
```

| Columns | Holds |
|---|---|
| 1-3 | standard time's name: 3 characters, all the date display has room for |
| 4-7 | the offset, `hhmm`, from UTC-12: GMT is `1200`, UTC-8 `0400`, UTC+9:30 `2130` |
| 8 | the rule's letter in `s.dstrules`; `-` for no DST |
| 9-11 | daylight time's name (spaces for none) |
| 12- | the description (28 characters show) |

The ML converts times between zones with the hour and minute of the offset
(`tzoneh`/`tzonem` for the BBS, `uzoneh`/`uzonem` for the caller, swap3's
`timezone`). On daylight time, the hour poked there is one more.

Image 3.0's zones were 7 characters (no rule). A BBS zone like that has no
DST until the sysop chooses the zone again; a caller with one is asked to
choose again at their next login (`i/lo.on` 4174).

### A rule: `s.dstrules`

A line per rule:

```
U03210200L11110100LUS and Canada (since 2007)
```

| Columns | Holds |
|---|---|
| 1 | the letter |
| 2-3 | when DST starts: the month |
| 4 | the week: 1-4, or 5 for the last |
| 5 | the weekday, 1 (Sunday) to 7 |
| 6-9 | the time, `hhmm`, in standard time |
| 10 | `L` local time, or `U` UTC |
| 11-19 | when it ends, the same way (its time in standard time too: the US's 2:00 AM daylight time is `0100`) |
| 20- | a description |

A start month after the end month (Australia, New Zealand) means DST over
New Year. The four shipped: `U` US and Canada, `E` the EU and the UK (1:00
AM UTC), `A` south-eastern Australia, `N` New Zealand.

### The BBS's state: `e.data` records 45 and 46

Record 45 is the BBS's zone (above). Record 46 is `1,` when the clock is on
daylight time (`0,` when not), then a copy of the zone's rule line, so the
check needn't read `s.dstrules` each time. A different letter, or no copy,
makes the next check read the rule and take the clock as right.

### `sub.clocks`: entries 12-15

| `im` | Does | Called by |
|---|---|---|
| 12 | the check: the clock in standard time (by the flag), whether DST should be on, and if that differs, the clock moved an hour (a CMD or DS12C887 clock written too), the flag saved and `tzoneh` set | `im` at boot (3158); `i/lo.idle` when checkmark 64 is set |
| 13 | the flag from the rule, taking the clock as right, and the alarms (15) | `i/IM.misc` (Time Zone), `i/IM.dstrules` after saving |
| 14 | the caller's zone by their rule: `uzoneh` and the name shown (`PST` or `PDT`) | `i/lo.on` at login |
| 15 | the alarms that set checkmark 64 at the minutes the rule changes the clock, on its change weekdays; old ones (checkmark 64) taken out first; `e.alarms` saved | `i/su.config`, 13 |

The check uses the rule's start and end in standard time, so the autumn's
hour that happens twice is never set back twice. Clocks `sub.clocks` can't
write (Lt. Kernal, Ultimate, TeensyROM) are taken to keep standard time:
reading one adds the hour while record 46 says `1`.

## The sysop information file: `e.sysop`

`e.sysop`, on drive 3, holds what callers who run an Image BBS of their own
say about it. `SF` (`i.SF`, Sysop File Maintenance) creates and edits
it, the new user application (`i/lo.new`) writes a new caller's record,
and the login module `i/lo-sysop info` has callers fill theirs in and
check it (SYSOP_COMMANDS.md).

A REL file of 250-byte records; record _n_ is user ID _n_'s. `SF`'s
Create (or `i/lo.new`, when there's no file) writes `^` to a record for
each user. A record is one of:

- `^`: nothing yet; `i/lo-sysop info` asks the caller to fill it in.
- `n`: the caller doesn't run an Image BBS; never asked. `SF`'s Delete and
  "Change file to n" write this.
- 14 fields, each ended by a carriage return:

| Field | Holds |
|---|---|
| 0 | when it was last written or checked: an 11-digit date (`d1$`) |
| 1-3 | handle, first name, last name |
| 4-7 | address, city, state, zip code |
| 8 | the BBS's Image serial number ("IMAGES#") |
| 9 | the board's name |
| 10 | voice phone number |
| 11 | the board's telnet address; the board's phone number in older records (`i/lo.new` still writes that here, and `i/lo-sysop.quest`, the older login module, called it "Board No.") |
| 12 | its network (`SF` writes `None` when blank) |
| 13 | its node ID (`SF`: `N/A` when blank) |

`i/lo-sysop info` compares field 0's month (characters 4-5) with
today's, to ask once a month. `SF` drops one leading space from each
field it reads.

## NetMail's overlays: `++ net`, `++ path`, `++ netsub`, `++ netlist`

NetMail (the `i.NM_*` and `i/NM.*` modules, `i/IM.netmail`, `i/SM.netfile`
and others) does its heavy work in four "++" overlays. A module loads one
with `a$="<name>":gosub 28` (`im` loads the file `++ <name>` at protostart,
`$1c00`, with `&,7`; `e%` is nonzero if it couldn't), then calls it with
`&,16`, `&,16,x` or `&,16,x,y`: `x` picks the routine, `y` is a number some
of them take (a device, a length, a record). Only one overlay is in memory
at a time, and each keeps its data just past itself, so loading another
loses that data (`++ path`'s node list, `++ netsub`'s tables): load the one
you need again before using it.

They read and set the ML's own variables (`a$`, `an$`, `b$`, `a%`, `b%`,
`dv%`, `qe`, `rc`: BASIC_VARIABLES.md). The source is `asm/net.asm`,
`asm/path.asm`, `asm/netsub.asm` and `asm/netlist.asm`; each one's header
says what changed from the C64's. `tests/standin/netovl.bas` tries `++ path`,
`++ netsub` and `++ netlist`; `tools/netpair.py` runs a NetMail exchange with
`++ net` between two x128s (`tests/standin/README.md`).

### `++ net`: the transfer protocol

`i.NM_auto` (calling another BBS, and answering one) and `i/NM.netsub4`.
Everything goes through the modem file, `131`; files go to and from the
disk file `2`, which the module opens first.

| Call | Does | Takes | Gives |
|---|---|---|---|
| `&,16` | sends file 2 to the other BBS | file 2 open for reading | `peek(512)`, `b%` |
| `&,16,1` | receives a file into file 2 | file 2 open for writing | `peek(512)`, `b%` |
| `&,16,2` | sends a name block | `b$`: up to 31 characters (the rest is cut) | `peek(512)` |
| `&,16,3` | receives a name block | | `b$` (to its Return, at most 79 characters), `peek(512)` |
| `&,16,4` | the sending side of the relaxed handshake | | `peek(512)`: 0 agreed, 1 no answer |
| `&,16,5` | its receiving side: relaxed timing stays on if the other side asks for it | | `peek(512)`: 0 agreed, 1 no answer |
| `&,16,6,n` | the modem chat: sends `a$` (if not empty), then keeps the last `n` characters that arrive | `a$`, `n` | `b$`; `rc` 1 and `b$` `""` if the carrier went or C= was held |

- **`peek(512)`** (BASIC's input buffer, `$0200` on both machines) is 0
  when the transfer finished and 1 when it was aborted: the sysop held C=
  (`shflag` 2), the carrier went (`carrst` bit 7 clear), the other side
  sent three Ctrl-X, or `++ net` gave up waiting (it sends three Ctrl-X
  then).
- **`b%`** after `&,16` and `&,16,1` is a block count, but not the file's
  size: it counts one for each good block and one for each 254 bytes (a
  1500-byte file gave 15).
- **The name block** is what `i.NM_auto` sends before each file:
  `"<to>/<from>/<A or R>/<file name>"` (node IDs of 3 characters, so the
  file name starts at character 11, `mid$(b$,11)`); `A` appends to a file
  already there, `R` replaces it.
- **The modem chat** (`&,16,6,n`) is how `i.NM_auto` logs in through
  another BBS's modem or a packet switch (3400-3418): it sends `a$`, then
  collects what arrives in `b$` until nothing has come for a while
  (25600 empty polls), keeping only the last `n` characters; control
  characters other than Return are dropped, and 32 is taken off characters
  from `$60` up. The module compares `b$` with the prompt it expects:
  `&,16,6,len(c$)`, then `b$<>c$`. `rc` is 1, not -1: Image's "minus one"
  (`&,32`) is `$81,0,0,0,0`, which is +1, on the C64 too.
- **2 MHz:** in 80 columns each `++ net` call runs at 2 MHz (`$d030`),
  the VIC not being seen there, and reads the modem straight from the
  driver: at 1 MHz, and through `&,4`, a 128 lost the odd byte from a
  sender at the full 19200 line rate. Afterwards the speed is the screen
  blanker's (2 MHz while it has the screen off). The lightbar's mHz
  checkmark (flag 62) shows the speed whatever set it.
- **Relaxed timing** waits longer for the other side: 100 rather than 35
  for a code, 30 rather than 16 for a block (in units of 256 passes of its
  wait loop). `&,16,4`/`&,16,5` agree on it, or a module sets it itself:
  `poke {sym:protostart}+3,1` (`i.NM_auto` 3196, for a node whose dial
  string starts with `*`).

Before a transfer the module prints a counter line on row 15
(`" Good: 00000  Bad: 00000  Bytes: 000000"`, `i.NM_auto` 3660), and
`++ net` counts in it, in the 40-column screen's row 15 as on the C64; in
80 columns it first copies the line the module printed from the VDC into
that row, and each cell that changes goes to the VDC too (`&,72`, below).

The protocol is Punter's. Its codes are three characters (`GOO`, `BAD`,
`ACK`, `S/B`, `SYN`, and three Ctrl-X to abort). A block is at most 255
bytes: a 4-byte checksum, the next block's size, the block's number (low,
high; a high byte of `$ff` marks the last block), then up to 248 bytes of
data. A name block is 39 bytes. Its waits count passes of a loop and, after
each code it sends, a tenth of a second on the TOD clock (`tenwait`,
`$dc08`); with the clock stopped that wait never ends. `im` starts the
clock at boot; a test program must `poke 56328,0`.

Before the protocol starts, `i.NM_auto` uses the modem itself: the caller
sends `chr$(1)` until the answering side sends back `chr$(2)` (ten of them),
reading each character with `&,4` and `peek({sym:sareg})` (3204-3210,
3292-3296).

### `++ path`: routes through the network

`i.NM_*`, `i/NM.*`, `i/IM.netmail`, `i.EM`, `i/MM.sb-mail` and
`i/SM.netfile`. It keeps the node list (`nm.nodelist`, drive
2) in memory and finds the way from one node to another through the nodes
each one links to.

| Call | Does | Takes | Gives |
|---|---|---|---|
| `&,16` | loads the node list | `a$` the file (with `dr$`), `dv%` | `a%` the number of nodes |
| `&,16,1` | the path from one node to another | from: `a%` (a node's number), or `a$` (its ID) when `a%` is 0; to: `b%`, or `b$` when `b%` is 0 | `an$` the path; `""` if there's none or a node isn't known |
| `&,16,2` | a node's number | `a$` its ID | `a%`; 0 if it isn't known |
| `&,16,3` | shortens a path | `an$` a path, `a$` a node's ID | `an$` from that node on |

A path is each node's ID after a `/`, with one more `/` at the end:
`/AAA/BBB/CCC/`. A node's ID is the first 3 characters of `a$` or `b$`.

`nm.nodelist` is a PRG file, loaded just past the overlay: a byte with the
number of nodes (up to 255), then 8 bytes for each node, numbered from 1:
its 3-character ID, a byte not used, and the numbers of up to 4 nodes it
links to (0 for none).

### `++ netsub`: the NetSubs' repeat check

`i/NM.netsub2` keeps, for each board ID (3 characters) that NetSub messages
come from, the number of the last message taken from it, and rejects a
message whose number isn't higher ("Repeat Rejected!"). The numbers are in
two tables of 128 records each, saved together in the files
`nm.P.track<NetSub><n>` on drive 2 (when one is full, the next `n`). The
first table is updated as messages come in; the second is the copy that
`i/NM.netsub1` makes when a run starts (`&,16,7`).

| Call | Does | Takes | Gives |
|---|---|---|---|
| `&,16` | a board's numbers | `a$` the board ID | `rc` from the second table, `qe` from the first |
| `&,16,1` | sets a board's number in the first table | `a$`, `qe` | `qe` -1 if the table is full |
| `&,16,2,dv%` | loads both tables (cleared first) | `a$` the file | |
| `&,16,3,dv%` | saves both tables | `a$` the file | |
| `&,16,4` | takes a board out of the first table (later ones move up) | `a$` | `qe` its number; -1 if it wasn't there |
| `&,16,5,n` | the first table's record `n` (from 0) | `n` | `an$` the board ID and `qe` its number; `an$` `""` and `qe` -1 past the last |
| `&,16,6` | clears both tables | | |
| `&,16,7` | copies the first table over the second | | |
| `&,16,255` | the version | | `a%` = 10 |

A board not in a table yet is added to it with the number 0, so `&,16`
gives 0 for a new board, and -1 only when a table is full.

### `++ netlist`: a NetSub's definition

A NetSub (a sub-board shared through the network) is defined in the file
`nm.netsub<n>`, _n_ 1 to 60, on drive 2. `i/SM.reledit` edits them;
`i/NM.netsub1`, `3` and `4` and `i/lo/ns` read them.

| Call | Does | Takes | Gives |
|---|---|---|---|
| `&,16` | the definition | `a%()` DIMmed | `a$` its name, `an$` its nodes, `a%(0)` how many sub-boards and `a%(1)`... their numbers |
| `&,16,1` | sets the definition | `a$`, `an$`, `a%()` | |
| `&,16,2,dv%` | loads a definition (cleared first) | `a$` the file | |
| `&,16,3,dv%` | saves it | `a$` the file | |
| `&,16,255` | the version | | `a%` = 9 |

- The name is up to 30 characters. The nodes are their 3-character IDs one
  after another, up to 16 (48 characters), padded with `-` (`an$` comes back
  padded too).
- `a%()` must be DIMmed (`dim a%(60)`), or `&,16` and `&,16,1` print
  "Error-Sec?" and do nothing more.
- `a%(0)` keeps only its low byte (enough for a count); `a%(1)`-`a%(60)`
  are kept whole. The release kept 120 bytes from `a%(0)`'s low byte on,
  so `a%(60)` lost its low byte, and a 60th sub-board's number was lost;
  the 128's keeps a 121st byte for it (11/05/2026). A file saved by the
  release (or the C64) hasn't that byte, so it loads as it always did,
  with `a%(60)`'s low byte 0.

## `++ chatmode`: chat between Lt. Kernal stations

A proof of concept (11/12/2026): on a multiplexed Lt. Kernal hard drive,
where up to 16 computers (stations, the host adapter's ports 0-15) share
one drive, callers at different stations chat in one room, and the sysop
comes in at any station by turning `Cht` on (and leaves by turning it
off). `modules/i.ltk chat.lbl` runs it from the main prompt (through an
ECS entry); the source is `asm/chatmode.asm`, whose header has the
details. It isn't on the boot disk: Image-128's own Lt. Kernal code is
still off (`use_ltk`, intro.asm).

| Call | Does |
|---|---|
| `&,16` | shows the transcript, oldest first, until a key |
| `&,16,2` | lists the other stations online: `Port nn: handle`, `(chat room)`, `with SysOp` |
| `&,16,3` | the chat room, as `a$`, until `/x`, or the caller's carrier or time runs out |
| `&,16,4,s` | this station's state: 0 offline, 1 online; `a$` the handle |

The results are at `peek({sym:protostart}+3)` on: `+3` 0 fine, 1 carrier
or time, 2 no room for the file on LU 10, 3 no LU 10 (or the new file not
found), 4 no Lt. Kernal, 5 the room is full (15 stations), 6 an old
`chatfile`; `+4` the transcript's blocks shown; `+5` this station's port;
`+6` the other stations online; `+7` of those, in the room.

- **The file:** `chatfile` on LU 10, user 0 (where every port sees it),
  34 contiguous blocks: the header; a block for each port; the
  transcript's position; the transcript, a ring of 16 blocks (8K).
- **One writer per block.** The Lt. Kernal's notes call two ports writing
  at once "usually fatal", so a station writes only its own block (its
  state, handle, a tick, and its last 5 lines, numbered), and the others
  read it; the transcript is written by the lowest-numbered station in the
  room only. When that one leaves, the next takes over; a line can be lost
  or written twice then. (`&,13`, Image's lock between stations, isn't
  used: nothing calls it yet, and it's off on the 128.)
- **The chat:** a line is sent on Return. About twice a second the overlay
  reads the blocks of the stations in the room, and one other in turn (a
  station coming in is seen within 8 seconds), and prints what's new. A
  station whose tick stops for about 100 seconds is shown as timed out.
- **Online** means in `i.ltk chat` for now: logon and logoff don't mark it.

`tests/standin/chatmode.bas` (one station) and `tests/standin/chat2.bas`
(two x128s on one emulated Lt. Kernal, ports 0 and 1) try it:
`tools/ltk_chatmode.py`, `tools/ltk_chat2.py`.

## VIC screen cells to the VDC: `&,72`

ML that draws on the VIC screen as it works (`++ net`'s and `++ copier`'s
counters on row 15, `++ 2`'s `BLKS:` on row 21) isn't seen in 80 columns.
`&,72` (`vdccell`, `asm/vdc.asm`) copies a cell across; in 40 columns it
does nothing.

| Call | Does |
|---|---|
| `&,72,r,c` | the character at VIC row `r` (0-24), column `c` (0-39) to the same row and column of the VDC |
| `&,72,r+128,c` | that, and the cell's color (VIC color RAM) as a VDC attribute, in the lowercase set |
| `&,72,r+64,c` | the other way: the VDC's characters from column `c` to 39 into that VIC row, so a module's line printed in 80 columns can be counted in by ML |
| `&,72,r+32,c` | the whole VIC row `r` (columns 0-39, characters; `c` not used) to the VDC's: `++ copier` shows each block it reads on rows 2-8 this way |

From ML: `ldx #row`, `ldy #column`, `lda #72`, `jsr usetbl1` (`$192a`).
That goes through `farcall`, so an overlay started with `sys` (`++ 2`)
can call it too. Each call is a farcall, so a counter that changes every
byte goes across now and then (`++ copier`'s `Bytes:`: every 64 bytes,
and when the call ends).

## The bus scan: `sub.sysdos` im=2

`im=2:a$="sysdos":gosub 74` lists the drives on the serial bus (devices
8-30): `tt$(d)` is each device's model, `a%` how many answered. A device
answers `open 15,d,15:close 15` (as `im` line 353 checks); its model comes
from its own ROM with `m-r` (no reset, no disk access): CMD's ID at
`$fea4` (`HD`, `FD`, `RL`, `RD`, as CMD's fcopy/mcopy/bcopy check), else
the power-on message's model number (`$e5bb`: 1541, 1570, 1571; `$a6df`:
1581). `tt$(d)` is `CMD HD`, `CMD FD`, `RAMLink`, `RAMDrive`, `1541`...,
`?` for one that answers but isn't recognized (SD2IEC), `""` for none.
About 0.1 s an absent device, 2-3 s a drive. The setup's Drives part uses
it; tried in x128 with a 1541, 1571 and 1581, and a CMD FD-4000
(`-drive9type 4000 -dos4000 ROMs/dos4000`, the ROM not in the repo).

## Test programs

`tests/standin/` programs are petcat source, not C64List: `\` is the `£`
(`\!i` prints `i` by MCI), and there's no `{sym:...}`. `sys 7171` turns
Image's trap off; call `&,37` to try it. See `tests/standin/README.md`.
