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
;-------------------------------------------------------------
VdpRam		EQU 0xFC00; text video memory, 512b
VdpFgColor	EQU VdpRam + 0x1FE	;write only, RRRGGGBB
VdpBkColor	EQU VdpRam + 0x1FF	;write only, RRRGGGBB
VdpCols		EQU VdpRam + 0x1FE	;read only, should be 30
VdpRows		EQU VdpRam + 0x1FF	;read only, should be 17


		ORG 0xFE00	;-----Suitable for 512b RAM system

		LDA VdpCols
		OUT PORT_0
		LDA VdpRows
		OUT PORT_1
		MVI C, 0x00	;-- start with white as fg color
NextColor:	MOV A, C
		STA VdpFgColor
		CMA
		STA VdpBkColor
		MOV B, C
		LXI H, VdpRam
		LXI D, 30*17-1
NextChar:	MOV M, B
		INR B
		INX H
		DCX D
		MOV A, D
		CPI 0xFF
		JNZ NextChar
		INR C
		JNZ NextColor
		
		JMP AltMon
