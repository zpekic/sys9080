----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:56:00 11/12/2017 
-- Design Name: 
-- Module Name:    ACIA - Behavioral 
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

entity ACIA is
    Port ( clk: in std_logic;
			  reset: in std_logic;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC;
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
			  IntReq: buffer std_logic;
			  IntAck: in STD_LOGIC;
			  txd: out std_logic;
			  rxd: in std_logic);
end ACIA;

architecture Behavioral of ACIA is

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

signal d_out, rxd_data: std_logic_vector(7 downto 0);
signal rd_data, wr_data, wr_data0, wr_data1, rd_status, data_send: std_logic;
signal readSelect, writeSelect: std_logic;
signal valid, busy, error, char_received, ready: std_logic;
signal status_valid, status_error: std_logic;

begin

readSelect <= nSelect nor nRead;
writeSelect <= nSelect nor nWrite;

wr_data <= writeSelect and A; 
rd_data <= readSelect and A ;
rd_status <= readSelect and not(A);

D <= d_out when (readSelect = '1') else "ZZZZZZZZ";
d_out <= rxd_data when (A = '1') else 
			(IntReq & status_error & "0000" & ready & status_valid);

sio: UART 
	 generic map 
	 (
		--CLK_FREQ => 100e6,
		BAUD_RATE => 38400 -- science fiction for the 80ies era...
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
        DATA_SEND => data_send,
        BUSY  => busy,
        -- USER DATA OUTPUT INTERFACE
        DATA_OUT => rxd_data,
        DATA_VLD => valid,
        FRAME_ERROR => error
    );

ready <= not busy;
data_send <= wr_data and not (wr_data1);
generate_sendpulse: process(reset, clk, busy, wr_data)
begin
	if (reset = '1') then
		wr_data0 <= '0';
		wr_data1 <= '0';
	else
		if (rising_edge(clk)) then
			wr_data1 <= wr_data0;
			wr_data0 <= wr_data;
		end if;
	end if;
end process;

char_received <= valid or error;
generate_intreq: process(reset, IntAck, rd_data, char_received)
begin
	if (reset = '1' or IntAck = '1' or rd_data = '1') then
		IntReq <= '0';
		status_error <= not(reset or rd_data);
		status_valid <= not(reset or rd_data);
	else
		if rising_edge(char_received) then
			IntReq <= '1';
			status_error <= error;
			status_valid <= valid;
		end if;
	end if;
end process;

end Behavioral;

