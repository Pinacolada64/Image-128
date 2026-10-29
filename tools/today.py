#!/usr/bin/env python3
"""today.py: list, check and edit the Today in History files (today.<Mon>,
read by i/lo/today) on a .d81 or as a SEQ file on the PC. The format is in
PROGRAMMING.md ("Today in History files").

    tools/today.py build/setup-test.d81 --month Nov list [--day 22] [--type R]
    tools/today.py today.nov.seq check
    tools/today.py DISK --month Oct add S 1028 1886 "The Statue of Liberty is dedicated."
    tools/today.py DISK --month Oct add R 1031 "Halloween." --weekday Fri
    tools/today.py DISK --month Nov sliding 4 Thu "Thanksgiving Day."
    tools/today.py DISK --month May sliding last Mon "Memorial Day, a legal holiday."
    tools/today.py DISK --month Oct delete 12
    tools/today.py DISK --month Oct replace 12 "New text for fact 12."

Facts are numbered in file order, as `list` shows them. `add` wraps its text
into C lines (each line at most 76 characters) and puts the fact after the
last one of its type on or before its day. `sliding` adds a one-line fact
for each of the 7 days the holiday can fall on, with the weekday in column
10 (1 Sunday ... 7 Saturday), so i/lo/today shows it only on that weekday.

Text is ASCII here, written as C64List's {alpha:alt} does: lowercase as
PETSCII $41-$5a, capitals as $c1-$da. A change to a .d81 copies the disk to
<disk>.bak-today first; detach it in x128 before changing it. Writing to a
.d81 uses c1541.
"""
import argparse, calendar, os, shutil, subprocess, sys, tempfile

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
TYPES = {'B': 'born', 'S': 'happened', 'R': "don't forget"}
WIDTH = 76      # longest line written (&,2,2 reads at most 80)
CONT = 0xc3     # PETSCII C: a continuation line, in column 10

def to_petscii(text):
    return bytes(ord(c) - 32 if c.islower() else ord(c) + 128 if c.isupper() else ord(c) for c in text)

def show(b):
    return ''.join(chr(c + 32) if 0x41 <= c <= 0x5a else chr(c - 128) if 0xc1 <= c <= 0xda
                   else chr(c) if 32 <= c < 127 else '{$%02x}' % c for c in b)

# --- the .d81 --------------------------------------------------------------

def off(t, s):
    return ((t - 1) * 40 + s) * 256

def dir_entries(d):
    t, s = 40, 3
    while t:
        b = off(t, s)
        for i in range(8):
            yield b + i * 32
        t, s = d[b], d[b + 1]

def find_entry(d, name):
    for e in dir_entries(d):
        if d[e + 2] & 7 and d[e + 5:e + 21].rstrip(b'\xa0') == name:
            return e
    return None

def read_file(d, e):
    out = bytearray()
    t, s = d[e + 3], d[e + 4]
    while t:
        b = off(t, s)
        if d[b] == 0:
            return bytes(out + d[b + 2:b + d[b + 1] + 1])
        out += d[b + 2:b + 256]
        t, s = d[b], d[b + 1]
    return bytes(out)

def disk_name(month):
    return to_petscii('today.' + month)

def load(a):
    if a.disk:
        d = open(a.source, 'rb').read()
        e = find_entry(d, disk_name(a.month))
        if e is None:
            sys.exit('today: no today.%s on %s' % (a.month, a.source))
        return read_file(d, e)
    return open(a.source, 'rb').read()

def save(a, data):
    if not a.disk:
        open(a.source, 'wb').write(data)
        print('%s written' % a.source)
        return
    shutil.copyfile(a.source, a.source + '.bak-today')
    with tempfile.TemporaryDirectory() as tmp:
        f = os.path.join(tmp, 'seq')
        open(f, 'wb').write(data)
        # c1541 writes the capital in "today.Nov" as PETSCII $ce, as the
        # maker's "today."+zm$ has it
        name = 'today.' + a.month
        r = subprocess.run(['c1541', a.source, '-delete', name, '-write', f, name + ',s'],
                           capture_output=True, text=True, errors='replace')
        if r.returncode:
            sys.exit('today: c1541 failed:\n' + r.stdout + r.stderr)
    d = open(a.source, 'rb').read()
    e = find_entry(d, disk_name(a.month))
    if e is None or read_file(d, e) != data:
        sys.exit('today: c1541 didn\'t write it; the old disk is %s.bak-today' % a.source)
    print('today.%s written to %s (%d bytes); the old disk is %s.bak-today'
          % (a.month, a.source, len(data), a.source))

# --- the file --------------------------------------------------------------

