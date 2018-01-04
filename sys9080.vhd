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
				--AUDIO_OUT_L, AUDIO_OUT_R: out std_logic;
				-- 7seg LED on baseboard 
				A_TO_G: out std_logic_vector(6 downto 0); 
				AN: out std_logic_vector(3 downto 0); 
				DOT: out std_logic; 
				-- 4 LEDs on Mercury board
				LED: out std_logic_vector(3 downto 0);
				-- ADC interface
				--ADC_MISO: in std_logic;
				--ADC_MOSI: out std_logic;
				--ADC_SCK: out std_logic;
				--ADC_CSN: out std_logic;
				--PMOD interface (for hex keypad)
				PMOD: inout std_logic_vector(7 downto 0)

          );
end sys9080;

architecture Structural of sys9080 is

component clock_divider is
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           slow : out  STD_LOGIC_VECTOR (11 downto 0);
           fast : out  STD_LOGIC_VECTOR (3 downto 0)
			 );
end component;

component clocksinglestepper is
    Port ( reset : in STD_LOGIC;
           clock0_in : in STD_LOGIC;
           clock1_in : in STD_LOGIC;
           clock2_in : in STD_LOGIC;
           clock3_in : in STD_LOGIC;
           clocksel : in STD_LOGIC_VECTOR(1 downto 0);
           modesel : in STD_LOGIC;
           singlestep : in STD_LOGIC;
           clock_out : out STD_LOGIC);
end component;

component counter16bit is
    Port ( reset : in STD_LOGIC;
           clk : in STD_LOGIC;
           mode : in STD_LOGIC_VECTOR (1 downto 0);
           d : in STD_LOGIC_VECTOR (31 downto 0);
           q : out STD_LOGIC_VECTOR (31 downto 0));
end component;

component debouncer8channel is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_raw : in  STD_LOGIC_VECTOR(7 downto 0);
           signal_debounced : out  STD_LOGIC_VECTOR(7 downto 0));
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

component simpledevice is 
		Port(
           clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  D: inout STD_LOGIC_VECTOR(7 downto 0);
			  A: in STD_LOGIC_VECTOR(3 downto 0);
           nRead: in STD_LOGIC;
           nWrite: in STD_LOGIC;
			  IntReq: out STD_LOGIC;
			  IntAck: in STD_LOGIC;			  
			  nSelect: in STD_LOGIC;
			  direct_in: in STD_LOGIC_VECTOR(15 downto 0);
			  direct_out: out STD_LOGIC_VECTOR(15 downto 0)
			);
end component;

component ACIA is 
		Port(
           clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  D: inout STD_LOGIC_VECTOR(7 downto 0);
			  A: in STD_LOGIC;
           nRead: in STD_LOGIC;
           nWrite: in STD_LOGIC;
			  nSelect: in STD_LOGIC;
			  IntReq: out STD_LOGIC;
			  IntAck: in STD_LOGIC;
			  txd: out STD_LOGIC;
			  rxd: in STD_LOGIC		  
			);
end component;

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

component hexfilerom is
	 Generic (
			filename: string;
			address_size: integer;
			default_value: STD_LOGIC_VECTOR(7 downto 0)
		);
    Port (           
			  D : out  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC
			 );
end component;

component interrupt_controller is
    Port ( CLK : in  STD_LOGIC;
           nRESET : in  STD_LOGIC;
           INT : out  STD_LOGIC;
           nINTA : in  STD_LOGIC;
           INTE : in  STD_LOGIC;
           D : out  STD_LOGIC_VECTOR (7 downto 0);
           DEVICEREQ : in  STD_LOGIC_VECTOR (7 downto 0);
           DEVICEACK : out  STD_LOGIC_VECTOR (7 downto 0));
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
           debug_ena : in  STD_LOGIC;
           debug_sel : in  STD_LOGIC;
           debug_out : out  STD_LOGIC_VECTOR (19 downto 0);
			  debug_reg : in STD_LOGIC_VECTOR(3 downto 0)
			);
end component;

--component ila_0 IS
--    PORT (
--        clk : IN STD_LOGIC;
--        probe0 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
--        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0));
--end component;

component vio_0 IS
PORT (
clk : IN STD_LOGIC;
probe_in0 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
probe_in1 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
probe_in2 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
probe_in3 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
probe_out0 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
probe_out1 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
probe_out2 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
probe_out3 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
);
END component;

-- CPU buses
signal data_bus: std_logic_vector(7 downto 0);
signal address_bus: std_logic_vector(15 downto 0);
signal Reset, nReset: std_logic;
signal clock_main: std_logic;
signal nIORead, nIOWrite, nMemRead, nMemWrite: std_logic;
signal IntReq, nIntAck, Hold, HoldAck, IntE: std_logic;

