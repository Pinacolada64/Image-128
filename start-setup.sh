# start-setup.sh: boot an unconfigured Image BBS 128 in x128, to try the
# new-system setup (i/su.config): at the start-up menu, press 1
#
# Each run copies build/image128.d81 (asm/build.sh's disk, never
# configured) to build/setup-try.d81 and boots that, so setup starts from
# scratch; the build disk and the run disk (build/setup-test.d81,
# start-image-128.sh's) aren't touched.
#
#   sh start-setup.sh              80 columns, a fresh copy
#   sh start-setup.sh -40          40 columns
#   sh start-setup.sh -9 1571      a drive 9 (no disk) for the Drives part's
#                                  bus scan: 1541, 1571, 1581...
#   sh start-setup.sh -k           keep build/setup-try.d81 as it is (to boot
#                                  what the last setup wrote)
#   sh start-setup.sh -- ARGS      more arguments for x128
#
# The clock is a DS12C887 at $d700, as start-image-128.sh has (the Clock
# part's DS12C887 choice, base 1), without -ds12c887rtcsave: the RTC's
# saved time is left alone. No modem: setup doesn't use one.
# JIFFYDOS=dir for other ROMs, as start-image-128.sh. 11/06/2026

JIFFYDOS=${JIFFYDOS:-$HOME/Documents/c64/JiffyDOS}

die() { echo "start-setup: $*" >&2; exit 1; }

cd "$(dirname "$0")" || die "can't cd to $(dirname "$0")"

cols=80col
drive9=
keep=
while [ $# -gt 0 ]; do
	case $1 in
	-40) cols=40col ;;
	-80) cols=80col ;;
	-9) [ $# -ge 2 ] || die "-9 needs a drive type (1541, 1571, 1581...)"
		drive9="-drive9type $2"; shift ;;
	-k) keep=1 ;;
	--) shift; break ;;
	*) die "unknown option: $1 (see the top of this script)" ;;
	esac
	shift
done

disk=build/setup-try.d81
[ -f build/image128.d81 ] || die "no build/image128.d81: run asm/build.sh first"

if [ -z "$keep" ]; then
	# an x128 with the try disk attached would write its own copy back
	if ps -eo args | grep '[x]128' | grep -q "setup-try\.d81"; then
		die "an x128 has $disk open: quit it first (or -k to boot it again as it is)"
	fi
	cp build/image128.d81 "$disk"
	echo "start-setup: $disk is a fresh copy of build/image128.d81"
else
	[ -f "$disk" ] || die "no $disk to keep: run without -k"
	echo "start-setup: booting $disk as it is"
fi

# shellcheck disable=SC2086 # $drive9: two words, or none
exec x128 -ntsc -$cols -drive8type 1581 $drive9 \
	-kernal "$JIFFYDOS/JDOS128.rom" -dos1581 "$JIFFYDOS/Jiffy1581.rom" \
	-ds12c887rtc -ds12c887rtcbase 0xd700 -ds12c887rtcrunning \
	"$@" \
	-autostart-warp -autostart "$disk:boot 128"
