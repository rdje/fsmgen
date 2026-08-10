library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

package base_output_arbitration_metadata_pkg is
  constant VIAL_PLAN_ID : string := "plan/dff960e224818f42aee83cda21cbcea82d49d23384c196618ea67415353e14ad";
  constant VIAL_FIXTURE_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration";
  constant VIAL_EXECUTION_PROFILE : string := "core_directed_single_clock_execution_v1";
  constant VIAL_BRIDGE_MANIFEST_ID : string := "bridge/326606e2b4d02515173c4512d65f9ae6ae591bd5ccf0e8414226268234d039b3";
  constant VIAL_UNIT_ID : string := "unit/ahb_lite_subordinate";
  constant VIAL_DOMAIN_ID : string := "domain/ahb_bus";
  constant VIAL_ACTIVE_EDGE : string := "rising";
  constant VIAL_INACTIVE_EDGE : string := "falling";
  constant VIAL_RESET_KIND : string := "async";
  constant VIAL_RESET_POLARITY : string := "active_low";
  constant VIAL_SCHEDULER_COUNT : natural := 1;
  constant VIAL_OPERATION_COUNT : natural := 21;
  constant VIAL_SCENARIO_COUNT : natural := 2;
  constant VIAL_FIBER_COUNT : natural := 4;
  constant VIAL_MODEL_COUNT : natural := 2;

  -- VIAL operation 00: reset at static rank 0
  constant VIAL_OPERATION_00_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~10/root";
  constant VIAL_OPERATION_00_KIND : string := "reset";
  constant VIAL_OPERATION_00_STATIC_RANK : natural := 0;
  constant VIAL_OPERATION_00_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 01: scoreboard_expect at static rank 1
  constant VIAL_OPERATION_01_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~11/root";
  constant VIAL_OPERATION_01_KIND : string := "scoreboard_expect";
  constant VIAL_OPERATION_01_STATIC_RANK : natural := 1;
  constant VIAL_OPERATION_01_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 02: start at static rank 2
  constant VIAL_OPERATION_02_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~12/root";
  constant VIAL_OPERATION_02_KIND : string := "start";
  constant VIAL_OPERATION_02_STATIC_RANK : natural := 2;
  constant VIAL_OPERATION_02_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 03: parallel at static rank 3
  constant VIAL_OPERATION_03_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/root";
  constant VIAL_OPERATION_03_KIND : string := "parallel";
  constant VIAL_OPERATION_03_STATIC_RANK : natural := 3;
  constant VIAL_OPERATION_03_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 04: await at static rank 4
  constant VIAL_OPERATION_04_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13~1fibers~10~1actions~10/root";
  constant VIAL_OPERATION_04_KIND : string := "await";
  constant VIAL_OPERATION_04_STATIC_RANK : natural := 4;
  constant VIAL_OPERATION_04_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/complete/root";

  -- VIAL operation 05: await at static rank 5
  constant VIAL_OPERATION_05_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13~1fibers~11~1actions~10/root";
  constant VIAL_OPERATION_05_KIND : string := "await";
  constant VIAL_OPERATION_05_STATIC_RANK : natural := 5;
  constant VIAL_OPERATION_05_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/stall/root";

  -- VIAL operation 06: expect at static rank 6
  constant VIAL_OPERATION_06_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~14/root";
  constant VIAL_OPERATION_06_KIND : string := "expect";
  constant VIAL_OPERATION_06_STATIC_RANK : natural := 6;
  constant VIAL_OPERATION_06_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 07: expect at static rank 7
  constant VIAL_OPERATION_07_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~15/root";
  constant VIAL_OPERATION_07_KIND : string := "expect";
  constant VIAL_OPERATION_07_STATIC_RANK : natural := 7;
  constant VIAL_OPERATION_07_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 08: expect at static rank 8
  constant VIAL_OPERATION_08_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~16/root";
  constant VIAL_OPERATION_08_KIND : string := "expect";
  constant VIAL_OPERATION_08_STATIC_RANK : natural := 8;
  constant VIAL_OPERATION_08_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 09: expect at static rank 9
  constant VIAL_OPERATION_09_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~17/root";
  constant VIAL_OPERATION_09_KIND : string := "expect";
  constant VIAL_OPERATION_09_STATIC_RANK : natural := 9;
  constant VIAL_OPERATION_09_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 10: expect at static rank 10
  constant VIAL_OPERATION_10_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~18/root";
  constant VIAL_OPERATION_10_KIND : string := "expect";
  constant VIAL_OPERATION_10_STATIC_RANK : natural := 10;
  constant VIAL_OPERATION_10_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 11: scoreboard_check at static rank 11
  constant VIAL_OPERATION_11_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~19/root";
  constant VIAL_OPERATION_11_KIND : string := "scoreboard_check";
  constant VIAL_OPERATION_11_STATIC_RANK : natural := 11;
  constant VIAL_OPERATION_11_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";

  -- VIAL operation 12: reset at static rank 0
  constant VIAL_OPERATION_12_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~10/root";
  constant VIAL_OPERATION_12_KIND : string := "reset";
  constant VIAL_OPERATION_12_STATIC_RANK : natural := 0;
  constant VIAL_OPERATION_12_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 13: inject at static rank 1
  constant VIAL_OPERATION_13_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~11/root";
  constant VIAL_OPERATION_13_KIND : string := "inject";
  constant VIAL_OPERATION_13_STATIC_RANK : natural := 1;
  constant VIAL_OPERATION_13_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 14: start at static rank 2
  constant VIAL_OPERATION_14_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~12/root";
  constant VIAL_OPERATION_14_KIND : string := "start";
  constant VIAL_OPERATION_14_STATIC_RANK : natural := 2;
  constant VIAL_OPERATION_14_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 15: await at static rank 3
  constant VIAL_OPERATION_15_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~13/root";
  constant VIAL_OPERATION_15_KIND : string := "await";
  constant VIAL_OPERATION_15_STATIC_RANK : natural := 3;
  constant VIAL_OPERATION_15_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 16: expect at static rank 4
  constant VIAL_OPERATION_16_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~14/root";
  constant VIAL_OPERATION_16_KIND : string := "expect";
  constant VIAL_OPERATION_16_STATIC_RANK : natural := 4;
  constant VIAL_OPERATION_16_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 17: expect at static rank 5
  constant VIAL_OPERATION_17_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~15/root";
  constant VIAL_OPERATION_17_KIND : string := "expect";
  constant VIAL_OPERATION_17_STATIC_RANK : natural := 5;
  constant VIAL_OPERATION_17_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 18: expect at static rank 6
  constant VIAL_OPERATION_18_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~16/root";
  constant VIAL_OPERATION_18_KIND : string := "expect";
  constant VIAL_OPERATION_18_STATIC_RANK : natural := 6;
  constant VIAL_OPERATION_18_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 19: expect at static rank 7
  constant VIAL_OPERATION_19_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~17/root";
  constant VIAL_OPERATION_19_KIND : string := "expect";
  constant VIAL_OPERATION_19_STATIC_RANK : natural := 7;
  constant VIAL_OPERATION_19_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL operation 20: expect at static rank 8
  constant VIAL_OPERATION_20_ID : string := "operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/~1packages~10~1fixtures~10~1scenarios~11~1actions~18/root";
  constant VIAL_OPERATION_20_KIND : string := "expect";
  constant VIAL_OPERATION_20_STATIC_RANK : natural := 8;
  constant VIAL_OPERATION_20_FIBER_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";

  -- VIAL scenario 00: success
  constant VIAL_SCENARIO_00_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";
  constant VIAL_SCENARIO_00_TIMEOUT_CYCLES : natural := 256;
  constant VIAL_SCENARIO_00_FIBER_COUNT : natural := 3;

  -- VIAL scenario 01: unsupported_size
  constant VIAL_SCENARIO_01_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size";
  constant VIAL_SCENARIO_01_TIMEOUT_CYCLES : natural := 256;
  constant VIAL_SCENARIO_01_FIBER_COUNT : natural := 1;

  -- VIAL fiber 00: root
  constant VIAL_FIBER_00_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root";
  constant VIAL_FIBER_00_CANCEL_SCOPE_ID : string := "cancel-scope/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";

  -- VIAL fiber 01: complete
  constant VIAL_FIBER_01_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/complete/root";
  constant VIAL_FIBER_01_CANCEL_SCOPE_ID : string := "cancel-scope/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";

  -- VIAL fiber 02: stall
  constant VIAL_FIBER_02_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/stall/root";
  constant VIAL_FIBER_02_CANCEL_SCOPE_ID : string := "cancel-scope/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success";

  -- VIAL fiber 03: root
  constant VIAL_FIBER_03_ID : string := "fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root";
  constant VIAL_FIBER_03_CANCEL_SCOPE_ID : string := "cancel-scope/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size";

  -- VIAL model 00: event_counter
  constant VIAL_MODEL_00_INSTANCE_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::accepts";
  constant VIAL_MODEL_00_TRIGGER_EVENT_ID : string := "ahb_subordinate_base_output_arbitration::transaction::ahb_write::event::accepted";

  -- VIAL model 01: event_counter
  constant VIAL_MODEL_01_INSTANCE_ID : string := "ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::completions";
  constant VIAL_MODEL_01_TRIGGER_EVENT_ID : string := "ahb_subordinate_base_output_arbitration::transaction::ahb_write::event::completed";

end package base_output_arbitration_metadata_pkg;
