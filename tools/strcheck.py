#!/usr/bin/env python3
"""strcheck.py: check BASIC 7.0's string area in a running x128, through
the remote monitor, for the damage its garbage collection writes through.

    tools/strcheck.py [--port 6510] [--dump N]

BASIC 7 keeps each string in bank 1's string area (fretop up to memsiz) as
[text][2-byte back-link to the descriptor holding it], or [text][length]
[$ff] once nothing holds it; the collection walks the area by those, and
writes each moved string's new address through its back-link
(PORTING_NOTES.md, "BASIC 7's strings"). One bad record and it reads text
as back-links and writes wherever they point: into the ML, if they point
at $c000 up (shared RAM).

It reads zero page and bank 1 in one monitor session (the CPU stopped
throughout; reads in separate sessions catch BASIC halfway through
something), then:
  1. walks the string area from memsiz down; each back-link has to point
     at a string descriptor (a string variable, a string array's element,
     or a temporary one in zero page) that points back at the same string.
     Stops at the first bad record and dumps the bytes before it.
  2. checks every string variable and string array element whose text is
     in the string area: the string's back-link has to be that descriptor
     (two descriptors sharing a string can't both be).
  3. lists strings that point outside the string area: into Image's
     buffers (below $4000, $c000 up) or the program text. Not errors.
The emulation runs on when it's done. Exit status 1 if anything is wrong.
"""
import argparse, re, socket, sys, time

PROMPT = re.compile(rb'\(C:\$[0-9a-f]{4}\) $')
VARTAB, ARYTAB, STREND, FRETOP, MEMSIZ = 0x2f, 0x31, 0x33, 0x35, 0x39


class Session:
    """one connection to VICE's text monitor: the CPU stays stopped until
    close() resumes it"""
    def __init__(self, port):
        self.s = socket.create_connection(('127.0.0.1', port), timeout=5)
        self.s.settimeout(0.05)
        self._read(0.5, first=True)

    def _read(self, limit, first=False):
        out = b''; end = time.time() + limit; last = time.time()
        while time.time() < end:
            try:
                d = self.s.recv(65536)
                if not d:
                    break
                out += d; last = time.time()
            except socket.timeout:
                if first and time.time() - last >= 0.1:
                    break
                if not first and PROMPT.search(out) and time.time() - last >= 0.03:
                    break
        return out

    def cmd(self, c, limit=20):
        self.s.sendall(c.encode() + b'\n')
        return self._read(limit).decode('latin-1')

    def mem(self, bank, a, b):
        """bytes a..b inclusive from a monitor bank ('cpu', 'ram01'...)"""
        self.cmd('bank ' + bank)
        out = self.cmd('m %04x %04x' % (a, b))
        lines = [(int(m.group(1), 16), m.group(2).split()) for m in
                 re.finditer(r'>C:([0-9a-f]{4})\s+(.*)', out)]
        n = b - a + 1; data = []
        for i, (ad, words) in enumerate(lines):
            count = lines[i + 1][0] - ad if i + 1 < len(lines) else n - len(data)
            data += [int(x, 16) for x in words[:count]]
        if len(data) < n:
            sys.exit('strcheck: read %d of %d bytes at $%04x' % (len(data), n, a))
        return bytes(data[:n])

    def close(self):
        self.s.sendall(b'x\n'); self.s.close()


