revision = 1
version_string = "2023-08-30 12:08"

{include:"equates.asm"}

;;;
;;; wedge
;;;

orig wedge_load_address

{include:"wedge.asm"}

room_in_wedge = editor_load_address - *

; pad to the start of the next module
	align  room_in_wedge,0
wedge_module_size = * - wedge_load_address

;;;
;;; editor
;;;

{include:"editor.asm"}

room_in_editor = gc_load_address - *

; pad to the start of the next module
	align room_in_editor,0
editor_module_size = * - editor_load_address

;;;
;;; garbage collection
;;;

{include:"gc.asm"}

room_in_gc = ecs_load_address - *

; pad to the start of the next module
	align room_in_gc,0
gc_module_size = * - gc_load_address

;;;
;;; extended command set
;;;

; $e400 - e.c.asm. checker

{include:"ecs.asm"}

room_in_ecs = struct_load_address - *

; pad to the start of the next module
	align  room_in_ecs,0
ecs_module_size = * - ecs_load_address

;;;
;;; struct
;;;

{include:"struct.asm"}

room_in_struct = swap1_load_address - *

; pad to the start of the next module
	align  room_in_struct,0
struct_module_size = * - struct_load_address

;;;
;;; swap1
;;;

{include:"swap1.asm"}

room_in_swap1 = swap2_load_address - *

; pad to the start of the next module
	align room_in_swap1, 0
swap1_module_size = * - swap1_load_address

;;;
;;; swap2
;;;

{include:"swap2.asm"}

room_in_swap2 = swap3_load_address - *

; pad to the start of the next module
	align  room_in_swap2,0
swap2_module_size = * - swap2_load_address

;;;
;;; swap3
;;;

{include:"swap3.asm"}

room_in_swap3 = jmptbl - *

; pad to the start of the next module
	align  room_in_swap3,0
swap3_module_size = * - swap3_load_address

{include:"jmptb.asm"}

{include:"strio.asm"}

{include:"mcicm.asm"}

{include:"chrio.asm"}

{include:"dskio.asm"}

{include:"irqhn.asm"}

{include:"setup.asm"}

{include:"varbl.asm"}

{include:"miscl.asm"}

{include:"shdlr.asm"}

{include:"modem.asm"}

{include:"calls.asm"}

; put intro program in

room_under_basic_rom = protostart-*
	align room_under_basic_rom,0

{include:"intro.asm"}

room_in_intro = $cb00 - *

;* skip rest of proto area *

	align room_in_intro,0

swapper0:
	sta swappg1	; source page
	sty swappg2	; destination page
	stx swapsiz	; how many pages to swap
swapagn0:
	lda #$d3	; reverse capital "S"
	sta tdisp+31
	jsr rsdisab
	sei
	lda r6510
	pha
	lda #r6510_all_ram
	sta r6510
swappg1 = *+1
	lda #$00
	sta fac2+1	; c64: $6a
swappg2 = *+1
	lda #$00
	sta fac2+3	; c64: $6c
swapsiz = *+1
	lda #$00
	sta fac2+4	; c64: $6d
	ldy #0
	sty fac2	; c64: $69
	sty fac2+2	; c64: $6b
swapr1:
	lda (fac2),y	; c64: ($69)
	tax
	lda (fac2+1),y	; c64: ($6b)
	sta (fac2),y	; c64: ($69)
	txa
	sta (fac2+1),y	; c64: ($6b)
	iny
	bne swapr1
	inc fac2+1	; c64: $6a
	inc fac2+3	; c64: $6c
	dec fac2+4	; c64: $6d
	bne swapr1
	pla
	sta r6510
	cli
	jsr rsinabl
	lda #$a0
	sta tdisp+31
	rts

getversn:
	lda #version_length
	sta var
	lda #<version
	sta var+1
	lda #>version
	sta var+2
	ldx #a_string ;a$
	jsr putvar

	ldy #4
loop:
	lda versnum,y
	sta var,y
	dey
	bpl loop
	ldx #15
	jmp putvar ;lp

