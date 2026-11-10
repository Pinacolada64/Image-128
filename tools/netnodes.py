#!/usr/bin/env python3
"""netnodes.py: two NetMail nodes for testing, ONE and TWO, made from copies
of a configured BBS on a CMD HD (the sources are only read).

    tools/netnodes.py [--src build/net-base.d81] [--hd build/net-base.dhd|none]
                      [--port 6540]

Writes build/node-one.d81 and build/node-two.d81 (copies of --src), and
build/node-one.dhd and build/node-two.dhd (copies of --hd, the CMD HD image
--src is used with as device 9: its bd.data puts the Etcetera drive there,
and e.data the other drives). The defaults, build/net-base.d81 and .dhd, are
a BBS set up with setup_test.py on 11/07/2026 (boot disk 8, its drives on
the HD's partitions), which boots to the idle screen. On each, a BASIC program (netinit, run in an x128 and then
scratched) finds Image drive 2, E-Mail, as im does at boot, and writes the
network's files there the way i/IM.netmail does, with the same
statements, but the test's values:

- nm.create: the network, two nodes (as the administrator's file would be)
- nm.nodes and nm.nodelist: from it (i/IM.netmail 4518-4542, 4076-4082)
- nm.config: the node's number, its password, the modem (19200), the
  calling hours (4562-4572)
- nm.connect: the other node as the first standard connection, with its
  password, all day every day, no limit on calls (4586-4590)
- the modem as IM's Modem Config sets it up: nimodem.dat from i/IM.modem's
  profiles, then "tcpser (VICE)" from it into e.i.modem and e.data record
  32 (the SwiftLink), with auto-answer; e.data record 37, the DS12C887 at
  $d700 for the clock
- i.NM/auto on the Module drive, copied from the boot disk if it's not
  there (the base HD's setup left it out)
- on ONE only: a NetMail message to TWO's sysop (nm.M.TWO/ONE, written as
  i/MM.sb-mail 4048-4056 writes one) and its line in nm.list

Nodes (NETWORK.md, "Nodes and how a call goes"):

    node  ID   phone    password  BBS
    1     ONE  1111001  ONEPW     NODE ONE
    2     TWO  2222002  TWOPW     NODE TWO

The phones are what each tcpser's phonebook maps to the other node
(tools/netrun.py): nm.create is read with INPUT#, which stops at a colon,
so a host:port can't be a phone number; and i.NM_auto drops a phone's
first three characters when they're the same as its own node's (an area
code), so the two start differently.

x128 runs with its monitor on --port (default 6540: not the BBS's 6537 or
the stand-ins' 6538). Needs asm/build.sh's build (the ML on the disk).
"""
import argparse, os, shutil, subprocess, sys, time

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(repo, 'tools'))
from vmon import X128

RUN_DISK = os.path.join(repo, 'build', 'setup-test.d81')   # never an output
BASE = os.path.join(repo, 'build', 'net-base.d81')
HDROM = os.path.join(repo, 'ROMs', 'cmd_hd_bootrom_v2.80.bin')   # not in git: CMD's
DATE = '22611091200'   # d1$-style: Monday 11/09/26 12:00 PM

NODES = [
    # number, ID, phone, password, BBS name, its connections
    (1, 'ONE', '1111001', 'ONEPW', 'NODE ONE', (2, 0, 0, 0)),
    (2, 'TWO', '2222002', 'TWOPW', 'NODE TWO', (1, 0, 0, 0)),
]
SYSOP = 'IMAGE SYSOP'   # the run disk's user 1, on both


