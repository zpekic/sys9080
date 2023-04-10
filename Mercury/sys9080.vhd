----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date: 08/24/2017 11:13:02 PM
-- Design Name: 
-- Module Name: sys9080 - Behavioral
-- Project Name: Simple 8-bit system around microcode implemented Am9080 CPU
-- Target Devices: https://www.micro-nova.com/mercury/ + Baseboard
-- Tool Versions: ISE 14.7 (nt)
-- Description:	https://hackaday.io/project/190239-from-bit-slice-to-basic-and-symbolic-tracing
-- 					https://github.com/zpekic/sys9080
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.99 - Kinda works...
-- Additional Comments:
-- https://en.wikichip.org/w/images/7/76/An_Emulation_of_the_Am9080A.pdf
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sys9080 is
    Port ( 
				-- 50MHz on the Mercury board
				CLK: in std_logic;
				-- Master reset button on Mercury board
				USR_BTN: in std_logic; 
				-- Switches on baseboard
				SW: in std_logic_vector(7 downto 0); 
				-- Push buttons on baseboard
				BTN: in std_logic_vector(3 downto 0); 
				-- Stereo audio output on baseboard
				AUDIO_OUT_L, AUDIO_OUT_R: out std_logic;
				-- 7seg LED on baseboard 
				A_TO_G: out std_logic_vector(6 downto 0); 
				AN: out std_logic_vector(3 downto 0); 
				DOT: out std_logic; 
				-- 4 LEDs on Mercury board
				LED: out std_logic_vector(3 downto 0);
				-- ADC interface
				-- channel	input
				-- 0			Audio Left
				-- 1 			Audio Right
				-- 2			Temperature
				-- 3			Light	
				-- 4			Pot
				-- 5			Channel 5 (free)
				-- 6			Channel 6 (free)
				-- 7			Channel 7 (free)
				--ADC_MISO: in std_logic;
				--ADC_MOSI: out std_logic;
				--ADC_SCK: out std_logic;
				--ADC_CSN: out std_logic;
				--PMOD interface
				PMOD: inout std_logic_vector(7 downto 0)

          );
end sys9080;

architecture Structural of sys9080 is

-- Connect to PmodUSBUART 
-- https://digilent.com/reference/pmod/pmodusbuart/reference-manual
alias PMOD_RTS0: std_logic is PMOD(0);	
alias PMOD_RXD0: std_logic is PMOD(1);
alias PMOD_TXD0: std_logic is PMOD(2);
alias PMOD_CTS0: std_logic is PMOD(3);	
alias PMOD_RTS1: std_logic is PMOD(4);
alias PMOD_RXD1: std_logic is PMOD(5);
alias PMOD_TXD1: std_logic is PMOD(6);
alias PMOD_CTS1: std_logic is PMOD(7);

-- CPU buses
signal data_bus: std_logic_vector(7 downto 0);
signal address_bus: std_logic_vector(15 downto 0);
signal control_bus: std_logic_vector(4 downto 0);
alias	nIntAck: std_logic is control_bus(4);
alias nIORead: std_logic is control_bus(3);
alias nIOWrite: std_logic is control_bus(2); 
alias nMemRead: std_logic is control_bus(1); 
alias nMemWrite: std_logic is control_bus(0);
signal Reset: std_logic;
signal IntReq, Hold, HoldAck, IntE, Ready, m1: std_logic;

-- other signals
signal debug: std_logic_vector(15 downto 0);
signal reset_delay: std_logic_vector(3 downto 0) := "1111";

-- 8 baseboard on/off switches
signal switch: std_logic_vector(7 downto 0);
-- display cpu or bus
alias sw_display_bus: std_logic is switch(7);
-- when displaying cpu
alias sw_displaycpu_seq: std_logic is switch(6);
alias sw_displaycpu_reg: std_logic_vector(2 downto 0) is switch(5 downto 3);
-- when displaying bus
alias sw_tracesel: std_logic_vector(4 downto 0) is switch(7 downto 3);
-- either
alias sw_clock_sel: std_logic_vector(2 downto 0) is switch(2 downto 0);

-- 4 baseboard push buttons (1 when pressed)
signal button: std_logic_vector(7 downto 0);
alias btn_traceload: std_logic is button(3);
alias btn_clk: std_logic is button(0);

signal inport: std_logic_vector(7 downto 0);
signal led_bus: std_logic_vector(23 downto 0);
signal cpu_debug_bus, sys_debug_bus: std_logic_vector(19 downto 0);
signal nPort0Enable, nPort1Enable, nACIA0Enable, nACIA1Enable: std_logic;
signal nTinyRomEnable, nBootRomEnable, nMonRomEnable, nRamEnable: std_logic;
signal showsegments: std_logic;
signal rts1_delay, rts1_pulse, continue: std_logic;

