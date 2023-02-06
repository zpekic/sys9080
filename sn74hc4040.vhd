----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:25:04 08/29/2020 
-- Design Name: 
-- Module Name:    sn74hc4040 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: https://www.futurlec.com/74HC/74HC4040.shtml
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sn74hc4040 is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           q : out  STD_LOGIC_VECTOR(11 downto 0));
end sn74hc4040;

architecture Behavioral of sn74hc4040 is

signal cnt: integer range 0 to 4095;

begin

-- logic (not quite correct as this is sync, not ripple)
count: process(clock, reset, cnt)
begin
	if (reset = '1') then
		cnt <= 0;
	else
		if (falling_edge(clock)) then
			cnt <= cnt + 1;
		end if;
	end if;
end process;

-- mapping
q <= std_logic_vector(to_unsigned(cnt, 12));

end Behavioral;

