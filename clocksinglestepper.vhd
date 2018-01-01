----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2017 10:55:47 PM
-- Design Name: 
-- Module Name: clocksinglestepper - Behavioral
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

entity clocksinglestepper is
    Port ( reset : in STD_LOGIC;
           clock0_in : in STD_LOGIC;
           clock1_in : in STD_LOGIC;
			  clock2_in : in STD_LOGIC;
			  clock3_in : in STD_LOGIC;
           clocksel : in STD_LOGIC_VECTOR(1 downto 0);
           modesel : in STD_LOGIC;
           singlestep : in STD_LOGIC;
           clock_out : out STD_LOGIC);
end clocksinglestepper;

architecture Behavioral of clocksinglestepper is

signal clock_in, clock_disable, clock_ss: std_logic;

begin

clock_in <= clock0_in when (clocksel = "00") else
				clock1_in when (clocksel = "01") else
				clock2_in when (clocksel = "10") else
				clock3_in when (clocksel = "11") else
				'0';
clock_out <= clock_in or clock_disable;
clock_ss <= clock_in when (clock_disable = '0') else singlestep;

ss: process(reset, clock_ss, modesel)
begin
    if (reset = '1') then
        clock_disable <= modesel;
    else
        if (rising_edge(clock_ss)) then
            clock_disable <= (not clock_disable and modesel);
        end if;
    end if;
end process;

end Behavioral;
