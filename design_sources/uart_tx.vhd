-- Description    : Transmitting part of a UART module
-- Target Devices : Trenz Electronics board TE0890 with a Xilinx Spartan 7S25 FPGA.
-- How to use     : Put data on DATA_I and pulse WR_I to begin sending the data on the TX_O line.
--                  BUSY_O will go high while the module is sending, and low again when it is done. 
--                  You can put new data on DATA_I while the module is still busy.
--                  The transmission rate will be 16 times slower than the provided clock 'CLK_UART_I'.
-- Author         : Rasmus Donbaek Knudsen
-- Date           : 2020-04-25

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- used for 'to_integer' on unsigned values
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- used for '+' on std_logic_vector


entity uart_tx is
  Port ( RESET_I    : in STD_LOGIC;
         CLK_UART_I : in STD_LOGIC; 
         DATA_I     : in STD_LOGIC_VECTOR (7 downto 0);
         WR_I       : in STD_LOGIC;
         TX_O       : out STD_LOGIC;
         BUSY_O     : out STD_LOGIC);
end uart_tx;


architecture Behavioral of uart_tx is

  -- Alias's for readability
  alias reset  : std_logic is RESET_I;
  alias clk    : std_logic is CLK_UART_I; 
  alias strobe : std_logic is WR_I;
  
  -- Main State signals  
  type STATE_TYPE is (st_reset, st_ready, st_startbit, st_sending, st_stopbit);
  signal current_state : STATE_TYPE   := st_reset;
  signal next_state    : STATE_TYPE   := st_reset;
   
  -- Sub State signals
  signal data     : std_logic_vector(7 downto 0) := "00000000";
  signal bit_cnt : std_logic_vector(2 downto 0) := (others => '0');
  signal clk_cnt : std_logic_vector(3 downto 0) := (others => '0');
  
  
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
      bit_cnt <= (others => '0'); -- default value
      clk_cnt <= (others => '0'); -- default value
      data    <= data;            -- default value
    
      case current_state is
        when st_ready    => if(next_state = st_startbit)
                            then data <= DATA_I; -- load data input as we are about to enter "send startbit state"
                            end if;
        when st_startbit => clk_cnt <= clk_cnt + 1;
        when st_sending  => clk_cnt <= clk_cnt + 1;
                            if(clk_cnt = "1111")
                            then bit_cnt <= bit_cnt + 1;
                            else bit_cnt <= bit_cnt;
                            end if;
        when st_stopbit  => clk_cnt <= clk_cnt + 1;
        when others      => NULL;
      end case; --end update of sub states
           
    end if; -- end not reset 
  end if; -- clk rising edge
end process clocked;


-- Asynchronous next state logic
nextstate: process(current_state, strobe, clk_cnt, bit_cnt) begin
  
  next_state <= next_state; -- default value
  
  case current_state is
      when st_reset    => next_state <= st_ready;
      
      when st_ready    => if(strobe = '1')
                          then next_state <= st_startbit;
                          end if;
      
      when st_startbit => if(clk_cnt = "1111")
                          then next_state <= st_sending;
                          end if;
                          
      when st_sending  => if(bit_cnt = "111" and clk_cnt = "1111")
                          then next_state <= st_stopbit;
                          end if;
                          
      when st_stopbit  => if(clk_cnt = "1111")
                          then next_state <= st_ready;
                          end if;
      
      when others      => NULL;
    end case; 
end process nextstate;


output: process (current_state, data, bit_cnt) begin    

    BUSY_O <= '1';
    case current_state is
      when st_reset    => BUSY_O <= '0';
      when st_ready    => BUSY_O <= '0';
      when st_startbit => BUSY_O <= '1';
      when st_sending  => BUSY_O <= '1';
      when st_stopbit  => BUSY_O <= '1';
      when others      => BUSY_O <= '1'; -- provided for a sense of completeness
    end case;
    
    TX_O <= '1';
    case current_state is
        when st_reset    => TX_O <= '1';
        when st_ready    => TX_O <= '1';
        when st_startbit => TX_O <= '0';
        when st_sending  => TX_O <= data(to_integer(unsigned(bit_cnt)));
        when st_stopbit  => TX_O <= '1';
        when others      => TX_O <= '1'; -- provided for a sense of completeness
    end case;       
end process output;


end Behavioral;
