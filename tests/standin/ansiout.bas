1 rem what outmod (asm/modem.asm) sends a caller in ascii + ansi colour
2 rem (flags 16 and 18), through the swiftlink: tools/ansiout.py listens
3 rem (ip232) and records the bytes. each character goes straight to outmod
4 rem (&,51 with it in $fe: modem only, no carrier or time checks, which
5 rem & output adds before it). each test is its byte(s) between "<" and ">".
6 rem 2817 1 once the driver is up (the script then pokes 2816 1), 2 at the end
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
100 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
110 a$="0:ml.rs232":&,7,8,2:&,16,1
120 open 131,2,134,chr$(6)
130 poke 2816,0:poke 2817,1
140 if peek(2816)=0 then 140
150 &,52,16,1:&,52,18,1:&,52,19,0
160 read n:for i=1 to n:read c:a$="<"+chr$(c)+">":gosub 500:next
170 a$="<"+chr$(27)+"["+chr$(204)+">":gosub 500
180 a$="<"+chr$(27)+"[2"+chr$(203)+">":gosub 500
190 &,52,16,0:&,52,18,0:poke 2817,2
200 goto 200
300 data 14,13,145,17,29,157,19,147,18,146,28,5,20,13,27
500 for j=1 to len(a$):poke 254,asc(mid$(a$,j,1)):&,51:next:return
