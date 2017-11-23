----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/12/2017 10:40:36 PM
-- Design Name: 
-- Module Name: debouncer8channel - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debouncer8channel is
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           signal_raw : in STD_LOGIC_VECTOR (7 downto 0);
           signal_debounced : out STD_LOGIC_VECTOR (7 downto 0));
end debouncer8channel;

architecture Behavioral of debouncer8channel is

component debouncer is
    Port ( clock : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           signal_in : in  STD_LOGIC;
           signal_out : out  STD_LOGIC);
end component;

begin
	d0: debouncer port map (
		reset => reset,
		clock => clock,
		signal_in => signal_raw(0),
		signal_out => signal_debounced(0)
	);
	d1: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(1),
        signal_out => signal_debounced(1)
    );
	d2: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(2),
        signal_out => signal_debounced(2)
    );
	d3: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(3),
        signal_out => signal_debounced(3)
    );
	d4: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(4),
        signal_out => signal_debounced(4)
    );
	d5: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(5),
        signal_out => signal_debounced(5)
    );
	d6: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(6),
        signal_out => signal_debounced(6)
    );
	d7: debouncer port map (
        reset => reset,
        clock => clock,
        signal_in => signal_raw(7),
        signal_out => signal_debounced(7)
    );

end Behavioral;
