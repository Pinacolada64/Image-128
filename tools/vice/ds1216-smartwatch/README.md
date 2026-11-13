# A DS1216 SmartWatch on a control port, for VICE 3.8

A joyport device for VICE that emulates a Dallas DS1216 SmartWatch wired to
a control port: the clock Image BBS calls the "Lt. Kernal clock" (setup's
"Lt. Kernal Port 1" or "Port 2"), which `swr.ml` on the C64, and
`++ ltk clock` (`asm/ltk_clock.asm`) on the 128, read by bit-banging CIA 1.
With it, `sub.clocks` im=3 can be tried in x64sc or x128 (11/12/2026).

`vice-3.8-ds1216-smartwatch.patch` adds `src/joyport/smartwatch.c` and
`smartwatch.h`, and registers the device in `src/joyport/joyport.c`,
`joyport.h` (`JOYPORT_ID_SMARTWATCH`, after `JOYPORT_ID_PAPERCLIP2`) and
`Makefile.am`. The DS1216 itself (the 64-bit recognition pattern, then 64
bits of clock data read or written) is VICE's own `src/core/rtc/ds1216e.c`,
which the FD-2000/4000 drives use; the new file turns the port's lines into
its cycles.

## The wiring it emulates

| Control port pin | Joyport bit | SmartWatch |
|---|---|---|
| 1 (up) | 0 | Q (data out, to the computer) |
| 2 (down) | 1 | D (data in) |
| 3 (left) | 2 | /CE (chip enable) |
| 4 (right) | 3 | /WE (write enable) |
| 7 | | +5V |
| 8 | | ground |

A cycle starts when /CE goes low: a write of D with /WE low, a read with
/WE high, and Q then holds the clock's bit until /CE goes high. This is
what `swr.ml` does (`$0f` idle; a write: the bit on line 2, lines 3 and 4
low; a read: `$08`, then line 1). As on a real port, the CIA's own output
wins: the clock can only pull line 1 low where the program left it an
input.

## Building

From a VICE 3.8 source tree (the release tarball):

```
cd vice-3.8
patch -p1 < .../tools/vice/ds1216-smartwatch/vice-3.8-ds1216-smartwatch.patch
./autogen.sh        # Makefile.am changed: regenerate the Makefiles
./configure ...     # as before
make
```

`autogen.sh` needs autoconf and automake. In a tree that's already been
configured and built, the build's own Makefiles can be edited instead (add
`smartwatch.c`, `.h`, `.$(OBJEXT)` and `.Po` beside each `bbrtc` line of
`src/joyport/Makefile.in` and `Makefile`, newer than `Makefile.am`); then
touch every source that includes `joyport.h`, since `JOYPORT_MAX_DEVICES`
grows by one, and run `make`. (11/12/2026, on Debian 13: a tree configured
earlier linked with `-lnsl`, which isn't there any more; taking it out of
`src/Makefile` was enough.)

## Using it

```
x128 -controlport2device smartwatch     # or "ds1216", or its number (42)
x128 -controlport1device smartwatch -smartwatchsave
```

It's listed as "RTC (DS1216 SmartWatch)" among the control port devices
(Settings, Input devices, Control port). It keeps the host's time, offset
by whatever a program sets it to; `-smartwatchsave` (resource
`SmartWatchSave`) saves that offset in VICE's RTC file, as the other RTCs
do.

The weekday register counts as VICE's DS1216 core does: 1 = Monday ... 6 =
Saturday, 0 = Sunday. A real SmartWatch's weekday means whatever the
program that set it counted from, so `sub.clocks` works the weekday out
from the date.

## Trying it

`tools/ltk_clock.py` runs `tests/standin/ltkclock.bas` on a patched x128
with the clock on control port 1 or 2: the port with the clock must read
today's date and time (as the host has them), the other non-digits (no
clock).
