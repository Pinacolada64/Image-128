# Tools: running Image BBS 128 on VICE's Lt. Kernal

The `tools/ltk_*.py` scripts run x128 with VICE's emulation of the Lt.
Kernal hard drive: the host adapter's boot ROM (`ltk.crt`) and three drive
images (`disk0.dlk`, `disk1.dlk`, `disk2.dlk`). Each script's own header
(`tools/<script> --help`) has the details; this is where to start.

Run them from the repo's top directory. Most need a build first:

```
asm/build.sh            # build/image128.d81: the ML, im 128 and the modules
```

## What they need

| What | Where | Set with |
|---|---|---|
| VICE 3.8 (`x128`), `c1541`, `petcat` | on the `PATH` | |
| the Lt. Kernal's boot ROM and blank drive images (DOS 7.2 installed, CONFIG's "cpu mode" 00, C128, for ports 00 and 01) | `~/Documents/c64/ltkernal/ltk128-images/` (`ltk.crt`, `disk0-2.dlk`) | `LTK_DIR=...` |
| tcpser, the modem | `~/bin/tcpser/tcpser` | `TCPSER=...` |
| the monitor port each x128 is driven through | each script has its own | `VMON_PORT=...` |

The drive images hold every byte inverted (XOR `$ff`): search them for a
file's bytes that way.

## Which drive images

| Images | What's on them | Made by |
|---|---|---|
| `LTK DIR` | the Lt. Kernal as installed: LU 10, no Image | the Lt. Kernal's own install |
| `build/ltk/` | a working copy of LTK DIR (most stand-in tests use it) | `ltk_chatmode.py` and the others, the first time or with `--fresh` |
| `build/ltk-installed/` | Image's boot disk copied onto LU 5, not set up yet | `ltk_install.py` |
| `build/ltk-configured/` | a configured system: Image on LU 5, its System and Etcetera drives on LU 6 | `setup_test.py --ltk 5`, then `cp build/ltk/disk*.dlk build/ltk-configured/` |
| `build/ltk-2users/` | the same, with TEST ACCOUNT (ID 2, password TEST1) | the new-user application, by hand |

A test that boots a configured system works on a copy of its images
(`build/ltk-bbs2/`, `build/ltk-primetime/`...), so the originals don't
change. `ltk_start.py` and `ltk_copy.py --save` are the ones that change
the images you give them.

## Using the BBS: `ltk_start.py`

```
tools/ltk_start.py --images build/ltk-configured
```

Boots Image from LU 5 in 80 columns, with tcpser as the modem (a
configured system's boot waits until its modem answers) and the DS12C887
clock: at the Lt. Kernal's `c128 d#08` prompt it types `LU 5`,
`LOAD"BOOT 128",8` and `RUN`, then x128 is yours. Callers telnet to port
6140 (`--telnet`); tcpser's log is `tcpser.log` beside the images. Closing
x128 stops tcpser.

- `--lu N`: Image's LU, if not 5
- `--no-boot`: type nothing; boot it yourself
- `--warp`: start in warp mode (the BBS clock runs fast too)
- `--telnet PORT`, `--link PORT` (x128 to tcpser, 25260), `--monitor PORT`
  (6620): when another BBS has those

The images are used in place: what the BBS writes stays.

## Putting new modules on it: `ltk_copy.py`

```
asm/build.sh
tools/ltk_copy.py --images build/ltk-configured --lu 5 --save i.IM i/lo.logoff
```

Copies each file named (as `c1541` lists it: `i.IM` with a shifted I and
M) from `build/image128.d81` (or `--source`) onto the LU: the old copy
scratched, `++ copier`, then a compare. It works on a copy of the images
(`build/ltk-copy/`); with `--save`, and only if every file copied, each
image it changed goes back in place, and the old one is kept as
`<image>.before-<date>-<time>`. Without `--images` it uses LTK DIR and LU
10.

The stand-in (`tests/standin/ltkcopy.bas`) prints in rows 16-23, below
`++ copier`'s block display (rows 2-8) and counters (row 15), and leaves
its result at `$0b00`-`$0b02` (files copied, failed, 1 when done), which
`ltk_copy.py` reads: the screen's text can be drawn over.

## Making a configured system

```
asm/build.sh
tools/standin.sh tests/standin/ltkinstall.bas
tools/ltk_install.py --fresh                     # the boot disk onto LU 5
tools/setup_test.py --ltk 5 --out build/ltk-setup.d81   # i/su.config, every default
mkdir -p build/ltk-configured && cp build/ltk/disk*.dlk build/ltk-configured/
```

To replace one file on an installed system: put its images in
`build/ltk-installed/`, then `tools/ltk_install.py --base installed --source
DISK --no-keep` (DISK holding just that file); or use `ltk_copy.py`.

## Tests

| Script | Before it | Tries |
|---|---|---|
| `ltk_bbs2.py [--from DIR] [--modem] [--user2 ...]` | a configured system | two stations (ports 0 and 1) booted from LU 5, logged on, chatting through `LTK` (`++ chatmode`), the transcript, logoff marking a station offline |
| `ltk_primetime.py [--from DIR]` | a configured system | IM's Prime Time screen |
| `ltk_chatmode.py` | `tools/standin.sh tests/standin/chatmode.bas`, and `++ chatmode` written onto its disk | `++ chatmode` on one station |
| `ltk_chat2.py` | `tests/standin/chat2.bas`, as above | `++ chatmode` between two stations |
| `ltk_lock.py` | `asm/build.sh ml`, `tests/standin/lock.bas` | `&,13`'s locks between two stations |
| `ltk_dos.py` | `tests/standin/ltkdos.bas` | the Lt. Kernal's DOS, a part at a time |

Most take `--keep` (leave x128 running at the end) and `--fresh` (copy
LTK DIR's images to `build/ltk/` again).

## Without the Lt. Kernal

- `start-image-128.sh`: the BBS from 1581 disk images
  (`build/setup-test.d81`, or `DISK=...`), with tcpser on port 6128
- `start-setup.sh`: the new-system setup
- `start-desterm.sh`: DesTerm 128, to call the BBS
  (`atdt127.0.0.1:6128`, or 6140 for `ltk_start.py`'s)
- `tools/standin.sh tests/standin/<name>.bas`: a stand-in test disk
  (`tests/standin/README.md`)
