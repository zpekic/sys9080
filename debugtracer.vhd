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
			  cpu_clk: in STD_LOGIC;
			  txd_clk: in STD_LOGIC;
			  continue: in STD_LOGIC;
           ready : out  STD_LOGIC;
           txd : out STD_LOGIC;
			  load : in STD_LOGIC;							-- load trigger selection
			  sel : in STD_LOGIC_VECTOR(4 downto 0);	-- 1 for signal that will trigger trace
           nM1 : in  STD_LOGIC;
           nIOR : in  STD_LOGIC;
           nIOW : in  STD_LOGIC;
           nMEMR : in  STD_LOGIC;
           nMEMW : in  STD_LOGIC;
           ABUS : in  STD_LOGIC_VECTOR (15 downto 0);
           DBUS : in  STD_LOGIC_VECTOR (7 downto 0)
			  );
end debugtracer;

architecture Behavioral of debugtracer is

type rom16x8 is array(0 to 15) of std_logic_vector(7 downto 0);

--constant char_NULL: std_logic_vector(7 downto 0) := X"00";
--constant char_CLEAR: std_logic_vector(7 downto 0) := X"01";
--constant char_HOME: std_logic_vector(7 downto 0) := X"02";
constant char_CR: std_logic_vector(7 downto 0) := X"0D";
constant char_LF: std_logic_vector(7 downto 0) := X"0A";

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

signal trace_start, trace_done, trace_clk, trace, trace_enable: std_logic;
signal reg_match, cbus: std_logic_vector(4 downto 0);
signal counter: std_logic_vector(7 downto 0);
alias chrSel: std_logic_vector(3 downto 0) is counter(7 downto 4);
alias bitSel: std_logic_vector(3 downto 0) is counter(3 downto 0);

signal char_1, char_2, char_hex, char: std_logic_vector(7 downto 0);
signal hex: std_logic_vector(3 downto 0);

begin

ready <= not trace;
cbus <= nM1 & nIOR & nIOW & nMEMR & nMEMW;

on_cpu_clk: process(reset, cpu_clk, ABUS, cbus, char)
begin
	if (reset = '1') then 
		trace <= '0';
		trace_enable <= '1';
--		reg_match <= (others => '1');
		reg_match <= not sel;
	else
		if (rising_edge(cpu_clk)) then
			-- update trace enable FF 
			-- responds to OUT 0x00 (trace off) to OUT 0x01 (trace on)
			if ((ABUS(7 downto 1) = "0000000") and (cbus(2) = '0')) then
				trace_enable <= ABUS(0);
			end if;
			if (load = '1') then
				reg_match <= not sel;
			end if;
		end if;
		if (falling_edge(cpu_clk)) then
			if (trace = '0') then 
			-- check if needs to be turned on
				if ((reg_match or cbus) /= "11111") then
					trace <= trace_enable;
				end if;
			else
			-- check if needs to be turned off
				if (char = X"00") then
					trace <= not continue;
				end if;
			end if;
		end if;
	end if;
end process;

---- main trace counter
on_txd_clk: process(txd_clk, trace, char)
begin
	if (trace = '0') then
		counter <= (others => '0');
	else
		if (rising_edge(txd_clk)) then
			if (char /= X"00") then
				counter <= std_logic_vector(unsigned(counter) + 1);
			end if;
		end if;
	end if;
end process;

-- character generation
with cbus select char_1 <=
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) when "01101",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) when "11101",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) when "11110",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('I'), 8)) when "10111",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('I'), 8)) when "11011",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) when others;

with cbus select char_2 <=
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('1'), 8)) when "01101",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8)) when "11101",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8)) when "11110",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8)) when "10111",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8)) when "11011",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) when others;

with chrSel select hex <=
	ABUS(15 downto 12) when X"3",	-- A
	ABUS(11 downto 8) when X"4",	-- A
	ABUS(7 downto 4) when X"5",	-- A
	ABUS(3 downto 0) when X"6",	-- A
	DBUS(7 downto 4) when X"8",	-- D
	DBUS(3 downto 0) when others; 	-- D

char_hex <= hex_lookup(to_integer(unsigned(hex)));

with chrSel select char <= 
	char_1 when X"0",
	char_2 when X"1",
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(','), 8)) when X"2",
--	char_hex when X"3",	-- A
--	char_hex when X"4",	-- A
--	char_hex when X"5",	-- A
--	char_hex when X"6",	-- A
	STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)) when X"7",
--	char_hex when X"8",	-- D
--	char_hex when X"9", 	-- D
	char_CR when X"A",
	char_LF when X"B",
	X"00" when X"C",
	char_hex when others;
	
-- serial output logic
with bitSel select txd <= 		
			'1'     when X"0", -- high while not busy
			'1'	  when X"1", -- delay 1 (to sync with txd_clk)
			'1'	  when X"2", -- delay 2 
			'0' 	  when X"3", -- start bit
			char(0) when X"4", -- data
			char(1) when X"5",
			char(2) when X"6",
			char(3) when X"7",
			char(4) when X"8",
			char(5) when X"9",
			char(6) when X"A",
			char(7) when X"B",
			'1'     when X"C",	-- parity or stop
			'1' 	  when X"D",	-- stop
			'1' when others;		-- delay
			
end Behavioral;

