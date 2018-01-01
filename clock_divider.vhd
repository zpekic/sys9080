----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    16:56:54 02/13/2016 
-- Design Name: 
-- Module Name:    clock_divider - rtl 
-- Project Name:   Alarm Clock
-- Target Devices: Mercury FPGA + Baseboard (http://www.micro-nova.com/mercury/)
-- Tool versions:  Xilinx ISE 14.7 (nt64)
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_divider is
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           slow : out  STD_LOGIC_VECTOR (11 downto 0);
			  fast : out STD_LOGIC_VECTOR(3 downto 0)
			 );
end clock_divider;

architecture rtl of clock_divider is
	constant max_count: integer := (100000000 / 4096); -- prescale 
	signal count: integer range 0 to max_count := 0; 
	signal slow_cnt: unsigned(11 downto 0);
	signal fast_cnt: unsigned(3 downto 0);
	
begin
		
	divider: process(clock, reset)
		begin
		if reset = '1' then
			count <= 0;
			slow_cnt <= "000000000000";
			fast_cnt <= "0000";
		else
			if rising_edge(clock) then
				fast_cnt <= fast_cnt + 1;
				if count = max_count then
					count <= 0;
					slow_cnt <= slow_cnt + 1;
				else
					count <= count + 1;
				end if;
			end if;
		end if;
	end process;
   -- connect divider output with internal counter
	slow <= std_logic_vector(slow_cnt);
	fast <= std_logic_vector(fast_cnt);
end rtl;

