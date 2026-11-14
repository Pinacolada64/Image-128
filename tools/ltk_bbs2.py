#!/usr/bin/env python3
"""ltk_bbs2.py: two stations of a multiplexed Lt. Kernal running the whole
Image BBS 128, chatting through ++ chatmode (the ECS command LTK, which
runs modules/i.ltk chat).

    asm/build.sh
    tools/standin.sh tests/standin/ltkinstall.bas
    tools/ltk_install.py --fresh
    tools/setup_test.py --ltk 5 --out build/ltk-setup.d81
    tools/ltk_bbs2.py [--from DIR] [--keep] [--port N]

The drive images are the Lt. Kernal's as setup_test.py --ltk left them
(build/ltk/, or --from DIR): Image on LU 5, its System and Etcetera drives
on LU 6. They're copied to build/ltk-bbs2/ and both x128s use that copy,
on the Lt. Kernal's ports 0 and 1 (-ltkport): VICE reads and writes the
image files a block at a time, so each station sees the other's writes, as
on a multiplexer (tools/ltk_chat2.py). CONFIG has "cpu mode" 00 (C128) for
both ports.

Each station: LU 5, LOAD"BOOT 128",8 and RUN at the Lt. Kernal's prompt;
im boots to the idle screen; Loc on and I (Instant Login, the sysop, ID 1,
password pw1), the logon's questions answered; then LTK at the main prompt
and C (Chat). Both stations are the sysop's account, so the lines are
told apart by their text, not the handle. Then:
  1. station 0 sends a line; station 1 must show it, and the reverse;
  2. at station 1 the sysop turns Cht on ($1301 bit 0): the sysop joins
     and sends a line, which station 0 must show; Cht off: the sysop leaves;
  3. both leave (/x), T shows the transcript at each, which must have all
     three lines; Q back to the main prompt.
Prints each step and both screens at the end, then "passed" or what was
missing. Monitors on --port (6612) and --port + 2; --keep leaves both
running.
"""
import os, re, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
JIFFY = os.environ.get('JIFFYDOS', os.path.expanduser('~/Documents/c64/JiffyDOS'))
CHKTBL = 0x1300     # chktbl: Loc is bit 4 of its first byte
CHT = 0x1301        # flag_cht_addr (chktbl + 1), bit 0: Cht

args = sys.argv[1:]
keep = '--keep' in args
src = os.path.join(repo, 'build', 'ltk')
if '--from' in args:
    src = args[args.index('--from') + 1]
port = 6612
if '--port' in args:
    port = int(args[args.index('--port') + 1])
work = os.path.join(repo, 'build', 'ltk-bbs2')
os.makedirs(work, exist_ok=True)
for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
    shutil.copyfile(os.path.join(src, f), os.path.join(work, f))


def sym(name):
    """an address from asm/ml.sym (asm/build.sh writes it)"""
    for l in open(os.path.join(repo, 'asm', 'ml.sym')):
        m = re.match(r'(\S+)\s*=\s*\$([0-9a-f]+)', l)
        if m and m.group(1) == name:
            return int(m.group(2), 16)
    sys.exit('ltk_bbs2.py: no %s in asm/ml.sym: run asm/build.sh' % name)


IRQ7 = sym('irq7')  # "ldy #1" at irq7: its operand set means "redraw the lightbar"
t0 = time.time()


def log(*a):
    print('%6.1f' % (time.time() - t0), *a, flush=True)


