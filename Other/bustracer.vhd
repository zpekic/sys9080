----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:36:11 02/17/2019 
-- Design Name: 
-- Module Name:    bustracer - Behavioral 
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

entity bustracer is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           nSel : in  STD_LOGIC;
           nMemRead : in  STD_LOGIC;
           nMemWrite : in  STD_LOGIC;
           nIORead : in  STD_LOGIC;
           nIOWrite : in  STD_LOGIC;
           M1 : in  STD_LOGIC;
           IntReq : in  STD_LOGIC;
           nIntAck : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (15 downto 0);
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
			  ready: buffer STD_LOGIC;
           tx_active : out  STD_LOGIC;
           tx_clock : in  STD_LOGIC;
           tx_data : out  STD_LOGIC;
			  debug: out STD_LOGIC_VECTOR(27 downto 0));
end bustracer;

architecture Behavioral of bustracer is

component mux16to4 is
    Port ( x3 : in  STD_LOGIC_VECTOR (3 downto 0);
           x2 : in  STD_LOGIC_VECTOR (3 downto 0);
           x1 : in  STD_LOGIC_VECTOR (3 downto 0);
           x0 : in  STD_LOGIC_VECTOR (3 downto 0);
           sel : in  STD_LOGIC_VECTOR (1 downto 0);
			  nEnable : in  STD_LOGIC;
			  ascii: in STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

type rom16x8 is array(0 to 15) of std_logic_vector(7 downto 0);
type rom8x16 is array(0 to 7) of std_logic_vector(15 downto 0);
type ram32x8 is array(0 to 7) of std_logic_vector(31 downto 0);
--
constant line: rom16x8 := 
	(
        0 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8)),
        1 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
        2 => "10011000",	-- a3
        3 => "10010000",	-- a2
        4 => "10001000",	-- a1
        5 => "10000000",	-- a0
        6 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
        7 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('D'), 8)),
        8 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('='), 8)),
        9 =>  "10101000",	-- d1
		  10 => "10100000",	-- d0
        --11 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)),
        11 => "11000000",	-- id1
		  12 => "11100000",	-- id0
		  13 => "10110000",	-- d2 (== "Sanitized ascii")
		  14 => X"0D",	-- CR
		  15 => X"0A"	-- LF
   );
	
constant busid: rom8x16 :=
	(
        0 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8)),
        1 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8)),
        2 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8)),
        3 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8)),
        4 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('F'), 8)),
        5 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('I'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8)),
        6 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)),
        7 => STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8))
	);

signal traceConfig: ram32x8;
signal configSel: std_logic_vector(2 downto 0);
signal configRead, configWrite: std_logic;
signal configValue: std_logic_vector(31 downto 0);
alias fromAddress: std_logic_vector(15 downto 0) is configValue(15 downto 0); 
alias toAddress: std_logic_vector(15 downto 0) is configValue(31 downto 16); 

--signal fromAddress: std_logic_vector(15 downto 0) := X"0000";
--signal   toAddress: std_logic_vector(15 downto 0) := X"FFFF";

signal d_out: std_logic_vector(7 downto 0);

signal runSequence, trace_done, forceReady, clearReady: std_logic;

signal sequenceCnt: std_logic_vector(7 downto 0) := X"00";
alias charSel: std_logic_vector(3 downto 0) is sequenceCnt(7 downto 4);
alias bitSel: std_logic_vector(3 downto 0) is sequenceCnt(3 downto 0);

signal dataread, fetch: std_logic;
signal busstate: std_logic_vector(2 downto 0);
signal busvector: std_logic_vector(7 downto 0);
signal busstring: std_logic_vector(15 downto 0);
signal rawChar, addressChar, dataChar, txChar, sanitized_ascii: std_logic_vector(7 downto 0);

type state is (st_reset, 			--0
					st_readytostart, 	--1
					st_memread,			--2
					st_memwrite,		--3
					st_ioread,			--4	
					st_iowrite,			--5
					st_fetch,			--6
					st_intack,			--7
					st_comparefrom,	--8
					st_compareto,		--9
					st_checkdone,		--A
					st_done				--B
					);
					
