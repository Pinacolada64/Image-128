1 rem copies the files that ltkcopy.list names from its own disk (a 1581
2 rem at device 9) onto an lu of the lt. kernal (device 8), as
3 rem ltkinstall.bas does: an old copy scratched, ++ copier, then a
4 rem compare. ltkcopy.list: the lu, then one file a line, its type
5 rem letter (p, s or u) first. run by tools/ltk_copy.py
6 rem the list is read and closed before any copy, so no file of the
7 rem 1581's is open but the one being copied
58 rem the result for ltk_copy.py at $0b00-$0b02 (2816): files copied,
59 rem failed, then 1 when done (the screen's text can be drawn over)
60 poke 2818,0:sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 d=8:s=9:x=0:n=0:eo=0:f$="":dim l$(255)
80 a$="0:++ copier":&,7,9,2
90 open 4,s,4,"0:ltkcopy.list,s,r":gosub 600:u$=l$+":"
95 gosub 600:if l$<>"" then n=n+1:l$(n)=l$:goto 95
96 rem output in rows 16-23: ++ copier draws rows 2-8 and 15, the header 0-1
97 close 4:window 0,16,39,23,1:print "copy to lu ";u$:open 14,s,15
98 rem 14: the 1581's command channel, open throughout (closing it closes
99 rem #3 too); 15, the lt. kernal's, opened with each scratch
100 for i=1 to n:l$=l$(i)
110 c$=left$(l$,1):q$=mid$(l$,2):y$=",p":if c$="s" then y$=",s"
115 if c$="u" then y$=",u"
116 rem 11/18/2026: "source=dest" copies the 1581's source to dest on the lu
117 r$=q$:k=instr(q$,"="):if k then r$=mid$(q$,k+1):q$=left$(q$,k-1)
120 open 15,d,15,"s"+u$+r$
125 open 3,s,3,"0:"+q$+y$+",r":input#14,e,e$:if e>=20 then f$=f$+q$+" on the 1581:"+str$(e)+" "+e$+chr$(13):x=x+1:close 3:close 15:goto 290
130 open 2,d,2,u$+r$+y$+",w":input#15,e,e$:if e>=20 then f$=f$+q$+str$(e)+" "+e$+chr$(13):x=x+1:close 2:close 3:close 15:goto 290
140 &,16,0:close 2:close 3:close 15
150 open 3,s,3,"0:"+q$+y$+",r":open 2,d,2,u$+r$+y$+",r":a%=9:&,16,3:close 2:close 3:if a% then f$=f$+q$+" differs at byte"+str$(b%)+chr$(13):x=x+1:goto 290
160 print i;r$
290 next
300 close 14:print chr$(147);"copied";n;"files,";x;"failed":print f$
310 poke 2816,n:poke 2817,x:poke 2818,1:end
600 l$="":if eo then return
610 get#4,a$:eo=st and 64:if a$=chr$(13) then return
620 l$=l$+a$:if eo then return
630 goto 610
