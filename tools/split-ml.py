#!/usr/bin/env python3
"""split-ml.py ML_PRG SYM OUT_DIR: cut ml.asm's output into the files
boot.asm loads.

ml.asm assembles every part of the ML where it runs (or, for the
modules, where it waits swapped out in bank 1), so ml.prg spans
$0e00-$feff with gaps that mustn't be loaded over: $1000-$18ff (the
KERNAL's function keys, BASIC's working storage, Image's tables), the
BASIC program area, and $d000-$dfff (I/O). This writes each part as its
own .prg with its own load address; boot.asm says which bank each goes
to. The part boundaries come from ml.sym (equates.asm's addresses), and
anything assembled outside them is an error.
"""
import re
import sys

prg_path, sym_path, out_dir = sys.argv[1:4]
sym = {}
for line in open(sym_path, encoding='latin-1'):
    m = re.match(r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$([0-9a-fA-F]+)', line)
    if m:
        sym[m.group(1).lower()] = int(m.group(2), 16)

data = open(prg_path, 'rb').read()
load = data[0] | data[1] << 8
body = data[2:]
end = load + len(body)

# name: (start, end) -- end is exclusive
parts = {
    'ml.buf': (sym['bufpage'], sym['bufpage'] + 0x200),
    'ml.low': (sym['wedgemem'], 0x4000),
    'ml.mod': (sym['editor_load_address'], sym['romtab']),
    'ml.res1': (sym['romtab'], sym['resident_lo_end']),
    'ml.res2': (sym['resident_hi'], min(end, sym['resident_hi_end'])),
}

covered = bytearray(len(body))
for name, (a, b) in parts.items():
    b = min(b, end)
    chunk = body[a - load:b - load]
    # drop trailing zero padding: nothing needs loading past the code
    chunk = chunk.rstrip(b'\x00') or chunk[:1]
    with open(f'{out_dir}/{name}', 'wb') as f:
        f.write(bytes([a & 0xff, a >> 8]) + chunk)
    covered[a - load:b - load] = b'\x01' * (b - a)
    print(f'{name:8} ${a:04x}-${a + len(chunk) - 1:04x}  {len(chunk):5} bytes')

stray = [load + i for i, (c, v) in enumerate(zip(covered, body)) if not c and v]
if stray:
    sys.exit(f'split-ml.py: assembled outside every part, from ${stray[0]:04x} ({len(stray)} bytes)')
