----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:49:28 04/25/2020 
-- Design Name: 
-- Module Name:    nibbleadder - Behavioral 
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

entity nibbleadder is
    Port ( cin : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           na : in  STD_LOGIC;
           nb : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
end nibbleadder;

architecture Behavioral of nibbleadder is

type lookup32 is array (0 to 31) of std_logic_vector(4 downto 0);
constant adcbcd: lookup32 :=
(
		'0' & X"0",   --0 
		'0' & X"1",   --1
		'0' & X"2",   --2
		'0' & X"3",   --3
		'0' & X"4",   --4
		'0' & X"5",   --5
		'0' & X"6",   --6
		'0' & X"7",   --7
		'0' & X"8",   --8
		'0' & X"9",   --9 
		'1' & X"0",   --A
		'1' & X"1",   --B
		'1' & X"2",   --C
		'1' & X"3",   --D
		'1' & X"4",   --E
		'1' & X"5",   --F 
		'1' & X"6",   --10 
		'1' & X"7",   --11
		'1' & X"8",   --12
		'1' & X"9",   --13 -- 9 + 9 + 1 = 19
		'1' & X"F",   --14 -- error from now on! 
		'1' & X"F",   --15
		'1' & X"F",   --16
		'1' & X"F",   --17 
		'1' & X"F",   --18
		'1' & X"F",   --19
		'1' & X"F",   --1A
		'1' & X"F",   --1B
		'1' & X"F",   --1C 
		'1' & X"F",   --1D
		'1' & X"F",   --1E
		'1' & X"F"	  --1F
);

type lookup16 is array (0 to 15) of std_logic_vector(3 downto 0);
constant a_compl9: lookup16 :=
(
		X"9",   --0 
		X"8",   --1
		X"7",   --2
		X"6",   --3
		X"5",   --4
		X"4",   --5
		X"3",   --6
		X"2",   --7
		X"1",   --8
		X"0",   --9 
		X"0",   --A (error from now on)
		X"0",   --B
		X"0",   --C
		X"0",   --D
		X"0",   --E
		X"0"    --F
);		

constant b_compl9: lookup16 :=
(
		X"9",   --0 
		X"8",   --1
		X"7",   --2
		X"6",   --3
		X"5",   --4
		X"4",   --5
		X"3",   --6
		X"2",   --7
		X"1",   --8
		X"0",   --9 
		X"0",   --A (error from now on)
		X"0",   --B
		X"0",   --C
		X"0",   --D
		X"0",   --E
		X"0"    --F
);		

signal r, s: std_logic_vector(3 downto 0);
signal sel_r, sel_s: std_logic_vector(1 downto 0);
signal sum_bin: std_logic_vector(5 downto 0);
signal sum_bcd: std_logic_vector(4 downto 0);

begin

sel_r <= bcd & na;
with sel_r select
	r <=	a 				when "00",	-- binary add
			a xor X"F" 	when "01",	-- binary sub
			a 				when "10",	-- bcd add
			a_compl9(to_integer(unsigned(a))) when others;	-- bcd sub

sel_s <= bcd & nb;
with sel_s select
	s <=	b 				when "00",	-- binary add
			b xor X"F" 	when "01",	-- binary sub
			b 				when "10",	-- bcd add
			b_compl9(to_integer(unsigned(b))) when others;	-- bcd sub

sum_bin <= std_logic_vector(unsigned('0' & r & '1') + unsigned('0' & s & cin));
sum_bcd <= adcbcd(to_integer(unsigned(sum_bin(5 downto 1))));

y <= sum_bin(4 downto 1) when (bcd = '0') else sum_bcd(3 downto 0);
cout <= sum_bin(5) when (bcd = '0') else sum_bcd(4);

end Behavioral;

