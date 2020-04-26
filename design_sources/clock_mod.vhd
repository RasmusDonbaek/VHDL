-------------------------------------------------------------------
-- Author       : Anders Stengaard SÃ¸rensen, 2019-11-14
-- Minor changes: Rasmus Donbaek Knudsen, 2020-04-26
-- Target Device: Trenz Electronics board TE0890 with a Xilinx Spartan 7S25 FPGA.
-- How to use   : Supply a 100 MHz input clock and the modules outputs a 16 MHz clock
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all; -- use for '+' on std_logiv_vector
Library UNISIM;                  -- For Xilinx primitives
use UNISIM.vcomponents.all;      -- allow all "components"


entity clock_mod is
  Port ( CLK_100_I  : in STD_LOGIC;
         CLK_16_O   : out STD_LOGIC;
         STABLE_O   : out STD_LOGIC);
end clock_mod;


architecture Behavioral of clock_mod is
  signal clk_feedback : std_logic;    -- Used for clock manager feedback in this module
  signal lock         : std_logic;    -- MMCM is locked in on target frequency or not
  signal clk_10       : std_logic;    -- 10MHz clock for measuring the MMCM locked in time
  
  signal count        : std_logic_vector(3 downto 0) := (others => '0'); -- Used for tracking MMCM locked in time. 17 bit counter --> 13ms at 10Mhz
  signal stable       : std_logic := '0'; -- Do the MMCM have a stable lock on the target frequency
    
  
begin 

  STABLE_O <= stable;

 -- Lock Monitor Process   
process(clk_10, lock) begin

  if(clk_10'event and clk_10 = '1') then
    
    if(lock = '0') then
      count  <= (others => '0');
      stable <= '0';
    elsif(count = "1010") then --the clock have now been stable for 10 cycles
      count  <= count;
      stable <= '1';
    else
      count  <= count + 1;
      stable <= '0';
    end if;
    
  end if; -- end clock rising edge  
end process;

-- MMCM instance
-- Connect signals to a MMCM (Mixed Mode Clock Manager) on the Spartan-7 FPGA
-- by using the MMCM2_BASE primitive in the Xilinx UniSim library (see Xilinx UG953)
MMCM_instance : MMCME2_BASE
generic map (
  BANDWIDTH       => "OPTIMIZED",   
  CLKFBOUT_MULT_F => 12.0, -- 12.0 --> 1.2 GHz F_vco
  CLKFBOUT_PHASE  => 0.0,  -- no phase change
  CLKIN1_PERIOD   => 10.0, -- 100 MHz input --> 10.0 ns period
  
  --Divide amounts for each clock
  -- CLKOUT0_DIVIDE_F => 1.0, -- 1.2 GHz (Divide amount (1.000-128.000 in increments of 0.125)
  CLKOUT1_DIVIDE => 75,  -- 16 MHz = 1.2 GHz / 75 (Divide amount 1 to 128 (integer)
  CLKOUT6_DIVIDE => 120, -- 10 MHz !!! used in asserting STABLE_O
  
  -- Duty cycle for each clock (0.01-0.99)
  CLKOUT1_DUTY_CYCLE => 0.5,
  CLKOUT6_DUTY_CYCLE => 0.5,
  
  --Phase offset for each clock (-360.000 to 360.000)
  CLKOUT1_PHASE => 0.0,
  CLKOUT6_PHASE => 0.0,
  
  CLKOUT4_CASCADE => FALSE,   -- Cascade clock 4's and clock 6's counters
  DIVCLK_DIVIDE => 1,         -- D: Master division value (1 - 106)
  REF_JITTER1 => 0.0,         -- Reference input jitter in UI (0.000-0.999)
  STARTUP_WAIT => FALSE       -- Delays DONE until MMCM is locked (FALSE, TRUE)
  ) --end generic map
port map (
  -- The clock outputs from the MMCM
  CLKOUT1 => CLK_16_O,
  CLKOUT6 => clk_10,
  
  -- Some other stuff
  CLKIN1   => CLK_100_I,    -- The input clock to the MMCM  
  CLKFBOUT => clk_feedback, -- Output: Feedback clock
  CLKFBIN  => clk_feedback, -- Input: Feedback clock
  LOCKED   => lock,         -- Locked status
  PWRDWN   => '0',          -- Power down
  RST      => '0');         -- Reset
-- End of MMCM instance


end Behavioral;