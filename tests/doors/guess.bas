10 print "Guess the Number":print "(a plain BASIC 7.0 program)"
20 x=rnd(-ti):n=int(rnd(1)*100)+1:t=0
30 input "Your guess (1-100)";g:t=t+1
40 if g<n then print "Higher!":goto 30
50 if g>n then print "Lower!":goto 30
60 print "Got it in";t;"tries!"
70 print "Play again (Y/N)? ";:getkey k$:print k$
80 if k$="y" or k$="Y" then 20
90 print "Bye!"
