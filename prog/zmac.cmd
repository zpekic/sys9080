@echo off
if not exists ..\..\zmac.exe goto :error
..\..\zmac.exe %f -8
goto :end

:error
@echo zmac.exe not found!
@echo download from http://48k.ca/zmac.html and place in same folder where Sys9080 is located
errorlevel 1

:end
errorlevel 0

