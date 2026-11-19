#!/usr/bin/env python3
"""ltk_primetime.py: try IM's Prime Time screen (i.IM, i/IM.misc) on a
configured Image BBS 128 on VICE's Lt. Kernal.

    tools/ltk_primetime.py [--from DIR] [--port N] [--keep] [--verbose]

Boots a copy (build/ltk-primetime/) of a configured system's drive images:
DIR, default build/ltk-configured (tools/ltk_bbs2.py's: Image on LU 5,
its System and Etcetera drives on LU 6; ltk.crt from LTK DIR, as
tools/ltk_chatmode.py). LU 5, LOAD"BOOT 128",8 and RUN at the Lt. Kernal's
prompt; at the idle screen, I (IM Configurator: i.IM as the local sysop,
no login), I (Misc. Features), M (Prime Time). Then, checking the screen
after each:

    1, 60    Minutes/Call 60
    2, 12P   Start Time 12PM (noon: 12P was stored as 24, which never matched)
    3, 12A   End Time 12AM (midnight)
    2, 1p    Start Time 1PM (an unshifted p, as typed without shift)
    3, 13    End Time 1PM (a number alone is 24-hour)
    2, 12P   Start Time 12PM
    3, 11P   End Time 11PM
    Return   Changes Saved; Misc. Features' M line says " 60, 12P-11P"

Keys: the idle screen's I goes in idlekey (asm/ml.sym) as shifted PETSCII
($c9), not the keyboard buffer; menu letters and the A and P typed at the
time prompts are shifted too (a capital, as typed with shift). To update a
configured system's modules first: tools/ltk_copy.py --images DIR --lu 5
i.IM i/IM.misc --save. Prints "passed", or what was wrong.

Passed 11/17/2026 on chatmode-bbs-test's build/ltk-configured, about two
minutes.
"""
import os, re, shutil, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
args = sys.argv[1:]
src = os.path.join(repo, 'build', 'ltk-configured')
if '--from' in args:
    src = args[args.index('--from') + 1]
port = int(args[args.index('--port') + 1]) if '--port' in args else 6620
keep = '--keep' in args
verbose = '--verbose' in args
work = os.path.join(repo, 'build', 'ltk-primetime')
os.makedirs(work, exist_ok=True)
for f in ('disk0.dlk', 'disk1.dlk', 'disk2.dlk'):
    if not os.path.exists(os.path.join(src, f)):
        sys.exit(f'ltk_primetime.py: no {f} in {src}: a configured system (tools/ltk_bbs2.py)')
    shutil.copyfile(os.path.join(src, f), os.path.join(work, f))


def sym(name):
    """an address from asm/ml.sym (asm/build.sh writes it)"""
    for l in open(os.path.join(repo, 'asm', 'ml.sym')):
        m = re.match(r'(\S+)\s*=\s*\$([0-9a-f]+)', l)
        if m and m.group(1) == name:
            return int(m.group(2), 16)
    sys.exit('ltk_primetime.py: no %s in asm/ml.sym: run asm/build.sh' % name)


IDLEKEY = sym('idlekey')
t0 = time.time()


def shift(s):
    """capitals as shifted PETSCII ($c1-$da), as typed with shift"""
    return ''.join(chr(ord(c) + 0x80) if 'A' <= c <= 'Z' else c for c in s)


v = X128(['+saveres', '-cartcrt', os.path.join(LTK, 'ltk.crt'), '-ltkport', '0',
          '-ltkimage0', os.path.join(work, 'disk0.dlk'),
          '-ltkimage1', os.path.join(work, 'disk1.dlk'),
          '-ltkimage2', os.path.join(work, 'disk2.dlk'),
          '-drive8type', '0',
          '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
          '-warp'], cols=80, wait=4, port=port)


def scr():
    return v.screen(25)


def line():
    return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')


def show(what):
    print(f'--- {time.time() - t0:6.1f} {what} (line {line()})', flush=True)
    for i, r in enumerate(scr().split('\n')):
        if r.strip():
            print('%2d|%s' % (i, r.rstrip()))


def sees(text):
    return text.lower() in scr().lower()


def until(cond, secs, what, every=2):
    t = time.time()
    while time.time() - t < secs:
        if cond():
            return
        time.sleep(every)
    show('timed out: ' + what)
    sys.exit(1)


def step(keys, wait_for, what, secs=60):
    v.type(keys)
    until(lambda: sees(wait_for), secs, what)
    time.sleep(2)
    if verbose:
        show(what)


def field(name):
    """the value after "name" on the Prime Time screen ("Start Time  : 12PM")"""
    m = re.search(re.escape(name) + r'\s*:\s*(\S+)', scr(), re.I)
    return m.group(1) if m else None


bad = []


def check(what, minutes, start, end):
    got = (field('Minutes/Call'), field('Start Time'), field('End Time'))
    ok = got == (minutes, start, end)
    print(f'{"ok  " if ok else "BAD "} {what}: {" / ".join(str(g) for g in got)}', flush=True)
    if not ok:
        bad.append(f'{what}: {got}, not {(minutes, start, end)}')
        show(what)


try:
    until(lambda: sees('c128 d#08'), 120, 'the Lt. Kernal prompt')
    v.type('LU 5\r'); time.sleep(3)
    v.type('LOAD"BOOT 128",8\r'); time.sleep(8)
    v.type('RUN\r')
    until(lambda: 4200 <= line() < 4300, 600, 'the idle screen', every=4)
    print(f'--- {time.time() - t0:6.1f} idle screen', flush=True)
    time.sleep(5)
    v.cmd('bank ram', f'> {IDLEKEY:04x} c9')
    until(lambda: sees('misc'), 180, 'the IM menu (the idle screen\'s I)')
    time.sleep(2)
    step(shift('I'), 'prime time:', 'Misc. Features')
    step(shift('M'), 'minutes/call', 'the Prime Time screen')
    show('the Prime Time screen, as it was')
    # (option, what's typed as it's written here: a capital is typed shifted,
    # what the screen should then show)
    for opt, label, expect in (
            ('1', '60', ('60', None, None)),
            ('2', '12P', (None, '12PM', None)),
            ('3', '12A', (None, None, '12AM')),
            ('2', '1p', (None, '1PM', None)),
            ('3', '13', (None, None, '1PM')),
            ('2', '12P', (None, '12PM', None)),
            ('3', '11P', (None, None, '11PM'))):
        before = (field('Minutes/Call'), field('Start Time'), field('End Time'))
        prompt = {'1': 'minutes/call:', '2': 'start time:', '3': 'end time:'}[opt]
        step(opt + '\r', prompt, f'option {opt}')
        step(shift(label) + '\r', 'end time', f'{opt}, {label}')
        want = tuple(e if e is not None else b for e, b in zip(expect, before))
        check(f'option {opt}, {label}', *want)
    v.type('\r')
    until(lambda: sees('changes saved'), 60, 'Changes Saved')
    v.type(' ')
    until(lambda: sees('prime time:'), 60, 'back at Misc. Features')
    time.sleep(2)
    m = re.search(r'Prime Time:\s*(.*\S)', scr())
    menu = m.group(1) if m else None
    ok = menu == '60, 12P-11P'
    print(f'{"ok  " if ok else "BAD "} Misc. Features: Prime Time: {menu}', flush=True)
    if not ok:
        bad.append(f'Misc. Features: {menu!r}, not "60, 12P-11P"')
        show('Misc. Features')
finally:
    if not keep:
        v.stop()

print('passed' if not bad else 'failed:\n  ' + '\n  '.join(bad))
sys.exit(1 if bad else 0)
