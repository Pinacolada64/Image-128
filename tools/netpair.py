#!/usr/bin/env python3
"""netpair.py: a NetMail exchange between two x128s, each running ++ net.

    asm/build.sh            (or asm/build.sh ml, after an ML change)
    tools/netpair.py [--cols 80|40] [--timeout 600] [--keep]

Makes the stand-in disks (tests/standin/netcall.bas, the caller, and
netans.bas, the answering BBS), starts tools/nullmodem.py, then both
x128s with a SwiftLink (ip232, so the null modem gives them carrier). The
caller sends two files; the answer receives them and compares them with
what the caller wrote. It prints both screens when both have finished (or
at the timeout), and exits 0 if both said "all passed".

Ports (none of them the BBSes'): null modem 25250 (caller) and 25251
(answer), monitors 6537 and 6538. The null modem's log, every byte with
its direction: build/nullmodem.log. --keep leaves both x128s running.
"""
import argparse, os, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

ap = argparse.ArgumentParser()
ap.add_argument('--cols', type=int, default=80)
ap.add_argument('--timeout', type=int, default=600)
ap.add_argument('--keep', action='store_true')
args = ap.parse_args()

os.chdir(repo)
for n in ('netcall', 'netans'):
    subprocess.run(['tools/standin.sh', f'tests/standin/{n}.bas'], check=True, stdout=subprocess.DEVNULL)

null = subprocess.Popen([sys.executable, 'tools/nullmodem.py', '--ports', '25250', '25251',
                         '--log', 'build/nullmodem.log'], stdout=subprocess.DEVNULL)
time.sleep(1)


def x128(name, port, mon):
    # the SwiftLink as im's "tcpser (VICE)" profile has it: $de00, NMI
    return X128(['-drive8type', '1581', '-acia1', '-acia1base', '0xde00', '-acia1irq', '1',
                 '-acia1mode', '1', '-myaciadev', '0', '-rsdev1', f'127.0.0.1:{port}', '-rsdev1ip232',
                 '-rsdev1baud', '19200', '-userportdevice', '0',
                 '-autostart-warp', '-autostart', f'build/standin-{name}.d81:boot 128'],
                cols=args.cols, port=mon)


machines = {}
try:
    machines['answer'] = x128('netans', 25251, 6538)
    machines['caller'] = x128('netcall', 25250, 6537)
    end = time.time() + args.timeout
    screens = {}
    while time.time() < end:
        time.sleep(5)
        screens = {k: m.screen() for k, m in machines.items()}
        if all(('all passed' in s or 'failed' in s) for s in screens.values()):
            break
    ok = True
    for k, s in screens.items():
        print(f'--- {k} ---')
        print('\n'.join(l for l in s.split('\n') if l.strip()))
        ok = ok and 'all passed' in s
    print('PASSED' if ok else 'FAILED (log: build/nullmodem.log)')
finally:
    if not args.keep:
        for m in machines.values():
            m.stop()
        null.terminate()
sys.exit(0 if ok else 1)
