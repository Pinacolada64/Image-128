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
