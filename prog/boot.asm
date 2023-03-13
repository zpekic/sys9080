;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------

;include ./sys9080.asm

		ORG 0x0000	;-----RST0 == RESET
		DI
		JMP Boot

		ORG 0x0008	;-----RST1 (TRACE)
		OUT PORT_VGATRACE
		RET

		ORG 0x0010	;-----RST2 (ACIA1)
		DI
		JMP Acia1ToPort

		ORG 0x0018	;-----RST3 (no device, execution trap)
		DI
		CALL DumpState
		JMP WaitForSS

		ORG 0x0020	;-----RST4 (no device, execution trap)
		DI
		CALL DumpState
		JMP WaitForSS

		ORG 0x0028	;-----RST5 (no device, execution trap)
		DI
		CALL DumpState
		JMP WaitForSS

		ORG 0x0030	;-----RST6 (BTN1, execution trap)
		DI
		JMP DumpState
		JMP WaitForSS

		ORG 0x0038	;-----RST7 (BTN0, execution trap)
		DI
		CALL DumpState
WaitForSS:	PUSH PSW
CheckSW7:	IN PORT0
			RAL		;faster than ANI MASK_SW7
			JNC CheckSW7
			POP PSW
			EI
			RET
		
DumpState:	XTHL			;PC from stack is now in HL
			SHLD Temp_PC	;store away (making this code non re-entrant)
			XTHL			;restore PC to stack
			PUSH H
			PUSH D
			PUSH B
			PUSH PSW

			PUSH H
			PUSH D
			PUSH B
			PUSH PSW

			LXI H, TextAF
			CALL TxStringAtHL
			XTHL
			CALL TxValueOfHL
			POP H
			
			LXI H, TextBC
			CALL TxStringAtHL
			XTHL
			CALL TxValueOfHL
			CALL BytesAtHL
			POP H

			LXI H, TextDE
			CALL TxStringAtHL
			XTHL
			CALL TxValueOfHL
			CALL BytesAtHL
			POP H

			LXI H, TextHL
			CALL TxStringAtHL
			XTHL
			CALL TxValueOfHL
			CALL BytesAtHL
			POP H

			LXI H, TextPC
			CALL TxStringAtHL
			LHLD Temp_PC
			CALL TxValueOfHL
			CALL BytesAtHL

			LXI H, TextSP
			CALL TxStringAtHL
			LXI D, 0xFFFF		;start searching for stack position from top of memory down
			LHLD Temp_PC
			XCHG			;HL = 0xFFFF, DE = PC to search for
SearchForPC:MOV A, D
			CMP M
			JNZ NotFound
			DCX H
			MOV A, E
			CMP M
			JNZ SearchForPC
			CALL TxValueOfHL
			CALL BytesAtHL
			MVI A, CR
			CALL SendChar
			MVI A, LF
			CALL SendChar
			JMP RestoreRegs
NotFound:	DCX H
			JMP SearchForPC

RestoreRegs:	POP PSW
		POP B
		POP D
		POP H
		EI
		RET
;-------------------------------------------
Acia0toPort:	PUSH PSW
		IN ACIA0_STATUS
		OUT PORT0
		IN ACIA0_DATA
		OUT PORT1
		POP PSW
		EI
		RET

Acia1toPort:	PUSH PSW
		IN ACIA1_STATUS
		OUT PORT0
		IN ACIA1_DATA
		OUT PORT1
		POP PSW
		EI
		RET

OnByteReceived:	PUSH PSW
				IN PORT1		;hooked up to 4 push buttons
				ANI MASK_BUTTON1
				JZ ProcessByte	
				PUSH H
				PUSH D
				PUSH B

				IN ACIA1_STATUS		
				MOV H, A
				IN ACIA1_DATA
				MOV L, A
				PUSH H

				IN ACIA0_STATUS		
				MOV H, A
				IN ACIA0_DATA
				MOV L, A
				PUSH H

				LXI H, TextACIA0
				CALL TxStringAtHL
				POP H
				CALL TxValueOfHL

				LXI H, TextACIA1
				CALL TxStringAtHL
				POP H
				CALL TxValueOfHL

				POP B
				POP D
				POP H
ProcessByte:	POP PSW
				EI
				RET
;-------------------------------------------
Boot:			LXI H, 0000H
				;DCX H
				SPHL
				CALL InitAcias
				CALL TxInlineString
TextGreet1:		DB CR, LF, "*** Sys9080 is ready. RAM @ ", 0x00
				IN PORT0
				ANI 00000100B
				JNZ TestRam		;if using "fast" clock then check RAM, otherwise skip
				CALL TxInlineString
				DB "(skipped)", 0x00
				JMP TextPort
TestRam:		CALL GetLowestRam
				MOV A, L
				OUT PORT0
				MOV A, H
				OUT PORT1		;display on LEDs
				CALL TxValueOfHL	;display on console
TextPort:		CALL TxInlineString
				DB " Switches= ", 0x00
				IN PORT0	;big slider switches
				MOV L, A
				IN PORT2	;dip switches B4...B1 A4..A1
				MOV H, A
				CALL TxValueOfHL
				CALL TxInlineString
