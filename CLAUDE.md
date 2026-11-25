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
