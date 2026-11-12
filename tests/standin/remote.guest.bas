10 print "guest";
20 a$="abc":b=5:dim c(10):c(3)=7:x$=""
30 for i=1 to 3:gosub 100:next
40 read d$:print " data ";d$
50 for i=1 to 300:x$=x$+"z":if len(x$)>50 then x$=""
60 next
70 input "name";n$
80 open 9,8,9,"0:t.gfile,s,w":print#9,n$
90 print "guest end";b;c(3);d$:end
100 print i;:return
200 data gd
