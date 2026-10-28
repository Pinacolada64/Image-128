# Porting notes: what differs between the C64 and the 128

Things found while porting Image BBS 3.0 to the 128 that the C64 code
takes for granted and the 128 doesn't, with what the port does about
each. Most of them failed quietly: a wrong value, a scrambled string, a
jam several steps later. For how they were tracked down, see
`DEBUG_TECHNIQUES.md`; the memory map is at the top of
`asm/memory 128.txt`.

## BASIC 7's strings

### Each string has a back-link to its variable

The C64 keeps a string as its text and nothing else; the variable's
descriptor (length, address) points at it, and nothing points back.
BASIC 7 keeps each string in bank 1's string area (from `fretop` up to
`memsiz`, `$9000` here) as:

    [the text] [2 bytes: the address of the descriptor holding it]

and a string nothing holds any more as:

    [the text] [its length] [$ff]

Read from a running 128 with `a$="hello"+"x"` and then
`a$="new"+"z"`: `4e 45 57 5a 02 04` ("NEWZ", held by the descriptor at
`$0402`), then `48 45 4c 4c 4f 58 06 ff` (the old "HELLOX", 6 bytes,
garbage).

BASIC 7's garbage collection (`$92ea`, `k_garbag`; `FRE(1)` calls it)
walks the string area by those links. It trusts them: a wrong one
makes it move a string to the wrong place, or write a new address into
something that isn't a descriptor any more.

GETSPA (`$9299`, under `makerm1`/`makeroom`, `$8688`) hands back a new
string already marked garbage. The assignment that stores it is what
writes the link. Until then the next collection is free to give its
room away.

### What that means for C64 code, and what Image does now

C64 code makes strings with `makeroom` and then writes the descriptor
straight into the variable. On the 128 that leaves the new string marked
garbage, and the string the variable held before still linked to it. The
first collection after that scrambles the strings at the top of the
string area: wrong text in variables, `?type mismatch`, jams.

- `putvar`, `putarr` (`tt$()`), `getstruc` and the struct module now do
  what BASIC 7's assignment does, around writing the descriptor
  (`varbl.asm`): `strold` marks the old string garbage if it links back
  to this variable, `strnew` links the new one. The struct module is
  assembled on its own and reaches them through `&,71` (`putvar2`).
- Image's own garbage collection (`gc.asm`, the C64's) can't keep the
  links, and did nothing; the wedge's `collect` (`&,40`, and the
  low-memory check before each statement) calls BASIC 7's instead.
- Putting the array pointers back (`&,28`; the error trap does it)
  drops the variables made since they were saved and moves the arrays
  down: `arrmark` marks the dropped variables' strings garbage first,
  and `arrlink` points the moved string arrays' strings back at their
  elements after. String arrays DIMmed after the save and dropped by it
  (im's line 304 drops line 306's `bb$()`, `dt$()`, `ed$()`, `nn$()` at
  every logon and logoff) get their strings marked garbage too
  (`arrmarka`, 10/26/2026): before that they stayed linked into memory the
  arrays moved over, and the collection wrote through those links into
  `co$()` and `im$()`. `tests/standin/arrayrs.bas`. All this is resident
  now (`arrays.asm`, at `arrayres_hi`, $fc00), which the wedge's `&,28`
  entry jumps to: the wedge ends where `tempscn` starts ($3300), and grew
  past it with `arrmarka` (`ml.asm` checks that now).

**When porting more ML** (the `++` overlays, the editor): look for
`sta (varpnt),y`, for `makeroom`/`makerm` users, and for anything that
moves memory in bank 1. Copying one variable's descriptor into another
(two descriptors, one string) can't be linked right either way: copy the
string instead. Nor can a variable be left pointing into the middle of a
string in the string area (C64 code shortens a string by moving its
pointer past the first characters): the collection walks the area string
by string, reads the skipped characters as a back-link and writes through
it. `&,15,5` and `&,15,6` did that to `an$`; `strrest` (`miscl.asm`) now
makes the rest a string of its own (`tests/standin/orphan.bas`).

