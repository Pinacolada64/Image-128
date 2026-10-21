#!/bin/bash
# build.sh -- Linux build of Image BBS 128 (make.bat's job, plus the boot
# disk): the module .bin files, the ML (cut into the parts boot.asm loads),
# boot 128, im 128 and the modules, written to build/image128.d81: a 1581
# disk (3160 blocks: the i.* and i/* modules alone are 2200), which the
# 128 KERNAL loads in burst mode too.
#
#   asm/build.sh            (from anywhere)
#
# C64List runs under wine: 4.04 for the assembly (as make.bat), 4.06 for
# "im 128.bas" (4.04 ignores {tokenizer}, so BASIC 7.0 keywords wouldn't be
# tokenized). Override where they are with C64LIST and C64LIST_406.

set -e
C64LIST=${C64LIST:-$HOME/bin/c64list4_04.exe}
C64LIST_406=${C64LIST_406:-$HOME/bin/C64List4.06/c64List.exe}
here=$(cd "$(dirname "$0")" && pwd)
repo=$(dirname "$here")
build="$repo/build"
mkdir -p "$build"

c64list() {
	# c64list file.asm args...: fail on any error C64List reports
	local log
	log=$(WINEDEBUG=-all wine "$C64LIST" "$@" 2>&1) || true
	if ! grep -q "^0 Errors" <<<"$log"; then
		grep -E "^Error|Errors;" <<<"$log" | sed 's/.*\\//' >&2
		echo "build.sh: $1 failed" >&2
		exit 1
	fi
}

cd "$here"
for module in wedge editor gc ecs struct swap1 swap2 swap3; do
	c64list "$module.asm" "-bin:$module.bin" -ovr
done
c64list ml.asm -prg:ml.prg -sym:ml.sym -ovr
# ml.rs232: the loader (rs232.asm) with both drivers embedded; im loads
# it at protostart and runs it with &,16 (0 user port, 1 SwiftLink)
c64list rs232_user.asm -bin:rs232_user.bin -ovr
c64list rs232_swift.asm -bin:rs232_swift.bin -ovr
c64list rs232.asm -prg:rs232.prg -ovr
cp rs232.prg "$build/ml.rs232.prg"

# the "++" overlays: im loads them at protostart (&,7,dv%,2), each on the
# disk as "++ <name>"; extra disk names for the same file after a ":"
overlays="index:4 clock"
ovlwrites=()
for o in $overlays; do
	name=${o%%:*}
	c64list "$name.asm" "-prg:$name.prg" -ovr
	cp "$name.prg" "$build/++ $name.prg"
	ovlwrites+=(-write "$build/++ $name.prg" "++ $name")
	extra=${o#"$name"}
	for alias in ${extra//:/ }; do
		ovlwrites+=(-write "$build/++ $name.prg" "++ $alias")
	done
done
c64list boot.asm -prg:boot.prg -ovr
python3 "$repo/tools/split-ml.py" ml.prg ml.sym "$build"
cp boot.prg "$build/boot 128.prg"

cd "$repo"
# imdate: the build's date and time as im's clock strings have it (z$,
# d1$): the weekday (1 = Sunday), YYMMDD, the hour 1-12 plus 80 after
# noon (im line 3354: noon is 92, midnight 12), the minute. im line 3153
# starts the clock with it when no clock chip or drive answers.
h=$(date +%-H)
h12=$(( h % 12 == 0 ? 12 : h % 12 ))
[ "$h" -ge 12 ] && h12=$(( h12 + 80 ))
imdate="$(( $(date +%w) + 1 ))$(date +%y%m%d)$(printf %02d $h12)$(date +%M)"
log=$(WINEDEBUG=-all wine "$C64LIST_406" "im 128.bas" "-prg:build\\im 128.prg" "-def:imdate=\"$imdate\"" -ovr 2>&1) || true
if ! grep -q "^0 Errors" <<<"$log"; then
	grep -E "^Error|Errors;" <<<"$log" | sed 's/.*\\//' >&2
	echo "build.sh: im 128.bas failed" >&2
	exit 1
fi

# modules: BASIC 2 tokens (BASIC 7 runs them), C64List 4.04 as the C64's
# (ISU_CONFIG: another copy to build instead, in the repo's top directory,
# e.g. the last committed one while i_su.config.lbl is being edited)
isu=${ISU_CONFIG:-i_su.config.lbl}
log=$(WINEDEBUG=-all wine "$C64LIST" "$isu" "-prg:build\\i_su.config.prg" -ovr 2>&1) || true
if ! grep -q "^0 Errors" <<<"$log"; then
	grep -E "^Error|Errors;" <<<"$log" | sed 's/.*\\//' >&2
	echo "build.sh: $isu failed" >&2
	exit 1
fi

# the modules (modules/): sub.* (im loads them at line 60000), i.* (3000)
# and i/* (4000; the listing names have "_" for "/"), the same way; a jump
# to a line C64List can't find stops the build too
modwrites=()
cd "$repo/modules"
for f in sub.*.lbl i.*.lbl i_*.lbl; do
	m=${f%.lbl}
	disk=${m//_//}
	crunch=; grep -q '{crunch:on}' "$f" && crunch=-crunch
	# a module that includes Basic70.bas (BASIC 7.0 keywords: dec, do...)
	# needs C64List 4.06, which tokenizes them; 4.06 won't take the
	# preface's numeric {assign}s, so such a module can't {uses:} it
	list=$C64LIST; grep -qi 'Basic70\.bas' "$f" && list=$C64LIST_406
	log=$(WINEDEBUG=-all wine "$list" "$f" "-prg:..\\build\\$m.prg" $crunch -ovr 2>&1) || true
	if ! grep -q "^0 Errors" <<<"$log" || grep -q "Can't locate target line" <<<"$log"; then
		grep -E "^Error|Errors;|Can't locate" <<<"$log" | sed 's/.*\\//' >&2
		echo "build.sh: modules/$f failed" >&2
		exit 1
	fi
	modwrites+=(-write "$m.prg" "$disk")
done

cd "$build"
rm -f image128.d64 image128.d71 image128.d81
c1541 -format "image bbs 128,ib" d81 image128.d81 \
	-write "boot 128.prg" "boot 128" \
	-write ml.buf ml.buf -write ml.low ml.low -write ml.mod ml.mod \
	-write ml.res1 ml.res1 -write ml.res2 ml.res2 \
	-write ml.rs232.prg ml.rs232 \
	-write "im 128.prg" "im 128" \
	-write i_su.config.prg "i/su.config" \
	-write "$repo/disk/e.lightbar.prg" e.lightbar \
	-write "$repo/disk/e.lightdefs.seq" "e.lightdefs,s" \
	-write "$repo/disk/e.ecs.main.prg" e.ecs.main \
	-write "$repo/disk/e.printmodes.prg" e.printmodes \
	-write "$repo/disk/e.alarms.prg" e.alarms \
	-write "$repo/disk/nm.times.prg" nm.times \
	-write "$repo/disk/e.fkeys.seq" "e.fkeys,s" \
	"${modwrites[@]}" "${ovlwrites[@]}" >/dev/null
c1541 image128.d81 -list
