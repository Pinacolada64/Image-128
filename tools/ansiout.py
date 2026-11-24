#!/usr/bin/env python3
"""ansiout.py: the bytes outmod (asm/modem.asm) sends an ASCII + ANSI colour
caller (flags 16 and 18), with tests/standin/ansiout.bas (each character
through &,51), through an x128's SwiftLink.

    tools/standin.sh tests/standin/ansiout.bas   (makes build/standin-ansiout.d81)
    tools/ansiout.py [--port N] [--tcp N]

Listens on --tcp (25233) as the far end of x128's ip232 RS-232 (carrier up,
$ff $01), records what arrives and prints each test: the PETSCII code sent
between "<" and ">", what the caller got, and whether that's what outmod
(asm/modem.asm) should send (PROGRAMMING.md, "What an ASCII or ANSI caller
gets"), and &,70's cursor position (CUP, asm/ansicup.asm). The disk is used from a copy (build/ansiout.d81).
"""
import argparse, os, shutil, socket, sys, threading, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

E = b'\x1b['
SGR = lambda i, c, b: E + b'0;%d;%d;%dm' % (i, c, b)
# what the caller should get for each test (the colour in effect: white,
# the boot's, until Red; reverse keeps it)
WANT = [
    ('Return (13)', SGR(0, 31, 40) + b'\r'),   # reverse off first (the boot's colour: red)
    ('Up ($91)', E + b'A'),
    ('Down ($11)', E + b'B'),
    ('Right ($1d)', E + b'C'),
    ('Left ($9d)', E + b'D'),
    ('Home ($13)', E + b'1;1H'),
    ('Clear ($93)', E + b'2J'),
    ('Rvs On ($12)', None),
    ('Rvs Off ($92)', None),
    ('Red ($1c)', SGR(0, 31, 40)),
    ('White ($05)', SGR(1, 37, 40)),
    ('Delete ($14)', b'\x08 \x08'),
    ('Return (13) again', SGR(1, 37, 40) + b'\r'),
    ('Esc ($1b)', b'\x1b'),
    ('Esc [ L (insert line)', E + b'L'),
    ('Esc [ 2 K (erase line)', E + b'2K'),
    ('&,70,5,3 (CUP)', E + b'4;6H'),
    ('&,70,0,0 (CUP)', E + b'1;1H'),
    ('&,70,79,24 (CUP)', E + b'25;80H'),
]


def listen(port, got, stop):
    srv = socket.socket(); srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(('127.0.0.1', port)); srv.listen(4); srv.settimeout(0.5)
    while not stop.is_set():
        try:
            c, _ = srv.accept()
        except socket.timeout:
            continue
        c.sendall(b'\xff\x01'); c.settimeout(0.2)
        while not stop.is_set():
            try:
                d = c.recv(4096)
            except socket.timeout:
                continue
            except OSError:
                break
            if not d:
                break
            got.extend(d)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--port', type=int, default=6538)
    ap.add_argument('--tcp', type=int, default=25233)
    args = ap.parse_args()
    disk = os.path.join(repo, 'build', 'ansiout.d81')
    shutil.copy(os.path.join(repo, 'build', 'standin-ansiout.d81'), disk)
    got, stop = bytearray(), threading.Event()
    threading.Thread(target=listen, args=(args.tcp, got, stop), daemon=True).start()
    v = X128(['-ntsc', '-drive8type', '1581', '-acia1', '-acia1base', '0xde00', '-acia1irq', '1',
              '-acia1mode', '1', '-myaciadev', '0', '-rsdev1', '127.0.0.1:%d' % args.tcp, '-rsdev1ip232',
              '-rsdev1baud', '19200', '-userportdevice', '0', '-autostart', disk + ':boot 128'],
             cols=40, wait=2, port=args.port)
    try:
        t0 = time.time()
        while v.mem('ram00', 0x0b01, 1)[0] != 1:
            if time.time() - t0 > 240:
                sys.exit('ansiout.py: the stand-in never got ready')
            time.sleep(1)
        time.sleep(2)
        got.clear()
        v.cmd('bank ram', '> 0b00 01')
        while v.mem('ram00', 0x0b01, 1)[0] != 2 and time.time() - t0 < 300:
            time.sleep(1)
        time.sleep(2)
        con = tuple(v.mem('ram00', 0x0b04, 2))
    finally:
        v.cmd('quit', resume=False); stop.set()
    data = bytes(got).replace(b'\xff\xff', b'\xff')
    tests, i = [], 0
    while True:
        a = data.find(b'<', i)
        if a < 0:
            break
        b = data.find(b'>', a + 1)
        tests.append(data[a + 1:b]); i = b + 1
    ok = 0
    for n, (name, want) in enumerate(WANT):
        g = tests[n] if n < len(tests) else None
        good = (want is None and bool(g)) or (want is not None and g == want)
        ok += good
        print('%-24s %-34r %s' % (name, g, 'ok' if good else 'want %r' % want))
    good = con == (9, 7)
    print('%-24s %-34s %s' % ('&,70,7,9 on the console', 'row %d, column %d' % con, 'ok' if good else 'want row 9, column 7'))
    ok += good
    print('%d of %d as expected; raw: %r' % (ok, len(WANT) + 1, data[:60]))
    return 0 if ok == len(WANT) + 1 else 1


if __name__ == '__main__':
    sys.exit(main())
