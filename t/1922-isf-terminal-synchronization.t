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
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $workspace = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

for my $kind (qw(all any)) {
    for my $pending (0, 1, 2) {
        subtest "$kind with $pending pending children" => sub {
            my $dir = "$workspace/${kind}_$pending";
            mkdir $dir or die $!;
            my $worker = $pending ? '(transaction worker (wait 3) (complete done))' : '';
            my $spawns = join ' ', map { "(spawn worker as w$_)" } 0 .. $pending - 1;
            my $source = write_file("$dir/source.isf", <<"ISF");
(actor terminal_sync
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (output marker (width 8) (reset 0)))
 (storage (var activations (width 8) (reset 0)))
 (rule observe 1 (marker activations))
 $worker
 (transaction main (on start) (set activations (+ activations 1))
  $spawns (await_$kind done)))
ISF
            my $actor = FSM::Adapter::ISF->new->parse_file($source);
            my $scheduler = FSM::Scheduler::ISF->new;
            my $ir = $scheduler->{ir}->build_module($actor);
            my ($join) = grep { $_->{kind} eq "sync_$kind" } @{$ir->{states}};
            is_deeply($join->{transitions}, [{target => $join->{name}}],
                'terminal synchronization has an explicit hold continuation');
            is_deeply($join->{done_ports}, [map { "w${_}_done" } 0 .. $pending - 1],
                'authored pending-set metadata is retained');
            my @warnings;
            my $lowered;
            { local $SIG{__WARN__} = sub { push @warnings, @_ };
              $lowered = $scheduler->lower($actor); }
            is_deeply(\@warnings, [], 'lowering emits no missing-target warning');
            for my $file (sort keys %{$lowered->{files}}) {
                my $path = write_file("$dir/$file", $lowered->{files}{$file});
                my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
                is($result->{exit_code}, 0, "$file strict replay")
                    or diag($result->{stdout}, $result->{stderr});
                is($result->{stderr}, '', "$file replay has clean stderr");
            }
            qualify_reports($source, $pending);
            my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)
                ->generate_hdl_from_file("$dir/terminal_sync.fsm")->{hdl_code};
            simulate($dir, $hdl, $pending);
        };
    }
}

done_testing();

sub qualify_reports {
    my ($source, $pending) = @_;
    my $relative = File::Spec->abs2rel($source, $root);
    for my $query (
        ['check', [qw(--strict --check --json)], 'fsmgen_check'],
        ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($kind, $flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "native $kind succeeds")
            or diag($native->{stdout}, $native->{stderr});
        is($native->{stderr}, '', "native $kind has clean stderr");
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths(
            $json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $report,
            "complete native/API $kind parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'],
            $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "newline $kind exits successfully");
        is($wire->{stderr}, '', "newline $kind has clean stderr");
        is_deeply($json->decode($wire->{stdout}), $response,
            "complete newline/API $kind parity") or diag($wire->{stdout}, $wire->{stderr});
        if ($kind eq 'semantic') {
            is_deeply([sort map { $_->{name} } @{$report->{semantic}{signal_analysis}{inputs}}],
                $pending ? [qw(clk rst_n start)] : ['start'], 'exact public data inputs');
            is_deeply([sort map { $_->{name} } @{$report->{semantic}{signal_analysis}{outputs}}],
                ['marker'], 'exact public outputs');
            if (!$pending) {
                is_deeply($report->{semantic}{explicit_system_contract},
                    {clock => 'clk', reset => 'rst_n', reset_active_level => 0,
                     reset_keyword => 'areset', reset_kind => 'async'},
                    'standalone clock/reset remain in the separate system contract');
            }
        }
    }
}

sub simulate {
    my ($dir, $hdl, $pending) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3
            unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $ports = join "\n", map { "logic w${_}_done=0; wire w${_}_start; int starts_$_=0;" } 0 .. $pending - 1;
        my $count = join "\n", map { "if(!rst_n) starts_$_=0; else if(w${_}_start) starts_$_++;" } 0 .. $pending - 1;
        my $check = join "\n", map { "if(starts_$_!=1) \$fatal(1,\"unexpected child $_ activation count: %0d\",starts_$_);" } 0 .. $pending - 1;
        my $pulses = join "\n", map {
            "@(negedge clk); w${_}_done=1; tick; @(negedge clk); w${_}_done=0; repeat(7) tick;"
        } 0 .. $pending - 1;
        my $tb = <<"SV";
module tb;
 logic clk=0, rst_n=1, start=0;
 wire [7:0] marker;
 $ports
 always #5 clk=~clk;
 terminal_sync dut(.*);
 always @(posedge clk) begin $count end
 task tick; @(posedge clk); #1; endtask
 task activation;
  @(negedge clk); start=1;
  @(negedge clk); start=0;
  repeat(8) tick;
  if(marker!==8'd1) \$fatal(1,"activation did not enter exactly once");
  $check
  // Non-overlapping external completion pulses exercise the parent's public
  // handoff contract; no completion may invent a return-to-entry edge.
  $pulses
  repeat(8) tick;
  @(negedge clk); start=1;
  repeat(5) tick;
  @(negedge clk); start=0;
  repeat(8) tick;
  if(marker!==8'd1) \$fatal(1,"terminal synchronization unexpectedly rearmed");
  $check
 endtask
 initial begin
  #2; rst_n=0; #10; rst_n=1;
  activation;
  @(negedge clk); rst_n=0; repeat(3) tick;
  if(marker!==0) \$fatal(1,"reset did not restore owner output");
  @(negedge clk); rst_n=1;
  activation;
  \$display("TERMINAL_SYNC_HOLD_PASS"); \$finish;
 end
 initial begin #10000; \$fatal(1,"test timeout"); end
endmodule
SV
        my $sv = write_file("$dir/dut.sv", $hdl);
        my $test = write_file("$dir/tb.sv", $tb);
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent compiler accepts terminal synchronization')
            or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compile failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'terminal hold and reset reactivation pass')
                or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/TERMINAL_SYNC_HOLD_PASS/, 'all terminal observations completed');
        }
    }
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
    return $path;
}
