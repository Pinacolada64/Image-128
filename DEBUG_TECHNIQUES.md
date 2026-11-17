# Debugging techniques

Ways of finding bugs in Image BBS 128 under VICE's x128 that have worked.
What they found is in `PORTING_NOTES.md`.
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

## C64List assembles an out-of-range branch without a word

C64List 4.04 doesn't report a branch whose target is more than 128 bytes
away: it assembles it with a wrong offset (`$ff` in the case found) and
the build says "0 Errors". Code moved further from a branch's target
then silently goes somewhere else. When a routine stops being reached
for no clear reason, check the assembled branch: find its bytes in the
built part (`build/ml.res2` etc., which start with the load address) or
in a `-lst:` disassembly, and compare the target with `ml.sym`. Use
`bxx skip / jmp target` for anything that might be far.

Found 2026-10-20: swapscn's `bmi vdcmask` stopped reaching vdcmask once
vdcrinit and vdcrcopy went in between, and the mask toggle silently
skipped the VDC side.

## Scripting x128: tools/vmon.py and tools/setup_test.py

`tools/vmon.py` starts x128 with its remote monitor on port 6537 and
drives it: `cmd()` sends monitor commands, `mem()` reads memory,
`screen()` reads the 40- or 80-column screen as text, `type()` fills
the keyboard buffer. Each call takes a fraction of a second: it reads
each answer until the monitor's prompt comes back (and goes quiet, since
VICE can print a prompt twice) instead of waiting out a timeout.

`tools/setup_test.py` runs the new-system setup on a copy of the boot
disk (`build/setup-test.d81`): 1 at the start-up menu, Return at every
prompt (each takes its default) and 1 at the clock menu, logging each
part as the setup's frame shows it; then it watches `im` boot from the
new configuration and prints where it stopped. About a minute for the
setup in warp mode.

## Using features in VICE

The x128 (VICE 3.8) command-line switches that give Image the hardware
it uses, as `start-image-128.sh`, `start-setup.sh`, `start-desterm.sh`
and the tools pass them. `x128 -help` lists them all; `+name` turns off
what `-name` turns on. A switch on the command line is for that run;
it only ends up in `vicerc` when Save settings on exit (`-saveres`) is on.

### The machine, the screen and starting a disk

| Switch | Does |
|---|---|
| `-ntsc` | an NTSC machine (`-pal` for PAL) |
| `-80col` / `-40col` | start in 80 columns (the VDC) or 40 (the VIC-II) |
| `+sound` | sound off (the tools run this way) |
| `-warp` | warp mode from the start |
| `-autostart-warp` | warp only while autostart loads, then 1x |
| `-autostart` | `"d.d81:boot 128"`: attach `d.d81` to drive 8 and `RUN` the file `boot 128` |

```sh
x128 -ntsc -80col -drive8type 1581 -autostart-warp \
	-autostart "build/setup-test.d81:boot 128"
```

### ROMs: JiffyDOS

| Switch | Does |
|---|---|
| `-kernal` | `<file>`: the C128 KERNAL (`$JIFFYDOS/JDOS128.rom`) |
| `-dos1581` | `<file>`: every emulated 1581's DOS (`$JIFFYDOS/Jiffy1581.rom`) |

`JIFFYDOS` is `~/Documents/c64/JiffyDOS` unless set; the start scripts
take another directory from it.

### Drives

| Switch | Does |
|---|---|
| `-drive8type` | drive 8's model: `1541`, `1571`, `1581`, `4000` (CMD FD-4000), `4844` (CMD HD), `0` (none) |
| `-drive9type` | the same for drive 9 (`-drive10type`, `-drive11type` likewise) |
| `-9` | `<image>`: attach a disk image (`.d81`, `.dhd`...) to drive 9 (`-8`, `-10`, `-11` likewise) |
| `-dos4000` | `<rom>`: the FD-4000's DOS (not in the repo) |
| `-dosCMDHD` | `<rom>`: the CMD HD's boot ROM (`ROMs/cmd_hd_bootrom_v2.80.bin`, not in git) |

```sh
sh start-setup.sh -9 1571     # a 1571 as drive 9 for the bus scan
sh start-setup.sh -hd         # a CMD HD as drive 9 (build/setup-try.dhd)
```

`start-image-128.sh`: drive 8 is the run disk (`build/setup-test.d81`),
drive 9 `build/s_files.d81` (DATA_FILES.md). Detach a disk in x128
before changing its image outside it: x128 writes its own copy back.

### The clock: a DS12C887 RTC

| Switch | Does |
|---|---|
| `-ds12c887rtc` | the DS12C887 real-time clock cartridge |
| `-ds12c887rtcbase` | `0xd700`: at `$d700` (`$de00` is the SwiftLink's, `$d500` the 128's MMU) |
| `-ds12c887rtcrunning` | its oscillator running from power-on |
| `-ds12c887rtcsave` | keep its time between runs (`start-image-128.sh` only) |

