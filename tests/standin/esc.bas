1 rem the 128 screen editor's esc sequences through & output (shdlr.asm
2 rem passes esc and its letter to the editor's print, 11/05/2026). for
3 rem each test: rows 2-7 "1abcdefghij".."6abcdefghij", image's cursor to
4 rem row 4 column 4 (&,70), es$ and the letter, then "*", so where the
5 rem cursor went shows. tools/esctest.py reads the screen at each step:
6 rem 2817 is the step (test number, +100 with the mask on), the program
7 rem waits until the driver pokes 2816. the tests, then again with the
8 rem screen mask on (&,18,1). esc t/b: a window rows 3-5 (t at row 3, b at
9 rem row 5), then "w1".."w4" on lines of their own, reset by printing two
10 rem homes through the editor (image's own home doesn't reach it)
20 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 56328,0
30 es$=chr$(27):m=0
40 restore:for t=1 to 11:read l$
50 &chr$(147):&,70,0,0:&"esc "+l$+" (test"+str$(t)+", mask"+str$(m)+")"
60 for r=1 to 6:&,70,0,r+1:&mid$(str$(r),2)+"abcdefghij":next
70 &,70,4,4:if l$="tb" then 200
80 a$=es$+l$:&:&"*"
90 poke 2816,0:poke 2817,t+100*m
100 if peek(2816)=0 then 100
110 next
120 if m=0 then m=1:&,18,1:goto 40
130 &,18,0:&chr$(147):&"all done":poke 2817,255:end
200 &,70,4,3:a$=es$+"t":&:&,70,4,5:a$=es$+"b":&
210 &,70,0,3:for w=1 to 4:&"w"+mid$(str$(w),2)+chr$(13):next
220 print chr$(19);chr$(19);:goto 90
300 data q,p,@,j,k,i,d,v,w,o,tb
