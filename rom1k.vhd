----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:24:33 12/12/2022 
-- Design Name: 
-- Module Name:    rom1k - Behavioral 
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
use work.sys9080_package.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rom1k is
	generic (
		filename: string := "";
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"00"
	);
	Port ( 
		A : in  STD_LOGIC_VECTOR (9 downto 0);
		nOE : in  STD_LOGIC;
		D : out  STD_LOGIC_VECTOR (7 downto 0)
	);
end rom1k;

architecture Behavioral of rom1k is

-- function defined in the package pulls in the content of the 
-- hex file in generic parameter
constant rom: mem1k8 := init_filememory(filename, 1024, default_value);
--constant bank0: mem1k8 := init_filememory("..\prog\fibonacci_code.hex", 1024, X"00");

begin

	D <= rom(to_integer(unsigned(A))) when (nOE = '0') else "ZZZZZZZZ";

end Behavioral;

