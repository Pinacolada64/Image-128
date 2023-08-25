10 bload"bank init.obj",b15,p3072:rem $0c00
20 sys dec("0c00")
30 poke dec("2e"),dec("20"):poke dec("2000"),0:poke dec("30"),dec("20")
40 print "memory from $0000-$1000 is now common."
50 print "returning from either bank 0 or bank 1"
60 print "will have this memory available."
70 print:print "basic now starts at $2001."
80 clr:new
90 scratch"bank init.bas":dsave"bank init.bas"
' start of basic is now $2001
