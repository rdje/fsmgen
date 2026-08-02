// Generated native VIAL checking, diagnostic, and result-collection structures.
// These structures are emitted for review; no runtime result is claimed.
package base_output_arbitration_checking_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;
  import base_output_arbitration_services_pkg::*;
  `uvm_analysis_imp_decl(_vial_diagnostic)

  class base_output_arbitration_diagnostic extends uvm_object;
    `uvm_object_utils(base_output_arbitration_diagnostic)

    string diagnostic_id;
    string semantic_id;
    uvm_severity severity;
    string message;
    vial_logical_time_s logical_time;

    function new(string name = "base_output_arbitration_diagnostic");
      super.new(name);
      diagnostic_id = "";
      semantic_id = "";
      severity = UVM_INFO;
      message = "";
      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_CHECK_PHASE};
    endfunction

    virtual function void do_copy(uvm_object rhs);
      base_output_arbitration_diagnostic rhs_item;
      super.do_copy(rhs);
      if (!$cast(rhs_item, rhs))
        `uvm_fatal("VIAL/DIAGNOSTIC/COPY", "diagnostic type mismatch")
      diagnostic_id = rhs_item.diagnostic_id;
      semantic_id = rhs_item.semantic_id;
      severity = rhs_item.severity;
      message = rhs_item.message;
      logical_time = rhs_item.logical_time;
    endfunction
  endclass

  class base_output_arbitration_result_snapshot extends uvm_object;
    `uvm_object_utils(base_output_arbitration_result_snapshot)

    string plan_id;
    string status;
    longint unsigned notification_count;
    longint unsigned diagnostic_count;
    longint unsigned expectation_count;
    longint unsigned expectation_failure_count;
    longint unsigned model_record_count;
    longint unsigned scoreboard_record_count;
    longint unsigned coverage_sample_count;
    longint unsigned fault_record_count;

    function new(string name = "base_output_arbitration_result_snapshot");
      super.new(name);
      plan_id = "";
      status = "emitted_unqualified";
      notification_count = 0;
      diagnostic_count = 0;
      expectation_count = 0;
      expectation_failure_count = 0;
      model_record_count = 0;
      scoreboard_record_count = 0;
      coverage_sample_count = 0;
      fault_record_count = 0;
    endfunction
  endclass

  class base_output_arbitration_coverage_collector extends uvm_component;
    `uvm_component_utils(base_output_arbitration_coverage_collector)

    uvm_analysis_port#(base_output_arbitration_diagnostic) diagnostic_ap;
    longint unsigned sample_count;
    covergroup stall_seen_cg with function sample(bit stalled);
      option.per_instance = 1;
      stall_seen: coverpoint stalled {
        bins not_stalled = {1'b0};
        bins stalled = {1'b1};
      }
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      diagnostic_ap = new("diagnostic_ap", this);
      stall_seen_cg = new();
      sample_count = 0;
    endfunction

    function void sample_ready(logic ready_out, vial_logical_time_s logical_time);
      base_output_arbitration_diagnostic item;
      if ($isunknown(ready_out)) begin
        item = base_output_arbitration_diagnostic::type_id::create("coverage_unknown");
        item.diagnostic_id = "diagnostic/coverage/stall_seen/unknown";
        item.semantic_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::coverpoint::stall_seen";
        item.severity = UVM_ERROR;
        item.message = "stall_seen requires a known ready_out sample";
        item.logical_time = logical_time;
        diagnostic_ap.write(item);
        return;
      end
      stall_seen_cg.sample(ready_out === 1'b0);
      sample_count++;
    endfunction
  endclass

  class base_output_arbitration_event_counter_model extends uvm_component;
    `uvm_component_utils(base_output_arbitration_event_counter_model)

    uvm_analysis_port#(base_output_arbitration_diagnostic) diagnostic_ap;
    string instance_id;
    string event_id;
    bit [31:0] count;
    longint unsigned record_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      diagnostic_ap = new("diagnostic_ap", this);
      count = 0;
      record_count = 0;
    endfunction

    function void configure(string configured_instance_id, string configured_event_id);
      instance_id = configured_instance_id;
      event_id = configured_event_id;
    endfunction

    function void observe_event(vial_logical_time_s logical_time);
      base_output_arbitration_diagnostic item;
      if (count == 32'hffffffff) begin
        item = base_output_arbitration_diagnostic::type_id::create("model_overflow");
        item.diagnostic_id = {"diagnostic/model/overflow/", instance_id};
        item.semantic_id = instance_id;
        item.severity = UVM_ERROR;
        item.message = "event-counter model overflow";
        item.logical_time = logical_time;
        diagnostic_ap.write(item);
        return;
      end
      count++;
      record_count++;
    endfunction
  endclass

  class base_output_arbitration_write_scoreboard extends uvm_component;
    `uvm_component_utils(base_output_arbitration_write_scoreboard)

    localparam int unsigned CAPACITY = 4;
    uvm_analysis_imp#(base_output_arbitration_ahb_write_item, base_output_arbitration_write_scoreboard) actual_export;
    uvm_analysis_port#(base_output_arbitration_diagnostic) diagnostic_ap;
    protected base_output_arbitration_ahb_write_item expected_queue[$];
    protected base_output_arbitration_ahb_write_item actual_queue[$];
    longint unsigned match_count;
    longint unsigned mismatch_count;
    longint unsigned record_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      actual_export = new("actual_export", this);
      diagnostic_ap = new("diagnostic_ap", this);
      match_count = 0;
      mismatch_count = 0;
      record_count = 0;
    endfunction

    protected function base_output_arbitration_ahb_write_item checked_clone(base_output_arbitration_ahb_write_item source, string name);
      base_output_arbitration_ahb_write_item copy;
      if (source == null)
        `uvm_fatal("VIAL/SCOREBOARD", "scoreboard received a null transaction")
      if (!$cast(copy, source.clone()))
        `uvm_fatal("VIAL/SCOREBOARD", "scoreboard transaction clone has an incompatible type")
      copy.set_name(name);
      return copy;
    endfunction

    function void enqueue_expected(base_output_arbitration_ahb_write_item transaction);
      if (expected_queue.size() >= CAPACITY)
        `uvm_fatal("VIAL/SCOREBOARD/BOUND", "expected queue capacity exceeded")
      expected_queue.push_back(checked_clone(transaction, "expected"));
      record_count++;
      compare_ready();
    endfunction

    virtual function void write(base_output_arbitration_ahb_write_item transaction);
      if (actual_queue.size() >= CAPACITY)
        `uvm_fatal("VIAL/SCOREBOARD/BOUND", "actual queue capacity exceeded")
      actual_queue.push_back(checked_clone(transaction, "actual"));
      record_count++;
      compare_ready();
    endfunction

    protected function void compare_ready();
      base_output_arbitration_ahb_write_item expected;
      base_output_arbitration_ahb_write_item actual;
      base_output_arbitration_diagnostic item;
      while (expected_queue.size() && actual_queue.size()) begin
        expected = expected_queue.pop_front();
        actual = actual_queue.pop_front();
        record_count++;
        if (expected.compare(actual)) begin
          match_count++;
          continue;
        end
        mismatch_count++;
        item = base_output_arbitration_diagnostic::type_id::create("scoreboard_mismatch");
        item.diagnostic_id = "diagnostic/scoreboard/writes/mismatch";
        item.semantic_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scoreboard_instance::writes";
        item.severity = UVM_ERROR;
        item.message = "in-order transaction mismatch";
        diagnostic_ap.write(item);
      end
    endfunction

    function bit check_empty();
      base_output_arbitration_diagnostic item;
      record_count++;
      if (!expected_queue.size() && !actual_queue.size() && mismatch_count == 0)
        return 1'b1;
      item = base_output_arbitration_diagnostic::type_id::create("scoreboard_pending");
      item.diagnostic_id = "diagnostic/scoreboard/writes/not_empty";
      item.semantic_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scoreboard_instance::writes";
      item.severity = UVM_ERROR;
      item.message = $sformatf("scoreboard check failed: expected=%0d actual=%0d mismatches=%0d", expected_queue.size(), actual_queue.size(), mismatch_count);
      diagnostic_ap.write(item);
      return 1'b0;
    endfunction

    function void reset_scenario();
      expected_queue.delete();
      actual_queue.delete();
      mismatch_count = 0;
    endfunction
  endclass

  function automatic base_output_arbitration_ahb_write_item make_success_expected();
    base_output_arbitration_ahb_write_item expected;
    expected = base_output_arbitration_ahb_write_item::type_id::create("success_expected");
    expected.semantic_id = "ahb_subordinate_base_output_arbitration::transaction::ahb_write";
    expected.scenario_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";
    expected.handle_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::handle::success_write";
    expected.address = 32'h00000000;
    expected.transfer = 2'h2;
    expected.write = 1'h1;
    expected.size = 3'h2;
    expected.data = 32'hcafebabe;
    expected.wait_cycles = 4'h2;
    return expected;
  endfunction

  class base_output_arbitration_fault_controller extends uvm_component;
    `uvm_component_utils(base_output_arbitration_fault_controller)

    uvm_analysis_port#(base_output_arbitration_diagnostic) diagnostic_ap;
    bit armed;
    int unsigned remaining_drive_intervals;
    longint unsigned record_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      diagnostic_ap = new("diagnostic_ap", this);
      armed = 1'b0;
      remaining_drive_intervals = 0;
      record_count = 0;
    endfunction

    function void arm();
      if (armed)
        `uvm_fatal("VIAL/FAULT/ARM", "substitution fault is already armed")
      armed = 1'b1;
      remaining_drive_intervals = 1;
      record_count++;
    endfunction

    function void apply_next_drive(ref base_output_arbitration_ahb_write_item transaction);
      if (!armed) return;
      transaction.size = 3'h7;
      record_count++;
      remaining_drive_intervals--;
      if (remaining_drive_intervals == 0) begin
        armed = 1'b0;
        record_count++;
      end
    endfunction
  endclass

  class base_output_arbitration_property_checker extends uvm_component;
    `uvm_component_utils(base_output_arbitration_property_checker)

    uvm_analysis_port#(base_output_arbitration_diagnostic) diagnostic_ap;
    longint unsigned expectation_count;
    longint unsigned failure_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      diagnostic_ap = new("diagnostic_ap", this);
      expectation_count = 0;
      failure_count = 0;
    endfunction

    function void record(string expectation_id, bit passed, string detail, vial_logical_time_s logical_time);
      base_output_arbitration_diagnostic item;
      expectation_count++;
      if (passed) return;
      failure_count++;
      item = base_output_arbitration_diagnostic::type_id::create("expectation_failure");
      item.diagnostic_id = {"diagnostic/expectation/", expectation_id};
      item.semantic_id = expectation_id;
      item.severity = UVM_ERROR;
      item.message = detail;
      item.logical_time = logical_time;
      diagnostic_ap.write(item);
    endfunction
  endclass
endpackage
