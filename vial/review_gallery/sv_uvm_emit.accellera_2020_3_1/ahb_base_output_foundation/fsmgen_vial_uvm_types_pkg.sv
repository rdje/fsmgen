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

  typedef enum int unsigned {
    VIAL_LIFECYCLE_CONSTRUCTED = 0,
    VIAL_LIFECYCLE_CONFIGURED = 1,
    VIAL_LIFECYCLE_READY = 2,
    VIAL_LIFECYCLE_RUNNING = 3,
    VIAL_LIFECYCLE_DRAINING = 4,
    VIAL_LIFECYCLE_COMPLETED = 5,
    VIAL_LIFECYCLE_FINALIZED = 6
  } vial_lifecycle_state_e;

  typedef enum int unsigned {
    VIAL_LIFETIME_FIXTURE = 0,
    VIAL_LIFETIME_SCENARIO = 1,
    VIAL_LIFETIME_TRANSACTION = 2,
    VIAL_LIFETIME_NOTIFICATION = 3,
    VIAL_LIFETIME_OPERATION = 4
  } vial_lifetime_e;

  typedef enum int unsigned {
    VIAL_REENTRANCY_REJECT = 0,
    VIAL_REENTRANCY_QUEUE = 1
  } vial_reentrancy_e;

  typedef enum int unsigned {
    VIAL_FILTER_ALWAYS = 0,
    VIAL_FILTER_NEVER = 1,
    VIAL_FILTER_RESPONSE_ERROR = 2
  } vial_filter_e;

  typedef enum int unsigned {
    VIAL_EFFECT_OBSERVE = 0,
    VIAL_EFFECT_CANCEL = 1,
    VIAL_EFFECT_TRANSFORM_DECLARED_VALUE = 2,
    VIAL_EFFECT_NOTIFY_DECLARED = 3,
    VIAL_EFFECT_RECORD_COVERAGE = 4,
    VIAL_EFFECT_APPEND_DIAGNOSTIC = 5
  } vial_effect_e;

  class fsmgen_vial_execution_context extends uvm_object;
    `uvm_object_utils(fsmgen_vial_execution_context)

    string plan_id;
    vial_logical_time_s logical_time;
    vial_lifecycle_state_e lifecycle_state;

    function new(string name = "fsmgen_vial_execution_context");
      super.new(name);
      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};
      lifecycle_state = VIAL_LIFECYCLE_CONSTRUCTED;
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

    function void transition_lifecycle(
      vial_lifecycle_state_e expected,
      vial_lifecycle_state_e next_state
    );
      if (lifecycle_state != expected)
        `uvm_fatal("VIAL/LIFECYCLE", $sformatf("illegal lifecycle transition %0d -> %0d; expected %0d", lifecycle_state, next_state, expected))
      lifecycle_state = next_state;
    endfunction
  endclass
endpackage
