# Sysop Commands

Commands for the sysop and maintenance users of Image BBS 128, as they
work on the 128: what to type, what you'll see, and how to read it. How
they work inside is in `PROGRAMMING.md`.

## `VL`: Variable List

Shows the BBS's BASIC variables and their values as they are right now.
Use it to see what a module left behind, check a setting the BBS is
using, or look at the state after something went wrong.

### Running it

Type `VL` at the main prompt. It's a main prompt maintenance command,
set up in the Extended Command Set (`e.ecs.main`) to run the module
`i.VL`; who may use it is set in that entry (`IM`, then the ECS editor).

### What you see

The values here are only an example:

```
 Image 128 Variable List 1.0

Press any key to abort.
 Simple Variables:
A$ ="VL"
AC%= 10
BD = 2400
CM$="i.VL"
...

View Arrays? [No]
```

One line per variable: its name, then `=` and its value.

| Name ends in | Type | Value shown as |
|---|---|---|
| (nothing) | number | the number: ` 2400`, `-1.5`, ` 0` |
| `%` | whole number (integer) | ` 10`, `-2` |
| `$` | string | the text between quotes: `"VL"`, `""` |

In a string:

- control characters (colors, cursor moves, Return) show in reverse:
  codes 0-31 as the letter Ctrl types them with (Return, 13, is a
  reversed `M`), codes 128-159 as the shifted character 64 above them;
- a `£` shows as `£`;
- `(static string in program text)` instead of the text means the
  variable was set from text written in the program itself (`d1$="..."`)
  and still points there; it hasn't been changed since.

A name followed by ` ?` is a function made with `def fn`, which has no
value to show.

### Arrays

Answer `Y` to "View Arrays?" to list the arrays after the simple
variables. Each array shows its name and size as it was DIMmed, then only
the entries that hold something (not 0, not `""`), with their numbers:

```
 Arrays:
TT$(254)
 (0)="Welcome"
 (12)="a line of the message being written"
DV%(36)
 (1)= 8
 (2)= 8
ST(38)
```

An array with every entry 0 or empty shows just its name and size
(`ST(38)` above). An array with two or more dimensions shows each entry's
numbers separated by commas: `(1,2)`.

### Keys

- Any key stops the list, even partway through a long string (it ends
  with `Aborted!`).
- "Hit Any Key" at the end goes back to the main prompt.

### What to keep in mind

- `VL` uses some variables of its own while it works (`a`, `b`, `t`,
  `x`, `y`, and for arrays `e`, `i`, `j`, `k`, `n`, `p`, `q`, `s`, `w`),
  so those show `VL`'s working values, not what they held before.
- `VL` changes none of the BBS's settings: it only reads the variables.
- Numbers are shown the way BASIC's `str$()` writes them: positive ones
  with a leading space, very large or small ones as `1.5E+12`.
