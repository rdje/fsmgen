library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity bitwise_vector_guard_tb is
end entity;

architecture test of bitwise_vector_guard_tb is
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal a, b : std_logic_vector(7 downto 0) := (others => '0');
  signal data, other : std_logic;
begin
  clk <= not clk after 5 ns;
  dut : entity work.bitwise_vector_guards
    port map (clk => clk, rst_n => rst_n, A => a, B => b, DATA => data, OTHER => other);

  stimulus : process
  begin
    wait for 1 ns;
    rst_n <= '1';
    a <= x"02"; b <= x"02";
    wait for 1 ns;
    assert data = '1' and other = '1' report "high bit 1 lost" severity failure;
    a <= x"80"; b <= x"80";
    wait for 1 ns;
    assert data = '1' and other = '1' report "high bit 7 lost" severity failure;
    a <= x"01"; b <= x"02";
    wait for 1 ns;
    assert data = '0' and other = '0' report "disjoint masks enabled guard" severity failure;
    report "fixed vector logical guard witness passed" severity note;
    stop;
    wait;
  end process;
end architecture;
