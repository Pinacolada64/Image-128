' comments begin with '
{include:"asm\equates.asm"}
' for quote mode character replacements:
{include:quoters.lbl}

{loadaddr:$1c01}
{assign:60000=60000}

' 0 on peek(829) goto 3000,4000:goto 300
0 on peek({sym:linflg}) goto 3000,4000:goto 300
1 gosub 10:&,22,1:goto 10
2 dv%(.)=d1%:dr%(.)=d2%:dv%=dv%(dr):dr$=mid$(str$(dr%(dr)),2)+":":d3%=dr%(dr):return
3 close 15:gosub 2:open15,dv%,15:return
4 close 2:gosub 3:open2,dv%,2,dr$+a$
5 input#15,e%,e$,t%,s%:a$="{f6}Status:{pound}#2{pound}%e:{pound}$e:{pound}%t:{pound}%s{f6}":return
' 6 an$=uu$:on-(an$<>"")gosub 310:on-(an$<>"")goto 314:pl=1:&,1:goto 310
6 an$=uu$:if an$<>"" then gosub 310:else if an$<>"" then 314:else pl=1:&,1:goto 310
7 &"{pound}g1":a$=an$:return
' i take it peek(17138) <c64 screen mask mode> is checked within &,69
' therefore eliminating it here:
9 if nt=. then:&,69,4,21,left$(" "+cm$+"               ",22),$8c:return:else return
' rem print#15,"p"chr$(xand255)chr$(x/256)"":return
' record# lfn, record_num [, byte_num]
10 record#2,x,1:return
11 a=val(mid$(fl$,a,1)):return
' no idea what 'flag' does
' poke 53253,.:poke 2024,.:poke 2031,.:poke 53260,.
12 poke {sym:flag},.:poke {sym:mjump},.:poke {sym:mci},.:poke {sym:mupcase},.:&"{pound}u0{pound}q"+chr$(df%+48):return

13 &"{clear}"
14 a$=a$+",s,r":gosub 4:if e%=. then:&,3,2
15 close 2:return
16 gosub 1:input#2,st(x):st(x)=st(x)+i
17 gosub 1:print#2,st(x):return
18 gosub 19:a$=a$+",s,w":goto 4
19 gosub 3:print#15,"s"dr$a$:return
' "scratch(dr$+a$) on u dr%(dr)" doesn't seem to work in basic 7.0
28 cm$=a$:gosub 9:dr=5:gosub 3:if "++ "+a$=ml$ then e%=.:return
29 ml$="++ "+a$:a$=dr$+ml$:&,7,dv%,2:goto 5
30 dr=3:a$="e.stats":goto 4
31 dr=3:a$="e.access":goto 4
32 dr=2:a$="m."+left$(tt$,13)+",s,"+a$:goto 4
33 dr=3:a$="e.data":goto 4
34 e%=a%:&,52,46,3:am=a%:a%=e%:dr=3:a$="e.log"+left$(lt$,am)+",s,"+a$:goto 4
35 dr=6:a$="u.config":goto 4
36 dr=3:a$="e."+b$+",s,"+a$:goto 4
37 a$="a":gosub 36:if e% then a$="w":gosub 36
38 print#2,na$r$id;r$d1$r$ac%r$ph$r$rn$r$co$:return
39 &,14,2,kk-1:print#2,"^":close 2:goto 62
40 a$="new user":goto 42
41 a$="config"
42 a$="s."+a$:dr=1:goto 13
43 dr=3:a$="e.say":gosub 4:on sgn(e%) goto 46:x=1:gosub 1:input#2,x
44 a=rnd(-ti):x=int(rnd(1)*x)+2:gosub 1
45 input#2,b$,c$,d$,f$:gosub 90:lp=1:&"{f6}{pound}$q{white} {pound}$b{f6}{pound}$q{cyan} {pound}$c{f6}{pound}$q{yellow} {pound}$d{f6}{pound}$q{orange} {pound}$f{f6}{pound}q0"
46 close 2:return
50 if i% then return
51 c$=a$:a$="a":gosub 34:if e%=. then print#2,c$
52 close 2:a$=c$:an$=c$:a=a%:&,52,13,3:b=a%:a%=a:if b=. then return
53 open 16,4,15:close 16:if st then return
54 print#4,a$:return
60 a$="{black},u,w":gosub 4:close2:print#15,"s"dr$"{black}":a=-sgn(e%):return
61 if dr<7 then if bf(dr)>-1 then gosub 2:a=bf(dr):bf=a:return
62 gosub 3:if dv%<>lk% then 64:else a$=dr$:if dr$="10:" then a$="a"
63 a=2:print#15,"lg"left$(a$,1):input#15,e%,a$,a$,a$,a$,a$:goto 65
64 a=1:close 2:open 2,dv%,0,"$"+dr$+"{black}":get#2,a$,a$:&,8,2,1:&,8,2,1:close 2
65 a=val(a$)*a:bf=a:for a=1 to 6:if dv%(a)=dv% and dr%(a)=val(dr$) then bf(a)=bf
66 next:a=bf:return
70 dr=5
71 if pr$<>"i."+a$ then gosub 76:else goto 3000
72 dr=5
73 if p1$<>"i/"+a$ then gosub 77:else goto 4000
74 if a$<>"modem" then 100:else dr=5:if p2$<>"sub."+a$ then gosub 78:else is=is+1:im$(is)=p2$
75 gosub 60000:is=is-1:if is<1 then return:else a$=mid$(im$(is),5):goto 78
'TODO: maybe?
'76 a$="i."+a$:pr$=a$+"":p1$="":p2$="":delete 3000-3999:goto 79
'77 a$="i/"+a$:p1$=a$+"":p2$="":delete 4000-59999:goto 79
76 a$="i."+a$:pr$=a$+"":p1$="":p2$="":new 3000:goto 79
77 a$="i/"+a$:p1$=a$+"":p2$="":new 4000:goto 79
' 78 a$="sub."+a$:p2$=a$+"":delete 60000-
78 a$="sub."+a$:p2$=a$+"":new 60000
79 cm$=a$:gosub 9:gosub 2:load dr$+a$,dv%:return
80 a$=z$:z$=mid$(p1$,3):gosub 72:a$=z$:dr=5:if lc<>1 then 77:else return
82 for i=1 to 4:&,11,i:next
83 &,11,.:return
84 a=int(mn%/60):pt%=-(a>=p2% and a<p3%)*sgn(p1%):return
85 &"{f6}Would You Like To Leave Feedback? ":gosub 93:if a=. then return:else dr=3:gosub 61
86 x=2:if bf<35 then 390:else im=1:goto 444
' FIXME: building the string like this is terribly inefficient
90 q$="":if ll%>42 then q$=left$("{space:42}",(ll%-42)/2)
' 90 q$="":if ll%>42 then for r=1 to int((ll%-42)/2):q$=q$+" ":next
' else won't help above
91 return
92 &"{f6}{lt. blue}>{cyan}>{white}Canceled!{f6}":return

