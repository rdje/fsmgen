#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $workspace = tempdir(CLEANUP => 1);
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $json = JSON::PP->new->canonical;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);

sub source {
    my ($declaration, $operation, $actor_width) = @_;
    my $storage = defined($actor_width) ? "(storage (var status (width $actor_width)))" : '';
    return "(actor width_scope (clock clk) (params (W 8)) (types (type word_t (bits 8))) "
        . "(interface (input start) (output done)) $storage "
        . "(transaction main (params (N 8)) (ports (output status $declaration)) "
        . "(on start) $operation (complete done)))";
}
sub parse { FSM::Adapter::ISF->new->parse_source($_[0], 'width_scope.isf') }
sub error { my $ok = eval {parse($_[0]); 1}; return $ok ? '' : "$@" }

for my $operation (
    '(set-bit status 7)', '(clear-bit status 7)', '(toggle-bit status 7)',
    '(set-field status (bits 7 4) 3)', '(rotate-left status by 7)', '(rotate-right status by 7)',
    '(when-bit status 7 (set status 1))', '(unless-bit status 7 (set status 1))',
    '(when-field status (bits 7 4) 3 (set status 1))', '(unless-field status (bits 7 4) 3 (set status 1))',
) {
    is(error(source('(width 8)', $operation, 4)), '', "$operation uses wider formal width");
    like(error(source('(width 4)', $operation, 8)), qr/(?:out of range|must be|outside|exceeds|requires 0 < N < 4)/,
        "$operation rejects an index outside the narrower formal");
}
my $parsed = parse(source('(width 8)', '(clear-bit status 7)', 4));
my ($set) = grep {$_->[0] eq 'set'} @{$parsed->{transactions}[0]{clauses}};
is_deeply($set, ['set', 'status', ['&', 'status', 127]], 'inverse mask uses formal width');
$parsed = parse(source('(width 4)', '(clear-bit status 0)', 8));
($set) = grep {$_->[0] eq 'set'} @{$parsed->{transactions}[0]{clauses}};
is_deeply($set, ['set', 'status', ['&', 'status', 14]], 'narrow formal does not inherit actor mask');
$parsed = parse(source('', '(clear-bit status 0)', 8));
($set) = grep {$_->[0] eq 'set'} @{$parsed->{transactions}[0]{clauses}};
is_deeply($set, ['set', 'status', ['&', 'status', 0]], 'omitted formal width is genuinely one bit');
is(error(source('(width 8)', '(clear-bit status 7)', undef)), '', 'port-only width needs no actor declaration');

for my $declaration ('(width W)', '(width N)', '(type word_t)') {
    like(error(source($declaration, '(clear-bit status 0)', 8)), qr/statically known register width/,
        "$declaration stays unresolved and does not borrow actor width");
}
my $typed_actor = '(actor typed_bits (clock clk) (types (type word_t (bits 8))) '
    . '(interface (input start) (output value (type word_t)) (output done)) '
    . '(transaction main (on start) (set value 255) (clear-bit value 0) (complete done)))';
like(error($typed_actor), qr/statically known register width/, 'typed actor interface placeholder cannot produce a zero mask');
for my $body (
    '(when start (clear-bit status 7))', '(repeat 2 (clear-bit status 7))',
    '(while start (clear-bit status 7))', '(until start (clear-bit status 7))',
    '(switch start (0 (clear-bit status 7)) (default (clear-bit status 7)))',
) {
    is(error(source('(width 8)', $body, 4)), '', "nested formal operation: $body");
}

