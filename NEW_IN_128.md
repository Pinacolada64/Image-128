# New in Image 128

Image BBS 128 is Image BBS 3.0 for the Commodore 64, ported to the
Commodore 128. Besides running on the 128, it adds these. Where a
feature has its own section, it's named in brackets: most are in this
manual's chapters, and PULL_REQUESTS.md lists the change each came from.

## The 128 itself

- **40 or 80 columns.** The console runs on the 40-column screen (VIC) or
  the 80-column screen (VDC), whichever the 128 is in at boot (Setting up,
  "Booting Image 128"). Switching while the BBS runs is planned.
- **An 80-column sysop screen.** In 80 columns the screen mask uses the
  whole width: a system box, and on row 22 the program and variable space
  (`P=`, `V=`), the BASIC line (`L=`) and the last module loaded (`M=`)
  (The status area).
- **2 MHz:** `++ net` runs at 2 MHz in 80 columns; `++ net`, `++ copier`
  and `++ 2` show their counters on the VDC; the lightbar's `mHz`
  checkmark shows the CPU's speed.
- **BASIC 7.0.** `im` and the modules run in BASIC 7.0, with the program in
  bank 0 and its variables and strings in bank 1; modules can use BASIC
  7.0's keywords (Programming).
- **The Lt. Kernal's multiplexer.** Several 128s on one Lt. Kernal hard
  drive: `&,13`'s locks between stations, setup on Lt. Kernal LUs, and
  `++ chatmode`, a chat room between stations (Sysop Commands, "`LTK`:
  Lt. Kernal Chat").

## Setting up

- **A new installer.** A menu of parts (drives, clock and time zone, sysop,
  BBS), each showing its defaults, so Return all the way through sets up a
  system; a scan of the bus that names each drive; the files copied to the
  drives chosen; conversion from Image 1.2 and 2.0 (Setting up a new
  system). The file copy doesn't copy System, Etcetera or REL files yet.
- **The boot screen's blocks-free list** shows each drive's device, drive
  and kind (1581, CMD HD, Lt. Kernal...) (Sysop Commands, "Booting").

## The clock and time

- **Daylight saving time.** Rules per time zone, the clock changed when
  they say, even if the BBS was off then; `IM`'s DST Rules editor (Sysop
  Commands, "Daylight saving time").
- **Time zones** from a list of 37, each with its daylight time name.
- **More clock sources:** CMD, Lt. Kernal, DS12C887, an Ultimate (read, and
  written back) and TeensyROM, or the last AutoMaint date (`IM` K).
- **Prime Time** shown and set in `IM` (12A and 12P typed and shown
  right), able to run past midnight, and `PRIME` down the screen's right
  edge while it's on.
- **Alarms by weekday**, each checkmark shown with its label.

## The screen and the lightbar

- **The status line reworked** for 40 and 80 columns: each indicator
  drawn by one routine, three-letter labels in 80 columns (The status
  area).
- **`IM` H's Lightbar Labels editor** for the lightbar's 64 labels.
- **The border color on events** (an error, a new user, feedback, a failed
  login), while the lightbar's right `Dbg` is on.
- **The separator line `ak$`** always as wide as the caller's screen.

## Callers

- **File transfers:** `++ punter` (Punter, Relaxed Punter, Image 1.3
  Punter) and `++ xmodem` with **Xmodem-1K**, new: on the C64 its 1K block
  didn't fit (Sysop Commands, "File transfer protocols").
- **`++ visual`, a full-screen editor**, alpha: pages, word wrap, a help
  screen (`++ visual`: the full-screen editor).
- **ANSI callers** get Esc through for cursor and screen codes, and one
  cursor-position code where `&,70` sent many cursor moves.
- **Lists in columns:** the time zone and protocol lists, and others that
  use `sub.columns`, in as many columns as the caller's screen has room for.
- **Mail file names** keep 14 characters of the handle (3.0: 13; `i.rename
  mail` renames older ones).

## The sysop

- **Image Terminal's phone book** keeps a graphics mode and speed for each
  entry, set when it's dialed (Sysop Commands, "Image Terminal").
- **The modem's escape character** (S2) is a setting, `IM` J's flag 13
  (Sysop Commands).
- **"Image BBS 128 v1.0"** in the menu headers, the macro editor,
  Auto-Maintenance and `VE`.

## Programming

- **`PRINT USING` for callers:** `&,15,9` catches what BASIC 7.0's
  `PRINT USING` formats, for `&` to print (Formatting numbers); modules
  can write BASIC 7.0's keywords as they are.
- **New `&` calls:** `&,15,7` centers a string for the caller's width;
  `&,15,8` gives the widest of `tt$()`; `&,13` locks between Lt. Kernal
  stations (Programming).
- **The MCI tab** (`£←nn`) counts columns on the caller's line, not the
  console's.
- **The 128's screen editor's Esc codes** in `&` output on the console
  (clear to the end of the line or the window, and the rest).
- **`columns.lbl`**, the list-in-columns routine, as an include for `sub.`
  modules (Programming, "Lists in columns").
- **Testing:** `i.test calls` and `i.test clocks` try the `&` calls and the
  clock sources on a running BBS; `tools/` runs the BBS, setup and the
  overlays in VICE's x128 from scripts (Debugging techniques).
- **`make docs` and `make manual`** build these docs as PDFs, one each or
  this one book.
