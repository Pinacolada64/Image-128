1 rem usr(0): the wedge's wfunc0, the cpu stack pointer (0-255), through
2 rem the 128's usr vector ($1219). before, ?illegal quantity error
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 a%=usr(0):print "usr(0) ="a%
20 bank 1:x=peek(16384):bank 15:print "bank ok"
30 print "iescex"peek(784)+256*peek(785)
40 goto 40
