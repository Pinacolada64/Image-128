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
| `fkey-macros.bas` | Ctrl/C= + f1/f3/f5/f7 typing `f1$`-`f8$` into an input line |
| `swiftlink.bas` | the SwiftLink driver (`ml.rs232`, `&,16,1`): sends a line, then shows and echoes back what arrives on device 2 |
| `userport.bas` | the same with the user port driver (`&,16,0`) at 1200 baud |

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