' TODO: rather than gosub 93 for "default no" and gosub 95 for "default yes"
' I'd rather go back to "a=0:gosub 94" for default yes, but this is a lot of change
{ifdef:yesno_change}
' updated working code:
94 &"{f6}Are You Sure?: {cyan}[{white}":if a then 96
95 &"No{cyan}]":gosub 7:&"{pound}h4":a=-(a$="Y"):goto 97
96 &"Yes{cyan}]":gosub 7:&"{pound}h5":a=(a$="N")+1
97 &"{pound}q"+chr$(df%+48)+mid$("YesNo",4-a*3,3)+"{f6}":return
{else:}
' current code:
93 gosub 98
94 &"{cyan}[{white}No{cyan}]":gosub 7:&"{pound}h4":a=-(a$="Y"):goto 97
95 gosub 98
96 &"{cyan}[{white}Yes{cyan}]":gosub 7:&"{pound}h5":a=(a$="N")+1
97 &"{pound}q"+chr$(df%+48)+mid$("YesNo",4-a*3,3)+"{f6}":return
98 &"{f6}Are You Sure?: ":return
{endif}

100 p2$="sub."+a$:gosub 110:is=is+1:im$(is)=im$
' FIXME: "new 60000": replace with delete 60000- ?
102 gosub 60000:new 60000:is=is-1:if is then a$=im$(is):p2$="sub."+a$:gosub 110
104 return
110 dr=5:gosub 2:im$=a$:cm$="sub."+a$:gosub 9:a$=dr$+"sub."+a$:load a$,dv%
112 return
200 on tr%+1 goto 240:&,52,17,lf:&,52,20,em:poke {sym:modclmn},ll%:poke {sym:usrlin},mp%:poke {sym:ptrlinm},0
202 &,52,30,3:on a% gosub 330
204 s=.:sh=.:gosub 12
206 poke {sym:ptrlinm},0:&,52,30,3:an$=d1$:&,15:b$=right$(an$,7)
208 mm=2:gosub 3000:gosub 9:&"{f6} {blue}- {white}{pound}$bM{pound}q0":if tr%<100 then a%=tr%:&" {blue}- {white}{pound}%a {cyan}Min Left{pound}q0"
209 if zz then a%=usr(0):&"{f6} {blue}- {cyan}Stack Free: {white}{pound}%a{pound}q0"
210 &"{f6:2}":poke {sym:llen},38:gosub 6
212 cm$=left$(p$,11)+":"+left$(an$,4):gosub 9:cm$=p$
214 on tr%+1 goto 240:if an$="" then gosub 250:goto 200
216 gosub 220:if f4 then gosub 304:on -(f4=1.1)-2*(f4=1.2)-3*(f4=1.3) goto 270,268,234
218 on rs goto 200:mm=1:goto 3000
220 on -(ac%<>ao%) gosub 320:an$=an$+"":rs=1:a$=left$(an$,1):z$=left$(an$,2)
222 &,52,20,3:em=a%:&,52,5,3:zz=a%
224 x=1:rq=.:rs=1
226 f4=.:a%=zz:b%=2^ac%:&,42:if a% then ef$=b$:ep$=a$:ec=a%:ec%=b%:goto 260
228 on -(a$="O" or (lc=1 and a$="Q"))-2*(a$="{question}") goto 230,250:rs=.:return
230 f4=.:ifright$(an$,1)<>"!"then:&"{f6:2}Logoff?: ":gosub 93:if a=. then return
232 f4=1.3:return
234 f1=1-(right$(an$,1)="!"):cd%=.:ifmid$(z$,2,1)="%"then302
236 &"{f6}Update Message/File Scan Date?: ":gosub 96:ifathenld$=lt$:elsegoto 302
240 &"{f6}Sorry, Time Limit Exceeded.{f6}":mm=3:gosub 3000:f1=1:goto 302
242 f1=.:&"{f6} Aborted!{f6}":goto 200
250 im=1:goto 436
260 if ec%>. and cr-ec%<. then:&"{red}Not Enough Credits!{f6}":return
262 cr=cr-ec%:if ep$="" or id=1 then 264
263 &"{f6}{white}Password{blue}:{white}":&,6:ifan$<>ep$then:&"{f6}{red}Incorrect Password.{f6}":return
264 f4=.:onecgoto 265,266,267,268:return
265 z$=ef$:f4=1.1:&,28,1:return
266 f4=1.2:&,28,1:return
267 z$=ef$:goto 80
268 a%=asc(ef$+nl$)+256*asc(mid$(ef$,2,1)+nl$):&,42,1
270 mm=.:a$=z$:goto 70
280 a%=zz:b%=2^ac%:&,42:ifa%thenef$=b$:ep$=a$:ec=a%:ec%=b%:goto 264
282 return
288 return
289 &"{pound}i0":ifan$=""thenreturn
290 &,15,2:return
' leave these two lines untouched: continue after
300 &,28,1:&,52,$30,3:ona%gosub 309:mm=.:a$="main":goto 70
302 &,28,1:&,52,$30,3:ona%gosub 309:mm=.:a$="lo":goto 70
304 &,28,1:gosub 306:&,27:return
306 dimbb$(31),dt$(61),ed$(61),nn$(61)
308 dima%(61),c%(61),d%(61),e%(31),f%(61),ac%(31),so%(31):return
309 cm$="1.3 Emulator":gosub 9:dr=5:gosub 3:loaddr$+"im.emul13",dv%:goto 304
310 pu$=an$:ifan$="{uparrow}{question}"then315
311 ifleft$(an$,1)="{uparrow}"thenan$=hs$(10-val(mid$(an$,2,1))):goto 314
312 &,15,6,140:uu$=an$:an$=a$
313 for ct=1 to 9:hs$(ct)=hs$(ct+1):next:hs$(10)=an$:return
314 &p$+": {pound}v7{f6}":return
315 for ct=1 to 10:a%=10-ct:a$=hs$(ct):&"{uparrow}{pound}%a: {pound}$a{f6}":next:an$="":uu$="":return
320 gosub 31:x=ac%+1:gosub 1:&,2,2:ag$=a$:&,2,2:close2
321 if len(fl$)<len(a$) then fl$=fl$+mid$(a$,len(fl$)+1)
322 if len(fl$)>len(a$) then fl$=a$
323 if ac%<>ao% then fl$=a$:ao%=ac%
324 a=6:gosub 11:le=(a+1)*10:a=16:gosub 11:poke {sym:idlemax},a:a=20:gosub 11:da%=a
325 return
330 dr=3:a$="e.macros":gosub 4
332 if e%=. then:&,2,2:a=val(a$):&"{f6:2}":x=int(rnd(1)*a)+2:gosub 1:&,3,2
334 close2:return
349 &"{f6}Device, Drive: {pound}i1":an$="  "+an$:return
350 a=int(val(mid$(an$,3,2))):ifa>.thenifa<7thendr=a:goto 353
351 ifa<7ora>29thena=8
352 &,15,6,133:d2%=val(an$):d1%=a:dr=.:dv%(.)=d1%:dr%(.)=d2%
353 gosub 3:close15:a=-(st<>.):return
370 a=1-a:&"{f6}{green}{pound}$b Mode{lt. green}: {white}O"+mid$("ffn",a*2+1,2)+"{f6}":return
371 a=val(mid$(uf$,b,1)):gosub 370:uf$=left$(uf$,b-1)+chr$(a+48)+mid$(uf$,b+1):return
372 a=em:b$="Expert":gosub 370:em=a:&,52,20,em:return
373 im=3:goto 430
374 b=3:b$="Graphic Menu":gosub 371:&,52,44,a:return
375 &,53,a:im=2+a:goto 443
376 a=pm:b$="Prompt":gosub 370:pm=a:return
390 dr=3:a$="e.text":gosub 4:gosub 1:&,2,2:close2:&"{f6}{pound}$a{f6}":return
400 rem**subroutine modules**
427 a$="turbo":goto 74
428 a$="comm1":goto 74
429 a$="comm2":goto 74
430 a$="param1":goto 74
431 a$="param2":goto 74
436 a$="menus":goto 74
437 a$="sysdos":goto 74
438 a$="stats":goto 74
439 a$="bar":goto 74
440 a$="editor":goto 74
441 a$="handles":goto 74
442 a$="protos":goto 74
443 a$="display":goto 74
444 a$="feedback":goto 74
445 a$="misc":goto 74
' 446 on-(lc=.andp2$="sub.modem")goto 60000:a$="modem":goto 74
446 if lc=. and p2$="sub.modem" then 60000:else a$="modem":goto 74
447 a$="info":goto 74
448 a$="local":goto 74
449 a$="misc2":goto 74
450 a$="stack":goto 74
500 rem**jump table**
' rem 12 bytes vs. 24: a=-(an$="I")-2*(an$="P"):
501 &"{f6}Edit (I)nfo or (P)arameters? {pound}g1{pound}v7{f6}":a=instr("IP",an$)
502 if a then im=1:on a goto 447,430:else return
503 im=2:goto 447
504 im=1:goto 443
505 im=1:goto 441
506 im=1:goto 430
507 im=1:goto 445
508 im=2:goto 445
509 im=1:goto 427
510 im=1:goto 428
511 im=2:goto 428
512 im=2:goto 430
513 im=4:goto 443
514 im=4:goto 430
515 im=5:goto 430
516 im=4:goto 447
520 im=1:goto 431
521 im=2:goto 431
525 im=1:goto 439
528 im=1:goto 438
533 im=13:goto 445
534 im=4:goto 445
535 im=5:goto 445
540 im=1:goto 437
541 im=2:goto 437
542 im=1:goto 440
543 im=2:goto 440
544 im=1:goto 429
545 im=8:goto 445
546 im=10:goto 445
547 im=14:goto 445
548 im=15:goto 445
549 im=1:goto 448
550 im=2:goto 448
551 im=3:goto 448
552 im=4:goto 448
553 im=5:goto 448
554 im=6:goto 448
555 im=7:goto 448
556 im=8:goto 448
557 im=9:goto 448
558 im=1:goto 436
559 im=2:goto 429
560 im=3:goto 429
561 im=4:goto 429
562 im=5:goto 429
563 im=6:goto 429
564 im=7:goto 429
565 im=2:goto 449
566 im=3:goto 449
567 im=1:goto 449
' TODO: drop 999
999 return
' FIXME: close all open files
2000 poke 22,25:for i=2 to peek(152):close peek(603):next:poke 2031,.
2002 x=peek(780):y=peek(781)+peek(782)*256:&"{f6}[Error#{pound}!x, Line#{pound}!y]{f6}":el=y
2004 &,11:&,28,1:poke 53248,.
2006 dr$=mid$(str$(dr%(5)),2)+":":dv%=dv%(5):load dr$+"im",dv%,2
2008 gosub 304:goto 4000

