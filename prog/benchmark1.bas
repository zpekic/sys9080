100 REM	-------------------------------------
101 REM	Simple benchmark - find primes < 1000
102 REM	-------------------------------------
103 REM http://www.mtmscientific.com/lalu.html
104 REM	-------------------------------------
130 PRINT "Starting."
140 FOR N = 1 TO 1000
150   FOR K = 2 TO 500
160     LET M = N/K
170     LET L = INT(M)
180     IF L = 0 THEN 230
190     IF L = 1 THEN 220 
200     IF M > L THEN 220
210     IF M = L THEN 240
220   NEXT K
230   PRINT N;
240 NEXT N
250 PRINT CHR$(7)
260 PRINT "Finished."
270 END
