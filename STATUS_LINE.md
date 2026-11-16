# The status area

The bottom of the sysop's screen: the lightbar (row 16), the screen mask's
caller information (rows 17-21), and three status rows (22-24). Rows 16-23
show while the screen mask is on; row 24 always shows. Rows are counted
from 0 and columns from 0, as `&,69` takes them.

In 40 columns everything is on the VIC screen. In 80 columns the VDC shows
the same left half (columns 0-39, copied from the VIC by `vdcstat`) and a
right half of its own (columns 40-79), drawn by the ML (`asm/status.asm`)
and, for the system box, by `sub.display`.

## 40 columns

```
row 22   C=00000 N=000 I=000 A=0    Image BBS 128
row 23   R           V=00000  L=00000           T
row 24    Sun Nov 15, 2026 12:51:39 PMOAGF 00:00✓
```

## 80 columns

```
rows 17-19, right half (the system box):
         Errors 22/22
         Stack  219
         Buf    000/127
row 22   C=00000 N=000 U=21 I=79 P=10924 V=07229 L=04232 M=sub.modem        Image BBS 128
row 23   R<--------- receive, 38 ---------->  <--------- transmit, 38 --------->T
row 24    Sun Nov 15, 2026 12:51:39 PM     00:00  Abt Pau Dsk GC  Swp Lck Ovr Flo Int Car
```

The system box's labels are reversed light gray and its values plain gray.
Row 22's right half carries on the reversed bar of its left half.

## The `=` fields

