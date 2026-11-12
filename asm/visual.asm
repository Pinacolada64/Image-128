; visual.s: a visual (full-screen) editor for Image BBS -- unfinished
;
; From Image BBS 2.0's visual.s ("code for a visual editor, unfinished"),
; on the 2.0 ML source disk 20ml-src.d81, by way of the text version in the
; 1.2/2.0 repo (v2/asm/tests/visual.asm). Converted to KickAssembler (an
; exact conversion built the same bytes as "ml.visual" on 20ml-src.d81),
; then:
; - case conversion (the line editor's "case" flag) is turned off while
;   editing, so letters aren't forced to capitals;
; - control keys are looked up in a key table (keys/keyjmp), like the line
;   editor's (ctrlchrs/ctrl in swap1.s), with editing keys added: Delete,
;   Insert (Shift-Delete) and Ctrl-I, Ctrl-D, Ctrl-B, Ctrl-N, Ctrl-W.
; - Ctrl-X's line count is fixed (2.0 stored the key code, 24, not 23), and
;   Ctrl-X puts the number of lines used (the last one that isn't blank) in
;   "lines" ($03fe; 128: mline, the line after it, as the line editor);
; - Ctrl-H shows a help screen of the keys (11/11/2026: through sub.editor,
;   from s.visual or s.visual 80, as .x=5);
; - lines are packed (pack) for saving and for the screen: a reverse or
;   colour code only where it changes, no colour code for plain spaces,
;   and no blanks after the last visible column;
; - the cursor is tracked (xchrout keeps curx/cury), and crsrpos moves it
;   the cheaper way: from where it is with cursor keys, or from Home;
; - a lost carrier or expired time saves the lines and leaves (xgetin then
;   returns Return forever, which 2.0 obeyed), and the chat key starts chat.
;
; Load it as an ML module, then start it with &,16,0-2 (128: see the
; entries below; c64: sys 49152): see
; core/tests/i.test visual.lbl. Lines are 3 bytes per column (reverse,
; colour, character) in the editor's line strings; Ctrl-V re-prints the
; lines, Ctrl-X stores them (putln), puts the number of lines used in
; $03fe ("lines"; not kk) and exits. (128: Ctrl-L re-prints, Ctrl-V/Ctrl-Y
; page down/up, and Ctrl-X sets mline: see vexit.)
;
; The &,nn calls it uses are reached through usetbl1 (lda #nn:jmp usetbl1).
;
; Image BBS 128 (11/08/2026, "++ visual"): ported from ImageBBS3's
; source/visual.s (KickAssembler) to C64List, as an overlay at protostart
; ($1c00), started with &,16 (a$="0:++ visual":&,7,dv%,2 to load it). 128
; changes: the colour codes in a table of its own (the c64 read the
; KERNAL's at $e8da); makerm1 through its ROM stub (romtab: the c64
; switched banks with $01); numx/numy bytes of its own, not $14/$15
; (BASIC 7's linnum); "lines" is the 128's ($18c2).
; And pages (user's request): the text can be up to 254 lines (tt$(1-254)),
; shown 23 at a time. tt$() holds the text packed (as Ctrl-X stores it),
; but for the page on the screen, whose lines are kept expanded (3 bytes a
; column) while it's edited. Ctrl-V shows the next page, Ctrl-Y the one
; before, and so do the cursor keys past the bottom or top row (and Return
; on the last row); Ctrl-L shows the page again (3.0's Ctrl-V: Ctrl-R would
; be $12, Rvs On). Its entries and exits: below, at vbegin.

{alpha:alt}	; c64: KickAss's petscii_mixed

{include:"equates.asm"}

	orig protostart	; c64: $c000

; numx, numy: bytes at the end (c64: $14/$15, which are BASIC 7's linnum)

; state from the 2.0 source, not used yet:
;	modes = $03ff, cline = $03fb (current line?),
;	flags = $03fa, comm = $03f9, mline = $03f8, temp3 = $03f7,
;	case1 = $03f4, flag1 = $03f3

; colors: the 16 colour codes, a table at the end (c64: the KERNAL's, $e8da)
; varbuf ($61, FAC1; "var" in the 2.0 source): varbuf+1/+2 point at a string

; 128 (11/08/2026): three entries, as the line editor's (&,54,0-2:
; entry1-3 in editor.asm), by &,16's number (in X):
;   &,16,0  a new text: tt$() emptied, page 1 (plain &,16 too)
;   &,16,1  the text so far kept and shown (tt$(1 to mline-1), as the line
;           editor keeps it), page 1
;   &,16,2  back where it left off: the same page, cursor, colour and
;           reverse (after a command BASIC or the line editor handled)
; And its exits, as the line editor's (done in editor.asm): the page stored
; packed, mline the line after the last that isn't blank, .x in sxreg:
;   1  saved (Ctrl-X)
;   4  a dot command: Return on a line starting with "." and a letter (the
;      line is emptied); the letter in viscmd and .a. sub.editor has the line
;      editor run it (&,54,3, its entry4), and comes back here with &,16,2
; "lines" is the most lines the user may write (sub.editor's), not changed
; here: the pages stop there (254 at most). The first bytes are a jmp and
; "vis", so sub.editor can see ++ visual is loaded (peek 7171-7173)
		jmp vbegin
		ascii "vis"
vbegin:
		stx ventry
		lda case	; the line editor's "convert to capitals" flag:
		sta savecase	; save it, and turn it off while editing
		lda #0
		sta case
		lda #1
		sta editor
		lda #$ff	; where the cursor is isn't known (++ visual stays
		sta curx	; in memory between runs); the Clear below sets it
		sta cury
		lda lines	; the most lines: lines, 254 if 0 or more
		beq vbegin1
		cmp #255
		bcc vbegin2
vbegin1:
		lda #254
vbegin2:
		sta vmax
		lda ventry
		cmp #1
		beq ventry1
		cmp #2
		beq ventry2
		jmp visual	; 0 (or anything else): a new text
; 1: the text so far is tt$(1 to mline-1); the lines after it are emptied
ventry1:
		ldx mline
		dex
		stx vlast
		jsr blankrest
		jmp vstart
; 2: the page it was on (stored packed when it left), expanded again; the
; lines from mline on emptied, as for 1 (a line editor command may have
; deleted lines, leaving old copies after its last)
ventry2:
		ldx mline
		dex
		stx vlast
		jsr blankrest
		jsr vexpand
		jmp visual2

; Clear: start over, with no text at all
visual:
		lda #0
		sta vlast
		jsr blankrest
; the first page, the cursor at its top left, white, reverse off
vstart:
		lda #1
		sta top
		sta crsrc
		sta crsrx
		sta crsry
		lda #0
		sta crsrr
		jsr vexpand
		jmp visual2

; Ctrl-L (3.0's Ctrl-V): clear the screen and print the page's 23 lines
visual2:
		lda #$93	; (clear)
		jsr xchrout
		lda #$ff	; the colour isn't known yet; it carries on from
		sta lastc	; line to line
		jsr findend	; 11/10/2026: the last line typed, for the marker
		ldx #1
		stx numx
visual3:
		ldx numx
		jsr markrow	; 11/10/2026: "*** End of Text ***" on the row
		bne visual3a	; after the last line typed
		jsr printmark
		jmp visual3b
visual3a:
		ldx numx
		jsr rowdes	; 128: the page's line numx
		jsr lastcol
		sta pend
		lda #$92	; (rvrs off): a carriage return turns reverse off
		sta lastr
		lda #1
		jsr pack
		jsr outbuf
visual3b:
		lda #13
		jsr xchrout
		inc numx
		ldx numx
		cpx #24
		bcc visual3
		ldx crsrr	; back to the current reverse and colour
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout

		jsr crsrpos
visual4:
		ldx crsry
		jsr rowdes	; 128: the page's line crsry

; main loop: get a key
visual5:
		jsr chkend	; 11/10/2026: the end-of-text marker follows the text
		jsr xgetin
		pha
; xgetin returns Return (13) on every call once the carrier is lost, time
; runs out or the sysop's chat key is hit, so check those first (as the
; line editor does in swap1.s)
		jsr carchk	; 0: OK, 1: carrier lost, 2: time up
		cmp #0
		beq visual5a
		pla
		jmp visual25	; save the lines and leave, as Ctrl-X does
visual5a:
		jsr chatchk
		cmp #0
		beq visual5b
		pla
		jsr chatmode	; the sysop wants to chat: do that, then
		jmp visual2	; show the lines again
visual5b:
		pla
		pha
		and #$7f
		cmp #32
		pla
		bcs visual6	; 128: visual9 is past a branch's reach (C64List
		jmp visual9	; built "bcc visual9" with a wrong offset, no error)
; a printable character: store reverse, colour and character for this column
visual6:
		pha
		lda crsrx
		asl
		clc
		adc crsrx
		tay
		dey
		dey
		dey
		ldx crsrr
		lda revers,x
		sta (varbuf+1),y
		iny
		ldx crsrc
		lda colors,x
		sta (varbuf+1),y
		iny
		pla
		sta (varbuf+1),y
		jsr xchrout
		inc crsrx
		lda crsrx
		cmp #40
		bne visual5
		jmp vwrap	; 11/11/2026: word wrap (vwrap: or the next line as before)
; end of a line (or Return): go to the start of the next line
visual7:
; 128: a line starting with "." and a letter is a dot command, for the line
; editor (its entry4): the line emptied (it isn't text), and out with .x=4
		ldy #2
		lda (varbuf+1),y	; column 1's character
		cmp #'.'
		bne visual7a
		ldy #5
		lda (varbuf+1),y	; column 2's
		and #$7f
		cmp #$41
		bcc visual7a
		cmp #$5b
		bcs visual7a
		sta viscmd
		jmp vdotcmd	; 11/11/2026: the line wiped on the screen too
visual7a:
		lda crsry
		cmp #23
		bcs visual8
		lda #13
		jsr xchrout
		lda #0
		sta crsrr
		lda #1
		sta crsrx
		inc crsry
		jmp visual4
; past the last line: the next page (128), or back to the top of this
; one if there's none
visual8:
		jsr pgnext
		bcs visual8a
		lda #1		; its first line, first column, reverse off
		sta crsrx
		sta crsry
		lda #0
		sta crsrr
		jmp visual2
visual8a:
		lda #1
		sta crsrx
		sta crsry
		lda #0
		sta crsrr
		lda #$13	; (home)
		jsr xchrout
		jmp visual4

; control characters: look the key up in keys, jump through keyjmp
visual9:
		ldx #keyjmp-keys-1
vkey1:
		cmp keys,x
		beq vkey2
		dex
		bpl vkey1
		jmp visual19	; not in the table: a colour code?
vkey2:
		pha
		txa
		asl
		tax
		lda keyjmp,x
		sta vkeyjmp+1
		lda keyjmp+1,x
		sta vkeyjmp+2
		pla
vkeyjmp:
		jmp $ffff	; self-modified

keys:
		byte $91, $11, $1d, $9d	; up, down, right, left
		byte $93, 13, $16, $18	; Clear, Return, Ctrl-V, Ctrl-X
		byte $12, $92	; RVS on, RVS off
		byte $14, $94, $09	; Delete, Insert, Ctrl-I
		byte $04, $02, $0e, $17	; Ctrl-D, Ctrl-B, Ctrl-N, Ctrl-W
		byte $08	; Ctrl-H
		byte $19, $0c	; 128: Ctrl-Y, Ctrl-L
keyjmp:
		word kup, kdown, kright, kleft
		word visual, visual7, kpgdn, visual25	; Ctrl-V: the next page (3.0: redraw)
		word krvson, krvsoff
		word kdelete, kinsert, kinsert
		word kctrld, kctrlb, kctrln, kctrlw
		word khelp
		word kpgup, visual2	; Ctrl-Y: the page before; Ctrl-L: redraw

; cursor keys: move, and send the key itself
kup:
		ldx crsry
		cpx #1
		beq kupedge	; 128: on the top row, the page before
		dec crsry
		jmp visual23
kdown:
		ldx crsry
		cpx #23
		beq kdnedge	; 128: on the bottom row, the next page
		inc crsry
		jmp visual23
kright:
		ldx crsrx
		cpx #39
		beq kignore
		inc crsrx
		jmp visual23
kleft:
		ldx crsrx
		cpx #1
		beq kignore
		dec crsrx
		jmp visual23
kignore:
		jmp visual5

krvson:
		ldx #1
		jmp visual24
krvsoff:
		ldx #0
		jmp visual24

; Delete: delete the character to the left of the cursor
kdelete:
		jsr markold
		lda crsrx
		cmp #1
		beq kignore
		dec crsrx
; fall through
; Ctrl-D: delete the character under the cursor
kctrld:
		jsr markold
		lda crsrx
		jsr delcell
		jmp kredraw

; Insert, Ctrl-I: insert a space at the cursor (column 39 is lost)
kinsert:
		jsr markold
		lda crsrx
		jsr inscell
		jmp kredraw

; Ctrl-B: delete from the start of the line to the cursor
kctrlb:
		jsr markold
		lda crsrx
		cmp #1
		beq kignore
kctrlb1:
		lda #1
		jsr delcell
		dec crsrx
		lda crsrx
		cmp #1
		bne kctrlb1
		jmp kredraw1	; redraw the whole line

; Ctrl-N: move to the end of the line's text
kctrln:
		ldy #3*39-1	; the character of column 39
		ldx #39
kctrln1:
		lda (varbuf+1),y
		cmp #' '
		bne kctrln2
		dey
		dey
		dey
		dex
		bne kctrln1
kctrln2:
		inx	; just after the last character
		cpx #40
		bcc kctrln3
		ldx #39
kctrln3:
		stx crsrx
		jsr crsrpos
		jmp visual5

; Ctrl-W: delete the previous word (and any spaces after it)
kctrlw:
		jsr markold
		lda crsrx
		cmp #1
		beq kctrlw3
		jsr prevchar
		cmp #' '
		bne kctrlw2
		dec crsrx	; a space before the cursor: delete it
		lda crsrx
		jsr delcell
		jmp kctrlw
kctrlw2:
		lda crsrx	; then the word's characters
		cmp #1
		beq kctrlw3
		jsr prevchar
		cmp #' '
		beq kctrlw3
		dec crsrx
		lda crsrx
		jsr delcell
		jmp kctrlw2
kctrlw3:
		jmp kredraw

; Ctrl-H: out to sub.editor, which shows the help (s.visual)
khelp:
; 11/11/2026: Ctrl-H leaves with .x=5: sub.editor shows s.visual (s.visual 80
; in 80 columns), waits for a key, and starts ++ visual again where it left
; (&,16,2). The help text was here (527 bytes); the file can say more
		ldx #5
		jmp vexit

; redraw the line from the cursor (kredraw) or from column 1 (kredraw1)
kredraw:
		lda crsrx
		jsr redraw
		jmp visual5
kredraw1:
		lda #1
		jsr redraw
		jmp visual5

; a colour code? (colour 0, black, is never matched)
visual19:
		ldx #15
visual20:
		cmp colors,x
		beq visual21
		dex
		bne visual20
		jmp visual5
visual21:
		stx crsrc
		jsr xchrout
visual22:
		jsr xchrout
		jmp visual5

visual23:
		jsr xchrout
		jmp visual4

visual24:
		stx crsrr
		jmp visual22

; Ctrl-X: saved (.x=1)
visual25:
		ldx #1
		jmp vexit

; 128: leave with .x (1 saved, 4 a dot command, 5 Ctrl-H: the help, which
; sub.editor shows from s.visual): the page stored packed;
; mline the line after the last that isn't blank (of all 254), as the line
; editor keeps it; the case flag back; .x in sxreg, as the line editor's
; done leaves it (sub.editor reads it), viscmd in .a
vexit:
		stx vcode
		jsr vpack
		ldx #254
		stx numx
vexit1:
		ldx numx
		jsr getdes
		lda varbuf	; its length: 0 for a blank line
		bne vexit2
		dec numx
		bne vexit1
vexit2:
		ldx numx
		inx
		stx mline
		lda savecase	; put the line editor's case setting back
		sta case
		ldx vcode
		stx sxreg
		lda viscmd
		rts

; the current line (varbuf) all blank: reverse off, white, space
blankline:
		ldy #0
blankl1:
		lda #$92
		sta (varbuf+1),y
		iny
		lda #$05
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		iny
		cpy #3*39
		bcc blankl1
		rts

; & calls, by number, through usetbl1
getdes:
		lda #33	; &,33 getarr
		jmp usetbl1
putdes:
		lda #34	; &,34 putarr
		jmp usetbl1
xgetin:
		lda #23	; &,23 xgetin
		jmp usetbl1
xchrout1:
		lda #24	; &,24 xchrout1
		jmp usetbl1
putln:
		lda #36	; &,36 putln
		jmp usetbl1
prtln:
		lda #39	; &,39 prtln
		jmp usetbl1
chatchk:
		lda #43	; &,43 chatchk: non-zero if the chat key was hit
		jmp usetbl1
carchk:
		lda #47	; &,47 carchk: 0 OK, 1 carrier lost, 2 time up
		jmp usetbl1
chatmode:
		lda #56	; &,56 chatmode
		jmp usetbl1

xchrout:
		sta $fe
		pha
		jsr xchrout1
		pla
; fall through: keep track of where this leaves the cursor

; track the cursor (curx, cury: 1 = left/top, $ff = not known) after
; sending the character in A; A is kept
; 128 (11/08/2026): the character kept in tchar and compared from there:
; after "txa" the compares tested X, not the character (3.0's source), so
; Home was never seen, curx/cury stayed $ff and crsrpos sent Home forever
track:
		sta tchar
		pha
		txa
		pha
		lda tchar
		ldx curx
		cpx #$ff
		beq track9	; not known: only Home/Clear make it known
		cmp #13
		beq trackcr
		cmp #$8d	; shifted Return
		beq trackcr
		cmp #$11	; (down)
		beq trackdn
		cmp #$91	; (up)
		beq trackup
		cmp #$1d	; (right)
		beq trackrt
		cmp #$9d	; (left)
		beq tracklt
		cmp #$13	; (home)
		beq trackhm
		cmp #$93	; (clear)
		beq trackhm
		and #$7f
		cmp #32
		bcc track10	; another control code: doesn't move
trackrt:
		inc curx	; a character, or (right)
		jmp track10
tracklt:
		dec curx
		jmp track10
trackup:
		dec cury
		jmp track10
trackdn:
		inc cury
		jmp track10
trackcr:
		lda #1
		sta curx
		inc cury
		jmp track10
track9:
		cmp #$13	; (home)
		beq trackhm
		cmp #$93	; (clear)
		bne track10
trackhm:
		lda #1
		sta curx
		sta cury
track10:
		pla
		tax
		pla
		rts

revers:
		byte 18+128, 18	; (rvrs off), (rvrs on)

; put the cursor at crsrx, crsry (both from 1), the cheaper way: from where
; it is (curx, cury) with cursor keys, or from Home. Where it is isn't known
; ($ff): from Home.
crsrpos:
		lda curx
		cmp #$ff
		beq crsrpos4	; not known
		lda crsry	; |crsry-cury| + |crsrx-curx|: cursor keys from here
		sec
		sbc cury
		bcs crsrpos1
		eor #$ff
		adc #1
crsrpos1:
		sta vtemp
		lda crsrx
		sec
		sbc curx
		bcs crsrpos2
		eor #$ff
		adc #1
crsrpos2:
		clc
		adc vtemp
		sta vtemp
		lda crsry	; Home, then crsry-1 downs and crsrx-1 rights
		clc
		adc crsrx
		sec
		sbc #1
		cmp vtemp
		bcs crsrpos5	; from here is no dearer
crsrpos4:
		lda #$13	; (home)
		jsr xchrout	; (makes curx/cury 1,1)
crsrpos5:
		lda cury	; up or down to the line
		cmp crsry
		beq crsrpos7
		bcc crsrpos6
		lda #$91	; (up)
		jsr xchrout
		jmp crsrpos5
crsrpos6:
		lda #$11	; (down)
		jsr xchrout
		jmp crsrpos5
crsrpos7:
		lda curx	; then left or right to the column
		cmp crsrx
		beq crsrpos9
		bcc crsrpos8
		lda #$9d	; (left)
		jsr xchrout
		jmp crsrpos7
crsrpos8:
		lda #$1d	; (right)
		jsr xchrout
		jmp crsrpos7
crsrpos9:
		rts

; --- line editing: each column of a line is 3 bytes at (varbuf+1),y:
; reverse, colour, character; column c (1-39) starts at y = 3*(c-1)

; column A -> y = 3*(A-1)
colofs:
		sta vtemp
		asl
		clc
		adc vtemp
		sec
		sbc #3
		tay
		rts

; the character in the column before the cursor
prevchar:
		lda crsrx
		jsr colofs
		dey	; the character byte of column crsrx-1
		lda (varbuf+1),y
		rts

; delete column A: columns A+1..39 move left, column 39 becomes a space
delcell:
		jsr colofs
delcell1:
		cpy #3*38
		bcs delcell2
		iny
		iny
		iny
		lda (varbuf+1),y
		dey
		dey
		dey
		sta (varbuf+1),y
		iny
		jmp delcell1
delcell2:
		ldy #3*38
		lda #$92	; (rvrs off)
		sta (varbuf+1),y
		iny
		lda #$05	; (white)
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		rts

; insert a space at column A, in the current reverse and colour: columns
; A..38 move right, and column 39 is lost
inscell:
		jsr colofs
		cpy #3*38	; column 39: nothing to move, just replace it
		bcs inscell2
		sty vtemp
		ldy #3*38-1	; the last byte of column 38
inscell1:
		lda (varbuf+1),y
		iny
		iny
		iny
		sta (varbuf+1),y
		dey
		dey
		dey
		cpy vtemp
		beq inscell2
		dey
		jmp inscell1
inscell2:
		ldx crsrr
		lda revers,x
		sta (varbuf+1),y
		iny
		ldx crsrc
		lda colors,x
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		rts

; redraw the line from column A to its end (or its old end, so characters
; left over from before an edit are overwritten), packed; then go back to
; the current reverse/colour and to the cursor
redraw:
		sta rstart
		jsr lastcol
		cmp oldend
		bcs redraw1
		lda oldend
redraw1:
		sta pend
		lda pend
		cmp rstart
		bcc redraw2	; nothing to print from column A on
		ldx crsrx
		stx vtemp2
		lda rstart
		sta crsrx
		jsr crsrpos	; to column A
		lda vtemp2
		sta crsrx
		lda #$ff	; what's on screen here isn't known: send both
		sta lastr
		sta lastc
		lda rstart
		jsr pack
		jsr outbuf
redraw2:
		ldx crsrr
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout
		jmp crsrpos

; before an edit: remember where the line's text ends (redraw uses it)
markold:
		jsr lastcol
		sta oldend
		rts

; the last visible column of the line (1-39): a character other than a
; space, or a reverse space; 0 if the line is blank
lastcol:
		ldx #39
		ldy #3*39-1	; the character of column 39
lastcol1:
		lda (varbuf+1),y
		cmp #' '
		bne lastcol2
		dey
		dey
		lda (varbuf+1),y	; a space: its reverse byte
		cmp #$12	; (rvrs on): a reverse space shows
		beq lastcol2
		dey	; the character of the column before
		dex
		bne lastcol1
lastcol2:
		txa
		rts

; pack columns A..pend into buffer, length in plen (at most 80 bytes):
; a reverse code only when it differs from lastr, a colour code only when
; it differs from lastc (and not for a space with reverse off, whose colour
; doesn't show), then the character. The caller sets lastr and lastc to
; what's already in effect, or $ff for "not known".
pack:
		sta pcol
		jsr colofs
		ldx #0
pack1:
		lda pend
		cmp pcol
		bcc pack9	; past the last column
		cpx #80-3
		bcs pack9	; full
		lda (varbuf+1),y	; reverse
		cmp lastr
		beq pack2
		sta lastr
		sta buffer,x
		inx
pack2:
		iny	; colour
		iny
		lda (varbuf+1),y	; (the character)
		dey
		cmp #' '
		bne pack3
		lda lastr
		cmp #$92	; a space with reverse off: its colour doesn't show
		beq pack4
pack3:
		lda (varbuf+1),y
		cmp lastc
		beq pack4
		sta lastc
		sta buffer,x
		inx
pack4:
		iny	; the character
		lda (varbuf+1),y
		sta buffer,x
		inx
		iny	; the next column
		inc pcol
		jmp pack1
pack9:
		stx plen
		rts

; send buffer (plen bytes) to the screen and modem
outbuf:
		ldx #0
outbuf1:
		cpx plen
		beq outbuf2
		stx outx
		lda buffer,x
		jsr xchrout
		ldx outx
		inx
		jmp outbuf1
outbuf2:
		rts

; put and store string: line X = buf2 (index bytes)
vputlnx:
		txa
		pha
		lda index
		jsr makerm1	; BASIC: make room for a string of A bytes (128: its ROM stub)
		ldy index
		beq vputln2
		dey
vputln1:
		lda buf2,y
		sta (varbuf+1),y
		dey
		bpl vputln1
vputln2:
		pla
		tax
		jmp putdes

crsrx:
		byte 1	; cursor column (1-39) (128: 1, 1, white to begin with, for
crsry:
		byte 1	; cursor line (1-23)    &,16,2 before any other entry)
crsrc:
		byte 1	; current colour (index into colors)
crsrr:
		byte 0	; reverse: 0 off, 1 on
savecase:
		byte 0	; the line editor's case flag, saved while editing
vtemp:
		byte 0
vtemp2:
		byte 0
pcol:
		byte 0	; pack: the column being packed
pend:
		byte 0	; pack: the last column to pack
plen:
		byte 0	; pack: the length of the packed text in buffer
lastr:
		byte 0	; pack: the reverse code in effect ($ff: not known)
lastc:
		byte 0	; pack: the colour code in effect ($ff: not known)
outx:
		byte 0	; outbuf: index into buffer
rstart:
		byte 0	; redraw: the first column to redraw
oldend:
		byte 0	; the line's last visible column before an edit
curx:
		byte $ff	; where the cursor is (1 = left; $ff: not known)
cury:
		byte $ff	; (1 = top)

; 11/11/2026: word wrap (user's request). Column 39 just typed: if it isn't a
; space, and a space is before it (columns 38 to 1, the last one: vws), the
; word after it (columns vws+1-39, vwt of them) goes to the start of the
; next line: copied to wraptmp (past the overlay's end, free), blanked here
; (and redrawn, so it leaves the screen), then put in columns 1-vwt of the
; next line, the cursor after it. Only if that line is blank, and is there:
; on the bottom row, the next page's first line (pgnext's test). Otherwise,
; or with no space, the next line as before (visual7)
vwrap:
		ldy #3*39-1	; column 39's character
		lda (varbuf+1),y
		cmp #' '
		beq vwrapno
		ldx #38
		ldy #3*38-1
vwrap1:
		lda (varbuf+1),y
		cmp #' '
		beq vwrap2
		dey
		dey
		dey
		dex
		bne vwrap1
vwrapno:
		jmp visual7
vwrap2:
		stx vws		; the space's column
		lda #39
		sec
		sbc vws
		sta vwt		; the word's length
		asl
		clc
		adc vwt
		sta vwn		; its bytes (3 a column)
		lda crsry
		cmp #23
		bcs vwrap3
		tax		; the next row: blank?
		inx
		jsr rowdes
		jsr lastcol
		pha
		ldx crsry
		jsr rowdes	; this line again
		pla
		bne vwrapno
		jmp vwrap4
vwrap3:
		lda top		; the bottom row: a next page (as pgnext), and
		clc		; its first line blank (packed: no length)
		adc #23
		cmp #233
		bcs vwrapno
		cmp vmax
		beq vwrap3a
		bcs vwrapno
vwrap3a:
		tax
		jsr getdes
		lda varbuf
		pha
		ldx crsry
		jsr rowdes
		pla
		bne vwrapno
vwrap4:
		lda vws		; the word's first byte: 3 * vws
		asl
		clc
		adc vws
		sta vtemp
		tay
		ldx #0
vwrap5:
		lda (varbuf+1),y	; the word to wraptmp
		sta wraptmp,x
		iny
		inx
		cpx vwn
		bcc vwrap5
		ldy vtemp	; and blanked here
		ldx vwt
vwrap6:
		lda #$92
		sta (varbuf+1),y
		iny
		lda #$05
		sta (varbuf+1),y
		iny
		lda #' '
		sta (varbuf+1),y
		iny
		dex
		bne vwrap6
		lda #39		; redrawn from the word's column to 39
		sta oldend
		ldx vws
		inx
		stx crsrx
		txa
		jsr redraw
		lda crsry
		cmp #23
		bcs vwrap8
		inc crsry	; the next row: the word in columns 1 on
		ldx crsry
		jsr rowdes
		jsr vwput
		lda #0
		sta oldend
		lda #1
		jsr redraw
		jmp visual4
vwrap8:
		lda top		; this line (top+22) has text now, but vend may
		clc		; not know yet (chkend runs before the next key):
		adc #22		; pgnext checks the next page against vend
		cmp vend
		bcc vwrap8a
		sta vend
vwrap8a:
		jsr pgnext	; the next page (tested above), its first line
		lda #1
		sta crsry
		ldx #1
		jsr rowdes
		jsr vwput
		jmp visual2
; wraptmp's word into columns 1-vwt of the line in varbuf, the cursor after it
vwput:
		ldy #0
vwput1:
		lda wraptmp,y
		sta (varbuf+1),y
		iny
		cpy vwn
		bcc vwput1
		ldx vwt
		inx
		stx crsrx
		rts
vws:
		byte 0
vwt:
		byte 0
vwn:
		byte 0

; 11/11/2026: a dot command: the line emptied, and wiped on the screen too
; (reverse off, spaces over what was typed, back to column 1), so the line
; editor's echo of the command ("Help!") doesn't follow the ".h", and ++
; visual comes back with the cursor at the line's start; then out with .x=4
vdotcmd:
		jsr lastcol	; how much of the line has something on it
		sta pend
		jsr blankline
		lda #1
		sta crsrx
		jsr crsrpos
		lda #$92	; (rvrs off)
		jsr xchrout
		lda #0
		sta vscan
vdotc1:
		lda vscan
		cmp pend
		bcs vdotc2
		lda #' '
		jsr xchrout
		inc vscan
		jmp vdotc1
vdotc2:
		lda #1
		sta crsrx
		jsr crsrpos
		ldx #4
		jmp vexit

; --- 11/10/2026: "*** End of Text ***" (user's request) on the row after
; the last line that isn't blank (vend; none typed: line 1), moving as the
; text grows or shrinks. Only the cursor's line changes in an edit (no key
; moves lines), so after each key chkend looks at that line alone: text on
; it past vend makes it the end; vend's line made blank, the end is the
; first line with text above it. findend scans from line 254 down when a
; page is drawn. The rows below the marker are blank and can be typed on.

; Z set if the page's row X (1-23) is the marker's: top-1+X = vend+1
markrow:
		txa
		clc
		adc top
		sec
		sbc #2
		cmp vend
		rts

; the marker, from the start of a row: reverse off, grey, the text
printmark:
		lda #$92
		jsr xchrout
		lda #$98	; (grey)
		jsr xchrout
		ldx #0
printm1:
		stx vscan
		lda marktext,x
		beq printm2
		jsr xchrout
		ldx vscan
		inx
		jmp printm1
printm2:
		lda #$98	; what's in effect now
		sta lastc
		lda #$92
		sta lastr
		rts
marktext:
		ascii "*** End of Text ***"
		byte 0

; vend: the last line with text, from line 254 down (findend) or from line
; X down (findfrom); 0 if none. A line on the page is expanded (lastcol), one
; off it packed (its length). Leaves varbuf on another line: the caller
; gets its own back (rowdes)
findend:
		ldx #254
findfrom:
		stx vscan
		cpx #0
		beq findf9
		txa
		cmp top
		bcc findf1	; above the page
		sec
		sbc top
		cmp #23
		bcs findf1	; below it
		tax
		inx		; its row
		jsr rowdes
		jsr lastcol
		jmp findf2
findf1:
		ldx vscan
		jsr getdes
		lda varbuf	; its length
findf2:
		bne findf8
		ldx vscan
		dex
		jmp findfrom
findf8:
		lda vscan
findf9:
		sta vend
		rts

; after a key: the cursor's line (varbuf, line top-1+crsry) against vend
chkend:
		jsr lastcol
		pha
		lda crsry
		clc
		adc top
		sec
		sbc #1
		sta vline
		pla
		beq chkend2
		lda vend	; text on it: past vend, it's the end now
		cmp vline
		bcs chkend9
		sta vold
		lda vline
		sta vend
		jmp movemark
chkend2:
		lda vline	; blank: if it was the end, look above it
		cmp vend
		bne chkend9
		sta vold
		tax
		dex
		jsr findfrom
		jmp movemark
chkend9:
		rts

; vend moved from vold: redraw the old marker's row and draw the new one,
; then the cursor, reverse and colour back, and varbuf on its line again
movemark:
		lda crsrx
		sta msx
		lda crsry
		sta msy
		ldx vold
		inx
		jsr drawline
		ldx vend
		inx
		jsr drawline
		lda msx
		sta crsrx
		lda msy
		sta crsry
		jsr crsrpos
		ldx crsrr
		lda revers,x
		jsr xchrout
		ldx crsrc
		lda colors,x
		jsr xchrout
		ldx crsry
		jmp rowdes

; line X (1-254) again, if it's on the page: the marker, or its text and
; then spaces over what the marker left (to column 19)
drawline:
		cpx #0
		beq drawl9	; 255+1: no line
		txa
		cmp top
		bcc drawl9
		sec
		sbc top
		cmp #23
		bcs drawl9
		tax
		inx
		stx crsry
		lda #1
		sta crsrx
		jsr crsrpos
		lda #$ff
		sta lastc
		ldx crsry
		jsr markrow
		bne drawl1
		jmp printmark
drawl1:
		lda #$92
		jsr xchrout
		lda #$92
		sta lastr
		ldx crsry
		jsr rowdes
		jsr lastcol
		sta pend
		lda #1
		jsr pack
		jsr outbuf
		lda #$92	; reverse off, so the spaces blank it
		jsr xchrout
		lda pend
		sta vscan
drawl2:
		lda vscan
		cmp #19
		bcs drawl9
		lda #' '
		jsr xchrout
		inc vscan
		jmp drawl2
drawl9:
		rts

vend:
		byte 0	; the last line with text (0: none)
vold:
		byte 0
vline:
		byte 0
vscan:
		byte 0
msx:
		byte 0
msy:
		byte 0

; --- 128: pages (11/08/2026)

; the page's row X (1-23): tt$(top-1+X) into varbuf
rowdes:
		txa
		clc
		adc top
		tax
		dex
		jmp getdes

; the next page (pgnext) or the one before (pgprev), if there is one: the
; page's lines stored packed, top moved, the new page's lines expanded;
; carry set: none (top is already the first, the last page that fits, or
; (11/11/2026) the next would start past the End of Text marker's line)
pgnext:
		lda top
		clc
		adc #23		; the next page's first line:
		cmp #233	; its last (+22) past 254, or
		bcs pgnone
		cmp vmax	; past the most lines the user may write: none
		beq pgnext0
		bcs pgnone
; 11/11/2026: nor past the end of the text: its first line (top+23) at most
; the End of Text marker's (vend+1), so top+22 <= vend (user's request)
pgnext0:
		sec
		sbc #1
		cmp vend
		beq pgnext1
		bcs pgnone
pgnext1:
		jsr vpack
		lda top
		clc
		adc #23
		sta top
		jmp pgmove
pgprev:
		lda top
		cmp #2
		bcc pgnone
		jsr vpack
		lda top
		sec
		sbc #23
		sta top
pgmove:
		jsr vexpand
		clc
		rts
pgnone:
		sec
		rts

; Ctrl-V, Ctrl-Y: the next page, the one before; the cursor where it was
kpgdn:
		jsr pgnext
		bcs kpg9
		jmp visual2
kpgup:
		jsr pgprev
		bcs kpg9
		jmp visual2
kpg9:
		jmp visual5

; Up on the top row, Down on the bottom: the page before (the cursor on its
; bottom row), the next (on its top row)
kupedge:
		jsr pgprev
		bcs kpg9
		lda #23
		sta crsry
		jmp visual2
kdnedge:
		jsr pgnext
		bcs kpg9
		lda #1
		sta crsry
		jmp visual2

; the page's 23 lines (tt$(top..top+22)), expanded, stored packed
vpack:
		lda #1
		sta numy
vpack1:
		ldx numy
		jsr rowdes
		jsr lastcol
		sta pend
		lda #$92	; (rvrs off): a line starts with reverse off
		sta lastr
		lda #$ff	; and with no colour known: the first one is sent
		sta lastc
		lda #1
		jsr pack
		lda plen
		sta index
		lda numy
		clc
		adc top
		tax
		dex
		jsr putln
		inc numy
		lda numy
		cmp #24
		bcc vpack1
		rts

; the page's 23 lines, packed in tt$(), expanded (3 bytes a column, as the
; editor keeps them): each read (getdes), unpacked into buf2 (unpack), and
; made a string of its own again (vputlnx)
vexpand:
		lda #1
		sta numy
vexpand1:
		ldx numy
		jsr rowdes
		jsr unpack
		lda numy
		clc
		adc top
		tax
		dex
		jsr vputlnx
		inc numy
		lda numy
		cmp #24
		bcc vexpand1
		rts

; the packed line in varbuf (reverse codes, colour codes, characters, as
; pack makes them) into buf2 as 39 columns of reverse, colour, character
; (117 bytes; index = 117), blank after its last character. A line starts
; with reverse off, and white until a colour code says otherwise
unpack:
		lda #$92
		sta ur
		lda #$05
		sta uc
		ldx #0
		ldy #0
unpack1:
		cpy varbuf	; its length
		bcs unpack8
		cpx #3*39
		bcs unpack8
		lda (varbuf+1),y
		iny
		cmp #$12	; (rvrs on)
		beq unpack2
		cmp #$92	; (rvrs off)
		bne unpack3
unpack2:
		sta ur
		jmp unpack1
unpack3:
		stx utmp	; a colour code?
		ldx #15
unpack4:
		cmp colors,x
		beq unpack5
		dex
		bpl unpack4
		ldx utmp	; a character: its column
		pha
		lda ur
		sta buf2,x
		inx
		lda uc
		sta buf2,x
		inx
		pla
		sta buf2,x
		inx
		jmp unpack1
unpack5:
		ldx utmp
		sta uc
		jmp unpack1
unpack8:
		cpx #3*39	; the rest of the line blank
		bcs unpack9
		lda #$92
		sta buf2,x
		inx
		lda #$05
		sta buf2,x
		inx
		lda #' '
		sta buf2,x
		inx
		jmp unpack8
unpack9:
		lda #3*39
		sta index
		rts

; tt$(vlast+1-254) emptied (putln of no bytes): text before the editor
; started is kept in tt$(1-vlast) only
blankrest:
		lda #0
		sta index
		ldx vlast
blankr1:
		cpx #254
		bcs blankr9
		inx
		txa
		pha
		jsr putln
		pla
		tax
		jmp blankr1
blankr9:
		rts

; the 16 colour codes (c64: the KERNAL's table at $e8da)
colors:
		byte $90, $05, $1c, $9f, $9c, $1e, $1f, $9e
		byte $81, $95, $96, $97, $98, $99, $9a, $9b

top:
		byte 1		; the page's first line in tt$() (1, 24, 47...)
numx:
		byte 0
numy:
		byte 0
ur:
		byte 0		; unpack: the reverse code in effect
uc:
		byte 0		; unpack: the colour code in effect
utmp:
		byte 0
tchar:
		byte 0		; track: the character sent
ventry:
		byte 0		; &,16's number: the entry (0 new, 1 keep, 2 back)
vmax:
		byte 254	; the most lines (lines; 254 at most)
vlast:
		byte 0		; the last line of text kept on entry
vcode:
		byte 0		; the exit code (.x: 1 saved, 4 a dot command)
; 11/11/2026: word wrap's word, up to 38 columns (114 bytes): past the
; overlay's end, in the protocol area's free room (to $2aff)
wraptmp:
