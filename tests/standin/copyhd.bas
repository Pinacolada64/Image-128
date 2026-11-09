1 rem ++ copier between two drives: ml.low (31 blocks) from the 1581 on
2 rem device 8 to the cmd hd on device 9 (partition 1) with &,16,0, then
3 rem &,16,3 compares them (a%=0: the same; b% the bytes compared, low 16
4 rem bits). before 11/07/2026 the copy stopped after a few blocks and the
5 rem compare at byte 1 (a status bit left by the other drive)
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 print chr$(147)"copy to the hd":a$="0:++ copier":&,7,8,2
30 open 15,9,15,"s1:t.copy":close 15
40 open 3,8,3,"0:ml.low,p,r":open 2,9,2,"1:t.copy,p,w":&,16,0:close 2:close 3
50 open 3,8,3,"0:ml.low,p,r":open 2,9,2,"1:t.copy,p,r":a%=9:b%=0:&,16,3:close 2:close 3
60 s=a%:n=b%:print "compare:";s;n;"bytes"
70 if s=0 and n=7844 then print "all passed":end
80 print "failed":end
