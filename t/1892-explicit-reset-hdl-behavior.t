#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Test::ProcessSupervisor qw(supervise_process);

my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my @cases = (
    ['sync_high', 'sreset', 'active_high', 'rst_high'],
    ['sync_low', 'sreset', 'active_low', 'rst_low'],
    ['async_high', 'areset', 'active_high', 'rst_high'],
    ['async_low', 'areset', 'active_low', 'rst_low'],
);
for my $c (@cases) {
    write_file("$work/$c->[0].fsm", "(?fsm:$c->[0]\n"
        ."  (+system (clock clk) ($c->[1] reset_pin $c->[2]))\n"
        ."  (+size (Q 4 (reset 3)) (DATA 4))\n"
        ."  (idle (<- (Q> DATA))))\n");
}

for my $language (qw(systemverilog verilog vhdl)) {
    subtest "$language independently honors reset kind and polarity" => sub {
        if ($language ne 'vhdl') {
            plan skip_all => 'Verilator runtime provider unavailable or not qualified'
                unless can_run('verilator') && darwin_verilator_runtime_qualified();
        }
        my $ghdl = $ENV{FSMGEN_RESET_GHDL} // 'ghdl';
        if ($language eq 'vhdl') {
            $ghdl = $ghdl =~ m{/} ? abs_path($ghdl) : can_run($ghdl);
            plan skip_all => 'GHDL runtime provider unavailable' unless defined($ghdl) && -x $ghdl;
        }
        my $dir = "$work/$language";
        mkdir $dir or die $!;
        my @hdl;
        for my $c (@cases) {
            my $output = "$dir/$c->[0]." . ($language eq 'vhdl' ? 'vhd' : $language eq 'verilog' ? 'v' : 'sv');
            my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                '--output', $output, "$work/$c->[0].fsm"], '');
            is($r->{exit_code}, 0, "$c->[0] generates through the real strict CLI") or diag($r->{stderr});
            return if $r->{exit_code};
            push @hdl, $output;
        }
        if ($language eq 'vhdl') {
            my $tb = "$dir/reset_tb.vhd";
            write_file($tb, vhdl_testbench());
            my $compile = ghdl_stage([$ghdl, '-a', '--std=08', '--workdir='.$dir, @hdl, $tb], $dir);
            ok($compile->{ok}, 'GHDL analyzes the generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
            return unless $compile->{ok};
            my $r = ghdl_stage([$ghdl, '--elab-run', '--std=08', '--workdir='.$dir, 'reset_tb', '--assert-level=error', '--stop-time=100ns'], $dir);
            ok($r->{ok}, 'GHDL reset behavior passes') or diag($r->{diagnostic},substr($r->{stderr},0,8192),$r->{stdout});
            like($r->{stdout}.$r->{stderr}, qr/RESET_BEHAVIOR_PASS/, 'independent VHDL oracle reaches completion');
        } else {
            my $tb = "$dir/reset_tb.sv";
            write_file($tb, sv_testbench());
            my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert',
                '-Wno-fatal', '-j', '1', '--top-module', 'reset_tb', '--Mdir', "$dir/obj", @hdl, $tb]);
            ok($compile->{ok}, 'Verilator builds the generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
            return unless $compile->{ok};
            my $r = run_generated_binary(["$dir/obj/Vreset_tb"]);
            ok($r->{ok}, 'Verilator reset behavior passes') or diag($r->{diagnostic},substr($r->{stderr},0,8192),$r->{stdout});
            like($r->{stdout}, qr/RESET_BEHAVIOR_PASS/, 'independent Verilog-family oracle reaches completion');
        }
    };
}

done_testing();

