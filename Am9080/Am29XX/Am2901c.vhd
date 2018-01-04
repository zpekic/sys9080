----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:52:57 01/01/2018 
-- Design Name: 
-- Module Name:    Am2901c - Behavioral 
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

entity Am2901c is
    Port ( clk : in  STD_LOGIC;
           --rst : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           d : in  STD_LOGIC_vector (3 downto 0);
           i : in  STD_LOGIC_VECTOR (8 downto 0);
           c_n : in  STD_LOGIC;
           oe : in  STD_LOGIC;
           ram0 : inout  STD_LOGIC;
           ram3 : inout  STD_LOGIC;
           qs0 : inout  STD_LOGIC;
           qs3 : inout  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (3 downto 0);
           g_bar : out  STD_LOGIC;
           p_bar : out  STD_LOGIC;
           ovr : out  STD_LOGIC;
           c_n4 : out  STD_LOGIC;
           f_0 : out  STD_LOGIC;
           f3 : out  STD_LOGIC);
end Am2901c;

architecture Behavioral of Am2901c is

---		I210	I543 		I876
---		SRC	FCT		DST ---
constant aq,	add,		qreg: std_logic_vector(2 downto 0) :="000";
constant ab,	subr,		nop: std_logic_vector(2 downto 0) :="001";
constant zq,	subs,		rama: std_logic_vector(2 downto 0) :="010";
constant zb,	orrs,		ramf: std_logic_vector(2 downto 0) :="011";
constant za,	andrs,	ramqd: std_logic_vector(2 downto 0) :="100";
constant da,	notrs,	ramd: std_logic_vector(2 downto 0) :="101";
constant dq,	exor,		ramqu : std_logic_vector(2 downto 0) :="110";
constant dz,	exnor,	ramu: std_logic_vector(2 downto 0) :="111";

alias src: std_logic_vector(2 downto 0) is i(2 downto 0);
alias fct: std_logic_vector(2 downto 0) is i(5 downto 3);
alias dst: std_logic_vector(2 downto 0) is i(8 downto 6);
signal r1, r1c, s1, nr1c, ns1c, f1: STD_LOGIC_VECTOR (5 downto 0);
signal f, a_latch, b_latch, r, s, y_int: std_logic_vector(3 downto 0);

signal q: std_logic_vector(3 downto 0);
type ram_array is array(0 to 15) of std_logic_vector (3 downto 0);
signal ram: ram_array;

begin
-- REGISTERS ---
update_ram: process(clk, dst, ram3, ram0)
begin
	if (rising_edge(clk)) then
		case dst is
			when rama | ramf =>
				ram(to_integer(unsigned(b))) <= f;
			when ramqd | ramd =>
				ram(to_integer(unsigned(b))) <= ram3 & f(3) & f(2) & f(1);
			when ramqu | ramu =>
				ram(to_integer(unsigned(b))) <= f(2) & f(1) & f(0) & ram0;
			when others =>
				null;
		end case;
	end if;
end process;

update_q: process(clk, dst, qs3, qs0)
begin
	if (rising_edge(clk)) then
		case dst is
			when qreg =>
				q <= f;
			when ramqd =>
				q <= qs3 & q(3) & q(2) & q(1);
			when ramqu =>
				q <= q(2) & q(1) & q(0) & qs0;
			when others =>
				null;
		end case;
	end if;
end process;
   
a_latch <= ram(to_integer(unsigned(a))) when (clk = '1') else a_latch;
b_latch <= ram(to_integer(unsigned(b))) when (clk = '1') else b_latch;

--- ALU SOURCES ---
 with src select
    r <= a_latch when aq | ab,
	      "0000" when zq | zb | za,
		   d when others;
		  
 with src select
    s <= q when aq | zq | dq,
         b_latch when  ab | zb,
         a_latch when za | da,
         "0000" when others;		
		 
-- ALU FUNCTIONS ---		 
r1 <=   ('0', r(3),		r(2),		 r(1),	  r(0),     c_n);
r1c <=  ('0', r(3),		r(2),		 r(1),	  r(0),     c_n);
nr1c <= ('0', not r(3), not r(2), not r(1), not r(0), c_n);

s1 <=   ('0', s(3),		s(2),		 s(1),		s(0), 	 c_n);
ns1c <= ('0', not s(3), not s(2), not s(1), 	not s(0), c_n);
	 
alu: process (r1, r1c, s1, nr1c, ns1c, fct)
begin
   case fct is 
      when add =>
			f1 <= std_logic_vector(unsigned(r1c) + unsigned(s1));
      when subr => ---subtraction same as 2's comp addn
		   f1 <= std_logic_vector(unsigned(s1) + unsigned(nr1c));
      when subs =>
			f1 <= std_logic_vector(unsigned(r1) + unsigned(ns1c));
      when orrs => 
			f1 <= r1 or s1;
      when andrs => 
			f1 <= r1 and s1;
      when notrs => 
			f1 <= (not r1) and s1;
      when exor => 
			f1 <= r1 xor s1;
      when exnor => 
			f1 <= not(r1 xor s1);
      when others => 
			null;
 end case;
end process;

--- INTERNAL OUTPUTS --
f <= f1(4 downto 1);
y_int <= a_latch when (dst = rama) else f;

--- INPUTS & OUTPUTS ---
with dst select
	ram0 <= f(0) when ramqd | ramd, 'Z' when others;

with dst select
	ram3 <= f(3) when ramqu | ramu, 'Z' when others;

with dst select
	qs0 <= q(0) when ramqd, 'Z' when others;

with dst select
	qs3 <= q(3) when ramqu, 'Z' when others;
	
--- OUTPUTS ---
c_n4 <= f1(5);

f_0 <= '1' when f = "0000" else '0'; -- not that these are "strong" signals, not open collector

f3  <= f(3);	

g_bar <= not(
   (r(3) and s(3)) or
    ((r(3) or s(3)) and (r(2) and s(2))) or
	 ((r(3) or s(3)) and (r(2) or s(2)) and (r(1) and s(1))) or
    ((r(3) or s(3)) and (r(2) or s(2)) and (r(1) or s(1)) and
    (r(0) and s(0))));
p_bar <= not(
    (r(3) or s(3)) and (r(2) or s(2)) and (r(1) and s(1)) and
    (r(0) and s(0)));

ovr <= f1(5) xor f1(4); --'1' when (f1(5) /= f1(4)) else '0';

y <= y_int when (oe = '0') else "ZZZZ";	 

end Behavioral;

