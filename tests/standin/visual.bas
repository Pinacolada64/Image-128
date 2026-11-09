1 rem ++ visual (asm/visual.asm): loaded with &,7 and started with &,16,0
2 rem (a new text). the script types hello, ctrl-v (the next page), page
3 rem two, ctrl-y (back: hello again, unpacked), ctrl-v, ctrl-x (x=1); then
4 rem &,16,2 (back where it left off: page 2): return, .l and return (a dot
5 rem command: x=4, l in viscmd, the line emptied); &,16,2 and ctrl-x. then
6 rem mline (the line after the last): 25; hello on 1, page two on 24
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
110 a$="0:++ visual":&,7,8,2:poke 6338,99:&,16,0:x1=peek(7)
115 &,16,2:x2=peek(7):v=peek(6558):&,16,2:x3=peek(7)
120 m=peek(6332):print chr$(147);"mline";m;"x";x1;x2;x3;"viscmd";v
130 for i=1 to m-1:a$=tt$(i):if a$="" then 170
140 b$="":for j=1 to len(a$):c=asc(mid$(a$,j,1)):if c>31 and c<128 then b$=b$+chr$(c)
150 next:print i;len(a$);b$:if i=1 then h$=b$
160 if i=24 then p$=b$
170 next
180 if m=25 and x1=1 and x2=4 and x3=1 and v=76 and h$="hello" and right$(p$,8)="page two" then print "all passed":print "done":end
190 print "failed":print "done":end
