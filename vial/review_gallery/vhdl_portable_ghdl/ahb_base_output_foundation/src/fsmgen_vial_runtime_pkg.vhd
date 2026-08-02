library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;

package fsmgen_vial_runtime_pkg is
  constant FSMGEN_VIAL_RUNTIME_SCHEMA : string := "fsmgen.vial_vhdl_runtime.v1";

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

  constant VIAL_INITIAL_LOGICAL_TIME : vial_logical_time_t := (
    cycle => 0,
    phase => VIAL_DRIVE_PHASE,
    static_rank => 0,
    local_index => 0
  );
end package fsmgen_vial_runtime_pkg;
