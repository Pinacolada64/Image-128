#!/usr/bin/env python3
"""diskcheck.py: check a .d81's directory, file chains and BAM against each
other, without changing it.

    tools/diskcheck.py build/setup-test.d81
    tools/diskcheck.py -v build/setup-test.d81      (also each leaked block)

Errors (exit status 1):
- two files, or a file and the directory, using the same block
- a block in a file's chain that the BAM marks free: the next write to the
  disk (c1541 or the BBS) can take it, and the files end up cross-linked
- a chain that leaves the disk (track 0 or past 80, sector past 39) or
  loops
- a BAM free count that doesn't match its bitmap
Warnings:
- a file that was never closed (type without bit 7: a "splat" file, as a
  file left open across a reset or a detach leaves it)
- a directory block count that isn't the chain's length
- an entry with a name of control characters (a garbage entry: its chain
  is checked like any other, as the DOS would scratch it like any other)
- blocks the BAM marks used that no file has ("leaked": a validate frees
  them)

A file's blocks are its data chain; a REL file's also its super side
sector and side sectors; a CBM partition's its whole area. Track 40 holds
the header (40/0), the BAM (40/1, 40/2) and the directory chain (from 40/3);
the DOS never puts a file there, whatever the BAM says (the release's disks
mark all of it free), so it isn't checked against the BAM, but a file
block there is a warning.
c1541's "Track 0, Sector 0 out of bounds" on a delete is not about this.
"""
import argparse, collections, sys

TYPES = ['DEL', 'SEQ', 'PRG', 'USR', 'REL', 'CBM']
TRACKS, SECTORS = 80, 40

def off(t, s):
    return ((t - 1) * SECTORS + s) * 256

def valid(t, s):
    return 1 <= t <= TRACKS and 0 <= s < SECTORS

def show(b):
    return ''.join(chr(c + 32) if 0x41 <= c <= 0x5a else chr(c - 128) if 0xc1 <= c <= 0xda
                   else chr(c) if 32 <= c < 127 else '{$%02x}' % c for c in b)

