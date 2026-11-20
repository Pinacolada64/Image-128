#!/bin/bash
# build.sh -- Linux build of Image BBS 128 (make.bat's job, plus the boot
# disk): the module .bin files, the ML (cut into the parts boot.asm loads),
# boot 128, im 128 and the modules, written to build/image128.d81: a 1581
# disk (3160 blocks: the i.* and i/* modules alone are 2200), which the
# 128 KERNAL loads in burst mode too.
#
#   asm/build.sh            (from anywhere)
#   asm/build.sh ml [disk.d81 ...]
#
# "ml" builds only the ML, boot 128, ml.rs232 and the "++" overlays, and
# replaces those files on build/image128.d81 (from a full build) and on
# each disk named after it (e.g. build/setup-test.d81, a configured system:
# its other files stay as they are). im and the modules don't change with
# the ML: they reach it through the fixed addresses in equates.asm.
#
# C64List runs under wine: 4.04 for the assembly (as make.bat), 4.06 for
# "im 128.bas" (4.04 ignores {tokenizer}, so BASIC 7.0 keywords wouldn't be
# tokenized). Override where they are with C64LIST and C64LIST_406.
#
# 11/19/2026: the compiles run in parallel, JOBS at a time (default: the
# number of CPUs; JOBS=1 builds one file at a time, as before). Each wine
# run took a second or more to start, ~240 of them one after another (about
# 11.5 minutes on a 4-CPU machine). The order: the ML's module .bin files and
# the two RS-232 drivers first (ml.asm and rs232.asm embed them), then
# everything else at once: ml.asm, rs232.asm, the overlays, boot, im 128 and
# every module (they read only source files: equates.asm, the preface,
# quoters, Basic70). A failure stops the build after the running compiles
# finish, with every failed file's errors. One wineserver serves the build
# (-p30: it stays 30 seconds after the last compile), not one per compile.

set -e
mode=all
if [ "$1" = ml ]; then
	mode=ml
	shift
fi
mldisks=()
for d in "$@"; do
	mldisks+=("$(cd "$(dirname "$d")" && pwd)/$(basename "$d")")
done
C64LIST=${C64LIST:-$HOME/bin/c64list4_04.exe}
C64LIST_406=${C64LIST_406:-$HOME/bin/C64List4.06/c64List.exe}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
build="$repo/build"
mkdir -p "$build"

JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}
jobdir=$(mktemp -d "${TMPDIR:-/tmp}/image128-build.XXXXXX")
trap 'rm -rf "$jobdir"' EXIT
WINEDEBUG=-all wineserver -p30 2>/dev/null || true

compile() {
	# compile DIR NAME EXE ARGS...: one C64List run in DIR; on an error
	# (or a jump to a line C64List can't find), its messages go in
	# $jobdir/NAME.err for finish to show
	local dir=$1 name=$2 exe=$3 log
	shift 3
	cd "$dir"
	log=$(WINEDEBUG=-all wine "$exe" "$@" 2>&1) || true
	if ! grep -q "^0 Errors" <<<"$log" || grep -q "Can't locate target line" <<<"$log"; then
		{
			grep -E "^Error|Errors;|Can't locate" <<<"$log" | sed 's/.*\\//'
			echo "build.sh: $name failed"
		} >"$jobdir/${name//\//_}.err"
	fi
}

spawn() {
	# spawn DIR NAME EXE ARGS...: compile in the background, at most JOBS at once
	while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do
		wait -n || true
	done
	compile "$@" &
}

