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
use FSM::Composition::ModuleDefinitionCollector;
use FSM::Composition::RealizedInstance;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $pipeline = FSM::Pipeline::HDLGenerator->new(quiet => 1);
for my $kind (qw(scalar aggregate parameters)) {
    subtest "repeated direct $kind source" => sub {
        my $dir = "$work/$kind";
        mkdir $dir or die $!;
        my $type = $kind eq 'aggregate' ? '(+types (type frame_t (record (payload (bits 8)))))' : '';
        my $width = $kind eq 'aggregate' ? 'frame_t' : '8';
        my $params = $kind eq 'parameters' ? '(+params (BIAS 0))' : '';
        my $first = $kind eq 'parameters' ? '(params (BIAS 3))' : '';
        my $second = $kind eq 'parameters' ? '(params (BIAS 7))' : '';
        my $rhs = $kind eq 'parameters' ? '(+ IN BIAS)' : 'IN';
        my $source = write_file("$dir/source.fsm", <<"FSM");
(?top:repeated_top
 $type
 (?ports:io first_in<$width second_in<$width first_out>$width second_out>$width)
 (?dtc:first shared_src $first) (?dtc:second shared_src $second)
 (?wiring:links (first_in first.IN) (first.OUT first_out) (second_in second.IN) (second.OUT second_out)))
(?dt:shared_src $type $params (+size (IN $width) (OUT $width)) (-pass (= (OUT $rhs))))
FSM
        my $result = $pipeline->generate_hdl_from_file($source);
        my $hdl = $result->{hdl_code};
        my @modules = $hdl =~ /^module\s+(\w+)/mg;
        is_deeply(\@modules, [qw(shared_src repeated_top)], 'one definition with a separate top');
        is_deeply([map {$_->instance_name} @{$result->{composition_plan}->instances}], [qw(first second)],
            'both instances and their metadata survive definition collection');
        if ($kind eq 'parameters') {
            like($hdl, qr/\.BIAS\(3\)/, 'first parameter override retained');
            like($hdl, qr/\.BIAS\(7\)/, 'second parameter override retained');
        }
        my $native = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $source], '');
        is($native->{exit_code}, 0, 'public strict check accepts repeated source') or diag($native->{stdout}, $native->{stderr});
        my $add_first = $kind eq 'parameters' ? 3 : 0;
        my $add_second = $kind eq 'parameters' ? 7 : 0;
        simulate($dir, $hdl, <<"SV");
module tb;
 logic [7:0] first_in, second_in; wire [7:0] first_out, second_out;
 repeated_top dut(.*);
 initial begin
  for (int i=0; i<256; i++) begin
   first_in=8'(i); second_in=8'(255-i); #1;
   if(first_out !== 8'(i+$add_first) || second_out !== 8'(255-i+$add_second))
    \$fatal(1,"shared definition merged instance behavior");
  end
  \$display("MODULE_INSTANCES_PASS"); \$finish;
 end
endmodule
SV
    };
}

subtest 'repeated ISF workers keep independent local state and public reports' => sub {
    my $dir = "$work/isf";
    mkdir $dir or die $!;
    my $source = write_file("$dir/source.isf", <<'ISF');
(actor repeated_workers
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input first_in (width 8)) (input second_in (width 8))
  (output first_out (width 8)) (output second_out (width 8)) (output done))
 (transaction worker (ports (input payload (width 8)) (output result (width 8)))
  (local acc (width 8) (default 0)) (set acc payload) (wait 3) (set result acc) (complete done))
 (transaction main (on start)
  (spawn worker as first_worker (bind (input payload first_in) (output result first_out)))
  (spawn worker as second_worker (bind (input payload second_in) (output result second_out)))
  (await_all done) (complete done)))
