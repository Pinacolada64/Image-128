#!/usr/bin/env python3
"""ltk_install.py: put Image BBS 128's boot disk on an LU of VICE's Lt. Kernal.

    asm/build.sh
    tools/standin.sh tests/standin/ltkinstall.bas
    tools/ltk_install.py [--fresh]
    tools/ltk_install.py --base installed --source other.d81 [--no-keep]

Runs tests/standin/ltkinstall.bas (a 1581 at device 9) with the Lt. Kernal
at device 8 (build/ltk/, as tools/ltk_chatmode.py) and a copy of
build/image128.d81 as a 1581 at device 10: every file of it is copied onto
LU 5 (scratched first, copied with ++ copier, compared). Then
tools/setup_test.py --ltk 5 boots Image from that LU (from a copy of the
drive images as they were installed: build/ltk-installed/).
--base installed starts from build/ltk-installed/ instead (to replace a few
files: --source names a disk with just those); --no-keep leaves
build/ltk-installed/ as it was.
"""
import os, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk')
disk = os.path.join(repo, 'build', 'standin-ltkinstall.d81')
src = os.path.join(repo, 'build', 'ltkinstall-source.d81')
PORT = int(os.environ.get('VMON_PORT', '6602'))

base = LTK
if '--base' in sys.argv and sys.argv[sys.argv.index('--base') + 1] == 'installed':
    base = os.path.join(repo, 'build', 'ltk-installed')
if base != LTK or '--fresh' in sys.argv or not os.path.exists(os.path.join(work, 'disk0.dlk')):
    os.makedirs(work, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(base, f), work)
source = os.path.join(repo, 'build', 'image128.d81')
if '--source' in sys.argv:
    source = sys.argv[sys.argv.index('--source') + 1]
shutil.copy(source, src)


def waitfor(v, texts, limit, every=5):
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
          '-drive8type', '0', '-drive9type', '1581', '-9', disk,
          '-drive10type', '1581', '-10', src, '-warp'],
         cols=40, wait=4, port=PORT)
try:
    t, s = waitfor(v, ['c128 d#08'], 120, every=3)
    if not t:
        sys.exit("the Lt. Kernal didn't come up in 128 mode:\n" + s)
    v.type('RUN"BOOT 128",U9\r')
    t, s = waitfor(v, ['installed', 'error in'], 3000)
    print(s)
    ok = t == 'installed' and ' 0 failed' in s.lower()
finally:
    v.stop()
# the installed drive images, kept: tools/setup_test.py --ltk starts from them
if ok and '--no-keep' not in sys.argv:
    keep = os.path.join(repo, 'build', 'ltk-installed')
    os.makedirs(keep, exist_ok=True)
    for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
        shutil.copy(os.path.join(work, f), keep)
    print('kept in', keep)
sys.exit(0 if ok else 1)
