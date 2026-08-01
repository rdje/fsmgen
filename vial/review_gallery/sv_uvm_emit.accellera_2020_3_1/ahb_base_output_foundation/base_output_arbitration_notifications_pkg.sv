// Generated native VIAL notification/interception structures.
// Interceptor tables are a private typed preview until public VIAL syntax is selected.
package base_output_arbitration_notifications_pkg;
  timeunit 1ns;
  timeprecision 1ps;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fsmgen_vial_uvm_types_pkg::*;

  class base_output_arbitration_notification_payload extends uvm_object;
    `uvm_object_utils(base_output_arbitration_notification_payload)

    string notification_id;
    string semantic_id;
    vial_logical_time_s logical_time;
    logic [31:0] haddr;
    logic [31:0] hrdata;
    logic hready;
    logic hreadyout;
    logic hresp;
    logic hsel;
    logic [2:0] hsize;
    logic [1:0] htrans;
    logic [31:0] hwdata;
    logic hwrite;
    logic rst_n;
    logic [3:0] wait_cycles;

    function new(string name = "base_output_arbitration_notification_payload");
      super.new(name);
      notification_id = "";
      semantic_id = "";
      logical_time = '{cycle: 0, ordinal: 0, phase: VIAL_DRIVE_PHASE};
    endfunction

    function base_output_arbitration_notification_payload clone_payload(string suffix = "copy");
      base_output_arbitration_notification_payload copy;
      copy = new({get_name(), "_", suffix});
      copy.notification_id = notification_id;
      copy.semantic_id = semantic_id;
      copy.logical_time = logical_time;
      copy.haddr = haddr;
      copy.hrdata = hrdata;
      copy.hready = hready;
      copy.hreadyout = hreadyout;
      copy.hresp = hresp;
      copy.hsel = hsel;
      copy.hsize = hsize;
      copy.htrans = htrans;
      copy.hwdata = hwdata;
      copy.hwrite = hwrite;
      copy.rst_n = rst_n;
      copy.wait_cycles = wait_cycles;
      return copy;
    endfunction
  endclass

  class base_output_arbitration_interceptor extends uvm_object;
    `uvm_object_utils(base_output_arbitration_interceptor)

    string semantic_id;
    string registration_scope_id;
    int unsigned rank;
    vial_filter_e filter_kind;
    vial_effect_e effect_kind;
    vial_lifetime_e lifetime;

    function new(string name = "base_output_arbitration_interceptor");
      super.new(name);
      semantic_id = "";
      registration_scope_id = "";
      rank = 0;
      filter_kind = VIAL_FILTER_NEVER;
      effect_kind = VIAL_EFFECT_OBSERVE;
      lifetime = VIAL_LIFETIME_SCENARIO;
    endfunction
  endclass

  class base_output_arbitration_notification_dispatcher extends uvm_event_callback#(base_output_arbitration_notification_payload);
    `uvm_object_utils(base_output_arbitration_notification_dispatcher)

    string notification_id;
    protected base_output_arbitration_interceptor ordered_interceptors[$];
    protected bit registration_frozen;
    protected bit dispatch_live;
    base_output_arbitration_notification_payload effective_payload;
    longint unsigned evaluated_count;
    longint unsigned skipped_count;
    longint unsigned observation_count;
    longint unsigned cancellation_count;
    longint unsigned diagnostic_count;
    longint unsigned committed_count;

    function new(string name = "base_output_arbitration_notification_dispatcher");
      super.new(name);
      registration_frozen = 0;
      dispatch_live = 0;
      evaluated_count = 0;
      skipped_count = 0;
      observation_count = 0;
      cancellation_count = 0;
      diagnostic_count = 0;
      committed_count = 0;
    endfunction

    function void register_interceptor(base_output_arbitration_interceptor candidate);
      int unsigned insert_index;
      if (candidate == null)
        `uvm_fatal("VIAL/NOTIFY/REGISTER", "null interceptor registration")
      if (registration_frozen)
        `uvm_fatal("VIAL/NOTIFY/REGISTER", "late interceptor registration")
      foreach (ordered_interceptors[i]) begin
        if (ordered_interceptors[i].semantic_id == candidate.semantic_id) begin
          if (ordered_interceptors[i].rank == candidate.rank &&
              ordered_interceptors[i].filter_kind == candidate.filter_kind &&
              ordered_interceptors[i].effect_kind == candidate.effect_kind)
            return;
          `uvm_fatal("VIAL/NOTIFY/REGISTER", "non-idempotent duplicate interceptor identity")
        end
        if (ordered_interceptors[i].rank == candidate.rank)
          `uvm_fatal("VIAL/NOTIFY/REGISTER", "duplicate interceptor rank")
      end
      insert_index = ordered_interceptors.size();
      foreach (ordered_interceptors[i]) begin
        if (candidate.rank < ordered_interceptors[i].rank ||
            (candidate.rank == ordered_interceptors[i].rank &&
             candidate.semantic_id < ordered_interceptors[i].semantic_id)) begin
          insert_index = i;
          break;
        end
      end
      ordered_interceptors.insert(insert_index, candidate);
    endfunction

    function void freeze_registration();
      registration_frozen = 1;
    endfunction

    protected function bit filter_matches(vial_filter_e filter_kind, base_output_arbitration_notification_payload data);
      case (filter_kind)
        VIAL_FILTER_ALWAYS: return 1'b1;
        VIAL_FILTER_NEVER: return 1'b0;
        VIAL_FILTER_RESPONSE_ERROR: return (data.hresp === 1'b1);
        default: return 1'b0;
      endcase
    endfunction

    protected function void apply_effect(vial_effect_e effect_kind, ref bit cancelled);
      case (effect_kind)
        VIAL_EFFECT_OBSERVE: observation_count++;
        VIAL_EFFECT_CANCEL: cancelled = 1'b1;
        VIAL_EFFECT_APPEND_DIAGNOSTIC: diagnostic_count++;
        default: `uvm_fatal("VIAL/NOTIFY/EFFECT", "effect is not selected by this typed preview")
      endcase
    endfunction

    virtual function bit pre_trigger(uvm_event#(base_output_arbitration_notification_payload) event_h, base_output_arbitration_notification_payload data);
      bit cancelled;
      if (!registration_frozen)
        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "notification triggered before registration freeze")
      if (dispatch_live)
        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "target-stack callback recursion is forbidden")
      if (data == null)
        `uvm_fatal("VIAL/NOTIFY/DISPATCH", "notification payload is null")
      dispatch_live = 1'b1;
      cancelled = 1'b0;
      effective_payload = data.clone_payload("effective");
      foreach (ordered_interceptors[i]) begin
        if (cancelled) begin
          skipped_count++;
          continue;
        end
        evaluated_count++;
        if (filter_matches(ordered_interceptors[i].filter_kind, effective_payload))
          apply_effect(ordered_interceptors[i].effect_kind, cancelled);
      end
      if (cancelled) begin
        cancellation_count++;
        dispatch_live = 1'b0;
        return 1'b1;
      end
      return 1'b0;
    endfunction

    virtual function void post_trigger(uvm_event#(base_output_arbitration_notification_payload) event_h, base_output_arbitration_notification_payload data);
      committed_count++;
      dispatch_live = 1'b0;
    endfunction
  endclass

  class base_output_arbitration_notification_channel extends uvm_object;
    `uvm_object_utils(base_output_arbitration_notification_channel)

    string notification_id;
    string scope_id;
    string persistence;
    string trigger_policy;
    vial_lifetime_e lifetime;
    vial_reentrancy_e reentrancy;
    int unsigned queue_bound;
    longint unsigned occurrence_bound;
    longint unsigned occurrence_count;
    uvm_event#(base_output_arbitration_notification_payload) event_h;
    base_output_arbitration_notification_dispatcher dispatcher_h;
    protected base_output_arbitration_notification_payload pending[$];
    protected bit trigger_live;

    function new(string name = "base_output_arbitration_notification_channel");
      super.new(name);
      trigger_live = 1'b0;
      occurrence_count = 0;
    endfunction

    function void configure(
      string configured_notification_id,
      string configured_scope_id,
      vial_reentrancy_e configured_reentrancy,
      int unsigned configured_queue_bound = 16,
      longint unsigned configured_occurrence_bound = 4096
    );
      notification_id = configured_notification_id;
      scope_id = configured_scope_id;
      persistence = "transient";
      trigger_policy = configured_reentrancy == VIAL_REENTRANCY_QUEUE ? "queued" : "single";
      lifetime = VIAL_LIFETIME_SCENARIO;
      reentrancy = configured_reentrancy;
      queue_bound = configured_queue_bound;
      occurrence_bound = configured_occurrence_bound;
      event_h = new({get_name(), "_event"});
      dispatcher_h = base_output_arbitration_notification_dispatcher::type_id::create({get_name(), "_dispatcher"});
      dispatcher_h.notification_id = notification_id;
      event_h.add_callback(dispatcher_h);
    endfunction

    function void register_interceptor(base_output_arbitration_interceptor candidate);
      dispatcher_h.register_interceptor(candidate);
    endfunction

    function void freeze_registration();
      dispatcher_h.freeze_registration();
    endfunction

    task trigger_notification(base_output_arbitration_notification_payload data);
      base_output_arbitration_notification_payload current;
      if (data == null)
        `uvm_fatal("VIAL/NOTIFY/TRIGGER", "notification payload is null")
      if (trigger_live) begin
        if (reentrancy == VIAL_REENTRANCY_REJECT)
          `uvm_fatal("VIAL/NOTIFY/REENTRANCY", "nested notification rejected")
        if (pending.size() >= queue_bound)
          `uvm_fatal("VIAL/NOTIFY/QUEUE", "notification queue bound exceeded")
        pending.push_back(data.clone_payload("queued"));
        return;
      end
      current = data;
      while (current != null) begin
        if (occurrence_count >= occurrence_bound)
          `uvm_fatal("VIAL/NOTIFY/OCCURRENCES", "notification occurrence bound exceeded")
        trigger_live = 1'b1;
        occurrence_count++;
        event_h.trigger(current);
        trigger_live = 1'b0;
        current = pending.size() ? pending.pop_front() : null;
      end
    endtask
  endclass

  class base_output_arbitration_notification_registry extends uvm_object;
    `uvm_object_utils(base_output_arbitration_notification_registry)

    protected base_output_arbitration_notification_channel channels[$];
    base_output_arbitration_notification_channel requested_notification;
    base_output_arbitration_notification_channel accepted_notification;
    base_output_arbitration_notification_channel captured_notification;
    base_output_arbitration_notification_channel held_notification;
    base_output_arbitration_notification_channel completed_notification;
    base_output_arbitration_notification_channel error_notification;

    function new(string name = "base_output_arbitration_notification_registry");
      super.new(name);
    endfunction

    protected function base_output_arbitration_interceptor make_interceptor(
      string semantic_id,
      string registration_scope_id,
      int unsigned rank,
      vial_filter_e filter_kind,
      vial_effect_e effect_kind
    );
      base_output_arbitration_interceptor item;
      item = base_output_arbitration_interceptor::type_id::create({"interceptor_", semantic_id});
      item.semantic_id = semantic_id;
      item.registration_scope_id = registration_scope_id;
      item.rank = rank;
      item.filter_kind = filter_kind;
      item.effect_kind = effect_kind;
      item.lifetime = VIAL_LIFETIME_SCENARIO;
      return item;
    endfunction

    function void configure_preview();
      requested_notification = base_output_arbitration_notification_channel::type_id::create("requested_notification");
      requested_notification.configure("event/ahb_write/requested", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_QUEUE, 16, 4096);
      requested_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::requested::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      requested_notification.freeze_registration();
      channels.push_back(requested_notification);
      accepted_notification = base_output_arbitration_notification_channel::type_id::create("accepted_notification");
      accepted_notification.configure("event/ahb_write/accepted", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_REJECT, 16, 4096);
      accepted_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::accepted::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      accepted_notification.freeze_registration();
      channels.push_back(accepted_notification);
      captured_notification = base_output_arbitration_notification_channel::type_id::create("captured_notification");
      captured_notification.configure("event/ahb_write/captured", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_QUEUE, 16, 4096);
      captured_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::captured::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      captured_notification.freeze_registration();
      channels.push_back(captured_notification);
      held_notification = base_output_arbitration_notification_channel::type_id::create("held_notification");
      held_notification.configure("event/ahb_write/held", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_REJECT, 16, 4096);
      held_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::held::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      held_notification.freeze_registration();
      channels.push_back(held_notification);
      completed_notification = base_output_arbitration_notification_channel::type_id::create("completed_notification");
      completed_notification.configure("event/ahb_write/completed", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_QUEUE, 16, 4096);
      completed_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::completed::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      completed_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::completed::cancel_error", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 20, VIAL_FILTER_RESPONSE_ERROR, VIAL_EFFECT_CANCEL));
      completed_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::completed::diagnostic", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 30, VIAL_FILTER_ALWAYS, VIAL_EFFECT_APPEND_DIAGNOSTIC));
      completed_notification.freeze_registration();
      channels.push_back(completed_notification);
      error_notification = base_output_arbitration_notification_channel::type_id::create("error_notification");
      error_notification.configure("event/ahb_write/error", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", VIAL_REENTRANCY_REJECT, 16, 4096);
      error_notification.register_interceptor(make_interceptor("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::transaction_binding::write::event::error::observe", "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration", 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE));
      error_notification.freeze_registration();
      channels.push_back(error_notification);
    endfunction

    function base_output_arbitration_notification_channel by_notification_id(string notification_id);
      foreach (channels[i]) begin
        if (channels[i].notification_id == notification_id)
          return channels[i];
      end
      `uvm_fatal("VIAL/NOTIFY/LOOKUP", {"unknown notification ", notification_id})
      return null;
    endfunction

    function longint unsigned total_occurrences();
      longint unsigned total;
      total = 0;
      foreach (channels[i]) total += channels[i].occurrence_count;
      return total;
    endfunction
  endclass
endpackage
