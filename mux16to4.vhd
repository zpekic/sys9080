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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux16to4 is
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           c : in  STD_LOGIC_VECTOR (3 downto 0);
           d : in  STD_LOGIC_VECTOR (3 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
			  nEnable : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (3 downto 0));
end mux16to4;

architecture behavioral of mux16to4 is
begin
	mux: process(nEnable, sel, a, b, c, d)
	begin
		if (nEnable = '0') then
			case sel is
				when "00" =>
					y <= a;
				when "01" =>
					y <= b;
				when "10" =>
					y <= c;
				when "11" =>
					y <= d;
				when others =>
					null;
			end case;
		else
			y <= "ZZZZ";
		end if;
	end process;
end behavioral;