signal state_current, state_next: state;

begin

-- reading and writing configuration RAM
configRead <= not (nSel or nMemRead);
configWrite <= not (nSel or nMemWrite);

configSel <= A(4 downto 2) when (configRead = '1' or configWrite = '1') else busstate;
configValue <= traceConfig(to_integer(unsigned(configSel)));

with A(1 downto 0) select
	d_out <= configValue(7 downto 0) when "00",
				configValue(15 downto 8) when "01",
				configValue(23 downto 16) when "10",
				configValue(31 downto 24) when others;
D <= d_out when configRead = '1' else "ZZZZZZZZ";

updateConfig: process(clk, configWrite, traceConfig, configValue)
begin
	if (falling_edge(clk) and configWrite = '1') then
		case A(1 downto 0) is
			when "00" =>
				traceConfig(to_integer(unsigned(configSel))) <= configValue(31 downto 8) & D;
			when "01" =>
				traceConfig(to_integer(unsigned(configSel))) <= configValue(31 downto 16) & D & configValue(7 downto 0);
			when "10" =>
				traceConfig(to_integer(unsigned(configSel))) <= configValue(31 downto 24) & D & configValue(15 downto 0);
			when "11" =>
				traceConfig(to_integer(unsigned(configSel))) <= D & configValue(23 downto 0);
			when others =>
				null;
		end case;
	end if;
end process;

busvector <= nMemRead & nMemWrite & nIoRead & nIoWrite & M1 & nIntAck & configRead & configWrite;
debug <= "00000" & busstate & std_logic_vector(to_unsigned(state'POS(state_current), 4)) & busvector & sequenceCnt;

forceReady <= '1' when (enable = '0') else (reset or trace_done or configRead or configWrite);
--clearReady <= clk or not(nMemRead and nMemRead and nIoRead and nIoWrite and (not M1) and nIntAck);
clearReady <= nMemRead and nMemRead and nIoRead and nIoWrite and (not M1) and nIntAck;

generateReady: process(forceReady, clearReady, clk)
begin
	if (forceReady = '1') then
		ready <= '1';
	else
--		if (rising_edge(clearReady)) then
--			ready <= '0';
--		end if;
		if (falling_edge(clk)) then
			ready <= clearReady;
		end if;
	end if;
end process;

generateSequence: process(reset, ready, tx_clock, state_current)
begin
	if (state_current = st_done) then
		trace_done <= '1';
	else
		if (reset = '1' or runSequence = '0') then
			sequenceCnt <= X"00";
			trace_done <= '0';
		else
			if (rising_edge(tx_clock)) then
				if (sequenceCnt = X"FF") then
					trace_done <= '1';
				else
					trace_done <= '0';
					sequenceCnt <= std_logic_vector(unsigned(sequenceCnt) + 1);
				end if;
			end if;
		end if;
	end if;
end process;

-- character output mux path
rawChar <= line(to_integer(unsigned(charSel)));

amux: mux16to4 port map (
			x3 => A(15 downto 12),
         x2 => A(11 downto 8),
         x1 => A(7 downto 4),
         x0 => A(3 downto 0),
         sel => rawChar(4 downto 3),
			nEnable => '0',
			ascii => '1',
         y => addressChar
);

dmux: mux16to4 port map (
			x3 => X"0",
         x2 => X"0",
         x1 => D(7 downto 4),
         x0 => D(3 downto 0),
         sel => rawChar(4 downto 3),
			nEnable => '0',
			ascii => '1',
         y => dataChar
);

sanitized_ascii <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(' '), 8)) when (D(7 downto 5) = "000" or D(7) = '1' or D = X"7F") else D;
busstring <= busid(to_integer(unsigned(busstate)));

