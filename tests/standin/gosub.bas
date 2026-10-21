1 rem &,66,1: a gosub from the ml to line a%, 50 times in a loop. its frame
2 rem has to be on basic 7.0's stack ($7d) for return to find it, and the &
3 rem call's own frames have to leave the cpu stack. shows "back 50" and the
4 rem basic stack empty again (2559, $09ff)
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
6 &chr$(147)
10 s=0:a%=100:for i=1 to 50:&,66,1:next:print "back";s;"stack";peek(125)+peek(126)*256
20 goto 20
100 s=s+1:return
