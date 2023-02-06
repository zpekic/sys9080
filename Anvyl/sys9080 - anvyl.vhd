----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date: 08/24/2017 11:13:02 PM
-- Design Name: 
-- Module Name: sys9080 - Behavioral
-- Project Name: Simple 8-bit system around microcode implemented Am9080 CPU
-- Target Devices: https://reference.digilentinc.com/_media/anvyl:anvyl_rm.pdf
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

entity sys9080_anvyl is
    Port ( 
				-- 100MHz on the Anvyl board
				CLK: in std_logic;
				-- Switches
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
				-- Push buttons 
				-- BTN0 - generate RST 7 interrupt which will dump processor regs and memory they are pointing to over ACIA0
				-- BTN1 - bypass ACIA Rx char input processing and dump received bytes and status to ACIA0
				-- BTN2 - put processor into HOLD mode
				-- BTN3 - single step clock cycle forward if in SS mode (NOTE: single press on this button is needed after reset to unlock SS circuit)
				BTN: in std_logic_vector(3 downto 0); 
				-- Stereo audio output on baseboard
				--AUDIO_OUT_L, AUDIO_OUT_R: out std_logic;
				-- 7seg LED on baseboard 
				SEG: out std_logic_vector(6 downto 0); 
				AN: out std_logic_vector(5 downto 0); 
				DP: out std_logic; 
				-- 8 LEDs on Mercury board
				LED: out std_logic_vector(7 downto 0);
				--PMOD interface
				--PMOD: inout std_logic_vector(7 downto 0)
				JD1: inout std_logic;
				JD2: inout std_logic;
				JD3: inout std_logic;
				JD4: inout std_logic;
				JF1: inout std_logic;
				JF2: inout std_logic;
				JF3: inout std_logic;
				JF4: inout std_logic;
				--DIP switches
				DIP_B4, DIP_B3, DIP_B2, DIP_B1: in std_logic;
				DIP_A4, DIP_A3, DIP_A2, DIP_A1: in std_logic;
				-- TFT
				TFT_R_O: out std_logic_vector(7 downto 0);
				TFT_G_O: out std_logic_vector(7 downto 0);
				TFT_B_O: out std_logic_vector(7 downto 0);
				TFT_CLK_O: out std_logic;
				TFT_DE_O: out std_logic;
				TFT_DISP_O: out std_logic;
				TFT_BKLT_O: out std_logic;
				TFT_VDDEN_O: out std_logic;
				-- Hex keypad
				KYPD_COL: out std_logic_vector(3 downto 0);
				KYPD_ROW: in std_logic_vector(3 downto 0);
				-- SRAM --
				SRAM_CS1: out std_logic;
				SRAM_CS2: out std_logic;
				SRAM_OE: out std_logic;
				SRAM_WE: out std_logic;
				SRAM_UPPER_B: out std_logic;
				SRAM_LOWER_B: out std_logic;
				Memory_address: out std_logic_vector(18 downto 0);
				Memory_data: inout std_logic_vector(15 downto 0);
				-- Red / Yellow / Green LEDs
				LDT1G: out std_logic;
				LDT1Y: out std_logic;
				LDT1R: out std_logic;
				LDT2G: out std_logic;
				LDT2Y: out std_logic;
				LDT2R: out std_logic;
				-- VGA
				HSYNC_O: out std_logic;
				VSYNC_O: out std_logic;
				RED_O: out std_logic_vector(3 downto 0);
				GREEN_O: out std_logic_vector(3 downto 0);
				BLUE_O: out std_logic_vector(3 downto 0);
				-- ACIA chip signal connections
				BB1: inout std_logic;
				BB2: inout std_logic;
				BB3: inout std_logic;
				BB4: inout std_logic;
				BB5: inout std_logic;
				BB6: inout std_logic;
				BB7: inout std_logic;
				BB8: inout std_logic;
				--BB9: out std_logic;
				--BB10: out std_logic;
				--JC1: out std_logic;
				--JC2: out std_logic;
				--JC3: out std_logic;
				JC4: in std_logic
				--JC5: inout std_logic;
				--JC6: inout std_logic;
				--JC7: inout std_logic;
				--JC8: inout std_logic
          );
end sys9080_anvyl;

architecture Structural of sys9080_anvyl is

component clock_divider is
	 generic (CLK_FREQ: integer);
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           slow : out  STD_LOGIC_VECTOR (11 downto 0);
			  baud : out STD_LOGIC_VECTOR(7 downto 0);
           fast : out  STD_LOGIC_VECTOR (6 downto 0)
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

component adcdevice is
    Port ( clk : in  STD_LOGIC;
			  reset: in STD_LOGIC;
			  samplingrate: in STD_LOGIC;
			  inputfreq: in STD_LOGIC;	
			  output: out std_logic_vector(15 downto 0));
end component;

component debouncer8channel is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_raw : in  STD_LOGIC_VECTOR(7 downto 0);
           signal_debounced : out  STD_LOGIC_VECTOR(7 downto 0));
end component;