scrnset:
	sta blnkflag
	sta $d030
	stx $d011
	rts

; find a basic variable

findvar1:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr ptrget1
	jmp @>exitint

; relink basic program lines

relink:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr linkprg
	jmp @>exitint

fpout:
; FIXME: output floating point value in .a
;	lda r6510
;	pha
;	lda #r6510_normal
;	sta r6510
	tax
	lda #$00
;	jsr bank_in_vars
	jsr jfout	; c128: $8e32. print 16-bit digit, > .a, < .x
;	jsr $bddd	;  c64: $bddd. convert contents of fac1 to string, pointed to by > .a < .y
;	jsr bank_in_prg
	jmp @>exitint


; make a dynamic string

makeroom:
	tax
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	txa
	jsr makerm1
@exitint:
; local label; the global label is $ff37
	pla
	sta r6510
	rts

mlgosub:
	lda txtptr+1	; c64: $7b
	pha
	lda txtptr	; c64: $7a
	pha
	lda curlin+1	; c64: $3a
	pha
	lda curlin	; c64: $39
	pha
	lda #$8d	; 'gosub' token
	pha
mlresume:
	lda #r6510_normal
	sta r6510
mljump:
	jsr mlgoto
	jmp newstt	; c64: $a7ae

mlgoto:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	stx linnum	; c64: $14
	sty linnum+1	; c64: $15
	jsr goto	; c64: $a8a3, 3 bytes past GOTO
	pla
	sta r6510
	rts

;* output a$
outspace:
	txa
	beq outspac2
outspac1:
; .x: number of spaces to output
	lda #" "
	jsr xchrout
	dex
	bne outspac1
outspac2:
	rts

outcomma:
	lda #0
outcomm1:
	clc
	adc #10
	bcs outastr0
	cmp modclm
	bcc outcomm1
	sec
	sbc modclm
	tax
	jsr outspace
outastr0:
	jsr chrget
	beq outastr2
outastr1:
	cmp #";"
	beq outastr0
	cmp #comma	; ","
	beq outcomma
	jsr getstr
	stx var+1
	sty var+2
	sta var
	jsr outstr
	jsr chrgot
	bne outastr1
outastr2:
	rts
outastr:
	jsr chrgot
	bne outastr1
	ldx #1
	jmp prtvar

getstr:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr frmeval	; c64: $ad9e
	bit valtyp	; c64: $0d, $80=numeric
	bpl getval
	jsr $b6a3	; c64: $b6a3: frestr
	tax
	jmp getstr1
getval:
	jsr $bddd
	lda #<$100
	sta $22
	lda #>$100
	sta $23
	ldx #0
getval1:
	lda $100,x
	beq getstr1
	inx
	bne getval1
getstr1:
	pla
	sta r6510
	txa
	ldx $22
	ldy $23
	rts

fnvar0:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr $b08b	; c64: ptrget
	ldx varpnt	; c64: $47
	ldy varpnt+1	; c64: $48
	pla
	sta r6510
	rts
fnvar2:
	jsr fnvar
	stx curlin	; c64: $14
	sty curlin+1	; c64: $15
	rts

evalstr0:
	lda r6510
	sta rom0
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr frmeval	; c64: $ad9e
	jsr frestr	; c64: $b6a3
	pha
	lda rom0
	sta r6510
	pla
	ldx index_24	; c64: $22
	ldy index_24+1	; c64: $23
	rts

evalbyt0:
	lda r6510
	sta rom0
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr chrgot	; c64: $0079
	jsr $b79e	; c64: $b79e. FIXME: 3 bytes past getbytc
	lda rom0
	sta r6510
	rts

evalint0:
	lda r6510
	sta rom0
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr frmnum
	jsr getadr
	ldx linnum	; c64: $14
	ldy linnum+1	; c64: $15
	lda rom0
	sta r6510
	rts

evalfil0:
	lda r6510
	sta rom0
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr getfile
	lda rom0
	sta r6510
	rts

convchr0:
	jsr chkspcl
	cmp #0
	bmi convchr1
	cmp #64
	bcc convchr1
	eor #64
