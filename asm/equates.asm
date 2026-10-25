;
; Image BBS 128 v1.0 equates
; based on Ray Kelm's work on Image BBS 64
;
; the version of this ML:
{def:version_number = "1.0"}
;
; printable characters
;

	dish	= $08     ; disable case-shift
	ensh	= $09     ; enable case-shift
	swlc	= $0e     ; switch to lowercase
	swuc	= $8e     ; switch to uppercase

	carriage_return	= 13
	cbm_backspace	= 20
	ascii_backspace	= 8
	ascii_bel	= 7
	ascii_escape	= 27
	ascii_formfeed	= 12

	; file transfer signals
	ascii_ctrl_d	= 4
	ascii_ctrl_x	= 24

	comma		= $2c	; avoids assembler addressing mode errors with cmp ","
	colon		= 58
	apostrophe	= 39

; TODO: change these to c64list quoter equates
	cursor_right	= $1d
	cursor_left	= $9d
	cursor_up	= $91
	cursor_down	= $11
	reverse_on	= $12
	reverse_off	= $92
	clear_screen	= $93
	cursor_home	= $13
	british_pound	= $5c

	function_key_2	= 137
	function_key_5	= 135
	function_key_6	= 139
	function_key_7	= 136
	function_key_8	= 140

; color chr$() codes:
	chr_black	= $90
	chr_white	= $05
	chr_red		= $1c
	chr_cyan	= $9f
	chr_purple	= $9c
	chr_green	= $1e
	chr_blue	= $1f
	chr_yellow	= $9e
	chr_orange	= $81
	chr_brown	= $95
	chr_lt_red	= $96
	chr_gray1	= $97
	chr_gray2	= $98
	chr_lt_green	= $99
	chr_lt_blue	= $9a
	chr_gray3	= $9b

; the C64 source's names for the same codes (mcicm.asm's color table)
	cursor_white	= chr_white
	cursor_red	= chr_red
	cursor_cyan	= chr_cyan
	cursor_purple	= chr_purple
	cursor_green	= chr_green
	cursor_blue	= chr_blue
	cursor_yellow	= chr_yellow
	cursor_orange	= chr_orange
	cursor_brown	= chr_brown
	cursor_lt_red	= chr_lt_red
	cursor_gray1	= chr_gray1
	cursor_gray2	= chr_gray2
	cursor_lt_green	= chr_lt_green
	cursor_lt_blue	= chr_lt_blue
	cursor_gray3	= chr_gray3

; same: memory address same between c64/c128
; [1.2]: labels/memory address is the same as 1.2
; [?]  : not certain of purpose of routine
; ($xx): Indirect addressing: $xx *256+ $xx+1

;		; 128	; c64
	d6510	= $00	; 128: 8502 I/O port data direction register
	r6510	= $01	; 128: 8502 I/O port data register

	r6510_loram		= %00000001 ; (out) 1=basic, 0=RAM
	r6510_hiram		= %00000010 ; (out) 1=kernal, 0=RAM
	r6510_charen 		= %00000100 ; (out) 1=I/O, 0=Character ROM
	r6510_cassette_data 	= %00001000 ; (out) cassette port data output line
	r6510_cassette_switch 	= %00010000 ; (in) senses the cassette switch
	r6510_cassette_motor 	= %00100000 ; (out) 1=motor on, 0=motor off
	r6510_nc1            	= %01000000 ; not connected
	r6510_nc2            	= %10000000 ; not connected

	; allow access to character ROM ($33)
	r6510_char_rom = (r6510_cassette_motor | r6510_cassette_switch | r6510_hiram | r6510_loram)

	; allow access to all ram ($34)
	r6510_all_ram = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen)

	; "normal" for this register is $37
	r6510_normal = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen | r6510_hiram | r6510_loram)

	; allow access to the RAM "underneath" the BASIC ROM ($36)
	r6510_basic_ram = (r6510_cassette_motor | r6510_cassette_switch | r6510_charen | r6510_hiram)

