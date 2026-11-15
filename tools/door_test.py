#!/usr/bin/env python3
"""door_test.py: play the doors (tests/doors, plain BASIC 7.0 programs) in
the whole BBS, as a caller does: DOOR at the main prompt runs i.remote door,
which runs them through ++ remote.

    tools/door_test.py [DISK] [--password PW] [--zone N] [--port N] [--keep]

DISK is a configured system (build/visual-test.d81 if not given), which
isn't changed: its copy, build/door-test.d81, gets every file of
build/image128.d81 but its REL files (so asm/build.sh's programs and
overlays, and its e.ecs.main with DOOR), and the doors, tests/doors/<name>.bas
as the PRG files door.<name> (petcat, at $1c01). Then, in an 80-column x128
(warp, JiffyDOS, the DS12C887 at $d700; no modem), it boots to the idle
screen, logs in at the console (Loc on, I, the password: as
tools/visual_wf.py), and at the main prompt:
  1. DOOR, then $: the list should have door.guess and door.oops;
  2. GUESS: plays Guess the Number, guessing by halves from Higher!/Lower!
     (INPUT), then N to "Play again" (GETKEY); "Back from the door." after;
  3. OOPS: ?division by zero in 20, and "error 20 in line 20" after;
  4. NOSUCH: "There's no door named nosuch.";
  5. Return: back at the main prompt.
Prints pass or fail for each and the screen when one fails, then
"all passed". The monitor is on --port (6541); --keep leaves x128 running.
"""
import argparse, os, re, shutil, subprocess, sys, tempfile, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

JIFFY = os.environ.get('JIFFYDOS', os.path.expanduser('~/Documents/c64/JiffyDOS'))
CHKTBL = 0x1300     # chktbl: flag 4 (Loc) is bit 4 of its first byte


def sym(name):
    for l in open(os.path.join(repo, 'asm', 'ml.sym')):
        m = re.match(r'(\S+)\s*=\s*\$([0-9a-f]+)', l)
        if m and m.group(1) == name:
            return int(m.group(2), 16)
    sys.exit('door_test.py: no %s in asm/ml.sym: run asm/build.sh' % name)


