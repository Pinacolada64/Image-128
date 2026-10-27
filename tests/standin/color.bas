1 rem colour codes in & output: "r" red, "w" white, "c" cyan on the top row.
2 rem the monitor reads their colours: vic colour ram ($d800) in 40 columns,
3 rem vdc attributes ($0800) in 80. before the fix they stayed one colour:
4 rem sc9 stored the code's colour in image's mcolor, which nothing used.
5 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
10 &chr$(147)+chr$(28)+"r"+chr$(5)+"w"+chr$(159)+"c"+chr$(13)
20 poke 2816,1
30 goto 30
