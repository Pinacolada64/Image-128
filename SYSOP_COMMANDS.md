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

## `VF`: View Feedback

Reads the messages the BBS keeps for the sysop: feedback, new user
applications, the error log and Telecheck. In local maintenance mode it
also edits canned replies, archives new user applications, scratches the
message files and shows the WatchDog logs.

### Running it

Type `VF` at the main prompt (module `i.VF`), or press `F` at the idle
screen. From the idle screen, VF logs the sysop in locally, adds
`(M)ail Check` to its menu, and goes back to the idle screen when you
quit. From the main prompt, quitting goes back to the main prompt.

### Reading the files

VF says what it's reading as it goes, a line for each file:

```
* Reading Feedback (e.fback): 3
* Reading New Users (e.new): 0
* Reading Error Log (e.errlog): 15
* Reading Telecheck (e.telecheck): None
* Reading Access Groups (e.access): 10
* Reading Canned Messages (s.can msg): 4
```

A file VF reads shows a count that goes up as it reads: Error Log,
Telecheck, Access Groups, Canned Messages. `None` means the file isn't
there. Feedback and New Users are counted in the daily statistics, not
read from their files, so their counts appear at once.

### The menu

```
 (F)eedback   (3)   (N)ew Users (0)
 (E)rror Log (15)   (T)elecheck (4)
 (C)an Msg's  (4)   (A)rch. New Users
 (S)cratch Files    (W)atchDog Files
 (M)ail Check
```

| Key | Does | Who |
|---|---|---|
| `F` `N` `E` `T` | read that file's messages (Telecheck: the sysop only) | everyone who can run VF |
| `C` | canned replies: `(A)dd (E)dit (K)ill (L)ist (S)end`, up to 60 (`s.can msg`, `s.can msg1`...) | local maintenance |
| `A` | archive the new user applications: `e.new` is added to `e.nark` | local maintenance |
| `S` | scratch a file's messages, or `(X)` all of them: `(S)elective` (delete or keep each one) or `(A)uto` (all) | local maintenance |
| `W` | the WatchDog logs (below) | local maintenance, user #1 |
| `M` | mail check (`i.EM`; `Q` there comes back to VF) | from the idle screen |
| Return | quit | |

### Reading a message

`Start At (N=New)?` takes a message number, or `N` for the ones since
your last call. Each message shows its sender's handle, date, access,
e-mail, name, computer and subject, then the text, and then:

| Key | Does |
|---|---|
| a number | go to that message |
| Return, `N` | the next message |
| `O` | show this one over |
| `F` | forward it as e-mail to a user |
| `R` | reply: a subject, the editor, and it's sent as e-mail to the sender |
| `Q` | back to the menu |

In local maintenance mode, more, all about the sender's account:

| Key | Does |
|---|---|
| `A` | set their access group; on a new user's application, VF then offers the welcome message (`s.nu welcome` and the group, or `s.nu welcome`) |
| `C` | send them a canned reply |
| `CR` | set their credits |
| `D` | delete their account (and their `f.` and `m.` files) |
| `V` | their account at a glance: handle, name, e-mail, access, calls, credits, posts, uploads, downloads |
| `P` | print the message, with or without its header |

### Where feedback goes: the QuickList

When a caller leaves feedback (`sub.feedback`), the QuickList decides
who it's for and where it's kept. The QuickList is up to 15 accounts in
`e.sysoplist`, edited in `IM`, then `D` (Logon Editor), then `D`
(Quicklist). Each entry has a handle, a description and eight Yes/No
flags:

| # | Flag | Does |
|---|---|---|
| 1 | In Feedback List | the account is offered at "Feedback To Whom", by its handle and description; `A` sends to all of them |
| 2 | Feedback To `e.fback` | feedback for this account is filed in `e.fback` (VF's Feedback); without it, it's sent to the account as e-mail |
| 3 | Feedback Shadow | not used: no module reads it (10/27/2026) |
| 4 | Remote Instant Logon | Instant Login offers the account to a caller |
| 5 | Console Instant Logon | Instant Login offers the account at the console |
| 6-8 | Flag #6-8 | not used |

So feedback ends up in VF's Feedback list when it's sent to an account
with flag 2, or to `A` (all), or when nobody has flag 1, or when there's
no `e.sysoplist`. With one account in the list, feedback goes to it
without asking.

### WatchDog files

Logs the BBS writes as it runs. Each one is shown, and then VF asks
whether to delete it.

| # | Log | File | What's in it |
|---|---|---|---|
| 1 | Network Error Log | `nm.errors` (NetMail drive) | NetMail's errors |
| 2 | E-Mail Sent Log | `e.em log` | e-mail sent |
| 3 | Netsub Tracking Log | `nm.P.count` (NetMail drive) | NetSub message tracking |
| 4 | Local Maint File | `e.zz log` | each time someone turned local maintenance mode on, with their handle and the date and time (`sub.local`) |

`e.zz log` shows who has used local maintenance and when. Delete it
when you've read it, or it keeps growing.

## The idle screen

What the BBS shows while nobody is connected (`i/lo.idle`). `?` lists
its keys. Most of them load another module; these report on the status
line's Area field instead, and their message stays there for 30 seconds
before `System Idle` comes back:

| Key | Message |
|---|---|
| `5` | `Garbage Collecting`, then `Garbage Collected` |
| `6` | `Resetting Modem`, then `Modem Reset` |
| `+` `-` | `Default Color` and its number |
| `£` | `Answering Call` |
| `T` | the carrier detect setting (below) |

### `T`: carrier detect (DCD)

The modem tells the BBS a caller is connected with its DCD (carrier
detect) line. Some modems, and tcpser run with `-I`, give it the other
way round, so Image can invert it: the lightbar's `DCD` checkmark, left
side ("Invert DCD Signal", flag 58). With the wrong setting, the check
mark at the right of the status line ("Carrier Present", flag 59) shows
while nobody is connected, and the BBS takes a call that isn't there.

`T` turns the inversion on or off, waits a moment for the BBS to read
the carrier again, and says which setting it's on and whether it's
right:

| Message | Means |
|---|---|
| `DCD Normal: OK` | not inverted; no carrier, as there shouldn't be at the idle screen |
| `DCD Inverted: OK` | inverted; no carrier |
| `DCD Normal: Wrong` | not inverted, but the check mark shows with nobody connected: press `T` again |
| `DCD Inverted: Wrong` | inverted, but the check mark shows: press `T` again |

"OK" and "Wrong" are judged by the idle screen itself: nobody is
connected there, so a carrier means the setting is the wrong way round.
Pressing `T` while a call is coming in can give `Wrong` when the setting
is right; press it again when the line is quiet. With tcpser run by
`start-image-128.sh` (`-I`), the right setting is `DCD Inverted`.

The setting is the lightbar checkmark itself, so it can be changed there
too. Until 10/28/2026 the ML put it back off every few moments (the
`mxor_compat` bug, `PORTING_NOTES.md`), so it couldn't be left on.
