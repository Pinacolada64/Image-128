1 rem the lightbar's mhz checkmark (flag 62: chktbl+7, $1307, bit 6) follows
2 rem the cpu's speed ($d030 bit 0) within an irq pass: fast, slow, and a
3 rem checkmark set by hand (&,52,62,1) put back by the next pass. 80 columns
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
20 print chr$(147);"mhz checkmark":f=0
30 fast:gosub 900:t$="fast: checkmark on":ok=m=64:gosub 800
40 slow:gosub 900:t$="slow: checkmark off":ok=m=0:gosub 800
50 &,52,62,1:gosub 900:t$="set by hand at 1 mhz: off again":ok=m=0:gosub 800
60 fast:&,52,62,0:gosub 900:t$="cleared by hand at 2 mhz: on again":ok=m=64:gosub 800
70 slow:gosub 900
80 if f=0 then print "all passed":end
90 print f;"failed":end
800 if ok then print "pass ";t$:return
810 print "fail ";t$:f=f+1:return
900 t=ti
905 if ti-t<60 then 905
910 m=peek(4871)and64:return
