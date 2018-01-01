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
		address_size: positive := 16;
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"FF");
    Port (       
			  clk: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end simpleram;

-- Using RAM from Xilinx IPCore library
--architecture structural of simpleram is
--
--component ram4kx8 IS
--  PORT (
--    clka : IN STD_LOGIC;
--    ena : IN STD_LOGIC;
--    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
--  );
--end component;
--
--signal d_out: std_logic_vector(7 downto 0);
--signal ena: std_logic;
--signal wr: std_logic_vector(0 downto 0);
--
--begin
--
--ena <= not nSelect;
--wr <= "" & not nWrite;
--D <= d_out when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";
--
--inner_ram: ram4kx8 port map
--	(
--    clka => clk,
--    ena => ena,
--    wea => wr,
--    addra => A,
--    dina => D,
--    douta => d_out
--  );
--  
--end structural;
  
-- Using standard abstract VHDL  
architecture Behavioral of simpleram is

type bytememory is array(0 to (2 ** address_size) - 1) of std_logic_vector(7 downto 0);
signal d_out: std_logic_vector(7 downto 0);
signal control: std_logic_vector(2 downto 0);

signal ram: bytememory := (others => default_value);
attribute ram_style: string;
attribute ram_style of ram: signal is "block";

begin

control <= nSelect & nRead & nWrite;
D <= d_out when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";

readwrite: process(clk, control, A, D, ram)
begin
	case control is
		when "010" => -- write 
			if (rising_edge(clk)) then
				ram(to_integer(unsigned(A))) <= D;
			end if;
		when "001" => -- read
			d_out <= ram(to_integer(unsigned(A)));
		when others =>
			null;
	end case;
end process;

end Behavioral;

