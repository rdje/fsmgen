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
use FSM::Test::ProcessSupervisor qw(supervise_process);
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
{
    my $format = 'fsm';
    mkdir "$work/$format" or die $!;
    for my $c (@cases) {
        my $text = "(?fsm:$c->[0]\n"
            ."  (+system (clock clk) ($c->[1] reset_pin $c->[2]))\n"
            ."  (+types (type signed_word_t (signed (bits 6))))\n"
            ."  (+interface (internal Q) (internal Z) (internal FLAG) (internal SPARE)\n"
            ."    (internal SIGNED_UNUSED) (internal WRITTEN) (input WE) (input DATA)\n"
            ."    (output OBS_Q) (output OBS_Z) (output OBS_FLAG) (output OBS_WRITTEN))\n"
            ."  (+size (Q 5 (reset 19)) (Z 4 (reset 0)) (FLAG 1 (reset 1)) (SPARE 7)\n"
            ."    (SIGNED_UNUSED signed_word_t) (WRITTEN 4 (reset 2)) (DATA 4)\n"
            ."    (OBS_Q 5) (OBS_Z 4) (OBS_WRITTEN 4))\n"
            ."  (idle (= (OBS_Q> Q)) (= (OBS_Z> Z)) (= (OBS_FLAG> FLAG)) (= (OBS_WRITTEN> WRITTEN))\n"
            ."    (<- (WRITTEN DATA) <WE) (-> idle)))\n";
        write_file("$work/$format/$c->[0].$format", $text);
    }
    subtest "$format native/API/newline reports preserve internal ownership" => sub {
        for my $c (@cases) {
            my $relative = File::Spec->abs2rel("$work/$format/$c->[0].$format", $root);
            my $default = $capture->([$^X, 'bin/fsmgen', '--check', '--json', $relative], '');
            is($default->{exit_code}, 0, "$c->[0] default mode accepts internal ownership") or diag($default->{stdout}, $default->{stderr});
            for my $kind (qw(check semantic)) {
                my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
                my %tools = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
                my $r = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
                is($r->{exit_code}, 0, "$c->[0] $kind native succeeds") or diag($r->{stdout},$r->{stderr});
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
                    my %inputs = map {$_->{name} => $_->{width}} @{$report->{semantic}{signal_analysis}{inputs}};
                    my %outputs = map {$_->{name} => $_->{width}} @{$report->{semantic}{signal_analysis}{outputs}};
                    is_deeply(\%inputs, {WE => 1, DATA => 4}, 'only authored data inputs; system ports are separate');
                    is_deeply(\%outputs, {OBS_Q => 5, OBS_Z => 4, OBS_FLAG => 1, OBS_WRITTEN => 4}, 'only authored outputs');
                    my %families = map {$_->{signal_name} => 1}
                        @{$report->{semantic}{forward_ir}{lowered_rtl_ir}{output_drive_families}};
                    ok(!grep($families{$_}, qw(Q Z FLAG SPARE SIGNED_UNUSED WRITTEN)), 'internal registers are not output drive families');
                    my %ports = map {$_->{name} => 1} @{$report->{semantic}{forward_ir}{structural_rtl_ir}{ports}};
                    is_deeply([sort keys %ports], [sort qw(clk reset_pin WE DATA OBS_Q OBS_Z OBS_FLAG OBS_WRITTEN)], 'structural ports agree with the external boundary');
                }
            }
        }
    };
    for my $language (qw(systemverilog verilog vhdl)) {
        subtest "$format $language internal reset/write/hold behavior and undriven control" => sub {
            my $dir = "$work/$format/$language";
            mkdir $dir or die $!;
            my @hdl;
            for my $c (@cases) {
                my $output = "$dir/$c->[0]." . ($language eq 'vhdl' ? 'vhd' : $language eq 'verilog' ? 'v' : 'sv');
                my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
                    '--output', $output, "$work/$format/$c->[0].$format"], '');
                is($r->{exit_code}, 0, "$c->[0] generates") or diag($r->{stdout},$r->{stderr});
                return if $r->{exit_code};
                my $text = read_file($output);
                like($text, $language eq 'vhdl' ? qr/signal SPARE : std_logic_vector\(6 downto 0\)/ : qr/\breg\s+\[6:0\] SPARE\b/, 'unused internal retains width');
                like($text, $language eq 'vhdl' ? qr/signal SIGNED_UNUSED : signed\(5 downto 0\)/ : qr/\breg signed\s+\[5:0\] SIGNED_UNUSED\b/, 'unused internal retains signed type');
                like($text, qr/\bQ\s*<=/, 'explicit reset creates a sequential driver');
                like($text, qr/\bZ\s*<=/, 'zero reset is not mistaken for absent metadata');
                like($text, qr/\bFLAG\s*<=/, 'scalar reset creates a sequential driver');
                unlike($text, qr/\bSPARE\s*(?:<=|=)/, 'no reset and no writer invents no value');
                push @hdl, $output;
            }
            subtest 'independent runtime oracle' => sub {
                if ($language eq 'vhdl') {
                    my $ghdl = $ENV{FSMGEN_RESET_GHDL} // 'ghdl';
                    $ghdl = $ghdl =~ m{/} ? abs_path($ghdl) : can_run($ghdl);
                    plan skip_all => 'GHDL provider unavailable' unless defined($ghdl) && -x $ghdl;
                    my $tb = "$dir/internal_role_tb.vhd";
                    write_file($tb, vhdl_tb($format));
                    my $compile = ghdl_stage([$ghdl, '-a', '--std=08', '--workdir='.$dir, @hdl, $tb], $dir);
                    ok($compile->{ok}, 'GHDL analyzes generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                    return unless $compile->{ok};
                    my $r = ghdl_stage([$ghdl, '--elab-run', '--std=08', '--workdir='.$dir, 'internal_role_tb', '--assert-level=error', '--stop-time=100ns'], $dir);
                    ok($r->{ok}, 'GHDL reset timing and hold pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
                    like($r->{stdout}.$r->{stderr}, qr/INTERNAL_ROLE_PASS/, 'VHDL oracle completes');
                } else {
                    plan skip_all => 'Verilator provider unavailable or not qualified'
                        unless can_run('verilator') && darwin_verilator_runtime_qualified();
                    my $tb = "$dir/internal_role_tb.sv";
                    write_file($tb, sv_tb($format));
                    my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert',
                        '-Wno-fatal', '-j', '1', '--top-module', 'internal_role_tb', '--Mdir', "$dir/obj", @hdl, $tb]);
                    ok($compile->{ok}, 'Verilator builds generated modules and independent oracle') or diag($compile->{diagnostic},substr($compile->{stderr},0,8192));
                    return unless $compile->{ok};
                    my $r = run_generated_binary(["$dir/obj/Vinternal_role_tb"]);
                    ok($r->{ok}, 'Verilator reset timing and hold pass') or diag($r->{diagnostic},$r->{stdout},$r->{stderr});
                    like($r->{stdout}, qr/INTERNAL_ROLE_PASS/, 'Verilog-family oracle completes');
                }
            };
        };
    }
}
subtest 'signal reset metadata does not invent a missing hardware reset' => sub {
    my $source = "$work/no_reset.fsm";
    write_file($source, "(?fsm:no_reset (+system (clock clk))\n"
        ."(+interface (internal Q)) (+size (Q 5 (reset 19))) (idle (-> idle)))\n");
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
        is($r->{exit_code}, 0, "$language retains the explicit clock-only contract") or diag($r->{stdout},$r->{stderr});
        next if $r->{exit_code};
        unlike(read_file($output), qr/\bQ\s*(?:<=|=)/, 'no effective reset invents no initialization');
    }
};
subtest 'clockless DT reset metadata cannot create hardware system ports' => sub {
    my $source = "$work/clockless.fsm";
    write_file($source, "(?dt:clockless (+interface (internal Q) (output OBS) (output SPARE))\n"
        ."(+size (Q 5 (reset 19)) (OBS 5) (SPARE 4 (reset 2))) (-logic (= (OBS> Q))))\n");
    for my $language (qw(systemverilog verilog vhdl)) {
        my $output = "$work/clockless.$language";
        my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--quiet', '--language', $language,
            '--output', $output, $source], '');
        is($r->{exit_code}, 0, "$language supports the clockless DT") or diag($r->{stdout},$r->{stderr});
        next if $r->{exit_code};
        my $text = read_file($output);
        unlike($text, qr/\b(?:Q|SPARE)\s*(?:<=|=)/, 'neither internal nor output reset metadata invents a driver');
        unlike($text, qr/\b(?:clk|rst_n)\b/, 'implicit defaults do not introduce system signals');
    }
};
subtest 'explicit role conflicts and malformed carriers fail closed' => sub {
    my @bad = (
        ['input_conflict', '(internal Q) (input Q)', '(idle (-> idle))', qr/Conflicting explicit roles/],
        ['output_conflict', '(output Q) (internal Q)', '(idle (-> idle))', qr/Conflicting explicit roles/],
        ['output_marker', '(internal Q)', '(idle (<- (Q> 1)))', qr/Internal signal 'Q'.*output marker/],
        ['system_clock', '(internal clk)', '(idle (-> idle))', qr/Internal signal 'clk'.*system port/],
        ['system_reset', '(internal rst_n)', '(idle (-> idle))', qr/Internal signal 'rst_n'.*system port/],
        ['arity', '(internal Q extra)', '(idle (-> idle))', qr/Malformed.*interface/],
        ['name', '(internal bad-name)', '(idle (-> idle))', qr/HDL-identifier-compatible/],
        ['unsupported_role', '(inout Q)', '(idle (-> idle))', qr/interface role must/],
    );
    for my $c (@bad) {
        my $source = "$work/$c->[0].fsm";
        write_file($source, "(?fsm:$c->[0] (+interface $c->[1]) $c->[2])\n");
        for my $strict ([], ['--strict']) {
            my $r = $capture->([$^X, 'bin/fsmgen', @$strict, '--check', '--json', $source], '');
            isnt($r->{exit_code}, 0, "$c->[0] rejects in default and strict mode");
            like($r->{stdout}.$r->{stderr}, $c->[3], 'specific refusal explains contradiction');
        }
    }
    my $source = "$work/repeated.fsm";
    write_file($source, "(?fsm:repeated (+interface (internal Q) (internal Q)) (idle (-> idle)))\n");
    my $r = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
    is($r->{exit_code}, 0, 'repeated identical role remains valid') or diag($r->{stdout},$r->{stderr});
};
done_testing();

