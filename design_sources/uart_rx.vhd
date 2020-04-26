-- Description    : Receiving part of a UART module
-- Target Devices : Trenz Electronics board TE0890 with a Xilinx Spartan 7S25 FPGA.
-- How to use     : Put serial data on RX_I (1 start bit, 8 data bit, 1 stop bit).
--                  When the data is read the module pulses latches the data to DATA_O
--                  and pulses the strobe 'STB_O' for one clock cycle
--                  The transmission rate should be 16 times slower than the provided clock 'CLK_UART_I'.
-- Author         : Rasmus Donbaek Knudsen
-- Date           : 2020-04-25 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- used for '+' on std_logic_vector
use IEEE.NUMERIC_STD.ALL; -- used for 'to_integer' on unsigned values


entity uart_rx is
  Port ( RESET_I    : in STD_LOGIC;
         CLK_UART_I : in STD_LOGIC;
         RX_I       : in STD_LOGIC;
         DATA_O     : out STD_LOGIC_VECTOR (7 downto 0);
         STB_O      : out STD_LOGIC); -- Strobe... high for 1 clock cycle
end uart_rx;


architecture Behavioral of uart_rx is

  -- Alias's for readability
  alias reset  : std_logic is RESET_I;
  alias clk    : std_logic is CLK_UART_I; 
  alias rx     : std_logic is RX_I;
  
  -- Main State signals   
  type STATE_TYPE is (st_reset, st_ready, st_start_bit, st_receiving, st_stop_bit);
  signal current_state : STATE_TYPE   := st_reset;
  signal next_state    : STATE_TYPE   := st_reset;
  
  -- Sub State signals
  signal data    : std_logic_vector(7 downto 0) := (others => '0');
  signal bit_cnt : std_logic_vector(2 downto 0) := (others => '0');
  signal clk_cnt : std_logic_vector(3 downto 0) := (others => '0');
  
  -- Other signals
  signal data_o_sig : std_logic_vector(7 downto 0) := (others => '0');
  signal strobe_sig : std_logic := '0'; -- synchronous strobe signal
  
begin

-- Synchronously update of the Main & Sub States of this module
clocked: process(clk) begin
  
  if( clk'event and clk = '1') then 
    
    if(reset = '1') then
      current_state <= st_reset;
      data    <= (others => '0');
      bit_cnt <= (others => '0');
      clk_cnt <= (others => '0');
                   
    else
      -- Update the main state
      current_state <= next_state;
      
      -- Update substates
      bit_cnt    <= (others => '0'); -- default value
      clk_cnt    <= (others => '0'); -- default value
      strobe_sig <= '0';             -- default value
      data       <= data;            -- default behavior
      
      case current_state is
        when st_ready     => NULL; -- do nothing
        when st_start_bit => clk_cnt <= clk_cnt + 1;
        when st_receiving => clk_cnt <= clk_cnt + 1;
                             
                             if(clk_cnt = "0111") then -- read the value in the middle of the bit
                               data(to_integer(unsigned(bit_cnt))) <= rx;
                               bit_cnt <= bit_cnt + 1;
                             else
                               data <= data;
                               bit_cnt <= bit_cnt;
                             end if; 
                             
        when st_stop_bit  => clk_cnt <= clk_cnt + 1;
                             if(clk_cnt = "0111" and rx = '1') -- reading the stop bit correctly
                             then strobe_sig <= '1';
                             end if;
        when others       => NULL;
      end case; -- end update of sub states
    
    end if; -- end not reset   
  end if; -- clk rising edge    
end process clocked;


-- Asynchronous next state logic
nextstate : process(current_state, rx, clk_cnt, bit_cnt) begin
    
  next_state <= next_state; -- default value
  
  case current_state is
      when st_reset     => next_state <= st_ready;
      
      when st_ready     => if(rx = '0')
                           then next_state <= st_start_bit;
                           end if;
      
      when st_start_bit => if(rx = '1')            -- it was just noise, not a start bit
                           then next_state <= st_ready; 
                           elsif(clk_cnt = "0111") -- it is a start bit, now start receiving data
                           then next_state <= st_receiving;
                           end if;
                          
      when st_receiving => if(bit_cnt = "111" and clk_cnt = "0111")
                           then next_state <= st_stop_bit;
                           end if;
                          
      when st_stop_bit  => if(clk_cnt = "0111") -- or should it be "1111" or maybe "1000"
                           then next_state <= st_ready;
                           end if;
      
      when others      => NULL;
    end case;     
end process nextstate;


-- Asynchronous output logic
output : process (strobe_sig, data_o_sig, data) begin    
  
  DATA_O <= data_o_sig;
  STB_O  <= strobe_sig;
  
  -- Latch the internal data to the output data signal
  if(strobe_sig = '1')
  then data_o_sig <= data;      
  else data_o_sig <= data_o_sig;
  end if;
              
end process output;

end Behavioral;
