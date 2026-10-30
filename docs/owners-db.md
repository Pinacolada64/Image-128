# Owners database: design (draft, 10/29/2026)

A port of Image 2.0's owners and orders database (`+.lo.serial`, New Image
Software's support BBS, 1990) to Image BBS 128, for the people who keep
track of who has which serial number and which builds they were sent. It
is built only into an "owners" build; a normal build has none of its code
and none of its files.

## What 2.0 had

`+.lo.serial`, a login module, on drive 0 (`or.` files):

| File | Kind | Holds |
|---|---|---|
| `or.serial` | REL, a record per user ID | the serial the caller gave (`G0895`); `*G0895` until staff verified it |
| `or.serial.add` | SEQ | user IDs who gave a serial, for staff to verify |
| `or.owners` | REL, a record per serial number | serial, last name, first name, address, city, state, zip, BBS name, voice number, BBS number; `^` ends it |
| `or.owners.fields` | SEQ | for each field: an input flag, a width and a prompt (`1 20First Name`) |
| `or.owners.chg` | SEQ | records callers changed, for staff to review |
| `or.orders` | REL, a record per serial number | a line per order: order date (YYMMDD), ship date (`000000`: not yet), payment (`C` C.O.D., `P` paid check/MO, `R` replacement, `D` dealer, `F` free), then the product; `^` ends it |

At login it showed "Image Owner: G0895", the caller's orders ("Ordered
...", "Shipped ..." or "Not Yet Shipped"), and once verified, their entry
for them to check; changes went to `or.owners.chg`. No 2.0 module wrote
`or.owners` or `or.orders`: staff kept them some other way.

## For Image 128

### The build option

- Every line of it is inside `{ifdef:owners_db}` ... `{endif}`.
- `OWNERS_DB=1 asm/build.sh` passes `-def:owners_db` to C64List and builds
  the owners-only modules; their names are listed in `build.sh`, so a
  normal build doesn't build or write them.
- An owners build goes to `build/image128-owners.d81`, so it isn't mixed
  up with a normal one.
- The data files are never in the repo. They're made on the owners'
  disks (below), from data kept outside it.

### The owners disk

The files are on a `.d64` of their own (664 blocks is plenty: few people
will register), not on any of the BBS's drives, so it's never copied
with the rest: `build/owners.d64` on the test setup, attached as a
device of its own (e.g. `-10 build/owners.d64` in x128). `i/SM.owners`
and `i/lo-serial` open the files on that device, which `i/SM.owners`
asks for once and saves in `e.data` (a record of its own, so a normal
build's `e.data` is the same as ever). When the disk isn't there,
`i/lo-serial` does nothing and `i/SM.owners` says so.

### Files (the owners disk)

| File | Kind | Holds |
|---|---|---|
| `e.owners` | REL, 254-byte records, one per owner in the order they were added serial (`A0002`), last name, first name, address, city, state, zip, BBS name, voice number, BBS telnet address, e-mail address, date issued, note; each ended by a CR, `^` after the last |
| `e.orders` | REL, the same record numbers as `e.owners` | a line per build or release sent, in 2.0's form: date sent (YYMMDD), date shipped (or `000000`), how (`F` free, `R` replacement, ...), then what (`Image BBS 128 alpha, 1.0 a1b2c3d`); `^` ends it |
| `e.owners.chg` | SEQ | records owners changed at login, for review |

Records are in the order serials were issued, not by number: the
numbers are sparse (G0041 ... G3355, and now A0002 ...), and a REL file
holds every record up to its highest. A serial is found by reading field
1 of each record (a few hundred at most); `e.owners` record 0's first
field could hold the count.

The caller's own serial is `e.sysop`'s field 8 (IMAGES#), which
`i/lo-sysop info` already asks for, in place of `or.serial`. The sysop
verifies it by hand in `i/SM.owners` (an owner's record marks it
verified, with the user ID it belongs to); until then `i/lo-serial`
says "not verified yet", as 2.0 did.

### Modules

- **`i/lo-serial`** (login module; owners build only): the port of
  `+.lo.serial`. From the caller's `e.sysop` record: "Image Owner:
  A0002" (or "not verified"), their builds from `e.orders`, and their
  `e.owners` entry to check; changes go to `e.owners.chg`.
- **`i/SM.owners`** (owners build only), and an "Owners Database" item in
  `i.SM`'s menu inside `{ifdef:owners_db}`: list owners (by serial, or
  find one by serial or name), add / edit / delete an owner, list and
  add the builds sent to one, and review `e.owners.chg` (apply or
  discard each).
- **`SF` (`i.SF`), every build:** a List option, `e.sysop`'s records by
  serial (field 8), like `sysop info.txt`. Nothing private: it's what
  callers said about themselves.

### Tools

- `tools/serial.py issue ... --to NAME` already stamps the next serial
  into `boot 128` and records it in `~/.local/share/image-bbs/serials.csv`.
- `tools/owners.py` (new): build `e.owners` and `e.orders` on an owners
  disk from that registry (and, once, from `sysop info.txt`); add a
  build sent to an owner; export the disk's files back to CSV, so the
  registry and the disk can't drift apart.

## Decided (10/29/2026)

1. A `.d64` of its own, not a drive of the BBS's.
2. The fields above, with an e-mail address; to be looked over again.
3. Everyone with a serial, A and G alike.
4. The sysop verifies serials by hand (`i/SM.owners`).

## Order of work

1. `tools/owners.py`: make `owners.d64` with `e.owners`, `e.orders`
   and `e.owners.chg` from the registry; export them back.
2. `i/SM.owners` and the `i.SM` menu item, `{ifdef:owners_db}`; the
   `OWNERS_DB=1` build.
3. `i/lo-serial`.
4. `SF`'s List option (every build).
