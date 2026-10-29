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

## Today in History files: `today.<Mon>` and `s.today/hist`

`i/lo/today` (the maker, `modules/i_lo_today.lbl`) reads this month's
`today.<Mon>` (`today.Jan` ... `today.Dec`, with a PETSCII capital) from
drive 3, picks out today's facts, lists them on the screen, and writes
them to `s.today/hist` on drive 1. `i/lo-today` (`modules/i_lo-today.lbl`)
shows `s.today/hist` to callers. Both are run from the logon and
maintenance lists. The twelve `today.*` files come on the release's
`MASTER D2` disk; `disk/today.<Mon>.seq` are those, fixed (see
`disk/README.md`), and `asm/build.sh` writes them to `image128.d81`.

`tools/today.py` lists, checks and edits a `today.<Mon>` file, on a
`.d81` or as a SEQ file (`tools/today.py --help`).

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

## Test programs

`tests/standin/` programs are petcat source, not C64List: `\` is the `£`
(`\!i` prints `i` by MCI), and there's no `{sym:...}`. `sys 7171` turns
Image's trap off; call `&,37` to try it. See `tests/standin/README.md`.
