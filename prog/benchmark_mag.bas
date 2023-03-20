100 REM	-------------------------------------
101 REM	Simple benchmark - find primes < 1000
103 REM	-------------------------------------
104 REM https://archive.org/details/InterfaceAge198006/page/n131/mode/2up
105 REM	SW210	CPU (MHz) Result (s)
106 REM   100	01.5625
107 REM	  101 	03.1250
108 REM   110 	06.2500
109 REM	  111 	25.0000 4m13s 253s
110 REM	-------------------------------------
130 PRINT "Starting."
140 FOR N = 1 TO 1000
150   FOR K = 2 TO 500
160     LET L = N/K
170     LET M = N-K*L
180     IF L = 0 GOTO 230
190     IF L = 1 GOTO 220 
200     IF M > L GOTO 220
210     IF M = L GOTO 240
220   NEXT K
230   PRINT N;
240 NEXT N
250 REM PRINT CHR$(7)
260 PRINT "Finished."
270 STOP