with rawChar(7 downto 4) select
	txChar <= 	addressChar 				when "1000",
					addressChar 				when "1001",
					dataChar 					when "1010",
					sanitized_ascii 			when "1011",
					busstring(15 downto 8) 	when "1100",
					busstring(15 downto 8)	when "1101",
					busstring(7 downto 0)	when "1110",
					busstring(7 downto 0)	when "1111",
					rawChar when others;
				
-- bit output mux path
tx_active <= '0' when (sequenceCnt = X"00") else '1';

with bitSel select 
		tx_data <= 	'1'		 when "0000", -- delay 0
						'1'		 when "0001",
						'1'		 when "0010",
						'1' 		 when "0011", -- delay 3
						'0' 		 when "0100", -- start bit
						txChar(0) when "0101", -- data
						txChar(1) when "0110",
						txChar(2) when "0111",
						txChar(3) when "1000",
						txChar(4) when "1001",
						txChar(5) when "1010",
						txChar(6) when "1011",
						txChar(7) when "1100",
						'1' 		 when "1101",	-- stop
						'1' 		 when "1110",	-- additional stop or parity
						'1' when others;			-- delay
						

drive: process(reset, clk, state_next)
begin
	if (reset = '1') then
		state_current <= st_reset;
	else
		if (rising_edge(clk)) then
			state_current <= state_next;
		end if;
	end if;
end process;

execute: process(clk, state_current)
begin
	if (rising_edge(clk)) then
		case state_current is
		
			when st_reset =>
				runSequence <= '0';

			when st_readytostart =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('?'), 8));
				busstate <= "111";
				
			when st_memread =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8));
				busstate <= "000";

			when st_memwrite =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8));
				busstate <= "001";

			when st_ioread =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('R'), 8));
				busstate <= "010";

			when st_iowrite =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('P'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('W'), 8));
				busstate <= "011";

			when st_fetch =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('M'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('F'), 8));
				busstate <= "100";

			when st_intack =>
				runSequence <= '0';
				--busstring <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('I'), 8)) & STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS('A'), 8));
				busstate <= "101";

			when st_comparefrom =>
				runSequence <= '0';
			
			when st_compareto =>
				runSequence <= '0';
			
			when st_checkdone =>
				runSequence <= '1';
				
			when st_done =>
				runSequence <= '0';
					
		end case;
	end if;
end process;

sequence: process(state_current, busvector, trace_done) 
begin
	case state_current is

		when st_reset =>
			state_next <= st_readytostart;

		when st_readytostart =>
			--busvector <= nMemRead & nMemWrite & nIoRead & nIoWrite & M1 & nIntAck & configRead & configWrite;
			if (ready = '0') then
				case busvector is
					when "01110100" =>	--74
						state_next <= st_memread;
					when "10110100" =>	--B4
						state_next <= st_memwrite;
					when "11010100" =>	--D4
						state_next <= st_ioread;
					when "11100100" =>	--E4
						state_next <= st_iowrite;
					when "01111100" =>	--7C
						state_next <= st_fetch;
					when "11111000" =>	--F8
						state_next <= st_intack;
					when others =>
						state_next <= st_done;
				end case;
			else
				state_next <= st_readytostart;
			end if;
			
		when st_memread =>
			state_next <= st_comparefrom;

		when st_memwrite =>
			state_next <= st_comparefrom;

		when st_ioread =>
			state_next <= st_comparefrom;

		when st_iowrite =>
			state_next <= st_comparefrom;

		when st_fetch =>
			state_next <= st_comparefrom;

		when st_intack =>
			state_next <= st_comparefrom;

		when st_comparefrom =>
			if (unsigned(A) < unsigned(fromAddress)) then
				state_next <= st_done;
			else
				state_next <= st_compareto;
			end if;

		when st_compareto =>
			if (unsigned(A) > unsigned(toAddress)) then
				state_next <= st_done;
			else
				state_next <= st_checkdone;
			end if;
			
		when st_checkdone =>
			if (trace_done = '1') then
				state_next <= st_done;
			else
				state_next <= st_checkdone;
			end if;
			
		when st_done =>
			state_next <= st_readytostart;
			
	end case;
end process;

end Behavioral;

