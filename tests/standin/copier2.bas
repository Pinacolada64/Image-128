1 rem ++ 2 (copier 3.0's copier): sys protostart copies "++ menu2" to
2 rem t.copy; sys protostart+3 counts its bytes into t.count (3 bytes, low
3 rem first). "++ menu2" is 1514 bytes (with its load address). the blks:
4 rem counter is on row 21. then ++ copier's &,16,3 compares t.copy with
5 rem "++ menu2" (a%=0, b%=1514) and with "++ 2" (a%=1), its bytes: counter
6 rem on row 15; &,16,255 gives its protocol number, 2
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 print chr$(147)"++ 2 test":a$="0:++ 2":&,7,8,2
30 open 15,8,15,"s0:t.copy,t.count":close 15
40 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.copy,p,w":sys 7168:close 2:close 3
90 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.count,p,w":sys 7171:close 2:close 3
100 open 2,8,2,"0:t.count,p,r":get#2,a$,b$,c$:close 2
110 c=asc(a$+chr$(0))+256*asc(b$+chr$(0))+65536*asc(c$+chr$(0)):print "count";c
120 a$="0:++ copier":&,7,8,2:a%=0:&,16,255:v=a%:print "protocol";v
130 print chr$(19);:for i=1 to 15:print:next:print " Good: 00000  Bad: 00000  Bytes: 000000";
140 print chr$(19);:print:print:print:print
150 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.copy,p,r":a%=9:b%=0:&,16,3:close 2:close 3
160 s=a%:n=b%:print "same:";s;n;"bytes"
170 open 3,8,3,"0:++ 2,p,r":open 2,8,2,"0:t.copy,p,r":a%=9:b%=0:&,16,3:close 2:close 3
180 d=a%:print "differ:";d;"at byte";b%
190 if s=0 and n=1514 and d=1 and c=1514 and v=2 then print "all passed":end
200 print "failed":end
