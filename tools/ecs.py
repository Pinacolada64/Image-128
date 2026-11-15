#!/usr/bin/env python3
"""ecs.py: list or add Extended Command Set entries in an e.ecs.main file
(a PRG, as disk/e.ecs.main.prg), the format i/IM.ecs (4026-4032) writes.

    tools/ecs.py FILE                       list the commands
    tools/ecs.py FILE --add CMD MODULE      add CMD running module i.MODULE
                [--access N] [--gosub] [--credits N] [--password PW]

After the two-byte load address, entries one after the other, ended by a
flag byte of 0:
  long (32 bytes, a module or a long command): flags, access (lo, hi),
      command (7), file (14: the module's name without "i."), password (7),
      credits (1)
  short (8 bytes): flags, access (lo, hi), command (2), file or line (2),
      credits (1)
flags: $80 active, $40 always, $10 a line in im (else a file), $20 GOSUB
(else GOTO), $08 short, $04 ignore extra, $01 ZZ locked. The command's
letters are kept shifted ($c1-$da, as im compares them); the module name
isn't (as PETSCII lower case). Access is a bit per group, 0-9 ($3ff all).
The file keeps its length: the new entry goes where the 0 was, and a 0
after it. The file is changed in place.
"""
import argparse, sys


def entries(d):
    i = 2
    while i < len(d) and d[i]:
        n = 8 if d[i] & 8 else 32
        yield i, d[i:i + n]
        i += n


def end(d):
    """where the 0 that ends the entries is"""
    i = 2
    for j, e in entries(d):
        i = j + len(e)
    return i


def text(b):
    return ''.join(chr(c & 0x7f) for c in b if c)


def show(d):
    for i, e in entries(d):
        if e[0] & 8:
            what = 'line %d' % (e[5] | e[6] << 8) if e[0] & 0x10 else 'i.' + text(e[5:7]).lower()
            print('$%04x %-7s %-16s access $%03x' % (i, text(e[3:5]), what, e[1] | e[2] << 8))
        else:
            what = 'line %d' % (e[10] | e[11] << 8) if e[0] & 0x10 else 'i.' + text(e[10:24]).lower()
            print('$%04x %-7s %-16s access $%03x credits %d' % (i, text(e[3:10]), what,
                                                                 e[1] | e[2] << 8, e[31]))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('file')
    ap.add_argument('--add', nargs=2, metavar=('CMD', 'MODULE'))
    ap.add_argument('--access', type=int, default=0x3ff)
    ap.add_argument('--gosub', action='store_true')
    ap.add_argument('--credits', type=int, default=0)
    ap.add_argument('--password', default='')
    a = ap.parse_args()
    d = bytearray(open(a.file, 'rb').read())
    if not a.add:
        show(d)
        return 0
    cmd, mod = a.add[0].upper(), a.add[1].upper()
    if len(cmd) > 7 or len(mod) > 14 or len(a.password) > 7:
        sys.exit('ecs.py: command up to 7 characters, module 14, password 7')
    for i, e in entries(d):
        if not e[0] & 8 and text(e[3:10]) == cmd or e[0] & 8 and text(e[3:5]) == cmd:
            sys.exit('ecs.py: %s is already there' % cmd)
    e = bytes([0x80 | 0x40 | (0x20 if a.gosub else 0), a.access & 255, a.access >> 8])
    e += bytes(ord(c) | 0x80 for c in cmd).ljust(7, b'\0')
    e += mod.encode().ljust(14, b'\0') + a.password.upper().encode().ljust(7, b'\0')
    e += bytes([a.credits])
    i = end(d)
    if i + 33 > len(d):
        sys.exit('ecs.py: no room in the file')
    d[i:i + 33] = e + b'\0'
    open(a.file, 'wb').write(d)
    show(d)
    return 0


if __name__ == '__main__':
    sys.exit(main())
