----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:58:22 10/22/2016 
-- Design Name: 
-- Module Name:    debouncer - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debouncer is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_in : in  STD_LOGIC;
           signal_out : out  STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is

signal debounced: std_logic := '0';
signal shifter: std_logic_vector(7 downto 0);
signal all0, all1: std_logic;

begin

--all0 <= '1' when shifter = "00000000" else '0';
--all1 <= '1' when shifter = "11111111" else '0';

-- all 1 or all 0 in shift register surely mean 1 or 0, but anything else keeps last state
--debounced <= (not all1 and not all0 and debounced) or 
--				 (not all1 and all0 and '0') or 
--				 (all1 and not all0 and '1') or 
--				 (all1 and all1 and debounced);
--signal_out <= debounced; 

signal_out <= '0' when (shifter = "00000000") else '1';

--debounce: process(clock, debounced)
--begin
--    if (rising_edge(clock)) then
--        if (all1 = '1') then
--            debounced <= '1'; 
--        else
--            if (all0 = '1') then
--                debounced <= '0';
--            else
--                debounced <= debounced;
--            end if;
--        end if;
--    end if;
--end process;

sample: process(clock, reset, signal_in)
begin
	if (reset = '1') then
		shifter <= (others => signal_in);
	else
		if (rising_edge(clock)) then
			shifter <= shifter(6 downto 0) & signal_in;
		end if;
	end if;
end process; 

end;

