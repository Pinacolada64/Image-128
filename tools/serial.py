#!/usr/bin/env python3
"""serial.py: show, set or issue the BBS serial number in "boot 128", which
the BBS shows under its copyright message at logon ("S# A0001").

    tools/serial.py show build/setup-test.d81
    tools/serial.py set build/image128.d81 A0002
    tools/serial.py issue build/image128.d81 --to "Ray Kelm"
    tools/serial.py list

A serial is a prefix letter (A alpha, B beta, G general release) and a
number, 1-9999. The file is a .d81 (its "boot 128", changed in place: the
disk is copied to <disk>.bak-serial first; detach it in x128) or the
"boot 128" .prg itself (build/boot 128.prg, asm/boot.prg).

issue takes the next number after the highest one already issued with that
prefix (A by default), stamps it, and adds a line to the registry of who
got which serial. The registry stays out of the repo, as the owners'
details aren't for everyone: ~/.local/share/image-bbs/serials.csv, or
--registry.

In boot 128 (asm/boot.asm, "serial") the serial is the bytes 00 ff 53 4e
("SN"), then the prefix letter in PETSCII ($c1 A ... $da Z), then the
number, low byte first. boot 128 copies the last three to bsnpre and
bsnval ($0af5-$0af7), which swap3 reads.
"""
import argparse, csv, datetime, os, shutil, sys

MARKER = b'\x00\xffSN'
REGISTRY = os.path.expanduser('~/.local/share/image-bbs/serials.csv')
BOOT_NAME = b'BOOT 128'          # "boot 128" in the directory (PETSCII lowercase)

def parse(text):
    text = text.strip().upper()
    if len(text) < 2 or not 'A' <= text[0] <= 'Z' or not text[1:].isdigit():
        sys.exit('serial: a serial is a letter and a number, e.g. A0001')
    n = int(text[1:])
    if not 1 <= n <= 9999:
        sys.exit('serial: the number is 1-9999')
    return text[0], n

def fmt(letter, n):
    return '%s%04d' % (letter, n)

# --- the .d81 ---------------------------------------------------------------

def off(t, s):
    return ((t - 1) * 40 + s) * 256

def boot_bytes(d):
    """the disk offsets of boot 128's bytes, in order"""
    t, s = 40, 3
    while t:
        b = off(t, s)
        for i in range(8):
            e = b + i * 32
            if d[e + 2] & 7 and d[e + 5:e + 21].rstrip(b'\xa0') == BOOT_NAME:
                where, ft, fs = [], d[e + 3], d[e + 4]
                while ft:
                    fb = off(ft, fs)
                    n = d[fb + 1] - 1 if d[fb] == 0 else 254
                    where += range(fb + 2, fb + 2 + n)
                    if d[fb] == 0:
                        break
                    ft, fs = d[fb], d[fb + 1]
                return where
        t, s = d[b], d[b + 1]
    sys.exit('serial: no "boot 128" on the disk')

class Target:
    def __init__(self, path):
        self.path = path
        self.d = bytearray(open(path, 'rb').read())
        self.disk = path.lower().endswith('.d81')
        self.where = boot_bytes(self.d) if self.disk else range(len(self.d))
        data = bytes(self.d[i] for i in self.where)
        i = data.find(MARKER)
        if i < 0:
            sys.exit('serial: %s has no serial (a boot 128 from before 10/29/2026?)' % path)
        self.at = [self.where[i + len(MARKER) + k] for k in range(3)]

    def get(self):
        p, lo, hi = (self.d[a] for a in self.at)
        return chr(p - 0x80) if 0xc1 <= p <= 0xda else '?', lo + 256 * hi

    def put(self, letter, n):
        for a, v in zip(self.at, (ord(letter) + 0x80, n & 255, n >> 8)):
            self.d[a] = v
        if self.disk:
            shutil.copyfile(self.path, self.path + '.bak-serial')
        open(self.path, 'wb').write(self.d)

# --- the registry -----------------------------------------------------------

def read_registry(path):
    if not os.path.exists(path):
        return []
    with open(path, newline='') as f:
        return list(csv.DictReader(f))

def add_registry(path, row):
    new = not os.path.exists(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'a', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['serial', 'to', 'date', 'note'])
        if new:
            w.writeheader()
        w.writerow(row)
    os.chmod(path, 0o600)

def main():
    ap = argparse.ArgumentParser(description='Show, set or issue boot 128\'s BBS serial number.')
    ap.add_argument('--registry', default=REGISTRY, help='who got which serial (default %(default)s)')
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('show'); p.add_argument('file')
    p = sub.add_parser('set'); p.add_argument('file'); p.add_argument('serial')
    p = sub.add_parser('issue'); p.add_argument('file'); p.add_argument('--to', required=True)
    p.add_argument('--prefix', default='A'); p.add_argument('--note', default='')
    sub.add_parser('list')
    a = ap.parse_args()

    if a.cmd == 'list':
        rows = read_registry(a.registry)
        if not rows:
            print('no serials issued yet (%s)' % a.registry)
        for r in rows:
            print('%-6s %-24s %s  %s' % (r['serial'], r['to'], r['date'], r['note']))
        return
    t = Target(a.file)
    if a.cmd == 'show':
        print('%s: %s' % (a.file, fmt(*t.get())))
        return
    if a.cmd == 'set':
        letter, n = parse(a.serial)
    else:
        letter = a.prefix.upper()
        if not 'A' <= letter <= 'Z' or len(letter) != 1:
            sys.exit('serial: --prefix is one letter')
        used = [int(r['serial'][1:]) for r in read_registry(a.registry) if r['serial'][:1] == letter]
        n = max(used, default=1) + 1      # A0001 is the build's default: the first one issued is A0002
        if n > 9999:
            sys.exit('serial: no numbers left for %s' % letter)
    old = fmt(*t.get())
    t.put(letter, n)
    print('%s: %s (was %s)%s' % (a.file, fmt(letter, n), old,
                                 '; the old disk is %s.bak-serial' % a.file if t.disk else ''))
    if a.cmd == 'issue':
        add_registry(a.registry, {'serial': fmt(letter, n), 'to': a.to,
                                  'date': datetime.date.today().isoformat(), 'note': a.note})
        print('registered to %s in %s' % (a.to, a.registry))

main()
