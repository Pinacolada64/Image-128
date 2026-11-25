#!/usr/bin/env python3
"""centseq.py IN OUT: an Empire II (Centipede 128 BBS) text file, as unpacked
from game11.zip's EMPIREDELUXE.LBR (`_WIN1`, `_TOURNEY 1`...), made into an
Image SEQ file for 40 columns (11/24/2026; the rules the s.emp6.win* files
were made by on 11/22, which this reproduces byte for byte):

- Centipede's clear-screen MCI, `£d1` alone on a line, is {clear} ($93)
- a line that starts with three or four spaces (after any colour codes)
  begins a paragraph, its indent made three; the lines after
  it, up to the next such line or a blank one, join on to it, two spaces
  after a full stop made one
- each paragraph is wrapped at 39 visible characters (colour and other
  control codes, $00-$1f and $80-$9f, count nothing), lines ended with a
  return; the paragraph's indent and its colour code stay on its first line
- blank lines, and a line on its own (the centred `<Press any Key>£g1`, a
  result line such as "You gain 30,000 gold!!" after a blank line), are
  kept as they are

The bytes stay PETSCII throughout; only spaces and returns move.

    centseq.py --text TXT OUT: from a plain text file instead, coloured as
    the Centipede texts are (below)"""
import sys

WIDTH = 39


def visible(b):
    return sum(1 for c in b if not (c < 0x20 or 0x80 <= c < 0xa0))


def wrap(words, first_prefix):
    lines, cur = [], first_prefix
    for w in words:
        if visible(cur) and visible(cur.rstrip(b' ')) and cur.strip(b' ') != b'' and not cur.endswith(b' ') and cur != first_prefix:
            trial = cur + b' ' + w
        else:
            trial = cur + w
        if visible(trial) > WIDTH and cur.strip(b' ') and cur != first_prefix:
            lines.append(cur)
            cur = w
        else:
            cur = trial
    lines.append(cur)
    return lines


def lead_indent(line):
    """the length of a paragraph's start, its colour codes then three or
    four spaces (win5 indents by four; five or more is a centred line), or 0"""
    i = 0
    while i < len(line) and (line[i] < 0x20 or 0x80 <= line[i] < 0xa0):
        i += 1
    rest = line[i:]
    n = len(rest) - len(rest.lstrip(b' '))
    if n in (3, 4):
        return i + n
    return 0


def convert(data):
    src = data.split(b'\r')
    if src and src[-1] == b'':
        src.pop()
    out = []
    para = None
    indent = b''

    def flush():
        nonlocal para
        if para is None:
            return
        text = b' '.join(para)
        while b'.  ' in text:
            text = text.replace(b'.  ', b'. ')
        while b'  ' in text:
            text = text.replace(b'  ', b' ')
        words = [w for w in text.split(b' ') if w]
        out.extend(wrap(words, indent))
        para = None

    for line in src:
        if line == b'\\D1':
            flush()
            out.append(b'\x93')
        elif line.strip(b' ') == b'':
            flush()
            out.append(b'')
        elif lead_indent(line):
            # three spaces, after any colour codes (win2: "{$1e}   Finally")
            flush()
            n = lead_indent(line)
            # the indent made three spaces, as the 11/22 files have it
            indent, para = line[:n].rstrip(b' ') + b'   ', [line[n:]]
        elif line.startswith(b'     '):
            # a centred line (<Press any Key>): as it is
            flush()
            out.append(line)
        elif para is not None:
            para.append(line.rstrip(b' '))
        else:
            out.append(line)
    flush()
    return b'\r'.join(out) + b'\r'


# --text: from a plain text file instead (games/empire6/"tourney N.txt",
# the user's 2014 corrections of the Centipede texts: typos, and "about a
# bazillion extra commas"; 11/24/2026). Paragraphs are separated by blank
# lines or begin with three spaces; each is given a colour in turn, as the
# Centipede texts colour theirs, and the result line ("You win ...", "You
# lose ...") is purple with its amounts white, as theirs are. Then the same
# wrapping as above.
PARA_COLOURS = [0x9e, 0x96, 0x9c, 0x99]   # yellow, light red, purple, light green
RESULT, AMOUNT = 0x9c, 0x05


def petscii(text):
    """ASCII to PETSCII as Image's files have it: a-z $41-$5a, A-Z $c1-$da,
    the backslash (Centipede's pound, MCI) $5c"""
    out = bytearray()
    for c in text:
        o = ord(c)
        if 'a' <= c <= 'z':
            out.append(o - 32)
        elif 'A' <= c <= 'Z':
            out.append(o + 0x80)
        else:
            out.append(o)
    return bytes(out)


def from_text(text):
    import re
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    lines = text.split('\n')
    paras, cur, tail = [], [], []
    for line in lines:
        if 'Press any' in line:
            tail.append(line.rstrip())
            continue
        if not line.strip():
            if cur:
                paras.append(' '.join(cur)); cur = []
            continue
        if line.startswith('   ') and cur:
            paras.append(' '.join(cur)); cur = []
        cur.append(line.strip())
    if cur:
        paras.append(' '.join(cur))
    src = []
    k = 0
    for p in paras:
        if re.match(r'You (win|lose|have)', p):
            body = re.sub(r'(\d[\d,]*)', lambda m: '\x05' + m.group(1) + chr(RESULT), p)
            src += [b'', bytes([RESULT]) + b'   ' + petscii(body)]
        else:
            src.append(bytes([PARA_COLOURS[k % len(PARA_COLOURS)]]) + b'   ' + petscii(p))
            k += 1
    src += [petscii(t) for t in tail]
    return convert(b'\r'.join(src) + b'\r')


if __name__ == '__main__':
    a = sys.argv[1:]
    if len(a) == 3 and a[0] == '--text':
        text = open(a[1], encoding='latin-1').read()
        open(a[2], 'wb').write(from_text(text))
    elif len(a) == 2:
        data = open(a[0], 'rb').read()
        open(a[1], 'wb').write(convert(data))
    else:
        sys.exit(__doc__)
