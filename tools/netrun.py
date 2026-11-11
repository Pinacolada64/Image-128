#!/usr/bin/env python3
"""netrun.py: run NetMail nodes ONE and TWO (tools/netnodes.py's disks), each
in its own x128 with its own tcpser, and have ONE call TWO.

    tools/netnodes.py           (makes the node disks; again for a fresh start)
    tools/netrun.py [--timeout 900] [--keep] [--no-call]

Each node is booted like start-image-128.sh's BBS (SwiftLink at $de00 to
tcpser, ip232; the DS12C887 at $d700), with drive 8 the node disk and, if
netnodes.py made one, device 9 its CMD HD (start-setup.sh -hd's: type
4844, the boot ROM from ROMs/), in 40 columns so the monitor can read its screen. Each tcpser's
phonebook has the other node: ONE dials 2222002, which its tcpser makes
127.0.0.1:6132, TWO's; TWO's maps 1111001 to ONE's 6131.

    node  modem port  telnet port  monitor  disk
    ONE   25261       6131         6541     build/node-one.d81, .dhd
    TWO   25262       6132         6542     build/node-two.d81, .dhd

Once both are at the idle screen (BASIC running i/lo.idle's loop), it sets
the lightbar's NetMail Enable (28) on both, and NetMail Trigger (29) on
ONE (Invert DCD, 58, off on both), which then starts NetMaint (i/lo.idle 4211); TWO answers when ONE's
Ctrl-A arrives (i.lo 3556). It prints both screens as they change, until
both are back at the idle screen after the call, or --timeout seconds.

Afterwards it lists what's on each disk: the mail TWO's sysop got
(m.IMAGE SYSOP), the logs and anything left in the queues. Logs:
build/tcpser-one.log, build/tcpser-two.log. --keep leaves both running
(their monitors on 6541 and 6542); --no-call doesn't set the trigger.
"""
import argparse, os, re, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

TCPSER = os.environ.get('TCPSER', os.path.expanduser('~/bin/tcpser/tcpser'))
JIFFY = os.environ.get('JIFFYDOS', os.path.expanduser('~/Documents/c64/JiffyDOS'))
HDROM = 'ROMs/cmd_hd_bootrom_v2.80.bin'   # not in git: CMD's
CHKTBL_NET = 0x1303
CHKTBL_DCD = 0x1307          # bit 2: Invert DCD (flag 58)
TIMESET = 0x18b6               # "time has been set" (i/lo.idle 4211 needs it)          # chktbl+3: bit 4 NetMail enable (28), bit 5 trigger (29)
NODES = {
    'one': dict(modem=25261, telnet=6131, mon=6541, dial={'2222002': 6132}),
    'two': dict(modem=25262, telnet=6132, mon=6542, dial={'1111001': 6131}),
}


def port_in_use(p):
    return f':{p} ' in subprocess.run(['ss', '-ltn'], capture_output=True, text=True).stdout


