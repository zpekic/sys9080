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
use ieee.std_logic_textio.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

--use work.tinycpu_common.all;

entity rom256x12 is
    Port ( address : in  STD_LOGIC_VECTOR (7 downto 0);
           data : out  STD_LOGIC_VECTOR (11 downto 0));
end rom256x12;

architecture Behavioral of rom256x12 is

constant uPrgAddress_nop: std_logic_vector(11 downto 0) := X"086";
constant uPrgAddress_hlt: std_logic_vector(11 downto 0) := X"082";

alias a8: std_logic_vector(7 downto 0) is address(7 downto 0);

type rom_array is array(0 to 255) of std_logic_vector(11 downto 0);

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
			assert false report "char2hex(): unexcpected character '" & char & "'" severity failure;
	end case;
	return 0;
end char2hex;

impure function init_wordmemory(mif_file_name : in string; hex_file_name: in string; depth: in integer; default_value: std_logic_vector(11 downto 0)) return rom_array is
    variable temp_mem : rom_array;-- := (others => (others => default));
	 -- mif file variables
    file mif_file : text open read_mode is mif_file_name;
    variable mif_line : line;
	 variable char: character;
	 variable line_cnt: integer := 1;
	 variable isOk: boolean;
	 variable word_address: std_logic_vector(15 downto 0);
	 variable word_value: std_logic_vector(11 downto 0);
	 variable word_offset: integer;
	 variable hex_cnt: integer;
	 -- hex file variables
	 file hex_file : text open write_mode is hex_file_name;
	 variable hex_line : line;
	 variable checksum: integer;
 
begin
	 -- fill with default value
	 for i in 0 to depth - 1 loop	
		temp_mem(i) := default_value;
	 end loop;
	 report "init_bytememory(): initialized " & integer'image(depth) & " bytes of memory to " & integer'image(to_integer(unsigned(default_value))) severity note;
	 -- parse the file for the data
	 report "init_bytememory(): loading memory from file " & mif_file_name severity note;
	 while not endfile(mif_file) loop --till the end of file is reached continue.
        readline (mif_file, mif_line);
		--next when mif_line'length = 0;  -- Skip empty lines
		report "init_mem(): line " & integer'image(line_cnt) & " read";
		isOk := true;
		hex_cnt := 0;
		word_offset := 0;
		while isOk and (line_cnt < 1024) loop -- TODO: remove this hack
			read(mif_line, char, isOk);
			if (isOk) then
				case char is
					when ' ' =>
						report "init_wordmemory(): space detected";
						if (hex_cnt > 6) then
						      isOk := false;
						end if;
					when ';' =>
						report "init_wordmemory(): comment detected, rest of line is ignored";
						exit;
					when '0' to '9'|'a' to 'f'|'A' to 'F' =>
						--report "init_mem(): hex char detected";
						case hex_cnt is
							when 0 =>
								word_address := x"000" & std_logic_vector(to_unsigned(char2hex(char), 4));
							when 1|2 =>
								word_address := word_address(11 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
							when 3 =>
								word_address := word_address(11 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
								report "init_wordmemory(): address parsed";
								--assert unsigned(word_address) < depth;
							when 4 =>
								word_value := x"00" & std_logic_vector(to_unsigned(char2hex(char), 4));
							when 5 =>
                        word_value := word_value(7 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
                     when 6 =>
								word_value := word_value(7 downto 0) & std_logic_vector(to_unsigned(char2hex(char), 4));
								temp_mem(to_integer(unsigned(word_address)) + word_offset) := word_value;
								report "init_wordmemory(): word " & integer'image(word_offset) & " set.";
								word_offset := word_offset + 1;
							when others =>
								assert false report "init_wordmemory(): too many bytes specified in line" severity note; 
								exit;
						end case;
						hex_cnt := hex_cnt + 1;
					when others =>
						assert false report "init_wordmemory(): unexpected char in line " & integer'image(line_cnt) severity note; 
						exit;
				end case;
			else
				report "init_bytememory(): end of line " & integer'image(line_cnt) & " reached";
			end if;
		end loop;
		
		line_cnt := line_cnt + 1;
	end loop; -- next line in file
 
	file_close(mif_file);
	
	-- dump memory content to Intel hex-format like file
	for i in 0 to (depth - 1) / 16 loop
		write(hex_line, string'(": 10 ")); -- 16 bytes per line
		hwrite(hex_line, std_logic_vector(to_unsigned(i * 16, 16)), RIGHT, 4);
		write(hex_line, string'(" 00 ")); -- regular data line marker
		checksum := 0;
		for j in 0 to 15 loop
			hwrite(hex_line, temp_mem(i * 16 + j), RIGHT, 3);
			checksum := checksum + to_integer(unsigned(temp_mem(i * 16 + j)));
			write(hex_line, string'(" "));
		end loop;
		hwrite(hex_line, std_logic_vector(to_unsigned(0  - checksum, 8)), RIGHT, 2);
		writeline(hex_file, hex_line);
   end loop;
   write(hex_line, string'(": 00 0000 01 FF")); -- last line marker
   writeline(hex_file, hex_line); -- write last line
   file_close(hex_file);
		
   return temp_mem;
	
end init_wordmemory;

constant data_from_file: rom_array := init_wordmemory("./prom/mapper.mif", "./prom/mapper.hex", 256, uPrgAddress_nop);

constant data_from_inline: rom_array :=
(
	0 => uPrgAddress_hlt, 
	others => uPrgAddress_nop
);

begin
	data <= data_from_file(to_integer(unsigned(a8)));

end Behavioral;

