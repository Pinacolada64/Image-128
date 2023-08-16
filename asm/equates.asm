;
; Image BBS 128 v1.0 equates
; based on Ray Kelm's work on Image BBS 64
;

;
; printable characters
;

	comma	= $2c
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
	ascii_ctrl_d	= 4
	ascii_ctrl_x	= 24

	comma	= $2c

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

; [1.2]: labels/memory address is the same as 1.2
; [?]  : not certain of purpose of routine
; ($xx): Indirect addressing: $xx *256+ ($xx+1)

;		; 128	; c64
	d8502	= $00	; 128: 8502 I/O port data direction register
	r8502	= $01	; 128: 8502 I/O port data register
	zp_02	= $02	; c64: free for use
	adray1	= $03	; c64: Vector: Routine to Convert a Number from Floating Point to Signed Integer
	adray2	= $05	; c64: Vector: Routine to Convert a Number from Integer to Floating Point
	charac	= $0a
	endchr	= $0a
	dimflg	= $0e	; c64: $0c. default array dimension
	valtyp	= $0f	; c64: $0d. data type: $ff=string, $00=numeric
	intflg	= $10	; c64: $0e. data type: $80=integer, $00=Floating point
	tansgn	= $12
	poker	= $16	; c128: temp integer value (used by adrfor)
	linnum	= $17	; c128: temp integer value (used by adrfor)
			; TODO: rename ($3b) "linnum" to "curlin" in source modules to
			; avoid using wrong label @ $17
; relocated 2 bytes up from c64 zero-page:
	temppt	= $18	; c64: $16. Pointer to the Next Available Space in the Temporary String Stack
	lastpnt	= $19	; c64: ($17). Pointer to the Address of the Last String in the Temporary String Stack
	tempst	= $1b	; c64: $19-$21. c128: $1b-$23. Descriptor Stack for Temporary Strings
	24_index= $24	; c128: $24-$27. Miscellaneous Temporary Pointers and Save Area
			; official name is "index", renamed to not conflict with BBS flag @ $d00f
	resho	= $28	; c64: $26-$2a. c128: $28-$2c. Floating point product of multiply
	txttab	= $2d	; c64: ($2b). pointer to start of BASIC text in bank 0
	vartab	= $2f	; c64: ($2d). pointer to start of BASIC variables in bank 1
	arytab	= $31	; c64: ($2f). pointer to start of arrays in bank 1
	strend	= $33	; c64: ($31). pointer to start of free memory in bank 1
	fretop	= $35	; c64: ($33). pointer to bottom of dynamic string storage in bank 1
	frespc	= $37	; c64: ($35). pointer to most recently used string in bank 1
	memsiz	= $39	; c64: ($37). pointer to top of dynamic string storage in bank 1
	linnum	= $3b	; c64: ($14). Current BASIC Line Number
			; TODO: rename ($3b) "linnum" to "curlin" in source modules to
			; avoid using wrong label @ $17
;	curlin	= $3b	; c128 label
;	oldtxt	= $3d	; c64 label
	txtptr	= $7a	; c128 label
;	datlin	= $3f	; c64 label
;	form	= $3f	; c128: used by "print using"
	datlin	= $41	; current "data" line #
	datptr	= $43	; current "data" item address
	inpptr	= $45	; vector: input routine
	varnam	= $47	; c64: $45-$46. c128: $47-$48. bytes of current BASIC variable name
	varpnt	= $49	; pointer: current BASIC variable data
	lstpnt 	= $4b	; pointer: index variable for "for...next"
	forpnt	= $4b
	opmask	= $4f	; c64: $4d
	defpnt	= $52	; c64: $4e
	dscpnt	= $52	; c64: $50
	four6	= $53	; FIXME: move elsewhere
	jmper	= $56	; c64: $54
	numwork	= $57	; FIXME: move elsewhere $57-$5c: 6 bytes

	var	= $63	; c64: $61-$66. c128: $63-$68? FAC1, Floating Point Accumulator #1
	fac2	= $6a	; c64: $69-$6e? c128: $6a-$6f? FAC2
	arisgn	= $71	; c64: $6f. arithmetic sign
	fbufpt	= $72	; c64: $71
	chrinc	= $76	; c128: flag if 10K hires screen allocated

	status	= $90	; same: Kernal I/O Status Word
	xsav	= $97	; same: Temporary .X Register Save Area
