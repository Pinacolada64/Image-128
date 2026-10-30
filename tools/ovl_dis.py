#!/usr/bin/env python3
"""ovl_dis.py: turn a C64 "++" overlay (a .prg that loads at $c000) into
C64List source, as a start for porting it to the 128.

    tools/ovl_dis.py overlay.prg [--entry $c0xx ...] [--label $c0xx ...] > asm/name.asm

It follows the code from the load address (and any --entry addresses: a
jump table's targets, routines reached through self-modified jumps) through
branches, jumps and subroutine calls; whatever it never reaches is written
as data (byte lines). Addresses inside the overlay get labels (L_c0xx);
those past its end (its variables) become equates after it. Everything
else is written as the C64 number with "; EXT <what's there>", the list to
port; immediates that look like the overlay's own high byte, a pointer into
itself, are marked "; HI?" for checking. --label puts a label at an address
even in the middle of data (what such a pointer points at), so the port can
write #<L_c0xx and #>L_c0xx.

Needs py65 (TADA's virtualenv has it).
"""
import argparse, re, sys
from py65.devices.mpu6502 import MPU
from py65.disassembler import Disassembler

ap = argparse.ArgumentParser()
ap.add_argument('prg')
ap.add_argument('--entry', action='append', default=[])
ap.add_argument('--label', action='append', default=[], help='an address to label (data a pointer points at)')
ap.add_argument('--name', default=None)
args = ap.parse_args()

raw = open(args.prg, 'rb').read()
base = raw[0] | raw[1] << 8
code = raw[2:]
end = base + len(code)
mpu = MPU()
mpu.memory[base:end] = list(code)
dis = Disassembler(mpu)


def region(v):
    if v < 0x100: return 'zero page'
    if v < 0x200: return 'stack'
    if v < 0x33c: return 'KERNAL/BASIC page 2-3'
    if v < 0x400: return 'C64 cassbuff (Image vars)'
    if v < 0x800: return 'C64 screen (Image vars past it)'
    if v < 0xa000: return 'BASIC RAM'
    if v < 0xc000: return 'BASIC ROM'
    if 0xcd00 <= v < 0xce00: return 'Image interface page $cd00'
    if 0xce00 <= v < 0xcf00: return 'Image buffer page $ce00'
    if v < 0xd000: return 'Image ML'
    if v < 0xe000: return 'I/O'
    if v >= 0xff81: return 'KERNAL jump table'
    return 'KERNAL ROM / Image ML'


# recursive descent
todo = [base] + [int(e.replace('$', ''), 16) for e in args.entry]
is_code = {}
targets = set(todo)
while todo:
    a = todo.pop()
    while base <= a < end and a not in is_code:
        n, t = dis.instruction_at(a)
        if t.startswith('???') or a + n > end:
            break
        for i in range(n):
            is_code[a + i] = (i == 0)
        op = t.split()[0]
        m = re.search(r'\$([0-9a-f]{4})', t.lower())
        if op in ('JMP', 'JSR') and m and '(' not in t:
            tgt = int(m.group(1), 16)
            if base <= tgt < end:
                todo.append(tgt); targets.add(tgt)
        if op.startswith('B') and op not in ('BIT', 'BRK') and m:
            tgt = int(m.group(1), 16)
            if base <= tgt < end:
                todo.append(tgt); targets.add(tgt)
        a += n
        if op in ('RTS', 'RTI', 'JMP', 'BRK'):
            break

# labels: code targets, --label addresses, plus anything in the overlay an
# operand refers to
labels = set(targets) | {int(v.replace('$', ''), 16) for v in args.label}
refs_beyond = set()
a = base
while a < end:
    if is_code.get(a):
        n, t = dis.instruction_at(a)
        m = re.search(r'\$([0-9a-f]{2,4})', t.lower())
        if m and '#' not in t and len(m.group(1)) == 4:
            v = int(m.group(1), 16)
            if base <= v < end:
                labels.add(v)
            elif end <= v < end + 0x100:
                refs_beyond.add(v)
        a += n
    else:
        a += 1


def lab(v):
    return f'L_{v:04x}'


def operand(t):
    """rewrite an instruction's operand: labels inside, EXT notes outside"""
    note = ''
    t = re.sub(r'^(ASL|LSR|ROL|ROR) A$', r'\1', t)   # C64List: accumulator mode has no "a"
    m = re.search(r'\$([0-9a-f]{2,4})', t.lower())
    if not m:
        return t.lower(), note
    s = m.group(1); v = int(s, 16)
    low = t.lower()
    if low.split()[0] == '#' or '#$' in low:
        if base >> 8 <= v <= (end - 1) >> 8 and len(s) == 2:
            note = '; HI? (the overlay\'s own page)'
        elif v in (0xcd, 0xce, 0xcf) and len(s) == 2:
            note = '; HI? (Image\'s interface or buffer page: buf2, buffer...)'
        return low, note
    if len(s) == 4 and base <= v < end:
        # an operand in the middle of an instruction: label + offset
        if v in labels:
            return low.replace('$' + s, lab(v)), note
    if len(s) == 4 and v in refs_beyond:
        return low.replace('$' + s, lab(v)), note
    note = f'; EXT {region(v)}'
    return low, note


out = []
name = args.name or args.prg.rsplit('/', 1)[-1]
out.append(f'; {name}: C64 "++" overlay, disassembled by tools/ovl_dis.py from')
out.append(f'; {args.prg.rsplit("/", 1)[-1]} (loads at ${base:04x}, {len(code)} bytes).')
out.append('; EXT marks each address outside the overlay: the list to port.')
out.append('')
out.append('{include:"equates.asm"}')
out.append('')
out.append(f'\torig protostart\t; c64: ${base:04x}')
a = base
data = []


def flush():
    while data:
        chunk = data[:8]
        del data[:8]
        out.append('\tbyte ' + ','.join(f'${b:02x}' for b in chunk))


while a < end:
    if a in labels:
        flush()
        out.append(f'{lab(a)}:')
    if is_code.get(a):
        flush()
        n, t = dis.instruction_at(a)
        text, note = operand(t)
        # C64List wants absolute addressing written out for zero page,y etc. as given
        out.append(f'\t{text}' + (f'\t{note}' if note else ''))
        a += n
    else:
        data.append(code[a - base])
        a += 1
        if a in labels or is_code.get(a):
            flush()
flush()
out.append(f'L_end:')
for v in sorted(refs_beyond):
    out.append(f'{lab(v)} = L_end + {v - end}\t; past the end: a variable')
print('\n'.join(out))
