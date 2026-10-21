#!/bin/bash
# build.sh -- Linux build of Image BBS 128 (make.bat's job, plus the boot
# disk): the module .bin files, the ML (cut into the parts boot.asm loads),
# boot 128, and im 128, written to build/image128.d71: a 1571 disk, so the
# 128 KERNAL loads it in burst mode.
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
c64list boot.asm -prg:boot.prg -ovr
python3 "$repo/tools/split-ml.py" ml.prg ml.sym "$build"
cp boot.prg "$build/boot 128.prg"

cd "$repo"
log=$(WINEDEBUG=-all wine "$C64LIST_406" "im 128.bas" "-prg:build\\im 128.prg" -ovr 2>&1) || true
if ! grep -q "^0 Errors" <<<"$log"; then
	grep -E "^Error|Errors;" <<<"$log" | sed 's/.*\\//' >&2
	echo "build.sh: im 128.bas failed" >&2
	exit 1
fi

# modules: BASIC 2 tokens (BASIC 7 runs them), C64List 4.04 as the C64's
log=$(WINEDEBUG=-all wine "$C64LIST" "i_su.config.lbl" "-prg:build\\i_su.config.prg" -ovr 2>&1) || true
if ! grep -q "^0 Errors" <<<"$log"; then
	grep -E "^Error|Errors;" <<<"$log" | sed 's/.*\\//' >&2
	echo "build.sh: i_su.config.lbl failed" >&2
	exit 1
fi

cd "$build"
rm -f image128.d64 image128.d71
c1541 -format "image bbs 128,ib" d71 image128.d71 \
	-write "boot 128.prg" "boot 128" \
	-write ml.buf ml.buf -write ml.low ml.low -write ml.mod ml.mod \
	-write ml.res1 ml.res1 -write ml.res2 ml.res2 \
	-write ml.rs232.prg ml.rs232 \
	-write "im 128.prg" "im 128" \
	-write i_su.config.prg "i/su.config" \
	-write "$repo/disk/e.lightbar.prg" e.lightbar \
	-write "$repo/disk/e.lightdefs.seq" "e.lightdefs,s" >/dev/null
c1541 image128.d71 -list
