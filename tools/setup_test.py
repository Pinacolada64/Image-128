#!/usr/bin/env python3
"""setup_test.py: run the new-system setup (i/su.config) on a copy of the
boot disk in x128, taking every default, then watch im boot from the new
configuration.

    tools/setup_test.py [disk.d81] [--cols 40|80] [--out disk.d81] [--drive9 TYPE] [--vice ARG ...] [--keep]

Copies build/image128.d81 (or the disk given) to build/setup-test.d81 (or
the --out disk: build/setup-test.d81 may be a configured run disk you want
to keep) and works on that. It presses 1 at im's start-up menu, then Return at every
prompt the setup shows (each takes its default), except the few in
`special` below that want a key, and logs each new line of the setup's frame (the "Part I:
Sysop Information" lines). After "Hit any key", it watches im until its
line number stops changing, and prints the screen and the line it stopped
on. x128 runs in warp mode through the remote monitor on port 6537 (not
6510, which a VICE of your own may have); --keep leaves it running.
--drive9 1571 (say) adds a drive 9 with no disk, for the Drives part's bus
scan; the scan's "Found:" line is logged too. --vice passes one argument
to x128 (repeat it), e.g. --vice -drive9type --vice 4000 --vice -dos4000
--vice <rom> for a CMD FD-4000. x128 has a DS12C887 RTC at $d700, as
start-image-128.sh has, and the Clock part chooses it (5, then base 1).
"""
import os, shutil, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vmon import X128

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]
cols = 40
if '--cols' in args:
    i = args.index('--cols'); cols = int(args[i + 1]); del args[i:i + 2]
out = None
if '--out' in args:
    i = args.index('--out'); out = args[i + 1]; del args[i:i + 2]
drive9 = None
if '--drive9' in args:
    i = args.index('--drive9'); drive9 = args[i + 1]; del args[i:i + 2]
vice = []
while '--vice' in args:
    i = args.index('--vice'); vice.append(args[i + 1]); del args[i:i + 2]
keep = '--keep' in args
args = [a for a in args if a != '--keep']
src = args[0] if args else os.path.join(repo, 'build', 'image128.d81')
disk = out or os.path.join(repo, 'build', 'setup-test.d81')
shutil.copyfile(src, disk)

# a DS12C887 RTC at $d700, as start-image-128.sh has (not -ds12c887rtcsave:
# the test leaves the saved RTC alone)
rtc = ['-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning']
v = X128(['-drive8type', '1581'] + (['-drive9type', drive9] if drive9 else []) +
         rtc + vice + ['-warp', '-autostart', disk + ':boot 128'], cols=cols, wait=2)
t0 = time.time()
# 11/06/2026: a crash in this script stops its x128 too (unless --keep), so
# the next run can have port 6537
import atexit
atexit.register(lambda: keep or v.p.poll() is not None or v.p.kill())


def ts():
    return '%6.1f' % (time.time() - t0)


def line():
    return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')


def rows():
    return [r for r in v.screen(25).split('\n')]


def press(ch):
    v.cmd('bank ram', '> 034a %02x' % ord(ch), '> 00d0 01')


def type_line(s):
    """s and Return into the keyboard buffer (10 keys at most)"""
    k = (s + '\r')[:10]
    v.cmd('bank ram', '> 034a ' + ' '.join('%02x' % ord(c) for c in k), '> 00d0 %02x' % len(k))


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
# The clock: the DS12C887 at $d700, as start-image-128.sh runs x128 (11/06/2026)
special = [('set the image bbs 128 system clock', '5', 'clock menu: 5 (DS12C887)'),
           ('ds12c887 base address', '1', 'DS12C887 base: 1 ($D700)'),
           ('which one?', '5', 'time zone: 5')]
# The sysop's password (11/06/2026): typed at the Sysop part's Password
# prompt, wrong at "Password again", then both again, matching. Each step
# answers the prompt on the cursor's row (by how it starts: the Password
# prompt shows the current one, PASS, after it, which four DELs clear; the
# keyboard buffer holds 10 keys); the Password item is reached by Return
# (the 5th item)
dels = '\x14' * 4
pw = [('password:', dels + 'pw1', 'password: typing pw1'),
      ('password again:', 'bad', 'password again: typing bad'),
      ('password:', dels + 'pw1', 'password: typing pw1 again'),
      ('password again:', 'pw1', 'password again: typing pw1')]
answered = set()
seen = set(); deadline = time.time() + 900   # 11/06/2026: 15 minutes (80 columns on a busy host took 10+)
while time.time() < deadline:
    for x in frame():
        if x and x not in seen:
            seen.add(x); print(ts(), 'frame:', x)
    # 11/06/2026: im's boot under way: the closing "Hit any key" was
    # answered (by a Return pressed before this saw it, on a slow run)
    if any(x.lower().startswith('reading drive configuration') for x in frame()):
        print(ts(), 'im booting: setup is over'); break
    screen = '\n'.join(rows()).lower()
    for r in screen.split('\n'):
        # the parts' menus (su.pick, 11/06/2026): "1-5, D(one), Return=next item"
        if ('found:' in r or 'return=' in r or 'time zone....' in r or 'to change' in r) and r.strip() not in seen:
            seen.add(r.strip()); print(ts(), 'screen:', r.strip())
    if ('time zone:' in screen or 'more?' in screen) and screen not in seen:
        seen.add(screen); print(ts(), 'time zone list:')
        print('\n'.join('   |' + r for r in rows()))
    if buffer_empty():
        if 'hit any key to continue' in screen:
            press('\r'); print(ts(), 'Hit any key: pressing Return')
            break
        cur = rows()[v.mem('ram00', 0xeb, 1)[0]].strip().lower()   # tblx: the cursor's row
        if pw and cur.startswith(pw[0][0]) and 'they don' not in cur:
            text, keys, note = pw.pop(0); type_line(keys); print(ts(), note)
            time.sleep(0.5); continue
        for text, key, note in special:
            if text in screen and text not in answered:
                answered.add(text); press(key); print(ts(), note)
                break
        else:
            press('\r')
    time.sleep(0.5)
else:
    print(ts(), 'setup still running after 15 minutes; at line', line())

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
if pw:
    print('password steps not reached:', [p[0] for p in pw])

if keep:
    print('x128 left running (monitor on port 6537)')
else:
    v.cmd('quit', resume=False)
    v.p.wait(timeout=30)
    print('disk:', disk)
