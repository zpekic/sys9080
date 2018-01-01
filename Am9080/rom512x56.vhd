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

--use work.tinycpu_common.all;

entity rom512x56 is
    Port ( address : in  STD_LOGIC_VECTOR (8 downto 0);
           data : out STD_LOGIC_VECTOR (55 downto 0));
end rom512x56;

architecture Behavioral of rom512x56 is

--type t_uinstruction is array (55 downto 0) of std_logic;
type t_word is array(15 downto 0) of std_logic;
type t_byte is array(7 downto 0) of std_logic;
type t_uinstruction512 is array(0 to 511) of std_logic_vector(55 downto 0);
constant uCode_nop: std_logic_vector(55 downto 0) := "11000000001011111010100111110000001101010101010001000000";
constant uCode_default: std_logic_vector(55 downto 0) := "11111111111111111111111111111111111111111111111111111111";

type t_string16x4 is array(0 to 15) of string(1 to 4);
type t_string8x3 is array(0 to 7) of string(1 to 3);
type t_string8x5 is array(0 to 7) of string(1 to 5);
type t_string8x6 is array(0 to 7) of string(1 to 6);
type t_string4x4 is array(0 to 3) of string(1 to 4);
type t_string4x2 is array(0 to 3) of string(1 to 2);
type t_string2x2 is array(0 to 1) of string(1 to 2);
type t_string2x1 is array(0 to 1) of string(1 to 1);
constant cond_decode: t_string16x4 := ("Z   ", "CY  ", "P   ", "S   ", "AC  ", "?(5)", "?(6)", "?(7)", "INT ", "RDY ", "HOLD", "?(B)", "F3  ", "F=0 ", "CN4 ", "TRUE");
constant reg_decode: t_string16x4 :=  ("R_BC", "R_CB", "R_DE", "R_ED", "R_HL", "R_LH", "R_?A", "R_A?", "R_SP", "R_9?", "RAS1", "RBS2", "RZ38", "R38Z", "RES3", "R_PC");
constant src_decode: t_string8x3 :=  ("AQ ", "AB ", "ZQ ", "ZB ", "ZA ", "DA ", "DQ ", "DZ ");
constant fct_decode: t_string8x5 :=  ("ADD  ", "SUBR ", "SUBS ", "OR   ", "AND  ", "NOTRS", "EXOR ", "EXNOR");
constant dst_decode: t_string8x5 :=  ("QREG ", "NOP  ", "RAMA ", "RAMF ", "RAMQD", "RAMD ", "RAMQU", "RAMU ");
constant next_decode: t_string8x6 := ("C/R   ", "D/R   ", "C/SBR ", "R/RTN ", "F/SBR ", "POP/PR", "R/PUSH", "R/F   ");
constant databusenable_decode: t_string4x2 := ("--", "YL", "YH", "FL");
constant outputsteer_decode: t_string4x4 := ("----", "DATA", "ADDR", "INTE");
constant immediatedatabus_decode: t_string2x1 := ("m", "-");
constant size_decode: t_string2x2 := ("8 ", "16");
constant instregenable_decode: t_string2x1 := ("i", "-");
constant condpolarity_decode: t_string2x1 := ("-", "!");

alias a8: std_logic_vector(8 downto 0) is address(8 downto 0);


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

impure function decode_buscontrol(buscontrol: in std_logic_vector(5 downto 0)) return string is
begin
	case buscontrol is
		when "111110" => return "NOC   ";
		when "111100" => return "MEMW  ";
		when "111010" => return "MEMR  ";
		when "110110" => return "IOW   ";
		when "101110" => return "IOR   ";
		when "011110" => return "INTA  ";
		when "111111" => return "HLDA  ";
	when others => 
		return "??????";
	end case;
end decode_buscontrol;

impure function decode_reg(reg: in std_logic_vector(3 downto 0)) return string is
begin
	return reg_decode(to_integer(unsigned(reg)));
end decode_reg;

impure function decode_cond(cond: in std_logic_vector(3 downto 0)) return string is
begin
	return cond_decode(to_integer(unsigned(cond)));
end decode_cond;

impure function decode_src(src: in std_logic_vector(2 downto 0)) return string is
begin
	return src_decode(to_integer(unsigned(src)));
end decode_src;

impure function decode_fct(fct: in std_logic_vector(2 downto 0)) return string is
begin
	return fct_decode(to_integer(unsigned(fct)));
end decode_fct;

impure function decode_dst(dst: in std_logic_vector(2 downto 0)) return string is
begin
	return dst_decode(to_integer(unsigned(dst)));
end decode_dst;

impure function decode_next(nxt: in std_logic_vector(2 downto 0)) return string is
begin
	return next_decode(to_integer(unsigned(nxt)));
end decode_next;

impure function decode_databusenable(busenable: in std_logic_vector(1 downto 0)) return string is
begin
	return databusenable_decode(to_integer(unsigned(busenable)));
end decode_databusenable;

