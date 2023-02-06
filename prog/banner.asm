;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------

include ./sys9080.asm


; text video memory, 512b
		ORG VdpRam
l0:	DB '012345678901234567891234567890'
l1:	DB '  _____                      1'                      
l2:	DB ' / ____|                     2'			                       
l3:	DB '| (___   _   _   ___         3'         
l4:	DB ' \___ \ | | | | / __|        4'         
l5:	DB ' ____) || |_| | \__ \        5'         
l6:	DB '|_____/  \__, | |___/        6'         
l7:	DB '          __/ |              7'               
l8:	DB '  ___    |___/   ___    ___  8'
l9:	DB ' / _ \  / _ \   / _ \  / _ \ 9'
l10:	DB '| (_) || | | | | (_) || | | |0'
l11:	DB ' \__, || | | |  > _ < | | | |1'
l12:	DB '   / / | |_| | | (_) || |_| |2'
l13:	DB '  /_/   \___/   \___/  \___/ 3'
l14:	DB '-----------------------------4'
l15:	DB 'zpekic@hotmail.com 2017,2018 5'
l16:	DB '-----------------------------6'

; set display colors
		ORG VdpFgColor	
		DB 	0xF0	;RRRGGGBB
		ORG VdpBkColor	
		DB 	0x0F	;RRRGGGBB
