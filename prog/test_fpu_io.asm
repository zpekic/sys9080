;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------

include ./sys9080.asm


; text video memory, 512b
		ORG 0x8000

TestFpu:	OUT BUSTRACEON

			LXI H, test_div
			CALL WriteId
			CALL WriteOper
			CALL WriteOprand	;"gen1" == source
			CALL WriteOprand	;"gen2" == destination (in case of division: gen2/gen1)
			Call FpuWait
			CALL ReadStatus
			JC Error
			CALL ReadResult		;"gen2" == destination
			CALL ReadElapsed

			LXI H, test_sfsr
			CALL WriteId
			CALL WriteOper
			CALL FpuWait
			CALL ReadStatus
			JC Error
			CALL ReadResult
			CALL ReadElapsed

			JMP NoError

Error:		RST 7
NoError:	OUT BUSTRACEOFF
			JMP AltMon

WriteId		MOV A, M
			OUT fpuID
			INX H
			MOV A, M
			OUT fpuID+1
			INX H
			RET

WriteOper:	MOV A, M
			OUT fpuOperation
			INX H
			MOV A, M
			OUT fpuOperation+1
			INX H
			RET

WriteOprand:MOV A, M
			OUT fpuOperand1Lo
			INX H
			MOV A, M
			OUT fpuOperand1Lo+1
			INX H
			MOV A, M
			OUT fpuOperand1Hi
			INX H
			MOV A, M
			OUT fpuOperand1Hi+1
			INX H
			RET

ReadStatus:	IN fpuStatus
			MOV M, A
			MOV E, A
			INX H
			IN fpuStatus+1
			MOV M, A
			MOV D, A
			INX H
			PUSH D
			POP PSW		;carry flag indicates FPU "quit", and after f11Cmp, Sign and Zero are also valid
			RET

ReadResult:	IN fpuResultLo
			MOV M, A
			INX H
			IN fpuResultLo+1
			MOV M, A
			INX H
			IN fpuResultHi
			MOV M, A
			INX H
			IN fpuResultHi+1
			MOV M, A
			INX H
			RET

ReadElapsed:IN fpuCycles
			MOV M, A
			INX H
			IN fpuCycles+1
			MOV M, A
			INX H
			RET 

FpuWait:	IN fpuDone
			ORA A
			RNZ	
			JMP FpuWait

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
fpsr_status:DW 0xFFFF	;-- filler
fpsrLo:		DW 0xADDE	;-- filler
fpsrHi:		DW 0xEFBE	;-- filler
fpsr_cycles:DW 0xFFFF	;-- filler
		
;------ DEBUG registers
			ORG btMemRead
			DW 0x0000
			DW 0x0000
			
			ORG btMemWrite
			DW div_status
			DW fpsr_cycles
			
			ORG btIoRead
			DW fpuBase << 8 | fpuBase
			DW 0xFFFF 
			
			ORG btIoWrite
			DW fpuBase << 8 | fpuBase
			DW 0xFFFF
			
			ORG btFetch
			DW 0x0000
			DW 0x0000
			
			ORG btIntAck
			DW 0x0000
			DW 0x0000
;------------------------			
			
OneLo:		EQU 0x0000
fOneHi:		EQU 0x3F80
fMinusOneLo:EQU 0x0000
fMinusOneHi:EQU 0xBF80
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

