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

## `LTK`: Lt. Kernal Chat

A chat room for a BBS on a multiplexed Lt. Kernal hard drive, where up to
16 computers (stations) share one drive. Callers at different stations
talk to each other, and the sysop can come in at any station. It's a proof
of concept (11/2026).

### What it needs

- The Lt. Kernal at device 8, with LU 10 (where the chat file goes; every
  station sees LU 10's user 0). Image finds the Lt. Kernal by itself at
  boot.
- `++ chatmode` and `i.ltk chat` on the system disk. `asm/build.sh` puts
  both on `build/image128.d81`.
- The `LTK` entry in the Extended Command Set. The `e.ecs.main` the build
  writes has it (any access group may use it). A BBS set up before
  11/14/2026 keeps its own `e.ecs.main`: add it with `IM`, then the ECS
  editor: command `LTK` (a long command), module `ltk chat`, and the
  access groups who may use it.

The first time anyone uses it, it makes `chatfile` on LU 10 (34 blocks).

### Running it

Type `LTK` at the main prompt. It tells you your station (the Lt.
Kernal's port number), lists who else is online, and offers a menu:

```
Lt. Kernal Chat: you're at station 1.

Online:
Port 00: IMAGE SYSOP (chat room)

C)hat, T)ranscript, W)ho, Q)uit:
```

| Key | Does |
|---|---|
| `C` | enters the chat room |
| `T` | shows the transcript, oldest first; a key stops it |
| `W` | lists who's online again |
| `Q` | back to the main prompt |

"Online" means logged on: a station shows as online, with its caller's
handle, from their logon until they log off (however they leave: `/G`,
the carrier dropping, their time running out), whether or not they've
typed `LTK`. "(chat room)" after a name means they're in the room; "with
SysOp" means the sysop is in the room at that station. A station that
crashed with a caller on stays listed until it boots again.

### In the chat room

```
Here: IMAGE SYSOP

* In the chat room. /x leaves.
* TEST ACCOUNT joined
IMAGE SYSOP: hello from zero
TEST ACCOUNT: hi from one
```

- Type a line and press Return to send it (78 characters at most; Delete
  works). It shows at every station in the room as `handle: text`.
- `/x` and Return leaves the room, back to the menu.
- Others coming and going show as `* handle joined`, `* handle left`, and
  `* handle timed out` (a station that stops answering for about 100
  seconds).
- A new line from another station shows within about half a second; a
  station coming into the room is seen within about 8 seconds.
- Up to 15 stations can be in the room at once. Past that: "The chat room
  is full."

### The sysop

At any station where a caller is in the room, turn `Cht` on (the
lightbar) to join: the room sees `* SysOp joined`, and while `Cht` is on
the keyboard at that station is the sysop's, and lines go out as
`SysOp: text`. Turn `Cht` off to leave (`* SysOp left`). A caller on the
modem at that station stays in the room and keeps typing on their own
line meanwhile.

### The transcript

Everything said in the room, joins and leaves too, goes into the
transcript: the last 8K or so (16 blocks of `chatfile`, the oldest
dropped as it fills). It's written by one station only (the
lowest-numbered one in the room), under the Lt. Kernal's lock 0 (`&,13`,
PROGRAMMING.md), so two stations never write it at once. When that station
leaves, the next one takes over; a line can be lost or written twice at
that moment.

### Messages

| Message | Means |
|---|---|
| Sorry, the chat module isn't on the system disk. | `++ chatmode` is missing |
| This BBS has no Lt. Kernal hard drive. | no Lt. Kernal found at boot |
| The chat file isn't ready (error _n_): tell the SysOp. | 2: no room on LU 10 for `chatfile`; 3: no LU 10; 6: `chatfile` is an old, smaller one: scratch it (LU 10, user 0) and the next `LTK` makes a new one |
| The chat room is full. | 15 stations are in it already |

`LTK` also leaves at once when the caller's time is up or their carrier
drops.

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
  9)  2:00A --:--   DST-L  Yes *
 16)  4:00A  5:00A  Res-R  No
