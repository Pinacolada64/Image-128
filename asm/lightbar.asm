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
checkmark	= 186

; TODO: Add VDC colors

strout		= $ab1e
chrout		= $ffd2
check_stop_key	= $ffe1	; .z=1 if stop hit

text_ram	= $0400
color_ram	= $d800

VIC_SCREEN_WIDTH = 40 ; 0-indexed, so is 0-39 (40)

lightbar_text		= text_ram  + (VIC_SCREEN_WIDTH * 16)
lightbar_color		= color_ram + (VIC_SCREEN_WIDTH * 16)
screen_mask_text_base	= text_ram  + (VIC_SCREEN_WIDTH * 17)
screen_mask_color_base	= color_ram + (VIC_SCREEN_WIDTH * 17)

setup:
	lda #'{clear}'
	jsr chrout
	lda #VIC_BLACK
	sta $d020
	sta $d021

; copy screen mask data/color to screen
	ldy #0; TODO: eventually #200 for 5 equal chunks
copy_loop:
	lda fake_lightbar_data,y
; eor bit 7 to reverse char
	eor #%10000000
	sta lightbar_text,y
	lda #VIC_LIGHT_GRAY
	sta lightbar_color,y

	lda screen_mask_data,y
; eor bit 7 to reverse char
	eor #%10000000
	sta screen_mask_text_base,y
	lda screen_mask_color,y
	sta screen_mask_color_base,y

	iny
	cpy #VIC_SCREEN_WIDTH
	bne copy_loop
	rts

draw_lightbar0:
	lda lightbar_text
	sta draw_lightbar1+1
	lda lightbar_text+1
	sta draw_lightbar1+2

	ldy #$00

get_checktbl:
; get checkmark status
	lda chktbl,y
	rol

; set color
draw_lightbar1:
	sta $ffff,y

keyboard_handler:
; TODO: read HELP key
; if hit, save contents of 16 character window.
; put "Lightbar Help" in programmable 16-char window.
; copy 5 screen mask lines color/text data somewhere.
; save arrray pointers (use level 5, or the highest value).
; load tt$() from s.lightbar.
; display help text in screen mask area somehow. two lines at least, 1 for each checkmark option.

	rts

lightbar_page:
	byte $00
lightbar_position:
	byte $04

lightbar_index:
; maybe just adc/sbc 8*3
	byte <page0,<page1,<page2,<page3,<page4
	byte >page0,>page1,>page2,>page3,>page4
{alpha:PokeAlt}
page0:
	ascii "SysAcsLocTsrChtNewPrtU/D"
; alphabetical (mostly), each page a broad category:
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
fake_lightbar_data:
	ascii " Sys  Acs ",checkmark,"Loc",checkmark," Tsr  Cht  New  Prt  U/D "
screen_mask_data:
; 0
	ascii "User Pinacolada{space:12}ID # DE1{space:5}"
; 40
	ascii "Last Mar 26, 2024  5:33 PM Call 1/48{space:4}"
; 80
	ascii "Name Ryan Sherwood{space:9}Prms 40x25{space:3}"
; 120
	ascii "Mail sym.rsherwood@gmail.co Baud Console{space:2}"
; 160
	ascii "Area{space:22}User{space:9}"
; 200
;                                      |<- msg area ->|
	ascii "C=00004 N=001 I=000 A=9 Screen Mask Test"
; 240
	ascii "R{space:10} M=18064  L=03006 {space:10}T"
; 280
	ascii checkmark,"Wed Mar 27, 2024 11:18 AM{space:5}"
; 320
{alpha:alt}

screen_mask_color:
; area <size>[, <fill>]
; row 1:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 10,VIC_MED_GRAY
; row 2:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 10,VIC_MED_GRAY
; row 3:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 10,VIC_MED_GRAY
; row 4:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 10,VIC_MED_GRAY
; row 5:
	area 04,VIC_LIGHT_GRAY
	area 23,VIC_MED_GRAY
	area 04,VIC_LIGHT_GRAY
	area 10,VIC_MED_GRAY
; rows 6-7:
	area 24,VIC_WHITE
	area 16,VIC_YELLOW
; row 8
	area 40,VIC_WHITE
