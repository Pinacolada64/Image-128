1 rem ++ 2 (copier 3.0's copier): sys protostart copies "++ menu2" to
2 rem t.copy, compared byte for byte after; sys protostart+3 counts its
3 rem bytes into t.count (3 bytes, low first). "++ menu2" is 1514 bytes
4 rem (with its load address). the blks: counter is on row 21
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 print chr$(147)"++ 2 test":a$="0:++ 2":&,7,8,2
30 open 15,8,15,"s0:t.copy,t.count":close 15
40 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.copy,p,w":sys 7168:close 2:close 3
50 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.copy,p,r":n=0:f=0
60 get#3,a$:s=st:get#2,b$:if a$<>b$ then f=f+1
70 n=n+1:if s=0 then 60
80 close 2:close 3:print "copied";n;"bytes,";f;"differ"
90 open 3,8,3,"0:++ menu2,p,r":open 2,8,2,"0:t.count,p,w":sys 7171:close 2:close 3
100 open 2,8,2,"0:t.count,p,r":get#2,a$,b$,c$:close 2
110 c=asc(a$+chr$(0))+256*asc(b$+chr$(0))+65536*asc(c$+chr$(0)):print "count";c
120 if f=0 and n=1514 and c=1514 then print "all passed":end
130 print "failed":end
