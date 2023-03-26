----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    15:42:44 02/20/2016 
-- Design Name: 
-- Module Name:    fourdigitsevensegled - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fourdigitsevensegled is
    Port ( -- inputs
			  data : in  STD_LOGIC_VECTOR (15 downto 0);
           digsel : in  STD_LOGIC_VECTOR (1 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (3 downto 0);
           showdot : in  STD_LOGIC_VECTOR (3 downto 0);
			  showsegments: in STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (3 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end fourdigitsevensegled;

architecture structural of fourdigitsevensegled is

--component seven_seg_controller is
--    Port ( dispEN : in STD_LOGIC;
--			  segdata : in STD_LOGIC_VECTOR(3 downto 0);
--			  segselect : in STD_LOGIC_VECTOR(2 downto 0);
--			  seg : out STD_LOGIC_VECTOR(7 downto 0);
--			  an : out STD_LOGIC_VECTOR(5 downto 0));
--end component;

signal internalseg: std_logic_vector(6 downto 0); -- 7th is the dot!
signal dot: std_logic;
signal displaybus: std_logic_vector(7 downto 0);
alias hexdata: std_logic_vector(3 downto 0) is displaybus(3 downto 0);

begin

anode <= displaybus(7 downto 4);

---- DP for each digit individually
	with digsel select dot <= 
		not showdot(0) when "00",
		not showdot(1) when "01",
		not showdot(2) when "10",
		not showdot(3) when others;

---- decode position and select 1 of 4 hex digits
	with digsel select displaybus <= 	
		("111" & not showdigit(0)) 		& data(3 downto 0) when "00",
		("11" & not showdigit(1) & "1")  & data(7 downto 4) when "01",
		("1" & not showdigit(2) & "11")  & data(11 downto 8) when "10",
		(not showdigit(3) & "111")			& data(15 downto 12) when others;
					
---- hook up the cathodes
	with hexdata select internalseg <= 
		 "0000001" when "0000",   --0
		 "1001111" when "0001",   --1
		 "0010010" when "0010",   --2
		 "0000110" when "0011",   --3
		 "1001100" when "0100",   --4
		 "0100100" when "0101",   --5
		 "0100000" when "0110",   --6
		 "0001111" when "0111",   --7
		 "0000000" when "1000",   --8
		 "0000100" when "1001",   --9
		 "0001000" when "1010",   --A
		 "1100000" when "1011",   --b
		 "0110001" when "1100",   --C
		 "1000010" when "1101",   --d
		 "0110000" when "1110",   --E
		 "0111000" when "1111",   --F
		 "0000000" when others;

-- display or not
	segment <= dot & internalseg when (showsegments = '1') else X"FF";

end structural;

