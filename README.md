# Image BBS 128

A port of Image BBS 3.0 for the Commodore 64 to the Commodore 128.

## Programming Resources

https://rvbelzen.tripod.com/128intpt/index.html

[C64Studio](https://github.com/GeorgRottensteiner/C64Studio) by Georg Rottensteiner

## Design goals

### BASIC

* Use more BASIC 7.0 commands where possible

### ML

* `&,9`: fix outputting numeric variables to window
* update `ak$` (seperator line) whenever `ll%` (user line length) changes
* `£g_x_`: put value of key pressed into `kp%` after key hit. This eliminates `an=asc(an$+nl$)`, or similar code.
* output to the VDC for 80 column sysop screen

## BASIC 7.0 Notes

* `asc("")` has been fixed to return `0`, not `?illegal quantity error`, so no need to append `nl$` as above
* `EL`, `ER` and `DS`/`DS$` are reserved variables: `dim el` or `el=5` is a `?syntax error`, so `im`'s error line is `e1`
* the 40/80 key is `peek(54533) and 128` (0 = down = 80 columns); `rwindow(2)` is the current screen's width

## Building

On Linux, `asm/build.sh` builds everything (the modules, the ML cut into
the parts the boot loads, `boot 128` and `im 128`) and writes
`build/image128.d81`, a 1581 disk (the 128 loads it in burst mode; the
modules need more room than a 1571 has). To run it in VICE with a 1581 as
drive 8:

    x128 -drive8type 1581 -autostart "build/image128.d81:boot 128"

(or attach the disk and `RUN "BOOT 128"`). The memory map is at the
top of `asm/memory 128.txt`.

`PORTING_NOTES.md` has what differs between the C64 and the 128 and
how the port deals with it; `PROGRAMMING.md`, writing BASIC for Image
128 (errors and TRAP, BASIC 7.0's stack, `&` output);
`BASIC_VARIABLES.md`, the variables the ML uses; `DEBUG_TECHNIQUES.md`,
how problems were tracked down; `tests/standin/README.md`, the test
programs.

`im 128.bas` needs C64List 4.06: 4.04 ignores the `{tokenizer}` directives in
`Basic70.bas` (copied from C64List 4.06), so BASIC 7.0 keywords would come out
as plain letters.

    c64list.exe "im 128.bas" -prg -ovr

Don't add `{:labels}` to it: one label makes C64List renumber every line from 0.

`asm/vdc.asm` is the TADA client's 8563 VDC code; `&,69` (`dispstr` in
`asm/shdlr.asm`) uses it in 80 columns.
