----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:14:42 03/03/2023 
-- Design Name: 
-- Module Name:    encoder16to4 - Behavioral 
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

entity encoder16to4 is
    Port ( i : in  STD_LOGIC_VECTOR (15 downto 0);
           o : out  STD_LOGIC_VECTOR (3 downto 0);
           valid : out  STD_LOGIC);
end encoder16to4;

architecture Behavioral of encoder16to4 is

type rom16x4 is array(0 to 15) of std_logic_vector(3 downto 0);

constant encoder4to2: rom16x4 := (
		"0000", 	-- 0000
		"0001", 	-- 0001
		"0011",	-- 001X
		"0011",	-- 001X
		"0101",	-- 01XX
		"0101",	-- 01XX
		"0101",	-- 01XX
		"0101",	-- 01XX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111",	-- 1XXX
		"0111"	-- 1XXX
);

signal e1: std_logic_vector(15 downto 0);
signal e2, o2: std_logic_vector(3 downto 0);

begin

-- 1st level
e1(3 downto 0) <= encoder4to2(to_integer(unsigned(i(3 downto 0))));
e1(7 downto 4) <= encoder4to2(to_integer(unsigned(i(7 downto 4))));
e1(11 downto 8) <= encoder4to2(to_integer(unsigned(i(11 downto 8))));
e1(15 downto 12) <= encoder4to2(to_integer(unsigned(i(15 downto 12))));

-- 2nd level
o2 <= e1(12) & e1(8) & e1(4) & e1(0);
e2 <= encoder4to2(to_integer(unsigned(o2)));

-- outputs
valid <= e2(0);

o(3 downto 2) <= e2(2 downto 1);
with e2(2 downto 1) select o(1 downto 0) <=
	e1(2 downto 1) when "00",
	e1(6 downto 5) when "01",
	e1(10 downto 9) when "10",
	e1(14 downto 13) when others;

end Behavioral;

