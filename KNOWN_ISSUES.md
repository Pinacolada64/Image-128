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

### The status line's module name (`M=`) is cut short in 80 columns

On the status line's row of counters, the name of the module running
(`M=i/emp.island`, `M=sub.modem`) doesn't show in full in 80 columns.

### The flashing chat display starts in the wrong column in 80 columns

When a caller asks to chat, the flashing display doesn't start drawing at
the right column in 80 columns.

### `++ menu2` leaves cursor droppings in 80 columns

Menus drawn by the `++ menu2` overlay (`IM`'s Configuration Editor, and
others that load it) leave stray cursor cells behind on the VDC screen in
80 columns.

### Setting up a Lt. Kernal port's modem changes the others' interface

On a multiplexed Lt. Kernal, each port has its own modem setup in
`e.i.modem` (a record a port), chosen in `IM`, `J` (Modem Config). But
saving it also writes the modem interface (SwiftLink, user port) to
`e.data` record 32, which all the stations share: setting up port 1's
modem made port 0's next boot wait for a modem it doesn't have. The
interface belongs in the port's own record.

### `IM`'s modem setup can't choose port 1 or port 15

"Edit Modem Config for Which Port?" (`i/IM.modem` line 4018) takes 0 and
2-14 only: `val(an$)>1 and val(an$)<15`. A Lt. Kernal has ports 0-15.
Until it's fixed, set up a port's modem at that station: Return there
chooses the station's own port.

### After any error on the Lt. Kernal, recording it fails too

An error shows "Recording Error, Please Wait..." and then "?load error in
29", and the station drops to the Lt. Kernal's prompt instead of going
back to the BBS. Restart it with `BOOT 128` at the left margin (or
reset it).

## Fixed, waiting to be merged

### Copied files whose length is a multiple of 254 got one byte too many

`++ copier`'s copy (`&,16,0`) read one byte past the end of a file whose
last block was full (254, 508, 762... bytes), and wrote it. Fixed on
`copier-254` (PR #45).
