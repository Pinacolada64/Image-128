#!/usr/bin/env python3
"""dst_test.py: the autumn daylight saving time change in x128: the clock is
set back an hour at 2:00 AM once, and only once (sub.clocks im=12, e.data
record 46's set-back flag).

    tools/dst_test.py [--case a|b|all] [--full] [--base disk.d81] [--fresh] [--port N] [--keep]

Each case boots a copy of a configured system (--base: build/dst-base.d81,
made by tools/setup_test.py the first time, or with --fresh: zone 5, MST
with the US rule, and a DS12C887 clock at $d700, so the alarm that sets
checkmark 64 at 2:00 on Sundays is in e.alarms) with e.data record 46
written first, and the DS12C887 set to Sunday, November 1, 2026, 1:55 AM,
the night the US clocks go back. x128 runs in warp mode, where the BBS's
clock runs about 3 times as fast as the RTC; the test reads the time on the
idle screen's status line (the one with seconds: date1, $16e0, is written
only at boot and login) every second or so and logs each minute it shows.

  a  record 46 "1,0,U..." (daylight time, not set back yet): at 2:00 the
     clock goes back to 1:00, once; record 46 is "0,1,U..." after. With
     --full, it also waits for the clock to reach 2:10 again (standard
     time: about 25 minutes more) and checks it wasn't set back again
  b  record 46 "1,1,U..." (daylight time, but already set back: what a check
     that found daylight time again in the repeated hour would leave): at
     2:00 the clock is not set back again; record 46 is "0,1,U..." after.
     Before the set-back flag (11/16/2026) this case went back to 1:00

x128 starts without -autostart (its reset puts the RTC back to the PC's
time): the RTC is set and read back at BASIC's prompt, then the boot is
typed. Each case's disk gets build/im 128.prg and build/sub.clocks.prg (when
they're there) over the base disk's, so a base disk made before a change
still tests it. Case a also needs im line 3155's d1$=z$ (11/16/2026): before
it, the boot's DST check read the build's date and time, not the RTC's, and
set the clock to that day's standard time.

It passes when the clock gets to 2:10 AM (case a without --full: 1:05, after
the set-back) with the right number of set-backs (half an hour or more back
between two readings) and record 46 says what it should; it fails on a
timeout (45 minutes a case), printing the screen.
--keep leaves x128 running after the last case.
"""
import functools, os, re, shutil, socket, subprocess, sys, time
print = functools.partial(print, flush=True)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vmon import X128

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULE = 'U03210200L11110100L'
CASES = {'a': ('1,0,' + RULE, 1), 'b': ('1,1,' + RULE, 0)}
RECLEN = 31          # e.data's records (sub.su.write: "e.data,l,"+chr$(31))
LIMIT = 45 * 60      # seconds a case may take

# --- e.data on the .d81: its records in the REL file's data sectors ---------

def off(t, s):
    return ((t - 1) * 40 + s) * 256


def petscii(text):
    return bytes(ord(c) - 32 if c.islower() else ord(c) + 128 if c.isupper() else ord(c) for c in text)


def ascii_(b):
    return ''.join(chr(c + 32) if 0x41 <= c <= 0x5a else chr(c - 128) if 0xc1 <= c <= 0xda
                   else chr(c) if 32 <= c < 127 else '' for c in b)


def rel_bytes(d, name):
    """the (disk offset) of each data byte of REL file name, in order"""
    t, s = 40, 3
    while t:
        b = off(t, s)
        for i in range(8):
            e = b + i * 32
            if d[e + 2] & 7 == 4 and d[e + 5:e + 21].rstrip(b'\xa0') == petscii(name):
                assert d[e + 23] == RECLEN, 'e.data: record length %d' % d[e + 23]
                where = []
                dt, ds = d[e + 3], d[e + 4]
                while dt:
                    o = off(dt, ds)
                    last = d[o + 1] if d[o] == 0 else 255
                    where += range(o + 2, o + last + 1)
                    dt, ds = d[o], d[o + 1]
                return where
        t, s = d[b], d[b + 1]
    sys.exit('dst_test.py: no REL file %s on the disk' % name)