def basic_line(v):
    return int.from_bytes(v.mem('ram00', 0x3b, 2), 'little')


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--timeout', type=int, default=900)
    ap.add_argument('--keep', action='store_true')
    ap.add_argument('--no-call', action='store_true')
    args = ap.parse_args()
    os.chdir(repo)
    for n, c in NODES.items():
        for p in (c['modem'], c['telnet'], c['mon']):
            if port_in_use(p):
                sys.exit(f'netrun.py: port {p} ({n}) is in use')
        for d in (f'build/node-{n}.d81',) + ((HDROM,) if os.path.exists(f'build/node-{n}.dhd') else ()):
            if not os.path.exists(d):
                sys.exit(f'netrun.py: no {d}' + ('' if d == HDROM else ': run tools/netnodes.py'))
    procs, machines = [], {}
    try:
        for n, c in NODES.items():
            cmd = [TCPSER, '-s', '19200', '-v', f'127.0.0.1:{c["modem"]}', '-p', str(c['telnet']),
                   '-l', '4', '-t', 'sS', '-L', f'build/tcpser-{n}.log']   # sS: the AT commands and replies
            for num, port in c['dial'].items():
                cmd += ['-n', f'{num}=127.0.0.1:{port}']
            procs.append(subprocess.Popen(cmd))
        time.sleep(1)
        jiffy = []
        if os.path.exists(os.path.join(JIFFY, 'JDOS128.rom')):
            jiffy = ['-kernal', os.path.join(JIFFY, 'JDOS128.rom'),
                     '-dos1581', os.path.join(JIFFY, 'Jiffy1581.rom')]
        for n in ('two', 'one'):                 # the answering node first
            c = NODES[n]
            hd = (['-drive9type', '4844', '-dosCMDHD', HDROM, '-9', f'build/node-{n}.dhd']
                  if os.path.exists(f'build/node-{n}.dhd') else [])
            machines[n] = X128(['-ntsc', '-drive8type', '1581', *jiffy, *hd,
                                '-ds12c887rtc', '-ds12c887rtcbase', '0xd700', '-ds12c887rtcrunning',
                                '-acia1', '-acia1base', '0xde00', '-acia1mode', '1', '-acia1irq', '1',
                                '-myaciadev', '2', '-userportdevice', '0',
                                '-rsdev3', f'127.0.0.1:{c["modem"]}', '-rsdev3ip232', '-rsdev3baud', '19200',
                                '-autostart-warp', '-autostart', f'build/node-{n}.d81:boot 128'],
                               cols=40, wait=2, port=c['mon'])
        # wait for both idle screens: i/lo.idle's loop (lines 4200-4299)
        t0 = time.time()
        idle = set()
        while len(idle) < 2 and time.time() - t0 < 300:
            time.sleep(5)
            for n, v in machines.items():
                if 4200 <= basic_line(v) < 4300:
                    idle.add(n)
        print(f'idle: {sorted(idle)} after {int(time.time() - t0)} s', flush=True)
        if len(idle) < 2:
            for n, v in machines.items():
                print(f'--- {n} (line {basic_line(v)})')
                print('\n'.join(l.rstrip() for l in v.screen(25).split('\n') if l.strip()))
            raise SystemExit('netrun.py: not both at the idle screen')
        time.sleep(5)
        for n, v in machines.items():
            mask = 0x10 | (0x20 if n == 'one' and not args.no_call else 0)
            b = v.mem('ram00', CHKTBL_NET, 1)[0] | mask
            # timeset 1 too: the copies' clocks haven't been set, and i/lo.idle
            # 4211 starts NetMaint only once one has
            # Invert DCD (flag 58, chktbl+7 bit 2; the idle screen's T) off: with
            # it on, a node reads a live call as no carrier and hangs up (ONE did,
            # 11/10/2026, right after its first Ctrl-A)
            d = v.mem('ram00', CHKTBL_DCD, 1)[0] & ~0x04
            v.cmd('bank ram', f'> {CHKTBL_NET:04x} {b:02x}', f'> {TIMESET:04x} 01',
                  f'> {CHKTBL_DCD:04x} {d:02x}')
            print(f'{n}: chktbl+3 = ${b:02x}', flush=True)
        # watch both screens until they've been through a call and are idle
        last, busy, t0 = {}, set(), time.time()
        while time.time() - t0 < args.timeout:
            time.sleep(10)
            for n, v in machines.items():
                line = basic_line(v)
                scr = '\n'.join(l.rstrip() for l in v.screen(25).split('\n')[:23] if l.strip())
                if 3000 <= line < 4000:     # i.NM_auto (an i. module) is running
                    busy.add(n)
                scr += '\n[%s] timeset %d, chktbl+3 $%02x' % (
                    v.screen(25).split('\n')[24].strip(), v.mem('ram00', TIMESET, 1)[0],
                    v.mem('ram00', CHKTBL_NET, 1)[0])
                if scr != last.get(n):
                    last[n] = scr
                    print(f'--- {n} (line {line}, {int(time.time() - t0)} s)\n{scr}', flush=True)
            if busy >= {'one'} and all(4200 <= basic_line(v) < 4300 for v in machines.values()):
                print('both idle again', flush=True)
                break
    finally:
        if not args.keep:
            for v in machines.values():
                try:
                    v.cmd('quit', resume=False)
                except Exception:
                    pass
            time.sleep(2)
            for p in procs:
                p.terminate()
    if not args.keep:
        for n in NODES:
            out = subprocess.run(['c1541', f'build/node-{n}.d81', '-list'], capture_output=True,
                                 text=True).stdout
            print(f'=== node {n}:')
            print('\n'.join(l for l in out.split('\n') if re.search(r'"(nm\.|m\.)', l)))


if __name__ == '__main__':
    main()
