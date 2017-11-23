----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/24/2017 01:49:44 PM
-- Design Name: 
-- Module Name: rom32x8 - Behavioral
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

entity rom32x8 is
    Port ( nCS : in STD_LOGIC;
           address : in STD_LOGIC_VECTOR (3 downto 0);
           data : out STD_LOGIC_VECTOR (4 downto 0));
end rom32x8;

architecture Behavioral of rom32x8 is

signal data_int: std_logic_vector(4 downto 0);

begin

sequence: process(address)
begin
    case address is
        when "0000" =>
            data_int <= "01000"; -- C
        when "0001" =>
            data_int <= "01001"; -- R
        when "0010" =>
            data_int <= "01011"; -- D
        when "0011" =>
            data_int <= "01001"; -- R
        when "0100" =>
            data_int <= "01000"; -- C
        when "0101" =>
            data_int <= "00101"; -- SBR
        when "0110" =>
            data_int <= "01001"; -- R
        when "0111" =>
            data_int <= "00010"; -- RTN
        when "1000" =>
            data_int <= "11010"; -- F
        when "1001" =>
            data_int <= "00101"; -- SBR
        when "1010" =>
            data_int <= "00000"; -- POP
        when "1011" =>
            data_int <= "00001"; -- PR
        when "1100" =>
            data_int <= "01001"; -- R
        when "1101" =>
            data_int <= "00100"; -- PUSH
        when "1110" =>
            data_int <= "01001"; -- R
        when "1111" =>
            data_int <= "11010"; -- F
        when others =>
            data_int <= "11111";
    end case;
end process;

data <= data_int when (nCS = '0') else "ZZZZZ";

end Behavioral;
