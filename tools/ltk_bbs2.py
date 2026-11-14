#!/usr/bin/env python3
"""ltk_bbs2.py: two stations of a multiplexed Lt. Kernal running the whole
Image BBS 128, chatting through ++ chatmode (the ECS command LTK, which
runs modules/i.ltk chat).

    asm/build.sh
    tools/standin.sh tests/standin/ltkinstall.bas
    tools/ltk_install.py --fresh
    tools/setup_test.py --ltk 5 --out build/ltk-setup.d81
    cp build/ltk/disk*.dlk build/ltk-configured/   (to run again without setup)
    tools/ltk_bbs2.py [--from DIR] [--keep] [--port N] [--user2 ID:PW:FIRST:LAST:EMAIL:HANDLE]

    tools/ltk_bbs2.py --from build/ltk-2users --user2 '2:TEST1:TEST:ACCOUNT:TEST@EXAMPLE.COM:TEST ACCOUNT'

--user2: station 1 logs on as that account through the normal logon
(Return, Return, the ID, the password; FIRST, LAST and EMAIL answer the
logon's "Additional Information" check; HANDLE as the chat shows it), and
the chat's lines are checked
with each station's handle: the sysop's at station 0 ("image sysop: ..."),
the other's at station 1. build/ltk-2users has TEST ACCOUNT (ID 2,
password TEST1), made 11/14/2026 through the new-user application (NEW at
the handle prompt) on build/ltk-configured.

Passed 11/14/2026 (about 5 minutes). VICE keeps the Lt. Kernal's drive
images with every byte inverted (XOR $ff): search them for a file's bytes
that way. To replace one file on a configured system, put the configured
images in build/ltk-installed/ and run tools/ltk_install.py --base installed
--source DISK --no-keep (DISK holding just that file); build/ltk/ then has it.

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
  0. station 1 types LTK first: station 0 must be listed online already
     (logged on is online: i.lo 3118), and not in the room;
  1. station 0 sends a line; station 1 must show it, and the reverse;
  2. at station 1 the sysop turns Cht on ($1301 bit 0): the sysop joins
     and sends a line, which station 0 must show; Cht off: the sysop leaves;
  3. both leave (/x), T shows the transcript at each, which must have all
     three lines; Q back to the main prompt;
  4. station 0 logs off (O!, the logoff's questions answered with their
     defaults) to the idle screen, and station 1's W must say "Nobody
     else." (i.lo 3230 marks it offline).
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
user2 = None
if '--user2' in args:
    user2 = args[args.index('--user2') + 1].split(':')
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

    def logon(self, user=None):
        """Instant Login (the sysop), or user (ID, password, first name,
        last name, email) through the normal logon"""
        v = self.v
        b = v.mem('ram00', CHKTBL, 1)[0]
        v.cmd('bank ram', '> %04x %02x' % (CHKTBL, b | 0x10), '> %04x 01' % (IRQ7 + 1))
        if not self.until(lambda: 'INSTANT LOGIN:' in self.screen().upper(), 120, 'Instant Login'):
            return False
        s = lambda: self.screen().upper()
        if user:
            uid, pw, first, last, email = user[:5]
            time.sleep(2)
            v.type('\r')
            if not self.until(lambda: 'LOGIN:' in s().split('INSTANT LOGIN')[-1], 60, 'the Login Options menu'):
                return False
            v.type('\r')
            if not self.until(lambda: 'LOGIN ID#' in s(), 60, 'the handle or ID prompt'):
                return False
            v.type(uid + '\r')
            if not self.until(lambda: 'PASSWORD' in s(), 60, 'the password prompt'):
                return False
            v.type(pw + '\r')
            # the "Additional Information" check: one of these three
            if self.until(lambda: 'ADDITIONAL' in s() or 'SUCCESSFUL' in s(), 30, 'the check question'):
                if 'ADDITIONAL' in s():
                    time.sleep(2)
                    q = s().split('ADDITIONAL')[-1]
                    v.type((first if 'FIRST' in q else last if 'LAST' in q else email) + '\r')
        else:
            for _ in range(3):
                time.sleep(2)
                v.type('I')
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
                v.type((user[1] if user else 'PW1') + '\r')
            elif 'KEY' in last or 'MORE' in last:     # HIT ANY KEY, (PRESS A KEY)
                v.type(' ')
            elif 'LINES' in last2:
                v.type('23\r')
            elif 'ZONE' in scr.upper() or 'PACIFIC' in scr.upper():
                v.type('4\r')
            elif last.endswith('?') or last.endswith(':'):
                v.type('\r')
        self.show('never reached the main prompt')
        return False

    def ltk(self):
        """LTK at the main prompt, to i.ltk chat's menu"""
        self.v.type('LTK\r')
        if not self.wait_text("you're at station %d" % self.n, 120):
            return False
        if not self.wait_text('c)hat, t)ranscript', 60):
            return False
        self.show('i.ltk chat')
        return True

    def chat(self):
        """C at the menu, into the chat room"""
        self.v.type('C')
        return self.wait_text('chat room. /x', 60)

    def enter_chat(self):
        return self.ltk() and self.chat()

    def logoff(self):
        """O! at the main prompt, D at the logoff menu, the rest answered,
        until the idle screen"""
        self.v.type('O!\r')
        t, seen = time.time(), None
        while time.time() - t < 240:
            time.sleep(3)
            if 4200 <= self.line() < 4300:
                log('station %d: logged off, idle screen' % self.n)
                return True
            rows = [r for r in self.screen().split('\n')[:16] if r.strip()]
            last = rows[-1].strip().upper() if rows else ''
            if last == seen:
                continue
            seen = last
            log('station %d logoff: %s' % (self.n, last[-70:]))
            if last.startswith('CMD:'):
                self.v.type('D')
            elif 'KEY' in last or 'MORE' in last:
                self.v.type(' ')
            elif '?' in last or last.endswith(':'):
                # Return takes the default (shown as ".Yes." or ".No.")
                self.v.type('\r')
        self.show('never got back to idle')
        return False


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
    if not (a.logon() and b.logon(user2)):
        sys.exit('a station never reached the main prompt')
    # the handles as the lines show them (lowercased); with one account
    # both are the sysop's, so only the text tells the lines apart
    h0 = 'image sysop: ' if user2 else ''
    h1 = user2[5].lower() if user2 else ''
    # logged on is online: station 1 sees station 0 before it types LTK
    if not b.ltk():
        sys.exit("station 1 never reached LTK's menu")
    h0n = 'port 00: ' + ('image sysop' if user2 else '')
    row = [r.lower() for r in b.screen().split('\n') if 'port 00:' in r.lower()]
    ok = bool(row) and h0n in row[0] and '(chat room)' not in row[0]
    log('station 1 %s station 0 online, not in the room: %r' % ('lists' if ok else 'MISSING', row))
    if not ok:
        missing.append('station 1: station 0 online at logon')
    if not a.enter_chat():
        sys.exit("station 0 never reached the chat room")
    if not b.chat():
        sys.exit("station 1 never reached the chat room")
    a.show('in the chat room'); b.show('in the chat room')
    expect(a, '* %s joined' % h1 if user2 else 'joined')
    a.v.type('HELLO FROM ZERO\r')
    expect(b, h0 + 'hello from zero')
    b.v.type('HI FROM ONE\r')
    expect(a, (h1 + ': ' if user2 else '') + 'hi from one')
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
        for t in (h0 + 'hello from zero', (h1 + ': ' if user2 else '') + 'hi from one',
                  ('sysop: ' if user2 else '') + 'sysop at one'):
            if not st.sees(t):
                missing.append('station %d transcript: %r' % (st.n, t))
        st.until(lambda: st.sees('c)hat, t)ranscript'), 60, 'the menu after T')
        st.v.type('Q')
        expect(st, 'main:')
    # quitting LTK keeps a station online; logging off takes it off
    b.v.type('LTK\r')
    expect(b, 'port 00:')
    b.until(lambda: b.sees('c)hat, t)ranscript'), 60, 'the menu')
    if not a.logoff():
        missing.append('station 0: logoff')
    b.v.type('W')
    time.sleep(10)
    b.show('W after station 0 logged off')
    tail = b.screen().lower().split('online:')[-1]
    if 'nobody else' not in tail or 'port 00:' in tail:
        missing.append('station 1: station 0 still online after its logoff')
    else:
        log('station 1 shows nobody else online')
    b.v.type('Q')
    expect(b, 'main:')
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
