#!/usr/bin/env python3
"""to406.py: convert a module from C64List 4.04 to 4.06, so its BASIC 7.0
keywords (instr, do/loop, dec, ...) are tokenized.

    tools/to406.py modules/<file>.lbl [--write]

Without --write it prints what it would change.

4.04 builds a module with {uses:..\\3_0-preface.lbl}, whose {assign:N=N}
lines let it jump to im's lines by number (gosub 72, goto 300); but 4.04
ignores {tokenizer}, so BASIC 7.0's keywords stay as letters (instr( reads as
variables: ?type mismatch). 4.06 tokenizes them when the module includes
Basic70.bas, but it won't take the preface's numeric {assign}s, and it
refuses a jump to a line the file doesn't have. So:

- {uses:..\\3_0-preface.lbl} becomes {include:..\\Basic70.bas} (asm/build.sh
  then builds the module with 4.06: it greps for Basic70.bas), and a module
  that numbers its lines with {number:} gets {renumber} too: without it 4.06
  ignores {number:} and numbers the lines from 0 (4.04 needed nothing);
- each jump to one of the preface's lines (after GOTO, GOSUB or THEN, and
  each number of an ON ... GOTO/GOSUB list) is written with its first digit
  as a raw byte, {$3d}: gosub 72 is gosub {$37}2, goto 300 is goto {$33}00,
  which C64List leaves as it is. Jumps glued to a keyword or a variable are
  found too (thengosub30, onntgoto999).

Strings and comments are left alone, and so are numbers that aren't the
preface's lines (a jump within the module, &,52,56,3).
"""
import re, sys, os

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PREFACE = os.path.join(REPO, '3_0-preface.lbl')
USES = re.compile(r'\{uses:\.\.\\3_0-preface\.lbl\}', re.I)
# a jump keyword, then a list: numbers, labels or raw-digit forms
JUMP = re.compile(r'(?i)(go\s*to|go\s*sub|then)(\s*)((?:\d+|\{[^}]*\}\d*)(?:\s*,\s*(?:\d+|\{[^}]*\}\d*))*)')


def preface_lines():
    s = open(PREFACE, encoding='latin-1').read()
    return {int(n) for n in re.findall(r'\{assign:\s*\w+\s*=\s*(\d+)\s*\}', s)}


def raw(n):
    t = str(n)
    return '{$%02x}%s' % (ord(t[0]), t[1:])


def convert_code(code, lines):
    """code outside strings: the jumps to preface lines made raw"""
    def item(m):
        def one(x):
            x2 = x.strip()
            if x2.isdigit() and int(x2) in lines:
                return x.replace(x2, raw(int(x2)))
            return x
        return m.group(1) + m.group(2) + ','.join(one(x) for x in m.group(3).split(','))
    return JUMP.sub(item, code)


def convert_line(line, lines):
    s = line.lstrip()
    if s.startswith("'") or s.startswith('{') and s.endswith('}') and ':' not in s[1:2]:
        return line
    out, i, q = '', 0, False
    seg = ''
    for ch in line:
        if ch == '"':
            if not q:
                out += convert_code(seg, lines)
                seg = ''
            else:
                out += seg
                seg = ''
            q = not q
            out += ch
            continue
        if ch == "'" and not q:
            out += convert_code(seg, lines)
            seg = ''
            out += line[len(out):]
            return out
        seg += ch
    out += convert_code(seg, lines) if not q else seg
    return out


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    write = '--write' in sys.argv
    lines = preface_lines()
    src = open(path, encoding='latin-1').read().split('\n')
    new, n = [], 0
    for i, l in enumerate(src):
        if USES.search(l):
            l2 = USES.sub(r'{include:..\\Basic70.bas}', l)
            # 4.06 ignores {number:} (it numbers from 0) unless asked to
            # {renumber}; 4.04 honored it without
            if any(x.startswith('{number:') for x in src):
                l2 += '\n{renumber}'
        else:
            l2 = convert_line(l, lines)
        if l2 != l:
            n += 1
            if not write:
                print(f'{i + 1}:\n  - {l.strip()[:150]}\n  + {l2.strip()[:150]}')
        new.append(l2)
    if write:
        open(path, 'w', encoding='latin-1').write('\n'.join(new))
    print(f'{n} lines', 'changed' if write else 'to change')


if __name__ == '__main__':
    main()
