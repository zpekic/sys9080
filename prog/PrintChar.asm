;---------------------------------------------------------------------------
; Anvyl hex kbd and TFT display test/demo  https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;---------------------------------------------------------------------------

include ./sys9080.asm

		.ORG 0x8000

		MVI A, HM
		CALL DisplayChar
KbdScan:	LXI H, KeyMap
		MVI C, 0xFE
ColLoop:	MVI D, 0xFE
		MOV A, C
		OUT PORT_COL
RowLoop:	IN PORT_ROW
		CMP D
		JNZ NotPressed
		NOP;RST 6
		MOV A, M
		ORA A
		JZ AltMon
		CALL DisplayChar
NotPressed:	INX H
		MOV A, D
		RLC
		MOV D, A
		CPI 0xEF
		JNZ RowLoop
		MOV A, C
		RLC
		MOV C, A
		CPI 0xEF
		JNZ ColLoop
		JZ KbdScan

DisplayChar:	PUSH H
		PUSH D
		PUSH B
		PUSH PSW
		CPI CS
		JZ ClearScreen
		CPI HM
		JZ HomeScreen
		CPI CR	;CR and LF are handled the same
		JZ CrLf
		CPI LF	
		JZ CrLf
		CPI ML	;Move cursor Left 
		JZ MoveLeft         
		CPI MR	;Move cursor Right
		JZ MoveRight         
		CPI MU	;Move cursor Up
		JZ MoveUp          
		CPI MD	;Move cursor Down
		JZ MoveDown
		;CPI BS	;BackSpace  
		PUSH PSW
		NOP;
		NOP;
		NOP;RST 6
		CALL GetCursorAddr
		POP PSW
		MOV M, A
MoveRight:	CALL AdvanceCursor
RestoreRegs:	POP PSW
		POP B
		POP D
		POP H
		RET

MoveLeft:	LHLD VdpCols
		XCHG
		LHLD CursorCol
		DCR L
		JP SetCursor
		MOV L, E
		DCR L
		DCR H
		JP SetCursor
		CALL ScrollDown
		JMP HomeScreen

MoveDown:	LHLD VdpCols
		XCHG
		LHLD CursorCol
		INR H
		MOV A, H
		CMP D
		JC SetCursor
		CALL ScrollUp
		LHLD VdpCols
		DCR H
		MVI L, 0x00
		JMP SetCursor

MoveUp:		LHLD VdpCols
		XCHG
		LHLD CursorCol
		DCR H
		JP SetCursor
		PUSH H
		CALL ScrollDown
		POP H
		MVI H, 0x00
		JMP SetCursor
		
ClearScreen:	LXI H, VdpRam
		LXI B, 17*30
ClearChar:	MVI A, ' '
		MOV M, A
		INX H
		DCX B
		MOV A, C
		ORA B
		JNZ ClearChar
HomeScreen:	LXI H, 0x0000
SetCursor:	SHLD CursorCol
		JMP RestoreRegs

CrLf:		LDA VdpCols
		DCR A
		STA CursorCol	
		CALL AdvanceCursor
		JMP RestoreRegs

GetCursorAddr:	LHLD CursorCol	;HL = CursorRow CursorCol
		MOV C, H
		MVI H, 0x00
		LXI D, VdpRam
		DAD D		;HL = VdpRam + CursorCol
		LDA VdpCols
		MOV E, A
		MVI D, 0x00	;DE = Cols
NextRow:	MOV A, C	;A = CursorRow
		ORA C
		RZ
		DAD D
		DCR C
		MOV A, L
		OUT PORT0
		MOV A, H
		OUT PORT1
		JMP NextRow 
		
AdvanceCursor:	LXI H, VdpCols
		LDA CursorCol
		INR A
		STA CursorCol
		CMP M
		RC
		XRA A
		STA CursorCol	;CursorCol = 0
		INX H		;points to VdpRows
		LDA CursorRow
		INR A
		STA CursorRow
		CMP M
		RC
		; continue with scroll up
ScrollUp:	NOP;RST 6	
		LXI B, 16*30	;replace with dynamic calculation	
		LHLD VdpCols
		MVI H, 0x00	;HL = VdpCols
		LXI D, VdpRam
		DAD D		;HL = VdpCols + VdpRam, DE = VdpRam
CopyNextChar:	MOV A, M
		STAX D		;(DE) <= (HL)
		INX H
		INX D
		MOV A, C
		ORA B
		JZ ClearLastLine
		DCX B
		JMP CopyNextChar
ClearLastLine:	NOP;RST 6
		MVI A, ' '
		LHLD VdpCols
ClearLastLC:	STAX D
		INX D
		DCR L
		JNZ ClearLastLC
		LDA VdpRows
		DCR A
SetCursorRow:	STA CursorRow
		RET

ScrollDown:	LXI B, 16*30
		LXI H, VdpRam
		DAD B
		XCHG	;DE = source
		LHLD VdpCols
		MOV A, E
		ADD L
		MOV L, A
		MOV A, D
		ACI 0x00
		MOV H, A;HL = dest
CopyPrevChar:	LDAX D
		MOV M, A
		DCX H
		DCX D
		MOV A, C
		ORA B
		JZ ClearFirstLine
		DCX B
		JMP CopyPrevChar
ClearFirstLine:	RST 6
		MVI A, ' '
		LHLD VdpCols
ClearFirstLC:	STAX D
		INX D
		DCR L
		JNZ ClearFirstLC
		XRA A
		JMP SetCursorRow
		

KeyMap:		DB "1", "4", "7", "0", "2", "5", "8", ML, "3", "6", "9", MR, 0x00, MU, MD, CS		
		
LastByte:	DB	0x00
