# Known Issues

Problems known in this alpha of Image BBS 128, and their state. Each is
fixed on a branch of its own; PULL_REQUESTS.md lists them as they're
merged.

## Open

### `++ menu2` leaves cursor droppings in 80 columns

Menus drawn by the `++ menu2` overlay (`IM`'s Configuration Editor, and
others that load it) leave stray cursor cells behind on the VDC screen in
80 columns.

### After any error on the Lt. Kernal, recording it fails too

An error shows "Recording Error, Please Wait..." and then "?load error in
29", and the station drops to the Lt. Kernal's prompt instead of going
back to the BBS. Restart it with `BOOT 128` at the left margin (or
reset it). This may have the same cause as the NEW error below (`im`
line 24 running on into the overlay loader at 28): to be tried again once
PR #48 is merged.

## Fixed, waiting to be merged

### Typing NEW at the login prompt stopped with error #29

A false `if ... then begin ... bend` on one line goes on at the next line
in BASIC 7.0: `im` 24 fell into line 28, the overlay loader, when
`i/lo.new` set the border color, and loaded an overlay named "0". Fixed on
`begin-bend` (PR #48).

### The login banners lost their reversed bar on wide screens

`i/lo.on`'s banners ("Good evening, <name>!", "Xpress Login Active!", and
now "Welcome, New User!") stopped the reversed bar after the text, or put
the rest of it on the next line. Each is now a bar from the left edge to
the caller's last column but one, with the text centered, in 40 and 80
columns. Fixed on `lo-on-banners` (PR #49).

### Pausing output didn't show on the status line

Pausing output with Ctrl-S, or at the console with the 128's NO SCROLL
key (F8 in VICE), now lights the pause indicator: `P` in 40 columns, `Pau`
in 80. While NO SCROLL holds output, the clock and time left keep
counting, and a caller hanging up ends the pause. STATUS_LINE.md,
"Pausing output", has the details. Fixed on `pause-indicator` (PR #50).

### The flashing chat display was in the wrong columns in 80 columns

A chat page flashed row 22's columns 24-39, under `P=` and `V=`, instead
of the window at 64-79. Fixed on `page-flash-80` (PR #51).

### The new user messages were broken for 40 columns, in Title Case

`i/lo.new`'s messages had hard returns in the middle of sentences, laid
out for 40 columns. They're word-wrapped now, and in sentence case.
Fixed on `lo-new-wrap` (PR #52).

### `{sym:}` values left extra spaces in the programs

C64List writes a `{sym:name}`'s value right-justified in a field
(`peek( 2670+2)`). The build now closes those spaces up
(`tools/tighten.py`). Fixed on `sym-spaces` (PR #53).

## Fixed

### The status line's module name (`M=`) was cut short in 80 columns

The name was kept with its drive prefix ("5:") counted in its 16
characters: "i/emp.startturn" showed as `i/emp.starttu`. Fixed on
`status-modname` (PR #46).

### A Lt. Kernal port's modem setup: the wrong port, the shared driver

At boot, `sub.modem` read the station's port with `peek(57092)`, which
read another bank there (port 0 took port 11's setup), and the RS-232
driver came from `e.data` record 32, shared by every station, where `IM`
writes whichever port was set up last. Now the port comes from the Lt.
Kernal itself at boot (`ltkprt`), and the driver from the port's own
record. `IM`'s port prompt also takes 1 and 15 now. Fixed on
`ltk-modem-config` (PR #47).

### Copied files whose length is a multiple of 254 got one byte too many

`++ copier`'s copy (`&,16,0`) read one byte past the end of a file whose
last block was full (254, 508, 762... bytes), and wrote it. Fixed on
`copier-254` (PR #45).