;
; rs232
;
	dfltn	= $99	; Default Input Device (Set to 0 for Keyboard)
	dflto	= $9a	; default output device
	ptr1	= $9e	; temp storage

;	jiffy	= $a2
	sal	= $ac
	eal	= $ae
	nxtbit	= $b5
	rodata	= $b6	; RS-232 Output Byte Buffer
	fnlen	= $b7	; same: filename length
	la	= $b8
	sa	= $b9
	fa	= $ba	; same: current output device
	fnadr	= $bb
	fsblk	= $be
	mych	= $bf
	stal	= $c1
	zp_c4	= $c4
	lstx	= $c5
	ndx	= $c6
	sfdx	= $cb
	blnsw	= $cc
	blnct	= $cd
	gdbln	= $ce
	blnon	= $cf
	crsw	= $d0
	pnt	= $d1
;	pntr	= $d3
	qtsw	= $d4
	lnmx	= $d5
	tblx	= $d6
	zp_d7	= $d7 ; temp storage for ASCII value of last char printed
	insrt	= $d8
	ldtb1	= $d9

	ribuf	= $f7 ; pointer to rs232 input buffer address
	robuf	= $f9 ; pointer to rs232 output buffer address

	free_fb	= $fb
	free_fc	= $fc
	free_fd	= $fd
	free_fe	= $fe
	free_ff	= $ff

;
; screen parameters
;
	rvs	= $f3	; $c7 Flag: Print Reverse Characters? 0=No
	crsrflg	= 204	; $cc
	undchr	= 206	; $ce
	crsrmode= 207	; $cf Flag: Was Last Cursor Blink on or off?
	curptr	= 209	; $d1
	scnpos	= $ec	; $d3, current screen column (0-39)
	scnclm	= scnpos; screen column
	sline	= $eb	; $d6, current screen row (0-24)
	colptr	= 243	; ($f3)

; immediate mode input buffer (161/$a1 bytes, $0200-$02a1)

	sat      = $026d ; secondary address table
	keyd     = $0277
	gdcol    = $0287
	shflag   = $d3	; $028d: Shift, Ctrl, C=, Alt keys

; original docs had this labeled "mcolor," same as $07ec (MCI color).
; I'm favoring "color," "Mapping the C64"'s label:
	color	= 646	; $0286: Current Foreground Color for Text
	undcol	= 647	; $0287

	chrget	= $0380	; c64: $0073
	chrgot	= $0386 ; c64: $0079

; Byte Indices to the Beginning and End of Receive and Transmit Buffers

	ridbe	= $0a18 ; 667, RS-232: Index to End of Receive Buffer
	ridbs	= $0a19 ; 668, RS-232: Index to Start of Receive Buffer
	rodbs	= $0a1a ; 669, RS-232: Index to Start of Transmit Buffer
	rodbe	= $0a1b ; 670, RS-232: Index to End of Transmit Buffer

	fkeybuf	= $100a ; c64: 679, $100a-$10ff (4106-4351), $f5 (245) bytes
	emptym0	= 711	; $02c7-$02ff (711-767), $39 (57) bytes
;
; serial # stuff
;
	bsnpre	= $02fd	; 765 BBS serial # prefix (a/b/g...)
	bsnval	= $02fe	; 766 BBS serial # lo byte, 767=hi byte

	rptflg	= $0a22 ; [c64: 650] 128 = most keys repeat, 0=no keys repeat

	cassbuff= $0b00 ; [c64: 828] $0b00-$0bbf (2816-3007, 191 bytes)
			; during BOOT command, image of boot sector is held
			; in $0b00-$0bff. I don't see another reference to
			; $0bc0-$0bff in the memory map; could this area be
			; extended?

	idlemax	= cassbuff + 002 ; $0b02: maximum idle time allowed
	datebuf	= cassbuff + 003 ; $0b03: 11 bytes
	daytbl	= cassbuff + 014 ; $0b0e: 24 bytes (8*3: "???SunMonTueWedThuFriSat")
	tzoneh	= cassbuff + 038 ; $0b26: bbs  time zone hour
	tzonem	= cassbuff + 039 ; $0b27: bbs  time zone minute
	uzoneh	= cassbuff + 040 ; $0b28: user time zone hour
	uzonem	= cassbuff + 041 ; $0b29: user time zone minute
	wrapbuf	= cassbuff + 042 ; $0b2a: 80 bytes