convchr1:
	and #127
	rts

room_in_swapper = $cd00 - *

	align  room_in_swapper,0

; interface page jmp table

hcd00:
	jmp outastr
hcd03:
	jmp usetbl0
hcd06:
	jmp swapper0
hcd09:
	jmp swapagn0
hcd0c:
	jmp trace0
hcd0f:
	jmp chkspcl0
hcd12:
	jmp convchr0
hcd15:
	jmp fnvar0
hcd18:
	jmp fnvar2
hcd1b:
	jmp evalstr0
hcd1e:
	jmp evalbyt0
hcd21:
	jmp evalint0
hcd24:
	jmp evalfil0

chkspcl0:
	cmp #$85
	bcc chkspcl1
	cmp #$8d
	bcs chkspcl1
	stx cxsav
	sec
	sbc #$85
	tax
	lda spchars,x
	ldx cxsav
chkspcl1:
	cmp #0
	rts

usetbl0:
	sta 780
	stx 781
	sty 782

; get index into jump table in X
	asl
	tax

; preserve ROM selection state

	lda r6510
	pha

; make sure we can access RAM under the BASIC ROM

	lda #r6510_basic_ram
	sta r6510

; get the address from the jump table with interrupts disabled
; to avoid race conditions where interrupt code changes addresses in the
; jump table
; puts the address in Y(lo)/X(hi)

	php
	sei
	lda jmptbl,x
	tay
	lda jmptbl+1,x
	tax
	plp

; if the target is under the kernel, call using "caller" swap code to visible memory

	lda #<caller
	sta jump+1
	lda #>caller
	sta jump+2
	cpx #>kernal_rom_start
	bcs jump
	sty jump+1
	stx jump+2
	ldx 781
	ldy 782

; jump to the target (self modifying code sets the address)

jump:
	jsr $ffff
	sta 780
	pla
	sta r6510
	lda 780
nothing:
	rts

; new system chrout routine

newout:
	sta ptr1	; same: $9e
	lda r6510
	pha
	lda #r6510_basic_ram
	sta r6510
	lda ptr1	; same: $9e
	jsr out
	sta ptr1	; same: $9e
	pla
	sta r6510
	lda ptr1	; same: $9e
	rts
oldout:
	jmp $ffff

; raster interrupt routine

raster:
	lda #$00
	bne rast1
	lda scnmode
	bne rast0
	lda #23
	sta $d018
rast0:
	lda #106
	sta $d012
	lda #1
	sta $d019
	inc raster+1
	jmp $ff37	; c64: $febc. pull registers from stack, RTI

rast1:
	nop
	lda mupcase
	and #1
	asl
	eor #23
	sta $d018
	lda #234
	sta $d012
	lda #1
	sta $d019
	dec raster+1
	inc jiffy

newirq:
	lda r6510
	pha
	lda #$36
	sta r6510
irqt:
	lda #$00
	beq newirq0
	dec irqt+1
	bne newirq1
newirq0:
	jsr irq
	lda irqcount
	sta irqt+1
newirq1:
	pla
	sta r6510
	jmp @>exitint	; c64: $ea81

; far call to the error handler

farerr:
	lda #$37
	sta r6510
	jmp error

room_in_interface_page = $ce00 - *

	align  room_in_interface_page,0

; buffer page

d1str:
	cbm "           "
spchars:
	byte ",:",34,"*?=",13,"^"

; pad up to fbuf start
	align  fbuf-*,0
; fbuf:
	align $20, 20

; pad up to buf2 start
	align  buf2-*,0
; buf2:
	align $20, 80

; pad up to buffer start
	align  buffer-*,0
; buffer:
	align $20, 80

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
	cbm version_string
version_length = * - version

; version in floating point

versnum:
	byte $81, $00, $00, $00, $00 ; 1.0
;	byte $81, $19, $99, $99, $9a ; 1.2
;	byte $81, $26, $66, $66, $66 ; 1.3
;	byte $82, $00, $00, $00, $00 ; 2.0
