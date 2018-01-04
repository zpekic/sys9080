Goal:

Implement i8080 compatible processor code in VHDL, using bit-slice technology and microcoding.

Background:

Retro-computing is fun and rich in learning. One fascinating aspect is bit-slice technology popular in 1970-ies, which was naturally combined with microcoded processor architectures. In some ways, it was another take on the idea of "programmable" logic, within the limits of the day. Researching the era, I stumbled upon following article:

https://en.wikichip.org/w/images/7/76/An_Emulation_of_the_Am9080A.pdf

AMD engineers describe building an "Am9080" CPU (i8080 second-sourced) using popular Amd29XX bit-slice product. The description was very detailed, including circuit schemas and microcode, and it seemed like a fun project to "reverse-engineer" (given that the article was written 30+ years ago, hoping not to run into any copyright issues...) and re-implement in VHDL. 

Debugging:

Very simple hardware debugging was used - a single step circuit combined with key signals from the guts of the processor (such as microinstruction address and data word, macro instruction register, register contents etc.) being exposed through 16-bit "debug" bus to LED display. Simple "test" assembler programs executed allowed instruction execution to be observed clock by clock cycle and fixed. The original microcode listing contained a few bugs that prevented for example RST n to function well when presented at INTA cycle.

Testing:

Instead of boring test bench, I decided to write an equivalent of once popular "evaluation system" boards, containing:

-2 kB ROM
-256 bytes RAM
-2 ACIA (UART) 
-parallel I/O port
-interrupt controller
-varible clock circuitry (from 1Hz to 25MHz)

Such system boards came with basic bootstrap loaders and monitors. The fact that the system can run and execute (most) commands of Altair monitor is encouraging, and sufficient to merit "beta" status. This is how it looks in "action": https://imgur.com/a/yNfA8


Hardware used:

* Micronova Mercury FPGA development board https://www.micro-nova.com/mercury/
* Mercury baseboard https://www.micro-nova.com/mercury-baseboard/
* Parallax USB2SER development board https://www.parallax.com/product/28024

Development tools:

* Xilinx ISE 14.7 (nt) - free version

* Zmac 8080/Z80 assembler for PC http://48k.ca/zmac.html 
Used to assemble the boot.asm and slighly changed AltMon.asm into *.hex files which are then loaded to 2 ROMs during VHDL compile

* Parallax Propeller IDE serial terminal
Probably most other generic serial terminal window programs can be used

Software and code (re)used:

* Altair monitor program by Mike Douglas http://altairclone.com/downloads/roms/Altair%20Monitor/
Minimal changes to assemble to address 0x0400 etc.

* VHDL uart-for-fpga by Jakub Cabal (https://github.com/jakubcabal/uart-for-fpga) 
The "ACIA" component wraps it to expose to CPU a "device" somewhat similar to classic MC6850 ACIA

* VHDL Am2901 by Amr Nasr (https://github.com/Amrnasr/AM2901)
In current iteration this is replaced by my own simpler VHDL Am2901c, but this was the inspiration

* VHDL Am2909 by Stanislaw Deniziak (http://achilles.tu.kielce.pl/Members/sdeniziak/studia-magisterskie/mikroprogramowanie-ii/materia142y-pomocnicze/am2909.vhd/view)
 
Possible next steps:

- run 8080 instruction verification program
- use audio in/out ports on baseboard for casette tape "mass storage" :-)
- port to other FPGA boards with more resources, possibly creating a CP/M microcomputer
- implement 8085 instruction set
- use in other projects

Known problems:

- interrupt ack only works for RST n instructions, not CALL. However, few if any 8080 systems used the latter
- the processor implementation is clunky - clean "RTL" state machine would be much more optimized and smaller / faster than many components and subcomponents I had to write to replicate 74XX-type logic as individual "ICs". However it is fun to see "guts" of processors as they used to be in that era.

It would be exciting to see if somebody could use this core in their own projects. If so, shoot me an email to zpekic@hotmail.com