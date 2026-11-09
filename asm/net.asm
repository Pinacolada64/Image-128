; net.asm -- "++ net": NetMail's transfer protocol, for i.NM_auto and
; i/NM.netsub4 (a$="net":gosub 28, then &,16,x): 0 send the open disk file
; (2) to the other BBS, 1 receive one into it, 2 send b$ as a name block,
; 3 receive a name block into b$, 4 and 5 the "relaxed" handshake (send,
; receive), 6,n the modem chat: send a$, then keep the last n characters
; that arrive in b$ until the line is quiet (rc 1 and b$ "" if the
; carrier goes or C= is held). Returns: peek(512) 0 done, 1 aborted; 0
; and 1 leave a block count in b%. PROGRAMMING.md has the details.
;
; Ported on 2026-11-05 from source/net.s, which builds the 3.0 release's
; "++ net" byte for byte (C64 values in the comments):
; - runs at protostart ($1c00; c64 $c000), where &,7,dv%,2 loads it
; - no 6510 port to set (c64: lda #r6510_normal / sta $01): it runs in
;   cfg_ml and reaches the KERNAL through the ML's ROM stubs
; - the shift flags are shflag ($d3; c64 653/$028d): 2 = C= on both
; - the RS-232 receive buffer's indices are ridbe/ridbs ($0a18/$0a19;
;   c64 667/668), which both 128 drivers keep
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63), and the
;   block pointer just past it, bufptr ($66/$67; c64 $64/$65, FAC1 too);
;   its buffer $0e77 (c64 $ce77), its & dispatcher usetbl1 ($192a; c64
;   $cd03)
; - the block buffers are still in the 40-column screen, as on the C64:
;   pbuf1 and pbuf2 ($0400, $0500, rows 0-12) and the counters at pbuf0
;   ($0658, row 15), which &,52,16 (screen) sets up. In 80 columns
;   (11/05/2026) screen copies the module's counter line from the VDC
;   into that row first, and each counter cell that changes goes to the
;   VDC too (&,72, vdccell in vdc.asm; showcell)
; - unchanged: $96 (the result code, as mcicm.asm uses it), 512 (BASIC's
;   input buffer, $0200 on both), $fe (xchrout's character)
; - the timeouts count loop passes (tmer1, dod2's delay), so they depend
;   on the CPU's speed and on how long the ML's calls take; the 128's go
;   through farcall and the ROM stubs, so a pass takes longer than on the
;   C64 (and half as long at 2 MHz)
; - 11/05/2026: 2 MHz in 80 columns (entry), and the modem read straight
;   from the driver (getmdm): a 1 MHz receiver lost bytes from a sender at
;   the full 19200 line rate

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

bufptr	= varbuf+3	; c64: $64/$65

	orig protostart	; c64: $c000

t3 = 70

mfile = 131 ;modem file number
dfile = 2 ;disk file number
errch = 15 ;disk error channel

xxx = 0
goo = 1
bad = 2
ack = 3
snb = 4
syn = 5

; each code's bit in accept's pattern (c64 source: 1<<code; C64List has
; no shift operator)
b_goo = 2	; 1<<goo
b_bad = 4	; 1<<bad
b_ack = 8	; 1<<ack
b_snb = 16	; 1<<snb
b_syn = 32	; 1<<syn

gcount = 11
bcount = 23
ncount = 38

pbuf0= $658
pbufrow = 15	; 128: pbuf0's row on the screen (for &,72)
pbuf1= $400
pbuf2= $500

reset = rsinabl

	jmp entry

relaxflg:
	byte 0

;serialp:
;	ascii "A"
;serialn:
;	word 3

;code accept
t1:
	byte 35,100
;receive timing
t2:
	byte 16,30

; 128, 11/05/2026: in 80 columns each call runs at 2 MHz (the VIC isn't
; seen there): at 1 MHz this side read a byte from the modem in about the
; time one takes at 19200 baud, and a sender at the full line rate (a
; 2 MHz 128, a C64, a PC) had blocks sent again (tools/netpair.py --fast
; caller). The abort (ext1) puts the stack back to entry1's frame, so it
; comes back here too. Afterwards the speed is the screen blanker's
; (blnkflag: blanked is 2 MHz, irqhn.asm), not the one saved, as the sysop
; may blank or unblank it meanwhile
entry:
	bit mode
	bpl entry1	; 40 columns: 1 MHz, as on the C64
	lda $d030
	ora #1
	sta $d030
	jsr entry1
	pha
	lda blnkflag
	and #1
	sta speed
	lda $d030
	and #$fe
	ora speed
	sta $d030
	pla
	rts
speed:
	byte 0

entry1:
	txa
	tsx
	stx stack
	tax
	lda #0
	sta tcount
			; c64: lda #r6510_normal / sta r6510
	tya
	inx
	dex
	beq jupload ;0
	dex
	beq jdnload ;1
	dex
	beq jupname ;2
	dex
	beq jdnname ;3
	dex
	beq juprelx ;4
	dex
	beq jdnrelx ;5
	dex
	beq jmodemx ;6
	rts

jupname:
	jmp trantype
jdnname:
	jmp rectype
jupload:
	jmp transmit
jdnload:
	jmp receive
juprelx:
	jmp tranrelx
jdnrelx:
	jmp recvrelx
jmodemx:
	jmp modemchk

; check carrier/abort
exit:
;	txa
;	pha
	lda shflag	; c64: $28d
	cmp #2
	beq ext1
;	ldx #4
;	lda bsnpre-4,x
;	cmp serialp-4,x
;	lda bsnval-4,x
;	cmp serialn-4,x
;	lda bsnval-3,x
;	cmp serialn-3,x
	lda carrst
	bmi ext2
ext1:
	ldx stack
	txs
	ldx #xxx
	jsr sendcode
ext0:
	lda #1
	sta 512
	jsr nobytes
ext2:
;	pla
;	tax
	rts

; get # bytes and exit
xfer1:
	lda blocks
	sta varbuf+1
	lda blocks+1
	sta varbuf
	ldx #var_b_integer
	jsr putvar
	lda #0
	sta 512
	rts

; check for code
accept:
	sta bitpat
	lda #$00
	sta codebuf
	sta codebuf+1
	sta codebuf+2
acc1:
	lda #$00
	sta tmer1
	sta tmer1+1
acc2:
	jsr getnumx
	bcs acc6
acc3:
	ldx codebuf+1
	stx codebuf
	ldx codebuf+2
	stx codebuf+1
	sta codebuf+2
	jsr chkcod
	beq acc1
	sec
	lda #$00
acc4:
	rol
	dex
	bpl acc4
	and bitpat
	beq acc2
	lda relaxflg
	bne acc5
	jsr getnumx
	bcc acc3
acc5:
	ldx bitcnt
	lda #0
	sta tcount
	sta $96
	rts
acc6:
	inc tmer1
	bne acc7
	inc tmer1+1
acc7:
	lda tmer1+1
	ldx relaxflg
	cmp t1,x
	bne acc2
	inc tcount
	lda tcount
	cmp #20
	bcc acc8
	jmp ext1
acc8:
	lda #1
	sta $96
	rts

chkcod:
	ldx #syn
chc1:
	lda codebuf
	cmp char1,x
	bne chc2
	lda codebuf+1
	cmp char2,x
	bne chc2
	lda codebuf+2
	cmp char3,x
	beq chc3
chc2:
	dex
	bpl chc1
chc3:
	stx bitcnt
	txa
	cmp #xxx
	bne chc4
	jmp ext1
chc4:
	cmp #255
	rts

;codes.........012345
char1:
	byte ascii_ctrl_x
	ascii "gbass"
char2:
	byte ascii_ctrl_x
	ascii "oac/y"
char3:
	byte ascii_ctrl_x
	ascii "odkbn"

sendcode:
	txa
	pha
	ldx #mfile
	jsr chkout
	pla
	tax
	lda char1,x
	jsr chrout
	lda char2,x
	jsr chrout
	lda char3,x
	jsr chrout
	jsr clrchn
	ldx #1
	jmp tenwait

getnumx:
	jsr exit
getnum1:
	lda #2
	sta $96
	lda #0
	sta $0200
	lda ridbe	; c64: 667
	cmp ridbs	; c64: 668
	beq getnum2
	tya
	pha
	txa
	pha
	jsr getmdm
	sta $0200
	pla
	tax
	pla
	tay
	lda #0
	sta $96
	clc
getnum2:
	lda $0200
	rts

tranrelx:
	lda #128
	sta repeat
trx1:
	ldx #syn
	jsr sendcode
	lda #b_syn  | b_goo
	jsr accept
	beq trx3
	dec repeat
	bne trx1
trx2:
	lda #1
	sta $200
	rts
trx3:
	cpx #syn
	bne trx2
	lda #0
	sta $200
	rts

recvrelx:
	lda #1
	sta relaxflg
	lda #128
	sta repeat
rrx1:
	lda #b_syn  | b_goo
	jsr accept
	beq rrx2
	dec repeat
	bne rrx1
	lda #1
	sta $200
	rts
rrx2:
	cpx #syn
	beq rrx3
	lda #0
	sta relaxflg
rrx3:
	ldx #syn
	jsr sendcode
	lda #0
	sta $200
	rts

rechand:
	sta gbsave
	lda recsize
	sta bufcount
	lda #0
	sta delay
rch1:
	lda #2
	sta repeat
	ldx gbsave
	jsr sendcode
rch2:
	lda #b_ack
	jsr accept
	beq rch3
	dec repeat
	bne rch2
	jmp rch1
rch3:
	ldx #snb
	jsr sendcode
	lda endflag
	beq rch4
	lda gbsave
	cmp #goo
	beq rch6
rch4:
	jsr recmodem
	ldx $96
	stx pbuf0+1
	jsr showstat	; 128: and on the VDC, in 80 columns
	cpx #2
	beq rch3
	cpx #4
	beq rch3
rch5:
	lda $96
	rts
rch6:
	lda #b_syn
	jsr accept
	bne rch1
	lda #3
	sta repeat
rch7:
	ldx #syn
	jsr sendcode
	lda #b_snb
	jsr accept
	beq rch8
	dec repeat
	bne rch7
rch8:
	rts

trh0:
	jmp ext1
tranhand:
	lda #$01
	sta delay
	lda #30
	sta repeat
trh1:
	dec repeat
	beq trh0
	lda specmode
	beq trh2
	ldx #goo
	jsr sendcode
trh2:
	lda #b_goo  | b_bad  | b_snb
	jsr accept
	bne trh1
	lda #0
	sta specmode
	cpx #goo
	bne trh6
	lda endflag
	bne trh8
	inc blocknum
	bne trh3
	inc blocknum+1
trh3:
	jsr thisbuf
	ldy #5+1
	lda (bufptr),y
	cmp #$ff
	bne trh4
	lda #$01
	sta endflag
	lda bufpnt
	eor #$01
	sta bufpnt
	jsr thisbuf
	jsr dummybl1
	jmp trh5
trh4:
	jsr dummyblk
trh5:
	lda #'-'
	byte $2c
trh6:
	lda #':'
	jsr prtdash
	lda #0
	sta ackcount
trh6a:
	inc ackcount
	lda ackcount
	cmp #20
	bcc trh6b
	jmp ext1
trh6b:
	ldx #ack
	jsr sendcode
	lda #b_snb
	jsr accept
	bne trh6a
	jsr thisbuf
	ldy #4
	lda (bufptr),y
	sta bufcount
	jsr altbuf
	ldx #mfile
	jsr chkout
	ldy #0
trh7:
	lda (bufptr),y
	jsr chrout
	iny
	cpy bufcount
	bne trh7
	jsr clrchn
	lda #$00
	rts
trh8:
	lda #'*'
	jsr prtdash
	ldx #ack
	jsr sendcode
	lda #b_snb
	jsr accept
	bne trh8
; lda #10
; sta bufcount
trh9:
	ldx #syn
	jsr sendcode
	lda #b_syn
	jsr accept
; bne trha
; dec bufcount
; bne trh9
;trha:
;	lda #3
;	sta bufcount
trhb:
	ldx #snb
	jsr sendcode
; lda #0
; jsr accept ;wait
; dec bufcount
; bne trhb
	lda #1
	rts

;returns:

; 1 = buffer is full
; 2 = timeout, stuff in buffer
; 3 = timeout, buffer empty
; 4 = timeout, "ack" in buffer
recmodem:
	ldy #$00
	lda recsize
	sta pbuf2+1
rcm1:
	lda #$00
	sta pbuf0+1
	sta tmer1
	sta tmer1+1
rcm2:
	jsr getnumx
	lda $96
	bne rcm5
	lda $0200
	sta pbuf1,y
	cpy #$02
	bne rcm3
	lda pbuf1
	cmp #'a'
	bne rcm3
	lda pbuf1+1
	cmp #'c'
	bne rcm3
	lda pbuf1+2
	cmp #'k'
	beq rcm4
rcm3:
	iny
	cpy recsize
	bne rcm1
	lda #1
	sta $96
	rts
rcm4:
	lda #$ff
	sta tmer1
	sta tmer1+1
	jmp rcm2
rcm5:
	inc tmer1
	bne rcm6
	inc tmer1+1
rcm6:
	lda tmer1
	ora tmer1+1
	beq rcm8
	lda tmer1+1
	ldx relaxflg
	cmp t2,x
	bne rcm2
	lda #2
	sta $96
	cpy #$00
	beq rcm7
	lda #3
	sta $96
rcm7:
	jmp dodelay
rcm8:
	lda #4
	sta $96
	jmp clrchn

dummyblk:
	lda bufpnt
	eor #$01
	sta bufpnt
	jsr thisbuf
	ldy #$05
	lda blocknum
	clc
	adc #$01
	sta (bufptr),y
	iny
	lda blocknum+1
	adc #$00
	sta (bufptr),y
	ldx #dfile
	jsr chkin
	ldy #7
dum1:
	jsr chrin
	sta (bufptr),y
	iny
	jsr readst
	bne dum2
	cpy maxsize
	bne dum1
	tya
	pha
	jmp dum3
dum2:
	tya
	pha
	ldy #5+1
	lda #$ff
	sta (bufptr),y
	jmp dum3
dummybl1:
	pha
dum3:
	jsr clrchn
	jsr reset
	jsr dod2
	jsr reset
	ldy #$04
	lda (bufptr),y
	sta bufcount
	jsr altbuf
	pla
	ldy #$04
	sta (bufptr),y
	jsr checksum
	rts

thisbuf:
	lda #<pbuf1
	sta bufptr	; c64: $64
	lda bufpnt
	clc
	adc #>pbuf1
	sta bufptr+1	; c64: $65
	rts

altbuf:
	lda #<pbuf1
	sta bufptr	; c64: $64
	lda bufpnt
	eor #1
	clc
	adc #>pbuf1
	sta bufptr+1	; c64: $65
	rts

checksum:
	lda #$00
	sta check1
	sta check1+1
	sta check1+2
	sta check1+3
	ldy #$04
chk1:
	lda check1
	clc
	adc (bufptr),y
	sta check1
	bcc chk2
	inc check1+1
chk2:
	lda check1+2
	eor (bufptr),y
	sta check1+2
	lda check1+3
	rol
	rol check1+2
	rol check1+3
	iny
	cpy bufcount
	bne chk1
	ldy #3
l1:
	lda check1,y
	sta (bufptr),y
	dey
	bpl l1
	rts

transmit:
	jsr screen
	lda #$00
	sta endflag
	sta skpdelay
	sta dontdash
	lda #$01
	sta bufpnt
	lda #$ff
	sta blocknum
	sta blocknum+1
	jsr altbuf
	ldy #4
	lda #7
	sta (bufptr),y
	jsr thisbuf
	ldy #5
	lda #0
	sta (bufptr),y
	iny
	sta (bufptr),y
tra1:
	jsr tranhand
	beq tra1
tra2:
	jmp xfer1

receive:
	jsr screen
	lda #$01
	sta blocknum
	lda #$00
	sta blocknum+1
	sta endflag
	sta bufpnt
	sta pbuf1+5
	sta pbuf1+6
	sta skpdelay
	ldx #7
	stx recsize
	lda #goo
rec1:
	jsr rechand
	lda endflag
	bne tra2
	jsr match
	bne rec5
	lda recsize
	cmp #7
	beq rec3
	ldx #dfile
	jsr chkout
	ldy #7
rec2:
	lda pbuf1,y
	jsr chrout
	iny
	cpy bufcount
	bne rec2
	jsr clrchn
rec3:
	lda pbuf1+6
	cmp #$ff
	bne rec4
	lda #1
	sta endflag
rec4:
	jsr goodblok
	jsr dobytes
	jsr reset
	ldx pbuf1+4
	stx recsize
	lda #goo
	jmp rec1
rec5:
	jsr badblok
	lda #bad
	jmp rec1

match:
	ldx #3
mch1:
	lda pbuf1,x
	sta check,x
	dex
	bpl mch1
	jsr thisbuf
	lda recsize
	sta bufcount
	jsr checksum
	ldx #3
mch2:
	lda pbuf1,x
	cmp check,x
	bne mch3
	dex
	bpl mch2
	lda #0
	rts
mch3:
	lda #1
	rts

rectype:
	jsr screen
	lda #$00
	sta blocknum
	sta blocknum+1
	sta endflag
	sta bufpnt
	sta skpdelay
	lda #goo
rct1:
	ldx #7+32
	stx recsize
	jsr rechand
	inc pbuf2
	lda endflag
	bne rct3
	jsr match
	bne rct2
	jsr buf2var
	lda #1
	sta endflag
	lda #goo
	jmp rct1
rct2:
	lda #bad
	jmp rct1
rct3:
	lda #0
	sta $0200
	rts

trantype:
	jsr screen
	lda #$00
	sta endflag
	sta skpdelay
	sta dontdash
	lda #$01
	sta bufpnt
	lda #$ff
	sta blocknum
	sta blocknum+1
	jsr altbuf
	ldy #4
	lda #7+32
	sta (bufptr),y
	jsr thisbuf
	ldy #5
	lda #$ff
	sta (bufptr),y
	iny
	sta (bufptr),y
	jsr var2buf
	lda #1
	sta specmode
trt1:
	jsr tranhand
	beq trt1
	lda #0
	sta $0200
	rts

var2buf:
	lda bufptr	; c64: $64
	sta var2buf3+1
	lda bufptr+1	; c64: $65
	sta var2buf3+2
	ldx #var_b_string
	jsr usevar
	ldy #0
	ldx #7
var2buf2:
	cpy varbuf
	beq var2buf4
	lda (varbuf+1),y
var2buf3:
	sta $ffff,x
	iny
	inx
	bne var2buf2
var2buf4:
	txa
	tay
	lda var2buf3+1
	sta bufptr	; c64: $64
	lda var2buf3+2
	sta bufptr+1	; c64: $65
	lda #13
	sta (bufptr),y
	iny
	rts

buf2var:
	ldx #7
	ldy #0
buf2var1:
	lda pbuf1,x
	cmp #13
	beq buf2var2
	sta buffer,y
	iny
	inx
	cpy #79
	bcc buf2var1
buf2var2:
	tya
	jsr makerm1
	ldy #0
buf2var3:
	cpy varbuf
	beq buf2var4
	lda buffer,y
	sta (varbuf+1),y
	iny
	bne buf2var3
buf2var4:
	ldx #var_b_string
	jmp putvar

dodelay:
	inc skpdelay
	lda skpdelay
	cmp #$03
	bcc dod1
	lda #$00
	sta skpdelay
	lda delay
	beq dod2
	bne dod5
dod1:
	lda delay
	beq dod5
dod2:
	ldx #$00
dod3:
	ldy #$00
dod4:
	iny
	bne dod4
	inx
	cpx #$78
	bne dod3
dod5:
	rts

prtdash:
	pha
	lda blocknum
	ora blocknum+1
	beq prd1
	lda dontdash
	bne prd1
	pla
	jsr dodash
	pha
prd1:
	pla
	rts

dodash:
	sta dash
	cmp #'*'
	beq dsh2
	cmp #'-'
	beq dsh1
	jmp badblok
dsh1:
	jsr goodblok
dsh2:
	jmp dobytes

screen:
	lda #0
	sta badcount
	jsr reset
	jsr nobytes
	lda #52
	ldx #16
	ldy #0
	jsr usetbl1	; c64: jmp
	ldx #pbufrow+64	; 128: in 80 columns the module printed the counter
	ldy #0		; line on the VDC: copy it into pbuf0's row, where the
	lda #72		; counters count (&,72, vdccell)
	jmp usetbl1

nobytes:
	lda #0
	sta bytes
	sta bytes+1
	sta bytes+2
	sta blocks
	sta blocks+1
	sta bytec
	sta bytec+1
	rts

dobytes:
	lda bufcount
	sec
	sbc #7
	pha
	clc
	adc bytes
	sta bytes
	bcc dobytes1
	inc bytes+1
	bne dobytes1
	inc bytes+2
dobytes1:
	pla
	clc
	adc bytec
	sta bytec
	bcs dobytes2
	inc bytec+1
dobytes2:
	lda bytec
	bne dobytes3
	lda bytec
	cmp #254
	bcs dobytes3
	rts
dobytes3:
	lda bytec
	sec
	sbc #254
	sta bytec
	lda bytec+1
	sbc #0
	sta bytec+1
	inc blocks
	bne dobytes4
	inc blocks+1
dobytes4:
	rts

bytes:
	byte 0,0,0
bytec:
	word 0
blocks:
	word 0
bitpnt:
	byte $20
bitcnt:
	byte $0f
bitpat:
	byte $04
tmer1:
	word $0000
gbsave:
	byte $00
bufcount:
	byte $07
delay:
	byte $00
skpdelay:
	byte $00
endflag:
	byte $00
check:
	word $0000,$0000
check1:
	word $0000,$0000
bufpnt:
	byte $00
recsize:
	byte $07
maxsize:
	byte $ff
blocknum:
	word $0000
stack:
	byte $f6
dontdash:
	byte $00
specmode:
	byte $00
dash:
	byte $00
codebuf:
	ascii "   "
numx:
	byte 0
repeat:
	byte 0
badcount:
	byte 0
tcount:
	byte 0
ackcount:
	byte 0
badblks:
	word 0

getln:
	lda #35
	jmp usetbl1
putln:
	lda #36
	jmp usetbl1
; 128, 11/05/2026: the driver directly, as the ML's getmdm (chrio.asm,
; &,4) does it, rather than &,4 through usetbl1: a byte read costs less
; (c64: lda #4 / jmp usetbl1)
getmdm:
	jsr rsinabl
	sec
	jsr rsget
	bcs getmdm6
	pha
	lda flag_asc_addr	; ASCII translation: 7 bits
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
tenwait:
	lda #22
	jmp usetbl1
xchrout:
	sta $fe
	lda #24
	jmp usetbl1
minusone:
	lda #32
	jmp usetbl1

modemchk:
	sty index
	ldx #var_a_string
	jsr usevar
	lda varbuf
	beq modemc2
	ldx #mfile
	jsr chkout
	ldy #0
modemc1:
	lda (varbuf+1),y
	jsr chrout
	iny
	cpy varbuf
	bcc modemc1
	jsr clrchn
modemc2:
	ldy #0
	sty varbuf
modemc3:
	lda #0
	sta tmer1
	sta tmer1+1
modemc4:
	lda 653
	cmp #2
	beq modemc6
	lda carrst
	bpl modemc6
	jsr getmdm
	and #127
	bne modemc7
	inc tmer1
	bne modemc5
	inc tmer1+1
modemc5:
	lda tmer1+1
	cmp #100
	bcc modemc4
	jmp modemc9
modemc6:
	jsr minusone
	ldx #var_rc_float
	jsr putvar
	lda #0
	sta varbuf
	jmp modemc9
modemc7:
	cmp #13
	beq modemc10
	cmp #32
	bcc modemc3
	cmp #96
	bcc modemc10
	sec
	sbc #32
modemc10:
	ldy varbuf
	sta buffer,y
	inc varbuf
	jsr xchrout
	ldy varbuf
	cpy index
	beq modemc3
	bcc modemc3
	ldy #0
modemc8:
	lda buffer+1,y
	sta buffer,y
	iny
	cpy index
	bcc modemc8
	sty varbuf
	jmp modemc3
modemc9:
	lda #<buffer
	sta varbuf+1
	lda #>buffer
	sta varbuf+2
	ldx #var_b_string
	jmp putvar

;increment byte count
commbyte:
	tya
	pha
	ldy #6
	ldx #ncount
	jsr counter
	inc bytes
	bne cmb6
	inc bytes+1
	bne cmb6
	inc bytes+2
cmb6:
	pla
	tay
	rts
commcnt:
	byte 0

;increment good blocks
goodblok:
	inc blocks
	bne goodb1
	inc blocks+1
goodb1:
	ldx #gcount
	jmp counter0

;increment bad blocks
badblok:
	inc badblks
	bne badb1
	inc badblks+1
badb1:
	ldx #bcount

counter0:
	ldy #5
counter:
	inc pbuf0,x
	lda pbuf0,x
	cmp #':'
	bne counter1
	lda #'0'
	sta pbuf0,x
	jsr showcell	; 128: each digit changed, on the VDC too
	dex
	dey
	bne counter
	rts
counter1:
	jmp showcell	; c64: rts

; 128, 11/05/2026: in 80 columns the VIC screen isn't seen, so each cell
; of the counter line that changes goes to the VDC too (&,72, vdccell;
; nothing in 40 columns): showcell column .x, showstat the status cell
; (column 1). Both keep .a .x .y
showstat:
	pha
	txa
	pha
	ldx #1
	bne showc1
showcell:
	pha
	txa
	pha
showc1:
	tya
	pha
	txa
	tay
	ldx #pbufrow
	lda #72
	jsr usetbl1
	pla
	tay
	pla
	tax
	pla
	rts