def record(disk, n, text=None):
    """e.data record n: read it (as text, to its Return), or write text"""
    d = bytearray(open(disk, 'rb').read())
    where = rel_bytes(d, 'e.data')[(n - 1) * RECLEN:n * RECLEN]
    assert len(where) == RECLEN, 'e.data has no record %d' % n
    if text is None:
        raw = bytes(d[i] for i in where)
        return ascii_(raw.split(b'\r')[0])
    data = (petscii(text) + b'\r').ljust(RECLEN, b'\0')
    assert len(data) == RECLEN, text
    for i, c in zip(where, data):
        d[i] = c
    open(disk, 'wb').write(d)

# --- x128 -------------------------------------------------------------------

def port_free(port):
    s = socket.socket()
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.bind(('127.0.0.1', port)); return True
    except OSError:
        return False
    finally:
        s.close()


def set_rtc(v):
    """the DS12C887 at $d700: Sunday 11/01/2026 1:55:00 AM, BCD (register B
    as VICE starts it, 0); register B's bit 7 holds the clock while it's set"""
    regs = {0: 0x00, 2: 0x55, 4: 0x01, 6: 0x01, 7: 0x01, 8: 0x11, 9: 0x26, 50: 0x20}
    cmds = ['bank io', '> d700 0b', '> d701 80']
    for r, val in regs.items():
        cmds += ['> d700 %02x' % r, '> d701 %02x' % val]
    v.cmd(*cmds, '> d700 0b', '> d701 00')


def rtc_reg(v, r):
    out = v.cmd('bank io', '> d700 %02x' % r, 'm d701 d701')
    m = re.search(r'>C:d701\s+([0-9a-f]{2})', out)
    return int(m.group(1), 16) if m else None


def set_rtc_sure(v):
    """set_rtc until the RTC reads it back (11/16/2026: set a second after x128
    started, it could be lost, and the BBS booted with the PC's date and time)"""
    for _ in range(20):
        set_rtc(v)
        time.sleep(0.5)
        got = [rtc_reg(v, r) for r in (4, 8, 7, 9)]
        if got == [0x01, 0x11, 0x01, 0x26] and rtc_reg(v, 2) in (0x55, 0x56):
            return True
        time.sleep(0.5)
    return False


def bbs_time(v):
    """the idle screen's status line ("Sun Nov  1, 2026  1:55:20 AM") ->
    (its date and time, minute of the day), or (None, None)"""
    m = re.search(r'(\w{3} \w{3}\s+\d{1,2}, \d{4})\s+(\d{1,2}):(\d\d):\d\d ([AP])M', v.screen(25))
    if not m:
        return None, None
    h = int(m.group(2)) % 12 + 12 * (m.group(4) == 'P')
    return m.group(0), h * 60 + int(m.group(3))


