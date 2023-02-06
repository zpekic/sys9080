----------------------------------------------------------------------------------
-- Company: @Home
-- Engineer: Zoltan Pekic (zpekic@hotmail.com)
-- 
-- Create Date:    01:57:47 02/27/2016 
-- Design Name: 
-- Module Name:    pwm10bit - Behavioral 
-- Project Name:   Alarm Clock
-- Target Devices: Mercury FPGA + Baseboard (http://www.micro-nova.com/mercury/)
-- Tool versions:  Xilinx ISE 14.7 (nt64)
--
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

entity adcdevice is
    Port ( clk : in  STD_LOGIC;
			  reset: in STD_LOGIC;
			  inputfreq: in STD_LOGIC;
			  samplingrate: in STD_LOGIC;
			  output: out std_logic_vector(15 downto 0));
end adcdevice;

-- From http://www.micro-nova.com/resources/
--use work.MercuryADC;

architecture Behavioral of adcdevice is

--component MercuryADC is
--  port
--    (
--      -- command input
--      clock    : in  std_logic;         -- 50MHz onboard oscillator
--      trigger  : in  std_logic;         -- assert to sample ADC
--      diffn    : in  std_logic;         -- single/differential inputs
--      channel  : in  std_logic_vector(2 downto 0);  -- channel to sample
--      -- data output
--      Dout     : out std_logic_vector(9 downto 0);  -- data from ADC
--      OutVal   : out std_logic;         -- pulsed when data sampled
--      -- ADC connection
--      adc_miso : in  std_logic;         -- ADC SPI MISO
--      adc_mosi : out std_logic;         -- ADC SPI MOSI
--      adc_cs   : out std_logic;         -- ADC SPI CHIP SELECT
--      adc_clk  : out std_logic          -- ADC SPI CLOCK
--      );
--end component;

signal counter0, counter1, capturedcount: unsigned(15 downto 0);
signal counter_sel: std_logic;

begin

	output <= std_logic_vector(capturedcount);
	
	update_output: process(samplingrate, counter0, counter1)
	begin
		if (rising_edge(samplingrate)) then
			if (counter_sel = '0') then
				capturedcount <= counter0;
				counter_sel <= '1';
			else
				capturedcount <= counter1;
				counter_sel <= '0';
			end if;
		end if;
	end process;
	
	update_count: process(inputfreq, counter_sel)
	begin
		if rising_edge(inputfreq) then
			if (counter_sel = '0') then
				counter1 <= X"0000";
				counter0 <= counter0 + 1;
			else
				counter0 <= X"0000";
				counter1 <= counter1 + 1;
			end if;
		end if;
	end process;

end Behavioral;

