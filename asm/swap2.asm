{include:equates.asm}
orig protostart
; .pseudopc protostart {
; .namespace swap2 {

@hc000:
	jmp term
@hc003:
	jmp >@chatmode
@hc006:
	jmp btmvar
@hc009:
	jmp >@convert
@hc00c:
	jmp sound

; jump table routines

@xchrout:
	sta $fe
	lda #24
	jmp usetbl1
@usevar:
	lda #29
	jmp usetbl1
@chatchk:
	lda #43
	jmp usetbl1
prtvar:
	lda #45
	jmp usetbl1
@prtvar0:
	lda #46
	jmp usetbl1
getkbd:
	lda #48
	jmp usetbl1
@getmod:
	lda #49
	jmp usetbl1
outscn0:
	sta $fe
@outscn:
	lda #50
	jmp usetbl1
outmod:
	lda #51
	jmp usetbl1
output:
	lda #55
	jmp usetbl1

; chat mode
@chatmode:
	lda #$00
	sta $fe
	sta chatpage
	sta sndrept
	ldx #var_c1_string
	jsr prtvar0
	lda #1
	sta inchat
	lda case
	pha
	lda #0
	sta case
chat1:
	jsr chatchk
	beq chat3
	lda carrst
	bpl chat1a
	lda #0
	sta carrst
chat1a:
	jsr getkbd
	bne chat2
	jsr <@getmod
	beq chat1
chat2:
	cmp #cursor_home
	beq chat1
	jsr <@xchrout
	jmp chat1
chat3:
	pla
	sta case
	lda #0
	sta inchat
	sta usrlin
	ldx #var_c2_string
	jsr prtvar0
	lda editor
	and #130	; %1000 0010
	beq chat5
	ldx #var_c3_string
	jsr prtvar0
chat5:
	ldx #var_co_string
	jmp btmvar

; terminal mode

term0:
	lda #0
	sta interm
	rts
term:
	lda #1
	sta interm
	lda 653
	cmp #6
	beq term0
	jsr getkbd
	beq term1
term2:
	sta $fe
	jsr outmod
term1:
	jsr <@getmod
	lda $fe
	beq term
	jsr outansi
	jmp term

; output to screen, interpret ansi
outansi:
	lda flag_ans_addr
	and #flag_ans_l_mask
	bne outansi2
	jmp <@outscn
outansi1:
	inx
	stx ansiptr
	rts
outansi2:
	lda $fe
	ldx ansiptr
	sta ansibuf,x
	lda ansibuf
	cmp #27
	bne outansi0
	cpx #1
	bcc outansi1
	lda ansibuf+1
	cmp #'['
	bne outansi0
	cpx #2
	bcc outansi1
	cpx #14
	bcs outansi0
	lda ansibuf,x
	cmp #';'
	beq outansi1
	cmp #'0'
	bcc outansi3
	cmp #':'
	bcc outansi1
outansi3:
	ldx #2
	stx ansiptr
	cmp #'m'
	beq ansim
	cmp #'A'
	beq ansia
	cmp #'B'
	beq ansib
	cmp #'C'
	beq ansic
	cmp #'D'
	beq ansid
	cmp #'F'
	beq ansih
	cmp #'H'
	beq ansih
	cmp #'J'
	beq ansij
outansi0:
	ldx #0
	stx ansiptr
	stx ansibuf
	stx ansibuf+1
	rts

ansim:
	jsr ansiparm
	bcs outansi0
	cmp #0
	bne ansim1
	lda #reverse_off
	jsr outscn0
	jmp ansim
ansim1:
	cmp #7
	bne ansim2
	lda #reverse_on
	jsr outscn0
	jmp ansim
ansim2:
	cmp #30
	bcc ansim
	cmp #38
	bcs ansim
	sec
	sbc #30
	tax
	lda >@ansiclrs,x
ansim3:
	jsr outscn0
	jmp outansi0

ansib:
	lda #cursor_down
	byte $2c
ansic:
	lda #cursor_right
	byte $2c
ansid:
	lda #cursor_left
	byte $2c
ansia:
	lda #cursor_up
ansia1:
	sta reptchr
	jsr ansiparm
	bcc ansia2
	lda #1
ansia2:
	sta reptcnt
	jsr ansirept
	jmp outansi0

ansij:
	lda #clear_screen
	jmp ansim3

ansih:
	jsr ansiparm
	bcs outansi0
	sec
	sbc #1
	sta ansiposv
	lda 211
	sta ansiposh
	jsr ansiparm
	bcs ansih1
	sec
	sbc #1
	sta ansiposh
ansih1:
	lda #cursor_home
	jsr outscn0
	lda #cursor_down
	ldx ansiposv
	jsr ansirpt0
	lda #cursor_right
	ldx ansiposh
	jsr ansirpt0
	jmp outansi0

ansirpt0:
	sta reptchr
	stx reptcnt
ansirept:
	lda reptcnt
	beq ansirpt1
	lda reptchr
	jsr outscn0
	dec reptcnt
	jmp ansirept
ansirpt1:
	rts

reptcnt:
	byte 0
reptchr:
	byte 0
ansibuf:
	ascii "                  "
ansiptr:
	byte 0
ansiposh:
	byte 0
ansiposv:
	byte 0
ansiprm:
	byte 0
@ansiclrs:
	byte chr_black, chr_red, chr_green, chr_yellow
	byte chr_blue, chr_purple, chr_cyan, chr_white

ansiparm:
	lda #0
	sta ansiprm
	ldx ansiptr
	lda ansibuf,x
	inc ansiptr
	cmp #';'
	bne ansiprm2
ansiprm1:
	ldx ansiptr
	lda ansibuf,x
	inc ansiptr
ansiprm2:
	cmp #'0'
	bcc ansiprm3
	cmp #':'
	bcc ansiprm4
	clc
	lda ansiprm
	rts
ansiprm3:
	sec
	lda ansiprm
	rts
ansiprm4:
	pha
	lda ansiprm
	asl
	asl
	clc
	adc ansiprm
	asl
	sta ansiprm
	pla
	sec
	sbc #'0'
	clc
	adc ansiprm
	sta ansiprm
	jmp ansiprm1

; print string variable to bottom
btmvar:
	inc scnlock
	lda scnmode
	bne btm2
	ldy #15
	lda #$a0
btm0:
	sta adisp+24,y
	dey
	bpl btm0
	jsr <@usevar
	ldy #0
	ldx #0
	lda varbuf
	beq btm2
	cmp #16
	bcs btm1
	lda #16
	sec
	sbc varbuf
	lsr
	tax
btm1:
	lda (varbuf+1),y
	jsr chkspcl
	cmp #0
	bmi btm1a
	cmp #64
	bcc btm1a
	eor #64
btm1a:
	ora #$80
	sta adisp+24,x
	inx
	cpx #16
	bcs btm2
	iny
	cpy varbuf
	bcc btm1
btm2:
	dec scnlock
	rts

isalpha:
	cmp #65
	bcc isalpha0
	cmp #91
	bcc isalpha1
	cmp #193
	bcc isalpha0
	cmp #219
	bcc isalpha1
isalpha0:
	clc
	rts
isalpha1:
	sec
	rts

lotbl:
	byte <convnam,<convdsk
	byte <convimg,<chkspcl
hitbl:
	byte >convnam,>convdsk
	byte >convimg,>chkspcl

convert0:
	rts
@convert:
	dex
	cpx #4
	bcs convert0
	lda lotbl,x
	sta convs2+1
	lda hitbl,x
	sta convs2+2
	ldx #var_an_string
	jsr <@usevar
	ldy #0
	ldx #0
convs1:
	cpy varbuf
	beq convs3
	lda (varbuf+1),y
convs2:
	jsr convdsk
	sta (varbuf+1),y
	iny
	bne convs1
convs3:
	rts

convd0:
	ascii ",:"
	ascii "{f5}"
	ascii "*?="
	ascii "{f6}{f8}"
convdsk:
	cmp #133
	bcc convd1
	cmp #140
	bcs convd1
	sbc #132
	tax
	lda convd0,x
convd1:
	rts

convnam:
	cmp #apostrophe
	beq convn3
	jsr isalpha
	bcs convn1
	ldx #0
	rts
convn1:
	cpx #0
	bne convn2
	ora #$80
	inx
	rts
convn2:
	and #$7f
	inx
convn3:
	rts

convi0:
	ascii "$,*?:=;"
convimg:
	ldx #6
convi1:
	cmp convi0,x
	beq convi2
	dex
	bpl convi1
	rts
convi2:
	lda #'-'
	rts

sound:
	cpx #255
	bne soundx
	lda #0
	sta sndrept
	rts
soundx:
	lda sndrept
	beq sound1
sound0:
	rts
sound1:
	sty sndrept
	cpx #0
	bne sound3
	lda flag_bel_addr
	and #flag_bel_r_mask
	bne sound0
	ldx #0
sound3:
	txa
	asl
	asl
	asl
	asl
	tax
	lda #$0f
	sta $d418
	lda #0
	sta $d404
	sta $d40b
	sta $d412
	lda sndtbl+4,x
	and #$fe
	sta sndwav1
	lda sndtbl+9,x
	and #$fe
	sta sndwav2
	lda sndtbl+14,x
	and #$fe
	sta sndwav3
	lda sndtbl+15,x
	pha
	lsr
	lsr
	lsr
	lsr
	tay
	lda timetbl,y
	sta sndtim1
	sta sndtim1a
	pla
	and #$0f
	tay
	lda timetbl,y
	sta sndtim2
	sta sndtim2a
	ldy #0
sound4:
	tya
	pha
	lda sndvec,y
	tay
	lda sndtbl,x
	sta $d400,y
	inx
	pla
	tay
	iny
	cpy #15
	bne sound4
	rts

sndvec:
	byte 0,1,5,6,4,7,8,12,13,11,14,15,19,20,18

timetbl:
	byte 010,020,030,040
	byte 050,060,070,080
	byte 090,100,110,120
	byte 150,180,240,001

; }
; }
