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

entity sixdigitsevensegled is
    Port ( -- inputs
			  data : in  STD_LOGIC_VECTOR (23 downto 0);
           digsel : in  STD_LOGIC_VECTOR (2 downto 0);
           showdigit : in  STD_LOGIC_VECTOR (5 downto 0);
           showdot : in  STD_LOGIC_VECTOR (5 downto 0);
           showsegments : in  STD_LOGIC;
			  -- outputs
           anode : out  STD_LOGIC_VECTOR (5 downto 0);
           segment : out  STD_LOGIC_VECTOR (7 downto 0)
			 );
end sixdigitsevensegled;

architecture structural of sixdigitsevensegled is

component seven_seg_controller is
    Port ( dispEN : in STD_LOGIC;
			  segdata : in STD_LOGIC_VECTOR(3 downto 0);
			  segselect : in STD_LOGIC_VECTOR(2 downto 0);
			  seg : out STD_LOGIC_VECTOR(7 downto 0);
			  an : out STD_LOGIC_VECTOR(5 downto 0));
end component;

signal internalseg: std_logic_vector(7 downto 0); -- 7th is the dot!
signal internalan: std_logic_vector(5 downto 0);
signal digit: std_logic_vector(3 downto 0);

begin
---- DP for each digit individually
	with digsel select
		internalseg(7) <= 
							 showdot(0) when "000",
							 showdot(1) when "001",
							 showdot(2) when "010",
							 showdot(3) when "011",
							 showdot(4) when "100",
							 showdot(5) when "101",
							'0' when others;
---- decode position
	with digsel select
		internalan <= "000010" when "000",
							"000001" when "001",
							"001000" when "010",
							"000100" when "011",
							"100000" when "100",
							"010000" when "101",
							"000000" when others;
-- select 1 digit out of 6 incoming	
	with digsel select
		digit <= data(3 downto 0) when "000",
					data(7 downto 4) when "001",
					data(11 downto 8) when "010",
					data(15 downto 12) when "011",
					data(19 downto 16) when "100",
					data(23 downto 20) when "101",
					"0000" when others;
					
--	controller: seven_seg_controller port map (
--		dispEN => showsegments,
--		segdata => digit,
--		segselect => digsel,
--		seg => segment,
--		an => anode
--	);
	--anode <= "111101";
	--segment <= "01010101";
-- set the anodes with digit blanking
	anodes: for i in 5 downto 0 generate
		anode(i) <= internalan(i) and showdigit(i);
	end generate;
--	anode <= internalsel;
---- hook up the cathodes
		with digit select
		internalseg(6 downto 0) <= 
				 "0111111" when "0000",   --0
				 "0000110" when "0001",   --1
				 "1011011" when "0010",   --2
				 "1001111" when "0011",   --3
				 "1100110" when "0100",   --4
				 "1101101" when "0101",   --5
				 "1111101" when "0110",   --6
				 "0000111" when "0111",   --7
				 "1111111" when "1000",   --8
				 "1101111" when "1001",   --9
				 "1110111" when "1010",   --A
				 "1111100" when "1011",   --b
				 "0111001" when "1100",   --C
				 "1011110" when "1101",   --d
				 "1111001" when "1110",   --E
				 "1110001" when "1111",   --F
				 "0000000" when others;
---- set cathodes with blanking (seg7 == dot)
	segment <= internalseg when showsegments = '1' else "00000000";
----	segs: for i in 7 downto 0 generate
----		segment(i) <= showsegments and (not internalsegment(i));
----	end generate;	

end structural;

