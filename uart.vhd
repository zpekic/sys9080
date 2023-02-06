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
--use IEEE.NUMERIC_STD.ALL;

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

signal d_out, rdr, status: std_logic_vector(7 downto 0);
signal tdre, rdrf, rdr_ok, send: std_logic;

begin

D <= d_out when ((nCS or nRD) = '0') else "ZZZZZZZZ"; 
d_out <= rdr when (RS = '1') else status;
 
status(7) <= '0';	-- no interrupt
status(6) <= not rdr_ok;	-- parity error	
status(5) <= not rdr_ok;	-- receiver overrun
status(4) <= not rdr_ok;	-- framing error
status(3) <= '0';				-- clear to send
status(2) <= '0';				-- data carrier detected
status(1) <= tdre;			-- transmit register empty
status(0) <= rdrf;			-- receive data register full
  
send <= RS and (not nCS) and (not nWR) and (not clk);
 
sender: uart_par2ser Port map (
			reset => reset,
			txd_clk => clk_txd,
			send => send,
			mode => "000", -- 8N2
			data => D,
			ready => tdre,
			txd => txd
		);

receiver: uart_ser2par Port map ( 
			reset => reset, 
			rxd_clk => clk_rxd,
			mode => "000", -- 8N2
			char => rdr,
			ready => rdrf,
			valid => rdr_ok,
			rxd => rxd
		);

end Behavioral;

