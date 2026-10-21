# Debugging techniques

Ways of finding bugs in Image BBS 128 under VICE's x128 that have worked.
The monitor commands work the same typed into the monitor (Alt+H) or sent
through the remote monitor (`-remotemonitor`).

## Find the instruction that changed a byte

When a byte ends up wrong and you don't know who wrote it, a *range*
tracepoint with a condition fires on the first instruction executed after
the condition becomes true. Have it delete itself so it fires only once:

```
trace exec 0000 ffff if @cpu:$00 == $01
command 1 "delete 1"
```

(Use the checkpoint number `trace` prints in place of `1`.) The logged
instruction is the one *after* the change; the instruction before it is
the culprit. If that's in ROM, disassemble the ROM there (see below).

This found the garbage character set (commit b311325): `$00`, the CPU
port's direction register, became `$01`. The first hit was an `RTS` at
`$cc49` in the screen editor, right after `sta ($e2),y`, the color store
of its character output, with `$e2` (`colptr`) zeroed. A second range
tracepoint on `@cpu:$e1 == $00` led to Image's swapper, which was
swapping each page with page zero.

A plain store checkpoint (`trace store 0000`) never fired for this, so
when a byte changes and the store checkpoint stays quiet, use the range
tracepoint.

## Only stop in Image's own code

Image's resident ML is at `$c000`-`$cfff` and `$e000`-`$feff`, the same
addresses as the screen editor and KERNAL ROMs, so a checkpoint there
also fires whenever the ROM runs. Add a condition on the MMU
configuration (Image's code runs with `$ff00` = `$7e`, cfg_ml):

```
trace exec c0f5 if @io:$d500 == $7e
```

The configuration register reads back as `@io:$d500` or `@cpu:$ff00`;
`@io:$ff00` reads `$ff`, so a condition on that never matches.

## See what led to a BRK

A BRK in 128 mode drops into the KERNAL's own monitor, so VICE's CPU
history is soon full of its input loop. Put a tracepoint on the KERNAL
monitor's BRK entry (`$b003`, where `$0316` points) with a `chis`
command, and log the monitor's output to a file:

```
logname "brk.log"
log on
trace exec b003
command 2 "chis 400"
```

The log then holds the 400 instructions before the BRK. The history only
holds about 2,400 instructions in all.

Two things that didn't work: patching the BRK vector to a JAM opcode
(im's error handler calls RESTOR, which puts the vector back), and
`break` checkpoints through the remote monitor (they didn't stop the
CPU; tracepoints did).

## Log every write to an address

```
logname "store.log"
log on
trace store d018
```

then group the log by writer and value, for example:

```
grep "^\.C:" store.log | awk '{print $1, $7}' | sort | uniq -c
```

That showed only the screen editor writing `$d018` and `$01`, which ruled
out Image's own code.

## Monitor banks on x128

`bank` lists them. The useful ones:

| Bank | Shows |
|---|---|
| `cpu` | memory as the CPU sees it now (`$00`/`$01` are the CPU port, `$ff00` the MMU) |
| `ram00`, `ram01` | RAM banks 0 and 1, raw (ignores shared RAM) |
| `io` | I/O registers; `io d000`, `io d500` describe the VIC-II and the MMU in words |
| `vdc` | VDC memory |

`ram00`/`ram01` read the RAM chips directly, so they don't show the MMU's
shared RAM. To test what the CPU sees in another bank, run a few bytes of
test code from the stack page, which is always shared.

## Screenshots of the 40-column screen

In this x128 the monitor's `screenshot` (`scrsh`) saved the 80-column
window. `-exitscreenshotvicii <file>` saves the VIC-II screen when x128
quits, so end with the monitor's `quit` rather than killing it.

## Check a ROM address

Disassemble the 128 (or C64) ROM images VICE ships, next to each other,
with py65 (from TADA's virtualenv) before trusting a ROM address in
`equates.asm`. BASIC 7.0's jump table at `$af00` and the screen editor's
at `$c000` are the stable entry points (Compute's 128 Programmer's Guide,
pp. 323-325).

## Test the ML's output with a stand-in "im 128"

To exercise Image's output (scrolling, wrapping) without `im`, write a
short BASIC program that prints with `&`, save it over `im 128` on a
scratch copy of the disk, and boot that: the ML loads and RUNs it. First
`sys 7171`, intro's `setup`, as `im` does on line 3074: without it the
screen mask's row tables, the cassbuff variables and the rest are never
set (the mask toggle, `&,18`, then swaps rows through garbage pointers
and runs into a BRK). Then the flags `setup` doesn't set: `passmode`
(2794), or `&` output may go through password mode (every character
printed as the mask), and `scnmode` (2787: 1 = mask off):

```
5 sys 7171:poke 2794,0:poke 2787,1
6 &chr$(147)
10 for i=1 to 30:&"line"+str$(i)+" of the scroll test"+chr$(13):next
15 &,18,1
```

Tokenize it with `petcat -w2 -l 1c01`. To pause it until the monitor
says go (to set checkpoints after the boot, or take a screenshot), loop
on a byte the monitor pokes: `20 if peek(2816)=0 then 20` (`$0b00`, the
boot loader's cassette buffer, is free once Image is running).

## Getting a log out of VICE

VICE writes the monitor log (`logname`, `log on`) when it exits through
the monitor's `quit`; killing x128 leaves the file empty. Set
checkpoints after autostart has finished: connecting to the monitor in
the first seconds of the boot can stop the autostart from running the
program.

## Remote monitor port

Run test copies of x128 with `-remotemonitoraddress 127.0.0.1:6537` (any
port but 6510, which a VICE you're using yourself may already have).
