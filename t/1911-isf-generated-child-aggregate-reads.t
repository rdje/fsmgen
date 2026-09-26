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

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
for my $case (
    ['single_record', '(record (payload (bits 8)))', 'status', 'wdata'],
    ['multi_record', '(record (payload (bits 7)) (flag bit))', 'status', 'wdata'],
    ['single_list', '(list (bits 8))', 'status', 'wdata'],
    ['multi_list', '(list (bits 4) (bits 4))', 'status', 'wdata'],
    ['nested', '(record (inner (list (record (payload (bits 7)) (flag bit)))))', 'status', 'wdata'],
    ['nested_leaf', '(record (inner (list (record (payload (bits 7)) (flag bit)))))', 'status.inner[0].payload', '(wdata >> 1)'],
) {
    my ($name, $definition, $read, $expected) = @$case;
    my $result_width = $name eq 'nested_leaf' ? 7 : 8;
    subtest $name => sub {
        my $dir = "$work/$name"; mkdir $dir or die $!;
        my $source = write_file("$dir/source.isf", <<"ISF");
(actor aggregate_$name
 (clock clk) (reset (rst_n async active_low))
 (types (type root_t $definition) (type other_t (list (bits 4) (bits 4))))
 (interface (input start) (input wdata (width 8)) (input other_data (width 8))
  (output observed (width $result_width)) (output observed_two (width $result_width))
  (output extra (width 8)) (output extra_two (width 8)) (output done))
 (storage (var status (type root_t) (reset 19)) (var other (type other_t) (reset 7))
  (var unused (width 7) (reset 3)))
 (transaction worker (ports (output result (width $result_width)) (output auxiliary (width 8)))
  (wait 6) (set result $read) (set auxiliary other) (complete done))
 (transaction parent (on start) (set status 53) (set other 11)
  (spawn worker as w0 (bind (output result observed) (output auxiliary extra)))
  (spawn worker as w1 (bind (output result observed_two) (output auxiliary extra_two)))
  (wait 1) (set status wdata) (set other other_data) (await_all done) (complete done)))
ISF
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $ir = $scheduler->{ir}->build_module($actor);
        my $child = $ir->{children}{worker};
        is_deeply($child->{declared_storage}, [], 'child contains no private actor storage');
        is_deeply([map {$_->{name}} @{$child->{actor_storage_reads}}], [qw(other status)], 'exact aggregate root reads');
        is_deeply([sort map {$_->{name}} @{$child->{ports}}], [qw(auxiliary done other result start status)],
            'child ports contain only explicit outputs, handshakes and typed live inputs');
        for my $pair (['status', 'root_t', 19], ['other', 'other_t', 7]) {
            my ($signal, $type, $reset) = @$pair;
            is($child->{signal_type_refs}{$signal}, $type, 'child input retains authored aggregate alias');
            is($ir->{signal_type_refs}{"isf_storage_read_$signal"}, $type, 'owner handoff retains the same alias');
            is($ir->{reset_values}{$signal}, $reset, 'reset stays with owner');
            ok(!exists $child->{reset_values}{$signal}, 'child does not reset a private copy');
        }
        my $files = $scheduler->lower($actor)->{files};
        for my $file (sort keys %$files) {
            my $replay = write_file("$dir/$file", $files->{$file});
            my $check = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $replay], '');
            is($check->{exit_code}, 0, "$file public scheduled replay") or diag($check->{stdout}, $check->{stderr});
        }
        my $relative = File::Spec->abs2rel($source, $root);
        for my $query (['check', [qw(--strict --check --json)], 'fsmgen_check'],
                       ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
                       ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview']) {
            my ($kind, $flags, $tool) = @$query;
            my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
            is($native->{exit_code}, 0, "native $kind accepted") or diag($native->{stdout}, $native->{stderr});
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $tool, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
            is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
            if ($kind eq 'semantic') {
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
                    [qw(clk other_data rst_n start wdata)], 'no public aggregate or child handoff inputs leak');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [qw(done extra extra_two observed observed_two)], 'exact authored public outputs');
            }
        }
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($dir, $hdl, <<"SV");
module tb;
 logic clk=0, rst_n=1, start=0;
 logic [7:0] wdata=91, other_data=166;
 wire [$result_width-1:0] observed, observed_two;
 wire [7:0] extra, extra_two; wire done;
 always #5 clk=~clk;
 aggregate_${name}_top dut(.*);
 task activate;
  @(negedge clk);start=1;@(negedge clk);start=0;
  wait(done);#1;
  if(observed!==$expected || observed_two!==$expected || extra!==other_data || extra_two!==other_data)
   \$fatal(1,"aggregate live view or independent typed handoff lost");
  repeat(5) @(negedge clk);
 endtask
 initial begin
  #2;rst_n=0;#10;rst_n=1;
  activate;
  wdata=7;other_data=3;activate;
  \$display("AGGREGATE_READ_PASS");\$finish;
 end
 initial begin #3000;\$fatal(1,"aggregate completion timeout");end
endmodule
SV
    };
}
done_testing();
sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl); my $test = write_file("$dir/tb.sv", $tb); my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent aggregate HDL compile') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'post-spawn updates and repeated reads pass') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/AGGREGATE_READ_PASS/, 'independent packed-value observations complete');
        }
    }
}
sub write_file { my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path; }