-- clock
signal freq1Hz, freq64Hz, freq128Hz: std_logic; 
signal debounce_clk, cpu_clk: std_logic;

signal baudrate: std_logic_vector(11 downto 0);
alias baud_153600: std_logic is baudrate(0);
alias baud_76800: std_logic is baudrate(1);
alias baud_38400: std_logic is baudrate(2);
alias baud_19200: std_logic is baudrate(3);
alias baud_9600: std_logic is baudrate(4);
alias baud_4800: std_logic is baudrate(5);
alias baud_2400: std_logic is baudrate(6);
alias baud_1200: std_logic is baudrate(7);
alias baud_600: std_logic is baudrate(8);
alias baud_300: std_logic is baudrate(9);

-- not used
signal audio_out: std_logic;

begin
   
	 Reset <= '0' when (reset_delay = "0000") else '1';
	 
	 led_bus <= (cpu_clk & "00" & freq1Hz 			& cpu_debug_bus) when (sw_display_bus = '0') else 
					(cpu_clk & Ready & continue & m1 & sys_debug_bus);
	 sys_debug_bus <= (control_bus(3 downto 0) xor "1111") & address_bus(7 downto 0) & data_bus;
 
	 -- flash 7seg when stopped due to READY low
	 showsegments <= freq1Hz or Ready;

	 -- USE AUDIO FOR CASETTE OUTPUT
	 AUDIO_OUT_L <= audio_out; 
	 AUDIO_OUT_R <= audio_out;

	 -- DISPLAY
	 LED <= led_bus(23 downto 20);
	 --LED(0) <= PMOD_RTS0;
	 --LED(1) <= PMOD_CTS0;
	 --LED(2) <= PMOD_RTS1;
	 --LED(3) <= PMOD_CTS1;
	 
    led4x7: entity work.fourdigitsevensegled port map ( 
			  -- inputs
			  data => led_bus(15 downto 0),
           digsel(1) => freq64Hz,
			  digsel(0) => freq128Hz,
			  showdigit => "1111",
           showdot => led_bus(19 downto 16),
           showsegments => showsegments,
			  -- outputs
           anode => AN,
           segment(6 downto 0) => A_TO_G(6 downto 0),
			  segment(7) => DOT
			 );

-- FREQUENCY GENERATOR
clocks: entity work.clockgen Port map ( 
		CLK => CLK, 				-- 50MHz on Mercury board
		RESET => USR_BTN,
		baudrate_sel => "110",	-- 38400
--		baudrate_sel => "111",	-- 57600
		cpuclk_sel =>	 sw_clock_sel,
		pulse => btn_clk,
		cpu_clk => cpu_clk,
		debounce_clk => debounce_clk,
		vga_clk => open,
		baudrate => baudrate,
		freq128Hz => freq128Hz,
		freq64Hz => freq64Hz,
		freq1Hz => freq1Hz
		);

