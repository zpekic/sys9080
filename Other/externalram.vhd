----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 09/29/2018 
-- Design Name: 
-- Module Name:    simpleram - Behavioral 
-- Project Name: 
-- Target Devices: https://www.renesas.com/us/en/doc/products/memory/rej03c0387_r1lv0816asb_ds.pdf
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

entity externalram is
    Port (       
				-- external SRAM
				SRAM_A: out std_logic_vector(18 downto 0);
				SRAM_D: inout std_logic_vector(15 downto 0);
				SRAM_CS1: out std_logic;
				SRAM_CS2: out std_logic;
				SRAM_OE: out std_logic;
				SRAM_WE: out std_logic;
				SRAM_UPPER_B: out std_logic;
				SRAM_LOWER_B: out std_logic;
				-- CPU bus
				clk: in STD_LOGIC;
				D : inout  STD_LOGIC_VECTOR (7 downto 0);
				A : in  STD_LOGIC_VECTOR (20 downto 0);
				nRead : in  STD_LOGIC;
				nWrite : in  STD_LOGIC;
				nSelect : in  STD_LOGIC);
end externalram;
  
architecture Behavioral of externalram is

signal d_out, d_in: std_logic_vector(7 downto 0);
signal nRD, nWR : std_logic;

begin

--setd_in: process(clk, D, nWR, nRD, A)
--begin
--	if (falling_edge(clk) and nWR = '0') then
--		if (nWR = '0') then
--			d_in <= D;--std_logic_vector(unsigned(d_in) + 1);
--		end if;
--		if (nRD = '0' and A(0) = '0') then
--			d_out <= SRAM_D(7 downto 0);
--		end if;
--		if (nRD = '0' and A(0) = '1') then
--			d_out <= SRAM_D(15 downto 8);
--		end if;
--	end if;
--end process;

nWR <= nSelect or nWrite;
nRD <= nSelect or nRead;

SRAM_OE <= nRD;
SRAM_WE <= nWR or clk;
SRAM_CS1 <= A(20) or nSelect;
SRAM_CS2 <= (not A(20)) or nSelect;
SRAM_LOWER_B <= A(0);
SRAM_UPPER_B <= not A(0);
SRAM_A(18 downto 0) <= A(19 downto 1);
SRAM_D(15 downto 8) <= D when (nWR = '0' and A(0) = '1') else "ZZZZZZZZ";
SRAM_D(7 downto 0)  <= D when (nWR = '0' and A(0) = '0') else "ZZZZZZZZ";
--SRAM_D(15 downto 8) <= D(7 downto 0) when (nWR = '0' and A(0) = '1') else "ZZZZZZZZ";
--SRAM_D(7 downto 0) <=  D(7 downto 0) when (nWR = '0' and A(0) = '0') else "ZZZZZZZZ";
d_out <= SRAM_D(15 downto 8) when (A(0) = '1') else SRAM_D(7 downto 0);
--d_out <= X"AA" when (A(0) = '1') else X"55";
D <= d_out when (nRD = '0') else "ZZZZZZZZ";

end Behavioral;

