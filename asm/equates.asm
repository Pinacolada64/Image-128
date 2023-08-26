;
; Image BBS 128 v1.0 equates
; based on Ray Kelm's work on Image BBS 64
;

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
	ascii_ctrl_d	= 4
	ascii_ctrl_x	= 24

	comma		= $2c	; avoids assembler addressing mode errors with cmp ","

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

; same: memory address same between c64/c128
; [1.2]: labels/memory address is the same as 1.2
; [?]  : not certain of purpose of routine
; ($xx): Indirect addressing: $xx *256+ ($xx+1)

;		; 128	; c64
	d6510	= $00	; 128: 8502 I/O port data direction register
	r6510	= $01	; 128: 8502 I/O port data register
	bank	= $02	; 128: token 'search' looks for, or bank #
	charac	= $09	; search character
	endchr	= $0a	; flag: scan for quote at end of string
	dimflg	= $0e	; c64: $0c. default array dimension
	valtyp	= $0f	; c64: $0d. data type: $ff=string, $00=numeric
	intflg	= $10	; c64: $0e. data type: $80=integer, $00=Floating point
	tansgn	= $12
	poker	= $16	; c128: temp integer value (used by adrfor)
	linnum	= $16	; c128: temp integer value (used by adrfor)
			; TODO: rename ($3b) "linnum" to "curlin" in source modules to
			; avoid using wrong label @ $16
; relocated 2 bytes up from c64 zero-page:
	temppt	= $18	; c64: $16. Pointer to the Next Available Space in the Temporary String Stack
	lastpnt	= $19	; c64: ($17). Pointer to the Address of the Last String in the Temporary String Stack
	tempst	= $1b	; c64: $19-$21. c128: $1b-$23. Descriptor Stack for Temporary Strings
	index_24= $24	; c128: $24-$27. Miscellaneous Temporary Pointers and Save Area
			; official name is "index", renamed to not conflict with BBS flag @ $d00f
	resho	= $28	; c64: $26-$2a. c128: $28-$2c. Floating point product of multiply
	txttab	= $2d	; c64: ($2b). pointer to start of BASIC text in bank 0
	vartab	= $2f	; c64: ($2d). pointer to start of BASIC variables in bank 1
	arytab	= $31	; c64: ($2f). pointer to start of arrays in bank 1
	strend	= $33	; c64: ($31). pointer to start of free memory in bank 1
	fretop	= $35	; c64: ($33). pointer to bottom of dynamic string storage in bank 1
	frespc	= $37	; c64: ($35). pointer to most recently used string in bank 1
	memsiz	= $39	; c64: ($37). pointer to top of dynamic string storage in bank 1
;	linnum	= $3b	; c64: ($14). Current BASIC Line Number
			; TODO: rename ($3b) "linnum" to "curlin" in source modules to
			; avoid using wrong label @ $17
;	curlin	= $3b	; c128 label
	oldtxt	= $1202	; c64: $3d. Pointer to the start of current line
	txtptr	= $3d	; c128 label
	form	= $3f	; c128: used by "print using"
	datlin	= $41	; current "data" line #
	datptr	= $43	; current "data" item address
	inpptr	= $45	; vector: input routine
	varnam	= $47	; c64: $45-$46. c128: $47-$48. bytes of current BASIC variable name
	varpnt	= $49	; $49-$4a: pointer: current BASIC variable descriptor
	lstpnt 	= $4b	; pointer: index variable for "for...next"
	forpnt	= $4b
	opmask	= $4f	; c64: $4d
	defpnt	= $52	; c64: $4e
	dscpnt	= $52	; c64: $50
	four6	= $53	; FIXME: move elsewhere
	jmper	= $56	; c64: $54
	numwork	= $57	; $57-$5c: 6 bytes. FIXME: move elsewhere? or share with $63-$68?

	var	= $63	; c64: $61-$66. c128: $63-$68? FAC1, Floating Point Accumulator #1
	fac2	= $6a	; c64: $69-$6e? c128: $6a-$6f? FAC2
	arisgn	= $71	; c64: $6f. arithmetic sign
	fbufpt	= $74	; c64: $71
	chrinc	= $76	; c128: flag if 10K hires screen allocated

	status	= $90	; same: Kernal I/O Status Word
	xsav	= $97	; same: Temporary .X Register Save Area
