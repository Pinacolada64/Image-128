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
`e.sysoplist`, edited in `IM`, then `D` (Module Editors), then `D`
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

## Other sysops: `i/lo-sysop info` and `SF`

Image keeps a file of what callers who run an Image BBS of their own say about
it: their name and address, the board's name, its Image serial number,
telnet address, network and node ID. It's `e.sysop` on the Etcetera
drive, a record for each user (the format is in PROGRAMMING.md).

### The login module `i/lo-sysop info`

Add it to the login modules (`IM`, `D` Module Editors, `A` Login Mods)
as `sysop info`. As a caller logs in, it looks at their record:

| Record | What happens |
|---|---|
| empty (`^`) | asks them to fill it in: fields 1-3 come from their user record, then address to node ID; they check it and say if it's correct |
| `n` | nothing: they don't run an Image BBS |
| filled in | once a month, for callers above access group 3: shows it, asks "Is This Correct?", and lets them change any field |

Each time, it writes the record back with today's date. When the caller
has changed something, it also sends "Changed Sysop Data", with the new
information, to Feedback.

Until 10/29/2026 it was `i/lo-question`. The release also had
`i/lo-sysop.quest`, an older copy with 12 fields (a "Board No." where
the telnet address is, and no network); it's gone.

### `SF`: Sysop File Maintenance

`SF` at the main prompt (an Extended Command Set command) runs `i.SF`:

| Option | Does |
|---|---|
| 1. Create Sysop File | makes a new `e.sysop`, every record empty (`^`): it erases what's there |
| 2. Edit Sysop Record | by handle or ID: shows the fields, and changes one at a time |
| 3. Delete Sysop | by ID: the record becomes `n` |
| 4. Change File to `n` | the same, without asking |
| 5. Add Sysop | by handle or ID: asks for every field |
| 6. Quit | |

The new user application (`i/lo.new`) asks "Are You An IMAGE BBS
Owner?", and writes the new caller's record (or `n`); it creates
`e.sysop` if it isn't there.

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

**To keep it:** `T` changes the setting only until the BBS restarts,
which sets the lightbar's checks from `e.lightdefs` (`im 128` line
3250). Once `T` says `OK`, set the `DCD` left checkmark the same way in
`IM`: **H** Lightbar/Alarms, **A** Lightbar Defs, then save; `i/IM.lightbar`
offers to make the saved table active. (Modem Config has no carrier
setting: its flag 9 is DTR, the BBS's own line to the modem.)

## `IM` H: Lightbar/Alarms

`IM`, then `H`. `i.IM` draws the menu; each choice but the last loads
`i/IM.lightbar` and runs its part.

| Key | Item | Edits | File |
|---|---|---|---|
| `A` | Lightbar Defs | the checkmarks the BBS starts with | `e.lightdefs` |
| `B` | Alarms | the alarm table | `e.alarms` |
| `C` | NetMail Alarms | the network alarm times | `nm.times` |
| `D` | Lightbar Labels | the lightbar's 64 labels | `e.lightbar` |
| `E` | Main Menu | back to `IM`'s menu | |

Lightbar Defs reads the lightbar help text (`s.lightdefs`, a line for
each checkmark) when it starts, the first time in each visit to this
menu ("Reading Lightbar Help Text...").

### `B`: Alarms

Image keeps 16 alarms. Each one sets a lightbar checkmark at one time of
day and clears it at another; modules and the idle screen act on those
checkmarks. The list:

```
 ##  OnTime OffTime Check Active?

  1) 12:00A 12:00A  At1-R if At1-L
  9)  2:00A --:--   DST-L  Yes
 16)  4:00A  5:00A  ...    No
```

- **OnTime:** at this minute the checkmark is set (if the alarm is active)
- **OffTime:** at this minute it's cleared
- **Check:** the checkmark the alarm sets and clears
- **Active?:** `Yes` (always on), `No` (off), or `if` and a checkmark: on
  only while that checkmark is set (alarms 1-8 come that way, each switched
  on by one of page 8's `At1`-`At8` left checkmarks)

The BBS checks the alarms once a minute, so an alarm acts on the minute it
names, not over a range: 2:00 to 3:00 means "set at 2:00, clear at 3:00".

**`--:--` means never.** As an on time, the alarm never sets its
checkmark. As an off time, it never clears it: the checkmark stays set
until something else clears it. That's how the daylight saving time alarm
works: it sets `DST` (checkmark 64) at 2:00, and the idle screen clears it
when it has run the check, even if a call was on at 2:00 and the check had
to wait for it to end. To enter `--:--`, type `-` for the time.

Pick an alarm by number, then:

| Key | Changes |
|---|---|
| `1` | the on time (`h:mm` and `A` or `P`, e.g. `2:00 A`; `-` for `--:--`) |
| `2` | the off time, the same way |
| `3` | active: `E` always, `D` never, `C` while a checkmark (its number) is set |
| `4` | the checkmark it sets |

Return at the list asks to save the table to `e.alarms`, and then whether to
make it active now (otherwise it's loaded at the next boot).

### `D`: Lightbar Labels

The lightbar has 8 pages of 8 labels, three characters each (`Sys`,
`Acs`, `Loc`...), and each label has two checkmarks, a left and a right.
This edits the labels themselves.

It starts with "Copying Lightbar Labels...Done", then shows page 1:

```
Lightbar Labels: Page 1

1) Sys  Checks 0/1
2) Acs  Checks 2/3
...
8) U/D  Checks 14/15

Load/Save/Next/Prev/#/Quit:
```

`Checks` are the label's two checkmark numbers, its left then its right
(label 1 on page 1 is 0 and 1, label 1 on page 2 is 16 and 17): the
numbers modules use for the flag (`&,52,`*number*`,`...).

| Key | Does |
|---|---|
| `1`-`8` | edit that label on this page |
| `N`, `P` | next or previous page (page 8 wraps to 1) |
| `L` | load the labels from `e.lightbar` again, dropping unsaved changes |
| `S` | save them to `e.lightbar` |
| `Q`, Return | back to the menu |

**Editing a label:** it shows the label and asks for a new one; type up
to three characters, in upper and lower case as they should show (`DSR`,
`Dbg`). A shorter one is padded with spaces; Return alone leaves it as it
was. The lightbar shows the new label at once, so you can see it before
saving.

**Saving:** `S` saves the labels to `e.lightbar` on the system drive
(drive 3); `im 128` loads that file at boot, so saved labels come back
after a restart. Leaving with changes not saved asks "Save Changes?": No
puts the labels back as they were ("Restoring Lightbar Labels..."), as
they were when the editor started or were last loaded or saved.

On the release's `e.lightbar`, pages 5 to 7 and the last label on page 4
have placeholder labels: the left checkmark's number in hex (`$3E`,
`$40`...). Naming one changes only its label, not what uses the
checkmarks.
