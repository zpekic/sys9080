----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:37:53 05/19/2019 
-- Design Name: 
-- Module Name:    sio0800 - Behavioral 
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
--use work.tms0800_package.all;

entity vio0800_microcode is
	 generic (maxrow: integer;
				 maxcol: integer);
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
			  enable: in STD_LOGIC;
           char : in  STD_LOGIC_VECTOR (7 downto 0);
           char_sent : out STD_LOGIC;
			  cr_is_lf: in STD_LOGIC;
			  busy_in: in STD_LOGIC;
			  busy_out: out STD_LOGIC;
			  we : out STD_LOGIC;
			  din: in STD_LOGIC_VECTOR(7 downto 0);
			  dout: buffer STD_LOGIC_VECTOR(7 downto 0);
			  x: out STD_LOGIC_VECTOR(7 downto 0);
			  y: out STD_LOGIC_VECTOR(7 downto 0));
end vio0800_microcode;

architecture Behavioral of vio0800_microcode is

-- special microcode "goto" codes (all others will be jump to that location)
constant upc_next:   std_logic_vector(7 downto 0) := X"00"; -- means we can't jump to location 0!
constant upc_return: std_logic_vector(7 downto 0) := X"01"; -- means we can't jump to location 1!
constant upc_repeat: std_logic_vector(7 downto 0) := X"FF"; -- means we can't jump to location 255!
constant upc_fork:   std_logic_vector(7 downto 0) := X"FE"; -- means we can't jump to location 254!

constant char_NULL: std_logic_vector(7 downto 0) := X"00";
constant char_CLEAR: std_logic_vector(7 downto 0) := X"01";
constant char_HOME: std_logic_vector(7 downto 0) := X"02";
constant char_CR: std_logic_vector(7 downto 0) := X"0D";
constant char_LF: std_logic_vector(7 downto 0) := X"0A";

-- define and initialize microcode
type rom64x32 is array(0 to 31) of std_logic_vector(31 downto 0);
constant nop: std_logic_vector(31 downto 0) := X"00000000";

-- microinstruction fields and setter functions
signal u_instruction: std_logic_vector(31 downto 0);

-- CCCCTTTTTTTTEEEEEEEE............
alias u_if: 	std_logic_vector(3 downto 0) is u_instruction(31 downto 28);
alias u_then: 	std_logic_vector(7 downto 0) is u_instruction(27 downto 20);
alias u_else: 	std_logic_vector(7 downto 0) is u_instruction(19 downto 12);
constant cond_true 			: std_logic_vector(3 downto 0) := X"0";			-- 0
constant cond_char0 			: std_logic_vector(3 downto 0) := X"1";
constant cond_charcontrol 	: std_logic_vector(3 downto 0) := X"2";
constant cond_busyin 		: std_logic_vector(3 downto 0) := X"3";
constant cond_row0 			: std_logic_vector(3 downto 0) := X"4";
constant cond_row49 			: std_logic_vector(3 downto 0) := X"5";
constant cond_col0 			: std_logic_vector(3 downto 0) := X"6";
constant cond_col79 			: std_logic_vector(3 downto 0) := X"7";
constant cond_charcr 		: std_logic_vector(3 downto 0) := X"8";		
constant cond_charlf 		: std_logic_vector(3 downto 0) := X"9";			
constant cond_charhome 		: std_logic_vector(3 downto 0) := X"A";
constant cond_charcls 		: std_logic_vector(3 downto 0) := X"B";
constant cond_cr_is_lf 		: std_logic_vector(3 downto 0) := X"C";			
constant cond_13 				: std_logic_vector(3 downto 0) := X"D";			-- not used
constant cond_14 				: std_logic_vector(3 downto 0) := X"E";			-- not used
constant cond_false 			: std_logic_vector(3 downto 0) := X"F";			-- 15
impure function uc_if(cond: in std_logic_vector(3 downto 0); goto_then: in std_logic_vector(7 downto 0); goto_else: in std_logic_vector(7 downto 0)) return std_logic_vector is
begin
	return cond & goto_then & goto_else & nop(11 downto 0);
end uc_if;

