// Generated native VIAL stimulus and service structures.
// Native role-substitution, RAL, and constraint forms are private typed previews.
package base_output_arbitration_services_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;

  class base_output_arbitration_ahb_write_item extends uvm_sequence_item;
    `uvm_object_utils(base_output_arbitration_ahb_write_item)

    string semantic_id;
    string scenario_id;
    string handle_id;
    logic [31:0] address;
    logic [1:0] transfer;
    bit write;
    logic [2:0] size;
    logic [31:0] data;
    bit [3:0] wait_cycles;

    function new(string name = "base_output_arbitration_ahb_write_item");
      super.new(name);
      semantic_id = "";
      scenario_id = "";
      handle_id = "";
    endfunction

    virtual function void do_copy(uvm_object rhs);
      base_output_arbitration_ahb_write_item rhs_item;
      super.do_copy(rhs);
      if (!$cast(rhs_item, rhs))
        `uvm_fatal("VIAL/ITEM/COPY", "transaction-item type mismatch")
      semantic_id = rhs_item.semantic_id;
      scenario_id = rhs_item.scenario_id;
      handle_id = rhs_item.handle_id;
      address = rhs_item.address;
      transfer = rhs_item.transfer;
      write = rhs_item.write;
      size = rhs_item.size;
      data = rhs_item.data;
      wait_cycles = rhs_item.wait_cycles;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
      base_output_arbitration_ahb_write_item rhs_item;
      if (!$cast(rhs_item, rhs)) return 0;
      if (!super.do_compare(rhs, comparer)) return 0;
      if (semantic_id != rhs_item.semantic_id ||
          scenario_id != rhs_item.scenario_id ||
          handle_id != rhs_item.handle_id) return 0;
      if (address !== rhs_item.address ||
          transfer !== rhs_item.transfer ||
          write !== rhs_item.write ||
          size !== rhs_item.size ||
          data !== rhs_item.data ||
          wait_cycles !== rhs_item.wait_cycles) return 0;
      return 1;
    endfunction

    virtual function void do_print(uvm_printer printer);
      super.do_print(printer);
      printer.print_string("semantic_id", semantic_id);
      printer.print_string("scenario_id", scenario_id);
      printer.print_string("handle_id", handle_id);
      printer.print_field("address", address, 32, UVM_HEX);
      printer.print_field("transfer", transfer, 2, UVM_HEX);
      printer.print_field("write", write, 1, UVM_HEX);
      printer.print_field("size", size, 3, UVM_HEX);
      printer.print_field("data", data, 32, UVM_HEX);
      printer.print_field("wait_cycles", wait_cycles, 4, UVM_HEX);
    endfunction
  endclass

  class base_output_arbitration_native_wait_decision extends uvm_object;
    `uvm_object_utils(base_output_arbitration_native_wait_decision)

    string decision_id;
    int unsigned seed;
    int unsigned attempt_bound;
    int unsigned attempt_count;
    rand bit [3:0] candidate;
    bit [3:0] accepted_value;
    bit replayed;

    constraint selected_domain_c {
      candidate inside {[4'h1:4'h2]};
    }

    function new(string name = "base_output_arbitration_native_wait_decision");
      super.new(name);
      attempt_bound = 64;
      attempt_count = 0;
      accepted_value = 4'h1;
      replayed = 1'b0;
    endfunction

    function void configure(string configured_id, int unsigned configured_seed);
      decision_id = configured_id;
      seed = configured_seed;
    endfunction

    function void replay_selected(bit [3:0] selected);
      if (!(selected inside {[4'h1:4'h2]}))
        `uvm_fatal("VIAL/DECISION/REPLAY", "replayed decision is outside its selected domain")
      accepted_value = selected;
      replayed = 1'b1;
    endfunction

    function bit solve_native_preview();
      this.srandom(seed);
      for (attempt_count = 1; attempt_count <= attempt_bound; attempt_count++) begin
        if (randomize()) begin
          accepted_value = candidate;
          replayed = 1'b0;
          return 1;
        end
      end
      return 0;
    endfunction
  endclass

  class base_output_arbitration_success_sequence extends uvm_sequence#(base_output_arbitration_ahb_write_item);
    `uvm_object_utils(base_output_arbitration_success_sequence)

    function new(string name = "base_output_arbitration_success_sequence");
      super.new(name);
    endfunction

    virtual task body();
      base_output_arbitration_ahb_write_item request;
      base_output_arbitration_native_wait_decision decision;
      decision = base_output_arbitration_native_wait_decision::type_id::create("decision");
      decision.configure("success.wait_cycles", 1);
      decision.replay_selected(4'h2);
      request = base_output_arbitration_ahb_write_item::type_id::create("request_0");
      start_item(request);
      request.semantic_id = "ahb_subordinate_base_output_arbitration::transaction::ahb_write";
      request.scenario_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";
      request.handle_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::handle::success_write";
      request.address = 32'h00000000;
      request.transfer = 2'h2;
      request.write = 1'h1;
      request.size = 3'h2;
      request.data = 32'hcafebabe;
      request.wait_cycles = decision.accepted_value;
      finish_item(request);
    endtask
  endclass

  class base_output_arbitration_unsupported_size_sequence extends uvm_sequence#(base_output_arbitration_ahb_write_item);
    `uvm_object_utils(base_output_arbitration_unsupported_size_sequence)

    function new(string name = "base_output_arbitration_unsupported_size_sequence");
      super.new(name);
    endfunction

    virtual task body();
      base_output_arbitration_ahb_write_item request;
      request = base_output_arbitration_ahb_write_item::type_id::create("request_0");
      start_item(request);
      request.semantic_id = "ahb_subordinate_base_output_arbitration::transaction::ahb_write";
      request.scenario_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size";
      request.handle_id = "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::handle::error_write";
      request.address = 32'h00000000;
      request.transfer = 2'h2;
      request.write = 1'h1;
      request.size = 3'h2;
      request.data = 32'hffffffff;
      request.wait_cycles = 4'h1;
      finish_item(request);
    endtask
  endclass

  class base_output_arbitration_transaction_observer extends uvm_subscriber#(base_output_arbitration_ahb_write_item);
    `uvm_component_utils(base_output_arbitration_transaction_observer)

    longint unsigned observation_count;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      observation_count = 0;
    endfunction

    virtual function void write(base_output_arbitration_ahb_write_item transaction);
      if (transaction == null)
        `uvm_fatal("VIAL/TLM/WRITE", "analysis subscriber received a null transaction")
      observation_count++;
    endfunction
  endclass

  class base_output_arbitration_reg_data_reg extends uvm_reg;
    `uvm_object_utils(base_output_arbitration_reg_data_reg)

    rand uvm_reg_field value;

    function new(string name = "base_output_arbitration_reg_data_reg");
      super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      value = uvm_reg_field::type_id::create("value");
      value.configure(this, 32, 0, "RO", 0, 32'h00000000, 1, 0, 0);
    endfunction
  endclass

  class base_output_arbitration_reg_block extends uvm_reg_block;
    `uvm_object_utils(base_output_arbitration_reg_block)

    rand base_output_arbitration_reg_data_reg reg_data;

    function new(string name = "base_output_arbitration_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
      reg_data = base_output_arbitration_reg_data_reg::type_id::create("reg_data");
      reg_data.configure(this);
      reg_data.build();
      default_map = create_map("default_map", 0, 4, UVM_LITTLE_ENDIAN, 1);
      default_map.add_reg(reg_data, 0, "RO");
    endfunction
  endclass

  class base_output_arbitration_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(base_output_arbitration_reg_adapter)

    function new(string name = "base_output_arbitration_reg_adapter");
      super.new(name);
      supports_byte_enable = 1'b0;
      provides_responses = 1'b0;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      base_output_arbitration_ahb_write_item transaction;
      transaction = base_output_arbitration_ahb_write_item::type_id::create("ral_request");
      transaction.semantic_id = "ahb_subordinate_base_output_arbitration::transaction::ahb_write";
      transaction.address = rw.addr[31:0];
      transaction.transfer = 2'h2;
      transaction.write = (rw.kind == UVM_WRITE);
      transaction.size = 3'h2;
      transaction.data = rw.data[31:0];
      transaction.wait_cycles = 4'h1;
      return transaction;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      base_output_arbitration_ahb_write_item transaction;
      if (!$cast(transaction, bus_item))
        `uvm_fatal("VIAL/RAL/ADAPTER", "RAL adapter received an incompatible item")
      rw.kind = transaction.write ? UVM_WRITE : UVM_READ;
      rw.addr = transaction.address;
      rw.data = transaction.data;
      rw.status = UVM_IS_OK;
    endfunction
  endclass

  class base_output_arbitration_reg_predictor extends uvm_reg_predictor#(base_output_arbitration_ahb_write_item);
    `uvm_component_utils(base_output_arbitration_reg_predictor)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass
endpackage
