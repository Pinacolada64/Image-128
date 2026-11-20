#!/usr/bin/env python3
"""branchcheck.py [FILE...]: find branches C64List assembled out of range.

C64List 4.04 assembles a branch whose target is too far with an offset of
$ff and says "0 Errors" (DEBUG_TECHNIQUES.md). A branch with offset $ff
goes to its own operand byte, which no working code does, so a branch
opcode followed by $ff is the sign. Data can look the same (an address
like $ff90 after a byte that happens to be a branch opcode), so each hit
is listed with the nearest label from asm/ml.sym to check by hand.

With no FILE: asm/ml.prg and the separately assembled parts (asm/*.bin,
asm/*.prg). A .prg's first two bytes are its load address. Known data,
11/20/2026: romtab's setmsg+4 ($ff90) and plot+4 ($fff0), and boot.prg's
"jsr setmsg" ($1c1f: 20 90 ff).
"""
import glob, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
asm = os.path.join(os.path.dirname(here), 'asm')
BRANCHES = (0x10, 0x30, 0x50, 0x70, 0x90, 0xb0, 0xd0, 0xf0)

labels = []
sym = os.path.join(asm, 'ml.sym')
if os.path.exists(sym):
    for line in open(sym):
        m = re.match(r'(\S+)\s*=\s*\$([0-9a-f]+)', line)
        if m:
            labels.append((int(m.group(2), 16), m.group(1)))
    labels.sort()


def near(a):
    best = None
    for addr, name in labels:
        if addr > a:
            break
        best = (addr, name)
    return f'{best[1]}+{a - best[0]}' if best else '?'


files = sys.argv[1:] or [os.path.join(asm, 'ml.prg')] + sorted(
    f for f in glob.glob(os.path.join(asm, '*.bin')) + glob.glob(os.path.join(asm, '*.prg'))
    if not f.endswith('ml.prg'))
found = 0
for f in files:
    d = open(f, 'rb').read()
    off = 2 if f.endswith('.prg') else 0
    base = d[0] | d[1] << 8 if off else 0
    mem = d[off:]
    for i in range(len(mem) - 1):
        if mem[i] in BRANCHES and mem[i + 1] == 0xff:
            found += 1
            where = near(base + i) if f.endswith('ml.prg') else f'+{i}'
            prev = f'{mem[i - 1]:02x} ' if i else ''
            print(f'{os.path.basename(f)} ${base + i:04x}: {prev}{mem[i]:02x} ff  ({where})')
print(f'{found} to check, {len(files)} files')