def split(data):
    """the file as lines, without the CRs; whatever follows the ^ line (the
    release's today.Dec has zeros there) is dropped"""
    lines = data.split(b'\r')
    for i, l in enumerate(lines):
        if l[:1] == b'^':
            return lines[:i + 1]
    return [l for l in lines if l] if lines[-1:] == [b''] else lines

def join(lines):
    return b''.join(l + b'\r' for l in lines)

def is_fact(l):
    return len(l) > 9 and show(l[:1]) in TYPES

def facts(lines):
    """(first line, number of lines) of each fact, in file order"""
    out = []
    for i, l in enumerate(lines):
        if is_fact(l) and l[9] == CONT and out and out[-1][0] + out[-1][1] == i:
            out[-1] = (out[-1][0], out[-1][1] + 1)
        elif is_fact(l) and l[9] != CONT:
            out.append((i, 1))
    return out

def fact_text(lines, f):
    i, n = f
    text = show(lines[i][10:])
    for l in lines[i + 1:i + n]:
        piece = show(l[10:])
        text += ('' if text.endswith(' ') else ' ') + piece
    return text.rstrip()

def describe(l):
    t, mmdd, year, flag = show(l[:1]), show(l[1:5]), show(l[5:9]), show(l[9:10])
    wd = ' (%ss only)' % calendar.day_name[(int(flag) + 5) % 7] if flag in '1234567' and flag.strip() else ''
    return t, mmdd, year, wd

def wrap(text, width):
    out, line = [], ''
    for w in text.split(' '):
        while len(w) > width:
            if line:
                out.append(line); line = ''
            out.append(w[:width]); w = w[width:]
        if not line:
            line = w
        elif len(line) + 1 + len(w) <= width:
            line += ' ' + w
        else:
            out.append(line); line = w
    if line:
        out.append(line)
    return out or ['']

def make_lines(t, mmdd, year, text, flag=' '):
    head = to_petscii(t) + mmdd.encode() + year.rjust(4).encode()
    pieces = wrap(text, WIDTH - 10)
    if flag != ' ' and len(pieces) > 1:
        sys.exit('today: a weekday fact must fit on one line (%d characters of text); '
                 'its C lines would show on the other weekdays as well' % (WIDTH - 10))
    return [head + to_petscii(flag) + to_petscii(pieces[0])] + \
           [head + bytes([CONT]) + to_petscii(p) for p in pieces[1:]]

def insert_at(lines, t, mmdd):
    """after the last fact of type t on or before mmdd; else before the
    first one after it; else before the ^"""
    fs = [f for f in facts(lines) if show(lines[f[0]][:1]) == t]
    before = [f for f in fs if show(lines[f[0]][1:5]) <= mmdd]
    if before:
        return before[-1][0] + before[-1][1]
    if fs:
        return fs[0][0]
    for i, l in enumerate(lines):
        if l[:1] == b'^':
            return i
    return len(lines)

def pick(lines, n):
    fs = facts(lines)
    if not 1 <= n <= len(fs):
        sys.exit('today: no fact %d (there are %d)' % (n, len(fs)))
    return fs[n - 1]

# --- the commands ----------------------------------------------------------

def cmd_list(a, lines):
    for n, f in enumerate(facts(lines), 1):
        t, mmdd, year, wd = describe(lines[f[0]])
        if a.day and int(mmdd[2:]) != a.day or a.type and t != a.type.upper():
            continue
        print('%4d %s %s/%s %s%s' % (n, t, mmdd[:2], mmdd[2:], year, wd))
        for piece in wrap(fact_text(lines, f), 70):
            print('       ' + piece)

def cmd_check(a, lines):
    problems = 0
    def say(i, what):
        nonlocal problems
        problems += 1
        print('line %d: %s\n    %s' % (i + 1, what, show(lines[i])))
    mm = '%02d' % (MONTHS.index(a.month) + 1) if a.month else None
    for i, l in enumerate(lines):
        if not l or l[:1] in (b'*', b'^'):
            continue
        if not is_fact(l):
            say(i, 'not a fact (B, S or R), a header (*) or the end (^)')
            continue
        if len(l) > 80:
            say(i, '%d characters: &,2,2 reads 80, the rest is lost' % len(l))
        mmdd = show(l[1:5])
        if not mmdd.isdigit() or not 1 <= int(mmdd[2:]) <= 31:
            say(i, 'the date (columns 2-5) isn\'t MMDD')
        elif mm and mmdd[:2] != mm:
            say(i, 'month %s in today.%s' % (mmdd[:2], a.month))
        flag = l[9]
        if flag == CONT:
            p = lines[i - 1] if i else b''
            if not is_fact(p):
                say(i, 'a C line with no fact before it')
            elif p[1:5] != l[1:5]:
                say(i, 'a C line with another date than the line before it')
            elif p[9] not in (CONT, 0x20):
                say(i, 'a C line after a weekday fact: on the other weekdays it is '
                       'joined onto whatever fact came before')
        elif flag != 0x20 and not 0x31 <= flag <= 0x37:
            say(i, 'column 10 is "%s": a space, C, or a weekday 1-7; this fact never shows'
                % show(bytes([flag])))
    per_day = {}
    for i, l in enumerate(lines):
        if is_fact(l):
            per_day.setdefault((show(l[:1]), show(l[3:5])), []).append(i)
    for (t, day), where in sorted(per_day.items()):
        if len(where) > 20:
            say(where[20], '%d lines of %s on day %s: i/lo/today holds 20 (dim zt$(3,20)), '
                           'then stops with ?bad subscript' % (len(where), t, day))
    if not any(l[:1] == b'^' for l in lines):
        print('no ^ line: i/lo/today reads until it finds one')
        problems += 1
    print('%d facts, %d problems' % (len(facts(lines)), problems))
    return problems

