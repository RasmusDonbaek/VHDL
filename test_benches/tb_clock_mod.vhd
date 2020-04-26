
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity tb_clock_mod is
--  Port ( );
end tb_clock_mod;


architecture Testbench of tb_clock_mod is

component clock_mod is
  Port ( CLK_100_I  : in STD_LOGIC;
         CLK_16_O   : out STD_LOGIC;
         STABLE_O   : out STD_LOGIC);
end component;

signal clk_100 : std_logic := '0';
signal clk_16 : std_logic;
signal stable : std_logic;

constant PERIOD      : time := 10 ns; -- 100 MHz clock  

begin

  clk_100 <= not clk_100 after (PERIOD/2.0);  

  U1:clock_mod
  Port Map (
    CLK_100_I => clk_100,
    CLK_16_O  => clk_16,
    STABLE_O  => stable);
  
end Testbench;
