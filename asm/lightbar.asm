; rationale for changing lightbar:
; 1) options are scattered all over, some check mark slots are unused
; 2) some options are disabled by checking them; others are enabled by checking them.
;    this is inconsistent behavior

; design goals:
; 1) translation table between old and new lightbar reorganization. This would eliminate
;    having to renumber all the &,52,x,x function calls if a reorganized lightbar does get
;    adopted.

;    A (loadable?) table should be kept which has either the old organization of the lightbar
;    checkmarks (a 1:1 mapping to Image '64 3.x) or something like, e.g.:
;    'byte 0=6' where (old) 0=Sys left, (new) 3=Cht right [same purpose, different position]

; 2) Move lesser-used options out of page 0. I don't believe sysops are blocking 300 BPS
;    callers, toggling prime time, or toggling screen blanking frequently enough to warrant
;    using slots on what could be a very useful overview/quick access lightbar page 0.

orig $1c01	; 7169

; basic sys line
; 7169-7170 line link:
	word end_of_line
; 7171-7172 line number:
	word 10
; 7173      'sys' token:
	byte $9e
; 7174-7177 address:
	ascii "7181"
end_of_line:
; 7178      zero byte
	byte $00
; 7179-7180 end of program:
	word $0000

; VIC 40-column color RAM colors:
VIC_BLACK	= 0
VIC_WHITE	= 1
VIC_RED		= 2
VIC_CYAN	= 3
VIC_PURPLE	= 4
VIC_GREEN	= 5
VIC_BLUE	= 6
VIC_YELLOW	= 7
VIC_ORANGE	= 8
VIC_BROWN	= 9
VIC_LIGHT_RED	= 10
VIC_DARK_GRAY	= 11
VIC_MED_GRAY	= 12
VIC_LIGHT_GREEN	= 13
VIC_LIGHT_BLUE	= 14
VIC_LIGHT_GRAY	= 15

; screen code values:
checkmark	= 186	; $7a / %01111010
checkmark_rvs	= 250	; $fa / %11111010

; TODO: Add VDC colors

; keyboard stuff:
ndx		= $d0	; c64: $c6/198. number of characters in keyboard buffer
shflag		= $d3	; c64: $028d/653. Shift, C=, Ctrl, Alt keys: 1=pressed
SHIFT_KEY	= %00000001
COMMODORE_KEY	= %00000010
CONTROL_KEY	= %00000100
ALT_KEY		= %00001000


lstx		= $d5	; c64: 197 / $c5. last key pressed

; keyboard scan codes:
F1_KEY		= 4
F3_KEY		= 5
F5_KEY		= 6
F7_KEY		= 3

HELP_KEY	= 64

NO_KEY_PRESSED	= %01011000 ; +88

; ROM routines:
strout		= $ab1e
chrout		= $ffd2
check_stop_key	= $ffe1	; .z=1 if stop hit

text_ram	= $0400
color_ram	= $d800

VIC_SCREEN_WIDTH = 40 ; 0-indexed, so is 0-39 (40)

lightbar_text_addr	= text_ram  + (VIC_SCREEN_WIDTH * 16)
lightbar_color_addr	= color_ram + (VIC_SCREEN_WIDTH * 16)
screen_mask_text_addr	= text_ram  + (VIC_SCREEN_WIDTH * 17)
screen_mask_color_addr	= color_ram + (VIC_SCREEN_WIDTH * 17)

; variables referenced by code:
var_a_integer	= $ff

; cia time-of-day clock registers:
tod_tenths	= $dc08	; tenths of a second
tod_secs	= $dc09	; seconds
tod_min		= $dc0a	; minutes
tod_hrs		= $dc0b	; hours
ciacrb		= $dc0f	; cia control register b

setup:
	lda #'{clear}'
	jsr chrout
	lda #'{lowercase}'
	jsr chrout
	lda #VIC_LIGHT_GREEN
	sta 646
	lda #VIC_BLACK
	sta $d020
	sta $d021

; set tod clock:
; .x: hour, .y=minute
	ldx #11
	ldy #59
	jsr settim

; copy opening instructions:
; text data lines 1-4:
	lda #<instructions_1_4
	sta source+1
	lda #>instructions_1_4
	sta source+2

	lda #<text_ram
	sta dest+1
	lda #>text_ram
	sta dest+2
	clc	; copy text un-reversed
	jsr copy_init

; text data lines 5-8:
	lda #<instructions_5_8
	sta source+1
	lda #>instructions_5_8
	sta source+2

	lda #<(text_ram + VIC_SCREEN_WIDTH * 4)
	sta dest+1
	lda #>(text_ram + VIC_SCREEN_WIDTH * 4)
	sta dest+2
	clc	; copy text un-reversed
	jsr copy_init

