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
use IEEE.NUMERIC_STD.ALL;

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

type rom is array(0 to 15) of std_logic_vector(4 downto 0);
constant lookup: rom := (
            "01000", -- C
            "01001", -- R
            "01011", -- D
            "01001", -- R
            "01000", -- C
            "00101", -- SBR
            "01001", -- R
            "00010", -- RTN
            "11010", -- F
            "00101", -- SBR
            "00000", -- POP
            "00001", -- PR
            "01001", -- R
            "00100", -- PUSH
            "01001", -- R
            "11010"  -- F
				);

begin

	data <= lookup(to_integer(unsigned(address))) when (nCS = '0') else "ZZZZZ";

end Behavioral;
