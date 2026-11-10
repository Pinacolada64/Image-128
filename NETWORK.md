# NetMail: the network's files

Image's network, NetMail ("ImageNet V3.0" on its call screen), passes
e-mail, NetSub posts, files, NetWall and Net Graffiti entries, and the
network administrator's updates between Image BBSes. This file lists
every file it uses, what writes and reads each one, and how they fit
together. It's a first inventory (11/09/2026): formats marked "not yet
traced" still need reading from the code, and the open questions are at
the end.

**3.0 and 128:** the modules use the same file names in both. Checked by
taking every quoted file name from the 3.0 release's network modules
(`ImageBBS3/build/image30.d81`, and `ImageBBS3/Ryan Sherwood/` for the
`i/SM.` ones) and from Image-128's `.lbl` files: the two lists are
identical. Image-128's changes are in the ML overlays (`++ net`,
`++ netsub`, `++ netlist`, `++ path`: their headers in `asm/` list them),
not in the files. So this file describes both.

**Where:** every `nm.` file is on drive 2, E-Mail (`dr=2`), except
`nm.times` (drive 3, Etcetera, loaded at boot). The other files the
network touches are listed in their own section.

## Nodes and how a call goes

Each BBS is a *node*: a number (its record in `nm.nodes`) and a 3-letter
ID (`nn$` in the modules; `dt$(0)`). A node has up to four standard
connections, the nodes it calls (`nm.connect` records 1-4), and more
"extra" connections after them.

A file to send goes in the outgoing list, `nm.list`, as one line:

```
DST/ORG/F/filename
```

- columns 1-3: the node it's for (`ALL`: every node);
- 5-7: the node it comes from;
- 9: what the receiver does if it already has a file of that name: `A`
  appends to it, `R` replaces it (anything else is an error);
- 11 on: the file's name.

Larry Hedman's note `CIB/DEB/A/nm.M.CIB/DEB` is one: NetMail for CIB from
DEB, appended to any `nm.M.CIB/DEB` already waiting there.

**Sorting** (`i/NM.sort`, after each call's processing) routes
`nm.list`'s lines:

- `ALL`: copied to the list for each standard connection, except the one
  it came from; and the file's name goes in `nm.s.ALL`: `i.NM_auto` scratches those
  files once no `nm.l.` list is left waiting;
- this node's own ID: to `nm.keep`, on node 1 only (elsewhere it's
  dropped: by then the processing modules have taken what they want);
- any other node: `++ path` finds the next node on the way there, from
  `nm.nodelist`, and the line goes in `nm.l.<that node>`, with its origin
  (columns 5-7) changed to this node: so on the way, ORG is the node it
  came from last, not where it started. No way there: `nm.zone`.

`nm.list` is scratched at the end.

**A call** (`i.NM_auto`, started by the network alarm, `nm.times`):

1. Connect: the caller sends Ctrl-A and waits for Ctrl-B.
2. Passwords: the caller writes `nm.password` (the other node's password
   from `nm.connect`, then its own) and sends it as
   `<them>/<us>/R/nm.password`; the answering node checks the first line
   against its own password (`nm.config`).
3. Files: each line of `nm.l.<node>` is sent, with its file (`++ net`
   0 and 2); then the other way. A file whose name isn't `nm.` and a
   shifted capital (the packet letters below) is renamed `nm.X...` on
   arrival, so a node can't write over anything else. Each file received
   gets its line in `nm.list`.
4. After: the files sent are scratched (not those for `ALL` or `ZZZ`),
   `nm.l.<node>` too; the call goes in the logs (`nm.log`); the
   connection's calls and minutes in `nm.connect`.
5. Processing, in this order: the weekly report (Sundays: `nm.R.` to
   node 1), `i/NM.mail`, `i/NM.netsub1` (which runs netsub2-4),
   `i/NM.update`, `i/NM.bbs list` (only if `e.bbs` exists), `i/NM.sort`.

## Packets: `nm.<letter>.<dest>/<origin>`

What's sent. Most are named for the node they're for and the node they
come from (`nm.M.CIB/DEB`); `<dest>` can be several IDs.

