#!/usr/bin/env python3
"""visesc.py: ++ visual's Esc I and Esc D (insert, delete a line), on the
console, with tests/standin/visesc.bas.

    tools/standin.sh tests/standin/visesc.bas    (makes build/standin-visesc.d81)
    tools/visesc.py [--cols 40|80] [--vesc 0|1] [--port N]

The stand-in fills tt$(1-30) with "line 1".."line 30" (28 blank) and starts
++ visual (&,16,1) with vesc (protostart+6, which sub.editor pokes from the
caller's "C128 Esc Codes") 0, the rows drawn again, or 1, the 128's own Esc
codes; both by default. This types the keys of each step below and waits
for the screen to show what it should (page rows 1-23 are screen rows
0-22; row 23 must stay blank). Last, Ctrl-X: the lines saved, which the
stand-in prints (mline, then each line's number, "-" for a blank line).

Port 6538 (not a running test's: see tools/vmon.py). The disk is used from
a copy (build/visesc.d81).
"""
import argparse, os, shutil, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

DOWN, UP, ESC, CTRLV, CTRLX = '\x11', '\x91', '\x1b', '\x16', '\x18'
MARK = '*** End of Text ***'


def page(lines, top):
    """screen rows 0-23 for the page starting at tt$(top), lines a dict
    (line number -> text; missing: blank) and the marker after the last"""
    last = max(n for n, t in lines.items() if t)
    rows = {}
    for r in range(24):
        n = top + r
        rows[r] = '' if r == 23 else MARK if n == last + 1 else lines.get(n, '')
    return rows


def text(nums):
    return {i + 1: ('line %d' % n if n else '') for i, n in enumerate(nums)}


START = [n if n != 28 else 0 for n in range(1, 31)]
DEL3 = [1, 2] + START[3:]                       # line 3 gone
INS3 = [1, 2, 0] + START[3:]                    # a blank line 3 again
DEL30 = INS3[:29]                               # line 30 gone
DEL29 = INS3[:27]                               # then 29: 28 is blank, the end is 27

STEPS = [
    ('page 1', '', page(text(START), 1)),
    ('Esc D on line 3', DOWN + DOWN + ESC + 'D', page(text(DEL3), 1)),
    ('Esc I on line 3', ESC + 'I', page(text(INS3), 1)),
    ('Ctrl-V: page 2', CTRLV, page(text(INS3), 24)),
    ('Esc D on line 30 (the last)', DOWN * 4 + ESC + 'D', page(text(DEL30), 24)),
    ('Esc D on line 29 (the marker back two)', UP + ESC + 'D', page(text(DEL29), 24)),
]
SAVED = 'mline 28', ' '.join(str(n) if n else '-' for n in DEL29)


def run(args, vesc):
    src = os.path.join(repo, 'build', 'standin-visesc.d81')
    disk = os.path.join(repo, 'build', 'visesc.d81')
    shutil.copy(src, disk)
    v = X128(['-ntsc', '-drive8type', '1581', '-autostart-warp', '-autostart', disk + ':boot 128'],
             cols=args.cols, wait=2, port=args.port)
    results = []
    try:
        t0 = time.time()
        while v.mem('ram00', 0x0b01, 1)[0] != 1:
            if time.time() - t0 > 120:
                print('visesc.py: the stand-in never got ready'); return [False]
            time.sleep(1)
        v.cmd('bank ram', '> 0b02 %02x' % vesc, '> 0b00 01')
        for name, keys, want in STEPS:
            if keys:
                v.type(keys)
            t0 = time.time()
            while True:
                scr = v.screen(25).split('\n')
                bad = [r for r in want if scr[r].rstrip() != want[r]]
                if not bad or time.time() - t0 > 20:
                    break
                time.sleep(1)
            print('vesc %d  %-40s %s' % (vesc, name, 'FAIL' if bad else 'PASS'), flush=True)
            if bad:
                for r in sorted(want):
                    print('      row %2d: %-22r %s %r' % (r, scr[r].rstrip(), '!=' if r in bad else '  ', want[r]))
            results.append(not bad)
        v.type(CTRLX)
        t0 = time.time()
        while v.mem('ram00', 0x0b01, 1)[0] != 2 and time.time() - t0 < 30:
            time.sleep(1)
        scr = v.screen(25).split('\n')
        got = scr[0].strip(), ' '.join(' '.join(scr[1:6]).split())
        ok = got == SAVED
        print('vesc %d  %-40s %s' % (vesc, 'Ctrl-X: the lines saved', 'PASS' if ok else 'FAIL'), flush=True)
        if not ok:
            print('      got  %r\n      want %r' % (got, SAVED))
        results.append(ok)
    finally:
        v.cmd('quit', resume=False)
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--cols', type=int, default=40, choices=(40, 80))
    ap.add_argument('--vesc', type=int, choices=(0, 1))
    ap.add_argument('--port', type=int, default=6538)
    args = ap.parse_args()
    if not os.path.exists(os.path.join(repo, 'build', 'standin-visesc.d81')):
        sys.exit('visesc.py: no build/standin-visesc.d81: tools/standin.sh tests/standin/visesc.bas')
    results = []
    for vesc in ([args.vesc] if args.vesc is not None else [0, 1]):
        results += run(args, vesc)
    print('%d of %d passed (%d columns)' % (sum(results), len(results), args.cols))
    return 0 if results and all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
