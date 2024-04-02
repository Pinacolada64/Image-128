; rationale for changing lightbar:
; 1) options are scattered all over, some check mark slots are unused
; 2) some options are disabled by checking them; others are enabled by checking them.
;    this is inconsistent behavior
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

; screen code printables:
checkmark	= 122

; TODO: Add VDC colors

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

setup:
	lda #'{clear}'
	jsr chrout
	lda #'{lowercase}'
	jsr chrout
	lda #VIC_BLACK
	sta $d020
	sta $d021

; copy screen mask data/color to screen
	ldy #0
copy_loop:
	lda screen_mask_data,y
; eor bit 7 to reverse char
	eor #%10000000
	sta screen_mask_text_addr,y
	lda screen_mask_color,y
	sta screen_mask_color_addr,y

	iny
	; TODO: eventually #200 for 5 equal chunks
	cpy #VIC_SCREEN_WIDTH * 6
	bne copy_loop

; print 8 lightbar pages
; 1) reset lightbar_label_index (which position, 0-7, we're drawing in the lightbar page)
;    reset lightbar_char_index (which character in the lightbar line we're drawing)
	lda #00
	sta lightbar_label_index
	sta lightbar_char_index
; 2) calculate which page we're on
	clc
	ldy #lightbar_page
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

{alpha:PokeAlt}
page0:
	ascii "SysAcsLocTsrChtNewPrtU/D"
; alphabetical within page (mostly), each page a broad category:
; common BBS options:
;	ascii "AcsChtLocResSysTsr"
; x Sys  : Sysop available to chat
; x Cht  : Enter/exit chat mode
;   Cht x: Background chat page enable

; x U/D  : 300 Baud U/D Lockout
;   U/D x: Disable U/D Section
page1:
; console options:
	ascii "AscAnsExpUnvTrcBelNetMac"
;	ascii "AscAnsBelDbgIdlMorTrc"
; x Dbg  : check to display more info in modules during debugging process
;   Idl  : was "Alt"
; x Idl  : use color scheme 1/2 for last ten callers
; x Trc  : Trace BASIC line numbers
page2:
; caller options:
	ascii "ChkMorFrdSubResMdmMnuXpr"
;	ascii "AscAnsMacMnuXpr"
;   Asc  : ASCII translation; LF after CR
;   Ans  : ANSI color enable; ANSI graphics enable
; x Mac  : enable main prompt "macros"
;   Mac x: Enable mci in editor
; Mnu: Graphic menu options
; x Mor  : More Prompt Enabled
;   Mor x: More Prompt Ignored FIXME
; x Xpr  : Xpress logon options
page3:
; sysop-set user-facing BBS options:
	ascii "ChkFrdMacMnuNewSecSubUnv"
; x Chk  : Mail check at logon
;   Chk x: Excessive chat request logoff
; x Frd  : don't display color [keep as homage to Fred Dart]
;   Frd x: undefined: FIXME: forwarding something?
; x Mac  : display main menu macros FIXME
; x Mnu  : Is User in Menu Mode?
;   Mnu  : Are Menus Available on BBS?
; x New  : NEW users allowed
; x Lgn  : Second security check question
;   Lgn x: Display 's.detect' files
;   Sub  : U/Ds or GF section closed
; x Unv  : Unvalidated files earn credit; auto-logoff
; unassigned:
; disallow double calls
page4:
; hardware options:
	ascii "1.xSecMHzAltDbgDCDDSR$3e"
;	ascii "CPUmHzScnPrtRTCCMDLtK"
; x CPU  : SuperCPU present
;   CPU x: SuperCPU at 20 mHz
; x Scn  : Screen blanking enabled
;   Scn  : 40 columns?
;   Scn x: 80 columns? maybe 40/80 key instead
; x Prt  : Print all text to printer
;   Prt x: Print log entries to printer
; x RTC  : RTC
;   RTC x: Periodic RTC poll to sync time
; x CMD  : CMD HD
;   CMD x: poll CMD RTC & reset BBS clock
; x LtK  : Lt. Kernal HD connected
;   LtK x: Multiplexer connected

page5:
; modem options
	ascii "$40$42$44$46$48$4a$4c$4e"
;	ascii "MdmMntDCDDSR"
;   Trc x: Poll CMD real-time clock
; x Mdm  : Enable modem input
; x Mnt  : Zero tr% at Hit Backspace
;   Mnt  : Modem Answer Disabled

help_text:
; built-in help text if s.lightbar file missing:
; Sys:
	ascii "Sysop available for chat{0}"
; CHANGE: move to right Cht
	ascii "Background page enable{0}"
; Acs:
	ascii "Edit user's access{0}"
	ascii "Block 300 BPS callers{0}"
; Loc:
	ascii "Local mode (no modem I/O){0}"
	ascii "ZZ (pseudo-local) mode{0}"
; Tsr:
	ascii "Edit user’s time left{0}"
	ascii "Toggle Prime Time{0}"
; Cht:
	ascii "Enter or exit chat mode{0}"
; CHANGE: move elsewhere
	ascii "Disable modem input{0}"
; New:
	ascii "Disallow new users{0}"
	ascii "Enable Screen Blanking{0}"
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
	ascii "{0}"
	ascii "{0}"
; Bel:
	ascii "{0}"
	ascii "{0}"
; Net:
	ascii "{0}"
	ascii "{0}"
; Mac:
	ascii "{0}"
	ascii "{0}"
; Chk:
	ascii "{0}"
	ascii "{0}"
; Mor:
	ascii "{0}"
	ascii "{0}"
; Frd:
	ascii "{0}"
; right: forwarding something
	ascii "{0}"
; Sub:
	ascii "{0}"
	ascii "{0}"
; Res:
	ascii "{0}"
	ascii "{0}"
; Mdm:
	ascii "{0}"
	ascii "{0}"
; Mnu:
	ascii "{0}"
	ascii "{0}"
; Xpr:
	ascii "{0}"
	ascii "{0}"
{alpha:alt}

chktbl:
; each 1 bit represents a check mark in the lightbar
; 16 bits per page
; page 1:
	byte %01010101,%10101010
; page 2:
	byte %10101010,%01010101
; page 3:
	byte %01010101,%10101010
; page 4:
	byte %10101010,%01010101
; page 5:
	byte %01010101,%10101010

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
{alpha:PokeAlt}
screen_mask_data:
; 0
	ascii "User Pinacolada            ID # DE1     "
; 40
	ascii "Last Mar 26, 2024  5:33 PM Call 1/48    "
; 80
	ascii "Name Ryan Sherwood         Prms 40x25   "
; 120
	ascii "Mail sym.rsherwood@gmail.c Baud Console "
; 160
	ascii "Area Lightbar Mock-Up      User 2/2     "
; 200
;                                      |<- msg area ->|
	ascii "C=00004 N=001 I=000 A=9 Screen Mask Test"
; 240
	ascii "R{right:10} M=18064  L=03006 {right:10}T"
; 280
	ascii checkmark,"Wed Mar 27, 2024 11:18 AM{space:5}"
; 320
{alpha:alt}

theme_table:
; format: mask_dark, mask_light, lightbar_highlight, theme_name{0}
	byte VIC_DARK_GRAY,VIC_MED_GRAY,VIC_WHITE
	ascii "Standard Gray{0}"

screen_mask_color:
; area <size>[, <fill>]
; row 1:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 09,VIC_MED_GRAY
; row 2:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 09,VIC_MED_GRAY
; row 3:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 09,VIC_MED_GRAY
; row 4:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 09,VIC_MED_GRAY
; row 5:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 09,VIC_MED_GRAY
; rows 6-7:
	area 24,VIC_WHITE
	area 16,VIC_YELLOW
; row 8
	area 40,VIC_WHITE
lightbar_char_index:
; position in the lightbar being drawn
	byte $00

lightbar_label_index:
; which label (0-7) we're drawing on the page:
	byte $00

