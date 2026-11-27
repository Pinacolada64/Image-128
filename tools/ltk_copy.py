#!/usr/bin/env python3
"""ltk_copy.py: copy files from a 1581 disk onto an LU of VICE's Lt. Kernal.

    asm/build.sh
    tools/ltk_copy.py [--lu N] [--source disk.d81] [--images DIR] [--save] [--keep] FILE...

e.g. tools/ltk_copy.py i.IM i/IM.misc --save

Runs tests/standin/ltkcopy.bas with the Lt. Kernal at device 8 (booted in
128 mode, as tools/ltk_chatmode.py) and build/standin-ltkcopy.d81 as a
1581 at device 9: a copy of the source disk (build/image128.d81, or
--source; it has to boot, so one asm/build.sh made) with the stand-in as
"im 128" and ltkcopy.list, the LU and the files to copy. Each FILE is
scratched on the LU, copied with ++ copier and compared (&,16,3).
"im 128" works too: the stand-in has that name on its disk, so the real
one goes there as "im 128.real" and is copied to the LU as "im 128".

FILE is the name as c1541 lists it: a capital letter is a shifted one
(i.IM is "i." and shifted I and M). The LU is 10 (the one the Lt. Kernal
logs in to at power-on) unless --lu says otherwise.

The run uses copies of LTK DIR's drive images (ltk_chatmode.py's header has
what they are), made fresh each time in build/ltk-copy/, so the originals
don't change. --save, if every file copied: each image the run changed
replaces LTK DIR's, after the old one is kept as <image>.before-<date>-<time>.
--images DIR takes the drive images from DIR instead (and --save puts them
back there), e.g. a configured system's (tools/ltk_bbs2.py's
build/ltk-configured: Image on LU 5, so --lu 5); ltk.crt still comes from
LTK DIR. VICE keeps the images with every byte inverted (XOR $ff).
--keep leaves x128 running at the end.
"""
import filecmp, os, re, shutil, subprocess, sys, time
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from vmon import X128

repo = os.path.dirname(here)
LTK = os.path.expanduser(os.environ.get('LTK_DIR', '~/Documents/c64/ltkernal/ltk128-images'))
work = os.path.join(repo, 'build', 'ltk-copy')
build = os.path.join(repo, 'build')
disk = os.path.join(build, 'standin-ltkcopy.d81')
PORT = int(os.environ.get('VMON_PORT', '6603'))
IMAGES = ('disk0.dlk', 'disk1.dlk', 'disk2.dlk')
REAL_IM = 'im 128.real'  # the real im 128 on the stand-in's disk

args = sys.argv[1:]
if not args or '-h' in args or '--help' in args:
    print(__doc__.split('\n\n')[1]); sys.exit(0 if args else 2)
lu = 10
if '--lu' in args:
    i = args.index('--lu'); lu = int(args[i + 1]); del args[i:i + 2]
source = os.path.join(build, 'image128.d81')
if '--source' in args:
    i = args.index('--source'); source = args[i + 1]; del args[i:i + 2]
images = LTK
if '--images' in args:
    i = args.index('--images'); images = args[i + 1]; del args[i:i + 2]
save = '--save' in args
keep = '--keep' in args
files = [a for a in args if a not in ('--save', '--keep')]
bad = [a for a in files if a.startswith('-')]
if bad or not files:
    sys.exit('ltk_copy.py: ' + (f'unknown option {bad[0]}' if bad else 'no files to copy'))


def petscii(name):
    # c1541's spelling to PETSCII: a-z unshifted ($41-$5a), A-Z shifted ($c1-$da)
    return bytes(ord(c) - 0x20 if 'a' <= c <= 'z' else
                 ord(c) + 0x80 if 'A' <= c <= 'Z' else ord(c) for c in name)


# each file's type from the source's directory (p, s or u; a rel can't be copied)
listing = subprocess.run(['c1541', '-attach', source, '-list'],
                         capture_output=True, text=True).stdout.splitlines()
types = {}
for line in listing[1:]:
    m = re.match(r'\s*\d+\s+"([^"]*)"\s+(\w+)', line)
    if m:
        types[m.group(1)] = m.group(2)[0]
missing = [f for f in files if f not in types]
if missing:
    sys.exit(f'ltk_copy.py: not on {source}: ' + ', '.join(missing))
