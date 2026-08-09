library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use std.env.all;

use work.fsmgen_vial_types_pkg.all;
use work.fsmgen_vial_runtime_pkg.all;
use work.base_output_arbitration_metadata_pkg.all;

entity base_output_arbitration_tb is
end entity base_output_arbitration_tb;

architecture portable_semantics of base_output_arbitration_tb is
  signal HADDR : std_logic_vector(31 downto 0) := (others => '0');
  signal HRDATA : std_logic_vector(31 downto 0);
  signal HREADY : std_logic;
  signal HREADYOUT : std_logic;
  signal HRESP : std_logic;
  signal HSEL : std_logic := '0';
  signal HSIZE : std_logic_vector(2 downto 0) := (others => '0');
  signal HTRANS : std_logic_vector(1 downto 0) := (others => '0');
  signal HWDATA : std_logic_vector(31 downto 0) := (others => '0');
  signal HWRITE : std_logic := '0';
  signal clk : std_logic := '0';
  signal rst_n : std_logic := '0';
  signal wait_cycles : std_logic_vector(3 downto 0) := (others => '0');
  signal vial_probe_reg_data_q : std_logic_vector(31 downto 0);

  component base_output_arbitration_probe_adapter is
    port (
      vial_probe_reg_data_q : out std_logic_vector(31 downto 0)
    );
  end component;

