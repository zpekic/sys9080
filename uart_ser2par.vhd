----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:50:01 06/11/2021 
-- Design Name: 
-- Module Name:    uart_ser2par - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- https://hackaday.io/project/181664-intel-hex-file-inputoutput-for-fpgas/log/197810-ser2par-a-novel-uart-receiver
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_ser2par is
    Port ( reset : in  STD_LOGIC;
           rxd_clk : in  STD_LOGIC;
           mode : in  STD_LOGIC_VECTOR (2 downto 0);
           char : out  STD_LOGIC_VECTOR (7 downto 0);
           ready : buffer  STD_LOGIC;
           valid : out  STD_LOGIC;
           rxd : in  STD_LOGIC);
end uart_ser2par;

architecture Behavioral of uart_ser2par is

signal sr: std_logic_vector(43 downto 0);
signal frame: std_logic_vector(12 downto 0); -- 9 bits to capture the data + 4 for start
signal data: std_logic_vector(8 downto 0); 	-- 8 bits for actual byte + 1 for parity
signal stop_bit, start_bit0, start_bit1: std_logic;
signal frame_valid, parity: std_logic;

begin

-- flip MSB/LSB order (data(0) was received or dummy parity bit so leave it out)
char <= data(1) & data(2) & data(3) & data(4) & data(5) & data(6) & data(7) & data(8);

-- for mode = 1XX frame is 11 bits (start + 8 data + parity + stop)
-- for mode = 0XX frame is 10 bits (start + 8 data + stop)
frame <= 	  (sr(43 downto 40) & sr(37) & sr(33) & sr(29) & sr(25) & sr(21) & sr(17) & sr(13) & sr(9) & sr(5)) when (mode(2) = '1') 
			else (sr(39 downto 36) & sr(33) & sr(29) & sr(25) & sr(21) & sr(17) & sr(13) & sr(9) & sr(5)  & '1'); 
--			else (sr(39 downto 36) & sr(34) & sr(30) & sr(26) & sr(22) & sr(18) & sr(14) & sr(10) & sr(6)  & '1'); 

-- detect stop and start bits
stop_bit <= sr(1) and sr(0) and rxd;	-- look ahead 1/4 of baudrate time 
start_bit0 <= not (frame(12) or frame(11) or frame(10));
start_bit1 <= not (frame(11) or frame(10) or frame(9));

-- frame is valid if stop is mark and start is space
frame_valid <= stop_bit and (start_bit0 or start_bit1);

-- parity includes all data and parity bit
parity <= data(8) xor (data(7) xor (data(6) xor (data(5) xor (data(4) xor (data(3) xor (data(2) xor (data(1) xor data(0))))))));

-- for modes 0XX it is always assumed valid
with mode select valid <= 
	not frame(0) 	when "100",	-- parity 0 
	frame(0) 		when "101",	-- parity 1
	parity when "110",	-- parity even
	parity when "111",	-- parity odd
	'1' when others;	-- hard coded to '1' (as no parity bit in frame when mode = 0XX)
	
-- capture the data from shift register as soon valid frame is detected	
on_frame_valid: process(frame_valid, frame)
begin
	if (rising_edge(frame_valid)) then
		data <= frame(8 downto 0);
	end if;
end process;

-- receive clock runs 4X baudrate - this way 3 bits can be detected for valid start / stop
on_rxd_clk: process(rxd_clk, reset, frame_valid, sr)
begin
	if (reset = '1') then
		sr <= (others => '1');
	else
		if (rising_edge(rxd_clk)) then
			ready <= frame_valid;
			if (frame_valid = '1') then
				sr <= "111" & X"FFFFFFFFFF" & rxd;
			else
				sr <= sr(42 downto 0) & rxd;
			end if;
		end if;
	end if;
end process;

end Behavioral;

