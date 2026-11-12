; remote.asm -- "++ remote": run a plain BASIC program for the caller.
; A module loads the overlay (a$="remote":gosub 28), then
;
;	a$=dr$+"<program>":&,16
;
; loads the program file a$ from drive dv% and RUNs it. What it PRINTs
; goes through Image's output (the screen, and the modem when a caller is
; on); INPUT, GET and GETKEY read the keyboard and the modem. When the
; program ends -- END, its last line, an error, Run/Stop, or the caller's
; carrier or time running out -- im carries on with the statement after
; the &,16, with its program, variables, arrays, GOSUBs, FORs and open
; files as they were. The result is in four bytes at protostart+3:
;
;	peek({sym:protostart}+3)  0 the program ended (END, or its last line)
;	                          1 the caller's carrier went, or their time
;	                            ran out (the program was stopped)
;	                          2 it stopped with an error (+4 is BASIC's
;	                            error number, 0 for Run/Stop; +5/+6 the
;	                            line); its message went to the caller too
;	                          3 it didn't start; +4 says why: 1 not found
;	                            (or a disk error), 2 too big for the room
;	                            left in bank 0, 3 no room for its
;	                            variables, 4 load error, 5 not called
;	                            from a program (direct mode)
;
; From Image BBS 2.0's remote.s (2008-12 source folder; the 1.2/2.0
; repo's v2/asm/tests/remote.asm is a text copy), a test that was never
; finished: "ML.REMOTE" at $c000 (the C64's protocol area) pointed CHROUT
; at Image's &,55, put BASIC's own error and statement vectors back, gave
; BASIC a second program area at $0a01-$4000, RUN the program loaded there
; (by the caller, before the SYS) and, through IMAIN, went back to im
; with GOTO 1 when it ended. Its bugs, fixed here:
; - its return path loaded two of the old vectors with "lda old / lda
;   old+1" (IERROR, IMAIN, IGONE), so their high bytes came from .x,
;   whatever the vector before left there;
; - "bcc *+2" skipped nothing: the inx after it always ran, so the
;   variables started a page past the program's end;
; - its CLR didn't reset the DATA pointer (READ went on in im's DATA),
;   nor BASIC's stack, nor the temporary strings; and im's GOSUB/FOR
;   stack wasn't kept, so a RUN or CLR in the program lost it
;   (the text copy's own typos, "stx IBSOUT" for "stx IBSOUT+1" and the
;   like, weren't in remote.s);
; - &,55 (output) also reads a key from the caller after each character
;   (for Ctrl-S, and "/" or space to abort a listing), so the characters
;   a caller typed while the program printed were lost; and nothing
;   read the caller's keys for INPUT or GET.
;
; Image BBS 128 (11/11/2026):
; - runs at protostart ($1c00; c64 $c000), started with &,16 (which comes
;   here in cfg_ml, from the middle of BASIC's & statement); a$ and dv%
;   name the program, which the overlay loads itself
; - BASIC 7 keeps text in bank 0 and variables in bank 1, and im fills
;   most of both. The program's text goes just past im's (and the modules
;   loaded into it: $1210, TEXT_TOP), up to the top of BASIC text ($1212,
;   $c000). The directory's block count is checked against that room
;   first, since a LOAD that ran on past $c000 would write over the ML
;   (romtab, the resident code). Its variables and strings go in im's
;   free memory, between the end of im's arrays (strend) and the bottom
;   of its strings (fretop), after a garbage collection: BASIC 7's own
;   collection then works on the program's strings only, below im's
; - CHROUT, CHRIN and GETIN (the screen and the keyboard only; files and
;   other devices go on to the old vectors): output through &,24
;   (xchrout1: the screen, modem and printer, without reading a key), keys
;   from &,48 (getkbd) and &,49 (getmod), the modem's only while Image
;   would use it (chrio.asm's carchk4); each one checks the caller's
;   carrier and time (&,47). INPUT's line is typed into a buffer here
;   (Delete works), echoed through the output; BASIC prints its Return
; - BASIC 7's vectors for errors, statements, functions and USR back to
;   the ROM's (IERROR $4d3f, IGONE $4aa2, IEVAL $78da, USR $7d28), so the
;   program is plain BASIC 7 (no &, no Image error trap); IERROR comes
;   here first to see how it ended: with .x = $80 (READY) it went back to
;   im without "READY." being printed; an error's message is printed by
;   BASIC, which then goes to IMAIN (here) and back to im
; - the program starts as RUN starts one (runmod, setmsg), with BASIC 7's
;   CLR past its CLALL ($51fd: CLALL would empty the KERNAL's table of
;   open files, im's modem and disk files with it), on an empty BASIC
;   stack ($0800-$09ff, saved first); and it goes back to im as Image's
;   farjmp_newstt does: the CPU's stack as NEWSTT left it ($82), NEWSTT
;   at the statement after the &,16
; - everything the program could change of im's is saved first (rmranges)
;   and put back: BASIC's pointers, its stack, DATA and TRAP, the
;   temporary strings, the open file table and default devices, the
;   vectors, BANK, and the CPU's stack above im's statement (CLR sets it
;   to $fa, where a GOSUB from the ML, &,66,1, keeps its return). Files the program left open are closed first, and the
;   default devices set back (clrchn)
; Not handled: a program that POKEs or SYSes into Image (or the 40/80
; column screen, GRAPHIC, WINDOW...), or that opens a file with one of
; im's file numbers after a CLR.

{alpha:alt}
{include:"equates.asm"}

; BASIC 7.0 ROM routines and vectors' power-up values
rm_igone	= $4aa2	; IGONE's own: execute the next statement
rm_ierror	= $4d3f	; IERROR's own: error messages, TRAP, READY
rm_ieval	= $78da	; IEVAL's own
rm_usr		= k_ilqerr	; USR's own ($7d28: ?illegal quantity)
rm_runflg	= $5a81	; RUN's start: runmod $80, BASIC's IRQ flags, setmsg 0
rm_clr		= $51fd	; CLR past its CLALL ($927b): TRAP off, string
			; space, BASIC's stack, arrays, PRINT USING's
			; characters, RESTORE, temporary strings
rm_runc		= $5254	; txtptr = txttab - 1
rm_ichrin	= $0324	; the KERNAL's CHRIN vector (IBASIN)
rm_igetin	= $032a	; its GETIN vector
rm_minvars	= $0200	; the least room for the program's variables
rm_lnmax	= 80	; INPUT's longest line

	orig protostart	; c64: $c000

	jmp rmentry

; the result (see the top): protostart+3 to +6
rmstat:
	byte 0
rmerr:
	byte 0
rmline:
	word 0

; the KERNAL vectors the hooks pass other devices on to (kept away from a
; page's last byte: jmp (vector))
rmoldout:
	word 0
rmoldin:
	word 0
rmoldget:
	word 0

; ********************************
; *  &,16: load the program and RUN it (cfg_ml)
; ********************************

rmentry:
	lda #0
	sta rmerr
	sta rmline
	sta rmline+1
	lda stksav	; the CPU's stack at the start of im's statement
	sta rmentsp
	bit runmod	; a program's statement? (stksav is kept only then)
	bmi rmentry0
	lda #5
	jmp rmfail
rmentry0:

; room for its variables: im's free memory, after a collection
	jsr forcegc
	sec
	lda fretop
	sbc strend
	lda fretop+1
	sbc strend+1
	cmp #>rm_minvars
	bcs rmentry1
	lda #3
	jmp rmfail
rmentry1:

; its name: a$ (read after the collection, which may have moved it), a
; string in bank 1, which cfg_ml sees
	ldx #var_a_string
	lda #29		; &,29: usevar
	jsr usetbl1
	lda varbuf
	bne rmentry2
rmnofile:
	lda #1
	jmp rmfail
rmentry2:
	cmp #39
	bcc rmentry3
	lda #38
rmentry3:
	sta rmnamelen
	tay
rmentry4:
	dey
	lda (varbuf+1),y
	sta rmname,y
	tya
	bne rmentry4
	ldx #var_dv_integer
	lda #29		; &,29: usevar
	jsr usetbl1
	lda varbuf+1	; dv%'s low byte
	sta rmdevice

; room for its text in bank 0: from im's end to the top of BASIC text
	lda txtend
	sta rmgstart
	lda txtend+1
	sta rmgstart+1
	sec
	lda maxmem0
	sbc txtend
	sta rmroom
	lda maxmem0+1
	sbc txtend+1
	sta rmroom+1

; its size from the directory: up to 254 bytes a block
	jsr rmdirsize
	bcs rmnofile
	lda rmblocks+1
	bne rmtoobig
	lda rmblocks
	asl
	sta rmtmp
	lda #0
	rol
	sta rmtmp+1	; blocks*2
	sec
	lda #0
	sbc rmtmp
	sta rmtmp
	lda rmblocks
	sbc rmtmp+1
	sta rmtmp+1	; blocks*256 - blocks*2
	lda rmroom
	cmp rmtmp
	lda rmroom+1
	sbc rmtmp+1
	bcs rmentry5
rmtoobig:
	lda #2
	jmp rmfail

; load it there (secondary address 0: at .x/.y), in bank 0
rmentry5:
	lda #0
	jsr setmsg
	lda rmnamelen
	ldx #<rmname
	ldy #>rmname
	jsr setnam
	lda #1
	ldx rmdevice
	ldy #0
	jsr setlfs
	lda #0		; the program and its name in bank 0 (the name
	tax		; here, in the shared 16K)
	jsr setbnk
	jsr rsdisab
	lda #0
	ldx rmgstart
	ldy rmgstart+1
	jsr loadf
	php
	stx rmgend
	sty rmgend+1
	jsr rsinabl
	plp
	bcc rmstart
	lda #4
	jmp rmfail

; ********************************
; *  from here on there's no going back to the & statement
; ********************************

rmstart:
	lda #0		; save im's
	jsr rmxfer
	ldx rmentsp	; and the CPU's stack above its statement's (CLR
rmstart0:		; sets it to $fa: a GOSUB from the ML, &,66,1,
	inx		; keeps its return there)
	beq rmstart00
	lda $0100,x
	sta rmcpu,x
	jmp rmstart0
rmstart00:
	lda ldtnd	; and its open files, for rmclose
	sta rmsavfiles
	ldx #9
rmstart1:
	lda lat,x
	sta rmsavlat,x
	dex
	bpl rmstart1
	lda #0
	sta rmlnlen
	sta rmlnpos

	sei
	lda ICHROUT
	sta rmoldout
	lda ICHROUT+1
	sta rmoldout+1
	lda #<rmout
	sta ICHROUT
	lda #>rmout
	sta ICHROUT+1
	lda rm_ichrin
	sta rmoldin
	lda rm_ichrin+1
	sta rmoldin+1
	lda #<rmin
	sta rm_ichrin
	lda #>rmin
	sta rm_ichrin+1
	lda rm_igetin
	sta rmoldget
	lda rm_igetin+1
	sta rmoldget+1
	lda #<rmget
	sta rm_igetin
	lda #>rmget
	sta rm_igetin+1
	lda #<rmerror
	sta IERROR
	lda #>rmerror
	sta IERROR+1
	lda #<rmmain
	sta IMAIN
	lda #>rmmain
	sta IMAIN+1
	lda #<rm_igone
	sta IGONE
	lda #>rm_igone
	sta IGONE+1
	lda #<rm_ieval
	sta IEVAL
	lda #>rm_ieval
	sta IEVAL+1
	lda #<rm_usr
	sta USRADD
	lda #>rm_usr
	sta USRADD+1

; its text past im's (the byte before it is 0: im's end link), its
; variables in im's free memory
	lda rmgstart
	sta txttab
	lda rmgstart+1
	sta txttab+1
	lda rmgend
	sta txtend
	lda rmgend+1
	sta txtend+1
	lda strend
	sta vartab
	lda strend+1
	sta vartab+1
	lda fretop
	sta memsiz
	lda fretop+1
	sta memsiz+1

; RUN it, as BASIC's RUN does but without CLALL
	lda #cfg_rom
	sta mmucr
	cli
	jsr k_linkprg
	jsr rm_runflg
	jsr rm_clr	; leaves the CPU's stack at $f8: put back below
	jsr rm_runc
	sei
	ldx rmentsp
	txs
	cli
	jmp k_newstt

; it didn't start: .a why; back to the & statement
rmfail:
	sta rmerr
	lda #3
	sta rmstat
	rts

; ********************************
; *  its size from the directory
; ********************************

; "$" and the name, as a listing: the first file's block count (the
; listing is read to its end, so the drive isn't left part way). Carry
; set if there's no such file
rmdirsize:
	lda #0
	sta rmdirst
	sta rmdirq
	sta rmblocks
	sta rmblocks+1
	lda #$24	; "$"
	sta rmdirname
	ldx rmnamelen
	inx
	txa
	ldx #<rmdirname
	ldy #>rmdirname
	jsr setnam
	lda #127
	ldx rmdevice
	ldy #0
	jsr setlfs
	lda #0
	tax
	jsr setbnk
	jsr rsdisab
	jsr openf
	bcs rmdir8
	ldx #127
	jsr chkin
	bcs rmdir7
	jsr rmdirget	; the load address
	jsr rmdirget
	jsr rmdirget	; the header: its link, the drive's number,
	jsr rmdirget	; the disk's name to its 0
	jsr rmdirget
	jsr rmdirget
rmdir1:
	lda rmdirst
	bne rmdir6
	jsr rmdirget
	bne rmdir1
	lda rmdirst	; the next line's link: 0 0 at the end
	bne rmdir6
	jsr rmdirget
	sta rmtmp
	jsr rmdirget
	ora rmtmp
	beq rmdir6
	jsr rmdirget	; its blocks
	sta rmblocks
	jsr rmdirget
	sta rmblocks+1
rmdir2:
	lda rmdirst
	bne rmdir6
	jsr rmdirget
	beq rmdir6
	cmp #$22	; a quote: a file's line ("blocks free." has none)
	bne rmdir2
	sta rmdirq
rmdir6:
	lda rmdirst	; the rest, to the end
	bne rmdir7
	jsr rmdirget
	jmp rmdir6
rmdir7:
	jsr clrchn
rmdir8:
	lda #127
	jsr closef
	jsr rsinabl
	lda rmdirq
	beq rmdir9
	clc
	rts
rmdir9:
	sec
	rts

rmdirget:
	jsr chrin
	sta rmtmp+1
	jsr readst
	ora rmdirst
	sta rmdirst
	lda rmtmp+1
	rts

; ********************************
; *  the hooks, while it runs
; ********************************

; IERROR (cfg_rom): .x = $80 is READY, the program's end; anything else
; an error, kept, then BASIC's own handling (TRAP, or the message, READY
; and IMAIN)
rmerror:
	txa
	bmi rmerror1
	stx rmerr
	lda curlin
	sta rmline
	lda curlin+1
	sta rmline+1
	jmp rm_ierror
rmerror1:
	lda #0		; an error TRAP took doesn't count
	sta rmerr
	sta rmline
	sta rmline+1
	jmp rmexit

; IMAIN (cfg_rom): after an error's message, or Run/Stop's BREAK
rmmain:
	lda rmerr
	bne rmmain1
	lda curlin	; BREAK: its line
	sta rmline
	lda curlin+1
	sta rmline+1
rmmain1:
	lda #2
	jmp rmexit

; CHROUT: the screen's characters to Image's output
rmout:
	pha
	lda dflto
	cmp #3
	beq rmout1
	pla
	jmp (rmoldout)
rmout1:
	pla
	sta rmchar
	txa
	pha
	tya
	pha
	lda mmucr
	pha
	lda #cfg_ml	; Image's routines from ML: usetbl1 calls
	sta mmucr	; them straight, not as BASIC's & (strfixes)
	jsr rmcarr
	lda rmchar
	jsr rmputc
	pla
	sta mmucr
	pla
	tay
	pla
	tax
	lda rmchar
	clc
	rts

; GETIN: a key from the keyboard or the caller, 0 if none
rmget:
	lda dfltn
	beq rmget1
	jmp (rmoldget)
rmget1:
	txa
	pha
	tya
	pha
	lda mmucr
	pha
	lda #cfg_ml
	sta mmucr
	jsr rmkey
rmget2:
	sta rmchar
	pla
	sta mmucr
	pla
	tay
	pla
	tax
	lda rmchar
	clc
	rts

; CHRIN: INPUT's line, a character at a time, typed into rmlnbuf first
rmin:
	lda dfltn
	beq rmin1
	jmp (rmoldin)
rmin1:
	txa
	pha
	tya
	pha
	lda mmucr
	pha
	lda #cfg_ml
	sta mmucr
	ldx rmlnpos
	cpx rmlnlen
	bcc rmin2
	jsr rmgetln
	ldx #0
rmin2:
	lda rmlnbuf,x
	inx
	stx rmlnpos
	jmp rmget2

; a line, to Return (kept at its end, not echoed: BASIC prints it)
rmgetln:
	lda #0
	sta rmlnlen
	sta rmlnpos
rmgetln1:
	jsr rmkey
	beq rmgetln1
	cmp #13
	beq rmgetln9
	cmp #20		; Delete
	bne rmgetln2
	ldx rmlnlen
	beq rmgetln1
	dec rmlnlen
	jsr rmputc
	jmp rmgetln1
rmgetln2:
	cmp #$20	; printable: $20-$7f, $a0-$ff
	bcc rmgetln1
	cmp #$80
	bcc rmgetln3
	cmp #$a0
	bcc rmgetln1
rmgetln3:
	ldx rmlnlen
	cpx #rm_lnmax
	bcs rmgetln1
	sta rmlnbuf,x
	inc rmlnlen
	jsr rmputc
	jmp rmgetln1
rmgetln9:
	ldx rmlnlen
	sta rmlnbuf,x
	inc rmlnlen
	rts

; (cfg_ml) .a to Image's output: &,24 (xchrout1) takes it in $fe
rmputc:
	sta $fe
	lda #24
	jmp usetbl1

; (cfg_ml) a key or 0, as getchr (chrio.asm) reads one: the keyboard,
; then the modem while Image uses it (carchk4), and its translation
rmkey:
	jsr rmcarr
	lda #48		; &,48: getkbd
	jsr usetbl1
	bne rmkey1
	lda flag_loc_addr
	and #flag_loc_l_mask
	bne rmkey0
	lda local
	bne rmkey0
	lda carrst
	and #127
	bne rmkey0
	lda #49		; &,49: getmod
	jsr usetbl1
	bne rmkey1
rmkey0:
	lda #0
	rts
rmkey1:
	cmp #$60
	bcc rmkey2
	cmp #$80
	bcs rmkey2
	adc #$60
rmkey2:
	cmp #$a0
	bcc rmkey3
	cmp #$bf
	bcs rmkey3
	adc #$40
rmkey3:
	cmp #$e0
	bne rmkey4
	lda #$20
rmkey4:
	cmp #$de
	bne rmkey5
	lda #$ff
rmkey5:
	cmp #0
	rts

; (cfg_ml) the caller's carrier and time (&,47: 0 fine or local): stop
; the program if either is gone
rmcarr:
	lda #47
	jsr usetbl1
	bne rmcarr1
	rts
rmcarr1:
	lda #1
	jmp rmexit

; ********************************
; *  back to im
; ********************************

; .a: the result. From any configuration and stack depth
rmexit:
	sei
	sta rmstat
	lda #cfg_rom
	sta mmucr
	ldx rmentsp
	txs
	cld
	cli
	jsr k_clrchn	; its CMD or channels off
	jsr rmclose
	sei
	lda #$80	; im's back
	jsr rmxfer
	ldx rmentsp
rmexit1:
	inx
	beq rmexit2
	lda rmcpu,x
	sta $0100,x
	jmp rmexit1
rmexit2:
	cli
	jmp k_newstt	; the statement after the &,16

; close the files it opened: those in the table that weren't im's
rmclose:
	ldx ldtnd
rmclose1:
	dex
	bmi rmclose9
	lda lat,x
	ldy rmsavfiles
rmclose2:
	dey
	bmi rmclose3
	cmp rmsavlat,y
	bne rmclose2
	beq rmclose1
rmclose3:
	jsr k_closef	; the table changes: start again
	jmp rmclose
rmclose9:
	rts

; copy the ranges below to rmsave (.a = 0) or back (.a = $80)
rmxfer:
	sta rmxdir
	lda #<rmsave
	sta rmbufp
	lda #>rmsave
	sta rmbufp+1
	ldx #0
rmxfer1:
	lda rmranges+1,x
	cmp #$ff	; the end
	beq rmxfer9
	bit rmxdir
	bmi rmxfer2
	sta rmxld+2	; save: from memory to the buffer
	lda rmranges,x
	sta rmxld+1
	lda rmbufp
	sta rmxst+1
	lda rmbufp+1
	sta rmxst+2
	jmp rmxfer3
rmxfer2:
	sta rmxst+2	; restore: from the buffer to memory
	lda rmranges,x
	sta rmxst+1
	lda rmbufp
	sta rmxld+1
	lda rmbufp+1
	sta rmxld+2
rmxfer3:
	lda rmranges+2,x
	sta rmxcnt
	ldy #0
rmxld:
	lda $ffff,y	; targets of self-modifying code
rmxst:
	sta $ffff,y
	iny
	cpy rmxcnt	; (0: 256)
	bne rmxld
	clc
	lda rmbufp
	adc rmxcnt
	sta rmbufp
	lda rmbufp+1
	adc #0
	ldy rmxcnt
	bne rmxfer4
	adc #1
rmxfer4:
	sta rmbufp+1
	inx
	inx
	inx
	jmp rmxfer1
rmxfer9:
	rts

; what the program could change of im's: address, count (0: 256)
rmranges:
	word $0012	; BASIC 7's (CLR zeroes it)
	byte 1
	word temppt	; $18-$23: the temporary strings
	byte 12
	word txttab	; $2d-$3e: the pointers, curlin, txtptr
	byte 18
	word datlin	; $41-$44: DATA's line and pointer
	byte 4
	word fbufpt	; $74-$75 (RUN zeroes them)
	byte 2
	word $007a	; $7a-$7f: DS$, BASIC's stack pointer, runmod
	byte 6
	word stksav	; $82
	byte 1
	word ldtnd	; $98-$9a: open files, default devices
	byte 3
	word $009d	; the KERNAL's messages flag
	byte 1
	word $00f6	; (RUN zeroes it)
	byte 1
	word IERROR	; $0300-$030b: BASIC's vectors
	byte 12
	word rm_ichrin	; $0324-$032b: CHRIN, CHROUT, STOP, GETIN
	byte 8
	word lat	; $0362-$037f: the open files' table
	byte 30
	word bnkvar	; BANK
	byte 1
	word $03df	; (CLR zeroes it)
	byte 1
	word oldtxt	; $1202-$120f: CONT's line, PRINT USING's
	byte 14		; characters, ER, EL, TRAP
	word txtend	; $1210-$1213: the ends of BASIC text
	byte 4
	word USRADD	; $1219-$121a
	byte 2
	word $1276	; $1276-$127f: BASIC's IRQ flags (RUN zeroes them)
	byte 10
	word $0800	; BASIC's stack: GOSUB, FOR, DO
	byte 0
	word $0900
	byte 0
	word $ffff

rmentsp:
	byte 0		; the CPU's stack pointer im's statement started with
rmdevice:
	byte 0
rmnamelen:
	byte 0
rmdirname:
	byte 0		; "$" for the directory, then the name
rmname:
	area 38, 0
rmgstart:
	word 0		; its text: start, end
rmgend:
	word 0
rmroom:
	word 0
rmblocks:
	word 0
rmtmp:
	word 0
rmdirst:
	byte 0
rmdirq:
	byte 0
rmchar:
	byte 0
rmlnlen:
	byte 0
rmlnpos:
	byte 0
rmxdir:
	byte 0
rmxcnt:
	byte 0
rmbufp:
	word 0
rmsavfiles:
	byte 0
rmsavlat:
	area 10, 0
rmlnbuf:
	area rm_lnmax+1, 0
; im's saved state: past the overlay's end, in the protocol area's free
; room (to $2aff): the ranges (643 bytes), then the CPU's stack page
; (rmentsp+1 to $ff of it)
rmsave:
rmcpu	= rmsave + 643
