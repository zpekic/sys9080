----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/20/2017 10:32:16 PM
-- Design Name: 
-- Module Name: Am2922 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Am2922 is
    Port ( clk : in STD_LOGIC;
           a : in STD_LOGIC;
           b : in STD_LOGIC;
           c : in STD_LOGIC;
           pol : in STD_LOGIC;
           nME : in STD_LOGIC;
           nRE : in STD_LOGIC;
           nCLR : in STD_LOGIC;
           nOE : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (7 downto 0);
           y : out STD_LOGIC);
end Am2922;

architecture Behavioral of Am2922 is

signal mux, muxen: std_logic;
signal q: std_logic_vector(3 downto 0) := "0000";

begin

y <= ((not q(3)) xor mux) when (nOE = '0') else 'Z';
with nME & q(2 downto 0) select
	mux <= 	d(0) when "0000",
				d(1) when "0001",
				d(2) when "0010",
				d(3) when "0011",
				d(4) when "0100",
				d(5) when "0101",
				d(6) when "0110",
				d(7) when "0111",
				'0' when others;
--mux <= (not nME) and d(to_integer(unsigned(q)));				

on_clk: process(clk, a, b, c, pol, nCLR, nRE)
begin
    if (nCLR = '0') then
        q <= (others => '0');
    else
        if (rising_edge(clk) and (nRE = '0')) then
            q <= pol & c & b & a;
        end if;   
    end if;
end process;

end Behavioral;