; MMU. On the 128, $01 doesn't switch ROMs (the C64 code's r6510 writes
; above): the MMU's configuration register at $ff00 does, and it's visible
; in every configuration (Compute's 128 Programmer's Guide, chapter 7).
;
;  bits 7-6 RAM bank, 5-4 $c000-$ffff (00 KERNAL ROM, 11 RAM), 3-2
;  $8000-$bfff (00 BASIC ROM, 11 RAM), 1 $4000-$7fff (0 ROM, 1 RAM),
;  0 $d000-$dfff (0 I/O)

	mmucr	= $ff00	; configuration register
	mmurcr	= $d506	; RAM configuration register: shared ("common") RAM
	cfg_rom	= $00	; bank 15: BASIC, KERNAL and editor ROMs, I/O; what BASIC
			; runs in
	cfg_ml	= $7e	; Image's ML: bank 1 RAM at $4000-$bfff (BASIC's variables
			; and strings, and the swapped-out modules), RAM at
			; $c000-$ffff, I/O. With rcr_shared, $0000-$3fff and
			; $c000-$ffff are bank 0's RAM whatever bank is selected,
			; so the ML at $c000, the screen, Image's tables and
			; glue.asm all stay visible, and the C64 code's
			; "lda (pointer),y" on variables and strings just works
	cfg_bank0= $3f	; bank 0 all RAM, no I/O: to read BASIC program text
	cfg_charrom= $01 ; bank 0 with the ROMs, and the character ROM at $d000
			; in place of I/O (editor.asm's big letters read it)
	rcr_shared= $0f	; $d506: 16K shared at the bottom and the top (bits 0-3;
			; bits 6-7, the VIC's bank, are kept). BASIC's variables
			; then have to start at $4000 in bank 1 (intro.asm moves
			; them), clear of the shared bottom 16K

	bank	= $02	; 128: token 'search' looks for, or bank #
	ssreg	= $05	; c64: 783/$030f. save .s register
	sareg	= $06	; c64: 780/$030c. save .a register
	sxreg	= $07	; c64: 781/$030d. save .x register
	syreg	= $08	; c64: 782/$030e. save .y register
	charac	= $09	; search character
	endchr	= $0a	; flag: scan for quote at end of string
	dimflg	= $0e	; c64: $0c. default array dimension
	valtyp	= $0f	; c64: $0d. data type: $ff=string, $00=numeric
	intflg	= $10	; c64: $0e. data type: $80=integer, $00=Floating point
	tansgn	= $12
;	curlin	= $16	; c64: $14-$15. integer line number value
	poker	= $16	; c128: temp integer value (used by adrfor)
	linnum	= $16	; c64: $14-$15. c128: $16-$17. temp integer value (used by adrfor)
		; TODO: rename "linnum" ($16-$17) to "curlin" ($3b-$3c) in source modules to
		; avoid using wrong label @ $16
; relocated 2 bytes up from c64 zero-page:
	temppt	= $18	; c64: $16. Pointer to the Next Available Space in the Temporary String Stack
	lastpnt	= $19	; c64: ($17). Pointer to the Address of the Last String in the Temporary String Stack
	tempst	= $1b	; c64: $19-$21. c128: $1b-$23. Descriptor Stack for Temporary Strings
	index_24= $24	; c64: $22-$25. c128: $24-$27. Miscellaneous Temporary Pointers and Save Area
			; official name is "index", renamed to not conflict with BBS flag @ $d00f
	resho	= $28	; c64: $26-$2a. c128: $28-$2c. Floating point product of multiply
	txttab	= $2d	; c64: ($2b). pointer to start of BASIC text in bank 0
	vartab	= $2f	; c64: ($2d). pointer to start of BASIC variables in bank 1
	arytab	= $0031	; c64: ($2f). pointer to start of arrays in bank 1
	strend	= $33	; c64: ($31)/(49). pointer to start of free memory in bank 1
	fretop	= $35	; c64: ($33). pointer to bottom of dynamic string storage in bank 1
	frespc	= $37	; c64: ($35). pointer to most recently used string in bank 1
	memsiz	= $39	; c64: ($37). pointer to top of BASIC [default: $feff]
	curlin	= $3b	; c64: ($39). Current BASIC Line Number
	oldtxt	= $1202	; c64: ($3d). Pointer to the start of current line
	txtptr	= $3d	; c64: ($7a). Pointer to address of current BASIC statement
	runmod	= $7f	; [128 BASIC] bit 7: running a program (not direct mode)
	stksav	= $82	; [128 BASIC] the CPU's stack pointer at the start of the
			; statement (NEWSTT, $4b00; program mode only)
	bstkptr	= $7d	; [128 BASIC] ($7d) points at the newest frame on BASIC's
			; run-time stack, $0800-$09ff ($09ff: empty). FOR $81
			; (18 bytes), GOSUB $8d and DO $eb (5: token, line, txtptr)
	form	= $3f	; c128: used by "print using"
	datlin	= $41	; c64: ($3f). current "data" line #
	datptr	= $43	; c64: ($41). current "data" item address
	inpptr	= $45	; vector: input routine
	varnam	= $47	; c64: $45/$46. c128: $47/$48. bytes of current BASIC variable name
	varpnt	= $49	; c64: ($47)/(71): pointer: current BASIC variable descriptor
	forpnt 	= $4b	; pointer: index variable for "for...next"
	opmask	= $4f	; c64: $4d. math operator table displacement
	defpnt	= $52	; c64: $4e. pointer to current DEF FN descriptor
	dscpnt	= $52	; c64: $50-$52. 128: $52-$54. temporary pointer to current string descriptor
;	four6	= $53	; c64: constant for garbage collection. FIXME: move elsewhere
	jmper	= $56	; c64: $54-$56. 128: $56-$58. jump to 'fn' instruction
	numwork	= $57	; c64: $57-$60. 128: $59-$62. both 9 bytes.

	var	= $0063	; c64: $61-$66. c128: $63-$67. FAC1, Floating Point Accumulator #1
	varbuf	= var	; used by varbl.asm
	fac2	= $6a	; c64: $69-$6e? c128: $6a-$6e. FAC2
	arisgn	= $71	; c64: $6f. arithmetic sign
	fbufpt	= $74	; c64: $71-$72. series evaluation pointer
	chrinc	= $76	; c128: flag if 10K hires screen allocated
;
; $90-$c4 seem to be the same between c64/c128
;
	status	= $90	; same: Kernal I/O Status Word
	xsav	= $97	; same: Temporary .X Register Save Area
;
; rs232
;
	dfltn	= $99	; same. Default Input Device (Set to 0 for Keyboard)
	dflto	= $9a	; same. default output device
	ptr1	= free_fd	; c64: $9e, temp storage. On the 128 $9e is where LOAD
			; keeps the secondary address: Image's CHROUT hook storing
			; there made a LOAD that printed load at the file's address

;	jiffy	= $a2	; FIXME: collision at 2593
	sal	= $ac	; pointer: tape buffer / screen scrolling
	eal	= $ae	; tape end addresses / end of program
	cmp0	= $b0	; $b0/$b1. tape timing constants, temp usage
	nxtbit	= $b5	; RS-232 transmit: next bit to be sent
	rodata	= $b6	; RS-232 Output Byte Buffer
	fnlen	= $b7	; same. filename length
	la	= $b8	; current file logical address
	sa	= $b9	; current file 2nd address
	fa	= $ba	; same: 186. current device address
	fnadr	= $bb	; same. vector: address of current filename string
	fnbank	= $c7	; [128 OS] bank the filename is in (setbnk's .x)
	fsblk	= $be	; same. cassette block read count
	mych	= $bf	; same. serial word buffer
	stal	= $c1	; same. I/O start address (lo)
	stah	= $c2	; same. I/O start address (hi)
	ribuf	= $c8	; c64: ($f7). vector to rs232 input buffer address
	robuf	= $ca	; c64: ($f9). vector to rs232 output buffer address

	sfdx	= $cb	; c64: $cb. flag: print shifted characters
;		=	; c128: 866-875/$0362-$036B. c64: 601-610/$0259-$0262.
;			; Table of active logical file numbers
	crsw	= $d6	; c64: $d0. Flag: Input from Keyboard or Screen
	pnt	= $e0	; c64: ($d1). Pointer to the address of the current screen line
	qtsw	= $f4	; c64: $d4/212. quote mode flag
	zp_d7	= $f0	; c64: $d7. temp storage for ASCII value of last char printed
	insrt	= $f5	; c64: $d8/216. insert mode flag
;	ldtb1	= $d9	; c64: $d9-$f2/217-242. Screen line link table / editor temporary storage

	free_fb	= $fb
	free_fc	= $fc
	free_fd	= $fd
	free_fe	= $fe

;
; cursor stuff
;
	pntr	= $ec	; c64: $d3. cursor column on current line
	curptr	= $e0	; c64: $d1-$d2. Pointer to address of current screen line
	crsrmode= $0a26	; c64: $cf/207. Flag: Was last cursor blink on or off?
	crsrflg	= $0a27	; c64: $cc/204. Cursor blink enable flag (0 = flashing cursor)
	blnct	= $0a28	; c64: $cd. Cursor blink countdown.
	undchr	= $0a29	; c64: $ce. Character under cursor.
	gdcol	= $0a2a	; c64: $0287. Color of character under cursor
;
; screen parameters
;
	sline	= $eb	; c64: $d6. current screen row (0-24)
	scnpos	= $ec	; c64: $d3. current screen column (0-39)
	scnclm	= scnpos; screen column
	lnmx	= $ee	; c64: $d5. maximum screen line length. [128 OS] the
			; last column of the screen, 39 or 79, set by the editor
	rmargin	= $e7	; [128 OS] the editor window's right edge, where its
			; print wraps (39 or 79 for the whole screen)
	scbot	= $e4	; [128 OS] the editor window's bottom row: its
			; scrolls and line inserts stop there
	graphm	= $d8	; [128 OS] graphic mode: $ff keeps the editor's IRQ off
			; the VIC's $d018/$d011/$d016/$d012 (irq_far splits
			; the screen); the editor's init sets it back to 0
	vm1	= $0a2c	; [128 OS] the editor's $d018 for its text screen
	scrlflg	= $f8	; [128 OS] bit 7: no scrolling at the window's
			; bottom; bit 6: no line linking/inserting when a
			; print wraps (ESC L/M, ESC Q...)
	colptr	= $e2	; c64: ($f3). Pointer to the address of the current screen color RAM location
	rvs	= $f3	; c64: $c7. Flag: Print Reverse Characters? 0=No
	color	= $f1	; c64: $0286/646. Current foreground text color
			; (in 80 columns, a VDC attribute byte)
	mode	= $d7	; [128 OS] bit 7 set: editor is on the 80-column (VDC) screen
	vdcscrn	= $0a2e	; [128 OS] high byte of VDC screen RAM ($00)
	vdcattr	= $0a2f	; [128 OS] high byte of VDC attribute RAM ($08)
	vdccmode= $0a2b	; [128 OS] VDC cursor mode (R10) the editor shows its cursor with
	undcol	= gdcol	; c64: 647 ($0287); on the 128 $0287 is in BASIC's input buffer

;
; keyboard stuff:
;
	lstx	= $d5	; c64: 197 / $c5. last key pressed
	ndx	= $d0	; c64: 198 / $c6. number of characters in keyboard buffer
	ldtb2	= $035e	; [128 OS] screen line link bitmap, 4 bytes (c64: ldtb1, 217)
	bnkvar	= $03d5	; [128 OS] BASIC 7's BANK number (0-15), which peek, poke and sys use
	initstat= $0a04	; [128 OS] bit 0: the KERNAL's IRQ calls BASIC 7's (sprites,
			; SOUND, PLAY); bits 6-7: screen editor
	shflag	= $d3	; c64: $028d/653. Shift, C=, Ctrl, Alt keys: 1=pressed
	SHIFT_KEY	= %00000001
	COMMODORE_KEY	= %00000010
	CONTROL_KEY	= %00000100
	ALT_KEY		= %00001000

			; immediate mode input buffer
			; (c64: $0200-$0258,  88/$58 bytes,
	buf	= $0200	; c128: $0200-$02a0, 160/$a0 bytes)
	keyd	= $034a	; c64: $0277. keyboard buffer (both 10 bytes)
	keyrept	= $0a22 ; c64: 650. 128 = most keys repeat, 0=no keys repeat
	pkybuf	= $1000	; [128 OS] the KERNAL's function key definitions: ten
	pkybuf_lens = 10 ; lengths, then the text (intro zeroes the lengths)
	fkeybuf	= $100a ; c64: 679. c128: $100a-$10ff (4106-4351), $f5 (245) bytes,
			; where the KERNAL's key text was

;
; system vectors
;
	IERROR	= $0300	; [$4d3f] Indirect vector into BASIC error handling routine
	IMAIN	= $0302	; [$4db7] Indirect vector into BASIC main loop
	IGONE	= $0308	; [$a7e4] Indirect vector into executing next BASIC token
	IEVAL	= $030a	; [$ae86] Indirect vector into evaluating single-term arithmetic
			;		expression

	USRADD	= usrpok	; c64: $0311. the USR function's vector ($1219; $0311 is BASIC 7's IESCEX, the escape-token vector)
	ICHROUT	= $0326	; Indirect vector into BASIC CHROUT


	ldtnd	= $98	; same. number of open files (the tables below)
	lat	= $0362	; c64: $0259. logical file number table
	fat	= $036c	; c64: $0263. device number table
	sat	= $0376	; c64: $026d. secondary address table

; Byte Indices to the Beginning and End of Receive and Transmit Buffers

	ridbe	= $0a18 ; c64: 667. RS-232: Index to End of Receive Buffer
	ridbs	= $0a19 ; c64: 668. RS-232: Index to Start of Receive Buffer
	rodbs	= $0a1a ; c64: 669. RS-232: Index to Start of Transmit Buffer
	rodbe	= $0a1b ; c64: 670. RS-232: Index to End of Transmit Buffer

; the rest of the KERNAL's RS-232 variables the drivers use (rs232_*.asm;
; the 128 keeps the C64's zero page ones, $a7-$ab and $b4-$b6, where
; they were). Checked against kernal-318020-05.bin.
	palnts	= $0a03	; c64: $02a6. 0 = NTSC, 1 = PAL
	enabl	= $0a0f	; c64: $02a1. CIA #2 NMIs the RS-232 code has enabled
	baudof	= $0a16	; c64: $0299. time to send a bit (2 bytes)

