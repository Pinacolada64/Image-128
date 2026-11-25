# Known Issues

Problems known in this alpha of Image BBS 128, and their state. Each is
fixed on a branch of its own; PULL_REQUESTS.md lists them as they're
merged.

## Open

### Logging in as a new user stops with error #29

Typing `NEW` at the login prompt (to apply as a new user) stops the BBS:
"SYSTEM ERROR #29 (load error) In Line:29 Of im", and the station drops to
the Lt. Kernal's prompt. `im` line 29 loads an ML overlay (`++ name`); the
status line shows "Area ++ 0", so it was asked for an overlay named "0",
which doesn't exist. `i/lo.new`, the new-user module, is on the disk and
loads by itself. Seen on the Lt. Kernal (11/25/2026).

### The flashing chat display starts in the wrong column in 80 columns

When a caller asks to chat, the flashing display doesn't start drawing at
the right column in 80 columns.

### `++ menu2` leaves cursor droppings in 80 columns

Menus drawn by the `++ menu2` overlay (`IM`'s Configuration Editor, and
others that load it) leave stray cursor cells behind on the VDC screen in
80 columns.

### After any error on the Lt. Kernal, recording it fails too

An error shows "Recording Error, Please Wait..." and then "?load error in
29", and the station drops to the Lt. Kernal's prompt instead of going
back to the BBS. Restart it with `BOOT 128` at the left margin (or
reset it).

## Fixed, waiting to be merged

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
