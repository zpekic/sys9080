----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:05:20 01/15/2019 
-- Design Name: 
-- Module Name:    ns32081 - Behavioral 
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

entity ns32081 is
    Port ( -- CPU bus signals --
           nReset : in  STD_LOGIC;
           nRD : in  STD_LOGIC;
           nWR : in  STD_LOGIC;
           nSel : in  STD_LOGIC;
			  a : in STD_LOGIC_VECTOR (3 downto 0);
           D : inout  STD_LOGIC_VECTOR (7 downto 0);
			  ready : out STD_LOGIC;
			  done: buffer STD_LOGIC;
			  internalstate: out STD_LOGIC_VECTOR(7 downto 0);
			  -- NS32081 bus signals --
			  fpu_clkin : in STD_LOGIC;
           fpu_clkout : out  STD_LOGIC;
           fpu_nRst : out  STD_LOGIC;
           fpu_nSpc : inout  STD_LOGIC;
           fpu_s : out STD_LOGIC_VECTOR (1 downto 0);
           fpu_d : inout  STD_LOGIC_VECTOR (15 downto 0));
end ns32081;

architecture Behavioral of ns32081 is

constant s_id: 										std_logic_vector(1 downto 0) := "11";
constant s_operation, s_operand, s_result: 	std_logic_vector(1 downto 0) := "01";
constant s_status: 									std_logic_vector(1 downto 0) := "10";
constant s_undefined:								std_logic_vector(1 downto 0) := "00";

constant fpu_rd, spc_rd, cpu_wait, spc_inactive:	std_logic := '0';
constant fpu_wr, spc_wr, cpu_cont, spc_active: 	std_logic := '1';

signal rd, wr: std_logic := '0';
signal spc_received: std_logic_vector(7 downto 0) := X"00";
signal resetCnt: std_logic_vector(7 downto 0);
signal elapsedCnt: std_logic_vector(15 downto 0);

signal fpu_in, fpu_out: std_logic_vector(15 downto 0);
signal datamux, fpuinmux: std_logic_vector(7 downto 0);

signal fpu_operation: std_logic_vector(7 downto 0) := cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;
alias cpu_continue: std_logic is fpu_operation(7);
-- 2 bits for future use
alias fpu_direction: std_logic is fpu_operation(4);
alias spc_direction: std_logic is fpu_operation(3);
alias spc_state: std_logic is fpu_operation(2);
alias s: std_logic_vector(1 downto 0) is fpu_operation(1 downto 0);

signal cpu_operation: std_logic_vector(1 downto 0) := "11";
alias writeReady: std_logic is cpu_operation(1);
alias readReady: std_logic is cpu_operation(0);

type state is (st_reset, 			-- 0
					st_readytostart, 	-- 1
					-- WRITE SEQUENCE
					st_cpuwrite,							--2
					st_cpuwrite_lobyte,					--3
					st_cpuwrite_hibyte_id0,				--4	
					st_cpuwrite_hibyte_id1,				--5
					st_cpuwrite_hibyte_id2,				--6
					st_cpuwrite_hibyte_operation0,	--7
					st_cpuwrite_hibyte_operation1,	--8
					st_cpuwrite_hibyte_operation2,	--9
					st_cpuwrite_hibyte_operand0,		--A
					st_cpuwrite_hibyte_operand1,		--B
					st_cpuwrite_hibyte_operand2,		--C
					--		READ SEQUENCE		
					st_cpuread,								--D
					st_cpuread_lobyte_status0,			--E
					st_cpuread_lobyte_status1,			--F
					st_cpuread_lobyte_status2,			--10
					st_cpuread_lobyte_result0,			--11
					st_cpuread_lobyte_result1,			--12
					st_cpuread_lobyte_result2,			--13
					st_cpuread_hibyte,					--14
					--		COMMON END
					st_continue								--15
					);
					
signal state_current, state_next: state;

begin

fpu_clkout <= fpu_clkin;
fpu_nRst <= resetCnt(7); -- trick to start from positive and flip to negative
fpu_s <= s;
done <= '1' when (spc_received = X"FF") else '0';

-- reset pulse should last at least 64 clocks
generatereset: process(nReset, fpu_clkin)
begin
	if (nReset = '0') then
		resetCnt <= X"00"; -- TODO, change to X"40" or similar
	else
		if (falling_edge(fpu_clkin) and resetCnt(7) = '0') then
			resetCnt <= std_logic_vector(unsigned(resetCnt) + 1);
		end if;
	end if;
