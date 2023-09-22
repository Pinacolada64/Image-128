{def:revision = {buildrev:.\revision}}
{'info:Code revision {usedef:revision}.}

{include:"equates.asm"}

;;;
;;; rs232: swap to $0c00
;;;

rs232_load_address = *
{include:rs232.bin}
align $100,$00
rs232_pages = (* - rs232_load_address) / 256 ; should be 2

;;;
;;; buffer page: swap to $0e00
;;;

buffer_page_start = *
{include:buffer-page.asm}
align $100,$00
buffer_pages = (* - buffer_page_start) / 256

;;;
;;; wedge: swap to $2f00
;;;

wedge_load_address = *
wedge_swap_address = $2f00

{include:"wedge.bin"}

align $0100,$00
wedge_pages = (* - wedge_load_address) / 256

;;;
;;; & jump table: swap $1a00
;;; just addresses, no need for a .bin file
;;;

wedge_load_address = *
wedge_swap_address = $1a00
{include:"jmptb.asm"}
; pad to the start of the next module
	align $100,0
wedge_pages = (* - wedge_load_address) / 256

;;;
;;; intro "protocol": swap to $1c00
;;; this should come after all the .bin files are included
;;; since all the module sizes and load addresses have been
;;; defined. the *_page_size label is used by the swapper to
;;; move blocks of code to their *_load_address location.
;;;

intro_load_address = *
intro_swap_address = protostart

{include:"intro.bin"}
align $100,$00
intro_pages = (* - intro_load_address) / 256

;;;
;;; text editor: $7000
;;;

editor_load_address = *
embed "editor.bin"
align $100,$00
editor_pages = (* - editor_load_address) / 256

;;;
;;; garbage collection: $8000
;;;

gc_load_address = *
embed "gc.bin"
; pad to the start of the next module:
align $100,$00
gc_pages = (* - gc_load_address) / 256

;;;
;;; extended command set: $8400
;;;

ecs_load_address = *
ecs_swap_address = $e400
embed "ecs.bin"
; pad to the start of the next module
align $100,$00
ecs_pages = (* - ecs_load_address) / 256

;;;
;;; structures
;;;

struct_load_address = *
struct_swap_address = $ee00
embed "struct.bin"
; pad to the start of the next module
	area $100,$0
struct_pages = (* - struct_load_address) / 256

;;;
;;; swap1: $9400
;;;

swap1_load_address = *
swap1_swap_address = $f800
embed "swap1.bin"
; pad to the start of the next module
	area $0f00, $00
swap1_pages = (* - swap1_load_address) / 256

;;;
;;; swap2: $9800
;;;

swap2_load_address = *
swap2_swap_address = $f800
embed "swap2.bin"
; pad to the start of the next module:
align $100,$00
swap2_pages = (* - swap2_load_address) / 256

;;;
;;; swap3: $9c00
;;;

swap3_load_address = *
swap3_swap_address = $fc00
embed "swap3.bin"
; pad to the start of the next module:
align $100,$00
; pad to the start of the next module
	align $100,$00
swap3_pages = >(* - swap3_load_address) / 256

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

align $100,$00

addrcheck $ca00

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
	lda #$a0	; reverse space
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
@:
	lda versnum,y
	sta var,y
	dey
	bpl <@
	ldx #15
	jmp putvar ;lp

scrnset:
	sta blnkflag
	sta $d030
	stx $d011
	rts

; find a BASIC variable

findvar1:
; TODO: jsr bank_in_vars
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr ptrget1
	jmp >@exitint

; relink BASIC program lines

relink:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr linkprg
	jmp >@exitint

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
;	jsr fout	;  c64: $bddd. convert contents of fac1 to string, pointed to by > .a < .y
;	jsr bank_in_prg
	jmp >@exitint

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
	jsr goto+3	; c64: $a8a3, 3 bytes past GOTO
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
	jsr >@outstr
	jsr chrgot
	bne outastr1
outastr2:
	rts
@outastr:
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
	jsr frestr	; c64: $b6a3: frestr
	tax
	jmp getstr1
getval:
	jsr fout	; c64: $bddd
	lda #<$100
	sta index_24	; c64: $22
	lda #>$100
	sta index_24+1	; c64: $23
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
	ldx index_24	; c64: $22
	ldy index_24+1	; c64: $23
	rts

fnvar0:
	lda r6510
	pha
	lda #r6510_normal
	sta r6510
	jsr chkcom
	jsr ptrget	; c64: $b08b
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
	jsr chkcom	; c64: $aefd
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
	jsr getbytc+3	; c64: $b79e. FIXME: getbytc+3
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

	align $100,$00

; interface page jmp table: $1b00

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
	lda >@spchars,x
	ldx cxsav
chkspcl1:
	cmp #0
	rts

usetbl0:
	sta sareg	; c64: 780
	stx sxreg	; c64: 781
	sty syreg	; c64: 782

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
; (calls.asm)

	lda #<caller
	sta jump+1
	lda #>caller
	sta jump+2
	cpx #>kernal_rom_start
	bcs >@jump
	sty >@jump+1
	stx >@jump+2
	ldx sxreg	; c64: 781
	ldy syreg	; c64: 782

; jump to the target (self modifying code sets the address)

@jump:
	jsr $ffff
	sta sareg	; c64: 780
	pla
	sta r6510
	lda sareg	; c64: 780
@nothing:
; no reference in this file
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
	jmp >@exitint	; c64: $ea81

; far call to the error handler

farerr:
	lda #$37
	sta r6510
	jmp error

	align $0100,$00	; pad to $ce00
