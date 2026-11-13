; chatmode.asm -- "++ chatmode": chat between the stations of a multiplexed
; Lt. Kernal, through the file "chatfile", with a transcript. A proof of
; concept (11/12/2026); i.ltk chat (modules/i.ltk chat.lbl) runs it. Not on
; the boot disk (not in build.sh's overlays): Image BBS 128's own Lt. Kernal
; code is still off (intro's use_ltk). Assemble it with
;
;	wine c64list4_04.exe chatmode.asm -prg:chatmode.prg -ovr
;
; A module loads it (a$="chatmode":gosub 28), then:
;
;	&,16        the transcript, oldest first, until a key
;	&,16,2      lists the other stations that are online: "Port nn:
;	            handle", "(chat room)", "with SysOp"
;	&,16,3      the chat room, as a$ (the handle), until /x (or the
;	            caller's carrier or time runs out): see "the chat" below
;	&,16,4,s    this station's state: 0 offline, 1 online; a$ the handle
;
; Each finds "chatfile" on LU 10, user 0 first (as the lockfile: every port
; sees the same one), or makes it. The results, at protostart+3:
;
;	+3  0 fine; 1 the carrier went or the time ran out (chat); 2 no room
;	    on LU 10 for the file; 3 no LU 10, or the file wasn't found after
;	    it was made; 4 no Lt. Kernal (the KERNAL's CHROUT entry isn't its
;	    jsr); 5 the chat room is full (cm_maxroom stations); 6 chatfile is
;	    an old one (fewer blocks than cm_size): scratch it
;	+4  the transcript's blocks shown (&,16)
;	+5  this station's port (the host adapter's DIP switches, GETPRT)
;	+6  the other stations online (&,16,2; &,16,3: in the room)
;	+7  of those, in the chat room (&,16,2)
;
; The file (cm_size blocks, contiguous, type 5): its header; a block for
; each port (1-16), which only that port writes; the transcript's position
; (cm_ctl); the transcript, a ring of cm_ringn blocks (cm_ring on). The Lt.
; Kernal's notes warn that two ports writing at once is "usually fatal", so
; nothing here is written by more than one port: a station writes its own
; block, and only the lowest-numbered station in the room writes the
; transcript (when it leaves, the next one does: a line can be lost or
; written twice then), under &,13's lock 0 (miscl.asm's arbit), so two
; that think they're the writer at a handover write one after the other.
;
; A station's block: b_magic, its port, its state (0 offline, 1 online, 2
; in the chat room), whether the sysop is in the room at it (Cht on), a
; tick (one more each time it's written: every ~8 s in the room, so a
; station whose tick stops for ~100 s has gone), the number of its last
; line, the next slot, its handle, and its last cm_nslots lines (number,
; who: 0 the station's user, 1 the sysop; length; text).
;
; The chat: the station's user types on the modem (or on the keyboard: a
; local login); the sysop, at any station in the room, turns Cht on to come
; in (the keyboard is then the sysop's) and off to leave. A line is sent on
; Return; /x leaves. About twice a second (30 of Image's jiffies) it reads
; the blocks of the stations in the room, and one other in turn (so a
; station coming in is seen within 8 s), and prints what's new: "handle:
; text", "SysOp: text", "* handle joined", left, timed out.
;
; From Image BBS 2.0's v2/asm/tests/chatmode.asm, a fragment (C64, "1990 sys
; ml:rem new image", the line in 2.0 that sets up the node identifiers):
; find "chatfile" in the logged LU, or make it (16 contiguous blocks, type
; 5, catalogued), then a loop until a key, with nothing in it. The Lt.
; Kernal's calls are as the Power Station articles document them
; (~/Documents/c64/ltkernal: PSV1N4.TXT; PSV1N5A.TXT is W. J. Brier's LK
; Mini-Mon 1.1, a C-128 program):
; - DRIVER ($8045): .a the LU, .x/.y the block (low, high), carry clear to
;   read, set to write, then the buffer and the number of blocks after the
;   jsr; 512-byte blocks. With $ff00 = %00001110, as Mini-Mon, into cmbuf
; - SETLUN, CLRHDR, FNFILE, ALCONT, the catalog mini-sub between BNKOUT and
;   BNKIN, which are in the Lt. Kernal's KERNAL: so with $ff00 = cfg_rom,
;   never cfg_ml (where $fc4e is Image's own ML); BNKOUT leaves interrupts
;   off, so cli after BNKIN; RS-232 off around them (its NMIs)
; - FNFILE fails with three values for the catalog mini-sub: the first
;   pushed, then .x/.y, .a = $24, jsr MNSEXT (no pla: the mini-sub takes
;   it); then the file is searched for again, as Mini-Mon does
; - HDRADR (blmilo): the header block, high byte first; NBINFL the same

{alpha:alt}
{include:"equates.asm"}

catlog	= $24		; mini-sub: index catalog
cntfil	= $05		; file type: contiguous sequential data
cm_lu	= 10
cm_drvcfg = %00001110	; $ff00 for DRIVER, as LK Mini-Mon
cm_size	= 34		; header, 16 stations, cm_ctl, the transcript's 16
cm_ctl	= 17		; the transcript's position
cm_ring	= 18		; the transcript's first block
cm_ringn = 16		; its blocks (a power of 2)
cm_maxroom = 15		; stations in the chat room at once
cm_nslots = 5		; a station's last lines kept in its block
cm_slotlen = 84		; number (2), who, length, 80 characters
cm_lnmax = 78		; a typed line's longest
cm_poll	= 30		; jiffies between polls (~0.5 s)
cm_stale = 200		; polls without a new tick: gone (~100 s)
cm_tlock = 0		; &,13's lock for the transcript

; a station's block
b_magic	= 0
b_port	= 1
b_state	= 2
b_sysop	= 3
b_tick	= 4
b_seq	= 5		; 2 bytes
b_next	= 7
b_handle = 8		; 20, 0-ended
b_slots	= 32
st_magic = $52		; a station's block
tc_magic = $54		; the transcript's position block

	orig protostart

	jmp cmentry

cmstat:
	byte 0		; +3
cmshown:
	byte 0		; +4
cmport:
	byte 0		; +5
cmonline:
	byte 0		; +6
cminroom:
	byte 0		; +7

cmentry:
	stx cmcall
	sty cmparm
	tsx
	stx cmsp
	lda #0
	sta cmstat
	sta cmshown
	sta cmonline
	sta cminroom
	sta tqlen
	lda cmcall
	cmp #3
	bcc cmentry1
	jsr cmhandle	; &,16,3 and 4: a$
cmentry1:
	jsr cmopen
	bcs cmexit
	lda cmcall
	beq cmentry2
	cmp #2
	beq cmentry3
	cmp #3
	beq cmentry4
	cmp #4
	beq cmentry5
cmexit:
	ldx cmsp	; the stack as it came (the mini-sub's byte)
	txs
	rts
cmentry2:
	jmp cmreplay
cmentry3:
	jmp cmstatus
cmentry4:
	jmp cmchat
cmentry5:
	lda cmparm	; &,16,4,s
	and #1
	sta cmmyst
	lda #0
	sta cmmysys
	jsr cmwrmine
	jmp cmexit

; a$ (the handle, up to 19 characters) to cmhand
cmhandle:
	ldx #var_a_string
	lda #29		; &,29: usevar
	jsr usetbl1
	ldy #0
cmhand1:
	lda #0
	cpy varbuf
	bcs cmhand2
	lda (varbuf+1),y	; bank 1, seen in cfg_ml
cmhand2:
	sta cmhand,y
	iny
	cpy #19
	bcc cmhand1
	lda #0
	sta cmhand,y
	rts

; ********************************
; *  the Lt. Kernal
; ********************************

; find or make chatfile; this station's port. Carry set if not (cmstat)
cmopen:
	jsr rsdisab
	lda #cfg_rom
	sta mmucr
	lda $ffd2	; the Lt. Kernal's KERNAL has a jsr here
	cmp #$20
	beq cmopen1
	lda #cfg_ml
	sta mmucr
	jsr rsinabl
	lda #4
	sta cmstat
	sec
	rts
cmopen1:
	jsr ltk_bnkout
	jsr ltk_getprt
	and #$0f
	sta cmport
	lda ltk_activu	; the logged LU and user, put back after
	sta cmuser
	lda ltk_activl
	sta cmlu
	lda #cm_lu
	jsr ltk_setlun
	bcs cmopen8
	lda #0
	sta ltk_activu
	jsr cmfind
	bcc cmopen5
	sta cmidx	; not there: make it
	stx cmidx+1
	sty cmidx+2
	jsr ltk_clrhdr
	jsr cmname1
	lda #cntfil
	sta filtyp
	lda #>cm_size	; high byte first
	sta nbinfl
	lda #<cm_size
	sta nbinfl+1
	jsr ltk_alcont
	bcc cmopen2
	lda #2
	bne cmopen9
cmopen2:
	lda cmidx	; into the catalog (the mini-sub takes the
	pha		; first value from the stack)
	lda #catlog
	ldx cmidx+1
	ldy cmidx+2
	jsr ltk_mnsext
	jsr cmfind	; its header, as Mini-Mon does
	bcs cmopen8
	bcc cmopen6
cmopen5:
	lda nbinfl+1	; an old (smaller) chatfile?
	cmp #<cm_size
	lda nbinfl
	sbc #>cm_size
	bcs cmopen6
	lda #6
	bne cmopen9
cmopen6:
	lda blmilo+0	; its header block
	sta cmhdr+1
	lda blmilo+1
	sta cmhdr
	lda #0
	beq cmopen9
cmopen8:
	lda #3
cmopen9:
	sta cmstat
	lda cmlu
	jsr ltk_setlun
	lda cmuser
	sta ltk_activu
	jsr ltk_bankin
	lda #cfg_ml
	sta mmucr
	cli
	jsr rsinabl
	lda cmstat
	cmp #1		; carry set if not 0
	rts

; (banked out) find chatfile: carry clear if it's there
cmfind:
	jsr ltk_clrhdr
	jsr cmname1
	jmp ltk_fnfile

cmname1:
	ldy #7		; "chatfile", 8 characters
cmname2:
	lda cmname,y
	sta filnam,y
	dey
	bpl cmname2
	rts

; (cfg_ml) block .a of the file: carry clear reads it into cmbuf, set
; writes cmbuf to it
cmblock:
	sta cmtmp
	php
	jsr rsdisab
	lda #cm_drvcfg
	sta mmucr
	jsr ltk_bnkout
	clc
	lda cmtmp
	adc cmhdr
	tax
	lda cmhdr+1
	adc #0
	tay
	lda #cm_lu
	plp		; read or write
	jsr ltk_driver
	word cmbuf
	byte 1
	lda #cfg_rom
	sta mmucr
	jsr ltk_bankin
	lda #cfg_ml
	sta mmucr
	cli
	jmp rsinabl

; port .x's block into cmbuf: .a its state (0 if it isn't a station's
; block yet); .x kept
cmrdport:
	stx cmpx
	txa
	clc
	adc #1
	clc
	jsr cmblock
	ldx cmpx
	lda cmbuf+b_magic
	cmp #st_magic
	bne cmrdp1
	txa
	cmp cmbuf+b_port
	bne cmrdp1
	lda cmbuf+b_state
	rts
cmrdp1:
	lda #0
	rts

; this station's block: read it, set its state, sysop, handle and a new
; tick (and a line, if cmplen isn't 0: cmpsrc's, from cmpptr), write it
cmwrmine:
	ldx cmport
	jsr cmrdport
	lda cmbuf+b_magic
	cmp #st_magic
	beq cmwr2
	ldy #0		; new: no lines yet
	tya
cmwr1:
	sta cmbuf,y
	sta cmbuf+256,y
	iny
	bne cmwr1
cmwr2:
	lda #st_magic
	sta cmbuf+b_magic
	lda cmport
	sta cmbuf+b_port
	lda cmmyst
	sta cmbuf+b_state
	lda cmmysys
	sta cmbuf+b_sysop
	inc cmbuf+b_tick
	ldy #19
cmwr3:
	lda cmhand,y
	sta cmbuf+b_handle,y
	dey
	bpl cmwr3
	lda cmplen
	beq cmwr7
	inc cmbuf+b_seq
	bne cmwr4
	inc cmbuf+b_seq+1
cmwr4:
	ldx cmbuf+b_next
	jsr cmslot	; cmp1: the slot
	ldy #0
	lda cmbuf+b_seq
	sta (cmp1),y
	iny
	lda cmbuf+b_seq+1
	sta (cmp1),y
	iny
	lda cmpsrc
	sta (cmp1),y
	iny
	lda cmplen
	sta (cmp1),y
	lda cmp1	; the text after those 4
	clc
	adc #4
	sta cmp1
	bcc cmwr5
	inc cmp1+1
cmwr5:
	ldy #0
cmwr6:
	lda (cmpptr),y
	sta (cmp1),y
	iny
	cpy cmplen
	bcc cmwr6
	inc cmbuf+b_next
	lda cmbuf+b_next
	cmp #cm_nslots
	bcc cmwr7
	lda #0
	sta cmbuf+b_next
cmwr7:
	lda #0
	sta cmplen
	lda cmport
	clc
	adc #1
	sec
	jmp cmblock

; slot .x of the block in cmbuf to cmp1
cmslot:
	lda cmslotlo,x
	sta cmp1
	lda cmslothi,x
	sta cmp1+1
	rts

; ********************************
; *  &,16,2: who's online
; ********************************

cmstatus:
	ldx #15
cmst1:
	stx cmpx
	cpx cmport
	beq cmst9
	jsr cmrdport
	beq cmst9
	sta cmtmp
	inc cmonline
	lda #<cmtport
	ldy #>cmtport
	jsr cmprint
	lda cmpx
	jsr cmpnum
	lda #<cmtcolon
	ldy #>cmtcolon
	jsr cmprint
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	jsr cmprint
	lda cmtmp
	cmp #2
	bne cmst2
	inc cminroom
	lda #<cmtroom
	ldy #>cmtroom
	jsr cmprint
	lda cmbuf+b_sysop
	beq cmst2
	lda #<cmtwsys
	ldy #>cmtwsys
	jsr cmprint
cmst2:
	lda #13
	jsr cmputc
cmst9:
	ldx cmpx
	dex
	bpl cmst1
	jmp cmexit

; ********************************
; *  &,16,3: the chat room
; ********************************

cmchat:
	ldx #15		; who's here
cmch1:
	lda #0
	sta pstate,x
	cpx cmport
	beq cmch3
	jsr cmrdport
	sta pstate,x
	lda cmbuf+b_tick
	sta ptick,x
	lda #0
	sta pstale,x
	lda cmbuf+b_seq
	sta plastlo,x
	lda cmbuf+b_seq+1
	sta plasthi,x
	lda cmbuf+b_sysop
	sta psys,x
	lda pstate,x
	cmp #2
	bne cmch3
	inc cminroom
	lda #<cmthere
	ldy #>cmthere
	jsr cmprint
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	jsr cmprint
	lda #13
	jsr cmputc
	ldx cmpx
cmch3:
	dex
	bpl cmch1
	lda cminroom
	sta cmonline
	cmp #cm_maxroom
	bcc cmch4
	lda #5		; full
	sta cmstat
	jmp cmexit
cmch4:
	lda #2
	sta cmmyst
	jsr cmchtflag
	sta cmmysys
	jsr cmwrmine
	lda #<cmtin
	ldy #>cmtin
	jsr cmprint
	lda #<cmhand	; the transcript: "* handle joined"
	ldy #>cmhand
	ldx #0
	jsr cmevent0
	lda cmmysys
	beq cmch5
	jsr cmsysev
cmch5:
	jsr cmtflush
	lda #0
	sta lnulen
	sta lnslen
	sta cmrr
	sta cmpolls
	lda jiffy
	sta cmlast

cmloop:
	lda #47		; &,47: carrier and time
	jsr usetbl1
	beq cmloop1
	lda #1
	jmp cmleave
cmloop1:
	jsr cmchtflag	; Cht: the sysop in or out
	cmp cmmysys
	beq cmloop2
	sta cmmysys
	jsr cmwrmine
	jsr cmsysev
	jsr cmtflush
cmloop2:
	lda #48		; &,48: getkbd
	jsr usetbl1
	beq cmloop3
	ldx cmmysys	; the keyboard: the sysop's while Cht is on
	jsr cmkey
	jmp cmloop4
cmloop3:
	lda flag_loc_addr	; the modem, while Image uses it (chrio's
	and #flag_loc_l_mask	; carchk4)
	bne cmloop4
	lda local
	bne cmloop4
	lda carrst
	and #127
	bne cmloop4
	lda #49		; &,49: getmod
	jsr usetbl1
	beq cmloop4
	ldx #0
	jsr cmkey
cmloop4:
	lda jiffy
	sec
	sbc cmlast
	cmp #cm_poll
	bcc cmloop
	lda jiffy
	sta cmlast
	jsr cmpoll
	jmp cmloop

; .a: Cht (0 off, 1 on)
cmchtflag:
	lda #43		; &,43: chatchk
	jsr usetbl1
	beq cmchtf1
	lda #1
cmchtf1:
	rts

; leave the room: .a the result
cmleave:
	sta cmstat
	lda #1
	sta cmmyst
	lda #0
	sta cmmysys
	jsr cmwrmine
	lda #<cmhand
	ldy #>cmhand
	ldx #1
	jsr cmevent0
	jsr cmtflush
	lda #<cmtout
	ldy #>cmtout
	jsr cmprint
	jmp cmexit

; a key .a, for line .x (0 the station's user, 1 the sysop)
cmkey:
	stx cmln
	jsr cmxlat
	bne cmkey0
	rts
cmkey0:
	ldx cmln
	ldy lnulen,x	; (lnslen follows lnulen)
	cmp #13
	beq cmkey5
	cmp #20		; Delete
	bne cmkey2
	cpy #0
	beq cmkey9
	dec lnulen,x
	jmp cmputc
cmkey2:
	cmp #$20	; printable: $20-$7f, $a0-$ff
	bcc cmkey9
	cmp #$80
	bcc cmkey3
	cmp #$a0
	bcc cmkey9
cmkey3:
	cpy #cm_lnmax
	bcs cmkey9
	pha
	jsr cmlnptr
	pla
	sta (cmpptr),y
	inc lnulen,x
	jmp cmputc
cmkey5:
	jsr cmputc	; Return
	ldx cmln
	lda lnulen,x
	beq cmkey9
	sta cmplen
	lda #0
	sta lnulen,x
	jsr cmlnptr
	cpx #0		; the user's "/x": leave
	bne cmkey6
	lda cmplen
	cmp #2
	bne cmkey6
	ldy #0
	lda (cmpptr),y
	cmp #$2f	; /
	bne cmkey6
	iny
	lda (cmpptr),y
	and #$7f
	cmp #$58	; x
	bne cmkey6
	lda #0
	jmp cmleave
cmkey6:
	stx cmpsrc
	lda cmplen
	sta cmtxtlen
	jsr cmwrmine	; send it
	lda cmpsrc	; and into the transcript, as it's shown
	jsr cmwho
	jsr cmtline
	jmp cmtflush
cmkey9:
	rts

; line .x's buffer to cmpptr (.x, .y kept)
cmlnptr:
	lda cmlnlo,x
	sta cmpptr
	lda cmlnhi,x
	sta cmpptr+1
	rts

; .a (0 the station's user, 1 the sysop): their name to .a/.y (this
; station's)
cmwho:
	bne cmwho1
	lda #<cmhand
	ldy #>cmhand
	rts
cmwho1:
	lda #<cmtsysop
	ldy #>cmtsysop
	rts

; ********************************
; *  the poll
; ********************************

cmpoll:
	lda #$80
	sta cmpolling
	inc cmpolls
	lda cmpolls
	and #15		; every 16 polls (~8 s): a new tick
	bne cmpoll1
	jsr cmwrmine
cmpoll1:
	ldx #15
cmpoll2:
	cpx cmport
	beq cmpoll4
	lda pstate,x	; the stations in the room, and one other
	cmp #2
	beq cmpoll3
	cpx cmrr
	bne cmpoll4
cmpoll3:
	jsr cmpoll1x
	ldx cmpx
cmpoll4:
	dex
	bpl cmpoll2
	inc cmrr
	lda cmrr
	and #15
	sta cmrr
	lda #0
	sta cmpolling
	jmp cmtflush

; port .x
cmpoll1x:
	jsr cmrdport
	sta cmst
	cmp #2
	beq cmpx0
	jmp cmpx8	; (out of a branch's reach)
cmpx0:
	lda cmbuf+b_tick	; in the room: its tick
	cmp ptick,x
	beq cmpx1
	sta ptick,x
	lda #0
	sta pstale,x
	beq cmpx2
cmpx1:
	lda pstale,x
	cmp #cm_stale
	bcs cmpx7
	inc pstale,x
cmpx2:
	lda pstate,x
	cmp #2
	beq cmpx3
	lda #2		; come in: lines from now on
	sta pstate,x
	lda cmbuf+b_seq
	sta plastlo,x
	lda cmbuf+b_seq+1
	sta plasthi,x
	lda #0
	sta psys,x
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	ldx #0
	jsr cmevent
	ldx cmpx
cmpx3:
	lda cmbuf+b_sysop	; the sysop in or out there
	cmp psys,x
	beq cmpx4
	sta psys,x
	jsr cmsysev
	ldx cmpx
cmpx4:
	lda plasthi,x	; new lines: plast+1 to seq
	cmp cmbuf+b_seq+1
	bne cmpx5
	lda plastlo,x
	cmp cmbuf+b_seq
	beq cmpx9
cmpx5:
	inc plastlo,x
	bne cmpx6
	inc plasthi,x
cmpx6:
	jsr cmline	; that one, if a slot still has it
	ldx cmpx
	jmp cmpx4
cmpx7:
	lda pstate,x	; its tick stopped: gone
	cmp #2
	bne cmpx9
	lda #3
	sta pstate,x
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	ldx #2
	jmp cmevent
cmpx8:
	lda pstate,x	; not in the room: did it leave?
	cmp #2
	bne cmpx8a
	lda tqlen
	sta cmtmp3
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	ldx #1
	jsr cmevent
	ldx cmpx
	cpx cmport	; a station below this one: it wrote its own
	bcs cmpx8a	; leaving (or a lower one did), so not queued
	lda cmtmp3
	sta tqlen
cmpx8a:
	lda cmst
	sta pstate,x
cmpx9:
	rts

; port cmpx's line plast (the block in cmbuf): show it and put it in the
; transcript, if one of its slots has it
cmline:
	ldx #cm_nslots-1
cmline1:
	stx cmtmp
	jsr cmslot
	ldx cmpx
	ldy #0
	lda (cmp1),y
	cmp plastlo,x
	bne cmline2
	iny
	lda (cmp1),y
	cmp plasthi,x
	beq cmline3
cmline2:
	ldx cmtmp
	dex
	bpl cmline1
	rts		; gone from its slots (more than cm_nslots behind)
cmline3:
	iny
	lda (cmp1),y	; who
	sta cmpsrc
	iny
	lda (cmp1),y
	sta cmtxtlen
	lda cmp1
	clc
	adc #4
	sta cmpptr
	lda cmp1+1
	adc #0
	sta cmpptr+1
	lda cmpsrc
	bne cmline4
	lda #<(cmbuf+b_handle)
	ldy #>(cmbuf+b_handle)
	bne cmline5
cmline4:
	lda #<cmtsysop
	ldy #>cmtsysop
cmline5:
	jsr cmtline
	jmp cmshow

; ********************************
; *  lines: tline, shown and queued
; ********************************

; "name: text" (.a/.y the name, cmpptr/cmtxtlen the text) to tline, and
; queued for the transcript
cmtline:
	jsr cmtlstart
	lda #<cmtcolon2
	ldy #>cmtcolon2
	jsr cmtladd
	ldy #0
cmtline1:
	cpy cmtxtlen
	bcs cmtline2
	lda (cmpptr),y
	jsr cmtlch
	iny
	bne cmtline1
cmtline2:
	jmp cmtlend

; "* name joined" and the like: .a/.y the name, .x the event (0 joined,
; 1 left, 2 timed out). cmevent shows it too
cmevent:
	jsr cmevent0
	jmp cmshow
cmevent0:
	stx cmtmp2
	pha
	tya
	pha
	lda #0
	sta tllen
	lda #$2a	; *
	jsr cmtlch
	lda #$20
	jsr cmtlch
	pla
	tay
	pla
	jsr cmtladd
	ldx cmtmp2
	lda cmevlo,x
	ldy cmevhi,x
	jsr cmtladd
	jmp cmtlend

; the sysop came in or left at a station (port cmpx's block in cmbuf, or
; this one's: cmmysys)
cmsysev:
	lda cmmysys
	bit cmpolling
	bpl cmsys1
	ldy cmpx
	lda psys,y
cmsys1:
	ldx #0		; joined
	cmp #0
	bne cmsys2
	ldx #1		; left
cmsys2:
	lda #<cmtsysop
	ldy #>cmtsysop
	bit cmpolling
	bmi cmevent
	jmp cmevent0	; this station's: not shown (Cht is enough)

; tline: start with name .a/.y
cmtlstart:
	pha
	lda #0
	sta tllen
	pla
; and .a/.y (a 0-ended string) to tline
cmtladd:
	sta cmtla+1
	sty cmtla+2
	ldy #0
cmtla:
	lda $ffff,y	; target of self-modifying code
	beq cmtla1
	jsr cmtlch
	iny
	bne cmtla
cmtla1:
	rts
cmtlch:
	ldx tllen
	cpx #127
	bcs cmtlch1
	sta tline,x
	inc tllen
cmtlch1:
	rts
; end it with Return, and queue it for the transcript
cmtlend:
	lda #13
	jsr cmtlch
	ldy #0
cmtle1:
	cpy tllen
	bcs cmtle3
	ldx tqlen
	cpx #255	; full: dropped
	bcs cmtle3
	lda tline,y
	sta tq,x
	inc tqlen
	iny
	bne cmtle1
cmtle3:
	rts

; show tline: a new line, it, then what's being typed again
cmshow:
	lda #13
	jsr cmputc
	ldy #0
cmshow1:
	cpy tllen
	bcs cmshow2
	lda tline,y
	jsr cmputc
	iny
	bne cmshow1
cmshow2:
	ldx #0
cmshow3:
	stx cmln
	jsr cmlnptr
	ldy #0
cmshow4:
	tya
	ldx cmln
	cmp lnulen,x
	bcs cmshow5
	lda (cmpptr),y
	jsr cmputc
	iny
	bne cmshow4
cmshow5:
	ldx cmln
	inx
	cpx #2
	bcc cmshow3
	rts

; ********************************
; *  the transcript
; ********************************

; is this station the lowest-numbered in the room? carry clear if so
cmwriter:
	ldx #0
cmwri1:
	cpx cmport
	beq cmwri2
	lda pstate,x
	cmp #2
	beq cmwri3
	inx
	bne cmwri1
cmwri2:
	clc
	rts
cmwri3:
	sec
	rts

; the queued lines (tq) to the transcript, if this station writes it
cmtflush:
	lda tqlen
	bne cmtf0
	rts
cmtf0:
	jsr cmwriter
	bcc cmtf0a
	jmp cmtf8	; (out of a branch's reach)
cmtf0a:
	ldx #1		; &,13,1,0: the transcript's lock (the Lt. Kernal's
	ldy #cm_tlock	; locks between stations: two writers at a handover
	lda #13		; write one after the other)
	jsr usetbl1
	jsr cmtpos	; where it ends
	lda tpoff	; its block, unless at its start (new)
	ora tpoff+1
	beq cmtf1
	lda tpcur
	clc
	adc #cm_ring
	clc
	jsr cmblock
	jmp cmtf2
cmtf1:
	jsr cmclrbuf
cmtf2:
	ldx #0
cmtf3:
	stx cmtmp2
	lda tq,x
	pha
	clc		; cmp1 = cmbuf + tpoff
	lda #<cmbuf
	adc tpoff
	sta cmp1
	lda #>cmbuf
	adc tpoff+1
	sta cmp1+1
	pla
	ldy #0
	sta (cmp1),y
	inc tpoff
	bne cmtf4
	inc tpoff+1
cmtf4:
	lda tpoff+1
	cmp #2		; 512: the block's full
	bcc cmtf5
	jsr cmtwrite
	inc tpcur
	lda tpcur
	and #cm_ringn-1
	sta tpcur
	bne cmtf4a
	lda #1
	sta tpwrap
cmtf4a:
	lda #0
	sta tpoff
	sta tpoff+1
	jsr cmclrbuf
cmtf5:
	ldx cmtmp2
	inx
	cpx tqlen
	bcc cmtf3
	jsr cmtwrite	; the block it ends in (a new one too: its old
			; text from the last time round is gone)
cmtf6:
	jsr cmclrbuf	; the position
	lda #tc_magic
	sta cmbuf
	lda tpcur
	sta cmbuf+1
	lda tpoff
	sta cmbuf+2
	lda tpoff+1
	sta cmbuf+3
	lda tpwrap
	sta cmbuf+4
	lda #cm_ctl
	sec
	jsr cmblock
	ldx #2		; &,13,2,0: give it back
	ldy #cm_tlock
	lda #13
	jsr usetbl1
cmtf8:
	lda #0
	sta tqlen
cmtf9:
	rts

; the transcript's block tpcur from cmbuf (a 0 after its text, if it's
; not full)
cmtwrite:
	lda tpoff+1
	cmp #2
	bcs cmtw1
	clc
	lda #<cmbuf
	adc tpoff
	sta cmp1
	lda #>cmbuf
	adc tpoff+1
	sta cmp1+1
	lda #0
	tay
	sta (cmp1),y
cmtw1:
	lda tpcur
	clc
	adc #cm_ring
	sec
	jmp cmblock

; the transcript's position: tpcur, tpoff, tpwrap (0 and carry set if
; there's none yet)
cmtpos:
	lda #cm_ctl
	clc
	jsr cmblock
	ldx #0
	lda cmbuf
	cmp #tc_magic
	bne cmtp1
	lda cmbuf+1
	and #cm_ringn-1
	sta tpcur
	lda cmbuf+2
	sta tpoff
	lda cmbuf+3
	and #1
	sta tpoff+1
	lda cmbuf+4
	sta tpwrap
	clc
	rts
cmtp1:
	stx tpcur
	stx tpoff
	stx tpoff+1
	stx tpwrap
	sec
	rts

cmclrbuf:
	ldy #0
	tya
cmclr1:
	sta cmbuf,y
	sta cmbuf+256,y
	iny
	bne cmclr1
	rts

; ********************************
; *  &,16: the transcript, oldest first
; ********************************

cmreplay:
	jsr cmtpos
	bcs cmrp9	; none yet
	lda tpcur	; from the block after the last (wrapped) or
	clc		; the first
	adc #1
	ldx tpwrap
	bne cmrp1
	lda #0
cmrp1:
	and #cm_ringn-1
	sta cmblk
cmrp2:
	lda ndx		; a key: stop
	bne cmrp9
	lda cmblk
	clc
	adc #cm_ring
	clc
	jsr cmblock
	inc cmshown
	lda #<cmbuf
	sta cmp1
	lda #>cmbuf
	sta cmp1+1
	ldx #2		; 2 pages
	ldy #0
cmrp3:
	lda (cmp1),y
	beq cmrp4
	jsr cmputc
	lda ndx
	bne cmrp9
	iny
	bne cmrp3
	inc cmp1+1
	dex
	bne cmrp3
cmrp4:
	lda cmblk	; the last one?
	cmp tpcur
	beq cmrp9
	inc cmblk
	lda cmblk
	and #cm_ringn-1
	sta cmblk
	jmp cmrp2
cmrp9:
	jmp cmexit

; ********************************
; *  Image's output and keys
; ********************************

; .a/.y a 0-ended string
cmprint:
	sta cmprint1+1
	sty cmprint1+2
	ldy #0
cmprint1:
	lda $ffff,y	; target of self-modifying code
	beq cmprint2
	jsr cmputc
	iny
	bne cmprint1
cmprint2:
	rts

; .a (0-99) in two digits
cmpnum:
	ldx #$2f	; "0" - 1
	sec
cmpnum1:
	inx
	sbc #10
	bcs cmpnum1
	adc #$3a	; 10 + "0"
	pha
	txa
	jsr cmputc
	pla
	jmp cmputc

; .a to Image's output (&,24 takes it in $fe); keeps .x .y
cmputc:
	sta $fe
	txa
	pha
	tya
	pha
	lda #24
	jsr usetbl1
	pla
	tay
	pla
	tax
	rts

; a key's translation, as getchr's (chrio.asm); 0 none
cmxlat:
	cmp #$60
	bcc cmxl2
	cmp #$80
	bcs cmxl2
	adc #$60
cmxl2:
	cmp #$a0
	bcc cmxl3
	cmp #$bf
	bcs cmxl3
	adc #$40
cmxl3:
	cmp #$e0
	bne cmxl4
	lda #$20
cmxl4:
	cmp #$de
	bne cmxl5
	lda #$ff
cmxl5:
	cmp #cursor_home
	bne cmxl6
	lda #0
cmxl6:
	cmp #0
	rts

; ********************************
; *  texts and variables
; ********************************

cmname:
	ascii "chatfile"
cmtport:
	ascii "Port "
	byte 0
cmtcolon:
	ascii ": "
	byte 0
cmtroom:
	ascii " (chat room)"
	byte 0
cmtwsys:
	ascii " with SysOp"
	byte 0
cmthere:
	ascii "Here: "
	byte 0
cmtin:
	byte 13
	ascii "* In the chat room. /x leaves."
	byte 13,0
cmtout:
	byte 13
	ascii "* Left the chat room."
	byte 13,0
cmtsysop:
	ascii "SysOp"
	byte 0
cmtcolon2:
	ascii ": "
	byte 0
cmevlo:
	byte <cmtjoin, <cmtleft, <cmtgone
cmevhi:
	byte >cmtjoin, >cmtleft, >cmtgone
cmtjoin:
	ascii " joined"
	byte 0
cmtleft:
	ascii " left"
	byte 0
cmtgone:
	ascii " timed out"
	byte 0

cmslotlo:
	byte <(cmbuf+b_slots+0*cm_slotlen), <(cmbuf+b_slots+1*cm_slotlen)
	byte <(cmbuf+b_slots+2*cm_slotlen), <(cmbuf+b_slots+3*cm_slotlen)
	byte <(cmbuf+b_slots+4*cm_slotlen)
cmslothi:
	byte >(cmbuf+b_slots+0*cm_slotlen), >(cmbuf+b_slots+1*cm_slotlen)
	byte >(cmbuf+b_slots+2*cm_slotlen), >(cmbuf+b_slots+3*cm_slotlen)
	byte >(cmbuf+b_slots+4*cm_slotlen)
cmlnlo:
	byte <lnu, <lns
cmlnhi:
	byte >lnu, >lns

cmcall:
	byte 0
cmparm:
	byte 0
cmsp:
	byte 0
cmlu:
	byte 0
cmuser:
	byte 0
cmidx:
	byte 0,0,0
cmhdr:
	word 0		; the header block's number (low, high)
cmtmp:
	byte 0
cmtmp2:
	byte 0
cmtmp3:
	byte 0
cmpx:
	byte 0
cmst:
	byte 0
cmmyst:
	byte 0
cmmysys:
	byte 0
cmhand:
	area 20, 0
cmplen:
	byte 0		; a line to send: its length, who, where
cmpsrc:
	byte 0
cmp1	= $fa		; pointers: $fa-$fd, free on the 128 ($fe is Image's
cmpptr	= $fc		; output character; farcall keeps $fb/$fc)
cmtxtlen:
	byte 0
cmln:
	byte 0
lnulen:
	byte 0		; the station's user's line
lnslen:
	byte 0		; the sysop's (after it: lnulen,x)
cmrr:
	byte 0
cmpolls:
	byte 0
cmpolling:
	byte 0
cmlast:
	byte 0
cmblk:
	byte 0
tllen:
	byte 0
tqlen:
	byte 0
tpcur:
	byte 0
tpoff:
	word 0
tpwrap:
	byte 0

; past the overlay's end (to $2aff)
cmend:
cmbuf	= cmend		; a block, 512
tq	= cmbuf+512	; lines for the transcript, 256
tline	= tq+256	; a line, 128
lnu	= tline+128	; the station's user's line, 80
lns	= lnu+80	; the sysop's, 80
pstate	= lns+80	; each port's: its state as last seen (3 gone)
ptick	= pstate+16	; its tick
pstale	= ptick+16	; polls since its tick changed
plastlo	= pstale+16	; its last line shown
plasthi	= plastlo+16
psys	= plasthi+16	; its sysop in the room
cmtop	= psys+16
