# start-image-128.sh: run Image BBS 128 in x128, with tcpser as the modem
#
# - tcpser emulates a Hayes modem: callers telnet to port $TELNET_PORT, and
#   x128's emulated SwiftLink ($de00, NMI) talks to tcpser on $MODEM_PORT
#   (ip232, which also carries DCD and DTR, so the BBS sees calls and can
#   hang up). tcpser is stopped when x128 exits. Ports, so all can run at
#   once: ImageBBS3's BBS 25238/6400, its CCGMS 25239/6401, this BBS
#   25240/6128, start-desterm.sh 25241/6402.
# - Call it from start-desterm.sh (DesTerm 128): atdt127.0.0.1:6128
# - The user port RS-232 is off (-userportdevice 0), so it can't take the
#   connection from the SwiftLink.
# - Logs: build/tcpser.log
#
#   TCPSER_TRACE=sS sh start-image-128.sh   also logs the AT commands the BBS
#                                           sends (s) and tcpser's replies (S)
#   TCPSER=path, TELNET_PORT=n, MODEM_PORT=n, BAUD=n override the defaults

# JiffyDOS: the C128 KERNAL and the 1581's DOS (JIFFYDOS=dir to use others)
JIFFYDOS=${JIFFYDOS:-$HOME/Documents/c64/JiffyDOS}

# --- modem (tcpser) ---
TCPSER=${TCPSER:-$HOME/bin/tcpser/tcpser}
MODEM_PORT=${MODEM_PORT:-25232}   # x128 <-> tcpser, on 127.0.0.1 only
TELNET_PORT=${TELNET_PORT:-6128}  # callers telnet here
# 19200: IM's "tcpser (VICE)" modem profile (rs232_swift.asm goes to 38400)
BAUD=${BAUD:-19200}
TCPSER_LOG_LEVEL=${TCPSER_LOG_LEVEL:-4}
TCPSER_TRACE=${TCPSER_TRACE:-}
LOG=build/tcpser.log

die() { echo "start-image-128: $*" >&2; exit 1; }
port_in_use() { ss -ltn 2>/dev/null | grep -q ":$1\b"; }

[ -x "$TCPSER" ] || die "tcpser not found: $TCPSER"
for p in "$MODEM_PORT" "$TELNET_PORT"; do
	port_in_use "$p" && die "port $p is already in use (is another tcpser running?)"
done

# -I would invert DCD: through VICE's SwiftLink the BBS otherwise sees a
# carrier when nobody is connected (ImageBBS3's start-image-bbs.sh uses it).
# Left off for now: instead, the lightbar's Invert DCD (flag 58, T at the
# idle screen) is set so the carrier check is off with no caller
"$TCPSER" -s "$BAUD" -v "127.0.0.1:$MODEM_PORT" -p "$TELNET_PORT" \
	-l "$TCPSER_LOG_LEVEL" ${TCPSER_TRACE:+-t "$TCPSER_TRACE"} -L "$LOG" &
TCPSER_PID=$!
trap 'kill "$TCPSER_PID" 2>/dev/null' EXIT

# wait up to 5 seconds for tcpser to listen for x128
for _ in $(seq 50); do
	port_in_use "$MODEM_PORT" && break
	kill -0 "$TCPSER_PID" 2>/dev/null || die "tcpser stopped: see $LOG"
	sleep 0.1
done
port_in_use "$MODEM_PORT" || die "tcpser isn't listening on port $MODEM_PORT"
echo "tcpser: callers telnet to port $TELNET_PORT (log: $LOG)"

# DS12C887 RTC cartridge at $d700 (x128 allows $d700, $de00, $df00; $d500
# is the MMU on the 128, and the SwiftLink is at $de00): sub.clocks'
# DS12C887 method (ck=4, cp=55040), chosen in IM's clock settings.
# -ds12c887rtcsave keeps its time between runs.
# SwiftLink: ACIA at $de00, mode 1, NMI (irq 1), on RS-232 device 3 (myaciadev 2)
x128 -80col -drive8type 1581 -drive9type 1581 \
	-kernal "$JIFFYDOS/JDOS128.rom" -dos1581 "$JIFFYDOS/Jiffy1581.rom" \
	-9 "build/s_files.d81" \
	-ds12c887rtc -ds12c887rtcbase 0xd700 -ds12c887rtcrunning -ds12c887rtcsave \
	-acia1 -acia1base 0xde00 -acia1mode 1 -acia1irq 1 -myaciadev 2 \
	-userportdevice 0 \
	-rsdev3 "127.0.0.1:$MODEM_PORT" -rsdev3ip232 -rsdev3baud "$BAUD" \
	-autostart-warp -autostart "build/setup-test.d81:boot 128"
