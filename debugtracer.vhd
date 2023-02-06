----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:29:08 11/12/2019 
-- Design Name: 
-- Module Name:    debugtracer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debugtracer is
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
end debugtracer;

architecture Behavioral of debugtracer is

type rom64x8 is array(0 to 63) of std_logic_vector(7 downto 0);
type rom16x8 is array(0 to 15) of std_logic_vector(7 downto 0);

constant char_NULL: std_logic_vector(7 downto 0) := X"00";
constant char_CLEAR: std_logic_vector(7 downto 0) := X"01";
constant char_HOME: std_logic_vector(7 downto 0) := X"02";
constant char_CR: std_logic_vector(7 downto 0) := X"0D";
constant char_LF: std_logic_vector(7 downto 0) := X"0A";

-- 
constant HEX: std_logic_vector(2 downto 0) := "000";
constant RWF: std_logic_vector(2 downto 0) := "001";
constant MPX: std_logic_vector(2 downto 0) := "010";

--
constant trace_sequence: rom64x8 := 
(
   char_CLEAR, -- will write this only after reset, otherwise start at next location
   char_CR,
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)),
	'1' & RWF & X"9",
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)),
	'1' & RWF & X"8",
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
	'1' & HEX & X"7",
	'1' & HEX & X"6",
	'1' & HEX & X"5",
	'1' & HEX & X"4",
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('D'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
	'1' & HEX & X"3",
	'1' & HEX & X"2",
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('Y'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
	'1' & HEX & X"1",
	'1' & HEX & X"0",
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('X'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
	'1' & HEX & X"B",
	'1' & HEX & X"A",
   char_LF,
	others => char_NULL
);

--- convert nibble to hex char
constant hex_lookup: rom16x8 := 
(
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('0'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('1'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('2'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('3'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('4'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('5'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('6'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('7'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('8'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('9'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('B'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('C'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('D'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('E'), 8)),
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('F'), 8))
);	

--- convert ('1', '1', nMem, nIO) to hex char
constant mpx_lookup: rom16x8 := 
(
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('0'), 8)), -- 0000 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('1'), 8)), -- 0001 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('2'), 8)), -- 0010 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('3'), 8)), -- 0011 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('4'), 8)), -- 0100 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('5'), 8)), -- 0101 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('6'), 8)), -- 0110 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('7'), 8)), -- 0111 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('8'), 8)), -- 1000 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('9'), 8)), -- 1001 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8)), -- 1010 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('B'), 8)), -- 1011 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('C'), 8)), -- 1100 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)), -- 1101 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)), -- 1110 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('-'), 8))  -- 1111 --- VALID
);	

--- convert ('1', M1, nRD, nWR) to hex char
constant rwf_lookup: rom16x8 := 
(
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('0'), 8)), -- 0000 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('1'), 8)), -- 0001 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('2'), 8)), -- 0010 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('3'), 8)), -- 0011 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('4'), 8)), -- 0100 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('5'), 8)), -- 0101 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('6'), 8)), -- 0110 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('7'), 8)), -- 0111 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('8'), 8)), -- 1000 ---
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8)), -- 1001 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8)), -- 1010 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('-'), 8)), -- 1011 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('C'), 8)), -- 1100 --- 
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('F'), 8)), -- 1101 --- VALID
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('E'), 8)), -- 1110 ---  
   STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8))  -- 1111 ---
);	

signal done, set_done: std_logic;
signal sel_index: integer range 0 to 63;
signal trace_i, trace_char, data_char: std_logic_vector(7 downto 0);
signal nibble: std_logic_vector(3 downto 0);

begin

-- keep ready high when not in active tracing
ready <= '1' when (trace = '0') else done;

-- internal done is set when last "instruction" X"00" triggers it
update_done: process(reset, trace, set_done)
begin
	if (reset = '1' or trace = '0') then
		done <= '0';
	else
		if (rising_edge(set_done)) then
			done <= '1';
		end if;
	end if;
end process;

update_sel_index: process(reset, trace, char_sent)
begin
	if (reset = '1' or trace = '0') then
		if (reset = '1') then
			sel_index <= 0; -- start at 0 when reset (e.g. clear screen)
		else	
			sel_index <= 1; -- start at 1 otherwise	
		end if;
	else
		if (rising_edge(char_sent)) then
			sel_index <= sel_index + 1;
		end if;
	end if;
end process;

-- current instruction
trace_i <= trace_sequence(sel_index);
-- if zero, trigger done
set_done <= '1' when (trace_i = char_NULL) else '0';

-- output data path
char <= X"00" when (reset = '1' or trace = '0' or char_sent = '1') else trace_char;

trace_char <= trace_i when (trace_i(7) = '0') else data_char; 

with trace_i(3 downto 0) select
	nibble <= 	in0 when X"0",
				in1 when X"1",
				in2 when X"2",
				in3 when X"3",
				in4 when X"4",
				in5 when X"5",
				in6 when X"6",
				in7 when X"7",
				in8 when X"8",
				in9 when X"9",
				in10 when X"A",
				in11 when X"B",
				X"0" when others;

with trace_i(6 downto 4) select
	data_char <= 	hex_lookup(to_integer(unsigned(nibble))) when HEX,
						rwf_lookup(to_integer(unsigned(nibble))) when RWF,
						mpx_lookup(to_integer(unsigned(nibble))) when MPX,
						STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) when others;

end Behavioral;

