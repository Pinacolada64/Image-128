1 rem i/lo/ns 4016-4018 (11/09/2026): a netsub's nodes from an$, as ++ netlist's
2 rem &,16 gives them (3 characters a node, padded with -), not peek(49707) (the
3 rem c64's $c22b). a definition with three nodes is put in (&,16,1), read back
4 rem (&,16), and its nodes listed as i/lo/ns lists them: ONE TWO THR
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53248,1:dim a%(61)
110 a$="0:++ netlist":&,7,8,2
120 a$="TEST NETSUB":an$="ONETWOTHR":for i=1 to 39:an$=an$+"-":next:a%(0)=1:a%(1)=5:&,16,1
130 a$="":an$="":&,16:print a$:print an$
140 n$="":for j=1 to 46 step 3:b$=mid$(an$,j,1):if b$<"A" or b$>"Z" then j=46:goto 160
150 n$=n$+mid$(an$,j,3)+" "
160 next j:print "nodes: ";n$
170 if n$="ONE TWO THR " and a$="TEST NETSUB" then print "all passed":print "done":end
180 print "failed":print "done":end