TextVdp:		DB " Vdp rows/cols= ", 0x00	
				LHLD VdpCols
				CALL TxValueOfHL
				CALL TxInlineString
TextGreet2:		DB " ***", CR, LF, "  (BTN0/1 to dump CPU/ACIAs state)", CR, LF, 0x00
				MVI A, CS
				OUT PORT_VGATRACE
				EI 
;				HLT			;interrupt is needed to go further
;-------------------------------------------------------------------------
				JMP AltMon		;enter monitor program
;-------------------------------------------------------------------------
InitAcias:		MVI	a,3		;reset 6850 uart
				OUT	ACIA0_STATUS
				OUT	ACIA1_STATUS	;2nd 2SIO port as well
				IN	PORT2		;slide switches contain ACIA mode
				OUT PORT2		;reflect on LEDs
				MVI	a,10h		;8N2, baudrate clock / 1 (== 38400)
				;NOP
				;NOP
				OUT	ACIA0_STATUS
				OUT	ACIA1_STATUS	;2nd 2SIO port as well
				RET

;PrintAsciiSet: LXI B, 0D20H		;set C to ASCII space
;SendNextChar: 	MOV A, C
;		CALL SendChar		;send char
;		CPI "~"			;end of printable chars reached?
;		JZ NextLine
;		INR C
;		JMP SendNextChar
;NextLine:	MOV A, B
;		CALL SendChar		;send char
;		XRI 00000110B		;cheap trick to convert newline to linefeed 
;		CALL SendChar		;send char
;		RET

DumpTrace:		PUSH H
				PUSH D
				PUSH B
				PUSH PSW

				CALL TxInlineString
				DB "AF=", 0x00
				XTHL
				CALL TxValueOfHL
				XTHL
				INX SP
				INX SP
				
				CALL TxInlineString
				DB " BC=", 0x00
				XTHL
				CALL TxValueOfHL
				XTHL
				INX SP
				INX SP

				CALL TxInlineString
				DB " DE=", 0x00
				XTHL
				CALL TxValueOfHL
				XTHL
				INX SP
				INX SP

				CALL TxInlineString
				DB " HL=", 0x00
				XTHL
				CALL TxValueOfHL
				XTHL
				INX SP
				INX SP

				CALL TxInlineString
				DB " PC=", 0x00
				XTHL
				CALL TxValueOfHL
				XTHL
				CALL TxInlineString
				DB CR, LF, 0x00

				DCX SP
				DCX SP
				DCX SP
				DCX SP
				DCX SP
				DCX SP
				DCX SP
				DCX SP

				POP PSW
				POP B
				POP D
				POP H
				
				;OUT CPUTRACEON
				EI
				RET
			
TxStringAtHL:	MOV A, M
				ANA A
				RZ
				CALL SendChar
				INX H
				JMP TxStringAtHL

TxInlineString:	POP H			;Return address was pointing at string start
TxInlineChar:	MOV A, M
				ANA A
				JZ Return
				CALL SendChar
				INX H
				JMP TxInlineChar
Return:			INX H			;go beyond terminating null byte
				PCHL

BytesAtHL:		MVI C, 0x10		;dump 16 bytes at (HL)
NextByteAtHL:	MVI A, " "
				CALL SendChar
				MOV A, M
				CALL TxValueOfA
				DCR C
				RZ			;return if reached 0
				INX H
				JMP NextByteAtHL

TxValueOfHL:	MOV A, H
				CALL TxValueOfA
				MOV A, L
TxValueOfA:		PUSH PSW
				RRC
				RRC
				RRC
				RRC
				CALL TxHexDig
				POP PSW
TxHexDig:		ANI 0x0F
				ADI '0'
				CPI '9' + 1
				JM TxHexDigOut
				ADI 0x07
TxHexDigOut:	CALL SendChar
				RET
	
SendChar:		PUSH PSW
				OUT PORT_VGATRACE
CheckIfReady:	IN ACIA0_STATUS
				ANI MASK_READY
				JZ CheckIfReady
				POP PSW
				OUT ACIA0_DATA
				RET

GetLowestRam:	LXI H, 0xFFFF	;assume RAM is located near top of address space
NextAddress:	MOV A, M
				CMA		;flip all bits
				MOV M, A
				CMP M
				JNZ LowestFound
				CMA
				MOV M, A
				MOV A, L
				OUT PORT0	;display address being examined
				MOV A, H
				OUT PORT1
				ORA L
				RZ		;Bail if HL = 0
				DCX H
				JMP NextAddress
LowestFound:	INX H
				RET
		
TextAF:		DB CR, LF, " AF=", 0x00
TextBC:		DB CR, LF, " BC=", 0x00
TextDE:		DB CR, LF, " DE=", 0x00
TextHL:		DB CR, LF, " HL=", 0x00
TextPC:		DB CR, LF, " PC=", 0x00
TextSP:		DB CR, LF, " SP=", 0x00
TextACIA0:	DB CR, LF, " ACIA0=", 0x00
TextACIA1:	DB CR, LF, " ACIA1=", 0x00
End:		DB 0x00		;Cheap trick to see last used address