' *** init ***

' color 0,1 => poke 53280,0 [vic border]
' color 4,1 -> poke 53281,0 [vic background]
' 3000 poke 828,peek(186):clr:print"{white}":poke 53280,.:poke 53281,.
3000 poke {sym:bootdev},{sym:fa}:clr:print"{clear}{switchdisable}{white}{lowercase}":color 0,1:color 4,1
' TODO: poke 52/56 RAM, 248,250 RS232
3002 open 131,2,134,chr$(6):poke 248,203:poke 250,204:poke 56,160:poke 52,160
3004 dima$,a%,ac%,am,ag$,ak$,am$,an$,ao%
3006 dimb$,b%,bd,bd$,bn$,bu
3008 dimc$,c%,c1$,c2$,c3$,ca,cc,cc$,cd%,ch$,cm$,cn,co$,co%,cr,ct,ct%
3010 dimd$,d%,d1$,d1%,d2$,d2%,d3%,d3$,d4$,d5$,d6$,da%,db%,dc,dc%,dd$,df%,dr,dr$,dv%
' 3012 dimdf%
3014 dime$,e%,el,em,ef$,ep$,ec,ec%
3016 dimf$,f%,f1,f2,f3,f4,ff$,fl,fl$,f1$,f2$,f3$,f4$,f5$,f6$,f7$,f8$
3018 dimg$,g%
3020 dimh$,h%,hx$
3022 dimi$,i%,id,im$,im,in$,is
' drop jn$ (haven't seen it used except in pre-TurboREL subs for join string)
3024 dimj$,j% ',jn$
3026 dimk$,k%,kk,kp%
3028 diml$,l%,l1,l1$,l2,l2$,l3,l3$,lc,ld$,le,lf,lk%,ll$,ll%,lm$,lp,lt$,lt%
3030 dimm$,m%,mc,mf,ml$,mp$,mt$,mw,mp%,mn%
3032 dimn$,n%,na$,nc,nf,nl,nl$,nm,nm$
3034 dimo$,o%
' TODO: change ph$ to em$ in varbl.asm?
3036 dimp$,p%,p1%,p2%,p3%,pf,ph$,pl,pm,po$,pp$,pr,pr$,ps,pu$,pw$,p1$,p2$
3038 dimq$,q%,qb,qe,qt$
3040 dimr$,r%,rc,rn$,rp,rq
3042 dims$,s%,sa%,sh,sg
3044 dimt$,t%,t1,tc%,tf,tk$,tr%,tt,tt$,tz$
3046 dimu$,u%,uc,uh,ul,ur,uf$,uu$
3048 dimv$,v%
3050 dimw$,w%
3052 dimx$,x%
3054 dimy$,y%
3056 dimz$,z%,zz
3058 ac%=16:x=rnd(-ti):hx$="0123456789ABCDEF"+""
3060 c3$="{f6}Returning To The Editor"+"{f6:2}"
3062 ak$=" {192:38}"+"{f6}"
3064 r$=chr$(13):nl$=chr$(.):qt$=chr$(34)
' 650 [c64], 2594/$0a22 [c128]: key repeat
' FIXME: 836
3066 open 4,4,7:poke 836,1:poke {sym:keyrept},128
3068 poke 56328,.:poke 56579,peek(56579)or 38:poke 56577,peek(56577) or 36
3070 dim tt$(254),dv%(36),dr%(36),co$(9),hs$(10),bf(6),st(38),im$(5),pf$(10)
3073 restore:for i=1 to 9:read a$:co$(i)=a$+"":next
3074 dv%=peek({sym:bootdev}):z%=dv%:dr$="0"+":":bd$=dr$:sr=2:pr=-1:f3=1:sys 49155:&,53
' NOTE: __BuildDate and __BuildTime are themselves quoted strings, hence the weirdness here:
3075 &,69,1,1,"im 128 revision: "+{usedef:__BuildDate}+" "+{usedef:__BuildTime},3
3076 a$="NTSC":if peek({sym:ntscpal})=255 then a$="PAL"
3078 gosub 3400:z3$=a$+" System Detected.":gosub 3404
3080 &,18,.:poke 53248,1:am$="1"+"0001018600":dv%=z%
3084 z3$="Reading Drive Configuration...":gosub 3404:close 15:open 15,dv%,15
3086 fl=.:close 2:open 2,dv%,2,bd$+"bd.data,s,r":gosub 5
' TODO: remove 3510. sets up modem type, should be moved to "i/setup 128"
' 3087 ife%thenclose2:gosub 3200:gosub 3510:z2$="":&"{home} ":&,28,1:goto 3084
3087 if e% then close 2:gosub 3200:z2$="":&"{home} ":&,28,1:goto 3084
3088 input#2,dv%(3),dr%(3),po$:close 2:if po$="" then po$="Main: "
3090 restore:do until a$<>"*":read a$:loop
3092 remifdv%=lk%thenprint#15,"l800"
3093 gosub 33:for i=1 to 6:x=i+51:gosub 1:&,2,2:dv%(i)=val(a$)
3094 &,2,2:dr%(i)=val(a$):next:close 2
' read rs232 interface type:
3095 gosub 33:x=32:gosub 1:&,2,2:a=val(a$):close 2
3096 dr=5:gosub 4:a$=dr$+"ml.rs232":&,7,dv%,2:&,16,a
3097 z3$="Reading System Info...":gosub 3404
3098 gosub 35:if e% then close 2:gosub 3240:goto 3097
3100 x=1:gosub 1:&,2,2:bs$=a$:close 2
3102 im=.:gosub 441:uh=a%
3103 z2$=left$(z2$,22)+"  ("+mid$(str$(a%),2)+left$(" Users",6+(a%<>.))+")":gosub 3404
3104 dr=3:gosub 3:z3$="Loading System Defaults...":gosub 3414:gosub 3404:d$=" Definitions: "
3106 &"{f6}{lt. blue}Extended Command Set{pound}$d":a$=dr$+"e.ecs.main":&,42,4:gosub 3192
3108 &"Print Mode{pound}$d":a$=dr$+"e.printmodes":&,7,dv%,7:gosub 3192
3110 &"Lightbar{pound}$d":a$=dr$+"e.lightbar":&,7,dv%,8:gosub 3192
3111 z3$="Setting Alarm Tables...":gosub 3404
3112 &"{f6:4}{lt. blue}Alarm Table: ":a$=dr$+"e.alarms":&,7,dv%,9:gosub 3192
3114 :
3116 &"{lt. blue}Network Alarm Table: ":dr=2:gosub 3:a$=dr$+"nm.times":&,7,dv%,12:gosub 3192
3118 dr=3:a$="e.fkeys,s,r":gosub 4:if e% then close 2:goto 3128
3120 z3$="Enabling Function Keys...":gosub 3404
3122 fori=1to8:&,2,2:ifright$(a$,1)="{back arrow}"thena$=left$(a$,len(a$)-1)+r$
3124 tt$(i)=a$:next:close2:f1$=tt$(1):f2$=tt$(2):f3$=tt$(3):f4$=tt$(4)
3126 f5$=tt$(5):f6$=tt$(6):f7$=tt$(7):f8$=tt$(8)
3128 z3$="Setting Up Variables... (e.data)":gosub 3404:gosub 33:if e% then close2:gosub 3240:goto 3128
3130 x=1:gosub 1:&,2,2:ca=val(a$):x=12:gosub 1:&,2,2:ur=val(a$)-1
3132 x=17:gosub 1:&,2,2:d3$=a$:x=18:gosub 1:&,2,2:pp$=a$
' date/time of last user logoff, prime time data
3134 x=19:gosub 1:&,2,2:z$=a$:x=20:gosub 1:input#2,p1%,p2%,p3%
' system reservation?
3135 x=21:gosub 1:&,2,2:l2=val(a$):l2$=(mid$(a$,3)):if l2 then:&,52,40,1
3136 x=35:gosub 1:&,2,2:am$=a$:an$=a$:&,15:d6$=an$+"M"
' clock type, lt. kernal device number
3138 x=37:gosub 1:&,2,2:y%=val(a$):x=38:gosub 1:&,2,2:lk%=val(a$)
' default color [cyan]:
3140 df%=3:x=40:gosub 1:&,2,2:a=val(a$):if a>. and a<16 then df%=a
' printer device #
3142 x=41:gosub 1:&,2,2:a=val(a$):if a then close 4:open 4,4,a
' password mask character(s)
3144 x=42:gosub 1:&,2,2:a=val(a$):if a then poke 17136,a
' system time zone string
3146 x=45:gosub 1:&,2,2:tz$=a$
' BBS name
3148 x=47:gosub 1:&,2,2:bn$=a$
' * entering chat mode *, * exiting chat mode *
3150 x=48:gosub 1:&,2,2:c1$="{clear}{f6}{$07}"+a$+"{f6:2}":x=49:gosub 1:&,2,2:c2$="{f6:2}"+a$+"{f6:2}"
3152 x=51:gosub 1:&,2,2:cc$=a$
' new user credits
3154 x=58:gosub 1:&,2,2:nc=val(a$)

