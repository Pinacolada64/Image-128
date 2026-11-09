1 rem (40 columns: rows 2-23 poked full of letters, row r of letter r)
2 rem the 128 screen editor's esc sequences through & output (shdlr.asm
3 rem passes esc to the editor, 11/05/2026), after &,70 puts the cursor:
4 rem rows 2-23 poked full, then esc @ at row 6
5 rem (clear to the end of the window), then esc q at row 3 column 5 (to the
6 rem end of the line). waits at each step for the test to poke 2816
10 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60:poke 56328,0
20 print chr$(147);:for r=2 to 23:for c=0 to 35:poke 1024+r*40+c,r:&,72,r,c:next:next
25 poke 2816,0:poke 2817,9
26 if peek(2816)=0 then 26
30 poke 2816,0:&,70,0,6:a$=chr$(27)+"@":&:poke 2817,1
40 if peek(2816)=0 then 40
50 poke 2816,0:&,70,5,3:a$=chr$(27)+"q":&:poke 2817,2
60 if peek(2816)=0 then 60
70 &,70,0,8:&"after - & still prints here":poke 2817,3
80 if peek(2816)=0 then 80
90 &,70,0,10:&"all passed":end
