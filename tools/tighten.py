#!/usr/bin/env python3
"""tighten.py [--check] PRG...: close up the spaces C64List leaves around a
{sym:name}'s value in a tokenized BASIC program (11/25/2026, the user's).

C64List writes a {sym:} value right-justified in a field, so the program has
"peek( 2670+2)" and "if peek( 2670+2)<   14" where the source had
"peek({sym:emp6mem}+2)". BASIC ignores spaces outside strings, so this is
only bytes and LIST's looks, and it changes nothing a program does.

In each line, outside strings, REM and DATA, a run of spaces before a digit:
  - goes, after "(" "," ";" or an operator ("+ - * / ^ = < >", AND, OR,
    as characters or as their tokens);
  - becomes one space, after any other keyword (GOTO, POKE, TO...);
  - stays, anywhere else.
BASIC 7.0's two-byte tokens ($ce xx, $fe xx) are kept whole. The lines' links
are made again for the program's load address. A program with nothing to
close up is left as it is (not written).

--check: write nothing; say what would change in each, and check that the
listing is the same apart from those spaces (the bytes, spaces outside
strings, REM and DATA left out, are the same)."""
import sys

OPS_CHR = set(b'(,;+-*/^=<>')
OPS_TOK = set(range(0xaa, 0xb4))      # + - * / ^ AND OR > = <
REM, DATA, QUOTE = 0x8f, 0x83, 0x22


def tighten_line(t):
    out = bytearray()
    q = rem = data = False
    i, n = 0, len(t)
    while i < n:
        c = t[i]
        if rem:
            out.append(c); i += 1; continue
        if c == QUOTE:
            q = not q
            out.append(c); i += 1; continue
        if q:
            out.append(c); i += 1; continue
        if data:
            if c == ord(':'):
                data = False
            out.append(c); i += 1; continue
        if c in (0xce, 0xfe) and i + 1 < n:     # BASIC 7.0's two-byte tokens
            out += t[i:i + 2]; i += 2; continue
        if c == REM:
            rem = True
        elif c == DATA:
            data = True
        if c == 0x20:
            j = i
            while j < n and t[j] == 0x20:
                j += 1
            if j < n and 0x30 <= t[j] <= 0x39 and out:
                p = out[-1]
                if p in OPS_CHR or p in OPS_TOK:
                    i = j; continue
                if p >= 0x80:
                    out.append(0x20); i = j; continue
            out += t[i:j]; i = j; continue
        out.append(c); i += 1
    return bytes(out)


def lines(prg):
    load = prg[0] | prg[1] << 8
    a, res = 2, []
    while a + 1 < len(prg):
        link = prg[a] | prg[a + 1] << 8
        if link == 0:
            break
        num = prg[a + 2] | prg[a + 3] << 8
        e = prg.index(0, a + 4)
        res.append((num, prg[a + 4:e]))
        a = e + 1
    return load, res


def build(load, ls):
    out = bytearray([load & 0xff, load >> 8])
    addr = load
    for num, t in ls:
        nxt = addr + 4 + len(t) + 1
        out += bytes([nxt & 0xff, nxt >> 8, num & 0xff, num >> 8]) + t + b'\0'
        addr = nxt
    return bytes(out + b'\0\0')


def nospace(t):
    """the line with spaces outside strings, REM and DATA left out"""
    out, q, rem, data = bytearray(), False, False, False
    for c in t:
        if c == QUOTE and not rem:
            q = not q
        if c == REM and not q:
            rem = True
        if c == DATA and not q:
            data = True
        if c == ord(':') and not q:
            data = False
        if c == 0x20 and not (q or rem or data):
            continue
        out.append(c)
    return bytes(out)


def main():
    a = sys.argv[1:]
    check = '--check' in a
    files = [f for f in a if f != '--check']
    bad = 0
    for f in files:
        prg = open(f, 'rb').read()
        load, ls = lines(prg)
        new = [(n, tighten_line(t)) for n, t in ls]
        saved = sum(len(t) for _, t in ls) - sum(len(t) for _, t in new)
        same = all(nospace(x) == nospace(y) for (_, x), (_, y) in zip(ls, new))
        if not same:
            print(f'{f}: CHANGED MORE THAN SPACES: not written', file=sys.stderr)
            bad += 1
            continue
        if saved == 0:
            continue
        if check:
            print(f'{f}: {saved} spaces')
        else:
            open(f, 'wb').write(build(load, new))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
