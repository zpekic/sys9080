----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/24/2017 09:28:27 AM
-- Design Name: 
-- Module Name: Am82S62 - Behavioral
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

entity Am82S62 is
    Port ( p : in STD_LOGIC_VECTOR (8 downto 0);
           inhibit : in STD_LOGIC;
           even : out STD_LOGIC;
           odd : out STD_LOGIC);
end Am82S62;

architecture Behavioral of Am82S62 is

signal odd_internal: std_logic;

begin

odd_internal <= p(0) xor p(1) xor p(2) xor p(3) xor p(4) xor p(5) xor p(6) xor p(7) xor p(8);
even <= '0' when (inhibit = '1') else not odd_internal;
odd <= '0' when (inhibit = '1') else odd_internal;

end Behavioral;