' clock types:
3155 if y%>4 then gosub 3348:gosub 3170:goto 3158
3156 on y% gosub 3348,3358,3366:gosub 3170
3158 poke 970,.:poke 971,23:mp$=" ...More? (Y/n) "+"":im=5:gosub 447:gosub 3250

3160 gosub 30:for x=1 to 38:gosub 1:&,2,2:st(x)=val(a$):next:close 2
3162 an$=am$:lt$=am$:tk$=left$(am$,1):gosub 3300
3164 close2:gosub 3186:&,37
3166 a$=z$:t1=mn%:an$=z$:&,15:d2$=an$+"M":for i=54272 to i+24:poke i,.:next
3168 f1=3:&,27,1:goto 302
' $cec7 (longdate):
3170 a=val(left$(z$,1)):gosub 3184:poke 52935,a
3172 a=val(mid$(z$,2,2)):gosub 3184:poke 52938,a
3174 a=val(mid$(z$,4,2)):gosub 3184:poke 52936,a
3176 a=val(mid$(z$,6,2)):gosub 3184:poke 52937,a
3178 b=val(mid$(z$,8,2))
3180 c=val(mid$(z$,10,2))
3182 &,62,b,c:b=b+80*((b=92)-(b=12))+12*((b=93)or(b=13)):&,58,b,.:return

