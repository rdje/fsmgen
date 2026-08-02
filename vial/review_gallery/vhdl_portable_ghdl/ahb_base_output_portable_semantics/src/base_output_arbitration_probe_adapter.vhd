library ieee;
use ieee.std_logic_1164.all;

entity base_output_arbitration_probe_adapter is
  port (
    vial_probe_reg_data_q : out std_logic_vector(31 downto 0)
  );
end entity base_output_arbitration_probe_adapter;

architecture declared_external_names of base_output_arbitration_probe_adapter is
  -- VIAL declared probe probe/reg_data_q maps to reg_data_q
  alias vial_declared_reg_data_q : std_logic_vector(31 downto 0) is
    << signal .base_output_arbitration_tb.dut.reg_data_q : std_logic_vector(31 downto 0) >>;
begin
  vial_probe_reg_data_q <= vial_declared_reg_data_q;
end architecture declared_external_names;