-- other signals
signal reset_delay: std_logic_vector(3 downto 0);
signal DeviceReq: std_logic_vector(7 downto 0);
signal DeviceAck: std_logic_vector(7 downto 0);
signal switch: std_logic_vector(7 downto 0);
signal button: std_logic_vector(7 downto 0);
--signal cnt: std_logic_vector(31 downto 0);
signal io_output: std_logic_vector(15 downto 0);
signal led_bus: std_logic_vector(19 downto 0);
signal cpu_debug_bus, sys_debug_bus: std_logic_vector(19 downto 0);
signal nIoEnable, nACIA0Enable, nACIA1Enable, nBootRomEnable, nMonRomEnable, nRamEnable: std_logic;
signal readwritesignals: std_logic_vector(4 downto 0);
signal showsegments: std_logic;
signal flash: std_logic;
signal freq2k, freq1k, freq512, freq256, freq128, freq64, freq32, freq16, freq8, freq4, freq2, freq1: std_logic;
signal freq25M, freq12M5, freq6M25, freq3M125: std_logic;

begin
   
	 Reset <= USR_BTN;
	 nReset <= '0' when (Reset = '1') or (reset_delay /= "0000") else '1'; 
	 
	 led_bus <= cpu_debug_bus when (switch(1) = '1') else sys_debug_bus;
	 sys_debug_bus <= readwritesignals(4 downto 1) & address_bus(7 downto 0) & data_bus when (switch(0) = '0') else "0000" & io_output;
	 
	 readwritesignals <= (not nIORead) & (not nIOWrite) & (not nMemRead) & (not nMemWrite) & (not nIntAck);
	 showsegments <= '0' when (switch(1 downto 0) = "00" and readwritesignals = "00000") else '1';

	 Hold <= button(2);
	 flash <= HoldAck or freq2; -- blink in hold bus mode!
	 -- DISPLAY
	 LED(3) <= nIntAck;  
	 LED(2) <= IntReq;  
	 LED(1) <= HoldAck; 
	 LED(0) <= clock_main;  
    led4x7: fourdigitsevensegled port map ( 
			  -- inputs
			  data => led_bus(15 downto 0),
           digsel(1) => freq1k,
			  digsel(0) => freq2k,
           showdigit(3) => flash,
           showdigit(2) => flash,
           showdigit(1) => flash,
           showdigit(0) => flash,
           showdot => led_bus(19 downto 16),
           showsegments => showsegments,
			  -- outputs
           anode => AN,
           segment(6 downto 0) => A_TO_G(6 downto 0),
			  segment(7) => DOT
			 );

    -- FREQUENCY GENERATOR
    one_sec: clock_divider port map 
    (
        clock => CLK,
        reset => Reset,
        slow(11) => freq1, -- 1Hz
        slow(10) => freq2, -- 2Hz
        slow(9) => freq4, -- 4Hz
        slow(8) => freq8, -- 8Hz
        slow(7) => freq16,  -- 16Hz
        slow(6) => freq32,  -- 32Hz
        slow(5) => freq64,  -- 64Hz
        slow(4) => freq128,  -- 128Hz
        slow(3) => freq256,  -- 256Hz
        slow(2) => freq512,  -- 512Hz
        slow(1) => freq1k,  -- 1024Hz
        slow(0) => freq2k,  -- 2048Hz
		  fast(3) => freq3M125,
		  fast(2) => freq6M25,
		  fast(1) => freq12M5,
		  fast(0) => freq25M
    );

	-- DEBOUNCE the 8 switches and 4 buttons
    debouncer_sw: debouncer8channel port map (
        clock => freq128,
        reset => Reset,
        signal_raw => SW,
        signal_debounced => switch
    );

    debouncer_btn: debouncer8channel port map (
        clock => freq128,
        reset => Reset,
        signal_raw(7 downto 4) => "1111",
        signal_raw(3 downto 0) => BTN(3 downto 0),
        signal_debounced => button
    );
	
	-- Hook up buttons to generate interrupts
	irq7: process(nReset, button(0), deviceack(7))
	begin
		if (nReset = '0' or deviceack(7) = '1') then
			devicereq(7) <= '0';
		else
			if (rising_edge(button(0))) then
				devicereq(7) <= '1';
			end if;
		end if;
	end process;

	irq6: process(nReset, button(1), deviceack(6))
	begin
		if (nReset = '0' or deviceack(6) = '1') then
			devicereq(6) <= '0';
		else
			if (rising_edge(button(1))) then
				devicereq(6) <= '1';
			end if;
		end if;
	end process;	
	
	-- delay to generate nReset 4 cycles after reset
	generate_nReset: process (clock_main, Reset)
	begin
		if (Reset = '1') then
			reset_delay <= "1111";
		else
			if (rising_edge(clock_main)) then
				reset_delay <= reset_delay(2 downto 0) & Reset;
			end if;
		end if;
	end process;
	
	-- Single step by each clock cycle, slow or fast
	ss: clocksinglestepper port map (
        reset => Reset,
        clock0_in => freq2,
        clock1_in => freq2k,
        clock2_in => freq3M125,
        clock3_in => freq25M,
        clocksel => switch(6 downto 5),
        modesel => switch(7),
        singlestep => button(3),
        clock_out => clock_main
    );
	