for my $generated (0, 1) {
    subtest $generated ? 'generated child shadows actor storage' : 'direct port-only execution' => sub {
        my $directory = "$workspace/case_$generated";
        mkdir $directory or die $!;
        my $owner_storage = $generated ? 'status' : 'actor_saved';
        my $name = $generated ? 'worker' : 'main';
        my $entry = $generated ? '' : '(on start)';
        my $copy = $generated ? '' : '(set seen status)';
        my $caller = $generated ? '(transaction parent (on start) (spawn worker as w0 (bind (output status seen))) (await_all done) (complete done))' : '';
        my $path = write_file("$directory/source.isf", <<"ISF");
(actor formal_bits
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (output seen (width 8)) (output owner_seen (width 4)) (output done))
 (storage (var $owner_storage (width 4) (reset 9)))
 (rule observe 1 (owner_seen $owner_storage))
 (transaction $name (ports (output status (width 8))) $entry
  (set status 255) (clear-bit status 7) (rotate-right status by 1)
  (set-field status (bits 3 1) 0)
  (when-bit status 7 (set status (+ status 2)))
  (when-field status (bits 3 1) 1 (set status (+ status 2)))
  (unless-bit status 6 (set status (+ status 2)))
  (unless-field status (bits 3 1) 0 (set status (+ status 2)))
  $copy (complete done))
 $caller)
ISF
        qualify_reports($path);
        my $actor = FSM::Adapter::ISF->new->parse_file($path);
        my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
        for my $file (sort keys %$files) {
            my $fsm = write_file("$directory/$file", $files->{$file});
            my $r = $capture->([$^X, 'bin/fsmgen', '--quiet', '--strict', '--check', '--json', $fsm], '');
            is($r->{exit_code}, 0, "$file strict replay") or diag($r->{stdout}, $r->{stderr});
        }
        my $hdl = "$directory/dut.sv";
        my $r = $capture->([$^X, 'bin/fsmgen', '--quiet', '--strict', '--output', $hdl, $path], '');
        is($r->{exit_code}, 0, 'production HDL generated') or diag($r->{stdout}, $r->{stderr});
        simulate($directory, $hdl, $generated ? 'formal_bits_top' : 'formal_bits');
    };
}
done_testing;

sub qualify_reports {
    my ($path) = @_;
    my $relative = File::Spec->abs2rel($path, $root);
    for my $query (
        ['check', [qw(--strict --check --json)], 'fsmgen_check'],
        ['semantic', [qw(--strict --emit-semantic-json)], 'fsmgen_semantic_introspect'],
        ['schedule', ['--emit-schedule-json'], 'fsmgen_schedule_preview'],
    ) {
        my ($kind, $flags, $tool) = @$query;
        my $native = $capture->([$^X, 'bin/fsmgen', @$flags, $relative], '');
        is($native->{exit_code}, 0, "native $kind passes") or diag($native->{stdout}, $native->{stderr});
        is($native->{stderr}, '', "native $kind stderr clean");
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
        my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call',
            params => {name => $tool, arguments => {source_id => $relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        is_deeply($response->{result}{structuredContent}{report}, $report, "complete native/API $kind parity");
        my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
        is($wire->{exit_code}, 0, "newline $kind exits successfully");
        is($wire->{stderr}, '', "newline $kind stderr clean");
        is_deeply($json->decode($wire->{stdout}), $response, "complete newline/API $kind parity");
    }
}
sub simulate {
    my ($directory, $hdl, $module) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 2
            unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $tb = write_file("$directory/tb.sv", <<"SV");
module tb;
 logic clk=0,rst_n=1,start=0;wire [7:0] seen;wire [3:0] owner_seen;wire done;
 always #5 clk=~clk;
 $module dut(.*);
 task tick; @(posedge clk); #1; endtask
 task run_once;
  @(negedge clk);start=1;tick;@(negedge clk);start=0;
  repeat(120) begin
   tick;
   if(done) begin
    if(seen!==8'd185 || owner_seen!==4'd9) \$fatal(1,"wrong formal/owner result: %0d/%0d",seen,owner_seen);
    repeat(5) tick;
    return;
   end
  end
  \$fatal(1,"completion timeout");
 endtask
 initial begin
  #2;rst_n=0;repeat(3) tick;@(negedge clk);rst_n=1;repeat(3) tick;
  run_once;run_once;
  @(negedge clk);start=1;tick;@(negedge clk);start=0;repeat(3) tick;
  @(negedge clk);rst_n=0;repeat(3) tick;@(negedge clk);rst_n=1;repeat(3) tick;
  run_once;
  \$display("FORMAL_BITS_PASS");\$finish;
 end
 initial begin #20000;\$fatal(1,"timeout");end
endmodule
SV
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', "$directory/obj", $hdl, $tb]);
        ok($compile->{ok}, 'production HDL compiles') or diag($compile->{stdout}, $compile->{stderr});
        if ($compile->{ok}) {
            my $run = run_generated_binary(["$directory/obj/Vtb"]);
            ok($run->{ok} && ($run->{stdout} // '') =~ /FORMAL_BITS_PASS/,
                'repeated and reset-aborted invocations preserve formal bit results and actor storage')
                or diag($run->{stdout}, $run->{stderr}, $run->{diagnostic});
        } else { fail('runtime unavailable after compile failure'); }
    }
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!;
    print {$fh} $text;
    close $fh or die $!;
    return $path;
}
