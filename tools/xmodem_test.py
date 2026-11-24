#!/usr/bin/env python3
"""xmodem_test.py: ++ xmodem (asm/xmodem.asm) against lrzsz, in x128.

    asm/build.sh
    tools/standin.sh tests/standin/xmodem.bas
    tools/xmodem_test.py [--cols 40|80] [--keep DIR]

Runs tests/standin/xmodem.bas with a SwiftLink on ip232 (as tools/netpair.py
does) and plays the other end of each of its five transfers here, through a
bridge that gives it carrier ($ff $01) and joins it to each program's
stdin/stdout in turn:

  1 the BBS sends t.xsrc with 1K blocks       rx -c (CRC)
  2 the same, to a checksum receiver          rx (checksum): 128-byte blocks
  3 the BBS receives t.r1k                    sx -k (1K blocks)
  4 the BBS receives t.rsum                   a checksum-only sender (here)
  5 the BBS sends t.xsrc, plain Xmodem/CRC    rx -c

t.xsrc is 3000 bytes, (k*7+3) and 255. Each file that arrives (on the PC
from rx, on the stand-in's disk from the BBS) must be those 3000 bytes,
then only ^Z padding. The stand-in's a% (good blocks), b% (bad) and rc
(bytes) are checked too. Prints each check, then "all ok". Needs lrzsz.
"""
import argparse, os, queue, shutil, socket, subprocess, sys, tempfile, threading, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vmon import X128

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ap = argparse.ArgumentParser()
ap.add_argument('--cols', type=int, default=40, choices=(40, 80))
ap.add_argument('--port', type=int, default=25260, help='the bridge (VICE connects to it)')
ap.add_argument('--mon', type=int, default=6584, help="x128's remote monitor")
ap.add_argument('--keep', help='keep the files that arrived here')
args = ap.parse_args()

SRC = bytes(((k * 7 + 3) & 255) for k in range(3000))
work = args.keep or tempfile.mkdtemp(prefix='xmodem-test-')
os.makedirs(work, exist_ok=True)
with open(os.path.join(work, 'src.bin'), 'wb') as f:
    f.write(SRC)
log = open(os.path.join(work, 'bridge.log'), 'w')


def say(msg):
    print(msg, flush=True)
    log.write(msg + '\n'); log.flush()


t0 = time.monotonic()


def hexlog(tag, d):
    """each burst in hex, with its time: the protocol's bytes going by"""
    log.write(f'{time.monotonic() - t0:8.3f} {tag} {d[:48].hex(" ")}{" ..." if len(d) > 48 else ""} ({len(d)})\n')


# ---- the bridge: ip232 on one side, data on the other
class Bridge:
    def __init__(self, port):
        self.ls = socket.socket()
        self.ls.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.ls.bind(('127.0.0.1', port))
        self.ls.listen(1)
        self.rx = queue.Queue()     # data bytes from the emulator
        self.conn = None
        threading.Thread(target=self.accept, daemon=True).start()

    def accept(self):
        self.conn, _ = self.ls.accept()
        self.conn.sendall(b'\xff\x01')      # carrier up
        say('bridge: x128 connected, carrier up')
        esc = False
        while True:
            d = self.conn.recv(4096)
            if not d:
                break
            hexlog('x128>', d)
            for b in d:
                if esc:
                    esc = False
                    if b == 0xff:
                        self.rx.put(0xff)
                    # $ff $00 / $ff $01: DTR, not data
                elif b == 0xff:
                    esc = True
                else:
                    self.rx.put(b)

    def send(self, data):
        hexlog('>x128', data)
        self.conn.sendall(data.replace(b'\xff', b'\xff\xff'))

    def get(self, timeout):
        try:
            return self.rx.get(timeout=timeout)
        except queue.Empty:
            return None


def run_prog(br, cmd, limit=180):
    """cmd's stdin/stdout joined to the emulator until it ends"""
    say('step: ' + ' '.join(cmd))
    p = subprocess.Popen(cmd, cwd=work, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=log)

    def out():
        while True:
            d = p.stdout.read1(4096) if hasattr(p.stdout, 'read1') else p.stdout.read(1)
            if not d:
                return
            br.send(d)
    threading.Thread(target=out, daemon=True).start()
    end = time.time() + limit
    while p.poll() is None and time.time() < end:
        b = br.get(0.05)
        if b is not None:
            try:
                p.stdin.write(bytes([b])); p.stdin.flush()
            except BrokenPipeError:
                break
    if p.poll() is None:
        p.kill()
        say(f'  {cmd[0]} timed out')
        return False
    say(f'  {cmd[0]} exit {p.returncode}')
    return p.returncode == 0