; 23 1-byte placeholders...
	wrapflg	= cassbuff + 122 ; $0b7a
	modclmn	= cassbuff + 123 ; $0b7b: ll%: user's screen width
	ptrclmn	= cassbuff + 124 ; $0b7c: printer column [?]
	wrapind	= cassbuff + 125 ; $0b7d
	wrapdmp	= cassbuff + 126 ; $0b7e
	ptrclm	= cassbuff + 127 ; $0b7f
	modclm	= cassbuff + 128 ; $0b80
	sndtim1	= cassbuff + 129 ; $0b81
	sndtim2	= cassbuff + 130 ; $0b82
	sndwav1	= cassbuff + 131 ; $0b83
	sndwav2	= cassbuff + 132 ; $0b84
	sndwav3	= cassbuff + 133 ; $0b85
	sndrept = cassbuff + 134 ; $0b86
	sndtim1a= cassbuff + 135 ; $0b87
	sndtim2a= cassbuff + 136 ; $0b88
	jiffy	= cassbuff + 137 ; $0b89 FIXME: also $a2?
	blnkflag= cassbuff + 138 ; $0b8a screen blank flag
	blnkcntr= cassbuff + 139 ; $0b8b screen blank counter
	ptrlin	= cassbuff + 140 ; $0b8c
	ptrlinm	= cassbuff + 141 ; $0b8d
	usrlin	= cassbuff + 142 ; $0b8e mp%: user's screen height
	usrlinm	= cassbuff + 143 ; $0b8f how many lines output to modem [?]
	fredmode= cassbuff + 144 ; $0b90 file read mode [?]
; ...until here:
	montbl	= cassbuff + 145 ; $0b91 month names, 36 bytes (12*3):
					; "JanFebMarAprMayJunJulAugSepOctNovDec"
	emptym1	= cassbuff + 181 ; $0bb5 1 byte
	timeset	= cassbuff + 182 ; $0bb6 "time has been set" flag: 0=no, flash bottom screen line
	flag1	= cassbuff + 183 ; $0bb7
	case1	= cassbuff + 184 ; $0bb8 3 bytes
	temp3	= cassbuff + 187 ; $0bbb
	mline	= cassbuff + 188 ; $0bbc
	comm	= cassbuff + 189 ; $0bbd
	flags	= cassbuff + 190 ; $0bbe
	cline	= cassbuff + 191 ; $0bbf 3 bytes
	lines	= cassbuff + 194 ; $0bc2 [64: $03f8]: kk, # of lines in text editor buffer
	modes	= cassbuff + 195 ; $0bc3

;
; screen display stuff:
; screen RAM is  1024-2023  ($0400-$07e7)
;  color RAM is 55296-56296 ($d800-$dbe7)
;
	ldisp	= $0400+640
	lcolr	= $d800+640
	adisp	= $0400+880
	acolr	= $d800+880
	sdisp	= $0400+920
	scolr	= $d800+920
	tdisp	= $0400+960
	tcolr	= $d800+960

;
; FIXME: Message Command Interpreter variables:
; 24 bytes
;
	mjump	= $07e8	; 2024: # of lines to skip for £J, £E, £D
	mresult	= $07e9	; 2025: Result of £A, £T
	mspeed	= $07ea	; 2026: Print speed for £S
	mprint	= $07eb	; 2027: Print mode for £P
	mcolor	= $07ec	; 2028: Current color for £C
	mprtr	= $07ed	; 2029: Printer flag for £L
	mreverse= $07ee	; 2030: Reverse mode flag for £R
	mci	= $07ef	; 2031: 0=don't interpret MCI
	mdigits	= $07f0	; 2032: Number of digits for £#
	carrst	= $07f1	; 2033: modem carrier status (check mark/no check mark, displayed on screen)
	tsp1	= $07f2	; 2034: transmit speed lo-byte
	tsp2	= $07f3	; 2035: transmit speed hi-byte
	chks	= $07f4	; 2036: Checkmark flag for Lightbar (left side)
