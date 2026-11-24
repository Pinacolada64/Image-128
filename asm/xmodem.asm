; xmodem.asm -- "++ xmodem": Xmodem, Xmodem/CRC and Xmodem-1K, for the
; U/D sections (sub.protos: a$="xmodem":gosub 28, then &,16,4,f with
; s.m.protos' column 7; i/MM.ud-download and i/MM.ud-trans call it):
;
; &,16      (0) send the open disk file #2 to the caller
; &,16,1    receive a file from the caller into #2
; &,16,2    send an$ (up to its comma) as a name block (Image to Image)
; &,16,3    receive a name block into an$ (",s" added)
; &,16,4,f  the flag byte: bit 1 relaxed timing (4 seconds a byte, not 1),
;           bit 2 send 1K blocks (STX) instead of 128 bytes (SOH)
; &,16,5    a% = the flag byte
; &,16,255  a% = 1, the protocol number
;
; Returns a% the good blocks, b% the bad ones, rc the bytes (a float).
; Receiving takes 128-byte and 1K blocks alike, CRC or checksum, whatever
; the flag says.
;
; Ported on 2026-11-20 from the 3.0 release's (C64 values in comments):
; - runs at protostart ($1c00; c64 $c000), where &,7,dv%,2 loads it; xbuf,
;   the 1024-byte block buffer, follows the code and must end below
;   protobuf ($2b00): on the C64 it ran past the protocol area ($ca80);
;   the CRC by table (512 bytes, after xbuf, made at setup), not bit by
;   bit, so a 1K block at 19200 is taken in 40 columns (1 MHz) too
; - in 80 columns each call runs at 2 MHz, as ++ net's (a 1 MHz receiver
;   loses bytes of a block at 19200), then the blanker's speed again
; - the KERNAL through the ML's ROM stubs; the modem read straight from
;   the driver (getmdm, as ++ net); carrier is carrst's bit 7 (c64:
;   flag_dcd_addr); the block pointer is bufptr ($66/$67; c64 $b0/$b1,
;   the 128's tape timing)
; - the screen: the counters ("Good:", "Bad:") on row 15 and the clock on
;   row 14, as sub.display draws them; in 80 columns both rows are copied
;   from the VDC first and each changed cell goes back (&,72, as ++
;   copier); the block's bytes from row 2 (pscr; rows 0-1 are the boot's
;   header), each block to the VDC's same rows. The clock is drawn when
;   its seconds change, not on every byte read; no colour RAM writes
; - rc made here (normalized by shifting), not with the C64 BASIC ROM's
;   $bc4f
; Fixed on the way (the C64's has them too):
; - receiving with checksums compared the check byte with the CRC, so
;   every block was refused
; - a block sent again (its number one less than expected) wasn't taken
;   as a repeat: the test was one more
; - receiving a 1K block: the byte index wasn't reset after each 128-byte
;   piece, so pieces 2-8 went astray; and the bytes were counted at the
;   flag's block size, not the block's
; - 1K blocks went to a receiver that asked for checksums (NAK, not "C");
;   now it gets 128-byte blocks, as Xmodem-1K is CRC only

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

bufptr	= varbuf+3	; the block pointer ($66/$67; c64 $b0/$b1)

	orig protostart	; c64: $c000

chrack = 6
chrnak = 21
chreot = 4
chrcan = 24
chrsoh = 1
chrstx = 2

mfile = 131	; the modem

gcount = 11	; "Good:"'s last digit (row 15)
bcount = 23	; "Bad:"'s
tcount = 17	; the clock's first digit (row 14)

pbuf0	= $0658	; row 15: the counters
pbufrow	= 15
pbuf3	= $0630	; row 14: the clock
clkrow	= 14
pscr	= $0400+80	; row 2 on: the block's bytes (c64: $0400)

; &,16,x passes x in X: 255 (wraps to 0 on inx) = protocol number,
; then 0-4, and anything above 4 reads the flag
; 128: in 80 columns at 2 MHz, as ++ net's entry
entry:
	bit mode
	bpl dispatch	; 40 columns: 1 MHz, as on the C64
	lda $d030
	ora #1
	sta $d030
	jsr dispatch
	lda blnkflag
	and #1
	sta speed
	lda $d030
	and #$fe
	ora speed
	sta $d030
	rts
speed:
	byte 0

dispatch:
	inx
	beq protonum
	dex
	beq jsend
	dex
	beq jrecv
	dex
	beq jsendnam
	dex
	beq jrecvnam
	dex
	beq setflag
	bne getflag

defflag:
	byte 0
flagbyte:
	byte 0
versiond:
	ascii "9107098739"

protonum:
	lda #0
	sta varbuf
	lda #1
	sta varbuf+1
	ldx #var_a_integer
	jmp putvar

jsend:
	jmp xsend
jrecv:
	jmp xrecv
jsendnam:
	jmp xsendnam
jrecvnam:
	jmp xrecvnam
setflag:
	sty defflag
	rts
getflag:
	lda defflag
	sta varbuf+1
	lda #0
	sta varbuf
	ldx #var_a_integer
	jmp putvar

wait1s:
	byte 60,240	; jiffies a wait counts as a second: normal, relaxed

setup:
	lda #52		; &,52,16,3: ASCII translation, kept; then off
	ldx #16
	ldy #3
	jsr usetbl1
	lda varbuf+1
	sta oldtrans
	lda #52
	ldx #16
	ldy #0
	jsr usetbl1
	jsr mkcrctab
	jsr nobytes
	lda #0
	sta endflag
	sta abrtflag
	sta lastbuf
	lda #$ff
	sta lastsec
	ldx #pbufrow+64	; 128: rows 14 and 15 from the VDC (80 columns)
	jsr vdcrow
	ldx #clkrow+64
	jsr vdcrow
	lda defflag
	sta flagbyte
	and #2
	bne setup2
	jsr set128
	jmp startclk
setup2:
	jsr set1k
	jmp startclk

; 128-byte blocks
set128:
	lda #0
	sta kflag
	lda #<128
	sta blocksiz
	lda #>128
	sta blocksiz+1
	rts
; 1K blocks
set1k:
	lda #1
	sta kflag
	lda #<1024
	sta blocksiz
	lda #>1024
	sta blocksiz+1
	rts

nobytes:
	lda #0
	sta errors
	sta blocks
	sta blocks+1
	sta badblks
	sta badblks+1
	sta bytes
	sta bytes+1
	sta bytes+2
	rts

goodblk:
	clc
	lda blocksiz
	adc bytes
	sta bytes
	lda blocksiz+1
	adc bytes+1
	sta bytes+1
	lda #0
	sta errors
	adc bytes+2
	sta bytes+2
	inc blocks
	bne goodb1
	inc blocks+1
goodb1:
	jsr showblk
	ldx #gcount
	bne incblk

badblk:
	inc errors
	lda errors
	cmp #21
	bcc badblk1
	jmp exit1
badblk1:
	inc badblks
	bne badb2
	inc badblks+1
badb2:
	ldx #bcount
; add 1 to the 5-digit counter whose last digit is at pbuf0+X, and (128)
; its five cells to the VDC
incblk:
	txa
	pha
	ldy #5
incblk1:
	inc pbuf0,x
	lda pbuf0,x
	cmp #':'
	bne incblk2
	lda #'0'
	sta pbuf0,x
	dex
	dey
	bne incblk1
incblk2:
	pla
	tax
	ldy #5
incblk3:
	txa
	pha
	tya
	pha
	txa
	tay
	ldx #pbufrow
	jsr vdccell
	pla
	tay
	pla
	tax
	dex
	dey
	bne incblk3
	rts

; 128: &,72: .x a row (+64: VDC to VIC; +32: VIC to VDC), or .x the row
; and .y the column of one cell (VIC to VDC). Nothing in 40 columns
vdcrow:
	ldy #0
vdccell:
	lda #72
	jmp usetbl1

; 128: the block's bytes (rows 2-4) to the VDC
showblk:
	ldx #2
showblk1:
	txa
	pha
	ora #$20
	tax
	jsr vdcrow
	pla
	tax
	inx
	cpx #5
	bcc showblk1
	rts

; add .a to the checksum and the CRC (CCITT, $1021; crc is its high byte,
; crc+1 its low). Keeps .a .x .y
; 128, 11/20/2026: the CRC by table (crchi/crclo, made by mkcrctab), not
; bit by bit: eight shifts a byte were too slow for a 1K block at 19200 in
; 40 columns (1 MHz): the driver's buffer overran, and every block was
; refused
calcsum:
	pha
	clc
	adc checksum
	sta checksum
	stx calcsx
	pla
	pha
	eor crc		; the table's index: the CRC's high byte and .a
	tax
	lda crc+1
	eor crchi,x
	sta crc
	lda crclo,x
	sta crc+1
	ldx calcsx
	pla
	rts
calcsx:
	byte 0

; the CRC tables after xbuf (not in the file): for each byte i, the CRC of
; i shifted in from the high byte. Made once per load
mkcrctab:
	lda crcmade
	bne mkcrc9
	ldx #0
mkcrc1:
	stx crc		; i * 256
	lda #0
	sta crc+1
	ldy #8
mkcrc2:
	asl crc+1
	rol crc
	bcc mkcrc3
	lda crc
	eor #>$1021
	sta crc
	lda crc+1
	eor #<$1021
	sta crc+1
mkcrc3:
	dey
	bne mkcrc2
	lda crc
	sta crchi,x
	lda crc+1
	sta crclo,x
	inx
	bne mkcrc1
	inc crcmade
mkcrc9:
	rts
crcmade:
	byte 0

; check carrier/abort
exit:
	lda shflag		; c64: $028d: C= held aborts
	cmp #COMMODORE_KEY
	beq exit1
	lda carrst		; c64: flag_dcd_addr; 128: bit 7, carrier
	bpl exit1
	rts

; abort the transfer
exit1:
	ldx stack
	txs
	lda #chrcan
	jsr sendbyte
	jsr sendbyte
	jsr sendbyte
	jsr sendbyte
	jsr sendbyte
	jsr nobytes
; a% the good blocks, b% the bad, rc the bytes; the translation back
exit2:
	lda #52
	ldx #16
	ldy oldtrans
	jsr usetbl1
	lda blocks
	sta varbuf+1
	lda blocks+1
	sta varbuf
	ldx #var_a_integer
	jsr putvar
	lda badblks
	sta varbuf+1
	lda badblks+1
	sta varbuf
	ldx #var_b_integer
	jsr putvar
; 128: rc from bytes (24 bits), as BASIC packs a float (c64: $bc4f): the
; exponent, then the mantissa from its top bit, which (positive) is
; cleared
	lda bytes+2
	sta varbuf+1
	lda bytes+1
	sta varbuf+2
	lda bytes
	sta varbuf+3
	lda #0
	sta varbuf+4
	sta varbuf
	lda varbuf+1
	ora varbuf+2
	ora varbuf+3
	beq exit4	; 0: exponent 0
	ldx #$98	; 2^24
exit3:
	lda varbuf+1
	bmi exit3a
	asl varbuf+3
	rol varbuf+2
	rol varbuf+1
	dex
	bne exit3
exit3a:
	stx varbuf
	and #$7f
	sta varbuf+1
exit4:
	ldx #var_rc_float
	jmp putvar

getbyte:
	jsr exit
	jsr displclk
getbyte1:
	lda #0
	sta charval
	lda ridbe	; c64: 667
	cmp ridbs	; c64: 668
	beq getbyte2
	tya
	pha
	txa
	pha
	jsr getmdm
	sta charval
	pla
	tax
	pla
	tay
	lda #0
	sta $96
	clc
	jmp getbyte3
getbyte2:
	lda #2
	sta $96
	sec
getbyte3:
	lda charval
	rts

; a byte to the modem. Keeps .a
; 128, 11/20/2026: the driver's rsout directly (c64: chkout 131, chrout,
; clrchn). The driver's clrchn turns its receiving off and on again, and a
; byte that came meanwhile (the PC answers an ACK at once) was lost; rsout
; keeps taking bytes while it waits to send. Translation is off (setup)
sendbyte:
	pha
	jsr rsout
	pla
	rts