| File | What | Written by | Taken by |
|---|---|---|---|
| `nm.M.` _dest/orig_ | NetMail: one or more messages, each the handle it's for, then the message as Image mail keeps it, to `{^}` | `i/NM.mail` (forwarding, returns), `i/MM.sb-mail`, `i/SM.netfile`, `i/lo/ns` | `i/NM.mail`: each message to `m.<handle>`; a handle that isn't here goes back to the sender ("Handle Not Found") |
| `nm.P.` _dest/orig_ | NetSub posts: each a header (`to:` the NetSub's name, `fr:` who wrote it, `id:` the node, `tr:` its tracking number, `mt:`, `sd:` the date sent, `st:` or `ms:`), then the text to `{^}` | `i/NM.netsub4` | `i/NM.netsub2`: checked against the NetSub's nodes and `nm.P.track`, into `nm.P.temp`_n_ |
| `nm.F.` _dest/orig_ | a file package | `i/SM.netfile` | `i/SM.netfile` (the sysop unpacks it); `i/NM.sort` mails the sysop "Net File Package from ..." |
| `nm.G.` _dest/orig_ | NetWall entries | `i/NM.mail`, from `nm.G.temp` | `i/NM.mail`: added to `nm.wall`, from the nodes `nm.config` record 7 accepts |
| `nm.B.` _dest/orig_ | Net Graffiti entries | `i/NM.mail`, from `nm.B.temp` | `i/NM.mail`: into `nm.grf2`, from the nodes in record 8 |
| `nm.R.` _node1/orig_ | the weekly report: the node's ID, the date and version, BBS name, city, state | `i.NM_auto` (Sundays) | node 1's `i/NM.sort`: appended to `nm.reports` |
| `nm.U.nodes`, `nm.U.map`, `nm.U.map 80`, `nm.U.message`, `nm.U.news` | the administrator's updates, sent to `ALL` with `R` | node 1's `i.NM/utils` | `i/NM.update`: into `nm.nodes` and `nm.nodelist`, `nm.map`, `nm.map 80` (the old one kept as `.bak`), the sysop's mail, NetNews |
| `nm.password` | the call's password check (above) | `i.NM_auto` | `i.NM_auto` |
| `nm.X...` | a received file whose name wasn't allowed (renamed) | `i.NM_auto` | nothing |
| `nm.E.` _dest/orig_ | mail from sub.local (60070): not yet traced, nothing found that sends or reads it | `sub.local` | ? |

## Queues and work files

| File | What | Written by | Read by |
|---|---|---|---|
| `nm.list` | the list: lines as above. Outgoing before a call; after one, what came in | anything that makes a packet; `i.NM_auto` (received) | `i/NM.mail`, `i/NM.netsub1`, `i/NM.update`, `i/NM.sort` (each takes its own lines out) |
| `nm.l.` _node_ | the lines waiting to be sent to that node | `i/NM.sort`; `i.NM_auto` (a file that didn't go) | `i.NM_auto`, then scratched |
| `nm.s.ALL` | the names of files sent to `ALL`, scratched (with it) once no `nm.l.` list is waiting | `i.NM_auto` | `i.NM_auto` |
| `nm.keep`, `nm.zone` | lines kept on node 1, and lines with no way to their node | `i/NM.sort` | not yet traced |
| `nm.templist` | `nm.list` without the NetSub lines (then renamed back over it) | `i/NM.netsub1` | |
| `nm.P.sub` _n_ | posts on local sub-board _n_ to send to its NetSub | `i/MM.sb-post` | `i/NM.netsub4` |
| `nm.P.temp` _n_ | posts received for NetSub _n_, to post | `i/NM.netsub2` | `i/NM.netsub3`: onto the sub-boards (`e.Sub`, `d.sub` _n_) |
| `nm.S.temp` | written by `i/MM.sb-post` for a sub-board with flag 8: not yet traced | `i/MM.sb-post` | ? |
| `nm.G.temp`, `nm.B.temp` | NetWall and Net Graffiti entries made here, to send | `i.NW`, `i/lo-netwall`; `i/lo-net.grf.rel` | `i/NM.mail` |
| `nm.temp` | NetWall: a copy while entries are deleted | `i.NW`, `i/lo-netwall` | |

## Settings

| File | Type | What | Written by |
|---|---|---|---|
| `nm.create` | SEQ | the network administrator's file for a new node: `i/IM.netmail` makes `nm.nodes` from it; its D, Make nm.create, writes one | `i/IM.netmail`, `i.NM/config`, `i.NM/utils` |
| `nm.config` | REL | this node: record 1 its number, which access groups may use NetMail, its password, the version date; 2 the fastest rate and the modem's off-hook, on-hook and dial commands; 3 the ten calling-hour slots (`HHHH`, from and to); 4 city and state; 5 the date of the last weekly report; 6 the Tymnet settings (`s1$`-`s3$`); 7 and 8 the NetWall and Net Graffiti nodes (8 each) | `i/IM.netmail` (`IM`'s Netmail Config), `i.NM/config` |
| `nm.nodes` | REL | the network: record 1 how many; then one per node (record = node + 1): its ID, phone, BBS name, sysop, a flag (bit 0: inactive), and its four connections' node numbers | `i/IM.netmail` (from `nm.create`), `i/NM.update` |
| `nm.nodelist` | PRG | `nm.nodes`' links for `++ path`: a count, then 8 bytes a node (ID, 0, its four connections). Load address `$c200` (the C64's), which `++ path` ignores | `i/NM.update`, `i/IM.netmail`, `i.NM/config`, `i.NM/utils`, `i/SM.netfile` |
| `nm.connect` | REL | the connections: records 1-4 the standard ones, 5 how many extra, 6 on the extras; each nine fields: the node's ID, its password, the hours (a character a weekday: a slot from `nm.config` record 3, `+` all day, `-` none), the dial prefix, the calls a day (a character a weekday: `+` no limit, `0` none), the calls and the minutes so far, a field not yet traced, and the date of the last call | `i/IM.netmail` (E, Connections), `i/NM.update` (when the network changes), `i.NM_auto` (the counts) |
| `nm.forward` | REL | forwarding: record 1 how many and the date last done; then a handle here, the handle and the node to send its mail to | `i/IM.netmail` (F, Fwd. List) |
| `nm.netsub1`-`nm.netsub60` | `++ netlist` | one NetSub each: its name, its nodes' IDs (16 at most), its local sub-boards | `i/SM.reledit` |
| `nm.P.track` _n m_ | `++ netsub` | NetSub _n_'s tracking numbers: each node's ID and the highest number taken from it; a post with a lower one is a repeat and is dropped. _m_ counts on when a table fills | `i/NM.netsub1` (start), `i/NM.netsub2` |
| `nm.times` | PRG | the network alarm table (drive 3), loaded at boot | `i/IM.lightbar` |
| `nm.origin` | SEQ | the origin line added to NetSub posts | not yet traced |
| `nm.wall header` | SEQ | the NetWall's header | not yet traced |
| `nm.grf2` | REL | the Net Graffiti wall: record 1 three pointers (oldest, next, size), then one entry a record | `i/NM.mail`, `i/lo-net.grf.rel` |