;
; rs232
;
	dfltn	= $99	; same. Default Input Device (Set to 0 for Keyboard)
	dflto	= $9a	; same. default output device
	ptr1	= $9e	; same. temp storage

;	jiffy	= $a2	; FIXME: collision at 2593
	sal	= $ac	; pointer: tape buffer / screen scrolling
	eal	= $ae	; tape end addresses / end of program
	nxtbit	= $b5	; RS-232 transmit: next bit to be sent
	rodata	= $b6	; RS-232 Output Byte Buffer
	fnlen	= $b7	; same. filename length
	la	= $b8	; current file logical address
	sa	= $b9	; current file 2nd address
	fa	= $ba	; same: 186. current device address
	fnadr	= $bb	; same. vector: address of current filename string
	fsblk	= $be	; same. cassette block read count
	mych	= $bf	; same. serial word buffer
	stal	= $c1	; same. I/O start address (lo)
	stah	= $c2	; same. I/O start address (hi)
	lstx	= $c5	; c128: tape read/write data
	ribuf	= $c8	; c64: ($f7). vector to rs232 input buffer address
	robuf	= $ca	; c64: ($f9). vector to rs232 output buffer address
	ndx	= $d0	; c64: 198 / $c6. number of characters in keyboard buffer
	rvs	= $f3	; c64: 199 / $c7. flag: print reverse characters. 0=no, 1=yes

	sfdx	= $cb	; c64: $cb. flag: print shifted characters
	blnsw	= $0a27	; c64: $cc. Flag: Cursor enable. 0=enabled, <>0=disabled.
	blnct	= $0a28	; c64: $cd. Cursor blink countdown.
	gdbln	= $0a29	; c64: $ce. Character under cursor.
	blnon	= $cf
	crsw	= $d0	; Flag: Input from Keyboard or Screen
	pnt	= $d1
;	pntr	= $d3	; c128: shflg
	qtsw	= $f4	; c64: $d4. quote mode flag
	lnmx	= $d5
	tblx	= $d6
	zp_d7	= $d7	; temp storage for ASCII value of last char printed
	insrt	= $f5	; c64: $d8. insert mode flag
	ldtb1	= $d9

	free_fb	= $fb
	free_fc	= $fc
	free_fd	= $fd
	free_fe	= $fe
	free_ff	= $ff

;
; screen parameters
;
	rvs	= $f3	; c64: $c7. Flag: Print Reverse Characters? 0=No
	crsrflg	= 204	; c64: $cc.
	undchr	= 206	; c64: $ce.
	crsrmode= 207	; c64: $cf. Flag: Was Last Cursor Blink On or Off?
	curptr	= 209	; $d1
	scnpos	= $ec	; c64: $d3. current screen column (0-39)
	scnclm	= scnpos; screen column
	sline	= $eb	; c64: $d6. current screen row (0-24)
	colptr	= 243	; ($f3)

; immediate mode input buffer (161/$a1 bytes, $0200-$02a1)

	keyd     = $0277
	gdcol    = $0287
	shflag   = $d3	; c64: $028d. Shift, Ctrl, C=, Alt keys

; original docs had this labeled "mcolor," same as $07ec (MCI color).
; I'm favoring "color," "Mapping the C64"'s label:
	color	= 646	; $0286: Current Foreground Color for Text
	undcol	= 647	; $0287

	sat	= $0376	; c64: $026d. secondary address table
	chrget	= $0380	; c64: $0073
	chrgot	= $0386 ; c64: $0079

