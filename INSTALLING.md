# Setting up a new system

Image BBS 128 sets itself up the first time it boots from a disk that
hasn't been configured: `build/image128.d81` (`asm/build.sh`'s disk) or a
copy of it. Setup (`i/su.config` and its parts, `modules/sub.su.*`) asks
where Image's drives are, how to set the clock, and the sysop's and the
board's details; then it copies the files from the boot disk to the drives
chosen and writes the configuration files.

> **Not done yet.** The file copy doesn't copy the System (`s.`) and
> Etcetera (`e.`) files yet, nor any RELative (REL) file: below, "What
> the file copy doesn't do yet", for how to put them on by hand.

## Booting Image 128

Put the boot disk in a drive, and at the 128's `READY.` type:

```
RUN "BOOT 128"
```

(`RUN "BOOT 128",U9` for a boot disk in device 9, and so on.) `boot 128`
loads the machine language and `im 128`, and `im` goes on from there: to
the start-up menu below on a disk that isn't set up yet, or to the boot
screen and the idle screen on one that is (SYSOP_COMMANDS.md, "Booting:
the boot screen").

**40 or 80 columns: choose before you boot.** Image 128 runs in the
screen mode the 128 is in when it boots: started on the 40-column screen
(the VIC, a TV or a 1702-style monitor), it runs in 40 columns; started on
the 80-column screen (the VDC, an RGBI monitor), in 80. `im` reads the
screen's width once, at boot (`im 128` line 3062: `sw=rwindow(2)`). So
before typing `RUN "BOOT 128"`:

- hold down the 128's `40/80 DISPLAY` key (down for 80 columns, up for 40)
  when you turn it on or press Reset; or
- in BASIC, press `Esc` then `X` to switch to the other screen.

The mode can't be changed while the BBS is running: switching between the
40- and 80-column screens (and monitors) while it runs is a planned
feature, not written yet (modules/TODO.md). To change it now, take the
BBS down, switch, and boot again. A caller's own width doesn't depend on
this: each caller's screen width is their own (Terminal Parameters).

In VICE: `x128 -80col` or `-40col` picks the screen it starts on
(`start-setup.sh -40` and `start-image-128.sh`'s switches pass it), and
`-autostart "image128.d81:boot 128"` types the `RUN` for you.

## Starting it

Boot the disk (above). With no `bd.data` on it, `im` shows the
start-up menu:

| Key | Does |
|---|---|
| `1` | set up a new system |
| `2` | convert an Image BBS 1.2 system (reads its `d.data`) |
| `3` | convert an Image BBS 2.0 system (reads its `d.data`, moves its `e.data` records, and scratches 2.0's own files if you say so) |

In VICE, `start-setup.sh` boots a fresh copy of `build/image128.d81` each
time (`-40` for 40 columns, `-9 1571` to put a drive 9 on the bus for the
drive scan, `-hd` for a CMD HD as device 9, `-k` to keep the last run's
disk): press `1` at the start-up menu. `tools/setup_test.py` runs the
whole setup by itself (DEBUG_TECHNIQUES.md).

## The parts

Setup is a menu of four parts, each with a check mark once it's done.
Return takes the first part not done yet, so pressing Return all the way
through sets up a system with every default. Inside a part, each item
shows its default: a number asks that item, Return the next one not asked
yet, `D` (or Return once all are asked) is done.

| Part | Asks |
|---|---|
| 1, Devices and Drives | the device and drive (or partition, or Lt. Kernal LU) of each of Image's six drives: System, E-Mail, Etcetera, Directory, Module, User. Each starts as the boot drive. Setup first scans the bus and lists what it found (1541, 1571, 1581, CMD HD/FD, RAMLink, RAMDrive, Lt. Kernal; `?` for a drive it doesn't know, an SD2IEC say); a device that didn't answer, or a drive it can't initialize, is used only if you say so |
| 2, Clock and Time Zone | how the clock is set at boot: by hand, or from a CMD device, a Lt. Kernal, a DS12C887, an Ultimate, a TeensyROM, or the last AutoMaint date. Then the system's time zone, from a list; with daylight saving time, setup also sets the alarms that change the clock (SYSOP_COMMANDS.md, "Daylight saving time") |
| 3, Sysop Information | the sysop's account, user 1: handle, password (typed twice), first and last name, e-mail address |
| 4, BBS Information | the board's name, the main prompt, the chat entry and exit messages, the credits a new user gets |

## Review, copy, write

`R` (or Return once the four parts are done) shows the review: the drives'
table, the clock and time zone, the sysop's handle and the board's name.
A number goes back to that part; `C` (or Return) goes on:

1. **The file copy** (`sub.su.copy`): each file on the boot disk goes to
   the drive it belongs on, by its name's prefix (DATA_FILES.md, "Where
   they are"): `i.`, `i/`, `sub.`, `++ `, `ml.` and `im 128` to the Module
   drive, `nm.` to E-Mail, `d.` to Directory, `u.` to User. A drive that
   is the boot disk itself keeps its files where they are. Each file is
   copied with `++ copier`, then compared with the boot disk's; an old copy
   on the drive is scratched first. `bd.data` and `boot 128` stay on the
   boot disk. A file that fails is written to `setup.log` on the boot disk
   with the reason; you can go on or go back to the review.
2. **The configuration files** (`sub.su.write`): `bd.data` on the boot
   drive (where `e.data` is, and the main prompt), then `u.config` (the
   sysop's account), `u.index`, `e.stats`, `e.data` and `e.access` on the
   drives chosen, and the day's log.

Setup ends by reminding you to run `IM` once online, to finish the
configuration, and the Base Editors for the message bases and the U/D and
U/X libraries. Then the BBS boots.

## What the file copy doesn't do yet

- **System files (`s.`):** the screens and menus. Image 128's boot disk
  has only a few of them (`s.visual`, `s.visual 80`, `s.m.protos`, and
  the time zone and DST files, `s.timezones` and `s.dstrules`); the rest
  are on the Image BBS 3.0
  release's `MASTER D2` disk. They aren't copied to the System drive.
- **Etcetera files (`e.`):** the shipped tables and settings (`e.macros`,
  `e.say` and the rest, DATA_FILES.md) aren't copied to the Etcetera drive
  either; setup writes only its own (`e.stats`, `e.data`, `e.access`).
- **REL files:** a RELative file can't be copied as a stream of bytes, so
  the copy counts any it finds as not copied. Setup makes the REL files a
  new system needs (`u.config`, `u.index`, `e.stats`, `e.data`,
  `e.access`); any other, from an older system or the release disk, has to
  be copied with a tool that knows REL files (a file copier on the 128,
  or the Lt. Kernal's own).

Until then, put the System and Etcetera files on by hand. With c1541, from
the 3.0 release disk to the drive's disk image, giving `,s` for a SEQ file:

```
c1541 "MASTER D2 231231.d81" -read "s.welcome 1 80,s" "s.welcome 1 80"
c1541 build/s_files.d81 -write "s.welcome 1 80" "s.welcome 1 80,s"
```

(Detach the disk in x128 first, and run `tools/diskcheck.py` on it before
and after.) On real hardware, use a file copier that copies between drives;
once the BBS is running, the sysop at the console can also choose
`Copier` from the transfer protocols (SYSOP_COMMANDS.md, "File transfer
protocols"), which copies files between two of the BBS's drives.

**Today in History**: its twelve `today.` files are on a disk of their
own, `build/features.d81` (they'd leave `image128.d81` too full). An
Optional Features part to copy them is planned, not written: copy them to
the Etcetera drive by hand the same way.
