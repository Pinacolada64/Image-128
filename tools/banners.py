#!/usr/bin/env python3
"""banners.py: run tests/standin/banners.bas in x128 (80 columns) and show
each reversed row with its reverse cells marked, then check the three bars:
reversed from column 1 to ll%-2, the text centered in them.

    asm/build.sh; tools/standin.sh tests/standin/banners.bas; tools/banners.py
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vmon import X128

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
disk = os.path.join(repo, 'build', 'standin-banners.d81')
port = int(os.environ.get('VMON_PORT', '6583'))

x = X128(['-drive8type', '1581', '-warp', '-autostart', disk + ':boot 128'], cols=80, port=port)
try:
    for _ in range(60):
        time.sleep(2)
        s = x.screen()
        if 'done' in s:
            break
    chars = s.split('\n')
    raw = x.mem('vdc', 0, 25 * 80)   # reverse: bit 7 of the screen code
finally:
    x.stop()

bars, fails = [], 0
for r, line in enumerate(chars):
    if line.startswith('done'):
        break   # Image's status rows below
    rev = ''.join('#' if raw[r * 80 + c] & 0x80 else '.' for c in range(80))
    if '#' in rev:
        print(f'{r:2} {line}')
        print(f'   {rev.rstrip(".")}')
        bars.append((line, rev))
for i, (line, rev) in enumerate(bars):
    ll = 40 if i < 3 else 80
    first, last = rev.index('#'), rev.rindex('#')
    text = line.strip()
    start = line.index(text)
    want = (ll - len(text)) // 2
    ok = first == 1 and last == ll - 2 and start == want
    fails += not ok
    print(f'll% {ll}: {text!r}: reverse {first}-{last}, text at {start} (want 1-{ll - 2}, {want})',
          'ok' if ok else 'WRONG')
if len(bars) != 6:
    fails += 1
    print(f'{len(bars)} bars, not 6')
print('all ok' if fails == 0 else f'{fails} wrong')
sys.exit(1 if fails else 0)