' convert a to bcd:
3184 a=16*int(a/10)+a-int(a/10)*10:return

' read blocks free
3186 for q=. to 6:bf(q)=-1:next
3188 z3$="Reading Blocks Free...":gosub 3404:for q=1 to 6:dr=q:gosub 61
3190 read b$:&"{f6}{rvs off}{lt. blue} {pound}$b Disk{pound}{back arrow}30:{cyan}"+str$(a):next:q=.:return

' new: from 3100- report ok/error
3192 gosub 5:c$="{lt. green}":if e% then c$="{lt. red}"
3194 &"{pound}{back arrow}20"+c$+"{pound}$e{f6}{lt. blue}":return

3200 &,27,1:z1$="Insert All System Disks In Correct ":z2$="      Drives, And Press RETURN     "
3202 &"{home}{f6:7}{green}OR: {lt. green}Press {yellow}({white}1{yellow}) {lt. green}to configure a new BBS{f6}"
3204 &"{pound}{back arrow}10{yellow}({white}2{yellow}) {lt. green}to convert from Image BBS v1.2{f6}"
3206 &"{pound}{back arrow}10{yellow}({white}3{yellow}) {lt. green}to convert from Image BBS v2.0{f6}"
3207 &"{pound}{back arrow}10{yellow}({white}4{yellow}) {lt. green}to reset C128{f6}"
3208 gosub 3408:lm=val(an$):on lm goto 3220,3222,3224,3226
3210 if an$=r$ then gosub 3414
3212 return
3220 z3$="Configure Image BBS 3.0":goto 3228
3222 z3$="Convert from Image BBS 1.2":goto 3228
3224 z3$="Convert from Image BBS 2.0":goto 3228
' [c64] sys 64738 (reset) = [128] sys 16384
3226 z3$="Reset C128":gosub 3404:a=.:gosub 94:if a=. then return:else sys 16384
' FIXME: ew
3228 gosub 3404:&"{f6}{pound}{back arrow}39 {f6}{pound}{back arrow}39 {f6}{pound}{back arrow}39 {f6}{pound}{back arrow}39 {f6}"
' 3240 f$="i/setup 128":close 15:open 1,dv%,1,f$:s=ds:close15:ifsthen:&"{f6}Cannot find {quotation}{pound}$f{quotation}. Halting.{pound}w5":goto 4048
' ds=63: file exists
3240 f$="i/setup 128":close 15:rename (f$) to (f$):if ds<>63 then:&"{f6}Cannot find {quotation}{pound}$f{quotation}. Halting.{pound}w5":goto 4048
3242 new 4000:load f$,dv%:gosub 4000:return

