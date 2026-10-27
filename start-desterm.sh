# start-desterm.sh: run the DesTerm 128 terminal program in x128 (80 columns),
# with its own tcpser as the modem, to call the BBS that start-image-128.sh runs
#
# - A tcpser emulates the caller's Hayes modem: x128's emulated SwiftLink
#   ($de00, NMI, which DesTerm finds by itself) talks to it on $MODEM_PORT,
#   and it dials out over telnet. (It also listens for calls on $TELNET_PORT;
#   nothing uses that.) tcpser is stopped when x128 exits.
# - In DesTerm's terminal, dial the BBS's tcpser:
#     atdt127.0.0.1:6128
# - Drive 8 (1581) holds a working copy of the DesTerm disk in $RUN_DIR, made
#   only if it doesn't exist yet, so DesTerm can save its settings and phone
#   book. Delete it to start over from $DESTERM_D81.
# - The remote monitor is off (+remotemonitor), so this x128 doesn't take
#   the BBS's x128's port, and the user port RS-232 is off
#   (-userportdevice 0), so only the SwiftLink uses the modem.
# - Logs: $RUN_DIR/tcpser.log
#
#   TCPSER_TRACE=sS sh start-desterm.sh   also logs what DesTerm sends (s)
#                                         and receives (S)
#   TCPSER=path, TELNET_PORT=n, MODEM_PORT=n, BAUD=n override the defaults

JIFFYDOS=${JIFFYDOS:-$HOME/Documents/c64/JiffyDOS}

# --- disk ---
DESTERM_D81=${DESTERM_D81:-$HOME/Documents/c128/desterm128-v3.02.d81}
RUN_DIR=${RUN_DIR:-$HOME/Documents/c128/desterm-run}
WORK_D81="$RUN_DIR/desterm.d81"

# --- modem (tcpser) ---
TCPSER=${TCPSER:-$HOME/bin/tcpser/tcpser}
# ports, so all can run at once: ImageBBS3's BBS 25238/6400, its CCGMS
# 25239/6401, start-image-128.sh 25240/6128, this 25241/6402
MODEM_PORT=${MODEM_PORT:-25241}   # x128 <-> tcpser, on 127.0.0.1 only
TELNET_PORT=${TELNET_PORT:-6402}  # tcpser's incoming-call port (unused)
BAUD=${BAUD:-19200}               # as the BBS; DesTerm's SwiftLink goes higher
TCPSER_LOG_LEVEL=${TCPSER_LOG_LEVEL:-4}
TCPSER_TRACE=${TCPSER_TRACE:-}
LOG="$RUN_DIR/tcpser.log"

die() { echo "start-desterm: $*" >&2; exit 1; }
port_in_use() { ss -ltn 2>/dev/null | grep -q ":$1\b"; }

[ -x "$TCPSER" ] || die "tcpser not found: $TCPSER"
for f in "$JIFFYDOS/JDOS128.rom" "$JIFFYDOS/Jiffy1581.rom"; do
	[ -f "$f" ] || die "not found: $f"
done
mkdir -p "$RUN_DIR"

# --- working copy of the disk ---
if [ ! -f "$WORK_D81" ]; then
	[ -f "$DESTERM_D81" ] || die "$DESTERM_D81 not found"
	cp "$DESTERM_D81" "$WORK_D81"
	echo "Made $WORK_D81 from $DESTERM_D81"
fi

# --- tcpser ---
for p in "$MODEM_PORT" "$TELNET_PORT"; do
	port_in_use "$p" && die "port $p is already in use (is another tcpser running?)"
done

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
port_in_use 6128 || echo "note: nothing is listening on port 6128 yet; start the BBS with start-image-128.sh before dialing"
echo "tcpser: in DesTerm, dial atdt127.0.0.1:6128 (log: $LOG)"

# --- x128 ---
# SwiftLink: ACIA at $de00, mode 1, NMI (irq 1), on RS-232 device 3 (myaciadev 2)
x128 -80col +remotemonitor \
	-kernal "$JIFFYDOS/JDOS128.rom" -dos1581 "$JIFFYDOS/Jiffy1581.rom" \
	-drive8type 1581 -drive9type 0 \
	-acia1 -acia1base 0xde00 -acia1mode 1 -acia1irq 1 -myaciadev 2 \
	-userportdevice 0 \
	-rsdev3 "127.0.0.1:$MODEM_PORT" -rsdev3ip232 -rsdev3baud "$BAUD" \
	-autostart "$WORK_D81:desboot"
