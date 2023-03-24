----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:21:06 04/23/2022 
-- Design Name: 
-- Module Name:    bcdcounter - Behavioral 
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

entity bcdcounter is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           value : buffer  STD_LOGIC_VECTOR (31 downto 0));
end bcdcounter;

architecture Behavioral of bcdcounter is

component adder16 is
    Port ( cin : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (15 downto 0);
           b : in  STD_LOGIC_VECTOR (15 downto 0);
           na : in  STD_LOGIC;
           nb : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (15 downto 0);
           cout : out  STD_LOGIC);
end component;

signal sum: std_logic_vector(31 downto 0);
signal c: std_logic_vector(2 downto 0);

begin

on_clk: process(clk, reset, sum)
begin
	if (reset = '1') then
		value <= (others => '0');
	else
		if (rising_edge(clk)) then 
			value <= sum;
		end if;
	end if;
end process;

c(0) <= enable;

generate_adder32: for i in 0 to 1 generate
	adder: adder16 Port map ( 
				cin => c(i), 
				a => value((((i + 1) * 16) - 1) downto (i * 16)),
				b => X"0000",
				na => '0',
				nb => '0',
				bcd => '1',
				y => sum((((i + 1) * 16) - 1) downto (i * 16)),
				cout => c(i + 1) 
			);
end generate;

end Behavioral;

