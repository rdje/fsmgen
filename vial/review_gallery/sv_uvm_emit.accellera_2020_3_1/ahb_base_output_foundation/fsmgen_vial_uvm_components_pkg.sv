// Simulator-neutral native VIAL UVM component foundations.
package fsmgen_vial_uvm_components_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;

  class fsmgen_vial_component_base extends uvm_component;
    `uvm_component_utils(fsmgen_vial_component_base)

    fsmgen_vial_execution_context context;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(fsmgen_vial_execution_context)::get(this, "", "vial_context", context))
        `uvm_fatal("VIAL/CONTEXT", "missing VIAL execution context")
    endfunction
  endclass

  class fsmgen_vial_agent_base extends uvm_agent;
    `uvm_component_utils(fsmgen_vial_agent_base)

    fsmgen_vial_execution_context context;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(fsmgen_vial_execution_context)::get(this, "", "vial_context", context))
        `uvm_fatal("VIAL/CONTEXT", "missing VIAL execution context")
    endfunction
  endclass

  class fsmgen_vial_env_base extends fsmgen_vial_component_base;
    `uvm_component_utils(fsmgen_vial_env_base)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class fsmgen_vial_test_base extends uvm_test;
    `uvm_component_utils(fsmgen_vial_test_base)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass
endpackage
