{loadaddr:$2000}
10 bload"string-input.obj",b0,p3328:rem $0d00
20 if ds then print ds$:stop
' start of basic is now $2000
30 a$="1234567890"+chr$(29)+chr$(157)+chr$(20)+chr$(148)
40 bank 0:sys dec("0d00"),20,10,5,0,a$,r$
50 print"you entered: "r$:end
60 scratch"string-input.bas":dsave"string-input.bas"

' sys dec("0d00"), length, line, column, 0, allowstring, returnstring
' means for example:
' the maximal input length is 20 characters
' the input should start at column 5 of line 10
' only the characters contained in a$ are allowed
' and the input itself should be returned in r$ (do not forget in the definition of a$ to include the editor keys).
