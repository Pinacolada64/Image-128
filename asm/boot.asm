; boot.asm -- "boot 128": loads Image BBS 128's ML and starts it.
;
; LOAD "BOOT 128",8 and RUN (or RUN "BOOT 128"). A BASIC line, 10 SYS7181,
; starts the code below, which copies the loader into the cassette buffer
; ($0b00) and runs it there: the ML loads over $1c01, where this program
; is. The loader loads each part of the ML where it runs (ml.asm and
; tools/split-ml.py: the modules into bank 1, the rest into bank 0) from
; the device this was loaded from, then jumps to intro (protostart).
;
; c64: "boot" loaded at $02a7 and took over BASIC's IMAIN vector to run
; itself; on the 128 that address is the KERNAL's own bank-switching code.

{def:direct_rom}
{include:"equates.asm"}

loader_run = $0b00	; cassette buffer

	orig $1c01

; BASIC stub: 10 SYS7181
	byte $0b,$1c,$0a,$00,$9e,$37,$31,$38,$31,$00,$00,$00

; copy the loader to loader_run and go (counting up: it's over 128 bytes)
	ldy #0
copy:
	lda loader,y
	sta loader_run,y
	iny
	cpy #loader_end-loader
	bne copy
	jmp loader_run

; ----- assembled here, runs at loader_run: below this line, only
; relative branches, and addresses written as loader_run+(label-loader)

loader:
	lda #0
	jsr setmsg		; no "LOADING" messages over the screen
	ldx #0
next:
	stx loader_run+(part_index-loader)
	lda loader_run+(parts-loader),x	; bank+1, or 0 at the end
	beq done
	sec
	sbc #1
	ldx #0			; the filename is in bank 0
	jsr setbnk
	lda #1			; lfn
	ldx fa			; the device this program came from
	ldy #1			; secondary address 1: load where the file says
	jsr setlfs
	ldx loader_run+(part_index-loader)
	clc
	lda loader_run+(parts-loader)+2,x	; name's offset from loader
	adc #<loader_run
	tay
	lda #>loader_run
	adc #0
	pha
	lda loader_run+(parts-loader)+1,x	; name length
	tax
	tya
	tay
	pla
	; setnam: .a length, .x/.y address
	sta loader_run+(name_hi-loader)
	sty loader_run+(name_lo-loader)
	txa
	ldx loader_run+(name_lo-loader)
	ldy loader_run+(name_hi-loader)
	jsr setnam
	lda #0			; load, not verify
	jsr loadf
	bcs failed
	ldx loader_run+(part_index-loader)
	inx
	inx
	inx
	bne next		; always
done:
	jmp protostart		; intro

; a part didn't load: print its name and stop
failed:
	ldx loader_run+(part_index-loader)
	ldy loader_run+(parts-loader)+2,x	; name's offset
	lda loader_run+(parts-loader)+1,x	; and length
	sta loader_run+(part_index-loader)
fail_name:
	lda loader_run,y
	jsr chrout
	iny
	dec loader_run+(part_index-loader)
	bne fail_name
	lda #'?'
	jsr chrout
	jmp ready

part_index:
	byte 0
name_lo:
	byte 0
name_hi:
	byte 0

; bank+1, name length, name offset from loader
parts:
	byte 1, name_buf_end-name_buf, name_buf-loader
	byte 1, name_low_end-name_low, name_low-loader
	byte 2, name_mod_end-name_mod, name_mod-loader
	byte 1, name_res1_end-name_res1, name_res1-loader
	byte 1, name_res2_end-name_res2, name_res2-loader
	byte 0

name_buf:
	ascii "ml.buf"
name_buf_end:
name_low:
	ascii "ml.low"
name_low_end:
name_mod:
	ascii "ml.mod"
name_mod_end:
name_res1:
	ascii "ml.res1"
name_res1_end:
name_res2:
	ascii "ml.res2"
name_res2_end:

loader_end:
; (the copy loop's "cpy #loader_end-loader" stops the build if this
; ever outgrows the cassette buffer's 256 bytes)