end process;

--internalstate <= writeReady & readReady & '0' & cpu_continue & a;
--internalstate <= fpu_operation; --cpu_continue & cpu_busvector & std_logic_vector(to_unsigned(state'POS(state_current), 4));
internalstate <= done & std_logic_vector(to_unsigned(state'POS(state_current), 7));
--internalstate <= fpu_d(7 downto 0);

-- as soon as CPU reads, block it until state machine completes
rd <= not (nSel or nRD);
waitOnRead: process(rd, nReset, cpu_continue, writeReady)
begin
	if (nReset = '0' or cpu_continue = '1' or writeReady = '0') then
		readReady <= '1';
	else
		if (rising_edge(rd)) then
			readReady <= '0';
		end if;
	end if;
end process; 

-- as soon as CPU writes, block it until state machine completes
wr <= not (nSel or nWR);
waitOnWrite: process(wr, nReset, cpu_continue, readReady)
begin
	if (nReset = '0' or cpu_continue = '1' or readReady = '0') then
		writeReady <= '1';
	else
		if (rising_edge(wr)) then
			writeReady <= '0';
		end if;
	end if;
end process; 

ready <= readReady and writeReady;

-- nSPC can be input and output
fpu_nSPC <= not spc_state when (spc_direction = spc_wr) else 'Z';

-- fpu_d can be input and output
fpu_d <= fpu_out when (fpu_direction = fpu_wr) else "ZZZZZZZZZZZZZZZZ";

-- return data path to CPU
with a(3 downto 0) select
	datamux <= 	spc_received when 		 "0000", -- done
					spc_received when			 "0001", -- done
					fpu_in(7 downto 0) when  "0010", -- status
					fpu_in(15 downto 8) when "0011",	-- status
					fpu_in(7 downto 0) when  "0100", -- result
					fpu_in(15 downto 8) when "0101", -- result
					fpu_in(7 downto 0) when  "0110", -- result
					fpu_in(15 downto 8) when "0111", -- result
					elapsedCnt(7 downto 0) when  "1000", -- elapsed cycles
					elapsedCnt(15 downto 8) when "1001", -- elapsed cycles
					X"00" when others;
D <= datamux when rd = '1' else "ZZZZZZZZ"; 

-- update the done bit!
setdone: process(nReset, spc_state, spc_direction, fpu_nSpc)
begin
	if ((nReset = '0') or (spc_state and spc_direction) = '1') then
		spc_received <= X"00";
	else
		if (falling_edge(fpu_nSpc)) then -- the FPU is supposed to pull it low!
			spc_received <= X"FF";
		end if;
	end if;
end process;

-- instruction timer counter
stopwatch: process(nReset, spc_state, spc_direction, fpu_clkin)
begin
	if ((nReset = '0') or (spc_state and spc_direction) = '1') then
		elapsedCnt <= X"0000";
	else
		if (rising_edge(fpu_clkin) and done = '0') then
			elapsedCnt <= std_logic_vector(unsigned(elapsedCnt) + 1);
		end if;
	end if;
end process;


-- FSM
drive: process(nReset, fpu_clkin, state_next)
begin
	if (nReset = '0') then
		state_current <= st_reset;
	else
		if (rising_edge(fpu_clkin)) then
			state_current <= state_next;
		end if;
	end if;
end process;

execute: process(fpu_clkin, state_current)
begin
	if (rising_edge(fpu_clkin)) then
		case state_current is
			when st_reset =>
				fpu_operation <= cpu_cont & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;
				
			when st_readytostart =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;

	--		WRITE SEQUENCE
			when st_cpuwrite =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;

			when st_cpuwrite_lobyte =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;
				fpu_out(7 downto 0) <= D;
			
			when st_cpuwrite_hibyte_id0 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_id;
				fpu_out(15 downto 8) <= D;
				
			when st_cpuwrite_hibyte_id1 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_active & s_id;
				
			when st_cpuwrite_hibyte_id2 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_id;

			when st_cpuwrite_hibyte_operation0 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_operation;
				fpu_out(15 downto 8) <= D;
				
			when st_cpuwrite_hibyte_operation1 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_active & s_operation;
				
			when st_cpuwrite_hibyte_operation2 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_operation;

			when st_cpuwrite_hibyte_operand0 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_operand;
				fpu_out(15 downto 8) <= D;
				
			when st_cpuwrite_hibyte_operand1 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_active & s_operand;
				
			when st_cpuwrite_hibyte_operand2 =>
				fpu_operation <= cpu_wait & "00" & fpu_wr & spc_wr & spc_inactive & s_operand;
				

	--		READ SEQUENCE		
			when st_cpuread =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;

			when st_cpuread_lobyte_status0 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_inactive & s_status;

			when st_cpuread_lobyte_status1 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_active & s_status;

			when st_cpuread_lobyte_status2 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_inactive & s_status;
				fpu_in <= fpu_d;

			when st_cpuread_lobyte_result0 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_inactive & s_result;

			when st_cpuread_lobyte_result1 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_active & s_result;

			when st_cpuread_lobyte_result2 =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_wr & spc_inactive & s_result;
				fpu_in <= fpu_d;

			when st_cpuread_hibyte =>
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;

	--		COMMON END
			when st_continue =>
				fpu_operation <= cpu_cont & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;

			when others => 
				fpu_operation <= cpu_wait & "00" & fpu_rd & spc_rd & spc_inactive & s_undefined;
					
		end case;
	end if;
end process;

sequence: process(state_current, cpu_operation) 
begin
--		COMMON START --	
	case state_current is
		when st_reset =>
			state_next <= st_readytostart;

		when st_readytostart =>
			case cpu_operation is
				when "00" =>
					state_next <= st_continue;
				when "01" =>
					state_next <= st_cpuwrite;
				when "10" =>
					state_next <= st_cpuread;
				when others =>
					state_next <= st_readytostart;
			end case;
			
--		WRITE SEQUENCE
		when st_cpuwrite =>
			if (a(0) = '0') then
				state_next <= st_cpuwrite_lobyte;
			else
				case a(3 downto 1) is
					when "000" => -- 0, 1 == 00BF or 003F
						state_next <= st_cpuwrite_hibyte_id0;
					when "001" => -- 2, 3 == operation
						state_next <= st_cpuwrite_hibyte_operation0;
					when "010" => -- 4, 5 == operand 1, lo
						state_next <= st_cpuwrite_hibyte_operand0;
					when "011" => -- 6, 7 == operand 1, hi
						state_next <= st_cpuwrite_hibyte_operand0;
					when "100" => -- 8, 9 == operand 2, lo
						state_next <= st_cpuwrite_hibyte_operand0;
					when "101" => -- 10, 11 == operand 2, hi
						state_next <= st_cpuwrite_hibyte_operand0;
					when others =>						
						state_next <= st_continue;
				end case;
			end if;

		when st_cpuwrite_hibyte_id0 =>
			state_next <= st_cpuwrite_hibyte_id1;
			
		when st_cpuwrite_hibyte_id1 =>
			state_next <= st_cpuwrite_hibyte_id2;
			
		when st_cpuwrite_hibyte_operation0 =>
			state_next <= st_cpuwrite_hibyte_operation1;
			
		when st_cpuwrite_hibyte_operation1 =>
			state_next <= st_cpuwrite_hibyte_operation2;

		when st_cpuwrite_hibyte_operand0 =>
			state_next <= st_cpuwrite_hibyte_operand1;

		when st_cpuwrite_hibyte_operand1 =>
			state_next <= st_cpuwrite_hibyte_operand2;

--		READ SEQUENCE		
		when st_cpuread =>
			if (a(0) = '1') then
				state_next <= st_cpuread_hibyte;
			else
				case a(3 downto 1) is
					when "001" => -- 2, 3
						state_next <= st_cpuread_lobyte_status0;
					when "010" => -- 4, 5
						state_next <= st_cpuread_lobyte_result0;
					when "011" => -- 6, 7
						state_next <= st_cpuread_lobyte_result0;
					when others =>
						state_next <= st_continue;
				end case;
			end if;

		when st_cpuread_lobyte_status0 =>
			state_next <= st_cpuread_lobyte_status1;

		when st_cpuread_lobyte_status1 =>
			state_next <= st_cpuread_lobyte_status2;

		when st_cpuread_lobyte_result0 =>
			state_next <= st_cpuread_lobyte_result1;

		when st_cpuread_lobyte_result1 =>
			state_next <= st_cpuread_lobyte_result2;

--		COMMON END
		when st_continue =>
			state_next <= st_readytostart;
			
		when others =>
			state_next <= st_continue;
	end case;
end process;

end Behavioral;

