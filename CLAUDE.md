# Image 128: notes for Claude

## Random outcomes: let Dbg choose them

To test every outcome of a random event, let the sysop pick the roll when
the lightbar's `Dbg` checkmark is on, instead of playing until it comes up.
Empire reads `Dbg` (check 56) into `db` when it starts (`&,52,56,3:db=a%`
in `i.empire`'s init), so turn it on before running Empire. The pattern,
from `i/emp.quests`:

```
	zr=fn r(40):if db then:&"{f6}{yellow}Dbg{white}: Zircon's roll, 1-40 (19-40: no gifts) {pound}i1":if an$>"" then zr=val(an$)
```

Roll first, then ask: Return keeps the random roll. Name what each value
does in the prompt. In x128, check 56 is bit 0 of `chktbl`+7 (`$1307`).

## The Lt. Kernal station's port

On a multiplexed Lt. Kernal, read the station's port (0-15) from BASIC as
`peek({sym:ltkprt})` (`asm/equates.asm`, `$37b2`): `lockinit` stores it
there at boot from the Lt. Kernal's GETPRT (0 without a Lt. Kernal). Don't
use `peek(57092) and 15` (the host adapter's `$df04`): at boot it read
another bank and gave port 0 port 11's modem setup (PR #47). ML has the
same port + `$80` in `glue.asm`'s `ltkport` (a lock's owner byte).

## BASIC 7.0: no `IF ... THEN BEGIN ... BEND` on one line

When the condition is false, BASIC 7.0 doesn't go on after a `BEND` on the
same line: it goes on at the next line, skipping whatever followed the
`BEND` (a `RETURN`). `im` 24 (`if a% then begin:color 4,a+1:bend:return`)
fell into line 28, the overlay loader, and broke every new user's login
(`begin-bend`). Put the block on a line of its own and go to it:

```
24 &,52,57,3:on -(a%<>.) goto 25:return
25 color 4,a+1:return
```

A `BEGIN` whose `BEND` is on a later line is fine. PROGRAMMING.md has the
details.
