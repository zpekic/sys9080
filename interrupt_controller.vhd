----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:12:03 12/12/2017 
-- Design Name: 
-- Module Name:    interrupt_controller - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity interrupt_controller is
    Port ( CLK : in  STD_LOGIC;
           nRESET : in  STD_LOGIC;
           INT : out  STD_LOGIC;
           nINTA : in  STD_LOGIC;
           INTE : in  STD_LOGIC;
           D : out  STD_LOGIC_VECTOR (7 downto 0);
           DEVICEREQ : in  STD_LOGIC_VECTOR (7 downto 0);
           DEVICEACK : out  STD_LOGIC_VECTOR (7 downto 0));
end interrupt_controller;

architecture Behavioral of interrupt_controller is

--constant opcode_rst0: std_logic_vector(7 downto 0) := X"C7";
--constant opcode_rst1: std_logic_vector(7 downto 0) := X"CF";
--constant opcode_rst2: std_logic_vector(7 downto 0) := X"D7";
--constant opcode_rst3: std_logic_vector(7 downto 0) := X"DF";
--constant opcode_rst4: std_logic_vector(7 downto 0) := X"E7";
--constant opcode_rst5: std_logic_vector(7 downto 0) := X"EF";
--constant opcode_rst6: std_logic_vector(7 downto 0) := X"F7";
--constant opcode_rst7: std_logic_vector(7 downto 0) := X"FF";
constant opcode_noop: std_logic_vector(7 downto 0) := X"00";

signal vector: std_logic_vector(7 downto 0);
signal level: std_logic_vector(3 downto 0);
signal intreq, intclk: std_logic;

begin

D <= vector when (nINTA = '0') else "ZZZZZZZZ";
--intclk <= CLK when (intreq = '0') else nINTA;
INT <= intreq;

level <= "1111" when DEVICEREQ(7) = '1' else -- highest level 7 == RST 7
			"1110" when DEVICEREQ(6) = '1' else
			"1101" when DEVICEREQ(5) = '1' else
			"1100" when DEVICEREQ(4) = '1' else
			"1011" when DEVICEREQ(3) = '1' else
			"1010" when DEVICEREQ(2) = '1' else
			"1001" when DEVICEREQ(1) = '1' else
			"1000" when DEVICEREQ(0) = '1' else -- lowest level 0 == RST 0
			"0000";										-- no interrupt

generate_ack: process(nINTA, vector)
begin
    if (nINTA = '0') then
        case vector(5 downto 3) is
            when "000" =>
					DEVICEACK <= "00000001";
            when "001" =>
					DEVICEACK <= "00000010";
            when "010" =>
					DEVICEACK <= "00000100";
            when "011" =>
					DEVICEACK <= "00001000";
            when "100" =>
					DEVICEACK <= "00010000";
            when "101" =>
					DEVICEACK <= "00100000";
            when "110" =>
					DEVICEACK <= "01000000";
            when "111" =>
					DEVICEACK <= "10000000";
            when others =>
					null;
        end case;
    else
        DEVICEACK <= "00000000";
    end if;
end process;

loadvector: process(nRESET, CLK, level, INTE, nINTA)
begin
	if (nRESET = '0') then
		intreq <= '0';
		vector <= opcode_noop; --- not really used
	else 
		if (rising_edge(CLK)) then
			if (intreq = '0') then
				if (level(3) = '1' and INTE = '1') then
					intreq <= '1';
					vector <= "11" & level(2 downto 0) & "111";
				end if;
			else
				intreq <= nINTA;
			end if;
		end if;
	end if;
end process;

end Behavioral;

