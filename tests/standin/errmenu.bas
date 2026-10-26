1 rem an error inside &,16,0 (++ menu2 adding an item to an m%() element out
2 rem of range), caught by image's trap (&,37) at line 2000, which then does
3 rem what im's 2000-2002 do: peek 6-8 for the error and line, mci off, and
4 rem an & line with \!x. then the same with a plain basic ?bad subscript.
10 dima$,a%,ac%,am,ag$,ak$,am$,an$,ao%
11 dimb$,b%,bd,bd$,bn$,bu
12 dimc$,c%,c1$,c2$,c3$,ca,cc,cc$,cd%,ch$,cm$,cn,co$,co%,cr,ct,ct%
13 dimd$,d%,d1$,d1%,d2$,d2%,d3%,d3$,d4$,d5$,d6$,da%,db%,dc,dc%,dd$,df%,dr,dr$,dv%
14 dime$,e%,e1,em,ef$,ep$,ec,ec%
15 dimf$,f%,f1,f2,f3,f4,ff$,fl,fl$,f1$,f2$,f3$,f4$,f5$,f6$,f7$,f8$
16 dimg$,g%
17 dimh$,h%,hx$
18 dimi$,i%,id,im$,im,in$,is
19 dimj$,j%
20 dimk$,k%,kk,kp%
21 diml$,l%,l1,l1$,l2,l2$,l3,l3$,lc,ld$,le,lf,lk%,ll$,ll%,lm$,lp,lt$,lt%,lw,lz$
22 dimm$,m%,mc,mf,ml$,mp$,mt$,mw,mp%,mn%
23 dimn$,n%,na$,nc,nf,nl,nl$,nm,nm$
24 dimo$,o%
25 dimp$,p%,p1%,p2%,p3%,pf,ph$,pl,pm,po$,pp$,pr,pr$,ps,pu$,pw$,p1$,p2$
26 dimq$,q%,qb,qe,qt$
27 dimr$,r%,rc,rn$,rp,rq
28 dims$,s%,sa%,sh,sg,sw
29 dimt$,t%,t1,tc%,tf,tk$,tr%,tt,tt$,tz$
30 dimu$,u%,uc,uh,ul,ur,uf$,uu$
31 dimv$,v%
32 dimw$,w%
33 dimx$,x%
34 dimy$,y%
35 dimz$,z%,zz
60 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
70 a$="0:++ menu2":&,7,8,2
80 dim m%(22,2):print chr$(147);"errmenu":t=1:&,37
90 print "test 1: bad subscript inside &,16,0"
100 &,16,0,46,m%(0,9),"a","","an item"
110 print "test 1: no error?":goto 300
200 print "test 2: the same with files 15 and 2 open, as i.uu has"
205 open 15,8,15:open 2,8,2,"boot 128,p,r"
210 &,16,0,46,m%(0,9),"a","","an item"
220 print "test 2: no error?":goto 300
300 print "done":end
2000 x=peek(6):y=peek(7)+peek(8)*256:print "trap: peek(6)=";x;"line=";y;"open:";peek(152)
2001 for i=2 to peek(152):close peek(868):next
2002 x=peek(6):y=peek(7)+peek(8)*256:print "after closes: peek(6)=";x;"line=";y;"open:";peek(152)
2003 poke 6350,0:&"[Error#\!x, Line#\!y]"+chr$(13)
2004 print "test";t;"survived the & line"
2006 t=t+1:if t=2 then:&,37:goto 200
2008 goto 300
