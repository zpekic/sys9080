;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------
ACIA0_STATUS	EQU 0x10; status read-only
ACIA0_DATA	EQU 0x11; data send/receive
ACIA1_STATUS	EQU 0x12; status read-only
ACIA1_DATA	EQU 0x13; data send/receive
PORT_0		EQU 0x00;
PORT_1		EQU 0x01;
MASK_VALID	EQU 0x01; fields in UART status register
MASK_READY	EQU 0x02;
MASK_ERROR	EQU 0x40;
MASK_INTREQ	EQU 0x80;
CR		EQU 0x0D; ASCII newline
LF		EQU 0x0A; ASCII line feed
MASK_BUTTON1	EQU 0x02;
Temp_PC		EQU 0xFF00; can't use DW because the hex file maps to ROM only
AltMon		EQU 0x0400; Altmon is org'd to this location


		ORG 0x0000	;-----RST0 == RESET
		DI
		JMP Boot

		ORG 0x0008	;-----RST1 (not used)
		DI
		JMP DumpState

		ORG 0x0010	;-----RST2 (not used)
		DI
		JMP DumpState

		ORG 0x0018	;-----RST3 (not used)
		DI
		JMP DumpState

		ORG 0x0020	;-----RST4 (ACIA1)
		DI
		JMP OnByteReceived

		ORG 0x0028	;-----RST5 (ACIA0)
		DI
		JMP OnByteReceived

		ORG 0x0030	;-----RST6 (BTN1)
		EI		;no interrupt servicing (used to control ACIA status)
		RET

		ORG 0x0038	;-----RST7 (BTN0)
		DI		
DumpState:	XTHL			;PC from stack is now in HL
		SHLD Temp_PC		;store away (making this code non re-entrant)
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
SearchForPC:	MOV A, D
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
OnByteReceived:	PUSH PSW
		IN PORT_1		;hooked up to 4 push buttons
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
Boot:		LXI H, 0000H
		DCX H
		SPHL
		LXI H, TextGreet1
		CALL TxStringAtHL
		CALL GetLowestRam
		MOV A, L
		OUT PORT_0
		MOV A, H
		OUT PORT_1		;display on LEDs
		CALL TxValueOfHL	;display on console
		LXI H, TextPort
		CALL TxStringAtHL
		IN PORT_0
		MOV L, A
		IN PORT_1
		MOV H, A
		CALL TxValueOfHL
		LXI H, TextGreet2
		CALL TxStringAtHL
		CALL PrintAsciiSet
		EI
;		HLT			;interrupt is needed to go further
;-------------------------------------------------------------------------
		JMP AltMon		;enter monitor program
;-------------------------------------------------------------------------
PrintAsciiSet: 	LXI B, 0D20H		;set C to ASCII space
SendNextChar: 	MOV A, C
		CALL SendChar		;send char
		CPI "~"			;end of printable chars reached?
		JZ NextLine
		INR C
		JMP SendNextChar
NextLine:	MOV A, B
		CALL SendChar		;send char
		XRI 00000110B		;cheap trick to convert newline to linefeed 
		CALL SendChar		;send char
		RET

TxStringAtHL:	MOV A, M
		ANA A
		RZ
		CALL SendChar
		INX H
		JP TxStringAtHL

BytesAtHL:	MVI C, 0x10		;dump 16 bytes at (HL)
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
TxValueOfA:	PUSH PSW
		RRC
		RRC
		RRC
		RRC
		ANI 0x0F
		CALL TxHexDig
		POP PSW
		ANI 0x0F
TxHexDig:	ADI '0'
		CPI '9' + 1
		JM TxHexDigOut
		ADI 0x07
TxHexDigOut:	CALL SendChar
		RET
	
SendChar:	PUSH PSW
CheckIfReady:	IN ACIA0_STATUS
		ANI MASK_READY
		JZ CheckIfReady
		POP PSW
		OUT ACIA0_DATA
		RET
		
GetLowestRam:	LXI H, 0xFFFF	;assume RAM is located near top of address space
NextAddress:	MOV A, M
		CMP M
		JNZ LowestFound
		CMA		;flip all bits
		MOV M, A
		CMP M
		JNZ LowestFound
		CMA
		MOV M, A
		MOV A, H
		ORA L
		RZ		;Bail if HL = 0
		DCX H
		JMP NextAddress
LowestFound:	INX H
		RET
		
		
TextAF:		DB CR, "AF = ", 0x00
TextBC:		DB CR, "BC = ", 0x00
TextDE:		DB CR, "DE = ", 0x00
TextHL:		DB CR, "HL = ", 0x00
TextPC:		DB CR, "PC = ", 0x00
TextSP:		DB CR, "SP = ", 0x00
TextGreet1:	DB CR, CR, "** Sys9080 is ready. RAM starts at ", 0x00
TextPort	DB " Input port = ", 0x00
TextGreet2:	DB " **", CR, "  (Press BTN0 to show processor state, or BTN1 for ACIAs)", CR, 0x00 
TextACIA0:	DB CR, "ACIA0 Rx status and data = ", 0x00
TextACIA1:	DB CR, "ACIA1 Rx status and data = ", 0x00
End:		DB 0x00		;Cheap trick to see last used address
