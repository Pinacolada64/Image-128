#!/usr/bin/env python3
"""setup_test.py: run the new-system setup (i/su.config) on a copy of the
boot disk in x128, taking every default, then watch im boot from the new
configuration.

    tools/setup_test.py [disk.d81] [--cols 40|80] [--out disk.d81] [--drive9 TYPE] [--vice ARG ...] [--keep] [--help]

Copies build/image128.d81 (or the disk given) to build/setup-esc-test.d81,
a test-only disk (or the --out disk), and works on that. (11/06/2026: the
default was build/setup-test.d81, start-image-128.sh's run disk, which a
run without --out replaced with an unconfigured copy.) It presses 1 at im's start-up menu, then Return at every
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

USAGE = """usage: tools/setup_test.py [disk.d81] [options]

  disk.d81          the disk to set up (a copy of it): default build/image128.d81
  --out disk.d81    the copy to work on: default build/setup-esc-test.d81
                    (test-only; not the run disk, build/setup-test.d81)
  --cols 40|80      the screen: default 40
  --drive9 TYPE     a drive 9 with no disk (1541, 1571, 1581, 4000...) for the
                    Drives part's bus scan; 4844 (or hd) is a CMD HD: a fresh
                    copy of build/cmdhd-base.dhd as build/setup-esc-test.dhd,
                    with ROMs/cmd_hd_bootrom_v2.80.bin (as start-setup.sh -hd)
  --hd-drives LIST  with --drive9 4844: which of Image's drives (1-6) to put
                    on the HD, each at the partition setup suggests: default
                    4,6 (until setup copies files: the build's files are on
                    drive 8, and im loads s.* (1), nm.times (2), e.ecs.main
                    and the other e.* defaults (3) and the modules (5) at boot)
  --vice ARG        one more argument for x128 (repeat it for more)
  --keep            leave x128 running at the end (on its monitor port)
  --port N          the x128's remote monitor port: default 6537 (another
                    for a second run at once)
  -h, --help        this list (the notes at the top of the script say more)
"""

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
args = sys.argv[1:]
# 11/06/2026: --help; and an option it doesn't know stops it (it was taken
# as the disk's name)
if '-h' in args or '--help' in args:
    print(USAGE, end=''); sys.exit(0)
cols = 40
if '--cols' in args:
    i = args.index('--cols'); cols = int(args[i + 1]); del args[i:i + 2]
out = None
if '--out' in args:
    i = args.index('--out'); out = args[i + 1]; del args[i:i + 2]
drive9 = None
if '--drive9' in args:
    i = args.index('--drive9'); drive9 = args[i + 1]; del args[i:i + 2]
port = 6537
if '--port' in args:
    i = args.index('--port'); port = int(args[i + 1]); del args[i:i + 2]
hddrives = None
if '--hd-drives' in args:
    i = args.index('--hd-drives'); hddrives = args[i + 1]; del args[i:i + 2]
vice = []
while '--vice' in args:
    i = args.index('--vice'); vice.append(args[i + 1]); del args[i:i + 2]
keep = '--keep' in args
args = [a for a in args if a != '--keep']
bad = [a for a in args if a.startswith('-')]
if bad or len(args) > 1:
    print('setup_test.py: unknown ' + ('option ' + bad[0] if bad else 'argument ' + args[1]), file=sys.stderr)
    print(USAGE, end='', file=sys.stderr); sys.exit(2)
src = args[0] if args else os.path.join(repo, 'build', 'image128.d81')
disk = out or os.path.join(repo, 'build', 'setup-esc-test.d81')
# never the run disk (start-image-128.sh's), whatever --out says
if os.path.abspath(disk) == os.path.join(repo, 'build', 'setup-test.d81'):
    sys.exit('setup_test.py: build/setup-test.d81 is the run disk: give --out another name')
shutil.copyfile(src, disk)

# a DS12C887 RTC at $d700, as start-image-128.sh has (not -ds12c887rtcsave:
# the test leaves the saved RTC alone)
rtc = ['-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning']
# 11/06/2026: a CMD HD needs its boot ROM and an image as well as the type
# (start-setup.sh -hd): a fresh copy of the partitioned base image, test-only
# 11/06/2026: another x128 on the monitor port would be the one this
# drives (its own couldn't listen there): stop instead
# (by listening on it, not connecting: a connection stops that emulator)
import socket
_s = socket.socket()
# (SO_REUSEADDR: a quit x128's old connections, in TIME_WAIT, don't count;
# a listening one still does)
_s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    _s.bind(('127.0.0.1', port))
except OSError:
    sys.exit('setup_test.py: an x128 already has monitor port %d (another test run?): quit it, or --port another' % port)
finally:
    _s.close()
d9 = ['-drive9type', drive9] if drive9 else []
if drive9 in ('4844', 'hd'):
    rom = os.path.join(repo, 'ROMs', 'cmd_hd_bootrom_v2.80.bin')
    base = os.path.join(repo, 'build', 'cmdhd-base.dhd')
    for f in (rom, base):
        if not os.path.exists(f):
            sys.exit('setup_test.py: --drive9 4844 needs ' + os.path.relpath(f, repo))
    hdimg = os.path.join(repo, 'build', 'setup-esc-test.dhd')
    shutil.copyfile(base, hdimg)
    d9 = ['-drive9type', '4844', '-dosCMDHD', rom, '-9', hdimg]
# the drives the Drives part puts on the HD: their Device questions get 9
# (the partition question then keeps the one named like the drive)
labels = ['system', 'e-mail', 'etcetera', 'directory', 'module', 'user']
if drive9 in ('4844', 'hd'):
    nums = [int(x) for x in (hddrives or '4,6').split(',') if x.strip()]
    tohd = [labels[n - 1] + ' device:' for n in nums]
    print('drives on the HD (device 9):', ', '.join(labels[n - 1] for n in nums))
else:
    tohd = []
v = X128(['-drive8type', '1581'] + d9 +
         rtc + vice + ['-warp', '-autostart', disk + ':boot 128'], cols=cols, wait=2, port=port)
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
           ]
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
zone_at = 0
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
        # the time zone list's question, on the cursor's row (11/06/2026: a
        # one-time '5' matched on the screen could land on the list's own
        # "<Hit any key>" pause instead, and the zone stayed unset)
        # (not again within 5 seconds: until the 5 is echoed, the row still
        # reads "Which One?", and a second 5 and Return reached im's idle
        # screen after the boot: i/lo.misc's "Activity, Idle or Net Log?")
        if cur.startswith('which one?') and cur.rstrip().endswith('?') and time.time() - zone_at > 5:
            type_line('5'); print(ts(), 'time zone: 5'); zone_at = time.time()
            time.sleep(0.5); continue
        # a drive going on the HD: its Device question (edit mode: the
        # cursor's row is the bare prompt, the answer typed there)
        if cur in tohd:
            tohd.remove(cur); type_line('9'); print(ts(), cur, 'typing 9')
            time.sleep(0.5); continue
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
    print('x128 left running (monitor on port %d)' % port)
else:
    v.cmd('quit', resume=False)
    v.p.wait(timeout=30)
    print('disk:', disk)