### Checking the string area

Walk it from `memsiz` down: the two bytes before each string's end are
its link, or its length and `$ff`; a link's descriptor has to point back
at the same string. Read zero page and bank 1 in **one** monitor
session, with the CPU stopped (`vmon.py`'s `cmd()` with several
commands): two separate reads catch BASIC halfway through something and
report damage that isn't there.

### The pointers moved

BASIC 7's variable pointers are two bytes on from the C64's: `vartab`
`$2f` (c64 `$2d`), `arytab` `$31` (`$2f`), `strend` `$33` (`$31`),
`fretop` `$35` (`$33`), `memsiz` `$39` (`$37`). C64 code that works out
free memory as `peek(52)-peek(50)...` reads the wrong bytes; the modules
use `{sym:fretop}` and `{sym:strend}`.

## im's BASIC

### Every variable is DIMmed at boot

`im` creates all its plain variables in its DIM lines (3004-3056).
Image puts the array pointers back now and then (`&,28`), and that drops
any variable created after the save. So a variable added later reads 0
again after the next error. Add a new variable to the DIM lines. The ML
finds its own variables by name when `sys 7171` runs, after the DIMs,
so adding names doesn't upset it.

`EL` (and `ER`, `DS`, `DS$`) are BASIC 7's own: `el=5` is a syntax error.

### BASIC 7's own stack

FOR, GOSUB and DO frames are on BASIC 7's run-time stack at
`$0800`-`$09ff`, not on the CPU's: `($7d)` (`bstkptr`) points at the
newest frame's token, and it's empty at `$09ff`. FOR (`$81`) is 18 bytes,
GOSUB (`$8d`) and DO (`$eb`) 5: token, line, text pointer. BEGIN/BEND
puts nothing there. `sub.stack` walks it; the C64 version read the CPU's
stack pointer, which on the 128 never shows these.

ML that jumps into BASIC from inside an `&` call has to leave both stacks
as BASIC 7's own statement would: `&,66,1` (`mlgosub`) used to push its
GOSUB frame onto the CPU stack (RETURN never found it) and leave the `&`
call's frames there too. NEWSTT saves the stack pointer at each statement
(`$82`, `stksav`) and runs it with `jsr` from `$4af3`; GOSUB leaves that
return address (`$4af5`) on the CPU stack, and RETURN returns through it.
`farjmp_newstt` puts the stack back that way.

### `on -(…) gosub …: more` is not IF/THEN/ELSE

The C64 idiom `on -(c) gosub 76:goto 3000` calls 76 if `c`, and then
goes to 3000 **either way**. Rewritten as `if c then gosub 76:else goto
3000`, the `goto` becomes the alternative: after loading a module, line
71 never ran it, and line 73 went on to load "i/i.lo". BASIC 7 runs the
C64 form as it is; keep it.

### C64 addresses in peek, poke and sys

Image's variables live elsewhere on the 128 (the C64's cassette buffer
at 828 is `cassbuff`, `$1800`), and C64 addresses land in the 128's own
workspace:

