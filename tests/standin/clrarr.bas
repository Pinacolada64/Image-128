1 rem &,11 (clear an array) on tt$(): its strings have to become garbage.
2 rem zeroed without that, they stayed "in use" with back-links to the
3 rem elements, which basic 7 then left behind when it moved the arrays (a
4 rem new variable), and its garbage collection wrote through them. run
5 rem tools/strcheck.py --port 6537 at the end: no damage. (i/lo-last's
6 rem tt$() lines, cleared by im's &,11 at line 82, then im's s=.)
10 dima$,a%,ac%,am,ag$,ak$,am$,an$,ao%
20 dimtt$(10),c%(3)
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
70 print chr$(147);"clrarr"
80 for i=1 to 8:tt$(i)="line"+str$(i):next
90 &,11,0
100 f=0:for i=1 to 8:if tt$(i)<>"" then f=f+1
110 next:print "after &,11,0: tt$() empty";f=0
120 zq=1:zr=2:x=fre(1):print "new variables, fre(1): ok"
130 for i=1 to 8:tt$(i)="new"+str$(i):next:x=fre(1)
140 for i=1 to 8:if tt$(i)<>"new"+str$(i) then f=f+1
150 next:if f=0 then print "done: run strcheck":end
160 print "failed";f:end
