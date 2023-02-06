----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:08:56 03/24/2019 
-- Design Name: 
-- Module Name:    traceunit - Behavioral 
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
--use work.tms0800_package.all;

entity traceunit is
    Port ( reset : in  STD_LOGIC;
			  clk: in STD_LOGIC;
			  enable : in STD_LOGIC;
			  char: in STD_LOGIC_VECTOR(7 downto 0);
           char_sent : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end traceunit;

architecture Behavioral of traceunit is

signal bitSel: std_logic_vector(3 downto 0);

begin

-- drive simple UART data output with mux
with bitSel select 
		txd <= 		'1'		 when "0000", -- delay 0
						'1'		 when "0001",
						'1'		 when "0010",
						'1' 		 when "0011", -- delay 3
						'0' 		 when "0100", -- start bit
						char(0) when "0101", -- data
						char(1) when "0110",
						char(2) when "0111",
						char(3) when "1000",
						char(4) when "1001",
						char(5) when "1010",
						char(6) when "1011",
						char(7) when "1100",
						'1' 		 when "1101",	-- stop
						'1' 		 when "1110",	-- additional stop or parity
						'1' when others;			-- delay

-- drive high when all bits transmitted, this signal is fed as a condition to microcode	
char_sent <= '1' when bitSel(3 downto 1) = "111" else '0'; 					

-- when char goes to non-zero, char is being sent to txd, until hits last 2 bitSel values
drivebitSel: process(reset, bitsel, clk, char, enable)
begin
	if (char = X"00" or reset = '1' or enable = '0') then
		bitSel <= X"0";
	else
		if (rising_edge(clk) and bitSel /= X"F") then
			bitSel <= std_logic_vector(unsigned(bitSel) + 1);
		end if;
	end if;
end process;

end Behavioral;

