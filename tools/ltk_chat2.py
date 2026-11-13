#!/usr/bin/env python3
"""ltk_chat2.py: ++ chatmode between two stations of VICE's Lt. Kernal.

    tools/standin.sh tests/standin/chat2.bas
    c1541 build/standin-chat2.d81 -write asm/chatmode.prg "++ chatmode"
    tools/ltk_chat2.py [--fresh] [--keep]

Two x128s, the Lt. Kernal's ports 0 and 1 (-ltkport), on the same drive
images (build/ltk/, copied from LTK DIR as tools/ltk_chatmode.py does):
VICE reads and writes the image file a block at a time and flushes each
write, so each sees the other's blocks, as stations on a multiplexer do.
LTK DIR's CONFIG has "cpu mode" 00 (C128) for ports 00 and 01. Each runs
tests/standin/chat2.bas from its own copy of the disk (device 9).

alice (port 0) comes in first, then bob; alice sends a line, bob answers;
at bob's station the sysop turns Cht on (flag_cht, $1301 bit 0), sends a
line and turns it off; alice leaves (/x), then bob. Each line must show at
the other station, and the transcript (shown by each after leaving) must
have them all. Prints the two screens and "passed" or what was missing.
"""
import os, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk')
disk = os.path.join(repo, 'build', 'standin-chat2.d81')
CHT = 0x1301		# flag_cht_addr (chktbl + 1), bit 0: Cht

if '--fresh' in sys.argv or not os.path.exists(os.path.join(work, 'disk0.dlk')):
    os.makedirs(work, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(LTK, f), work)

def station(port, mon):
    d = os.path.join(repo, 'build', f'standin-chat2-{port}.d81')
    shutil.copy(disk, d)
    return X128(['-cartcrt', os.path.join(LTK, 'ltk.crt'), '-ltkport', str(port),
                 '-ltkimage0', os.path.join(work, 'disk0.dlk'),
                 '-ltkimage1', os.path.join(work, 'disk1.dlk'),
                 '-ltkimage2', os.path.join(work, 'disk2.dlk'),
                 '-drive8type', '0', '-drive9type', '1581', '-9', d],
                cols=40, wait=4, port=mon)

def waitfor(v, text, limit=180, every=3):
    t0 = time.time()
    s = ''
    while time.time() - t0 < limit:
        s = v.screen()
        if text in s.lower():
            return True, s
        time.sleep(every)
    return False, s

missing = []
def expect(v, name, text, limit=60):
    ok, s = waitfor(v, text, limit)
    if not ok:
        missing.append(f'{name}: {text!r}')
    return ok

def boot(v):
    ok, s = waitfor(v, 'c128 d#08', 120)
    if not ok:
        sys.exit("the Lt. Kernal didn't come up in 128 mode:\n" + s)
    v.type('RUN"BOOT 128",U9\r')
    return waitfor(v, 'chat room. /x', 300)[0]

a = station(0, int(os.environ.get('VMON_PORT', '6602')))
b = None
try:
    if not boot(a):
        sys.exit('alice never reached the chat room:\n' + a.screen())
    b = station(1, int(os.environ.get('VMON_PORT', '6602')) + 2)
    if not boot(b):
        sys.exit('bob never reached the chat room:\n' + b.screen())
    expect(b, 'bob', 'here: alice')
    expect(a, 'alice', '* bob joined')
    a.type('HELLO BOB\r')
    expect(b, 'bob', 'alice: hello bob')
    b.type('HI ALICE\r')
    expect(a, 'alice', 'bob: hi alice')
    b.cmd('bank ram00', f'> {CHT:04x} 01')	# Cht on at bob's station
    time.sleep(3)
    b.type('SYSOP HERE\r')
    expect(a, 'alice', '* sysop joined')
    expect(a, 'alice', 'sysop: sysop here')
    b.cmd('bank ram00', f'> {CHT:04x} 00')
    expect(a, 'alice', '* sysop left')
    a.type('/X\r')
    expect(b, 'bob', '* alice left')
    expect(a, 'alice', 'done')
    b.type('/X\r')
    expect(b, 'bob', 'done')
    for name, v in (('alice', a), ('bob', b)):
        s = v.screen()
        print(f'===== {name}'); print(s)
        for t in ('alice: hello bob', 'bob: hi alice', 'sysop: sysop here'):
            if t not in s.lower():
                missing.append(f'{name} transcript: {t!r}')
    print('passed' if not missing else 'missing: ' + '; '.join(missing))
    sys.exit(0 if not missing else 1)
finally:
    if '--keep' not in sys.argv:
        a.stop()
        if b:
            b.stop()