begin
  dut : entity work.ahb_lite_subordinate(rtl)
    port map (
      HADDR => HADDR,
      HRDATA => HRDATA,
      HREADY => HREADY,
      HREADYOUT => HREADYOUT,
      HRESP => HRESP,
      HSEL => HSEL,
      HSIZE => HSIZE,
      HTRANS => HTRANS,
      HWDATA => HWDATA,
      HWRITE => HWRITE,
      clk => clk,
      rst_n => rst_n,
      wait_cycles => wait_cycles
    );

  probe_adapter : base_output_arbitration_probe_adapter
    port map (
      vial_probe_reg_data_q => vial_probe_reg_data_q
    );

  HREADY <= HREADYOUT;

  vial_clock_generator : process
  begin
    loop
      wait for 1 ns;
      clk <= not clk;
    end loop;
  end process vial_clock_generator;

  vial_scheduler : process
    variable vial_runtime_state : vial_runtime_state_t := VIAL_RUNTIME_CONSTRUCTED;
    variable vial_time : vial_logical_time_t := VIAL_INITIAL_LOGICAL_TIME;
    variable vial_scenario_status : vial_scenario_status_t := VIAL_SCENARIO_DORMANT;
    variable vial_current_scenario : natural := 0;
    variable vial_scenario_timeout : natural := 0;
    variable vial_current_operation_rank : natural := 0;
    variable vial_scenario_started : boolean := false;
    variable vial_scenario_done : boolean := false;
    variable vial_transaction_active : boolean := false;
    variable vial_transaction_accepted : boolean := false;
    variable vial_scoreboard : vial_scoreboard_state_t := (0, 0, 0, 0, false);
    variable vial_coverage : vial_coverage_counter_t := (0, 0);
    variable vial_fault : vial_fault_state_t := (false, 0, 0);
    variable vial_scoreboard_comparisons_total : natural := 0;
    variable vial_scoreboard_mismatches_total : natural := 0;
    variable vial_scoreboard_overflowed_any : boolean := false;
    variable vial_fault_applications_total : natural := 0;
    variable vial_nonzero_read_data_count : natural := 0;
    variable vial_check_passes : natural := 0;
    variable vial_check_failures : natural := 0;
    variable vial_unknown_evidence : natural := 0;
    variable vial_diagnostic_count : natural := 0;
    variable vial_diagnostics : vial_diagnostic_array_t(0 to VIAL_DIAGNOSTIC_CAPACITY - 1);
    variable vial_scenario_failure_baseline : natural := 0;
    variable vial_scenario_unknown_baseline : natural := 0;
    variable vial_trace_sequence : natural := 0;
    variable vial_trace_open : boolean := false;
    variable vial_trace_closed : boolean := false;
    variable vial_result_consistent : boolean := false;
    variable vial_scenario_00_passed : boolean := false;
    variable vial_scenario_00_timed_out : boolean := false;
    variable vial_scenario_00_cycles : natural := 0;
    variable vial_scenario_00_accepts : natural := 0;
    variable vial_scenario_00_ready_low_cycles : natural := 0;
    variable vial_scenario_00_response_error_cycles : natural := 0;
    variable vial_scenario_00_nonzero_read_data_cycles : natural := 0;
    variable vial_scenario_00_final_ready : vial_observation_t;
    variable vial_scenario_00_final_response : vial_observation_t;
    variable vial_scenario_00_final_read_data : vial_observation_vector_t(0 to 31);
    variable vial_scenario_00_final_storage : vial_observation_vector_t(0 to 31);
    variable vial_scenario_01_passed : boolean := false;
    variable vial_scenario_01_timed_out : boolean := false;
    variable vial_scenario_01_cycles : natural := 0;
    variable vial_scenario_01_accepts : natural := 0;
    variable vial_scenario_01_ready_low_cycles : natural := 0;
    variable vial_scenario_01_response_error_cycles : natural := 0;
    variable vial_scenario_01_nonzero_read_data_cycles : natural := 0;
    variable vial_scenario_01_final_ready : vial_observation_t;
    variable vial_scenario_01_final_response : vial_observation_t;
    variable vial_scenario_01_final_read_data : vial_observation_vector_t(0 to 31);
    variable vial_scenario_01_final_storage : vial_observation_vector_t(0 to 31);
    variable vial_sample_haddr : vial_observation_vector_t(31 downto 0);
    variable vial_sample_hrdata : vial_observation_vector_t(31 downto 0);
    variable vial_sample_hready : vial_observation_vector_t(0 downto 0);
    variable vial_sample_hreadyout : vial_observation_vector_t(0 downto 0);
    variable vial_sample_hresp : vial_observation_vector_t(0 downto 0);
    variable vial_sample_hsel : vial_observation_vector_t(0 downto 0);
    variable vial_sample_hsize : vial_observation_vector_t(2 downto 0);
    variable vial_sample_htrans : vial_observation_vector_t(1 downto 0);
    variable vial_sample_hwdata : vial_observation_vector_t(31 downto 0);
    variable vial_sample_hwrite : vial_observation_vector_t(0 downto 0);
    variable vial_sample_clk : vial_observation_vector_t(0 downto 0);
    variable vial_sample_rst_n : vial_observation_vector_t(0 downto 0);
    variable vial_sample_wait_cycles : vial_observation_vector_t(3 downto 0);
    variable vial_sample_probe_reg_data_q : vial_observation_vector_t(31 downto 0);
    -- VIAL fiber state 00: fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/root
    variable vial_fiber_00_status : vial_fiber_status_t := VIAL_FIBER_DORMANT;
    -- VIAL fiber state 01: fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/complete/root
    variable vial_fiber_01_status : vial_fiber_status_t := VIAL_FIBER_DORMANT;
    -- VIAL fiber state 02: fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~13/stall/root
    variable vial_fiber_02_status : vial_fiber_status_t := VIAL_FIBER_DORMANT;
    -- VIAL fiber state 03: fiber/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size/root
    variable vial_fiber_03_status : vial_fiber_status_t := VIAL_FIBER_DORMANT;
    -- VIAL model state 00: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::accepts
    variable vial_model_00_count : natural := 0;
    -- VIAL model state 01: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::completions
    variable vial_model_01_count : natural := 0;
    variable vial_event_requested_count : natural := 0;
    variable vial_event_accepted_count : natural := 0;
    variable vial_event_captured_count : natural := 0;
    variable vial_event_held_count : natural := 0;
    variable vial_event_completed_count : natural := 0;
    variable vial_event_error_count : natural := 0;

    procedure vial_emit_trace(constant record_kind : in string) is
      variable trace_line : line;
    begin
      assert vial_trace_open and not vial_trace_closed
        report "FSMGen VIAL trace record outside the open trace interval"
        severity failure;
      write(trace_line, string'("FSMGEN_VIAL_TRACE_V1"));
      write(trace_line, HT);
      write(trace_line, string'("{""payload"":{""logical_time"":{""cycle"":"));
      write(trace_line, vial_time.cycle);
      write(trace_line, string'(",""local_index"":"));
      write(trace_line, vial_time.local_index);
      write(trace_line, string'(",""phase_rank"":"));
      write(trace_line, vial_phase_t'pos(vial_time.phase));
      write(trace_line, string'(",""static_rank"":"));
      write(trace_line, vial_time.static_rank);
      write(trace_line, string'("}},""plan_id"":"""));
      write(trace_line, VIAL_PLAN_ID);
      write(trace_line, string'(""",""record_kind"":"""));
      write(trace_line, record_kind);
      write(trace_line, string'(""",""run_id"":"));
      if record_kind = "header" or record_kind = "footer" then
        write(trace_line, string'("null"));
      else
        write(trace_line, string'("""run/"));
        write(trace_line, VIAL_PLAN_ID);
        write(trace_line, string'("/"));
        case vial_current_scenario is
          when 0 => write(trace_line, VIAL_SCENARIO_00_ID);
          when 1 => write(trace_line, VIAL_SCENARIO_01_ID);
          when others => write(trace_line, string'("unknown"));
        end case;
        write(trace_line, character'val(34));
      end if;
      write(trace_line, string'(",""schema"":"""));
      write(trace_line, VIAL_TRACE_SCHEMA);
      write(trace_line, string'(""",""schema_version"":1,""sequence"":"));
      write(trace_line, vial_trace_sequence);
      write(trace_line, string'("}"));
      writeline(output, trace_line);
      vial_trace_sequence := vial_trace_sequence + 1;
    end procedure vial_emit_trace;

    procedure vial_write_observation_bits(
      variable target : inout line;
      constant value : in vial_observation_vector_t
    ) is
      variable value_index : natural;
    begin
      for offset in 0 to value'length - 1 loop
        if value'ascending then
          value_index := value'left + offset;
        else
          value_index := value'left - offset;
        end if;
        case value(value_index).normalized_value is
          when VIAL_VALUE_0 => write(target, character'val(48));
          when VIAL_VALUE_1 => write(target, character'val(49));
          when VIAL_VALUE_X => write(target, character'val(88));
          when VIAL_VALUE_Z => write(target, character'val(90));
        end case;
      end loop;
    end procedure vial_write_observation_bits;

    procedure vial_write_observation_number(
      variable target : inout line;
      constant value : in vial_observation_t
    ) is
    begin
      if vial_is_known_zero(value) then
        write(target, character'val(48));
      elsif vial_is_known_one(value) then
        write(target, character'val(49));
      else
        write(target, string'("null"));
      end if;
    end procedure vial_write_observation_number;

    procedure vial_record_diagnostic(
      constant code : in string;
      constant outcome : in vial_check_outcome_t
    ) is
    begin
      assert vial_diagnostic_count < VIAL_DIAGNOSTIC_CAPACITY
        report "FSMGen VIAL diagnostic capacity overflow" severity failure;
      assert code'length <= vial_diagnostics(vial_diagnostic_count).code'length
        report "FSMGen VIAL diagnostic code exceeds its portable bound" severity failure;
      vial_diagnostics(vial_diagnostic_count).code := (others => ' ');
      vial_diagnostics(vial_diagnostic_count).code(1 to code'length) := code;
      vial_diagnostics(vial_diagnostic_count).code_length := code'length;
      if outcome = VIAL_CHECK_PASSED then
        vial_diagnostics(vial_diagnostic_count).severity_name := "info    ";
      else
        vial_diagnostics(vial_diagnostic_count).severity_name := "error   ";
      end if;
      vial_diagnostics(vial_diagnostic_count).logical_time := vial_time;
      vial_diagnostics(vial_diagnostic_count).outcome := outcome;
      vial_diagnostic_count := vial_diagnostic_count + 1;
      if outcome = VIAL_CHECK_UNKNOWN then
        vial_unknown_evidence := vial_unknown_evidence + 1;
      elsif outcome = VIAL_CHECK_FAILED then
        vial_check_failures := vial_check_failures + 1;
      else
        vial_check_passes := vial_check_passes + 1;
      end if;
      vial_emit_trace("expectations");
    end procedure vial_record_diagnostic;

    procedure vial_scoreboard_enqueue_expected is
    begin
      if vial_scoreboard.expected_depth = VIAL_SCOREBOARD_CAPACITY then
        vial_scoreboard.overflowed := true;
        vial_scoreboard_overflowed_any := true;
        vial_record_diagnostic("VIAL_SCOREBOARD_OVERFLOW", VIAL_CHECK_FAILED);
      else
        vial_scoreboard.expected_depth := vial_scoreboard.expected_depth + 1;
        vial_emit_trace("scoreboards");
      end if;
    end procedure vial_scoreboard_enqueue_expected;

    procedure vial_scoreboard_compare(constant matches : in boolean) is
    begin
      assert vial_scoreboard.expected_depth > 0
        report "FSMGen VIAL scoreboard actual without expected item" severity failure;
      vial_scoreboard.actual_depth := vial_scoreboard.actual_depth + 1;
      vial_scoreboard.comparisons := vial_scoreboard.comparisons + 1;
      vial_scoreboard_comparisons_total := vial_scoreboard_comparisons_total + 1;
      if not matches then
        vial_scoreboard.mismatches := vial_scoreboard.mismatches + 1;
        vial_scoreboard_mismatches_total := vial_scoreboard_mismatches_total + 1;
        vial_record_diagnostic("VIAL_SCOREBOARD_MISMATCH", VIAL_CHECK_FAILED);
      end if;
      vial_scoreboard.expected_depth := vial_scoreboard.expected_depth - 1;
      vial_scoreboard.actual_depth := vial_scoreboard.actual_depth - 1;
      vial_emit_trace("scoreboards");
    end procedure vial_scoreboard_compare;

    procedure vial_close_trace_and_project_result is
      variable result_line : line;
      procedure vial_write_status(
        variable target : inout line;
        constant passed : in boolean;
        constant timed_out : in boolean
      ) is
      begin
        if timed_out then
          write(target, string'("timeout"));
        elsif passed then
          write(target, string'("pass"));
        else
          write(target, string'("fail"));
        end if;
      end procedure vial_write_status;
    begin
      assert vial_trace_open and not vial_trace_closed
        report "FSMGen VIAL trace did not close exactly once" severity failure;
      vial_emit_trace("footer");
      vial_trace_closed := true;
      vial_result_consistent := vial_check_failures = 0
        and vial_unknown_evidence = 0
        and not vial_scoreboard_overflowed_any
        and vial_scoreboard_mismatches_total = 0
        and vial_scoreboard.expected_depth = 0
        and vial_scoreboard.actual_depth = 0
        and vial_scenario_00_passed and vial_scenario_01_passed;
      write(result_line, string'("FSMGEN_VIAL_RESULT_V1"));
      write(result_line, HT);
      write(result_line, string'("{""backend_evidence"":{""analysis_status"":""not_run"",""elaboration_status"":""not_run"",""runtime_status"":""projection_only""},""backend_profile"":{""capabilities"":[""vial.backend.vhdl_portable_ghdl.v1"",""vial.backend.vhdl_portable_ghdl.result_manifest_projection.v1""],""id"":""vhdl_portable_ghdl"",""methodology"":""plain_vhdl_no_provider"",""target_language"":""VHDL"",""tool_name"":null,""tool_version"":null,""uvm_revision"":null,""vhdl_standard"":""IEEE 1076-2008""},""capability_evidence"":{""native_only"":[],""required"":[],""satisfied"":[""portable_checking_projection""],""unsatisfied"":[]},""coverage"":[{""bins"":{""not_stalled"":"));
      write(result_line, vial_coverage.not_stalled);
      write(result_line, string'(",""stalled"":"));
      write(result_line, vial_coverage.stalled);
      write(result_line, string'("},""coverpoint_id"":""coverpoint/stall_seen""}],""diagnostics"":["));
      if vial_diagnostic_count > 0 then
        for diagnostic_index in 0 to vial_diagnostic_count - 1 loop
          if diagnostic_index > 0 then
            write(result_line, string'(","));
          end if;
          write(result_line, string'("{""code"":"""));
          write(result_line, vial_diagnostics(diagnostic_index).code(
            1 to vial_diagnostics(diagnostic_index).code_length));
          write(result_line, string'(""",""logical_time"":{""cycle"":"));
          write(result_line, vial_diagnostics(diagnostic_index).logical_time.cycle);
          write(result_line, string'(",""local_index"":"));
          write(result_line, vial_diagnostics(diagnostic_index).logical_time.local_index);
          write(result_line, string'(",""phase_rank"":"));
          write(result_line, vial_phase_t'pos(
            vial_diagnostics(diagnostic_index).logical_time.phase));
          write(result_line, string'(",""static_rank"":"));
          write(result_line, vial_diagnostics(diagnostic_index).logical_time.static_rank);
          write(result_line, string'("},""outcome"":"""));
          if vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_PASSED then
            write(result_line, string'("pass"));
          elsif vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_UNKNOWN then
            write(result_line, string'("unknown"));
          else
            write(result_line, string'("fail"));
          end if;
          write(result_line, string'(""",""severity"":"""));
          if vial_diagnostics(diagnostic_index).outcome = VIAL_CHECK_PASSED then
            write(result_line, string'("info"));
          else
            write(result_line, string'("error"));
          end if;
          write(result_line, string'("""}"));
        end loop;
      end if;
      write(result_line, string'("],""drives"":[],""events"":[],""exclusions"":[],""execution_profile"":"""));
      write(result_line, VIAL_EXECUTION_PROFILE);
      write(result_line, string'(""",""expectations"":[],""faults"":[{""applications"":"));
      write(result_line, vial_fault_applications_total);
      write(result_line, string'(",""fault_id"":""fault/unsupported_size"",""kind"":""substitution""}],""fibers"":[],""fixture_id"":"""));
      write(result_line, VIAL_FIXTURE_ID);
      write(result_line, string'(""",""metrics"":{""coverage_not_stalled"":"));
      write(result_line, vial_coverage.not_stalled);
      write(result_line, string'(",""coverage_stalled"":"));
      write(result_line, vial_coverage.stalled);
      write(result_line, string'(",""diagnostic_records"":"));
      write(result_line, vial_diagnostic_count);
      write(result_line, string'(",""fault_applications"":"));
      write(result_line, vial_fault_applications_total);
      write(result_line, string'(",""scoreboard_comparisons"":"));
      write(result_line, vial_scoreboard_comparisons_total);
      write(result_line, string'(",""scoreboard_mismatches"":"));
      write(result_line, vial_scoreboard_mismatches_total);
      write(result_line, string'("},""models"":[],""native_extensions"":[],""parity_digest"":null,""parity_projection"":{""outcomes"":["));
      write(result_line, string'("{""bus_accepts"":"));
      write(result_line, vial_scenario_00_accepts);
      write(result_line, string'(",""final_read_data_bits"":"""));
      vial_write_observation_bits(result_line, vial_scenario_00_final_read_data);
      write(result_line, string'(""",""final_ready"":"));
      vial_write_observation_number(result_line, vial_scenario_00_final_ready);
      write(result_line, string'(",""final_response"":"));
      vial_write_observation_number(result_line, vial_scenario_00_final_response);
      write(result_line, string'(",""nonzero_read_data_cycles"":"));
      write(result_line, vial_scenario_00_nonzero_read_data_cycles);
      write(result_line, string'(",""ready_low_cycles"":"));
      write(result_line, vial_scenario_00_ready_low_cycles);
      write(result_line, string'(",""response_error_cycles"":"));
      write(result_line, vial_scenario_00_response_error_cycles);
      write(result_line, string'(",""scenario_id"":"""));
      write(result_line, VIAL_SCENARIO_00_ID);
      write(result_line, string'(""",""status"":"""));
      vial_write_status(result_line, vial_scenario_00_passed,
        vial_scenario_00_timed_out);
      write(result_line, string'(""",""storage_bits"":"""));
      vial_write_observation_bits(result_line, vial_scenario_00_final_storage);
      write(result_line, string'("""}"));
      write(result_line, string'(","));
      write(result_line, string'("{""bus_accepts"":"));
      write(result_line, vial_scenario_01_accepts);
      write(result_line, string'(",""final_read_data_bits"":"""));
      vial_write_observation_bits(result_line, vial_scenario_01_final_read_data);
      write(result_line, string'(""",""final_ready"":"));
      vial_write_observation_number(result_line, vial_scenario_01_final_ready);
      write(result_line, string'(",""final_response"":"));
      vial_write_observation_number(result_line, vial_scenario_01_final_response);
      write(result_line, string'(",""nonzero_read_data_cycles"":"));
      write(result_line, vial_scenario_01_nonzero_read_data_cycles);
      write(result_line, string'(",""ready_low_cycles"":"));
      write(result_line, vial_scenario_01_ready_low_cycles);
      write(result_line, string'(",""response_error_cycles"":"));
      write(result_line, vial_scenario_01_response_error_cycles);
      write(result_line, string'(",""scenario_id"":"""));
      write(result_line, VIAL_SCENARIO_01_ID);
      write(result_line, string'(""",""status"":"""));
      vial_write_status(result_line, vial_scenario_01_passed,
        vial_scenario_01_timed_out);
      write(result_line, string'(""",""storage_bits"":"""));
      vial_write_observation_bits(result_line, vial_scenario_01_final_storage);
      write(result_line, string'("""}"));
      write(result_line, string'("],""schema"":""fsmgen.vial_vhdl_portable_outcomes.v1"",""schema_version"":1},""plan_id"":"""));
      write(result_line, VIAL_PLAN_ID);
      write(result_line, string'(""",""portable_parity_eligible"":false,""random_decisions"":[{""algorithm"":""sha256_counter_rejection_v1"",""attempt"":0,""decision_id"":""success.wait_cycles"",""declaration_semantic_id"":""ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::choice::success_wait"",""distribution"":{""high"":{""kind"":""scalar"",""known_hex"":""f"",""signed"":0,""state_domain"":""two_state"",""type_id"":""execution-type/0bc61ad085c7a24e898dfd8612321a4ef7fa1cad5a908b6efd8903333044e1ee"",""value_hex"":""2"",""width"":4,""z_hex"":""0""},""kind"":""uniform"",""low"":{""kind"":""scalar"",""known_hex"":""f"",""signed"":0,""state_domain"":""two_state"",""type_id"":""execution-type/0bc61ad085c7a24e898dfd8612321a4ef7fa1cad5a908b6efd8903333044e1ee"",""value_hex"":""1"",""width"":4,""z_hex"":""0""}},""occurrence_id"":""decision/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/success.wait_cycles/0"",""origin"":""generated"",""reference_operation_ids"":[""operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~11/root"",""operation/ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success/~1packages~10~1fixtures~10~1scenarios~10~1actions~12/root""],""scenario_id"":""ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success"",""seed"":1,""source_location"":{""end_byte_exclusive"":2302,""end_column"":55,""end_line"":64,""source_name"":""vial/ahb_subordinate_base_output_arbitration.vial"",""start_byte"":2131,""start_column"":11,""start_line"":61},""type_id"":""execution-type/0bc61ad085c7a24e898dfd8612321a4ef7fa1cad5a908b6efd8903333044e1ee"",""value"":{""kind"":""scalar"",""known_hex"":""f"",""signed"":0,""state_domain"":""two_state"",""type_id"":""execution-type/0bc61ad085c7a24e898dfd8612321a4ef7fa1cad5a908b6efd8903333044e1ee"",""value_hex"":""2"",""width"":4,""z_hex"":""0""}}],""result_id"":null,""scenario_results"":["));
      write(result_line, string'("{""cancelled_fiber_ids"":[],""completion_reason"":"""));
      if vial_scenario_00_timed_out then
        write(result_line, string'("timeout"));
      elsif vial_scenario_00_passed then
        write(result_line, string'("completed"));
      else
        write(result_line, string'("expectation_failed"));
      end if;
      write(result_line, string'(""",""diagnostic_ids"":[],""end_time"":{""cycle"":"));
      write(result_line, vial_scenario_00_cycles);
      write(result_line, string'(",""domain_id"":"""));
      write(result_line, VIAL_DOMAIN_ID);
      write(result_line, string'(""",""ordinal"":0,""phase"":""check""},""expectation_ids"":[],""logical_cycle_count"":"));
      write(result_line, vial_scenario_00_cycles);
      write(result_line, string'(",""run_id"":""run/"));
      write(result_line, VIAL_PLAN_ID);
      write(result_line, string'("/"));
      write(result_line, VIAL_SCENARIO_00_ID);
      write(result_line, string'(""",""scenario_id"":"""));
      write(result_line, VIAL_SCENARIO_00_ID);
      write(result_line, string'(""",""start_time"":{""cycle"":0,""domain_id"":"""));
      write(result_line, VIAL_DOMAIN_ID);
      write(result_line, string'(""",""ordinal"":0,""phase"":""drive""},""status"":"""));
      vial_write_status(result_line, vial_scenario_00_passed,
        vial_scenario_00_timed_out);
      write(result_line, string'("""}"));
      write(result_line, string'(","));
      write(result_line, string'("{""cancelled_fiber_ids"":[],""completion_reason"":"""));
      if vial_scenario_01_timed_out then
        write(result_line, string'("timeout"));
      elsif vial_scenario_01_passed then
        write(result_line, string'("completed"));
      else
        write(result_line, string'("expectation_failed"));
      end if;
      write(result_line, string'(""",""diagnostic_ids"":[],""end_time"":{""cycle"":"));
      write(result_line, vial_scenario_01_cycles);
      write(result_line, string'(",""domain_id"":"""));
      write(result_line, VIAL_DOMAIN_ID);
      write(result_line, string'(""",""ordinal"":0,""phase"":""check""},""expectation_ids"":[],""logical_cycle_count"":"));
      write(result_line, vial_scenario_01_cycles);
      write(result_line, string'(",""run_id"":""run/"));
      write(result_line, VIAL_PLAN_ID);
      write(result_line, string'("/"));
      write(result_line, VIAL_SCENARIO_01_ID);
      write(result_line, string'(""",""scenario_id"":"""));
      write(result_line, VIAL_SCENARIO_01_ID);
      write(result_line, string'(""",""start_time"":{""cycle"":0,""domain_id"":"""));
      write(result_line, VIAL_DOMAIN_ID);
      write(result_line, string'(""",""ordinal"":0,""phase"":""drive""},""status"":"""));
      vial_write_status(result_line, vial_scenario_01_passed,
        vial_scenario_01_timed_out);
      write(result_line, string'("""}"));
      write(result_line, string'("],""schema"":"""));
      write(result_line, VIAL_RESULT_SCHEMA);
      write(result_line, string'(""",""schema_version"":1,""scoreboards"":[{""capacity"":4,""comparisons"":"));
      write(result_line, vial_scoreboard_comparisons_total);
      write(result_line, string'(",""mismatches"":"));
      write(result_line, vial_scoreboard_mismatches_total);
      write(result_line, string'("}],""status"":"""));
      vial_write_status(result_line, vial_result_consistent, vial_scenario_00_timed_out or vial_scenario_01_timed_out);
      write(result_line, string'(""",""transactions"":[]}"));
      writeline(output, result_line);
    end procedure vial_close_trace_and_project_result;

    procedure vial_inactive_barrier is
      variable vial_accept_now : boolean := false;
      variable vial_complete_now : boolean := false;
    begin
      wait until falling_edge(clk);
      vial_time.cycle := vial_time.cycle + 1;
      vial_time.phase := VIAL_SAMPLE_PHASE;
      -- FSMGEN VIAL PHASE: SAMPLE
      vial_sample_haddr := observe_vial_vector(HADDR);
      vial_sample_hrdata := observe_vial_vector(HRDATA);
      vial_sample_hready := observe_vial_vector(std_logic_vector'(0 => HREADY));
      vial_sample_hreadyout := observe_vial_vector(std_logic_vector'(0 => HREADYOUT));
      vial_sample_hresp := observe_vial_vector(std_logic_vector'(0 => HRESP));
      vial_sample_hsel := observe_vial_vector(std_logic_vector'(0 => HSEL));
      vial_sample_hsize := observe_vial_vector(HSIZE);
      vial_sample_htrans := observe_vial_vector(HTRANS);
      vial_sample_hwdata := observe_vial_vector(HWDATA);
      vial_sample_hwrite := observe_vial_vector(std_logic_vector'(0 => HWRITE));
      vial_sample_clk := observe_vial_vector(std_logic_vector'(0 => clk));
      vial_sample_rst_n := observe_vial_vector(std_logic_vector'(0 => rst_n));
      vial_sample_wait_cycles := observe_vial_vector(wait_cycles);
      vial_sample_probe_reg_data_q := observe_vial_vector(vial_probe_reg_data_q);

      vial_time.phase := VIAL_REACT_PHASE;
      -- FSMGEN VIAL PHASE: REACT
      vial_accept_now := vial_transaction_active
        and not vial_transaction_accepted
        and vial_is_known_one(vial_sample_hsel(0))
        and vial_is_known_one(vial_sample_hready(0))
        and vial_matches(vial_sample_htrans,
          to_vial_value_vector(std_logic_vector'("10")));
      vial_complete_now := vial_transaction_active
        and vial_is_known_one(vial_sample_hreadyout(0))
        and (vial_transaction_accepted or vial_accept_now);
      if vial_accept_now then
        vial_event_accepted_count := vial_event_accepted_count + 1;
        vial_event_captured_count := vial_event_captured_count + 1;
        vial_transaction_accepted := true;
      end if;
      if vial_transaction_active and vial_is_known_zero(vial_sample_hreadyout(0)) then
        vial_event_held_count := vial_event_held_count + 1;
        vial_coverage.stalled := vial_coverage.stalled + 1;
        vial_emit_trace("coverage");
      elsif vial_transaction_active and vial_is_known_one(vial_sample_hreadyout(0)) then
        vial_coverage.not_stalled := vial_coverage.not_stalled + 1;
        vial_emit_trace("coverage");
      end if;
      if vial_transaction_active and vial_is_known_one(vial_sample_hresp(0)) then
        vial_event_error_count := vial_event_error_count + 1;
      end if;
      if vial_transaction_active and not vial_matches(vial_sample_hrdata, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000"))) then
        vial_nonzero_read_data_count := vial_nonzero_read_data_count + 1;
      end if;
      if vial_complete_now then
        vial_event_completed_count := vial_event_completed_count + 1;
        vial_emit_trace("events");
        if vial_scoreboard.expected_depth > 0 then
          vial_scoreboard_compare(vial_is_known_zero(vial_sample_hresp(0)));
        end if;
      end if;
      -- VIAL model update 00: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::accepts
      if vial_accept_now then
        vial_model_00_count := vial_model_00_count + 1;
      end if;
      -- VIAL model update 01: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::completions
      if vial_complete_now then
        vial_model_01_count := vial_model_01_count + 1;
      end if;
      if vial_scenario_started then
        case vial_current_scenario is
          when 0 =>
            vial_current_operation_rank := 4;
            if vial_event_completed_count > 0 then
              vial_fiber_01_status := VIAL_FIBER_COMPLETED;
            end if;
            vial_current_operation_rank := 5;
            if vial_matches(vial_sample_hreadyout, to_vial_value_vector(std_logic_vector'("0"))) then
              vial_fiber_02_status := VIAL_FIBER_COMPLETED;
            end if;
            vial_current_operation_rank := 3;
            if vial_fiber_01_status = VIAL_FIBER_COMPLETED and vial_fiber_02_status = VIAL_FIBER_COMPLETED then
              vial_fiber_00_status := VIAL_FIBER_COMPLETED;
              if vial_is_known_zero(vial_sample_hresp(0)) then
                vial_scenario_done := true;
              end if;
            end if;
          when 1 =>
            vial_current_operation_rank := 3;
            if vial_event_completed_count > 0 then
              vial_fiber_03_status := VIAL_FIBER_COMPLETED;
            end if;
            if vial_fiber_03_status = VIAL_FIBER_COMPLETED then
              if vial_is_known_zero(vial_sample_hresp(0)) then
                vial_scenario_done := true;
              end if;
            end if;
          when others =>
            vial_scenario_done := true;
        end case;
      end if;
      if vial_scenario_started and vial_time.cycle >= vial_scenario_timeout then
        vial_scenario_status := VIAL_SCENARIO_TIMED_OUT;
        vial_scenario_done := true;
      end if;

      vial_time.phase := VIAL_CHECK_PHASE;
      -- FSMGEN VIAL PHASE: CHECK
      if not vial_is_known(vial_sample_hreadyout(0))
          or not vial_is_known(vial_sample_hresp(0)) then
        vial_record_diagnostic("VIAL_UNKNOWN_SAMPLE", VIAL_CHECK_UNKNOWN);
      end if;
      if vial_scenario_done then
        if vial_scenario_status = VIAL_SCENARIO_TIMED_OUT then
          vial_record_diagnostic("VIAL_SCENARIO_TIMEOUT", VIAL_CHECK_FAILED);
        elsif vial_current_scenario = 0 then
          if vial_event_accepted_count = 1
              and vial_event_completed_count = 1
              and vial_is_known_zero(vial_sample_hresp(0))
              and vial_matches(vial_sample_hrdata, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")))
              and vial_matches(vial_sample_probe_reg_data_q, to_vial_value_vector(std_logic_vector'("11001010111111101011101010111110")))
              and vial_nonzero_read_data_count = 0
              and vial_event_held_count > 0
              and vial_event_error_count = 0
          then
            vial_record_diagnostic("VIAL_EXPECT_SUCCESS", VIAL_CHECK_PASSED);
          else
            vial_record_diagnostic("VIAL_EXPECT_SUCCESS", VIAL_CHECK_FAILED);
          end if;
        elsif vial_current_scenario = 1 then
          if vial_event_accepted_count = 1
              and vial_event_completed_count = 1
              and vial_is_known_zero(vial_sample_hresp(0))
              and vial_matches(vial_sample_hrdata, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")))
              and vial_matches(vial_sample_probe_reg_data_q, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")))
              and vial_nonzero_read_data_count = 0
              and vial_event_error_count = 2
          then
            vial_record_diagnostic("VIAL_EXPECT_ERROR", VIAL_CHECK_PASSED);
          else
            vial_record_diagnostic("VIAL_EXPECT_ERROR", VIAL_CHECK_FAILED);
          end if;
        else
          vial_record_diagnostic("VIAL_SCENARIO_UNKNOWN", VIAL_CHECK_FAILED);
        end if;
      end if;

      vial_time.phase := VIAL_DRIVE_PHASE;
      -- FSMGEN VIAL PHASE: DRIVE
      if vial_complete_now then
        drive_vial_value(HSEL, VIAL_VALUE_0);
        drive_vial_vector(HTRANS,
          to_vial_value_vector(std_logic_vector'("00")));
        vial_transaction_active := false;
      end if;
      vial_time.static_rank := vial_current_operation_rank;
      vial_time.local_index := 0;
    end procedure vial_inactive_barrier;

  begin
    vial_runtime_state := VIAL_RUNTIME_READY;
    vial_time := VIAL_INITIAL_LOGICAL_TIME;
    vial_runtime_state := VIAL_RUNTIME_RUNNING;
    vial_trace_open := true;
    vial_emit_trace("header");
    for scenario_index in 0 to 1 loop
      vial_current_scenario := scenario_index;
      vial_scenario_status := VIAL_SCENARIO_RUNNING;
      vial_scenario_started := false;
      vial_scenario_done := false;
      vial_transaction_active := false;
      vial_transaction_accepted := false;
      vial_scoreboard := (0, 0, 0, 0, false);
      vial_fault := (false, 0, 0);
      vial_scenario_failure_baseline := vial_check_failures;
      vial_scenario_unknown_baseline := vial_unknown_evidence;
      vial_nonzero_read_data_count := 0;
      vial_time.cycle := 0;
      vial_current_operation_rank := 0;
      vial_fiber_00_status := VIAL_FIBER_DORMANT;
      vial_fiber_01_status := VIAL_FIBER_DORMANT;
      vial_fiber_02_status := VIAL_FIBER_DORMANT;
      vial_fiber_03_status := VIAL_FIBER_DORMANT;
      vial_model_00_count := 0;
      vial_model_01_count := 0;
      vial_event_requested_count := 0;
      vial_event_accepted_count := 0;
      vial_event_captured_count := 0;
      vial_event_held_count := 0;
      vial_event_completed_count := 0;
      vial_event_error_count := 0;
      vial_emit_trace("scenario_start");
      case scenario_index is
        when 0 =>
          -- VIAL scenario 0: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::success
          vial_scenario_timeout := 256;
          vial_current_operation_rank := 0;
          drive_vial_value(rst_n, VIAL_VALUE_0);
          for reset_index in 1 to 3 loop
            vial_inactive_barrier;
          end loop;
          drive_vial_value(rst_n, VIAL_VALUE_1);
          vial_current_operation_rank := 1;
          vial_scoreboard_enqueue_expected;
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::address
          drive_vial_vector(HADDR, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::transfer
          drive_vial_vector(HTRANS, to_vial_value_vector(std_logic_vector'("10")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::write
          drive_vial_value(HWRITE, VIAL_VALUE_1);
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::size
          drive_vial_vector(HSIZE, to_vial_value_vector(std_logic_vector'("010")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::data
          drive_vial_vector(HWDATA, to_vial_value_vector(std_logic_vector'("11001010111111101011101010111110")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::wait_cycles
          drive_vial_vector(wait_cycles, to_vial_value_vector(std_logic_vector'("0010")));
          drive_vial_value(HSEL, VIAL_VALUE_1);
          vial_current_operation_rank := 2;
          vial_transaction_active := true;
          vial_transaction_accepted := false;
          vial_event_requested_count := vial_event_requested_count + 1;
          vial_fiber_00_status := VIAL_FIBER_RUNNING;
          vial_fiber_01_status := VIAL_FIBER_RUNNING;
          vial_fiber_02_status := VIAL_FIBER_RUNNING;
          vial_scenario_started := true;
          while not vial_scenario_done loop
            vial_inactive_barrier;
          end loop;
          if vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT then
            vial_scenario_status := VIAL_SCENARIO_STIMULUS_COMPLETED;
          end if;
          vial_scenario_00_timed_out := vial_scenario_status = VIAL_SCENARIO_TIMED_OUT;
          vial_scenario_00_cycles := vial_time.cycle;
          vial_scenario_00_accepts := vial_event_accepted_count;
          vial_scenario_00_ready_low_cycles := vial_event_held_count;
          vial_scenario_00_response_error_cycles := vial_event_error_count;
          vial_scenario_00_nonzero_read_data_cycles := vial_nonzero_read_data_count;
          vial_scenario_00_final_ready := vial_sample_hreadyout(0);
          vial_scenario_00_final_response := vial_sample_hresp(0);
          vial_scenario_00_final_read_data := vial_sample_hrdata;
          vial_scenario_00_final_storage := vial_sample_probe_reg_data_q;
          vial_scenario_00_passed := vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT
            and vial_check_failures = vial_scenario_failure_baseline
            and vial_unknown_evidence = vial_scenario_unknown_baseline
            and not vial_scoreboard.overflowed
            and vial_scoreboard.expected_depth = 0
            and vial_scoreboard.actual_depth = 0;
          vial_emit_trace("scenario_end");
        when 1 =>
          -- VIAL scenario 1: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size
          vial_scenario_timeout := 256;
          vial_current_operation_rank := 0;
          drive_vial_value(rst_n, VIAL_VALUE_0);
          for reset_index in 1 to 3 loop
            vial_inactive_barrier;
          end loop;
          drive_vial_value(rst_n, VIAL_VALUE_1);
          vial_current_operation_rank := 1;
          vial_fault.armed := true;
          vial_fault.remaining_cycles := 1;
          vial_emit_trace("faults");
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::address
          drive_vial_vector(HADDR, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::transfer
          drive_vial_vector(HTRANS, to_vial_value_vector(std_logic_vector'("10")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::write
          drive_vial_value(HWRITE, VIAL_VALUE_1);
          -- VIAL substitution fault preserves the immutable authored field
          vial_fault.applications := vial_fault.applications + 1;
          vial_fault_applications_total := vial_fault_applications_total + 1;
          vial_fault.remaining_cycles := 0;
          vial_fault.armed := false;
          vial_emit_trace("faults");
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::size
          drive_vial_vector(HSIZE, to_vial_value_vector(std_logic_vector'("111")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::data
          drive_vial_vector(HWDATA, to_vial_value_vector(std_logic_vector'("11111111111111111111111111111111")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::wait_cycles
          drive_vial_vector(wait_cycles, to_vial_value_vector(std_logic_vector'("0001")));
          drive_vial_value(HSEL, VIAL_VALUE_1);
          vial_current_operation_rank := 2;
          vial_transaction_active := true;
          vial_transaction_accepted := false;
          vial_event_requested_count := vial_event_requested_count + 1;
          vial_fiber_03_status := VIAL_FIBER_RUNNING;
          vial_scenario_started := true;
          while not vial_scenario_done loop
            vial_inactive_barrier;
          end loop;
          if vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT then
            vial_scenario_status := VIAL_SCENARIO_STIMULUS_COMPLETED;
          end if;
          vial_scenario_01_timed_out := vial_scenario_status = VIAL_SCENARIO_TIMED_OUT;
          vial_scenario_01_cycles := vial_time.cycle;
          vial_scenario_01_accepts := vial_event_accepted_count;
          vial_scenario_01_ready_low_cycles := vial_event_held_count;
          vial_scenario_01_response_error_cycles := vial_event_error_count;
          vial_scenario_01_nonzero_read_data_cycles := vial_nonzero_read_data_count;
          vial_scenario_01_final_ready := vial_sample_hreadyout(0);
          vial_scenario_01_final_response := vial_sample_hresp(0);
          vial_scenario_01_final_read_data := vial_sample_hrdata;
          vial_scenario_01_final_storage := vial_sample_probe_reg_data_q;
          vial_scenario_01_passed := vial_scenario_status /= VIAL_SCENARIO_TIMED_OUT
            and vial_check_failures = vial_scenario_failure_baseline
            and vial_unknown_evidence = vial_scenario_unknown_baseline
            and not vial_scoreboard.overflowed
            and vial_scoreboard.expected_depth = 0
            and vial_scoreboard.actual_depth = 0;
          vial_emit_trace("scenario_end");
        when others =>
          null;
      end case;
    end loop;
    vial_runtime_state := VIAL_RUNTIME_COMPLETED;
    vial_close_trace_and_project_result;
    assert vial_trace_closed and vial_result_consistent
      report "FSMGen VIAL trace/result closure inconsistency" severity failure;
    vial_runtime_state := VIAL_RUNTIME_FINALIZED;
    finish;
  end process vial_scheduler;
end architecture portable_semantics;
