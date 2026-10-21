# Stand-in test programs

Small BASIC programs that run in place of `im 128`, to try one part of
the ML without the whole BBS. `tools/standin.sh` makes a test disk from
one: it writes the program as `im 128` on a copy of `build/image128.d71`,
so the boot loads the ML and RUNs it.

```
asm/build.sh
tools/standin.sh tests/standin/fkey-macros.bas
x128 -80col -drive8type 1571 -autostart-warp -autostart "build/standin-fkey-macros.d71:boot 128"
```

They're petcat source (BASIC 7.0), not C64List: `chr$(92)` for `£`, no
`{sym:...}`.

| Program | Tries |
|---|---|
| `scroll.bas` | scrolling, and wrapping a long line at the screen's width |
| `mask.bas` | the screen mask on and off (`&,18`), console text scrolling underneath |
| `status-right.bas` | `&,69` on the 80-column status area's right half, with the mask off and on |
| `lightbar.bas` | the lightbar's labels and default checkmarks, loaded as `im` loads them; the f-keys move the highlight |
| `fkey-macros.bas` | Ctrl/C= + f1/f3/f5/f7 typing `f1$`-`f8$` into an input line |

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

`mask.bas` and `status-right.bas` wait at each step for a byte the
monitor pokes (`$0b00`, the boot loader's cassette buffer, free once
Image runs): `> 0b00 01`, then `02`, and so on. See
`DEBUG_TECHNIQUES.md` for driving x128 from the remote monitor.
