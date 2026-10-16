#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Test::HDLBehaviorRuntime qw(ghdl_behavior_provider run_ghdl_analysis run_ghdl_behavior);
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical->utf8;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my @cases = (
    ['sync_high', 'sreset', 'active_high', 'rst_high'],
    ['sync_low', 'sreset', 'active_low', 'rst_low'],
    ['async_high', 'areset', 'active_high', 'rst_high'],
    ['async_low', 'areset', 'active_low', 'rst_low'],
);
for my $format (qw(fsm isf)) {
    mkdir "$work/$format" or die $!;
    for my $c (@cases) {
        my $text = $format eq 'fsm'
            ? "(?fsm:$c->[0]\n"
                ."  (+system (clock clk) ($c->[1] reset_pin $c->[2]))\n"
                ."  (+interface (output Q) (output Z) (output FLAG) (output SPARE))\n"
                ."  (+size (Q 5 (reset 19)) (Z 4 (reset 0)) (FLAG 1 (reset 1)) (SPARE 7))\n"
                ."  (idle (-> idle)))\n"
            : "(actor $c->[0]\n  (clock clk)\n"
                ."  (reset (reset_pin " . ($c->[1] eq 'areset' ? 'async ' : '') . "$c->[2]))\n"
                ."  (interface (input start) (output done) (output Q (width 5) (reset 19))\n"
                ."    (output Z (width 4) (reset 0)) (output FLAG (reset 1)) (output SPARE (width 7)))\n"
                ."  (transaction tx (on start) (complete done)))\n";
        write_file("$work/$format/$c->[0].$format", $text);
    }
    subtest "$format native/API/newline reports retain reset-only metadata" => sub {
        for my $c (@cases) {
            my $relative = File::Spec->abs2rel("$work/$format/$c->[0].$format", $root);
            for my $kind (qw(check semantic), ($format eq 'isf' ? 'schedule' : ())) {
                my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
                my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
                my $r = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
                is($r->{exit_code}, 0, "$c->[0] $kind native succeeds") or diag($r->{stderr});
                next if $r->{exit_code};
                my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($r->{stdout}), $root);
                my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                    name => $tools{$kind}, arguments => {source_id => $relative}}};
                my $response = $api->handle_jsonrpc_request($request);
                ok(!$response->{error} && !$response->{result}{isError}, "$kind API succeeds");
                is_deeply($response->{result}{structuredContent}{report}, $report, "$kind complete native/API parity");
                my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
                is($wire->{exit_code}, 0, "$kind transport succeeds");
                is_deeply($json->decode($wire->{stdout}), $response, "$kind complete newline/API parity");
                if ($kind eq 'semantic') {
                    my %outputs = map {$_->{name} => $_} @{$report->{semantic}{signal_analysis}{outputs}};
                    is($outputs{Q}{width}, 5, 'reset-only vector retains output width');
                    is($outputs{SPARE}{width}, 7, 'unreset undriven output retains output width');
                    my %families = map {$_->{signal_name} => $_}
                        @{$report->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}};
                    for my $name (qw(Q Z FLAG)) {
                        my %reset = (Q => '19', Z => "4'b0000", FLAG => '1');
                        my %width = (Q => 5, Z => 4, FLAG => 1);
                        is_deeply($families{$name}, {
                            signal_name => $name, width => $width{$name},
                            multiplexer_type => 'flop', default_value => $name,
                            reset_value => $reset{$name}, pulse_delay_cycles => undef, driver_count => 0,
                            driver_blocks => [], driver_enable_signals => [],
                            family_enable_signals => [], rhs_enable_families => [], rhs_values => [],
                        }, "$name exposes reset/hold without fabricated data drivers");
                    }
                    ok(!exists $families{SPARE}, 'plain undriven output has no drive family');
                }
            }
        }
    };
    for my $language (qw(systemverilog verilog vhdl)) {
        subtest "$format $language reset-only behavior and undriven control" => sub {
            my $dir = "$work/$format/$language";
            mkdir $dir or die $!;
            my @hdl;
            for my $c (@cases) {
                my $output = "$dir/$c->[0]." . ($language eq 'vhdl' ? 'vhd' : $language eq 'verilog' ? 'v' : 'sv');
                my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                    '--output', $output, "$work/$format/$c->[0].$format"], '');
                is($r->{exit_code}, 0, "$c->[0] generates") or diag($r->{stderr});
                return if $r->{exit_code};
                my $text = read_file($output);
                like($text, qr/\bQ\s*<=/, 'explicit reset creates a sequential driver');
                like($text, qr/\bZ\s*<=/, 'zero reset is not mistaken for absent metadata');
                like($text, qr/\bFLAG\s*<=/, 'scalar reset creates a sequential driver');
                unlike($text, qr/\bSPARE\s*(?:<=|=)/, 'no reset and no writer invents no value');
                push @hdl, $output;
            }
            subtest 'independent runtime oracle' => sub {
                if ($language eq 'vhdl') {
                    my $ghdl = ghdl_behavior_provider('reset_only');
                    plan skip_all => 'GHDL provider unavailable' unless defined($ghdl) && -x $ghdl;
                    my $tb = "$dir/reset_only_tb.vhd";
                    write_file($tb, vhdl_tb($format));
                    my $compile = run_ghdl_analysis('reset_only', $dir, [@hdl, $tb]);
                    ok($compile->{ok}, 'GHDL analyzes generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                    return unless $compile->{ok};
                    my $r = run_ghdl_behavior('reset_only', $dir);
                    ok($r->{ok}, 'GHDL reset timing and hold pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
                    like($r->{stdout}.$r->{stderr}, qr/RESET_ONLY_PASS/, 'VHDL oracle completes');
                } else {
                    plan skip_all => 'Verilator provider unavailable or not qualified'
                        unless can_run('verilator') && darwin_verilator_runtime_qualified();
                    my $tb = "$dir/reset_only_tb.sv";
                    write_file($tb, sv_tb($format));
                    my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert',
                        '-Wno-fatal', '-j', '1', '--top-module', 'reset_only_tb', '--Mdir', "$dir/obj", @hdl, $tb]);
                    ok($compile->{ok}, 'Verilator builds generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                    return unless $compile->{ok};
                    my $r = run_generated_binary(["$dir/obj/Vreset_only_tb"]);
                    ok($r->{ok}, 'Verilator reset timing and hold pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
                    like($r->{stdout}, qr/RESET_ONLY_PASS/, 'Verilog-family oracle completes');
                }
            };
        };
    }
}
subtest 'signal reset metadata does not invent a missing hardware reset' => sub {
    my $source = "$work/no_reset.fsm";
    write_file($source, "(?fsm:no_reset (+system (clock clk))\n"
        ."(+interface (output Q)) (+size (Q 5 (reset 19))) (idle (-> idle)))\n");
    for my $language (qw(systemverilog verilog vhdl)) {
        my $output = "$work/no_reset.$language";
        my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
            '--output', $output, $source], '');
        if ($language eq 'vhdl') {
            isnt($r->{exit_code}, 0, 'clock-only VHDL is outside the reset-bearing subset');
            like($r->{stderr}, qr/unsupported generated always_ff condition 'current_state <= next_state;'/,
                'VHDL refuses the unsupported process explicitly');
            ok(!-e $output, 'refused VHDL leaves no output artifact');
            next;
        }
        is($r->{exit_code}, 0, "$language retains the explicit clock-only contract") or diag($r->{stderr});
        next if $r->{exit_code};
        unlike(read_file($output), qr/\bQ\s*(?:<=|=)/, 'no effective reset invents no initialization');
    }
};
done_testing();

