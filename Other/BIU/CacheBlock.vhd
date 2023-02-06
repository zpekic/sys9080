----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:08:39 11/05/2019 
-- Design Name: 
-- Module Name:    CacheBlock - Behavioral 
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

entity CacheBlock is
    Port ( clk : in  STD_LOGIC;
           we : in  STD_LOGIC;
			  wsel: in STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (15 downto 0);
           addr_a : in  STD_LOGIC_VECTOR (14 downto 0);
           addr_b : in  STD_LOGIC_VECTOR (14 downto 0);
           dout_a : out  STD_LOGIC_VECTOR (15 downto 0);
           dout_b : out  STD_LOGIC_VECTOR (15 downto 0);
           hit_a : out  STD_LOGIC;
           hit_b : out  STD_LOGIC);
end CacheBlock;

architecture Behavioral of CacheBlock is

type entry_array is array(0 to 2**(DEPTH) - 1) of std_logic_vector (31 downto 0);
signal entry: entry_array := (others => X"00000000");

signal entry_a: std_logic_vector(31 downto 0);
alias data_a: std_logic_vector(15 downto 0) is entry_a(15 downto 0);
alias tag_a: std_logic_vector(9 downto 0) is entry_a(25 downto 16);
alias valid_a: std_logic_vector is entry_a(31);
alias index_a: std_logic_vector(4 downto 0) is addr_a(4 downto 0);
 
signal entry_b: std_logic_vector(31 downto 0);
alias data_b: std_logic_vector(15 downto 0) is entry_a(15 downto 0);
alias tag_b: std_logic_vector(9 downto 0) is entry_a(25 downto 16);
alias valid_b: std_logic_vector is entry_a(31);
alias index_b: std_logic_vector(4 downto 0) is addr_b(4 downto 0);

begin

-- read A
entry_a <= entry(to_integer(unsigned(index_a))); 
hit_a <= valid_a when (tag_a = addr_a(14 downto 5)) else '0';
dout_a <= data_a;

-- read B
entry_b <= entry(to_integer(unsigned(index_b))); 
hit_b <= valid_b when (tag_b = addr_b(14 downto 5)) else '0';
dout_b <= data_b;

-- select write entry from A or B
entry_w <= addr_a when (wsel = '0') else addr_b; 

-- write using address 
write_b: process(clk, we)
begin
	if (rising_edge(clk) and we = "1") then
		entry(to_integer(unsigned(entry_w(4 downto 0)))) <= "100000" & entry_w(14 downto DEPTH) & din;
	end if;
end process;

end Behavioral;

