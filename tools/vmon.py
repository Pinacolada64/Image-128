"""vmon.py: drive x128 through its remote monitor (port 6537, not the 6510 a VICE of
your own may use). screen() reads the 40- or 80-column screen as text, in the
lower/upper case character set Image uses (reverse video shown as plain)."""
import re, socket, subprocess, time
MON = 6537
PROMPT = re.compile(rb'\(C:\$[0-9a-f]{4}\) $')


class X128:
    def __init__(self, args=(), cols=80, wait=4):
        self.p = subprocess.Popen(['x128', f'-{cols}col', '+sound', '-remotemonitor', '-remotemonitoraddress',
                                   f'127.0.0.1:{MON}', *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
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
        s = socket.create_connection(('127.0.0.1', MON), timeout=5)
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
        """poke text (PETSCII bytes) into the keyboard buffer, 10 at a time"""
        for i in range(0, len(text), 10):
            chunk = text[i:i+10]
            self.cmd('bank ram', 'f 034a 0353 00', *(f'> {0x34a+j:04x} {ord(ch):02x}' for j, ch in enumerate(chunk)), f'> 00d0 {len(chunk):02x}')
            time.sleep(1)

    def stop(self):
        self.p.kill(); self.p.wait()
