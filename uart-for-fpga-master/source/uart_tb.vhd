--------------------------------------------------------------------------------
-- PROJECT: SIMPLE UART FOR FPGA
--------------------------------------------------------------------------------
-- MODULE:  TESTBANCH OF UART TOP MODULE
-- AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
-- LICENSE: The MIT License (MIT), please read LICENSE file
-- WEBSITE: https://github.com/jakubcabal/uart_for_fpga
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_TB is
end UART_TB;

architecture FULL of UART_TB is

	signal CLK           : std_logic := '0';
	signal RST           : std_logic := '0';
	signal tx_uart       : std_logic;
	signal rx_uart       : std_logic := '1';
	signal data_vld      : std_logic;
	signal data_out      : std_logic_vector(7 downto 0);
	signal frame_error   : std_logic;
	signal data_send     : std_logic;
	signal busy          : std_logic;
	signal data_in       : std_logic_vector(7 downto 0);

    constant clk_period  : time := 20 ns;
	constant uart_period : time := 8680.56 ns;
	constant data_value  : std_logic_vector(7 downto 0) := "10100111";
	constant data_value2 : std_logic_vector(7 downto 0) := "00110110";

begin

	utt: entity work.UART
    generic map (
        CLK_FREQ    => 50e6,
        BAUD_RATE   => 115200,
        PARITY_BIT  => "none"
    )
    port map (
        CLK         => CLK,
        RST         => RST,
        -- UART INTERFACE
        UART_TXD    => tx_uart,
        UART_RXD    => rx_uart,
        -- USER DATA INPUT INTERFACE
        DATA_OUT    => data_out,
        DATA_VLD    => data_vld,
        FRAME_ERROR => frame_error,
        -- USER DATA OUTPUT INTERFACE
        DATA_IN     => data_in,
        DATA_SEND   => data_send,
        BUSY        => busy
    );

	clk_process : process
	begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
	end process;

	test_rx_uart : process
	begin
		rx_uart <= '1';
		RST <= '1';
		wait for 100 ns;
    	RST <= '0';

		wait until rising_edge(CLK);

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to (data_value'LENGTH-1) loop
			rx_uart <= data_value(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		rx_uart <= '0'; -- start bit
		wait for uart_period;

		for i in 0 to (data_value2'LENGTH-1) loop
			rx_uart <= data_value2(i); -- data bits
			wait for uart_period;
		end loop;

		rx_uart <= '1'; -- stop bit
		wait for uart_period;

		wait;

	end process;

	test_tx_uart : process
	begin
		data_send <= '0';
		RST <= '1';
		wait for 100 ns;
      	RST <= '0';

		wait until rising_edge(CLK);

		data_send <= '1';
		data_in <= data_value;

		wait until rising_edge(CLK);

		data_send <= '0';

		wait until rising_edge(CLK);

		wait for 80 us;
		wait until rising_edge(CLK);

		data_send <= '1';
		data_in <= data_value2;

		wait until rising_edge(CLK);

		data_send <= '0';

		wait until rising_edge(CLK);

		wait;

	end process;

end FULL;