sub sv_tb {
    my ($format) = @_;
    my $text = "`timescale 1ns/1ps\nmodule reset_only_tb;\nlogic clk=0, rst_high=0, rst_low=1;\nalways #5 clk=~clk;\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "wire [4:0] q_$n; wire [3:0] z_$n; wire f_$n;\n"
            ."$n dut_$n(.clk(clk), .reset_pin($c->[3]), .Q(q_$n), .Z(z_$n), .FLAG(f_$n), .SPARE()"
            .($format eq 'isf' ? ", .start(1'b0), .done()" : '').");\n";
    }
    $text .= "task expect_all; begin\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "assert(q_$n === 5'd19 && z_$n === 4'd0 && f_$n === 1'b1) else \$fatal(1, \"$n reset/hold mismatch\");\n";
    }
    return $text . <<'SV';
end endtask
initial begin
  #1; assert(q_sync_high !== 5'd19 && q_sync_low !== 5'd19 && q_async_high !== 5'd19 && q_async_low !== 5'd19) else $fatal(1,"invented pre-reset initialization");
  #1; rst_high=1; rst_low=0;
  #1; assert(q_async_high === 5'd19 && q_async_low === 5'd19 && q_sync_high !== 5'd19 && q_sync_low !== 5'd19) else $fatal(1,"reset edge timing mismatch");
  #1; rst_high=0; rst_low=1;
  #2; assert(q_sync_high !== 5'd19 && q_sync_low !== 5'd19 && q_async_high === 5'd19 && q_async_low === 5'd19) else $fatal(1,"inactive edge changed reset-only register");
  #1; rst_high=1; rst_low=0;
  #9; expect_all();
  #1; rst_high=0; rst_low=1;
  #20; expect_all();
  $display("RESET_ONLY_PASS"); $finish;
