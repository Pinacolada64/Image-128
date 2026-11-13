1 rem ++ chatmode (asm/chatmode.asm) on a lt. kernal: run by
2 rem tools/ltk_chatmode.py, the stand-in on a 1581 at device 9, the lt.
3 rem kernal at 8 (vice's emulation, its config set to boot 128 mode).
4 rem the first &,16 makes chatfile (1; 0 if it's there already) and
5 rem shows its empty first block; the second finds it (0). then the lt.
6 rem kernal's directory of lu 10, user 0 shows the file
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 print chr$(147);"++ chatmode":p=7171:f=0
80 a$="0:++ chatmode":&,7,9,2
90 &,16:a=peek(p):b=peek(p+1):print:print "first";a;b
100 &,16:c=peek(p):d=peek(p+1):print:print "second";c;d
110 if a>1 or c<>0 or d<>1 then f=1
120 open 1,8,0,"$chatfile":get#1,x$,x$
130 get#1,x$,x$:if st then 160
140 get#1,x$,y$:n=asc(x$+chr$(0))+256*asc(y$+chr$(0)):print n;
150 get#1,x$:if x$<>"" then print x$;:goto 150
155 print:goto 130
160 close 1
170 if f=0 then print "all passed":end
180 print "failed":end
