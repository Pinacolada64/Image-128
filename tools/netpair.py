#!/usr/bin/env python3
"""netpair.py: a NetMail exchange between two x128s, each running ++ net.

    asm/build.sh            (or asm/build.sh ml, after an ML change)
    tools/netpair.py [--cols 80|40] [--fast caller|answer|both] [--timeout 600] [--keep]

Makes the stand-in disks (tests/standin/netcall.bas, the caller, and
netans.bas, the answering BBS), starts tools/nullmodem.py, then both
x128s with a SwiftLink (ip232, so the null modem gives them carrier). The
caller sends two files; the answer receives them and compares them with
what the caller wrote. It prints both screens when both have finished (or
at the timeout), and exits 0 if both said "all passed".

Ports (none of them the BBSes'): null modem 25250 (caller) and 25251
(answer), monitors 6537 and 6538. The null modem's log, every byte with
its direction and time: build/nullmodem.log. --keep leaves both x128s running.

--fast runs that side (or both) at 2 MHz (BASIC 7's fast: the stand-in
does it when it finds the file t.fast on its disk). ++ net's waits count
passes of a loop, so at 2 MHz they end in half the time: a mixed pair
shows whether the protocol copes. 80 columns only (2 MHz blanks the VIC).
++ net itself runs its calls at 2 MHz in 80 columns (11/05/2026), so for a
1 MHz side run it in 40: --answer-cols 40.
"""
import argparse, os, re, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

ap = argparse.ArgumentParser()
ap.add_argument('--cols', type=int, default=80)
ap.add_argument('--timeout', type=int, default=600)
ap.add_argument('--keep', action='store_true')
ap.add_argument('--fast', choices=['caller', 'answer', 'both'])
ap.add_argument('--answer-cols', type=int, choices=[40, 80],
                help='the answering side in these columns (++ net goes to 2 MHz in 80 only)')
args = ap.parse_args()

os.chdir(repo)
for n in ('netcall', 'netans'):
    subprocess.run(['tools/standin.sh', f'tests/standin/{n}.bas'], check=True, stdout=subprocess.DEVNULL)
if args.fast:
    if args.cols != 80 or args.answer_cols == 40:
        sys.exit('netpair.py: --fast needs 80 columns (2 MHz blanks the VIC)')
    flag = os.path.join('build', 'netpair-fast.seq')
    with open(flag, 'w') as f:
        f.write('2 mhz\r')
    for n, side in (('netcall', 'caller'), ('netans', 'answer')):
        if args.fast in (side, 'both'):
            subprocess.run(['c1541', f'build/standin-{n}.d81', '-write', flag, 't.fast,s'],
                           check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

null = subprocess.Popen([sys.executable, 'tools/nullmodem.py', '--ports', '25250', '25251',
                         '--log', 'build/nullmodem.log', '--times'], stdout=subprocess.DEVNULL)
time.sleep(1)


def x128(name, port, mon, cols=None):
    # the SwiftLink as im's "tcpser (VICE)" profile has it: $de00, NMI
    return X128(['-drive8type', '1581', '-acia1', '-acia1base', '0xde00', '-acia1irq', '1',
                 '-acia1mode', '1', '-myaciadev', '0', '-rsdev1', f'127.0.0.1:{port}', '-rsdev1ip232',
                 '-rsdev1baud', '19200', '-userportdevice', '0',
                 '-autostart-warp', '-autostart', f'build/standin-{name}.d81:boot 128'],
                cols=cols or args.cols, port=mon)


machines = {}
try:
    machines['answer'] = x128('netans', 25251, 6538, args.answer_cols)
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
        # ++ net's counters (row 15) on the screen, in 80 columns too
        # (&,72): the good blocks counted there
        good = re.search(r'ood: (\d{5})', s)  # column 1 is ++ net's receive status (A-D), over the G, as on the C64
        if not good or int(good.group(1)) == 0:
            print(f'{k}: no good blocks counted on the screen')
            ok = False
    print('PASSED' if ok else 'FAILED (log: build/nullmodem.log)')
finally:
    if not args.keep:
        for m in machines.values():
            m.stop()
        null.terminate()
sys.exit(0 if ok else 1)