; Image's RS-232 buffers: 128-byte rings indexed by the four above (c64:
; ribuf $0b00 and robuf $0b80). The drivers replace the KERNAL's RS-232
; code, so they use its buffers.
	rsibuf	= $0c00	; input
	rsobuf	= $0d00	; output

; the KERNAL's NMI entry ($ff05) saves .a .x .y and $ff00, switches to
; cfg_rom and jumps through NMINV ($0318); a handler ends with jmp here,
; which puts them back and returns (c64: $febc, which pulled .y .x .a)
	nmiexit	= $ff33

; the 128 KERNAL's own copies of the C64 routines the RS-232 drivers call
; by address (kernal-318020-05.bin, found by their code). The drivers'
; KERNAL hooks (CHKIN and the rest) run with the ROMs in.
	k_findfn = $f202	; c64: $f30f. find logical file .x: Z set, .x its table index
	k_devnum = $f212	; c64: $f31f. la, sa and fa from table entry .x
	k_nofile = $f682	; c64: $f701. return "file not open"

; 2670-2687 / $0A6E-$0A7F: Unused [128 OS] (17 bytes)

	ntscpal = $0a03	; c64: $02a6, c128: 255=pal, 1=ntsc

;
; 2758-2815 / $0AC6-$0AFF: [128 OS] Unused (58 bytes)
;
	idlejif	= $0ad0	; 2768
	idlesec	= $0ad1	; 2769
	idleten	= $0ad2	; 2770
	idlemin	= $0ad3	; 2771
	curdsp	= $0ad4	; 2772
	bar	= $0ad5	; 2773
	tsr2	= $0ad6	; 2774: 3 bytes
	cphase	= $0ad9	; 2777
	key	= $0ada	; 2778
	shft	= $0adb	; 2779: 5 bytes
		; $0adc ; 2780
		; $0add ; 2781
		; $0ade ; 2782
		; $0adf ; 2783
	ptrlnfd	= $0ae0	; 2784: [1.2: 17136] printer linefeed: +/IM.misc
	ha577	= $0ae1	; 2785
	mask	= $0ae2	; 2786: [1.2: 17138] password mask character
	scnmode	= $0ae3	; 2787: [1.2: 17139] 1=screen mask off
	dflag	= $0ae4	; 2788
	dstat	= $0ae5	; 2789
	cytmp 	= $0ae6	; 2790
	interm	= $0ae7	; 2791
	cxsav	= $0ae8	; 2792
	len1	= $0ae9	; 2793
	passmode= $0aea	; 2794
	scnlock	= $0aeb	; 2795
	tmp6	= $0aec	; 2796
	tmp7	= $0aed	; 2797
	freq	= $0aee	; 2798

; $0aff: end of unused block

; [128 OS]
	adray1	= $117a	; c64: $03. Vector: Routine to Convert a Number from Floating Point to Signed Integer
	adray2	= $117c	; c64: $05. Vector: Routine to Convert a Number from Integer to Floating Point
	oldlin	= $1200 ; c64: ($3b). previous BASIC line number
	usrpok	= $1219	; "usr" function jump vector. $1218 is $4c, the "jmp" opcode

	emptym0	= 711	; FIXME: $02c7-$02ff (711-767), $39 (57) bytes


;	cassbuff= $0b00 ; [c64: 828] $0b00-$0bbf (2816-3007, 191 bytes).
		; During BOOT command, image of boot sector is held
		; in $0b00-$0bff. I don't see another reference to
		; $0bc0-$0bff in the memory map; could this area be
		; extended?

		; There is a conflict with JiffyDOS's usage of this
		; area (255 bytes?) while LOADing BASIC programs.

		; This block has been relocated to $1800.

; $0bff / 3071: end of cassette buffer / boot sector image

; $0c00-$0cff: rs-232 input buffer

; $0d00-$0dff: rs-232 output buffer

; $0E00-$0FFF / 3584-4095: Sprite Pattern Storage Area (511 / $1ff bytes)

; screen display stuff (ldisp...tcolr, tempscn, tempcol): defined once,
; after protostart below
;	emptym3	= $1280 ; 4736-4863, 127 bytes


