1 rem the vdc cursor in the output colour: after red "x" with &, the cell
2 rem under the cursor (row 0, column 1) gets the current attribute, so the
3 rem cursor shows red. the monitor reads vdc attribute $0801 while &,1
4 rem waits for a line (cursor on). 80 columns only.
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 &chr$(147)+chr$(28)+"x"
20 poke 2816,1:&,1
30 goto 30
