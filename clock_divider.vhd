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
	 generic (CLK_FREQ: integer);
    Port ( reset : in  STD_LOGIC;
           clock : in  STD_LOGIC;
           slow : out  STD_LOGIC_VECTOR (11 downto 0);
			  baud : out STD_LOGIC_VECTOR(7 downto 0);
			  fast : out STD_LOGIC_VECTOR(6 downto 0)
			 );
end clock_divider;

architecture rtl of clock_divider is
	constant max_slowcount: integer := (CLK_FREQ / (2 * 2048)); -- prescale to generate "even" frequencies
	constant max_baudcount: integer := (CLK_FREQ / (2 * 38400)); -- prescale to generate "baudrate" frequencies
	--constant max_baudcount: integer := (CLK_FREQ / (2 * 57600));
	signal scount: integer range 0 to max_slowcount := 0; 
	signal bcount: integer range 0 to max_baudcount := 0; 
	signal slow_cnt: unsigned(11 downto 0);
	signal fast_cnt: unsigned(6 downto 0);
	signal baud_cnt: unsigned(7 downto 0);
	
begin
		
	divider: process(clock, reset)
		begin
		if reset = '1' then
			scount <= 0;
			bcount <= 0;
			slow_cnt <= X"000";
			baud_cnt <= X"00";
			fast_cnt <= "0000000";
		else
			if rising_edge(clock) then
				fast_cnt <= fast_cnt + 1;
				if scount = max_slowcount then
					scount <= 0;
					slow_cnt <= slow_cnt + 1;
				else
					scount <= scount + 1;
				end if;
				if bcount = max_baudcount then
					bcount <= 0;
					baud_cnt <= baud_cnt + 1;
				else
					bcount <= bcount + 1;
				end if;
			end if;
		end if;
	end process;
	
   -- connect divider outputs with internal counters
	slow <= std_logic_vector(slow_cnt);
	fast <= std_logic_vector(fast_cnt);
	baud <= std_logic_vector(baud_cnt);
end rtl;

