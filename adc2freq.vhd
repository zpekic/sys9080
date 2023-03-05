----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:20:13 03/04/2023 
-- Design Name: 
-- Module Name:    adc2freq - Behavioral 
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

entity adc2freq is
    Port ( adc_sample : in  STD_LOGIC_VECTOR (9 downto 0);
           adc_done : in  STD_LOGIC;
           avg_sel : in  STD_LOGIC_VECTOR (1 downto 0);
           round_sel : in  STD_LOGIC_VECTOR (1 downto 0);
			  sum_start: buffer STD_LOGIC;
			  sum_end: buffer STD_LOGIC;
           freq_out : out  STD_LOGIC);
end adc2freq;

architecture Behavioral of adc2freq is

type table is array(0 to 7) of std_logic_vector(3 downto 0);
constant stable: table := 
(
	"1111", 
	"0001", 
	"0011", 
	"0001", 
	"0111",
	"0001",
	"0011",
	"0001"
);
constant etable: table := 
(
	"0001",
	"0011",
	"0001",
	"0111",
	"0001",
	"0011",
	"0001",
	"1111"
);

signal s0, s1, s_avg, s_round, s_sum: std_logic_vector(15 downto 0);
signal adc_cnt: std_logic_vector(2 downto 0);

begin

-- remove LSB noise from ADC reading
with round_sel select s_round <= 
	"000000" & adc_sample when "00",
	"0000000" & adc_sample(9 downto 1) when "01",
	"00000000" & adc_sample(9 downto 2) when "10",
	"000000000" & adc_sample(9 downto 3) when others;

sum_start <= stable(to_integer(unsigned(adc_cnt)))(to_integer(unsigned(avg_sel)));
sum_end <= etable(to_integer(unsigned(adc_cnt)))(to_integer(unsigned(avg_sel)));

on_adc_done_rising: process(adc_done, sum_start)
begin
	if (rising_edge(adc_done)) then
		adc_cnt <= std_logic_vector(unsigned(adc_cnt) + 1);
		if (sum_start = '1') then
			s_sum <= s_round;
		else
			s_sum <= std_logic_vector(unsigned(s_sum) + unsigned(s_round));	
		end if;
	end if;
end process;

with avg_sel select s_avg <= 
	s_sum when "00",									-- /1
	'0' & s_sum(15 downto 1) when "01",			-- /2
	"00" & s_sum(15 downto 2) when "10",		-- /4
	"000" & s_sum(15 downto 3) when others;	-- /8
	
on_adc_done_falling: process(adc_done, sum_end)
begin
	if (falling_edge(adc_done)) then
		if (sum_end = '1') then
			-- values
			s0 <= s_avg;
			s1 <= s0;
		end if;
	end if;
end process;
		
freq_out <= '1' when (unsigned(s0) > unsigned(s1)) else '0';

end Behavioral;