; Byte Indices to the Beginning and End of Receive and Transmit Buffers

	ridbe	= $0a18 ; c64: 667. RS-232: Index to End of Receive Buffer
	ridbs	= $0a19 ; c64: 668. RS-232: Index to Start of Receive Buffer
	rodbs	= $0a1a ; c64: 669. RS-232: Index to Start of Transmit Buffer
	rodbe	= $0a1b ; c64: 670. RS-232: Index to End of Transmit Buffer

; 2670-2687 / $0A6E-$0A7F: Unused (17 bytes)

;
; 2758-2815 / $0AC6-$0AFF: Unused (58 bytes)
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

	fkeybuf	= $100a ; c64: 679. c128: $100a-$10ff (4106-4351), $f5 (245) bytes
	adray1	= $117a	; c64: $03. Vector: Routine to Convert a Number from Floating Point to Signed Integer
	adray2	= $117c	; c64: $05. Vector: Routine to Convert a Number from Integer to Floating Point

	emptym0	= 711	; FIXME: $02c7-$02ff (711-767), $39 (57) bytes

	keyrept	= $0a22 ; [c64: 650] 128 = most keys repeat, 0=no keys repeat

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

;
; screen display stuff:
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

	ntscpal = $0a03	; c64: $02a6, c128: 255=pal, 1=ntsc

;	ribuf	= $0b00	; rs232 input buffer
;	robuf	= $0b80	; rs232 output buffer

;
; temporary storage for 8 rows of screen mask
; $1000-$12ff / 4096-4863 ($2ff / 767 bytes) [from ray's memory map]
;
	tempscn = $1000 ; 4096, $200 (40 x 8 = 512) bytes
	tempscn0= tempscn+(0*40) ; 000 lightbar row
	tempscn1= tempscn+(1*40) ; 040 user
	tempscn2= tempscn+(2*40) ; 080 last
	tempscn3= tempscn+(3*40) ; 120 name
	tempscn4= tempscn+(4*40) ; 160 mail
	tempscn5= tempscn+(5*40) ; 200 area
	tempscn6= tempscn+(6*40) ; 240 c=00003
	tempscn7= tempscn+(7*40) ; 280 receive/transmit windows
	tempcol	= $1140	; 4416, $140 bytes
	tempcol0= tempcol+(0*40) ; 000
	tempcol1= tempcol+(1*40) ; 040
	tempcol2= tempcol+(2*40) ; 080
	tempcol3= tempcol+(3*40) ; 120
	tempcol4= tempcol+(4*40) ; 160
	tempcol5= tempcol+(5*40) ; 200
	tempcol6= tempcol+(6*40) ; 240
	tempcol7= tempcol+(7*40) ; 280
	emptym3	= $1280 ; 4736-4863, 127 bytes

	oldlin	= $1200 ; c64: ($3b). previous BASIC line number
	usrpok	= $1219	; "usr" function jump vector. $1218 is $4c, the "jmp" opcode

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
	lobytes	= $1700 ; 25 bytes
	hibytes	= $1719 ; 25 bytes
	lobytec	= $1732 ; 25 bytes
	hibytec	= $174b ; 25 bytes
	emptym4	= $1764 ; 28 bytes
	pmodetbl= $1780 ; $80 bytes: MCI print mode table
		; $1800 : end of pmodetbl

; relocated cassette buffer data:
	cassbuff= $1800
	bootdev	= cassbuff + 000 ; 6144 / $1800: c64: 828. boot device #
	linflg	= cassbuff + 001 ; 6145 / $1801: c64: 829. line flag. 1=3000, 2=4000, other=300
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
	clock	= cassbuff + 217 ; 6361 / $18e2: [1.2] 1=Turns on idle screen clock
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
	rsinabl = rs232 + $15	; 6421 / $1915
	rsdisab = rs232 + $18	; 6424 / $1918
	rsget	= rs232 + $1b	; 6427 / $191b
	rsout	= rs232 + $1e	; 6430 / $191e
	rsbaud	= rs232 + $21	; 6433 / $1921
	rschar	= rs232 + $24	; 6436 / $1924
;
; Image routine jump table (21 bytes)
;
	outastr	= rs232 + $27	; 6439 / $1927: output a$
	usetbl1	= rs232 + $2a	; 6442 / $192a: '&' addresses table at $a000
	swapper	= rs232 + $2d	; 6445 / $192d: swap pages of memory
	swapagn	= rs232 + $30	; 6448 / $1930: re-swap same pages set up by 'swapper'
	trace	= rs232 + $33	; 6451 / $1933: BASIC line number trace
	chkspcl	= rs232 + $36	; 6454 / $1936: check for special chars in a$ [?]
	convchr	= rs232 + $39	; 6457 / $1939: convert special characters in a$ [?]

; buffers:

	buf2	= rs232	+ $3c	; 6460 / $193c: 80 / $50 bytes. c64: $ce27
	buffer	= buf2	+ $50	; 6540 / $198c: 80 / $50 bytes. c64: $ce77
;	longdate= $ceca ; starts at $cec7? im 3170

; $19dc-$1bff: $0223 / 547 bytes free

; TODO: $1a00-$1bff: $1ff / 511 bytes. room for IRQ/& jump tables?

; $1bff: end of Application Program Area

; FIXME Image IRQ jump table (under ROM):
	jmptbl	= $a000

; 7167 / $1C01: Normal start of BASIC text
; to reserve 9K RAM from 7168-16383 / $lC00-$3FFF: GRAPHIC l:GRAPHIC 0
; (9216 / $2400 bytes)

; 1) VIC = 40 (or VDC = 80) * 8 rows * 2 blocks (text/color) for screen mask buffer
;    max 80*8*2 = 1280 bytes

