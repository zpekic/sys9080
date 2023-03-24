----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:03:59 11/17/2018 
-- Design Name: 
-- Module Name:    color_rom - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity color_rom is
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           d : out  STD_LOGIC_VECTOR (7 downto 0));
end color_rom;

architecture Behavioral of color_rom is

type colorpalette is array (0 to 15) of std_logic_vector(23 downto 0);
----------------------------------------------------------
-- Based on C64 palette from https://www.c64-wiki.com/wiki/Color
----------------------------------------------------------
constant c64palette: colorpalette :=(
		X"000000", 	-- Black
		X"FFFFFF",	-- White
		X"880000",	-- Red
		X"AAFFEE",	-- Cyan
		X"CC44CC",	-- Purple / Violet
		X"00CC55",	-- Green
		X"0000AA",	-- Blue
		X"DD8855",	-- Orange
		X"664400",	-- Brown
		X"FF7777",	-- Light red
		X"333333",	-- Dark grey
		X"777777",	-- Medium grey
		X"AAFF66",	-- Light green
		X"0088FF",	-- Light blue
		X"BBBBBB"	-- Light grey
	);
	
signal color24: std_logic_vector(23 downto 0);
alias red: std_logic_vector(7 downto 0) is color24(23 downto 16);
alias green: std_logic_vector(7 downto 0) is color24(15 downto 8);
alias blue: std_logic_vector(7 downto 0) is color24(7 downto 0);

begin

color24 <= c64palette(to_integer(unsigned(a)));

-- sample high order bits only to convert to 8 bit color RRRGGGBB
d(7 downto 5) <= green(7 downto 5);
d(4 downto 2) <= red(7 downto 5);
d(1 downto 0) <= blue(7 downto 6);

end Behavioral;