--- ............CCCCCCCC............
alias u_constant: std_logic_vector(7 downto 0) is u_instruction(19 downto 12); -- reuse u_else field!
impure function uc_constant(val: in std_logic_vector(7 downto 0)) return std_logic_vector is
begin
	return uc_if(cond_true, upc_next, val);
end uc_constant;

alias u_mem: 	std_logic_vector(1 downto 0) is u_instruction(11 downto 10);
constant mem_read: std_logic_vector(1 downto 0) := "10";
constant mem_write: std_logic_vector(1 downto 0) := "11";
impure function uc_mem(mem: in std_logic_vector(1 downto 0)) return std_logic_vector is
begin
	return nop(31 downto 12) & mem & nop(9 downto 0);
end uc_mem;

alias u_dout: 	std_logic_vector(1 downto 0) is u_instruction(9 downto 8);
constant dout_constant: std_logic_vector(1 downto 0) := "01";
constant dout_din: 		std_logic_vector(1 downto 0) := "10";
constant dout_char: 		std_logic_vector(1 downto 0) := "11";
impure function uc_dout(dout: in std_logic_vector(1 downto 0)) return std_logic_vector is
begin
	return nop(31 downto 10) & dout & nop(7 downto 0);
end uc_dout;

alias u_row: 	std_logic_vector(1 downto 0) is u_instruction(7 downto 6);
constant row_constant: 	std_logic_vector(1 downto 0) := "01";
constant row_inc: 		std_logic_vector(1 downto 0) := "10";
constant row_dec: 		std_logic_vector(1 downto 0) := "11";
impure function uc_row(row: in std_logic_vector(1 downto 0)) return std_logic_vector is
begin
	return nop(31 downto 8) & row & nop(5 downto 0);
end uc_row;

alias u_col: 	std_logic_vector(1 downto 0) is u_instruction(5 downto 4);
constant col_constant: 	std_logic_vector(1 downto 0) := "01";
constant col_inc: 		std_logic_vector(1 downto 0) := "10";
constant col_dec: 		std_logic_vector(1 downto 0) := "11";
impure function uc_col(col: in std_logic_vector(1 downto 0)) return std_logic_vector is
begin
	return nop(31 downto 6) & col & nop(3 downto 0);
end uc_col;

alias u_charsent: std_logic is u_instruction(3);
impure function uc_charsent return std_logic_vector is
begin
	return nop(31 downto 4) & '1' & nop(2 downto 0);
end uc_charsent;

alias u_unused: std_logic_vector(2 downto 0) is u_instruction(2 downto 0);

-- helper functions ------------------------------
impure function uc_label(destination: integer) return std_logic_vector is
begin
	return std_logic_vector(to_unsigned(destination, 8));
end uc_label;

impure function uc_goto(dest: in std_logic_vector(7 downto 0)) return std_logic_vector is
begin
	return uc_if(cond_true, dest, X"00");
end uc_goto;

impure function uc_call(dest: in std_logic_vector(7 downto 0)) return std_logic_vector is
begin
	return uc_goto(dest); -- there is an automatic 1-level deep "stack" so goto = call
end uc_call;

impure function uc_nop return std_logic_vector is
begin
	return nop;
end uc_nop;

constant RESTART: integer := 0;
constant WAIT4CHAR: integer := 2;
constant PRINT: integer := 8;
constant LF: integer := 11;
constant CR: integer :=12;
constant SCROLL: integer := 13;
constant CLS: integer := 20;
constant HOME: integer := 25;
constant DONE: integer := 26;
constant WRITEMEM: integer := 28;
constant READMEM: integer := 30;

