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
-- Description: 
-- 
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
				-- SW(1 downto 0) -- LED display selection
				--   0	0  Sys9080 - A(7:0) & D(7:0) & io and memory r/w on dots
				--   0   1  Sys9080 - OUT port 1 & port 0
				--   1   0  Am9080 - microinstruction counter & instruction register
				--   1   1  Am9080 - content of register as defined by SW5:2
				-- SW(5 downto 2) -- 4 bit Am9080 register selector when inspecting register states in SS mode
				-- SW(6 downto 5) -- system clock speed 
				--   0   0	1Hz	(can be used with SS mode)
				--   0   1	1024Hz (can be used with SS mode)
				--   1   0  6.125MHz
				--   1   1  25MHz
				-- SW7
				--   0   single step mode off (BTN3 should be pressed once to start the system)
				--   1   single step mode on (use with BTN3)
				SW: in std_logic_vector(7 downto 0); 
				-- Push buttons on baseboard
				-- BTN0 - generate RST 7 interrupt which will dump processor regs and memory they are pointing to over ACIA0
				-- BTN1 - bypass ACIA Rx char input processing and dump received bytes and status to ACIA0
				-- BTN2 - put processor into HOLD mode
				-- BTN3 - single step clock cycle forward if in SS mode (NOTE: single press on this button is needed after reset to unlock SS circuit)
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

component debouncer8channel is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           signal_raw : in STD_LOGIC_VECTOR (7 downto 0);
           signal_debounced : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component clockgen is
    Port ( CLK : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
           baudrate_sel : in  STD_LOGIC_VECTOR (2 downto 0);
           cpuclk_sel : in  STD_LOGIC_VECTOR (2 downto 0);
			  pulse : in STD_LOGIC;
           cpu_clk : out  STD_LOGIC;
           debounce_clk : out  STD_LOGIC;
           vga_clk : out  STD_LOGIC;
           baudrate_x4 : out  STD_LOGIC;
           baudrate : out  STD_LOGIC;
           freq100Hz : out  STD_LOGIC;
           freq50Hz : out  STD_LOGIC;
			  freq1Hz : out STD_LOGIC);
end component;


