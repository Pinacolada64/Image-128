1 rem function key macros: ctrl or c= with f1/f3/f5/f7 types f1$-f8$ into the input.
2 rem fkey finds f1$-f8$ by their offsets in im's variables, so dim them in im's order
3004 dima$,a%,ac%,am,ag$,ak$,am$,an$,ao%
3006 dimb$,b%,bd,bd$,bn$,bu
3008 dimc$,c%,c1$,c2$,c3$,ca,cc,cc$,cd%,ch$,cm$,cn,co$,co%,cr,ct,ct%
3010 dimd$,d%,d1$,d1%,d2$,d2%,d3%,d3$,d4$,d5$,d6$,da%,db%,dc,dc%,dd$,df%,dr,dr$,dv%
3014 dime$,e%,e1,em,ef$,ep$,ec,ec%
3016 dimf$,f%,f1,f2,f3,f4,ff$,fl,fl$,f1$,f2$,f3$,f4$,f5$,f6$,f7$,f8$
3018 dimg$,g%
3020 dimh$,h%,hx$
3022 dimi$,i%,id,im$,im,in$,is
3024 dimj$,j%
3026 dimk$,k%,kk,kp%
3028 diml$,l%,l1,l1$,l2,l2$,l3,l3$,lc,ld$,le,lf,lk%,ll$,ll%,lm$,lp,lt$,lt%
3030 dimm$,m%,mc,mf,ml$,mp$,mt$,mw,mp%,mn%
3032 dimn$,n%,na$,nc,nf,nl,nl$,nm,nm$
3034 dimo$,o%
3036 dimp$,p%,p1%,p2%,p3%,pf,ph$,pl,pm,po$,pp$,pr,pr$,ps,pu$,pw$,p1$,p2$
3038 dimq$,q%,qb,qe,qt$
3040 dimr$,r%,rc,rn$,rp,rq
3042 dims$,s%,sa%,sh,sg,sw
3044 dimt$,t%,t1,tc%,tf,tk$,tr%,tt,tt$,tz$
3046 dimu$,u%,uc,uh,ul,ur,uf$,uu$
3048 dimv$,v%
3050 dimw$,w%
3052 dimx$,x%
3054 dimy$,y%
3056 dimz$,z%,zz
3100 sys 7171:poke 2794,0:poke 2787,1:poke 53252,60
3102 f1$="[ctrl f1]":f2$="[c= f1]":f3$="[ctrl f3]":f4$="[c= f3]"
3104 f5$="[ctrl f5]":f6$="[c= f5]":f7$="[ctrl f7]":f8$="[c= f7]"
3106 &chr$(147)+"fkey macro test"+chr$(13)+chr$(13)
3108 &"ctrl or c= with f1/f3/f5/f7 types a macro; return ends a line"+chr$(13)+chr$(13)
3110 do
3112 &"> ":&chr$(92)+"i1":&chr$(13)+"you typed: "+an$+chr$(13)
3114 loop