rel = [f for f in files if types[f] not in 'psu']
if rel:
    sys.exit('ltk_copy.py: only prg, seq and usr files: ' + ', '.join(rel))

# the stand-in's disk: the source, the stand-in as "im 128" (tokenized as
# tools/standin.sh does), and ltkcopy.list
os.makedirs(work, exist_ok=True)
prg = os.path.join(work, 'ltkcopy.prg')
subprocess.run(['petcat', '-w70', '-l', '1c01', '-o', prg, '--',
                os.path.join(repo, 'tests', 'standin', 'ltkcopy.bas')],
               capture_output=True, check=True)
shutil.copyfile(source, disk)
lst = os.path.join(work, 'ltkcopy.list')
with open(lst, 'wb') as f:
    f.write(str(lu).encode() + b'\r')
    for name in files:
        # the type letter in PETSCII too: an ASCII "s" ($73) is a shifted
        # character there, so the stand-in opened every seq file as a prg
        # 11/18/2026: "im 128" is the stand-in on this disk, so the real one
        # goes on as REAL_IM and the list says "source=dest" (an LU then got
        # the stand-in as its im 128, which boots to ?LOAD ERROR IN 80)
        src = REAL_IM + '=' + name if name == 'im 128' else name
        f.write(petscii(types[name] + src) + b'\r')
c1541 = ['c1541', '-attach', disk]
if 'im 128' in files:
    real = os.path.join(work, 'im128-real.prg')
    subprocess.run(['c1541', '-attach', source, '-read', 'im 128', real],
                   capture_output=True, check=True)
    c1541 += ['-delete', REAL_IM, '-write', real, REAL_IM]
subprocess.run(c1541 + ['-delete', 'im 128', '-write', prg, 'im 128',
                        '-delete', 'ltkcopy.list', '-write', lst, 'ltkcopy.list,s'],
               capture_output=True, check=True)

for f in IMAGES:
    shutil.copy(os.path.join(images, f), work)


def waitfor(v, texts, limit, every=3):
    t0 = time.time()
    s = ''
    while time.time() - t0 < limit:
        s = v.screen()
        for t in texts:
            if t in s.lower():
                return t, s
        time.sleep(every)
    return None, s


v = X128(['-cartcrt', os.path.join(LTK, 'ltk.crt'),
          '-ltkimage0', os.path.join(work, 'disk0.dlk'),
          '-ltkimage1', os.path.join(work, 'disk1.dlk'),
          '-ltkimage2', os.path.join(work, 'disk2.dlk'),
          '-drive8type', '0', '-drive9type', '1581', '-9', disk, '-warp'],
         cols=40, wait=4, port=PORT)
ok = False
try:
    t, s = waitfor(v, ['c128 d#08'], 120)
    if not t:
        sys.exit("the Lt. Kernal didn't come up in 128 mode:\n" + s)
    v.type('RUN"BOOT 128",U9\r')
    # 11/27/2026: the result from memory, not the screen: the stand-in
    # pokes files copied, failed and 1 (done) into $0b00-$0b02 (++ copier
    # draws its blocks and counters over the screen's text)
    t0, res, s = time.time(), None, ''
    while time.time() - t0 < 300 + 120 * len(files):
        m = v.mem('ram00', 0xb00, 3)
        s = v.screen()
        if len(m) == 3 and m[2] == 1:
            res = m
            break
        if 'error' in s.lower():
            break
        time.sleep(3)
    print(s.rstrip())
    if res:
        print(f'copied {res[0]} files, {res[1]} failed')
    ok = res is not None and res[0] == len(files) and res[1] == 0
finally:
    if not keep:
        v.stop()

if not ok:
    sys.exit(f'ltk_copy.py: not every file copied; {images} left as it was')
changed = [f for f in IMAGES
           if not filecmp.cmp(os.path.join(images, f), os.path.join(work, f), shallow=False)]
print('changed:', ', '.join(changed) or 'none')
if save:
    stamp = time.strftime('%Y%m%d-%H%M')
    for f in changed:
        shutil.copy2(os.path.join(images, f), os.path.join(images, f'{f}.before-{stamp}'))
        shutil.copy(os.path.join(work, f), os.path.join(images, f))
        print(f'saved {f} in {images} (the old one: {f}.before-{stamp})')
