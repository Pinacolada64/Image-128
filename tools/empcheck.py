#!/usr/bin/env python3
"""empcheck.py: check modules/emp6-includes.lbl's {assign:name=line} against
where i.empire's labels landed in the build (build/i.empire.prg, listed with
VICE's petcat): each label's next code line must be at the line the table
says, as the i/emp.* modules jump there by number ({$33}nnn). Run after
asm/build.sh whenever i.empire changes (11/24/2026, from the session that
kept the lines fixed). Exit 1 if any moved."""
import os, re, subprocess, sys
W = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + '/'
src = open(W + 'modules/i.empire.lbl', encoding='latin-1').read().split('\n')
lst = subprocess.run(['petcat', '-2', '--', W + 'build/i.empire.prg'], capture_output=True,
                     text=True, encoding='latin-1').stdout.split('\n')
lines = {}
for l in lst:
    m = re.match(r'\s*(\d+) (.*)', l)
    if m:
        lines[int(m.group(1))] = m.group(2)
inc = open(W + 'modules/emp6-includes.lbl', encoding='latin-1').read()
assigns = dict((a, int(b)) for a, b in re.findall(r'\{assign:([^=]+)=(\d+)\}', inc))
bad = 0
for name, want in assigns.items():
    # the label in the source, then its next code line
    idx = next((i for i, l in enumerate(src) if l.strip() == '{:%s}' % name), None)
    if idx is None:
        print(f'?? {name}: no such label in i.empire'); bad += 1; continue
    code = None
    for l in src[idx + 1:]:
        s = l.strip()
        if s and not s.startswith("'") and not s.startswith('{'):
            code = s; break
    key = re.sub(r'[^a-z]', '', re.sub(r'\{[^}]*\}', '', code).lower())[:10]
    got = [n for n, t in lines.items() if re.sub(r'[^a-z]', '', re.sub(r'\{[^}]*\}', '', t).lower()).startswith(key)]
    ok = want in got
    bad += not ok
    if not ok:
        print(f'WRONG {name}: assigned {want}, the line is at {got} ({code[:40]})')
print('checked', len(assigns), 'labels;', 'all match' if bad == 0 else f'{bad} wrong')
sys.exit(1 if bad else 0)
