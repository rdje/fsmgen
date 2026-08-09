library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;

package fsmgen_vial_runtime_pkg is
  constant FSMGEN_VIAL_RUNTIME_SCHEMA : string := "fsmgen.vial_vhdl_runtime.v3";

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

  type vial_check_outcome_t is (
    VIAL_CHECK_PENDING,
    VIAL_CHECK_PASSED,
    VIAL_CHECK_FAILED,
    VIAL_CHECK_UNKNOWN
  );

  type vial_diagnostic_record_t is record
    code : string(1 to 32);
    code_length : natural;
    severity_name : string(1 to 8);
    logical_time : vial_logical_time_t;
    outcome : vial_check_outcome_t;
  end record;

  type vial_diagnostic_array_t is array (natural range <>) of vial_diagnostic_record_t;

  type vial_scoreboard_state_t is record
    expected_depth : natural;
    actual_depth : natural;
    comparisons : natural;
    mismatches : natural;
    overflowed : boolean;
  end record;

  type vial_coverage_counter_t is record
    not_stalled : natural;
    stalled : natural;
  end record;

  type vial_fault_state_t is record
    armed : boolean;
    remaining_cycles : natural;
    applications : natural;
  end record;

  constant VIAL_SCOREBOARD_CAPACITY : positive := 4;
  constant VIAL_DIAGNOSTIC_CAPACITY : positive := 64;
  constant VIAL_TRACE_SCHEMA : string := "fsmgen.vial_vhdl_runtime_trace.v1";
  constant VIAL_RESULT_SCHEMA : string := "fsmgen.verification_result_manifest.v1";

  constant VIAL_INITIAL_LOGICAL_TIME : vial_logical_time_t := (
    cycle => 0,
    phase => VIAL_DRIVE_PHASE,
    static_rank => 0,
    local_index => 0
  );
end package fsmgen_vial_runtime_pkg;
