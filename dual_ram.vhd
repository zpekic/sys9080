----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:28:42 11/17/2018 
-- Design Name: 
-- Module Name:    dual_ram - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dual_ram is
    Port ( d_in : in  STD_LOGIC_VECTOR (7 downto 0);
           a_write : in  STD_LOGIC_VECTOR (6 downto 0);
           a_read : in  STD_LOGIC_VECTOR (6 downto 0);
           bankselect : in  STD_LOGIC;
           nWE : in  STD_LOGIC;
           d_out : out  STD_LOGIC_VECTOR (7 downto 0));
end dual_ram;

architecture Behavioral of dual_ram is

type bank is array (0 to 63) of std_logic_vector(7 downto 0);

signal bank_a: bank;
signal bank_b: bank;

begin
------------------------------
-- bankselect	bank_a	bank_b
--				0	READ		WRITE
--				1	WRITE		READ
------------------------------
write_bank: process(bankselect, nWE)
begin
	if (rising_edge(nWE)) then
		if (bankselect = '0') then
			bank_b(to_integer(unsigned(a_write))) <= d_in;
		end if;
		if (bankselect = '1') then
			bank_a(to_integer(unsigned(a_write))) <= d_in;
		end if;
	end if;
end process;

d_out <= bank_a(to_integer(unsigned(a_read))) when (bankselect = '0') else 
			bank_b(to_integer(unsigned(a_read)));

end Behavioral;

