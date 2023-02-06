------------------------------------------------------------------------
--     seven_seg_controller.vhd -- a 7-seg display controller
------------------------------------------------------------------------
-- Author:  Cong He
--          Copyright 2012 Digilent, Inc.
------------------------------------------------------------------------
-- This module tests basic device function and connectivity on the Pegasus
-- board. It was developed using the Xilinx WebPack tools.
--
--  Inputs:
--		rst		- resets disply
--		cclk		- controls anos
--		dispEN	- enables the seven seg display
--    dpSel    - dot point of 7-seg display
--		cntr1-4  - 4 counters each representing a single digit on the display
--
--  Outputs:
--		an		   - anode lines for the 7-seg displays on Nexys3
--		seg		- cathodes (segment lines) for the displays on Nexys3
--
------------------------------------------------------------------------
-- Revision History:
--  3/30/2012(HC): Created
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity seven_seg_controller is
    Port ( dispEN : in STD_LOGIC;
			  segdata : in STD_LOGIC_VECTOR(3 downto 0);
			  segselect : in STD_LOGIC_VECTOR(2 downto 0);
			  seg : out STD_LOGIC_VECTOR(7 downto 0);
			  an : out STD_LOGIC_VECTOR(5 downto 0));
end seven_seg_controller;

architecture Behavioral of seven_seg_controller is

	begin
					 
		with segdata select
		seg(6 downto 0) <= "1000000" when "0000",   --0
				 "1111001" when "0001",   --1
				 "0100100" when "0010",   --2
				 "0110000" when "0011",   --3
				 "0011001" when "0100",   --4
				 "0010010" when "0101",   --5
				 "0000010" when "0110",   --6
				 "1111000" when "0111",   --7
				 "0000000" when "1000",   --8
				 "0010000" when "1001",   --9
				 "0001000" when "1010",   --A
				 "0000011" when "1011",   --b
				 "1000110" when "1100",   --C
				 "0100001" when "1101",   --d
				 "0000110" when "1110",   --E
				 "0001110" when "1111",   --F
				 "0111111" when others;
				
		an <= "111110" when segselect(2 downto 0) = "000" and dispEN = '1' else
				"111101" when segselect(2 downto 0) = "001" and dispEN = '1' else
				"111011" when segselect(2 downto 0) = "010" and dispEN = '1' else
				"110111" when segselect(2 downto 0) = "011" and dispEN = '1' else
            "101111" when segselect(2 downto 0) = "100" and dispEN = '1' else
            "011111" when segselect(2 downto 0) = "101" and dispEN = '1' else				
				"111111";
				
		seg(7) <= '1';  -- dot point of 7-seg display


	end Behavioral;

