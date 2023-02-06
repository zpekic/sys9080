----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:43:00 06/17/2019 
-- Design Name: 
-- Module Name:    xyram - Behavioral 
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

entity xyram is
	 generic (maxram: integer;
				 maxrow: integer;
				 maxcol: integer);
    Port ( clk : in  STD_LOGIC;
           rw_we : in  STD_LOGIC;
           rw_x : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_y : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_din : in  STD_LOGIC_VECTOR (7 downto 0);
           rw_dout : out  STD_LOGIC_VECTOR (7 downto 0);
			  mode: in STD_LOGIC_VECTOR (7 downto 0);
           nDigit : in  STD_LOGIC_VECTOR (8 downto 0);
           segment : in  STD_LOGIC_VECTOR(7 downto 0);
			  field: buffer STD_LOGIC_VECTOR(1 downto 0);
           ro_x : in  STD_LOGIC_VECTOR (7 downto 0);
           ro_y : in  STD_LOGIC_VECTOR (7 downto 0);
           ro_dout : out  STD_LOGIC_VECTOR (7 downto 0));
end xyram;

architecture Behavioral of xyram is

component ram4k8dual IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;

component mux11x4 is
    Port ( e : in  STD_LOGIC_VECTOR (10 downto 0);
           x : in  STD_LOGIC_VECTOR (43 downto 0);
           y : out  STD_LOGIC_VECTOR (3 downto 0));
end component;

--type ram4k is array(0 to (maxram - 1)) of std_logic_vector(7 downto 0);
--signal vram: ram4k := (others => X"2E"); -- dot
--attribute ram_style: string;
--attribute ram_style of vram : signal is "block";

--type rom256 is array(0 to 255) of std_logic_vector(7 downto 0);
--
--constant vrom_ti: rom256 := (
--X"20", X"20", X"20", X"20", X"20", X"54", X"4d", X"53", X"30", X"38", X"30", X"30", X"2d", X"62", X"61", X"73", X"65", X"64", X"20", X"63", X"61", X"6c", X"63", X"75", X"6c", X"61", X"74", X"6f", X"72", X"20", X"6f", X"6e", X"20", X"46", X"50", X"47", X"41", X"20", X"2d", X"20", X"68", X"74", X"74", X"70", X"73", X"3a", X"2f", X"2f", X"67", X"69", X"74", X"68", X"75", X"62", X"2e", X"63", X"6f", X"6d", X"2f", X"7a", X"70", X"65", X"6b", X"69", X"63", X"2f", X"53", X"79", X"73", X"30", X"38", X"30", X"30", X"2f", X"20", X"20", X"20", X"20", X"20", X"20",
--X"2a", X"20", X"20", X"20", X"20", X"54", X"49", X"20", X"44", X"61", X"74", X"61", X"6d", X"61", X"74", X"68", X"20", X"6d", X"6f", X"64", X"65", X"20", X"28", X"53", X"57", X"37", X"3d", X"6f", X"6e", X"20", X"61", X"6e", X"64", X"20", X"72", X"65", X"73", X"65", X"74", X"20", X"66", X"6f", X"72", X"20", X"53", X"69", X"6e", X"63", X"6c", X"61", X"69", X"72", X"2c", X"20", X"70", X"72", X"65", X"73", X"73", X"20", X"42", X"54", X"4e", X"33", X"20", X"74", X"6f", X"20", X"73", X"74", X"61", X"72", X"74", X"20", X"29", X"20", X"20", X"20", X"20", X"2a", 
--X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"28", X"69", X"6e", X"73", X"70", X"69", X"72", X"65", X"64", X"20", X"62", X"79", X"20", X"68", X"74", X"74", X"70", X"3a", X"2f", X"2f", X"72", X"69", X"67", X"68", X"74", X"6f", X"2e", X"63", X"6f", X"6d", X"2f", X"74", X"69", X"20", X"29", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", 
--X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20"
--); 
--
--constant vrom_sinclair: rom256 := (
--X"20", X"20", X"20", X"20", X"20", X"54", X"4d", X"53", X"30", X"38", X"30", X"30", X"2d", X"62", X"61", X"73", X"65", X"64", X"20", X"63", X"61", X"6c", X"63", X"75", X"6c", X"61", X"74", X"6f", X"72", X"20", X"6f", X"6e", X"20", X"46", X"50", X"47", X"41", X"20", X"2d", X"20", X"68", X"74", X"74", X"70", X"73", X"3a", X"2f", X"2f", X"67", X"69", X"74", X"68", X"75", X"62", X"2e", X"63", X"6f", X"6d", X"2f", X"7a", X"70", X"65", X"6b", X"69", X"63", X"2f", X"53", X"79", X"73", X"30", X"38", X"30", X"30", X"2f", X"20", X"20", X"20", X"20", X"20", X"20",
--X"2a", X"20", X"53", X"69", X"6e", X"63", X"6c", X"61", X"69", X"72", X"20", X"53", X"63", X"69", X"65", X"6e", X"74", X"69", X"66", X"69", X"63", X"20", X"6d", X"6f", X"64", X"65", X"20", X"28", X"53", X"57", X"37", X"3d", X"6f", X"66", X"66", X"20", X"61", X"6e", X"64", X"20", X"72", X"65", X"73", X"65", X"74", X"20", X"66", X"6f", X"72", X"20", X"54", X"49", X"2c", X"20", X"70", X"72", X"65", X"73", X"73", X"20", X"42", X"54", X"4e", X"33", X"20", X"74", X"6f", X"20", X"73", X"74", X"61", X"72", X"74", X"29", X"20", X"20", X"20", X"20", X"20", X"2a",
--X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"28", X"69", X"6e", X"73", X"70", X"69", X"72", X"65", X"64", X"20", X"62", X"79", X"20", X"68", X"74", X"74", X"70", X"3a", X"2f", X"2f", X"72", X"69", X"67", X"68", X"74", X"6f", X"2e", X"63", X"6f", X"6d", X"2f", X"73", X"69", X"6e", X"63", X"6c", X"61", X"69", X"72", X"20", X"29", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", 
--X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20", X"20"
--); 

