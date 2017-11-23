----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:11:54 04/26/2010 
-- Design Name: 
-- Module Name:    alu - alu 
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
use work.mnemonics.all;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity alu is
    Port ( r : in  STD_LOGIC_VECTOR (3 downto 0);
           s : in  STD_LOGIC_VECTOR (3 downto 0);
           c_n : in  STD_LOGIC;
           alu_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           f : out  STD_LOGIC_VECTOR (3 downto 0);
           g_bar : out  STD_LOGIC;
           p_bar : out  STD_LOGIC;
           c_n4 : out  STD_LOGIC;
           ovr : out  STD_LOGIC);
end alu;

architecture alu of alu is
   signal r1, s1, nr1, ns1, f1: STD_LOGIC_VECTOR (4 downto 0);
begin
   
	 r1<=('0',r(3),r(2),r(1),r(0));
	 s1<=('0',s(3),s(2),s(1),s(0));
	 nr1<=('0',not r(3),not r(2),not r(1),not r(0));
	 ns1<=('0',not s(3),not s(2),not s(1),not s(0));
	 
 alu: process (r1,s1,c_n,alu_ctl)

    begin
      case alu_ctl is 
       when add =>
         if c_n ='0' then
           f1<=r1+s1;
         else
           f1<=r1+s1+1;
         end if;
       when subr => ---subtraction same as 2's comp addn
          if c_n='0' then
             f1<=s1 + nr1;		-- $BUGBUG: in original file SUBS and SUBR are reversed, fixed here
          else
             f1<=s1 + nr1 + 1;
          end if;
      when subs =>
         if c_n='0' then
           f1<=r1 + ns1 + 1;
         else 
           f1<=r1 + ns1; -- $BUGBUG: in original file, not() was missing, fixed here
         end if;

      when orrs=> f1 <=r1 or s1;
      when andrs=> f1<= r1 and s1;
      when notrs=> f1 <= (not r1) and s1;
      when exor=> f1 <= r1 xor s1;
      when exnor=> f1 <= not(r1 xor s1);
      when others=> f1<="-----";
 end case;
end process;

f<=f1(3 downto 0);
c_n4<=f1(4);

g_bar<=not(
   (r(3) and s(3)) or
    ((r(3) or s(3)) and (r(2) and s(2))) or
	 ((r(3) or s(3)) and (r(2) or s(2)) and (r(1) and s(1))) or
    ((r(3) or s(3)) and (r(2) or s(2)) and (r(1) or s(1)) and
    (r(0) and s(0))));
p_bar<=not(
    (r(3) or s(3)) and (r(2) or s(2)) and (r(1) and s(1)) and
    (r(0) and s(0)));

ovr<='1' when (f1(4) /= f1(3)) else '0';	 
        		 

end alu;

