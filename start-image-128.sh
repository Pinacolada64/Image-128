# JiffyDOS: the C128 KERNAL and the 1581's DOS (JIFFYDOS=dir to use others)
JIFFYDOS=${JIFFYDOS:-$HOME/Documents/c64/JiffyDOS}
# DS12C887 RTC cartridge at $d700 (x128 allows $d700, $de00, $df00; $d500
# is the MMU on the 128): sub.clocks' DS12C887 method (ck=4, cp=55040),
# chosen in IM's clock settings. -ds12c887rtcsave keeps its time between runs
x128 -80col -drive8type 1581 -drive9type 1581 \
	-kernal "$JIFFYDOS/JDOS128.rom" -dos1581 "$JIFFYDOS/Jiffy1581.rom" \
	-9 "build/s_files.d81" \
	-ds12c887rtc -ds12c887rtcbase 0xd700 -ds12c887rtcrunning -ds12c887rtcsave \
	-autostart-warp -autostart "build/setup-test.d81:boot 128"
