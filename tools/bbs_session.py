#!/usr/bin/env python3
"""bbs_session.py: drive a configured Image 128 BBS in x128, a step at a
time, from the shell: for trying a module by hand (Empire's port was tested
this way, 11/20/2026).

    tools/bbs_session.py boot DISK   start x128 on DISK (80 columns, warp,
                     JiffyDOS, the DS12C887), boot to the idle screen, turn
                     Loc on and Instant Login as the sysop (PW1), answering
                     the logon's questions; x128 keeps running
    tools/bbs_session.py type TEXT [SECS]   type TEXT, wait SECS (4), show the
                     screen. \\r is Return, %XX a byte: shifted capitals for
                     Image's input are %c1-%da (R, 3, EMPIRE: unshifted, so
                     lowercase, as typed ASCII capitals are)
    tools/bbs_session.py screen      the screen and BASIC's line
    tools/bbs_session.py update DISK FILE.prg...   rewrite modules on the
                     attached disk without rebooting: detach drive 8, write
                     each as its disk name (build/i_emp.town.prg as
                     "i/emp.town"), attach again. A module already in memory
                     is used until another replaces it (im's p1$)
    tools/bbs_session.py warp on|off
    tools/bbs_session.py stop

The disk is a configured system on one 1581 (all six Image drives on device
8), e.g. a copy of one tools/visual_wf.py used. Monitor port 6590; the ML's
symbols (for the lightbar's redraw flag) from asm/ml.sym, or BBS_ML_SYM.
"""
import os, sys, time, subprocess
REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(REPO, 'tools'))
from vmon import X128
PORT = 6590
JIFFY = os.path.expanduser('~/Documents/c64/JiffyDOS')
CHKTBL = 0x1300
PIDFILE = os.path.join(REPO, 'build', 'bbs_session.pid')


def attach():
    x = X128.__new__(X128)
    x.port = PORT
    return x


def line(v):
    return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')


def show(v, t=''):
    print('--- %s (BASIC line %d)' % (t, line(v)), flush=True)
    for i, r in enumerate(v.screen(25).split('\n')):
        if r.strip():
            print('%2d|%s' % (i, r))


def until(v, cond, secs):
    t0 = time.time()
    while time.time() - t0 < secs:
        time.sleep(2)
        if cond():
            return True
    return False


def sym(name):
    for l in open(os.environ.get('BBS_ML_SYM', os.path.join(REPO, 'asm', 'ml.sym'))):
        p = l.split()
        if len(p) >= 3 and p[0] == name:
            return int(p[2].lstrip('$'), 16)
    sys.exit('no ' + name)


def boot(disk):
    jiffy = []
    if os.path.exists(os.path.join(JIFFY, 'JDOS128.rom')):
        jiffy = ['-kernal', os.path.join(JIFFY, 'JDOS128.rom'), '-dos1581', os.path.join(JIFFY, 'Jiffy1581.rom')]
    p = subprocess.Popen(['x128', '-80col', '+sound', '-remotemonitor', '-remotemonitoraddress',
                          f'127.0.0.1:{PORT}', '-ntsc', '-drive8type', '1581', *jiffy,
                          '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
                          '-warp', '-autostart', disk + ':boot 128'],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    open(PIDFILE, 'w').write(str(p.pid))
    time.sleep(3)
    v = attach()
    retried = [False]

    def booted():
        if 4200 <= line(v) < 4300:
            return True
        scr = v.screen(25).lower()
        if 'ready.' in scr and 'image bbs' not in scr and not retried[0]:
            retried[0] = True
            v.type('\rRUN"BOOT 128",8\r')
        return False
    if not until(v, booted, 400):
        show(v, 'no idle screen'); return
    irq7 = sym('irq7')
    b = v.mem('ram00', CHKTBL, 1)[0]
    v.cmd('bank ram', '> %04x %02x' % (CHKTBL, b | 0x10), '> %04x 01' % (irq7 + 1))
    until(v, lambda: 'INSTANT LOGIN:' in v.screen(25).upper(), 120)
    for _ in range(3):
        time.sleep(2)
        v.type('I')
        if until(v, lambda: 'MAIN' in v.screen(25).upper() or 'PASSWORD' in v.screen(25).upper(), 40):
            break
    t0, seen = time.time(), None
    while time.time() - t0 < 300:
        time.sleep(3)
        scr = v.screen(25)
        rows = [r for r in scr.split('\n')[:16] if r.strip()]
        last = rows[-1].strip().upper() if rows else ''
        last2 = ' '.join(r.strip().upper() for r in rows[-2:])
        if 'MAIN:' in last:
            break
        if last2 == seen:
            continue
        seen = last2
        if 'PASSWORD' in last2:
            v.type('PW1\r')
        elif 'HIT ANY KEY' in last or 'MORE' in last:
            v.type(' ')
        elif 'LINES' in last2:
            v.type('23\r')
        elif 'ZONE' in scr.upper() or 'PACIFIC' in scr.upper():
            v.type('4\r')
        elif last.endswith('?') or last.endswith(':'):
            v.type('\r')
    show(v, 'logged on')


cmd = sys.argv[1]
if cmd == 'boot':
    boot(sys.argv[2])
elif cmd == 'type':
    v = attach()
    import re
    t = sys.argv[2].replace('\\r', '\r')
    t = re.sub(r'%([0-9a-fA-F]{2})', lambda m: chr(int(m.group(1), 16)), t)
    v.type(t)
    time.sleep(float(sys.argv[3]) if len(sys.argv) > 3 else 4)
    show(v, 'after ' + repr(sys.argv[2]))
elif cmd == 'update':
    # rewrite built modules on the attached disk without rebooting: detach
    # drive 8, write each build/<name>.prg as its disk name (_ for /), attach
    disk, prgs = sys.argv[2], sys.argv[3:]
    v = attach()
    v.cmd('detach 8')
    for f in prgs:
        n = os.path.basename(f)[:-4].replace('_', '/')
        subprocess.run(['c1541', disk, '-delete', n, '-write', f, n], capture_output=True)
        print('wrote', n)
    v.cmd('attach "%s" 8' % disk)
elif cmd == 'screen':
    show(attach(), 'now')
elif cmd == 'warp':
    attach().cmd('warp ' + sys.argv[2])
elif cmd == 'stop':
    # by its pid (a pkill -f pattern would match the shell that runs this)
    import signal
    try:
        os.kill(int(open(PIDFILE).read()), signal.SIGTERM)
    except (OSError, ValueError):
        pass
