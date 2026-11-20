# BASIC variables the ML uses

Image's ML reads and writes some of `im`'s BASIC variables by name: the
list is `varlist` in `asm/intro.asm`, and the `var_*` equates in
`asm/equates.asm` give each one's index. `im` creates them all in its
DIM lines (3004-3056); `sys 7171` (intro's setup) creates any that are
missing, so a stand-in program has them too.

## `ak$`: the separator line, kept `ll%` wide (index 14, `var_ak_string`)

`ak$` is the line between sections (`{pound}vj` in `&` output): a space,
midlines (`{$c0}`), and Image's return, `ll%` characters in all. Since
11/19/2026 the ML keeps it that way itself. Between statements (from
`trace0`, after `anfix`), `akfix` (`asm/trace.asm`) compares `ll%` with
`len(ak$)`. When `ll%` is 3-80 and they differ, it builds a new `ak$` as
`strfix` builds a string: `makeroom`, fill, `putvar`. So any change to
`ll%` shows in the next statement's `{pound}vj`. Modules don't build
`ak$` (the loops in `i.lo` 3594, `i/lo.on` 4102 and `sub.param1` 60606
are gone). Only `im` 3062 still sets it at boot, from `sw`, before `ll%`
is set.

`ll%` (the caller's line length) has no index in `vars` (`varbl.asm` is
full). `setptrs` (`asm/intro.asm`) looks it up once, after `im`'s DIMs,
and keeps its place in `lloff`. Before then `akfix` does nothing.

Where `ll%` comes from:

- At the idle screen: `sw`, the console's screen width (`i/lo.idle`
  4108).
- A console login (the `Loc` checkmark: `zz`): `sw` (`i.lo` 3106, also
  `l9%`; `sub.misc` 60038 after it reads the account; `i.VF` 3001). The
  logoff, a refused login included, also gives `sw` there (`i.lo` 3203).
- A caller: 80 while connecting (`i.lo` 3546), then their answer to
  "Are You in 80 Columns?" (3574, also `l9%`). Logging on puts `l9%`
  back in `ll%` (`i/lo.login` 4200, `i/lo.instant` 4043, `i/lo.on` 4002)
  after the account's own width was read.

## `rc`: the last `&` output was stopped (index 17, `var_rc_float`)

`outstr` (`asm/strio.asm`) sets it each time a string is printed with
`&`:

- `rc` = 0 at the start of the output;
- `rc` = -1 if the output was stopped before its end: `chat` was set.

`chat` (`$d006`) is set by:

- the caller pressing `/`, space or Ctrl-C (`$03`) while text is going
  out (`output`, `asm/chrio.asm`);
- answering No at a "More?" prompt (`moreprmt`, `asm/strio.asm`): `/`;
- the carrier dropping (`outstr7`, `carchk` returned 1): `/`.

At the same point `outstr` sets two more:

- `kp%` (index 38, `var_kp_integer`): the key that stopped it (`chat`),
  0 if nothing did;
- `sh` (index 18, `var_sh_float`): 0, or 47 (`/`) when it was stopped
  by `/`, a No at "More?" or a dropped carrier. Space and Ctrl-C leave it
  0.

So `rc` is the "skip the rest" flag of a listing loop. The modules use it
as:

```basic
i=i+rc*n:next
```

which jumps `i` past the end of the loop once the caller stops the
output (`i.IM` line 3220, `sub.menus`, `i/SM.netfile`), or test `rc+sh`
for "was it stopped at all" (`sub.sysdos`, `i/SM.reledit`). A routine that
prints with `&` itself and then needs the caller's `rc` saves and puts it
back (`a=rc:gosub 12:rc=a`, `i/SM.lk util`).

ImageBBS3's `docs/prg-variables.adoc` lists it only in a comment:
"rc - abort char typed".
