----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:12:29 02/11/2023 
-- Design Name: 
-- Module Name:    byteport - Behavioral 
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

entity byteport is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           nCS : in  STD_LOGIC;
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
           i : in  STD_LOGIC_VECTOR (7 downto 0);
           o : out  STD_LOGIC_VECTOR (7 downto 0));
end byteport;

architecture Behavioral of byteport is

signal int_read, int_write: std_logic;

begin

-- enable signals
int_read <= not (nCS or nRead);
int_write <= not (nCS or nWrite);

-- input is a snapshot
D <= i when (int_read = '1') else "ZZZZZZZZ";

-- output is a register
on_clk: process(clk, reset, D, int_write)
begin
	if (reset = '1') then
		o <= (others => '0'); 
	else
		if (rising_edge(clk) and (int_write = '1')) then
			o <= D;
		end if;
	end if;
end process;


end Behavioral;

