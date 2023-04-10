----------------------------------------------------------------------------------
-- Company:  @Home
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date:    21:42:37 10/25/2017 
-- Design Name: 
-- Module Name:    Am9080a - Structural
-- Project Name: 	 Sys9080
-- Target Devices: https://www.micro-nova.com/mercury
-- Tool versions:  Xilinx ISE 14.7 (nt)
-- Description:    https://en.wikichip.org/w/images/7/76/An_Emulation_of_the_Am9080A.pdf
--
-- Dependencies: 
-- 	(slightly modified) Am2909 by Stanislaw Deniziak ( http://achilles.tu.kielce.pl/Members/sdeniziak/studia-magisterskie/mikroprogramowanie-ii/materia142y-pomocnicze/am2909.vhd/view ) 
-- 	(slightly modified) Am2901 by Amr Nasr ( https://github.com/Amrnasr/AM2901 )
-- 	All other components by zpekic@hotmail.com
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use work.mnemonics.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Am9080a is
    Port ( DBUS : inout  STD_LOGIC_VECTOR(7 downto 0);
			  ABUS : out STD_LOGIC_VECTOR(15 downto 0);
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
			  M1: out STD_LOGIC;		-- indicates M1 machine cycle (instruction fetch)
			  -- debug port, not part of actual processor
			  -- 0: current microinstruction details appear on debug_out (processor can work!)
			  -- 1: register contents appears on debug_out
           debug_sel : in  STD_LOGIC;
			  -- register selection if debug_sel == '1', otherwise ignored
			  --debug_reg	Am2901_reg	value that appears on debug_out
			  --1				0				BC
			  --				1				CB
			  --2				2				DE
			  --				3				ED
			  --3				4				HL
			  --				5				LH
			  --				6				-A
			  --0				7				A-
			  --4				8				SP (in documentation, this is marked as "not used")
			  --				9				not used (in documentation, this is marked as SP)
			  --				A				scratch pad
			  --				B				scratch pad
			  --6				C				X"0038"
			  --7				D				X"3800"
			  --				E				not used
			  --5				F				PC
			  debug_reg : in STD_LOGIC_VECTOR(2 downto 0);
			  -- data from processor internals
           debug_out : out  STD_LOGIC_VECTOR (19 downto 0)
		);
end Am9080a;

architecture structural of Am9080a is

component rom512x56 is
    Port ( address : in  STD_LOGIC_VECTOR (8 downto 0);
           data : out  STD_LOGIC_VECTOR (55 downto 0)
			 );
end component;

component rom256x12 is
    Port ( address : in  STD_LOGIC_VECTOR (7 downto 0);
           data : out  STD_LOGIC_VECTOR (11 downto 0)
			);
end component;

component rom32x8 is
    Port ( nCS : in STD_LOGIC;
           address : in STD_LOGIC_VECTOR (3 downto 0);
           data : out STD_LOGIC_VECTOR (4 downto 0));
end component;

component Am25LS377 is
    Port ( clk : in STD_LOGIC;
           nE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           q : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component Am25LS374 is
    Port ( clk : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR(7 downto 0);
           y : out STD_LOGIC_VECTOR(7 downto 0));
end component;

component Am25LS153 is
    Port ( sel : in STD_LOGIC_VECTOR (1 downto 0);
           n1G : in STD_LOGIC;
           n2G : in STD_LOGIC;
           in1 : in STD_LOGIC_VECTOR (3 downto 0);
           in2 : in STD_LOGIC_VECTOR (3 downto 0);
           out1 : out STD_LOGIC;
           out2 : out STD_LOGIC);
end component;

component Am25LS157 is
    Port ( a : in STD_LOGIC_VECTOR (3 downto 0);
           b : in STD_LOGIC_VECTOR (3 downto 0);
           s : in STD_LOGIC;
           nG : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component Am25LS257 is
    Port ( a : in STD_LOGIC_VECTOR (3 downto 0);
           b : in STD_LOGIC_VECTOR (3 downto 0);
           s : in STD_LOGIC;
           nOE : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component Am25139 is
    Port ( nG1 : in STD_LOGIC;
           B1 : in STD_LOGIC;
           A1 : in STD_LOGIC;
           nY1 : out STD_LOGIC_VECTOR (3 downto 0);
           nG2 : in STD_LOGIC;
           B2 : in STD_LOGIC;
           A2 : in STD_LOGIC;
           nY2 : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component Am82S62 is
    Port ( p : in STD_LOGIC_VECTOR (8 downto 0);
           inhibit : in STD_LOGIC;
           even : out STD_LOGIC;
           odd : out STD_LOGIC);
end component;

component Am2920 is
    Port ( clk : in STD_LOGIC;
           nE : in STD_LOGIC;
           nCLR : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           y : out STD_LOGIC_VECTOR (7 downto 0));
end component;

component Am2918 is
    Port ( clk : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (3 downto 0);
           o : buffer STD_LOGIC_VECTOR (3 downto 0);
           y : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component Am2922 is
    Port ( clk : in STD_LOGIC;
           a : in STD_LOGIC;
           b : in STD_LOGIC;
           c : in STD_LOGIC;
           pol : in STD_LOGIC;
           nME : in STD_LOGIC;
           nRE : in STD_LOGIC;
           nCLR : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           y : out STD_LOGIC);
end component;

-- http://www.cselettronica.com/datasheet/AM2909.pdf
--component Am2909 is
--	port
--	(
--		-- Input ports
--		S : in std_logic_vector(1 downto 0);
--		R,D	: in  std_logic_vector(3 downto 0);
--		ORi	: in  std_logic_vector(3 downto 0);
--		nFE, PUP, nRE, nZERO, nOE, CN : in std_logic;
--		CLK  : in std_logic;
--		-- Output ports
--		Y	: out std_logic_vector(3 downto 0);
--		C4	: out std_logic
--	);
--end component;

component Am2909x12 is
	port
	(
		-- Input ports
		S : in std_logic_vector(1 downto 0);
		R,D	: in  std_logic_vector(11 downto 0);
		ORi	: in  std_logic_vector(11 downto 0);
		nFE, PUP, nRE, nZERO, nOE, CN : in std_logic;
		CLK  : in std_logic;
		-- Output ports
		Y	: out std_logic_vector(11 downto 0);
		C4	: out std_logic
	);
end component;

-- http://www.cselettronica.com/datasheet/AM2901.pdf
component am2901c is
    Port ( clk : in  STD_LOGIC; 
           a : in  std_logic_vector (3 downto 0);-- address inputs
           b : in  STD_LOGIC_VECTOR (3 downto 0);-- address inputs
           d : in  STD_LOGIC_VECTOR (3 downto 0);-- direct data
           i : in  STD_LOGIC_VECTOR (8 downto 0);-- micro instruction
           c_n : in  STD_LOGIC;-------------------- carry in
           oe : in  STD_LOGIC;--------------------- output enable
           ram0 : inout  STD_LOGIC;---------------- shift lines to ram
           ram3 : inout  STD_LOGIC;---------------- shift lines to ram
           qs0 : inout  STD_LOGIC;----------------- shift lines to q
           qs3 : inout  STD_LOGIC;----------------- shift lines to q
           y : out  STD_LOGIC_VECTOR (3 downto 0);	-- data outputs(3-state)
           g_bar : out   STD_LOGIC;	---------------carry generate
           p_bar : out  STD_LOGIC;---------------carry propagate
           ovr : out  STD_LOGIC;	----------------overflow
           c_n4 : out  STD_LOGIC;----------------carry out
           f_0 : out  STD_LOGIC;	-----------------f = 0
           f3 : out  STD_LOGIC;	-----------------f(3) w/o 3-state
			  --- DEBUG PORT ---
			  debug_regsel: in STD_LOGIC_VECTOR(3 downto 0);
			  debug_regval: out STD_LOGIC_VECTOR(3 downto 0)
			);
end component;

signal current_instruction: std_logic_vector(7 downto 0);
signal instruction_startaddress: std_logic_vector(11 downto 0);

signal ma: std_logic_vector(8 downto 0);		-- microcode address

signal u: std_logic_vector(55 downto 0);		-- microcode output 
signal pl: std_logic_vector(55 downto 0);		-- microcode register
---------------------------------------
--	Bits	Length	Description I
---------------------------------------
--	0-2	3 			ALU Source (I0-I2 of the Am2901A's)
alias pl_alu_source: std_logic_vector(2 downto 0) is pl(2 downto 0);
--	3-5	3 			ALU Function (I3-I5 of the Am2901A's)
alias pl_alu_function: std_logic_vector(2 downto 0) is pl(5 downto 3);
--	6-8	3 			ALU Destination (I6-I8 of the Am2901A's)
alias pl_alu_destination: std_logic_vector(2 downto 0) is pl(8 downto 6);
--	9-12	4 			ALU "B" Address
alias pl_alu_b: std_logic_vector(3 downto 0) is pl(12 downto 9);
--	13-16	4 			ALU "A" Address
alias pl_alu_a: std_logic_vector(3 downto 0) is pl(16 downto 13);
--	17		1 			Single/Double Byte
alias pl_not8or16: std_logic is pl(17);
--	18		1 			Cn for least significant Am2901A slice
alias pl_carryin: std_logic is pl(18);
--	19		1 			Rotate and Swap Control (formatted)
alias pl_rotateorswap: std_logic is pl(19);
--	20-21	2 			Update/keep flags
alias pl_updateorkeepflags: std_logic_vector(1 downto 0) is pl(21 downto 20);
--	22		1 			"A" Address Switch
alias pl_aswitch: std_logic is pl(22);
--	23-24	2 			Am2901A Output Steering Control
alias pl_outputsteer: std_logic_vector(1 downto 0) is pl(24 downto 23);
--	25-26	2 			Data Bus Enable Control
alias pl_databusenable: std_logic_vector(1 downto 0) is pl(26 downto 25);
--	27-32	6 			HLDA, MEMW, MEMR, I/OW, I/OR, INTA (Am9080A System Control Outputs)
alias pl_syscontrol: std_logic_vector(5 downto 0) is pl(32 downto 27);
--	33		1 			"B" Address Switch
alias pl_bswitch: std_logic is pl(33);
--	34-37	4 			Condition Code Select
alias u_condcode: std_logic_vector(3 downto 0) is u(37 downto 34);
--	38		1 			Condition Code Polarity Control
alias u_condpolarity: std_logic is u(38);
--	39-41	3 			Next Instruction Select
alias pl_nextinstrselect: std_logic_vector(2 downto 0) is pl(41 downto 39);
--	42-53	12 		Numerical Field
alias u_immediate: std_logic_vector(11 downto 0) is u(53 downto 42);
--	54		1 			Numerical Field to Data Bus Control
alias pl_immediatedatabus: std_logic is pl(54);
--	55		1 			Instruction Register Clock Enable
alias pl_instregenable: std_logic is pl(55);
-----------------------------------------

signal sequence: std_logic_vector(4 downto 0); -- sequencer output (U14)

--signal u21_pin24, u22_pin24: std_logic;
signal u62_pin2, u62_pin4, u62_pin6, u62_pin10, u62_pin12: std_logic;
signal u63_pin7, u63_pin9: std_logic;
signal u64_pin4: std_logic;
signal u73_pin8, u73_pin6: std_logic; 
signal u83_pin6, u83_pin8, u83_pin3: std_logic;
signal u91_pin12, u91_pin9, u91_pin7, u91_pin4: std_logic;
signal u92_pin7: std_logic;
signal u97_pin9: std_logic;
signal u112_pin6: std_logic;
signal u113_pin1: std_logic;
signal u115_pin12, u115_pin9, u115_pin7, u115_pin4: std_logic;
signal u125_pin4: std_logic;
signal u126_pin6: std_logic;
signal u131_pin10: std_logic;
signal u135_pin12: std_logic;
signal u5161_pin19: std_logic;
signal u8474_u8475_pin15: std_logic; -- joined due to opposite tri-state enable
signal u121_pin2, u121_pin5, u121_pin6, u121_pin12, u121_pin15, u121_pin16: std_logic;

signal interrupt_or_mask: std_logic_vector(11 downto 0);

signal ocl: std_logic_vector(3 downto 1);
signal db: std_logic_vector(3 downto 1);

signal t: std_logic_vector(15 downto 0); -- test conditions
signal flag_z:  std_logic; --is t(0);
signal flag_cy: std_logic; --is t(1);
signal flag_p:  std_logic; --is t(2);
signal flag_s:  std_logic; --is t(3);
signal flag_ac: std_logic; --is t(4);
signal interrupt_enabled: std_logic;

signal am2901_dbg_val: std_logic_vector(15 downto 0);
signal am2901_dbg_sel: std_logic_vector(3 downto 0);
signal am2901_data: std_logic_vector(15 downto 0);
signal am2901_y: std_logic_vector(15 downto 0);
signal am2901_a: std_logic_vector(3 downto 0);
signal am2901_b: std_logic_vector(3 downto 0);
signal am2901_ram0, am2901_ram3, am2901_ram11, am2901_ram15: std_logic;
signal am2901_q0, am2901_q3, am2901_q11, am2901_q15: std_logic;
signal am2901_c3, am2901_c7, am2901_c11, am2901_c15: std_logic;
signal signal_a, signal_b, signal_c, signal_d: std_logic;
signal u33pin11, u34pin11, u43pin11, u44pin11: std_logic; -- f=0 outputs from Am2901 slices cannot be tied together as there is no "open collector"
signal am2901_f_is_0: std_logic;
signal am2901_f15: std_logic;

signal signal_rotate, signal_swap: std_logic;
   
signal bl: std_logic_vector(7 downto 0);

-- various debug signals
signal debug_register, debug_microcode: std_logic_vector(19 downto 0);
--signal debug_alu_destination, debug_alu_function, debug_alu_source: std_logic_vector(2 downto 0);
--signal debug_a_lop, debug_a_hop: std_logic_vector(3 downto 0);
signal is_debug_register_mode: std_logic;

begin

-----       debug port     --------
--is_debug_register_mode <= debug_ena and debug_sel;
with debug_reg select am2901_dbg_sel <= 
	X"7" when O"0",	-- AF
	X"0" when O"1",	-- BC
	X"2" when O"2",	-- DE
	X"4" when O"3",	-- HL
	X"8" when O"4",	-- SP
	X"F" when O"5",	-- PC
	X"C" when O"6",	-- 0038
	X"D" when others;	-- 3800

debug_register(19 downto 16) <= am2901_dbg_sel;
-- map F register (flags) to LSB of AF
debug_register(15 downto 0) <= am2901_dbg_val(15 downto 8) & (flag_s & flag_z & '0' & flag_ac & '0' & flag_p & '1' & flag_cy) when (debug_reg = "000") else am2901_dbg_val;
-- combine current microinstruction with CPU opcode
debug_microcode <= "000" & ma & current_instruction;

debug_out <= debug_microcode when (debug_sel = '1') else debug_register; 
-- if debugging register, feed NOP/OR/ZA to Am2901 instead of one coming from microcode ("pl" fields)
-- note that this interferes with the CPU operation, so the debug_ena must be explicitly enabled!
--debug_alu_destination <= "001" when (is_debug_register_mode = '1') else pl_alu_destination; -- NOP
--debug_alu_function <= "011" when (is_debug_register_mode = '1') else pl_alu_function; -- OR
--debug_alu_source <= "100" when (is_debug_register_mode = '1') else pl_alu_source; -- ZA
--debug_a_hop <= debug_reg when (is_debug_register_mode = '1') else am2901_a;
--debug_a_lop <= debug_reg when (is_debug_register_mode = '1') else am2901_a(3 downto 1) & u63_pin7;

--- expose loading of instruction register as M1 cycle signal ---
M1 <= not pl_instregenable;

-----------------------------------
---     START OF FIGURE 3       ---
-----------------------------------	

	-- instruction register ---
	u1516: am25ls377 port map (
		clk => CLK,
		nE => pl_instregenable,
		d => DBUS,
		q => current_instruction
	);
	
	-- u11, u12, u13 ----------
	mapper_rom: rom256x12 Port map ( 
	    address => current_instruction,
       data => instruction_startaddress(11 downto 0)
   );	

	-- microcode sequencers ---
	interrupt_or_mask <= (others => u73_pin8);
	
	-- to save some FPGA area, 3 * 2909 = 1 * 2909-12
	u21u22u23: am2909x12 port map (
		S => sequence(1 downto 0),
		R => u_immediate,
		D => instruction_startaddress,
		ORi => interrupt_or_mask,
		nFE => sequence(3),
		PUP => sequence(2),
		nRE => '0',
		nZERO => nRESET,
		nOE => '0',
		CN => '1', 
		CLK => CLK,
		-- Output ports
		Y(11 downto 9) => open,
		Y(8 downto 0)	=> ma,
		C4	=> open
	);
	
--	u21: am2909 port map (
--		S(1) => sequence(1),
--		S(0) => sequence(0),
--		R => u_immediate(3 downto 0),
--		D => instruction_startaddress(3 downto 0),
--		ORi => interrupt_or_mask,
--		nFE => sequence(3),
--		PUP => sequence(2),
--		nRE => '0',
--		nZERO => nRESET,
--		nOE => '0',
--		CN => '1', 
--		CLK => CLK,
--		-- Output ports
--		Y	=> ma(3 downto 0),
--		C4	=> u21_pin24
--	);
--
--	u22: am2909 port map (
--		S(1) => sequence(1),
--		S(0) => sequence(0),
--		R => u_immediate(7 downto 4),
--		D => instruction_startaddress(7 downto 4),
--		ORi => interrupt_or_mask,
--		nFE => sequence(3),
--		PUP => sequence(2),
--		nRE => '0',
--		nZERO => nRESET,
--		nOE => '0',
--		CN => u21_pin24,
--		CLK => CLK,
--		-- Output ports
--		Y	=> ma(7 downto 4),
--		C4	=> u22_pin24
--	);
--
--	u23: am2909 port map (
--		S(1) => sequence(1),
--		S(0) => sequence(0),
--		R => u_immediate(11 downto 8),
--		D => instruction_startaddress(11 downto 8),
--		ORi => interrupt_or_mask,
--		nFE => sequence(3),
--		PUP => sequence(2),
--		nRE => '0',
--		nZERO => nRESET,
--		nOE => '0',
--		CN => u22_pin24,
--		CLK => CLK,
--		-- Output ports
--		Y	=> ma(11 downto 8),
--		C4	=> open
--	);
	
	--- test condition multiplexers ---
	u8474: am2922 port map (
			  clk => CLK,
           a => u_condcode(0),
           b => u_condcode(1),
           c => u_condcode(2),
           pol => u_condpolarity,
           nME => '0',
           nRE => '0',
           nCLR => '1',
           nOE => pl(37),
           d => t(7 downto 0),
           y => u8474_u8475_pin15
	);

	t(15) <= '1'; -- TRUE
	t(14) <= u121_pin12; -- (coming from u34_pin33 == CN+4)
	t(13) <= u121_pin15; -- (coming from Am2901 common F=0)
	t(12) <= u121_pin16; -- (coming from u34_pin31 == F3)
	t(11) <= '0'; -- OPEN
	t(10) <= u121_pin6; -- HOLD
	t(9) <= READY; --u121_pin5; -- READY -- bypass clocked register and have READY one cycle faster
	t(8) <= u121_pin2; -- INT
	t(7) <= '0'; -- OPEN
	t(6) <= '0'; -- OPEN
	t(5) <= '0'; -- OPEN
	t(4) <= flag_ac; 
	t(3) <= flag_s;  
	t(2) <= flag_p;  
	t(1) <= flag_cy; 
	t(0) <= flag_z;  

	u62_pin10 <= not pl(37);
	
	u8475: am2922 port map (
			  clk => CLK,
           a => u_condcode(0),
           b => u_condcode(1),
           c => u_condcode(2),
           pol => u_condpolarity,
           nME => '0',
           nRE => '0',
           nCLR => '1',
           nOE => u62_pin10,
           d => t(15 downto 8),
           y => u8474_u8475_pin15
	);
	
   --- sequencer rom ----
    u14: rom32x8 port map ( -- TODO: it is actually 16*5 only
        nCS => '0',
		  address(3 downto 1) => pl_nextinstrselect,
        address(0) => u8474_u8475_pin15,
        data(4 downto 0) => sequence
    );
   
	INTE <= interrupt_enabled;
	u73_pin8 <= interrupt_enabled and INT and sequence(4);

   --- microcode rom ---	
   microcode_rom: rom512x56 Port map ( 
        address => ma,
        data => u
  );
  
  --- data bus output from microcode ---
  u8182: Am25LS374 port map ( 
			  clk => CLK,
           nOE => pl_immediatedatabus,
           d => u_immediate(7 downto 0),
           y => DBUS
			);
			
   --- bus state output register ---
	u83_pin6 <= u8474_u8475_pin15 and (not u73_pin6); 
	
   u7172: Am25LS374 port map ( 
			  clk => CLK,
           nOE => pl(27),
           d(0) => '0', -- ignored
           d(1) => '0', -- ignored
           d(2) => u83_pin6,
           d(3) => u(32),
           d(4) => u(31),
           d(5) => u(30),
           d(6) => u(29),
           d(7) => u(28),
           y(0) => open,
           y(1) => open,
           y(2) => WAITOUT,
           y(3) => pl(32), --nINTA,
           y(4) => pl(31), --nIOR,
           y(5) => pl(30), --nIOW,
           y(6) => pl(29), --nMEMR,
           y(7) => pl(28)  --nMEMW
			);
	HLDA <= not pl(27);
	nINTA <= pl(32);
   nIOR <= pl(31);
   nIOW <= pl(30);
   nMEMR <= pl(29);
   nMEMW <= pl(28);
	
	--- microcode output register ---
   u3132: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
           d => u(7 downto 0),
			  y => pl(7 downto 0)
			);

   u3241: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
           d => u(15 downto 8),
           y => pl(15 downto 8)
			);

   u4142: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
           d => u(23 downto 16),
           y => pl(23 downto 16)
			);

   u51: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
			  d(7 downto 4) => "0000", -- ignore
			  d(3 downto 0) => u(27 downto 24), 
			  y(7) => open,
			  y(6) => open,
			  y(5) => open,
			  y(4) => open,
			  y(3 downto 0) => pl(27 downto 24)
			);

	u62_pin6 <= not pl(55);
	
   u5161: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
           d(0) => u(37),
           d(1) => u(55),
           d(2) => u(54),
           d(3) => u(41),
           d(4) => u(40),
           d(5) => u(39),
           d(6) => u(33),
           d(7) => u62_pin6,
           y(0) => pl(37),
           y(1) => pl(55),
           y(2) => pl(54),
           y(3) => pl(41),
           y(4) => pl(40),
           y(5) => pl(39),
           y(6) => pl(33),
           y(7) => u5161_pin19
			);

-----------------------------------
---     START OF FIGURE 4       ---
-----------------------------------

-- Data bus register ---
	u12324: Am25LS377 port map (
				clk => CLK,
				nE => u5161_pin19, 
				d => DBUS,
				q => bl
	);

-- 2901 data mux ---
	u53: Am25LS157 port map ( 
				 a => bl(3 downto 0),
				 b => am2901_y(11 downto 8),
				 s => signal_swap,
				 nG => '0',
				 y => am2901_data(3 downto 0)
			);

	u54: Am25LS157 port map ( 
				 a => bl(7 downto 4),
				 b => am2901_y(15 downto 12),
				 s => signal_swap,
				 nG => '0',
				 y => am2901_data(7 downto 4)
			);

	u55: Am25LS157 port map ( 
				 a => bl(3 downto 0),
				 b => am2901_y(3 downto 0),
				 s => signal_swap,
				 nG => '0',
				 y => am2901_data(11 downto 8)
			);

	u56: Am25LS157 port map ( 
				 a => bl(7 downto 4),
				 b => am2901_y(7 downto 4),
				 s => signal_swap,
				 nG => '0',
				 y => am2901_data(15 downto 12)
			);

-- 2901 address a and b mux --
	u65: Am25LS157 port map ( 
				 a => pl_alu_b, 
				 b(3) => '0', 
				 b(2 downto 0) => current_instruction(5 downto 3), 
				 s => pl_bswitch,
				 nG => '0',
				 y => am2901_b(3 downto 0)
			);			  

	u66: Am25LS157 port map ( 
				 a => pl_alu_a, 
				 b(3) => '0', 
				 b(2 downto 0) => current_instruction(2 downto 0), 
				 s => pl_aswitch,
				 nG => '0',
				 y => am2901_a(3 downto 0)
			);			  
			
	u62_pin2 <= not am2901_a(0);
	u62_pin4 <= not am2901_b(0);
	
	u63: Am25LS153 port map ( 
				  sel(1) => pl_bswitch, 
				  sel(0) => pl_not8or16,
				  n1G => '0',
				  n2G => '0',
				  in1(3) => am2901_a(0), 
				  in1(2) => u62_pin2, 
				  in1(1) => am2901_a(0), 
				  in1(0) => u62_pin2,
				  in2(3) => '0', 
				  in2(2) => u62_pin4,
				  in2(1) => am2901_b(0),
				  in2(0) => u62_pin4,
				  out1 => u63_pin7, -- am2901_a(0) for LOP slices
				  out2 => u63_pin9  -- am2901_b(0) for LOP slices
			);
		  
-- LOP slices ---
	u43: Am2901c port map (
				  clk => CLK, 
				  a(3 downto 1) => am2901_a(3 downto 1), 
				  a(0) => u63_pin7,
				  b(3 downto 1) => am2901_b(3 downto 1), 
				  b(0) => u63_pin9,
				  d => am2901_data(3 downto 0),
				  i(8 downto 6) => pl_alu_destination,
				  i(5 downto 3) => pl_alu_function,
				  i(2 downto 0) => pl_alu_source,
				  c_n => pl_carryin,
				  oe => '0',
				  ram0 => am2901_ram0,
				  ram3 => am2901_ram3, 
				  qs0 => am2901_q0,
				  qs3 => am2901_q3,
				  y => am2901_y(3 downto 0),
				  g_bar => open,
				  p_bar => open,
				  ovr => open,
				  c_n4 => am2901_c3,
				  f_0 => u43pin11,
				  f3 => open,
				  -- DEBUG PORT --
				  debug_regsel => am2901_dbg_sel,
				  debug_regval => am2901_dbg_val(3 downto 0)
	);		  

	u44: Am2901c port map (
				  clk => CLK, 
				  a(3 downto 1) => am2901_a(3 downto 1), 
				  a(0) => u63_pin7,
				  b(3 downto 1) => am2901_b(3 downto 1), 
				  b(0) => u63_pin9,
				  d => am2901_data(7 downto 4),
				  i(8 downto 6) => pl_alu_destination,
				  i(5 downto 3) => pl_alu_function,
				  i(2 downto 0) => pl_alu_source,
				  c_n => am2901_c3,
				  oe => '0',
				  ram0 => am2901_ram3,
				  ram3 => signal_c, 
				  qs0 => am2901_q3,
				  qs3 => signal_d,
				  y => am2901_y(7 downto 4),
				  g_bar => open,
				  p_bar => open,
				  ovr => open,
				  c_n4 => am2901_c7,
				  f_0 => u44pin11,
				  f3 => open,
				  -- DEBUG PORT --
				  debug_regsel => am2901_dbg_sel,
				  debug_regval => am2901_dbg_val(7 downto 4)
	);		  

-- HOP slices ---
	u33: Am2901c port map (
				  clk => CLK, 
				  a => am2901_a,
				  b => am2901_b,
				  d => am2901_data(11 downto 8),
				  i(8 downto 6) => pl_alu_destination,
				  i(5 downto 3) => pl_alu_function,
				  i(2 downto 0) => pl_alu_source,
				  c_n => u64_pin4,
				  oe => '0',
				  ram0 => signal_b,
				  ram3 => am2901_ram11, 
				  qs0 => signal_a,
				  qs3 => am2901_q11,
				  y => am2901_y(11 downto 8),
				  g_bar => open,
				  p_bar => open,
				  ovr => open,
				  c_n4 => am2901_c11,
				  f_0 => u33pin11,
				  f3 => open,
				  -- DEBUG PORT --
				  debug_regsel => am2901_dbg_sel,
				  debug_regval => am2901_dbg_val(11 downto 8)
	);		  

	u34: Am2901c port map (
				  clk => CLK, 
				  a => am2901_a,
				  b => am2901_b,
				  d => am2901_data(15 downto 12),
				  i(8 downto 6) => pl_alu_destination,
				  i(5 downto 3) => pl_alu_function,
				  i(2 downto 0) => pl_alu_source,
				  c_n => am2901_c11,
				  oe => '0',
				  ram0 => am2901_ram11,
				  ram3 => am2901_ram15, 
				  qs0 => am2901_q11,
				  qs3 => am2901_q15,
				  y => am2901_y(15 downto 12),
				  g_bar => open,
				  p_bar => open,
				  ovr => open,
				  c_n4 => am2901_c15,
				  f_0 => u34pin11,
				  f3 => am2901_f15,
				  -- DEBUG PORT --
				  debug_regsel => am2901_dbg_sel,
				  debug_regval => am2901_dbg_val(15 downto 12)
	);		  

	-- use standard "and", not open collector.
	am2901_f_is_0 <= u33pin11 and u34pin11 and u43pin11 and u44pin11; 
	
	u64: Am25LS157 port map ( 
				 a(3) => '0',
				 a(2) => pl_rotateorswap,
				 a(1) => pl_carryin, 
				 a(0) => '0',			-- open 
				 
				 b(3) => pl_rotateorswap,   
				 b(2) => '0',   
				 b(1) => am2901_c7,	-- open 
				 b(0) => '0', 			-- open,
				 
				 s => pl_not8or16,
				 nG => '0',
				 
				 y(3) => signal_swap,
				 y(2) => signal_rotate,
				 y(1) => u64_pin4,
				 y(0) => open
			);	
			
	 u62_pin12 <= not pl(7);
	 
    u76: Am25LS257 port map ( 
           b(3) => am2901_q15, 
			  b(2) => signal_d,   
			  b(1) => flag_cy, 
			  b(0) => flag_cy,
			  a(3) => signal_d,   
			  a(2) => am2901_q15, 
			  a(1) => signal_c, 
			  a(0) => am2901_ram15,
           s => signal_rotate,
           nOE => u62_pin12,
           y(3) => am2901_q0, 
			  y(2) => signal_a, 
			  y(1) => am2901_ram0, 
			  y(0) => signal_b
			);

    u77: Am25LS257 port map ( 
			  a(3) => am2901_q0, 
			  a(2) => signal_a, 
			  a(1) => am2901_ram0, 
			  a(0) => signal_b,
           b(3) => signal_a, 
			  b(2) => am2901_q0, 
			  b(1) => flag_cy, 
			  b(0) => flag_cy,
           s => signal_rotate,
           nOE => pl(7),
           y(3) => signal_d, 
			  y(2) => am2901_q15, 
			  y(1) => signal_c, 
			  y(0) => am2901_ram15
			);

-----------------------------------
---     START OF FIGURE 5       ---
-----------------------------------
-- parity generator
	u97: Am82S62 port map ( 
				p(8) => '0',
				p(7 downto 0) => am2901_y(15 downto 8),
				inhibit => '0',
				even => u97_pin9,
				odd => open
			);
			
-- address bus register
	u9596: Am2920 port map (
				clk => CLK,
            nE => ocl(2),
            nCLR => '1',
            nOE => pl(27),
            d => am2901_y(7 downto 0),
            y => ABUS(7 downto 0)
			);

	u10506: Am2920 port map (
				clk => CLK,
            nE => ocl(2),
            nCLR => '1',
            nOE => pl(27),
            d => am2901_y(15 downto 8),
            y => ABUS(15 downto 8)
			);

-- data bus register (LSB)
	u9394: Am2920 port map (
				clk => CLK,
            nE => ocl(1),
            nCLR => '1',
            nOE => db(1),
            d => am2901_y(7 downto 0),
            y => DBUS(7 downto 0)
			);

-- data bus register (MSB)
	u10304: Am2920 port map (
				clk => CLK,
            nE => ocl(1),
            nCLR => '1',
            nOE => db(2),
            d => am2901_y(15 downto 8),
            y => DBUS(7 downto 0)
			);
			
-- data bus register (FLAGS)
-- 7 6 5 4  3 2 1 0 --------
-- S Z 0 AC 0 P 1 C --------
	  u102: Am2918 port map ( 
					clk => CLK,
					nOE => db(3),
					d(3) => '1', 
					d(2) => '0', 
					d(1) => '0', 
					d(0) => u92_pin7,
					o(3) => open, 
					o(2) => open, 
					o(1) => open, 
					o(0) => flag_cy,
					y(3) => DBUS(1), 
					y(2) => DBUS(3), 
					y(1) => DBUS(5), 
					y(0) => DBUS(0)
				);
				  
	  u101: Am2918 port map ( 
					clk => CLK,
					nOE => db(3),
					d(3) => u91_pin4, 
					d(2) => u91_pin7, 
					d(1) => u91_pin9, 
					d(0) => u91_pin12,
					o(3) => flag_z, 
					o(2) => flag_p, 
					o(1) => flag_s, 
					o(0) => flag_ac,
					y(3) => DBUS(6), 
					y(2) => DBUS(2), 
					y(1) => DBUS(7), 
					y(0) => DBUS(4)
				);
			
-- bus register enabler
	u131: Am25139 port map (
				nG1 => '0',
				B1 => pl_databusenable(1), 
				A1 => pl_databusenable(0), 
				nY1(0) => open,
				nY1(1) => db(1),
				nY1(2) => db(2),
				nY1(3) => db(3),
				---------
				nG2 => '0',
				B2 => pl_outputsteer(1),
				A2 => pl_outputsteer(0),
				nY2(0) => open,
				nY2(1) => ocl(1),
				nY2(2) => u131_pin10,
				nY2(3) => ocl(3)
			);
			
	-- high only if there is memory or io read/write		
	u73_pin6 <= '1' when pl_syscontrol(4 downto 1) = "1111" else '0';		
	ocl(2) <= u131_pin10 or (t(9) nor u73_pin6);		

-- condition code and misc bus logic
   u121: Am25LS374 port map ( 
			  clk => CLK,
           nOE => '0',
           d(0) => INT,
           d(1) => READY,
           d(2) => HOLD,
           d(3) => '0', --open
           d(4) => am2901_c15,
           d(5) => am2901_f_is_0,
           d(6) => am2901_f15,
           d(7) => '0', --open
           y(0) => u121_pin2,
           y(1) => u121_pin5,
           y(2) => u121_pin6,
           y(3) => open,
           y(4) => u121_pin12,
           y(5) => u121_pin15,
           y(6) => u121_pin16,
           y(7) => open
			);

	u111: Am2920 port map (
				clk => CLK,
            nE => ocl(3),
            nCLR => '1',
            nOE => pl_syscontrol(0), -- HLDA
            d(0) => am2901_f15, 
				d(1) => '0', --open
				d(2) => '0', --open
				d(3) => '0', --open
				d(4) => '0', --open
				d(5) => '0', --open
				d(6) => '0', --open
				d(7) => '0', --open
            y(0) => interrupt_enabled,
				y(1) => open,
				y(2) => open,
				y(3) => open,
				y(4) => open,
				y(5) => open,
				y(6) => open,
				y(7) => open
			);

	  u113_pin1 <= pl(5) nor (pl(4) and pl(3)); -- ADD, SUBS, SUBS
	  u83_pin8 <= am2901_c11 and u113_pin1;
	  u83_pin3 <= am2901_c15 and u113_pin1;
	  u126_pin6 <= u113_pin1 and (pl(4) or pl(3));
	  u135_pin12 <= '1' when pl_alu_function = "101" else '0'; -- NOTRS
	  u112_pin6 <= not u83_pin3;
	  
	  u92: Am25LS153 port map (
				sel(1) => pl_updateorkeepflags(1), 
				sel(0) => u126_pin6,
            n1G => '0',
            n2G => '0',
            in1(3) => u125_pin4, 
				in1(2) => u125_pin4, 
				in1(1) => u112_pin6, 
				in1(0) => u83_pin3,
            in2 => "0000", --open
            out1 => u92_pin7,
            out2 => open
			);

		u125: Am25LS157 port map (
					a(3 downto 1) => "000", -- open
					a(0) => flag_cy,
					b(3 downto 1) => "000", -- open
					b(0) => bl(0),
					s => u135_pin12,
					nG => '0',
					----------------
					y(3) => open, 
					y(2) => open, 
					y(1) => open, 
					y(0) => u125_pin4
				);				

		u91: Am25LS157 port map (
					a(3) => u83_pin8, 		--4A
					a(2) => am2901_f15, 		--3A
					a(1) => u97_pin9, 		--2A
					a(0) => am2901_f_is_0,	--1A
					b(3) => u115_pin12, 		--4B
					b(2) => u115_pin9, 		--3B
					b(1) => u115_pin7, 		--2B
					b(0) => u115_pin4,		--1B
					s => pl_updateorkeepflags(0),
					nG => '0',
					----------------
					y(3) => u91_pin12, 
					y(2) => u91_pin9, 
					y(1) => u91_pin7, 
					y(0) => u91_pin4
				);			

		u115: Am25LS157 port map (
					a(3) => flag_ac,	--4A
					a(2) => flag_s, 	--3A
					a(1) => flag_p, 	--2A
					a(0) => flag_z,	--1A
					b(3) => bl(4), 	--4B
					b(2) => bl(7), 	--3B
					b(1) => bl(2), 	--2B
					b(0) => bl(6),		--1B
					s => u135_pin12,
					nG => '0',
					y(3) => u115_pin12, 
					y(2) => u115_pin9, 
					y(1) => u115_pin7, 
					y(0) => u115_pin4
				);			
						
end structural;

