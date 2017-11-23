-----Set of registers (unsigned)
----- Sizes : (1,size)
-----

-----clk ---posedge clock input
-----reset -----asynchronous reset
-----load  -----active high input loads rregister
-----d     -----register input
-----q     -----register output


----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:52:23 04/26/2010 
-- Design Name: 
-- Module Name:    ureg - archureg 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ureg is
        Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           d : in  std_logic_vector (3 downto 0);
           q : out  std_logic_vector (3 downto 0));
end ureg;

architecture archureg of ureg is
signal q_temp: std_logic_vector(3 downto 0);
begin
 
  p1: process(reset,clk) 
       begin
		   if reset ='1' then 
			   q_temp<=(others =>'0');
			elsif (clk'event and clk='1') then
              if load='1' then 
                 q_temp<=d;
              else
                 q_temp<=q_temp;
              end if;
         end if;
    end process;			
q <= q_temp;
end archureg;