sub sv_tb {
    my ($format) = @_;
    my $text = "`timescale 1ns/1ps\nmodule internal_role_tb;\nlogic clk=0, rst_high=0, rst_low=1, we=0; logic [3:0] data=9;\nalways #5 clk=~clk;\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "wire [4:0] q_$n; wire [3:0] z_$n; wire f_$n; wire [3:0] written_$n;\n"
            ."$n dut_$n(.clk(clk), .reset_pin($c->[3]), .OBS_Q(q_$n), .OBS_Z(z_$n), .OBS_FLAG(f_$n), .OBS_WRITTEN(written_$n), .WE(we), .DATA(data)"
            .");\n";
    }
    $text .= "task expect_all(input [3:0] expected_written); begin\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "assert(q_$n === 5'd19 && z_$n === 4'd0 && f_$n === 1'b1 && written_$n === expected_written) else \$fatal(1, \"$n reset/hold mismatch\");\n";
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
  #9; expect_all(2);
  #1; rst_high=0; rst_low=1;
  #20; expect_all(2);
  we=1; #10; expect_all(9);
  we=0; data=4; #20; expect_all(9);
  $display("INTERNAL_ROLE_PASS"); $finish;
end
endmodule
SV
}
sub vhdl_tb {
    my ($format) = @_;
    my $text = "library ieee; use ieee.std_logic_1164.all;\nentity internal_role_tb is end;\narchitecture behavior of internal_role_tb is\n"
        ."signal clk: std_logic := '0'; signal rst_high: std_logic := '0'; signal rst_low: std_logic := '1'; signal we: std_logic := '0'; signal data: std_logic_vector(3 downto 0) := \"1001\";\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "signal q_$n: std_logic_vector(4 downto 0); signal z_$n: std_logic_vector(3 downto 0); signal f_$n: std_logic; signal written_$n: std_logic_vector(3 downto 0);\n";
    }
    $text .= "begin\nclk <= not clk after 5 ns;\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "dut_$n: entity work.$n port map(clk=>clk, reset_pin=>$c->[3], OBS_Q=>q_$n, OBS_Z=>z_$n, OBS_FLAG=>f_$n, OBS_WRITTEN=>written_$n, WE=>we, DATA=>data"
            .");\n";
    }
    $text .= "process\nprocedure expect_all(expected_written: std_logic_vector) is begin\n";
    for my $c (@cases) {
        my $n = $c->[0];
        $text .= "assert q_$n = \"10011\" and z_$n = \"0000\" and f_$n = '1' and written_$n = expected_written report \"$n reset/hold mismatch\" severity failure;\n";
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
  wait for 9 ns; expect_all("0010");
  wait for 1 ns; rst_high <= '0'; rst_low <= '1';
  wait for 20 ns; expect_all("0010");
  we <= '1'; wait for 10 ns; expect_all("1001");
  we <= '0'; data <= "0100"; wait for 20 ns; expect_all("1001");
  report "INTERNAL_ROLE_PASS" severity note; std.env.stop; wait;
end process;
end;
VHDL
}
sub ghdl_stage {
    my ($argv, $cwd) = @_;
    return supervise_process(schema => 'fsmgen.test.internal_role.v1', stage => 'ghdl',
        bounds => {timeout_seconds => 60, capture_limit_bytes => 1_048_576},
        containment => 'test_runtime_process_group', cwd => $cwd, argv => $argv);
}
sub read_file { open my $fh, '<', $_[0] or die $!; local $/; return <$fh>; }
sub write_file { open my $fh, '>', $_[0] or die $!; print {$fh} $_[1] or die $!; close $fh or die $!; }
