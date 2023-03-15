100 REM	-------------------------------------
101 REM	Simple benchmark - find primes < 1000
102 REM	-------------------------------------
103 REM http://www.mtmscientific.com/lalu.html
104 REM	-------------------------------------
130 PRINT "Starting."
140 FOR N = 1 TO 1000
150 GOSUB 300
240 NEXT N
250 PRINT "Finished."
260 END
300 FOR K = 2 TO 500
310 M=N/K
312 J=N-M*K
320 IF K=N GOTO 380
330 IF M=0 RETURN
340 IF M=1 GOTO 370
350 IF J>0 GOTO 370
360 IF J=0 RETURN
370 NEXT K
380 PRINT N
390 RETURN
