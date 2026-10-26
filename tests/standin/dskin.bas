1 rem &,2,2 (dskin) gives a$ as a string of its own: g$=a$, h$=a$, u$=a$
2 rem after three reads keep three lines (before, a$ pointed at buf2 and
3 rem they all showed the last line read), through garbage collections
4 rem and many more reads. im's variables first, in its order.
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
70 print chr$(147);"dskin":f=0
80 open 15,8,15,"s0:t.lines":open 2,8,2,"t.lines,s,w"
90 print#2,"alpha":print#2,"beta":print#2,"gamma 12345":close 2
100 open 2,8,2,"t.lines,s,r":&,2,2:g$=a$:&,2,2:h$=a$:&,2,2:u$=a$:close 2
110 print "read:";g$;"/";h$;"/";u$:gosub 500
120 x=fre(1):print "after fre(1):";g$;"/";h$;"/";u$:gosub 500
130 dim z$(150):for i=1 to 150:open 2,8,2,"t.lines,s,r":&,2,2:&,2,2:z$(i)=a$+str$(i):close 2:next
140 x=fre(1):print "after 150 reads:";g$;"/";h$;"/";u$:gosub 500
150 for i=1 to 150:if z$(i)<>"beta"+str$(i) then print "z$(";i;")=";z$(i):f=f+1:i=150
160 next
170 close 15:if f=0 then print "all passed":end
180 print "failed";f:end
500 if g$<>"alpha" or h$<>"beta" or u$<>"gamma 12345" then print "  wrong":f=f+1
510 return