impure function decode_outputsteer(outputsteer: in std_logic_vector(1 downto 0)) return string is
begin
	return outputsteer_decode(to_integer(unsigned(outputsteer)));
end decode_outputsteer;

impure function decode_immediatedatabus(immediatedatabus: in std_logic) return string is
begin
	return immediatedatabus_decode(to_integer(unsigned'("" & immediatedatabus)));
end decode_immediatedatabus;

impure function decode_size(size: in std_logic) return string is
begin
	return size_decode(to_integer(unsigned'("" & size)));
end decode_size;

impure function decode_instregenable(instregenable: in std_logic) return string is
begin
	return instregenable_decode(to_integer(unsigned'("" & instregenable)));
end decode_instregenable;

impure function decode_condpolarity(condpolarity: in std_logic) return string is
begin
	return condpolarity_decode(to_integer(unsigned'("" & condpolarity)));
end decode_condpolarity;

procedure dump_wordmemory(out_file_name: in string; depth: in integer; temp_mem: in t_uinstruction512; base: in integer) is
    file out_file : text open write_mode is out_file_name;
    variable out_line : line;

begin
	-- dump memory content in <address> <word> format for verification
    for i in 0 to (depth - 1) loop

		  if ((i mod 32 = 0) and not ((base = 8) or (base = 16))) then
				write(out_line, string'("-----------------------------------------------------------------------------------------"));writeline(out_file, out_line);
				write(out_line, string'("     I D DIRECT-VALUE NXT    P COND B SYSCTL OE OS   A UK S C W  AADR BADR DST   FCT  SRC"));writeline(out_file, out_line);
				write(out_line, string'("-----------------------------------------------------------------------------------------"));writeline(out_file, out_line);
		  end if;

        hwrite(out_line, std_logic_vector(to_unsigned(i, 16)));
        write(out_line, string'(" ")); 
		  if (temp_mem(i) = ucode_default) then
				write(out_line, string'("(uninitialized)")); 
		  else
			  case base is
					when 2 =>
						 write(out_line, temp_mem(i)(55));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(54));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(53 downto 42));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(41 downto 39));write(out_line, string'("    "));
						 write(out_line, temp_mem(i)(38));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(37 downto 34));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(33));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(32 downto 27));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(26 downto 25));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(24 downto 23));write(out_line, string'("   "));
						 write(out_line, temp_mem(i)(22));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(21 downto 20));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(19));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(18));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(17));write(out_line, string'("  "));
						 write(out_line, temp_mem(i)(16 downto 13));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(12 downto 9));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(8 downto 6));write(out_line, string'("   "));
						 write(out_line, temp_mem(i)(5 downto 3));write(out_line, string'("   "));
						 write(out_line, temp_mem(i)(2 downto 0));
					when 8 =>
						 owrite(out_line, temp_mem(i));
					when 16 =>
						 hwrite(out_line, temp_mem(i));
					when others => -- any other value will dump microcode "mnemonics"
						 write(out_line, decode_instregenable(temp_mem(i)(55)));write(out_line, string'(" "));
						 write(out_line, decode_immediatedatabus(temp_mem(i)(54)));write(out_line, string'(" "));
						 if (unsigned(temp_mem(i)(53 downto 42)) = i) then
							write(out_line, string'("= location = "));
						 else
							write(out_line, temp_mem(i)(53 downto 42));write(out_line, string'(" "));
						 end if;
						 write(out_line, decode_next(temp_mem(i)(41 downto 39)));write(out_line, string'(" "));
						 write(out_line, decode_condpolarity(temp_mem(i)(38)));write(out_line, string'(" "));
						 write(out_line, decode_cond(temp_mem(i)(37 downto 34)));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(33));write(out_line, string'(" "));
						 write(out_line, decode_buscontrol(temp_mem(i)(32 downto 27)));write(out_line, string'(" "));
						 write(out_line, decode_databusenable(temp_mem(i)(26 downto 25)));write(out_line, string'(" "));
						 write(out_line, decode_outputsteer(temp_mem(i)(24 downto 23)));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(22));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(21 downto 20));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(19));write(out_line, string'(" "));
						 write(out_line, temp_mem(i)(18));write(out_line, string'(" "));
						 write(out_line, decode_size(temp_mem(i)(17)));write(out_line, string'(" "));
						 write(out_line, decode_reg(temp_mem(i)(16 downto 13)));write(out_line, string'(" "));
						 write(out_line, decode_reg(temp_mem(i)(12 downto 9)));write(out_line, string'(" "));
						 write(out_line, decode_dst(temp_mem(i)(8 downto 6)));write(out_line, string'(" "));
						 write(out_line, decode_fct(temp_mem(i)(5 downto 3)));write(out_line, string'(" "));
						 write(out_line, decode_src(temp_mem(i)(2 downto 0)));
			  end case;
		  end if;	 
        writeline(out_file, out_line);
    end loop;
    file_close(out_file);
end dump_wordmemory;

impure function parseHex16(hex_str: in string) return std_logic_vector is
	variable intVal: integer := 0;
begin
	--report "parseHex16(" & hex_str & ")" severity note;
	
	for i in hex_str'left to hex_str'right loop
		intVal := 16 * intVal + char2hex(hex_str(i));
	end loop;
	return std_logic_vector(to_unsigned(intVal, 16));
end parseHex16;

impure function parseBinary8(bin_str: in string) return std_logic_vector is
	variable val: std_logic_vector(7 downto 0) := "00000000";
begin
	--report "parseBinary8(" & bin_str & ")" severity note;
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


impure function init_wordmemory(input_file_name : in string; dump_file_name: in string; dump_file_base: in integer; depth: in integer; default_value: std_logic_vector(55 downto 0)) return t_uinstruction512 is
    variable temp_mem : t_uinstruction512;-- := (others => (others => default_value));
	 -- mif file variables
    file input_file : text open read_mode is input_file_name;
    variable input_line : line;
	 variable line_current: integer := 0;
	 variable line_cnt_accepted, line_cnt_ignored: integer := 0;
	 variable address: std_logic_vector(15 downto 0);
	 variable word: std_logic_vector(55 downto 0);
	 variable addr_str: string(1 to 3);
	 variable data16_str1, data16_str2, data16_str3: string(1 to 16);
	 variable data8_str: string(1 to 8);
	 variable addr_ok, data16_ok1, data16_ok2, data16_ok3, data8_ok : boolean;
	 variable firstChar: character;
 
begin
	 -- fill with default value
	 for i in 0 to depth - 1 loop	
		temp_mem(i) := default_value;
		--temp_mem(i) := std_logic_vector(to_unsigned(i, 9)) & "00000000000000000000000000000000000000000000000";
	 end loop;
	 assert false report "init_bytememory(): initialized " & integer'image(depth) & " words of memory to default value " severity note;
   	 
	 -- parse the file for the data
	 assert false report "init_bytememory(): loading memory from file " & input_file_name severity note;
	 loop 
		exit when endfile(input_file); --till the end of file is reached continue.
		line_current := line_current + 1;
      readline (input_file, input_line);
		--next when input_line'length = 0;  -- Skip empty lines
		report "init_mem(): parsing line " & integer'image(line_current) severity note;
		--report "[" & integer'image(input_line'left) & "]" severity note;
		address := X"0000";
		word := X"00000000000000";

		read(input_line, firstChar);
		--exit when endline(input_line);
		addr_ok := true;
		report "addr_str='" & firstChar & "'" severity note;
		case firstChar is
		when ';' =>
			--report "Semicolon detected, line is treated as comment" severity note;
			line_cnt_ignored := line_cnt_ignored + 1;
		when '0' to '9' | 'A' to 'F' =>
			read(input_line, addr_str, addr_ok);
			read(input_line, data16_str1, data16_ok1);
			read(input_line, data16_str2, data16_ok2);
			read(input_line, data16_str3, data16_ok3);
			read(input_line, data8_str, data8_ok);
			--if (addr_ok and data16_ok1 and data16_ok2 and data16_ok3 and data8_ok) then
				address := parseHex16(firstChar & addr_str);
				word := parseBinary16(data16_str1) & parseBinary16(data16_str2) & parseBinary16(data16_str3) & parseBinary8(data8_str);

				temp_mem(to_integer(unsigned(address))) := word;
				line_cnt_accepted := line_cnt_accepted + 1;
				report "init_bytememory(): line " & integer'image(line_current) & " parsed and accepted for address " & integer'image(to_integer(unsigned(address))) severity note;
			--else
			--	report "init_bytememory(): line " & integer'image(line_current) & " is ignored due to missing data" severity note;
			--	line_cnt_ignored := line_cnt_ignored + 1;
			--end if;
		when others =>
			report "init_bytememory(): line " & integer'image(line_current) & " is ignored due to unrecognized 1st char" severity note;
			line_cnt_ignored := line_cnt_ignored + 1;
		end case;
	end loop; -- next line in file

	file_close(input_file);

	report "init_bytememory(): " & integer'image(line_cnt_accepted) & " total lines parsed and accepted from file " & input_file_name severity note;
	report "init_bytememory(): " & integer'image(line_cnt_ignored) & " total lines parsed and ignored from file " & input_file_name severity note;
   
	dump_wordmemory(dump_file_name, depth, temp_mem, dump_file_base);

   return temp_mem;  	
end init_wordmemory;

constant data_from_file: t_uinstruction512 := init_wordmemory("./prom/microcode.mif", "./prom/microcode.lst", 0, 512, uCode_default);
--constant data_from_file: rom_array := init_wordmemory("./prom/microcode.mif", "./prom/microcode.hex", 2, 512, uCode_default);

constant data_from_inline: t_uinstruction512 :=
(
	0 => uCode_nop, 
	others => uCode_nop
);

begin
	data <= data_from_file(to_integer(unsigned(a8)));

end Behavioral;

