100 REM	-------------------------------------
101 REM	Simple benchmark - find primes < 1000
102 REM See http://www.mtmscientific.com/lalu.html
103 REM	-------------------------------------
104 REM https://archive.org/details/InterfaceAge198006/page/n131/mode/2up
105 REM   SW210    CPU (MHz) Result (s)
106 REM   100     01.5625 52m23   3143
107 REM   101     03.1250 26m12   1572
108 REM   110     06.2500 13m06   786
109 REM   111     25.0000 3m17    197
110 REM   -------------------------------------
130 PRINT "Starting."
140 FOR N = 1 TO 1000
150 GOSUB 300
240 NEXT N
250 PRINT "Finished."
260 STOP
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
