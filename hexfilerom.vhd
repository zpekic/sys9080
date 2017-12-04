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
variable i: integer range 0 to (2 ** address_size) - 1;
variable location: std_logic_vector(7 downto 0);
 
begin
	-- fill with default value
	for i in 0 to depth - 1 loop	
		location := std_logic_vector(to_unsigned(i, 8));
		case location is
			------- RST0 @ 0x00 --------
			when X"00" => 
				temp_mem(i) := X"F3"; -- DI
			when X"01" => 
				temp_mem(i) := X"21"; -- LXI H, 0xFFFF
			when X"02" => 
				temp_mem(i) := X"FF"; 
			when X"03" => 
				temp_mem(i) := X"FF"; 
			when X"04" => 
				temp_mem(i) := X"F9"; -- SPHL
			when X"05" => 
				temp_mem(i) := X"2E"; -- MVI L, 0x55
			when X"06" => 
				temp_mem(i) := X"55"; 
			when X"07" => 
				temp_mem(i) := X"11"; -- LXI D, 0x4445
			when X"08" => 
				temp_mem(i) := X"45";
			when X"09" => 
				temp_mem(i) := X"44";
			when X"0A" => 
				temp_mem(i) := X"FB"; -- EI
			when X"0B" => 
				temp_mem(i) := X"01"; -- DeadLoop: LXI B, 0x0020; set C to ASCII space
			when X"0C" => 
				temp_mem(i) := X"20"; 
			when X"0D" => 
				temp_mem(i) := X"00";
			when X"0E" => 
				temp_mem(i) := X"79"; -- SendNextChar: MOV A, C
			when X"0F" => 
				temp_mem(i) := X"D3"; -- OUT 0x00; send char
			when X"10" => 
				temp_mem(i) := X"00"; 
			when X"11" => 
				temp_mem(i) := X"DB"; -- IN 0x01; read status
			when X"12" => 
				temp_mem(i) := X"01"; 
			when X"13" => 
				temp_mem(i) := X"FE"; -- CPI 0x80; end of printable chars reached?
			when X"14" => 
				temp_mem(i) := X"80"; 
			when X"15" => 
				temp_mem(i) := X"CA"; -- JZ DeadLoop
			when X"16" => 
				temp_mem(i) := X"0B"; 
			when X"17" => 
				temp_mem(i) := X"00"; 
			when X"18" => 
				temp_mem(i) := X"0C"; -- INR C
			when X"19" => 
				temp_mem(i) := X"C2"; -- JMP SendNextChar
			when X"1A" => 
				temp_mem(i) := X"0E"; 
			when X"1B" => 
				temp_mem(i) := X"00"; 
			when X"1C" => 
				temp_mem(i) := X"00"; -- NOP 
			------- RST7 @ 0x38 --------
			when X"38" => 
				temp_mem(i) := X"00"; -- NOP
			when X"39" => 
				temp_mem(i) := X"F5"; -- PUSH PSW
			when X"40" => 
				temp_mem(i) := X"E5"; -- PUSH H
			when X"41" => 
				temp_mem(i) := X"D5"; -- PUSH D
			when X"42" => 
				temp_mem(i) := X"C5"; -- PUSH B
			when X"43" => 
				temp_mem(i) := X"C1"; -- POP B
			when X"44" =>  
				temp_mem(i) := X"D1"; -- POP D
			when X"45" => 
				temp_mem(i) := X"E1"; -- POP H
			when X"46" => 
				temp_mem(i) := X"F1"; -- POP PSW
			when X"47" => 
				temp_mem(i) := X"FB"; -- EI 
			when X"48" => 
				temp_mem(i) := X"C9"; -- RET
			when X"49" => 
				temp_mem(i) := X"00"; -- NOP
			-----------------------------
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

