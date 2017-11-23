----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/24/2017 11:13:02 PM
-- Design Name: 
-- Module Name: sys9080 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
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
				--SWITCH_OEN: out std_logic;
				--MEMORY_OEN: out std_logic;
				--IO: inout std_logic_vector(29 downto 0)
          );
end sys9080;

architecture Structural of sys9080 is

component clock_divider is
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           div : out  STD_LOGIC_VECTOR (11 downto 0)
			 );
end component;

component clocksinglestepper is
    Port ( reset : in STD_LOGIC;
           clock0_in : in STD_LOGIC;
           clock1_in : in STD_LOGIC;
           clocksel : in STD_LOGIC;
           modesel : in STD_LOGIC;
           singlestep : in STD_LOGIC;
           clock_out : out STD_LOGIC);
end component;

component counter16bit is
    Port ( reset : in STD_LOGIC;
           clk : in STD_LOGIC;
           mode : in STD_LOGIC_VECTOR (1 downto 0);
           d : in STD_LOGIC_VECTOR (15 downto 0);
           q : out STD_LOGIC_VECTOR (15 downto 0));
end component;

--component PmodSSD is
--    Port ( sel : in STD_LOGIC;
--           blank : in STD_LOGIC;
--           d : in STD_LOGIC_VECTOR (7 downto 0);
--           cathode: out std_logic;
--           anode: out std_logic_vector(6 downto 0)
--          );
--end component;

component debouncer8channel is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_raw : in  STD_LOGIC_VECTOR(7 downto 0);
           signal_debounced : out  STD_LOGIC_VECTOR(7 downto 0));
end component;

--component rgbledpwm is
--    Port ( reset : in STD_LOGIC;
--           freq_pwm : in STD_LOGIC;
--           rgb : in STD_LOGIC_VECTOR (23 downto 0);
--           pwm_red : out STD_LOGIC;
--           pwm_green : out STD_LOGIC;
--           pwm_blue : out STD_LOGIC;
--           debug_out: out STD_LOGIC_VECTOR(23 downto 0));
--end component;

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
           --CLK : in STD_LOGIC;
           --nRESET: in STD_LOGIC;
			  D: inout STD_LOGIC_VECTOR(7 downto 0);
			  A: in STD_LOGIC_VECTOR(3 downto 0);
           nRead: in STD_LOGIC;
           nWrite: in STD_LOGIC;
			  nSelect: in STD_LOGIC;
			  ---------------------
			  direct_in: in STD_LOGIC_VECTOR(15 downto 0);
			  direct_out: out STD_LOGIC_VECTOR(15 downto 0)
			);
end component;

