----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/24/2017 10:11:13 AM
-- Design Name: 
-- Module Name: Am25LS157 - Behavioral
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

entity Am25LS157 is
    Port ( a : in STD_LOGIC_VECTOR (3 downto 0);
           b : in STD_LOGIC_VECTOR (3 downto 0);
           s : in STD_LOGIC;
           nG : in STD_LOGIC;
           y : out STD_LOGIC_VECTOR (3 downto 0));
end Am25LS157;

architecture Behavioral of Am25LS157 is

signal y_internal: std_logic_vector(3 downto 0);

begin
	
y_internal <= a when (s = '0') else b;
y <= y_internal when (nG = '0') else "0000";

end Behavioral;
