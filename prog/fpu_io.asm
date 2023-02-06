;--------------------------------------------------------------------------
; Simple test program for Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------

include ./sys9080.asm


		ORG 0x8000
;------ TEST CODE --------
TestFpu:	OUT BUSTRACEON

			LXI D, fpuMem
			CALL fpuExec9
			DW f9Mov | f9Single | f9DWord | smc | dm0;	fpumem(0) := float(4)
			DW 0x0004
			DW 0x0000
			JC Error
			
			NOP
			
			LXI D, fpuMem
			CALL fpuExec9
			DW f9Mov | f9Single | f9DWord | smc | dm1; fpumem(1) := float(5)
			DW 0x0005
			DW 0x0000
			JC Error
			
			NOP

			LXI D, fpuMem
			CALL fpuExec11
			DW f11Mul | f11Single | sm0 | dm1		; fpumem(1) := fpumem(0) * fpumem(1);
			JNC NoError
		
Error:		OUT BUSTRACEOFF
			RST 7
NoError:	OUT BUSTRACEOFF
			JMP AltMon

;---- FPU subroutines --------
fpuExec9:	MVI A, (format9 and 0xFF)
			POP H		;HL points now to the fpu instruction word, where in normal call the next CPU instruction would be
			MOV C, M
			INX H
			MOV B, M	;BC contains the FPU instructions, no bytes swapped yet
			INX H
			PUSH H		;in case of no constant, stack is now good to return from fpuExec
			CALL OutId	;output 0x00BE or 0x003E
			; determine operands
			MOV A,B
			ANI 11000110B
			;
			CPI 10000010B
			JZ ConstMem9
			;
			CPI 01000010B
			JZ MemMem9
			;
			CPI 00000010B
			JZ RegMem9
			;
			JMP fpuExec
			
fpuExec11:	MVI A, (format11 and 0xFF)
			POP H		;HL points now to the fpu instruction word, where in normal call the next CPU instruction would be
			MOV C, M
			INX H
			MOV B, M	;BC contains the FPU instructions, no bytes swapped yet
			INX H
			PUSH H		;in case of no constant, stack is now good to return from fpuExec
			CALL OutId	;output 0x00BE or 0x003E
			; determine operands
			MOV A,B
			ANI 11000110B
			;
			CPI 10000010B
			JZ ConstMem11
			;
			CPI 01000010B
			JZ MemMem11
			;
			CPI 00000010B
			JZ RegMem11
			;
fpuExec:	CPI 10000000B
			JZ ConstReg
			;
			CPI 01000000B
			JZ MemReg
			;
			CPI 00000000B
			JZ RegReg
			;
			STC	; Carry flag set means error 
			RET

; -- destination is internal register, which means that gen2 is is not picked up from memory so format 9 and 11 have same flow
RegReg:		CALL OutOperation
			Call FpuWait
			JMP InStatus

ConstReg:	CALL OutOperation
			POP H
			CALL OutConstant	; 4 bytes pointed by HL
			PUSH H
			CALL FpuWait
			JMP InStatus

MemReg:		CALL OutOperation
			CALL OutOperand1
			CALL FpuWait
			JMP InStatus

RegMem9:	CALL OutOperation
			JMP Result2Mem

; destination is memory, that means in format 11 2nd operand must be presented, but not for format 9
RegMem11:	CALL OutOperation
			CALL OutOperand2
			JMP Result2Mem

ConstMem9:	CALL OutOperation
			POP H
			CALL OutConstant	; 4 bytes pointed by HL
			PUSH H
			JMP Result2Mem
			
ConstMem11:	CALL OutOperation
			POP H
			CALL OutConstant	; 4 bytes pointed by HL
			PUSH H
			CALL OutOperand2
			JMP Result2Mem
			
MemMem9:	CALL OutOperation
			CALL OutOperand1
			JMP Result2Mem
			
MemMem11:	CALL OutOperation
			CALL OutOperand1
			CALL OutOperand2
Result2Mem:	CALL FpuWait
			CALL InStatus
			RC					; Carry flag indicates error, break off protocol with FPU
			CALL GetMemAddr2
			IN fpuResultLo
			MOV M, A
			INX H
			IN fpuResultLo + 1
			MOV M, A
			INX H
			IN fpuResultHi
			MOV M, A
			INX H
			IN fpuResultHi + 1
			MOV M, A
			INX H
			RET			

GetMemAddr1: 	XCHG ;save base address to HL
				MOV A, C
				ANI 00000000B
				MOV E, A
				MOV A, B
				ANI 00111000B
				MOV D, A
				MVI C, 9
				JMP GetMemAddr
GetMemAddr2: 	XCHG	;save base address to HL
				MOV A, C
				ANI 11000000B
				MOV E, A
				MOV A, B
				ANI 00000001B
				MOV D, A
				MVI C, 4
GetMemAddr:		CALL ShiftDERight ;move offset to be value * 4
				STC
				CMC
				DAD D
				RET
				
OutOperand2:	CALL GetMemAddr2
				JMP OutConstant