- `poke 970,…` (the C64's `ptrlinm`) is in BASIC 7's RAM routines at
  `$0380`: the next statement fails with `?syntax error`.
- `poke j,peek(j) or 128` for `j=217 to 242` (unlinking the screen
  lines in the C64's link table) sets bit 7 in the 128 screen editor's
  own variables (`pnt`, the cursor): the editor breaks. The 128 keeps
  the links in a 4-byte bitmap at `ldtb2` (`$035e`; a set bit links a
  row): clear it.
- `poke 17136,a` (1.2's mask address) is in `im`'s program text, on the
  C64 3.0 too.

`im`, the `sub.*` and the `i.*` modules use `{sym:…}` names from
`asm/equates.asm`, whose comments give the C64 number for each. A scan
for these has to find them after a keyword with no space
(`ifpeek(1010)`), not just after a word boundary.

Unchanged on the 128: the VIC, SID and CIA registers, Image's flags at
`$d000`-`$d010`, the KERNAL jump table (`sys 65418`), `$90` status,
`$0200`.

### `an$` after an input (copied since 10/27/2026)

`&,1` and `£i` (`swap1`'s `ctrlm`) and `£g` (`inchr`) leave `an$`
pointing at Image's input buffer (`buffer`, $0e77), outside the string
area, and BASIC 7's `c$=an$` copies only the descriptor for such a string:
`c$` pointed at the buffer too, and changed with the next input. The next
input starts by putting a 0 in the buffer's first byte, so `c$` lost its
first character (Larry's `i.main` R command: "edit idlecmds" loaded as
"i.?dit idlecmds", `?load error` on line 79; "sub.0tack" before), and a
garbage collection could scramble it further.

Now those three set `anfix` (`$0af4`), and `trace0`, which the wedge calls
before every statement, copies `an$` into a string of its own (`strfix`,
as `&,2` does for `a$`) before the next statement runs. Not at the end of
the input itself: `£i` and `£g` run in the middle of an `&` string's MCI,
where a collection (`makeroom` can start one) could move the very string
being printed. So a plain `c$=an$` keeps its value; the `an$+""` copies in
`im` (line 220) and the modules are harmless and no longer needed.
`tests/standin/anfix.bas` (with the old ML: `c$=453 d$=45`, then
`853/85/8/8` after a collection; now `123/45/7/8`).

### C64List and long branches

C64List 4.04 assembled a branch out of range without an error: `arrlink`'s
`bcs arrm9` became `bcs` to the next byte once `arrmarka` sat between them,
and the loop never ended. After moving code apart, check that each branch
still reaches its label (a `$ff` offset is the giveaway).

### Other things im relies on

- `llen` (`$d004`) is the longest input line: at 0, `&,1` and `£i`
  refuse every character but Return. `im` sets it before input.
- `sys 7171` (intro's `setup`, `im` line 3074) sets up the cassbuff
  variables, the screen mask's row tables and more.
- The clock starts from the date `im` was built when there's no clock
  to read (line 3153, `-def:imdate` from `build.sh`): weekday 1-7
  (1 = Sunday), `YYMMDD`, the hour 1-12 plus 80 after noon, the minute.

## Modules

- They're C64 BASIC 2 programs (BASIC 7 runs BASIC 2 tokens), from
  `modules/`, built with C64List 4.04 but for the six that use BASIC 7
  keywords (4.06, below). Most come from the 3.0 release
  through ImageBBS3's `tools/detok.sh`, which checks the listing
  rebuilds byte for byte.
- A jump into another module (an `i/` module into its main module's
  3000s; into 4000, 60000) or to a line that never existed is a line
  C64List can't find, and it writes `[n]` into the program. Write the
  first digit as a byte, `{$33}004`, and it leaves the number alone.
- The wedge's LOAD always loads at the first line at or after the
  module's own first line (`new 3000:load …`); the secondary address
  only goes into `loadflag`.
- A module that needs BASIC 7 keywords includes `Basic70.bas` and is
  built with C64List 4.06 (`build.sh` picks it); 4.06 won't take the
  preface's numeric `{assign}`s, so such a module can't use the preface.
  sub.stack and i.VL were written that way; sub.modem, i/IM.modem,
  sub.misc2 and i/lo.idle were converted. Converting one:
  swap the preface for `Basic70.bas`, write each jump into `im` with its
  first digit as a byte (`gosub {$33}`, `goto {$39}99`), build, and check
  the program is byte for byte the 4.04 build before changing any code. A
  jump right after THEN or a variable (`thengosub30`, `onntgoto999`) is
  easy to miss: 4.06 says "Can't locate target line". Unquoted text that
  never runs can tokenize differently (`copyright` became COPY).
- A GOTO or THEN to an earlier line searches the program from the start,
  a line at a time, and a module's lines come after `im`'s (236 below
  3000). On x128 at 1 MHz, 500 passes of `k=k+1` behind an `im`-sized
  program took 2908 jiffies looping with `if k<500 then 60010`, 307 with
  the same loop at line 2, 290 as `do:k=k+1:loop while k<500` and 47 as
  `for k=1 to 500:next`: about 90 ms a pass just to find the line. A loop
  in a module that goes round many times (reading a file) is worth a DO
  loop, or a routine in `im`'s low lines (`im` 47, the editor's file
  loader). RETURN from inside a DO or FOR leaves BASIC 7's stack clean;
  a GOTO out of one doesn't.
- `dec()` takes only `0`-`9` and unshifted `a`-`f` ($41-$46), and stops
  the program with `?illegal quantity` on anything else; `hex$()` gives
  unshifted letters. Under `{alpha:alt}` a capital in the source is
  shifted ($c1-$da), so `hx$`'s A-F can't be read by `dec()`. The S2
  setting reads and writes its digits with `hx$` and `instr()` instead.
- Flags that have to outlive a module load, an error or a restart of
  `im` are bytes in the 128 OS's unused block at `$0ac6`-`$0aff`, past
  Image's last (`freq`, `$0aee`), not new variables (which also cost
  string and variable space in a module that loads others):

  | Byte | Name | Use |
  |---|---|---|
  | `$0aef` | `idletool` | 1: i.CP or i.RF was started from the idle screen, so it goes back there on quitting |
  | `$0af0` | `idlecolr` | i/lo.idle: the colour byte (`$f1`) as its last `£q` left it |
  | `$0af1` | `idlekey` | the first key the editor decoded (see below) |
  | `$0af2`-`$0af3` | `idlemsgt` | when i/lo.idle's last status message went up, in seconds |
  | `$0af4` | `anfix` | not 0: an input left `an$` in the input buffer; `trace0` copies it out |

## The ML

- **`farcall`** (`glue.asm`) reads its inline bytes through `$fb`/`$fc`.
  C64 code takes those for free zero page, and an IRQ's `farcall` can
  land in the middle of using them, so `farcall` puts the caller's two
  bytes back before going on. It has to stay first in `glue.asm`: the
  wedge, assembled on its own, calls it as `jsr glue`.
- **Interrupts:** the KERNAL's NMI entry (`$ff05`) has already saved
  `.a .x .y` and `$ff00` and switched to the ROMs; a handler ends with
  `jmp $ff33`. Image's IRQ runs in `cfg_ml` from `irq_far`, chained
  ahead of the KERNAL's.
- **The VDC:** an interrupt can't touch it (the editor selects a
  register, then writes it), so the 80-column status lines are copied
  from the VIC screen by the main line (`vdcstat`).
- **The editor's zero page:** `$ee` is the last column (39 or 79), set
  by the editor (C64 code wrote 39 into `$d5`); `$e7` is where its print
  wraps.
- **The split screen:** the C64 keeps console text off the screen mask
  with its own scroll (up to `botline`), but the 128 editor's print
  (`$c72d`, Image's `prtscn`) also scrolls at the bottom of its window
  and, when a line wraps, inserts a line by moving every row below it
  down, the mask's too. `setwin` (`shdlr.asm`, from `setmode`) makes the
  editor's window end at `botline` (`$e4`: 15 with the mask on, 23 off)
  and turns line inserting off (`$f8` bit 6). The other half, the
  raster split: with the mask on, the console rows follow the user's case
  (`mupcase`) and the mask's rows keep the lowercase set. The editor's IRQ
  rewrites `$d018` and `$d012` every frame unless `graphm` (`$d8`) is
  `$ff`, so `setirq` sets that and `irq_far` (`glue.asm`) does both: at
  line `$ff` the console's set, then two lines above row 16 the mask's,
  returning without the KERNAL so the clocks and keyboard still run once
  a frame. The C64 split at rows 7 and 23, which don't match 3.0's mask;
  the date keeps its capitals while the mask is on (`caseflag`).
- **Function keys:** the KERNAL expands f-keys into their KEY texts
  (`$1000`: ten lengths, then the text). `intro` zeroes the lengths;
  Image's `fkeybuf` is at `$100a`, where the text began.
- **RS-232:** BASIC 7's `GET#` treats carry set from GETIN as an error
  (`?break error`); the drivers' `ngetin` returns "" for "nothing
  waiting". The 128 KERNAL's `findfn`, `devnum` and "file not open" are
  at `$f202`, `$f212` and `$f682` (C64 `$f30f`, `$f31f`, `$f701`).
- **`&` calls' results:** the C64's `usetbl0` follows the call with
  `sta 780` / `lda 780`, so BASIC reads a call's `.a` with `peek(780)`
  (`sub.modem`: `&,4` then `peek(780)`, 0 for nothing received). Dropping
  it with the `r6510` save left `sareg` holding the call number: the
  modem check never saw 0, and the idle loop never came back to `&,16`.
- **SYS to the overlays:** the C64's `$c000` is `protostart` (`$1c00`).
- **`linnum` moved, and so did the zero page around it.** The C64 code
  hands addresses around in `$14`/`$15` (its `linnum`): `fnvar1` (`&,60`'s
  array element) left one there for the struct code. The port wrote it
  to `curlin` (`$3b`, BASIC's line number) and the struct code went on
  reading `$14`, which BASIC 7 uses for its operators and its garbage
  collection: every struct put wrote to a random address (strings, the
  screen, BASIC's pointers). They meet in `linnum` (`$16`) now, which only
  line numbers and PEEK/POKE use. Look for `$14`, `$22` (the C64's string
  pointer after FRESTR; the 128's is `$24`) and `$62` in C64 code.
- **The 128's vectors at `$0300` aren't all the C64's.** The C64's USR
  vector is `$0311`; on the 128 that's BASIC 7's escape-token vector
  (IESCEX), and USR's is `$1219` (`usrpok`). The wedge set `$0311`: `usr()`
  gave `?illegal quantity` and IESCEX pointed at junk.
- **The `++` overlays** are assembled on their own: they reach the ML
  only through names in `equates.asm` (`++ clock` carries its own VDC
  register writes and colour table).

## Keys and the status line at the idle screen

- **`&` output eats keys.** Every character printed with `&` goes
  through `output` (`chrio.asm`), which calls `getchr` after it to look
  for space, `/`, Ctrl-C and Ctrl-S, and `getchr` takes a key out of the
  keyboard buffer (`getkbd`, the editor's `kbdget`). Any other key is
  dropped. The idle loop printed its colour (`&"£q"+…`) on every pass,
  right before its `get a$`, so most presses never reached the GET; the
  C64 3.0 poked 646 instead and printed nothing there.
- **KEYCHK.** The 128's editor passes each key it decodes through the
  vector at `$033c` (default `$c6ad`, which handles the function keys and
  puts the key in the buffer at `$034a`), with the key in `.a`, inside
  the keyboard interrupt. `setirq` points it at `keychk_far` (`glue.asm`,
  visible in every configuration), which keeps the first key in
  `idlekey` and goes on to the old vector, so the buffer gets the key as
  before. i/lo.idle reads `idlekey` and clears it rather than using GET.
  A key poked into the buffer from the monitor bypasses KEYCHK: to try the
  idle keys in a test, poke `idlekey` instead.
- **Clear `a$` each pass.** With the key read on its own line, a pass with
  no key has to start `a$=""`, or the last key is done again on every
  pass (T toggled the carrier over and over).
- **The colour** is printed only when `$f1` differs from `idlecolr`: the
  views, the menu, and `+` and `-` print in other colours, but most passes
  print nothing at all.
- **The status line:** the loop writes "System Idle" (4040) on nearly
  every pass. A message from a key goes through 4043, which notes when in
  `idlemsgt`; 4040 leaves it there for 30 seconds. "System Idle" is
  padded to the field's width, so a longer message doesn't show past it.

- **The DCD invert flag** (lightbar 58, `$3a`) was put back to off every
  eighth frame: `mxor_compat` (`irqhn.asm`), which copies Image 1.2's
  53258 (`mxor`) into the flag, branched the wrong way (`bne` for `beq`,
  as in the C64 source), so it rewrote the flag from `mxor` whenever
  `mxor` *hadn't* changed (nearly always 0) and ignored it when it had.
  Fixed 10/28/2026. The idle screen's `T` toggles flag 58 with `&,52`
  and reads `Carrier Present` (59, `$3b`) back after `carrier_update`
  has run (`irq5`, every eighth frame: `&,22,3`).

## C64List

- Text in the ML is `{alpha:alt}`, as the C64's KickAss `petscii_mixed`:
  capitals `$c1`-`$da`, lowercase `$41`-`$5a`. `{alpha:normal}` folds
  both to `$41`-`$5a`, which Image shows as lowercase: every capital in
  the ML's strings (the day and month names, the editor's commands) was
  lost that way. Each file assembled on its own sets it before including
  `equates.asm`.
- 4.04 assembles a branch more than 128 bytes away without an error
  (the offset comes out wrong): use `bxx skip / jmp target` where it
  might be far.
- 4.06 rejects `{assign:60000=60000}` (a numeric label), and a `{:label}`
  makes it number the whole file from 0, one by one: it ignores `{number:}`,
  `{step:}` and `{renumber:}` (tried 10/27/2026), so a module with labels
  can't use BASIC 7 keywords (i.edit idlecmds keeps to BASIC 2), and
  `im 128.bas` (4.06) uses neither;
  a jump to a line that's only there at run time is `{$36}0000`.
- C64List 4.06's `-def:name="text"` with `{usedef:name}` puts a string
  into the program (`build.sh`'s `imdate`).

## Testing

- `tools/setup_test.py`: the new-system setup and the boot after it, in
  x128 (about a minute and a half).
- `tests/standin/`: small programs that run in place of `im` to try one
  part of the ML; `tools/standin.sh` puts one on a test disk.
- `tools/strcheck.py`: checks BASIC 7's string area in a running x128
  (remote monitor, port 6510 by default): every back-link against its
  descriptor and back; shows the first bad record the garbage collection
  would write through.
- `tools/vmon.py`: driving x128 through its remote monitor (port 6537);
  `tools/ovl_dis.py`: a C64 `++` overlay into C64List source to port.
- Booting the run disk in a test x128 needs the SwiftLink and a tcpser
  (`start-image-128.sh`'s options, on other ports): without them the boot
  waits at "Reading Blocks Free" for the modem.
- Warp mode runs `ti` and the clocks fast too: a 30-second wait passes in
  3. Turn warp off (`warp off` in the monitor) before timing anything.
- To find what takes a key out of the buffer, `watch store 00d0` in the
  monitor, put a key in, and read the stack when it stops: the editor's
  `dec $d0` at `$c252` and the return addresses above it.

## Open problems

### `&,2,2`'s `a$`, and `&,11` leaving strings linked (fixed 10/26/2026)

`&,2` (`dskin`) left `a$` pointing at `buf2`, outside the string area, and
BASIC 7's `x$=a$` copies only the descriptor: every `x$=a$` after `&,2,2`
(76 places in im and the modules) changed with the next line read. im's
`d3$` (the status line's "Last"), and `sub.modem`'s `mt$`, whose `val()`
overflowed `300*2^a` at logon (i/lo.on 4112). Now `&,2` goes to `dskina`
(`miscl.asm`): `dskin`, then `strfix` copies `a$` into a new string as the
`&` call ends, as `putln` does for `tt$()`. `tests/standin/dskin.bas`.

Copying inside `putvar` instead (commit 2f022ff, reverted) let a garbage
collection start in the middle of any ML that stores a string, and the
collection uses zero page as scratch (`$11`, `$14`, `$24`/`$25`,
`$50`-`$5f`, `$61`/`$62`, `$68`, `$70`) that such code may be holding:
`?syntax error` in i/lo-last's `&,60,1`, `?type mismatch` in im's error
report. Make a string with `makeroom` only where nothing is half done.

The first try with `dskina` hung a logon: `getmdm`'s SEC was overwritten
with `$40` through a bad back-link. The copies make collections frequent,
and the string area already held bad links: `tools/strcheck.py` found one
of i/lo-last's `tt$()` lines linked into the variable `s`. `&,11` (clear an
array, `clrarr`) zeroed `tt$()`'s descriptors the C64 way, leaving their
strings "in use" and linked to elements that no longer held them; BASIC 7
corrects a string's link when it moves the arrays (a new variable: im's
`s=.` at the main prompt) only through the element holding it, so those
links stayed behind, and the collection wrote through them. Now `&,11`
marks a string array's strings garbage first (`clrstr`), as BASIC 7's
assignment does. That no longer fit in the struct module's 6 pages, so
`clrarr` is resident: `miscl.asm`'s `arrclr`, which `&,11` goes to.
`tests/standin/clrarr.bas` (with the old ML, strcheck finds its "LINE 1"
string linked into the new variable `zq`).

`&,1`/`£i` left `an$` at `buffer` the same way: see "`an$` after an input".
And BASIC code that copies `d1$` keeps a pointer to the clock's own string
at `$0e00`, which the ML rewrites: copy it with `+""` (i/lo.idle's `lt$`).

### Logoff corrupts memory (found 10/22/2026, fixed 10/26/2026)

The cause found 10/26/2026 with `tools/strwatch.py` during a logoff: the
string area was clean at line 7 and damaged at im line 304, `&,28,1`, which
dropped line 306's string arrays without marking their strings garbage
(fixed: `arrmarka`, see "BASIC 7's strings" above). `&,11` was another
source (section above). The logoffs since (four in `e.last` from 10/26 to
10/27) all finished. What follows is how it was tracked down.

Logging off (`O` at the main prompt, after a local login) crashes the
128, a different way on each try. Reported: a CPU JAM at $7b8c with
sub.misc loaded, on im line 200.

**The JAM is a symptom.** $7b8c is good code in BASIC 7's ROM (`cmp
#$44`, PTRGET's check for the reserved names TI, ST, ER, EL, DS): a
JAM there means the CPU ran it with RAM banked in where the ROM was.
One test run ended the same way: PC $0000 with bank 1 and the internal
function ROM in, a configuration Image never uses, on im line 2002 (the
error handler's `&"[Error#{pound}!x…"`).

**How it jams** (caught 10/22 with `-jamaction 1`, which leaves the CPU
jammed and the remote monitor usable, and `chis`): ML code calls the
`ptrget1` stub in romtab.asm ($c04d: `jsr farcall`, `byte cfg_rom`,
`word k_ptrget1`), but its bytes read `a9 87 7b`: `farcall` stores $a9 in
`$ff00` and jumps to $7b87, the middle of PTRGET, with nothing it needs
banked in. $87a9 is an address in the string area: BASIC 7's garbage
collection wrote a moved string's new address through a back-link that
pointed at $c04f. Everything below has the same cause: **the collection
writing through bad back-links** (see "BASIC 7's strings" above). One bad
record is enough: the collection steps from string to string by the
lengths in their descriptors, so after one wrong step it reads text as
back-links, and writes wherever those point.

**Fixed:** `&,15,5` and `&,15,6` left `an$` pointing into the middle of
its old string (see above). Logoff still jams with that fixed.

**Where it shows.** Logoff runs sub.misc, which runs sub.modem for the
hangup (im line 74, then 100). When sub.modem returns, im line 102 does
`new 60000` and line 110 reloads sub.misc over itself, while BASIC is
still inside a gosub from sub.misc's own lines (the 3.0 release does the
same; line 110 had a debugging `gosub 20` and `"L:"` in the status line
text then, gone since). The loads around it are what make the collection
run; every failure seen came after that reload:

- `[Error#18, Line#2]` (?bad subscript in im's drive lookup), then
  struct.asm's `clrarr` looping for good: it walks the arrays from
  `arytab` until it lands exactly on `strend`, and met a size of 0
- the first array's header (`tt$()`) overwritten: `87 d4 88 85 01 00 ff`
  where `54 d4 04 03 01 00 ff` belongs; `d4 88 85` is a descriptor
  (212 bytes at $8588) written by the collection
- `?undef'd statement error in 79` or `in 2002`, out to `ready.`; a BRK
  into BASIC 7's monitor at about $3020; once, a BRK at $202e during
  login (with the `&,15` fix, so maybe the same damage, maybe not)
- stray bytes on the screen: the `y` of the mask's `Sys.` ($0682) and a
  digit of the status line's date

**The string area is already bad at the main prompt**, before logoff:
walking it (see "Checking the string area") stops at a string i/lo-last
built during login (`tt$(1)`, the last callers list) whose back-link
($45f2) is `tt$(1)` as it was then; by the main prompt the arrays had
moved up 21 bytes (three new variables) and the link wasn't moved with
them.

**The cause, confirmed 10/26/2026:** string arrays a module DIMs after
`&,27` and drops with `&,28` (`arrmark` marked only the dropped *plain*
variables' strings then; `arrmarka` does the arrays now). Their strings stay live, linked to memory that is
other variables or arrays later. Login runs modules that do that (e.g.
`i.lo.im`: `dt$()`, `ed$()`, `b$()`, `c$()`).

**Ruled out:**

- sub.modem's `+++`/`ath` waits (`&,22`, `tenwait`): they run in
  `cfg_ml` with I/O in, and the TOD clock ticks
- glue.asm's `irq_far` and `farcall`, and rs232_user.asm's NMI handler:
  each puts `$ff00` back (the NMI exits through `$ff33`)
- the ML writing the MMU's preset registers (`$d501`-`$d504`, `$ff01`-
  `$ff04`) or BASIC 7's RAM routines at `$0380`-`$03ff`: nothing does
- the ML's string writes: every `putvar`/`putarr` (and the overlays'
  `&,30`) goes through `strold`/`strnew`; `getstruc` too; `irqhn.asm`'s
  direct writes are integers (`tr%`, `ac%`, `mn%`); `makeroom` and the
  collection leave `varpnt` alone (they write $24/$25 and $61-$65)
- BASIC 7 moving the arrays when a new variable is made: it moves the
  string arrays' back-links with them (a stand-in test: `t$(1)` and the
  new variables survive a collection)
- `&,28` moving the arrays *up* (its forward copy would smear them): a
  debug count in the wedge saw none through login and logoff

**Done:** `arrmarka` marks the dropped string arrays' strings garbage.
It didn't fit in the wedge (which ends where `tempscn` starts, $3300), so
`&,28` runs from `arrays.asm`, resident at `$fc00`. To repeat the old
failure: a configured disk, `i.lo` with
`tr%=10`, the Loc checkmark (`> 1300` bit `$10`) at the idle screen,
warp off from then on, log in, `O`, `Y`, Return, Return. With
`-jamaction 2` x128 opens its own monitor window on the JAM and the
remote monitor stops answering. Breakpoints and store watchpoints set
over the remote monitor left it unreachable then; on 10/27/2026 a store
watchpoint (`watch store 00d0`) worked, set and resumed in one
connection and read from a new one once it stopped. The two TODOs this
left (fixing the nested reload; i/lo-last's time used) are in
`modules/TODO.md`.
