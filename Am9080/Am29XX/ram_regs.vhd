----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:16:34 04/08/2010 
-- Design Name: 
-- Module Name:    ram_regs - ram_regs 
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
library IEEE;--, basic;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.mnemonics.all;
--use basic.regs_pkg.all;
---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram_regs is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           a : in  std_logic_vector (3 downto 0);
           b : in  std_logic_vector (3 downto 0);
			  f : in std_logic_vector (3 downto 0);
           dest_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           ram0 : inout  STD_LOGIC;
           ram3 : inout  STD_LOGIC;
           ad : buffer  std_logic_vector (3 downto 0);
           bd : buffer  std_logic_vector (3 downto 0));
end ram_regs;

architecture ram_regs of ram_regs is
 

 component ureg is
        Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           d : in  std_logic_vector (3 downto 0);
           q : out  std_logic_vector (3 downto 0));
end component;
  
  
  
  
  
  
  
  
  signal ram_en: std_logic;
  signal data: std_logic_vector (3 downto 0);
  signal en : std_logic_vector(15 downto 0);
  type ram_array is array(15 downto 0) of std_logic_vector (3 downto 0);
  signal ab_data: ram_array;
     
begin
   
	 --define register array:
	 
  gen : for i in 15 downto 0 generate
          ram : ureg 
                port map(clk,rst,en(i),data,ab_data(i));
          end generate;

   ---decode b to determine which register is enabled:

  with dest_ctl select
        ram_en <='0' when qreg |nop,
                 '1' when others;
   
  	decode_b: process(b, ram_en) 
	       begin
			   for i in 0 to 15 loop
				   if CONV_INTEGER(b) = i then en(i) <= ram_en;
				       else en(i) <='0';
					end if;
            end loop;
         end process;

 ----define data input to register array:

  with dest_ctl select
      data<=(f(2),f(1),f(0),ram0) when ramqu|ramu , --shift up
		    (ram3,f(3),f(2),f(1)) when ramqd| ramd , --shift down
			 f when rama|ramf,
			 "----" when others;
			 
	--define reg_array output for a and b regs:

  ad<= ab_data(CONV_INTEGER(a));  --- to_integer defined in
  bd<= ab_data(CONV_INTEGER(b));  --- numeric_std (See Chapter 7)

  ----define ram0 and ram3 inouts:
    ram3 <= f(3) when (dest_ctl = ramu or dest_ctl = ramqu ) else 'Z';
    ram0 <= f(0) when (dest_ctl = ramd or dest_ctl = ramqd) else 'Z';	 
		


end ram_regs;