; 4862-4863 / $12FE-$12FF Unused (2 bytes)
; These locations are not used by any 128 ROM routine.

; Application Program Area
; 4864-7167 / $1300-$1BFF Unused (2304 / $8ff bytes)

;
; data tables ($1300-$1800, $0500 bytes)
; yay, they don't have to move!
;
	chktbl	= $1300 ; $10 bytes (8 lightbar positions*2 checks per page, 8 pages=128 bits)
	bartbl	= $1310 ; $c0 / 192 bytes
	arryptrs= $13d0 ; $10 bytes: FIXME: levels 1-8 with &,27,x?
	daysofm	= $13e0 ; $0c bytes: Days of months
	emptym2	= $13ec ; $04 bytes
	sndtbl	= $13f0 ; $60 bytes
	netalrm	= $1450 ; $30 bytes: Net Alarm table
	tblatc	= $1480 ; $80 bytes: ASCII -> C= translation [?]
	tblcta	= $1500 ; $100 bytes: C= -> ASCII translation [?]
	tblcta1	= $1600 ; $20 bytes
	tblcta2	= $1620 ; $20 bytes
	tblcta3	= $1640 ; $20 bytes
	alarmtb	= $1660 ; $80 bytes: Alarm table [?]
	date1	= $16e0 ; $20 bytes "Thu Sep 13, 2018 02:17 PM PSTxxx"
	lobytes	= $1700 ; 25 bytes: address of each line in screen RAM [?]
	hibytes	= $1719 ; 25 bytes
	lobytec	= $1732 ; 25 bytes: address of each line in color RAM [?]
	hibytec	= $174b ; 25 bytes
	emptym4	= $1764 ; 28 bytes: TODO: remove
	pmodetbl= $1780 ; $80 bytes: MCI print mode table
	; $1800 : end of pmodetbl

; relocated cassette buffer data:
	cassbuff= $1800
	bootdev	= cassbuff + 000 ; 6144 / $1800: c64: 828. boot device #
	linflg	= cassbuff + 001 ; 6145 / $1801: c64: 829. line flag. 1=3000, 2=4000, other=300
	loadflag= linflg	; c64: 829, the wedge's name for the same byte
	idlemax	= cassbuff + 002 ; 6146 / $1802: c64: 830. maximum idle time allowed
	datebuf	= cassbuff + 003 ; 6147 / $1803: 11 bytes
	daytbl	= cassbuff + 014 ; 6158 / $180e: 24 bytes (8*3: "???SunMonTueWedThuFriSat")
	tzoneh	= cassbuff + 038 ; 6182 / $1826: bbs  time zone hour
	tzonem	= cassbuff + 039 ; 6183 / $1827: bbs  time zone minute
	uzoneh	= cassbuff + 040 ; 6184 / $1828: user time zone hour
	uzonem	= cassbuff + 041 ; 6185 / $1829: user time zone minute
	wrapbuf	= cassbuff + 042 ; 6186 / $182a: 80 bytes
; 23 1-byte placeholders...
	wrapflg	= cassbuff + 122 ; 6266 / $187a
	modclmn	= cassbuff + 123 ; 6267 / $187b. c64: 951. ll%: user's screen width
	ptrclmn	= cassbuff + 124 ; 6268 / $187c: printer column [?]
	wrapind	= cassbuff + 125 ; 6269 / $187d
	wrapdmp	= cassbuff + 126 ; 6270 / $187e
	ptrclm	= cassbuff + 127 ; 6271 / $187f
	modclm	= cassbuff + 128 ; 6272 / $1880
	sndtim1	= cassbuff + 129 ; 6273 / $1881
	sndtim2	= cassbuff + 130 ; 6274 / $1882
	sndwav1	= cassbuff + 131 ; 6275 / $1883
	sndwav2	= cassbuff + 132 ; 6276 / $1884
	sndwav3	= cassbuff + 133 ; 6277 / $1885
	sndrept = cassbuff + 134 ; 6278 / $1886
	sndtim1a= cassbuff + 135 ; 6279 / $1887
	sndtim2a= cassbuff + 136 ; 6280 / $1888
	jiffy	= cassbuff + 137 ; 6281 / $1889 FIXME: also $a2?
	blnkflag= cassbuff + 138 ; 6282 / $188a screen blank flag
	blnkcntr= cassbuff + 139 ; 6283 / $188b screen blank counter
	ptrlin	= cassbuff + 140 ; 6284 / $188c
	ptrlinm	= cassbuff + 141 ; 6285 / $188d c64: 970.
	usrlin	= cassbuff + 142 ; 6286 / $188e c64: 971. mp%: user's screen height
	usrlinm	= cassbuff + 143 ; 6287 / $188f how many lines output to modem [?]
	fredmode= cassbuff + 144 ; 6288 / $1890 file read mode [?]
; ...until here:
	montbl	= cassbuff + 145 ; 6289 / $1891 month names, 36 bytes (12*3):
			; "JanFebMarAprMayJunJulAugSepOctNovDec"
	emptym1	= cassbuff + 181 ; 6325 / $18b5 1 byte
	timeset	= cassbuff + 182 ; 6326 / $18b6 "time has been set" flag: 0=no, flash bottom screen line
	flag1	= cassbuff + 183 ; 6327 / $18b7
	case1	= cassbuff + 184 ; 6328 / $18b8 3 bytes
	temp3	= cassbuff + 187 ; 6331 / $18bb
	mline	= cassbuff + 188 ; 6332 / $18bc
	comm	= cassbuff + 189 ; 6333 / $18bd
	flags	= cassbuff + 190 ; 6334 / $18be
	cline	= cassbuff + 191 ; 6335 / $18bf 3 bytes
	lines	= cassbuff + 194 ; 6338 / $18c2 [64: $03f8]: kk, # of lines in text editor buffer
	modes	= cassbuff + 195 ; 6339 / $18c3
;
; serial # stuff
;
	bsnpre	= cassbuff + 196 ; 6340 / $18c4.   c64:     765 / $02fd. BBS serial # prefix (a/b/g...)
	bsnval	= cassbuff + 197 ; 6341 / $18c5-6. c64: 766-767 / $02fe. BBS serial #: 766=lo byte, 767=hi byte
;
; Message Command Interpreter variables: 24 bytes
;
	mjump	= cassbuff + 199 ; 6343 / $18c7: # of lines to skip for £J, £E, £D
	mresult	= cassbuff + 200 ; 6344 / $18cb: Result of £A, £T
	mspeed	= cassbuff + 201 ; 6345 / $18d2: Print speed for £S
	mprint	= cassbuff + 202 ; 6346 / $18d3: Print mode for £P
	mcolor	= cassbuff + 203 ; 6347 / $18d4: Current color for £C
	mprtr	= cassbuff + 204 ; 6348 / $18d5: Printer flag for £L
	mreverse= cassbuff + 205 ; 6349 / $18d6: Reverse mode flag for £R
	mci	= cassbuff + 206 ; 6350 / $18d7: 0=don't interpret MCI
	mdigits	= cassbuff + 207 ; 6351 / $18d8: Number of digits for £#
	carrst	= cassbuff + 208 ; 6352 / $18d9: modem carrier status (check mark/no check mark, displayed on screen)
	tsp1	= cassbuff + 209 ; 6353 / $18da: transmit speed lo-byte
	tsp2	= cassbuff + 210 ; 6354 / $18db: transmit speed hi-byte
	chks	= cassbuff + 211 ; 6355 / $18dc: Checkmark flag for Lightbar (left side)
