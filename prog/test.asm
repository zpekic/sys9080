switch_lsb 	.equ 0x0 ;port 0 when reading
switch_msb	.equ 0x1 ;port 1 when reading
leds_lsb	.equ 0x0 ;port 0 when writing
leds_msb	.equ 0x1 ;port 1 when writing
		
		.org 0x0
		di
loop: 		in switch_lsb
		inr a
		out leds_lsb
		in switch_msb
		xra a
		out leds_msb
		jz loop
		hlt