end
endmodule
SV
}
sub vhdl_tb {
    my ($format) = @_;
    my $text = "library ieee; use ieee.std_logic_1164.all;\nentity reset_only_tb is end;\narchitecture behavior of reset_only_tb is\n"
        ."signal clk: std_logic := '0'; signal rst_high: std_logic := '0'; signal rst_low: std_logic := '1';\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "signal q_$n: std_logic_vector(4 downto 0); signal z_$n: std_logic_vector(3 downto 0); signal f_$n: std_logic;\n";
    }
    $text .= "begin\nclk <= not clk after 5 ns;\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "dut_$n: entity work.$n port map(clk=>clk, reset_pin=>$c->[3], Q=>q_$n, Z=>z_$n, FLAG=>f_$n, SPARE=>open"
            .($format eq 'isf' ? ", start=>'0', done=>open" : '').");\n";
    }
    $text .= "process\nprocedure expect_all is begin\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "assert q_$n = \"10011\" and z_$n = \"0000\" and f_$n = '1' report \"$n reset/hold mismatch\" severity failure;\n";
    }
    return $text . <<'VHDL';
end procedure;
begin
  wait for 1 ns;
  assert q_sync_high /= "10011" and q_sync_low /= "10011" and q_async_high /= "10011" and q_async_low /= "10011" report "invented pre-reset initialization" severity failure;
  wait for 1 ns; rst_high <= '1'; rst_low <= '0';
  wait for 1 ns;
  assert q_async_high = "10011" and q_async_low = "10011" and q_sync_high /= "10011" and q_sync_low /= "10011" report "reset edge timing mismatch" severity failure;
  wait for 1 ns; rst_high <= '0'; rst_low <= '1';
  wait for 2 ns;
  assert q_sync_high /= "10011" and q_sync_low /= "10011" and q_async_high = "10011" and q_async_low = "10011" report "inactive edge changed reset-only register" severity failure;
  wait for 1 ns; rst_high <= '1'; rst_low <= '0';
  wait for 9 ns; expect_all;
  wait for 1 ns; rst_high <= '0'; rst_low <= '1';
  wait for 20 ns; expect_all;
  report "RESET_ONLY_PASS" severity note; std.env.stop; wait;
end process;
end;
VHDL
}
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
