----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:26:38 09/09/2018 
-- Design Name: 
-- Module Name:    TextVDP - Behavioral 
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

entity TextVDP is
    Port ( Reset : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           A : in  STD_LOGIC_VECTOR (8 downto 0);
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
           nCS : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           Pixel_x : in  STD_LOGIC_VECTOR (11 downto 0);
           Pixel_y : in  STD_LOGIC_VECTOR (11 downto 0);
			  nBusy : buffer STD_LOGIC;
           color : out  STD_LOGIC_VECTOR (7 downto 0);
           blank : buffer STD_LOGIC);
end TextVDP;

architecture Behavioral of TextVDP is

component simpleram is
	 generic (
		address_size: integer;
		default_value: STD_LOGIC_VECTOR(7 downto 0)
	  );
    Port (       
			  clk: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR ((address_size - 1) downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC);
end component;

component arraymapper is 
		port (
			doublecols: in STD_LOGIC;
			row: in STD_LOGIC_VECTOR(5 downto 0); -- 6 bits to cover 0 .. 59
			col:  in STD_LOGIC_VECTOR(5 downto 0); -- 6 bits to cover 0 .. 33
			y:  in STD_LOGIC_VECTOR(10 downto 0)	-- 11 bits to cover 0 .. 60*34 = 1980
		);
end component;
		
-- temporary character generator table
type chargen is array (0 to (128 * 8 - 1)) of std_logic_vector(7 downto 0);
constant tempgen: chargen :=(
----------------------------------------------------------
-- Based on "TinyFont" from http://www.rinkydinkelectronics.com/r_fonts.php
----------------------------------------------------------
X"00", X"00", X"77", X"55", X"55", X"55", X"77", X"00", -- 00
X"00", X"00", X"71", X"51", X"51", X"51", X"71", X"00", -- 01
X"00", X"00", X"73", X"51", X"53", X"52", X"73", X"00", -- 02
X"00", X"00", X"73", X"51", X"53", X"51", X"73", X"00", -- 03
X"00", X"00", X"74", X"55", X"57", X"51", X"71", X"00", -- 04
X"00", X"00", X"77", X"54", X"57", X"51", X"77", X"00", -- 05
X"00", X"00", X"77", X"54", X"57", X"55", X"77", X"00", -- 06
X"00", X"00", X"77", X"51", X"52", X"54", X"74", X"00", -- 07
X"00", X"00", X"77", X"55", X"57", X"55", X"77", X"00", -- 08
X"00", X"00", X"77", X"55", X"57", X"51", X"77", X"00", -- 09
X"00", X"00", X"77", X"55", X"57", X"55", X"75", X"00", -- 0A
X"00", X"00", X"74", X"54", X"57", X"55", X"77", X"00", -- 0B
X"00", X"00", X"77", X"54", X"54", X"54", X"77", X"00", -- 0C
X"00", X"00", X"71", X"51", X"57", X"55", X"77", X"00", -- 0D
X"00", X"00", X"77", X"54", X"57", X"54", X"77", X"00", -- 0E
X"00", X"00", X"77", X"54", X"57", X"54", X"74", X"00", -- 0F
X"00", X"00", X"17", X"15", X"15", X"15", X"17", X"00", -- 10
X"00", X"00", X"11", X"11", X"11", X"11", X"11", X"00", -- 11
X"00", X"00", X"13", X"11", X"13", X"12", X"13", X"00", -- 12
X"00", X"00", X"13", X"11", X"13", X"11", X"13", X"00", -- 13
X"00", X"00", X"14", X"15", X"17", X"11", X"11", X"00", -- 14
X"00", X"00", X"17", X"14", X"17", X"11", X"17", X"00", -- 15
X"00", X"00", X"17", X"14", X"17", X"15", X"17", X"00", -- 16
X"00", X"00", X"17", X"11", X"12", X"14", X"14", X"00", -- 17
X"00", X"00", X"17", X"15", X"17", X"15", X"17", X"00", -- 18
X"00", X"00", X"17", X"15", X"17", X"11", X"17", X"00", -- 19
X"00", X"00", X"17", X"15", X"17", X"15", X"15", X"00", -- 1A
X"00", X"00", X"14", X"14", X"17", X"15", X"17", X"00", -- 1B
X"00", X"00", X"17", X"14", X"14", X"14", X"17", X"00", -- 1C
X"00", X"00", X"11", X"11", X"17", X"15", X"17", X"00", -- 1D
X"00", X"00", X"17", X"14", X"17", X"14", X"17", X"00", -- 1E
X"00", X"00", X"17", X"14", X"17", X"14", X"14", X"00", -- 1F
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", -- <Space>
X"18", X"3C", X"3C", X"18", X"18", X"00", X"18", X"00", -- !
X"66", X"66", X"24", X"00", X"00", X"00", X"00", X"00", -- "
X"6C", X"6C", X"FE", X"6C", X"FE", X"6C", X"6C", X"00", -- #
X"18", X"3E", X"60", X"3C", X"06", X"7C", X"18", X"00", -- $
X"00", X"C6", X"CC", X"18", X"30", X"66", X"C6", X"00", -- %
X"38", X"6C", X"38", X"76", X"DC", X"CC", X"76", X"00", -- &
X"18", X"18", X"30", X"00", X"00", X"00", X"00", X"00", -- '
X"0C", X"18", X"30", X"30", X"30", X"18", X"0C", X"00", -- (
X"30", X"18", X"0C", X"0C", X"0C", X"18", X"30", X"00", -- )
X"00", X"66", X"3C", X"FF", X"3C", X"66", X"00", X"00", -- *
X"00", X"18", X"18", X"7E", X"18", X"18", X"00", X"00", -- +
X"00", X"00", X"00", X"00", X"00", X"18", X"18", X"30", -- , --
X"00", X"00", X"00", X"7E", X"00", X"00", X"00", X"00", -- -
X"00", X"00", X"00", X"00", X"00", X"18", X"18", X"00", -- .
X"06", X"0C", X"18", X"30", X"60", X"C0", X"80", X"00", -- /
X"7C", X"C6", X"CE", X"D6", X"E6", X"C6", X"7C", X"00", -- 0
X"18", X"38", X"18", X"18", X"18", X"18", X"7E", X"00", -- 1
X"7C", X"C6", X"06", X"1C", X"30", X"66", X"FE", X"00", -- 2
X"7C", X"C6", X"06", X"3C", X"06", X"C6", X"7C", X"00", -- 3
X"1C", X"3C", X"6C", X"CC", X"FE", X"0C", X"1E", X"00", -- 4
X"FE", X"C0", X"C0", X"FC", X"06", X"C6", X"7C", X"00", -- 5
X"38", X"60", X"C0", X"FC", X"C6", X"C6", X"7C", X"00", -- 6
X"FE", X"C6", X"0C", X"18", X"30", X"30", X"30", X"00", -- 7
X"7C", X"C6", X"C6", X"7C", X"C6", X"C6", X"7C", X"00", -- 8
X"7C", X"C6", X"C6", X"7E", X"06", X"0C", X"78", X"00", -- 9
X"00", X"18", X"18", X"00", X"00", X"18", X"18", X"00", -- :
X"00", X"18", X"18", X"00", X"00", X"18", X"18", X"30", -- ;
X"06", X"0C", X"18", X"30", X"18", X"0C", X"06", X"00", -- <
X"00", X"00", X"7E", X"00", X"00", X"7E", X"00", X"00", -- =
X"60", X"30", X"18", X"0C", X"18", X"30", X"60", X"00", -- >
X"7C", X"C6", X"0C", X"18", X"18", X"00", X"18", X"00", -- ?
X"7C", X"C6", X"DE", X"DE", X"DE", X"C0", X"78", X"00", -- @
X"38", X"6C", X"C6", X"FE", X"C6", X"C6", X"C6", X"00", -- A
X"FC", X"66", X"66", X"7C", X"66", X"66", X"FC", X"00", -- B
X"3C", X"66", X"C0", X"C0", X"C0", X"66", X"3C", X"00", -- C
X"F8", X"6C", X"66", X"66", X"66", X"6C", X"F8", X"00", -- D
X"FE", X"62", X"68", X"78", X"68", X"62", X"FE", X"00", -- E
X"FE", X"62", X"68", X"78", X"68", X"60", X"F0", X"00", -- F
X"3C", X"66", X"C0", X"C0", X"CE", X"66", X"3A", X"00", -- G
X"C6", X"C6", X"C6", X"FE", X"C6", X"C6", X"C6", X"00", -- H
X"3C", X"18", X"18", X"18", X"18", X"18", X"3C", X"00", -- I
X"1E", X"0C", X"0C", X"0C", X"CC", X"CC", X"78", X"00", -- J
X"E6", X"66", X"6C", X"78", X"6C", X"66", X"E6", X"00", -- K
X"F0", X"60", X"60", X"60", X"62", X"66", X"FE", X"00", -- L
X"C6", X"EE", X"FE", X"FE", X"D6", X"C6", X"C6", X"00", -- M
X"C6", X"E6", X"F6", X"DE", X"CE", X"C6", X"C6", X"00", -- N
X"7C", X"C6", X"C6", X"C6", X"C6", X"C6", X"7C", X"00", -- O
X"FC", X"66", X"66", X"7C", X"60", X"60", X"F0", X"00", -- P
X"7C", X"C6", X"C6", X"C6", X"C6", X"CE", X"7C", X"0E", -- Q
X"FC", X"66", X"66", X"7C", X"6C", X"66", X"E6", X"00", -- R
X"7C", X"C6", X"60", X"38", X"0C", X"C6", X"7C", X"00", -- S
X"7E", X"7E", X"5A", X"18", X"18", X"18", X"3C", X"00", -- T
X"C6", X"C6", X"C6", X"C6", X"C6", X"C6", X"7C", X"00", -- U
X"C6", X"C6", X"C6", X"C6", X"C6", X"6C", X"38", X"00", -- V
X"C6", X"C6", X"C6", X"D6", X"D6", X"FE", X"6C", X"00", -- W
X"C6", X"C6", X"6C", X"38", X"6C", X"C6", X"C6", X"00", -- X
X"66", X"66", X"66", X"3C", X"18", X"18", X"3C", X"00", -- Y
X"FE", X"C6", X"8C", X"18", X"32", X"66", X"FE", X"00", -- Z
X"3C", X"30", X"30", X"30", X"30", X"30", X"3C", X"00", -- [
X"C0", X"60", X"30", X"18", X"0C", X"06", X"02", X"00", -- <Backslash>
X"3C", X"0C", X"0C", X"0C", X"0C", X"0C", X"3C", X"00", -- ]
X"10", X"38", X"6C", X"C6", X"00", X"00", X"00", X"00", -- ^
X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"FF", -- _
X"30", X"18", X"0C", X"00", X"00", X"00", X"00", X"00", -- '
X"00", X"00", X"78", X"0C", X"7C", X"CC", X"76", X"00", -- a
X"E0", X"60", X"7C", X"66", X"66", X"66", X"DC", X"00", -- b
X"00", X"00", X"7C", X"C6", X"C0", X"C6", X"7C", X"00", -- c
X"1C", X"0C", X"7C", X"CC", X"CC", X"CC", X"76", X"00", -- d
X"00", X"00", X"7C", X"C6", X"FE", X"C0", X"7C", X"00", -- e
X"3C", X"66", X"60", X"F8", X"60", X"60", X"F0", X"00", -- f
X"00", X"00", X"76", X"CC", X"CC", X"7C", X"0C", X"F8", -- g
X"E0", X"60", X"6C", X"76", X"66", X"66", X"E6", X"00", -- h
X"18", X"00", X"38", X"18", X"18", X"18", X"3C", X"00", -- i
X"06", X"00", X"06", X"06", X"06", X"66", X"66", X"3C", -- j
X"E0", X"60", X"66", X"6C", X"78", X"6C", X"E6", X"00", -- k
X"38", X"18", X"18", X"18", X"18", X"18", X"3C", X"00", -- l
X"00", X"00", X"EC", X"FE", X"D6", X"D6", X"D6", X"00", -- m
X"00", X"00", X"DC", X"66", X"66", X"66", X"66", X"00", -- n
X"00", X"00", X"7C", X"C6", X"C6", X"C6", X"7C", X"00", -- o
X"00", X"00", X"DC", X"66", X"66", X"7C", X"60", X"F0", -- p
X"00", X"00", X"76", X"CC", X"CC", X"7C", X"0C", X"1E", -- q
X"00", X"00", X"DC", X"76", X"60", X"60", X"F0", X"00", -- r
X"00", X"00", X"7E", X"C0", X"7C", X"06", X"FC", X"00", -- s
X"30", X"30", X"FC", X"30", X"30", X"36", X"1C", X"00", -- t
X"00", X"00", X"CC", X"CC", X"CC", X"CC", X"76", X"00", -- u
X"00", X"00", X"C6", X"C6", X"C6", X"6C", X"38", X"00", -- v
X"00", X"00", X"C6", X"D6", X"D6", X"FE", X"6C", X"00", -- w
X"00", X"00", X"C6", X"6C", X"38", X"6C", X"C6", X"00", -- x
X"00", X"00", X"C6", X"C6", X"C6", X"7E", X"06", X"FC", -- y
X"00", X"00", X"7E", X"4C", X"18", X"32", X"7E", X"00", -- z
X"0E", X"18", X"18", X"70", X"18", X"18", X"0E", X"00", -- {
X"18", X"18", X"18", X"18", X"18", X"18", X"18", X"00", -- |
X"70", X"18", X"18", X"0E", X"18", X"18", X"70", X"00", -- }
X"76", X"DC", X"00", X"00", X"00", X"00", X"00", X"00", -- ~
X"00", X"7E", X"42", X"42", X"42", X"42", X"7E", X"00"  -- DEL 
);

constant rowCount : integer := 17; -- will be returned when reading 1FF
constant colCount : integer := 30; -- will be returned when reading 1FE

alias char_x: std_logic_vector(4 downto 0) is pixel_x(8 downto 4); -- 0 to 29
alias chargen_x: std_logic_vector(3 downto 0) is pixel_x(3 downto 0); -- 0 to 15
alias char_y: std_logic_vector(4 downto 0) is pixel_y(8 downto 4); -- 0 to 16
alias chargen_y: std_logic_vector(3 downto 0) is pixel_y(3 downto 0); -- 0 to 15

-- x, y counters are conveniently set up to start displaying from 0, 0; so "negative" values mean blank
alias VBlank: std_logic is pixel_y(11);
alias HBlank: std_logic is pixel_x(11);
-- character address
signal char_A: std_logic_vector(10 downto 0);

-- shared memory bus
signal nMemSelect, nMemRead, nMemWrite: std_logic;
signal Mem_D, reg, regOrMem: std_logic_vector(7 downto 0);
signal Mem_A: std_logic_vector(8 downto 0);
alias char_code: std_logic_vector(7 downto 0) is Mem_D;
signal setReady, setBusy, busy, pixel_read: std_logic;

-- chargen 128 8*8 pixel chars = 1k ROM 
signal chargen_addr: std_logic_vector(9 downto 0);
signal chargen_data: std_logic_vector(7 downto 0);
signal chargen_pixel: std_logic;

signal color_bg: std_logic_vector(7 downto 0) := "00011111"; -- cyan
signal color_fg: std_logic_vector(7 downto 0) := "00000011"; -- blue
signal regAccess: std_logic;

-- 2 "registers" are supported -----------------
-- Address	read		write ---------------------
-- 1FE		30			Foreground color (RRRGGGBB)
--	1FF		17			Background color (RRRGGGBB)
-- Note: when FGC == BGC then blank the display
------------------------------------------------
begin

	vdpram: simpleram 
		generic map(
			address_size => 9,
			default_value => X"20" -- initialize with space (blank)
			)	
		port map(
			  clk => Clk,
			  D => mem_D,
			  A => mem_A,
           nRead => nMemRead,
			  nWrite => nMemWrite,
			  nSelect => nMemSelect
		);

	addressgenerator: arraymapper
		port map(
			doublecols => '0',
			row => '0' & char_y, -- 6 bits to cover 0 .. 59
			col => '0' & char_x, -- 6 bits to cover 0 .. 33
			y => char_A				-- 11 bits to cover 0 .. 60*34 = 1980
		);

-- reserve bytes 1FE and 1FF
regAccess <= '1' when (A(8 downto 1) = X"FF") else '0';

--setReady <= '1' when (Reset = '1') else VBlank;
--setReady <= Reset or VBlank;
--setBusy  <= (not Reset) and Pixel_read and (not nCS);
--setBusy <= '0' when (nCS = '1' or Reset = '1') else Pixel_read;

--busy <= not (setReady or nBusy);
--nBusy <= not (setBusy or busy);
pixel_read <= not (VBlank or blank); -- need memory only when y >= 0 and display is not blanked


busy <= '0' when (Reset = '1' or VBlank = '1') else (not nBusy);
nBusy <= '0' when (nCS = '0' and pixel_read = '1') else (not busy);

--updateBusy: process(clk, Reset, VBlank, nCS, Pixel_read)
--begin
--	if (Reset = '1') then
--		busy <= '0';
--	else
--		if (rising_edge(clk)) then
--			if (VBlank = '1') then
--				busy <= '0';
--			else
--				busy <= Pixel_read and (not nCS);
--			end if;
--		end if;
--	end if;
--end process;
 
updateColors: process(clk, nCS, nWR, regAccess)
begin
	if (rising_edge(clk) and regAccess = '1' and nCS = '0' and nWR = '0') then
		if (A(0) = '0') then
			color_fg <= D;
		else
			color_bg <= D;
		end if;
	end if;
end process;

nMemRead <=   '0' when (pixel_read = '1') else nRD;
nMemWrite <=  '1' when (pixel_read = '1') else nWR;
nMemSelect <= '0' when (pixel_read = '1') else nCS;
mem_A <= char_A(8 downto 0) when (pixel_read = '1') else A;

reg <= std_logic_vector(to_unsigned(colCount, 8)) when (A(0) = '0') else std_logic_vector(to_unsigned(rowCount, 8));
regOrMem <= mem_D when (regAccess = '0') else reg;
D <= regOrMem when (nCS = '0' and nRD = '0') else "ZZZZZZZZ";
mem_D <= D when (Pixel_read = '0' and nCS = '0' and nWR = '0') else "ZZZZZZZZ";

-- chargen
chargen_addr <= char_code(6 downto 0) & chargen_y(3 downto 1);
chargen_data <= tempgen(to_integer(unsigned(chargen_addr)));
with chargen_x(3 downto 1) select
	chargen_pixel <=  chargen_data(7) when "000",
							chargen_data(6) when "001",
							chargen_data(5) when "010",
							chargen_data(4) when "011",
							chargen_data(3) when "100",
							chargen_data(2) when "101",
							chargen_data(1) when "110",
							chargen_data(0) when others;

color <= color_fg when ((char_code(7) xor chargen_pixel) = '1') else color_bg;

-- blank display when fg and bg colors are the same
blank <= '1' when (color_fg = color_bg) else '0';

end Behavioral;

