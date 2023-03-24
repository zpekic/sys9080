----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:50:59 02/13/2016 
-- Design Name: 
-- Module Name:    mux16to4 - structural 
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

entity mux16to4 is
    Port ( x3 : in  STD_LOGIC_VECTOR (3 downto 0);
           x2 : in  STD_LOGIC_VECTOR (3 downto 0);
           x1 : in  STD_LOGIC_VECTOR (3 downto 0);
           x0 : in  STD_LOGIC_VECTOR (3 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
			  nEnable : in  STD_LOGIC;
			  ascii: in STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (7 downto 0));
end mux16to4;

architecture behavioral of mux16to4 is

signal y_hex: std_logic_vector(3 downto 0);
signal y_int, y_ascii, offset: std_logic_vector(7 downto 0);
signal over9: std_logic;

begin

	-- select input
	with sel select
		y_hex <= x0 when "00",
					x1 when "01",
					x2 when "10",
					x3 when others;
	-- convert to ASCII
	over9 <= (y_hex(3) and y_hex(2)) or (y_hex(3) and (not y_hex(2)) and y_hex(1)); -- 101X, 11XX
	offset <= X"37" when over9 = '1' else X"30";
   y_ascii <= std_logic_vector(unsigned("0000" & y_hex) + unsigned(offset));
	-- pick ascii or hex
	y_int <= y_ascii when (ascii = '1') else "0000" & y_hex;
	-- pass to output if enabled
	y <= y_int when (nEnable = '0') else "ZZZZZZZZ";
	
end behavioral;