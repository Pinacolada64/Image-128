#RetroDevStudio.MetaData.BASIC:7169,BASIC V7.0,uppercase,10,10
10 print"label     offset  $addr size"
20 ad=2816:do until lb$="x":read lb$,of:print lb$tab(10):print using"+#####";of;
30 print"  $"hex$(ad+of)"  ";:if ad+of>1 then print of-po;:else print"---";
32 print:po=of:loop
50 data cassbuff,0
52 data datebuf,2
54 data daytbl,14
56 data tzoneh,38
58 data wrapflg,122
60 data montbl,145
62 data emptym1,181
64 data temp3,187
66 data lines,194
99 data x,0
100 rem calculate addresses and offsets in cassette buffer for image bbs 128
110 rem ad=address
120 rem of=offset into table
130 rem po=previous offset (used for size display)