def basic(node):
    """netinit for node (a NODES entry), as petcat source: lowercase is
    PETSCII $41-$5a (Image's lowercase file names), capitals $c1-$da (as
    typed: node IDs, passwords, handles)"""
    num, nid, phone, pw, bbs, conns = node
    other = [n for n in NODES if n[0] != num][0]
    L = []
    def add(s): L.append(s)
    # Image drive 2 (E-Mail): bd.data on the boot disk gives the Etcetera
    # drive, and e.data's record 53 there gives drive 2's device and drive
    # (im 3086-3094)
    add('10 r$=chr$(13):d1$="%s"' % DATE)
    add('11 open 2,8,2,"0:bd.data,s,r":input#2,dv,d:close 2')
    # the CMD HD needs a while after power-on (its boot ROM): wait until its
    # command channel answers with 73 (the DOS version) or 0
    add('12 sleep 5:open 15,dv,15:input#15,e,e$:print "device";dv;e;e$:if e<>73 and e<>0 then close 15:goto 12')
    add('14 open 2,dv,2,mid$(str$(d),2)+":e.data":input#15,e,e$:print "e.data";e;e$')
    add('15 x=53:gosub 900:input#2,a$,b$:e1=val(a$):e2=val(b$):x=56:gosub 900:input#2,m$,n$')
    # e.data: record 32 the RS-232 interface, 1 the SwiftLink (im 3095; the
    # base BBS has 0, the user port, which x128 has off here); record 37 the
    # clock, the DS12C887 at $d700 (sub.clocks' "4,d,55040"), as netrun.py
    # starts x128 with one
    # e.data record 37: the clock, the DS12C887 at $d700 (sub.clocks'
    # "4,d,55040"), as netrun.py starts x128 with one
    add('16 x=37:gosub 900:print#2,"4,d,55040":close 2')
    # the modem, as IM's Modem Config does it: nimodem.dat written from
    # i/IM.modem's own profiles (its option 4: lines 4860-4866, DATA
    # 4900-4990), "tcpser (VICE)" read back from it (the import, 4620-4622),
    # then e.data record 32 (the interface: its flag 11, 1 the SwiftLink;
    # i/IM.modem 4028) and e.i.modem record 1 (port 0: flags, init string,
    # name, author; 4510). Flag 3 is A (auto-answer, s0=1: tcpser answers and
    # the BBS sees the carrier), not the profile's M (the BBS sends ATA on a
    # RING): that needs the profile's result codes in e.modem, a struct the
    # import saves with &,60,3, which this can't (the ML isn't loaded here)
    add('17 p3$=mid$(str$(d),2)+":":print#15,"s"+p3$+"nimodem.dat":open 3,dv,3,p3$+"nimodem.dat,s,w":gosub 860:close 3')
    add('18 open 3,dv,3,p3$+"nimodem.dat,s,r":gosub 880:close 3:mt$=left$(u$,2)+"A"+mid$(u$,4):print "modem: ";g$;" ";mt$')
    add('19 open 2,dv,2,p3$+"e.data":x=32:gosub 900:print#2,mid$(mt$,11,1):close 2:open 2,dv,2,p3$+"e.i.modem,l,"+chr$(100):x=1:gosub 900:print#2,mt$r$v$r$g$r$h$:close 2:close 15')
    add('20 dv=e1:p$=mid$(str$(e2),2)+":":open 15,dv,15:print "e-mail drive";dv;p$')
    names = ['nm.create', 'nm.nodes', 'nm.nodelist', 'nm.config', 'nm.connect', 'nm.list',
             'nm.M.%s/%s' % (other[1], nid)]
    add('21 restore:for i=1 to %d:read f$:print#15,"s"+p$+f$:next' % len(names))
    add('30 data ' + ','.join(names))
    # nm.create: the network (10 values a node, as i/IM.netmail reads it)
    add('100 open 2,dv,2,p$+"nm.create,s,w"')
    for i, n in enumerate(NODES):
        c = n[5]
        add('%d print#2,%d;r$"%s"r$"%s"r$"%s"r$"%s"r$0;r$%d;r$%d;r$%d;r$%d' %
            (110 + i, n[0], n[1], n[2], n[4], SYSOP, *c))
    add('190 close 2')
    # nm.nodes from nm.create: i/IM.netmail 4530-4542
    add('200 open 3,dv,3,p$+"nm.create,s,r":open 2,dv,2,p$+"nm.nodes,l,"+chr$(100):n=0')
    add('210 input#3,a,a$,b$,c$,d$,o%,a%,b%,c%,d%:s=st')
    add('220 x=a+1:gosub 900:print#2,a$r$b$r$c$r$d$r$o%r$a%r$b%r$c%r$d%')
    add('230 if a>n then n=a:x=1:gosub 900:print#2,n')
    add('240 if s=0 then 210')
    add('250 close 2:close 3')
    # nm.nodelist: i/IM.netmail 4076-4084
    add('300 open 2,dv,2,p$+"nm.nodes,l,"+chr$(100):open 3,dv,3,p$+"nm.nodelist,p,w"')
    add('310 print#3,chr$(0)chr$(194);:x=1:gosub 900:input#2,n:print#3,chr$(n);')
    add('320 for i=1 to n:x=i+1:gosub 900:input#2,a$,b$,b$,b$,b$,a,b,c,d')
    add('330 print#3,left$(a$+"---",3)chr$(0)chr$(a)chr$(b)chr$(c)chr$(d);:next')
    add('340 close 3:close 2')
    # nm.config: i/IM.netmail 4562-4572 (the password set, not {f2}; 19200)
    add('400 open 2,dv,2,p$+"nm.config,l,z"')
    add('410 x=1:gosub 900:print#2,%d;r$1022;r$"%s"r$"900610"' % (num, pw))
    add('420 x=2:gosub 900:print#2,19200;r$r$r$"atdt"')
    add('430 x=3:gosub 900:a$="":for i=0 to 9:a$=a$+"2306"+r$:next:print#2,a$;')
    add('440 x=4:gosub 900:print#2,"TEST"r$"VI"')
    add('450 x=1:gosub 900:close 2')
    # nm.connect: i/IM.netmail 4586-4590, the other node's password set,
    # all day (+) every day, calls unlimited (+)
    add('500 open 2,dv,2,p$+"nm.connect,l,"+chr$(100)')
    add('510 x=1:gosub 900:print#2,"%s"r$"%s"r$"+++++++"r$r$"+++++++"r$"0"r$"0"r$d1$r$d1$'
        % (other[1], other[3]))
    add('520 for x=2 to 4:gosub 900:print#2,"^"r$"{f2}"r$"-------"r$r$"0000000"r$"0"r$"0"r$d1$r$d1$:next')
    add('530 x=5:gosub 900:print#2,0:gosub 900:x=1:gosub 900:close 2')
    if num == 1:
        # a NetMail message for TWO's sysop: i/MM.sb-mail 4048-4056
        f = 'nm.M.%s/%s' % (other[1], nid)
        add('600 open 2,dv,2,p$+"%s,s,w"' % f)
        add('610 print#2,"%s"r$"%s"r$0r$d1$' % (SYSOP, SYSOP))
        add('620 print#2,"!"left$(str$(%d)+"    ",4)left$("%s"+"                    ",20)"[Network test]"'
            % (num, bbs))
        add('630 print#2,"Hello from node %s.":print#2,"^":close 2' % nid)
        add('640 open 2,dv,2,p$+"nm.list,s,w":print#2,"%s/%s/A/%s":close 2' % (other[1], nid, f))
    # i.NM/auto on the Module drive (e.data record 56), copied from the boot
    # disk if it isn't there (the base HD's setup didn't copy it)
    add('700 dm=val(m$):pm$=mid$(str$(val(n$)),2)+":":open 14,dm,15')
    add('710 open 3,dm,3,pm$+"i.NM/auto,p,r":input#14,e,e$:close 3:if e=0 then 770')
    add('720 print "copying i.NM/auto to";dm;pm$:open 3,8,3,"0:i.NM/auto,p,r":open 4,dm,4,pm$+"i.NM/auto,p,w"')
    add('730 get#3,a$:s=st:if a$="" then a$=chr$(0)')
    add('740 print#4,a$;:if s=0 then 730')
    add('750 close 4:close 3:input#14,e,e$:print "copied:";e;e$')
    add('770 close 14')
    add('800 close 15:print "netinit done":end')
    # nimodem.dat's writer and reader: i/IM.modem 4860-4866 and 4620-4624
    add('860 restore 910')
    add('862 read g$:if g$="^" then print#3,"^":return')
    add('864 read h$,u$,v$,n:print#3,g$r$h$r$u$r$v$r$mid$(str$(n),2)')
    add('866 for u=1 to n:read k,f,a$:print#3,mid$(str$(k),2)r$mid$(str$(f),2)r$a$:next:goto 862')
    add('880 input#3,g$,h$,u$,v$,n:if g$="tcpser (VICE)" or st then return')
    add('882 for u=1 to 3*n:input#3,a$:next:goto 880')
    # position a REL record (channel 2, record x): im line 1's "p" command
    add('900 print#15,"p"chr$(98)chr$(x and 255)chr$(x/256)chr$(1):return')
    # i/IM.modem's profiles (4902-4990), its "nimodem.dat" marker left out
    add('910 data "tcpser (VICE)","Jim Brain","6DMNH0H4N11000","^",5')
    add('912 data 1,7,"CONNECT",2,1,"RING",3,0,"NO CARRIER",4,0,"ERROR",14,7,"CONNECT 19200"')
    add('914 data "Generic Hayes 2400","Image BBS docs","3DMNH0H4N10000","m0&c1&d2",9')
    add('916 data 1,2,"CONNECT",2,1,"RING",3,0,"NO CARRIER",4,0,"ERROR",5,3,"CONNECT 1200"')
    add('918 data 6,0,"NO DIALTONE",7,0,"BUSY",8,0,"NO ANSWER",10,4,"CONNECT 2400"')
    add('920 data "Generic Hayes 19.2k","Image BBS docs","6DMNH0H4N11000","m0&c1&d2",12')
    add('922 data 1,2,"CONNECT",2,1,"RING",3,0,"NO CARRIER",4,0,"ERROR",5,3,"CONNECT 1200"')
    add('924 data 6,0,"NO DIALTONE",7,0,"BUSY",8,0,"NO ANSWER",10,4,"CONNECT 2400"')
    add('926 data 11,5,"CONNECT 4800",12,6,"CONNECT 9600",16,7,"CONNECT 19200"')
    add('928 data "^"')
    return '\n'.join(L) + '\n'