def make_disk(src, disk):
    """src's copy with build/image128.d81's files (but REL) and the doors"""
    shutil.copy(src, disk)
    built = os.path.join(repo, 'build', 'image128.d81')
    listing = subprocess.run(['c1541', built, '-list'], capture_output=True, text=True).stdout
    files = re.findall(r'^\d+\s+"([^"]+)"\s+(prg|seq|usr)', listing, re.M)
    tmp = tempfile.mkdtemp(dir=os.path.join(repo, 'build'))
    reads, writes = [], []
    for i, (name, typ) in enumerate(files):
        f = os.path.join(tmp, str(i))
        sfx = '' if typ == 'prg' else ',' + typ[0]
        reads += ['-read', name + sfx, f]
        writes += ['-delete', name, '-write', f, name + sfx]
    for b in sorted(os.listdir(os.path.join(repo, 'tests', 'doors'))):
        if b.endswith('.bas'):
            f = os.path.join(tmp, b + '.prg')
            subprocess.run(['petcat', '-w70', '-l', '1c01', '-o', f, '--',
                            os.path.join(repo, 'tests', 'doors', b)], check=True)
            writes += ['-delete', 'door.' + b[:-4], '-write', f, 'door.' + b[:-4]]
    subprocess.run(['c1541', built, *reads], capture_output=True)
    subprocess.run(['c1541', disk, *writes], capture_output=True)
    shutil.rmtree(tmp)
    print('%s: %d files from image128.d81, and the doors' % (os.path.basename(disk), len(files)),
          flush=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('disk', nargs='?', default=os.path.join(repo, 'build', 'visual-test.d81'))
    ap.add_argument('--password', default='PW1')
    ap.add_argument('--zone', default='4')
    ap.add_argument('--port', type=int, default=6541)
    ap.add_argument('--keep', action='store_true')
    args = ap.parse_args()
    disk = os.path.join(repo, 'build', 'door-test.d81')
    make_disk(args.disk, disk)
    irq7 = sym('irq7')
    jiffy = []
    if os.path.exists(os.path.join(JIFFY, 'JDOS128.rom')):
        jiffy = ['-kernal', os.path.join(JIFFY, 'JDOS128.rom'),
                 '-dos1581', os.path.join(JIFFY, 'Jiffy1581.rom')]
    v = X128(['-ntsc', '-drive8type', '1581', *jiffy,
              '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
              '-warp', '-autostart', disk + ':boot 128'], cols=80, wait=2, port=args.port)
    fails = []

    def line():
        return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')

    def rows():
        return [r for r in v.screen(25).split('\n')]

    def show(t):
        print('---', t, '(BASIC line %d)' % line(), flush=True)
        for i, r in enumerate(rows()):
            if r.strip():
                print('%2d|%s' % (i, r))

    def screen():
        return v.screen(25).upper()

    def until(cond, secs, what, quiet=False):
        t0 = time.time()
        while time.time() - t0 < secs:
            time.sleep(1.5)
            if cond():
                return True
        if not quiet:
            show('timed out: ' + what)
        return False

    def last_rows(n=3):
        # the console's rows: 0-23, or 0-15 while the screen mask (the
        # sysop's status area, rows 16-23) is up
        rr = rows()
        top = 16 if rr[16].strip().upper().startswith('SYS.') else 24
        rs = [r.strip().upper() for r in rr[:top] if r.strip()]
        return rs[-n:]

    def check(name, ok):
        print(('pass ' if ok else 'fail ') + name, flush=True)
        if not ok:
            fails.append(name)
            show('after ' + name)

    def door_prompt():
        return any(r.startswith('DOOR (') for r in last_rows(1))

    try:
        def booted():
            # the idle loop (4200s), not AutoMaint passing through them
            if 4200 <= line() < 4300 and 'AREA SYSTEM IDLE' in screen():
                return True
            scr = v.screen(25).lower()
            if 'ready.' in scr and 'image bbs' not in scr and not booted.retried:
                booted.retried = True
                v.type('\rRUN"BOOT 128",8\r')
            return False
        booted.retried = False
        if not until(booted, 1200, "the idle screen"):   # AutoMaint can run first
            return 1
        b = v.mem('ram00', CHKTBL, 1)[0]
        v.cmd('bank ram', '> %04x %02x' % (CHKTBL, b | 0x10), '> %04x 01' % (irq7 + 1))
        until(lambda: 'INSTANT LOGIN:' in screen(), 120, 'the Instant Login prompt')
        for _ in range(3):
            time.sleep(2)
            v.type('I')
            if until(lambda: 'MAIN' in screen() or 'PASSWORD' in screen(), 40, 'the password'):
                break
        t0, seen = time.time(), None
        while time.time() - t0 < 300:
            time.sleep(3)
            rs = [r for r in v.screen(25).split('\n')[:16] if r.strip()]
            last = rs[-1].strip().upper() if rs else ''
            last2 = ' '.join(r.strip().upper() for r in rs[-2:])
            if 'MAIN:' in last:
                break
            if last2 == seen:
                continue
            seen = last2
            print('logon:', last2, flush=True)
            if 'PASSWORD' in last2:
                v.type(args.password + '\r')
            elif 'HIT ANY KEY' in last or 'MORE' in last:
                v.type(' ')
            elif 'LINES' in last2:
                v.type('23\r')
            elif 'ZONE' in v.screen(25).upper() or 'PACIFIC' in v.screen(25).upper():
                v.type(args.zone + '\r')
            elif last.endswith('?') or last.endswith(':'):
                v.type('\r')
        else:
            show('no main prompt')
            return 1

        # 1. DOOR, then $
        v.type('DOOR\r')
        check('DOOR runs i.remote door', until(door_prompt, 60, 'the Door prompt'))
        v.type('$\r')
        until(lambda: door_prompt() and 'BLOCKS' in screen(), 60, 'the list')
        scr = screen()
        check('$ lists door.guess and door.oops', 'DOOR.GUESS' in scr and 'DOOR.OOPS' in scr)

        # 2. GUESS
        v.type('GUESS\r')
        ok = until(lambda: any('YOUR GUESS' in r for r in last_rows(1)), 60, 'the first guess')
        check('door.guess starts', ok)
        lo, hi, tries, result = 1, 100, 0, None
        while ok and tries < 10:
            g = (lo + hi) // 2
            tries += 1
            v.type('%d\r' % g)
            # the reply: a new prompt under Higher!/Lower!, or "Got it"
            def replied():
                r = last_rows(3)
                return any('GOT IT' in x for x in r) or \
                    ('YOUR GUESS' in r[-1] and r[-1].endswith('?') and
                     any(x in r[-2] for x in ('HIGHER', 'LOWER')) and r[-3].endswith(' %d' % g))
            if not until(replied, 60, 'the reply to %d' % g):
                break
            r = last_rows(3)
            print('  guessed %d: %s' % (g, ' / '.join(x for x in r[-2:])), flush=True)
            if any('GOT IT' in x for x in r):
                result = g
                break
            if 'HIGHER' in r[-2]:
                lo = g + 1
            else:
                hi = g - 1
        check('guessed it (%s) in %d tries' % (result, tries), result is not None)
        until(lambda: 'PLAY AGAIN' in last_rows(1)[0], 30, 'Play again')
        v.type('N')
        until(door_prompt, 60, 'the Door prompt after guess')
        scr = '\n'.join(last_rows(5))
        check('GETKEY took N; "Back from the door."', 'BYE!' in scr and 'BACK FROM THE DOOR.' in scr)

        # 3. OOPS
        v.type('OOPS\r')
        until(lambda: door_prompt() and 'OOPS' not in last_rows(1)[0], 60, 'the Door prompt after oops')
        scr = '\n'.join(last_rows(6))
        check('door.oops: ?division by zero, error 20 in line 20',
              'DIVISION BY ZERO' in scr and 'ERROR 20 IN LINE 20.' in scr)

        # 4. NOSUCH
        v.type('NOSUCH\r')
        until(lambda: door_prompt() and 'NOSUCH' not in last_rows(1)[0], 60, 'the Door prompt after nosuch')
        check('a missing door', "NO DOOR NAMED NOSUCH" in '\n'.join(last_rows(3)))

        # 5. back to the main prompt
        v.type('\r')
        check('Return: the main prompt', until(lambda: 'MAIN:' in last_rows(1)[0], 60, 'the main prompt'))
        show('the end')
        print('all passed' if not fails else '%d failed: %s' % (len(fails), ', '.join(fails)))
        return 1 if fails else 0
    finally:
        if args.keep:
            print('x128 left running: its monitor is on port %d' % args.port)
        else:
            v.cmd('quit', resume=False)


if __name__ == '__main__':
    sys.exit(main())
