----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2017 11:29:08 PM
-- Design Name: 
-- Module Name: Am2918 - Behavioral
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

entity Am2918 is
    Port ( clk : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (3 downto 0);
           o : buffer STD_LOGIC_VECTOR (3 downto 0);
           y : out STD_LOGIC_VECTOR (3 downto 0));
end Am2918;

architecture Behavioral of Am2918 is

begin

y <= o when (nOE = '0') else "ZZZZ";

load_q: process(clk, d)
begin
    if (rising_edge(clk)) then
        o <= d;
    end if;
end process;

end Behavioral;
