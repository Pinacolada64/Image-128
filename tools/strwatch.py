#!/usr/bin/env python3
"""strwatch.py: run strcheck's checks over and over in a running x128,
and stop at the first BASIC line where the string area goes bad.

    tools/strwatch.py [--port 6510] [--interval 0.5]

Each round pauses x128 for one monitor session (zero page and bank 1,
as strcheck.py reads them), notes the BASIC line it was on (curlin,
$3b/$3c; $ffxx is direct mode), checks the string area and lets x128 run
on. It prints each new line it finds and stops at the first round with
damage, with strcheck's report and the lines it passed through before.
Start it, then do what breaks (a logoff, say). Rounds take a second or
so, so lines in between are missed; the last good line and the first bad
one bracket where it happened. A round that looks bad is read again a
moment later: one that stopped the CPU in the middle of ML moving things
(&,28 sets the pointers, then moves the arrays) is clean by then, and
isn't damage. Ctrl+C stops it.
"""
import argparse, collections, sys, time
from strcheck import read_state, analyze

CURLIN = 0x3b


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--port', type=int, default=6510, help='remote monitor port (default 6510)')
    ap.add_argument('--interval', type=float, default=0.5, help='seconds between rounds')
    args = ap.parse_args()

    seen = collections.deque(maxlen=40)     # (time, line) of the last rounds
    last = None; t0 = time.time(); rounds = 0
    try:
        while True:
            zp, lo, b1 = read_state(args.port)
            line = zp[CURLIN] | zp[CURLIN + 1] << 8
            report = []
            bad = analyze(zp, lo, b1, out=report.append)
            if bad:
                # a round can stop the CPU in the middle of ML that's moving
                # things (&,28 sets the pointers, then moves the arrays, then
                # relinks): look again before calling it damage
                time.sleep(0.3)
                zp2, lo2, b12 = read_state(args.port)
                report2 = []
                if not analyze(zp2, lo2, b12, out=report2.append):
                    print('%7.1fs  %-12s caught mid-operation; clean a moment later'
                          % (time.time() - t0, 'line %d' % line), flush=True)
                    bad = 0
                else:
                    zp, lo, b1, report = zp2, lo2, b12, report2
                    line = zp[CURLIN] | zp[CURLIN + 1] << 8
            rounds += 1
            t = time.time() - t0
            if line != last or bad:
                shown = 'direct mode' if line >= 0xff00 else 'line %d' % line
                print('%7.1fs  %-12s %s' % (t, shown, 'BAD' if bad else 'ok'), flush=True)
                seen.append((t, line)); last = line
            if bad:
                print('\nfirst damage at %s, after %d clean rounds. lines before it:'
                      % ('direct mode' if line >= 0xff00 else 'line %d' % line, rounds - 1))
                print('  ' + ' '.join(str(l) for _, l in seen))
                print('\nstrcheck:')
                for r in report:
                    print('  ' + r)
                sys.exit(1)
            time.sleep(args.interval)
    except KeyboardInterrupt:
        print('\nstopped after %d rounds, no damage seen' % rounds)


if __name__ == '__main__':
    main()
