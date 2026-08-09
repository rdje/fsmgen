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

  type vial_value_vector_t is array (natural range <>) of vial_value_symbol_t;
  type vial_observation_vector_t is array (natural range <>) of vial_observation_t;

  function normalize_vial_value(value : std_logic) return vial_value_symbol_t;
  function to_vial_value_vector(value : std_logic_vector) return vial_value_vector_t;
  function to_strong_std_logic(value : vial_value_symbol_t) return std_logic;
  function observe_vial_value(value : std_logic) return vial_observation_t;
  function observe_vial_vector(value : std_logic_vector) return vial_observation_vector_t;
  function vial_is_known_zero(value : vial_observation_t) return boolean;
  function vial_is_known_one(value : vial_observation_t) return boolean;
  function vial_is_known(value : vial_observation_t) return boolean;
  function vial_matches(
    actual : vial_observation_vector_t;
    expected : vial_value_vector_t
  ) return boolean;
  procedure drive_vial_value(
    signal target : out std_logic;
    constant value : in vial_value_symbol_t
  );
  procedure drive_vial_vector(
    signal target : out std_logic_vector;
    constant value : in vial_value_vector_t
  );
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

  function to_vial_value_vector(value : std_logic_vector) return vial_value_vector_t is
    variable result : vial_value_vector_t(0 to value'length - 1);
    variable source_index : natural;
  begin
    for offset in 0 to value'length - 1 loop
      if value'ascending then
        source_index := value'left + offset;
      else
        source_index := value'left - offset;
      end if;
      result(offset) := normalize_vial_value(value(source_index));
    end loop;
    return result;
  end function to_vial_value_vector;

  function to_strong_std_logic(value : vial_value_symbol_t) return std_logic is
  begin
    case value is
      when VIAL_VALUE_0 => return '0';
      when VIAL_VALUE_1 => return '1';
      when VIAL_VALUE_X => return 'X';
      when VIAL_VALUE_Z => return 'Z';
    end case;
  end function to_strong_std_logic;

  function observe_vial_vector(value : std_logic_vector) return vial_observation_vector_t is
    variable result : vial_observation_vector_t(0 to value'length - 1);
    variable source_index : natural;
  begin
    for offset in 0 to value'length - 1 loop
      if value'ascending then
        source_index := value'left + offset;
      else
        source_index := value'left - offset;
      end if;
      result(offset) := observe_vial_value(value(source_index));
    end loop;
    return result;
  end function observe_vial_vector;

  function vial_is_known_zero(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_0;
  end function vial_is_known_zero;

  function vial_is_known_one(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_1;
  end function vial_is_known_one;

  function vial_is_known(value : vial_observation_t) return boolean is
  begin
    return value.normalized_value = VIAL_VALUE_0
      or value.normalized_value = VIAL_VALUE_1;
  end function vial_is_known;

  function vial_matches(
    actual : vial_observation_vector_t;
    expected : vial_value_vector_t
  ) return boolean is
    variable actual_index : natural;
    variable expected_index : natural;
  begin
    if actual'length /= expected'length then
      return false;
    end if;
    for offset in 0 to actual'length - 1 loop
      if actual'ascending then
        actual_index := actual'left + offset;
      else
        actual_index := actual'left - offset;
      end if;
      if expected'ascending then
        expected_index := expected'left + offset;
      else
        expected_index := expected'left - offset;
      end if;
      if actual(actual_index).normalized_value /= expected(expected_index) then
        return false;
      end if;
    end loop;
    return true;
  end function vial_matches;

  procedure drive_vial_value(
    signal target : out std_logic;
    constant value : in vial_value_symbol_t
  ) is
  begin
    target <= to_strong_std_logic(value);
  end procedure drive_vial_value;

  procedure drive_vial_vector(
    signal target : out std_logic_vector;
    constant value : in vial_value_vector_t
  ) is
    variable target_index : natural;
    variable value_index : natural;
  begin
    assert target'length = value'length
      report "FSMGen VIAL driver width mismatch"
      severity failure;
    for offset in 0 to target'length - 1 loop
      if target'ascending then
        target_index := target'left + offset;
      else
        target_index := target'left - offset;
      end if;
      if value'ascending then
        value_index := value'left + offset;
      else
        value_index := value'left - offset;
      end if;
      target(target_index) <= to_strong_std_logic(value(value_index));
    end loop;
  end procedure drive_vial_vector;
end package body fsmgen_vial_types_pkg;
