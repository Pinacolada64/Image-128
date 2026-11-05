#!/usr/bin/env python3
"""nullmodem.py: a null modem cable between two emulators' RS-232, for
trying a NetMail exchange (or any two BBSes) without a modem.

    tools/nullmodem.py [--ports 25250 25251] [--log build/nullmodem.log]

VICE connects to its RS-232 device as a TCP client, so this listens on two
ports and joins the two connections that arrive, one on each. Both sides
talk ip232 (x128 -rsdev1ip232, as tcpser -v does): a $ff in the data is
sent as $ff $ff, and $ff $00 / $ff $01 carry DCD (to the emulator) and DTR
(from it). Once both are connected, each is told carrier is up ($ff $01);
when one goes, the other is told carrier is down ($ff $00). Each side's
DTR is logged, not passed on.

--log writes each burst of data with its direction (A>B, B>A) in hex, for
seeing the protocol's codes and blocks go by.
"""
import argparse, select, socket, sys, time

ap = argparse.ArgumentParser()
ap.add_argument('--ports', nargs=2, type=int, default=[25250, 25251])
ap.add_argument('--log', default=None)
args = ap.parse_args()

log = open(args.log, 'w') if args.log else None


def say(msg):
    line = f'{time.strftime("%H:%M:%S")} {msg}'
    print(line, flush=True)
    if log:
        log.write(line + '\n'); log.flush()


listeners = []
for p in args.ports:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', p))
    s.listen(1)
    listeners.append(s)
say(f'listening on 127.0.0.1:{args.ports[0]} (A) and :{args.ports[1]} (B)')

conns = [None, None]
pending = [b'', b'']   # a $ff split across reads
names = 'AB'


def unescape(i, data):
    """the data bytes in what side i sent, its DTR changes logged"""
    data = pending[i] + data
    pending[i] = b''
    out = bytearray()
    j = 0
    while j < len(data):
        b = data[j]
        if b != 0xff:
            out.append(b); j += 1
        elif j + 1 == len(data):
            pending[i] = b'\xff'; break
        else:
            c = data[j + 1]; j += 2
            if c == 0xff:
                out.append(0xff)
            else:
                say(f'{names[i]} DTR {"on" if c else "off"}')
    return bytes(out)


def dcd(i, on):
    if conns[i]:
        conns[i].sendall(b'\xff\x01' if on else b'\xff\x00')


while True:
    socks = [l for k, l in enumerate(listeners) if conns[k] is None] + [c for c in conns if c]
    ready, _, _ = select.select(socks, [], [])
    for s in ready:
        if s in listeners:
            k = listeners.index(s)
            conns[k], addr = s.accept()
            say(f'{names[k]} connected from {addr[0]}:{addr[1]}')
            if all(conns):
                dcd(0, True); dcd(1, True)
                say('both connected: carrier up')
            continue
        i = conns.index(s)
        o = 1 - i
        data = s.recv(4096)
        if not data:
            say(f'{names[i]} disconnected')
            s.close(); conns[i] = None; pending[i] = b''
            dcd(o, False)
            continue
        data = unescape(i, data)
        if not data:
            continue
        if log:
            log.write(f'{names[i]}>{names[o]} {data.hex(" ")}\n'); log.flush()
        if conns[o]:
            conns[o].sendall(data.replace(b'\xff', b'\xff\xff'))