def run_case(name, base, port, keep, full):
    rec46, want_backs = CASES[name]
    disk = os.path.join(repo, 'build', 'dst-test-%s.d81' % name)
    shutil.copyfile(base, disk)
    # the build's im and sub.clocks, not the ones the base disk was made with
    for f in ('im 128', 'sub.clocks'):
        prg = os.path.join(repo, 'build', f + '.prg')
        if os.path.exists(prg):
            subprocess.run(['c1541', '-attach', disk, '-delete', f, '-write', prg, f],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    record(disk, 46, rec46)
    print('case %s: record 46 "%s", the RTC at Sun 11/01/26 1:55 AM' % (name, record(disk, 46)))
    # 11/16/2026: not -autostart: its reset puts the RTC back to the PC's
    # time, and the RTC set before it was lost. The RTC is set at BASIC's
    # READY. prompt, then the boot typed: rU"boot* (RUN, abbreviated to fit
    # the keyboard buffer's 10 keys)
    v = X128(['-drive8type', '1581', '-8', disk, '-ds12c887rtc', '-ds12c887rtcbase', '0xd700',
              '-ds12c887rtcrunning', '-warp'], cols=40, wait=4, port=port)
    t0 = time.time()
    try:
        if not set_rtc_sure(v):
            print('case %s: the DS12C887 at $d700 would not take 1:55 AM' % name)
            return False
        v.cmd('bank ram', '> 034a 52 d5 22 42 4f 4f 54 2a 0d', '> 00d0 09')
        last = None; backs = 0; seen = []; ok = None
        while time.time() - t0 < LIMIT:
            text, now = bbs_time(v)
            # the BBS's clock is set from the RTC at boot: before that,
            # the status line has another date
            # until im reads the RTC (3155), the status line has another date
            # (11/16/2026: "Wed Dec  9, 2026  0:00:13 AM"); 5 minutes without
            # 11/01, or another date after it: the RTC wasn't set in time
            nov1 = now is not None and re.search(r'Nov\s+0?1, 2026', text)
            if not nov1:
                if seen and now is not None or not seen and time.time() - t0 > 300:
                    print('case %s: the BBS clock is at %s, not 11/01/2026' % (name, text))
                    ok = False; break
                time.sleep(1); continue
            if now is not None:
                if now != last:
                    if last is not None and now <= last - 30:
                        backs += 1; print('%6.1f  %s   <- set back' % (time.time() - t0, text))
                    else:
                        print('%6.1f  %s' % (time.time() - t0, text))
                    seen.append(now)
                    if backs > want_backs:
                        ok = False; break
                    # done: past 2:10 with the set-backs it should have had
                    # (case a, unless --full: 1:05, after its set-back)
                    end = 65 if backs and not full else 130
                    if backs == want_backs and now >= end and len(seen) > 1:
                        ok = True; break
                    last = now
            time.sleep(1)
        if ok is None:
            print('case %s: timed out; the screen:' % name)
            print('\n'.join(r for r in v.screen(25).split('\n') if r.strip()))
            ok = False
    finally:
        if keep:
            print('x128 left running (monitor on port %d)' % port)
        else:
            v.cmd('quit', resume=False)
            try:
                v.p.wait(timeout=30)
            except subprocess.TimeoutExpired:
                v.stop()
    after = record(disk, 46)
    good_rec = after.startswith('0,1,' + RULE)
    print('case %s: %d set-back(s) (want %d); record 46 after: "%s" (want "0,1,%s")'
          % (name, backs, want_backs, after, RULE))
    passed = ok and backs == want_backs and good_rec
    print('case %s: %s' % (name, 'PASS' if passed else 'FAIL'))
    return passed


def main():
    args = sys.argv[1:]
    if '-h' in args or '--help' in args:
        print(__doc__); return 0
    opt = lambda k, d: args[args.index(k) + 1] if k in args else d
    case = opt('--case', 'all')
    base = opt('--base', os.path.join(repo, 'build', 'dst-base.d81'))
    port = int(opt('--port', '6537'))
    keep = '--keep' in args
    full = '--full' in args
    if case not in ('a', 'b', 'all'):
        sys.exit('dst_test.py: --case a, b or all')
    if not port_free(port):
        sys.exit('dst_test.py: an x128 already has monitor port %d: quit it, or --port another' % port)
    if '--fresh' in args or not os.path.exists(base):
        print('making', os.path.relpath(base, repo), 'with tools/setup_test.py (several minutes)')
        r = subprocess.run([sys.executable, os.path.join(repo, 'tools', 'setup_test.py'),
                            '--out', base, '--port', str(port)], stdout=subprocess.DEVNULL)
        if r.returncode:
            sys.exit('dst_test.py: setup_test.py failed')
    names = ['a', 'b'] if case == 'all' else [case]
    results = [run_case(n, base, port, keep and n == names[-1], full) for n in names]
    return 0 if all(results) else 1


if __name__ == '__main__':
    sys.exit(main())
