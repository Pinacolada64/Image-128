1 rem &,66,1: a gosub from the ml to line a%, 50 times in a loop. its frame
2 rem has to be on basic 7.0's stack ($7d) for return to find it, and the &
3 rem call's own frames have to leave the cpu stack. shows "back 50" and the
4 rem basic stack empty again (2559, $09ff)
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:trap 2000
6 &chr$(147)
8 def fn sp(x)=peek(125)+peek(126)*256:rem stack pointer (a def fn returns a number)
10 s=0:a%=100:for i=1 to 50:print"gosub";a%;:&,66,1:next:print "back";s;", stack pointer: $";hex$(fn sp(0))
12 if s=i-1 then print"gosub count matches return count"
14 rem test trapping ?undef'd statement error
16 a%=500:&,66,1
18 print"Program end."
20 goto 20
100 s=s+1:l=peek(dec("3b"))+peek(dec("3c"))*256
110 print"in line"l;:if l<>a% then print"(mismatch)"
130 return
2000 print"error:"er" ("err$(er)"), in line"el
2010 resume next