## Logs and reports

| File | What | Written by | Read by |
|---|---|---|---|
| `nm.log` _YYMM_ | this month's calls: from, to, the times, the files | `i.NM_auto` | `i.LN` (6), `i/SM.scan netlog`, `i.VF` |
| `nm.log` _d_ | the same for weekday _d_ (1 Sunday); `i/lo.automaint` scratches the day's, so it starts again each week | `i.NM_auto` | `i/lo.misc` (Scan Netlog), `i/SM.scan netlog` |
| `nm.connlog.` _YYMM_ | each connection made, this month | `i.NM_auto` | |
| `nm.errors` | each failed transfer: its line and the error | `i.NM_auto` | `i.LN` (8) |
| `nm.sylog` | changes to the network settings: who, when, what | `i.NM/config`, `i.NM/utils` | `i.LN` (7) |
| `nm.P.count` | each NetSub post sent: the date, time and tracking number | `i/MM.sb-post` | `i.LN` (9); its format in the 3.0 manual |
| `nm.reports` | node 1: the weekly reports received | `i/NM.sort` | `i.NM/utils` |
| `nm.ark rep` _month_ | node 1: reports archived by month | `i.NM/utils` | `i.NM/utils` |
| `nm.dead` | read and scratched by `i.NM/utils`; what writes it isn't traced | ? | `i.NM/utils` |

## What callers see

| File | What | Written by | Read by |
|---|---|---|---|
| `nm.wall` | the NetWall: entries from here and from other nodes | `i.NW`, `i/lo-netwall`, `i/NM.mail` | `i.NW`, `i/lo-netwall` |
| `nm.map`, `nm.map 80` | the network map, 40 and 80 columns | `i/NM.update` | `i.LN` (4) |
| `s.netmenu`, `s.netmenuzz` | `i.LN`'s menu, and its sysop part (drive 1) | | `i.LN` |
| `s.netapp` | the network application (drive 1, on the 3.0 run disk) | | not yet traced |

