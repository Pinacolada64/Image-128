#!/bin/sh
# standin.sh -- make a test disk that boots a stand-in for "im 128"
#
#   tools/standin.sh tests/standin/<name>.bas
#
# Tokenizes the program (petcat, BASIC 7.0, at $1c01, where intro loads
# im) and writes it as "im 128" on a copy of build/image128.d71, so the
# ML loads and RUNs it: build/standin-<name>.d71. Run asm/build.sh first.
# See tests/standin/README.md.

set -e
[ $# -eq 1 ] || { echo "usage: $0 tests/standin/<name>.bas" >&2; exit 2; }
repo=$(cd "$(dirname "$0")/.." && pwd)
src=$1
name=$(basename "$src" .bas)
build="$repo/build"
[ -f "$build/image128.d71" ] || { echo "$0: no build/image128.d71: run asm/build.sh" >&2; exit 1; }

prg="$build/standin-$name.prg"
disk="$build/standin-$name.d71"
petcat -w70 -l 1c01 -o "$prg" -- "$src"
cp "$build/image128.d71" "$disk"
c1541 "$disk" -delete "im 128" -write "$prg" "im 128" >/dev/null
rm -f "$prg"
echo "$disk"
echo "x128 -80col -drive8type 1571 -autostart-warp -autostart \"$disk:boot 128\""
