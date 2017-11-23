----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    simpleram - Behavioral 
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

entity simpleram is
	 generic (
		address_size: positive := 8;
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"00");
    Port (       
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end simpleram;

architecture Behavioral of simpleram is

type bytememory is array(0 to (2 ** address_size) - 1) of std_logic_vector(7 downto 0);
signal d_out: std_logic_vector(7 downto 0);
signal ram: bytememory := (others => default_value);

begin

D <= d_out when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";

internal_write: process(nSelect, nWrite, A, D)
begin
	if (nSelect = '0' and nWrite = '0') then
		ram(to_integer(unsigned(A))) <= D;
	end if;
end process;

internal_read: process(nSelect, nRead, A, ram)
begin
	if (nSelect = '0' and nRead = '0') then
		d_out <= ram(to_integer(unsigned(A)));
	end if;
end process;

end Behavioral;