def name(b0, b1):
    n = chr(b0 & 0x7f) + (chr(b1 & 0x7f) if b1 & 0x7f else '')
    return n.lower() + ('%' if b0 & 0x80 and b1 & 0x80 else '$' if b1 & 0x80 else '')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--port', type=int, default=6510, help='remote monitor port (default 6510)')
    ap.add_argument('--dump', type=int, default=64, help='bytes to show before a bad record')
    args = ap.parse_args()

    ses = Session(args.port)
    try:
        zp = ses.mem('cpu', 0, 0xff)
        w = lambda a: zp[a] | zp[a + 1] << 8
        vartab, arytab, strend, fretop, memsiz = (w(a) for a in (VARTAB, ARYTAB, STREND, FRETOP, MEMSIZ))
        lo = min(vartab, 0x4000)
        b1 = ses.mem('ram01', lo, memsiz - 1)
    finally:
        ses.close()
    B = lambda a: b1[a - lo]
    W = lambda a: B(a) | B(a + 1) << 8
    print('vartab $%04x  arytab $%04x  strend $%04x  fretop $%04x  memsiz $%04x'
          % (vartab, arytab, strend, fretop, memsiz))
    print('variables %d, arrays %d bytes, free %d, string area %d bytes'
          % ((arytab - vartab) // 7, strend - arytab, fretop - strend, memsiz - fretop))

    # every string descriptor: address -> what holds it
    desc = {}
    for v in range(vartab, arytab, 7):
        if B(v) < 0x80 and B(v + 1) >= 0x80:
            desc[v + 2] = name(B(v), B(v + 1))
    a = arytab
    while a < strend:
        size = W(a + 2)
        if size < 5 or a + size > strend:
            print('BAD array table at $%04x (offset %d): stopping there' % (a, size)); break
        n = B(a + 4); data = a + 5 + 2 * n
        if B(a) < 0x80 and B(a + 1) >= 0x80:
            nm = name(B(a), B(a + 1))
            for k, e in enumerate(range(data, a + size, 3)):
                desc[e] = '%s(%d)' % (nm, k)
        a += size

    bad = 0

    # 1. the string area, from memsiz down
    p = memsiz; strings = garbage = 0; held = {}
    while p > fretop:
        if p - 2 < fretop:
            print('BAD: %d stray byte(s) at $%04x, below the last record' % (p - fretop, fretop)); bad += 1; break
        l0, l1 = B(p - 2), B(p - 1)
        if l1 == 0xff:
            start = p - 2 - l0
            if start < fretop:
                print('BAD garbage record ending $%04x: length %d runs past fretop' % (p - 1, l0)); bad += 1; break
            garbage += 1; p = start; continue
        link = l0 | l1 << 8
        if link < 0x100:
            dl, da = zp[link], zp[link + 1] | zp[(link + 2) & 0xff] << 8; who = 'temp $%02x' % link
        elif link in desc:
            dl, da = B(link), W(link + 1); who = desc[link]
        else:
            dl = da = None; who = None
        start = None if dl is None else p - 2 - dl
        if who is None or da != start or start < fretop:
            bad += 1
            why = ('back-link $%04x is no string descriptor' % link if who is None else
                   'back-link to %s ($%04x), which holds %d bytes at $%04x, not this string' % (who, link, dl, da))
            print('BAD record ending $%04x: %s' % (p - 1, why))
            d0 = max(fretop, p - args.dump)
            for r in range(d0, p, 16):
                row = [B(x) for x in range(r, min(r + 16, p))]
                print('  $%04x  %-48s %s' % (r, ' '.join('%02x' % c for c in row),
                      ''.join(chr(c & 0x7f) if 32 <= (c & 0x7f) < 127 else '.' for c in row)))
            print('  (the collection would write a new address through $%04x+1)' % link)
            break
        held[start] = link; strings += 1; p = start
    print('string area: %d strings held, %d garbage%s' % (strings, garbage, '' if bad else ', all links good'))

    # 2. and 3. every descriptor against the string it points at
    outside = []
    for d, who in sorted(desc.items()):
        ln, ad = B(d), W(d + 1)
        if ln == 0:
            continue
        if fretop <= ad < memsiz:
            if ad + ln + 1 >= memsiz:
                print('BAD %s ($%04x): %d bytes at $%04x run past memsiz' % (who, d, ln, ad)); bad += 1; continue
            back = W(ad + ln)
            if back != d:
                bad += 1
                print('BAD %s ($%04x): its string at $%04x links back to $%04x%s' % (who, d, ad, back,
                      ' (%s)' % desc[back] if back in desc else ' (garbage)' if B(ad + ln + 1) == 0xff else ''))
        else:
            where = 'program text' if 0x4000 <= ad < 0xc000 else 'shared RAM'
            outside.append('%s -> $%04x (%s, %d bytes)' % (who, ad, where, ln))
    if outside:
        print('pointing outside the string area (not errors):')
        for o in outside:
            print('  ' + o)
    print('BAD records: %d' % bad if bad else 'no damage found')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
