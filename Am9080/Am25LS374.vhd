----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/24/2017 10:11:13 AM
-- Design Name: 
-- Module Name: Am25LS374 - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Am25LS374 is
    Port ( clk : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           y : out STD_LOGIC_VECTOR (7 downto 0)
			 );
end Am25LS374;

architecture Behavioral of Am25LS374 is

signal q: std_logic_vector(7 downto 0);

begin

update_q: process(clk, d)
begin
    if (rising_edge(clk)) then
        q <= d;
    end if;
end process;

y <= q when (nOE = '0') else "ZZZZZZZZ";

end Behavioral;
