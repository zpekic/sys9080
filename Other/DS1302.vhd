----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:16:23 02/23/2019 
-- Design Name: 
-- Module Name:    DS1302 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: https://www.parallax.com/sites/default/files/downloads/29125-DS1302-RTC-Module-Guide-v1.0.pdf
--					 https://datasheets.maximintegrated.com/en/ds/DS1302.pdf
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

entity DS1302 is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           nSel : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (5 downto 0);
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
			  Ready: buffer STD_LOGIC;
           CE : buffer  STD_LOGIC;
           SCLK : buffer  STD_LOGIC;
           IO : inout  STD_LOGIC;
			  debug: out STD_LOGIC_VECTOR(27 downto 0)
			);
end DS1302;

architecture Behavioral of DS1302 is

type state is (st_reset, 			--0
					st_readytostart, 	--1
					st_startread,		--2
					st_startwrite,		--3
					st_write16,			--4
					st_write8,			--5
					st_read8,			--6
					st_done				--7
					);
					
signal state_current, state_next: state;

signal count: std_logic_vector(3 downto 0);
signal nReadAccess, nWriteAccess: std_logic := '1';
signal driveIO, SCLK_enable: std_logic;
signal continue: std_logic;
signal readyState: std_logic_vector(1 downto 0);
alias readReady: std_logic is readyState(1);
alias writeReady: std_logic is readyState(0);
signal inputByte: std_logic_vector(7 downto 0);
signal controlword: std_logic_vector(15 downto 0);
alias dout: std_logic is controlword(0);		-- LSB goes out first!
signal clk2, clk2delayed: std_logic_vector(3 downto 0);
alias fsmclk: std_logic is clk2(3);

begin
--
--X"0" & "0000",
--X"0" & "0010",
--X"0" & "0011",
--X"1" & "0010",
--X"1" & "0011",
--X"2" & "0010",
--X"2" & "0011",
--X"3" & "0010",
--X"3" & "0011",
--X"4" & "0010",
--X"4" & "0011",
--X"5" & "0010",
--X"5" & "0011",
--X"6" & "0010",
--X"6" & "0011",
--X"7" & "0010",
--X"7" & "0011",
--X"8" & "0010",
--X"8" & "0011",
--X"9" & "0010",
--X"9" & "0011",
--X"A" & "0010",
--X"A" & "0011",
--X"B" & "0010",
--X"B" & "0011",
--X"C" & "0010",
--X"C" & "0011",
--X"D" & "0010",
--X"D" & "0011",
--X"E" & "0010",
--X"E" & "0011",
--X"F" & "0010",
--X"F" & "0011",
--X"0" & "0000"

debug <= ready & CE & IO & SCLK & std_logic_vector(to_unsigned(state'POS(state_current), 4)) & count & controlword when (driveIO = '1')
			else 
			ready & CE & IO & SCLK & std_logic_vector(to_unsigned(state'POS(state_current), 4)) & count & inputbyte & controlword(7 downto 0);

IO <= dout when driveIO = '1' else 'Z';
SCLK <= SCLK_enable and clk2delayed(3);
ready <= readReady and writeReady;
D <= inputbyte when nReadAccess = '0' else "ZZZZZZZZ";

nReadAccess <= nSel or nRD;
rdReady: process(reset, nReadAccess)
begin
	if (reset = '1' or continue = '1') then
		readReady <= '1';
	else
		if (falling_edge(nReadAccess)) then
			readReady <= '0';
		end if;
	end if;
end process;

nWriteAccess <= nSel or nWR;
wrReady: process(reset, nWriteAccess)
begin
	if (reset = '1' or continue = '1') then
		writeReady <= '1';
	else
		if (falling_edge(nWriteAccess)) then
			writeReady <= '0';
		end if;
	end if;
end process;
	
generateClocks: process(clk, reset)
begin
	if (reset = '1') then
		clk2 <= 			"0110";
		clk2delayed <= "0011";
	else
		if (rising_edge(clk)) then
			clk2 <= clk2(2 downto 0) & clk2(3);
			clk2delayed <= clk2delayed(2 downto 0) & clk2delayed(3);
		end if;
	end if;
end process;

readByte: process(SCLK, driveIO, IO)
begin
	if (driveIO = '0') then
		if (rising_edge(SCLK)) then
			inputbyte <= inputbyte(6 downto 0) & IO;
		end if;
	end if;
end process;

drive: process(reset, fsmclk, state_next)
begin
	if (reset = '1') then
		state_current <= st_reset;
	else
		if (rising_edge(fsmclk)) then
			state_current <= state_next;
		end if;
	end if;
end process;

execute: process(fsmclk, state_current)
begin
	if (rising_edge(fsmclk)) then
		case state_current is
		
			when st_reset =>
				CE <= '0';
				SCLK_enable <= '0';
				driveIO <= '0';
				continue <= '1';

			when st_readytostart =>
				CE <= '0';
				SCLK_enable <= '0';
				driveIO <= '0';
				count <= X"0";
				continue <= '0';
				
			when st_startread =>
				CE <= '1';
				SCLK_enable <= '0';
				controlword <= D & '1' & A & '1';

			when st_startwrite =>
				CE <= '1';
				SCLK_enable <= '0';
				controlword <= D & '1' & A & '0';
	
			when st_write8 | st_write16 =>
				CE <= '1';
				SCLK_enable <= '1';
				driveIO <= '1';
				controlword <= '0' & controlword(15 downto 1);
				count <= std_logic_vector(unsigned(count) + 1);
				
			when st_read8 =>
				CE <= '1';
				SCLK_enable <= '1';
				driveIO <= '0';
				count <= std_logic_vector(unsigned(count) + 1);
				
			when st_done =>
				CE <= '0';
				SCLK_enable <= '0';
				driveIO <= '0';
				continue <= '1';

		end case;
	end if;
end process;

sequence: process(state_current, readyState, count) 
begin
	case state_current is

		when st_reset =>
			state_next <= st_readytostart;

		when st_readytostart =>
			case readyState is
				when "01" =>	
					state_next <= st_startread;
				when "10" =>	
					state_next <= st_startwrite;
				when others =>
					state_next <= st_readytostart;
			end case;
			
		when st_startread =>
			state_next <= st_write8;

		when st_startwrite =>
			state_next <= st_write16;
			
		when st_write16 =>
			if (count = X"F") then
				state_next <= st_done;
			else
				state_next <= st_write16;
			end if;

		when st_write8 =>
			if (count = X"7") then
				state_next <= st_read8;
			else
				state_next <= st_write8;
			end if;

		when st_read8 =>
			if (count = X"F") then
				state_next <= st_done;
			else
				state_next <= st_read8;
			end if;

		when st_done =>
			state_next <= st_readytostart;
			
	end case;
end process;


end Behavioral;

