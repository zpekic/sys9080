----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/26/2017 09:54:45 AM
-- Design Name: 
-- Module Name: counter16bit - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter16bit is
    Port ( reset : in STD_LOGIC;
           clk : in STD_LOGIC;
           mode : in STD_LOGIC_VECTOR (1 downto 0);
           d : in STD_LOGIC_VECTOR (31 downto 0);
           q : out STD_LOGIC_VECTOR (31 downto 0));
end counter16bit;

architecture Behavioral of counter16bit is

signal count: std_logic_vector(31 downto 0);

begin

q <= count;

update: process (reset, clk, mode, d)
begin
 if (reset = '1') then -- async reset
	count <= X"00000000";
 else
	if (rising_edge(clk)) then
		case (mode) is
			when "00" => -- no change
				count <= count;
			when "01" => -- increment
				count <= std_logic_vector(unsigned(count) + 1);
			when "10" => -- decrement
			    count <= std_logic_vector(unsigned(count) - 1);
			when "11" => -- synchronous set
				count <= d; 
			when others =>
				null;
		end case;
	end if;
 end if;
 
end process;

end Behavioral;
