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

entity simpledevice is
    Port ( D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR (3 downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
           direct_in : in  STD_LOGIC_VECTOR (15 downto 0);
           direct_out : out STD_LOGIC_VECTOR (15 downto 0));
end simpledevice;

architecture Behavioral of simpledevice is

type memory16x8 is array(0 to 15) of std_logic_vector(7 downto 0);
signal ports: memory16x8 := (
	others => X"FF"
);
signal d_out: std_logic_vector(7 downto 0);

begin

D <= d_out when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";

internal_write: process(nSelect, nWrite, A, D)
begin
	if (nSelect = '0' and nWrite = '0') then
		case A is
			when X"0" =>
				direct_out(7 downto 0) <= D;
			when X"1" =>
				direct_out(15 downto 8) <= D;
			when others =>
				ports(to_integer(unsigned(A))) <= D;
		end case;
	end if;
end process;

internal_read: process(nSelect, nRead, A, direct_in, ports)
begin
	if (nSelect = '0' and nRead = '0') then
		case A is
			when X"0" =>
				d_out <= direct_in(7 downto 0);
			when X"1" =>
				d_out <= direct_in(15 downto 8);
			when others =>
				d_out <= ports(to_integer(unsigned(A)));
		end case;
	end if;
end process;

end Behavioral;