class Station:
    def __init__(self, n):
        self.n = n
        self.v = X128(['+saveres', '-cartcrt', os.path.join(LTK, 'ltk.crt'), '-ltkport', str(n),
                       '-ltkimage0', os.path.join(work, 'disk0.dlk'),
                       '-ltkimage1', os.path.join(work, 'disk1.dlk'),
                       '-ltkimage2', os.path.join(work, 'disk2.dlk'),
                       '-drive8type', '0',
                       '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
                       '-warp'], cols=80, wait=4, port=port + 2 * n)

    def screen(self):
        return self.v.screen(25)

    def line(self):
        return int.from_bytes(self.v.mem('ram00', 0x3b, 2), 'little')

    def show(self, what):
        print('--- station %d: %s (BASIC line %d)' % (self.n, what, self.line()), flush=True)
        for i, r in enumerate(self.screen().split('\n')):
            if r.strip():
                print('%2d|%s' % (i, r))

    def until(self, cond, secs, what, every=2):
        t = time.time()
        while time.time() - t < secs:
            if cond():
                return True
            time.sleep(every)
        self.show('timed out: ' + what)
        return False

    def sees(self, text):
        return text.lower() in self.screen().lower()

    def wait_text(self, text, secs=90):
        return self.until(lambda: self.sees(text), secs, repr(text))

    def boot(self):
        if not self.wait_text('c128 d#08', 120):
            return False
        self.v.type('LU 5\r'); time.sleep(3)
        self.v.type('LOAD"BOOT 128",8\r'); time.sleep(8)
        self.v.type('RUN\r')
        if not self.until(lambda: 4200 <= self.line() < 4300, 600, 'the idle screen', every=4):
            return False
        log('station %d: idle screen' % self.n)
        return True

    def logon(self):
        v = self.v
        b = v.mem('ram00', CHKTBL, 1)[0]
        v.cmd('bank ram', '> %04x %02x' % (CHKTBL, b | 0x10), '> %04x 01' % (IRQ7 + 1))
        if not self.until(lambda: 'INSTANT LOGIN:' in self.screen().upper(), 120, 'Instant Login'):
            return False
        for _ in range(3):
            time.sleep(2)
            v.type('I')
            s = lambda: self.screen().upper()
            if self.until(lambda: 'MAIN' in s() or 'PASSWORD' in s(), 40, 'the password'):
                break
        t, seen = time.time(), None
        while time.time() - t < 300:
            time.sleep(3)
            scr = self.screen()
            rows = [r for r in scr.split('\n')[:16] if r.strip()]
            last = rows[-1].strip().upper() if rows else ''
            last2 = ' '.join(r.strip().upper() for r in rows[-2:])
            if 'MAIN:' in last:
                log('station %d: main prompt' % self.n)
                return True
            if last2 == seen:
                continue
            seen = last2
            log('station %d logon: %s' % (self.n, last2[-70:]))
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
        self.show('never reached the main prompt')
        return False

    def enter_chat(self):
        self.v.type('LTK\r')
        if not self.wait_text("you're at station %d" % self.n, 120):
            return False
        if not self.wait_text('c)hat, t)ranscript', 60):
            return False
        self.show('i.ltk chat')
        self.v.type('C')
        return self.wait_text('chat room. /x', 60)


missing = []


def expect(st, text, secs=60):
    ok = st.until(lambda: st.sees(text), secs, repr(text))
    log('station %d %s %r' % (st.n, 'shows' if ok else 'MISSING', text))
    if not ok:
        missing.append('station %d: %r' % (st.n, text))
    return ok


a = b = None
try:
    a = Station(0)
    b = Station(1)
    if not (a.boot() and b.boot()):
        sys.exit('a station never reached the idle screen')
    if not (a.logon() and b.logon()):
        sys.exit('a station never reached the main prompt')
    if not a.enter_chat():
        sys.exit("station 0 never reached the chat room")
    if not b.enter_chat():
        sys.exit("station 1 never reached the chat room")
    a.show('in the chat room'); b.show('in the chat room')
    expect(a, 'joined')
    a.v.type('HELLO FROM ZERO\r')
    expect(b, 'hello from zero')
    b.v.type('HI FROM ONE\r')
    expect(a, 'hi from one')
    b.v.cmd('bank ram00', '> %04x 01' % CHT)    # Cht on at station 1
    time.sleep(4)
    b.v.type('SYSOP AT ONE\r')
    expect(a, 'sysop at one')
    b.v.cmd('bank ram00', '> %04x 00' % CHT)
    time.sleep(4)
    a.show('after the sysop'); b.show('after the sysop')
    for st in (a, b):
        st.v.type('/X\r')
        expect(st, 'c)hat, t)ranscript')
    for st in (a, b):
        st.v.type('T')
        time.sleep(8)
        st.show('the transcript')
        for t in ('hello from zero', 'hi from one', 'sysop at one'):
            if not st.sees(t):
                missing.append('station %d transcript: %r' % (st.n, t))
        st.until(lambda: st.sees('c)hat, t)ranscript'), 60, 'the menu after T')
        st.v.type('Q')
        expect(st, 'main:')
    a.show('the end'); b.show('the end')
    print('passed' if not missing else 'missing: ' + '; '.join(missing))
    sys.exit(0 if not missing else 1)
finally:
    if keep:
        print('left running: monitors on ports %d and %d' % (port, port + 2))
    else:
        for st in (a, b):
            if st:
                st.v.stop()
