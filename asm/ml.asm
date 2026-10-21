{def:revision = {buildrev:.\revision}}
{'info:Code revision {usedef:revision}.}

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

;;;
;;; Everything is assembled where it runs (or, for the modules, where it
;;; waits swapped out), in address order: orig only moves forward, so a
;;; part that outgrows its space stops the build. tools/split-ml.py cuts
;;; the result into the files the boot loads. Addresses: equates.asm.
;;;

;;;
;;; buffer page: $0e00
;;;

	orig bufpage
{include:buffer-page.asm}

;;;
;;; wedge jump table ($1900), RS-232 jump table ($1912) and interface jump
;;; table ($1927). The RS-232 entries are rts until a driver is loaded
;;; (&,16); the wedge's entries go through glue.asm into cfg_rom.
;;;

	orig wedgemem
	jmp wedge_far+0		; trapoff
	jmp wedge_far+7		; trapon
	jmp wedge_far+14	; loadprg
	jmp wedge_far+21	; arraysav
	jmp wedge_far+28	; arrayres
	jmp wedge_far+35	; forcegc

	orig rs232
	area 21, $60		; rts

	orig outastr
hcd00:
	jmp outastr_ml
hcd03:
	jmp usetbl_far	; the wedge calls this in cfg_rom
hcd06:
	jmp swapper0
hcd09:
	jmp swapagn0
hcd0c:
	jmp trace_far	; the wedge calls this in cfg_rom
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


;;;
;;; & jump table: $1a00
;;;

	orig jmptbl
{include:"jmptb.asm"}

;;;
;;; intro "protocol": runs at protostart, once, at boot (and setup again
;;; from im's "sys 7171")
;;;

	orig protostart
{include:"intro.asm"}

;;;
;;; wedge: $2f00
;;;

	orig wedge_exec_address
	embed "wedge.bin"
	align $100,$00
wedge_pages = (* - wedge_exec_address) / 256

;;;
;;; glue: $3600-$3fff
;;;

	orig glue
{include:"glue.asm"}
	addrcheck $4000

;;;
;;; modules: each starts at its *_load_address from equates.asm, the one
;;; place module addresses are set (intro.asm and the swapper use them
;;; too). orig only moves forward, so a module that outgrows its slot
;;; stops the build instead of running into the next one. Where each one
;;; runs (*_exec_address) and waits swapped out (*_swap_address) is in
;;; equates.asm as well.
;;;

;;;
;;; text editor: $7000
;;;

	orig editor_load_address
	embed "editor.bin"
	align $100,$00
editor_pages = (* - editor_load_address) / 256

;;;
;;; garbage collection: $8000
;;;

	orig gc_load_address
	embed "gc.bin"
	align $100,$00
gc_pages = (* - gc_load_address) / 256

;;;
;;; extended command set: $8400
;;;

	orig ecs_load_address
	embed "ecs.bin"
	align $100,$00
ecs_pages = (* - ecs_load_address) / 256

;;;
;;; structures: $8e00
;;;

	orig struct_load_address
	embed "struct.bin"
	align $100,$00
struct_pages = (* - struct_load_address) / 256

;;;
;;; swap1: $9400
;;;

	orig swap1_load_address
	embed "swap1.bin"
	align $100,$00
swap1_pages = (* - swap1_load_address) / 256

;;;
;;; swap2: $9800
;;;

	orig swap2_load_address
	embed "swap2.bin"
	align $100,$00
swap2_pages = (* - swap2_load_address) / 256

;;;
;;; swap3: $9c00
;;;

	orig swap3_load_address
	embed "swap3.bin"
	align $100,$00
swap3_pages = (* - swap3_load_address) / 256

;;;
;;; resident ML: $c000-$cfff, then $e000-$feff
;;;

	orig romtab
{include:"romtab.asm"}

{include:"strio.asm"}

{include:"mcicm.asm"}

{include:"chrio.asm"}

{include:"dskio.asm"}

{include:"setup.asm"}

{include:"varbl.asm"}

	addrcheck resident_lo_end

	orig resident_hi

{include:"irqhn.asm"}

{include:"miscl.asm"}

{include:"shdlr.asm"}

{include:"vdc.asm"}

{include:"modem.asm"}

{include:"calls.asm"}

swapper0:
	sta swappg1	; source page
	sty swappg2	; destination page
	stx swapsiz	; how many pages to swap
swapagn0:
	lda #$d3	; reverse capital "S"
	sta tdisp+31
	jsr rsdisab
	sei
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
; two pointers: fac2/fac2+1 (c64: $69/$6a) and fac2+2/fac2+3 (c64: $6b/$6c).
; This used (fac2+1) for the second, which overlaps the first and swapped
; each page with page zero.
swapr1:
	lda (fac2),y	; c64: ($69)
	tax
	lda (fac2+2),y	; c64: ($6b)
	sta (fac2),y	; c64: ($69)
	txa
	sta (fac2+2),y	; c64: ($6b)
	iny
	bne swapr1
	inc fac2+1	; c64: $6a
	inc fac2+3	; c64: $6c
	dec fac2+4	; c64: $6d
	bne swapr1
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
	ldx #var_a_string ;a$
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
	jmp ptrget1

; relink BASIC program lines

relink:
	jmp linkprg

; FAC1 to text at $0100 (c64: jsr $bddd, FOUT): mcicm.asm's cvar prints it
fpout:
	jmp fout

; make a dynamic string

makeroom:
	jmp makerm1

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
mljump:
	jsr mlgoto
	jmp farjmp_newstt	; c64: $a7ae

; set txtptr to line .x (lo) .y (hi): GOTO past its linget
mlgoto:
	stx linnum	; c64: $14
	sty linnum+1	; c64: $15
	jmp gotol	; c64: jsr $a8a3 (goto+3)

;* output a$
outspace:
	txa
	beq outspac2
outspac1:
; .x: number of spaces to output
	lda #$20	; " "
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
	cmp #$3b	; semicolon
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
outastr_ml:
	jsr chrgot
	bne outastr1
	ldx #1
	jmp prtvar

getstr:
	jsr frmevl	; c64: $ad9e
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
	txa
	ldx index_24	; c64: $22
	ldy index_24+1	; c64: $23
	rts

fnvar0:
	jsr chkcom
	jsr ptrget	; c64: $b08b
	ldx varpnt	; c64: $47
	ldy varpnt+1	; c64: $48
	rts
fnvar2:
	jsr fnvar
	stx curlin	; c64: $14
	sty curlin+1	; c64: $15
	rts

evalstr0:
	jsr chkcom	; c64: $aefd
	jsr frmevl	; c64: $ad9e
	jsr frestr	; c64: $b6a3
	ldx index_24	; c64: $22
	ldy index_24+1	; c64: $23
	rts

evalbyt0:
	jsr chkcom
	jsr chrgot	; c64: $0079
	jsr getbytc	; c64: $b79e (getbytc+3): the 128's has no chrget
	rts

evalint0:
	jsr chkcom
	jsr frmnum
	jsr getadr
	ldx linnum	; c64: $14
	ldy linnum+1	; c64: $15
	rts

evalfil0:
	jsr chkcom
	jsr getfile
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
	sta sareg	; c64: 780
	stx sxreg	; c64: 781
	sty syreg	; c64: 782

; get index into jump table in X
	asl
	tax

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

; if the target is in a swapped-out module (bank 1, gc_swap_address up to
; the ML at romtab), call it through caller (calls.asm), which swaps it in;
; anything else is visible as it is

	lda #<caller
	sta jump+1
	lda #>caller
	sta jump+2
	cpx #>gc_swap_address
	bcc usetbl2
	cpx #>romtab
	bcc jump
usetbl2:
	sty jump+1
	stx jump+2
	ldx sxreg	; c64: 781
	ldy syreg	; c64: 782

; jump to the target (self modifying code sets the address)

jump:
	jsr $ffff
; the result in sareg, for BASIC's peek (sub.modem: &,4 then
; peek({sym:sareg})), and the flags from it, as the c64 left them
	sta sareg	; c64: 780
	lda sareg	; c64: 780
nothing:
	rts

; new system chrout routine

; (reached through newout_far in glue.asm, in cfg_ml)
newout:
	jmp out

; the KERNAL's own CHROUT handler, which iosetup saves in oldout_vec
oldout:
	jsr farcall
	byte cfg_rom
oldout_vec:
	word $ffff
	rts

; Image's IRQ work, once a frame: reached through irq_far (glue.asm) in
; cfg_ml on the VIC raster interrupt, before the KERNAL's own handler.
;
; c64: "raster" took over the VIC's raster interrupt and split the screen
; at lines 106 and 234, switching $d018 so the screen mask (the bottom
; rows) could use the uppercase/graphics set while the rest followed the
; user's case (mupcase); its second half ran this. FIXME (128): the
; screen editor rewrites $d018 from its shadow ($0a2c) every frame, so
; that split needs doing the editor's way; until then the screen mask
; uses the same character set as the rest of the screen.

newirq:
	inc jiffy	; c64: rast1, once a frame
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
	rts

; far call to the error handler

farerr:
	jmp farjmp_error

	addrcheck resident_hi_end
