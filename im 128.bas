#RetroDevStudio.MetaData.BASIC:7169,BASIC V7.0,lowercase,10,10
# COMMENTS BEGIN WITH OCTOTHORPE
0 ON PEEK(829) GOTO 3000,4000:GOTO 300
1 GOSUB10:&,22,1:GOTO10
2 DV%(.)=D1%:DR%(.)=D2%:DV%=DV%(DR):DR$=MID$(STR$(DR%(DR)),2)+":":D3%=DR%(DR):RETURN
3 CLOSE15:GOSUB2:OPEN15,DV%,15:RETURN
4 CLOSE2:GOSUB3:OPEN2,DV%,2,DR$+A$
5 INPUT#15,E%,E$,T%,S%:A$="TATUS:£#2£%E:£$E:£%T:£%S":RETURN
6 AN$=UU$:ON-(AN$<>"")GOSUB310:ON-(AN$<>"")GOTO314:PL=1:&,1:GOTO310
7 &"£G1":A$=AN$:RETURN
# I TAKE IT PEEK(17138) <C64 SCREEN MASK MODE> IS CHECKED WITHIN &,69
# THEREFORE ELIMINATING IT HERE:
9 IF NT=. THEN:&,69,4,21,LEFT$(" "+CM$+"               ",22),$8C:RETURN:ELSE RETURN
# REM PRINT#15,"P"CHR$(XAND255)CHR$(X/256)"":RETURN
10 RECORD#X:RETURN
11 A=VAL(MID$(FL$,A,1)):RETURN
12 POKE53253,0:POKE2024,.:POKE2031,.:POKE53260,.:&"£U0£Q"+CHR$(DF%+48):RETURN
13 &""
14 A$=A$+",S,R":GOSUB4:IFE%=.THEN:&,3,2
15 CLOSE2:RETURN
16 GOSUB1:INPUT#2,ST(X):ST(X)=ST(X)+I
17 GOSUB1:PRINT#2,ST(X):RETURN
18 GOSUB19:A$=A$+",S,W":GOTO4
19 GOSUB3:PRINT#15,"S"DR$A$:RETURN
# "SCRATCH(DR$+A$) ON U DR%(DR)" DOESN'T SEEM TO WORK IN BASIC 7.0
28 CM$=A$:GOSUB9:DR=5:GOSUB3:IF"++ "+A$=ML$THENE%=.:RETURN
29 ML$="++ "+A$:A$=DR$+ML$:&,7,DV%,2:GOTO5
30 DR=3:A$="E.STATS":GOTO4
31 DR=3:A$="E.ACCESS":GOTO4
32 DR=2:A$="M."+LEFT$(TT$,13)+",S,"+A$:GOTO4
33 DR=3:A$="E.DATA":GOTO4
34 E%=A%:&,52,46,3:AM=A%:A%=E%:DR=3:A$="E.LOG"+LEFT$(LT$,AM)+",S,"+A$:GOTO4
35 DR=6:A$="U.CONFIG":GOTO4
36 DR=3:A$="E."+B$+",S,"+A$:GOTO4
37 A$="A":GOSUB36:IFE%THENA$="W":GOSUB36
38 PRINT#2,NA$R$ID;R$D1$R$AC%R$PH$R$RN$R$CO$:RETURN
39 &,14,2,KK-1:PRINT#2,"^":CLOSE2:GOTO62
40 A$="NEW USER":GOTO42
41 A$="CONFIG"
42 A$="S."+A$:DR=1:GOTO13
43 DR=3:A$="E.SAY":GOSUB4:ONSGN(E%)GOTO46:X=1:GOSUB1:INPUT#2,X
44 A=RND(-TI):X=INT(RND(1)*X)+2:GOSUB1
45 INPUT#2,B$,C$,D$,F$:GOSUB90:LP=1:&"£$Q £$B£$Q £$C£$Q £$D£$Q £$F£Q0"
46 CLOSE2:RETURN
50 IFI%THENRETURN
51 C$=A$:A$="A":GOSUB34:IFE%=.THENPRINT#2,C$
52 CLOSE2:A$=C$:AN$=C$:A=A%:&,52,13,3:B=A%:A%=A:IFB=.THENRETURN
53 OPEN16,4,15:CLOSE16:IFSTTHENRETURN
54 PRINT#4,A$:RETURN
60 A$=",U,W":GOSUB4:CLOSE2:PRINT#15,"S"DR$"":A=-SGN(E%):RETURN
61 IFDR<7THENIFBF(DR)>-1THENGOSUB2:A=BF(DR):BF=A:RETURN
62 GOSUB3:IFDV%<>LK%THEN64:ELSEA$=DR$:IFDR$="10:"THENA$="A"
63 A=2:PRINT#15,"LG"LEFT$(A$,1):INPUT#15,E%,A$,A$,A$,A$,A$:GOTO65
64 A=1:CLOSE2:OPEN2,DV%,0,"$"+DR$+"":GET#2,A$,A$:&,8,2,1:&,8,2,1:CLOSE2
65 A=VAL(A$)*A:BF=A:FORA=1TO6:IFDV%(A)=DV%ANDDR%(A)=VAL(DR$)THENBF(A)=BF
66 NEXT:A=BF:RETURN
70 DR=5
71 IFPR$<>"I."+A$THENGOSUB76:ELSEGOTO3000
72 DR=5
73 IFP1$<>"I/"+A$THENGOSUB77:ELSEGOTO4000
74 IFA$<>"MODEM"THEN100:ELSEDR=5:IFP2$<>"SUB."+A$GOSUB78:ELSEIS=IS+1:IM$(IS)=P2$
75 GOSUB60000:IS=IS-1:IFIS<1THENRETURN:ELSEA$=MID$(IM$(IS),5):GOTO78
76 A$="I."+A$:PR$=A$+"":P1$="":P2$="":NEW3000:GOTO79
77 A$="I/"+A$:P1$=A$+"":P2$="":NEW4000:GOTO79
78 A$="SUB."+A$:P2$=A$+"":NEW60000
79 CM$=A$:GOSUB9:GOSUB2:LOADDR$+A$,DV%:RETURN
80 A$=Z$:Z$=MID$(P1$,3):GOSUB72:A$=Z$:DR=5:IFLC<>1THEN77:ELSERETURN
82 FORI=1TO4:&,11,I:NEXT
83 &,11,.:RETURN
84 A=INT(MN%/60):PT%=-(A>=P2%ANDA<P3%)*SGN(P1%):RETURN
85 &"OULD OU IKE O EAVE EEDBACK? ":GOSUB96:IFA=.THENRETURN:ELSEDR=3:GOSUB61
86 X=2:IF BF<35 THEN 390:ELSE IM=1:GOTO444
90 Q$="":IFLL%>42THENFORR=1TOINT((LL%-42)/2):Q$=Q$+" ":NEXT
91 RETURN:REM ELSE WON'T HELP ABOVE
92 &">>ANCELED!":RETURN
93 GOSUB98
94 &"[O]":GOSUB7:&"£H4":A=-(A$=""):GOTO97
95 GOSUB98
96 &"[ES]":GOSUB7:&"£H5":A=(A$="")+1
97 &"£Q"+CHR$(DF%+48)+MID$("ESO",4-A*3,3)+"":RETURN
98 &"RE OU URE?: ":RETURN
100 P2$="SUB."+A$:GOSUB110:IS=IS+1:IM$(IS)=IM$
102 GOSUB60000:NEW60000:IS=IS-1:IFISTHENA$=IM$(IS):P2$="SUB."+A$:GOSUB110
104 RETURN
110 DR=5:GOSUB2:IM$=A$:CM$="SUB."+A$:GOSUB9:A$=DR$+"SUB."+A$:LOADA$,DV%
112 RETURN
200 ONTR%+1GOTO240:&,52,17,LF:&,52,20,EM:POKE951,LL%:POKE971,MP%:POKE970,0
202 &,52,30,3:ONA%GOSUB330
204 S=.:SH=.:GOSUB12
206 POKE970,0:&,52,30,3:AN$=D1$:&,15:B$=RIGHT$(AN$,7)
208 MM=2:GOSUB3000:GOSUB9:&" - £$B£Q0":IFTR%<100THENA%=TR%:&" - £%A IN EFT£Q0"
209 IFZZTHENA%=USR(0):&" - TACK REE: £%A£Q0"
210 &"":POKE53252,38:GOSUB6
212 CM$=LEFT$(P$,11)+":"+LEFT$(AN$,4):GOSUB9:CM$=P$
214 ONTR%+1GOTO240:IFAN$=""THENGOSUB250:GOTO200
216 GOSUB220:IFF4THENGOSUB304:ON-(F4=1.1)-2*(F4=1.2)-3*(F4=1.3)GOTO270,268,234
218 ONRSGOTO200:MM=1:GOTO3000
220 ON-(AC%<>AO%)GOSUB320:AN$=AN$+"":RS=1:A$=LEFT$(AN$,1):Z$=LEFT$(AN$,2)
222 &,52,20,3:EM=A%:&,52,5,3:ZZ=A%
224 X=1:RQ=.:RS=1
226 F4=.:A%=ZZ:B%=2^AC%:&,42:IFA%THENEF$=B$:EP$=A$:EC=A%:EC%=B%:GOTO260
228 ON-(A$=""OR(LC=1ANDA$=""))-2*(A$="")GOTO230,250:RS=.:RETURN
230 F4=.:IFRIGHT$(AN$,1)<>"!"THEN:&"OGOFF?: ":GOSUB96:IFA=.THENRETURN
232 F4=1.3:RETURN
234 F1=1-(RIGHT$(AN$,1)="!"):CD%=.:IFMID$(Z$,2,1)="%"THEN302
236 &"PDATE ESSAGE/ILE CAN ATE?: ":GOSUB96:IFATHENLD$=LT$:ELSEGOTO302
240 &"ORRY, IME IMIT XCEEDED.":MM=3:GOSUB3000:F1=1:GOTO302
242 F1=.:&" BORTED!":GOTO200
250 IM=1:GOTO436
260 IF EC%>. AND CR-EC%<. THEN:&"OT NOUGH REDITS!":RETURN
262 CR=CR-EC%:IF EP$="" OR ID=1 THEN 264
263 &"ASSWORD:":&,6:IFAN$<>EP$THEN:&"NCORRECT ASSWORD.":RETURN
264 F4=.:ONECGOTO265,266,267,268:RETURN
265 Z$=EF$:F4=1.1:&,28,1:RETURN
266 F4=1.2:&,28,1:RETURN
267 Z$=EF$:GOTO80
268 A%=ASC(EF$+NL$)+256*ASC(MID$(EF$,2,1)+NL$):&,42,1
270 MM=.:A$=Z$:GOTO70
280 A%=ZZ:B%=2^AC%:&,42:IFA%THENEF$=B$:EP$=A$:EC=A%:EC%=B%:GOTO264
282 RETURN
288 RETURN
289 &"£I0":IFAN$=""THENRETURN
290 &,15,2:RETURN
# LEAVE THESE TWO LINES UNTOUCHED: CONTINUE AFTER
300 &,28,1:&,52,$30,3:ONA%GOSUB309:MM=.:A$="MAIN":GOTO70
302 &,28,1:&,52,$30,3:ONA%GOSUB309:MM=.:A$="LO":GOTO70
304 &,28,1:GOSUB306:&,27:RETURN
306 DIMBB$(31),DT$(61),ED$(61),NN$(61)
308 DIMA%(61),C%(61),D%(61),E%(31),F%(61),AC%(31),SO%(31):RETURN
309 CM$="1.3 MULATOR":GOSUB9:DR=5:GOSUB3:LOADDR$+"IM.EMUL13",DV%:GOTO304
310 PU$=AN$:IFAN$=""THEN315
311 IFLEFT$(AN$,1)=""THENAN$=HS$(10-VAL(MID$(AN$,2,1))):GOTO314
312 &,15,6,140:UU$=AN$:AN$=A$
313 FORCT=1TO9:HS$(CT)=HS$(CT+1):NEXT:HS$(10)=AN$:RETURN
314 &P$+": £V7":RETURN
315 FORCT=1TO10:A%=10-CT:A$=HS$(CT):&"£%A: £$A":NEXT:AN$="":UU$="":RETURN
320 GOSUB31:X=AC%+1:GOSUB1:&,2,2:AG$=A$:&,2,2:CLOSE2
321 IFLEN(FL$)<LEN(A$)THENFL$=FL$+MID$(A$,LEN(FL$)+1)
322 IFLEN(FL$)>LEN(A$)THENFL$=A$
323 IFAC%<>AO%THENFL$=A$:AO%=AC%
324 A=6:GOSUB11:LE=(A+1)*10:A=16:GOSUB11:POKE830,A:A=20:GOSUB11:DA%=A
325 RETURN
330 DR=3:A$="E.MACROS":GOSUB4
332 IFE%=.THEN:&,2,2:A=VAL(A$):&"":X=INT(RND(1)*A)+2:GOSUB1:&,3,2
334 CLOSE2:RETURN
349 &"EVICE, RIVE: £I1":AN$="  "+AN$:RETURN
350 A=INT(VAL(MID$(AN$,3,2))):IFA>.THENIFA<7THENDR=A:GOTO353
351 IFA<7ORA>29THENA=8
352 &,15,6,133:D2%=VAL(AN$):D1%=A:DR=.:DV%(.)=D1%:DR%(.)=D2%
353 GOSUB3:CLOSE15:A=-(ST<>.):RETURN
370 A=1-A:&"£$B ODE: "+MID$("FFN",A*2+1,2)+"":RETURN
371 A=VAL(MID$(UF$,B,1)):GOSUB370:UF$=LEFT$(UF$,B-1)+CHR$(A+48)+MID$(UF$,B+1):RETURN
372 A=EM:B$="XPERT":GOSUB370:EM=A:&,52,20,EM:RETURN
373 IM=3:GOTO430
374 B=3:B$="RAPHIC ENU":GOSUB371:&,52,44,A:RETURN
375 &,53,A:IM=2+A:GOTO443
376 A=PM:B$="ROMPT":GOSUB370:PM=A:RETURN
390 DR=3:A$="E.TEXT":GOSUB4:GOSUB1:&,2,2:CLOSE2:&"£$A":RETURN
400 REM**SUBROUTINE MODULES**
427 A$="TURBO":GOTO74
428 A$="COMM1":GOTO74
429 A$="COMM2":GOTO74
430 A$="PARAM1":GOTO74
431 A$="PARAM2":GOTO74
436 A$="MENUS":GOTO74
437 A$="SYSDOS":GOTO74
438 A$="STATS":GOTO74
439 A$="BAR":GOTO74
440 A$="EDITOR":GOTO74
441 A$="HANDLES":GOTO74
442 A$="PROTOS":GOTO74
443 A$="DISPLAY":GOTO74
444 A$="FEEDBACK":GOTO74
445 A$="MISC":GOTO74
446 ON-(LC=.ANDP2$="SUB.MODEM")GOTO60000:A$="MODEM":GOTO74
447 A$="INFO":GOTO74
448 A$="LOCAL":GOTO74
449 A$="MISC2":GOTO74
450 A$="STACK":GOTO74
500 REM**JUMP TABLE**
501 &"DIT ()NFO OR ()ARAMETERS? £G1£V7":A=INSTR("",AN$):REM 12 BYTES VS. 24: A=-(AN$="")-2*(AN$="")
502 IM=1:ONAGOTO447,430:RETURN
503 IM=2:GOTO447
504 IM=1:GOTO443
505 IM=1:GOTO441
506 IM=1:GOTO430
507 IM=1:GOTO445
508 IM=2:GOTO445
509 IM=1:GOTO427
510 IM=1:GOTO428
511 IM=2:GOTO428
512 IM=2:GOTO430
513 IM=4:GOTO443
514 IM=4:GOTO430
515 IM=5:GOTO430
516 IM=4:GOTO447
520 IM=1:GOTO431
521 IM=2:GOTO431
525 IM=1:GOTO439
528 IM=1:GOTO438
533 IM=13:GOTO445
534 IM=4:GOTO445
535 IM=5:GOTO445
540 IM=1:GOTO437
541 IM=2:GOTO437
542 IM=1:GOTO440
543 IM=2:GOTO440
544 IM=1:GOTO429
545 IM=8:GOTO445
546 IM=10:GOTO445
547 IM=14:GOTO445
548 IM=15:GOTO445
549 IM=1:GOTO448
550 IM=2:GOTO448
551 IM=3:GOTO448
552 IM=4:GOTO448
553 IM=5:GOTO448
554 IM=6:GOTO448
555 IM=7:GOTO448
556 IM=8:GOTO448
557 IM=9:GOTO448
558 IM=1:GOTO436
559 IM=2:GOTO429
560 IM=3:GOTO429
561 IM=4:GOTO429
562 IM=5:GOTO429
563 IM=6:GOTO429
564 IM=7:GOTO429
565 IM=2:GOTO449
566 IM=3:GOTO449
567 IM=1:GOTO449
999 RETURN
2000 POKE22,25:FORI=2TOPEEK(152):CLOSEPEEK(603):NEXT:POKE2031,.
2002 X=PEEK(780):Y=PEEK(781)+PEEK(782)*256:&"[RROR#£!X, INE#£!Y]":EL=Y
2004 &,11:&,28,1:POKE53248,.
2006 DR$=MID$(STR$(DR%(5)),2)+":":DV%=DV%(5):LOADDR$+"IM",DV%,2
2008 GOSUB304:GOTO4000
3000 POKE828,PEEK(186):CLR:PRINT"":POKE53280,.:POKE53281,.
3002 OPEN131,2,134,CHR$(6):POKE248,203:POKE250,204:POKE56,160:POKE52,160
3004 DIMA$,A%,AC%,AM,AG$,AK$,AM$,AN$,AO%
3006 DIMB$,B%,BD,BD$,BN$,BU
3008 DIMC$,C%,C1$,C2$,C3$,CA,CC,CC$,CD%,CH$,CM$,CN,CO$,CO%,CR,CT,CT%
3010 DIMD$,D%,D1$,D1%,D2$,D2%,D3%,D3$,D4$,D5$,D6$,DA%,DB%,DC,DC%,DD$,DR,DR$,DV%
3012 DIMDF%
3014 DIME$,E%,EL,EM,EF$,EP$,EC,EC%
3016 DIMF$,F%,F1,F2,F3,F4,FF$,FL,FL$,F1$,F2$,F3$,F4$,F5$,F6$,F7$,F8$
3018 DIMG$,G%
3020 DIMH$,H%,HX$
3022 DIMI$,I%,ID,IM$,IM,IN$,IS
3024 DIMJ$,J%,JN$
3026 DIMK$,K%,KK,KP%
3028 DIML$,L%,L1,L1$,L2,L2$,L3,L3$,LC,LD$,LE,LF,LK%,LL$,LL%,LM$,LP,LT$,LT%
3030 DIMM$,M%,MC,MF,ML$,MP$,MT$,MW,MP%,MN%
3032 DIMN$,N%,NA$,NC,NF,NL,NL$,NM,NM$
3034 DIMO$,O%
3036 DIMP$,P%,P1%,P2%,P3%,PF,PH$,PL,PM,PO$,PP$,PR,PR$,PS,PU$,PW$,P1$,P2$
3038 DIMQ$,Q%,QB,QE,QT$
3040 DIMR$,R%,RC,RN$,RP,RQ
3042 DIMS$,S%,SA%,SH,SG
3044 DIMT$,T%,T1,TC%,TF,TK$,TR%,TT,TT$,TZ$
3046 DIMU$,U%,UC,UH,UL,UR,UF$,UU$
3048 DIMV$,V%
3050 DIMW$,W%
3052 DIMX$,X%
3054 DIMY$,Y%
3056 DIMZ$,Z%,ZZ
3058 AC%=16:X=RND(-TI):HX$="0123456789"+""
3060 C3$="ETURNING O HE DITOR"+""
3062 AK$=" "+""
3064 R$=CHR$(13):NL$=CHR$(.):QT$=CHR$(34)
3066 OPEN4,4,7:POKE836,1:POKE650,128
3068 POKE56328,.:POKE56579,PEEK(56579)OR38:POKE56577,PEEK(56577)OR36
3070 DIMTT$(254),DV%(36),DR%(36),CO$(9),HS$(10),BF(6),ST(38),IM$(5),PF$(10)
3073 RESTORE:FORI=1TO9:READA$:CO$(I)=A$+"":NEXT
3074 DV%=PEEK(828):Z%=DV%:DR$="0"+":":BD$=DR$:SR=2:PR=-1:F3=1:SYS49155:&,53
3075 &,69,1,1,"IM 128 EVISION: UG  4, 2021 11:22 ",3
3076 A$="":IFPEEK(DEC("0A03"))=255THENA$=""
3078 GOSUB3400:Z3$=A$+" YSTEM ETECTED.":GOSUB3404
3080 &,18,.:POKE53248,1:AM$="1"+"0001018600":DV%=Z%
3084 Z3$="EADING RIVE ONFIGURATION...":GOSUB3404:CLOSE15:OPEN15,DV%,15
3086 FL=.:CLOSE2:OPEN2,DV%,2,BD$+"BD.DATA,S,R":GOSUB5
3087 IFE%THENCLOSE2:GOSUB3200:GOSUB3510:Z2$="":&" ":&,28,1:GOTO3084
3088 INPUT#2,DV%(3),DR%(3),PO$:CLOSE2:RESTORE:IFPO$=""THENPO$="AIN: "
3090 READA$:IFA$<>"*"THEN3090
3092 REM:IFDV%=LK%THENPRINT#15,"L800"
3093 GOSUB33:FORI=1TO6:X=I+51:GOSUB1:&,2,2:DV%(I)=VAL(A$)
3094 &,2,2:DR%(I)=VAL(A$):NEXT:CLOSE2
3095 GOSUB33:X=32:GOSUB1:&,2,2:A=VAL(A$):CLOSE2
3096 DR=5:GOSUB4:A$=DR$+"ML.RS232":&,7,DV%,2:&,16,A
3097 Z3$="EADING YSTEM NFO...":GOSUB3404
3098 GOSUB35:IFE%THENCLOSE2:GOSUB3240:GOTO3096
3100 X=1:GOSUB1:&,2,2:BS$=A$:CLOSE2
3102 IM=.:GOSUB441:UH=A%
3103 Z2$=LEFT$(Z2$,22)+"  ("+MID$(STR$(A%),2)+LEFT$(" SERS",6+(A%<>.))+")":GOSUB3404
3104 DR=3:GOSUB3:Z3$="OADING RESET EFINITIONS...":GOSUB3414:GOSUB3404
3106 &" EFS: ":A$=DR$+"E.ECS.MAIN":&,42,4:GOSUB5:&"ONE..."
3108 &"RINT ODE EFS: ":A$=DR$+"E.PRINTMODES":&,7,DV%,7:GOSUB5:&"ONE..."
3110 &"IGHTBAR EFS: ":A$=DR$+"E.LIGHTBAR":&,7,DV%,8:GOSUB5:&"ONE..."
3111 Z3$="ETTING LARM ABLES...":GOSUB3404
3112 &"LARM ABLE: ":A$=DR$+"E.ALARMS":&,7,DV%,9:GOSUB5:&"ONE..."
3114 DR=2:GOSUB3
3116 &"ETWORK LARM ABLE: ":A$=DR$+"NM.TIMES":&,7,DV%,12:GOSUB5:&"ONE..."
3118 DR=3:A$="E.FKEYS,S,R":GOSUB4:IFE%THENCLOSE2:GOTO3128
3120 Z3$="NABLING UNCTION EYS...":GOSUB3404
3122 FORI=1TO8:&,2,2:IFRIGHT$(A$,1)=""THENA$=LEFT$(A$,LEN(A$)-1)+R$
3124 TT$(I)=A$:NEXT:CLOSE2:F1$=TT$(1):F2$=TT$(2):F3$=TT$(3):F4$=TT$(4)
3126 F5$=TT$(5):F6$=TT$(6):F7$=TT$(7):F8$=TT$(8)
3128 Z3$="ETTING P ARIABLES... (E.DATA)":GOSUB3404:GOSUB33
3129 IFE%THENCLOSE2:GOSUB3240:GOTO3128
3130 X=1:GOSUB1:&,2,2:CA=VAL(A$):X=12:GOSUB1:&,2,2:UR=VAL(A$)-1
3132 X=17:GOSUB1:&,2,2:D3$=A$:X=18:GOSUB1:&,2,2:PP$=A$
3134 X=19:GOSUB1:&,2,2:Z$=A$:X=20:GOSUB1:INPUT#2,P1%,P2%,P3%
3135 X=21:GOSUB1:&,2,2:L2=VAL(A$):L2$=(MID$(A$,3)):IFL2THEN:&,52,40,1
3136 X=35:GOSUB1:&,2,2:AM$=A$:AN$=A$:&,15:D6$=AN$+""
3138 X=37:GOSUB1:&,2,2:Y%=VAL(A$):X=38:GOSUB1:&,2,2:LK%=VAL(A$)
3140 DF%=3:X=40:GOSUB1:&,2,2:A=VAL(A$):IFA>.ANDA<16THENDF%=A
3142 X=41:GOSUB1:&,2,2:A=VAL(A$):IFA$<>""THENCLOSE4:OPEN4,4,A
3144 X=42:GOSUB1:&,2,2:A=VAL(A$):IFATHENPOKE17136,A
3146 X=45:GOSUB1:&,2,2:TZ$=A$
3148 X=47:GOSUB1:&,2,2:BN$=A$
3150 X=48:GOSUB1:&,2,2:C1$=""+A$+"":X=49:GOSUB1:&,2,2:C2$=""+A$+""
3152 X=51:GOSUB1:&,2,2:CC$=A$
3154 X=58:GOSUB1:&,2,2:NC=VAL(A$)
3155 IFY%>4THENGOSUB3348:GOSUB3170:GOTO3158
3156 ONY%GOSUB3348,3358,3366:GOSUB3170
3158 POKE970,.:POKE971,23:MP$=" ...ORE? (/N) "+"":IM=5:GOSUB447:GOSUB3250
3160 GOSUB30:FORX=1TO38:GOSUB1:&,2,2:ST(X)=VAL(A$):NEXT:CLOSE2
3162 AN$=AM$:LT$=AM$:TK$=LEFT$(AM$,1):GOSUB3300
3164 CLOSE2:GOSUB3186:&,37
3166 A$=Z$:T1=MN%:AN$=Z$:&,15:D2$=AN$+"":FORI=54272TOI+24:POKEI,.:NEXT
3168 F1=3:&,27,1:GOTO302
3170 A=VAL(LEFT$(Z$,1)):GOSUB3184:POKE52935,A
3172 A=VAL(MID$(Z$,2,2)):GOSUB3184:POKE52938,A
3174 A=VAL(MID$(Z$,4,2)):GOSUB3184:POKE52936,A
3176 A=VAL(MID$(Z$,6,2)):GOSUB3184:POKE52937,A
3178 B=VAL(MID$(Z$,8,2))
3180 C=VAL(MID$(Z$,10,2))
3182 &,62,B,C:B=B+80*((B=92)-(B=12))+12*((B=93)OR(B=13)):&,58,B,.:RETURN
3184 A=16*INT(A/10)+A-INT(A/10)*10:RETURN
3186 FORQ=.TO6:BF(Q)=-1:NEXT
3188 Z3$="EADING LOCKS REE...":GOSUB3404:FORQ=1TO6:DR=Q:GOSUB61
3190 READB$:&" £$B ISK£30:"+STR$(A):NEXT:Q=.:RETURN
3200 &,27,1:Z1$="NSERT LL YSTEM ISKS N ORRECT ":Z2$="      RIVES, ND RESS      "
3202 &": RESS (1) TO ONFIGURE A EW "
3204 &"£10(2) TO ONVERT FROM MAGE 1.2"
3206 &"£10(3) TO ONVERT FROM MAGE 2.0£10(4) TO ESET 64"
3208 &"":GOSUB3408:LM=VAL(AN$):ONLMGOTO3220,3222,3224,(:3226
3210 IFAN$=R$THENGOSUB3414
3212 RETURN
3220 Z3$="ONFIGURE MAGE  3.0":GOTO3228
3222 Z3$="ONVERT FROM MAGE  1.2":GOTO3228
3224 Z3$="ONVERT FROM MAGE  2.0":GOTO3228
3226 Z3$="ESET 128":GOSUB3404:GOSUB93:ONA+1GOTO999:SYS64738
3228 GOSUB3404:&"£39 £39 £39 £39 "
3240 F$="I/SETUP 128":CLOSE15:OPEN1,DV%,1,F$:S=DS:CLOSE15:IFSTHEN:&"ANNOT FIND £$F. ALTING.£W5":GOTO4048
3242 NEW4000:LOADF$,DV%:GOSUB4000:RETURN
3250 DR=3:A$="E.LIGHTDEFS,S,R":GOSUB4:IFE%THENCLOSE2:GOTO3300
3252 Z3$="ETTING EFAULT HECKMARKS...":GOSUB3404
3254 FORX=.TO7:&,2,2:IFLEN(A$)<>16THEN:&"IGHTBAR DEFAULTS LENGTH ERROR, LINE !X":GOTO3258
3256 FORI=1TO16:&,52,X*16+I-1,VAL(MID$(A$,I,1)):NEXT
3258 NEXT:CLOSE2
# : DUPLICATE CODE
3300 DR=3:A$="E.LOG"+LEFT$(LT$,1):GOSUB4:IFE%=.THENRETURN
3302 DR=3:A$="E.LOG"+LEFT$(LT$,1):GOSUB18:CLOSE2:AN$=D1$:&,15:D6$=AN$
3304 A$="  : "+D6$+" £Q0£O£O":GOSUB51
3306 GOSUB33:X=44:GOSUB1:PRINT#2,D6$:CLOSE2
3308 GOSUB30:FORX=12TO22:ST(X)=.:GOSUB17:NEXT:RETURN
3348 Z3$="ETTING LOCK BY  EVICE...":GOSUB3404:CLOSE15:OPEN15,Y%,15:PRINT#15,"T-RA":&,2,15
3350 Z$=LEFT$(A$,2):A=-(Z$="SU")-2*(Z$="MO")-3*(Z$="TU")-4*(Z$="WE")-5*(Z$="TH")
3352 A=A-6*(Z$="FR")-7*(Z$="SA"):Z$=MID$(STR$(A),2,1)+MID$(A$,12,2)+MID$(A$,6,2)
3354 A=-80*(MID$(A$,24,1)="P")+VAL(MID$(A$,15,2))
3356 Z$=Z$+MID$(A$,9,2)+RIGHT$("0"+MID$(STR$(A),2),2)+MID$(A$,18,2):POKE1010,1:RETURN
3358 GOSUB3364:SYS49155:GOTO3362
3360 GOSUB33:X=35:GOSUB1:&,2,2:D1$=A$:CLOSE2:POKE1010,1:RETURN
3362 Z$="":FORA=49159TO49169:Z$=Z$+CHR$(PEEK(A)):NEXT:POKE1010,1:RETURN
3364 Z$="ETTING LOCK BY T.ERNAL...":GOSUB3404:DR=5:GOSUB4:A$=DR$+"SWR.ML":&,7,DV%,2:RETURN
3366 GOSUB3364:SYS49152:SYS49155:GOTO3362
# : USE  COMMAND?
# FIXED CODE IS IN
# HTTPS://GITHUB.COM/INACOLADA64/MAGE3/BLOB/MASTER/CORE/TESTS/I.TEST%20FRAME.LBL
3400 Z1$="":Z2$="":&" "+MID$(AK$,2,36)+""
3401 FORX=2TO3:&" £O                  ":NEXT
3403 &" "+MID$(AK$,2,36)+"":RETURN
3404 Z1$=Z2$:Z2$=Z3$:FORI=1TO(34-LEN(Z2$)):Z2$=Z2$+" ":NEXT
3406 &"£"+Z1$+""+Z2$+"":RETURN
3408 C$="":I=I+1:IFI>2THENI=1
3409 B$=MID$(C$,I,1)+" "+Z1$:&"£$B":B$=MID$(C$,I,1)+" "+Z2$:&"£$B"
3410 GETAN$:Z=Z+1:IFAN$<>""THENZ2$="":Z=.:GOSUB3400:RETURN
3411 IFZ=20THENZ=.:GOTO3408
3412 GOTO3410
# :
# 3414 FORI=7TO24:&,69,0,I,"                             ":&,70,0,6
3414 &"":FORI=7TO24:&"£38 ":NEXT:&"":RETURN
3500 DATA"OMMODORE 64","OMMODORE 128","MIGA","PPLE/OMP."
3502 DATA"/OMP.","ACINTOSH","TARI/","ANDY ERIES","THER YPE"
3504 DATA"*","YSTEM","-AIL","TCETERA","IRECTORY","LUS-ILE","SER"
3510 REMOVE: &"232 NTERFACE YPE:NTER 0 FOR SER ORTNTER 1 FOR WIFTINK/URBO232> £I1"
3512 REMOVE: A=VAL(AN$):IFA<0ORA>1THEN3510
3514 REMOVE: GOSUB33:X=32:GOSUB1:PRINT#2,AN$:CLOSE2:RETURN
3999 REM COPR. 2023 NEW IMAGE 8/10/2023
4000 &,38:CM$=CM$+"":P$=P$+"":PR$=PR$+"":P1$=P1$+"":P2$=P2$+""
4002 IFX<128THEN4006:ELSEA$=" !!":GOSUB51:SYS64789:PRINT""A$:END
4004 &,38:&,61,.,8:PRINT"&,37:GOTO300:":END
4006 RESTORE
4008 READA$:IFA$<>"ERRORS"THEN4008
4010 &,40:D$="":IFX>.ANDX<30THENFORK=1TOX:READD$:NEXT
4012 A%=X:&"   #£%A (£$D )":R$=CHR$(13)
4014 A$="IM":IFEL=>3000THENA$=PR$:IFEL=>4000THENA$=P1$:IFEL=>60000THENA$=P2$
4016 A=EL:&" N INE:£!A F £$A"
4018 &"ECORDING RROR, LEASE AIT...":D$=STR$(X)+" ("+D$+" )"
4020 DR=3:A$="E.ERRLOG,S,A":GOSUB4:IFE%=.THEN4024
4022 A$="E.ERRLOG,S,W":GOSUB4
4024 PRINT#2,NA$R$ID;R$D1$R$AC%;R$PH$R$RN$R$CO$(CO%)R$
4026 PRINT#2,"RROR :"D$R$"INE  :"EL;R$"REA  : "CM$R$"ROMPT: "P$
4028 PRINT#2,"ROGRAM: "PR$R$"ODULE: "P1$R$"UB ODULE: "P2$
4030 PRINT#2," ILE: "ML$R$"ROTOCOL: "D4$R$
4032 FORI=1TO10:A$=CHR$(58-I):IFHS$(I)<>""THENPRINT#2," "A$": "HS$(I)
4034 NEXT:PRINT#2,"^":CLOSE2:REM : CHECK LIGHTBAR FLAG: POKE53280,2
4036 A$="SER  : "+NA$+R$+"RROR :"+D$+R$+"INE  :"+STR$(B)+R$+"IME  : "+D1$+R$
4038 A$=A$+"FILE : "+PR$+R$+"REA  : "+CM$+R$+".":REMGOSUB51
4040 CLOSE2:&,37:FORX=1TO4:&,11,X:NEXT:SY$="":SB$="":SG=.
4042 P2$="":IS=.:P1$="":PR$="":ML$="":PR=-1:PF=.
4044 IFAC%<>16THEN:&,52,4,3:IFA%ORIF(PEEK(2033)AND1)=.THEN4050
4046 F1=2:GOTO302
4048 A$=" !!":GOSUB51:SYS64789:PRINT""A$:END
4050 &,52,4,3:IFA%ORI%ORID=1THEN4068
4052 GOSUB4092:KK=.:A$="S.ERRMAIL,S,R":DR=1:GOSUB4:IFE%THENCLOSE2:GOTO4068
4054 KK=KK+1:&,2,2:S=(64ANDST):TT$(KK)=A$:IFS=.THEN4054
4056 CLOSE2:TT$=NA$:A$="A":GOSUB32:IFE%THENA$="W":GOSUB32
4058 A$="[YSTEM RROR ("+D$+")]":A=.:PRINT#2,I1$R$1;R$D1$R$A$R$
4060 GOSUB39:CLOSE15
4062 GOSUB30:I=1:X=14:GOSUB16:X=25:GOSUB16:X=32:GOSUB16:CLOSE2
4064 &"£HO£H9ED!OU AVE EW -AIL AITING:EAD OW? ":GOSUB96
4066 IFATHENA$=""+"":GOTO70
4068 PR$="":GOTO300
4070 DATA"ERRORS"
4072 DATA"  "," ","  "
4074 DATA"  ","  ","  "
4076 DATA"  ","  ","  "
4078 DATA"  ","","  "
4080 DATA"  "," ",""
4082 DATA"  ","' "," "
4084 DATA"' ","  "," "
4086 DATA" ","  "," "
4088 DATA"  ","' ","' "
4090 DATA"",""," "
4092 GOSUB35:X=1:GOSUB1:&,2,2:I1$=A$:CLOSE2:RETURN:REM GET SYSOP NAME
4094 REM COPR. 1996 NEW IMAGE 5/6/96-JLF
4096 REM IM (C)NISSA 2020-09-29 LH-AD, 2023-08-10 RS
