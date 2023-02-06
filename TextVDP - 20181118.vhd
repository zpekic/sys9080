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
           A : out  STD_LOGIC_VECTOR (15 downto 0);
           D : in  STD_LOGIC_VECTOR (7 downto 0);
           nRD : out  STD_LOGIC;
           BusRequest : out  STD_LOGIC;
           BusAck : in  STD_LOGIC;
           Pixel_x : in  STD_LOGIC_VECTOR (11 downto 0);
           Pixel_y : in  STD_LOGIC_VECTOR (11 downto 0);
			  control : in STD_LOGIC_VECTOR(7 downto 0);
			  -- outputs
           color : out  STD_LOGIC_VECTOR (7 downto 0);
           blank : out STD_LOGIC);
end TextVDP;

architecture Behavioral of TextVDP is

component arraymapper is 
		port (
			doublecols: in STD_LOGIC;
			row: in STD_LOGIC_VECTOR(5 downto 0); -- 6 bits to cover 0 .. 59
			col:  in STD_LOGIC_VECTOR(5 downto 0); -- 6 bits to cover 0 .. 33
			y:  in STD_LOGIC_VECTOR(10 downto 0)	-- 11 bits to cover 0 .. 60*34 = 1980
		);
end component;
		
component color_rom is
    Port ( a : in  STD_LOGIC_VECTOR (3 downto 0);
           d : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

component dual_ram is
    Port ( d_in : in  STD_LOGIC_VECTOR (7 downto 0);
           a_write : in  STD_LOGIC_VECTOR (6 downto 0);
           a_read : in  STD_LOGIC_VECTOR (6 downto 0);
           bankselect : in  STD_LOGIC;
           nWE : in  STD_LOGIC;
           d_out : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

component chargen_rom is
    Port ( a : in  STD_LOGIC_VECTOR (10 downto 0);
           d : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

-- control bits
alias display_enable: std_logic is control(7);	-- 1 to display, 0 to blanks
alias cursor_enable: std_logic is control(6);	-- 1 to show cursor, 0 to hide
alias cursor_fullsize: std_logic is control(5);	-- 1 for full size cursor, 0 for underline
alias reserved4: std_logic is control(4);
alias reserved3: std_logic is control(4);
alias reserved2: std_logic is control(4);
alias multicolor: std_logic is control(1);	-- 1 for each char having own fg/bg color, 1 for common fg/bg
alias hires: std_logic is control(0);	-- 1 for 60*34, 0 for 30*17

-- these will eventually later be modifible
constant color_bg: std_logic_vector(7 downto 0) := "00011111"; -- cyan
constant color_fg: std_logic_vector(7 downto 0) := "00000011"; -- blue
constant baseaddress_text:  std_logic_vector(15 downto 0) := X"1000";
constant baseaddress_color: std_logic_vector(15 downto 0) := X"1800";

-- x, y counters are conveniently set up to start displaying from 0, 0; so "negative" values mean blank
alias VBlank: std_logic is pixel_y(11);
alias HBlank: std_logic is pixel_x(11);

-- "char" and "pixel" parts
alias col_div8: std_logic_vector(6 downto 0) is pixel_col(11 downto 3);
alias col_mod8: std_logic_vector(2 downto 0) is pixel_col(2 downto 0);
alias row_div8: std_logic_vector(6 downto 0) is pixel_row(11 downto 3);
alias row_mod8: std_logic_vector(2 downto 0) is pixel_row(2 downto 0);

signal color_multicolor, color_bichrome: std_logic_vector(7 downto 0);

begin

-- drive outputs
blank <= not display_enable;
color <= color_multicolor when (multicolor = '1') else color_bichrome;

-- trick to half the resolution
pixel_col <= Pixel_x when (hires = '1') else Pixel_x(11) & Pixel_x(11 downto 1);
pixel_row <= Pixel_y when (hires = '1') else Pixel_y(11) & Pixel_y(11 downto 1);

-- parallel color paths
color_bichrome <= color_fg when (final_pixel = '1') else color_bg;
color_multicolor <= palette_fg when (final_pixel = '1') else palette_bg;

palette_hi: color_rom port map (
	a => colorcode(7 downto 0),
	d => paletter_fg
);

palette_lo: color_rom port map (
	a => colorcode(3 downto 0),
	d => paletter_bg
);

-- character and color paths
charbuffer: dual_ram port map (
	d_in => D,
	a_write => col_div8,
	a_read => col_div8,
	bankselect => row_dma(0),
	nWE =>
	d_out => charcode
);

colorbuffer: dual_ram port map (
	d_in => D,
	a_write => col_div8,
	a_read => col_div8,
	bankselect => row_dma(0),
	nWE =>
	d_out => colorcode
);

-- character to pixel path
chargen: chargen_rom port map (
	a(10 downto 3) => charcode,
	a(2 downto 0) => row_mod8,
	d => chargen_data
);

with col_mod8 select
	chargen_pixel <=  chargen_data(7) when "000",
							chargen_data(6) when "001",
							chargen_data(5) when "010",
							chargen_data(4) when "011",
							chargen_data(3) when "100",
							chargen_data(2) when "101",
							chargen_data(1) when "110",
							chargen_data(0) when others;

-- TODO cursor logic comes here
final_pixel <= chargen_pixel;
							
-- DMA circuit
row_dma <= std_logic_vector(unsigned(row_div8) + 1);

offset: arraymapper port map(
	doublecols => hires,
	rows => row_dma,
	cols => col_div8,
	y => address_offset
);

address_char  <= std_logic_vector(unsigned(baseaddress_text) + unsigned("00000" & address_offset));
address_color <= std_logic_vector(unsigned(baseaddress_color) + unsigned("00000" & address_offset));

-- read/write sequence
-- ... XXXX012345670123456701234567...
-- ... -----RRRRRRR-RRRRRRR-RRRRRRR-.. master DMA read
-- ... ----------W-------W-------W--.. master color/text buffer write
-- 110 CCCCCCCCCCCCCCCCCCCCCCCCCCCCC.. master color DMA request (only in hires mode)
-- 111 TTTTTTTTTTTTTTTTTTTTTTTTTTTTT.. master text DMA request
readMaster <= '0' when (col_mod8 = "000") else not pixel_col(0);
writeMaster <= not pixel_col(0) when (col_mod8 = "110") else '0';
colorBusRequest <= hires when (row_mod8 = "110") else '0';
textBusRequest  <= '1' when (row_mod8 = "111") else '0';  
 
BusRequest <= (colorBusRequest or textBusRequest) when () else '0';
A <= "ZZZZZZZZZZZZZZZZ" when (BusAck = '0') else ;
nRD <= 'Z' when (BusAck = '0) else 
end Behavioral;