' gosub from
3250 dr=3:a$="e.lightdefs,s,r":gosub 4:if e% then close 2:goto 3300
3252 z3$="Setting Default Checkmarks...":gosub 3404
3254 for x=. to 7:&,2,2:if len(a$)<>16 then:&"Lightbar defaults length error, page !x{f6}":goto 3258
3256 for i=1 to 16:&,52,x*16+i-1,val(mid$(a$,i,1)):next
3258 next:close 2

' FIXME: duplicate code
' restart log file
3300 dr=3:a$="e.log"+left$(lt$,1):gosub 4:if e%=. then return
3302 dr=3:a$="e.log"+left$(lt$,1):gosub 18:close 2:an$=d1$:&,15:d6$=an$
3304 a$=" LOG START: "+d6$+"{f6} {pound}q0{yellow}{pound}o{pound}o{f6}":gosub 51
3306 gosub 33:x=44:gosub 1:print#2,d6$:close 2
3308 gosub 30:for x=12 to 22:st(x)=.:gosub 17:next:return

' cmd clock set:
3348 z3$="Setting Clock by CMD Device...":gosub 3404:close 15:open 15,y%,15:print#15,"t-ra":&,2,15
3350 z$=left$(a$,2):a=-(z$="su")-2*(z$="mo")-3*(z$="tu")-4*(z$="we")-5*(z$="th")
3352 a=a-6*(z$="fr")-7*(z$="sa"):z$=mid$(str$(a),2,1)+mid$(a$,12,2)+mid$(a$,6,2)
3354 a=-80*(mid$(a$,24,1)="p")+val(mid$(a$,15,2))
3356 z$=z$+mid$(a$,9,2)+right$("0"+mid$(str$(a),2),2)+mid$(a$,18,2):poke1010,1:return