waitch10:
	lda #10
	bne waitch
waitch02:
	lda #2
waitch:
	sta waitsec
waitch1:
	lda #0
	sta jiffy
waitch2:
	jsr getbyte
	bcc waitch3
	lda flagbyte
	and #1
	tax
	lda jiffy
	cmp wait1s,x
	bcc waitch2
	dec waitsec
	bne waitch1
	lda #0
	sec
waitch3:
	rts

; the receiver's first byte: "C" CRC, NAK checksum (128: and then
; 128-byte blocks, as 1K is CRC only), CAN cancels
xsendcrc:
	lda #0
	sta crcflag
xsendc0:
	jsr waitch10
	bcs xsendc0
	cmp #chrnak
	beq xsendc2
	cmp #'c'
	beq xsendc1
	cmp #chrcan
	beq xsendc3
xsendc1:
	lda #1
	sta crcflag
	rts
xsendc2:
	jmp set128
xsendc3:
	jmp exit1

sendblk0:
	jsr badblk
sendblk:
	lda kflag
	beq sendblk1
	lda #chrstx
	byte $2c
sendblk1:
	lda #chrsoh
	jsr sendbyte
	lda blocknum
	jsr sendbyte
	eor #255
	jsr sendbyte
	jsr sendbuf
	jsr sendchk