impure function init_microcode(dump_file_name: in string) return rom64x32 is
    variable temp_mem: rom64x32 := 
	 (
		RESTART =>	-- start microcode execution (note: this location can't be used as jump target as reserved for "next")
			uc_constant(X"00") or
			uc_row(row_constant) or
			uc_col(col_constant),
		
		1 =>	-- this is a no-jump location
			uc_nop,
			
		WAIT4CHAR =>  -- wait for non-zero character (note: this location can't be used as jump target as reserved for "return")
			uc_if(cond_char0, upc_repeat, upc_next),
			
		3 => 
			uc_if(cond_charcontrol, upc_next, uc_label(PRINT)),
			
		4 =>
			uc_if(cond_charcr, uc_label(CR), upc_next), 

		5 =>
			uc_if(cond_charlf, uc_label(LF), upc_next), 

		6 =>
			uc_if(cond_charhome, uc_label(HOME), upc_next), 

		7 =>
			uc_if(cond_charcls, uc_label(CLS), upc_next),
			
		PRINT =>
			uc_dout(dout_char) or
			uc_call(uc_label(WRITEMEM)),
			
		9 =>
			uc_col(col_inc) or
			uc_if(cond_col79, upc_next, uc_label(DONE)),
			
		10 =>
			uc_constant(X"00") or
			uc_col(col_constant),
					
		LF =>	-- LF
			uc_row(row_inc) or
			uc_if(cond_row49, uc_label(SCROLL), uc_label(DONE)), 
			--uc_if(cond_row49, uc_label(SCROLL), uc_label(CR)), 
			
		CR => -- CR
			uc_constant(X"00") or
			uc_col(col_constant) or 
			uc_if(cond_cr_is_lf, uc_label(LF), uc_label(DONE)),
			
		SCROLL =>	-- SCROLL UP
			uc_constant(X"00") or
			uc_row(row_constant), 
			
		14 => 
			uc_constant(X"00") or
			uc_col(col_constant), 

		15 => 
			uc_call(uc_label(READMEM)),
			
		16 => 
			uc_call(uc_label(WRITEMEM)),

		17 => 
			uc_col(col_inc) or
			uc_if(cond_col79, upc_next, uc_label(15)),

		18 => 
			uc_row(row_inc) or
			uc_if(cond_row49, upc_next, uc_label(14)), 

		19 => 
			uc_constant(std_logic_vector(to_unsigned(maxrow - 1, 8))) or
			uc_row(col_constant) or 
			uc_goto(uc_label(CR)),

		CLS =>	-- CLEAR SCREEN
			uc_constant(X"00") or	
			uc_row(row_constant), 
			
		21 => 
			uc_constant(X"00") or
			uc_col(col_constant), 
			
		22 => 
			uc_constant(X"20") or	-- fill screen with whitespace chars
			uc_dout(dout_constant) or
			uc_call(uc_label(WRITEMEM)),

		23 => 
			uc_col(col_inc) or
			uc_if(cond_col79, upc_next, uc_label(22)),

		24 => 
			uc_row(row_inc) or
			uc_if(cond_row49, upc_next, uc_label(21)), 

		HOME => 
			uc_constant(X"00") or
			uc_row(row_constant) or
			uc_col(col_constant),

		DONE =>
			uc_charsent,
			--uc_if(cond_busyin, upc_repeat, upc_next),
			
		27 =>
			uc_charsent or
			uc_if(cond_char0, uc_label(WAIT4CHAR), uc_label(DONE)),

		WRITEMEM => -- wait until bus access free (in vertical sync)
			uc_mem(mem_write) or
			uc_if(cond_busyin, upc_repeat, upc_next),
			
		29 => -- write dout reg
			uc_mem(mem_write) or
			uc_goto(upc_return),
			
		READMEM => -- wait until bus access free (in vertical sync)
			uc_mem(mem_read) or
			uc_dout(dout_din) or
			uc_if(cond_busyin, upc_repeat, upc_next),

		31 => -- read into dout
			uc_mem(mem_read) or
			uc_dout(dout_din) or
			uc_goto(upc_return),
		
		others =>
			uc_nop
	 );


begin
	-- return for runtime
	return temp_mem;
end init_microcode;

-- initialize microcode
constant u_code: rom64x32 := init_microcode("");
--attribute ram_style: string;
--attribute ram_style of u_code : signal is "block";

-- internal registers
signal row, col: std_logic_vector(7 downto 0);
signal u_pc, u_ra, u_next: std_logic_vector(7 downto 0);
signal data: std_logic_vector(7 downto 0);

-- conditions
signal u_condition: std_logic;
signal row0, row49: std_logic;
signal col0, col79: std_logic;
signal char0, charcontrol, charcr, charlf, charcls, charhome: std_logic;

begin

u_instruction <= u_code(to_integer(unsigned(u_pc(5 downto 0))));

-- various conditions
row0 <= '1' when (unsigned(row) = 0) else '0';
row49 <= '1' when (unsigned(row) = (maxrow - 1)) else '0';
col0 <= '1' when (unsigned(col) = 0) else '0';
col79 <= '1' when (unsigned(col) = (maxcol - 1)) else '0';
char0 <= '1' when (char = char_NULL) else (not enable);
charcontrol <= '1' when (char(7 downto 5) = "000") else '0'; -- ASCII 0x00 - 0x1F
charcr <= '1' when (char = char_CR) else '0';
charlf <= '1' when (char = char_LF) else '0';
charcls <= '1' when (char = char_CLEAR) else '0';
charhome <= '1' when (char = char_HOME) else '0';

-- select condition code
with u_if select
	u_condition <= '1' 			when cond_true,			-- 0
						char0			when cond_char0,
						charcontrol when cond_charcontrol,
						busy_in 		when cond_busyin,
						row0  		when cond_row0,
						row49  		when cond_row49,
						col0  		when cond_col0,
						col79  		when cond_col79,
						charcr or (cr_is_lf and charlf) when cond_charcr,		
						charlf 		when cond_charlf,			
						charhome 	when cond_charhome,		
						charcls 		when cond_charcls,		
						cr_is_lf 	when cond_cr_is_lf,			
						'0' 			when cond_13,				-- not used
						'0' 			when cond_14,				-- not used
						'0' 			when cond_false;			-- 15

-- select then or else part
u_next <= u_then when (u_condition = '1') else u_else;

-- update microcode program counter
update_upc: process(clk, reset, u_next)
begin
	if (reset = '1') then
		-- start execution at location 0
		u_pc <= X"00";
		u_ra <= X"00";
	else
		if (rising_edge(clk)) then
			case u_next is
				-- if condition(0) = '1' then X"00000" (default) will cause simple u_pc advance
				when upc_next =>
					u_pc <= std_logic_vector(unsigned(u_pc) + 1);
				-- used to repeat same microinstruction until condition turns true
				when upc_repeat =>
					u_pc <= u_pc;
				-- not used
				--when upc_fork => 
				--	u_pc <= '1' & instruction;
				-- return from "1 level subroutine"
				when upc_return => 
					u_pc <= u_ra;
				-- any other value is a jump to that microinstruction location, save return address for "1 level stack"
				when others =>
					u_pc <= u_next;
					u_ra <= std_logic_vector(unsigned(u_pc) + 1);
			end case;
		end if;
	end if;
end process;  

-- update dout
update_dout: process(clk, u_dout, u_constant, char, din, col)
begin
	if (rising_edge(clk)) then
		case u_dout is
			when dout_constant =>
				dout <= u_constant;
			when dout_din =>
				dout <= din;
			when dout_char =>
				dout <= char;
			when others =>
				dout <= dout;
		end case;
	end if;
end process;

-- update row
update_row: process(clk, u_row, row, u_constant)
begin
	if (rising_edge(clk)) then
		case u_row is
			when row_constant =>
				row <= u_constant;
			when row_inc =>
				row <= std_logic_vector(unsigned(row) + 1);
			when row_dec =>
				row <= std_logic_vector(unsigned(row) - 1);
			when others =>
				row <= row;
		end case;
	end if;
end process;

-- update row
update_col: process(clk, u_col, col)
begin
	if (rising_edge(clk)) then
		case u_col is
			when col_constant =>
				col <= u_constant;
			when col_inc =>
				col <= std_logic_vector(unsigned(col) + 1);
			when col_dec =>
				col <= std_logic_vector(unsigned(col) - 1);
			when others =>
				col <= col;
		end case;
	end if;
end process;

-- drive output ready signal
char_sent <= u_charsent;
--drivesent: process(reset, char0, u_charsent)
--begin
--	if ((char0 or reset) = '1') then
--		char_sent <= '0';
--	else
--		if (rising_edge(u_charsent)) then
--			char_sent <= '1';
--		end if;
--	end if;
--end process;

-- direct output signals
busy_out <= u_mem(1);
we <= u_mem(0);
x <= col;
y <= row when (u_mem(0) = '1') else std_logic_vector(unsigned(row) + 1); -- always read from the row below

end Behavioral;