; unofficially added by Pinacolada:
	chk_rt	= cassbuff + 212 ; 6356 / $18dd: Checkmark flag for Lightbar (right side)
	readmode= cassbuff + 213 ; 6357 / $18de: [1.2] Unabortable file read flag
	filenum	= cassbuff + 214 ; 6358 / $18df: [1.2] [Logical] file number for read0/dskin
	tmp5	= cassbuff + 215 ; 6359 / $18e0
	abtchr	= cassbuff + 216 ; 6360 / $18e1: [1.2] Alternate abort character (works like <space>)
	clock	= cassbuff + 217 ; 6361 / $18d9: [1.2] 1=Turns on idle screen clock
	filetyp	= cassbuff + 218 ; 6362 / $18e3: [1.2] Filetype for Punter transfer protocol (1=PRG, 2=SEQ)
	tmp1	= cassbuff + 219 ; 6363 / $18e4
	tmp2	= cassbuff + 220 ; 6364 / $18e5
	tmp3	= cassbuff + 221 ; 6365 / $18e6
	tmp4	= cassbuff + 222 ; 6366 / $18e7
	mright	= cassbuff + 223 ; 6367 / $18e8: c64: 4839 / $12e7. £m> right margin
	mleft	= cassbuff + 224 ; 6368 / $18e9: c64: 4840 / $12e8. £m< left margin
;
; wedge jump table: 18 bytes
;
	wedgemem= $1900
	trapoff	= wedgemem + $00 ; 6400 / $1900: error trapping off
	trapon	= wedgemem + $03 ; 6403 / $1903: error trapping on
	loadprg	= wedgemem + $06 ; 6406 / $1906: load program
	arraysav= wedgemem + $09 ; 6409 / $1909: array pointer save
	arrayres= wedgemem + $0c ; 6412 / $190c: array pointer restore
	forcegc	= wedgemem + $0f ; 6415 / $190f: force garbage collection
;
; RS-232 jump table: 21 bytes
;
	rs232	= wedgemem + $12; 6418 / $1912
	rsinabl = rs232 + $03	; 6421 / $1915
	rsdisab = rs232 + $06	; 6424 / $1918
	rsget	= rs232 + $09	; 6427 / $191b
	rsout	= rs232 + $0c	; 6430 / $191e
	rsbaud	= rs232 + $0f	; 6433 / $1921
	rschar	= rs232 + $12	; 6436 / $1924
;
; interface page jump table (39 bytes; c64: $cd00, the same offsets)
;
	iface	= rs232 + 21	; 6439 / $1927
	outastr	= iface + 0	; 6439 / $1927: output a$
	outastrp= outastr	; c64: $cd00. the "jmp outastr" entry itself: swap3's
				; copyrite reads its target from outastrp+1/+2
	usetbl1	= iface + 3	; 6442 / $192a: '&' addresses table at $a000
	swapper	= iface + 6	; 6445 / $192d: swap pages of memory
	swapagn	= iface + 9	; 6448 / $1930: re-swap same pages set up by 'swapper'
	trace	= iface + 12	; 6451 / $1933: BASIC line number trace
	chkspcl	= iface + 15	; 6454 / $1936: check for special chars in a$ [?]
	convchr	= iface + 18	; 6457 / $1939: convert special characters in a$ [?]
	fnvar	= iface + 21	; 6460 / $193c: find variable
	fnvar1	= iface + 24	; 6463 / $193f: ?
	evalstr	= iface + 27	; 6466 / $1942: evaluate string
	evalbyt	= iface + 30	; 6469 / $1945: evaluate byte
	evalint	= iface + 33	; 6472 / $1948: evaluate integer
	evalfil	= iface + 36	; 6475 / $194b: evaluate filename?

; buffers:

; the buffer page (c64: $ce00): $0e00-$0fff, the sprite definition area
; (no sprites here). buffer-page.asm lays its data out at these addresses.

	bufpage	= $0e00
	d1str	= bufpage + $00	; 11 bytes
	spchars	= bufpage + $0b	; 8 bytes: what the encoded f-keys print as
	fbuf	= bufpage + $13	; 20 bytes: filename buffer. c64: $ce13
	bootdate_at = bufpage + $c7 ; the clock's date, 6 bytes BCD (buffer-page.asm's
			; bootdate): day of week, month, date, year. c64: $cec7
			; (52935), which sub.clocks pokes
	buf2	= bufpage + $27	; 80 bytes. c64: $ce27
	buffer	= bufpage + $77	; 80 bytes. c64: $ce77
;	longdate= buffer+ ?	; starts at $cec7? im 3170 $ce77 + $50 = $cf17

; $194e-$19ff: free (buf2 and buffer are in the buffer page at $0e00)

; TODO: $1a00-$1bff: $1ff / 511 bytes. room for IRQ/& jump tables?

; Image '&' jump table:
	jmptbl	= $1a00	; 72 * 2 = 144 bytes => 6800 / $1A90

; 369 bytes free

; $1bff: end of Application Program Area

; 7167 / $1C01: Normal start of BASIC text
; to reserve 9K RAM from 7168-16383 / $lC00-$3FFF: GRAPHIC l:GRAPHIC 0
; (9216 / $2400 bytes)

; 1) VIC = 40 (or VDC = 80) * 8 rows * 2 blocks (text/color) for screen mask buffer
;    max 80*8*2 = 1280 bytes

; 2) protocols

; swap-to / transfer protocol area (c64: $a78/2680 bytes)
; 128: $fff/4095 bytes

	protostart	= $1c00			; 128: $1c00. c64: $c000
	protobuf	= protostart	+ $f00	; 128: $2b00. proto block transfer area
	protoend	= protobuf	+ $ff	; 128: $2bff. c64: $ca80

; screen display stuff (bank 1):
; TODO: move to bank 1 so less banking back & forth?
; screen RAM is  1024-2023  ($0400-$07e7)
;  color RAM is 55296-56296 ($d800-$dbe7)
;
; the screen line calculations are zero-based (top screen line is offset 0)
; TODO: this will probably have to be made a table so we can refer to addresses
; for the VDC - or maybe use its block copy feature
;

	ldisp	= $0400 + (40*16) ; 640: lightbar
	lcolr	= $d800 + (40*16) ; 640
	adisp	= $0400 + (40*22) ; 880: access? c=, n=, i=, a=, 16-character window
	acolr	= $d800 + (40*22) ; 880
	sdisp	= $0400 + (40*23) ; 920: receive/transmit windows, free memory
	scolr	= $d800 + (40*23) ; 920
	tdisp	= $0400 + (40*24) ; 960: time/date, time left, status flags
	tcolr	= $d800 + (40*24) ; 960

