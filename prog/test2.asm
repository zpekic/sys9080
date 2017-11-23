switch_lsb 	.equ 0x0 ;port 0 when reading
switch_msb	.equ 0x1 ;port 1 when reading
leds_lsb	.equ 0x0 ;port 0 when writing
leds_msb	.equ 0x1 ;port 1 when writing
		
		.org 0x0
		di
loop: 		lxi d, 0xddee
		lxi b, 0xbbcc
		lxi h, 0xffff
		sphl
		mov a, c
		out leds_lsb
		mov a, b
		out leds_msb
		mov a, e
		out leds_lsb
		mov a, d
		out leds_msb
		mov a, l
		out leds_lsb
		mov a, h
		out leds_msb
		jnz loop; dead loop because a is !0
		hlt


