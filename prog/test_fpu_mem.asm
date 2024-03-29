;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------

include ./sys9080.asm


; text video memory, 512b
		ORG 0x8000

TestFpu:	RST 7

		LXI D, test_div
		CALL WriteId
		CALL WriteOperation
		CALL WriteOperand	;"gen1" == source
		CALL WriteOperand	;"gen2" == destination (in case of division: gen2/gen1)
		Call FpuWait
		CALL ReadStatus
		JC Error
		CALL ReadResult		;"gen2" == destination
		CALL ReadElapsed

		LXI D, test_sfsr
		CALL WriteId
		CALL WriteOperation
		CALL FpuWait
		CALL ReadStatus
		JC Error
		CALL ReadResult
		CALL ReadElapsed

		JMP NoError

Error:		RST 7
NoError:	JMP AltMon

WriteId		CALL GetWordIntoHL
		SHLD fpuID
		RET

WriteOperation	CALL GetWordIntoHL
		SHLD fpuOperation
		RET

WriteOperand	CALL GetWordIntoHL
		SHLD fpuOperand1Lo
		CALL GetWordIntoHL
		SHLD fpuOperand1Hi
		RET

ReadStatus	LHLD fpuStatus
		PUSH H
		CALL SetWordFromHL
		POP PSW		;carry flag indicates FPU "quit", and after f11Cmp, Sign and Zero are also valid
		RET

ReadResult	LHLD fpuResultLo
		CALL SetWordFromHL
		LHLD fpuResultHi
		JMP SetWordFromHL

ReadElapsed:	LHLD fpuCycles
		JMP SetWordFromHL

FpuWait:	LHLD fpuDone
		MOV A, L
		ORA H
		RNZ	
		JMP FpuWait

GetWordIntoHL:	LDAX D
		INX D
		MOV L, A
		LDAX D
		INX D
		MOV H, A
		RET

SetWordFromHL:	MOV L, A
		STAX D
		INX D
		MOV H, A
		STAX D
		INX D
		RET 

test_div:	DW format11
		DW f11Single | f11Div | dm | sm
		DW fTenLo
		DW fTenHi
		DW fMinusOneLo
		DW fMinusOneHi
div_status:	DW 0xFFFF	;-- filler
resultLo:	DW 0xADDE	;-- filler
resultHi:	DW 0xEFBE	;-- filler
div_cycles	DW 0xFFFF	;-- filler

test_sfsr:	DW format9
		DW f9Sfsr | dm | f9DWord | f9Double
fpsr_status:	DW 0xFFFF	;-- filler
fpsrLo:		DW 0xADDE	;-- filler
fpsrHi:		DW 0xEFBE	;-- filler
fpsr_cycles:	DW 0xFFFF	;-- filler
		

fOneLo:		EQU 0x0000
fOneHi:		EQU 0x3F80
fMinusOneLo:	EQU 0x0000
fMinusOneHi:	EQU 0xBF80
fTenLo:		EQU 0x0000
fTenHi:		EQU 0x4120

; -- source operands (m = supplied from the bus (from memory), rx = internal from register x)
sm		EQU 0x0080
sr7		EQU 0x0038
sr6		EQU 0x0030
sr5		EQU 0x0028
sr4		EQU 0x0020
sr3		EQU 0x0018
sr2		EQU 0x0010
sr1		EQU 0x0008
sr0		EQU 0x0000
; -- destination operands (m = supplied from/to the bus (from memory), rx = internal from register x)
dm		EQU 0x0004
dr7		EQU 0x8003
dr6		EQU 0x0003
dr5		EQU 0x8002
dr4		EQU 0x0002
dr3		EQU 0x8001
dr2		EQU 0x0001
dr1		EQU 0x8000
dr0		EQU 0x0000

;--- format 11 constants ---
format11:	EQU 0x00BE	
f11Single:	EQU 0x0100
f11Double:	EQU 0x0000
f11Add:		EQU 0x0000
f11Sub:		EQU 0x1000
f11Div:		EQU 0x2000
f11Mul:		EQU 0x3000
f11Cmp:		EQU 0x0800
f11Neg:		EQU 0x2400
f11Abs:		EQU 0x3400

;--- format 19 constants ---
format9:	EQU 0x003E	
f9Single:	EQU 0x0400
f9Double:	EQU 0x0000
f9Byte:		EQU 0x0000
f9Word:		EQU 0x0100
f9DWord:	EQU 0x0200
f9Mov:		EQU 0x0000
f9Floor:	EQU 0x3800
f9Trunc:	EQU 0x2800
f9Round:	EQU 0x2000
f9Movfl:	EQU 0x1800
f9Movlf:	EQU 0x1000
f9Movf:		EQU 0x4000
f9Lfsr:		EQU 0x0800
f9Sfsr:		EQU 0x3000