;
; temporary storage for bottom 8 rows of screen mask
; c64: $1000-$12ff / 4096-4863 ($2ff / 767 bytes) [from ray's memory map]
; 128: $3300-$3580
;
	tempscn = $3300		;  $3300/13056, $200 (40 x 8 = 512) bytes
				;  $addr +offset
	tempscn0= tempscn+(0*40) ; $3300 +000 lightbar row
	tempscn1= tempscn+(1*40) ; $3328 +040 user
	tempscn2= tempscn+(2*40) ; $3350 +080 last
	tempscn3= tempscn+(3*40) ; $3378 +120 name
	tempscn4= tempscn+(4*40) ; $33a0 +160 mail
	tempscn5= tempscn+(5*40) ; $33c8 +200 area
	tempscn6= tempscn+(6*40) ; $33f0 +240 c=00003
	tempscn7= tempscn+(7*40) ; $3418 +280 receive/transmit windows
				 ; $3440

	tempcol	= tempscn+(8*40) ; $3440/13376, $200 bytes
	tempcol0= tempcol+(0*40) ; $3440 +000
	tempcol1= tempcol+(1*40) ; $3468 +040
	tempcol2= tempcol+(2*40) ; $3490 +080
	tempcol3= tempcol+(3*40) ; $34b8 +120
	tempcol4= tempcol+(4*40) ; $34e0 +160
	tempcol5= tempcol+(5*40) ; $3508 +200
	tempcol6= tempcol+(6*40) ; $3530 +240
	tempcol7= tempcol+(7*40) ; $3558 +280
				 ; $3580

; $3581 - $3600: $80 / 128 bytes free

; $3601 - $feff: adjusted range of BASIC

; FIXME: modules, sub-modules load...?


; variable creation
; these are from Rene Belzen's excellent article on the 128's BASIC Interpreter.

	addrbyt	= $8803	; calls addrbyt (16-bit), chkcom (,), getbyt (8-bit).
			; returns .x: 8-bit value, < $16, > $17: 16-bit value.

; ROM routines. k_* is each one's real address: BASIC 7.0 and KERNAL
; entries checked against kernal-318020-05, basiclo-318018-04 and
; basichi-318019-04 (VICE's images) next to the C64 routine they replace,
; on 2026-10-19; [af..] marks an address taken from BASIC 7.0's jump
; table at $af00 (Compute's 128 Programmer's Guide, pp. 323-324).
;
; Image's ML runs with cfg_ml in $ff00 (BASIC and KERNAL ROMs out; see
; "MMU" above), so it can't jsr a ROM routine directly: the plain names
; below (chrout, chkcom...) are stubs in romtab.asm that switch to cfg_rom,
; call k_*, and put the caller's $ff00 back. Code that runs under BASIC's
; own configuration (the wedge) defines direct_rom before including this
; file, which makes the plain names the k_* addresses themselves.
;
; To add one: give it a k_ address here, add it to both lists below with
; the next entry number (and bump romtab_entries), and add its stub to the
; end of romtab.asm.

	k_chrget	= $0380	; c64: $0073. RAM routine; ends in bank 15
	k_chrgot	= $0386	; c64: $0079
	k_chkcom	= $795c	; c64: $aefd. check for a comma or ?syntax error
	k_frmnum	= $77d7	; c64: $ad8a. evaluate numeric expression into FAC1
	k_frmevl	= $77ef	; c64: $ad9e. evaluate any expression [af96]
	k_frestr	= $877e	; c64: $b6a3. discard temp string: .a len, $24/$25 addr
	k_getbytc	= $87f4	; c64: $b79e (not $b79b: no chrget first). byte in .x
	k_getadr	= $8815	; c64: $b7f7. FAC1 to 16-bit linnum ($16/$17) [af0c]
	k_fout		= $8e42	; c64: $bddd. FAC1 to ASCII at $0100 [af06]
	k_jfout		= $8e32	; c64: $bdcd. print 16-bit .a (hi) .x (lo)
	k_ptrget	= $7aaf	; c64: $b08b. find/create variable named in text
	k_ptrget1	= $7b0b	; c64: $b0e7. find/create variable named in varnam
	k_makerm1	= $8688	; c64: $b475. allocate a string of length .a
	k_linkprg	= $4f4f	; c64: $a533. relink BASIC lines [af87]
	k_getfile	= $91ae	; c64: $e1d4. parse "name",dev,sa and setnam/setlfs
	k_prtscn	= $c72d	; c64: $e716. print .a on the screen [verified]
	k_givayf	= $793c	; c64: $b391. signed integer .a (hi) .y (lo) to FAC1 [af03]
	k_linget	= $50a0	; c64: $a96b. line number from text into linnum [af9f]
	k_parchk	= $7950	; c64: $aef1. "(" expression ")"
	k_setmsg	= $ff90
	k_readst	= $ffb7
	k_setlfs	= $ffba
	k_setnam	= $ffbd
	k_openf		= $ffc0
	k_closef	= $ffc3
	k_chkin		= $ffc6	; .x: lfn; set current input file
	k_chkout	= $ffc9
	k_clrchn	= $ffcc
	k_chrin		= $ffcf
	k_chrout	= $ffd2
	k_loadf		= $ffd5
	k_savef		= $ffd8
	k_getin		= $ffe4
	k_plot		= $fff0
	k_setbnk	= $ff68	; .a: bank for load/save data, .x: bank for the filename
	k_indfet	= $ff74	; FETCH: .a = lda (zero page .a),y in bank .x; keeps .y
	k_kbdget	= $c006	; c64: $f142 (GETIN's keyboard half): the screen editor's
				; next key, from a function key string or the buffer

; these don't return to their caller, so they're reached with
; farjmp_<name> in glue.asm (switch to cfg_rom, jmp) instead of a stub

	k_newstt	= $4af6	; c64: $a7ae. next statement [af90]
	k_gone1		= $4af3	; c64: $a7e7. execute the statement chrget just read,
				; then newstt (the default IGONE, $4aa2, from past
				; its sprite-collision code and chrget at $4af0)
	k_gone2		= k_newstt ; c64: $a7ea (jmp newstt)
	k_eval1		= $78e1	; c64: $ae8d. default IEVAL ($78da) past its chrget
	k_error		= $4d3c	; c64: $a437. jmp (IERROR), .x = error number
	k_ready		= $4d37	; c64: $a474. "ready." prompt [verified]
	k_run		= $5a9b	; c64: $a871. RUN [af7b]
	k_retval	= $8c75	; c64: $bc49. float the integer in FAC1 with exponent .x
				; (FLOATC [af0f]; enter with sec for positive)
	k_ilqerr	= $7d28	; c64: $b248. ?illegal quantity error
	k_synerr	= $4c83	; c64: $af08. ?syntax error [verified]
	k_goto		= $59db	; c64: $a8a0. GOTO
	k_gotol		= $59e2	; c64: $a8a3 (goto+3): go to the line in linnum,
				; setting txtptr -- GOTO past its linget and its
				; "was there a number" check ($59de); returns
	k_garbag	= $92ea	; BASIC 7's string garbage collection (FRE(1) calls it at
				; $803a); keeps its back-links. c64: Image's own, gc.asm
	k_syscll	= $5885	; c64: $e130. FIXME: re-evaluates its argument
	k_exitint	= $ff33	; c64: $ea81. exit IRQ: restore $ff00, .y, .x, .a, rti
	k_irq		= $fa65	; c64: $ea31. the KERNAL's IRQ handler (CINV's default):
				; screen editor, clock, keyboard; exits via $ff33
	k_primm		= $9281	; 128 only: print the null-terminated string after the jsr