' ltk clock set:
3358 gosub 3364:sys 49155:goto 3362
3360 gosub 33:x=35:gosub 1:&,2,2:d1$=a$:close 2:poke 1010,1:return
3362 z$="":for a=49159 to a+10:z$=z$+chr$(peek(a)):next:poke 1010,1:return
3364 z$="Setting Clock by Lt.Kernal...":gosub 3404:dr=5:gosub 4:a$=dr$+"swr.ml":&,7,dv%,2:return
3366 gosub 3364:sys 49152:sys 49155:goto 3362

' TODO: use WINDOW command?
' based on fixed code in
' https://github.com/Pinacolada64/ImageBBS3/blob/master/core/tests/i.test%20frame.lbl

' &,69 [writestring] can't do special petscii characters like {$b0}
3400 z1$="":z2$="":s$="{space:36}":&,70,1,2:&"{gray2}{$b0}"+mid$(ak$,2,36)+"{$ae}"
3401 for i=3 to 4:&,70,1,i:&"{gray2}{$dd}{gray3}{rvrs on}{pound}$s{rvrs off}{gray2}{$dd}":next
3402 &,70,1,5:&"{gray2}{$ad}"+mid$(ak$,2,36)+"{$bd}":return

' scroll z1$ up, display z2$
' add trailing spaces after z2$

' NOTE: Immutable line number
' pass z3$ as new line of info to scroll
' scroll z1$ and z2$ up. z3$ is new line to display
' pad z2$ out with spaces
3404 z1$=z2$:c=$8f:z2$=left$(z3$+s$,34)
' display both z2$ and z3$, don't scroll
3405 &,69,3,3,z1$,c:&,69,3,4,z2$,c:return

' FIX: remove z=z+1 stuff. this does not delay 1/2 second on a SuperCPU system. use timer instead:
' 'i=not i' does not work

' i=color index (0=gray, 1=yellow)
3406 gosub {:sub.clear_lines}:i=1:&"1) Option 1{f6}2) Option 2{f6}3) Option 3{f6}{back arrow}) Abort{f6:2}Option: "

' NOTE: Immutable line number
' flash frame contents:
' t=ti, e=30 ('elapsed time': 1/2 second delay [30 jiffies], instead of continuously interpreting floating point)
3408 t=ti:e=t+30
3410 on peek(198) goto 3420:if ti<e then 3410
' jiffy delay has run out. toggle color index 'i' for new interior text color 'c':
' $87=rvs yellow, $8f=rvs gray3
3411 i=1-i:c=$87:if i then c=$8f
' draw interior text, reset jiffy delay
3412 gosub 3405:goto 3408
' &,69,<column>,<row>,<text>,<color>

' color index
' 5 c=1
' t=time, e=elapsed time (1/2 second, 30 jiffies)
' 10 t=ti:e=30
' an=non-zero when key is hit, check for expired timeout (elapsed jiffies>30)
' 20 on peek(198) goto 40:if ti<t+e then 20
' if so, toggle color index, print color and index value
' 30 c=1-c:printmid$("{yellow}{light gray}",c+1,1)c:goto 10
' key hit: read key buffer, convert to numeric value
' 40 get an$:print"key:"an$:lm=val(an$):if lm<1 and lm>3 then 20

' NOTE: Immutable line number
{:sub.clear_lines}
' clear screen lines 7-24 (0-based)
' reposition cursor on row 7, col 0
' TODO: clear line links?
' 3414 for i=6 to 23:&,70,.,i:&"{pound}{back arrow}38":next:&,70,.,6:return

3414 for i=7 to 24:&,69,0,i,s$+"   ":next:&,70,0,6:return

' key hit
3420 &"Fixme!":goto 4000

3500 data"Commodore 64","Commodore 128","Amiga","Apple/Comp."
3502 data"IBM/Comp.","Macintosh","Atari/ST","Tandy Series","Other Type"
3504 data"*","System","E-Mail","Etcetera","Directory","Plus-File","User"
' TODO: move these lines into i/setup 128:
' 3510 rem &"{f6}RS232 Interface Type:{f6}Enter 0 for User Port{f6}Enter 1 for SwiftLink/Turbo232{f6}> {pound}i1"
' 3512 rem a=val(an$):ifa<0ora>1then3510
' 3514 rem gosub 33:x=32:gosub 1:print#2,an$:close2:return
3999 rem copr. 2023 new image 8/14/2023