component simpleram is
	 generic (
		address_size: integer;
		default_value: STD_LOGIC_VECTOR(7 downto 0)
	  );
    Port (       
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
           CLK : in  STD_LOGIC;
           nRESET : in  STD_LOGIC;
			  INT: in STD_LOGIC;
			  READY: in STD_LOGIC;
			  HOLD: in STD_LOGIC;
			  -- debug port, not part of actual processor
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

signal switch: std_logic_vector(7 downto 0);
signal button: std_logic_vector(7 downto 0);
signal cnt: std_logic_vector(15 downto 0);
signal io_output: std_logic_vector(15 downto 0);
signal led_bus: std_logic_vector(19 downto 0);
signal internal_debug_bus, external_debug_bus: std_logic_vector(19 downto 0);
signal nIoEnable, nRomEnable, nRamEnable: std_logic;

signal reset: std_logic;
signal clock_main: std_logic;
signal data_bus: std_logic_vector(7 downto 0);
signal address_bus: std_logic_vector(15 downto 0);
signal nReset, nIORead, nIOWrite, nMemRead, nMemWrite: std_logic;
signal nIntAck, HoldAck: std_logic;

signal readwritesignals: std_logic_vector(3 downto 0);
signal showsegments: std_logic;
signal freq2k, freq1k, freq512, freq256, freq128, freq64, freq32, freq16, freq8, freq4, freq2, freq1: std_logic;

begin
   
	 --SWITCH_OEN <= '1'; -- Drive high to disconnect GPIO bus and use it as RAM bus ( http://bit.ly/2mH2OXk )
    reset <= USR_BTN;
	 nReset <= '0' when (USR_BTN = '1') or (cnt(15 downto 2) = "00000000000000") else '1'; 
	 
	 led_bus <= internal_debug_bus when (switch(1) = '1') else external_debug_bus;
	 external_debug_bus <= readwritesignals & address_bus(7 downto 0) & data_bus when (switch(0) = '0') else "0000" & io_output;
	 
	 readwritesignals <= (not nIORead) & (not nIOWrite) & (not nMemRead) & (not nMemWrite);
	 showsegments <= '0' when (switch(1) = '0' and switch(0) = '0' and readwritesignals = "0000") else '1';

	 -- DISPLAY
	 LED(3) <= nIntAck; -- note reverse for easier readability 
	 LED(2) <= HoldAck; -- note for easier readability 
	 LED(1) <= nReset;
	 LED(0) <= clock_main; -- note reverse for easier readability 
    led4x7: fourdigitsevensegled port map ( 
			  -- inputs
			  data => led_bus(15 downto 0),
           digsel(1) => freq1k,
			  digsel(0) => freq2k,
           showdigit => "1111",
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
        reset => reset,
        div(11) => freq1, -- 1Hz
        div(10) => freq2, -- 2Hz
        div(9) => freq4, -- 4Hz
        div(8) => freq8, -- 8Hz
        div(7) => freq16,  -- 16Hz
        div(6) => freq32,  -- 32Hz
        div(5) => freq64,  -- 64Hz
        div(4) => freq128,  -- 128Hz
        div(3) => freq256,  -- 16Hz
        div(2) => freq512,  -- 32Hz
        div(1) => freq1k,  -- 64Hz
        div(0) => freq2k  -- 128Hz
    );

	-- SIMPLE COUNTER
		counter16: counter16bit port map (
	    reset => RESET,
	    clk => clock_main,
        mode => "01", --button(1 downto 0),
        d => X"0000",
        q => cnt
	);

	-- DEBOUNCE the 8 switches and 4 buttons
    debouncer_sw: debouncer8channel port map (
        clock => freq128,
        reset => RESET,
        signal_raw => SW,
        signal_debounced => switch
    );

    debouncer_btn: debouncer8channel port map (
        clock => freq128,
        reset => RESET,
        signal_raw(7 downto 4) => "1111",
        signal_raw(3 downto 0) => BTN(3 downto 0),
        signal_debounced => button
    );
	
	ss: clocksinglestepper port map (
        reset => RESET,
        clock0_in => freq1,
        clock1_in => freq4,
        clocksel => switch(7),
        modesel => switch(6),
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
    
	
	nIoEnable <= (nIoRead and nIoWrite) when address_bus(15 downto 4) = X"000" else '1';
	nRomEnable <= nMemRead when address_bus(15 downto 8) = X"00" else '1';
	nRamEnable <= (nMemRead and nMemWrite) when address_bus(15 downto 8) = X"FF" else '1';
	
	iodevice: simpledevice port map(
			  D => data_bus,
			  A => address_bus(3 downto 0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nIoEnable,
			  ---------------------
			  direct_in(7 downto 0) => switch,
			  direct_in(15 downto 8) => button,
			  direct_out => io_output
	);
	
	rom: hexfilerom 
		generic map(
			filename => "./zout/test2.hex",
			address_size => 7,
			default_value => X"76" -- HLT instruction if uninitialized memory is executed
			)	
		port map(
			  D => data_bus,
			  A => address_bus(6 downto 0),
           nRead => nMemRead,
			  nSelect => nRomEnable
		);

	ram: simpleram 
		generic map(
			address_size => 5,
			default_value => X"00" -- cleared
			)	
		port map(
			  D => data_bus,
			  A => address_bus(4 downto 0),
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
           CLK => clock_main,
           nRESET => nreset,
			  INT => '0', -- TODO
			  READY => '1', -- TODO - use to implement single stepping
			  HOLD => '0', -- TODO
			  -- debug port, not part of actual processor
           debug_sel => switch(0),
           debug_out => internal_debug_bus,
			  debug_reg => switch(5 downto 2)
			);
	 
   
end;