{ifdef:direct_rom}
	chrget	= k_chrget
	chrgot	= k_chrgot
	chkcom	= k_chkcom
	frmnum	= k_frmnum
	frmevl	= k_frmevl
	frestr	= k_frestr
	getbytc	= k_getbytc
	getadr	= k_getadr
	fout	= k_fout
	jfout	= k_jfout
	ptrget	= k_ptrget
	ptrget1	= k_ptrget1
	makerm1	= k_makerm1
	linkprg	= k_linkprg
	getfile	= k_getfile
	prtscn	= k_prtscn
	givayf	= k_givayf
	linget	= k_linget
	parchk	= k_parchk
	setmsg	= k_setmsg
	readst	= k_readst
	setlfs	= k_setlfs
	setnam	= k_setnam
	openf	= k_openf
	closef	= k_closef
	chkin	= k_chkin
	chkout	= k_chkout
	clrchn	= k_clrchn
	chrin	= k_chrin
	chrout	= k_chrout
	loadf	= k_loadf
	savef	= k_savef
	getin	= k_getin
	plot	= k_plot
	setbnk	= k_setbnk
	kbdget	= k_kbdget
	gotol	= k_gotol
	indfet	= k_indfet
	newstt	= k_newstt
	gone1	= k_gone1
	gone2	= k_gone2
	eval1	= k_eval1
	error	= k_error
	ready	= k_ready
	run	= k_run
	retval	= k_retval
	ilqerr	= k_ilqerr
	synerr	= k_synerr
	goto	= k_goto
{else}
; stubs in romtab.asm, 7 bytes each (jsr farcall / byte cfg_rom / word k_* / rts)
	chrget	= romtab + 7*0
	chrgot	= romtab + 7*1
	chkcom	= romtab + 7*2
	frmnum	= romtab + 7*3
	frmevl	= romtab + 7*4
	frestr	= romtab + 7*5
	getbytc	= romtab + 7*6
	getadr	= romtab + 7*7
	fout	= romtab + 7*8
	jfout	= romtab + 7*9
	ptrget	= romtab + 7*10
	ptrget1	= romtab + 7*11
	makerm1	= romtab + 7*12
	linkprg	= romtab + 7*13
	getfile	= romtab + 7*14
	prtscn	= romtab + 7*15
	givayf	= romtab + 7*16
	linget	= romtab + 7*17
	parchk	= romtab + 7*18
	setmsg	= romtab + 7*19
	readst	= romtab + 7*20
	setlfs	= romtab + 7*21
	setnam	= romtab + 7*22
	openf	= romtab + 7*23
	closef	= romtab + 7*24
	chkin	= romtab + 7*25
	chkout	= romtab + 7*26
	clrchn	= romtab + 7*27
	chrin	= romtab + 7*28
	chrout	= romtab + 7*29
	loadf	= romtab + 7*30
	savef	= romtab + 7*31
	getin	= romtab + 7*32
	plot	= romtab + 7*33
	setbnk	= romtab + 7*34
	kbdget	= romtab + 7*35
	gotol	= romtab + 7*36
	romtab_entries = 37
{endif}




