1 rem copies image bbs 128's boot disk (a 1581 at device 10) onto lu 5 of
2 rem the lt. kernal (device 8), as
3 rem sub.su.copy copies a file: an old copy scratched, ++ copier, then a
4 rem compare. rel files and ones not closed are passed over. run by
5 rem tools/ltk_install.py, the stand-in on a 1581 at 9
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 d=8:s=10:u=5
75 u$=mid$(str$(u),2)+":":print chr$(147);"install on lu";u:n=0:x=0
80 a$="0:++ copier":&,7,9,2
90 dim n$(255),t$(255)
100 open 2,s,0,"$0":get#2,a$,a$:get#2,a$,a$:get#2,a$,a$:gosub 600
110 get#2,a$,b$:if (a$="" and b$="") or st then 200
120 get#2,a$,a$:gosub 600:if q$="" then 110
130 n=n+1:n$(n)=q$:t$(n)=y$:goto 110
200 close 2:print n;"files":open 15,d,15
210 for f=1 to n:q$=n$(f):c$=left$(t$(f),1):y$=",p":if c$="s" then y$=",s"
215 if c$="u" then y$=",u"
220 if c$="r" or c$="*" then 260
225 print#15,"s"+u$+q$
230 open 3,s,3,"0:"+q$+y$+",r":open 2,d,2,u$+q$+y$+",w":input#15,e,e$:if e>=20 then print q$;e;e$:x=x+1:close 2:close 3:goto 260
240 &,16,0:close 2:close 3
250 open 3,s,3,"0:"+q$+y$+",r":open 2,d,2,u$+q$+y$+",r":a%=9:&,16,3:close 2:close 3:if a% then print q$;" differs":x=x+1
255 print f;q$
260 next:close 15:print chr$(147);"installed";n;"files,";x;"failed":end
600 l$=""
610 get#2,a$:if a$<>"" and st=0 then l$=l$+a$:goto 610
620 i=instr(l$,chr$(34)):q$="":y$="":if i=0 then return
630 j=instr(l$,chr$(34),i+1):if j=0 then return
640 q$=mid$(l$,i+1,j-i-1):y$=mid$(l$,j+1):k=1
650 if mid$(y$,k,1)=" " then k=k+1:goto 650
660 y$=mid$(y$,k,3):return
