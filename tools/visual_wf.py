#!/usr/bin/env python3
"""visual_wf.py: start ++ visual the way a caller does, to reproduce problems
with it in the whole BBS (the stand-in, tests/standin/visual.bas, runs it
alone).

    tools/visual_wf.py [DISK] [--overlay FILE.prg] [--password PW] [--zone N]
                       [--port N] [--keep]

On a copy of DISK (build/visual-test.d81 if not given; the copy is
build/visual-wf.d81, so DISK itself isn't changed) in an 80-column x128
(warp, JiffyDOS, the DS12C887 at $d700; no modem):
  1. boots to the idle screen;
  2. turns Loc on (flag 4: chktbl bit 4, and irq7 told to redraw) and
     presses I (Instant Login), giving the password (--password, PW1) and
     answering the logon's questions: a key for "Hit any key", the time
     zone (--zone, 4: Pacific), 23 lines, Return for the rest;
  3. EP, P, then 10 until the Parameters menu's Editor reads Visual;
  4. Return, then WF: sub.editor loads ++ visual and starts it (&,16).
It prints the screen after each step (80 columns, rows 0-24, blank rows
left out) and BASIC's line. With --overlay FILE.prg, that file goes on the
copy as "++ visual" first, and afterwards the overlay's memory is compared
with the file (what differs: its own variables, or something written over
it), and the registers and the stack are shown.

With --catch-brk, WF goes in through a monitor connection that stays open
with a breakpoint on where the BRK vector ($0316) points (the 128's monitor,
whose "break" and registers come out garbled through Image's output). If a
BRK comes within --wait seconds (60), it shows where: the 128's interrupt
entry pushes the MMU setting, Y, X and A on the BRK's status and return
address (the BRK + 2), so the stack names the BRK, and the code before it
is disassembled.

The x128's monitor is on --port (6538; not a running test's: see
tools/vmon.py). --keep leaves it running at the end, to look further
with the monitor; otherwise it quits.

Letters are typed as ASCII capitals, which the 128's keyboard buffer takes
as unshifted keys ($41-$5a); "i" would be $69, a graphics character.
"""
import argparse, os, re, shutil, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

JIFFY = os.environ.get('JIFFYDOS', os.path.expanduser('~/Documents/c64/JiffyDOS'))
CHKTBL = 0x1300     # chktbl: flag 4 (Loc) is bit 4 of its first byte


def sym(name):
    """an address from asm/ml.sym (asm/build.sh writes it)"""
    for l in open(os.path.join(repo, 'asm', 'ml.sym')):
        m = re.match(r'(\S+)\s*=\s*\$([0-9a-f]+)', l)
        if m and m.group(1) == name:
            return int(m.group(2), 16)
    sys.exit('visual_wf.py: no %s in asm/ml.sym: run asm/build.sh' % name)