# The fixtures drive a nonzero reset value and pulses wholly between clock
# edges. Checking only reset expressions or clock-edge behavior cannot tell
# synchronous and asynchronous policies apart.
sub sv_testbench {
    my $instances = join "\n", map {
        "  $_->[0] dut_$_->[0](.clk(clk), .reset_pin($_->[3]), .DATA(data_in), .Q(q_$_->[0]));"
    } @cases;
    return <<'SV' . $instances . <<'SV';
module reset_tb;
  reg clk = 0;
  always #5 clk = !clk;
  reg rst_high = 1, rst_low = 0;
  reg [3:0] data_in = 9;
  wire [3:0] q_sync_high, q_sync_low, q_async_high, q_async_low;
SV
  task expect_all(input [3:0] value);
    if (q_sync_high !== value || q_sync_low !== value || q_async_high !== value || q_async_low !== value)
      $fatal(1, "all reset modes expected %d, got %d %d %d %d", value, q_sync_high, q_sync_low, q_async_high, q_async_low);
  endtask
  task expect_split(input [3:0] sync_value, input [3:0] async_value);
    if (q_sync_high !== sync_value || q_sync_low !== sync_value || q_async_high !== async_value || q_async_low !== async_value)
      $fatal(1, "reset timing/polarity mismatch: %d %d %d %d", q_sync_high, q_sync_low, q_async_high, q_async_low);
  endtask
  initial begin
    #6; expect_all(3);
    #6; rst_high = 0; rst_low = 1;
    #4; expect_all(9);
    #1; rst_high = 1; rst_low = 0;
    #1; expect_split(9, 3);
    #8; expect_all(3);
    #1; rst_high = 0; rst_low = 1; data_in = 6;
    #9; expect_all(6);
    #1; rst_high = 1; rst_low = 0;
    #1; expect_split(6, 3);
    #1; rst_high = 0; rst_low = 1;
    #5; expect_split(6, 3);
    #2; expect_all(6);
    $display("RESET_BEHAVIOR_PASS");
    $finish;
  end
endmodule
SV
}
sub vhdl_testbench {
    my $instances = join "\n", map {
        "  dut_$_->[0]: entity work.$_->[0] port map(clk => clk, reset_pin => $_->[3], DATA => data_in, Q => q_$_->[0]);"
    } @cases;
    return <<'VHDL' . $instances . <<'VHDL';
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity reset_tb is end;
architecture behavior of reset_tb is
  signal clk: std_logic := '0';
  signal rst_high: std_logic := '1';
  signal rst_low: std_logic := '0';
  signal data_in: std_logic_vector(3 downto 0) := "1001";
  signal q_sync_high, q_sync_low, q_async_high, q_async_low: std_logic_vector(3 downto 0);
begin
  clk <= not clk after 5 ns;
VHDL
  process
    procedure expect_values(synchronous_value, asynchronous_value: natural) is
    begin
      assert q_sync_high = std_logic_vector(to_unsigned(synchronous_value,4)) and
             q_sync_low = std_logic_vector(to_unsigned(synchronous_value,4)) and
             q_async_high = std_logic_vector(to_unsigned(asynchronous_value,4)) and
             q_async_low = std_logic_vector(to_unsigned(asynchronous_value,4))
        report "reset kind/polarity behavior mismatch" severity failure;
    end procedure;
  begin
    wait for 6 ns; expect_values(3,3);
    wait for 6 ns; rst_high <= '0'; rst_low <= '1';
    wait for 4 ns; expect_values(9,9);
    wait for 1 ns; rst_high <= '1'; rst_low <= '0';
    wait for 1 ns; expect_values(9,3);
    wait for 8 ns; expect_values(3,3);
    wait for 1 ns; rst_high <= '0'; rst_low <= '1'; data_in <= "0110";
    wait for 9 ns; expect_values(6,6);
    wait for 1 ns; rst_high <= '1'; rst_low <= '0';
    wait for 1 ns; expect_values(6,3);
    wait for 1 ns; rst_high <= '0'; rst_low <= '1';
    wait for 5 ns; expect_values(6,3);
    wait for 2 ns; expect_values(6,6);
    report "RESET_BEHAVIOR_PASS" severity note;
    std.env.stop;
    wait;
  end process;
end;
VHDL
}
sub ghdl_stage {
    my ($argv, $cwd) = @_;
    return supervise_process(schema => 'fsmgen.test.reset_behavior.v1', stage => 'ghdl',
        bounds => {timeout_seconds => 60, capture_limit_bytes => 1_048_576},
        containment => 'test_runtime_process_group', cwd => $cwd, argv => $argv);
}
sub write_file {
    open my $fh, '>', $_[0] or die $!;
    print {$fh} $_[1] or die $!;
    close $fh or die $!;
}
