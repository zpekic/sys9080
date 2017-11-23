----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:13:03 04/26/2010 
-- Design Name: 
-- Module Name:    q_reg - q_reg 
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
library IEEE;--,basic;
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

entity q_reg is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           f : in  std_logic_vector (3 downto 0);
           dest_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           qs0 : inout  STD_LOGIC;
           qs3 : inout  STD_LOGIC;
           q : out  std_logic_vector (3 downto 0));
end q_reg;

architecture q_reg of q_reg is

 component ureg is
        Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           d : in  std_logic_vector (3 downto 0);
           q : out  std_logic_vector (3 downto 0));
end component;

 signal q_en: std_logic;
 signal data: std_logic_vector(3 downto 0);
 


begin
 
  ---define q register:
  u1: ureg    port map (clk,rst,q_en,data,q);
		  
  ---- define q_en: 
  with dest_ctl select
      q_en <='1' when qreg|ramqd|ramqu,
             '0' when others;

  ----define data input to q register:
  
   with dest_ctl select
      data<=(f(2),f(1),f(0),qs0) when ramqu , --- shift up
            (qs3,f(3),f(2),f(1)) when ramqd, --- shift down
             f   when qreg,
            "----" when others;

  ----define qs0 and qs3 inouts: 

  qs3 <=f(3) when (dest_ctl = ramu or dest_ctl = ramqu) else 'Z';
  qs0 <=f(0) when (dest_ctl = ramd or dest_ctl = ramqd) else 'Z';  

end q_reg;

