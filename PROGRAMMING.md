# Programming Image BBS 128 in BASIC

Notes for writing `im` code, modules and test programs that run under
Image BBS 128: things BASIC 7.0 does differently from the C64's BASIC 2,
and how Image's own parts fit around them. Each was tried on an x128
running Image; `tests/standin/gosub.bas` and `tests/standin/mask.bas`
are the programs. What changed in the port itself is in
`PORTING_NOTES.md`; the ML's own BASIC variables (`rc`, `kp%`, `sh`...)
in `BASIC_VARIABLES.md`.

## Where BASIC is

| | 128 | (C64) |
|---|---|---|
| current line, `curlin` | `peek(59)+peek(60)*256` (`$3b`/`$3c`) | 57/58 |
| text pointer, `txtptr` | `$3d`/`$3e` (61/62) | 122/123 |
| BASIC's stack pointer | `peek(125)+peek(126)*256` (`$7d`/`$7e`) | (the CPU's) |

In direct mode the line's high byte is `$ff` (65280 and up). In `.lbl`
files, write the names: `{sym:curlin}`, `{sym:txtptr}`, `{sym:bstkptr}`
(`asm/equates.asm`).

## Errors

### Image's trap: `&,37` on, `&,38` off

`im` turns it on at boot. On an error, Image's trap (`wtrap`,
`asm/wedge.asm`):

- saves the error number in `peek(6)` and its line in
  `peek(7)+peek(8)*256` (`sareg`, `sxreg`/`syreg`; C64 780-782),
- empties both stacks, the CPU's and BASIC 7.0's, as CLR does, and the
  temporary string stack,
- turns itself off (it puts BASIC's own error vector back), and
- goes to line 2000 (`trapline`).

`im`'s line 2000 prints the error ("[Error#.., Line#..]"), closes the
files, loads `im` again and carries on at 4000, Image's error handler,
which logs it. Since the trap is off once it has fired, an error in the
handler before `im` turns it on again stops the program with BASIC's own
message.

### RESUME doesn't work with Image's trap

BASIC 7.0's `resume`, `resume next` and `resume <line>` need what its own
`trap` saved at the error; Image's trap doesn't save it, and has already
emptied the stacks. Under `&,37`, a `resume` gives `?can't resume error`
(and, the trap being off by then, stops the program).

So, in a handler that Image's trap reached, go on with `goto` to a line
you know. Where a routine really needs to resume, use BASIC 7.0's own:

```
&,38:trap 5000          : rem Image's trap off, BASIC's on
... the code that may fail ...
trap:&,37               : rem BASIC's off, Image's on again
...
5000 ... er, el, err$(er) ...:resume next
```

`er` is the error number, `el` its line and `err$(er)` its message
(BASIC 7.0's: `el` can't be a variable of your own). With both on,
Image's wins.

## BASIC 7.0's stack

FOR, GOSUB and DO keep their frames on BASIC 7.0's own stack at
`$0800`-`$09ff`, not on the CPU's (the C64 keeps them on the CPU's).
`$7d`/`$7e` points at the newest frame's first byte; `$09ff` (2559) is
empty.

| Frame | First byte | Size | Then |
|---|---|---|---|
| FOR | `$81` | 18 | the variable's address (bank 1), STEP, sign, TO, line, text pointer |
| GOSUB | `$8d` | 5 | line, text pointer |
| DO | `$eb` | 5 | line, text pointer |

BEGIN/BEND puts nothing there: an unclosed BEGIN block can't leave
garbage.

### What leaves garbage

A frame whose RETURN, NEXT or LOOP never runs stays on the stack:

- a `goto` out of a subroutine, a FOR loop or a DO loop (EXIT leaves a DO
  loop without a trace);
- a GOSUB to a line that doesn't exist, caught with `trap` and `resume
  next`: GOSUB puts its frame on before it looks for the line, and the
  error doesn't take it off. `&,66,1` does the same.

Each one takes stack space for good. The stack holds about 66 GOSUB
frames (fewer FOR frames, at 18 bytes), and evaluating an expression
needs free room there too, so it usually runs out as `?formula too
complex` (error 25) on an ordinary statement, before GOSUB's own `?out of
memory`; a handler for it can't evaluate anything either until the stack
is cleared. An error that reaches Image's trap clears it, as do CLR and
RUN.

### `sub.stack`: looking at it

`a$="stack":gosub 74` (or `gosub 450`) runs `sub.stack`, which lists the
frames on BASIC 7.0's stack with their lines (a FOR's with its variable),
past the two GOSUBs that called it. If there are more, it offers to clear
them by forcing a `?syntax error` on its own line (63022), which Image's
trap logs and recovers from. Frames from further out (a check run from
inside a module's own FOR loop) look the same as garbage: they're listed,
and cleared too.

## GOSUB and GOTO from the ML: `&,66`

`a%=<line>:&,66,1` is a GOSUB to line `a%` (its RETURN comes back to
the statement after the `&`); `&,66,0` is a GOTO. The line must be under
32768 (`a%` is an integer).

## Writing `&` output

- After THEN, write `then:&"..."`: the wedge only sees `&` at the start
  of a statement, so `then &"..."` is a `?syntax error`.
- With `lp=1` before it, a string is printed with word wrap, and the ML
  ends the line itself unless the string ends with a space; `lp` is back
  to 0 after each string, so set it before each one.

## Test programs

`tests/standin/` programs are petcat source, not C64List: `\` is the `£`
(`\!i` prints `i` by MCI), and there's no `{sym:...}`. `sys 7171` turns
Image's trap off; call `&,37` to try it. See `tests/standin/README.md`.