-- debouncers removed due to lack of FPGA space :-(
	switch <= SW;
	button <= "0000" & BTN;

	-- delay to generate nReset 4 cycles after reset
	generate_Reset: process (cpu_clk, USR_BTN)
	begin
		if (USR_BTN = '1') then
			reset_delay <= "1111";
		else
			if (rising_edge(cpu_clk)) then
				reset_delay <= reset_delay(2 downto 0) & USR_BTN;
				rts1_delay <= PMOD_RTS1;
			end if;
		end if;
	end process;
	
-- Enable bus devices
	nACIA0Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001000" else '1'; -- 0x10 - 0x11
	nACIA1Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001001" else '1'; -- 0x12 - 0x13

	nTinyRomEnable <= nMemRead when address_bus(15 downto 11) =	"00000" else '1'; -- 2k ROM (0000 - 07FF)
	nBootRomEnable <= nMemRead when address_bus(15 downto 10) =	"000000" else '1'; -- 1k ROM (0000 - 03FF)
	nMonRomEnable <= 	nMemRead when address_bus(15 downto 10) =	"000001" else '1'; -- 1k ROM (0400 - 07FF)
	nRamEnable <= '1' 			when address_bus(15 downto 11) =	"00000" else (nMemRead and nMemWrite); -- RAM repeats everywhere outside ROM space
	
-- read switches and buttons as ports 0 and 1
inport <= switch when (address_bus(0) = '0') else button;
data_bus <= inport when (nIORead = '0' and (address_bus(7 downto 4) = "0000")) else "ZZZZZZZZ";

acia0: entity work.uart Port map (
			reset => Reset,
			clk => cpu_clk,
			clk_txd => baud_38400,	-- x1
			clk_rxd => baud_153600,	-- x4
			nCS => nACIA0Enable,
			nRD => nIORead,
			nWR => nIOWrite,
			RS => address_bus(0),
			D => data_bus,
			debug => open,
			TXD => PMOD_RXD0,
			RXD => PMOD_TXD0
		);

--acia1: uart Port map (
--			reset => Reset,
--			clk => cpu_clk,
--			clk_txd => baudrate,
--			clk_rxd => baudrate_x4,
--			nCS => nACIA1Enable,
--			nRD => nIORead,
--			nWR => nIOWrite,
--			RS => address_bus(0),
--			D => data_bus,
--			debug => open,
--			TXD => PMOD_RXD1,
--			RXD => PMOD_TXD1
--		);
		
-- ROM 2k at 0000H to 07FFH
-- See http://cpuville.com/Code/tiny_basic_instructions.pdf
	tinyrom: entity work.rom1k generic map(
		address_size => 11,
		filename => "..\prog\zout\tinybasic2dms.hex",
		default_value => X"76" -- HLT
	)	
	port map(
		D => data_bus,
		A => address_bus(10 downto 0),
		nOE => nTinyRomEnable
	);

--	bootrom: entity work.rom1k generic map(
--		address_size => 10,
--		filename => "..\prog\zout\boot.hex",
--		default_value => X"76" -- HLT
--	)	
--	port map(
--		D => data_bus,
--		A => address_bus(9 downto 0),
--		nOE => nBootRomEnable
--	);
--	
--	monrom: entity work.rom1k generic map(
--		address_size => 10,
--		filename => "..\prog\zout\altmon.hex",
--		default_value => X"76" -- HLT
--	)	
--	port map(
--		D => data_bus,
--		A => address_bus(9 downto 0),
--		nOE => nMonRomEnable
--	);
	
-- RAM 2k (repeated across 64k address space where no ROM is present)
	ram: entity work.simpleram 
		generic map(
			address_size => 11,
			default_value => X"76" -- if executed, will be HLT
			)	
		port map(
			  clk => cpu_clk,
			  D => data_bus,
			  A => address_bus(10 downto 0),
           nRead => nMemRead,
			  nWrite => nMemWrite,
			  nSelect => nRamEnable
		);
		
-- CPU (Intel 8080 compatible)
	Hold <= '0';	-- Not used
	IntReq <= '0';	-- Not used
	
	cpu: entity work.Am9080a port map (
			  DBUS => data_bus,
			  ABUS => address_bus,
           WAITOUT => open,
           nINTA => nIntAck,
           nIOR => nIORead,
           nIOW => nIOWrite,
           nMEMR => nMemRead,
           nMEMW => nMemWrite,
           HLDA => HoldAck,
			  INTE => IntE,
           CLK => cpu_clk,
           nRESET => not Reset,
			  INT => IntReq,
			  READY => Ready,
			  HOLD => Hold, 
			  M1 => m1,
			  -- debug port, not part of actual processor
           debug_sel => sw_displaycpu_seq,	-- allows inspection of microcode counter and instruction register
			  debug_reg => sw_displaycpu_reg,	-- allows inspection of any register pair
			  -- connecting this breaks the design as the modest FPGA is overmapped
           debug_out => open --cpu_debug_bus
			);
	 
-- Tracer watches system bus activity and if signal match is detected, freezes the CPU in 
-- the cycle by asserting low READY signal, and outputing the trace record to serial port
-- After that, cycle will continue if continue signal is high, or stop there.	 
	tracer: entity work.debugtracer Port map(
			reset => reset,
			cpu_clk => cpu_clk,
			txd_clk => baud_38400,
			continue => continue,  
			ready => ready,			-- freezes CPU when low
			txd => PMOD_RXD1,			-- output trace (to any TTY of special tracer running on the host
			load => btn_traceload,	-- load mask register if high
			sel => sw_tracesel,		-- set mask register: M1 & IOR & IOW & MEMR & MEMW;
			nM1 => not m1,
			nIOR => nIORead,
			nIOW => nIOWrite,
			nMEMR => nMemRead,
			nMEMW => nMemWrite,
			ABUS => address_bus,
			DBUS => data_bus
	);
	 
-- Tracer works best when the output is intercepted on the host and resolved using symbolic .lst file
-- In addition, host is able to flip RTS pin to start/stop tracing 
-- See https://github.com/zpekic/sys9080/blob/master/Tracer/Tracer/Program.cs
rts1_pulse <= PMOD_RTS1 xor rts1_delay;
on_rts1_pulse: process(reset, rts1_pulse)
begin
	if ((USR_BTN or btn_clk) = '1') then
		continue <= '1';
	else
		if (rising_edge(rts1_pulse)) then
			continue <= not continue;
		end if;
	end if;
end process;
 	 
end;
