#!/usr/bin/env python3
"""punterpair.py: ++ punter between two x128s.

    asm/build.sh
    tools/punterpair.py [--send-cols 40|80] [--recv-cols 40|80] [--keep]

Makes the stand-in disks (tests/standin/punsend.bas and punrecv.bas),
starts tools/nullmodem.py, then both x128s with a SwiftLink (ip232, so the
null modem gives them carrier), in warp while they write their files, at
normal speed for the transfers. punsend sends t.psrc (3000 bytes, (k*7+3)
and 255) three times: Punter, Relaxed Punter, Image 1.3 Punter (flags 0, 1,
2); punrecv takes them as t.prcv1-3. Checks rc (3000 on both sides), b%
and the file type the receiver got (2, SEQ, where a type block is sent),
then each received file byte for byte (c1541). Prints both screens and
"all ok". The receiver's b% must be 0; the sender's isn't checked: it
counts any answer but GOO as bad (a stray S/B at the start, as the C64's
does), with nothing sent again.

Ports (none of them the BBSes'): null modem 25270 (send) and 25271
(receive), monitors 6585 and 6586. The null modem's log: build/punterpair.log.

This tries the 128 against itself. Another Punter (a C64's) is a test still
to do.
"""
import argparse, os, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

ap = argparse.ArgumentParser()
ap.add_argument('--send-cols', type=int, default=80, choices=(40, 80))
ap.add_argument('--recv-cols', type=int, default=80, choices=(40, 80))
ap.add_argument('--timeout', type=int, default=900)
ap.add_argument('--keep', action='store_true')
args = ap.parse_args()

os.chdir(repo)
for n in ('punsend', 'punrecv'):
    subprocess.run(['tools/standin.sh', f'tests/standin/{n}.bas'], check=True, stdout=subprocess.DEVNULL)
null = subprocess.Popen([sys.executable, 'tools/nullmodem.py', '--ports', '25270', '25271',
                         '--log', 'build/punterpair.log', '--times'], stdout=subprocess.DEVNULL)
time.sleep(1)


def x128(name, port, mon, cols):
    return X128(['-drive8type', '1581', '-acia1', '-acia1base', '0xde00', '-acia1irq', '1',
                 '-acia1mode', '1', '-myaciadev', '0', '-rsdev1', f'127.0.0.1:{port}', '-rsdev1ip232',
                 '-rsdev1baud', '19200', '-userportdevice', '0',
                 '-autostart-warp', '-autostart', f'build/standin-{name}.d81:boot 128'],
                cols=cols, port=mon)


SRC = bytes(((k * 7 + 3) & 255) for k in range(3000))
machines = {}
fails = 0
screens = {}
try:
    machines['recv'] = x128('punrecv', 25271, 6586, args.recv_cols)
    machines['send'] = x128('punsend', 25270, 6585, args.send_cols)
    # warp while they set up (the sender's print# loop), then normal speed
    for m in machines.values():
        m.cmd('warp on')
    end = time.time() + 300
    ready = set()
    while time.time() < end and len(ready) < 2:
        for k, m in machines.items():
            if k not in ready and 'waiting for carrier' in m.screen():
                m.cmd('warp off')
                ready.add(k)
        time.sleep(1)
    if len(ready) < 2:
        print('WRONG: not both waiting for carrier:', sorted(ready))
    end = time.time() + args.timeout
    while time.time() < end:
        time.sleep(5)
        screens = {k: m.screen() for k, m in machines.items()}
        if all('done' in s for s in screens.values()):
            break
finally:
    if not args.keep:
        for m in machines.values():
            m.stop()
        null.terminate()
    time.sleep(1)

results = {}
for k, s in screens.items():
    print(f'--- {k} ---')
    print('\n'.join(l for l in s.split('\n') if l.strip()))
    for line in s.split('\n'):
        if line[:1] in '123' and line[1:2] == ' ' and ':' in line:
            try:
                a, b, rc, ft = (int(float(v)) for v in line.split(':', 1)[1].split()[:4])
            except ValueError:
                continue
            results[(k, line[0])] = (a, b, rc, ft)
for n in '123':
    for k in ('send', 'recv'):
        r = results.get((k, n))
        if not r:
            fails += 1; print(f'WRONG: {k} step {n}: no result'); continue
        a, b, rc, ft = r
        # the sender's b% counts any answer but GOO (a stray S/B from the
        # handshake's start too) as a bad block, though nothing was sent
        # again; the receiver's counts blocks that failed their checks
        ok = rc == 3000 and a > 0 and (b == 0 or k == 'send')
        if k == 'recv' and n != '3':
            ok = ok and ft == 2     # the type block's SEQ arrived
        fails += not ok
        print(f'{"ok" if ok else "WRONG"}: {k} step {n}: a% {a} b% {b} rc {rc} filetyp {ft}')
for n in '123':
    out = os.path.join('build', f'punterpair-prcv{n}.bin')
    if os.path.exists(out):
        os.remove(out)
    subprocess.run(['c1541', 'build/standin-punrecv.d81', '-read', f't.prcv{n},s', out],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    data = open(out, 'rb').read() if os.path.exists(out) else None
    ok = data == SRC
    fails += not ok
    print(f'{"ok" if ok else "WRONG"}: t.prcv{n}: ' + ('missing' if data is None else f'{len(data)} bytes'))
print('all ok' if fails == 0 else f'{fails} wrong')
sys.exit(1 if fails else 0)
