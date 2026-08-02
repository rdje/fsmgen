library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;
use work.fsmgen_vial_runtime_pkg.all;

entity base_output_arbitration_tb is
end entity base_output_arbitration_tb;

architecture foundation of base_output_arbitration_tb is
  signal HADDR : std_logic_vector(31 downto 0) := (others => '0');
  signal HRDATA : std_logic_vector(31 downto 0) := (others => '0');
  signal HREADY : std_logic := '0';
  signal HREADYOUT : std_logic := '0';
  signal HRESP : std_logic := '0';
  signal HSEL : std_logic := '0';
  signal HSIZE : std_logic_vector(2 downto 0) := (others => '0');
  signal HTRANS : std_logic_vector(1 downto 0) := (others => '0');
  signal HWDATA : std_logic_vector(31 downto 0) := (others => '0');
  signal HWRITE : std_logic := '0';
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal wait_cycles : std_logic_vector(3 downto 0) := (others => '0');

begin
  -- Driver, sampler, scheduler, scenario, and probe processes are emitted by later slices.
  dut : entity work.ahb_lite_subordinate(rtl)
    port map (
      HADDR => HADDR,
      HRDATA => HRDATA,
      HREADY => HREADY,
      HREADYOUT => HREADYOUT,
      HRESP => HRESP,
      HSEL => HSEL,
      HSIZE => HSIZE,
      HTRANS => HTRANS,
      HWDATA => HWDATA,
      HWRITE => HWRITE,
      clk => clk,
      rst_n => rst_n,
      wait_cycles => wait_cycles
    );
end architecture foundation;
