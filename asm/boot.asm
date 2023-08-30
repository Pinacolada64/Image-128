{include:"equates.asm"}

orig $02a7

; the boot program!

; put back correct basic main loop address

boot:
	lda #<$4db7	; c64: $a483
	sta IMAIN	; $302
	lda #>$4db7	; c64: $a483
	sta IMAIN+1	; $303

; our screen colors

	lda #$00
	sta $d020
	sta $d021
	lda #'{clear}'
	jsr chrout	; was $e716

; kernal messages off

	lda #$00	; added by pinacolada, chrout trashes .a
	jsr setmsg	; $ff90

; load the ml

	lda #filename_length
	ldx #<file
	ldy #>file
	jsr setnam	; $ffbd
	lda #1
	sta sa	; $b9: secondary file address
	lda #0
	jsr loadf	; $ffd5

; run it

	jsr linkprg	; c64: $a533
	lda #0
	jsr run	; c64: $a871
	jmp newstt	; c64: $a7ae

; the ml filename:

file:
	ascii "ml 128 1.0"
	filename_length = * - file

; write $00 bytes from * to start of vector table at $300
	align $100,$00

; the boot vectors
; IERROR:
	word $4d3f	; c64: $e38b. error message handler
; IMAIN:
	word boot
