#!/usr/bin/env python3
"""ltk_chatmode.py: run tests/standin/chatmode.bas on x128 with VICE's Lt. Kernal.

    tools/standin.sh tests/standin/chatmode.bas
    c1541 build/standin-chatmode.d81 -write asm/chatmode.prg "++ chatmode"
    tools/ltk_chatmode.py [--fresh] [--keep]

The Lt. Kernal is device 8 (the host adapter's boot ROM, ltk.crt, and three
drive images: LTK DIR, below), set up to boot in 128 mode; the stand-in's
disk is a 1581 at device 9, started with RUN"BOOT 128",U9 (boot.asm loads
the ML from the device it came from). The drive images are copied to
build/ltk/ the first time (or with --fresh) and used from there, so a run
doesn't change the originals.

LTK DIR (~/Documents/c64/ltkernal/ltk128-images) holds ltk.crt and disk0-2.dlk:
the pre-installed DOS 7.2 images from ltk-max.zip (LTK-testfiles.zip), with
CONFIG's "cpu mode" for port 00 set to 00 (C128 mode; they come set to 01,
C64 mode, and GO 128 then resets back into 64 mode). VICE's notes say the
Lt. Kernal DOS 7.2 needs the 128's first KERNAL (318020-03) in 128 mode;
this ran with VICE's 318020-05.
"""
import os, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk')
disk = os.path.join(repo, 'build', 'standin-chatmode.d81')
PORT = int(os.environ.get('VMON_PORT', '6602'))

if '--fresh' in sys.argv or not os.path.exists(os.path.join(work, 'disk0.dlk')):
    os.makedirs(work, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(LTK, f), work)

def waitfor(v, texts, limit, every=3):
    t0 = time.time()
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
        sys.exit('the Lt. Kernal didn\'t come up in 128 mode:\n' + s)
    v.type('RUN"BOOT 128",U9\r')
    t, s = waitfor(v, ['all passed', 'failed'], 400, every=5)
    print(s)
    sys.exit(0 if t == 'all passed' else 1)
finally:
    if '--keep' not in sys.argv:
        v.stop()
