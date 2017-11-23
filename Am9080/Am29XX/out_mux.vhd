----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:46:36 04/26/2010 
-- Design Name: 
-- Module Name:    out_mux - out_mux 
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

entity out_mux is
    Port ( ad : in  STD_LOGIC_VECTOR (3 downto 0);
           f : in  STD_LOGIC_VECTOR (3 downto 0);
           dest_ctl : in  STD_LOGIC_VECTOR (2 downto 0);
           oe : in  STD_LOGIC;
           y : inout  STD_LOGIC_VECTOR (3 downto 0));
end out_mux;

architecture out_mux of out_mux is
 signal y_int: STD_LOGIC_VECTOR(3 downto 0); ---output before tri-state
                                     ---- buffer
begin 
  y_int <= ad when dest_ctl = rama else f;
  y     <= y_int when oe='0' else "ZZZZ";

end out_mux;

