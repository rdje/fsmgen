#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::Emitter::FSM;
use FSM::Pipeline::HDLGenerator;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
for my $placement (qw(direct generated)) {
    for my $case ([wait_one => '(wait 1)'], [wait_many => '(wait 3)'], [point => '(point end)'], [phase => '(phase end)']) {
        my ($label, $clause) = @$case;
        subtest "$placement terminal $label" => sub {
            my $dir = "$work/${placement}_$label";
            mkdir $dir or die $!;
            my $body = $placement eq 'direct'
                ? "(transaction main (on start) (set visits (+ visits 1)) $clause)"
                : "(transaction main (on start) (spawn worker as job) (await_all done)) (transaction worker (set visits (+ visits 1)) $clause)";
            my $source = write_file("$dir/source.isf", <<"ISF");
(actor terminal_hold (clock clk) (reset (rst_n async active_low))
  (interface (input start) (output marker (width 8)))
  (storage (var visits (width 8) (reset 0)))
  (rule observe 1 (marker visits))
  $body)
ISF
            my $actor = FSM::Adapter::ISF->new->parse_file($source);
            my $scheduler = FSM::Scheduler::ISF->new;
            my $ir = $scheduler->{ir}->build_module($actor);
            my $selected = $placement eq 'direct' ? $ir : $ir->{children}{worker};
            my @empty = grep {!@{$_->{assignments}} && !@{$_->{transitions}}} @{$selected->{states}};
            is(scalar @empty, 1, 'source graph retains one passive terminal state');
            my $terminal = $empty[0]{name};
            my $before = dclone($selected);
            my $text = FSM::Scheduler::ISF::Emitter::FSM->new->emit($selected);
            is_deeply($selected, $before, 'emission preserves source graph and metadata');
            like($text, qr/\(\Q$terminal\E\s+\(-> \Q$terminal\E\)\s*\)/, 'empty carrier body has an explicit hold');
            my @warnings;
            my $lowered;
            { local $SIG{__WARN__} = sub {push @warnings, @_}; $lowered = $scheduler->lower($actor); }
            is_deeply(\@warnings, [], 'actual lowering has no missing-body/target warnings');
            write_file("$dir/$_", $lowered->{files}{$_}) for sort keys %{$lowered->{files}};
            for my $name (sort keys %{$lowered->{files}}) {
                check_carrier("$dir/$name", 0, "$name strict replay");
            }
            (my $empty_again = $text) =~ s/\(\Q$terminal\E\s+\(-> \Q$terminal\E\)\s*\)/( $terminal )/;
            isnt($empty_again, $text, 'negative control removes the terminal body');
            my $negative = write_file("$dir/empty-control.fsm", $empty_again);
            my $bad = check_carrier($negative, 1, 'empty-body negative control is refused');
            like($bad->{stdout}, qr/Unsupported top-level form.*\Q$terminal\E/, 'native refusal identifies the removed state body');
            qualify_reports($source);
            simulate($dir, $source, $placement) if $label eq 'wait_many';
        };
    }
}

subtest 'explicit successor and completion remain real continuations' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source(<<'ISF', 'continuation.isf');
(actor continued (clock clk) (reset rst_n)
  (interface (input start) (output done) (output value (width 4)))
  (transaction main (on start) (wait 2) (point end) (phase end)
    (set value 3) (complete done)))
ISF
    my $scheduler = FSM::Scheduler::ISF->new;
    my $ir = $scheduler->{ir}->build_module($actor);
    for my $state (grep {$_->{kind} eq 'wait' || exists $_->{point_name} || exists $_->{phase_name}} @{$ir->{states}}) {
        ok(@{$state->{transitions}}, 'explicit successor retained');
        isnt($state->{transitions}[0]{target}, $state->{name}, 'continued state is not replaced by a hold');
    }
    my $files = $scheduler->lower($actor)->{files};
    check_carrier(write_file("$work/continued.fsm", $files->{'continued.fsm'}), 0, 'continued carrier strict replay');
};
done_testing;

sub check_carrier {
    my ($path, $exit, $label) = @_;
    my $result = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', $path], '');
    is($result->{exit_code}, $exit, $label) or diag($result->{stdout}, $result->{stderr});
    is($result->{stderr}, '', "$label has clean stderr");
    return $result;
}
sub qualify_reports {
    my ($source) = @_;
    my $relative = File::Spec->abs2rel($source, $root);
    for my $query (
        [[qw(--strict --check --json)], 'fsmgen_check'],
        [[qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        [['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "$tool native success") or diag($native->{stdout}, $native->{stderr});
        is($native->{stderr}, '', "$tool native clean stderr");
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
            name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $report, "$tool complete native/API parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, "$tool newline success");
        is($wire->{stderr}, '', "$tool newline clean stderr");
        is_deeply($json->decode($wire->{stdout}), $response, "$tool complete newline/API parity");
    }
}
sub simulate {
    my ($dir, $source, $placement) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3
            unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $hdl = FSM::Pipeline::HDLGenerator->new(quiet => 1)->generate_hdl_from_file($source)->{hdl_code};
        my $dut = write_file("$dir/dut.sv", $hdl);
        my $module = $placement eq 'direct' ? 'terminal_hold' : 'terminal_hold_top';
        my $tb = write_file("$dir/tb.sv", <<"SV");
module tb;
 logic clk=0,rst_n=1,start=0;wire [7:0] marker;
 always #5 clk=~clk;
 $module dut(.*);
 task tick; @(posedge clk); #1; endtask
 task activate;
  @(negedge clk);start=1;
  @(negedge clk);start=0;
  repeat(15) tick;
  if(marker!==8'd1) \$fatal(1,"body did not execute once: %0d",marker);
  @(negedge clk);start=1;
  repeat(10) tick;
  @(negedge clk);start=0;
  repeat(10) tick;
  if(marker!==8'd1) \$fatal(1,"terminal hold invented rearm: %0d",marker);
 endtask
 initial begin
  #2;rst_n=0;#20;rst_n=1;
  activate;
  @(negedge clk);rst_n=0;repeat(3) tick;
  if(marker!==0) \$fatal(1,"reset failed to restore storage");
  @(negedge clk);rst_n=1;
  activate;
  \$display("TERMINAL_STATE_HOLD_PASS");\$finish;
 end
 initial begin #10000;\$fatal(1,"timeout");end
endmodule
SV
        my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $dut, $tb]);
        ok($compile->{ok}, 'terminal hold HDL compiles') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) {fail('runtime compilation failed'); fail('runtime observations absent')}
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'hold, repeated request and reset behavior passes') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/TERMINAL_STATE_HOLD_PASS/, 'independent runtime oracle completed');
        }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    return $path;
}
