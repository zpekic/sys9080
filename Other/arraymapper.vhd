----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:55:16 10/06/2018 
-- Design Name: 
-- Module Name:    arraymapper - Behavioral 
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

entity arraymapper is
    Port ( doublecols : in  STD_LOGIC;
           row : in  STD_LOGIC_VECTOR (5 downto 0);
           col : in  STD_LOGIC_VECTOR (5 downto 0);
           y : out  STD_LOGIC_VECTOR (10 downto 0));
end arraymapper;

architecture Behavioral of arraymapper is

type mulby30 is array (0 to 33) of integer range 0 to 1023;
constant lookup: mulby30 :=(
		0,			-- 0
		30,
		60,
		90,
		120,
		150,
		180,
		210,
		240,
		270,
		300,		-- 10
		330,
		360,
		390,
		420,
		450,
		480,
		510,
		540,
		570,
		600,		-- 20
		630,
		660,
		690,
		720,
		750,
		780,
		810,
		840,
		870,
		900,		-- 30
		930,		-- 31
		960,		-- 32
		990		-- 33
);

signal rowstart, offset: std_logic_vector(10 downto 0);

begin

rowstart <= std_logic_vector(to_unsigned(lookup(to_integer(unsigned(row))), 11));
offset <= rowstart when doublecols = '0' else rowstart(9 downto 0) & '0';
y <= std_logic_vector(unsigned(offset) + unsigned("00000" & col));

end Behavioral;

