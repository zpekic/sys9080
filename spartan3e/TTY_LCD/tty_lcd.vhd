----------------------------------------------------------------------------------
-- Company: 
-- Engineer: zpekic@hotmail.com
-- 
-- Create Date:    20:40:14 05/10/2020 
-- Design Name: 
-- Module Name:    tty_screen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: https://hackaday.io/project/182959-custom-circuit-testing-using-intel-hex-files/log/201614-micro-coded-controller-deep-dive
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

use work.tty_screen_code.all;
use work.tty_screen_map.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tty_screen is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
			  enable: in STD_LOGIC;
			  ---
           char : in  STD_LOGIC_VECTOR (7 downto 0);
			  char_sent: out STD_LOGIC;
			  ---
			  maxRow: in STD_LOGIC_VECTOR (7 downto 0);
			  maxCol: in STD_LOGIC_VECTOR (7 downto 0);
           mrd : out  STD_LOGIC;
           mwr : out  STD_LOGIC;
           x : out  STD_LOGIC_VECTOR (7 downto 0);
           y : out  STD_LOGIC_VECTOR (7 downto 0);
			  mready: in STD_LOGIC;
           din : in  STD_LOGIC_VECTOR (7 downto 0);
           dout : out  STD_LOGIC_VECTOR (7 downto 0);
			  
			  -- not part of real device, used for debugging
           debug : out  STD_LOGIC_VECTOR (31 downto 0)
			  
          );
end tty_screen;

architecture Behavioral of tty_screen is

component tty_control_unit is
	 Generic (
			CODE_DEPTH : positive;
			IF_WIDTH : positive
			);
    Port ( 
			  reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           seq_cond : in  STD_LOGIC_VECTOR (IF_WIDTH - 1 downto 0);
           seq_then : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           seq_else : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           seq_fork : in  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           cond : in  STD_LOGIC_VECTOR (2 ** IF_WIDTH - 1 downto 0);
           ui_nextinstr : buffer  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0);
           ui_address : out  STD_LOGIC_VECTOR (CODE_DEPTH - 1 downto 0));
end component;

-- registers
signal cursorx, cursory: std_logic_vector(7 downto 0);
signal data: std_logic_vector(7 downto 0);

-- conditions
signal char_is_zero: std_logic;
signal cursorx_is_zero, cursory_is_zero : std_logic;
signal cursorx_ge_maxcol, cursory_ge_maxrow: std_logic;

-- microcontrol related
signal ui_address, ui_nextinstr: std_logic_vector(CODE_ADDRESS_WIDTH - 1 downto 0);

signal ready: std_logic;

begin

-- debug port
--debug <= "00010101" & data & char & "00" & ui_address;
--debug <= "00000" & tty_uinstruction;
debug <= cursory & cursorx & data & "00" & ui_address;

-- conditions
--char_is_zero <= '1' when (char = X"00") else '0';	
char_is_zero <= '1' when (char = X"00") else (not enable);	
cursorx_ge_maxcol <= '0' when (unsigned(cursorx) < unsigned(maxcol)) else '1';	
cursory_ge_maxrow <= '0' when (unsigned(cursory) < unsigned(maxrow)) else '1';
cursorx_is_zero <= '1' when (cursorx = X"00") else '0';
cursory_is_zero <= '1' when (cursory = X"00") else '0';

-- control unit
tty_uinstruction <= tty_microcode(to_integer(unsigned(ui_address)));
tty_instructionstart <= tty_mapper(to_integer(unsigned(data(MAPPER_ADDRESS_WIDTH - 1 downto 0))));

cu: tty_control_unit
		generic map (
			CODE_DEPTH => CODE_ADDRESS_WIDTH,
			IF_WIDTH => CODE_IF_WIDTH
		)
		port map (
			-- inputs
			reset => reset,
			clk => clk,
			seq_cond => tty_seq_cond,
			seq_then => tty_seq_then,
			seq_else => tty_seq_else,
			seq_fork => tty_instructionstart,
			cond(seq_cond_true) => '1',
			--cond(seq_cond_char_is_zero) => (char_is_zero or (not enable)),
			cond(seq_cond_char_is_zero) => char_is_zero,
			cond(seq_cond_cursorx_ge_maxcol) => cursorx_ge_maxcol,	
			cond(seq_cond_cursory_ge_maxrow) => cursory_ge_maxrow,	
			cond(seq_cond_cursorx_is_zero) => cursorx_is_zero,	
			cond(seq_cond_cursory_is_zero) => cursory_is_zero,	
			cond(seq_cond_memory_ready) => mready,
			cond(seq_cond_false) => '0',
			-- outputs
			ui_nextinstr => ui_nextinstr, -- NEXT microinstruction to be executed
			ui_address => ui_address	-- address of CURRENT microinstruction

		);

char_sent <= ready;

with tty_ready select ready <=
			'1' when ready_yes,
			(char_is_zero or (not enable)) when ready_char_is_zero,
			'0' when others;
				
-- memory interface
mwr <= tty_mem(1);
mrd <= tty_mem(0);

x <= cursorx;
y <= cursory;

dout <= data;

-- data from or to memory
update_data: process(clk, tty_data, char, din)
begin
	if (rising_edge(clk)) then
		case tty_data is
			when data_char =>
				data <= char;
			when data_memory =>
				data <= din;
			when data_space =>
				data <= X"20";
			when others =>
				null;
		end case;
	end if;
end process;

-- cursor registers
update_cursorx: process(clk, tty_cursorx, cursorx, maxcol)
begin
	if (rising_edge(clk)) then
		case tty_cursorx is
			when cursorx_zero =>
				 cursorx <= X"00";
			when cursorx_inc =>
				 cursorx <= std_logic_vector(unsigned(cursorx) + 1);
			when cursorx_dec =>
				 cursorx <= std_logic_vector(unsigned(cursorx) - 1);
			when cursorx_maxcol =>
				 cursorx <= maxcol;
			when others =>
				null;
		end case;
	end if;
end process;

update_cursory: process(clk, tty_cursory, cursory, maxrow)
begin
	if (rising_edge(clk)) then
		case tty_cursory is
			when cursory_zero =>
				 cursory <= X"00";
			when cursory_inc =>
				 cursory <= std_logic_vector(unsigned(cursory) + 1);
			when cursory_dec =>
				 cursory <= std_logic_vector(unsigned(cursory) - 1);
			when cursory_maxrow =>
				 cursory <= maxrow;
			when others =>
				null;
		end case;
	end if;
end process;
					
end Behavioral;

