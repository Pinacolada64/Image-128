#!/usr/bin/env python3
"""ltk_start.py: boot Image BBS 128 from VICE's Lt. Kernal, to use it.

    tools/ltk_start.py --images DIR [--lu N] [--no-boot] [--warp]
        [--telnet PORT] [--link PORT] [--monitor PORT]
    e.g. tools/ltk_start.py --images build/ltk-configured

x128 (80 columns) with the Lt. Kernal's boot ROM (LTK DIR's ltk.crt), the
drive images in DIR (disk0.dlk, disk1.dlk, disk2.dlk: a configured system,
as tools/setup_test.py --ltk left it), the DS12C887 clock at $d700, and
tcpser as the modem on the SwiftLink: a configured system's boot waits for
its modem to answer (tools/vmon.py's Modem). Callers telnet to --telnet
(6140); tcpser's log is DIR/tcpser.log.

At the Lt. Kernal's "c128 d#08" prompt it types LU N (5), LOAD"BOOT 128",8
and RUN, then leaves x128 to you (--no-boot: types nothing). When x128
closes, tcpser is stopped.

The images are used in place: what the BBS writes stays, as on a real
drive. Keep a copy first if you want to go back (tools/ltk_copy.py --save
keeps one of each image it changes as <image>.before-<date>-<time>).
VICE keeps the images with every byte inverted (XOR $ff).
"""
import os, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128, Modem

LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
IMAGES = ('disk0.dlk', 'disk1.dlk', 'disk2.dlk')

args = sys.argv[1:]
if not args or '-h' in args or '--help' in args:
    print(__doc__.split('\n\n')[1]); sys.exit(0 if args else 2)

def opt(name, default):
    if name in args:
        i = args.index(name); v = args[i + 1]; del args[i:i + 2]
        return v
    return default

images = opt('--images', None)
lu = int(opt('--lu', 5))
telnet = int(opt('--telnet', 6140))
link = int(opt('--link', 25260))
port = int(opt('--monitor', 6620))
boot = '--no-boot' not in args
warp = '--warp' in args
if not images:
    sys.exit('ltk_start.py: --images DIR is needed (the configured drive images)')
images = os.path.abspath(images)
missing = [f for f in IMAGES if not os.path.exists(os.path.join(images, f))]
if missing:
    sys.exit(f'ltk_start.py: not in {images}: ' + ', '.join(missing))

modem = Modem(link, telnet, os.path.join(images, 'tcpser.log'))
print(f'tcpser: callers telnet to port {telnet} (log: {images}/tcpser.log)', flush=True)
v = None
try:
    v = X128(['+saveres', '-cartcrt', os.path.join(LTK, 'ltk.crt'),
              *(a for i, f in enumerate(IMAGES) for a in (f'-ltkimage{i}', os.path.join(images, f))),
              '-drive8type', '0',
              '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
              *modem.args, *(['-warp'] if warp else [])],
             cols=80, wait=4, port=port)
    if boot:
        for _ in range(120):
            if v.p.poll() is not None:
                break
            if 'c128 d#08' in v.screen().lower():
                print(f'Lt. Kernal ready: LU {lu}, LOAD"BOOT 128",8, RUN', flush=True)
                v.type(f'LU {lu}\r'); time.sleep(3)
                v.type('LOAD"BOOT 128",8\r'); time.sleep(8)
                v.type('RUN\r')
                break
            time.sleep(2)
        else:
            print("the Lt. Kernal's prompt didn't come: boot it by hand", flush=True)
    print('x128 is yours; close it to stop tcpser', flush=True)
    v.p.wait()
finally:
    if v and v.p.poll() is None:
        v.stop()
    modem.stop()