;
; where the boot loads each part of the ML. ml.asm assembles everything at
; these addresses and tools/split-ml.py cuts the result into files: the
; modules into bank 1 (above vartop, where they wait swapped out), the
; rest into bank 0. Nothing is moved at startup but the module in use.
;
	glue			= $3600	; $3600-$3fff: glue.asm, visible in every
					; configuration (shared bottom 16K)
	romtab			= $c000	; romtab.asm, then the resident ML:
	resident_lo_end		= $d000	;   $c000-$cfff
	resident_hi		= $e000	;   and $e000-$feff ($ff00-: MMU, and the
	resident_hi_end		= $ff00	;   KERNAL's interrupt code in RAM)

	wedge_load_address	= $2f00	; bank 0: loads where it runs
	editor_load_address	= $9000	; bank 1, $9000-$bfff: 48 pages
	gc_load_address		= $a000
	ecs_load_address	= $a400
	struct_load_address	= $ae00
	swap1_load_address	= $b400
	swap2_load_address	= $b800
	swap3_load_address	= $bc00

; address of modules when they are executing
; swap modules use protostart if not listed here
	rs232_exec_address	= $2c00	; $2c00-$2eff (the KERNAL's RS-232
					; buffers stay at $0c00-$0dff)
	wedge_exec_address	= $2f00
	editor_exec_address	= protostart

; address of modules when they are "swapped out," waiting to be used:
; where they load (bank 1, seen at these addresses in cfg_ml)

	editor_swap_address	= editor_load_address
	gc_swap_address		= gc_load_address
	ecs_swap_address	= ecs_load_address
	struct_swap_address	= struct_load_address
	swap1_swap_address	= swap1_load_address
	swap2_swap_address	= swap2_load_address
	swap3_swap_address	= swap3_load_address

; (gc and ecs run at protostart; ml.asm works out gc_pages and ecs_pages
; from the size of gc.bin and ecs.bin)

; the wedge's names for gc (c64: gc = $c000, gchide = $e000, gclen = 4)
	gc	= protostart	; where gc runs
	gchide	= gc_swap_address ; where gc waits, swapped out
	gclen	= 4		; pages: gc_load_address (bank 1) to ecs_load_address

; CIA #1 (same addresses on the 128)
	timblo	= $dc06	; timer B low byte
	timbhi	= $dc07	; timer B high byte
	d1icr	= $dc0d	; interrupt control register
	ciacrb	= $dc0f	; control register B

;
; BBS flags (really, unused VIC-II registers)
;
	local	= $d000 ; 53248: 1=no modem output with &
	case	= $d001 ; 53249: &,1 or £Ix: can POKE this or set pl=1: UPPERCASE, pl=0: Mixed Case
	editor	= $d002 ; 53250: flags for &,1 routine
	tsr	= $d003 ; 53251: time remaining on call - needed by inline.s [?]
	llen	= $d004 ; 53252: max input line length for &,1 or £Ix
	flag	= $d005 ; 53253
	someflag= flag	; the C64 source's other name for it (strio.asm, irqhn.asm)
	chat	= $d006 ; 53254: [1.2] Flag for returning from & for an abort
	inchat	= $d007 ; 53255
	chatpage= $d008 ; 53256: [1.2] 1=flashing chat page on
	carrier	= $d009 ; 53257: *** modem carrier status [?] ***
	mxor	= $d00a ; 53258: [1.2] carrier XOR value
	mkolor	= $d00b ; 53259: [1.2] MCI Kolorific mode flag
	mupcase	= $d00c ; 53260: [1.2] Uppercase mode flag
	irqcount= $d00d ; 53261: [1.2] IRQ slowdown flag
	trans	= $d00e ; 53262: [1.2] ASCII translation flag
	index	= $d00f ; 53263: [1.2] length of string returned by &,1 or £Ix

	colorram= $d800
;
; CIA #2 Time-of-Day clock stuff
;
	ten	= $dc08	; tenths of second
	scs	= $dc09 ; seconds
	min	= $dc0a ; minutes
	hrs	= $dc0b ; hours

;	carrier = $dd01 ; This definition conflicts with $d009;
		; "carrier" is referenced by irqhn.s
		; 56577: CIA #2 Data Port B
		; Bit 4: RS-232 carrier detect (DCD)/ Pin H of User Port

	romcolors= $0a80; c64: $e8da. table of chr$() values to print colors





;
; Extended BASIC tokens:
;

	poketok	= 151	; poke $addr,$val
	peektok	= 194	; peek($addr)
	systok	= 158	; sys $addr
	loadtok	= 147	; load"filename",<device>,<segment>
	newtok	= 162	; "new <line_num>" erases <line_num>-
			; related: $51d6 handles the NEW statement

;
; module addresses:
;
	prgstart= $4001	; im: BASIC text in bank 0 starts here (txttab), $4000 = 0
	textop	= $c000	; top of BASIC text in bank 0 ($1212), below the ML
	varstart= $4000	; bank 1: BASIC's variables start (vartab); BASIC sets
			; $0400 at power-up, which rcr_shared would put in bank 0
	vartop	= $9000	; bank 1: top of variables and strings ($39, $0a07);
			; the swapped-out modules are above it
;
; module line #s/sizes:
;
	mainline= 1000
	trapline= 2000
	imodline= 2300
	immdline= 3000
	immdsize= $a00
;
; Lt. Kernal hard drive equates
;
	ltk_bnkout= $fc4e
	ltk_bankin= $fc71
	ltk_getprt= $9f03
	ltk_driver= $8045
	ltk_redbuf= $91e0
	ltk_clrhdr= $806c
	ltk_fnfile= $804b
	ltk_alcont= $807b
	ltk_mnsext= $809c
	ltk_output= $8048
	ltk_activl= $8000
	ltk_activu= $8001
	ltk_setlun= $8099

	hdrblk	= $91e0
	filnam	= hdrblk+$00
	filtyp	= hdrblk+$18
	nbinfl	= hdrblk+$10
	loadad	= hdrblk+$1a
	blmilo	= hdrblk+$20
	nrpblk	= hdrblk+$12

; variable indices used with usevar/putvar

var_an_string	= 0
var_a_string	= 1
var_b_string	= 2
var_d1_string	= 4
var_lp_float	= 15
var_pl_float	= 16
var_rc_float	= 17
var_sh_float	= 18
var_ac_integer	= 24
var_w_string	= 27
var_p_string	= 28
var_tr_integer	= 29
var_a_integer	= 30
var_b_integer	= 31
var_dv_integer	= 32
var_c1_string	= 34
var_c2_string	= 35
var_co_string	= 36
var_kp_integer	= 38
var_c3_string	= 39
var_mp_string	= 48
var_mn_integer	= 49

; indices and bit masks for chktbl
flag_sys_addr	= chktbl + 0
flag_sys_l_mask	= %00000001	; 0 Sysop available to chat
flag_sys_r_mask	= %00000010	; 1 Background chat page enable

flag_acs_addr	= chktbl + 0
flag_acs_l_mask	= %00000100	; 2 Edit users access
flag_acs_r_mask	= %00001000	; 3 Block 300 baud callers

flag_loc_addr	= chktbl + 0
flag_loc_l_mask	= %00010000	; 4 Local mode (no modem I/O)
flag_loc_r_mask	= %00100000	; 5 ZZ (pseudo-local) mode

flag_tsr_addr	= chktbl + 0
flag_tsr_l_mask	= %01000000	; 6 Edit user's time remaining
flag_tsr_r_mask	= %10000000	; 7 Prime-time enabled

flag_cht_addr	= chktbl + 1
flag_cht_l_mask	= %00000001	; 8 Enter/exit chat mode
flag_cht_r_mask	= %00000010	; 9 Disable modem input

flag_new_addr	= chktbl + 1
flag_new_l_mask	= %00000100	; 10 Disallow new users
flag_new_r_mask	= %00001000	; 11 Enable screen blanking

flag_prt_addr	= chktbl + 1
flag_prt_l_mask	= %00010000	; 12 Print spooling
flag_prt_r_mask	= %00100000	; 13 Print log entries

flag_uxd_addr	= chktbl + 1
flag_uxd_l_mask	= %01000000	; 14 Disable U/D section
flag_uxd_r_mask	= %10000000	; 15 300 baud U/D lockout

flag_asc_addr	= chktbl + 2
flag_asc_l_mask	= %00000001	; 16 ASCII translation
flag_asc_r_mask	= %00000010	; 17 Line feed after carriage return

flag_ans_addr	= chktbl + 2
flag_ans_l_mask	= %00000100	; 18 ANSI color enabled
flag_ans_r_mask	= %00001000	; 19 ANSI graphics enabled

flag_exp_addr	= chktbl + 2
flag_exp_l_mask	= %00010000	; 20 Expert mode enabled
flag_exp_r_mask	= %00100000	; 21 Disallow double calls

flag_unv_addr	= chktbl + 2
flag_unv_l_mask	= %01000000	; 22 No immediate U/D credits
flag_unv_r_mask	= %10000000	; 23 Allow auto-logoff

flag_trc_addr	= chktbl + 3
flag_trc_l_mask	= %00000001	; 24 On-screen trace enable
flag_trc_r_mask	= %00000010	; 25 Undefined

flag_bel_addr	= chktbl + 3
flag_bel_l_mask	= %00000100	; 26 Local bells enabled
flag_bel_r_mask	= %00001000	; 27 Local beeps disabled

flag_net_addr	= chktbl + 3
flag_net_l_mask	= %00010000	; 28 NetMail enable
flag_net_r_mask	= %00100000	; 29 NetMail trigger

flag_mac_addr	= chktbl + 3
flag_mac_l_mask	= %01000000	; 30 Macros on/off
flag_mac_r_mask	= %10000000	; 31 MCI disable in editor

flag_chk_addr	= chktbl + 4
flag_chk_l_mask	= %00000001	; 32 Enable MailCheck at logon
flag_chk_r_mask	= %00000010	; 33 Excessive chat logoff

flag_mor_addr	= chktbl + 4
flag_mor_l_mask	= %00000100	; 34 More prompt on
flag_mor_r_mask	= %00001000	; 35 More prompt not available

flag_frd_addr	= chktbl + 4
flag_frd_l_mask	= %00010000	; 36 Full-color read disable
flag_frd_r_mask	= %00100000	; 37 Undefined

flag_sub_addr	= chktbl + 4
flag_sub_l_mask	= %01000000	; 38 Messages bases closed
flag_sub_r_mask	= %10000000	; 39 Files section closed

flag_res_addr	= chktbl + 5	; Res
flag_res_l_mask	= %00000001	; 40 System reserved
flag_res_r_mask	= %00000010	; 41 Network reserved

flag_mnt_addr	= chktbl + 5	; Mnt
flag_mnt_l_mask	= %00000100	; 42 Undefined
flag_mnt_r_mask	= %00001000	; 43 Modem answer disabled

flag_mnu_addr	= chktbl + 5 	; Mnu
flag_mnu_l_mask	= %00010000	; 44 Is user in menu mode?
flag_mnu_r_mask	= %00100000	; 45 Are menus available on BBS?

flag_h2e_addr	= chktbl + 5 	; $2e
flag_h2e_l_mask	= %01000000	; 46 Undefined
flag_h2e_r_mask	= %10000000	; 47 Undefined

; lightbar positions $3e-$6e are undefined

flag_h38_addr	= chktbl + 7 	; Trb
flag_h38_l_mask	= %00000001	; 56 ($38) On: Do not display BASIC variables
flag_h38_r_mask	= %00000010	; 57 ($39) Undefined

flag_dcd_addr	= chktbl + 7 	; DCD
flag_dcd_l_mask	= %00000100	; 58 ($3a) invert DCD: off=normal, on=inverted
flag_dcd_r_mask	= %00001000	; 59 ($3b) Carrier present

flag_dsr_addr	= chktbl + 7 	; DSR
flag_dsr_l_mask	= %00010000	; 60 ($3c) DCD/DSR select: on = DSR, off = DCD
flag_dsr_r_mask = %00100000	; 61 ($3d) enable RX/TX windows

; editor input flags

editor_allow_cursor_controls	= %00000001 ; allow cursor movement and color characters in input
editor_dot_on_column_one	= %00000010 ; dot on column one exits input
editor_show_prompt		= %00000100 ; show prompt
editor_allow_mci		= %00001000 ; allow mci command character input
editor_word_wrap		= %00010000 ; word wrap enabled
editor_edit_mode		= %00100000 ; edit mode
editor_ignore_time_remaining	= %01000000 ; ignore time remaining
editor_backspace_on_column_one	= %10000000 ; backspace on column one exits input

passmode_off			= %00000000 ; all password flags off
passmode_show_mask		= %00000001 ; password mask enabled for output
passmode_no_output		= %00000010 ; no output
