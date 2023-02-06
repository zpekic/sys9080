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
			  baudrate: in STD_LOGIC;
			  D : inout  STD_LOGIC_VECTOR (7 downto 0);
           A : in  STD_LOGIC;
           nRead : in  STD_LOGIC;
           nWrite : in  STD_LOGIC;
           nSelect : in  STD_LOGIC;
			  IntReq: out std_logic;
			  IntAck: in STD_LOGIC;
			  txd: out std_logic;
			  rxd: in std_logic;
			  rts: out STD_LOGIC;
			  cts: in STD_LOGIC
			  );
end ACIA;

architecture Behavioral of ACIA is

--
-- http://www.volkerschatz.com/hardware/vhdocl-example/sources/acia6850.html
-- 
component acia6850 is 
  port ( 
    -- 
    -- CPU Interface signals 
    -- 
    clk      : in  std_logic;                     -- System Clock 
    rst      : in  std_logic;                     -- Reset input (active high) 
	 cs       : in  std_logic;                     -- miniUART Chip Select 
    addr     : in  std_logic;                     -- Register Select 
    rw       : in  std_logic;                     -- Read / Not Write 
    data_in  : in  std_logic_vector(7 downto 0);  -- Data Bus In 
    data_out : out std_logic_vector(7 downto 0);  -- Data Bus Out 
    irq      : out std_logic;                     -- Interrupt Request out 
    -- 
    -- RS232 Interface Signals 
    -- 
    RxC   : in  std_logic;              -- Receive Baud Clock 
    TxC   : in  std_logic;              -- Transmit Baud Clock 
    RxD   : in  std_logic;              -- Receive Data 
    TxD   : out std_logic;              -- Transmit Data 
    DCD_n : in  std_logic;              -- Data Carrier Detect 
    CTS_n : in  std_logic;              -- Clear To Send 
    RTS_n : out std_logic               -- Request To send 
    ); 
end component;  --================== End of entity ==============================-- 

signal data_out: std_logic_vector(7 downto 0);
signal cs, irq6850: std_logic;
signal readDelay, writeDelay: std_logic_vector(3 downto 0);
signal nReadAccess, nWriteAccess: std_logic;
signal clean_one, clean_zero, rxd_clean, n_rxd_clean: std_logic;
signal shiftreg: std_logic_vector(7 downto 0);

begin
	
	D <= data_out when (nReadAccess = '0') else "ZZZZZZZZ";
	cs <= nReadAccess nand nWriteAccess;
	
	ic: acia6850 port map
	(
    -- CPU Interface signals 
    clk => clk,   		-- System Clock 
    rst => reset,			-- Reset input (active high) 
    cs => cs,				-- miniUART Chip Select 
    addr => A,          -- Register Select 
    rw => nWrite,       -- Read / Not Write 
    data_in => D,  		-- Data Bus In 
    data_out => data_out,  -- Data Bus Out 
    irq => irq6850,       -- Interrupt Request out 
    -- RS232 Interface Signals 
    RxC   => baudrate,         -- Receive Baud Clock 
    TxC   => baudrate,         -- Transmit Baud Clock 
    RxD   => rxd_clean,  		 -- Receive Data 
    TxD   => txd,              -- Transmit Data 
    DCD_n => '0',              -- Data Carrier Detect 
    CTS_n => cts,              -- Clear To Send 
    RTS_n => rts               -- Request To send 
   ); 

	irq: process(reset, IntAck, irq6850)
	begin
		if (reset = '1' or IntAck = '1') then
			IntReq <= '0';
		else
			if (rising_edge(irq6850)) then
				IntReq <= '1';
			end if;
		end if;
	end process;
	
--	ready <= readDelay(3) and writeDelay(3);
	
	nReadAccess <= nSelect or nRead;
	rdReady: process(clk, nReadAccess)
	begin
		if (nReadAccess = '1') then
			readDelay <= "1000";
		else
			if (rising_edge(clk)) then
				readDelay <= readDelay(2 downto 0) & (not nReadAccess);
			end if;
		end if;
	end process;
	
	nWriteAccess <= nSelect or nWrite;
	wrReady: process(clk, nWriteAccess)
	begin
		if (nWriteAccess = '1') then
			writeDelay <= "1000";
		else
			if (rising_edge(clk)) then
				writeDelay <= writeDelay(2 downto 0) & (not nWriteAccess);
			end if;
		end if;
	end process;
	
	-- debounce rxd ---
	--clean_one  <= '1' when shiftreg = X"F" else '0';
	--clean_zero <= '1' when shiftreg = X"0" else '0';
	
	--rxd_clean <= clean_zero nor n_rxd_clean;
	--n_rxd_clean <= clean_one nor rxd_clean;
	
	rxd_clean <= '1' when shiftreg = X"FF" else '0';
	clean_rxd: process(rxd, clk)
	begin
		if (rising_edge(clk)) then
			shiftreg <= shiftreg(6 downto 0) & rxd;
		end if;
	end process;
	
end Behavioral;

