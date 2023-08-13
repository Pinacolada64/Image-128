#retrodevstudio.metadata.basic:7169,basic v7.0,lowercase,10,10
10 if a=0 then a=1:load"wedge 128",8,1
20 if ds=0 then print"ok"
30 if ds then print ds$:stop
40 sys dec("0c00"):print"wedge 128 enabled"
50 i=0:do until i=15:&:sleep 1:i=i+1:loop
60 sys dec("0c03"):print"wedge 128 disabled"
70 &:rem ignored
