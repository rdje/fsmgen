#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use File::Copy qw(copy);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $base = <<'ISF';
(actor composed_activation
 (clock-domains
  (domain core (clock clk) (reset (rst_n async active_low)) :default)
  (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))
 (interface (input start) (output core_done) (output local_seen) (output aux_seen (domain aux)))
 (crossings (activation remote (from core) (to aux)))
 (transaction worker (wait 1) (complete local_seen))
 (transaction parent (on start) (spawn worker as job) (await_all done) (do remote) (complete core_done))
 (transaction remote (domain aux) (wait 2) (complete aux_seen)))
ISF
my $both = $base;
$both =~ s/\(transaction remote/(transaction aux_worker (domain aux) (wait 1) (complete done)) (transaction remote/;
$both =~ s/\(transaction remote \(domain aux\) \(wait 2\)/(transaction remote (domain aux) (spawn aux_worker as aux_job) (await_all done) (wait 2)/;
open my $fifo, '<', 'isf/fifo_library_use.isf' or die $!;
my $library = do {local $/; <$fifo>}; close $fifo or die $!;
$library =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
$library =~ s/\(interface/(interface (input start) (output core_done) (output aux_seen (domain aux))/;
$library =~ s/\)\s*\z/ (crossings (activation remote (from core) (to aux))) (transaction parent (on start) (do remote) (complete core_done)) (transaction remote (domain aux) (wait 2) (complete aux_seen)))/;

for my $case (['caller', $base], ['both', $both], ['library', $library]) {
    my ($label, $text) = @$case;
    subtest "$label explicit activation boundaries remain wired" => sub {
        my $dir = "$work/$label"; mkdir $dir or die $!;
        if ($label eq 'library') {
            mkdir "$dir/common" or die $!;
            copy('isf/common/fifo.isf', "$dir/common/fifo.isf") or die $!;
        }
        my $source = write_file("$dir/source.isf", $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $files = $scheduler->lower($actor)->{files};
        my $top = $files->{"$actor->{actor_name}_top.fsm"};
        for my $edge (
            'core.remote_start remote_activation_start_cdc.request',
            'remote_activation_done_cdc.pulse core.remote_done',
            'remote_activation_start_cdc.ready core.remote_start_ready',
            'remote_activation_start_cdc.pulse aux.remote_start',
            'aux.remote_done remote_activation_done_cdc.request',
            'remote_activation_done_cdc.ready aux.remote_done_ready',
        ) {
            my $count = () = $top =~ /\(\Q$edge\E\)/g;
            is($count, 1, "$edge has exactly its declared route");
        }
        my ($ports) = $top =~ /\(\?ports:public_io\s+([^()]*)\)/s;
        unlike($ports, qr/\b(?:remote_(?:start|done)(?:_ready)?|job_(?:start|done)|aux_job_(?:start|done))\b/,
            'activation and local child handoffs never become public top ports');
        for my $file (sort keys %$files) {write_file("$dir/$file", $files->{$file})}
        my $strict = $capture->([$^X, 'bin/fsmgen', '--strict', '--check', '--json', "$dir/$actor->{actor_name}_top.fsm"], '');
        is($strict->{exit_code}, 0, 'complete exported top strict-checks') or diag($strict->{stdout}, $strict->{stderr});
        my $relative = File::Spec->abs2rel($source, $root);
        for my $kind (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %methods = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $native = $capture->([$^X, 'bin/fsmgen', @{$flags{$kind}}, $relative], '');
            is($native->{exit_code}, 0, "$kind native source query succeeds") or diag($native->{stdout}, $native->{stderr});
            next if $native->{exit_code};
            my $report = $normalize->($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $methods{$kind}, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{result}{isError}, "$kind adapter succeeds");
            is_deeply($response->{result}{structuredContent}{report}, $report, "$kind entire native/API report agrees");
            my $wire = $capture->([$^X, 'bin/fsmgen-mcp', '--workspace-root', '.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, "$kind newline MCP succeeds");
            is_deeply($json->decode($wire->{stdout}), $response, "$kind entire newline/API response agrees");
        }
        if ($label ne 'library') {
            subtest 'independent stopped-clock and repeated-activation oracle' => sub {
                plan skip_all => 'qualified Verilator runtime unavailable'
                    unless can_run('verilator') && darwin_verilator_runtime_qualified();
                my $tb = write_file("$dir/tb.sv", <<'SV');
module tb;
 logic clk=0, aux_clk=0, run_aux=0, rst_n=1, aux_rst_n=1, start=0;
 wire core_done, local_seen, aux_seen;
 integer local_count=0, aux_count=0, done_count=0;
 always #5 clk=~clk;
 always #7 if(run_aux) aux_clk=~aux_clk;
 always @(posedge clk) begin
  #1;
  if(rst_n) begin
   if(local_seen) local_count=local_count+1;
   if(core_done) done_count=done_count+1;
  end
 end
 always @(posedge aux_clk) begin
  #1;if(aux_rst_n && aux_seen) aux_count=aux_count+1;
 end
 composed_activation_top dut(.*);
 initial begin
  #2;rst_n=0;aux_rst_n=0;#19;rst_n=1;aux_rst_n=1;
  @(negedge clk);start=1;@(negedge clk);start=0;
  repeat(25) @(negedge clk);
  if(local_count!=1 || aux_count!=0 || done_count!=0)
   $fatal(1,"stopped aux clock did not retain activation ownership");
  run_aux=1;wait(core_done===1);#2;
  if(local_count!=1 || aux_count!=1 || done_count!=1)
   $fatal(1,"first activation did not cross and return exactly once");
  repeat(20) @(negedge clk);
  if(local_count!=1 || aux_count!=1 || done_count!=1) $fatal(1,"activation replayed");
  rst_n=0;aux_rst_n=0;#19;rst_n=1;aux_rst_n=1;
  @(negedge clk);start=1;@(negedge clk);start=0;
  wait(core_done===1);#2;
  if(local_count!=2 || aux_count!=2 || done_count!=2)
   $fatal(1,"reset and repeated activation lost exact event counts");
  repeat(20) @(negedge clk);
  if(local_count!=2 || aux_count!=2 || done_count!=2) $fatal(1,"second activation replayed");
  $display("COMPOSED_ACTIVATION_PASS");$finish;
 end
 initial begin #20000;$fatal(1,"composed activation timeout");end
endmodule
SV
                for my $language (qw(systemverilog verilog)) {
                    my $hdl = "$dir/$language.sv";
                    my $emit = $capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$source], '');
                    is($emit->{exit_code}, 0, "$language public HDL generation") or diag($emit->{stdout}, $emit->{stderr});
                    next if $emit->{exit_code};
                    my $obj = "$dir/obj_$language";
                    my $compile = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal',
                        '-j','1','--top-module','tb','--Mdir',$obj,$hdl,$tb]);
                    ok($compile->{ok}, "$language independent oracle builds") or diag($compile->{diagnostic}, $compile->{stderr});
                    next unless $compile->{ok};
                    my $run = run_generated_binary(["$obj/Vtb"]);
                    ok($run->{ok}, "$language independent activation oracle passes") or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
                    like($run->{stdout}, qr/COMPOSED_ACTIVATION_PASS/, "$language oracle completes all observations");
                }
            };
        }
    };
}
done_testing;
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!; return $path;
}