sendblk3:
	jsr waitch10
	bcs sendblk3
sendblk4:
	cmp #chrnak
	beq sendblk0
	cmp #chrack
	beq sendblk5
	cmp #chrcan
	bne sendblk3
	jsr waitch10
	bcs sendblk3
	cmp #chrcan
	bne sendblk4
	lda #1
	sta abrtflag
sendblk5:
	inc bufnum
	inc blocknum
	jsr goodblk
	clc
	lda kflag
	bne sendbl4
	lda bufptr
	adc #128
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	rts
sendbl4:
	lda lastbuf
	beq sendbl5
	sta bufnum
sendbl5:
	rts

sendbuf:
	ldy #0
	lda #0
	sta checksum
	sta crc
	sta crc+1
	lda kflag
	beq sendbuf1
	lda #<xbuf
	sta bufptr
	lda #>xbuf
	sta bufptr+1
	lda #1
	sta bufnum
sendbuf1:
	lda (bufptr),y
	jsr sendbyte
	jsr calcsum
	sta pscr,y
	iny
	cpy #128
	bcc sendbuf1
	lda lastbuf
	cmp bufnum
	bne sendbuf2
	lda #1
	sta endflag
sendbuf2:
	lda kflag
	beq sendbuf3
	clc
	ldy #0
	lda bufptr
	adc #128
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	inc bufnum
	lda bufnum
	cmp #9
	bne sendbuf1