' error trap stuff
4000 &,38:cm$=cm$+"":p$=p$+"":pr$=pr$+"":p1$=p1$+"":p2$=p2$+""
' FIXME: 64789
' FIXME: mostly copy of 4048
4002 if x<128 then 4006:else a$="FATAL ERROR!!":gosub 51:sys 64789:print"{clear}{switchdisable}{white}{lowercase}{down:2}"a$:end
4004 &,38:&,61,.,8:print"&,37:goto 300:":end
4006 restore 4072
' 4008 read a$:if a$<>"errors" then 4008
' 4008 do until a$="errors":read a$:loop
4010 &,40:d$="GURU":if x>. and x<42 then for k=1 to x:read d$:next
4012 a%=x:&"{f6}{lt. red} SYSTEM ERROR #{pound}%a {white}({pound}$d ERROR){f6}":r$=chr$(13)
4014 a$="im":if el=>3000 then a$=pr$:if el=>4000 then a$=p1$:if el=>60000 then a$=p2$
4016 a=el:&"{lt. blue} In Line:{gray3}{pound}!a {lt. blue}Of {gray3}{pound}$a{f6}"
4018 &"{f6}{lt. red}Recording Error, Please Wait...":d$=str$(x)+" ("+d$+" ERROR)"
4020 dr=3:a$="e.errlog,s,a":gosub 4:if e%=. then 4024
4022 a$="e.errlog,s,w":gosub 4
4024 print#2,na$r$id;r$d1$r$ac%;r$ph$r$rn$r$co$(co%)r$
4026 print#2,"Error :"d$r$"Line  :"el;r$"Area  : "cm$r$"Prompt: "p$
4028 print#2,"Program: "pr$r$"Module: "p1$r$"Sub Module: "p2$
4030 print#2,"ML File: "ml$r$"Protocol: "d4$r$
4032 for i=1 to 10:a$=chr$(58-i):if hs$(i)<>"" then print#2," {uparrow}"a$": "hs$(i)
' FIXME: check right Dbg lightbar flag before color 4,3 to turn border red
4034 next:print#2,"^":close 2:rem &,52,x,3:if a% then color 4,3
4036 a$="User  : "+na$+r$+"Error :"+d$+r$+"Line  :"+str$(b)+r$+"Time  : {04}"+d1$+r$
4038 a$=a$+"Pfile : "+pr$+r$+"Area  : "+cm$+r$+".":remgosub 51
4040 close 2:&,37:for x=1 to 4:&,11,x:next:sy$="":sb$="":sg=.
4042 p2$="":is=.:p1$="":pr$="":ml$="":pr=-1:pf=.
' peek(2033) is carrst (modem carrier status)
4044 if ac%<>16 then:&,52,4,3:if a% or if (peek(2033) and 1)=. then 4050
4046 f1=2:goto 302
' FIXME: 64789
4048 a$="FATAL ERROR!!":gosub 51:sys 64789:print"{clear}{switchdisable}{white}{lowercase}{down:2}"a$:end
4050 &,52,4,3:if a% or i% or id=1 then 4068
' get sysop name:
4052 gosub 35:x=1:gosub 1:&,2,2:i1$=a$:close 2:kk=.:a$="s.errmail,s,r":dr=1:gosub 4:if e% then close 2:goto 4068
'    kk=kk+1:&,2,2:s=(64andst):tt$(kk)=a$:ifs=.then4054
4054 do while (64 and st)=.:kk=kk+1:&,2,2:tt$(kk)=a$:loop
4056 close 2:tt$=na$:a$="a":gosub 32:if e% then a$="w":gosub 32
4058 a$="[System Error ("+d$+")]":a=.:print#2,i1$r$1;r$d1$r$a$r$
4060 gosub 39:close 15
4062 gosub 30:i=1:x=14:gosub 16:x=25:gosub 16:x=32:gosub 16:close 2
4064 &"{pound}ho{pound}h9ed!{f6:2}{white}{$07}You Have New E-Mail Waiting:{f6:2}{green}Read Now? ":gosub 96
4066 if a then a$="E"+"M":goto 70
4068 pr$="":goto 300
' 30 errors in BASIC 2.0
' 41 errors in BASIC 7.0
' error strings also used in another module...
' 4070 data"errors"
' 1-3
4072 data"TOO MANY FILES","FILE OPEN","FILE NOT OPEN"
' 4-6
4074 data"FILE NOT FOUND","DEVICE NOT PRESENT","NOT INPUT FILE"
' 7-9
4076 data"NOT OUTPUT FILE","MISSING FILE NAME","ILLEGAL DEVICE NUMBER"
' 10-12
4078 data"NEXT WITHOUT FOR","SYNTAX","RETURN WITHOUT GOSUB"
' 13-15
4080 data"OUT OF DATA","ILLEGAL QUANTITY","OVERFLOW"
' 16-18
4082 data"OUT OF MEMORY","UNDEF'D STATEMENT","BAD SUBSCRIPT"
' 19-21
4084 data"REDIM'D ARRAY","DIVISION BY ZERO","ILLEGAL DIRECT"
' 22-24
4086 data"TYPE MISMATCH","STRING TOO LONG","FILE DATA"
' 25-27
4088 data"FORMULA TOO COMPLEX","CAN'T CONTINUE","UNDEFINED FUNCTION"
' 28-32
4090 data"VERIFY","LOAD","BREAK ","CAN'T RESUME","LOOP NOT FOUND"
' 33-35
4092 data"LOOP WITHOUT DO","DIRECT MODE ONLY","NO GRAPHICS AREA"
' 36-38
4094 data"BAD DISK","BEND NOT FOUND","LINE # TOO LARGE"
' 39-41
4096 data"UNRESOLVED REFERENCE","UNIMPLEMENTED COMMAND","FILE READ"
4098 rem copr. 1996 new image 5/6/96-jlf
4100 rem im (c)nissa 2020-09-29 lh-ad, 2023-08-14 rs