In IM's clock settings this is `sub.clocks`' DS12C887 method (`ck=4`,
`cp=55040`). `tools/dst_test.py` adds `-warp` to these to run the
autumn DST change.

### The modem: a SwiftLink and tcpser

| Switch | Does |
|---|---|
| `-acia1` | the ACIA cartridge (SwiftLink) |
| `-acia1base` | `0xde00`: at `$de00` |
| `-acia1mode` | `1`: SwiftLink mode (`0` normal, `2` Turbo232) |
| `-acia1irq` | `1`: on NMI (`2` IRQ) |
| `-myaciadev` | `<0-3>`: which RS-232 device it uses: `0` is `-rsdev1`, `2` `-rsdev3` |
| `-rsdev3` | `127.0.0.1:<port>`: RS-232 device 3 is a TCP connection to tcpser |
| `-rsdev3ip232` | ip232 on it (tcpser `-v`), which carries DCD and DTR too |
| `-rsdev3baud` | `19200`: its speed (IM's "tcpser (VICE)" modem profile) |
| `-userportdevice` | `0`: nothing on the user port, so its RS-232 can't take the connection (`2`: a user-port modem) |

```sh
x128 -acia1 -acia1base 0xde00 -acia1mode 1 -acia1irq 1 -myaciadev 2 \
	-userportdevice 0 \
	-rsdev3 127.0.0.1:25232 -rsdev3ip232 -rsdev3baud 19200 ...
```

`tools/netpair.py` does the same on `-rsdev1` (`-myaciadev 0`), and
`tests/standin/README.md` has a user-port modem instead
(`-userportdevice 2 -rsuserdev 0 -rsuserbaud 1200 -rsdev1 ...`). Two
x128s can run at once on different tcpser ports (`start-desterm.sh`
calls the BBS: `atdt127.0.0.1:6128`); the RS-232 section below has what
the connection does.

### The Lt. Kernal hard drive

| Switch | Does |
|---|---|
| `-cartcrt` | `<dir>/ltk.crt`: the Lt. Kernal host adapter, from its cartridge image |
| `-ltkimage0` | `<file>.dlk`: hard drive 0's image (`-ltkimage1`, `-ltkimage2`: the others) |
| `-ltkport` | `<0-15>`: this computer's port on the multiplexer |
| `-ltkserial` | `<8 digits>`: the serial number the DOS install disks are keyed to (default 87000000) |
| `-drive8type` | `0`: no drive 8 (as the Lt. Kernal tools run it) |

```sh
LTK=~/Documents/c64/ltkernal/ltk128-images
x128 -cartcrt $LTK/ltk.crt -ltkport 1 \
	-ltkimage0 build/ltk/disk0.dlk -ltkimage1 build/ltk/disk1.dlk \
	-ltkimage2 build/ltk/disk2.dlk \
	-drive8type 0 -drive9type 1581 -9 build/standin-chat2-1.d81
```

Two x128s on the same `.dlk` images with ports 0 and 1 are two stations
sharing one Lt. Kernal (`tools/ltk_chat2.py`, `tools/ltk_lock.py`); the
tools copy the images to `build/ltk/` first (`LTK_DIR` for others).

### Debugging

| Switch | Does |
|---|---|
| `-remotemonitor` | the monitor over TCP, for `tools/vmon.py` |
| `-remotemonitoraddress` | `127.0.0.1:6537`: on 6537, not the 6510 your own VICE has (below) |
| `+remotemonitor` | none (`start-desterm.sh`, beside the BBS's x128) |
| `-jamaction` | `1`, "continue": on a JAM the CPU stays jammed and the remote monitor answers; `2`, "Monitor": x128's own monitor window, and the remote monitor stops answering |
| `-exitscreenshotvicii` | `<file>`: save the VIC-II screen when x128 exits |

```sh
x128 -80col +sound -remotemonitor -remotemonitoraddress 127.0.0.1:6537 \
	-jamaction 1 -autostart "build/setup-test.d81:boot 128"
```

`tools/setup_test.py --vice <arg>` passes one more argument to x128
(repeat it), e.g. `--vice -drive9type --vice 4000`.

## RS-232 in VICE

The ACIA (`-acia1 ...`) and the user port modem (`-userportdevice 2`)
both connect to `-rsdev1 host:port` as a TCP client, raw bytes both
ways. A listener for them has to accept more than one connection: VICE
connected once at start-up and again when the driver dropped and
raised DTR, and the first connection closed. Test at normal speed: in
warp mode the SwiftLink lost the odd incoming byte that it didn't at
1x. `tests/standin/README.md` has the command lines.

## Getting a log out of VICE

VICE writes the monitor log (`logname`, `log on`) when it exits through
the monitor's `quit`; killing x128 leaves the file empty. Set
checkpoints after autostart has finished: connecting to the monitor in
the first seconds of the boot can stop the autostart from running the
program.

## Remote monitor port

Run test copies of x128 with `-remotemonitoraddress 127.0.0.1:6537` (any
port but 6510, which a VICE you're using yourself may already have).
