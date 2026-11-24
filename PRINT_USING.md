# Formatting numbers: `PRINT USING`, `PUDEF` and `&,15,9`

BASIC 7.0 can format numbers for you: line up columns, put commas in
thousands, round to two decimal places, add a dollar sign. That's
`PRINT USING`, and `PUDEF` changes the characters it uses. Image 128
adds one call, `&,15,9`, so what `PRINT USING` makes goes to the caller,
not just the console's screen.

This chapter is a tutorial: the pattern first, then each kind of field,
with what it prints. Every result shown was printed by BASIC 7.0 in VICE's
x128 (11/24/2026). Brackets mark the ends of what was printed, so the
spaces show; they aren't printed.

## The pattern

A `print` in an Image module only reaches the console's screen: the
caller sees what `&` sends. So format with `PRINT USING`, catch it with
`&,15,9`, and print it with `&`:

```
x=1234.5
&,15,9:print using "#,###.##";x;:&,15,9,1
&"Your balance is $"+a$+".{f6}"
```

prints `Your balance is $1,234.50.` to the caller.

- `&,15,9` starts catching: from here, what BASIC prints on the screen goes
  into a buffer instead.
- `print using ...` formats `x` into that buffer.
- `&,15,9,1` stops catching, and puts the buffer in `a$`.

Then `a$` is an ordinary string: print it with `&`, with MCI, word wrap
and the translation each caller's terminal needs, or keep it for later.
`&,15,9,1,s$` puts it in another string variable instead
(`&,15,9,1,b$`).

Write the three on one line, as above, so nothing else is printed (or
lost) while it's catching: see "Things to watch" below.

## Number fields

A `#` holds one digit. The number is right-aligned in the field, and the
unused places on the left are spaces:

| Format | Number | Prints |
|---|---|---|
| `"#####"` | 42 | `[   42]` |
| `"#####"` | -42 | `[  -42]` |
| `"###"` | 0 | `[  0]` |
| `"##.##"` | 3.14159 | `[ 3.14]` |
| `"##.##"` | 0.001 | `[ 0.00]` |
| `"##.##"` | -0.5 | `[-0.50]` |

The `.` puts the decimal point there, and the number is rounded to the
places after it: 2.005 in `"##.##"` is `[ 2.01]`, 1234.5 in `"#####"` is
`[ 1235]`, and 7.25 in `"####.#"` is `[   7.3]`.

A `,` anywhere before the point puts in commas every three digits. It
counts as a place, and it's left out (as a space) when the number is too
small to need it:

| Format | Number | Prints |
|---|---|---|
| `"#,###.##"` | 1234.5 | `[1,234.50]` |
| `"#,###.##"` | 5 | `[    5.00]` |

### Too big for the field

When a number doesn't fit, the whole field is `*`s, never a wrong number:

| Format | Number | Prints |
|---|---|---|
| `"##"` | 123 | `[**]` |
| `"#,###.##"` | 1234567 | `[********]` |
| `"##.##"` | 99.995 | `[*****]` (it rounds to 100.00) |
| `"###.##"` | -123.456 | `[******]` (the minus sign needs a place too) |

So make fields one wider than the largest number, for a minus sign.

### Signs

Without a sign in the format, a negative number gets a `-` in front of
its digits (`"#####"`, -42: `[  -42]`). A `+` or `-` at either end of the
field puts the sign there instead:

| Format | Number | Prints |
|---|---|---|
| `"+####"` | 42 | `[+  42]` |
| `"+####"` | -42 | `[-  42]` |
| `"####+"` | 42 | `[  42+]` |
| `"####-"` | -42 | `[  42-]` |
| `"####-"` | 42 | `[  42 ]` |
| `"-###.##"` | 3.5 | `[   3.50]` |

`+` always shows a sign; `-` shows one only for a negative number (a
space otherwise). At the start of the field the sign stays at the left
edge, away from the digits.