finish() {
	# wait for every compile; stop the build if any failed
	wait || true
	if compgen -G "$jobdir/*.err" >/dev/null; then
		cat "$jobdir"/*.err >&2
		exit 1
	fi
}

# the ML's module .bin files and the RS-232 drivers, which ml.asm and
# rs232.asm embed
for module in wedge editor gc ecs struct swap1 swap2 swap3; do
	spawn "$here" "$module.asm" "$C64LIST" "$module.asm" "-bin:$module.bin" -ovr
done
spawn "$here" rs232_user.asm "$C64LIST" rs232_user.asm -bin:rs232_user.bin -ovr
spawn "$here" rs232_swift.asm "$C64LIST" rs232_swift.asm -bin:rs232_swift.bin -ovr
finish

# then the rest at once: the ML, ml.rs232 (the loader, rs232.asm, with
# both drivers embedded; im loads it at protostart and runs it with &,16:
# 0 user port, 1 SwiftLink), the overlays, boot; and for a full build im
# 128 and the modules
spawn "$here" ml.asm "$C64LIST" ml.asm -prg:ml.prg -sym:ml.sym -ovr
spawn "$here" rs232.asm "$C64LIST" rs232.asm -prg:rs232.prg -ovr
# the "++" overlays: im loads them at protostart (&,7,dv%,2), each on the
# disk as "++ <name>"; extra disk names for the same file after a ":"
overlays="index:4 clock menu2 2 read post path net netsub netlist copier visual chatmode"
ovlwrites=()
for o in $overlays; do
	name=${o%%:*}
	spawn "$here" "$name.asm" "$C64LIST" "$name.asm" "-prg:$name.prg" -ovr
	ovlwrites+=(-write "$build/++ $name.prg" "++ $name")
	extra=${o#"$name"}
	for alias in ${extra//:/ }; do
		ovlwrites+=(-write "$build/++ $name.prg" "++ $alias")
	done
done
spawn "$here" boot.asm "$C64LIST" boot.asm -prg:boot.prg -ovr

modwrites=()
if [ $mode = all ]; then
	# imdate: the build's date and time as im's clock strings have it (z$,
	# d1$): the weekday (1 = Sunday), YYMMDD, the hour 1-12 plus 80 after
	# noon (im line 3354: noon is 92, midnight 12), the minute. im line 3153
	# starts the clock with it when no clock chip or drive answers.
	h=$(date +%-H)
	h12=$(( h % 12 == 0 ? 12 : h % 12 ))
	[ "$h" -ge 12 ] && h12=$(( h12 + 80 ))
	imdate="$(( $(date +%w) + 1 ))$(date +%y%m%d)$(printf %02d $h12)$(date +%M)"
	# 10/29/2026: -crunch when the file asks for it, as for the modules below:
	# C64List 4.06 ignores {crunch:on} too
	imcrunch=; grep -q '{crunch:on}' "$repo/im 128.bas" && imcrunch=-crunch
	spawn "$repo" "im 128.bas" "$C64LIST_406" "im 128.bas" "-prg:build\\im 128.prg" \
		"-def:imdate=\"$imdate\"" $imcrunch -ovr

	# the modules (modules/): sub.* (im loads them at line 60000), i.* (3000)
	# and i/* (4000; the listing names have "_" for "/"), the same way; a jump
	# to a line C64List can't find stops the build too
	cd "$repo/modules"
	for f in sub.*.lbl i.*.lbl i_*.lbl; do
		m=${f%.lbl}
		disk=${m//_//}
		crunch=; grep -q '{crunch:on}' "$f" && crunch=-crunch
		# a module that includes Basic70.bas (BASIC 7.0 keywords: dec, do...)
		# needs C64List 4.06, which tokenizes them; 4.06 won't take the
		# preface's numeric {assign}s, so such a module can't {uses:} it
		list=$C64LIST; grep -qi 'Basic70\.bas' "$f" && list=$C64LIST_406
		# ISU_CONFIG: another copy of i_su.config.lbl (the setup) to build in its
		# place, in modules/ too, e.g. the last committed one while it's being
		# edited (11/13/2026: the setup moved here from the top directory)
		src=$f; [ "$f" = i_su.config.lbl ] && [ -n "$ISU_CONFIG" ] && src=$ISU_CONFIG
		spawn "$repo/modules" "modules/$f" "$list" "$src" "-prg:..\\build\\$m.prg" $crunch -ovr
		modwrites+=(-write "$m.prg" "$disk")
	done
fi
finish

cd "$here"
cp rs232.prg "$build/ml.rs232.prg"
for o in $overlays; do
	name=${o%%:*}
	cp "$name.prg" "$build/++ $name.prg"
done
python3 "$repo/tools/split-ml.py" ml.prg ml.sym "$build"
cp boot.prg "$build/boot 128.prg"

if [ $mode = ml ]; then
	[ -f "$build/image128.d81" ] || { echo "build.sh: no build/image128.d81: run asm/build.sh first" >&2; exit 1; }
	# each file by name: delete it (if it's there), then write it
	mlfiles=("boot 128.prg:boot 128" ml.buf:ml.buf ml.low:ml.low ml.mod:ml.mod
		ml.res1:ml.res1 ml.res2:ml.res2 ml.io:ml.io ml.rs232.prg:ml.rs232)
	for ((i = 1; i < ${#ovlwrites[@]}; i += 3)); do
		mlfiles+=("$(basename "${ovlwrites[i]}"):${ovlwrites[i+1]}")
	done
	args=()
	for f in "${mlfiles[@]}"; do
		args+=(-delete "${f#*:}" -write "$build/${f%%:*}" "${f#*:}")
	done
	for d in "$build/image128.d81" "${mldisks[@]}"; do
		c1541 "$d" "${args[@]}" >/dev/null 2>&1
		echo "$d:"
		c1541 "$d" -list | grep -E '"(boot 128|ml\.[a-z0-9]+|\+\+ [^"]+)"'
	done
	exit 0
fi

cd "$repo/modules"
# Today in History (disk/today.<Mon>.seq): c1541 writes the capital in
# "today.Oct" as the PETSCII capital, as i/lo/today's "today."+zm$ has it
todaywrites=()
for m in Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec; do
	todaywrites+=(-write "$repo/disk/today.$m.seq" "today.$m,s")
done

# 11/05/2026: s.timezones and s.dstrules (tools/dstfiles.py), which a new
# system needs before any s.* files are copied: setup's Clock part lists the
# zones from s.timezones (sub.info im=8), and sub.clocks reads s.dstrules
python3 "$repo/tools/dstfiles.py" "$build/dst" >/dev/null

cd "$build"
rm -f image128.d64 image128.d71 image128.d81
c1541 -format "image bbs 128,ib" d81 image128.d81 \
	-write "boot 128.prg" "boot 128" \
	-write ml.buf ml.buf -write ml.low ml.low -write ml.mod ml.mod \
	-write ml.res1 ml.res1 -write ml.res2 ml.res2 -write ml.io ml.io \
	-write ml.rs232.prg ml.rs232 \
	-write "im 128.prg" "im 128" \
	-write "$repo/disk/e.lightbar.prg" e.lightbar \
	-write "$repo/disk/e.lightdefs.seq" "e.lightdefs,s" \
	-write "$repo/disk/e.ecs.main.prg" e.ecs.main \
	-write "$repo/disk/e.printmodes.prg" e.printmodes \
	-write "$repo/disk/e.alarms.prg" e.alarms \
	-write "$repo/disk/nm.times.prg" nm.times \
	-write "$repo/disk/e.fkeys.seq" "e.fkeys,s" \
	-write "$repo/disk/s.visual.seq" "s.visual,s" \
	-write "$repo/disk/s.visual 80.seq" "s.visual 80,s" \
	-write "$build/dst/s.timezones" "s.timezones,s" \
	-write "$build/dst/s.dstrules" "s.dstrules,s" \
	"${modwrites[@]}" "${ovlwrites[@]}" >/dev/null
c1541 image128.d81 -list
# 11/05/2026: the optional features' files on a disk of their own, which
# setup's Optional Features part copies from (Today in History's 12 files
# are ~550 blocks; on image128.d81 they left 84 free, and a 1581 with that
# little room hangs extending a REL file: setup's u.config write)
rm -f features.d81
c1541 -format "image bbs 128 features,if" d81 features.d81 "${todaywrites[@]}" >/dev/null
c1541 features.d81 -list | tail -1
