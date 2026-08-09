library ieee;
use ieee.std_logic_1164.all;

library osvvm;
context osvvm.OsvvmContext;

library osvvm_common;

entity fsmgen_vial_osvvm_runtime_probe is
end entity;

architecture probe of fsmgen_vial_osvvm_runtime_probe is
  signal phase_barrier : work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_vial_osvvm_barrier_t := 1;
begin
  exercise_provider : process
    variable random_generator : osvvm.RandomPkg.RandomPType;
    variable random_value : integer;
    variable coverage_id : work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_vial_osvvm_coverage_id_t;
    variable scoreboard_id : work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_vial_osvvm_scoreboard_id_t;
    variable memory_id : work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_vial_osvvm_memory_id_t;
    variable memory_value : std_logic_vector(7 downto 0);
  begin
    random_generator.InitSeed("fsmgen-vial-osvvm-2026.05");
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_native_random(
      random_generator, 0, 3, random_value);
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_affirm(
      random_value >= 0 and random_value <= 3,
      "adapter random value stays within the selected range");

    coverage_id := osvvm.CoveragePkg.NewID("fsmgen_adapter_coverage");
    osvvm.CoveragePkg.AddBins(coverage_id, osvvm.CoveragePkg.GenBin(0, 3));
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_coverage_sample(
      coverage_id, random_value);

    scoreboard_id := osvvm.ScoreboardPkg_slv.NewID("fsmgen_adapter_scoreboard");
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_scoreboard_expect(
      scoreboard_id, x"A5");
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_scoreboard_check(
      scoreboard_id, x"A5");

    memory_id := work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_new_memory(
      "fsmgen_adapter_memory", 4, 8);
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_memory_write(
      memory_id, x"3", x"5A");
    osvvm.MemoryPkg.MemRead(memory_id, x"3", memory_value);
    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_affirm(
      memory_value = x"5A", "adapter memory round trip matches");

    work.fsmgen_vial_osvvm_adapter_pkg.fsmgen_osvvm_wait_for_barrier(phase_barrier);
    report "FSMGEN_VIAL_OSVVM_PROVIDER_PROBE_V1 pass random=" & integer'image(random_value)
      severity note;
    osvvm.ReportPkg.EndOfTestReports;
    std.env.stop;
    wait;
  end process;
end architecture;
