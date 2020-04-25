
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_uart_tx is
--  Port ( );
end tb_uart_tx;

architecture Testbench of tb_uart_tx is

component uart_tx
  Port ( RESET_I    : in STD_LOGIC;
         CLK_UART_I : in STD_LOGIC; 
         DATA_I     : in STD_LOGIC_VECTOR (7 downto 0);
         WR_I       : in STD_LOGIC;
         TX_O       : out STD_LOGIC;
         BUSY_O     : out STD_LOGIC);
end component;

signal reset : std_logic := '1';
signal clk : std_logic := '0';
signal data : std_logic_vector(7 downto 0) := "01010101";
signal strobe : std_logic := '0';
signal tx : std_logic;
signal busy : std_logic;

constant PERIOD      : time := 20 ns; -- 50 MHz clock  

begin

  reset <= '0' after 5 * PERIOD;
  clk <= not clk after (PERIOD/2.0);  
  
    --Simulation input
  process
  begin
    -- Wait for 'reset' to go Low
    wait for (10 * PERIOD);
    
    -- Pulse the strobe
    strobe <= '1';
    wait for (PERIOD / 4);
    strobe <= '0';
    
    -- Wait while transmitting
    wait for (170 * PERIOD);
    
    -- Pulse the strobe again
    strobe <= '1';
    wait for 48 ns;
    strobe <= '0';
    
    wait; --wait forever
  end process;
  
U1:uart_tx
Port Map(
  RESET_I => reset,
  CLK_UART_I => clk,
  DATA_I => data,
  WR_I => strobe,
  TX_O => tx,
  BUSY_O => busy);

end Testbench;