OutOperand1:	CALL GetMemAddr1
OutConstant:	MOV A, M
				OUT fpuOperand1Lo
				INX H
				MOV A, M
				OUT fpuOperand1Lo + 1
				INX H
				MOV A, M
				OUT fpuOperand1Hi
				INX H
				MOV A, M
				OUT fpuOperand1Hi + 1
				INX H
				RET
				
OutId:			OUT fpuID
				XRA A
				OUT fpuID + 1
				RET

OutOperation:	MOV A, B
				OUT fpuOperation
				MOV A, C
				OUT fpuOperation + 1
				RET

InStatus:		IN fpuStatus	;HL no longer needed when this is called
				MOV L, A
				IN fpuStatus + 1
				MOV H, A
				PUSH H
				POP PSW		;carry flag indicates FPU "quit", and after f11Cmp, Sign and Zero are also valid
				RET

InElapsed:		IN fpuCycles
				MOV M, A
				INX H
				IN fpuCycles + 1
				MOV M, A
				INX H
				RET 

FpuWait:		IN fpuDone
				ORA A
				RNZ	
				JMP FpuWait

ShiftDERight:	MOV A, C
				ORA A
				RZ		;done when C == 0
				STC
				CMC
				MOV A, D
				RAR
				MOV D, A
				MOV A, E
				RAR
				MOV E, A
				DCR C
				JMP ShiftDERight
			
fpuMem:	; 8 32 bit memory locations for 8 memory based FPU numbers
		DW 0x0000
		DW 0x0000
		DW 0x1111
		DW 0x1111
		DW 0x2222
		DW 0x2222
		DW 0x3333
		DW 0x3333
		DW 0x4444
		DW 0x5555
		DW 0x5555
		DW 0x6666
		DW 0x6666
		DW 0x7777
		DW 0x7777
		
fZeroLo:		EQU 0x0000
fZeroHi:		EQU 0x0000
fOneLo:			EQU 0x0000
fOneHi:			EQU 0x3F80
fMinusOneLo:	EQU 0x0000
fMinusOneHi:	EQU 0xBF80
fTenLo:			EQU 0x0000
fTenHi:			EQU 0x4120

; -- source operands (sm = supplied from the bus (from memory), sm = internal from register x)
srcmask EQU 0xF800
smc		EQU 0x8000	;-- constant coming from instruction stream (HL)
sm7 	EQU 0x7800	;-- offset from DE
sm6 	EQU 0x7000
sm5 	EQU 0x6800
sm4 	EQU 0x6000
sm3 	EQU 0x5800
sm2 	EQU 0x5000
sm1 	EQU 0x4800
sm0		EQU 0x4000
sr7		EQU 0x3800
sr6		EQU 0x3000
sr5		EQU 0x2800
sr4		EQU 0x2000
sr3		EQU 0x1800
sr2		EQU 0x1000
sr1		EQU 0x0800
sr0		EQU 0x0000
; -- destination operands (dm = supplied from/to the bus (from memory), dx = internal from register x)
dstmask EQU 0x07C0
dmc		EQU 0x0400 ;-- this should throw an "exception" as destination cannot be a constant
dm7		EQU 0x03C0 ;-- offset from DE
dm6		EQU 0x0380
dm5		EQU 0x0340
dm4		EQU 0x0300
dm3		EQU 0x02C0
dm2		EQU 0x0280
dm1		EQU 0x0240
dm0		EQU 0x0200
dr7		EQU 0x01C0
dr6		EQU 0x0180
dr5		EQU 0x0140
dr4		EQU 0x0100
dr3		EQU 0x00C0
dr2		EQU 0x0080
dr1		EQU 0x0040
dr0		EQU 0x0000

;--- format 11 constants ---
format11:	EQU 0x00BE
f11Single:	EQU 0x0001
f11Double:	EQU 0x0000
f11Mask:	EQU 0x003C	
f11Add:		EQU 0x0000
f11Sub:		EQU 0x0010
f11Div:		EQU 0x0020
f11Mul:		EQU 0x0030
f11Cmp:		EQU 0x0008
f11Neg:		EQU 0x0014
f11Abs:		EQU 0x0034

;--- format 19 constants ---
format9:	EQU 0x003E	
f9Single:	EQU 0x0040
f9Double:	EQU 0x0000
f9Byte:		EQU 0x0000
f9Word:		EQU 0x0001
f9DWord:	EQU 0x0003
f9Mask:		EQU 0x0038
f9Mov:		EQU 0x0000
f9Floor:	EQU 0x0038
f9Trunc:	EQU 0x0028
f9Round:	EQU 0x0020
f9Movfl:	EQU 0x0018
f9Movlf:	EQU 0x0010
f9Movf:		EQU 0x0040
f9Lfsr:		EQU 0x0008
f9Sfsr:		EQU 0x0030

			ORG btFetch
			DW TestFpu
			DW NoError
			ORG btIoRead
			DW fpuBase << 8 | fpuBase
			DW 0xFFFF
			ORG btIoWrite
			DW fpuBase << 8 | fpuBase
			DW 0xFFFF
		