sendbuf3:
	rts

sendchk:
	lda crcflag
	bne sendchk1
	lda checksum
	jmp sendbyte
sendchk1:
	lda crc
	jsr sendbyte
	lda crc+1
	jmp sendbyte

; read up to eight 128-byte pieces of #2 into xbuf, the last one padded
; with ^Z; lastbuf: the piece the file ended in (0: it didn't)
fillbuf:
	ldx #2
	jsr chkin
	lda #<xbuf
	sta bufptr
	lda #>xbuf
	sta bufptr+1
	ldx #1
	stx bufnum
fillbuf0:
	ldy #0
fillbuf1:
	jsr chrin
	sta (bufptr),y
	iny
	jsr readst
	bne fillbuf2
	cpy #128
	bcc fillbuf1
	lda bufptr
	adc #127
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	inc bufnum
	ldx bufnum
	cpx #9
	bcc fillbuf0
	bcs setbuf
fillbuf2:
	stx lastbuf
	cpy #128
	bcs fillbuf4
fillbuf3:
	lda #26
	sta (bufptr),y
	iny
	cpy #128
	bcc fillbuf3
fillbuf4:
	ldy #0
	lda bufptr
	adc #127
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	inx
	cpx #9
	bcc fillbuf3

setbuf:
	lda #<xbuf
	sta bufptr
	lda #>xbuf
	sta bufptr+1
	lda #1
	sta bufnum
	jmp clrchn

xsend:
	tsx
	stx stack
	jsr setup
	lda #1
	sta blocknum
	jsr xsendcrc
xsend2:
	jsr fillbuf
xsend3:
	jsr sendblk
	lda abrtflag
	bne xsend6
	lda endflag
	bne xsend4
	lda bufnum
	cmp #9
	bcs xsend2
	bcc xsend3
xsend4:
	lda #chreot
	jsr sendbyte
xsend5:
	jsr waitch10
	bcs xsend5
	cmp #chrack
	bne xsend4
	jmp exit2
xsend6:
	jmp exit1

; initial handshake: "C" three times (CRC), then NAK three times
; (checksum), again until something comes; crcflag says which
xrecvcrc:
	lda #1
	sta crcflag
	lda #3
	sta bufnum
xrecvc1:
	lda #'c'
	jsr sendbyte
	jsr waitch10
	bcc xrecvc3
	dec bufnum
	bne xrecvc1
	lda #3
	sta bufnum
	lda #0
	sta crcflag
xrecvc2:
	lda #chrnak
	jsr sendbyte
	jsr waitch10
	bcc xrecvc3
	dec bufnum
	bne xrecvc2
	jmp xrecvcrc
xrecvc3:
	rts

xrecv:
	tsx
	stx stack
	jsr setup
	lda #1
	sta blocknum
	lda #0
	sta lastbuf
	jsr xrecvcrc
	jsr recvblk0
	jmp xrecv2
xrecv1:
	jsr recvblk
xrecv2:
	cpx #0
	beq xrecv1
	cpx #1
	beq xrecv3
	jmp exit2
xrecv3:
	jmp exit1

; a block (or EOT, or CAN CAN); exits with .x 0 a block, 1 cancelled,
; 2 the end
recvblk:
	jsr waitch02
	bcs recvblk2
recvblk0:
	cmp #chrsoh
	beq recvsoh
	cmp #chrstx
	beq recvblk1
	cmp #chrcan
	beq recvblk3
	cmp #chreot
	beq recvblk4

; nothing recognized in time, or a bad block: wait for the line to go
; quiet, then NAK
recvblk2:
	jsr waitch02
	bcc recvblk2
	lda #chrnak
	jsr sendbyte
	jsr badblk
	jmp recvblk

; two CANs cancel
recvblk3:
	jsr waitch02
	bcs recvblk2
	cmp #chrcan
	bne recvblk2
	ldx #1
	rts

; EOT: the end
recvblk4:
	lda #chrack
	jsr sendbyte
	ldx #2
	rts

; SOH: a 128-byte block; STX: a 1K block (128: counted as such)
recvsoh:
	jsr set128
	jmp recvblk5
recvblk1:
	jsr set1k
recvblk5:
	jsr waitch02
	bcs recvblk2
	sta blockrcv
	jsr waitch02
	bcs recvblk2
	sta blockrcv+1
	jsr recvbuf
	bcs recvblk2
	jsr waitch02
	bcs recvblk2
; 128: the checksum, or the CRC's two bytes (c64: compared the first
; byte with the CRC's either way)
	ldx crcflag
	bne recvbl5c
	cmp checksum
	bne recvblk7
	beq recvblk8
recvbl5c:
	cmp crc
	bne recvblk7
	jsr waitch02
	bcs recvblk7
	cmp crc+1
	beq recvblk8
recvblk7:
	jmp recvblk2
; the block number and its complement; the one expected is saved, the
; one before (sent again: our ACK was lost) is ACKed and dropped
recvblk8:
	lda blockrcv+1
	eor #255
	cmp blockrcv
	bne recvblk7
	lda blockrcv
	cmp blocknum
	beq recvblk9
	clc		; 128: +1 = blocknum (c64: -1)
	adc #1
	cmp blocknum
	bne recvblk7
	lda #chrack
	jsr sendbyte
	jmp recvblk
recvblk9:
	jsr savebuf
	jsr goodblk
	lda #chrack
	jsr sendbyte
	inc blocknum
	ldx #0
	rts

; write the block in xbuf (1 or 8 pieces) to #2
savebuf:
	ldx #2
	jsr chkout
	ldy #0
	lda #<xbuf
	sta bufptr
	lda #>xbuf
	sta bufptr+1
	lda #1
	sta bufnum
savebuf1:
	lda (bufptr),y
	jsr chrout
	iny
	cpy #128
	bcc savebuf1
	ldy #0
	lda bufptr
	adc #127
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	inc bufnum
	lda bufnum
	cmp #9
	beq savebuf2
	lda kflag
	bne savebuf1
savebuf2:
	jmp clrchn

buffer_index:
	byte 0

; a block's data (128 bytes, or 1024 with kflag) into xbuf, with its
; checksum and CRC; carry set if a byte didn't come in time
recvbuf:
	ldy #0
	sty checksum
	sty crc
	sty crc+1
	lda #<xbuf
	sta bufptr
	lda #>xbuf
	sta bufptr+1
	lda #1
	sta bufnum
	lda #0
	sta buffer_index
; 128, 11/20/2026: a byte already in the driver's buffer straight from
; rsget; the timeouts, carrier and clock (waitch02) only when it's empty.
; Each byte the long way was too slow for a 1K block at 19200 in 40
; columns: the driver's buffer (128 bytes) reached its 120 and stopped
; taking bytes, and the block was refused
; With 8 or more waiting, straight from the buffer (rsibuf, a ring of
; 128 in both drivers), without rsget's receive window on the status
; line; with fewer, rsget, which also turns the SwiftLink's receiving
; back on (flow control) once fewer than 100 wait
recvbuf1:
	ldy ridbs
	cpy ridbe
	beq recvbf1s
	lda ridbe
	sec
	sbc ridbs
	and #127
	cmp #8
	bcc recvbf1r
	lda rsibuf,y
	iny
	bpl recvbf1w
	ldy #0
recvbf1w:
	sty ridbs
	jmp recvbf1g
recvbf1r:
	jsr rsget	; a byte (translation is off: setup)
	jmp recvbf1g
recvbf1s:
	jsr waitch02
	bcs recvbuf3
recvbf1g:
	jsr calcsum
	ldy buffer_index
	sta (bufptr),y
	sta pscr,y
	iny
	sty buffer_index
	cpy #128
	bcc recvbuf1
	ldy #0		; 128: the next piece from its start (c64: kept 128)
	sty buffer_index
	lda bufptr
	adc #127
	sta bufptr
	lda bufptr+1
	adc #0
	sta bufptr+1
	inc bufnum
	lda bufnum
	cmp #9
	beq recvbuf2
	lda kflag
	bne recvbuf1
recvbuf2:
	clc
	rts
recvbuf3:
	sec
	rts

blocknum:
	byte 0
blockrcv:
	byte 0,0
blocksiz:
	word 1024
crcflag:
	byte 0
kflag:
	byte 1
bufnum:
	byte 0
abrtflag:
	byte 0
endflag:
	byte 0
lastbuf:
	byte 0
waitsec:
	byte 0
stack:
	byte 0
oldtrans:
	byte 0
bytes:
	byte 0,0,0
crc:
	word 0
checksum:
	byte 0
charval:
	byte 0
errors:
	byte 0
blocks:
	word 0
badblks:
	word 0
lastsec:
	byte 0

; send an$ up to its comma, as a 128-byte name block numbered 0
xsendnam:
	tsx
	stx stack
	jsr setup
	jsr setbuf
	lda #0
	sta blocknum
	jsr xsendcrc
	jsr set128	; a name block is 128 bytes, whatever the flag
	ldx #var_an_string
	jsr usevar
	ldy #0
	lda varbuf
	beq xsendn4
xsendn3:
	lda (varbuf+1),y
	cmp #comma
	beq xsendn5
	cmp #65
	bcc xsendn7
	cmp #91
	bcs xsendn8
	adc #32
	bcc xsendn7
xsendn8:
	and #127
xsendn7:
	sta pscr,y
	sta xbuf,y
	iny
	cpy varbuf
	bcc xsendn3
xsendn5:
	lda #0
xsendn4:
	sta xbuf,y
	iny
	cpy #128
	bcc xsendn4
	jsr sendblk
	jmp exit2

; receive a name block into an$, with ",s"
xrecvnam:
	tsx
	stx stack
	jsr setup
	lda #0
	sta blocknum
	jsr xrecvcrc
	jsr recvblk0
	ldy #0
xrecvn1:
	lda xbuf,y
	beq xrecvn2
	cmp #comma
	beq xrecvn2
	cmp #65
	bcc xrecvn3
	cmp #91
	bcs xrecvn4
	adc #128
	bcc xrecvn3
xrecvn4:
	sbc #32
xrecvn3:
	sta buffer,y
	iny
	cpy #16
	bcc xrecvn1
xrecvn2:
	lda #comma
	sta buffer,y
	iny
	lda #'s'
	sta buffer,y
	iny
	sty varbuf
	lda #<buffer
	sta varbuf+1
	lda #>buffer
	sta varbuf+2
	ldx #var_an_string
	jsr putvar
	jmp exit2

; 128, as ++ net's: the driver directly, rather than &,4 through usetbl1
; (c64: lda #4 / jmp usetbl1); 7 bits only in ASCII translation, which
; setup turns off
getmdm:
	jsr rsinabl
	sec
	jsr rsget
	bcs getmdm6
	pha
	lda flag_asc_addr
	and #flag_asc_l_mask
	beq getmdm1
	pla
	and #$7f
	pha
getmdm1:
	pla
	rts
getmdm6:
	lda #0
	rts
usevar:
	lda #29
	jmp usetbl1
putvar:
	lda #30
	jmp usetbl1

; CIA 2's time of day from 00:00:00 (hours written first stop it, tenths
; last start it)
startclk:
	lda #0
	ldy #3
startcl1:
	sta $dd08,y
	dey
	bpl startcl1
	rts

; the clock on row 14, hh:mm:ss, when its seconds have changed (128: and
; its cells to the VDC; c64: on every byte read). Reading the seconds
; alone doesn't latch it; reading the hours does, until the tenths are.
; Keeps .x .y
displclk:
	lda $dd09
	cmp lastsec
	bne displcl0
	rts
displcl0:
	sta lastsec
	txa
	pha
	tya
	pha
	ldx #0
	ldy #3
displcl1:
	lda $dd08,y
	pha
	lsr
	lsr
	lsr
	lsr
	jsr displcl3
	pla
	and #15
	jsr displcl3
	dey
	beq displcl2
	lda #':'
	jsr displcl4
	jmp displcl1
displcl2:
	lda $dd08
	ldx #tcount	; 128: its 8 cells to the VDC
displcl5:
	txa
	tay
	pha
	ldx #clkrow
	jsr vdccell
	pla
	tax
	inx
	cpx #tcount+8
	bcc displcl5
	pla
	tay
	pla
	tax
	rts
displcl3:
	ora #$30
displcl4:
	sta pbuf3+tcount,x
	inx
	rts

; the 1K block buffer, then the CRC tables (made by mkcrctab, not in
; the file): all must end below protobuf ($2b00); asm/build.sh checks
xbuf:
crchi	= xbuf+1024
crclo	= xbuf+1280
