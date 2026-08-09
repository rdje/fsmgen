library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use std.textio.all;

use work.fsmgen_vial_types_pkg.all;

entity ghdl_6_0_0_four_state_probe is
end entity ghdl_6_0_0_four_state_probe;

architecture qualification of ghdl_6_0_0_four_state_probe is
  signal driven : std_logic_vector(3 downto 0) := (others => 'U');
begin
  probe : process
    variable values : vial_value_vector_t(0 to 3);
    variable observed : vial_observation_vector_t(0 to 3);
    variable output_line : line;
  begin
    values := to_vial_value_vector(std_logic_vector'("01XZ"));
    drive_vial_vector(driven, values);
    wait for 1 ns;
    observed := observe_vial_vector(driven);
    assert observed(0).original_symbol = '0'
      and observed(0).normalized_value = VIAL_VALUE_0
      and observed(1).original_symbol = '1'
      and observed(1).normalized_value = VIAL_VALUE_1
      and observed(2).original_symbol = 'X'
      and observed(2).normalized_value = VIAL_VALUE_X
      and observed(3).original_symbol = 'Z'
      and observed(3).normalized_value = VIAL_VALUE_Z
      report "FSMGen VIAL four-state qualification mismatch"
      severity failure;
    write(output_line, string'("FSMGEN_VIAL_FOUR_STATE_PROBE_V1 pass"));
    writeline(output, output_line);
    finish;
  end process probe;
end architecture qualification;
