// Generated native VIAL UVM fixture foundation.
package base_output_arbitration_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;
  import fsmgen_vial_uvm_components_pkg::*;

  class base_output_arbitration_config extends uvm_object;
    `uvm_object_utils(base_output_arbitration_config)

    virtual base_output_arbitration_if vif;

    function new(string name = "base_output_arbitration_config");
      super.new(name);
    endfunction
  endclass

  class base_output_arbitration_env extends fsmgen_vial_env_base;
    `uvm_component_utils(base_output_arbitration_env)

    base_output_arbitration_config cfg;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "missing generated fixture configuration")
    endfunction
  endclass

  class base_output_arbitration_test extends fsmgen_vial_test_base;
    `uvm_component_utils(base_output_arbitration_test)

    base_output_arbitration_config cfg;
    base_output_arbitration_env env;
    fsmgen_vial_execution_context context;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      cfg = base_output_arbitration_config::type_id::create("cfg");
      if (!uvm_config_db#(virtual base_output_arbitration_if)::get(this, "", "vif", cfg.vif))
        `uvm_fatal("VIAL/VIF", "missing generated virtual interface")
      context = fsmgen_vial_execution_context::type_id::create("context");
      context.plan_id = "plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574";
      uvm_config_db#(base_output_arbitration_config)::set(this, "env", "cfg", cfg);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "env", "vial_context", context);
      env = base_output_arbitration_env::type_id::create("env", this);
    endfunction
  endclass
endpackage
