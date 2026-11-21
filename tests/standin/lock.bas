1 rem &,13 (arbit): the lt. kernal's locks between stations. run on two
2 rem x128s (ports 0 and 1) by tools/ltk_lock.py, which pokes the steps
3 rem into $0b00 (2816), and the address of ltkflag (glue.asm; ltkport
4 rem after it) into $0b02/$0b03. station a (port 0) takes lock 3 twice
5 rem and gives it back one step at a time; station b waits for it; then a
6 rem takes lock 5 and is stopped (a crash), and b gets 5 once a has
7 rem booted again (lockinit frees a station's locks from before)
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 53248,1
70 poke 2816,0:print chr$(147);"&,13 locks"
80 if peek(2816)=0 then 80
90 a=peek(2818)+256*peek(2819):f=peek(a):p=peek(a+1)-128:print "lt. kernal";f;"port";p
100 if f=0 then print "no lockfile":end
110 if p then 300
210 &,13,1,3:&,13,1,3:print "a has 3 twice"
220 if peek(2816)<2 then 220
230 &,13,2,3:print "a gave 3 back once"
240 if peek(2816)<3 then 240
250 &,13,2,3:print "a gave 3 back"
260 if peek(2816)<4 then 260
270 &,13,1,5:print "a has 5"
280 goto 280
300 print "b waits for 3":&,13,1,3:print "b has 3":&,13,2,3:print "b gave 3 back"
320 if peek(2816)<2 then 320
330 print "b waits for 5":&,13,1,5:print "b has 5":&,13,2,5:print "all done"
