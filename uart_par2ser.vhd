----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:08:56 03/24/2019 
-- Design Name: 
-- Module Name:    uart_par2ser - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- https://hackaday.io/project/181664-intel-hex-file-inputoutput-for-fpgas/log/197809-par2ser-a-novel-uart-trasmitter
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

entity uart_par2ser is
    Port ( reset : in  STD_LOGIC;
			  txd_clk: in STD_LOGIC;
			  send: in STD_LOGIC;
			  mode: in STD_LOGIC_VECTOR(2 downto 0);
			  data: in STD_LOGIC_VECTOR(7 downto 0);
           ready : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end uart_par2ser;

architecture Behavioral of uart_par2ser is

signal bitSel: std_logic_vector(3 downto 0);
signal bitClk, p_bit, parity: std_logic;
signal char: std_logic_vector(7 downto 0);

begin

parity <= char(7) xor (char(6) xor (char(5) xor (char(4) xor (char(3) xor (char(2) xor (char(1) xor (char(0) xor mode(0))))))));

-- p_bit depends on "mode"
with mode select p_bit <= 
	'0' when "100",	-- parity 0
	'1' when "101",	-- parity 1
	parity when "110", -- parity even (because mode(0) is '0')
	parity when "111", -- parity odd (because mode(1) is '1')
	'1' when others;

-- drive simple UART data output with mux
with bitSel select txd <= 		
			'1'     when X"0", -- high while not busy
			'1'	  when X"1", -- delay 1 (to sync with txd_clk)
			'1'	  when X"2", -- delay 2 
			'0' 	  when X"3", -- start bit
			char(0) when X"4",   -- data
			char(1) when X"5",
			char(2) when X"6",
			char(3) when X"7",
			char(4) when X"8",
			char(5) when X"9",
			char(6) when X"A",
			char(7) when X"B",
			p_bit   when X"C",	-- parity or stop
			'1' 	  when X"D",	-- stop
			'1' when others;		-- delay

-- drive low when any are being bits transmitted	
ready <= '1' when (bitSel = X"0") else '0'; 					

-- when ready, listen to rising edge of send signal to start
bitClk <= send when (bitSel = X"0") else txd_clk;

-- note that when going from 1100 to 0000 this counter shuts itself off, waits for send pulse
on_bitclk: process(reset, bitClk)
begin
	if (reset = '1') then
		bitSel <= X"0";
	else
		if (rising_edge(bitClk)) then
			case bitSel is
				when X"0" =>
					char <= data;
					bitSel <= std_logic_vector(unsigned(bitSel) + 1);
				when X"E" =>
					bitSel <= X"0";
				when others =>
					bitSel <= std_logic_vector(unsigned(bitSel) + 1);
			end case;
		end if;
	end if;
end process;

end Behavioral;

