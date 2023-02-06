;--------------------------------------------------------------------------
; "fast" plot for TIM-011 (with "clear screen" test routine)
; 		(c) zpekic@hotmail.com - 2020
;--------------------------------------------------------------------------
	org 0x0800	; some place in ROM or RAM

; ------------------------------------------------------------	
; test routine - fill screen with all 4 colors and then return
; ------------------------------------------------------------
testplot	ld de, 3	;colors from 3 downto 0
c_loop		ld bc, 255	;Y from 255 downto 0
y_loop		ld hl, 511	;X from 511 downto 0

x_loop		call fastplot

		ld a, h		;X == 0?
		or l
		jz y_next
		dec hl		;X--
		jmp x_loop	

y_next		ld a, b		;Y == 0?
		or c
		jz c_next
		dec bc		;Y--
		jmp y_loop

c_next		ld a, d		;color == 0?
		or e
		rz		;yes, all colors drawn, return
		dec de
		jmp c_loop

; -------------------------------------------------------
; Set pixel on TIM-011 screen, call with:
; HL = X (normalize to 0..511) 
; BC = Y (normalize to 0..255), 
; DE = color (normalize to 0..3)
; Note: byte address is 1yyyyyyy yxxxxxxx in 64k I/O space
; -------------------------------------------------------
fastplot	push af		;save regs
		push bc		;????????yyyyyyyy
		push de		;??????????????cc
		push hl		;???????xxxxxxxxx

;--- handle Y
		ld b, c		;BC = yyyyyyyyyyyyyyyy 
		ld c, 0x00	;BC = yyyyyyyy00000000 (sanitize Y)
		scf	
		rr b		;BC = 1yyyyyyy00000000, CY = y0
		rr c		;BC = 1yyyyyyyy0000000
				
;--- handle X and color
		ld a, h
		and a, 0x01	
		ld h, a		;HL = 0000000xxxxxxxxx (sanitize X)	

		ld d, 0x00
		ld a, e
		and a, 0x03
		ld e, a		;DE = 00000000000000cc (sanitize color)

		sra h		;HL = 00000000xxxxxxxx, CY = x8
		rr l		;HL = 00000000xxxxxxxx, CY = x0
		rl d		;DE = 0000000000000ccx
		sra l		;HL = 000000000xxxxxxx, CY = x1
		rl d		;DE = 000000000000ccxx, note C1 C0 X0 X1 (lower 2 x-bits reversed!)
					
;--- create video RAM base address
		add hl, bc	;HL = 1yyyyyyyyxxxxxxx
		ld c, l
		ld b, h		;BC = 1yyyyyyyyxxxxxxx (video RAM address for indirect I/O)

;--- apply to video RAM
		in a, (c)	;load byte from video RAM
		
		ld hl, mask_clr
		add hl, de
		and (hl)	;clear appropriate 2 bits

		ld hl, mask_set
		add hl, de
		or (hl)		;set same 2 bits with right color

		out (c), a	;write back to video RAM

;--- 
		pop hl		;restore and return
		pop de
		pop bc
		pop af
		ret

;masks for clearing bits for x mod 3 (color is not important)
mask_clr	db 11001111b, 11111100b, 00111111b, 11110011b;	color 0: pix 0, 2, 1, 3 
		db 11001111b, 11111100b, 00111111b, 11110011b;	color 1: pix 0, 2, 1, 3 
		db 11001111b, 11111100b, 00111111b, 11110011b;	color 2: pix 0, 2, 1, 3 
		db 11001111b, 11111100b, 00111111b, 11110011b;	color 3: pix 0, 2, 1, 3 

;masks for setting bits for x mod 3 (color is taken into account)
mask_set	db 00000000b, 00000000b, 00000000b, 00000000b; 	color 0: pix 0, 2, 1, 3 
		db 00010000b, 00000001b, 01000000b, 00000100b; 	color 1: pix 0, 2, 1, 3 
		db 00100000b, 00000010b, 10000000b, 00001000b; 	color 2: pix 0, 2, 1, 3 
		db 00110000b, 00000011b, 11000000b, 00001100b; 	color 3: pix 0, 2, 1, 3 
