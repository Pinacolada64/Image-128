# `++ visual`: the full-screen editor

> **Alpha.** `++ visual` works, but it is unfinished: some editing a word
> processor would have isn't there yet (below, "What it can't do yet"),
> and it has crashed now and then when started from `WF`. The line editor
> is still the default; a caller who chooses this one can go back to it.

`++ visual` lets a caller write a message, a feedback or a file on the
whole screen, moving the cursor freely, instead of a line at a time. It
began as Image BBS 2.0's unfinished `visual.s`, came to Image BBS 3 as
`source/visual.s`, and was ported to the 128 as an overlay (`asm/visual.asm`,
11/08/2026), with pages, word wrap and a help screen added.

## Who gets it

A caller chooses it in Terminal Parameters, option 10 (`Text Editor`),
which switches between `Line` and `Visual` (`uf$` position 4). It is for
Commodore and ANSI callers: an ASCII caller (flag 16 without 18) is told
"You may only use the line-based editor", and gets the line editor
whatever the setting says. If `++ visual` won't load, the line editor is
used instead.

## The screen

- The text is shown a page at a time, 23 lines a page, up to 254 lines
  (or fewer: the most the message base or command allows, the same limit
  as the line editor's).
- Lines are 40 columns wide. Typing past column 39 moves the unfinished
  word to the next line, if that line is empty (word wrap).
- `*** End of Text ***` marks the row after the last line written; the
  cursor stops there going down.
- The screen mask is off while it runs, and comes back after.

## Keys

The same list is its help screen, `Ctrl-H` (`s.visual` on the System
drive; `s.visual 80` in 80 columns):

| Key | Does |
|---|---|
| Cursor keys | move; past the bottom or top row, the next or previous page |
| Return | the next line (on the last row, the next page) |
| Delete | delete to the left |
| Shift-Del, Ctrl-I | insert a space |
| Ctrl-D | delete at the cursor |
| Ctrl-B | delete to the start of the line |
| Ctrl-W | delete the previous word |
| Ctrl-N | go to the end of the line |
| Rvs On / Rvs Off | reverse on / off |
| Colour keys | change colour |
| Ctrl-V | the next page |
| Ctrl-Y | the page before |
| Ctrl-L | show the page again |
| Clear | start over: **the whole text is erased** |
| Ctrl-X | done: save the lines and leave |
| Ctrl-H | the help screen |

## Line editor commands

A line that starts with `.` and a letter, followed by Return, is a line
editor command: the line editor runs it (`.H` for its help, and the
others it knows), then `++ visual` comes back where it was, on the same
page with the cursor where it was. The command's line is emptied.

## Leaving

`Ctrl-X` saves the lines and leaves, as the line editor's save does.
If the carrier drops or the caller's time runs out, the lines are saved
and the editor leaves. The chat key starts chat as usual.

## What it can't do yet

From `modules/TODO.md`:

- insert or delete a whole line (the End of Text marker would move with it)
- split a line with Return in its middle, or join two lines with Delete at
  column 1
- show where you are ("Line 37 · Page 2")
- keys for the start of the line, the first page, and the page with the
  End of Text marker
- undo for the current line
- use the C128 screen editor's escape codes for 128 callers, to insert or
  delete a line with a byte or two instead of redrawing
- it has crashed (a BRK) now and then when started from `WF` (seen once in
  two tries on 11/11/2026, with the End of Text marker)

## For programmers

`sub.editor` runs it (60144 on): it loads `++ visual` at `protostart`
(`a$="0:++ visual":&,7,dv%,2`; the first bytes, a `jmp` and `vis` at
7171-7173, tell it the overlay is already there) and starts it with
`&,16`, as the line editor's `&,54,0-2`:

| Call | Starts |
|---|---|
| `&,16,0` (or `&,16`) | a new text: `tt$()` emptied, page 1 |
| `&,16,1` | the text so far (`tt$(1)` to `tt$(mline-1)`) shown, page 1 |
| `&,16,2` | back where it left off: the same page, cursor, colour and reverse |

It leaves with the page stored packed in `tt$()` (a colour or reverse
code only where it changes, no trailing blanks), `mline` the line after
the last that isn't blank, and `.x` (`peek(sxreg)`): 1 saved (`Ctrl-X`),
4 a dot command (its letter in `viscmd` and `.a`; `sub.editor` has the
line editor run it with `&,54,3`, then comes back with `&,16,2`). Its
source's header (`asm/visual.asm`) has the details, and
`tools/visual_wf.py` drives it through `WF` in x128.
