----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    simpledevice - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Simple wrapper for parallel I/O ports and maybe more
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

entity simpledevice is
    Port ( clk: in std_logic;
			  reset: in std_logic;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR(3 downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
			  IntReq: buffer std_logic;
			  IntAck: in STD_LOGIC;
           direct_in : in  STD_LOGIC_VECTOR (15 downto 0);
           direct_out : out STD_LOGIC_VECTOR (15 downto 0));
end simpledevice;

architecture Behavioral of simpledevice is

signal d_out: std_logic_vector(7 downto 0);
signal readSelect, writeSelect: std_logic;

begin

readSelect <= nSelect nor nRead;
writeSelect <= nSelect nor nWrite;

D <= d_out when (readSelect = '1') else "ZZZZZZZZ";

with A select
	d_out <= direct_in(7 downto 0) when "0000", 
				direct_in(15 downto 8) when "0001", 
				X"FF" when others;

IntReq <= '0'; -- generate no interrupt for now

set_output: process(reset, clk, writeSelect, D, A)
begin
	if (reset = '1') then
		direct_out <= X"FFFF";
	else
		if (rising_edge(clk) and writeSelect = '1') then
			case A is
				when "0000" =>
					direct_out(7 downto 0) <= D;
				when "0001" => 
					direct_out(15 downto 8) <= D;
				when others =>
					null;
			end case;
		end if;
	end if;
end process;

end Behavioral;

