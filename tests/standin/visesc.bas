1 rem ++ visual's esc i and esc d (11/15/2026), driven by tools/visesc.py:
2 rem the text is line 1 to line 30, line 28 blank. 2817 1: ready, the
3 rem script pokes vesc's value in 2818 (0 the rows drawn again, 1 the
4 rem 128's own esc codes) and 2816 1; ++ visual then runs (&,16,1) while
5 rem the script types its keys. after ctrl-x: mline and each line's number
6 rem ("-" blank) printed, 2817 2
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53248,1:dim tt$(254)
110 a$="0:++ visual":&,7,8,2:poke 6338,99
120 for i=1 to 30:tt$(i)="line"+str$(i):next:tt$(28)=""
130 poke 2816,0:poke 2817,1
140 if peek(2816)=0 then 140
150 poke 6332,31:poke 7174,peek(2818):&,18,0:&,16,1
160 m=peek(6332):print chr$(147);"mline";m
170 for i=1 to m-1:a$=tt$(i):b$="-":j=instr(a$,"e "):if j then b$=mid$(a$,j+2)
180 print b$;" ";:if i/10=int(i/10) then print
185 next:print:poke 2817,2
190 goto 190