component sixdigitsevensegled is
    Port ( -- inputs
			  data : in  STD_LOGIC_VECTOR (23 downto 0);
           digsel : in  STD_LOGIC_VECTOR (2 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (5 downto 0);
           showdot : in  STD_LOGIC_VECTOR (5 downto 0);
           showsegments : in  STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (5 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end component;

component simpledevice is 
		Port(
           clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  D: inout STD_LOGIC_VECTOR(7 downto 0);
			  A: in STD_LOGIC_VECTOR(2 downto 0);
           nRead: in STD_LOGIC;
           nWrite: in STD_LOGIC;
			  IntReq: out STD_LOGIC;
			  IntAck: in STD_LOGIC;			  
			  nSelect: in STD_LOGIC;
			  kbd_col: out STD_LOGIC_VECTOR (3 downto 0);
			  kbd_row: in STD_LOGIC_VECTOR (3 downto 0);			  
			  direct_in: in STD_LOGIC_VECTOR(23 downto 0);
			  direct_out: out STD_LOGIC_VECTOR(23 downto 0);
			  direct_flags: out STD_LOGIC_VECTOR(1 downto 0)
			);
end component;

component ACIA is
		Port(
           clk : in STD_LOGIC;
           reset: in STD_LOGIC;
			  baudrate: in STD_LOGIC;
			  D: inout STD_LOGIC_VECTOR(7 downto 0);
			  A: in STD_LOGIC;
           nRead: in STD_LOGIC;
           nWrite: in STD_LOGIC;
			  nSelect: in STD_LOGIC;
			  IntReq: out STD_LOGIC;
			  IntAck: in STD_LOGIC;
			  ready: OUT STD_LOGIC;
			  txd: out STD_LOGIC;
			  rxd: in STD_LOGIC;
			  rts: out STD_LOGIC;
			  cts: in STD_LOGIC
			);
end component;

--component delaygen is
--    Port ( reset : in  STD_LOGIC;
--           clk : in  STD_LOGIC;
--           duration : in  STD_LOGIC_VECTOR (2 downto 0);
--           nActive : in  STD_LOGIC;
--           ready : out  STD_LOGIC);
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

component externalram is
    Port (       
				-- external SRAM
				SRAM_A: out std_logic_vector(18 downto 0);
				SRAM_D: inout std_logic_vector(15 downto 0);
				SRAM_CS1: out std_logic;
				SRAM_CS2: out std_logic;
				SRAM_OE: out std_logic;
				SRAM_WE: out std_logic;
				SRAM_UPPER_B: out std_logic;
				SRAM_LOWER_B: out std_logic;
				-- inner bus
			   clk : in STD_LOGIC;
				D : inout  STD_LOGIC_VECTOR (7 downto 0);
				A : in  STD_LOGIC_VECTOR (20 downto 0);
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

--component interrupt_controller is
--    Port ( CLK : in  STD_LOGIC;
--           nRESET : in  STD_LOGIC;
--           INT : out  STD_LOGIC;
--           nINTA : in  STD_LOGIC;
--           INTE : in  STD_LOGIC;
--           D : out  STD_LOGIC_VECTOR (7 downto 0);
--           DEVICEREQ : in STD_LOGIC_VECTOR (7 downto 0);
--           DEVICEACK : out STD_LOGIC_VECTOR (7 downto 0));
--end component;

component VModTFT is
    Port ( Reset : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           Pixel_x : out  STD_LOGIC_VECTOR (8 downto 0);
           Pixel_y : out  STD_LOGIC_VECTOR (8 downto 0);
           Pixel_color : in  STD_LOGIC_VECTOR (7 downto 0);
           Pixel_read : out  STD_LOGIC;
			  Display_blank: in STD_LOGIC;
			  VBlank: out STD_LOGIC;
           TFT_R : out  STD_LOGIC_VECTOR (7 downto 0);
           TFT_G : out  STD_LOGIC_VECTOR (7 downto 0);
           TFT_B : out  STD_LOGIC_VECTOR (7 downto 0);
           TFT_CLK : out  STD_LOGIC;
           TFT_DE : out  STD_LOGIC;
			  TFT_DISP: out STD_LOGIC;
           TFT_BKLT : out  STD_LOGIC;
           TFT_VDDEN : out  STD_LOGIC
			);
end component;

component TextVDP is
    Port ( Reset : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (8 downto 0);
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
           nCS : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           Pixel_x : in  STD_LOGIC_VECTOR (8 downto 0);
           Pixel_y : in  STD_LOGIC_VECTOR (8 downto 0);
           Pixel_read : in  STD_LOGIC;
			  VBlank: in STD_LOGIC;
			  nBusy : buffer STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (7 downto 0);
           blank : out  STD_LOGIC);
end component;

component mwvga is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           rgbBorder : in  STD_LOGIC_VECTOR (7 downto 0);
			  field: in STD_LOGIC_VECTOR(1 downto 0);
			  din: in STD_LOGIC_VECTOR (7 downto 0);
           hactive : buffer  STD_LOGIC;
           vactive : buffer  STD_LOGIC;
           x : out  STD_LOGIC_VECTOR (7 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0);
			  -- VGA connections
           rgb : out  STD_LOGIC_VECTOR (7 downto 0);
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC);
end component;

component xyram is
	 generic (maxram: integer;
				 maxrow: integer;
				 maxcol: integer);
    Port ( clk : in  STD_LOGIC;
           rw_we : in  STD_LOGIC;
           rw_x : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_y : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_din : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_dout : out  STD_LOGIC_VECTOR (7 downto 0);
			  mode: in STD_LOGIC_VECTOR (7 downto 0);
           nDigit : in  STD_LOGIC_VECTOR (8 downto 0);
           segment : in  STD_LOGIC_VECTOR(7 downto 0);
			  field: buffer STD_LOGIC_VECTOR(1 downto 0);
           ro_x : in  STD_LOGIC_VECTOR (7 downto 0);
           ro_y : in  STD_LOGIC_VECTOR (7 downto 0);
           ro_dout : out  STD_LOGIC_VECTOR (7 downto 0));
end component;
--
component vio0800_microcode is
	 generic (maxrow: integer;
				 maxcol: integer);
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  enable : in STD_LOGIC;
           char : in  STD_LOGIC_VECTOR (7 downto 0);
           char_sent : out STD_LOGIC;
			  cr_is_lf: in STD_LOGIC;
			  busy_in: in STD_LOGIC;
			  busy_out: out STD_LOGIC;
			  we : out STD_LOGIC;
			  din: in STD_LOGIC_VECTOR(7 downto 0);
			  dout: buffer STD_LOGIC_VECTOR(7 downto 0);
			  x: out STD_LOGIC_VECTOR(7 downto 0);
			  y: out STD_LOGIC_VECTOR(7 downto 0));
end component;

component traceunit is
    Port ( reset: in STD_LOGIC;
			  clk : in  STD_LOGIC;
			  enable : in STD_LOGIC;
			  char: in STD_LOGIC_VECTOR(7 downto 0);
           char_sent : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end component;

component debugtracer is
    Port ( reset : in  STD_LOGIC;
           trace : in  STD_LOGIC;
           ready : out  STD_LOGIC;
           char : out  STD_LOGIC_VECTOR (7 downto 0);
           char_sent : in  STD_LOGIC;
           in0 : in  STD_LOGIC_VECTOR (3 downto 0);
           in1 : in  STD_LOGIC_VECTOR (3 downto 0);
           in2 : in  STD_LOGIC_VECTOR (3 downto 0);
           in3 : in  STD_LOGIC_VECTOR (3 downto 0);
           in4 : in  STD_LOGIC_VECTOR (3 downto 0);
           in5 : in  STD_LOGIC_VECTOR (3 downto 0);
           in6 : in  STD_LOGIC_VECTOR (3 downto 0);
           in7 : in  STD_LOGIC_VECTOR (3 downto 0);
           in8 : in  STD_LOGIC_VECTOR (3 downto 0);
           in9 : in  STD_LOGIC_VECTOR (3 downto 0);
           in10 : in  STD_LOGIC_VECTOR (3 downto 0);
           in11 : in  STD_LOGIC_VECTOR (3 downto 0)
			);
end component;

--component DS1302 is
--    Port ( reset : in  STD_LOGIC;
--           clk : in  STD_LOGIC;
--           nSel : in  STD_LOGIC;
--           nRD : in  STD_LOGIC;
--           nWR : in  STD_LOGIC;
--           A : in  STD_LOGIC_VECTOR (5 downto 0);
--           D : inout  STD_LOGIC_VECTOR (7 downto 0);
--			  Ready: out STD_LOGIC;
--           CE : out  STD_LOGIC;
--           SCLK : out  STD_LOGIC;
--           IO : inout  STD_LOGIC;
--			  debug: out STD_LOGIC_VECTOR(27 downto 0)
--			);
--end component;

--component bustracer is
--    Port ( reset : in  STD_LOGIC;
--           clk : in  STD_LOGIC;
--           enable : in  STD_LOGIC;
--           nSel : in  STD_LOGIC;
--           nMemRead : in  STD_LOGIC;
--           nMemWrite : in  STD_LOGIC;
--           nIORead : in  STD_LOGIC;
--           nIOWrite : in  STD_LOGIC;
--           M1 : in  STD_LOGIC;
--           IntReq : in  STD_LOGIC;
--           nIntAck : in  STD_LOGIC;
--           A : in  STD_LOGIC_VECTOR (15 downto 0);
--           D : inout  STD_LOGIC_VECTOR (7 downto 0);
--			  ready: out STD_LOGIC;
--           tx_active : out  STD_LOGIC;
--           tx_clock : in  STD_LOGIC;
--           tx_data : out  STD_LOGIC;
--			  debug: out STD_LOGIC_VECTOR(27 downto 0));
--end component;

--component ns32081 is
--    Port ( -- CPU bus signals --
--           nReset : in  STD_LOGIC;
--           nRD : in  STD_LOGIC;
--           nWR : in  STD_LOGIC;
--           nSel : in  STD_LOGIC;
--			  a : in STD_LOGIC_VECTOR (3 downto 0);
--           D : inout  STD_LOGIC_VECTOR (7 downto 0);
--			  ready : out STD_LOGIC;
--			  done: out STD_LOGIC;
--           internalstate: out  STD_LOGIC_VECTOR (7 downto 0);
--			  -- NS32081 bus signals --
--           fpu_clkin : in  STD_LOGIC;
--           fpu_clkout : out  STD_LOGIC;
--           fpu_nRst : out  STD_LOGIC;
--           fpu_nSpc : inout  STD_LOGIC;
--           fpu_s : out  STD_LOGIC_VECTOR (1 downto 0);
--           fpu_d : inout  STD_LOGIC_VECTOR (15 downto 0));
--end component;

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
			  M1: out STD_LOGIC;
			  -- debug port, not part of actual processor
           debug_ena : in  STD_LOGIC;
           debug_sel : in  STD_LOGIC;
           debug_out : out  STD_LOGIC_VECTOR (19 downto 0);
			  debug_reg : in STD_LOGIC_VECTOR(3 downto 0)
			);
end component;

-- CPU buses
signal data_bus, extmemdata_bus: std_logic_vector(7 downto 0);
signal address_bus: std_logic_vector(15 downto 0);
signal Reset, nReset: std_logic;
signal clock_main, clock_acia, cpu_clock: std_logic;
--signal acia_clkselect: std_logic_vector(1 downto 0);
signal nIORead, nIOWrite, nMemRead, nMemWrite: std_logic;
signal nIoAccess: std_logic; 
signal nMemAccess: std_logic;
signal IntReq, nIntAck, Hold, HoldAck, IntE, m1: std_logic;
signal Ready, vdpReady, fpuReady, acia0Ready, acia1Ready, bustrace_ready: std_logic;

-- RTC signals
--signal rtc_CE, rtc_SCLK, rtc_IO: std_logic;
--signal nRTCEnable: std_logic;
--signal rtcReady: std_logic;

-- fpu signals
--signal fpu_clk: std_logic;
--signal fpu_clkselect: std_logic_vector(3 downto 0);
--signal nFpuReset, fpuDone: std_logic;

-- other signals
signal reset_delay: std_logic_vector(3 downto 0);
--signal DeviceReq: std_logic_vector(7 downto 0);
--signal DeviceAck: std_logic_vector(7 downto 0);
signal switch: std_logic_vector(7 downto 0);
signal button: std_logic_vector(7 downto 0);
signal io_output: std_logic_vector(23 downto 0);
signal led_bus: std_logic_vector(27 downto 0);
signal fpu_internal_state: std_logic_vector(7 downto 0);
signal fpu_debug_bus, cpu_debug_bus, sys_debug_bus: std_logic_vector(27 downto 0);
signal nIoEnable, nACIA0Enable, nACIA1Enable: std_logic; 
signal nBootRomEnable, nMonRomEnable, nRamEnable, nDiagRomEnable, nVdpEnable, nFpuEnable, nExtRamEnable, nExtRamRead, nExtRamWrite, nTracerEnable: std_logic;
signal readwritesignals: std_logic_vector(4 downto 0);
signal showsegments: std_logic;
signal flash: std_logic;
signal freq2k, freq1k, freq512, freq256, freq128, freq64, freq32, freq16, freq8, freq4, freq2, freq1: std_logic;
signal freq57600, freq38400, freq19200, freq9600, freq4800, freq2400, freq1200, freq600, freq300: std_logic;
signal freq50M, freq25M, freq12M5, freq6M25, freq3M125, freq1M5625, freq0m78125: std_logic;

-- ACIA signals
signal txd0, rxd0, rts0, cts0: std_logic; 
signal txd1, rxd1, rts1, cts1: std_logic;

signal tft_x: std_logic_vector(8 downto 0);
signal tft_y: std_logic_vector(8 downto 0);
signal tft_color: std_logic_vector(7 downto 0);
signal tft_read: std_logic;
signal tft_blank: std_logic;
signal tft_vblank: std_logic;

-- 2 UARTs connected to PMOD JD and JF for https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/
alias JD_RTS: std_logic is JD1;
alias JD_RXD: std_logic is JD2;
alias JD_TXD: std_logic is JD3;
alias JD_CTS: std_logic is JD4;
alias JF_RTS: std_logic is JF1;
alias JF_RXD: std_logic is JF2;
alias JF_TXD: std_logic is JF3;
alias JF_CTS: std_logic is JF4;

-- Physical 6850 ACIA chip on breadboard
-- http://www.bg-electronics.de/datenblaetter/Schaltkreise/MC6850.pdf
--alias acia_d: std_logic_vector(7 downto 0) is JC;	-- white
alias acia_D0 is BB1;		-- green
alias acia_D1 is BB2; 		-- orange
alias acia_D2 is BB3; -- lilac
alias acia_D3 is BB4;	-- brown
alias acia_D4 is BB5;	-- brown
alias acia_D5 is BB6;		-- gray
alias acia_D6 is BB7; 		-- gray
alias acia_D7 is BB8;		-- gray
--alias acia_RXTXCLK is BB9;		-- yellow
--alias acia_E is BB10;		-- yellow
--alias acia_RW is JC1;
--alias acia_RS is JC2;
--alias acia_nCS2 is JC3;
alias acia_IRQ is JC4;

-- VGA
signal tracer_out, tracer_in, controller_in: std_logic_vector(7 downto 0);
signal controller_x, tracer_x: std_logic_vector(7 downto 0);
signal controller_y, tracer_y: std_logic_vector(7 downto 0);
signal tracer_we, ram_we: std_logic;
signal colorband: std_logic_vector(1 downto 0);
signal nWriteTrace: std_logic;

-- Bus tracer
signal trace_ascii: std_logic_vector(7 downto 0);
signal tracerReady, tracer_busMatch, tracer_addrMatch: std_logic;
signal v_tracedone, s_tracedone, tracedone, s_txd: std_logic;

-- LED signals that also go to VGA
signal led_anode: std_logic_vector(5 downto 0);
signal led_segment: std_logic_vector(7 downto 0);

-- fast serial input
signal ser0, ser1: std_logic_vector(15 downto 0);
signal ser0_xchar, ser1_xchar: std_logic_vector(8 downto 0);
--alias ser0_valid: std_logic is ser0_xchar(8);
--alias ser1_valid: std_logic is ser1_xchar(8); 
signal ser_valid, ser0_valid, ser1_valid, v_cont, ser_clk: std_logic;
--signal ser0_count, ser1_count: integer range 0 to 15;
signal ser_framelen, ser_clksel: std_logic_vector(3 downto 0);

begin
   
	 Reset <= BTN(2); --USR_BTN;
	 nReset <= '0' when (Reset = '1') or (reset_delay /= "0000") else '1'; 
	 
	 --led_bus <= X"0" & ser1(13 downto 2) & ser0(13 downto 2); --cpu_debug_bus when (switch(1) = '1') else sys_debug_bus;
	 --sys_debug_bus <= X"0" & address_bus(15 downto 0) & data_bus when (switch(0) = '0') else X"0" & io_output;
	 sys_debug_bus <= X"0" & address_bus(15 downto 0) & data_bus when (switch(0) = '0') else X"0" & io_output;
	 led_bus <= cpu_debug_bus when (switch(1) = '1') else sys_debug_bus;
	 
	 readwritesignals <= (not nIORead) & (not nIOWrite) & (not nMemRead) & (not nMemWrite) & Ready;
	 showsegments <= '0' when (switch(1 downto 0) = "00" and readwritesignals(4 downto 1) = "0000") else '1';

	 Hold <= '0'; --'0' when (tft_blank = '1') else not tft_vblank;
	 flash <= Ready or freq4; -- blink in hold bus mode!

	 -- DISPLAY
	 LED(7 downto 3) <= readwritesignals;
	 LED(2) <= not nIntAck;  
	 LED(1) <= IntReq; 
	 LED(0) <= clock_main;  
    led6x7: sixdigitsevensegled port map ( 
			  -- inputs
			  data => led_bus(23 downto 0),
			  digsel(2) => freq64,
           digsel(1) => freq128,
			  digsel(0) => freq256,
           showdigit => (others => flash),
           showdot(5 downto 2) => led_bus(27 downto 24),
			  showdot(1 downto 0) => "00",
           showsegments => showsegments,
			  -- outputs
           anode => led_anode,
			  segment => led_segment
			 );
	 
	 AN <= led_anode;
	 SEG <= led_segment(6 downto 0);
	 DP <= led_segment(7);
	 
    -- FREQUENCY GENERATOR
    one_sec: clock_divider
	 generic map (CLK_FREQ => 100e6)	 
	 port map 
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
		  baud(7) => freq300,
		  baud(6) => freq600,		  
		  baud(5) => freq1200,
		  baud(4) => freq2400,
		  baud(3) => freq4800,
		  baud(2) => freq9600,
		  baud(1) => freq19200,
		  baud(0) => freq38400,
		  fast(6) => freq0M78125,
		  fast(5) => freq1M5625,
		  fast(4) => freq3M125,
		  fast(3) => freq6M25,
		  fast(2) => freq12M5,
		  fast(1) => freq25M,
		  fast(0) => freq50M
    );

	-- Single step by each clock cycle, slow or fast
	ss: clocksinglestepper port map (
        reset => Reset,
        clock3_in => freq2,
        clock2_in => freq1k,
        clock1_in => freq3M125,
        clock0_in => freq0M78125, --freq6M25,
        clocksel => switch(6 downto 5),
        modesel => switch(7),
        singlestep => button(3),
        clock_out => clock_main
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
	
	nIoAccess <= nIoRead and nIoWrite;
	nMemAccess <= nMemRead and nMemWrite;
	
	-- I/O address space
	nIoEnable <= nIoAccess when address_bus(7 downto 3) = "00000" else '1'; 		-- 0x00 - 0x07
	nACIA0Enable <= nIoAccess when address_bus(7 downto 1) = "0001000" else '1';	-- 0x10 - 0x11
	nACIA1Enable <= nIoAccess when address_bus(7 downto 1) = "0001001" else '1';	-- 0x12 - 0x13
	--nFpuEnable <= nIoAccess when address_bus(7 downto 4) = "1111" else '1';			-- 0xF0 - 0xFF
	nWriteTrace <= nIoWrite when address_bus(7 downto 0) = X"FF" else '1';	-- port FF write only
	
	-- Memory address space
	nBootRomEnable <= nMemRead when address_bus(15 downto 10)  = "000000" else '1'; -- 1k ROM (0000 - 03FF)
	nMonRomEnable <= 	nMemRead when address_bus(15 downto 10)  = "000001" else '1'; -- 1k ROM (0400 - 07FF)
	nVdpEnable <=		nMemAccess when address_bus(15 downto 9) = "0000110" else '1'; -- 512b VDP, 1 times (0C00 - 0DFF)
	--nRTCEnable <=  '1'; --nMemAccess when address_bus(15 downto 6) =   "0000001110" else '1'; -- RTC config (0380 - 03BF)
	--nTracerEnable <= nMemAccess when address_bus(15 downto 6) =   "0000001111" else '1'; -- Tracer config (03C0 - 03FF)
	--nFpuEnable <=  '1'; --nMemAccess when address_bus(15 downto 9)   = "0000111" else '1'; -- 512b FPU, 32 times (0E00 - 0FFF)

	nExtRamEnable <= '1' when (address_bus(15 downto 12) = "0000") else nMemAccess;
	nExtRamRead <=   '1' when (address_bus(15 downto 12) = "0000") else nMemRead;
	nExtRamWrite <=  '1' when (address_bus(15 downto 12) = "0000") else nMemWrite;
	--nExtRamEnable <= '1' when (address_bus(15) = '0') else nMemAccess;
	
	-- external memory
	SRAM_CS1 <= nExtRamEnable;
	SRAM_CS2 <= '1';
	SRAM_OE <= nMemRead;
	SRAM_WE <= nMemWrite;
	SRAM_UPPER_B <= not address_bus(0);
	SRAM_LOWER_B <= address_bus(0);
	Memory_address(18 downto 15) <= "0000";
	Memory_address(14 downto 0) <= address_bus(15 downto 1);

	Memory_data(15 downto 8) <= data_bus when (nExtRamWrite = '0') else "ZZZZZZZZ";
	Memory_data(7 downto 0) <= data_bus when (nExtRamWrite = '0') else "ZZZZZZZZ";
	extmemdata_bus <= Memory_data(15 downto 8) when (address_bus(0) = '1') else Memory_data(7 downto 0);
	data_bus <= extmemdata_bus when (nExtRamRead = '0') else "ZZZZZZZZ";
	
	TFT: VModTFT Port map ( 
				Reset => Reset,
				Clk => CLK,
				Pixel_x => tft_x,
				Pixel_y => tft_y,
				Pixel_color => tft_color,
				Pixel_read => tft_read,
				Display_blank => tft_blank,
				VBlank => tft_vblank,
				TFT_R => TFT_R_O,
				TFT_G => TFT_G_O,
				TFT_B => TFT_B_O,
				TFT_CLK => TFT_CLK_O,
				TFT_DE => TFT_DE_O,
				TFT_DISP => TFT_DISP_O,
				TFT_BKLT => TFT_BKLT_O,
				TFT_VDDEN => TFT_VDDEN_O
			);
			
	VDP: TextVDP Port map ( 
				Reset => Reset,
				Clk => CLK,
				A => address_bus(8 downto 0),
				D => data_bus,
				nCS => nVdpEnable,
				nRD => nMemRead,
				nWR => nMemWrite,
				Pixel_x => tft_x,
				Pixel_y => tft_y,
				Pixel_read => tft_read,
				VBlank => tft_vblank,
				nBusy => vdpReady,
				color => tft_color,
				blank => tft_blank
			);
			
	iodevice: simpledevice port map(
			  clk => CLK, -- this is the full 50MHz clock!
			  reset => Reset,
			  D => data_bus,
			  A => address_bus(2 downto 0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nIoEnable,
			  IntReq => open,
			  IntAck => '1',
			  kbd_col => KYPD_COL,
			  kbd_row => KYPD_ROW,
			  direct_in(7 downto 0) => switch,
			  direct_in(15 downto 8) => button,
			  direct_in(23) => DIP_B4,
			  direct_in(22) => DIP_B3,
			  direct_in(21) => DIP_B2,
			  direct_in(20) => DIP_B1,
			  direct_in(19) => DIP_A4,
			  direct_in(18) => DIP_A3,
			  direct_in(17) => DIP_A2,
			  direct_in(16) => DIP_A1,
			  direct_out => io_output,
			  direct_flags(1) => open, --flag_bustrace,
			  direct_flags(0) => open  --flag_cputrace
			);

	-- connect serial ports and show their activity on LEDs

	-- "null modem" for https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/
	JD_CTS <= rts0;
	JD_RXD <= txd0;
	rxd0 <= JD_TXD;
	cts0 <= JD_RTS;

	LDT1R <= not JD_CTS;
	LDT1Y <= not nAcia0Enable;
	LDT1G <= not JD_RTS;
	
	acia0: ACIA
			port map(
			  clk => freq12M5, 
			  reset => Reset,
			  baudrate => freq38400,
			  D => data_bus,
			  A => address_bus(0),
           nRead => nIORead,
           nWrite => nIOWrite,
			  nSelect => nAcia0Enable,
			  IntReq => open,
			  IntAck => '0',
			  ready => acia0Ready,
			  txd => txd0,
			  rxd => rxd0,
			  rts => rts0,
			  cts => cts0
	);


--acia_D0 <= data_bus(0);		-- green
--acia_D1 <= data_bus(1); 		-- orange
--acia_D2 <= data_bus(2); -- lilac
--acia_D3 <= data_bus(3);	-- brown
--acia_D4 <= data_bus(4);	-- brown
--acia_D5 <= data_bus(5);		-- gray
--acia_D6 <= data_bus(6); 		-- gray
--acia_D7 <= data_bus(7);		-- gray

--nJCRead <= nAcia1Enable or nIORead;
--nJCWrite <= nAcia1Enable or nIOWrite;
--
--JC1 <= data_bus(0) when (nJCWrite = '0') else 'Z';
--JC2 <= data_bus(1) when (nJCWrite = '0') else 'Z';
--JC3 <= data_bus(2) when (nJCWrite = '0') else 'Z';
--JC4 <= data_bus(3) when (nJCWrite = '0') else 'Z';
--JC5 <= data_bus(4) when (nJCWrite = '0') else 'Z';
--JC6 <= data_bus(5) when (nJCWrite = '0') else 'Z';
--JC7 <= data_bus(6) when (nJCWrite = '0') else 'Z';
--JC8 <= data_bus(7) when (nJCWrite = '0') else 'Z';
--data_bus(0) <= JC1 when (nJCRead = '0') else 'Z';
--data_bus(1) <= JC2 when (nJCRead = '0') else 'Z';
--data_bus(2) <= JC3 when (nJCRead = '0') else 'Z';
--data_bus(3) <= JC4 when (nJCRead = '0') else 'Z';
--data_bus(4) <= JC5 when (nJCRead = '0') else 'Z';
--data_bus(5) <= JC6 when (nJCRead = '0') else 'Z';
--data_bus(6) <= JC7 when (nJCRead = '0') else 'Z';
--data_bus(7) <= JC8 when (nJCRead = '0') else 'Z';
--acia_nCS2 <= nAcia1Enable;
--acia_RS <= address_bus(0);
--acia_RXTXCLK <= freq19200;
--acia_RW <= nIOWrite;
--acia_E <= (nIOWrite and nIORead); --freq0M78125; -- TODO: slow down CPU to match this frequency
--
--acia1ready <= nAcia1Enable or not(freq0M78125);

--	acia1: ACIA
--			port map(
--			  clk => freq12M5,
--			  reset => Reset,
--			  baudrate => freq38400,
--			  D => data_bus,
--			  A => address_bus(0),
--			  nRead => nIORead,
--			  nWrite => nIOWrite,
--			  nSelect => nAcia1Enable,
--			  IntReq => open,
--			  IntAck => '0',
--			  ready => acia1ready,
--			  txd => txd1,
--			  rxd => rxd1,				  
--			  rts => rts1,
--			  cts => cts1
--	);

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

--	enable_cputrace <= flag_cputrace and (not nBootRomEnable);
--	ncputrace <= not (cputracereq or (not cputraceack) or enable_cputrace);
--	cputracereq <= not (ncputrace or (not m1) or (not enable_cputrace));

	Ready <= vdpReady and acia0Ready and acia1Ready and tracerReady; --  and fpuReady and rtcReady;
	--Ready <= vdpReady and acia0Ready and acia1Ready;
			  
   --cpu_clock <= '0' when bustrace_ready = '0' else clock_main;
	
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
			  INT => '0', --IntReq,
			  READY => Ready,
			  HOLD => Hold, 
			  M1 => m1,
			  -- debug port, not part of actual processor
			  debug_ena => switch(1),
           debug_sel => switch(0),
           debug_out => cpu_debug_bus(19 downto 0),
			  debug_reg => switch(5 downto 2)
			);

---------------------------------------------------------------------
-- Tracer watches the bus and outputs either on VGA or simple UART --
---------------------------------------------------------------------
tracer_addrMatch <= '1' when (address_bus(15 downto 8) = io_output(15 downto 8)) else io_output(20);
tracer_busMatch <= 	(io_output(19) and not(nMemWrite)) or
							(io_output(18) and not(nMemRead)) or
							(io_output(17) and not(nIoWrite)) or
							(io_output(16) and not(nIoRead));

tracer: debugtracer Port map ( 
			reset => reset,
			trace => tracer_busMatch and tracer_addrMatch,
			ready => tracerReady,
			char => trace_ascii,
			char_sent => tracedone,
			in0 => tracer_y(3 downto 0), --io_output(3 downto 0),
			in1 => tracer_y(7 downto 4),--io_output(7 downto 4),
			in2 => data_bus(3 downto 0),
			in3 => data_bus(7 downto 4),
			in4 => address_bus(3 downto 0),
			in5 => address_bus(7 downto 4),
			in6 => address_bus(11 downto 8),
			in7 => address_bus(15 downto 12),
			in8 => '1' & m1 & nMemRead & nMemWrite,
			in9 => "10" & nIoRead & nIoWrite,
			in10 => tracer_x(3 downto 0),
			in11 => tracer_x(7 downto 4)
	);

tracedone <= v_tracedone when (button(0) = '0') else s_tracedone; 

-- serial debug tracer (active when button(0) is not pressed)
	s_tracer: traceunit Port map ( 
		reset => reset,
		clk => ser_clk,
		enable => button(0),
		char => trace_ascii,
      char_sent => s_tracedone,
      txd => s_txd
	);

-- vga debug tracer (active when button(0) is pressed)
	v_tracer: vio0800_microcode 
	generic map (
		maxrow => 48,
		maxcol => 80)	 
	port map ( 
		reset => reset,
		clk => freq25M,
		enable => not button(0),
		char => trace_ascii,
		char_sent => v_tracedone,
		cr_is_lf => '0', -- '1'
		busy_in => '0', --controller_busy,
		busy_out => open, --tracer_busy,
		we => tracer_we,
		din => tracer_in,
		dout => tracer_out,
		x => tracer_x,
		y => tracer_y
	);

-- VGA debug tracing ----------------------
	RED_O(0) <= '0';
	GREEN_O(0) <= '0';
	BLUE_O(1 downto 0) <= switch(6 downto 5);
	
	v_controller: mwvga 
	port map ( 
		reset => reset,
		clk => freq25M, 
		rgbBorder => SW,
		field => colorband,
		din => controller_in,
		hactive => open, --controller_h,
		vactive => open, --controller_v, --controller_busy,
		x => controller_x,
		y => controller_y,
		-- VGA connections
		rgb(2 downto 0) => RED_O(3 downto 1),
		rgb(5 downto 3) => GREEN_O(3 downto 1),
		rgb(7 downto 6) => BLUE_O(3 downto 2),
		hsync => HSYNC_O,
		vsync => VSYNC_O
	);

	v_ram: xyram 
	generic map (
		maxram => 2048, -- must be <= than maxrow * maxcol
		maxrow => 48,
		maxcol => 80	 
	)
	port map (
		clk => CLK, --freq25M,
		rw_we => tracer_we,
		rw_x => tracer_x,
		rw_y => tracer_y,
		rw_din => tracer_out,
		rw_dout => tracer_in,
		mode => SW, -- TODO: display on VGA current switch settings
		nDigit(0) => led_anode(1),
		nDigit(1) => led_anode(0),
		nDigit(2) => led_anode(3),
		nDigit(3) => led_anode(2),
		nDigit(4) => led_anode(5),
		nDigit(5) => led_anode(4),
		nDigit(8 downto 6) => "111",
		segment => led_segment,
		field => colorband,
		ro_x => controller_x,
		ro_y => controller_y,
		ro_dout => controller_in
	);

	-- "null modem" for https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/
	JF_CTS <= rts1;
	JF_RXD <= txd1 and s_txd; -- works as both are high inactive
	rxd1 <= JF_TXD;
	cts1 <= JF_RTS;

	LDT2R <= not JF_CTS;
	LDT2Y <= not nAcia1Enable;
	LDT2G <= not JF_RTS;

--ser_framelen 	<= DIP_A4 & DIP_A3 & DIP_A2 & DIP_A1;
ser_clksel 		<= DIP_B4 & DIP_B3 & DIP_B2 & DIP_B1;
with ser_clksel select
	ser_clk <=  freq300 		when "0000",
					freq600 		when "0001",
					freq1200 	when "0010",
					freq2400 	when "0011",
					freq4800 	when "0100",
					freq9600 	when "0101",
					freq19200 	when "0110",
					freq38400 	when others;

--ser0_valid <= ser0(12) and ser0(11) and (not ser0(10)) and ser0(1) and ser0(0);
--get_ser0: process(reset, ser_clk, rxd1, ser0_valid)
--begin
--	if ((reset) = '1') then
--		ser0 <= X"FFFF";
--	else
--		if (rising_edge(ser_clk)) then
--			if (ser0_valid = '1') then
--				ser0 <= "111111111111111" & rxd1;
--				ser0_xchar <= '1' & ser0(2) & ser0(3) & ser0(4) & ser0(5) & ser0(6) & ser0(7) & ser0(8) & ser0(9);
--			else 
--				ser0 <= ser0(14 downto 0) & rxd1;
--				ser0_xchar <= '0' & X"00";
--			end if;
--		end if;
--	end if;
--end process;
--
--ser1_valid <= ser1(12) and ser1(11) and (not ser1(10)) and ser1(1) and ser1(0);
--get_ser1: process(reset, ser_clk, rxd1, ser1_valid)
--begin
--	if ((reset) = '1') then
--		ser1 <= X"FFFF";
--	else
--		if (falling_edge(ser_clk)) then
--			if (ser1_valid = '1') then
--				ser1 <= "111111111111111" & rxd1;
--				ser1_xchar <= '1' & ser1(2) & ser1(3) & ser1(4) & ser1(5) & ser1(6) & ser1(7) & ser1(8) & ser1(9);
--			else
--				ser1 <= ser1(14 downto 0) & rxd1;
--				ser1_xchar <= '0' & X"00";
--			end if;
--		end if;
--	end if;
--end process;
--
--ser_valid <= ser0_xchar(8) or ser1_xchar(8);

--	ic: interrupt_controller Port map ( 
--			CLK => clock_main, -- this is the full 50MHz clock!
--			nRESET => nReset,
--			INT => IntReq,
--		   nINTA => nIntAck,
--		   INTE => IntE,
--			D => data_bus,
--		   DEVICEREQ(7) => '0',			-- lowest
--		   DEVICEREQ(6) => '0',
--		   DEVICEREQ(5) => '0', 
--		   DEVICEREQ(4) => '0', 
--		   DEVICEREQ(3) => '0',
--		   DEVICEREQ(2) => '0',
--		   DEVICEREQ(1) => '0', --cputracereq,
--		   DEVICEREQ(0) => '0',			-- highest (reserved for RESET)
--			DEVICEACK(7) => open,
--			DEVICEACK(6) => open,
--			DEVICEACK(5) => open,
--			DEVICEACK(4) => open,
--			DEVICEACK(3) => open,
--			DEVICEACK(2) => open,
--			DEVICEACK(1) => open, --cputraceack,
--			DEVICEACK(0) => open
--		);

--tracer_sync: process(reset, v_cont, ser_valid)
--begin
--	if ((reset or v_cont) = '1') then
--		trace_ascii <= X"00";
--	else
--		if (rising_edge(ser_valid)) then
--			if (ser0_xchar(8) = '1') then
--				trace_ascii <= ser0_xchar(7 downto 0); 
--			else 
--				trace_ascii <= ser1_xchar(7 downto 0);
--			end if;
--		end if;
--	end if;
--end process;

--rtc: ds1302 Port map 
--	(	
--		reset => reset,
--		clk => button(3),
--		nSel => nRTCEnable,
--		nRD => nMemRead,
--		nWR => nMemWrite,
--		A => address_bus(5 downto 0),
--		D => data_bus,
--		Ready => rtcReady,
--		CE => rtc_CE,
--		SCLK => rtc_SCLK,
--		IO => rtc_IO,
--		debug => open--fpu_debug_bus
--	);
--	-- to RTC PMOD
--	JB1 <= rtc_CE;
--	JB2 <= rtc_SCLK;
--	JB3 <= button(3);
--	JB4 <= rtc_IO;
--	
--	-- for external debugging
--	JB7 <= txd0;--rtc_CE;
--	JB8 <= rxd0;--rtc_SCLK;
--	JB9 <= txd1;--button(3);
--	JB10 <= rxd1;--rtc_IO;
--
--bt: bustracer Port map
--		( 
--			reset => reset,
--			clk => clock_main,
--			enable => flag_bustrace,
--			nSel => nTracerEnable,
--			nMemRead => nMemRead,
--			nMemWrite => nMemWrite,
--			nIORead => nIoRead,
--			nIOWrite => nIoWrite,
--			M1 => M1,
--			IntReq => IntReq,
--			nIntAck => nIntAck,
--			A => address_bus,
--			D => data_bus,
--			ready => bustrace_ready,
--			tx_active => bustrace_active,
--			tx_clock => freq38400,
--			tx_data => bustrace_txd,
--			debug => fpu_debug_bus
--		);

	--fpu_debug_bus <= BB6 & BB5 & BB4 & BB3 & fpu_internal_state & JC10 & JC9 & JC8 & JC7 & JC4 & JC3 & JC2 & JC1 & JA10 & JA9 & JA8 & JA7 & JA4 & JA3 & JA2 & JA1;
--	nFpuReset <= nReset and (not button(0));
--	fpu_clkselect <= DIP_B4 & DIP_B3 & DIP_B2 & DIP_B1;
--	with (fpu_clkselect) select
--		fpu_clk <= 	freq1 when 		"0000",
--						freq2 when 		"0001", -- 2Hz
--						freq4 when 		"0010", -- 4Hz
--						freq8 when 		"0011", -- 8Hz
--						freq16 when 	"0100",  -- 16Hz
--						freq32 when 	"0101",  -- 32Hz
--						freq64 when 	"0110",  -- 64Hz
--						freq128 when 	"0111",  -- 128Hz
--						freq256 when 	"1000",  -- 256Hz
--						freq512 when 	"1001",  -- 512Hz
--						freq1k when 	"1010",  -- 1024Hz
--						freq2k when 	"1011",  -- 2048Hz
--						freq19200 when "1100",
--						freq1M5625 when "1101",
--						freq3M125 when "1110",
--						freq6M25 when others;
	
--fpu: ns32081 Port map ( -- CPU bus signals --
--           nReset => nFpuReset,
--           nRD => nIoRead,
--           nWR => nIoWrite,
--           --nRD => nMemRead,
--           --nWR => nMemWrite,
--           nSel => nFpuEnable,
--			  a => address_bus(3 downto 0),
--           D => data_bus,
--			  ready => fpuReady,
--			  done => fpuDone,
--			  internalstate => fpu_internal_state,
--			  -- NS32081 bus signals --
--			  fpu_clkin => freq3M125, --fpu_clk,
--           fpu_clkout => BB5,
--           fpu_nRst => BB4,
--           fpu_nSpc => BB3,
--           fpu_s(1) => BB2,
--           fpu_s(0) => BB1,
--           fpu_d(15) => JC10,
--           fpu_d(14) => JC9,
--           fpu_d(13) => JC8,
--           fpu_d(12) => JC7,
--           fpu_d(11) => JC4,
--           fpu_d(10) => JC3,
--           fpu_d(9) => JC2,
--           fpu_d(8) => JC1,
--           fpu_d(7) => JA10,
--           fpu_d(6) => JA9,
--           fpu_d(5) => JA8,
--           fpu_d(4) => JA7,
--           fpu_d(3) => JA4,
--           fpu_d(2) => JA3,
--           fpu_d(1) => JA2,
--           fpu_d(0) => JA1
--		);

--ioDelay: delaygen port map ( 
--				reset => reset,
--				clk => clock_main,
--				duration(2) => '1',
--				duration(1) => '1',--DIP_A2,
--				duration(0) => '1',--DIP_A1,
--				nActive => nIoAccess,
--				ready => ioReady
--			);

--memDelay: delaygen port map ( 
--				reset => reset,
--				clk => clock_main,
--				duration(2) => '1',
--				duration(1) => '1',--DIP_A4,
--				duration(0) => '1',--DIP_A3,
--				nActive => nMemAccess,
--				ready => memReady
--			);
	 
end;