; 2) protocols

; transfer protocol area (c64: 2680 bytes)

	protosta= $1c00	; c64: $c000	; FIXME: maybe
	protoend= $2000 ; c64: $ca80	; FIXME: maybe

; 9216 - 1280 = 7,936 free

; $2001 - ?: adjusted start of BASIC

; FIXME: modules, sub-modules load...?


; variable creation
; these are from Rene Belzen's excellent article on the 128's BASIC Interpreter.

	getpos	= $7aaf	; find or create a variable in bank 1.
			; returns address < in .a & $49, > in .y & $4a
	addrbyt	= $8803	; calls addrbyt (16-bit), chkcom (,), getbyt (8-bit).
			; returns .x: 8-bit value, < $16, > $17: 16-bit value.

; FIXME BASIC routines:

	error	= $a437
	linkprg	= $af87 ; c64: $a533
	gone1	= $a7e7 ; for extra keywords
	gone2	= $a7ea
	linget	= $50a0	; c64: $a96b. Creates integer value from a character string
	frnum	= $77d7	; c64: $ad8a. get arbitrary numeric expression. returns in fac1.
	getadr	= $880f	; c64: $b7f7. call chkcom, frnum, adrfor.
	adrfor	= $8815 ; c128 only? get 16-bit number in fac1, return < .y & $16, > .a & $17
	frmevl	= $af96	; c64: $ad9e. evaluate string/math expressions
	eval1	= $ae8d
	parchk	= $aef1 ; parentheses check: '(', ')'
	chkcom	= $795c	; c64: $aefd. check if next character is comma, return "?syntax  error" if not
	synerr	= $4c83	; c64: $af08. emit "?syntax  error" [verified]

	ptrget1	= $b0e7	; set up descriptor stored in ($45) [varname],
			; returns address in (varpnt)
	ilqerr	= $7d28	; c64: $b248. issue "?illegal quantity  error"
	retbyt	= $b3a2
	makerm1	= $b475	; c64: midway through str$()
	getbytc	= $b79b
	getnum	= $87f4	; c64: $b7eb. get 8-bit value (0-255)
	retval	= $bc49

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
