----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/24/2017 10:11:13 AM
-- Design Name: 
-- Module Name: Am25LS153 - Behavioral
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

entity Am25LS153 is
    Port ( sel : in STD_LOGIC_VECTOR (1 downto 0);
           n1G : in STD_LOGIC;
           n2G : in STD_LOGIC;
           in1 : in STD_LOGIC_VECTOR (3 downto 0);
           in2 : in STD_LOGIC_VECTOR (3 downto 0);
           out1 : out STD_LOGIC;
           out2 : out STD_LOGIC);
end Am25LS153;

architecture Behavioral of Am25LS153 is

signal y1, y2: std_logic;

begin

selection: process(sel, in1, in2)
begin
    case sel is
        when "00" =>
            y1 <= in1(0); 
            y2 <= in2(0); 
        when "01" =>
            y1 <= in1(1); 
            y2 <= in2(1); 
        when "10" =>
            y1 <= in1(2); 
            y2 <= in2(2); 
        when "11" =>
            y1 <= in1(3); 
            y2 <= in2(3); 
        when others =>
            null;
    end case;
end process;

out1 <= y1 when (n1G = '0') else '0';
out2 <= y2 when (n2G = '0') else '0';

end Behavioral;
