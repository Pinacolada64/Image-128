#!/usr/bin/env python3
"""ltk_clock.py: ++ ltk clock on an x128 with an emulated DS1216 SmartWatch.

    asm/build.sh ml
    tools/standin.sh tests/standin/ltkclock.bas
    X128=/path/to/patched/src/x128 tools/ltk_clock.py 1     # or 2

Needs an x128 built with tools/vice/ds1216-smartwatch (its README); X128
names it (default: x128 on the PATH, which won't have the device unless
it's patched). Runs tests/standin/ltkclock.bas with the SmartWatch on
control port 1 or 2 (0: none): the stand-in's own checks must pass, the
port with the clock must read today's date and time (the host's, give or
take a minute: z$'s digits, its hour 1-12 with 80 more after noon), and
the other port non-digits. Prints the reads and "passed" or what went wrong.
"""
import os, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import vmon

repo = os.path.dirname(here)
X = os.environ.get('X128', 'x128')
PORT = int(os.environ.get('VMON_PORT', '6602'))
cp = sys.argv[1] if len(sys.argv) > 1 else '2'


class X128(vmon.X128):
    def __init__(self, args, port):
        self.port = port
        self.p = subprocess.Popen([X, '-40col', '+sound', '-remotemonitor', '-remotemonitoraddress',
                                   f'127.0.0.1:{port}', *args],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(4)


def zdate(t):
    """z$ as Image has it, without the weekday: yymmdd, hour (+80 after noon), minute"""
    h = t.tm_hour
    c = 92 if h == 12 else 12 if h == 0 else h + 80 - 12 if h > 12 else h
    return time.strftime('%y%m%d', t) + f'{c:02d}{t.tm_min:02d}'


args = ['-drive8type', '1581']
if cp != '0':
    args += [f'-controlport{cp}device', 'smartwatch']
v = X128(args + ['-autostart-warp', '-autostart',
                 os.path.join(repo, 'build', 'standin-ltkclock.d81') + ':boot 128'], PORT)
try:
    for i in range(80):
        s = v.screen()
        if 'port 1 read' in s:
            break
        time.sleep(3)
    time.sleep(2)
    s = v.screen()
    now = time.localtime()
    print(s)
    problems = []
    if 'all passed' not in s:
        problems.append("the stand-in's checks")
    reads = {p: '' for p in '12'}
    for line in s.splitlines():
        for p in '12':
            if line.startswith(f'port {p} read: '):
                reads[p] = line.split(': ', 1)[1].strip()
    want = {zdate(now), zdate(time.localtime(time.time() - 60))}
    for p in '12':
        r = reads[p]
        if p == cp:
            if not (len(r) == 11 and r.isdigit() and r[1:] in want):
                problems.append(f'port {p} read {r!r}, not now ({sorted(want)})')
        elif r.isdigit():
            problems.append(f'port {p} read digits with no clock there: {r!r}')
    print('passed' if not problems else 'problems: ' + '; '.join(problems))
    sys.exit(0 if not problems else 1)
finally:
    v.stop()
