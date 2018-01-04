-- VERSION: 1.0
-- MODULE: am2909
-- 13/1/2010
-- ************************************************************
-- Copyright (C) Stanisalw Deniziak

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity am2909 is
	port
	(
		-- Input ports
		S : in std_logic_vector(1 downto 0);
		R,D	: in std_logic_vector(3 downto 0);
		ORi	: in std_logic_vector(3 downto 0);
		nFE, PUP, nRE , nZERO, nOE, CN : in std_logic;
		CLK  : in std_logic;
		-- Output ports
		Y	: out std_logic_vector(3 downto 0);
		C4	: out std_logic
	);
end am2909;

architecture RTL of am2909 is
signal  XX, AR, F, PC, YY : std_logic_vector(3 downto 0);
begin

Sel: process (S, AR, F, PC, D)
begin 
case S(1 downto 0) is
	when "00" =>
		XX <= PC; 
	when "01" =>
		XX <= AR; 
	when "10" =>
		XX <= F; 
	when "11" =>
		XX <= D;
	when others =>
		null;
	end case;
end process;

stos: process (CLK)
variable STK0, STK1, STK2, STK3: std_logic_vector(3 downto 0); 
begin
if (rising_edge(clk)) then
   if (nFE = '0') then 
     if PUP = '0' then
        STK0 := STK1;
        STK1 := STK2;
        STK2 := STK3;
     else
        STK3 := STK2;
        STK2 := STK1;
        STK1 := STK0;
        STK0 := PC;        
     end if;
    end if;
 end if;
 F <= STK0; 
end process;

AReg: process (clk)
begin
if (rising_edge(clk)) then
  if nRE = '0' then
    AR <= R;
  end if;
 end if; 
end process;
 
uPC: process (CLK, YY, CN)
variable res	: std_logic_vector(5 downto 0);
variable PCint	: std_logic_vector(5 downto 0);
begin 
    PCint := '0' & YY & CN;
    res := std_logic_vector(unsigned(PCint) + 1);
    C4 <= res(5);
    if (rising_edge(clk)) then
      PC <= res(4 downto 1);
    end if;
end process;

output: process (nOE, nZERO, XX, ORi, YY)
begin
	if (nZERO = '0') then 
		YY <= "0000"; 
	else 
		YY <= XX or ORi; 
	end if;
	
	if (nOE = '0') then  
		Y <= YY;  
	else 
		Y <= "ZZZZ";  
	end if;
	
end process;

end RTL;

