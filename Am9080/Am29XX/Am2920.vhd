----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2017 11:10:09 PM
-- Design Name: 
-- Module Name: Am2920 - Behavioral
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

entity Am2920 is
    Port ( clk : in STD_LOGIC;
           nE : in STD_LOGIC;
           nCLR : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           y : out STD_LOGIC_VECTOR (7 downto 0));
end Am2920;

architecture Behavioral of Am2920 is

signal q: std_logic_vector(7 downto 0);

begin

y <= q when (nOE = '0') else "ZZZZZZZZ";

load_q: process(clk, d, nE, nCLR)
begin
    if (nCLR = '0') then
        q <= (others => '0');
    else
       if (rising_edge(clk) and (nE = '0')) then
            q <= d;
       end if; 
    end if;
end process;

end Behavioral;
