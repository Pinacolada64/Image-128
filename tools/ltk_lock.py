#!/usr/bin/env python3
"""ltk_lock.py: &,13's locks between two stations of VICE's Lt. Kernal.

    asm/build.sh ml
    tools/standin.sh tests/standin/lock.bas
    tools/ltk_lock.py [--fresh] [--keep]

Two x128s, the Lt. Kernal's ports 0 (a) and 1 (b), on the same drive
images (build/ltk/, as tools/ltk_chat2.py), each running
tests/standin/lock.bas from its own copy of the disk (device 9). The
program waits at each step for a byte this pokes into $0b00; it gets the
address of ltkflag (from asm/ml.sym) in $0b02/$0b03.

a takes lock 3 twice; b must wait, with a reverse L on its status line;
a gives it back once: b still waits; again: b gets it. a takes lock 5 and
its x128 is stopped (a crash); b waits for 5; a boots again (its lockinit
frees a's locks) and b gets it. Prints "passed" or what went wrong.
"""
import os, re, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk')
disk = os.path.join(repo, 'build', 'standin-lock.d81')
MON = int(os.environ.get('VMON_PORT', '6602'))
STATUS_L = 0x0400 + 960 + 31	# tdisp+31: the reverse L while waiting

sym = open(os.path.join(repo, 'asm', 'ml.sym')).read()
LTKFLAG = int(re.search(r'^ltkflag\s*=\s*\$([0-9a-f]+)', sym, re.M).group(1), 16)

if '--fresh' in sys.argv or not os.path.exists(os.path.join(work, 'disk0.dlk')):
    os.makedirs(work, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(LTK, f), work)

def station(port):
    d = os.path.join(repo, 'build', f'standin-lock-{port}.d81')
    if not os.path.exists(d):
        shutil.copy(disk, d)
    return X128(['-cartcrt', os.path.join(LTK, 'ltk.crt'), '-ltkport', str(port),
                 '-ltkimage0', os.path.join(work, 'disk0.dlk'),
                 '-ltkimage1', os.path.join(work, 'disk1.dlk'),
                 '-ltkimage2', os.path.join(work, 'disk2.dlk'),
                 '-drive8type', '0', '-drive9type', '1581', '-9', d],
                cols=40, wait=4, port=MON + 2 * port)

def waitfor(v, text, limit=120, every=2):
    t0 = time.time()
    s = ''
    while time.time() - t0 < limit:
        s = v.screen()
        if text in s.lower():
            return True, s
        time.sleep(every)
    return False, s

problems = []
def expect(v, name, text, limit=120):
    ok, s = waitfor(v, text, limit)
    if not ok:
        problems.append(f'{name}: no {text!r}')
    return ok

def absent(v, name, text):
    if text in v.screen().lower():
        problems.append(f'{name}: {text!r} too soon')

def step(v, n):
    v.cmd('bank ram00', f'> 0b00 {n:02x}')

def boot(v, name):
    ok, s = waitfor(v, 'c128 d#08', 120)
    if not ok:
        sys.exit(f"{name}: the Lt. Kernal didn't come up in 128 mode:\n" + s)
    v.type('RUN"BOOT 128",U9\r')
    if not waitfor(v, '&,13 locks', 300)[0]:
        sys.exit(f'{name}: the stand-in never started:\n' + v.screen() + v.cmd('r'))
    time.sleep(2)
    v.cmd('bank ram00', f'> 0b02 {LTKFLAG & 255:02x}', f'> 0b03 {LTKFLAG >> 8:02x}')
    step(v, 1)

for p in (0, 1):
    d = os.path.join(repo, 'build', f'standin-lock-{p}.d81')
    shutil.copy(disk, d)
a = station(0)
b = None
try:
    boot(a, 'a')
    expect(a, 'a', 'lt. kernal 1 port 0')
    expect(a, 'a', 'a has 3 twice')
    b = station(1)
    boot(b, 'b')
    expect(b, 'b', 'lt. kernal 1 port 1')
    expect(b, 'b', 'b waits for 3')
    time.sleep(5)
    absent(b, 'b', 'b has 3')
    if b.mem('ram00', STATUS_L, 1)[0] != 0xcc:
        problems.append("b: no reverse L on its status line while waiting")
    step(a, 2)
    expect(a, 'a', 'a gave 3 back once')
    time.sleep(5)
    absent(b, 'b', 'b has 3')
    step(a, 3)
    expect(a, 'a', 'a gave 3 back')
    expect(b, 'b', 'b gave 3 back', 60)
    step(a, 4)
    expect(a, 'a', 'a has 5')
    a.stop()				# a crashes, holding lock 5
    step(b, 2)
    expect(b, 'b', 'b waits for 5')
    time.sleep(5)
    absent(b, 'b', 'b has 5')
    a = station(0)			# a boots again: lockinit frees lock 5
    ok, s = waitfor(a, 'c128 d#08', 120)
    a.type('RUN"BOOT 128",U9\r')
    expect(b, 'b', 'all done', 300)
    for name, v in (('a', a), ('b', b)):
        print(f'===== {name}'); print(v.screen())
    print('passed' if not problems else 'problems: ' + '; '.join(problems))
    sys.exit(0 if not problems else 1)
finally:
    if '--keep' not in sys.argv:
        a.stop()
        if b:
            b.stop()
