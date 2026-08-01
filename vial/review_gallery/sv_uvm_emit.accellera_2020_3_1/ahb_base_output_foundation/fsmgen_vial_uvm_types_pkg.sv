// Simulator-neutral native VIAL UVM support.
package fsmgen_vial_uvm_types_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  typedef enum int unsigned {
    VIAL_DRIVE_PHASE = 0,
    VIAL_SAMPLE_PHASE = 1,
    VIAL_REACT_PHASE = 2,
    VIAL_CHECK_PHASE = 3
  } vial_phase_e;

  typedef struct {
    longint unsigned cycle;
    int unsigned ordinal;
    vial_phase_e phase;
  } vial_logical_time_s;

  class fsmgen_vial_execution_context extends uvm_object;
    `uvm_object_utils(fsmgen_vial_execution_context)

    string plan_id;
    vial_logical_time_s logical_time;

    function new(string name = "fsmgen_vial_execution_context");
      super.new(name);
      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};
    endfunction

    function void set_logical_time(
      longint unsigned cycle,
      vial_phase_e phase,
      int unsigned ordinal = 0
    );
      logical_time.cycle = cycle;
      logical_time.phase = phase;
      logical_time.ordinal = ordinal;
    endfunction
  endclass
endpackage
