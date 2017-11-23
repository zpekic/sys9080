----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    hexfilerom - Behavioral 
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

entity hexfilerom is
	 generic (
		filename: string := "";
		address_size: positive := 8;
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"76");
    Port (           
			  D : out  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end hexfilerom;

architecture Behavioral of hexfilerom is

type bytememory is array(0 to (2 ** address_size) - 1) of std_logic_vector(7 downto 0);

impure function init_bytememory(file_name : in string; depth: in integer; default_value: std_logic_vector(7 downto 0)) return bytememory is
variable temp_mem : bytememory;
 
begin
	-- fill with default value
	for i in 0 to depth - 1 loop	
		case i is
			when 0 => 
				temp_mem(i) := X"F3"; -- DI
			when 1 => 
				temp_mem(i) := X"11"; -- LXI D, 0xDDEE
			when 2 => 
				temp_mem(i) := X"EE";
			when 3 => 
				temp_mem(i) := X"DD";
			when 4 => 
				temp_mem(i) := X"01"; -- LXI B, 0xBBCC
			when 5 => 
				temp_mem(i) := X"CC"; 
			when 6 => 
				temp_mem(i) := X"BB";
			when 7 => 
				temp_mem(i) := X"21"; -- LXI H, 0xFFFF
			when 8 => 
				temp_mem(i) := X"FF"; 
			when 9 => 
				temp_mem(i) := X"FF"; 
			when 10 => 
				temp_mem(i) := X"F9"; -- SPHL
			when 11 => 
				temp_mem(i) := X"79"; -- MOV A, C
			when 12 => 
				temp_mem(i) := X"D3"; -- OUT 0x00
			when 13 => 
				temp_mem(i) := X"00"; 
			when 14 => 
				temp_mem(i) := X"78"; -- MOV A, B
			when 15 => 
				temp_mem(i) := X"D3"; -- OUT 0x01
			when 16 => 
				temp_mem(i) := X"01"; 
			when 17 => 
				temp_mem(i) := X"7B"; -- MOV A, E
			when 18 => 
				temp_mem(i) := X"D3"; -- OUT 0x00
			when 19 => 
				temp_mem(i) := X"00"; 
			when 20 => 
				temp_mem(i) := X"7A"; -- MOV A, D
			when 21 => 
				temp_mem(i) := X"D3"; -- OUT 0x01
			when 22 => 
				temp_mem(i) := X"01"; 
			when 23 => 
				temp_mem(i) := X"2B"; -- LOOP: DCX H
			when 24 => 
				temp_mem(i) := X"00"; -- NOP
			when 25 => 
				temp_mem(i) := X"7D"; -- MOV A, L
			when 26 => 
				temp_mem(i) := X"D3"; -- OUT 0x00
			when 27 => 
				temp_mem(i) := X"00"; 
			when 28 => 
				temp_mem(i) := X"7C"; -- MOV A, H
			when 29 => 
				temp_mem(i) := X"D3"; -- OUT 0x01
			when 30 => 
				temp_mem(i) := X"01"; 
			when 31 => 
				temp_mem(i) := X"FA"; -- JM 0x0017
			when 32 => 
				temp_mem(i) := X"17";
			when 33 => 
				temp_mem(i) := X"00"; 
			when 34 => 
				temp_mem(i) := X"F2"; -- JP 0x0017
			when 35 => 
				temp_mem(i) := X"17";
			when 36 => 
				temp_mem(i) := X"00"; 
		when others =>
			temp_mem(i) := default_value;
		end case;
	end loop;

   return temp_mem;
	
end init_bytememory;

--signal rom: bytememory := init_bytememory(filename, 2 ** address_size, default_value);
constant rom: bytememory := init_bytememory(filename, 2 ** address_size, default_value);

begin

D <= rom(to_integer(unsigned(A))) when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";

end Behavioral;