--	ila_ss: ila_0 port map (
--            clk => CLK,
--            probe0(5) => RESET,
--            probe0(4) => button(3),
--            probe0(3) => switch(3),
--            probe0(2) => switch(2),
--            probe0(1) => freq2k,
--            probe0(0) => freq1,
--            probe1(0) => clock_main
--    );
    
	nIoEnable <= (nIoRead and nIoWrite) when address_bus(7 downto 4) = "0000" else '1'; 		-- 0x00 - 0x0F
	nACIA0Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001000" else '1'; -- 0x10 - 0x11
	nACIA1Enable <= (nIoRead and nIoWrite) when address_bus(7 downto 1) = "0001001" else '1'; -- 0x12 - 0x13
	nBootRomEnable <= nMemRead when address_bus(15 downto 10) = "000000" else '1'; -- 1k ROM (0000 - 03FF)
	nMonRomEnable <= nMemRead when address_bus(15 downto 10)  = "000001" else '1'; -- 1k ROM (0400 - 07FF)
	nRamEnable <= (nMemRead and nMemWrite) when address_bus(15 downto 8) = "11111111" else '1'; -- 256b RAM (FF00 - FFFF)
	
	iodevice: simpledevice port map(
			  clk => CLK, -- this is the full 50MHz clock!
			  reset => Reset,
			  D => data_bus,
			  A => address_bus(3 downto 0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nIoEnable,
			  IntReq => open,
			  IntAck => '1',
			  direct_in(7 downto 0) => switch,
			  direct_in(15 downto 8) => button,
			  direct_out => io_output
	);

	acia0: ACIA port map(
			  clk => CLK, -- this is the full 50MHz clock!
			  reset => Reset,
			  D => data_bus,
			  A => address_bus(0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nAcia0Enable,
			  IntReq => DeviceReq(5),
			  IntAck => DeviceAck(5),
			  txd => PMOD(0),
			  rxd => PMOD(1)				  
	);

	acia1: ACIA port map(
			  clk => CLK, -- this is the full 50MHz clock!
			  reset => Reset,
			  D => data_bus,
			  A => address_bus(0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nAcia1Enable,
			  IntReq => DeviceReq(4),
			  IntAck => DeviceAck(4),
			  txd => PMOD(2),
			  rxd => PMOD(3)				  
	);
	
	bootrom: hexfilerom 
		generic map(
			filename => "./prog/zout/boot.hex",
			address_size => 10,
			default_value => X"FF" -- if executed, will be RST 7
			)	
		port map(
			  D => data_bus,
			  A => address_bus(9 downto 0),
           nRead => nMemRead,
			  nSelect => nBootRomEnable
		);

	monrom: hexfilerom 
		generic map(
			filename => "./prog/zout/altmon.hex",
			address_size => 10,
			default_value => X"FF" -- if executed, will be RST 7
			)	
		port map(
			  D => data_bus,
			  A => address_bus(9 downto 0),
           nRead => nMemRead,
			  nSelect => nMonRomEnable
		);

	ram: simpleram 
		generic map(
			address_size => 8,
			default_value => X"FF" -- if executed, will be RST 7
			)	
		port map(
			  clk => clock_main,
			  D => data_bus,
			  A => address_bus(7 downto 0),
           nRead => nMemRead,
			  nWrite => nMemWrite,
			  nSelect => nRamEnable
		);
	
	ic: interrupt_controller Port map ( 
			CLK => CLK, -- this is the full 50MHz clock!
			nRESET => nReset,
			INT => IntReq,
		   nINTA => nIntAck,
		   INTE => IntE,
			D => data_bus,
		   DEVICEREQ(7) => devicereq(7), -- button 0
		   DEVICEREQ(6) => devicereq(6), -- button 1
		   DEVICEREQ(5) => devicereq(5), -- ACIA 0
		   DEVICEREQ(4) => '0', --devicereq(4), -- ACIA 1 $BUGBUG - interrupt req stuck for ACIA1?
		   DEVICEREQ(3) => '0',
		   DEVICEREQ(2) => '0',
		   DEVICEREQ(1) => '0',
		   DEVICEREQ(0) => '0',
			DEVICEACK => DeviceAck
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
           CLK => clock_main,
           nRESET => nReset,
			  INT => IntReq,
			  READY => '1', -- TODO - use to implement single stepping per instruction, not cycle
			  HOLD => Hold, 
			  -- debug port, not part of actual processor
			  debug_ena => switch(1),
           debug_sel => switch(0),
           debug_out => cpu_debug_bus,
			  debug_reg => switch(5 downto 2)
			);
	 
end;