```

- **OnTime:** at this minute the checkmark is set (if the alarm is active)
- **OffTime:** at this minute it's cleared
- **Check:** the checkmark the alarm sets and clears
- **Active?:** `Yes` (always on), `No` (off), or `if` and a checkmark: on
  only while that checkmark is set (alarms 1-8 come that way, each switched
  on by one of page 8's `At1`-`At8` left checkmarks)
- **`*`** at the end: this alarm runs on specific days only (option 5)

Checkmarks are shown by their label as the lightbar has it, and the side:
`At1-R` is `At1`'s right checkmark. A label renamed in Lightbar Labels
(`D`) shows here at once.

The BBS checks the alarms once a minute, so an alarm acts on the minute it
names, not over a range: 2:00 to 3:00 means "set at 2:00, clear at 3:00".

**`--:--` means never.** As an on time, the alarm never sets its
checkmark. As an off time, it never clears it: the checkmark stays set
until something else clears it. That's how the daylight saving time alarm
works: it sets `DST` (checkmark 64) at 2:00, and the idle screen clears it
when it has run the check, even if a call was on at 2:00 and the check had
to wait for it to end. To enter `--:--`, type `-` for the time.

**Days.** An alarm can run on certain days of the week only: at its on
time, it sets its checkmark only on those days. Its off time clears the
checkmark on any day, so an alarm on at 10 PM Saturday and off at 2 AM
still clears on Sunday. The DST alarm runs on the days its rule changes
the clock: Sundays, for every rule shipped in `s.dstrules`.

Pick an alarm by number. Its screen shows the checkmarks with their labels:

```
Alarm #9:

 1) On Time:   2:00A
 2) Off Time: --:--
 3) Enabled
 4) Checkmark 64 (DST-L) is Triggered
 5) Days: S------
```

Then:

| Key | Changes |
|---|---|
| `1` | the on time (`h:mm` and `A` or `P`, e.g. `2:00 A`; `-` for `--:--`) |
| `2` | the off time, the same way |
| `3` | active: `E` always, `D` never, `C` while a checkmark (its number) is set |
| `4` | the checkmark it sets |
| `5` | the days it runs: digits `1`-`7` for Sunday to Saturday (`17` is weekends), `0` every day, or `?` to answer Yes or No for each day in turn |

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

## Daylight saving time

The BBS can move its clock forward and back for daylight saving time by
itself, and show each caller their own local time, DST included.

**Turning it on.** Choose the system's time zone, during setup (Part II,
after the clock) or in `IM`, Misc. Features, `G` (Time Zone). The list
has the places that don't use DST as zones of their own (Arizona,
Saskatchewan, Puerto Rico, Queensland...). Choosing a zone with DST:

- notes whether the clock is on daylight time now, taking it as right
- adds an alarm (or two) that sets the `DST` checkmark (64, page 5) at the
  minute the clock changes, on the weekday it changes (Sundays, for every
  rule shipped)

At that minute, the idle screen sees the checkmark, clears it, and checks
the clock: on the change days it moves it an hour, on other days nothing.
If a call is on then, the check waits until the call ends. The BBS also
checks at boot, in case it was off at the change.

**Turning it off:** choose a zone without DST; its alarm is taken out.

**Callers** choose their own zone (Personal Information), and times are
shown to them in it, with their own DST: a caller in Arizona or in Europe
sees the right time all year, and the zone's name follows (`PST`, `PDT`).
A caller whose zone was chosen before this is asked to choose again, once.

**Clocks.** A CMD or DS12C887 clock is set too when the BBS's clock moves.
A clock the BBS can't set (Lt. Kernal, Ultimate, TeensyROM) is taken to
keep standard time: the BBS adds the hour when it reads one on daylight
time.

### `IM` Misc. Features `H`: DST Rules

The rules say when DST starts and ends; each zone names its rule by letter.
The list shows each rule in words, with this year's dates:

```
1) U US and Canada (since 2007)
   Starts Mar 2nd Sun, 2:00 AM
   Ends   Nov 1st Sun, 2:00 AM
   2026: Mar 8 to Nov 1
```

| Key | Does |
|---|---|
| `1`... | edit that rule, a field at a time (Return keeps each): its letter, its description, then for the start and the end the month, the week (1-4, or `L` for the last), the weekday (1 = Sunday), the time and whether it's local (`L`) or UTC (`U`) |
| `A` | add a rule, starting from the US one |
| `D` | delete a rule, after saying how many time zones use it (they'd have no DST) |
| `S` | save; if the BBS's zone has a rule, its DST and alarms are set again by the rule as saved |
| `Q` | back (offering to save changes) |

A local end time is asked and shown as the clock reads it then, on daylight
time (2:00 AM for the US). When a country changes its dates, this is where
to change them.
