----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:41:24 10/31/2018 
-- Design Name: 
-- Module Name:    delaygen - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity delaygen is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           duration : in  STD_LOGIC_VECTOR (2 downto 0);
           nActive : in  STD_LOGIC;
           ready : out  STD_LOGIC);
end delaygen;

architecture Behavioral of delaygen is

signal delay: std_logic_vector(7 downto 0);
signal tap, clearDelayLine: std_logic;

begin

clearDelayLine <= reset or nActive;
ready <= '1' when clearDelayLine = '1' else tap;

delayline: process(reset, clk, clearDelayLine)
begin
	if (clearDelayLine = '1') then
		delay <= "00000000";
	else
		if (rising_edge(clk)) then
			delay <= delay(6 downto 0) & (not nActive);
		end if;
	end if;
end process;
	
with (duration) select
	tap <= 	'1' when 		"000",	-- no delay always ready
				delay(1) when 	"001", -- 1 clock
				delay(2) when 	"010", 
				delay(3) when 	"011", 
				delay(4) when 	"100", 
				delay(5) when 	"101", 
				delay(6) when 	"110",  
				delay(7) when 	"111";  -- 7 clocks
					
end Behavioral;

