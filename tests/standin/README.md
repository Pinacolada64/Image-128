# Stand-in test programs

Small BASIC programs that run in place of `im 128`, to try one part of
the ML without the whole BBS. `tools/standin.sh` makes a test disk from
one: it writes the program as `im 128` on a copy of `build/image128.d81`,
so the boot loads the ML and RUNs it.

```
asm/build.sh
tools/standin.sh tests/standin/fkey-macros.bas
x128 -80col -drive8type 1581 -autostart-warp -autostart "build/standin-fkey-macros.d81:boot 128"
```

They're petcat source (BASIC 7.0), not C64List: `chr$(92)` for `£`, no
`{sym:...}`.

| Program | Tries |
|---|---|
| `scroll.bas` | scrolling, and wrapping a long line at the screen's width |
| `mask.bas` | the screen mask on and off (`&,18`), console text scrolling and wrapping underneath |
| `status-right.bas` | `&,69` on the 80-column status area's right half, with the mask off and on |
| `lightbar.bas` | the lightbar's labels and default checkmarks, loaded as `im` loads them; the f-keys move the highlight |
| `gosub.bas` | `&,66,1` (a GOSUB from the ML) 50 times: the frame on BASIC 7's stack, the CPU stack left clean; then one to a missing line, caught by BASIC 7's `trap` and `resume next` |
| `struct.bas` | `&,60,3` then `&,60,2`: an array saved as a struct and loaded back (bank 1, the right length) |
| `usr.bas` | `usr(0)` (the wedge's stack-pointer function, through the 128's USR vector) and a BANK statement |
| `orphan.bas` | `&,15,6` and `&,15,5` shorten `an$`, then a garbage collection: nothing may be written through the dropped characters (they spell a back-link to a fake descriptor at $0b00); the split's edge cases |
| `menu2.bas` | `++ menu2`, the cursor menu: loaded with `&,7`, four items added with `&,16,0` and drawn with `&,16,2` as `i.IM` does; the script presses cursor down and Return, and `a%` has to be 1 (im's variables are DIMmed first, in its order: the ML finds `a%` by its place) |
| `copier2.bas` | `++ 2`, Copier 3.0's copier: `sys` protostart copies `++ menu2` to `t.copy`, protostart+3 counts its bytes into `t.count` (1514); `BLKS:` shows 6 on row 21. Then `++ copier`'s `&,16,3` compares `t.copy` with `++ menu2` (`a%` 0, `b%` 1514) and with `++ 2` (`a%` 1), and `&,16,255` gives 2. In 80 columns `BLKS:` and the row-15 counter line show on the VDC (`&,72`) |
| `trap.bas` | BASIC 7's `trap`/`resume` with Image's trap off, then both on (Image's wins); `er`/`el` against what Image's trap saves (`peek(6)`, `peek(7)+256*peek(8)`) |
| `fkey-macros.bas` | Ctrl/C= + f1/f3/f5/f7 typing `f1$`-`f8$` into an input line |
| `anfix.bas` | `&,1` and `£g1` inputs kept with a plain `x$=an$`: each keeps its own value through the next input and a collection (the ML copies `an$` out of the input buffer before the next statement); the script types 123, 45, 7 and 8 |
| `mcii.bas` | MCI input `£i1` with more text after it in the same `&`: `a: £i1{f6}`, `e: £i1xyz{f6}` (and `£i1` alone, `{f6}` in its own `&`, `£g1£v7{f6}`). Type 1, 2, 3 (each with Return), 4, 5, 6: each answer stays on its own line, and `e:`'s `xyz` follows it. Before 11/06/2026 the `{f6}` after `£i1` printed the answer again (`1b:`, `xyz5f:`): `inline`'s Return copied `an$` (`trace0`, `strfix`) over the temporary copy of the string the `&` was still printing |
| `dirlines.bas` | the line lengths of a CMD HD's directories (device 9: run it with an HD attached, as `start-setup.sh -hd`): the partition directory (`$=p`) has a 30-byte header line, then 32-byte lines; a partition's (`$3`) header 30. Setup reads them with `&,2,2,n` (sub.su.drives) |
| `copyhd.bas` | `++ copier` between two drives: `ml.low` from the 1581 (device 8) to a CMD HD (device 9, partition 1), `&,16,0`, then `&,16,3` compares them: `0 7844`. Before 11/07/2026 the copy stopped after a few blocks and the compare at byte 1 (a status bit the other drive left) |
| `dirparse.bas` | sub.su.copy's directory reading (`&,2,2,n`, then `&,15,6` at the quotes) on the 1581's `$0`, printing each step's bytes for the `i.NM` files: right on its own (11/07/2026); in setup, `i.NM/auto` was changed later in `tt$()` (modules/TODO.md) |
| `strrest.bas` | `&,15,6` while garbage collections happen: 200 strings in `tt$()`, 3000 splits with garbage made around them, each split's name and every `tt$()` checked (`bad 0`). Passes with strrest before and after 11/08/2026's change (no makeroom inside the & call), so it doesn't reproduce the damage setup's copy saw (modules/TODO.md) |
| `swiftlink.bas` | the SwiftLink driver (`ml.rs232`, `&,16,1`): sends a line, then shows and echoes back what arrives on device 2 |
| `userport.bas` | the same with the user port driver (`&,16,0`) at 1200 baud |
| `dskin.bas` | `&,2,2` into `a$`, then `g$=a$`, `h$=a$`, `u$=a$`: each keeps its own line (`dskina`/`strfix`), through `fre(1)` and 150 more reads. Reads `t.lines` (`dskin.t.lines.seq`, put on its disk by `standin.sh`) |
| `clrarr.bas` | `&,11,0` clears `tt$()`, then two new variables move the arrays and `fre(1)` collects: run `tools/strcheck.py --port 6537` at the end, no damage (the old `clrarr` left the strings linked into a new variable) |
| `arrayrs.bas` | `&,28` as im's line 304 runs it: im's arrays (`tt$()`, `co$()`...) saved with `&,27,1`, then 20 rounds of `&,28,1`, line 306's DIMs (`bb$()`...) with strings in them, four new variables and `fre(1)`: `co$()` and `tt$(1)` stay right, and `tools/strcheck.py --port 6537` at the end finds no damage (with the old `&,28` it found one, linked into dropped memory) |
| `color.bas` | colour codes in `&` output (red, white, cyan): the monitor reads VIC colour RAM (`$d800`) in 40 columns or VDC attributes (`$0800`) in 80; before `sc9` passed the codes to the screen editor, all three stayed one colour |
| `cursorcolor.bas` | 80 columns: red text with `&`, then `&,1` waits with the cursor on; the cell under the cursor (`pnt`+`pntr`) gets the current attribute (`color`, `$88`), so the VDC cursor shows red (before: `$87`, the clear's cyan) |
| `mhz.bas` | the lightbar's mHz checkmark (flag 62, `$3e`) follows the CPU's speed within an IRQ pass: BASIC 7's `fast` turns it on, `slow` off, and a checkmark set or cleared by hand (`&,52,62,x`) goes back to the speed. 80 columns |
| `errmenu.bas` | an error inside `&,16,0` (`++ menu2`) and a plain `?bad subscript`, caught by Image's trap at line 2000, which reads `peek(6)`-`peek(8)`, closes files as `im` does, and prints them with MCI `\!x` |
| `netovl.bas` | the network overlays, each loaded with `&,7` and run with `&,16` as the NM modules do: `++ path` loads a 3-node list it writes and finds the path `/aaa/bbb/ccc/`; `++ netsub` adds, copies, saves, loads and deletes records; `++ netlist` saves and loads a name, a list and `a%()`; `++ net`'s modem chat (`&,16,6`) returns with no carrier (`rc` 1). Prints pass or fail for each, then "all passed" |
| `remote.bas` | `++ remote` (`&,16`) runs plain BASIC programs, which `standin.sh` writes to the disk from `remote.<file>.bas`. `guest`: FOR/GOSUB, its own DATA, string garbage, INPUT (type `bob` and Return) and a file left open, all called from inside `im`'s GOSUB and FOR. Then `im`'s strings, arrays, FOR, GOSUB and DATA are checked, and the file the guest left open is read back. `guest2` does CLR, then 1/0 (result 2, error 20, line 20; file 15 still open). A missing file gives 3/1, and `guest3` with local mode off and no carrier gives 1. Prints "all passed" |
| `netcall.bas`, `netans.bas` | a NetMail exchange between two x128s, run together by `tools/netpair.py` and joined by `tools/nullmodem.py` (ip232, so each sees a carrier): the caller does `i.NM_auto`'s steps (3204-3274), the answer its 3292-3344. After the `$01`/`$02` handshake the caller sends two files, each as a name block (`&,16,2`) and the file (`&,16,0`); the answer receives them (`&,16,3`, `&,16,1`) and compares them byte for byte with what the caller wrote (1500 bytes of every value, `$ff` and Return too). Both start the TOD clock (`poke 56328,0`): `++ net`'s `tenwait` counts its tenths and waits forever while it's stopped |

## What a stand-in has to set up

`im` does these, so a stand-in must too, before printing anything:

- `sys 7171`: intro's `setup` (`im` line 3074). Without it the screen
  mask's row tables, the cassbuff variables and more are never set.
- `poke 2794,0`: `passmode`, or `&` output may come out as the password
  mask.
- `poke 2787,1`: `scnmode`, screen mask off (`&,18` toggles only from 0
  or 1).
- `poke 53252,60`: `llen` (`$d004`), the longest input line. At 0, `&,1`
  and `£i` refuse every character and only Return gets through.

`fkey-macros.bas` also DIMs `im`'s variables first, in `im`'s order (its
lines 3004-3056): the ML finds `f1$`-`f8$`, and others, by their offset
from the start of BASIC's variables.

## Stepping through

`status-right.bas` waits at each step for a byte the monitor pokes
(`$0b00`, the boot loader's cassette buffer, free once Image runs):
`> 0b00 01`, then `02`, and so on. `mask.bas` waits once, at "Press any
key", for a key or for `> 0b00 01`; f1 toggles the mask meanwhile. See
`DEBUG_TECHNIQUES.md` for driving x128 from the remote monitor.

## The RS-232 tests

`swiftlink.bas` and `userport.bas` need x128's RS-232 connected to
something at the other end: VICE connects to a TCP port as a client,
so run a listener there first (`nc -l 25232`, or a script), then:

```
x128 -80col -drive8type 1581 -acia1 -acia1base 0xde00 -acia1irq 1 -acia1mode 1 \
    -myaciadev 0 -rsdev1 127.0.0.1:25232 -autostart "build/standin-swiftlink.d81:boot 128"
x128 -80col -drive8type 1581 -userportdevice 2 -rsuserdev 0 -rsuserbaud 1200 \
    -rsdev1 127.0.0.1:25232 -autostart "build/standin-userport.d81:boot 128"
```

The listener should accept more than one connection: VICE reconnects
when the driver drops and raises DTR at setup. Run at normal speed:
in warp mode the SwiftLink lost the odd incoming byte.
