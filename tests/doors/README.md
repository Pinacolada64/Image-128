# Doors for `++ remote`

Plain BASIC 7.0 programs (petcat source) that `i.remote door` runs for a
caller through `++ remote`: on the disk, `<name>.bas` is the PRG file
`door.<name>` on the modules drive (5). `tools/door_test.py` writes them to
a test disk and plays them from the main prompt's `DOOR` command.

| File | Does |
|---|---|
| `guess.bas` | guess a number from 1 to 100: INPUT for each guess, GETKEY for "Play again" |
| `oops.bas` | prints 6/3, 6/2, 6/1, then ?division by zero error in 20: the module reports error 20 in line 20 |
