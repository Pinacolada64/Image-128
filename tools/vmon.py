"""vmon.py: drive x128 through its remote monitor (port 6537, not the 6510 a VICE of
your own may use). screen() reads the 40- or 80-column screen as text, in the
lower/upper case character set Image uses (reverse video shown as plain).

Modem: a tcpser as the Hayes modem on x128's SwiftLink, as start-image-128.sh
sets it up, for tools that boot a configured BBS (its sub.modem waits for
the modem at boot, after "Reading Blocks Free", until something answers)."""
import os, re, socket, subprocess, time
MON = 6537
TCPSER = os.environ.get('TCPSER', os.path.expanduser('~/bin/tcpser/tcpser'))
PROMPT = re.compile(rb'\(C:\$[0-9a-f]{4}\) $')


class X128:
    def __init__(self, args=(), cols=80, wait=4, port=MON):
        self.port = port   # another for each x128 run at once (tools/netpair.py)
        self.p = subprocess.Popen(['x128', f'-{cols}col', '+sound', '-remotemonitor', '-remotemonitoraddress',
                                   f'127.0.0.1:{port}', *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(wait)

    @staticmethod
    def _until_prompt(s, buf, limit, quiet=0.03):
        """read until the monitor's prompt ends what came back and nothing more
        arrives for `quiet` seconds (it can print a prompt twice), or limit"""
        end = time.time() + limit
        last = time.time()
        while time.time() < end:
            try:
                d = s.recv(65536)
                if not d:
                    break
                buf += d; last = time.time()
            except socket.timeout:
                if PROMPT.search(buf) and time.time() - last >= quiet:
                    break
        return buf

    def cmd(self, *cmds, resume=True):
        """send monitor commands, each answered once its prompt comes back; then
        resume the emulation ('x') unless resume=False. Returns the text."""
        # 11/06/2026: a busy x128 can miss a connection: try again
        # (12 tries: with a CMD HD busy in warp mode, x128 took over 30
        # seconds to answer)
        for i in range(12):
            try:
                s = socket.create_connection(('127.0.0.1', self.port), timeout=5)
                break
            except (TimeoutError, ConnectionRefusedError):
                if i == 11:
                    raise
                time.sleep(2)
        s.settimeout(0.05)
        out = b''                                   # whatever the stop printed first:
        end = time.time() + 0.5                     # take it until 0.1 s of quiet
        last = time.time()
        while time.time() < end and time.time() - last < 0.1:
            try:
                d = s.recv(65536)
                if not d:
                    break
                out += d; last = time.time()
            except socket.timeout:
                pass
        for c in cmds:
            s.sendall(c.encode() + b'\n')
            out += self._until_prompt(s, b'', 10)
        if resume:
            s.sendall(b'x\n')
        s.close()
        return out.decode('latin-1')

    def mem(self, bank, addr, n):
        # 11/06/2026: a busy host can end the read before the bytes come
        # (setup_test.py's "index out of range"): try again, a few times
        for _ in range(5):
            b = self._mem(bank, addr, n)
            if len(b) == n:
                return b
            time.sleep(0.5)
        return b

    def _mem(self, bank, addr, n):
        out = self.cmd(f'bank {bank}', f'm {addr:04x} {addr+n-1:04x}')
        lines = [(int(m.group(1), 16), m.group(2).split()) for m in
                 re.finditer(r'>C:([0-9a-f]{4})\s+(.*)', out)]
        # each line is its address, its bytes, then the bytes as text; that
        # text can look like more bytes ("80 columns"), so take only as
        # many as the next line's address says the line holds
        b = []
        for i, (a, words) in enumerate(lines):
            count = lines[i + 1][0] - a if i + 1 < len(lines) else n - len(b)
            b += [int(x, 16) for x in words[:count]]
        return bytes(b[:n])

    def screen(self, rows=25):
        cols80 = self.mem('ram', 0xd7, 1)[0] & 0x80
        width = 80 if cols80 else 40
        raw = self.mem('vdc', 0, rows * 80) if cols80 else self.mem('ram', 0x400, rows * 40)
        out = []
        for r in range(rows):
            t = ''
            for c in raw[r * width:(r + 1) * width]:
                c &= 0x7f
                t += chr(c+96) if 1 <= c <= 26 else chr(c) if 0x20 <= c <= 0x5a else '@' if c == 0 else '.'
            out.append(t.rstrip())
        return '\n'.join(out)

    def type(self, text):
        """poke text (PETSCII bytes) into the keyboard buffer, 10 at a time.
        11/11/2026: each chunk only once the buffer is empty (ndx, $d0, 0),
        up to 20 seconds: written over keys not yet read, it lost them (a
        page redraw in ++ visual outlasted the old 1-second pause)"""
        for i in range(0, len(text), 10):
            for _ in range(100):
                if self.mem('ram00', 0xd0, 1)[0] == 0:
                    break
                time.sleep(0.2)
            chunk = text[i:i+10]
            self.cmd('bank ram', 'f 034a 0353 00', *(f'> {0x34a+j:04x} {ord(ch):02x}' for j, ch in enumerate(chunk)), f'> 00d0 {len(chunk):02x}')
            time.sleep(1)

    def stop(self):
        self.p.kill(); self.p.wait()


def _listening(port):
    """is something listening on 127.0.0.1:port (or any address)?"""
    out = subprocess.run(['ss', '-ltn'], capture_output=True, text=True).stdout
    return re.search(r':%d\b' % port, out) is not None


class Modem:
    """tcpser as the modem on x128's SwiftLink (start-image-128.sh's setup):
    x128 connects to it on link (ip232, which carries DCD and DTR too) and
    callers telnet to telnet. Pass .args to X128; stop() when done.

    11/18/2026: a configured BBS's boot runs sub.modem, which sends ATZ and
    waits until the modem answers (60010-60050), so without one the boot
    never gets past "Reading Blocks Free". The SwiftLink is at $de00 (NMI,
    RS-232 device 3); the user port RS-232 is off. Carrier: VICE puts the
    modem's DCD on the 6551's DSR bit, so a call is seen with the lightbar's
    Dsr left check on and Dcd left off (SYSOP_COMMANDS.md, "T: carrier
    detect"); booting needs neither."""

    def __init__(self, link, telnet, log, baud=19200):
        for p in (link, telnet):
            if _listening(p):
                raise RuntimeError(f'port {p} is already in use (another tcpser or x128?)')
        if not os.access(TCPSER, os.X_OK):
            raise RuntimeError(f'tcpser not found: {TCPSER} (TCPSER=path)')
        self.link, self.telnet, self.log = link, telnet, log
        self.p = subprocess.Popen([TCPSER, '-s', str(baud), '-v', f'127.0.0.1:{link}', '-p', str(telnet),
                                   '-l', '4', '-L', log],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(50):     # up to 5 seconds to listen for x128
            if _listening(link):
                break
            if self.p.poll() is not None:
                raise RuntimeError(f'tcpser stopped: see {log}')
            time.sleep(0.1)
        else:
            self.stop()
            raise RuntimeError(f"tcpser isn't listening on port {link}")
        self.args = ['-acia1', '-acia1base', '0xde00', '-acia1mode', '1', '-acia1irq', '1',
                     '-myaciadev', '2', '-userportdevice', '0',
                     '-rsdev3', f'127.0.0.1:{link}', '-rsdev3ip232', '-rsdev3baud', str(baud)]

    def stop(self):
        if self.p.poll() is None:
            self.p.kill()
        self.p.wait()


def in_sub_modem_wait(line):
    """BASIC line `line` is sub.modem's wait for the modem at boot (60010-60350:
    ATZ, its init strings and their replies)"""
    return 60010 <= line <= 60350
