#!/usr/bin/env python3
"""setup_test.py: run the new-system setup (i/su.config) on a copy of the
boot disk in x128, taking every default, then watch im boot from the new
configuration.

    tools/setup_test.py [disk.d71] [--cols 40|80] [--keep]

Copies build/image128.d71 (or the disk given) to build/setup-test.d71 and
works on that. It presses 1 at im's start-up menu, then Return at every
prompt the setup shows (each takes its default), except the few in
`special` below that want a key, and logs each new line of the setup's frame (the "Part I:
Sysop Information" lines). After "Hit any key", it watches im until its
line number stops changing, and prints the screen and the line it stopped
on. x128 runs in warp mode through the remote monitor on port 6537 (not
6510, which a VICE of your own may have); --keep leaves it running.
"""
import os, shutil, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vmon import X128

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]
cols = 40
if '--cols' in args:
    i = args.index('--cols'); cols = int(args[i + 1]); del args[i:i + 2]
keep = '--keep' in args
args = [a for a in args if a != '--keep']
src = args[0] if args else os.path.join(repo, 'build', 'image128.d71')
disk = os.path.join(repo, 'build', 'setup-test.d71')
shutil.copyfile(src, disk)

v = X128(['-drive8type', '1571', '-warp', '-autostart', disk + ':boot 128'], cols=cols, wait=2)
t0 = time.time()


def ts():
    return '%6.1f' % (time.time() - t0)


def line():
    return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')


def rows():
    return [r for r in v.screen(25).split('\n')]


def press(ch):
    v.cmd('bank ram', '> 034a %02x' % ord(ch), '> 00d0 01')


def buffer_empty():
    return v.mem('ram00', 0xd0, 1)[0] == 0


def frame():
    """the two lines inside the setup's frame (rows 3-4)"""
    r = rows()
    return tuple(x.strip(' .').strip() for x in r[3:5])


# 1. wait for the start-up menu (im's key loop at 3410), then press 1
deadline = time.time() + 120
while line() != 3410:
    if time.time() > deadline:
        print(ts(), 'never reached the start-up menu; at line', line())
        print('\n'.join(rows())); v.stop(); sys.exit(1)
    time.sleep(1)
print(ts(), 'start-up menu: pressing 1')
press('1')

# 2. the setup: Return at every prompt, until its last one ("Hit any key to
# continue") has been answered. (The line number can't tell: the setup's
# prompts run in im's subroutines too, lines 1-96, 3404 and 3414.)
# Prompts that need a key other than Return, by text on the screen; each
# is answered once.
special = [('set the image 3.0 system clock', '1', 'clock menu: 1 (Manually)')]
answered = set()
seen = set(); deadline = time.time() + 600
while time.time() < deadline:
    for x in frame():
        if x and x not in seen:
            seen.add(x); print(ts(), 'frame:', x)
    screen = '\n'.join(rows()).lower()
    if buffer_empty():
        if 'hit any key to continue' in screen:
            press('\r'); print(ts(), 'Hit any key: pressing Return')
            break
        for text, key, note in special:
            if text in screen and text not in answered:
                answered.add(text); press(key); print(ts(), note)
                break
        else:
            press('\r')
    time.sleep(0.5)
else:
    print(ts(), 'setup still running after 10 minutes; at line', line())

# 3. im boots from the new configuration: wait until its line settles
history = []
deadline = time.time() + 240
while time.time() < deadline:
    n = line(); history.append(n)
    if len(history) >= 10 and len(set(history[-10:])) == 1:
        break
    time.sleep(1)
print(ts(), 'im settled at line', history[-1] if history else line())
print('\n'.join(r for r in rows() if r.strip()))

if keep:
    print('x128 left running (monitor on port 6537)')
else:
    v.cmd('quit', resume=False)
    v.p.wait(timeout=30)
    print('disk:', disk)
