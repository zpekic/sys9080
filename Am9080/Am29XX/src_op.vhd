----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:00:06 04/26/2010 
-- Design Name: 
-- Module Name:    src_op - src_op 
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
use WORK.MNEMONICS.ALL;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity src_op is
    Port ( d : in  std_logic_vector (3 downto 0);
           ad : in  std_logic_vector (3 downto 0);
           bd : in  std_logic_vector (3 downto 0);
           q : in  std_logic_vector (3 downto 0);
           src_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           r : buffer  std_logic_vector (3 downto 0);
           s : buffer  std_logic_vector (3 downto 0));
end src_op;

architecture src_op of src_op is

begin
 ---decode alu operand r:
 
 with src_ctl select
    r<= ad when aq |ab,
	     "0000" when zq|zb|za,
		  d when others;
		  
 with src_ctl select
    s<=q when aq|zq|dq,
       bd when  ab|zb,
       ad when za|da,
       "0000" when others;		 

end src_op;

