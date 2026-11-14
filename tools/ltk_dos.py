#!/usr/bin/env python3
"""ltk_dos.py: run tests/standin/ltkdos.bas with VICE's Lt. Kernal at device 8.

    tools/standin.sh tests/standin/ltkdos.bas
    tools/ltk_dos.py [--fresh] [--keep]

As tools/ltk_chatmode.py: the Lt. Kernal (LTK DIR's ltk.crt and drive
images, copied to build/ltk/), booted in 128 mode, and the stand-in on a
1581 at device 9 (RUN"BOOT 128",U9). The stand-in stops after each part
("--- part n done"); this prints the screen, then pokes n into $0b00.
"""
import os, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk')
disk = os.path.join(repo, 'build', 'standin-ltkdos.d81')
PORT = int(os.environ.get('VMON_PORT', '6602'))

if '--fresh' in sys.argv or not os.path.exists(os.path.join(work, 'disk0.dlk')):
    os.makedirs(work, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(LTK, f), work)


def waitfor(v, texts, limit, every=3):
    t0 = time.time()
    s = ''
    while time.time() - t0 < limit:
        s = v.screen()
        for t in texts:
            if t in s.lower():
                return t, s
        time.sleep(every)
    return None, s


v = X128(['-cartcrt', os.path.join(LTK, 'ltk.crt'),
          '-ltkimage0', os.path.join(work, 'disk0.dlk'),
          '-ltkimage1', os.path.join(work, 'disk1.dlk'),
          '-ltkimage2', os.path.join(work, 'disk2.dlk'),
          '-drive8type', '0', '-drive9type', '1581', '-9', disk],
         cols=40, wait=4, port=PORT)
try:
    t, s = waitfor(v, ['c128 d#08'], 120)
    if not t:
        sys.exit("the Lt. Kernal didn't come up in 128 mode:\n" + s)
    v.type('RUN"BOOT 128",U9\r')
    for part in (1, 2, 3):
        t, s = waitfor(v, [f'--- part {part} done', '?'], 300)
        print(f'===== part {part}'); print(s)
        if t != f'--- part {part} done':
            sys.exit(1)
        v.cmd('bank ram00', f'> 0b00 {part:02x}')
        time.sleep(3)
    t, s = waitfor(v, ['done', 'error'], 300)
    print('===== part 4'); print(s)
finally:
    if '--keep' not in sys.argv:
        v.stop()
