{loadaddr:$2001}
' start of basic is now $2001 after "bank init.bas" has been run
10 bload"string-input.obj",b15,p3328:rem $0d00
20 if ds then print ds$:stop
30 a$="1234567890"+chr$(29)+chr$(157)+chr$(20)+chr$(148):rem allowed keys
40 scnclr:sys dec("0d00"),20,10,5,0,a$,r$
50 print:print "you entered: "r$
60 print "its length is"len(r$)
80 end
90 scratch"string-input.bas":dsave"string-input.bas"

' sys dec("0d00"), length, line, column, 0, allowstring, returnstring
' means for example:
' the maximal input length is 20 characters
' the input should start at column 5 of line 10
' only the characters contained in a$ are allowed
' and the input itself should be returned in r$ (do not forget in the definition of a$ to include the editor keys).
