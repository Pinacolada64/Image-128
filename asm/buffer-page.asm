d1str:
	area $20, 11
spchars:
	ascii comma,colon,34,"*?=",13,"^"
fbuf:
	area $20, 20
buf2:
	area $20, 80
buffer:
	area $20, 80

; date in 6 byte bcd format

bootdate:

dateday:
	byte $01
datemon:
	byte $12
datedate:
	byte $09
dateyear:
	byte $90
	byte $20,$00

; storage for conversion routines

binary:
	byte 0,0,0,0

; days in each month

ha560:
	byte $31,$28,$31,$30,$31
	byte $30,$31,$31,$30,$00
decchr:
	byte $30,$30,$30,$30,$30
	byte $31,$30,$31

; the date this ml was made

version:
	ascii {usedef:__BuildDate}
	ascii " "
	ascii {usedef:__BuildTime}

version_length = * - version

; version in floating point

versnum:
	byte $81, $00, $00, $00, $00 ; 1.0
;	byte $81, $19, $99, $99, $9a ; 1.2
;	byte $81, $26, $66, $66, $66 ; 1.3
;	byte $82, $00, $00, $00, $00 ; 2.0
