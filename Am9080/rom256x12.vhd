----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:51:58 02/19/2017 
-- Design Name: 
-- Module Name:    tinyrom - Behavioral 
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
-- http://www.pastraiser.com/cpu/i8080/i8080_opcodes.html
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.textio.all;
--use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.sys9080_package.all;

entity rom256x12 is
    Port ( address : in  STD_LOGIC_VECTOR (7 downto 0);
           data : out  STD_LOGIC_VECTOR (11 downto 0));
end rom256x12;

architecture Behavioral of rom256x12 is

constant uPrgAddress_nop: std_logic_vector(11 downto 0) := X"086";
constant uPrgAddress_hlt: std_logic_vector(11 downto 0) := X"082";

--alias a8: std_logic_vector(7 downto 0) is address(7 downto 0);

type t_mem256x12 is array(0 to 255) of std_logic_vector(11 downto 0);

--impure function load_mem(mif_file_name : in string; depth: in integer; default_value: std_logic_vector(11 downto 0)) return rom_array is
--    variable temp_mem : rom_array;-- := (others => (others => default));
--	 -- mif file variables
--    file mif_file : text; -- open read_mode is mif_file_name;
--    variable mif_line : line;
--	 variable char: character;
--	 variable line_cnt: integer := 1;
--	 variable isOk: boolean;
--	 variable word_address: std_logic_vector(15 downto 0);
--	 variable word_value: std_logic_vector(11 downto 0);
--	 variable word_offset: integer;
--	 variable hex_cnt: integer;
--	 variable continue: boolean := true;
--
--begin
--	 -- fill with default value
--	 for i in 0 to depth - 1 loop	
--		temp_mem(i) := default_value;
--	 end loop;
--	 report "load_mem(): initialized " & integer'image(depth) & " words of memory to " & integer'image(to_integer(unsigned(default_value))) severity note;
--	 -- parse the file for the data
--	 report "load_mem(): loading memory from file " & mif_file_name severity note;
--	 file_open(mif_file, mif_file_name, read_mode);
--	 while (not endfile(mif_file)) and continue loop--till the end of file is reached continue.
--      readline (mif_file, mif_line);
--		--next when mif_line'length = 0;  -- Skip empty lines
--		report "load_mem(): line " & integer'image(line_cnt) & " read";
--		isOk := true;
--		hex_cnt := 0;
--		word_offset := 0;
--		while isOk loop
--			read(mif_line, char, isOk);
--			if (isOk) then
--				case char is
--					when '.' =>
--						report "load_mem(): " & mif_file_name & " has been processed." severity NOTE;
--						--file_close(mif_file);
--						--return temp_mem;
--						exit;
--					when ' ' =>
--						report "load_mem(): space detected";
--						if (hex_cnt > 6) then
--						      isOk := false;
--						end if;
--					when ';' =>
--						report "load_mem(): comment detected, rest of line is ignored";
--						exit;
--					when '0' to '9'|'a' to 'f'|'A' to 'F' =>
--						report "load_mem(): [" & char & "]";
--						case hex_cnt is
--							when 0 =>
--								word_address := x"000" & std_logic_vector(to_unsigned(char2hex(char), 4));
--							when 1|2 =>
--								word_address := word_address(11 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
--							when 3 =>
--								word_address := word_address(11 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
--								report "load_wordmemory(): address parsed";
--								--assert unsigned(word_address) < depth;
--							when 4 =>
--								word_value := x"00" & std_logic_vector(to_unsigned(char2hex(char), 4));
--							when 5 =>
--                        word_value := word_value(7 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
--                     when 6 =>
--								word_value := word_value(7 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
--								temp_mem(to_integer(unsigned(word_address)) + word_offset) := word_value;
--								report "load_mem(): word " & integer'image(word_offset) & " set.";
--								word_offset := word_offset + 1;
--							when others =>
--								assert false report "load_mem(): too many bytes specified in line" severity note; 
--								exit;
--						end case;
--						hex_cnt := hex_cnt + 1;
--					when others =>
--						assert false report "load_mem(): unexpected char in line " & integer'image(line_cnt) severity note; 
--						exit;
--				end case;
--			else
--				report "load_mem(): end of line " & integer'image(line_cnt) & " reached";
--			end if;
--		end loop;
--		
--		line_cnt := line_cnt + 1;
--	end loop; -- next line in file
-- 
--	file_close(mif_file);
--   return temp_mem;
--	
--end load_mem;

impure function load_mem(input_file_name : in string; depth: in integer; default_value: std_logic_vector(11 downto 0)) return t_mem256x12 is
    variable temp_mem : t_mem256x12;-- := (others => (others => default_value));
	 -- mif file variables
    file input_file : text; -- open read_mode is input_file_name;
    variable input_line : line;
	 variable line_current: integer := 0;
	 variable line_cnt_accepted, line_cnt_ignored: integer := 0;
	 variable address: std_logic_vector(15 downto 0);
	 variable word: std_logic_vector(11 downto 0);
	 variable addr_str: string(1 to 3);
	 variable data12_str: string(1 to 3);
	 variable addr_ok, data12_ok : boolean;
	 variable firstChar: character;
	 variable space: character;
 
begin
	 -- fill with default value
	 for i in 0 to depth - 1 loop	
		temp_mem(i) := default_value;
	 end loop;
	 assert false report "load_mem(): initialized " & integer'image(depth) & " words of memory to default value " severity note;
   	 
	 -- parse the file for the data
	 assert false report "load_mem(): loading memory from file " & input_file_name severity note;
	 file_open(input_file, input_file_name, read_mode);
	 loop 
		exit when endfile(input_file); --till the end of file is reached continue.
		line_current := line_current + 1;
      readline (input_file, input_line);
		--next when input_line'length = 0;  -- Skip empty lines
		report "init_wordmemory(): parsing line " & integer'image(line_current) severity note;
		--report "[" & integer'image(input_line'left) & "]" severity note;
		address := X"0000";
		word := X"000";

		read(input_line, firstChar);
		--exit when endline(input_line);
		addr_ok := true;
		--report "firstChar='" & firstChar & "'" severity note;
		case firstChar is
		when ';' =>
			--report "Semicolon detected, line is treated as comment" severity note;
			line_cnt_ignored := line_cnt_ignored + 1;
		when '0' to '9' | 'A' to 'F' =>
			read(input_line, addr_str, addr_ok);
			--read(input_line, space);
			read(input_line, data12_str, data12_ok);
			--read(input_line, space);
			--if (addr_ok and data16_ok1 and data16_ok2 and data16_ok3 and data8_ok) then
				address := parseHex16(firstChar & addr_str);
				word := parseHex16(data12_str);

				temp_mem(to_integer(unsigned(address))) := word;
				line_cnt_accepted := line_cnt_accepted + 1;
				report "load_mem(): line " & integer'image(line_current) & " parsed and accepted for address " & get_string(unsigned(address), 4, 16) severity note;
			--else
			--	report "load_mem(): line " & integer'image(line_current) & " is ignored due to missing data" severity note;
			--	line_cnt_ignored := line_cnt_ignored + 1;
			--end if;
		when others =>
			report "load_mem(): line " & integer'image(line_current) & " is ignored due to unrecognized 1st char" severity note;
			line_cnt_ignored := line_cnt_ignored + 1;
		end case;
	end loop; -- next line in file

	file_close(input_file);

	report "load_mem(): " & integer'image(line_cnt_accepted) & " total lines parsed and accepted from file " & input_file_name severity note;
	report "load_mem(): " & integer'image(line_cnt_ignored) & " total lines parsed and ignored from file " & input_file_name severity note;

   return temp_mem;  	
end load_mem;

impure function dump_mem(hex_file_name: in string; depth: in integer; temp_mem: in t_mem256x12) return boolean is
	 -- hex file variables
	 file hex_file : text; -- open write_mode is hex_file_name;
	 variable hex_line : line;
	 variable checksum: integer;
	 variable status: FILE_OPEN_STATUS;
	
begin
	-- dump memory content to Intel hex-format like file
	file_open(status, hex_file, hex_file_name, write_mode);
	report "FILE_OPEN_STATUS of " & hex_file_name & " is " & FILE_OPEN_STATUS'IMAGE(status) severity note;
	for i in 0 to (depth - 1) / 16 loop
		report integer'image(i) severity note;
		write(hex_line, string'(": 10 ")); -- 16 bytes per line
		write(hex_line, get_string(to_unsigned(i * 16, 16), 4, 16));
		write(hex_line, string'(" 00 ")); -- regular data line marker
		checksum := 0;
		for j in 0 to 15 loop
			write(hex_line, get_string(unsigned(temp_mem(i * 16 + j)), 3, 16));
			checksum := checksum + to_integer(unsigned(temp_mem(i * 16 + j)));
			write(hex_line, string'(" "));
		end loop;
		write(hex_line, get_string(to_unsigned(0  - checksum, 8), 2, 16));
		writeline(hex_file, hex_line);
   end loop;
   write(hex_line, string'(": 00 0000 01 FF")); -- last line marker
   writeline(hex_file, hex_line); -- write last line
   file_close(hex_file);
	return true;
end dump_mem;
		
impure function init_wordmemory(mif_file_name : in string; hex_file_name: in string; depth: in integer; default_value: std_logic_vector(11 downto 0)) return t_mem256x12 is
    variable temp_mem : t_mem256x12;-- := (others => (others => default));
	 variable dummy: boolean;

begin
	temp_mem := load_mem(mif_file_name, depth, default_value);
	dummy := dump_mem(hex_file_name, depth, temp_mem);
	return temp_mem;
end init_wordmemory;
	

constant data_from_file: t_mem256x12 := init_wordmemory("../am9080/prom/mapper.mif", "../am9080/prom/mapper.hex", 256, uPrgAddress_nop);

--constant data_from_inline: rom_array :=
--(
--	0 => uPrgAddress_hlt, 
--	others => uPrgAddress_nop
--);

begin
	data <= data_from_file(to_integer(unsigned(address)));
--	data <= data_from_inline(to_integer(unsigned(a8)));

end Behavioral;

