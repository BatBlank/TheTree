library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity STRAND_DRIVER is
generic (
	NUM_LEDS	: integer := 30
);
port (
	CLK_16	: in std_logic;
	DATA_OUT	: out std_logic
);
end STRAND_DRIVER;

architecture arch of STRAND_DRIVER is
	constant NUM_BITS	: integer := NUM_LEDS * 24;
	type state_type is (RESET, ONE_HIGH, ONE_LOW, ZERO_HIGH, ZERO_LOW, STRAND_CLEAR);
	signal state	: state_type := RESET;
	
	signal lastState : std_logic := '0';
	signal clkCnt, bitCnt : unsigned(31 downto 0);
begin

main_proc : process (CLK_16)
begin
	-- For now, just create a state machine that pukes out 30 LEDs of '1'
	-- and then wait for a full second. Then output 30 LEDs of '0' then wait
	-- for a second. Repeat that over and over to prove it works
	if rising_edge(CLK_16) then
		case state is
			when RESET =>
				DATA_OUT	<= '0';
				bitCnt	<= (others=>'0');
				-- Sleep for a second before making a decision
				if clkCnt < 16000000-1 then
					clkCnt	<= clkCnt + 1;
				else
					-- Check to see what the last output strand was and alternate
					if lastState = '0' then
						state	<= ONE_HIGH;
					else
						-- TODO: This should be ZERO_HIGH
						state <= ONE_HIGH;
					end if;
					
					-- Reset clkCnt and alternate lastState
					clkCnt		<= (others=>'0');
					lastState	<= not lastState;
				end if;
				
			when ONE_HIGH =>
				-- Assert the output high for 13 clocks then go low
				DATA_OUT	<= '1';
				if clkCnt < 13-1 then
					clkCnt	<= clkCnt + 1;
				else
					clkCnt	<= (others=>'0');
					state		<= ONE_LOW;
				end if;
				
			when ONE_LOW =>
				-- Assert output low for 7 clocks
				DATA_OUT	<= '0';
				if clkCnt < 7-1 then
					clkCnt	<= clkCnt + 1;
				else
					-- Reset clkCnt
					clkCnt	<= (others=>'0');
					
					-- Check to see if we have output NUM_BITS yet
					if bitCnt < NUM_BITS-1 then
						bitCnt	<= bitCnt + 1;
						state		<= ONE_HIGH;
					else
						bitCnt	<= (others=>'0');
						state		<= STRAND_CLEAR;
					end if;
				end if;
				
			when ZERO_HIGH =>
			when ZERO_LOW =>
			when STRAND_CLEAR =>
				-- Simply output zero for 800 clocks to reset the strand
				if clkCnt < 800-1 then
					clkCnt	<= clkCnt + 1;
				else
					clkCnt	<= (others=>'0');
					state		<= RESET;
				end if;
		end case;
	end if;
end process main_proc;
	
end arch;