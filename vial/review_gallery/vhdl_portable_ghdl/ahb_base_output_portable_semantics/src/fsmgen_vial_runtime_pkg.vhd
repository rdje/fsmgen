library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;

package fsmgen_vial_runtime_pkg is
  constant FSMGEN_VIAL_RUNTIME_SCHEMA : string := "fsmgen.vial_vhdl_runtime.v2";

  type vial_logical_time_t is record
    cycle : natural;
    phase : vial_phase_t;
    static_rank : natural;
    local_index : natural;
  end record;

  type vial_runtime_state_t is (
    VIAL_RUNTIME_CONSTRUCTED,
    VIAL_RUNTIME_READY,
    VIAL_RUNTIME_RUNNING,
    VIAL_RUNTIME_COMPLETED,
    VIAL_RUNTIME_FINALIZED
  );

  type vial_fiber_status_t is (
    VIAL_FIBER_DORMANT,
    VIAL_FIBER_RUNNING,
    VIAL_FIBER_COMPLETED,
    VIAL_FIBER_CANCELLED,
    VIAL_FIBER_TIMED_OUT
  );

  type vial_scenario_status_t is (
    VIAL_SCENARIO_DORMANT,
    VIAL_SCENARIO_RUNNING,
    VIAL_SCENARIO_STIMULUS_COMPLETED,
    VIAL_SCENARIO_TIMED_OUT
  );

  constant VIAL_INITIAL_LOGICAL_TIME : vial_logical_time_t := (
    cycle => 0,
    phase => VIAL_DRIVE_PHASE,
    static_rank => 0,
    local_index => 0
  );
end package fsmgen_vial_runtime_pkg;
