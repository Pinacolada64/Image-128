#!/usr/bin/env python3
"""urecord.py: list or change the fields of a user record in u.config (the
REL file of user records) on a .d81, without the BBS.

    tools/urecord.py build/setup-test.d81 1
    tools/urecord.py build/setup-test.d81 1 --set 5=example@example.com --set 13=01100

A record is its fields, each ended by a carriage return, then zeros up to
the record length (254). Field numbers are i.ED's: 1 handle, 2 password, 3-4
first and last name, 5 email, 6 last date, 7 access group, ... 13
linefeeds (with four more flags after it), 22 last call, 23 the flags.
--set takes ASCII, written as C64List's {alpha:alt} does: lowercase as
$41-$5a, capitals as $c1-$da. The disk is copied to <disk>.bak-urecord
first. Detach it in x128 before changing it.
"""
import argparse, shutil, sys

def off(t, s):
    return ((t - 1) * 40 + s) * 256

def petscii_name(n):
    return bytes(ord(c) - 32 if c.islower() else ord(c) + 128 if c.isupper() else ord(c) for c in n)

def to_petscii(text):
    return bytes(ord(c) - 32 if c.islower() else ord(c) + 128 if c.isupper() else ord(c) for c in text)

def show(b):
    return ''.join(chr(c + 32) if 0x41 <= c <= 0x5a else chr(c - 128) if 0xc1 <= c <= 0xda
                   else chr(c) if 32 <= c < 127 else '{$%02x}' % c for c in b)

def find_entry(d, name):
    t, s = 40, 3
    while t:
        b = off(t, s)
        for i in range(8):
            e = b + i * 32
            if d[e + 2] & 7 and d[e + 5:e + 21].rstrip(b'\xa0') == petscii_name(name):
                return e
        t, s = d[b], d[b + 1]
    sys.exit('urecord: no %s on the disk' % name)

def data_bytes(d, e):
    """the file's data, as (disk offset of each byte) in order"""
    where = []
    t, s = d[e + 3], d[e + 4]
    while t:
        b = off(t, s)
        n = d[b + 1] - 1 if d[b] == 0 else 254
        where += range(b + 2, b + 2 + n)
        if d[b] == 0:
            break
        t, s = d[b], d[b + 1]
    return where

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('disk'); ap.add_argument('record', type=int)
    ap.add_argument('--set', action='append', default=[], metavar='N=TEXT')
    a = ap.parse_args()
    d = bytearray(open(a.disk, 'rb').read())
    e = find_entry(d, 'u.config')
    reclen = d[e + 0x15 + 2]          # the directory entry's record length ($17)
    where = data_bytes(d, e)
    start = (a.record - 1) * reclen
    if start + reclen > len(where):
        sys.exit('urecord: no record %d' % a.record)
    rec = bytes(d[where[i]] for i in range(start, start + reclen))
    fields = rec.split(b'\r')[:-1]
    if len(fields) != 23:
        print('note: %d fields, not 23' % len(fields))
    for k in a.set:
        n, _, text = k.partition('=')
        n = int(n)
        if not 1 <= n <= len(fields):
            sys.exit('urecord: no field %d' % n)
        fields[n - 1] = to_petscii(text)
    for i, f in enumerate(fields, 1):
        print('%2d %3d %s' % (i, len(f), show(f)))
    if not a.set:
        return
    new = b''.join(f + b'\r' for f in fields)
    if len(new) > reclen:
        sys.exit('urecord: %d bytes, more than the record length (%d): nothing written' % (len(new), reclen))
    new += bytes(reclen - len(new))
    shutil.copyfile(a.disk, a.disk + '.bak-urecord')
    for i, b in enumerate(new):
        d[where[start + i]] = b
    open(a.disk, 'wb').write(d)
    print('record %d written (%d bytes used of %d); the old disk is %s.bak-urecord'
          % (a.record, len(new.rstrip(b'\0')), reclen, a.disk))

main()