ISF
    my $result = $pipeline->generate_hdl_from_file($source);
    my @workers = $result->{hdl_code} =~ /^module worker\b/mg;
    is(scalar(@workers), 1, 'worker definition is emitted once');
    my $worker_run = simulate($dir, $result->{hdl_code}, <<'SV', 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.43: staggered completion pulses require retained join state');
module tb;
 logic clk=0, rst_n=1, start=0; logic [7:0] first_in=83, second_in=29;
 wire [7:0] first_out, second_out; wire done;
 always #5 clk=~clk;
 repeated_workers_top dut(.*);
 initial begin
  #2;rst_n=0;#10;rst_n=1;#8;start=1;#10;start=0;
  wait(done);#1;
  if(first_out!==83 || second_out!==29) $fatal(1,"independent worker state lost");
  #50;first_in=3;second_in=207;start=1;#10;start=0;
  wait(done);#1;
  if(first_out!==3 || second_out!==207) $fatal(1,"repeated activation lost");
  $display("MODULE_INSTANCES_PASS");$finish;
 end
 initial begin #150; if(first_out!==83 || second_out!==29) $fatal(1,"independent local storage lost"); $display("WORKER_VALUES_PASS"); end
 initial begin #2000;$fatal(1,"completion timeout");end
endmodule
SV
    like($worker_run->{stdout}, qr/WORKER_VALUES_PASS/, 'worker-local values remain independent before the known join failure') if $worker_run;
    my $root = abs_path('.');
    my $relative = File::Spec->abs2rel($source, $root);
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
    my $json = JSON::PP->new->canonical;
    for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                   ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                   ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
        my ($kind, $flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "native $kind accepted");
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
};

subtest 'definition conflicts and timestamp normalization are bounded' => sub {
    my $header = "//=====\n// Flattened Decision Tree FSM: shared\n// Generated using Enable-based Methodology with WEN/EN Signals\n";
    my $body = "module shared; endmodule\n";
    my $first = instance('one', 'shared', $header."// Date: first run\n".$body);
    my $second = instance('two', 'shared', $header."// Date: later run\n".$body);
    my $collected = collect($first, $second);
    is_deeply($collected, [$first->hdl_code], 'only the known header date is ignored for equality; first payload stays exact');
    is_deeply(collect($first, instance('external', 'ext', undef)), [$first->hdl_code], 'external no-HDL instances require no emitted definition');
    for my $different ($body."// Date: meaningful body comment\n", 'module shared; wire added; endmodule') {
        my $ok = eval { collect($first, instance('two', 'shared', $header."// Date: later run\n".$different)); 1 };
        ok(!$ok, 'any definition difference beyond header metadata fails closed');
        like($@, qr/conflicting definitions for instances 'one' and 'two'/, 'conflict names both instances');
    }
    my $ok = eval { FSM::Composition::ModuleDefinitionCollector->collect(instances => [$first], top_name => 'shared'); 1 };
    ok(!$ok, 'generated child cannot redefine the composition top');
    like($@, qr/conflicts with composition top 'shared'/, 'top collision diagnostic');
    my $upper = instance('upper', 'SHARED', $body);
    my $lower = instance('lower', 'shared', $body);
    is_deeply(FSM::Composition::ModuleDefinitionCollector->collect(instances => [$upper, $lower], target_language => 'vhdl'), [$body], 'VHDL module identity folds case');
    is_deeply(collect($upper, $lower), [$body, $body], 'Verilog module identity preserves case');
};
done_testing();

sub instance { my ($instance, $module, $hdl) = @_; return FSM::Composition::RealizedInstance->new(instance_name => $instance, module_name => $module, hdl_code => $hdl); }
sub collect { return FSM::Composition::ModuleDefinitionCollector->collect(instances => [@_], top_name => 'top'); }
sub simulate {
    my ($dir, $hdl, $tb, $known_runtime_failure) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl);
        my $test = write_file("$dir/tb.sv", $tb);
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent HDL compiler admits the single definition') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            local $TODO = $known_runtime_failure if defined $known_runtime_failure;
            ok($run->{ok}, 'independent runtime preserves instance behavior') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/MODULE_INSTANCES_PASS/, 'independent observations completed');
            return $run;
        }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "open $path: $!"; print {$fh} $text; close $fh or die "close $path: $!"; return $path;
}