; text data lines 9-12:
	lda #<instructions_9_12
	sta source+1
	lda #>instructions_9_12
	sta source+2

	lda #<(text_ram + VIC_SCREEN_WIDTH * 8)
	sta dest+1
	lda #>(text_ram + VIC_SCREEN_WIDTH * 8)
	sta dest+2
	clc	; copy text un-reversed
	jsr copy_init

; copy 1st half of screen mask:
; text data:
breakpoint:
	lda #<screen_mask_text_1_4
	sta source+1
	lda #>screen_mask_text_1_4
	sta source+2

	lda #<screen_mask_text_addr
	sta dest+1
	lda #>screen_mask_text_addr
	sta dest+2
	sec	; copy text reversed
	jsr copy_init

; color data (with theme colors applied):
	lda #<screen_mask_color_1_4
	sta source+1
	lda #>screen_mask_color_1_4
	sta source+2

	lda #<screen_mask_color_addr
	sta dest+1
	lda #>screen_mask_color_addr
	sta dest+2
	clc	; copy color un-reversed
	jsr theme_apply

; copy 2nd half of screen mask
; text data:
	lda #<screen_mask_text_5_8
	sta source+1
	lda #>screen_mask_text_5_8
	sta source+2

	lda #<(screen_mask_text_addr + VIC_SCREEN_WIDTH * 4)
	sta dest+1
	lda #>(screen_mask_text_addr + VIC_SCREEN_WIDTH * 4)
	sta dest+2
	sec	; copy text reversed
	jsr copy_init
; color data
	lda #<screen_mask_color_5_8
	sta source+1
	lda #>screen_mask_color_5_8
	sta source+2

	lda #<(screen_mask_color_addr + VIC_SCREEN_WIDTH * 4)
	sta dest+1
	lda #>(screen_mask_color_addr + VIC_SCREEN_WIDTH * 4)
	sta dest+2
	clc	; copy color data un-reversed
	jsr theme_apply

	jmp main_loop

copy_init:
; copy 4 lines of screen mask data/color to screen
; this will also be used for moving lightbar help text

; enter with .c=1 to invert copied text, .c=0 to not
	bcc not_reversed
	lda #%10000000
	bne store_reverse
not_reversed:
	lda #%00000000
store_reverse:
	sta reverse+1

	ldy #0
copy_loop:
source:
; copy 4 lines from source to dest
	lda $ffff,y
	jsr ascii_to_screencode
reverse:
	eor #$ff
dest:
	sta $ffff,y
	iny
	cpy #VIC_SCREEN_WIDTH * 4
	bne copy_loop
	rts

theme_apply:
; copy locations from initial copy operation
	lda source+1
	sta mod_theme_source+1
	lda source+2
	sta mod_theme_source+2
	lda dest+1
	sta mod_theme_dest+1
	lda dest+2
	sta mod_theme_dest+2

!breakpoint:
; save zp values on stack to restore at quit
	lda $fd
	pha
	lda $fe
	pha
; get theme #:
	lda theme_current
	cmp theme_count
	bpl theme_done
	asl
	tay
	lda theme_color_table,y
; store in hi/lo order since words are stored that way:
	sta $fd
	iny
	lda theme_color_table,y
	sta $fe

; replace color indices with theme colors:
; .x: index into screen_mask_color_1_4
; .y: index into theme_color_table
; .a: color RAM value

; set flag to not change lightbar colors in mid-redraw if IRQ fires:
	inc scnlock
	ldy #2

	lda ($fd),y
	sta mod_lightbar_background+1
	iny
	lda ($fd),y
	sta mod_lightbar_highlight+1
; resume updating lightbar:
	dec scnlock
; TODO: flashing chat page colors

	ldx #00
theme_loop:
; read theme colors, apply to screen mask
; we're not storing text data, that's already been done in 'copy_init'

; where to copy theme color data from:
mod_theme_source:
; get color index:
	lda $ffff,x
	tay
; now .y is index into theme_color_table
; get colors from theme table:
!theme_color_addr:
; get color index from screen mask color table:
	lda $ffff,y
mod_theme_dest:
	sta $ffff,x
	inx
	cpx VIC_SCREEN_WIDTH * 4
	bne theme_loop
!theme_done:
	pla
	sta $fe
	pla
	sta $fd
	rts

ascii_to_screencode:
	; by Mace on CSDB
	; convert ASCII/PetSCII to screen code
	; enter with .a: value

	cmp #$20	; if A<32 then...
	bcc ddRev

	cmp #$60	; if A<96 then...
	bcc dd1

	cmp #$80	; if A<128 then...
	bcc dd2

	cmp #$a0	; if A<160 then...
	bcc dd3

	cmp #$c0	; if A<192 then...
	bcc dd4

	cmp #$ff	; if A<255 then...
	bcc ddRev

	lda #$7e	; A=255, then A=126
	bne ddEnd

