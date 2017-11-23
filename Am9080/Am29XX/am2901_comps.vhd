--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
package am2901_comps is
 component ram_regs is
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
end component;
 component q_reg is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           f : in  std_logic_vector (3 downto 0);
           dest_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           qs0 : inout  STD_LOGIC;
           qs3 : inout  STD_LOGIC;
           q : out  std_logic_vector (3 downto 0));
end component;

component src_op is
    Port ( d : in  std_logic_vector (3 downto 0);
           ad : in  std_logic_vector (3 downto 0);
           bd : in  std_logic_vector (3 downto 0);
           q : in  std_logic_vector (3 downto 0);
           src_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           r : buffer  std_logic_vector (3 downto 0);
           s : buffer  std_logic_vector (3 downto 0));
end component; 


  component alu is
    Port ( r : in  STD_LOGIC_VECTOR (3 downto 0);
           s : in  STD_LOGIC_VECTOR (3 downto 0);
           c_n : in  STD_LOGIC;
           alu_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           f : out  STD_LOGIC_VECTOR (3 downto 0);
           g_bar : out  STD_LOGIC;
           p_bar : out  STD_LOGIC;
           c_n4 : out  STD_LOGIC;
           ovr : out  STD_LOGIC);
end component;


  component out_mux is
    Port ( ad : in  STD_LOGIC_VECTOR (3 downto 0);
           f : in  STD_LOGIC_VECTOR (3 downto 0);
           dest_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           oe : in  STD_LOGIC;
           y : inout  STD_LOGIC_VECTOR (3 downto 0));
end component;

  
  
end am2901_comps;