component fourdigitsevensegled is
    Port ( -- inputs
			  data : in  STD_LOGIC_VECTOR (15 downto 0);
           digsel : in  STD_LOGIC_VECTOR (1 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (3 downto 0);
           showdot : in  STD_LOGIC_VECTOR (3 downto 0);
           showsegments : in  STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (3 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component uart is
    Port ( reset : in  STD_LOGIC;
			  clk: in STD_LOGIC;
           clk_txd : in  STD_LOGIC;
           clk_rxd : in  STD_LOGIC;
           nCS : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           RS : in  STD_LOGIC;
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
			  ---
			  debug: out std_logic_vector(15 downto 0);
			  --- 
           TXD : out  STD_LOGIC;
           RXD : in  STD_LOGIC);
end component;

--component ACIA is Generic (
--			  BAUDRATE: integer := 115200 -- baud rate value
--			);
--		Port(
--           clk : in STD_LOGIC;
--           reset: in STD_LOGIC;
--			  D: inout STD_LOGIC_VECTOR(7 downto 0);
--			  A: in STD_LOGIC;
--           nRead: in STD_LOGIC;
--           nWrite: in STD_LOGIC;
--			  nSelect: in STD_LOGIC;
--			  IntReq: out STD_LOGIC;
--			  IntAck: in STD_LOGIC;
--			  txd: out STD_LOGIC;
--			  rxd: in STD_LOGIC;
--			  rts: out STD_LOGIC;
--			  cts: in STD_LOGIC
--			);
--end component;

component simpleram is
	 generic (
		address_size: integer;
		default_value: STD_LOGIC_VECTOR(7 downto 0)
	  );
    Port (       
			  clk: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end component;

--component hexfilerom is
--	 Generic (
--			filename: string;
--			address_size: integer;
--			default_value: STD_LOGIC_VECTOR(7 downto 0)
--		);
--    Port (           
--			  D : out  STD_LOGIC_VECTOR (7 downto 0);
--           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
--           nRead : in  STD_LOGIC;
--           nSelect : in  STD_LOGIC
--			 );
--end component;

component rom1k is
	generic (
		filename: string := "";
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"00"
	);
	Port ( 
		A : in  STD_LOGIC_VECTOR (9 downto 0);
		nOE : in  STD_LOGIC;
		D : out  STD_LOGIC_VECTOR (7 downto 0)
	);
end component;

component Am9080a is
    Port ( DBUS : inout  STD_LOGIC_VECTOR (7 downto 0);
			  ABUS : out STD_LOGIC_VECTOR (15 downto 0);
           WAITOUT : out  STD_LOGIC;
           nINTA : out  STD_LOGIC;
           nIOR : out  STD_LOGIC;
           nIOW : out  STD_LOGIC;
           nMEMR : out  STD_LOGIC;
           nMEMW : out  STD_LOGIC;
           HLDA : out  STD_LOGIC;
			  INTE : out STD_LOGIC;
           CLK : in  STD_LOGIC;
           nRESET : in  STD_LOGIC;
			  INT: in STD_LOGIC;
			  READY: in STD_LOGIC;
			  HOLD: in STD_LOGIC;
			  -- debug port, not part of actual processor
           debug_sel : in  STD_LOGIC;
			  debug_reg : in STD_LOGIC_VECTOR(2 downto 0);
           debug_out : out  STD_LOGIC_VECTOR (19 downto 0)
			);
end component;

-- Connect to PmodUSBUART 
-- https://digilent.com/reference/pmod/pmodusbuart/reference-manual
alias PMOD_RTS: std_logic is PMOD(0);	
alias PMOD_RXD: std_logic is PMOD(1);
alias PMOD_TXD: std_logic is PMOD(2);
alias PMOD_CTS: std_logic is PMOD(3);	

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
signal reset_delay: std_logic_vector(3 downto 0) := "1111";
signal IntReq, Hold, HoldAck, IntE: std_logic;

-- other signals
signal debug: std_logic_vector(15 downto 0);

signal switch: std_logic_vector(7 downto 0);
alias sw_display_cpu: std_logic is switch(7);
alias sw_displaycpu_seq: std_logic is switch(6);
alias sw_displaycpu_reg: std_logic_vector(2 downto 0) is switch(5 downto 3);
alias sw_bus_break: std_logic_vector(3 downto 0) is switch(6 downto 3);
alias sw_clock_sel: std_logic_vector(2 downto 0) is switch(2 downto 0);

signal button: std_logic_vector(3 downto 0);
alias btn_ss: std_logic is button(0);

signal led_bus: std_logic_vector(19 downto 0);
signal cpu_debug_bus, sys_debug_bus: std_logic_vector(19 downto 0);
signal nIoEnable, nACIA0Enable, nACIA1Enable, nBootRomEnable, nMonRomEnable, nRamEnable: std_logic;
signal showsegments: std_logic;
signal flash: std_logic;

-- clock
signal freq1Hz, freq50Hz, freq100Hz, baudrate, baudrate_x4: std_logic; 
signal debounce_clk, cpu_clk: std_logic;

begin
   
	 Reset <= '0' when (reset_delay = "0000") else '1';
	 --nReset <= '0' when (Reset = '1') or (reset_delay /= "0000") else '1'; 
	 
	 led_bus <= cpu_debug_bus when (sw_display_cpu = '1') else sys_debug_bus;
--	 sys_debug_bus <= (control_bus(3 downto 0) xor "1111") & address_bus(7 downto 0) & data_bus;
	 sys_debug_bus <= (control_bus(3 downto 0) xor "1111") & debug; --address_bus(7 downto 0) & data_bus;
 
	 showsegments <= sw_display_cpu when (control_bus = "11111") else '1';

	 Hold <= '0';--button(2);
	 flash <= '1'; --HoldAck or freq1Hz; -- blink in hold bus mode!
	 -- USE AUDIO FOR CASETTE OUTPUT
	 --cassette_out <= freq1200 when PMOD(2) = '1' else freq2400;
	 AUDIO_OUT_L <= '0'; --freq1200; --cassette_out; 
	 AUDIO_OUT_R <= '0'; --freq2400; --cassette_out;
	 -- DISPLAY
	 LED(3) <= PMOD_CTS; --Reset;  
	 LED(2) <= PMOD_RXD; --not nIntAck;  
	 LED(1) <= PMOD_TXD; --HoldAck; 
	 LED(0) <= PMOD_RTS; --cpu_clk;  
    led4x7: fourdigitsevensegled port map ( 
			  -- inputs
			  data => led_bus(15 downto 0),
           digsel(1) => freq50Hz,
			  digsel(0) => freq100Hz,
			  showdigit => "1111",
           showdot => led_bus(19 downto 16),
           showsegments => showsegments,
			  -- outputs
           anode => AN,
           segment(6 downto 0) => A_TO_G(6 downto 0),
			  segment(7) => DOT
			 );

   -- FREQUENCY GENERATOR
-- generate various frequencies
clocks: clockgen Port map ( 
		CLK => CLK, 				-- 50MHz on Mercury board
		RESET => USR_BTN,
		baudrate_sel => "111",	-- 57600
		cpuclk_sel =>	 sw_clock_sel,
		pulse => btn_ss,
		cpu_clk => cpu_clk,
		debounce_clk => debounce_clk,
		vga_clk => open,
		baudrate_x4 => baudrate_x4,
		baudrate => baudrate,
		freq100Hz => freq100Hz,
		freq50Hz => freq50Hz,
		freq1Hz => freq1Hz
		);
	

	-- DEBOUNCE the 8 switches and 4 buttons (plus "Reset" on Mercury board)
    debouncer_sw: debouncer8channel port map (
        clock => debounce_clk,
        reset => Reset,
        signal_raw => SW,
        signal_debounced => switch
    );

    debouncer_btn: debouncer8channel port map (
        clock => debounce_clk,
        reset => Reset,
		  signal_raw(7 downto 4) => "0000",
        signal_raw(3 downto 0) => BTN,
		  signal_debounced(7 downto 4) => open,
        signal_debounced(3 downto 0) => button
    );

	-- delay to generate nReset 4 cycles after reset
	generate_Reset: process (cpu_clk, USR_BTN)
	begin
		if (USR_BTN = '1') then
			reset_delay <= "1111";
		else
			if (rising_edge(cpu_clk)) then
				reset_delay <= reset_delay(2 downto 0) & USR_BTN;
			end if;
		end if;
	end process;
	
	nIoEnable <= (nIoRead and nIoWrite) when address_bus(7 downto 4) = "0000" else '1'; 		-- 0x00 - 0x0F
	nACIA0Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001000" else '1'; -- 0x10 - 0x11
	nACIA1Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001001" else '1'; -- 0x12 - 0x13
	nBootRomEnable <= nMemRead when address_bus(15 downto 10) = "000000" else '1'; -- 1k ROM (0000 - 03FF)
	--nBootRomEnable <= nMemRead when address_bus(15 downto 9) = "0000000" else '1'; -- 512b ROM (0000 - 01FF)
	nMonRomEnable <= nMemRead when address_bus(15 downto 10)  = "000001" else '1'; -- 1k ROM (0400 - 07FF)
	nRamEnable <= (nMemRead and nMemWrite) when address_bus(15 downto 8) = "11111111" else '1'; -- 256b RAM (FF00 - FFFF)
	--nRamEnable <= (nMemRead and nMemWrite) when address_bus(15 downto 7) = "111111111" else '1'; -- 128b RAM (FF80 - FFFF)
	
acia0: uart Port map (
			reset => Reset,
			clk => cpu_clk,
			clk_txd => baudrate,
			clk_rxd => baudrate_x4,
			nCS => nACIA0Enable,
			nRD => nIORead,
			nWR => nIOWrite,
			RS => address_bus(0),
			D => data_bus,
			debug => debug,
			TXD => PMOD_RXD,
			RXD => PMOD_TXD
		);
	
--	acia0: ACIA Generic map(
--				BAUDRATE => 19200 -- baud rate value
--			)
--			port map(
--			  clk => CLK, -- this is the full 50MHz clock!
--			  reset => Reset,
--			  D => data_bus,
--			  A => address_bus(0),
--           nRead => nIORead,
--           nWrite => nIOWrite,
--			  nSelect => nAcia0Enable,
--			  IntReq => open,
--			  IntAck => '0',
--			  txd => PMOD_TXD,
--			  rxd => PMOD_RXD,
--			  rts => open,
--			  cts => '0'
--	);
--
--	acia1: ACIA Generic map(
--				BAUDRATE => 300 -- baud rate value
--			)
--			port map(
--			  clk => CLK, -- this is the full 50MHz clock!
--			  reset => Reset,
--			  D => data_bus,
--			  A => address_bus(0),
--			  nRead => nIORead,
--			  nWrite => nIOWrite,
--			  nSelect => nAcia1Enable,
--			  IntReq => open,
--			  IntAck => '0',
--			  txd => open,
--			  rxd => '1',				  
--			  rts => open,
--			  cts => '0'
--	);

	bootrom: rom1k generic map(
		filename => "..\prog\zout\boot.hex",
		default_value => X"76" -- HLT
	)	
	port map(
		D => data_bus,
		A => address_bus(9 downto 0),
		nOE => nBootRomEnable
	);
	
--	bootrom: hexfilerom 
--		generic map(
--			filename => "../prog/zout/boot.hex",
--			address_size => 10,
--			default_value => X"FF" -- if executed, will be RST 7
--			)	
--		port map(
--			  D => data_bus,
--			  A => address_bus(9 downto 0),
--           nRead => nMemRead,
--			  nSelect => nBootRomEnable
--		);

--	monrom: hexfilerom 
--		generic map(
--			filename => "../prog/zout/altmon.hex",
--			address_size => 10,
--			default_value => X"FF" -- if executed, will be RST 7
--			)	
--		port map(
--			  D => data_bus,
--			  A => address_bus(9 downto 0),
--           nRead => nMemRead,
--			  nSelect => nMonRomEnable
--		);

	monrom: rom1k generic map(
		filename => "..\prog\zout\altmon.hex",
		default_value => X"76" -- HLT
	)	
	port map(
		D => data_bus,
		A => address_bus(9 downto 0),
		nOE => nMonRomEnable
	);
	
	ram: simpleram 
		generic map(
			address_size => 8,
			default_value => X"76" -- if executed, will be HLT
			)	
		port map(
			  clk => cpu_clk,
			  D => data_bus,
			  A => address_bus(7 downto 0),
           nRead => nMemRead,
			  nWrite => nMemWrite,
			  nSelect => nRamEnable
		);
		
	cpu: Am9080a port map (
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
			  READY => '1', -- TODO - use to implement single stepping per instruction, not cycle
			  HOLD => Hold, 
			  -- debug port, not part of actual processor
           debug_sel => sw_displaycpu_seq,
			  debug_reg => sw_displaycpu_reg,
           debug_out => cpu_debug_bus
			);
	 
end;
