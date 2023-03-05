--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use STD.textio.all;
use ieee.std_logic_textio.all;

package sys9080_package is

type mem16x16 is array(0 to 15) of std_logic_vector(15 downto 0);
constant decode4to16: mem16x16 := (
	"1111111111111110",
	"1111111111111101",
	"1111111111111011",
	"1111111111110111",
	"1111111111101111",
	"1111111111011111",
	"1111111110111111",
	"1111111101111111",
	"1111111011111111",
	"1111110111111111",
	"1111101111111111",
	"1111011111111111",
	"1110111111111111",
	"1101111111111111",
	"1011111111111111",
	"0111111111111111"
);

-- some handy i8080 instruction codes
constant nop: std_logic_vector(7 downto 0) := X"00";
constant hlt: std_logic_vector(7 downto 0) := X"76";
constant rst_7: std_logic_vector(7 downto 0) := X"FF";

type mem1k8 is array(0 to 1023) of std_logic_vector(7 downto 0);

impure function init_filememory(file_name : in string; depth: in integer; default_value: std_logic_vector(7 downto 0)) return mem1k8;
impure function char2hex(char: in character) return integer;
impure function get_string(value: in unsigned; len: in integer; base: in integer) return string;
impure function parseBinary8(bin_str: in string) return std_logic_vector;
impure function parseBinary16(bin_str: in string) return std_logic_vector;
impure function parseHex16(hex_str: in string) return std_logic_vector;

end sys9080_package;

package body sys9080_package is

impure function char2hex(char: in character) return integer is
begin
	case char is
		when '0' to '9' =>
			return character'pos(char) - character'pos('0');
		when 'a' to 'f' =>
			return character'pos(char) - character'pos('a') + 10;
		when 'A' to 'F' =>
			return character'pos(char) - character'pos('A') + 10;
		when others =>
			assert false report "char2hex(): unexpected character '" & char & "'" severity failure;
	end case;
	return 0;
end char2hex;

impure function get_string(value: in unsigned; len: in integer; base: in integer) return string is
	variable str: string(1 to 8) := "????????"; 
	variable m, d: integer;
	
begin
	d := to_integer(value);
	
	for i in 0 to len - 1 loop
		m := d mod base;
		d := d / base;
		case m is
			when 0 => str(8 - i) := '0';
			when 1 => str(8 - i) := '1';
			when 2 => str(8 - i) := '2';
			when 3 => str(8 - i) := '3';
			when 4 => str(8 - i) := '4';
			when 5 => str(8 - i) := '5';
			when 6 => str(8 - i) := '6';
			when 7 => str(8 - i) := '7';
			when 8 => str(8 - i) := '8';
			when 9 => str(8 - i) := '9';
			when 10 => str(8 - i) := 'A';
			when 11 => str(8 - i) := 'B';
			when 12 => str(8 - i) := 'C';
			when 13 => str(8 - i) := 'D';
			when 14 => str(8 - i) := 'E';
			when 15 => str(8 - i) := 'F';
			when others =>
				assert false report "get_string() reached unexpected case m =" & integer'image(m) severity failure; 
		end case;
	end loop;
	
	return str(8 - len + 1 to 8);
	
end get_string;

impure function parseBinary8(bin_str: in string) return std_logic_vector is
	variable val: std_logic_vector(7 downto 0) := "00000000";
begin
	--report "parseBinary8(" & bin_str & ")" severity note;
	assert bin_str'right - bin_str'left = 7 report "parseBinary8(): length of '" & bin_str & "' is not 8." severity failure;
	for i in bin_str'left to bin_str'right loop
		case bin_str(i) is
			when '0' =>
				val := val(6 downto 0) & "0";
			when '1'|'X' => -- interpret X as '1' due to bus signal being low active - this way is undefined microinstruction is executed, bus won't short!
				val := val(6 downto 0) & "1";
			when others =>
				assert false report "parseBinary8(): unexpected character '" & bin_str(i) & "'" severity failure;
		end case;
	end loop;

	return val;
end parseBinary8;

impure function parseBinary16(bin_str: in string) return std_logic_vector is
begin
	--report "parseBinary16(" & bin_str & ")" severity note;
	return parseBinary8(bin_str(1 to 8)) & parseBinary8(bin_str(9 to 16));
end parseBinary16;

impure function parseHex16(hex_str: in string) return std_logic_vector is
	variable intVal: integer := 0;
begin
	--report "parseHex16(" & hex_str & ")" severity note;
	
	for i in hex_str'left to hex_str'right loop
		intVal := 16 * intVal + char2hex(hex_str(i));
	end loop;
	return std_logic_vector(to_unsigned(intVal, 16));
end parseHex16;

impure function init_filememory(file_name : in string; depth: in integer; default_value: std_logic_vector(7 downto 0)) return mem1k8 is
variable temp_mem : mem1k8;
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
--	for i in 0 to depth - 1 loop	
--			temp_mem(i) := default_value;
--	end loop;

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
						--report file_name & ": parsing line " & integer'image(line_current) & " for " & integer'image(count) & " bytes at address " & integer'image(addr_start) severity note;
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

end sys9080_package;