| Field | Row, columns | Shows | Drawn by |
|---|---|---|---|
| `C=` | 22, 2-6 | Total calls to the BBS (`ca`, saved in `e.stats`; one more at each logon, `i/lo.on` 4113) | `sub.display`, `i/lo.idle` 4026 |
| `N=` | 22, 10-12 | Calls since the BBS was started (`cn`, one more at each logon, `i/lo.on` 4174; not saved, so 0 after a restart) | same |
| `U=` | 22, 14-23 with `I=` (idle screen) | System used: the percentage of today's log with a caller on (`st(21)`) | `i.lo` 3085-3087, after each call and each idle stretch |
| `I=` | (idle screen) | System idle: the rest of today's log (`st(22)`). `i/lo.automaint` reports the same two numbers as "System used x%, Idle y% this log" | same |
| `I=` | 22, 14-18 (caller online) | The caller's idle time: minutes, tens of seconds, seconds since the last key. At `idlemax` minutes the caller is logged off | the ML, every second while it waits for a key (`dspidle`, `getchr`) |
| `A=` | 22, 22 (caller online) | The caller's access group, 0-9 (`ac%`); the sysop's f-keys change it there (`t3fk*`) | `sub.display`, the ML |
| `P=` | 40: 23, 12-18 (Dbg on); 80: 22, 24-30 | Program space: bank 0's room left for BASIC text, `maxmem0 - txtend` ($1212 - $1210). It goes down as modules load | `trace2` / `trace80` (`asm/trace.asm`, `asm/status.asm`), between BASIC statements |
| `V=` | 40: 23, 12-18 (Dbg off) or 21-27 (Dbg on); 80: 22, 32-38 | Variable space: bank 1's free room between the arrays and the strings, `fretop - strend`. (Image 1.2's `M=`, all of free memory on the C64) | same |
| `L=` | 40: 23, 21-27 (Dbg off); 80: 22, 40-46 | The BASIC line running (`curlin`), while the lightbar's left Trc (check 24) is on; Ctrl pauses it | same |
| `M=` | 80: 22, 48-65 | The last module loaded, without its drive prefix (up to 16 characters; the wedge's `openroom` keeps it in `modname`) | `r80_mod` (`asm/status.asm`) |
| `Buf` | 80: 19, 41-54 | Bytes waiting in the RS-232 receive buffer, out of 127 | `r80_buf` |

In 40 columns, row 23 has room for two numbers only, so the lightbar's
right `Dbg` checkmark picks which: see the next section. 80 columns shows
all of them all the time.

## `Dbg`: the 40-column mask's numbers

`Dbg` is the lightbar's fifth label on page 4 (checks 56 and 57). Its right
checkmark, check 57, picks what row 23's two number cells show on the
40-column screen mask (11/15/2026):

```
Dbg right off:   R           V=07504  L=04232           T
Dbg right on:    R           P=10924  V=07504           T
```

- **Off** (as Image 3.0 had it, with 1.2's `M=` renamed `V=`): variable
  space and the BASIC line. `L=` follows the line only while the left
  `Trc` checkmark (check 24, the line trace) is on, and holding Ctrl
  pauses the program there.
- **On**: program space and variable space, for watching memory while
  modules load (`P=` goes down as each one is loaded over the program).
  The line isn't shown; Ctrl still pauses the trace.
- **Changing it** rewrites both cells' letters and draws both numbers at
  once, at the next BASIC statement. Turning it off shows `L=` with the
  last line run even if the trace is off, so the cell doesn't keep `V=`'s
  digits.

`trace2` (`asm/trace.asm`) reads the checkmark between BASIC statements
while the mask is on. In 80 columns it changes nothing: `P=`, `V=` and `L=`
are all on row 22.

Check 57 was also meant to turn the VIC-II's border red on an error (`im
128` 4034), but that test is commented out there (`rem &,52,57,3:if a%
then color 4,3`), so for now the checkmark only does the above. The left
`Dbg` checkmark, check 56, is "do not display BASIC variables"; nothing in
Image 128 acts on it yet (`i.LB`'s lightbar menu can toggle it, as it can
any checkmark).

The idle screen's mask and the caller-online mask draw different fields in
row 22's columns 14-23: `U=`/`I=` (system used and idle) at the idle
screen, `I=`/`A=` (the caller's idle time and access) while a caller is on.

## The 16-character window

`&,9` prints a string variable, centered, in a 16-character window at the
right of row 22: the caller's computer type when they log on (`co$`,
`sub.display`); chat mode uses it too. Its own text is `Image BBS 128`. In 40 columns it is
columns 24-39; in 80 columns, columns 64-79 (`btmvar` writes `btmwin`, and
the ML copies it there), as 24-39 hold `P=` and `V=`.

## Row 23: the receive and transmit windows

While the screen mask is on and the lightbar's right Dsr (check 61) is on,
each byte received scrolls in at the right of the receive window (after
`R`) and each byte sent at the right of the transmit window (before `T`).
In 40 columns each window is 10 characters (columns 1-10 and 29-38); in 80
columns, 38 (columns 1-38 and 41-78). Both RS-232 drivers call the same code
(`rs_rxwin`, `rs_txwin` in `asm/status.asm`).

## Row 24: date, time left and indicators

The date and time (columns 1-28) and the caller's time left (34-38, `MM:SS`)
are drawn by the IRQ. Column 0 has a check while the lightbar's left Asc
(check 16, ASCII translation) is off.

The indicators turn on and off through `draw_status_line` ($199f: .a = the
indicator, .x = 0 off or non-zero on). In 40 columns each is a reversed
letter in a fixed cell; where several share a cell, the first in this table
that is on shows. In 80 columns each has a three-letter label at column
40 + 4 × its number, blank while it's off.

| # | 80 columns | 40 columns | On while |
|--:|---|---|---|
| 0 | `Abt` | `A`, column 30 | output was aborted (`/`, space or Ctrl-C) |
| 1 | `Pau` | `P`, column 30 | output is paused (Ctrl-S), waiting for a key |
| 2 | `Dsk` | `L`, column 30 | a load or save runs with the SwiftLink's interrupts off |
| 3 | `GC` | `G`, column 31 | garbage collection |
| 4 | `Swp` | `S`, column 31 | the ML swaps pages of memory (modules in and out) |
| 5 | `Lck` | `L`, column 31 | waiting for a Lt. Kernal lock another station has |
| 6 | `Ovr` | `O`, column 29 | the SwiftLink's receive buffer overran; stays on until logoff |
| 7 | `Flo` | `F`, column 32 | flow control: RTS dropped, the receive buffer is nearly full |
| 8 | `Int` | `I`, column 32 | the SwiftLink's interrupts are off |
| 9 | `Car` | a check, column 39 | carrier present |

The user port driver shows none of `Ovr`, `Flo` and `Int`, and `Dsk` is the
SwiftLink's only.
