@echo off
if not exist ..\..\zmac.exe goto notfound
..\..\zmac.exe %1 -z
goto :end

:notfound
@echo zmac.exe not found!
@echo download from http://48k.ca/zmac.html and place in same folder where Sys9080 is located
errorlevel 1

:end

