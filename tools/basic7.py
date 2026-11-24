#!/usr/bin/env python3
"""basic7.py: find BASIC 7.0 keywords in a C64List 4.04 module, and build
a copy of it C64List 4.06 can tokenize (11/24/2026).

    tools/basic7.py check FILE...      list each file's BASIC 7.0 keywords
    tools/basic7.py convert FILE OUT   if FILE (a 4.04 module) has any, write
                                       OUT, converted for 4.06 (to406.py),
                                       and exit 0; otherwise exit 1

asm/build.sh runs convert on each module that uses the preface
({uses:..\\3_0-preface.lbl}), so a module can write print using, pudef,
instr( or do/loop as they are and keep the preface's jumps (gosub 72) as
they are: the source stays a 4.04 module, and only the copy built from
(modules/.406.<name>.lbl, not in git) is in 4.06's form. C64List 4.04
leaves BASIC 7.0's keywords as letters (instr( reads as variables: ?type
mismatch); 4.06 tokenizes them only with Basic70.bas included.

The code is read as BASIC 7.0's tokenizer reads a typed line: at each
place, the first keyword in its tables that matches (BASIC 2's first).
So crunched code hides keywords: ifb>cdorb reads c DO rb, 2^xorf reads
XOR. Each keyword found is one of two kinds:

- a use: a statement's keyword where a statement starts (the line's
  start or number, :, then, else, do, loop) and not run into a letter;
  a function's (instr, dec, xor...) with its ( after it; using after
  print or print#;
- an accident: any other (a variable's name, crunched code, copyright).

convert builds the copy only for a module with a use; if it has
accidents too it stops (exit 2) and names their lines, which 4.06 would
tokenize as keywords: a space between the letters is enough (cd or b).
A module with accidents and no use builds with 4.04 as before, where
they're letters. Strings, rem and data, C64List's ' comments and {...}
(directives, labels, control codes) are skipped.
"""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import to406

BASIC2 = ('end for next data input# input dim read let goto run if restore '
          'gosub return rem stop on wait load save verify def poke print# '
          'print cont list clr cmd sys open close get new tab( to fn spc( '
          'then not step + - * / ^ and or > = < sgn int abs usr fre pos sqr '
          'rnd log exp cos sin tan atn peek len str$ val asc chr$ left$ '
          'right$ mid$ go').split()
# BASIC 7.0's: the main table's ($cc-$fd), then the $ce and $fe tables
BASIC7 = ('rgr rclr joy rdot dec hex$ err$ instr else resume trap tron troff '
          'sound vol auto pudef graphic paint char box circle gshape sshape '
          'draw locate color scnclr scale help do loop exit directory dsave '
          'dload header scratch collect copy rename backup delete renumber '
          'key monitor using until while '
          'pot bump pen rsppos rsprite rspcolor xor rwindow pointer '
          'bank filter play tempo movspr sprite sprcolor rreg envelope sleep '
          'catalog dopen append dclose bsave bload record concat dverify '
          'dclear sprsav collision begin bend window boot width sprdef quit '
          'stash fetch swap off fast slow').split()
TABLE = BASIC2 + BASIC7
NEW = set(BASIC7)
FUNCS = set('rgr rclr joy rdot dec hex$ err$ instr pot bump pen rsppos '
            'rsprite rspcolor xor rwindow pointer'.split())
STARTS = {'start', ':', 'then', 'else', 'do', 'loop'}


def keywords(line):
    """the BASIC 7.0 keywords in one source line's code: (keyword, use)"""
    s = line.strip()
    if not s or s.startswith("'"):
        return []
    s = s.lower()
    found, i, q, data = [], 0, False, False
    prev = 'start'			# what came before: start, :, a keyword, x
    m = re.match(r'\d+\s*', s)		# a line number
    if m:
        i = m.end()
    while i < len(s):
        ch = s[i]
        if ch == '{':			# a directive, label or control code
            j = s.find('}', i)
            i = len(s) if j < 0 else j + 1
            continue
        if ch == '"':
            q = not q
            i += 1
            continue
        if q:
            i += 1
            continue
        if data:
            if ch == ':':
                data = False
                prev = ':'
            i += 1
            continue
        if ch == "'":			# a comment to the line's end
            break
        if ch in ' \t':
            i += 1
            continue
        for k in TABLE:
            if s.startswith(k, i):
                if k in NEW:
                    nxt = s[i + len(k):].lstrip()[:1]
                    if k in FUNCS:
                        use = nxt == '('
                    elif k == 'using':
                        use = prev in ('print', 'print#')
                    else:
                        use = prev in STARTS and not s[i + len(k):i + len(k) + 1].isalpha()
                    found.append((k, use))
                if k == 'rem':
                    return found
                if k == 'data':
                    data = True
                prev = ':' if k == ':' else k
                i += len(k)
                break
        else:
            prev = ':' if ch == ':' else 'x'
            i += 1
    return found


def scan(path):
    """[(line, keyword, use)]"""
    out = []
    for n, l in enumerate(open(path, encoding='latin-1').read().split('\n'), 1):
        for k, use in keywords(l):
            out.append((n, k, use))
    return out


def fmt(hits):
    return ', '.join('%s (%d)' % (k, n) for n, k, u in hits)


def main():
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == 'check':
        for f in a[1:]:
            hits = scan(f)
            uses = [h for h in hits if h[2]]
            acc = [h for h in hits if not h[2]]
            if uses:
                print('%s: uses %s' % (f, fmt(uses)))
            if acc:
                print('%s: accidents (letters in 4.04, keywords in 4.06) %s' % (f, fmt(acc)))
        return 0
    if len(a) == 3 and a[0] == 'convert':
        f, out = a[1], a[2]
        src = open(f, encoding='latin-1').read()
        if not to406.USES.search(src):
            return 1			# not a 4.04 module
        hits = scan(f)
        uses = [h for h in hits if h[2]]
        acc = [h for h in hits if not h[2]]
        if not uses:
            return 1
        if acc:
            print('%s: BASIC 7.0 (%s), so built with C64List 4.06, which would '
                  'also read these as keywords: %s. Put a space in each '
                  '(cd or b), or write them another way' %
                  (os.path.basename(f), fmt(uses), fmt(acc)), file=sys.stderr)
            return 2
        lines = to406.preface_lines()
        new = []
        for l in src.split('\n'):
            if to406.USES.search(l):
                # on the same line, so the copy's line numbers are the
                # source's (C64List's messages)
                l = to406.USES.sub(r'{include:..\\Basic70.bas}', l)
                if '{number:' in src:
                    l += '{renumber}'
            else:
                l = to406.convert_line(l, lines)
                # 4.04 takes a label that is a number ({:3200}) as the
                # line's number; 4.06 as a plain label, numbering on from
                # the last {number:}: given its {number:} too (i.test
                # calls' &,66,1 jumps to 3200+an*50)
                l = re.sub(r'^(\s*)\{:(\d+)\}', r'\1{number:\2}{:\2}', l)
            new.append(l)
        open(out, 'w', encoding='latin-1').write('\n'.join(new))
        print('%s: BASIC 7.0 (%s): built with C64List 4.06' %
              (os.path.basename(f), ', '.join(sorted({k for n, k, u in uses}))))
        return 0
    sys.exit(__doc__)


if __name__ == '__main__':
    sys.exit(main())
