// Generated native VIAL UVM fixture foundation.
package base_output_arbitration_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;
  import fsmgen_vial_uvm_components_pkg::*;
  import base_output_arbitration_notifications_pkg::*;
  import base_output_arbitration_services_pkg::*;

  class base_output_arbitration_config extends uvm_object;
    `uvm_object_utils(base_output_arbitration_config)

    virtual base_output_arbitration_if vif;
    int unsigned scenario_timeout_cycles;
    string role_substitution_id;
    string ral_preview_id;

    function new(string name = "base_output_arbitration_config");
      super.new(name);
      scenario_timeout_cycles = 256;
      role_substitution_id = "private-preview/driver/default";
      ral_preview_id = "private-preview/ral/reg_data";
    endfunction
  endclass

  class base_output_arbitration_sequencer extends uvm_sequencer#(base_output_arbitration_ahb_write_item);
    `uvm_component_utils(base_output_arbitration_sequencer)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class base_output_arbitration_driver_base extends uvm_driver#(base_output_arbitration_ahb_write_item);
    `uvm_component_utils(base_output_arbitration_driver_base)

    base_output_arbitration_config cfg;
    uvm_analysis_port#(base_output_arbitration_ahb_write_item) driven_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      driven_ap = new("driven_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "driver is missing generated fixture configuration")
    endfunction

    virtual task drive_item(base_output_arbitration_ahb_write_item request);
      `uvm_fatal("VIAL/DRIVER", "compiler-selected driver override is missing")
    endtask

    virtual task run_phase(uvm_phase phase);
      base_output_arbitration_ahb_write_item request;
      base_output_arbitration_ahb_write_item published;
      forever begin
        seq_item_port.get_next_item(request);
        if (request == null)
          `uvm_fatal("VIAL/DRIVER", "sequencer supplied a null transaction item")
        drive_item(request);
        if (!$cast(published, request.clone()))
          `uvm_fatal("VIAL/DRIVER", "transaction clone has an incompatible type")
        driven_ap.write(published);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class base_output_arbitration_driver extends base_output_arbitration_driver_base;
    `uvm_component_utils(base_output_arbitration_driver)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual task drive_item(base_output_arbitration_ahb_write_item request);
      @(cfg.vif.driver_cb);
      cfg.vif.driver_cb.HADDR <= request.address;
      cfg.vif.driver_cb.HTRANS <= request.transfer;
      cfg.vif.driver_cb.HWRITE <= request.write;
      cfg.vif.driver_cb.HSIZE <= request.size;
      cfg.vif.driver_cb.HWDATA <= request.data;
      cfg.vif.driver_cb.wait_cycles <= request.wait_cycles;
      cfg.vif.driver_cb.HSEL <= 1'b1;
      do @(cfg.vif.driver_cb);
      while (cfg.vif.driver_cb.HREADYOUT !== 1'b1);
      cfg.vif.driver_cb.HSEL <= 1'b0;
      cfg.vif.driver_cb.HTRANS <= '0;
    endtask
  endclass

  class base_output_arbitration_monitor extends fsmgen_vial_component_base;
    `uvm_component_utils(base_output_arbitration_monitor)

    base_output_arbitration_config cfg;
    base_output_arbitration_notification_registry notifications;
    uvm_analysis_port#(base_output_arbitration_ahb_write_item) observed_ap;
    longint unsigned sampled_cycle;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      observed_ap = new("observed_ap", this);
      sampled_cycle = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "monitor is missing generated fixture configuration")
      if (!uvm_config_db#(base_output_arbitration_notification_registry)::get(this, "", "notifications", notifications))
        `uvm_fatal("VIAL/NOTIFY", "monitor is missing notification registry")
    endfunction

    protected function base_output_arbitration_notification_payload sample_payload(string notification_id, string semantic_id);
      base_output_arbitration_notification_payload item;
      item = new("sampled_notification");
      item.notification_id = notification_id;
      item.semantic_id = semantic_id;
      item.logical_time = context.logical_time;
      item.haddr = cfg.vif.monitor_cb.HADDR;
      item.hrdata = cfg.vif.monitor_cb.HRDATA;
      item.hready = cfg.vif.monitor_cb.HREADY;
      item.hreadyout = cfg.vif.monitor_cb.HREADYOUT;
      item.hresp = cfg.vif.monitor_cb.HRESP;
      item.hsel = cfg.vif.monitor_cb.HSEL;
      item.hsize = cfg.vif.monitor_cb.HSIZE;
      item.htrans = cfg.vif.monitor_cb.HTRANS;
      item.hwdata = cfg.vif.monitor_cb.HWDATA;
      item.hwrite = cfg.vif.monitor_cb.HWRITE;
      item.rst_n = cfg.vif.monitor_cb.rst_n;
      item.wait_cycles = cfg.vif.monitor_cb.wait_cycles;
      return item;
    endfunction

    protected function base_output_arbitration_ahb_write_item sample_transaction();
      base_output_arbitration_ahb_write_item transaction;
      transaction = base_output_arbitration_ahb_write_item::type_id::create("observed_transaction");
      transaction.semantic_id = "ahb_subordinate_base_output_arbitration::transaction::ahb_write";
      transaction.address = cfg.vif.monitor_cb.HADDR;
      transaction.transfer = cfg.vif.monitor_cb.HTRANS;
      transaction.write = cfg.vif.monitor_cb.HWRITE;
      transaction.size = cfg.vif.monitor_cb.HSIZE;
      transaction.data = cfg.vif.monitor_cb.HWDATA;
      transaction.wait_cycles = cfg.vif.monitor_cb.wait_cycles;
      return transaction;
    endfunction

    virtual task run_phase(uvm_phase phase);
      base_output_arbitration_notification_payload item;
      forever begin
        @(cfg.vif.monitor_cb);
        if (cfg.vif.monitor_cb.rst_n !== 1'b1)
          continue;
        context.set_logical_time(sampled_cycle, VIAL_SAMPLE_PHASE, 0);
        // 'accepted' keeps a typed channel; its adapter-state predicate is not executed by this emission-only slice.
        // 'captured' keeps a typed channel; its adapter-state predicate is not executed by this emission-only slice.
        // 'held' keeps a typed channel; its adapter-state predicate is not executed by this emission-only slice.
        if (cfg.vif.monitor_cb.HREADYOUT) begin
          item = sample_payload("event/ahb_write/completed", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::completed");
          notifications.completed_notification.trigger_notification(item);
          observed_ap.write(sample_transaction());
        end
        // 'error' keeps a typed channel; its adapter-state predicate is not executed by this emission-only slice.
        sampled_cycle++;
      end
    endtask
  endclass

  class base_output_arbitration_agent extends fsmgen_vial_agent_base;
    `uvm_component_utils(base_output_arbitration_agent)

    base_output_arbitration_config cfg;
    base_output_arbitration_notification_registry notifications;
    base_output_arbitration_sequencer sequencer;
    base_output_arbitration_driver_base driver;
    base_output_arbitration_monitor monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "agent is missing generated fixture configuration")
      if (!uvm_config_db#(base_output_arbitration_notification_registry)::get(this, "", "notifications", notifications))
        `uvm_fatal("VIAL/NOTIFY", "agent is missing notification registry")
      uvm_config_db#(base_output_arbitration_config)::set(this, "monitor", "cfg", cfg);
      uvm_config_db#(base_output_arbitration_notification_registry)::set(this, "monitor", "notifications", notifications);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "monitor", "vial_context", context);
      uvm_config_db#(base_output_arbitration_config)::set(this, "driver", "cfg", cfg);
      sequencer = base_output_arbitration_sequencer::type_id::create("sequencer", this);
      driver = base_output_arbitration_driver_base::type_id::create("driver", this);
      monitor = base_output_arbitration_monitor::type_id::create("monitor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  class base_output_arbitration_controller extends fsmgen_vial_component_base;
    `uvm_component_utils(base_output_arbitration_controller)

    base_output_arbitration_config cfg;
    base_output_arbitration_notification_registry notifications;
    base_output_arbitration_sequencer sequencer;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "controller is missing generated fixture configuration")
      if (!uvm_config_db#(base_output_arbitration_notification_registry)::get(this, "", "notifications", notifications))
        `uvm_fatal("VIAL/NOTIFY", "controller is missing notification registry")
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
      super.start_of_simulation_phase(phase);
      if (cfg == null || cfg.vif == null || notifications == null || sequencer == null)
        `uvm_fatal("VIAL/READY", "generated controller is not ready")
    endfunction

    task run_selected_lifecycle();
      base_output_arbitration_success_sequence success_sequence;
      base_output_arbitration_unsupported_size_sequence unsupported_size_sequence;
      base_output_arbitration_notification_payload requested;
      wait (cfg.vif.rst_n === 1'b1);
      context.transition_lifecycle(VIAL_LIFECYCLE_READY, VIAL_LIFECYCLE_RUNNING);
      context.set_logical_time(0, VIAL_DRIVE_PHASE, 0);
      requested = new("requested_notification");
      requested.notification_id = "event/ahb_write/requested";
      requested.semantic_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::requested";
      requested.logical_time = context.logical_time;
      notifications.requested_notification.trigger_notification(requested);
      success_sequence = base_output_arbitration_success_sequence::type_id::create("success_sequence");
      success_sequence.start(sequencer);
      unsupported_size_sequence = base_output_arbitration_unsupported_size_sequence::type_id::create("unsupported_size_sequence");
      unsupported_size_sequence.start(sequencer);
      context.transition_lifecycle(VIAL_LIFECYCLE_RUNNING, VIAL_LIFECYCLE_DRAINING);
    endtask

    function void complete_lifecycle();
      context.transition_lifecycle(VIAL_LIFECYCLE_DRAINING, VIAL_LIFECYCLE_COMPLETED);
    endfunction
  endclass

  class base_output_arbitration_result_collector extends fsmgen_vial_component_base;
    `uvm_component_utils(base_output_arbitration_result_collector)

    base_output_arbitration_notification_registry notifications;
    longint unsigned notification_occurrences;
    bit sealed;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      sealed = 1'b0;
      notification_occurrences = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_notification_registry)::get(this, "", "notifications", notifications))
        `uvm_fatal("VIAL/NOTIFY", "result collector is missing notification registry")
    endfunction

    function void seal();
      if (sealed)
        `uvm_fatal("VIAL/RESULT", "result collector sealed more than once")
      notification_occurrences = notifications.total_occurrences();
      sealed = 1'b1;
    endfunction

    virtual function void extract_phase(uvm_phase phase);
      super.extract_phase(phase);
      if (!sealed)
        `uvm_fatal("VIAL/RESULT", "result collector reached extract before seal")
    endfunction

    virtual function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (!sealed)
        `uvm_error("VIAL/RESULT", "result collector is unsealed")
    endfunction

    virtual function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info("VIAL/RESULT", $sformatf("emission-review notification occurrences=%0d", notification_occurrences), UVM_LOW)
    endfunction
  endclass

  class base_output_arbitration_env extends fsmgen_vial_env_base;
    `uvm_component_utils(base_output_arbitration_env)

    base_output_arbitration_config cfg;
    base_output_arbitration_notification_registry notifications;
    base_output_arbitration_agent agent;
    base_output_arbitration_controller controller;
    base_output_arbitration_result_collector result_collector;
    uvm_tlm_analysis_fifo#(base_output_arbitration_ahb_write_item) driven_fifo;
    base_output_arbitration_transaction_observer transaction_observer;
    base_output_arbitration_reg_block ral_model;
    base_output_arbitration_reg_adapter ral_adapter;
    base_output_arbitration_reg_predictor ral_predictor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(base_output_arbitration_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("VIAL/CONFIG", "missing generated fixture configuration")
      if (!uvm_config_db#(base_output_arbitration_notification_registry)::get(this, "", "notifications", notifications))
        `uvm_fatal("VIAL/NOTIFY", "environment is missing notification registry")
      uvm_config_db#(base_output_arbitration_config)::set(this, "agent", "cfg", cfg);
      uvm_config_db#(base_output_arbitration_notification_registry)::set(this, "agent", "notifications", notifications);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "agent", "vial_context", context);
      uvm_config_db#(base_output_arbitration_config)::set(this, "controller", "cfg", cfg);
      uvm_config_db#(base_output_arbitration_notification_registry)::set(this, "controller", "notifications", notifications);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "controller", "vial_context", context);
      uvm_config_db#(base_output_arbitration_notification_registry)::set(this, "result_collector", "notifications", notifications);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "result_collector", "vial_context", context);
      agent = base_output_arbitration_agent::type_id::create("agent", this);
      controller = base_output_arbitration_controller::type_id::create("controller", this);
      result_collector = base_output_arbitration_result_collector::type_id::create("result_collector", this);
      driven_fifo = new("driven_fifo", this);
      transaction_observer = base_output_arbitration_transaction_observer::type_id::create("transaction_observer", this);
      ral_model = base_output_arbitration_reg_block::type_id::create("ral_model");
      ral_model.build();
      ral_model.lock_model();
      ral_adapter = base_output_arbitration_reg_adapter::type_id::create("ral_adapter");
      ral_predictor = base_output_arbitration_reg_predictor::type_id::create("ral_predictor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.driver.driven_ap.connect(driven_fifo.analysis_export);
      agent.monitor.observed_ap.connect(transaction_observer.analysis_export);
      agent.monitor.observed_ap.connect(ral_predictor.bus_in);
      ral_predictor.map = ral_model.default_map;
      ral_predictor.adapter = ral_adapter;
      controller.sequencer = agent.sequencer;
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      if (agent == null || controller == null || result_collector == null ||
          driven_fifo == null || transaction_observer == null ||
          ral_model == null || ral_adapter == null || ral_predictor == null)
        `uvm_fatal("VIAL/TOPOLOGY", "generated component topology is incomplete")
      context.transition_lifecycle(VIAL_LIFECYCLE_CONFIGURED, VIAL_LIFECYCLE_READY);
    endfunction
  endclass

  class base_output_arbitration_test extends fsmgen_vial_test_base;
    `uvm_component_utils(base_output_arbitration_test)

    base_output_arbitration_config cfg;
    base_output_arbitration_notification_registry notifications;
    base_output_arbitration_env env;
    fsmgen_vial_execution_context context;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_factory::get().set_inst_override_by_type(
        base_output_arbitration_driver_base::get_type(), base_output_arbitration_driver::get_type(),
        "uvm_test_top.env.agent.driver"
      );
      cfg = base_output_arbitration_config::type_id::create("cfg");
      if (!uvm_config_db#(virtual base_output_arbitration_if)::get(this, "", "vif", cfg.vif))
        `uvm_fatal("VIAL/VIF", "missing generated virtual interface")
      context = fsmgen_vial_execution_context::type_id::create("context");
      context.plan_id = "plan/038c968edbd7782d36f49af5092dd4301ca95989914eeba73250f9b609525574";
      notifications = base_output_arbitration_notification_registry::type_id::create("notifications");
      notifications.configure_preview();
      cfg.scenario_timeout_cycles = 256;
      cfg.role_substitution_id = "private-preview/driver/base-output-arbitration";
      cfg.ral_preview_id = "private-preview/ral/reg-data-at-zero";
      uvm_config_db#(base_output_arbitration_config)::set(this, "env", "cfg", cfg);
      uvm_config_db#(base_output_arbitration_notification_registry)::set(this, "env", "notifications", notifications);
      uvm_config_db#(fsmgen_vial_execution_context)::set(this, "env", "vial_context", context);
      context.transition_lifecycle(VIAL_LIFECYCLE_CONSTRUCTED, VIAL_LIFECYCLE_CONFIGURED);
      env = base_output_arbitration_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this, "VIAL root lifecycle");
      env.controller.run_selected_lifecycle();
      env.result_collector.seal();
      env.controller.complete_lifecycle();
      phase.drop_objection(this, "VIAL root lifecycle complete");
    endtask

    virtual function void final_phase(uvm_phase phase);
      super.final_phase(phase);
      context.transition_lifecycle(VIAL_LIFECYCLE_COMPLETED, VIAL_LIFECYCLE_FINALIZED);
    endfunction
  endclass
endpackage
