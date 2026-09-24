library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity reset_tb is end;
architecture behavior of reset_tb is
  signal clk: std_logic := '0';
  signal rst_high: std_logic := '1';
  signal rst_low: std_logic := '0';
  signal data_in: std_logic_vector(3 downto 0) := "1001";
  signal q_sync_high, q_sync_low, q_async_high, q_async_low: std_logic_vector(3 downto 0);
begin
  clk <= not clk after 5 ns;
  dut_sync_high: entity work.sync_high port map(clk => clk, reset_pin => rst_high, DATA => data_in, Q => q_sync_high);
  dut_sync_low: entity work.sync_low port map(clk => clk, reset_pin => rst_low, DATA => data_in, Q => q_sync_low);
  dut_async_high: entity work.async_high port map(clk => clk, reset_pin => rst_high, DATA => data_in, Q => q_async_high);
  dut_async_low: entity work.async_low port map(clk => clk, reset_pin => rst_low, DATA => data_in, Q => q_async_low);
  process
    procedure expect_values(synchronous_value, asynchronous_value: natural) is
    begin
      assert q_sync_high = std_logic_vector(to_unsigned(synchronous_value,4)) and
             q_sync_low = std_logic_vector(to_unsigned(synchronous_value,4)) and
             q_async_high = std_logic_vector(to_unsigned(asynchronous_value,4)) and
             q_async_low = std_logic_vector(to_unsigned(asynchronous_value,4))
        report "reset kind/polarity behavior mismatch" severity failure;
    end procedure;
  begin
    wait for 6 ns; expect_values(3,3);
    wait for 6 ns; rst_high <= '0'; rst_low <= '1';
    wait for 4 ns; expect_values(9,9);
    wait for 1 ns; rst_high <= '1'; rst_low <= '0';
    wait for 1 ns; expect_values(9,3);
    wait for 8 ns; expect_values(3,3);
    wait for 1 ns; rst_high <= '0'; rst_low <= '1'; data_in <= "0110";
    wait for 9 ns; expect_values(6,6);
    wait for 1 ns; rst_high <= '1'; rst_low <= '0';
    wait for 1 ns; expect_values(6,3);
    wait for 1 ns; rst_high <= '0'; rst_low <= '1';
    wait for 5 ns; expect_values(6,3);
    wait for 2 ns; expect_values(6,6);
    report "RESET_BEHAVIOR_PASS" severity note;
    std.env.stop;
    wait;
  end process;
end;