type crom256 is array(0 to 255) of character;

constant vrom_ti: crom256 := (
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
); 

constant vrom_sinclair: crom256 := (
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',
'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
); 

type rom64 is array(0 to 63) of std_logic_vector(7 downto 0);
constant sevensegmask: rom64 := (
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
X"20", X"01", X"01", X"01", X"02", X"00", X"00", X"00",
X"20", X"00", X"00", X"00", X"02", X"00", X"00", X"00",
X"20", X"00", X"00", X"00", X"02", X"00", X"00", X"00",
X"00", X"40", X"40", X"40", X"00", X"00", X"00", X"00",
X"10", X"00", X"00", X"00", X"04", X"00", X"00", X"00",
X"10", X"00", X"00", X"00", X"04", X"00", X"00", X"00",
X"10", X"08", X"08", X"08", X"04", X"00", X"80", X"00"
);

type ram16 is array(0 to 15) of std_logic_vector(7 downto 0);
signal seg_mem: ram16;

--attribute ram_style of vrom : signal is "block";
--attribute ram_init_file: string;
--attribute ram_init_file of vrom : signal is "logo.mif";

signal x_ok, y_ram, y_rom: std_logic;
signal vram_addr, vrom_addr, ro_y64, ro_y16, ro_x1: std_logic_vector(11 downto 0);
signal doutb, vrom: std_logic_vector(7 downto 0);

signal rw_addr, rw_y64, rw_y16, rw_x1: std_logic_vector(11 downto 0);

signal fontmask, sevensegchar: std_logic_vector(7 downto 0);
signal maskaddress: std_logic_vector(5 downto 0);
signal write_address: std_logic_vector(3 downto 0);
--signal nDig, nSeg: std_logic;

begin

x_ok <= '1' when (unsigned(ro_x) < maxcol) else '0';
y_ram <= x_ok when (unsigned(ro_y) < maxrow) else '0';
y_rom <= x_ok when (unsigned(ro_y) > 56) else '0';

ro_x1 <= "0000" & ro_x;
ro_y16 <= ro_y & "0000";
ro_y64 <= ro_y(5 downto 0) & "000000";
vram_addr <= std_logic_vector(unsigned(ro_y64) + unsigned(ro_y16) + unsigned(ro_x1));	-- a = 80 * y + x
vrom_addr <= std_logic_vector(unsigned(vram_addr) - (57 * 80));					-- map to row 57..59
vrom <= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(vrom_sinclair(to_integer(unsigned(vrom_addr(7 downto 0))))), 8)) when (mode(7) = '1') else STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(vrom_ti(to_integer(unsigned(vrom_addr(7 downto 0))))), 8));

rw_x1 <= "0000" & rw_x;
rw_y16 <= rw_y & "0000";
rw_y64 <= rw_y(5 downto 0) & "000000";
rw_addr <= std_logic_vector(unsigned(rw_y64) + unsigned(rw_y16) + unsigned(rw_x1));	-- a = 80 * y + x

vram: ram4k8dual PORT map
(
	-- for tracer
    clka => clk,
    wea => "" & rw_we & "", --"" & we and y_ram & "",
    addra => rw_addr,
    dina => rw_din,
    douta => rw_dout,
	-- for controller
    clkb => clk,
    web => "" & '0' & "",
    addrb => vram_addr,
    dinb => X"00",
    doutb => doutb
  );

field <= y_rom & y_ram;

-- "paint" the 7seg state on VGA
addrmux: mux11x4 port map 
	(
		e => '1' & nDigit & '1',
		x => X"01234567890",
		y => write_address
	);

writeseg: process(clk, segment, write_address)
begin
	if (rising_edge(clk)) then
		if (write_address = X"0") then
			seg_mem(0) <= X"00";
		else
			seg_mem(to_integer(unsigned(write_address))) <= segment;
		end if;
	end if;
end process;

maskaddress <= ro_y(2 downto 0) & ro_x(2 downto 0);
fontmask <= sevensegmask(to_integer(unsigned(maskaddress))) and seg_mem(to_integer(unsigned(ro_x(6 downto 3))));
sevensegchar <= X"20" when (fontmask = X"00") else X"A0";

--	
with field select
	ro_dout <= 	doutb 			when "01",		-- x < 80, y < 50
					vrom				when "10",		-- x < 80, y > 56
					sevensegchar	when others;	-- calculator result display

end Behavioral;

