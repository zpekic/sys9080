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


		ORG 0xFE00	;-----Suitable for 512b RAM system

		LXI H, 0x9900
LoopDAA		MOV A, H
		SUI 0x01
		DAA
		OUT PORT_1
		MOV H, A
		MOV A, L
		ADI 0x01
		DAA
		OUT PORT_0
		MOV L, A
		ORA A
		JNZ LoopDAA

		LXI B, 0x0000
LoopB:		DCX B
		MOV A, B
		OUT PORT_1
		MOV A, C
		OUT PORT_0
		ORA B
		JNZ LoopB

		LXI D, 0x0000
LoopD:		DCX D
		MOV A, D
		OUT PORT_1
		MOV A, E
		OUT PORT_0
		ORA D
		JNZ LoopD

		LXI H, 0x0000
LoopH:		DCX H
		MOV A, H
		OUT PORT_1
		MOV A, L
		OUT PORT_0
		ORA H
		JNZ LoopH
		
		JMP AltMon