def catch_brk(v, wait):
    """type WF with a breakpoint on the BRK vector's target, staying
    connected (a break with no client opens VICE's own monitor window)"""
    import socket
    vec = v.mem('ram00', 0x0316, 2)
    target = vec[0] | vec[1] << 8
    print('BRK vector ($0316): $%04x' % target, flush=True)
    s = socket.create_connection(('127.0.0.1', v.port), timeout=5)
    s.settimeout(0.05)
    X128._until_prompt(s, b'', 3)
    keys = 'WF\r'
    cmds = ['bank ram', 'f 034a 0353 00'] + ['> %04x %02x' % (0x34a + i, ord(c)) for i, c in enumerate(keys)] + \
           ['> 00d0 %02x' % len(keys), 'break exec %04x' % target]
    for c in cmds:
        s.sendall(c.encode() + b'\n')
        X128._until_prompt(s, b'', 3)
    s.sendall(b'x\n')
    out = X128._until_prompt(s, b'', wait).decode('latin-1')
    if ('%04x' % target) not in out.lower():
        print('no BRK in %d seconds' % wait, flush=True)
        s.sendall(b'del\n'); X128._until_prompt(s, b'', 3)
        s.sendall(b'x\n'); s.close()
        return
    print('*** BRK caught ***', flush=True)
    def ask(c, limit=5):
        s.sendall(c.encode() + b'\n')
        return X128._until_prompt(s, b'', limit).decode('latin-1')
    regs = ask('r')
    print(regs[-300:])
    m = re.search(r'\.;[0-9a-f]{4} [0-9a-f]{2} [0-9a-f]{2} [0-9a-f]{2} ([0-9a-f]{2})', regs)
    sp = int(m.group(1), 16) if m else 0xff
    st = ask('bank ram', 3) and ask('m %04x %04x' % (0x100 + sp + 1, 0x100 + sp + 16))
    print(st)
    b = re.findall(r'>C:[0-9a-f]{4}\s+((?:[0-9a-f]{2}\s+)+)', st)
    by = [int(x, 16) for line in b for x in line.split()][:16]
    if len(by) >= 7:
        mmu, ry, rx, ra, rp, pcl, pch = by[:7]
        brk = (pcl | pch << 8) - 2
        print('MMU $%02x  A $%02x X $%02x Y $%02x  P $%02x  BRK at $%04x' % (mmu, ra, rx, ry, rp, brk))
        print('return addresses further up the stack (lo, hi pairs):',
              ' '.join('%02x%02x' % (by[i + 1], by[i]) for i in range(7, len(by) - 1, 2)))
        print(ask('bank ram', 3) and ask('d %04x %04x' % (max(brk - 24, 0), brk + 6)))
    ask('del')
    s.close()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('disk', nargs='?', default=os.path.join(repo, 'build', 'visual-test.d81'))
    ap.add_argument('--overlay')
    ap.add_argument('--password', default='PW1')
    ap.add_argument('--zone', default='4')
    ap.add_argument('--port', type=int, default=6538)
    ap.add_argument('--keep', action='store_true')
    ap.add_argument('--catch-brk', action='store_true')
    ap.add_argument('--wait', type=int, default=60)
    args = ap.parse_args()
    disk = os.path.join(repo, 'build', 'visual-wf.d81')
    shutil.copy(args.disk, disk)
    if args.overlay:
        subprocess.run(['c1541', disk, '-delete', '++ visual', '-write', args.overlay, '++ visual'],
                       capture_output=True)
    irq7 = sym('irq7')   # "ldy #1" at irq7: its operand set means "redraw the lightbar"
    jiffy = []
    if os.path.exists(os.path.join(JIFFY, 'JDOS128.rom')):
        jiffy = ['-kernal', os.path.join(JIFFY, 'JDOS128.rom'),
                 '-dos1581', os.path.join(JIFFY, 'Jiffy1581.rom')]
    v = X128(['-ntsc', '-drive8type', '1581', *jiffy,
              '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
              '-warp', '-autostart', disk + ':boot 128'], cols=80, wait=2, port=args.port)

    def line():
        return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')

    def show(t, n=25):
        print('---', t, '(BASIC line %d)' % line(), flush=True)
        for i, r in enumerate(v.screen(25).split('\n')[:n]):
            if r.strip():
                print('%2d|%s' % (i, r))

    def until(cond, secs, what):
        t0 = time.time()
        while time.time() - t0 < secs:
            time.sleep(2)
            if cond():
                return True
        show('timed out: ' + what)
        return False

    def screen():
        return v.screen(25).upper()

    try:
        # x128's autostart sometimes stops at READY. with a stray line
        # typed: start the boot by hand then
        def booted():
            if 4200 <= line() < 4300:
                return True
            scr = v.screen(25).lower()
            if 'ready.' in scr and 'image bbs' not in scr and not booted.retried:
                booted.retried = True
                print('autostart stopped at READY.: RUN"BOOT 128" by hand', flush=True)
                v.type('\rRUN"BOOT 128",8\r')
            return False
        booted.retried = False
        if not until(booted, 400, 'the idle screen'):
            return 1
        b = v.mem('ram00', CHKTBL, 1)[0]
        v.cmd('bank ram', '> %04x %02x' % (CHKTBL, b | 0x10), '> %04x 01' % (irq7 + 1))
        # I once the prompt is up (typed before it, it's lost), again if need be
        until(lambda: 'INSTANT LOGIN:' in screen(), 120, 'the Instant Login prompt')
        for _ in range(3):
            time.sleep(2)
            v.type('I')
            if until(lambda: 'MAIN' in screen() or 'PASSWORD' in screen(), 40, 'the password or main prompt'):
                break
        show('Instant Login', 12)
        # the logon's questions, until the main prompt
        t0, seen = time.time(), None
        while time.time() - t0 < 300:
            time.sleep(3)
            scr = v.screen(25)
            rows = [r for r in scr.split('\n')[:16] if r.strip()]
            last = rows[-1].strip().upper() if rows else ''
            # the question can be on the row above its input (": ")
            last2 = ' '.join(r.strip().upper() for r in rows[-2:])
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
            elif 'ZONE' in scr.upper() or 'PACIFIC' in scr.upper():
                v.type(args.zone + '\r')
            elif last.endswith('?') or last.endswith(':'):
                v.type('\r')
        show('the main prompt', 16)
        v.type('EP\r'); time.sleep(12)
        v.type('P')
        if not until(lambda: 'EDITOR' in screen(), 60, 'the Parameters menu'):
            return 1

        def editor():
            for r in v.screen(25).split('\n'):
                if 'EDITOR' in r.upper():
                    return r.strip()
            return ''
        for _ in range(3):
            e = editor()
            print('menu:', e, flush=True)
            if 'VISUAL' in e.upper():
                break
            v.type('10\r'); time.sleep(8)
        else:
            show('Editor never read Visual')
            return 1
        v.type('\r'); time.sleep(8)
        until(lambda: 'MAIN:' in screen(), 60, 'the main prompt again')
        show('Editor: Visual', 16)
        if args.catch_brk:
            catch_brk(v, args.wait)
        else:
            v.type('WF\r')
            time.sleep(25)
        show('after WF')
        if args.overlay:
            prg = open(args.overlay, 'rb').read()
            la, body = prg[0] | prg[1] << 8, prg[2:]
            mem = v.mem('ram00', la, len(body))
            diffs = [i for i in range(len(body)) if mem[i] != body[i]]
            print('overlay $%04x-$%04x: %d bytes differ from %s' % (
                la, la + len(body) - 1, len(diffs), os.path.basename(args.overlay)))
            runs = []
            for i in diffs:
                if runs and i == runs[-1][1] + 1:
                    runs[-1][1] = i
                else:
                    runs.append([i, i])
            for a, b in runs[:20]:
                print('  $%04x-$%04x now %s, was %s' % (la + a, la + b, mem[a:b + 1][:16].hex(),
                                                       body[a:b + 1][:16].hex()))
            print(v.cmd('r', 'bank ram', 'm 0100 01ff', resume=True)[-1400:])
        return 0
    finally:
        if args.keep:
            print('x128 left running: its monitor is on port %d' % args.port)
        else:
            v.cmd('quit', resume=False)


if __name__ == '__main__':
    sys.exit(main())