def c1541(disk, *args):
    r = subprocess.run(['c1541', disk, *args], capture_output=True, text=True)
    return r.stdout + r.stderr


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--src', default=BASE)
    ap.add_argument('--hd', default=os.path.join(repo, 'build', 'net-base.dhd'),
                    help='the CMD HD image --src uses as device 9, or none (a BBS on one disk)')
    ap.add_argument('--port', type=int, default=6540)
    args = ap.parse_args()
    build = os.path.join(repo, 'build')
    tmp = os.environ.get('CLAUDE_JOB_DIR', build)
    for node in NODES:
        nid = node[1].lower()
        disk = os.path.join(build, 'node-%s.d81' % nid)
        sdisk = os.path.join(build, 'node-%s.dhd' % nid)
        hd = args.hd.lower() != 'none'
        for d in (disk, sdisk):
            if os.path.abspath(d) in (os.path.abspath(args.src), os.path.abspath(args.hd) if hd else '',
                                      os.path.abspath(RUN_DISK)):
                sys.exit('netnodes.py: %s is a source disk, not an output' % d)
        shutil.copyfile(args.src, disk)
        if hd:
            shutil.copyfile(args.hd, sdisk)
        elif os.path.exists(sdisk):
            os.remove(sdisk)              # netrun.py attaches an HD if there's one
        src = os.path.join(tmp, 'netinit-%s.bas' % nid)
        prg = os.path.join(tmp, 'netinit-%s.prg' % nid)
        open(src, 'w').write(basic(node))
        subprocess.run(['petcat', '-w70', '-l', '1c01', '-o', prg, '--', src], check=True)
        c1541(disk, '-write', prg, 'netinit')
        hdargs = ['-drive9type', '4844', '-dosCMDHD', HDROM, '-9', sdisk] if hd else []
        v = X128(['-drive8type', '1581', *hdargs, '-warp', '-autostart', disk + ':netinit'],
                 cols=40, wait=2, port=args.port)
        try:
            done = False
            for _ in range(240):
                time.sleep(1)
                scr = v.screen(25)
                if 'netinit done' in scr:
                    done = True
                    break
                if '?' in scr and 'error' in scr:
                    break
            print('--- node %s' % node[1])
            print('\n'.join(l for l in scr.split('\n') if l.strip()))
        finally:
            v.cmd('quit', resume=False)
            # the next node's x128 takes the same monitor port: wait for it
            for _ in range(30):
                if f':{args.port} ' not in subprocess.run(['ss', '-ltn'], capture_output=True,
                                                          text=True).stdout:
                    break
                time.sleep(1)
        if not done:
            sys.exit('netnodes.py: netinit on %s didn\'t finish' % disk)
        c1541(disk, '-delete', 'netinit')
        r = subprocess.run([sys.executable, os.path.join(repo, 'tools', 'diskcheck.py'), disk],
                           capture_output=True, text=True)
        print(r.stdout.strip().split('\n')[-1])


if __name__ == '__main__':
    main()
