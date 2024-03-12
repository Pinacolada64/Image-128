; rationale for changing lightbar:
; 1) options are scattered all over, some check mark slots are unused
; 2) some options are disabled by checking them; others are enabled by checking them.
;    this is inconsistent behavior
; 2049
orig $0801

; basic sys line
; 2049-2050 line link:
	word end_of_line
; 2051-2052 line number:
	word 10
;  2053     'sys' token:
	byte $9e
; 2054-2057 address:
	ascii "2061"
end_of_line:
; 2058      zero byte
	byte $00
; 2059-2060 end of program:
	word $0000

strout	= $ab1e
chrout	= $ffd2
check_stop_key	= $ffe1	; .z=1 if stop hit

color_ram = $d800

lightbar_row = color_ram + 40 * 20

draw_lightbar0:
	lda lightbar_row
	sta draw_lightbar1+1
	lda lightbar_row
	sta draw_lightbar1+2

	ldy #$00

get_checktbl:
; get checkmark status
	lda chktbl,y
	rol

; set color
draw_lightbar1:
	sta $ffff,y

lightbar_page:
	byte $00
lightbar_position:
	byte $04

lightbar_index:
; mybe just adc/sbc 8*3
	byte <page0,<page1,<page2,<page3,<page4
	byte >page0,>page1,>page2,>page3,>page4
{alpha:poke}
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
; Asc: ASCII translation; LF after CR
; Ans: ANSI color enable; ANSI graphics enable
; Mac: enable main prompt "macros"; FIXME
; Mnu: Graphic menu options
; x Mor  : More Prompt Enabled
;   Mor x: More Prompt Ignored FIXME
; x Xpr  : Xpress logon options
;   Xpr x: Use 's.detect' fles
page3:
; sysop-set BBS options:
	ascii "ChkFrdMacMnuNewSecSubUnv"
; x Chk  : Mail check at logon
;   Chk x: Excessive chat request logoff
; x Frd  : don't display color [keep as homage to Fred Dart]
;   Frd x: undefined
; Mac: display main menu macros FIXME
; x Mnu  : Is User in Menu Mode?
;   Mnu  : Are Menus Available on BBS?
; New: block NEW users; screen blanking
; Sec: logon security check questions
; Sub: U/Ds or GF section closed
; Unv: Unvalidated files don't earn credit; auto-logoff
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
;   Scn x: 80 columns?
; x Prt  : Print all text to printer
;   Prt x: Print log entries to printer
; x RTC  : RTC
; x CMD  : CMD HD
;   CMD x: poll CMD RTC & reset BBS clock
; x LtK  : Lt. Kernal HD connected
;   LtK x: Multiplexer connected

;   LtK  : Lt Kernal HD
page5:
; modem options
	ascii "$40$42$44$46$48$4a$4c$4e"
;	ascii "MdmMntDCDDSRMnt"
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

