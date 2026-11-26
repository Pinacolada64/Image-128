# Known Issues

Problems known in this alpha of Image BBS 128, and their state. Each is
fixed on a branch of its own; PULL_REQUESTS.md lists them as they're
merged.

## Open

### The flashing chat display starts in the wrong column in 80 columns

When a caller asks to chat, the flashing display doesn't start drawing at
the right column in 80 columns.

### `++ menu2` leaves cursor droppings in 80 columns

Menus drawn by the `++ menu2` overlay (`IM`'s Configuration Editor, and
others that load it) leave stray cursor cells behind on the VDC screen in
80 columns.

### Pausing output doesn't show on the status line

Pausing a caller's output with Ctrl+S (or, at the console, the 128's NO
SCROLL key) should light the status line's pause indicator: `P` in 40
columns, `Pau` in 80. It doesn't.

### After any error on the Lt. Kernal, recording it fails too

An error shows "Recording Error, Please Wait..." and then "?load error in
29", and the station drops to the Lt. Kernal's prompt instead of going
back to the BBS. Restart it with `BOOT 128` at the left margin (or
reset it).

## Fixed, waiting to be merged

### Typing NEW at the login prompt stopped with error #29

A false `if ... then begin ... bend` on one line goes on at the next line
in BASIC 7.0: `im` 24 fell into line 28, the overlay loader, when
`i/lo.new` set the border color, and loaded an overlay named "0". Fixed on
`begin-bend` (PR #48).

### `{sym:}` values left extra spaces in the programs

C64List writes a `{sym:name}`'s value right-justified in a field
(`peek( 2670+2)`). The build now closes those spaces up
(`tools/tighten.py`). On `sym-spaces`.

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
