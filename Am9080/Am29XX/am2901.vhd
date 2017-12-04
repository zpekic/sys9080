----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:59:18 04/26/2010 
-- Design Name: 
-- Module Name:    am2901 - am2901 
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
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.am2901_comps.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity am2901 is
    Port ( clk : in  STD_LOGIC; 
           rst : in  STD_LOGIC;
           a : in  std_logic_vector (3 downto 0);----address  inputs
           b : in  STD_LOGIC_VECTOR (3 downto 0);----address inputs
           d : in  STD_LOGIC_VECTOR (3 downto 0);----direct data
           i : in  STD_LOGIC_VECTOR (8 downto 0);---micro instruction
           c_n : in  STD_LOGIC;---------------------carry in
           oe : in  STD_LOGIC;----------------------output enable
           ram0 : inout  STD_LOGIC;-----------------shift lines to ram
           ram3 : inout  STD_LOGIC;-----------------shift lines to ram
           qs0 : inout  STD_LOGIC;------------------shift lines to q
           qs3 : inout  STD_LOGIC;------------------shift lines to q
           y : inout  STD_LOGIC_VECTOR (3 downto 0);-------data outputs(3-state)
           g_bar : out  STD_LOGIC;---------------carry generate
           p_bar : out  STD_LOGIC;---------------carry propagate
           ovr : out  STD_LOGIC;-----------------overflow
           c_n4 : out  STD_LOGIC;----------------carry out
           f_0 : out  STD_LOGIC;-----------------f = 0
           f3 : out  STD_LOGIC);-----------------f(3) w/o 3-state
end am2901;

architecture am2901 of am2901 is 
 
 alias dest_ctl: std_logic_vector(2 downto 0) is i(8 downto 6);
 alias alu_ctl : std_logic_vector(2 downto 0) is i(5 downto 3);
 alias src_ctl : std_logic_vector(2 downto 0) is i(2 downto 0);
 
 signal ad,bd: STD_LOGIC_VECTOR (3 downto 0);
 signal q    : std_logic_vector (3 downto 0);
 signal r,s  : std_logic_vector (3 downto 0);
 signal f    : STD_LOGIC_VECTOR (3 downto 0); 

begin
-----instantiate and connect components

u1: ram_regs port map(clk=>clk,rst=>rst,a=>a,b=>b,f=>f,
             dest_ctl=>dest_ctl,ram0=>ram0,ram3=>ram3,
				  ad=>ad,bd=>bd);

u2: q_reg port map(clk=>clk,rst=>rst,f=>f,dest_ctl=>dest_ctl,
                qs0=>qs0,qs3=>qs3,q=>q);

u3: src_op port map(d=>d,ad=>ad,bd=>bd,q=>q,
                src_ctl=>src_ctl,r=>r,s=>s);

u4: alu port map(r=>r, s=>s,c_n=>c_n,alu_ctl=>alu_ctl,
               f=>f, g_bar => g_bar, p_bar=>p_bar,
               c_n4=>c_n4, ovr=>ovr);

u5: out_mux port map(ad=>ad,f=>f,dest_ctl=>dest_ctl,
              oe=>oe,y=>y);


------define f_0 and f3 outputs 

f_0 <= '1' when f = "0000" else '0'; -- not that these are "strong" signals, not open collector
f3  <= f(3);				  

end am2901;

