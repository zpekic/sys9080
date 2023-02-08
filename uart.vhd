----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:58:35 02/05/2023 
-- Design Name: 
-- Module Name:    uart - Behavioral 
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

entity uart is
    Port ( reset : in  STD_LOGIC;
			  clk: in STD_LOGIC;
           clk_txd : in  STD_LOGIC;
           clk_rxd : in  STD_LOGIC;
           nCS : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           RS : in  STD_LOGIC;
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
			  ---
			  debug: out std_logic_vector(15 downto 0);
			  ---
           TXD : out  STD_LOGIC;
           RXD : in  STD_LOGIC);
end uart;

architecture Behavioral of uart is

component uart_par2ser is
    Port ( reset : in  STD_LOGIC;
			  txd_clk: in STD_LOGIC;
			  send: in STD_LOGIC;
			  mode: in STD_LOGIC_VECTOR(2 downto 0);
			  data: in STD_LOGIC_VECTOR(7 downto 0);
           ready : buffer STD_LOGIC;
           txd : out  STD_LOGIC);
end component;

component uart_ser2par is
    Port ( reset : in  STD_LOGIC;
           rxd_clk : in  STD_LOGIC;
           mode : in  STD_LOGIC_VECTOR (2 downto 0);
           char : out  STD_LOGIC_VECTOR (7 downto 0);
           ready : buffer  STD_LOGIC;
           valid : out  STD_LOGIC;
           rxd : in  STD_LOGIC);
end component;

signal d_out, rdr, status, control: std_logic_vector(7 downto 0);
signal tdre, rdrf, rdr_ok, send, received, ready, valid: std_logic; 
signal err_parity, err_frame, err_overrun: std_logic;
signal int_read, int_write, int_reset, int_txdclk, int_rxdclk: std_logic;
signal txdcnt, rxdcnt: std_logic_vector(5 downto 0);
signal mode: std_logic_vector(2 downto 0);
signal reset_receiver, reset_sender: std_logic;

begin

----
debug <= status & control;
----
int_read <= not (nCS or nRD);
int_write <= not (nCS or nWR);
int_reset <= control(1) and control(0);
send <= 		RS and int_write and (not clk);	-- trigger data register out
received <= RS and int_read and (not clk);	-- ack data register in
 
D <= d_out when (int_read = '1') else "ZZZZZZZZ"; 
d_out <= rdr when (RS = '1') else status;
 
status(7) <= '0';		-- no interrupt
status(6) <= err_parity;	-- parity error	
status(5) <= err_overrun;	-- receiver overrun
status(4) <= err_frame;		-- framing error
status(3) <= '0';		-- clear to send
status(2) <= '0';		-- data carrier detected
status(1) <= tdre;	-- transmit register empty
status(0) <= rdrf;	-- receive data register full
 
-- translate from MC6850 3-bit mode to internal mode 
with control(4 downto 2) select mode <=
	"101" when "100", -- 8 data, 2 stop
	"000" when "101",	-- 8 data, 1 stop
	"110" when "110",	-- 8 data, even parity, 1 stop
	"111" when "111",	-- 8 data, odd parity, 1 stop
	"000" when others;	-- no 7 bit data supported, default to 8-N-1

reset_sender <= reset or int_reset; 
sender: uart_par2ser Port map (
			reset => reset_sender,
			txd_clk => int_txdclk,
			send => send,
			mode => mode, 
			data => D,
			ready => tdre,
			txd => txd
		);

reset_receiver <= reset or int_reset or received;
receiver: uart_ser2par Port map ( 
			reset => reset_receiver, 
			rxd_clk => int_rxdclk,
			mode => mode, 
			char => rdr,
			ready => ready,
			valid => valid,
			rxd => rxd
		);

-- load control register
on_clk: process(clk, reset, D, RS, int_write)
begin
	if (reset = '1') then
		control <= "00000011"; -- internal reset
	else
		if (rising_edge(clk) and (RS = '0') and (int_write = '1')) then
			control <= D;
		end if;
	end if;
end process;

-- TXD clock processing
on_clk_txd: process(clk_txd)
begin
	if (rising_edge(clk_txd)) then
		txdcnt <= std_logic_vector(unsigned(txdcnt) + 1);
	end if;
end process;

with control(1 downto 0) select int_txdclk <= 
		txdcnt(3) when "01", -- /16
		txdcnt(5) when "10", -- /64
		clk_txd when others;	-- /1

-- RXD clock processing
on_clk_rxd: process(clk_rxd)
begin
	if (rising_edge(clk_rxd)) then
		rxdcnt <= std_logic_vector(unsigned(rxdcnt) + 1);
	end if;
end process;

with control(1 downto 0) select int_rxdclk <= 
		rxdcnt(3) when "01", -- /16
		rxdcnt(5) when "10", -- /64
		clk_rxd when others;	-- /1

-- capture received serial data
on_ready: process(ready, reset, received)
begin
	if ((reset or received) = '1') then
		rdrf <= '0';
		err_parity <= '0';
		err_frame <= '0'; 
		err_overrun <= '0';
	else
		if (rising_edge(ready)) then
			rdrf <= '1';
			err_parity <= not valid;	-- not differentiated error
			err_frame <= not valid;		-- not differentiated error 
			err_overrun <= rdrf;			-- new data incoming and previous was not read
		end if;
	end if;
end process;
 
end Behavioral;