### Dollars

A `$` at the start of the field prints a dollar sign there, at the left
edge (it doesn't move next to the digits):

| Format | Number | Prints |
|---|---|---|
| `"$###.##"` | 3.5 | `[$  3.50]` |
| `"$#####"` | 42 | `[$   42]` |
| `"$#,###.##"` | 1234.5 | `[$1,234.50]` |

To put it next to the number, leave it out of the format and add it
yourself: `&"$"+a$`, after trimming the spaces (below).

### Scientific notation

Four `^`s after the field print the exponent:

| Format | Number | Prints |
|---|---|---|
| `"#.##^^^^"` | 12345 | `[1.23e+04]` |
| `"#.##^^^^"` | -0.000123 | `[-.12e-03]` |

(BASIC prints a capital `E`, which shows as `e` in the lower/upper case
mode Image runs in.)

## Several values, and text

Give several values, separated by **commas**, and the format is used for
each in turn:

```
print using "###";1,2,3
```

prints `[  1  2  3]`. (A `;` between them is a `?syntax error`: after the
format string, `;` comes only once.)

A format can hold several fields, and anything that isn't a field
character is printed as it is, so one format can make a whole line:

| Format | Values | Prints |
|---|---|---|
| `"total ###"` | 5 | `[total   5]` |
| `"##) ########## #,###"` | 3,"bob",1234 | `[ 3) bob        1,234]` |
| `"time ##:##"` | 12,5 | `[time 12: 5]` |

Note the last one: `PRINT USING` doesn't fill with zeros, so 5 is ` 5`,
not `05`. For times and dates, use Image's MCI instead: `{pound}#2` then
`{pound}%m` prints `m%` two places wide with zeros (`05`), as the
manual's MCI chapter has it.

## String fields

`#`s hold the characters of a string too. The string is cut to fit,
left-aligned unless the field starts with `=` (centered) or `>`
(right-aligned); the `=` or `>` counts as a place:

| Format | String | Prints |
|---|---|---|
| `"########"` | `"hi"` | `[hi      ]` |
| `"=#######"` | `"hi"` | `[   hi   ]` |
| `">#######"` | `"hi"` | `[      hi]` |
| `"###"` | `"hello"` | `[hel]` |
| `">#####: ###"` | `"gold"`,7 | `[  gold:   7]` |

## `PUDEF`: the fill, comma and point

`PUDEF` changes the characters `PRINT USING` puts in a field. Its string's
first character is the fill (a space at first), the second the comma,
the third the decimal point:

| `PUDEF` | Format | Number | Prints |
|---|---|---|---|
| `pudef "*"` | `"#####"` | 42 | `[***42]` |
| `pudef "*"` | `"$#####"` | 42 | `[$***42]` |
| `pudef "*"` | `"#,###.##"` | 5 | `[****5.00]` |
| `pudef " .,"` | `"#,###.##"` | 1234.5 | `[1.234,50]` |
| `pudef "  "` | `"#,###"` | 1234 | `[1 234]` |

- `pudef "*"` is a check writer's fill: no room to add digits in front.
- `pudef " .,"` swaps the comma and the point, the way most of Europe
  writes numbers.
- `pudef "  "` makes the comma a space (`1 234`).

The BASIC 7.0 manual gives `PUDEF` a fourth character, the dollar sign,
but in x128 it made no difference: `pudef " ,.x"` still printed `$`. Put
your own currency sign in the text instead.

**Put `PUDEF` back when you're done**: it lasts until it's changed, for
every module after yours too. `pudef " ,.$"` is how BASIC starts.

```
pudef "*":&,15,9:print using "#####";c;:&,15,9,1:pudef " ,.$"
```

## Into the caller's text

`&,15,9` catches everything BASIC prints on the screen until
`&,15,9,1`, so one string can be built from several `print`s:

```
&,15,9:print using "##) ";i;:print using "=#########";n$;:print using " #,###";c;:&,15,9,1
```

The returns a `print` ends with are left out, so a `;` at the end, or not,
makes no difference. Up to 255 characters (a string's most) are kept; the
rest are lost.
Plain `print`s are caught too: `print "credits";x;` gives
`credits 7 `, with the spaces BASIC puts around a number.

Once it's in `a$`:

- **Trim it**: a field's spaces are part of the string. To put a number
  in a sentence, take them off the front:
  `do while left$(a$,1)=" ":a$=mid$(a$,2):loop` (`"   42"` becomes
  `"42"`).
- **Center it** for the caller's screen with `&,15,7` (the programming
  chapter, "Centering: `&,15,7`"): `&,15,7:&a$+"{f6}"`.
- **Fit the caller's width**: `ll%` is their line length. A table of
  columns 40 wide fits everyone; check `ll%` before printing a wider
  one.

### An example: a bank statement

A module showing a caller's last five transactions, with a total (`d()`
the amounts, `n$()` what each was):

