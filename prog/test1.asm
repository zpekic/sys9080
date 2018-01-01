;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------
UART0_STATUS	EQU 0x10; status read-only
UART0_DATA	EQU 0x11; data send/receive
UART1_STATUS	EQU 0x12; status read-only
UART1_DATA	EQU 0x13; data send/receive
PORT_0		EQU 0x00;
PORT_1		EQU 0x01;
MASK_VALID	EQU 0x01; fields in UART status register
MASK_BUSY	EQU 0x02;
MASK_ERROR	EQU 0x40;
MASK_INTREQ	EQU 0x80;
CR		EQU 0x0D; ASCII newline
LF		EQU 0x0A; ASCII line feed
Temp_PC		EQU 0xFF00; can't use DW because the hex file maps to ROM only


		ORG 0x0000	;-----RST0 == RESET
		DI
		JMP Boot

		ORG 0x0008	;-----RST1
		DI
		JMP DumpState

		ORG 0x0010	;-----RST2
		DI
		JMP DumpState

		ORG 0x0018	;-----RST3
		DI
		JMP DumpState

		ORG 0x0020	;-----RST4
		DI
		JMP CharEcho

		ORG 0x0028	;-----RST5
		DI
		JMP CharEcho

		ORG 0x0030	;-----RST6
		DI
		JMP DumpState

		ORG 0x0038	;-----RST7
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
CharEcho:	PUSH PSW	
		IN UART0_STATUS		;read status bits from UART
		PUSH H
		MOV H, A
		IN UART0_DATA
		MOV L, A
		CALL TxValueOfHL
		POP H
		POP PSW
		EI
		RET
;-------------------------------------------
Boot:		LXI H, 0000H
		DCX H
		SPHL
		LXI H, TextGreet1
		CALL TxStringAtHL
		CALL GetLowestRam
		INX H
		CALL TxValueOfHL
		LXI H, TextPort
		CALL TxStringAtHL
		IN PORT_0
		MOV L, A
		IN PORT_1
		MOV H, A
		CALL TxValueOfHL
		LXI H, TextGreet2
		CALL TxStringAtHL
		EI
		HLT			;interrupt is needed to go further
		NOP			;Deadloop sometimes goes 1 byte up too far and executes HLT again??
DeadLoop: 	LXI B, 0D20H		;set C to ASCII space
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
		JMP DeadLoop

TxStringAtHL:	MOV A, M
		ANA A
		RZ
		CALL SendChar
		INX H
		JP TxStringAtHL

BytesAtHL:	MVI C, 0x08		;dump 8 bytes at (HL)
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
CheckIfBusy:	IN UART0_STATUS
		ANI MASK_BUSY
		JNZ CheckIfBusy
		POP PSW
		OUT UART0_DATA
		RET
		
GetLowestRam:	LXI H, 0xFFFF	;assume RAM is located near top of address space
NextAddress	MOV A, M
		CMP M
		RNZ
		CMA		;flip all bits
		MOV M, A
		CMP M
		RNZ
		CMA
		MOV M, A
		MOV A, H
		ORA L
		RZ		;Bail if HL = 0
		DCX H
		JMP NextAddress
		
		
TextAF:		DB CR, "AF = ", 0x00
TextBC:		DB CR, "BC = ", 0x00
TextDE:		DB CR, "DE = ", 0x00
TextHL:		DB CR, "HL = ", 0x00
TextPC:		DB CR, "PC = ", 0x00
TextSP:		DB CR, "SP = ", 0x00
TextGreet1:	DB CR, CR, "*** Sys9080 is ready. RAM detected at ", 0x00
TextPort	DB " Input port = ", 0x00
TextGreet2:	DB " ***", CR, "(Waiting for serial input to continue, or interrupt to dump processor state)", CR, 0x00
