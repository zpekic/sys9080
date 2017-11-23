----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2017 11:51:21 PM
-- Design Name: 
-- Module Name: Am25139 - Behavioral
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

entity Am25139 is
    Port ( nG1 : in STD_LOGIC;
           B1 : in STD_LOGIC;
           A1 : in STD_LOGIC;
           nY1 : out STD_LOGIC_VECTOR (3 downto 0);
           nG2 : in STD_LOGIC;
           B2 : in STD_LOGIC;
           A2 : in STD_LOGIC;
           nY2 : out STD_LOGIC_VECTOR (3 downto 0));
end Am25139;

architecture Behavioral of Am25139 is

signal sel1, sel2: std_logic_vector(1 downto 0);

begin

sel1 <= B1 & A1;
sel2 <= B2 & A2;

decoder1: process(nG1, sel1)
begin
    if (nG1 = '0') then
        case sel1 is
            when "00" =>
                nY1 <= "1110"; -- 0
            when "01" =>
                nY1 <= "1101"; -- 1
            when "10" =>
                nY1 <= "1011"; -- 2
            when "11" =>
                nY1 <= "0111"; -- 3
            when others =>
					null;
        end case;
    else
        nY1 <= "1111";
    end if;
end process;

decoder2: process(nG2, sel2)
begin
    if (nG2 = '0') then
        case sel2 is
            when "00" =>
                nY2 <= "1110"; -- 0
            when "01" =>
                nY2 <= "1101"; -- 1
            when "10" =>
                nY2 <= "1011"; -- 2
            when "11" =>
                nY2 <= "0111"; -- 3
            when others =>
					null;
        end case;
    else
        nY2 <= "1111";
    end if;
end process;

end Behavioral;
