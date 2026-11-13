1 rem ++ ltk clock (asm/ltk_clock.asm), the ds1216 smartwatch reader. vice
2 rem has no such clock on a control port, so: &,16,0 turns clock values
3 rem poked into its registers (+20 on: 26-11-12, thursday, 07:30) into the
4 rem date (+7 on) for each awkward hour (midnight, noon, 1 pm, 8-11 pm);
5 rem &,16,1 and &,16,2 with nothing there must come back with cia 1's
6 rem data directions ($dc02, $dc03) as they were
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 print chr$(147);"++ ltk clock":p=7168:f=0
80 a$="0:++ ltk clock":&,7,8,2
90 data 38,17,18,5,0,7,48,0
92 data 0,"12",9,"09",18,"92",19,"81",32,"88",33,"89",34,"90",35,"91",-1,""
100 for i=0 to 7:read r:poke p+20+i,r:next
110 read h,e$:if h<0 then 200
120 poke p+24,h:&,16,0:z$="":for i=7 to 19:z$=z$+chr$(peek(p+i)):next
130 t$="hour"+str$(h)+" "+z$:ok=z$="5261112"+e$+"0730":gosub 900:goto 110
200 a=peek(56322):b=peek(56323):&,16,1:c=peek(56322):d=peek(56323):&,16,2
210 t$="no clock: ddr"+str$(a)+str$(b)+str$(c)+str$(d)+str$(peek(56322))+str$(peek(56323))
220 ok=a=c and b=d and a=peek(56322) and b=peek(56323):gosub 900
230 print "port 2 read: ";:for i=7 to 17:print chr$(peek(p+i));:next:print
800 print:if f=0 then print "all passed":end
810 print f;"failed":end
900 if ok then print "pass ";t$:return
910 print "fail ";t$:f=f+1:return