## Other files the network uses

| File | Drive | Use |
|---|---|---|
| `m.` _handle_ | 2 | a user's mail: NetMail is delivered into it; the sysop's gets the reports and file notices (`sy$`, from `nm.nodes`) |
| `e.bbs` | 3 | if it exists, `i/NM.bbs list` runs after a call |
| `e.Sub` | 3 | the sub-boards, for `i/NM.netsub3` |
| `e.walladds` | 3 | `i/lo-net.grf.rel` |
| `d.sub` _n_ | 4 | a sub-board's posts (`i/NM.netsub3` posts NetSub messages) |
| `d.n.Main`, `n.` _..._ | 4, 1 | NetNews: `i/NM.update` (`nm.U.news`) |
| `e.menu` | 3 | `i/SM.conmenu` |

## The modules

| Module | Does |
|---|---|
| `i.NM_auto` (`i.NM/auto`) | the calls: dialing, passwords, transfers, logs; then the processing |
| `i.NM_config`, `i/IM.netmail` | the settings (`IM`'s Netmail Config is `i/IM.netmail`) |
| `i.NM_utils` | node 1's tools: updates to `ALL`, reports, `nm.create` |
| `i/NM.mail` | NetMail in and out, forwarding, NetWall and Net Graffiti |
| `i/NM.netsub1`-`4` | NetSubs: sort the posts in, check them, post them, send the local ones |
| `i/NM.update` | the administrator's updates |
| `i/NM.sort` | routing (above); node 1's reports |
| `i.LN` | the callers' node list and map; logs for the sysop |
| `i.NW`, `i/lo-netwall`, `i/lo-net.grf.rel` | NetWall and Net Graffiti |
| `i/SM.netfile` | file packages |
| `i/SM.scan netlog` | the logs |
| `i/SM.reledit` | the NetSub definitions |
| `i/lo/ns` | mails each connection the list of NetSubs |
| `i/MM.sb-post`, `i/MM.sb-mail` | posting to a NetSub, NetMail from a sub-board |
| `++ net` | the transfer protocol (`asm/net.asm`) |
| `++ path` | routing over `nm.nodelist` (`asm/path.asm`) |
| `++ netlist` | a NetSub definition (`asm/netlist.asm`) |
| `++ netsub` | the tracking tables (`asm/netsub.asm`) |

## Testing with two nodes

`tools/netnodes.py` makes two nodes, ONE (node 1, `1111001`) and TWO
(node 2, `2222002`), from copies of the run disk (`build/node-one.d81`,
`build/node-two.d81`, each with a copy of the `s.` files disk): it writes
`nm.create` and runs a BASIC program in x128 that makes `nm.nodes`,
`nm.nodelist`, `nm.config` and `nm.connect` with i/IM.netmail's own
statements, and on ONE a NetMail message for TWO's sysop.

`tools/netrun.py` boots both, each with its own tcpser (ONE: modem 25261,
telnet 6131, monitor 6541; TWO: 25262, 6132, 6542), whose phonebooks map
the other node's phone to its telnet port. At the idle screen it sets the
lightbar's NetMail Enable (28) on both and NetMail Trigger (29) on ONE,
and prints both screens through the call.


## Open questions and problems found

- **`i/NM.bbs list`** is run after each call when `e.bbs` exists, but
  isn't in either repo or on the 3.0 disks.
- **`nm.E.`**: `sub.local` 60070 writes it (mail to "!node" addresses?),
  but no line is added to `nm.list`, and nothing reads it.
- **`nm.S.temp`**: `i/MM.sb-post` writes it; no reader found.
- **`nm.dead`**: read and scratched by `i.NM_utils`; no writer found.
- **`i/NM.sort`'s NetNews code** (4600-4634, the same as `i/NM.update`'s)
  is never reached.
- **`i/lo/ns` on the 128:** it reads the NetSub's node IDs with
  `peek(49707)`-`peek(49755)`, where `++ netlist` keeps them on the C64
  (`$c22b`); on the 128 the overlay is at `$1c00`, so it reads the wrong
  memory. It should use `&,16`'s `an$` instead.
- To check in a real exchange: `nm.keep` and `nm.zone` (what reads them),
  `nm.origin` and `nm.wall header` (who writes them), the `mt:`, `st:` and
  `ms:` header lines, and `nm.connect`'s fields 8-9.
