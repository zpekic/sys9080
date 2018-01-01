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
use STD.textio.all;
use ieee.std_logic_textio.all;

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
		default_value: STD_LOGIC_VECTOR(7 downto 0) := X"FF");
    Port (           
			  D : out  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end hexfilerom;

architecture Behavioral of hexfilerom is

COMPONENT rom4kx8
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

type bytememory is array(0 to (2 ** address_size) - 1) of std_logic_vector(7 downto 0);

impure function init_inlinememory(depth: in integer; default_value: std_logic_vector(7 downto 0)) return bytememory is
variable temp_mem : bytememory;
variable i: integer range 0 to (depth - 1);
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
				temp_mem(i) := X"21"; -- LXI H, 0x0000
			when X"02" => 
				temp_mem(i) := X"00"; 
			when X"03" => 
				temp_mem(i) := X"00"; 
			when X"04" => 
				temp_mem(i) := X"2B"; -- DCX H
			when X"05" => 
				temp_mem(i) := X"F9"; -- SPHL
			when X"06" => 
				temp_mem(i) := X"FB"; -- EI
			when X"07" => 
				temp_mem(i) := X"00"; -- NOP
			when X"08" => 
				temp_mem(i) := X"AF"; -- XRA A
			when X"09" => 
				temp_mem(i) := X"37"; -- STC
			when X"0A" => 
				temp_mem(i) := X"76"; -- HLT ; interrupt is needed to go further
			when X"0B" => 
				temp_mem(i) := X"01"; -- DeadLoop: LXI B, 0x0D20; set C to ASCII space
			when X"0C" => 
				temp_mem(i) := X"20"; 
			when X"0D" => 
				temp_mem(i) := X"0D";
			when X"0E" => 
				temp_mem(i) := X"79"; -- SendNextChar: MOV A, C
			when X"0F" => 
				temp_mem(i) := X"D3"; -- OUT 0x00; send char
			when X"10" => 
				temp_mem(i) := X"00"; 
			when X"11" => 
				temp_mem(i) := X"FE"; -- CPI 07FH; end of printable chars reached?
			when X"12" => 
				temp_mem(i) := X"7F"; 
			when X"13" => 
				temp_mem(i) := X"F2"; -- JP NextLine
			when X"14" => 
				temp_mem(i) := X"1A"; 
			when X"15" => 
				temp_mem(i) := X"00"; 
			when X"16" => 
				temp_mem(i) := X"0C"; -- INR C
			when X"17" => 
				temp_mem(i) := X"C3"; -- JMP SendNextChar
			when X"18" => 
				temp_mem(i) := X"0E"; 
			when X"19" => 
				temp_mem(i) := X"00"; 
			when X"1A" => 
				temp_mem(i) := X"78"; -- NextLine: MOV A, B
			when X"1B" => 
				temp_mem(i) := X"D3"; -- OUT 0x00; send char
			when X"1C" => 
				temp_mem(i) := X"00"; 
			when X"1D" => 
				temp_mem(i) := X"EE"; -- XRI A, 00000110B 
			when X"1E" => 
				temp_mem(i) := X"06"; 
			when X"1F" => 
				temp_mem(i) := X"D3"; -- OUT 0x00; send char
			when X"20" => 
				temp_mem(i) := X"00"; 
			when X"21" => 
				temp_mem(i) := X"C3"; -- JMP DeadLoop
			when X"22" => 
				temp_mem(i) := X"0B"; 
			when X"23" => 
				temp_mem(i) := X"00"; 
			when X"24" => 
				temp_mem(i) := X"00"; 
			when X"25" => 
				temp_mem(i) := X"00"; 
			when X"26" => 
				temp_mem(i) := X"00"; 
			when X"27" => 
				temp_mem(i) := X"00"; 
			------- RST5 @ 0x28 --------
			when X"28" => 
				temp_mem(i) := X"C3"; -- JMP RST7
			when X"29" => 
				temp_mem(i) := X"38"; 
			when X"2A" => 
				temp_mem(i) := X"00"; 
			------- RST6 @ 0x30 --------
			when X"30" => 
				temp_mem(i) := X"C3"; -- JMP RST7
			when X"31" => 
				temp_mem(i) := X"38"; 
			when X"32" => 
				temp_mem(i) := X"00"; 
			------- RST7 @ 0x38 --------
			when X"38" => 
				temp_mem(i) := X"F3"; -- DI
			when X"39" => 
				temp_mem(i) := X"F5"; -- PUSH PSW
			when X"3A" => 
				temp_mem(i) := X"E5"; -- PUSH H
			when X"3B" => 
				temp_mem(i) := X"3E"; -- MVI A, '*'
			when X"3C" => 
				temp_mem(i) := X"2A"; 
			when X"3D" => 
				temp_mem(i) := X"D3"; -- OUT 00H
			when X"3E" =>  
				temp_mem(i) := X"00"; 
			when X"3F" => 
				temp_mem(i) := X"E1"; -- POP H
			when X"40" => 
				temp_mem(i) := X"F1"; -- POP PSW
			when X"41" => 
				temp_mem(i) := X"FB"; -- RETI: EI 
			when X"42" => 
				temp_mem(i) := X"C9"; -- RET
			when X"43" => 
				temp_mem(i) := X"00"; -- NOP
			-----------------------------
		when others =>
			temp_mem(i) := default_value;
		end case;
	end loop;

   return temp_mem;
	
end init_inlinememory;

impure function init_filememory(file_name : in string; depth: in integer; default_value: std_logic_vector(7 downto 0)) return bytememory is
variable temp_mem : bytememory;
variable i, addr_start, addr_end: integer range 0 to (depth - 1);
variable location: std_logic_vector(7 downto 0);
file input_file : text open read_mode is file_name;
variable input_line : line;
variable line_current: integer := 0;
variable address: std_logic_vector(15 downto 0);
variable byte_count, record_type, byte_value: std_logic_vector(7 downto 0);
variable firstChar: character;
variable count: integer;
variable isOk: boolean;

begin
	-- fill with default value
	for i in 0 to depth - 1 loop	
			temp_mem(i) := default_value;
	end loop;

	 -- parse the file for the data
	 -- format described here: https://en.wikipedia.org/wiki/Intel_HEX
	 assert false report file_name & ": loading up to " & integer'image(depth) & " bytes." severity note;
	 loop 
		line_current := line_current + 1;
      readline (input_file, input_line);
		exit when endfile(input_file); --till the end of file is reached continue.

		read(input_line, firstChar);
		if (firstChar = ':') then
			hread(input_line, byte_count);
			hread(input_line, address);
			hread(input_line, record_type);
			case record_type is
				when X"00" => -- DATA
					count := to_integer(unsigned(byte_count));
					if (count > 0) then
						addr_start := to_integer(unsigned(address));
						addr_end := addr_start + to_integer(unsigned(byte_count)) - 1;
						report file_name & ": parsing line " & integer'image(line_current) & " for " & integer'image(count) & " bytes at address " & integer'image(addr_start) severity note;
						for i in addr_start to addr_end loop
							hread(input_line, byte_value);
							if (i < depth) then
								temp_mem(i) := byte_value;
							else
								report file_name & ": line " & integer'image(line_current) & " data beyond memory capacity ignored" severity note;
							end if;
						end loop;
					else
						report file_name  & ": line " & integer'image(line_current) & " has no data" severity note;
					end if;
				when X"01" => -- EOF
					report file_name & ": line " & integer'image(line_current) & " eof record type detected" severity note;
					exit;
				when others =>
					report file_name & ": line " & integer'image(line_current) & " unsupported record type detected" severity failure;
			end case;
		else
			report file_name & ": line " & integer'image(line_current) & " does not start with ':' " severity failure;
		end if;
	end loop; -- next line in file

	file_close(input_file);

   return temp_mem;
	
end init_filememory;

signal rom: bytememory := init_filememory(filename, 2 ** address_size, default_value);
--signal rom: bytememory := init_inlinememory(2 ** address_size, default_value);
attribute ram_style: string;
attribute ram_style of rom: signal is "block";

begin
	D <= rom(to_integer(unsigned(A))) when (nRead = '0' and nSelect = '0') else "ZZZZZZZZ";
end Behavioral;