; unofficially added by Pinacolada:
	chk_rt	= $07f5 ; 2037: Checkmark flag for Lightbar (right side)
	readmode= $07f6	; 2038: [1.2] Unabortable file read flag
	filenum	= $07f7	; 2039: [1.2] [Logical] file number for read0/dskin
	tmp5	= $07f8	; 2040
	abtchr	= $07f9	; 2041: [1.2] Alternate abort character (works like <space>)
	clock	= $07fa ; 2042: [1.2] 1=Turns on idle screen clock
	filetyp	= $07fb	; 2043: [1.2] Filetype for Punter transfer protocol (1=PRG, 2=SEQ)
	tmp1	= $07fc	; 2044
	tmp2	= $07fd	; 2045
	tmp3	= $07fe	; 2046
	tmp4	= $07ff	; 2047

;
; rs232 jump table FIXME
;
	rs232	= $0800
	rsinabl = rs232 + $03
	rsdisab = rs232 + $06
	rsget	= rs232 + $09
	rsout	= rs232 + $0c
	rsbaud	= rs232 + $0f
	rschar	= rs232 + $12

	ntscpal = $0a03	; c64: $02a6, 255=pal, 1=ntsc FIXME

;	ribuf	= $0b00	; rs232 input buffer
;	robuf	= $0b80	; rs232 output buffer

	wedgemem= $0c00
	trapoff	= wedgemem+0
	trapon	= wedgemem+3
	loadprg	= wedgemem+6
	arraysav= wedgemem+9
	arrayres= wedgemem+12
	forcegc	= wedgemem+15

;
; temporary storage for screen mask? FIXME
;
	tempscn = $1000 ; 4096, $140 (320) bytes
	tempscn0= tempscn+000
	tempscn1= tempscn+040
	tempscn2= tempscn+080
	tempscn3= tempscn+120
	tempscn4= tempscn+160
	tempscn5= tempscn+200
	tempscn6= tempscn+240
	tempscn7= tempscn+280
	tempcol	= $1140	; 4416, $140 bytes
	tempcol0= tempcol+000
	tempcol1= tempcol+040
	tempcol2= tempcol+080
	tempcol3= tempcol+120
	tempcol4= tempcol+160
	tempcol5= tempcol+200
	tempcol6= tempcol+240
	tempcol7= tempcol+280
	emptym3	= $1280 ; 4736, 96 bytes

	oldlin	= $1200 ; c64: $3b, previous BASIC line number

; FIXME: relocate 25 bytes
	idlejif	= $12e0	; 4832
	idlesec	= $12e1	; 4833
	idleten	= $12e2	; 4834
	idlemin	= $12e3	; 4835
	curdsp	= $12e4	; 4836
	bar	= $12e5	; 4837
	tsr2	= $12e6	; 4838
	mright	= $12e7	; 4839: £m> right margin
	mleft	= $12e8	; 4840: £m< left margin
	cphase	= $12e9	; 4841
	key	= $12ea	; 4842
	shft	= $12eb	; 4843

	ptrlnfd	= $12f0	; 4848: printer linefeed. 1.3's +/IM.misc is $42f0 (17136)
	ha577	= $12f1	; 4849
	mask	= $12f2	; 4850: password mask character (1.3 is 17138)
	scnmode	= $12f3	; 4851: 17139: 1=mask off
	dflag	= $12f4	; 4852
	dstat	= $12f5	; 4853
	cytmp 	= $12f6	; 4854
	interm	= $12f7	; 4855
	cxsav	= $12f8	; 4856
	len1	= $12f9	; 4857
	passmode= $12fa	; 4858
	scnlock	= $12fb	; 4859
	tmp6	= $12fc	; 4860
	tmp7	= $12fd	; 4861
	freq	= $12fe	; 4862

;
; FIXME: relocate tables ($1300-$1800, $0500 bytes)
;
	chktbl	= $1300 ; $10 bytes (8 lightbar positions*2 checks per page, 8 pages=128 bits)
	bartbl	= $1310 ; $c0 bytes
	arryptrs= $13d0 ; $10 bytes
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
	lobytes	= $1700 ; 25 bytes
	hibytes	= $1719 ; 25 bytes
	lobytec	= $1732 ; 25 bytes
	hibytec	= $174b ; 25 bytes
	emptym4	= $1764 ; 28 bytes
	pmodetbl= $1780 ; $80 bytes: MCI print mode table

; FIXME Image IRQ jump table (under ROM):
	jmptbl	= $a000

