#!/bin/sh
# standin.sh -- make a test disk that boots a stand-in for "im 128"
#
#   tools/standin.sh tests/standin/<name>.bas
#
# Tokenizes the program (petcat, BASIC 7.0, at $1c01, where intro loads
# im) and writes it as "im 128" on a copy of build/image128.d81, so the
# ML loads and RUNs it: build/standin-<name>.d81. Data files it reads:
# tests/standin/<name>.<file>.seq. Run asm/build.sh first.
# See tests/standin/README.md.

set -e
[ $# -eq 1 ] || { echo "usage: $0 tests/standin/<name>.bas" >&2; exit 2; }
repo=$(cd "$(dirname "$0")/.." && pwd)
src=$1
name=$(basename "$src" .bas)
build="$repo/build"
[ -f "$build/image128.d81" ] || { echo "$0: no build/image128.d81: run asm/build.sh" >&2; exit 1; }

# petcat keeps the lines in the file's order, and BASIC's line search
# goes wrong if they aren't ascending (?undef'd statement): refuse them
awk '/^[0-9]/ { if ($1+0 <= last) { print FILENAME ": line " $1 " after " last; bad=1 } last=$1+0 }
	END { exit bad }' "$src" >&2 || { echo "$0: line numbers out of order" >&2; exit 1; }

prg="$build/standin-$name.prg"
disk="$build/standin-$name.d81"
petcat -w70 -l 1c01 -o "$prg" -- "$src"
cp "$build/image128.d81" "$disk"
c1541 "$disk" -delete "im 128" -write "$prg" "im 128" >/dev/null
rm -f "$prg"
# data files: tests/standin/<name>.<file>.seq goes on the disk as the SEQ
# file <file> (PETSCII, Return at the end of each line), for a stand-in that
# reads one without having to write it first
for f in "$(dirname "$src")/$name".*.seq; do
	[ -e "$f" ] || continue
	file=${f##*/$name.}
	file=${file%.seq}
	c1541 "$disk" -delete "$file" -write "$f" "$file,s" >/dev/null
done
echo "$disk"
echo "x128 -80col -drive8type 1581 -autostart-warp -autostart \"$disk:boot 128\""
