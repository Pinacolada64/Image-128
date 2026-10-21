1 rem &,60,2/3: a struct saved from an array and loaded back. the arrays are in
2 rem bank 1, so load and save have to use bank 1 (setbnk): in bank 0, at
3 rem the same address, is the program text. shows "mismatches 0" and the
4 rem line after it
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 dim l%(15,30):for i=0 to 15:l%(i,1)=i*7+1:next
20 open 15,8,15,"s0:t.struct":close 15
30 &,60,3,0,l%(0,0),992,"0:t.struct",8
40 for i=0 to 15:l%(i,1)=0:next
50 &,60,2,0,l%(0,0),"0:t.struct",8
60 s=0:for i=0 to 15:if l%(i,1)<>i*7+1 then s=s+1
70 next:print "mismatches";s
80 print "program text intact"
90 goto 90
