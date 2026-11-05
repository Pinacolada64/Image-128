; netlist.asm -- "++ netlist": one NetSub's definition (a file
; nm.netsub1-nm.netsub60) in memory, for i/NM.netsub1, 3 and 4, i/lo/ns
; and i/SM.reledit (a$="netlist":gosub 28, then &,16,x): its name (30
; characters), its nodes' IDs (48 characters, 3 a node, padded with "-")
; and its sub-boards (a%(0) how many, a%(1)... their numbers), kept just
; past this:
;   &,16    a$ the name, an$ the nodes, a%() the sub-boards (a%() must be
;           DIMmed: "Error-Sec?" if it isn't)
;   &,16,1  the reverse: a$, an$ and a%() into the definition
;   &,16,2,dv%  load a definition from file a$ (cleared first)
;   &,16,3,dv%  save it to file a$
;   &,16,255  a% = the version (9)
; The release copies 120 bytes of numbers from a%(0)'s low byte on, so
; a%(0) keeps only its low byte (enough for the count), a%(1)-a%(59) are
; whole, and a%(60) kept only its high byte: a 60th sub-board's number was
; lost. 11/05/2026: a%(60)'s low byte is copied too, as a 121st byte
; (nlnums+120); a file saved before has 0 there, as a C64 one does, so
; it loads as it always did (and the C64 overlay loads a 128 one, the
; extra byte landing past its area)
;
; No source survives: disassembled from the 3.0 release's "++ netlist"
; ("01/09/91  4:39P", 3 blocks) by tools/ovl_dis.py, then ported on
; 2026-11-05 (C64 values in the comments):
; - runs at protostart ($1c00; c64 $c000), where &,7,dv%,2 loads it; the
;   setup starts at nlname, its last byte (c64 $c20d)
; - Image's variable buffer is varbuf ($63-$65; c64 $61-$63, FAC1), which
;   this also uses as a pointer into a%() (c64 ($61),y)
; - a%() is found from arytab to strend ($31/$32, $33/$34; c64 $2f/$30,
;   $31/$32): BASIC 7's arrays are in bank 1, which cfg_ml has at
;   $4000-$bfff, and its array header is the C64's
; - $fb-$fd as on the C64: farcall puts the caller's $fb/$fc back
; - the KERNAL through the ML's ROM stubs; setbnk before LOAD and SAVE:
;   the setup in bank 0, the filename (a$) in bank 1, as ++ post does

{alpha:alt}	; c64: KickAss's petscii_mixed: capitals $c1-$da, lowercase $41-$5a
{include:"equates.asm"}

	orig protostart	; c64: $c000
netlist:
	jmp entry
	byte $09	; the version
	byte $30,$31,$2f,$30,$39,$2f,$39,$31	; "01/09/91  4:39P"
	byte $20,$20,$34,$3a,$33,$39,$50,$00

entry:
	cpx #$ff
	bne entry0
	jsr zero	; &,16,255: a% = the version
	lda #$09
	sta varbuf+1	; c64: $62
	ldx #var_a_integer
	jmp putvar
entry0:
	txa
	bne entry1
	jmp getall	; 0
entry1:
	dex
	bne entry2
	jmp putall	; 1
entry2:
	dex
	bne entry3
	jmp loadlist	; 2
entry3:
	dex
	bne entry4
	jmp savelist	; 3
entry4:
	rts

; the array's name: a%
aname:
	byte $c1,$80

; the file: a$ on device .y, secondary address 0
setfile:
	tya
	tax
	lda #$01
	ldy #$00
	jsr setlfs	; c64: $ffba (the ROM is out in cfg_ml)
	ldx #var_a_string
	jsr usevar
	lda varbuf	; c64: $61
	ldx varbuf+1	; c64: $62
	ldy varbuf+2	; c64: $63
	jsr setnam	; c64: jmp $ffbd
	lda #0		; 128: the setup in bank 0 (just past this),
	ldx #1		; the filename a BASIC string, in bank 1
	jmp setbnk

; clear the setup, the list to "-"s
clear:
	tya
	pha
	lda #<nlname	; c64: #$0d
	sta clear1+1
	lda #>nlname	; c64: #$c2
	sta clear1+2
clear0:
	lda #$00
clear1:
	sta $ffff	; (the address: set above)
	inc clear1+1
	bne clear2
	inc clear1+2
clear2:
	lda clear1+1
	cmp #<nlend	; c64: #$d3
	bne clear0
	lda clear1+2
	cmp #>nlend	; c64: #$c2
	bne clear0
	ldy #$30
	lda #$2d	; "-"
clear3:
	sta nllist,y	; (and the first number's high byte, as the release)
	dey
	bpl clear3
	pla
	tay
	rts

; 2: load the setup
loadlist:
	jsr clear
	jsr setfile
	lda #$00
	ldx #<nlname	; c64: #$0d
	ldy #>nlname	; c64: #$c2
	jmp loadf	; c64: $ffd5

; 3: save it
savelist:
	jsr setfile
	lda #<nlname	; c64: #$0d
	sta varbuf	; c64: $61
	lda #>nlname	; c64: #$c2
	sta varbuf+1	; c64: $62
	lda #varbuf	; c64: #$61, the start's zero page address
	ldx #<nlend	; c64: #$d3
	ldy #>nlend	; c64: #$c2
	jmp savef	; c64: $ffd8

; 0: a$ the name (up to its first 0), an$ the list, a%() the numbers
getall:
	jsr zero
	ldy #$1d
getall1:
	lda nlname,y
	cmp #$00
	bne getall2
	dey
	bpl getall1
getall2:
	iny
	sty varbuf	; c64: $61
	lda #<nlname	; c64: #$0d
	sta varbuf+1	; c64: $62
	lda #>nlname	; c64: #$c2
	sta varbuf+2	; c64: $63
	ldx #var_a_string
	jsr putvar
	jsr zero
	lda #$30
	sta varbuf	; c64: $61
	lda #<nllist	; c64: #$2b
	sta varbuf+1	; c64: $62
	lda #>nllist	; c64: #$c2
	sta varbuf+2	; c64: $63
	ldx #var_an_string
	jsr putvar
	lda #$01
	sta free_fd
	lda #<nlnums	; c64: #$5b
	sta free_fb
	lda #>nlnums	; c64: #$c2
	sta free_fc
	jsr findarr
	bcc copynums
noarray:
	lda #$0a	; a$ = "Error-Sec?", printed
	sta varbuf	; c64: $61
	lda #<errmsg	; c64: #$03
	sta varbuf+1	; c64: $62
	lda #>errmsg	; c64: #$c2
	sta varbuf+2	; c64: $63
	ldx #var_a_string
	jsr putvar
	jmp prta

; the numbers from ($fb) to (varbuf): 60 pairs of bytes, then a%(60)'s
; low byte
copynums:
	ldy #$00
	lda (free_fb),y
	sta (varbuf),y	; c64: ($61),y
	iny
	lda (free_fb),y
	sta (varbuf),y	; c64: ($61),y
	lda free_fb
	clc
	adc #$02
	sta free_fb
	lda free_fc
	adc #$00
	sta free_fc
	lda varbuf	; c64: $61
	clc
	adc #$02
	sta varbuf	; c64: $61
	lda varbuf+1	; c64: $62
	adc #$00
	sta varbuf+1	; c64: $62
	inc free_fd
	lda free_fd
	cmp #$3d
	bne copynums
	ldy #$00	; 11/05/2026: and a%(60)'s low byte (the release
	lda (free_fb),y	; stopped at its high byte)
	sta (varbuf),y	; c64: ($61),y
	rts

; 1: a$ into the name, an$ into the list, a%() into the numbers
putall:
	ldx #var_a_string
	jsr usevar
	ldy #$00
putall1:
	cpy varbuf	; c64: $61
	beq putall2
	lda (varbuf+1),y	; c64: ($62),y
	sta nlname,y
	iny
	cpy #$1e
	bne putall1
	jmp putall3
putall2:
	lda #$00	; the rest 0s
	sta nlname,y
	iny
	cpy #$1e
	bne putall2
putall3:
	ldx #var_an_string
	jsr usevar
	ldy #$00
putall4:
	cpy varbuf	; c64: $61
	beq putall5
	lda (varbuf+1),y	; c64: ($62),y
	sta nllist,y
	iny
	cpy #$30
	bne putall4
	jmp putall6
putall5:
	lda #$2d	; the rest "-"s
	sta nllist,y
	iny
	cpy #$30
	bne putall5
putall6:
	lda #$01
	sta free_fd
	jsr findarr
	bcc putall7
	lda #$0a	; a$ = "Error-Sec?", printed
	sta varbuf	; c64: $61
	lda #<errmsg	; c64: #$03
	sta varbuf+1	; c64: $62
	lda #>errmsg	; c64: #$c2
	sta varbuf+2	; c64: $63
	ldx #var_a_string
	jsr putvar
	jmp prta
putall7:
	lda varbuf	; c64: $61
	sta free_fb
	lda varbuf+1	; c64: $62
	sta free_fc
	lda #<nlnums	; c64: #$5b
	sta varbuf	; c64: $61
	lda #>nlnums	; c64: #$c2
	sta varbuf+1	; c64: $62
	jmp copynums
	byte $60,$60

; find a%(): varbuf 8 bytes into it (its 7-byte header, then a%(0)'s low
; byte: the release's offset), carry clear; carry set if it isn't there
findarr:
	lda arytab	; c64: $2f
	sta varbuf	; c64: $61
	lda arytab+1	; c64: $30
	sta varbuf+1	; c64: $62
findarr1:
	cmp strend+1	; c64: $32
	bne findarr2
	lda varbuf	; c64: $61
	cmp strend	; c64: $31
	bne findarr2
	sec
	rts
findarr2:
	ldy #$00
findarr3:
	lda (varbuf),y	; c64: ($61),y
	cmp aname,y
	bne findarr4
	iny
	cpy #$02
	bne findarr3
	lda varbuf	; c64: $61
	clc
	adc #$08
	sta varbuf	; c64: $61
	lda varbuf+1	; c64: $62
	adc #$00
	sta varbuf+1	; c64: $62
	clc
	rts
findarr4:
	ldy #$03	; the next array: past this one's size
	lda (varbuf),y	; c64: ($61),y
	pha
	dey
	lda (varbuf),y	; c64: ($61),y
	clc
	adc varbuf	; c64: $61
	sta varbuf	; c64: $61
	pla
	adc varbuf+1	; c64: $62
	sta varbuf+1	; c64: $62
	jmp findarr1

usevar:
	lda #29
	jmp usetbl1	; c64: $cd03
putvar:
	lda #30
	jmp usetbl1	; c64: $cd03
zero:
	lda #31
	jmp usetbl1	; c64: $cd03
prta:
	lda #0		; & (print a$)
	jmp usetbl1	; c64: $cd03
errmsg:
	byte $c5,$52,$52,$4f,$52,$2d,$d3,$c5	; "Error-Sec?"
	byte $c3,$8b

; the setup, from the last byte on: the name (30 bytes), the list (48),
; the sub-boards (121 bytes, a%(0)'s low byte to a%(60)'s low byte; the
; release had 120, ending at a%(60)'s high byte)
nlname:
	byte $00
nllist	= nlname + 30	; c64: $c22b
nlnums	= nllist + 48	; c64: $c25b
nlend	= nlnums + 121	; c64: nlnums + 120, $c2d3
