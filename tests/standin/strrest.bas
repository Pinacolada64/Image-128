1 rem &,15,6 (strscan, strrest) while garbage collections happen: 200
2 rem strings in tt$(), then 3000 splits of a directory-like line with
3 rem garbage made around them; each split's name and every tt$() checked.
4 rem before 11/08/2026 strrest made its string with makeroom inside the &
5 rem call, and a collection there changed strings and gave ?syntax errors
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53248,1:print chr$(147)"strrest"
110 dim tt$(200):for k=1 to 200:tt$(k)="entry"+str$(k):next:b=0:q$=chr$(34)
120 for j=1 to 15:for k=1 to 200
130 an$=" 12   "+q$+"file"+str$(k)+q$+"   prg":&,15,6,34:&,15,6,34:n$=a$
140 if n$<>"file"+str$(k) then b=b+1:if b<4 then print "split";j;k;n$
150 g$=str$(rnd(1))+str$(k):h$=g$+g$:next:print ".";:next:print
160 for k=1 to 200:if tt$(k)<>"entry"+str$(k) then b=b+1:print "tt$";k;tt$(k)
170 next:print "bad";b:if b=0 then print "all passed":end
180 print "failed":end
