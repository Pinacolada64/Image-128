1 rem the setup's u.config write (sub.su.write 60020) alone: a new rel file
2 rem of 254-byte records, positioned as im line 1 does (record#, &,22,1,
3 rem record# again), a 150-character record written, then a second one.
4 rem prints a step number before each step: the last one shown is where it
5 rem stops
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 56328,0
20 print chr$(147);"rel write test"
30 open 15,8,15,"s0:t.rel":close 15
40 print "1 open":open 15,8,15:open 2,8,2,"0:t.rel,l,"+chr$(254)
50 print "2 record 1":record#2,1,1
60 print "3 tenwait":&,22,1
70 print "4 record 1 again":record#2,1,1
80 t$="":for i=1 to 15:t$=t$+"abcdefghij":next
90 print "5 print#":print#2,t$
100 print "6 record 2":record#2,2,1:&,22,1:record#2,2,1
110 print "7 print# 2":print#2,"^"
120 print "8 close":close 2:input#15,e,e$:close 15
130 print "status";e;e$
140 if e=0 then print "all passed":end
150 print "failed":end
