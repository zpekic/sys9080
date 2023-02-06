;--------------------------------------------------------------------------
; Common definitions for  Sys9080 project https://github.com/zpekic/sys9080
; 		(c) zpekic@hotmail.com - 2017, 2018
;--------------------------------------------------------------------------
ACIA0_STATUS	EQU 0x10; status read-only
ACIA0_DATA		EQU 0x11; data send/receive

ACIA1_STATUS	EQU 0x12; status read-only
ACIA1_DATA		EQU 0x13; data send/receive

MASK_VALID	EQU 0x01; fields in UART status register
MASK_READY	EQU 0x02;
MASK_ERROR	EQU 0x40;
MASK_INTREQ	EQU 0x80;

PORT0		EQU 0x00; switches when reading, LEDs when writing
PORT1		EQU 0x01; buttons (3..0) when reading, LEDs when writing
PORT2		EQU 0x02; slider switches when reading, LEDs when writing
PORT_COL	EQU 0x03; hex key colums 3..0 when writing
PORT_ROW	EQU 0x03; hex key rows 3..0 when reading
PORT_VGATRACE	EQU 0xFF; write only port for VGA tracing (only ASCII char!)
; writing to following ports will set / reset flip flops
CPUTRACEOFF	EQU 0x04; OUT CPUTRACEOFF to turn off CPU tracing
CPUTRACEON	EQU 0x05; OUT CPUTRACEON to turn on CPU tracing
BUSTRACEOFF	EQU 0x06; OUT BUSTRACEOFF to turn off bus tracing
BUSTRACEON	EQU 0x07; OUT BUSTRACEON to turn on bus tracing

MASK_BUTTON0	EQU 0x01;
MASK_BUTTON1	EQU 0x02;
MASK_BUTTON2	EQU 0x04;
MASK_BUTTON3	EQU 0x08;
MASK_SW0	EQU 0x01;
MASK_SW1	EQU 0x02;
MASK_SW2	EQU 0x04;
MASK_SW3	EQU 0x08;
MASK_SW4	EQU 0x10;
MASK_SW5	EQU 0x20;
MASK_SW6	EQU 0x40;
MASK_SW7	EQU 0x80;

;-------------------------------------------------------------
AltMon		EQU 0x0400; Altmon is org'd to this location

;-------------------------------------------------------------
VdpRam		EQU 0x0C00; text video memory, 512b
VdpFgColor	EQU VdpRam + 0x1FE	;write only, RRRGGGBB
VdpBkColor	EQU VdpRam + 0x1FF	;write only, RRRGGGBB
VdpCols		EQU VdpRam + 0x1FE	;read only, should be 30
VdpRows		EQU VdpRam + 0x1FF	;read only, should be 17
RamBottom	EQU 0xFE00
Heap		EQU RamBottom + 0x0180
Temp_PC		EQU Heap; can't use DW because the hex file maps to ROM only
CursorCol	EQU Heap + 2
CursorRow	EQU Heap + 3

;Some ASCII codes with special handling during PrintCharText
CS 	EQU 1   ;CS: Clear Screen      
HM 	EQU 2   ;HM: HoMe cursor       
NL 	EQU 13  ;NL: New Line
CR 	EQU 13  ;CR: Carriage return == NL       
LF 	EQU 10  ;LF: Line Feed       
ML 	EQU  3  ;ML: Move cursor Left          
MR 	EQU  4  ;MR: Move cursor Right         
MU 	EQU  5  ;MU: Move cursor Up          
MD 	EQU  6  ;MD: Move cursor Down
TB 	EQU  9  ;TB: TaB        
BS 	EQU  8  ;BS: BackSpace  

;--------------------------------------
fpuBase	EQU 0xF0	; I/O Mapped version
;fpuBase		EQU 0x0E00	; Mem Mapped version
;-- write access ----------------------
fpuId		EQU fpuBase + 0
fpuOperation	EQU fpuBase + 2
fpuOperand1Lo	EQU fpuBase + 4
fpuOperand1Hi	EQU fpuBase + 6
fpuOperand2Lo	EQU fpuBase + 8
fpuOperand2Hi	EQU fpuBase + 10
;-- read access -----------------------
fpuDone		EQU fpuBase + 0
fpuStatus	EQU fpuBase + 2
fpuResultLo	EQU fpuBase + 4
fpuResultHi	EQU fpuBase + 6
fpuCycles	EQU fpuBase + 8

;---------------------------------------
; bus tracer "registers"
;---------------------------------------
busTracer	EQU 0x03c0;
btMemRead	EQU busTracer + 0
btMemWrite	EQU busTracer + 4
btIoRead	EQU busTracer + 8
btIoWrite	EQU busTracer + 12
btFetch		EQU	busTracer + 16
btIntAck	EQU busTracer + 20