def cmd_add(a, lines):
    t = a.type.upper()
    if t not in TYPES:
        sys.exit('today: type is B, S or R')
    mmdd = a.date[:4]
    year = a.year or ''
    flag = ' '
    if a.weekday:
        flag = str([d.lower() for d in DAYS].index(a.weekday[:3].lower()) + 1)
    new = make_lines(t, mmdd, year, a.text, flag)
    i = insert_at(lines, t, mmdd)
    lines[i:i] = new
    for l in new:
        print('+ ' + show(l))
    return lines

def cmd_sliding(a, lines):
    m = MONTHS.index(a.month) + 1
    wd = [d.lower() for d in DAYS].index(a.weekday[:3].lower()) + 1
    last = calendar.monthrange(2001, m)[1]       # a common year
    if a.nth == 'last':
        if m == 2:
            sys.exit('today: "last" in February moves with leap years; give the days with add --weekday')
        first = last - 6
    else:
        first = 7 * int(a.nth) - 6
    days = range(first, first + 7)
    t = a.type.upper()
    for day in days:
        mmdd = '%02d%02d' % (m, day)
        new = make_lines(t, mmdd, '', a.text, str(wd))
        i = insert_at(lines, t, mmdd)
        lines[i:i] = new
        print('+ ' + show(new[0]))
    return lines

def cmd_delete(a, lines):
    i, n = pick(lines, a.n)
    for l in lines[i:i + n]:
        print('- ' + show(l))
    del lines[i:i + n]
    return lines

def cmd_replace(a, lines):
    i, n = pick(lines, a.n)
    l = lines[i]
    new = make_lines(show(l[:1]), show(l[1:5]), show(l[5:9]).strip(), a.text, show(l[9:10]))
    for old in lines[i:i + n]:
        print('- ' + show(old))
    for x in new:
        print('+ ' + show(x))
    lines[i:i + n] = new
    return lines

def main():
    ap = argparse.ArgumentParser(description='List, check and edit a Today in History file (today.<Mon>).', epilog='See the top of tools/today.py for examples.')
    ap.add_argument('source', help='a .d81, or a today.<Mon> SEQ file')
    ap.add_argument('--month', help='Jan ... Dec (needed with a .d81)')
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('list'); p.add_argument('--day', type=int); p.add_argument('--type')
    sub.add_parser('check')
    p = sub.add_parser('add')
    p.add_argument('type'); p.add_argument('date', help='MMDD')
    p.add_argument('year', nargs='?', help='the year (B and S; R has none)')
    p.add_argument('text')
    p.add_argument('--weekday', help='Sun ... Sat: show it only on that weekday')
    p = sub.add_parser('sliding')
    p.add_argument('nth', choices=['1', '2', '3', '4', 'last'])
    p.add_argument('weekday', help='Sun ... Sat'); p.add_argument('text')
    p.add_argument('--type', default='R')
    p = sub.add_parser('delete'); p.add_argument('n', type=int)
    p = sub.add_parser('replace'); p.add_argument('n', type=int); p.add_argument('text')
    a = ap.parse_args()
    a.disk = a.source.lower().endswith('.d81')
    if a.month:
        a.month = a.month[:3].capitalize()
        if a.month not in MONTHS:
            sys.exit('today: --month is Jan ... Dec')
    elif a.disk or a.cmd == 'sliding':
        sys.exit('today: give --month')
    if a.cmd == 'add' and (len(a.date) != 4 or not a.date.isdigit()):
        sys.exit('today: the date is MMDD')
    lines = split(load(a))
    if a.cmd == 'list':
        return cmd_list(a, lines)
    if a.cmd == 'check':
        sys.exit(1 if cmd_check(a, lines) else 0)
    lines = {'add': cmd_add, 'sliding': cmd_sliding, 'delete': cmd_delete,
             'replace': cmd_replace}[a.cmd](a, lines)
    save(a, join(lines))

main()
