----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    simpledevice - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Simple wrapper around https://github.com/jakubcabal/uart-for-fpga
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

entity simpledevice is
    Port ( clk: in std_logic;
			  reset: in std_logic;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC_VECTOR(3 downto 0);
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
			  IntReq: buffer std_logic;
			  txd: out std_logic;
			  rxd: in std_logic;
           direct_in : in  STD_LOGIC_VECTOR (15 downto 0);
           direct_out : out STD_LOGIC_VECTOR (15 downto 0));
end simpledevice;

architecture Behavioral of simpledevice is

--
-- https://github.com/jakubcabal/uart-for-fpga
-- 
component UART is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        CLK         : in  std_logic; -- system clock
        RST         : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD    : out std_logic; -- serial transmit data
        UART_RXD    : in  std_logic; -- serial receive data
        -- USER DATA INPUT INTERFACE
        DATA_IN     : in  std_logic_vector(7 downto 0); -- input data
        DATA_SEND   : in  std_logic; -- when DATA_SEND = 1, input data are valid and will be transmit
        BUSY        : out std_logic; -- when BUSY = 1, transmitter is busy and you must not set DATA_SEND to 1
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT    : out std_logic_vector(7 downto 0); -- output data
        DATA_VLD    : out std_logic; -- when DATA_VLD = 1, output data are valid
        FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid
    );
end component;

--type memory16x8 is array(0 to 15) of std_logic_vector(7 downto 0);
--signal ports: memory16x8 := (
--	others => X"FF"
--);

signal d_out, rxd_data, rxd_status: std_logic_vector(7 downto 0);
signal status: std_logic_vector(7 downto 0);
signal txd_pulse, wr0, wr1: std_logic;
signal status_pulse, rd0, rd1: std_logic;
signal readSelect, writeSelect: std_logic;
signal data_addr, status_addr: std_logic;
signal valid, busy, error: std_logic;
signal wr_shift, rd_shift: std_logic_vector(7 downto 0);

begin

readSelect <= nSelect nor nRead;
writeSelect <= nSelect nor nWrite;

data_addr <= '1' when (A = "0000") else '0';
status_addr <= '1' when (A = "0001") else '0';

txd_pulse <= data_addr when (wr_shift(7 downto 1) /= "0000000") else '0'; 
status_pulse <= status_addr when (rd_shift(7 downto 1) /= "0000000") else '0';

D <= d_out when (readSelect = '1') else "ZZZZZZZZ";
d_out <= rxd_data when A(0) = '0' else rxd_status; 

sio: UART 
	 generic map 
	 (
		--CLK_FREQ => 100e6,
		BAUD_RATE => 19200 -- more inline with 80ies era...
		--PARITY_BIT => "even"
	 )
	 port map 
	 (
        CLK => clk,
        RST => reset,
        -- UART INTERFACE
        UART_TXD => txd, -- serial transmit data
        UART_RXD => rxd, -- serial receive data
        -- USER DATA INPUT INTERFACE
        DATA_IN  => D,
        DATA_SEND => txd_pulse,
        BUSY  => busy,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT => rxd_data,
        DATA_VLD => valid,
        FRAME_ERROR => error
    );

generate_intreq: process(reset, status_pulse, valid)
begin
	if (reset = '1' or status_pulse = '1') then
		IntReq <= '0';
	else
		if rising_edge(valid) then
			IntReq <= '1';
		end if;
	end if;
end process;

capture_status: process(reset, busy, valid, error, status_pulse)
begin
	if (reset = '1') then
		status <= "00000000";
	else
		if rising_edge(status_pulse) then
			status <= (busy, valid, error, '0', '0', '0', '0', '0');
		end if;
	end if;
end process;

generate_wr: process(clk, writeSelect)
begin
	if (writeSelect = '1') then
		if rising_edge(clk) then
			wr_shift <= wr_shift(6 downto 0) & '0';
		end if;
	else
		wr_shift <= "00000001";
	end if;
end process;

generate_rd: process(clk, readSelect)
begin
	if (readSelect = '1') then
		if rising_edge(clk) then
			rd_shift <= rd_shift(6 downto 0) & '0';
		end if;
	else
		rd_shift <= "00000001";
	end if;
end process;


--internal_write: process(writeSelect, A, D)
--begin
--	if (writeSelect = '1') then
--		case A is
--			when X"0" => -- set output data
--				d_in <= D;
--			when others =>
--				--ports(to_integer(unsigned(A))) <= D;
--				null;
--		end case;
--	end if;
--end process;

--internal_read: process(readSelect, A, direct_in)
--begin
--	if (readSelect = '1') then
--		case A is
--			when X"0" => -- read input data
--				d_or_s <= d_out;
--			when X"1" => -- read status
--				d_or_s <= status;
--			when others =>
--				null;
--				--d_out <= ports(to_integer(unsigned(A)));
--		end case;
--	end if;
--end process;

end Behavioral;