def checksum_sender(br, data, limit=180):
    """send data in 128-byte blocks with checksums: wait for NAK (letting
    the receiver's "C"s go by, so it has to fall back to checksums)"""
    say('step: checksum sender')
    end = time.time() + limit
    cs = 0
    while time.time() < end:
        b = br.get(1)
        if b == 0x15:
            break
        if b == ord('C'):
            cs += 1
    else:
        say('  no NAK'); return False
    say(f'  NAK after {cs} "C"s')
    blocks = [data[i:i + 128].ljust(128, b'\x1a') for i in range(0, len(data), 128)]
    n = 1
    for blk in blocks:
        for _ in range(10):
            br.send(bytes([1, n & 255, 255 - (n & 255)]) + blk + bytes([sum(blk) & 255]))
            r = br.get(10)
            if r == 6:
                break
            say(f'  block {n}: {r!r}, again')
        else:
            say('  gave up'); return False
        n += 1
    for _ in range(10):
        br.send(b'\x04')
        if br.get(10) == 6:
            say('  sent, EOT ACKed')
            return True
    return False


def check_file(name, data):
    ok = len(data) >= 3000 and data[:3000] == SRC and all(b == 0x1a for b in data[3000:])
    say(f'{"ok" if ok else "WRONG"}: {name}: {len(data)} bytes')
    return ok


br = Bridge(args.port)
x = X128(['-drive8type', '1581', '-acia1', '-acia1base', '0xde00', '-acia1irq', '1',
          '-acia1mode', '1', '-myaciadev', '0', '-rsdev1', f'127.0.0.1:{args.port}', '-rsdev1ip232',
          '-rsdev1baud', '19200', '-userportdevice', '0',
          '-autostart-warp', '-autostart', os.path.join(repo, 'build', 'standin-xmodem.d81') + ':boot 128'],
         cols=args.cols, port=args.mon)
fails = 0
screen = ''
try:
    # warp while the stand-in writes t.xsrc (a print# loop: minutes at
    # 1 MHz), then normal speed for the transfers (their timeouts count
    # jiffies); the PC side starts once it says "carrier" (++ xmodem in)
    x.cmd('warp on')
    for _ in range(300):
        screen = x.screen()
        if 'waiting for carrier' in screen:
            break
        time.sleep(1)
    x.cmd('warp off')
    for _ in range(120):
        lines = [l.strip() for l in x.screen().split('\n')]
        if br.conn and 'carrier' in lines:
            break
        time.sleep(1)
    else:
        say('WRONG: no carrier on the stand-in')
    steps = [lambda: run_prog(br, ['rx', '-vv', '-c', 'out1.bin']),
             lambda: run_prog(br, ['rx', '-vv', 'out2.bin']),
             lambda: run_prog(br, ['sx', '-vv', '-k', 'src.bin']),
             lambda: checksum_sender(br, SRC),
             lambda: run_prog(br, ['rx', '-vv', '-c', 'out5.bin'])]
    for i, step in enumerate(steps, 1):
        if not step():
            fails += 1
            say(f'WRONG: step {i} (the PC side) failed')
    for _ in range(60):
        screen = x.screen()
        if 'done' in screen:
            break
        time.sleep(1)
finally:
    x.stop()
    time.sleep(1)

say(screen)
# the stand-in's results: "n name: a% b% rc"
want = {'1': (3, 0, 3072), '2': (24, 0, 3072), '4': (24, 0, 3072), '5': (24, 0, 3072)}
seen = set()
for line in screen.split('\n'):
    if ':' in line and line[:1] in '12345' and line[1:2] == ' ':
        n = line[0]
        nums = line.split(':', 1)[1].split()
        try:
            a, b, rc = (int(float(v)) for v in nums[:3])
        except ValueError:
            continue
        seen.add(n)
        if n in want:
            ok = (a, b, rc) == want[n]
        else:   # 3: sx -k's blocks; all its bytes
            ok = b == 0 and rc >= 3000
        fails += not ok
        say(f'{"ok" if ok else "WRONG"}: step {n}: a% {a} b% {b} rc {rc}' + ('' if ok or n not in want else f' (want {want[n]})'))
if seen != set('12345'):
    fails += 1
    say(f'WRONG: results seen for steps {sorted(seen)}')
for n in ('out1.bin', 'out2.bin', 'out5.bin'):
    p = os.path.join(work, n)
    if os.path.exists(p):
        fails += not check_file(n, open(p, 'rb').read())
    else:
        fails += 1; say(f'WRONG: {n}: not received')
disk = os.path.join(repo, 'build', 'standin-xmodem.d81')
for n in ('t.r1k', 't.rsum'):
    out = os.path.join(work, n + '.bin')
    subprocess.run(['c1541', disk, '-read', n + ',s', out], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.path.exists(out):
        fails += not check_file(n, open(out, 'rb').read())
    else:
        fails += 1; say(f'WRONG: {n}: not on the disk')
say('all ok' if fails == 0 else f'{fails} wrong')
if not args.keep:
    shutil.rmtree(work, ignore_errors=True)
sys.exit(1 if fails else 0)
