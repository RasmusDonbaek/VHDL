
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_uart_rx is
--  Port ( );
end tb_uart_rx;

architecture Testbench of tb_uart_rx is

component uart_rx
  Port ( RESET_I    : in STD_LOGIC;
         CLK_UART_I : in STD_LOGIC;
         RX_I       : in STD_LOGIC;
         DATA_O     : out STD_LOGIC_VECTOR (7 downto 0);
         STB_O      : out STD_LOGIC);
end component;

signal reset : std_logic := '1';
signal clk : std_logic := '0';
signal rx : std_logic := '1';

signal data : std_logic_vector(7 downto 0);
signal strobe : std_logic;


constant PERIOD      : time := 20 ns; -- 50 MHz clock  

begin

  reset <= '0' after 5 * PERIOD;
  clk <= not clk after (PERIOD/2.0);  
  
    --Simulation input
  process
  begin
    -- Wait for 'reset' to go Low
    wait for (10 * PERIOD);
    
    -- Send 1 byte of data
    rx <= '0'; wait for (16 * PERIOD); -- start bit
    rx <= '1'; wait for (16 * PERIOD); -- bit 0
    rx <= '0'; wait for (16 * PERIOD); -- bit 1
    rx <= '1'; wait for (16 * PERIOD); -- bit 2
    rx <= '0'; wait for (16 * PERIOD); -- bit 3
    rx <= '1'; wait for (16 * PERIOD); -- bit 4
    rx <= '0'; wait for (16 * PERIOD); -- bit 5
    rx <= '1'; wait for (16 * PERIOD); -- bit 6
    rx <= '0'; wait for (16 * PERIOD); -- bit 7
    rx <= '1'; wait for (16 * PERIOD); -- stop bit
    
    -- Wait a short while
    wait for (10 * PERIOD);
    
    -- Send 2 bytes of data
    rx <= '0'; wait for (16 * PERIOD); -- start bit
    rx <= '1'; wait for (16 * PERIOD); -- bit 0
    rx <= '1'; wait for (16 * PERIOD); -- bit 1
    rx <= '1'; wait for (16 * PERIOD); -- bit 2
    rx <= '1'; wait for (16 * PERIOD); -- bit 3
    rx <= '0'; wait for (16 * PERIOD); -- bit 4
    rx <= '0'; wait for (16 * PERIOD); -- bit 5
    rx <= '0'; wait for (16 * PERIOD); -- bit 6
    rx <= '0'; wait for (16 * PERIOD); -- bit 7
    rx <= '1'; wait for (16 * PERIOD); -- stop bit
    
    -- No pause, send the next byte right away
    rx <= '0'; wait for (16 * PERIOD); -- start bit
    rx <= '0'; wait for (16 * PERIOD); -- bit 0
    rx <= '0'; wait for (16 * PERIOD); -- bit 1
    rx <= '1'; wait for (16 * PERIOD); -- bit 2
    rx <= '1'; wait for (16 * PERIOD); -- bit 3
    rx <= '0'; wait for (16 * PERIOD); -- bit 4
    rx <= '0'; wait for (16 * PERIOD); -- bit 5
    rx <= '1'; wait for (16 * PERIOD); -- bit 6
    rx <= '1'; wait for (16 * PERIOD); -- bit 7
    rx <= '1'; wait for (16 * PERIOD); -- stop bit
    
    wait; --wait forever
  end process;


U1:uart_rx
Port Map (
  RESET_I => reset,
  CLK_UART_I => clk,
  RX_I => rx,
  DATA_O => data,
  STB_O => strobe);

end Testbench;
