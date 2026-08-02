library ieee;
use ieee.std_logic_1164.all;

use work.fsmgen_vial_types_pkg.all;
use work.fsmgen_vial_runtime_pkg.all;

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
        and vial_is_known_one(vial_sample_hsel(0))
        and vial_is_known_one(vial_sample_hready(0))
        and vial_matches(vial_sample_htrans,
          to_vial_value_vector(std_logic_vector'("10")));
      vial_complete_now := vial_transaction_active
        and vial_is_known_one(vial_sample_hreadyout(0))
        and (vial_transaction_accepted or vial_accept_now);
      if vial_accept_now and not vial_transaction_accepted then
        vial_event_accepted_count := vial_event_accepted_count + 1;
        vial_event_captured_count := vial_event_captured_count + 1;
        vial_transaction_accepted := true;
      end if;
      if vial_transaction_active and vial_is_known_zero(vial_sample_hreadyout(0)) then
        vial_event_held_count := vial_event_held_count + 1;
      end if;
      if vial_transaction_active and vial_is_known_one(vial_sample_hresp(0)) then
        vial_event_error_count := vial_event_error_count + 1;
      end if;
      if vial_complete_now then
        vial_event_completed_count := vial_event_completed_count + 1;
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
              vial_scenario_done := true;
            end if;
          when 1 =>
            vial_current_operation_rank := 3;
            if vial_event_completed_count > 0 then
              vial_fiber_03_status := VIAL_FIBER_COMPLETED;
            end if;
            if vial_fiber_03_status = VIAL_FIBER_COMPLETED then
              vial_scenario_done := true;
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
      -- FSMGEN VIAL PHASE: CHECK (checking and results are emitted by slice .15.3)

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
    for scenario_index in 0 to 1 loop
      vial_current_scenario := scenario_index;
      vial_scenario_status := VIAL_SCENARIO_RUNNING;
      vial_scenario_started := false;
      vial_scenario_done := false;
      vial_transaction_active := false;
      vial_transaction_accepted := false;
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
        when 1 =>
          -- VIAL scenario 1: ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::scenario::unsupported_size
          vial_scenario_timeout := 256;
          vial_current_operation_rank := 0;
          drive_vial_value(rst_n, VIAL_VALUE_0);
          for reset_index in 1 to 3 loop
            vial_inactive_barrier;
          end loop;
          drive_vial_value(rst_n, VIAL_VALUE_1);
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::address
          drive_vial_vector(HADDR, to_vial_value_vector(std_logic_vector'("00000000000000000000000000000000")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::transfer
          drive_vial_vector(HTRANS, to_vial_value_vector(std_logic_vector'("10")));
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::write
          drive_vial_value(HWRITE, VIAL_VALUE_1);
          -- VIAL drive ahb_subordinate_base_output_arbitration::transaction::ahb_write::field::size
          drive_vial_vector(HSIZE, to_vial_value_vector(std_logic_vector'("010")));
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
        when others =>
          null;
      end case;
    end loop;
    vial_runtime_state := VIAL_RUNTIME_COMPLETED;
    vial_runtime_state := VIAL_RUNTIME_FINALIZED;
    wait;
  end process vial_scheduler;
end architecture portable_semantics;