class Disk:
    def __init__(self, path):
        self.d = open(path, 'rb').read()
        if len(self.d) not in (819200, 822400):
            sys.exit('diskcheck: %s isn\'t a .d81 (%d bytes)' % (path, len(self.d)))
        self.owner = collections.defaultdict(list)
        self.errors, self.warnings = [], []

    def block(self, t, s):
        b = off(t, s)
        return self.d[b:b + 256]

    def bam_free(self, t, s):
        bam = off(40, 1) if t <= 40 else off(40, 2)
        o = bam + 0x10 + 6 * ((t - 1) % 40)
        return bool(self.d[o + 1 + s // 8] & (1 << (s % 8)))

    def chain(self, t, s, who):
        """follow a chain of linked blocks, owning each for who; the list of
        (t, s)"""
        seen, out = set(), []
        while t:
            if not valid(t, s):
                self.errors.append('%s: its chain goes to %d/%d, off the disk' % (who, t, s))
                break
            if (t, s) in seen:
                self.errors.append('%s: its chain loops at %d/%d' % (who, t, s))
                break
            seen.add((t, s)); out.append((t, s))
            self.owner[(t, s)].append(who)
            b = self.block(t, s)
            t, s = b[0], b[1]
        return out

def check(path, verbose):
    k = Disk(path)
    d = k.d
    for ts in [(40, 0), (40, 1), (40, 2)]:
        k.owner[ts].append('(header/BAM)')
    # the directory
    dirblocks = k.chain(40, 3, '(directory)')
    entries = []
    for t, s in dirblocks:
        b = off(t, s)
        for i in range(8):
            e = b + i * 32
            if d[e + 2] & 7:
                entries.append(e)
    for e in entries:
        typ, raw = d[e + 2], d[e + 5:e + 21].rstrip(b'\xa0')
        kind = TYPES[typ & 7] if typ & 7 < len(TYPES) else '?%d' % (typ & 7)
        who = '"%s" %s' % (show(raw), kind.lower())
        count = d[e + 30] + 256 * d[e + 31]
        if any(c < 0x20 or 0x80 <= c < 0xa0 or c == 0xff for c in raw) or not raw:
            k.warnings.append('%s: a name of control characters (directory entry at %d/%d, slot %d): a garbage entry?'
                              % (who, (e // 256) // SECTORS + 1, (e // 256) % SECTORS, (e % 256) // 32))
        if not typ & 0x80:
            k.warnings.append('%s: never closed (type $%02x)' % (who, typ))
        if typ & 7 == 5:            # a CBM partition: its area, by count
            t, s = d[e + 3], d[e + 4]
            n = 0
            for _ in range(count):
                if not valid(t, s):
                    k.errors.append('%s: its area runs off the disk' % who); break
                k.owner[(t, s)].append(who); n += 1
                s += 1
                if s == SECTORS:
                    t, s = t + 1, 0
            continue
        blocks = k.chain(d[e + 3], d[e + 4], who)
        n = len(blocks)
        if any(t == 40 for t, s in blocks):
            k.warnings.append('%s: has blocks on track 40, the directory track' % who)
        if typ & 7 == 4:            # REL: the super side sector, then the side sectors
            sst, sss = d[e + 0x15], d[e + 0x16]
            if valid(sst, sss):
                n += len(k.chain(sst, sss, who + ' (side sectors)'))
            else:
                k.errors.append('%s: its side sectors are at %d/%d, off the disk' % (who, sst, sss))
        if n != count:
            k.warnings.append('%s: %d blocks in the directory, %d in the chain' % (who, count, n))
    # the BAM: free counts, blocks in use that it marks free, leaked blocks
    for t in range(1, TRACKS + 1):
        bam = off(40, 1) if t <= 40 else off(40, 2)
        o = bam + 0x10 + 6 * ((t - 1) % 40)
        bits = sum(bin(x).count('1') for x in d[o + 1:o + 6])
        if bits != d[o]:
            k.errors.append('BAM: track %d says %d free, its bitmap %d' % (t, d[o], bits))
    shared = {ts: w for ts, w in k.owner.items() if len(w) > 1}
    for ts, w in sorted(shared.items()):
        k.errors.append('%d/%d is used by %s' % (ts + (' and '.join(w),)))
    freeused = collections.defaultdict(list)
    for ts, w in k.owner.items():
        if ts[0] != 40 and k.bam_free(*ts):
            for x in set(w):
                freeused[x].append(ts)
    for who, l in sorted(freeused.items()):
        k.errors.append('%s: %d block%s marked free in the BAM (%s)'
                        % (who, len(l), 's' * (len(l) > 1), ' '.join('%d/%d' % ts for ts in sorted(l))))
    leaked = [(t, s) for t in range(1, TRACKS + 1) for s in range(SECTORS)
              if not k.bam_free(t, s) and (t, s) not in k.owner]
    if leaked:
        k.warnings.append('%d block%s marked used that no file has (a validate frees them)%s'
                          % (len(leaked), 's' * (len(leaked) > 1),
                             ': ' + ' '.join('%d/%d' % ts for ts in leaked) if verbose else ''))
    free = sum(d[(off(40, 1) if t <= 40 else off(40, 2)) + 0x10 + 6 * ((t - 1) % 40)]
               for t in range(1, TRACKS + 1) if t != 40)
    print('%s: %d files, %d blocks free' % (path, len(entries), free))
    for x in k.errors:
        print('error: ' + x)
    for x in k.warnings:
        print('warning: ' + x)
    if not k.errors and not k.warnings:
        print('ok')
    return 1 if k.errors else 0

def main():
    ap = argparse.ArgumentParser(description='Check a .d81\'s directory, chains and BAM.')
    ap.add_argument('disk', nargs='+')
    ap.add_argument('-v', '--verbose', action='store_true', help='list each leaked block')
    a = ap.parse_args()
    sys.exit(max(check(p, a.verbose) for p in a.disk))

main()
