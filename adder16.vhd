----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:44:19 10/23/2020 
-- Design Name: 
-- Module Name:    adder16 - Behavioral 
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

entity adder16 is
    Port ( cin : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (15 downto 0);
           b : in  STD_LOGIC_VECTOR (15 downto 0);
           na : in  STD_LOGIC;
           nb : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (15 downto 0);
           cout : out  STD_LOGIC);
end adder16;

architecture Behavioral of adder16 is

component nibbleadder is
    Port ( cin : in  STD_LOGIC;
           a : in  STD_LOGIC_VECTOR (3 downto 0);
           b : in  STD_LOGIC_VECTOR (3 downto 0);
           na : in  STD_LOGIC;
           nb : in  STD_LOGIC;
           bcd : in  STD_LOGIC;
           y : out  STD_LOGIC_VECTOR (3 downto 0);
           cout : out  STD_LOGIC);
end component;

signal cout3, cout7, cout11: std_logic;

begin

s0: nibbleadder Port map ( 
				cin => cin,
				a => a(3 downto 0),
				b => b(3 downto 0),
				na => na,
				nb => nb,
				bcd => bcd,
				y => y(3 downto 0),
				cout => cout3
			);

s1: nibbleadder Port map ( 
				cin => cout3,
				a => a(7 downto 4),
				b => b(7 downto 4),
				na => na,
				nb => nb,
				bcd => bcd,
				y => y(7 downto 4),
				cout => cout7
			);

s2: nibbleadder Port map ( 
				cin => cout7,
				a => a(11 downto 8),
				b => b(11 downto 8),
				na => na,
				nb => nb,
				bcd => bcd,
				y => y(11 downto 8),
				cout => cout11
			);

s3: nibbleadder Port map ( 
				cin => cout11,
				a => a(15 downto 12),
				b => b(15 downto 12),
				na => na,
				nb => nb,
				bcd => bcd,
				y => y(15 downto 12),
				cout => cout
			);

end Behavioral;

