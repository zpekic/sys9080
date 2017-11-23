--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mnemonics is

  
  ---ALU source operand control mnemonics
  
  
  constant aq: std_logic_vector(2 downto 0) :="000";
  constant ab: std_logic_vector(2 downto 0) :="001";
  constant zq: std_logic_vector(2 downto 0) :="010";
  constant zb: std_logic_vector(2 downto 0) :="011";
  constant za: std_logic_vector(2 downto 0) :="100";
  constant da: std_logic_vector(2 downto 0) :="101";
  constant dq: std_logic_vector(2 downto 0) :="110";
  constant dz: std_logic_vector(2 downto 0) :="111";
  
  ----ALU function control mnemonics
  
  constant add: std_logic_vector(2 downto 0) :="000";
  constant subr: std_logic_vector(2 downto 0) :="001";
  constant subs: std_logic_vector(2 downto 0) :="010";
  constant orrs: std_logic_vector(2 downto 0) :="011";
  constant andrs: std_logic_vector(2 downto 0) :="100";
  constant notrs: std_logic_vector(2 downto 0) :="101";
  constant exor : std_logic_vector(2 downto 0) :="110";
  constant exnor: std_logic_vector(2 downto 0) :="111";
  
  
  ---ALU destination control mnemonics
  
  constant qreg: std_logic_vector(2 downto 0) :="000";
  constant nop : std_logic_vector(2 downto 0) :="001";
  constant rama: std_logic_vector(2 downto 0) :="010";
  constant ramf: std_logic_vector(2 downto 0) :="011";
  constant ramqd: std_logic_vector(2 downto 0) :="100";
  constant ramd : std_logic_vector(2 downto 0) :="101";
  constant ramqu: std_logic_vector(2 downto 0) :="110";
  constant ramu : std_logic_vector(2 downto 0) :="111";
  
  end mnemonics;
  
  