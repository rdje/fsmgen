library ieee;
use ieee.std_logic_1164.all;

package fsmgen_vial_types_pkg is
  type vial_value_symbol_t is (
    VIAL_VALUE_0,
    VIAL_VALUE_1,
    VIAL_VALUE_X,
    VIAL_VALUE_Z
  );

  type vial_phase_t is (
    VIAL_DRIVE_PHASE,
    VIAL_SAMPLE_PHASE,
    VIAL_REACT_PHASE,
    VIAL_CHECK_PHASE
  );

  type vial_observation_t is record
    original_symbol : std_logic;
    normalized_value : vial_value_symbol_t;
  end record;

  function normalize_vial_value(value : std_logic) return vial_value_symbol_t;
  function observe_vial_value(value : std_logic) return vial_observation_t;
end package fsmgen_vial_types_pkg;

package body fsmgen_vial_types_pkg is
  function normalize_vial_value(value : std_logic) return vial_value_symbol_t is
  begin
    case value is
      when '0' => return VIAL_VALUE_0;
      when '1' => return VIAL_VALUE_1;
      when 'Z' => return VIAL_VALUE_Z;
      when 'L' => return VIAL_VALUE_0;
      when 'H' => return VIAL_VALUE_1;
      when others => return VIAL_VALUE_X;
    end case;
  end function normalize_vial_value;

  function observe_vial_value(value : std_logic) return vial_observation_t is
  begin
    return (
      original_symbol => value,
      normalized_value => normalize_vial_value(value)
    );
  end function observe_vial_value;
end package body fsmgen_vial_types_pkg;