```
	&"{f6}{white}  #  For           Amount{f6}"
	t=.:for i=1 to 5:t=t+d(i)
	&,15,9:print using "###  ##########  #,###.##";i,n$(i),d(i);:&,15,9,1
	&"{lt. blue}"+a$+"{f6}":next
	&,15,9:print using "Total:           #,###.##";t;:&,15,9,1
	&"{white}"+a$+"{f6}"
```

which prints (checked in x128, with `print` in place of `&`):

```
  #  For           Amount
  1  Lotto          25.00
  2  Bank        1,200.50
  3  Trade          87.25
  4  Quest          12.00
  5  Tax           -50.00
Total:           1,274.75
```

Every line ends at column 25, because each comes from fields of the same
widths: count the places in the formats (`###` 3, two spaces, `##########`
10, two spaces, `#,###.##` 8) and give the header and the total line the
same. The minus sign of -50.00 takes one of the field's spaces.

## Things to watch

- **Stop catching right away.** Between `&,15,9` and `&,15,9,1`, nothing
  BASIC prints reaches the screen. Keep them on one line. If a module ends
  (or an error stops it) in between, BASIC's `print`s on the console stay
  hidden until the next `&,15,9,1`. `&` output isn't affected: it never
  goes through BASIC's `print`.
- **Put `PUDEF` back** (`pudef " ,.$"`): it's for the whole BBS, not just
  your module.
- **No £ in `PUDEF` or in a format's text.** `a$` is printed with `&`,
  where £ starts an MCI command.
- **No zeros in front** (`05`): use MCI's `{pound}#` for that.
- **Commas between values**, not semicolons.
- **Writing it in a module**: write `print using` and `pudef` as they are.
  A module built with C64List 4.04 (one with `{uses:..\3_0-preface.lbl}`)
  is built with 4.06 when it uses them, automatically (the programming
  chapter, "BASIC 7.0 keywords in a 4.04 module").
- `i.test calls`, option 76, runs the examples on a live BBS.

## Quick reference

| In a format | Means |
|---|---|
| `#` | a digit (or a string's character) |
| `.` | the decimal point; rounds to the places after it |
| `,` | commas every three digits (a place; a space when not needed) |
| `+` (either end) | a sign, always |
| `-` (either end) | a sign for a negative number, a space otherwise |
| `$` (at the start) | a dollar sign at the field's left edge |
| `^^^^` (after) | scientific notation, `e+04` |
| `=` (at the start) | center a string |
| `>` (at the start) | right-align a string |
| anything else | printed as it is |
| a field too small | all `*`s |

| `PUDEF "abc"` | a: the fill (space), b: the comma, c: the point |
|---|---|

| Call | Does |
|---|---|
| `&,15,9` | start catching BASIC's screen output |
| `&,15,9,1` | stop; what was printed into `a$` |
| `&,15,9,1,s$` | stop; into `s$` |
