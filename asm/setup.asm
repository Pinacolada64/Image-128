logoff:
	stx curdsp
	lda #0
	sta chatpage
	sta sndrept
	lda #11
	sta varbuf
	lda #<d1str
	sta varbuf+1
	lda #>d1str
	sta varbuf+2
	ldx #var_d1_string
	jsr putvar
	lda #$a0
	sta tdisp+30
	sta tdisp+31
	sta tdisp+32
	rts

setbaud:
	txa
	jmp rsbaud

; 128, 11/05/2026: the lightbar's mHz checkmark (flag 62, $3e) shows the
; CPU's speed: on at 2 MHz ($d030 bit 0), off at 1 MHz. It only watches:
; whatever sets the speed (BASIC 7's fast and slow, ++ net's calls in 80
; columns, the screen blanker's scrnset) shows within an irq5 pass (8
; IRQs, about 0.13 s), and a checkmark set or cleared by hand (the f-keys,
; &,52,62,x) goes back to the speed at the next pass, as the carrier's does.
; (In setup.asm, as the resident ML from $e000 is full: irqtbl's carrier
; slice comes here, then goes on to irq5)
irq5_128:
	jsr speed_update
	jmp irq5
speed_update:
	lda $d030
	lsr		; bit 0, the speed, into the carry
	lda flag_mhz_addr
	bcc speed_slow
	ora #flag_mhz_l_mask
	bne speed_set	; (always)
speed_slow:
	and #~flag_mhz_l_mask
speed_set:
	sta flag_mhz_addr
	rts