dd2:
	and #$5f	; if A=96..127 then strip bits 5 and 7
	bne ddEnd

dd3:
	ora #$40	; if A=128..159, then set bit 6
	bne ddEnd

dd4:
	eor #$c0	; if A=160..191 then flip bits 6 and 7
	bne ddEnd

dd1:
	and #$3f	; if A=32..95 then strip bits 6 and 7
	bpl ddEnd

ddRev:
	eor #$80	; flip bit 7 (reverse on when off and vice versa)
ddEnd:
	; screen code is now in accumulator
	rts

main_loop:
{def:use_ray_lightbar}
{ifdef:use_ray_lightbar}
	jsr irq7	; display lightbar checkmarks
	jsr irq4	; handle lightbar f-keys
	jsr clock	; display clock
{endif}
	jsr check_stop_key
	bne main_loop
basic:
; clear keyboard buffer of any pending keypresses
; TODO: clear f-key presses
	lda #$00
	sta ndx

	rts

{ifndef:use_ray_lightbar}
; print 8 lightbar pages
; 1) reset lightbar_label_index (which position, 0-7, we're drawing in the lightbar page)
;    reset lightbar_char_index (which character in the lightbar line we're drawing)
	lda #00
	sta lightbar_label_index
	sta lightbar_char_index
; 2) calculate which page we're on
	clc
	ldy lightbar_page
	lda lightbar_page_offsets,y
; .y holds offset into lightbar_text_offsets
	tay
; change self-modifying draw_lightbar_current_position address
	lda #<lightbar_text_offset_hi
	sta draw_lightbar0+1
	lda #>lightbar_text_offset_hi
	sta draw_lightbar0+2
; drawing lightbar text and lightbar checkmarks will be two separate IRQ tasks
draw_lightbar_status0:
; lightbar text address is self-modifying to free up .y
	sta $ffff

; get bits from checkmark table
	lda chktbl,y
	asl
	bcc chktbl_clear
; if set, draw checkmark:
	lda #checkmark
	jmp draw_lightbar3
chktbl_clear:
; otherwise, draw reversed space:
	lda #32
draw_lightbar3:
; reverse char
	eor #%10000000
	sta draw_char
lightbar_label:
; 0   12   34   56   7 etc.
; xSysxxAcsxxLocxxTsrx etc.
; if lightbar_label_index is even (bit #0=0), adc #3
; if lightbar_label_index is odd  (bit #0=1), adc #1
	lda lightbar_label_index
	and #1
	bne lightbar_label_index_add_1
	inc lightbar_char_index
	inc lightbar_char_index
lightbar_label_index_add_1:
	inc lightbar_char_index
	ldy lightbar_char_index
draw_char:
; char to print:
	lda #$ff
; eor bit 7 to reverse char on VIC; set 'reverse' attribute on VDC
	eor #%10000000
	sta lightbar_text,y

; TODO: need an abstracted "jsr put_console_char" subroutine (&,50: outscn)
; might put char .a at column .x, row .y
; and be aware of 40/80 column mode.
; surely one should be in the 128's ROM?
;	bit vic_or_vdc	; using 40 or 80 columns?
;	bcs using_80_columns
;	cmp console_screen_width

draw_lightbar0:
draw_lightbar1:
	sta lightbar_text,y

; handle colors:
; check for color change from background to highlight if lightbar_page_index = lightbar_position
	lda lightbar_char_index
	cmp lightbar_position
	bne draw_lightbar_background
	lda mask_theme_lightbar_highlight
	jmp draw_lightbar_color
draw_lightbar_background:
	lda mask_theme_lightbar_background
draw_lightbar_color:
	sta lightbar_color_addr,y
	iny
	cpy VIC_SCREEN_WIDTH
	bne draw_lightbar0

	rts

keyboard_handler:
; TODO: read HELP key
; if hit, save contents of 16 character window.
; put "Lightbar Help" in programmable 16-char window.
; copy 5 screen mask lines color/text data somewhere.
; save arrray pointers (use level 5, or the highest value).
; load tt$() from s.lightbar.
; display help text in screen mask area somehow. two lines at least, 1 for each checkmark option.

; T: change theme
	rts

lightbar_page:
; which page of the lightbar is being displayed
	byte $00
lightbar_position:
; which position (0-7) is to be highlighted
	byte $04
lightbar_index:
; which char in the lightbar line we are drawing:
	byte $ff

mask_theme_dark:
	byte VIC_MED_GRAY
mask_theme_light:
	byte VIC_LIGHT_GRAY
mask_theme_highlight:
	byte VIC_WHITE
mask_theme_lightbar_background:
	byte VIC_MED_GRAY
mask_theme_lightbar_highlight:
	byte VIC_WHITE

lightbar_page_offsets:
	byte 0,8,16,24,32,40

lightbar_text_offset_lo:
	byte <page0,<page1,<page2,<page3,<page4,<page5
lightbar_text_offset_hi:
	byte >page0,>page1,>page2,>page3,>page4,>page5
{endif}

{alpha:PokeAlt}
bartbl:
lightbar_text:
page0:
	ascii "SysAcsLocTsrChtNewPrtU/D"
; Old:
; x Sys  : Sysop available to chat
;   Sys x: Background page enable
; x Acs  : Edit user's access level
;   Acs x: Block 300 baud callers
; x Loc  : Local mode (console login)
;   Loc x: Pseudo-local ('ZZ') mode
; x Tsr  : Edit user's time left
;   Tsr x: Toggle prime time
; x Cht  : Enter/exit chat mode
;   Cht x: Disable modem input
; x New  : Disallow new users
;   New x: Enable screen blanking
; x Prt  : Print spooling
;   Prt x: Print log entries
; x U/D  : Disable U/D section
;   U/D x: 300 baud U/D lockout

; New:
; alphabetical within page (mostly), each page a broad category:
; common BBS options:
;	ascii "AcsChtLocPagRsvSysTsrNet"
; x Acs  : Edit user's access level
;   Acs x: Console keyboard lockout [WISH]
; x Cht  : Enter/exit chat mode
;   Cht x: Sysop available for chatting
; x Loc  : Local mode (console login)
;   Loc x: Pseudo-local ('ZZ') mode
; x Pag  : Background chat page enable
;   Pag x: Excessive chat page logoff active
; x Rsv  : Reserve BBS (need reservation password)
;   Rsv x: Network reservation active
; x Sys  : undefined
;   Sys x: Chat logging enable [WISH]
; x Tsr  : Edit user's time still remaining
;   Tsr x: undefined
; x Net  : NetMail transfers enabled
;   Net x: NetMail trigger active

; [CHANGE] maybe "Res x" and "Net x" are redundant?

page1:
; console options:
	ascii "AscAnsExpUnvTrcBelNetMac"
; OLD:
; x Asc   ;
;   Asc x ;
; x Ans   ;
;   Ans x ;
; x Exp   ;
;   Exp x ;
; x Unv   ;
;   Unv x ;
; x Trc   ;
;   Trc x ;
; x Bel   ;
;   Bel x ;
; x Net   ;
;   Net x ;
; x Mac   ;
;   Mac x ;

; NEW:
;	ascii "AscAnsBarBelDbgIdlMorTrc"
; x Bar  : Use Image '64 3.x lightbar configuration
; x Dbg  : Display debug info in modules enabled
;   Dbg x: Change border colors on error condition
;   Idl  : was "Alt"
; x Idl  : use color scheme 1 for last ten callers
;   Idl x: use "e.idlekeys" feature (extra functions) [?]
; x Trc  : Trace BASIC line numbers
;   Trc x: Trace ML program counter
page2:
	ascii "ChkMorFrdSubResMntMnuXpr"
; OLD:
; x Chk  : Enable MailCheck at Logon
;   Chk x: Excessive Chat logoff
; x Res  : System reserved
;   Res x: Network reserved

; NEW:
; caller options:
;	ascii "AscAnsMacMCIMnuMorXpr"
; x Asc  : ASCII translation enabled
;   Asc x: Send linefeed after carriage return
; x Ans  : ANSI color enabled
;   Ans x: ANSI graphics enabled
; x Mac  : Main prompt "macros" enabled
; x MCI  : MCI commands enabled
;   MCI x: MCI commands in text editor enabled
; x Mnu  : Graphic Menus Available
;   Mnu x: Graphic Menus Enabled
; x Mor  : More Prompt enabled
;   Mor x: More Prompt available
; x Xpr  : Xpress logon option available
page3:
; sysop-set user-facing BBS options:
	ascii "Em3Sc2ScpAltTrbDCDDSR$3e"
;	ascii "ChkFrdMacMnuNewSecSubUnv"
; x Chk  : Mail check at logon enabled
;   Chk x:
; x Frd  : Full-color read enabled [keep as homage to Fred Dart]
;   Frd x: undefined: FIXME: forwarding something?
; x Mac  : display main menu macros FIXME
; x Mnu  : Graphic Menus Available
;   Mnu x: Graphic Menus Enabled
; x New  : NEW users allowed
; x Lgn  : Second security check question
;   Lgn x: Display 's.detect' files
; x Sub  : U/D section available
;   Sub x: Sub-boards available
; x Unv  : Unvalidated files earn credit
;   Unv x: auto-logoff after file transfer done
; unassigned:
; allow back-to-back calls
page4:
; hardware options:
	ascii "$40$42$44$46$48$4a$4c$4e"
;	ascii "TboREURAMScnPrtRTCCMDLtK"
; x Tbo  : SuperCPU present
;   Tbo x: SuperCPU at 20 mHz
; x REU  : RAM expansion unit enabled
; x RAM  :
; x Scn  : Screen blanking enabled
;   Scn  : 40 columns?
;   Scn x: 80 columns? maybe 40/80 key instead
; x Prt  : Print all text to printer
;   Prt x: Print log entries to printer
; x RTC  : RTC present
;   RTC x: Sync RTC with BBS clock periodically
; x CMD  : CMD HD present; use subdirectories
;   CMD x: Sync BBS clock with RTC
; x LtK  : Lt. Kernal HD present
;   LtK x: Multiplexer present

page5:
; modem options
	ascii "$50$52$54$56$58$5a$5c$5e"
;	ascii "DCDDSRI/ORng300         "
; x DCD  : Hang up on inverted DSR signal
;[ ]DCD  : Hang up on no DCD signal
;   DCD x: Data carrier detect present
; x DSR  : Hang up on no Data Set Ready (DSR) signal
;[ ]DSR  : Hang up on no DCD signal
;   DSR x: Display Rx/Tx windows enabled
; x I/O  : Enable modem input
;   I/O x: Enable modem output
; x Rng  : Modem answer on ring enabled

; x Lgn  : Zero time at "Hit Backspace"
;   Lgn x:
; x 300  : 300 BPS caller logon enabled
;   300 x: 300 BPS caller U/Ds enabled
page6:
; undefined
	ascii "$60$62$64$66$68$6a$6c$6e"
page7:
; alarm triggers
	ascii "At1At2At3At4At5At6At7At8"

help_text:
; built-in help text if s.lightbar file missing:
; Sys:
	ascii "Sysop available for chat{0}"
; CHANGE: move to right Cht
	ascii "Background page sound enable{0}"
; Acs:
	ascii "Edit user's access level{0}"
	ascii "Allow 300 BPS callers{0}"
; Loc:
	ascii "Local mode (no modem output){0}"
	ascii "ZZ (pseudo-local) mode{0}"
; Tsr:
	ascii "Edit user’s time still remaining{0}"
	ascii "Toggle Prime Time on or off{0}"
; Cht:
	ascii "Enter or exit chat mode{0}"
; CHANGE: move elsewhere
	ascii "Enable modem input{0}"
; New:
	ascii "Allow NEW users{0}"
	ascii "Enable screen blanking{0}"
; Prt:
	ascii "{0}"
	ascii "{0}"
; U/D:
	ascii "{0}"
	ascii "{0}"
; Asc:
	ascii "{0}"
	ascii "{0}"
; Ans:
	ascii "{0}"
	ascii "{0}"
; Exp:
	ascii "{0}"
	ascii "{0}"
; Unv:
	ascii "{0}"
	ascii "{0}"
; Trc:
	ascii "Trace BASIC line number enabled{0}"
	ascii "Trace ML program counter enabled{0}"
; Bel:
	ascii "Console bell enabled{0}"
	ascii "Console beep enabled{0}"
; Net:
	ascii "Network file transfers enabled{0}"
	ascii "Network file transfer triggered{0}"
; Mac:
	ascii "Main prompt {quote}macros{quote} enabled{0}"
	ascii "MCI in text editor enabled{0}"
; Chk:
	ascii "{0}"
	ascii "{0}"
; Mor:
	ascii "'More' prompt enabled{0}"
	ascii "'More' prompt active{0}"
; Frd:
	ascii "Monochrome color output enabled{0}"
; right: forwarding something
	ascii "Undefined{0}"
; Sub:
	ascii "Message bases enabled{0}"
	ascii "File transfers enabled{0}"
; Res:
	ascii "BBS reserved{0}"
	ascii "{0}"
; Mdm:
	ascii "{0}"
	ascii "{0}"
; Mnu:
	ascii "Graphic menus available{0}"
	ascii "Graphic menus enabled{0}"
; Xpr:
	ascii "Express logon option available{0}"
	ascii "Auto-logoff after U/D available{0}"
{alpha:alt}

chktbl:
; each 1 bit represents a check mark in the lightbar
; 16 bits per page
; page 0:
	byte %01010101,%10101010
; page 1:
	byte %10101010,%01010101
; page 2:
	byte %01010101,%10101010
; page 3:
	byte %10101010,%01010101
; page 4:
	byte %01010101,%10101010
; page 5:
	byte %00110011,%11001100
; page 6:
	byte %00001111,%11110000
; page 7:
	byte %11001100,%00110011

bits:
; which bit to set in chktbl byte depending on lightbar_position:
	byte %00000001
	byte %00000010
	byte %00000100
	byte %00001000
	byte %00010000
	byte %00100000
	byte %01000000
	byte %10000000

; required to get upper/lowercase screen codes:
{'alpha:PokeAlt}
screen_mask_text_1_4:
; 0
	ascii "User Pinacolada            ID # DE1     "
; 40
	ascii "Last Mar 26, 2024  5:33 PM Call 1/48    "
; 80
	ascii "Name Ryan Sherwood         Prms 40x25   "
; 120
	ascii "Mail sym.rsherwood@gmail.c Baud Console "
; 160
screen_mask_text_5_8:
	ascii "Area Lightbar/Mask Mock-Up User 1/2     "
; 200
;                                      |<- msg area ->|
; TODO: Alt+another key could show a second status line in 40 col. mode, combined into 1 line in 80 col. mode
	ascii "C=00004 N=001 I=000 A=9 Screen Mask Test"
;	ascii "PT: 05:00 PM - 09:30 PM (00:30 min)"
; 240: $a0 = 128 + 32 for reverse spaces
; TODO: un-reverse these spaces
	ascii "R{$a0:10} M=18064  L=03006 {$a0:10}T"
; 280
	ascii checkmark,"Wed Mar 27, 2024 11:18:00 AM{space:5}--:59 "
; 320
{alpha:alt}

theme_current:
	byte 0
theme_count:
; since each entry takes 2 bytes, halve the value
; FIXME
	byte <(>@ - theme_color_table) / 2
!theme_color_table:
	word theme_color_grays, theme_color_blues, theme_color_monochrome, theme_color_user_defined
@:
theme_color_grays:
; format: mask_dark, mask_light, lightbar_background, lightbar_highlight:
	byte VIC_MED_GRAY,VIC_LIGHT_GRAY,VIC_MED_GRAY,VIC_WHITE
; 6 flashing chat page colors (irqhn.asm: pagecol):
	byte VIC_WHITE,VIC_LIGHT_GRAY,VIC_MED_GRAY,VIC_DARK_GRAY,VIC_MED_GRAY,VIC_LIGHT_GRAY
theme_color_blues:
	byte VIC_BLUE,VIC_LIGHT_BLUE,VIC_CYAN,VIC_WHITE
; 6 flashing chat page colors
	byte VIC_WHITE,VIC_CYAN,VIC_LIGHT_GREEN,VIC_LIGHT_BLUE,VIC_LIGHT_GREEN,VIC_CYAN
!theme_color_monochrome:
	byte VIC_GREEN,VIC_LIGHT_GREEN,VIC_GREEN,VIC_LIGHT_GREEN
; 6 chat page colors:
	byte VIC_WHITE,VIC_LIGHT_GREEN,VIC_GREEN,VIC_GREEN,VIC_LIGHT_GREEN,VIC_WHITE
!theme_color_user_defined:
	area VIC_BLACK,10
!theme_string_table:
	word theme_string_grays, theme_string_blues, theme_string_monochrome, theme_string_user_defined
!theme_string_grays:
	ascii "Gray & White{0}"
theme_string_blues:
	ascii "The Blues   {0}"
!theme_string_monochrome:
	ascii "Monochrome  {0}"
!theme_string_user_defined:
	ascii "User-Defined{0}"

screen_mask_color_1_4:
; area <size>[, <fill>]

; fill parameter is offset into theme_color_table:
; 0=mask_dark, 1=mask_light,
; 2=lightbar_background, 3=lightbar_highlight

; row 1:
	area 04,01
	area 23,00
	area 04,01
	area 09,00
; row 2:
	area 04,01
	area 23,00
	area 04,01
	area 09,00
; row 3:
	area 04,01
	area 23,00
	area 04,01
	area 09,00
; row 4:
	area 04,01
	area 23,00
	area 04,01
	area 09,00
screen_mask_color_5_8:
; row 5:
	area 04,01
	area 23,00
	area 04,01
	area 09,00
; row 6-8:
	area 40,03
	area 40,03
	area 40,03

irq4:
; handle lightbar f-keys

; in VICE:
; host OS   C=     host OS   C=
; -------   --     -------   --
;       f1: f1           f3: f5
; Shift+f1: f2     Shift+f3: f6
;       f2: f3           f4: f7
; Shift+f2: f4     Shift+f4: f8

	lda lstx	; c64: 197. last key pressed
	cmp oldkey
	beq irq4c
	sta oldkey
	cmp #HELP_KEY
	beq helpkey
	cmp #F7_KEY	; 3
	bcc irq4c
	cmp #7
	bcs irq4c
	and #3
	asl
	sta tmpkey
	lda shflag		; c64: 653 C=, Ctrl, Shift hit?
	cmp #COMMODORE_KEY	; 2
	bcs irq4d
	and #1
	sta shfkey
	ora tmpkey
	asl
	tay
	jsr irq4b
	sta irq4a+1
	iny
	jsr irq4b
	sta irq4a+2
irq4a:
; self modifying code:
	jmp $ffff
irq4b:
; target of self-modifying code
	lda ktbl1,y
irq4c:
	rts
irq4d:
	jmp fkey

helpkey:
	lda helpmode
	eor #$01	; toggle value
	sta helpmode
	sta 1024
	rts

helpmode:
; $00: not in lightbar help mode
; $01: in lightbar help mode
	byte $00

tmpkey:
	byte 0
oldkey:
	byte 64
shfkey:
	byte 0

ktbl1:
	word t1fk1,t1fk2
	word t1fk3,t1fk4
	word t1fk5,t1fk6
	word t1fk7,t1fk7

t1init:
	ldy #0
	jsr chkflags
	ldx #<ktbl1
	ldy #>ktbl1
usekey:
	stx irq4b+1
	sty irq4b+2
	rts
t1fk1:
	ldx scnlock
	bne t1fk3b
	ldx scnmode
	jmp setmode1
t1fk2:
	lda blnkflag
	bne t1fk2a
	jmp scrnoff
t1fk2a:
	jmp scrnon
t1fk3:
	dec bar
t1fk3a:
	inc irq7+1
t1fk3b:
	rts
t1fk4:
	sec
	lda bar
	sbc #8
t1fk4a:
	sta bar
	jmp t1fk3a
t1fk5:
	inc bar
	jmp t1fk3a
t1fk6:
	clc
	lda bar
	adc #8
	jmp t1fk4a
t1fk7:
	lda bar
	asl
	ora shfkey
	pha
	tax
	ldy #2
	jsr chkflags
	pla
	cmp #2
	beq t1fk7a
	cmp #6
	beq t1fk7b
	cmp #12
	beq t1fk7c
	rts
t1fk7a:
	jmp t3init ;acs
t1fk7b:
	jmp t2init ;tsr
t1fk7c:
	lda outptr6+1
	eor #1
	sta outptr6+1
	rts

; placeholder code:
t2init:
t3init:
fkey:
setmode1:
	jmp main_loop
scrnoff:
	jmp main_loop
scrnon:
	jmp main_loop

outptr6:
	word $ffff

;* display lightbar checkmarks
irq7:
; self modifying code changes this
	ldy #1
	lda bar
	and #63
	sta bar
	cpy #0
	beq irq7z
	lda scnmode
	bne irq7z
	lda #0
	sta irq7+1
	lda tmpbar
	pha
	lda bar
	and #7
	sta tmpbar
	asl
	asl
	adc tmpbar
	sta tmpbar
	lda bar
	and #$38
	sta irq7a+1
	asl
	clc

irq7a:
; self modifying code changes this
	adc #0
	tay
	lda bar
	lsr
	lsr
	lsr
	asl
	tax
	lda chktbl+1,x
	pha
	lda chktbl+0,x
	ldx #0
irq7b:
	jsr irq7h
	cpx #20
	bcc irq7b
	pla
irq7c:
	jsr irq7h
	cpx #40
	bcc irq7c
	pla
	sta tmpbar
irq7z:
	rts

; display either a space or a checkmark for a lightbar flag

irq7d:
	lsr
	pha
	lda #' '
	bcc irq7e
	lda #$7a	; using '#checkmark' breaks output
irq7e:
	jsr irq7f
	pla
	rts

irq7j:
	lda bartbl,y
	iny

; write a single character to the on-screen lightbar

irq7f:
	ora #$80
	sta lightbar_text_addr,x
irq7g:
; self-modifying code changes this
	lda #15
	sta lightbar_color_addr,x
	inx
	rts

irq7h:
	pha
; set the background color for this lightbar position
mod_lightbar_background:
	lda #VIC_LIGHT_GRAY	; 15
	cpx tmpbar
	bne irq7i
; otherwise, set highlight color:
mod_lightbar_highlight:
	lda #VIC_WHITE		; 1
irq7i:
	sta irq7g+1
	pla
	jsr irq7d
	pha
	jsr irq7j
	jsr irq7j
	jsr irq7j
	pla
	jmp irq7d

chkflag:
	ldy #5
chkflags:
	lda $ff
	pha
	stx $ff
	txa
	and #7
	tax
	lda bits,x
	pha
	lda $ff
	lsr
	lsr
	lsr
	and #$0f
	tax
	pla

; at this point:
; A = bit mask
; X = index into the flag bytes
; Y = function number

	iny
	dey
	beq chkflag0
	dey
	beq chkflag1
	dey
	beq chkflag2
	dey
	beq chkflag3
	dey
	beq chkflag4
	dey
	beq chkflag5
chkflag6:
	sta chktbl,x
chkflag7:
	inc irq7+1
chkflag8:
	tax
	pla
	sta $ff
	txa
	rts

; clear a flag

chkflag0:
	eor #$ff
	and chktbl,x
	jmp chkflag6

; set a flag

chkflag1:
	ora chktbl,x
	jmp chkflag6

; toggle a flag

chkflag2:
	eor chktbl,x
	jmp chkflag6

; read a flag (basic, result in a%)

chkflag3:
	ldy #0
	sty varbuf
	and chktbl,x
	beq chkflg3a
	iny
chkflg3a:
	sty varbuf+1
	ldx #var_a_integer
	jsr putvar
	jmp chkflag8

; set selected position

chkflag4:
	lda $ff
	sta bar
	jmp chkflag7

; read a flag (ml), result in accumulator

chkflag5:
	and chktbl,x
	jmp chkflag8

; display time
clock:
	ldy #$00 ; index

	lda tod_hrs	; tens digit
	pha
	and #$10
	jsr bcd_to_ascii_tens_digit+2
	pla
	jsr bcd_to_ascii_ones_digit

	lda #$ba	; reversed ':'
	jsr clock_display

	lda tod_min	; tens digit
	pha
	jsr bcd_to_ascii_tens_digit
	pla
	jsr bcd_to_ascii_ones_digit

	lda #$ba	; reversed ':'
	jsr clock_display

	lda tod_secs	; tens digit
	pha
	jsr bcd_to_ascii_tens_digit
	pla
	jsr bcd_to_ascii_ones_digit

	lda tod_tenths	; read to keep clock running
	rts

bcd_to_ascii_tens_digit:
	and #$f0
	lsr
	lsr
	lsr
	lsr
	jmp clock_display

bcd_to_ascii_ones_digit:
	and #$0f

clock_display:
	ora #$b0	; %1011 0000
	sta $0400+(40*24)+18,y
	iny
	rts

settim:
; enter with:
; .x: hour    (01-12, 81-92=PM)
; .y: minute  (00-59)
	lda #$01
	byte $2c
setalm:
	lda #$81
	sta ciacrb
	cmp #$81
	beq settim2
	lda #1
	sta timeflag
	cpx #12
	bne settim1
	ldx #92
	bne settim2
settim1:
	cpx #92
	bne settim2
	ldx #12
settim2:
	txa
	jsr settim3
	sta tod_hrs
	tya
	jsr settim3
	sta tod_min
	lda #0
	sta tod_secs
	sta tod_tenths
	lda #$01
	sta ciacrb
	rts
settim3:
	ldx #0
settim4:
	cmp #10
	bcc settim5
	sbc #10
	inx
	bne settim4
settim5:
	sta $ff
	txa
	asl
	asl
	asl
	asl
	ora $ff
	rts

; variables & memory locations referenced by code:
timeflag:
	byte $ff

tmpbar:
	byte 0
bar:
; position of lightbar highlight?
	byte 4

lightbar_char_index:
; position in the lightbar being drawn
	byte $00

lightbar_label_index:
; which label (0-7) we're drawing on the page:
	byte $00

; screen stuff:
scnmode:
; $01: don't display screen mask
; $00: display
	byte $00

scnlock:
; $00: ignore f1 keypresses, never display screen mask
	byte $00

blnkflag:
; $00: don't blank screen?
	byte $00

putvar:
	rts

varbuf:
	area 7,$00

instructions_1_4:
{'alpha:PokeAlt}
;              ====+====+====+====+====+====+====+====+
	ascii "Welcome to the concept preview of the   "
	ascii "Image 128 BBS lightbar and screen mask. "
	ascii "Use the following keys to manipulate the"
	ascii "lightbar:                               "
instructions_5_8:
	ascii "                                        "
	ascii "f1: not implemented f2: toggle fast/slow"
	ascii "f3: highlight left  f4: previous page   "
	ascii "f5: highlight right f6: next page       "

instructions_9_12:
	ascii "f7: toggle left {186}   f8: toggle right {186}  "
	ascii "                                        "
	ascii "This build is dated ",{usedef:__BuildDate}," ",{usedef:__BuildTime}
	ascii "Build ID: ",{usedef:__BuildRID64},"   Stop exits."

mask_text_buf:
	area (4 * VIC_SCREEN_WIDTH),$00

mask_color_buf:
	area (4 * VIC_SCREEN_WIDTH),$00
