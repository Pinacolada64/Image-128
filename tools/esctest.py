#!/usr/bin/env python3
"""esctest.py: check the 128 screen editor's Esc sequences through Image's
& output, on the console, with tests/standin/esc.bas.

    tools/standin.sh tests/standin/esc.bas      (makes build/standin-esc.d81)
    tools/esctest.py [--cols 40|80] [--port N]

The stand-in draws rows 2-7 ("1abcdefghij".."6abcdefghij"), puts Image's
cursor at row 4, column 4 (&,70), sends Esc and a letter, then prints "*";
it does that for each sequence below, then all again with the screen mask on
(&,18,1). At each step it waits (2817 = the step, 2816 = 0) for this script,
which reads the screen and Image's cursor (sline $eb, scnpos $ec) and
compares them with what the 128's editor should do. T/B (a window) is
expected not to work: Image does its own carriage returns and cursor
placing, which the editor's window doesn't govern; it's checked to stay
that way (so a change shows).

Port 6538 (not a running test's: see tools/vmon.py). The disk is used from
a copy (build/esctest.d81).
"""
import argparse, os, shutil, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

B = {r + 2: '%dabcdefghij' % (r + 1) for r in range(6)}   # rows 2-7


def rows(**changes):
    """the pattern with some rows changed (r4='...'), rows 2-8"""
    d = dict(B)
    d[8] = ''
    for k, v in changes.items():
        d[int(k[1:])] = v
    return d


# test number -> (letter, expected rows, expected (sline, scnpos) after the "*")
TESTS = {
    1: ('Q', 'erase to the end of the line', rows(r4='3abc*'), (4, 5)),
    2: ('P', 'erase to the start of the line', rows(r4='    *efghij'), (4, 5)),
    3: ('@', 'erase to the end of the window', rows(r4='3abc*', r5='', r6='', r7=''), (4, 5)),
    4: ('J', 'the start of the line', rows(r4='*abcdefghij'), (4, 1)),
    5: ('K', 'the end of the line', rows(r4='3abcdefghij*'), (4, 12)),
    6: ('I', 'insert a line', rows(r4='*', r5='3abcdefghij', r6='4abcdefghij',
                                   r7='5abcdefghij', r8='6abcdefghij'), (4, 1)),
    7: ('D', 'delete the line', rows(r4='*abcdefghij', r5='5abcdefghij', r6='6abcdefghij',
                                     r7=''), (4, 1)),
    8: ('V', 'scroll up', {1: '1abcdefghij', 2: '2abcdefghij', 3: '3abcdefghij',
                           4: '4abc*efghij', 5: '5abcdefghij', 6: '6abcdefghij', 7: ''}, (4, 5)),
    9: ('W', 'scroll down', {3: '1abcdefghij', 4: '2abc*efghij', 5: '3abcdefghij',
                             6: '4abcdefghij', 7: '5abcdefghij', 8: '6abcdefghij'}, (4, 5)),
    10: ('O', 'cancel quote/insert (no change)', rows(r4='3abc*efghij'), (4, 5)),
    11: ('T/B', 'a window, rows 3-5 (known not to work)',
         {3: 'w1bcwefghij', 4: '3abc efghij', 5: '4abc efghij'}, None),
}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--cols', type=int, default=80, choices=(40, 80))
    ap.add_argument('--port', type=int, default=6538)
    args = ap.parse_args()
    src = os.path.join(repo, 'build', 'standin-esc.d81')
    if not os.path.exists(src):
        sys.exit('esctest.py: no build/standin-esc.d81: tools/standin.sh tests/standin/esc.bas')
    disk = os.path.join(repo, 'build', 'esctest.d81')
    shutil.copy(src, disk)
    v = X128(['-ntsc', '-drive8type', '1581', '-autostart-warp', '-autostart', disk + ':boot 128'],
             cols=args.cols, wait=2, port=args.port)
    results, last, t0 = [], None, time.time()
    try:
        while time.time() - t0 < 300:
            time.sleep(1)
            b = v.mem('ram00', 0x0b00, 2)
            step = b[1]
            if step == 255:     # done (2816 is still the 1 poked last)
                break
            if not step or step == last or b[0] != 0:
                continue
            last = step
            mask, t = divmod(step, 100)
            letter, what, want, cur = TESTS[t]
            scr = v.screen(25).split('\n')
            sp = tuple(v.mem('ram00', 0xeb, 2))
            bad = [r for r, text in want.items() if scr[r].rstrip() != text]
            curbad = cur is not None and sp != cur
            ok = not bad and not curbad
            label = 'mask %s  Esc %-3s %-38s' % ('on ' if mask else 'off', letter, what)
            print('%s %s' % (label, 'PASS' if ok else 'FAIL'), flush=True)
            if not ok:
                for r in sorted(want):
                    mark = '  ' if r not in bad else '!='
                    print('      row %d: %-14r %s %r' % (r, scr[r].rstrip(), mark, want[r]))
                if curbad:
                    print('      Image\'s cursor (sline, scnpos) %s, expected %s' % (sp, cur))
            results.append(ok)
            v.cmd('bank ram', '> 0b00 01')
        else:
            print('esctest.py: timed out at step', last)
    finally:
        v.cmd('quit', resume=False)
    print('%d of %d passed (%d columns)' % (sum(results), len(results), args.cols))
    return 0 if results and all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
