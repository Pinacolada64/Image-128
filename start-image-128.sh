# JiffyDOS: the C128 KERNAL and the 1581's DOS (JIFFYDOS=dir to use others)
JIFFYDOS=${JIFFYDOS:-$HOME/Documents/c64/JiffyDOS}
x128 -80col -drive8type 1581 \
	-kernal "$JIFFYDOS/JDOS128.rom" -dos1581 "$JIFFYDOS/Jiffy1581.rom" \
	-autostart-warp -autostart "build/setup-test.d81:boot 128"