; FIXME BASIC routines:
	error	= $a437
	linkprg	= $af87 ; c64: $a533
	gone1	= $a7e7
	gone2	= $a7ea
	linget	= $af9f	; c64: $a96b
	frnum	= $77d7	; c64: $ad8a. get arbitrary numeric expression. returns in fac1.
	getadr	= $880f	; c64: $b7f7. call chkcom, frnum, adrfor.
	adrfor	= $8815 ; c128 only? get 16-bit number in fac1, return < .y & $16, > .a & $17
	frmevl	= $af96	; c64: $ad9e. evaluate string/math expressions
	eval1	= $ae8d
	parchk	= $aef1 ; parentheses check: '(', ')'
	chkcom	= $795c	; c64: $aefd ; check if next character is comma, return "?syntax  error" if not
	synerr	= $af08 ; emit "?syntax  error"

	ptrget1	= $b0e7	; set up descriptor stored in ($45) [varname],
		; returns address in (varpnt)
	ilqerr	= $b248
	retbyt	= $b3a2
	makerm1	= $b475	; c64: midway through str$()
	getbytc	= $b79b
	getnum	= $87f4	; c64: $b7eb. get 8-bit value (0-255)
	retval	= $bc49

; FIXME transfer protocol area

	protosta= $c000
	protoend= $ca80	; 2680 bytes

;
; garbage collection stuff
;
	gc	= $c000	; module load addr
	gchide	= $e000	; swaps to
	gclen	= 4	; # pages
;
; extended command set stuff:
;
	ecs	= $c000	; module load addr
	ecshide	= $e400	; swaps to
	ecslen	= 10	; # pages (seems like a lot)

; FIXME Image routines:

	outastr	= $cd00	; output a$
	usetbl1	= $cd03	; irq addresses table at $a000
	swapper	= $cd06	; swap pages of memory
	swapagn	= $cd09	; re-swap same pages set up by 'swapper'
	trace	= $cd0c	; BASIC line number trace
	chkspcl	= $cd0f	; check for special chars in a$ [?]
	convchr	= $cd12	; convert special characters in a$ [?]

; FIXME buffers:

	buf2	= $ce27	; 80 bytes
	buffer	= $ce77	; 80 bytes
;	longdate= $ceca ; starts at $cec7? im 3170

; BBS flags (really, unused VIC-II registers)

	local	= $d000 ; 53248: 1=no modem output with &
	case	= $d001 ; 53249: &,1 or £Ix: can POKE this or set pl=1: UPPERCASE, pl=0: Mixed Case
	editor	= $d002 ; 53250: flags for &,1 routine
	tsr	= $d003 ; 53251: time remaining on call - needed by inline.s [?]
	llen	= $d004 ; 53252: max input line length for &,1 or £Ix
	flag	= $d005 ; 53253
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

; CIA #2 Time-of-Day clock stuff
	ten	= $dc08	; tenths of second
	scs	= $dc09 ; seconds
	min	= $dc0a ; minutes
	hrs	= $dc0b ; hours

;	carrier = $dd01 ; This definition conflicts with $d009;
			; "carrier" is referenced by irqhn.s
			; 56577: CIA #2 Data Port B
			; Bit 4: RS-232 carrier detect (DCD)/ Pin H of User Port

	colors	= $e8da	; flashing chat page color table

; Kernal routines:

	syscll	= $e130
	getfile	= $e1d4 ; 57812 (print last filename in BASIC)
	prtscn	= $e716	; output char in .a to screen regardless of output device

	setmsg	= $ff90
	readst	= $ffb7
	setlfs	= $ffba
	setnam	= $ffbd
	openf	= $ffc0
	closef	= $ffc3
	chkin	= $ffc6
	chkout	= $ffc9
	clrchn	= $ffcc
	chrin	= $ffcf
	chrout	= $ffd2
	loadf	= $ffd5
	savef	= $ffd8
	getin	= $ffe4

;
; Extended BASIC tokens:
;

	poketok	= 151	; poke $addr,$val
	peektok	= 194	; peek($addr)
	systok	= 158	; sys $addr
	loadtok	= 147	; load"filename",<device>,<segment>
	newtok	= 162	; "new <line_num>" erases <line_num>-

;
; module addresses:
;
	death	= $1800 ; 1.3 is $0800
	prgstart= $1801	; im
	bmpstart= $2001
	mmpstart= $3001
	lmpstart= $4001
	prgend	= $5000
	imstart	= $5001
;
; module line #s/sizes:
;
	mainline= 1000
	trapline= 2000
	imodline= 2300
	immdline= 3000
	immdsize= $a00
