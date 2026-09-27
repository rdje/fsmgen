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
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $normalize = \&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
my $scheduler = FSM::Scheduler::ISF->new;
my %sources = (pin => <<'ISF', storage => <<'STORAGE');
(actor formal_shadow (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input payload (width 8)) (input data (width 4))
  (output observed (width 4)) (output done))
 (transaction main (ports (input payload (width 4))) (on start)
  (set payload data) (wait payload) (set observed payload) (complete done)))
ISF
(actor formal_shadow (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input data (width 4)) (output observed (width 4))
  (output stored (width 12)) (output done))
 (storage (var payload (width 12) (reset 291)))
 (transaction worker (ports (output seen (width 12))) (set seen payload) (complete done))
 (transaction main (ports (input payload (width 4))) (on start)
  (set payload data) (spawn worker as job (bind (output seen stored)))
  (await_all done) (wait payload) (set observed payload) (complete done)))
STORAGE

for my $kind (qw(pin storage)) {
    subtest "automatic physical scope preserves $kind ownership" => sub {
        my $dir = "$work/$kind"; mkdir $dir or die $!;
        my $path = write_file("$dir/source.isf", $sources{$kind});
        my $actor = FSM::Adapter::ISF->new->parse_source($sources{$kind}, $path);
        my $before = dclone($actor);
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
        my $formal = $context->{plan}{formals}{main}{payload}{physical_name};
        my $files = $scheduler->lower($actor)->{files};
        like($files->{'formal_shadow.fsm'}, qr/\(\Q$formal\E 4\)/, 'emitted private formal has its own width');
        my $report = $json->decode($scheduler->report($actor));
        my ($entry) = grep {$_->{name} eq $formal} @{$report->{inferred_storage}};
        is($entry->{role}, 'transaction_port', 'physical storage has formal ownership');
        is($entry->{width}, 4, 'physical report width belongs to formal');
        my ($wait) = grep {$_->{transaction} eq 'main'} @{$report->{transaction_waits}};
        is($wait->{count_source}, 'payload', 'public wait provenance retains the authored operand');
        is_deeply($actor, $before, 'production lowering/reporting leave source actor unchanged');
        for my $file (sort keys %$files) {write_file("$dir/$file", $files->{$file})}
        my $top = $kind eq 'storage' ? 'formal_shadow_top' : 'formal_shadow';
        my $strict = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$top.fsm"], '');
        is($strict->{exit_code}, 0, 'complete exported carrier strict-checks') or diag($strict->{stdout}, $strict->{stderr});
        my $relative = File::Spec->abs2rel($path, $root);
        for my $query (qw(check semantic schedule)) {
            my %flags = (check => [qw(--strict --check --json)], semantic => [qw(--strict --emit-semantic-json)], schedule => ['--emit-schedule-json']);
            my %methods = (check => 'fsmgen_check', semantic => 'fsmgen_semantic_introspect', schedule => 'fsmgen_schedule_preview');
            my $native = $capture->([$^X,'bin/fsmgen',@{$flags{$query}},$relative], '');
            is($native->{exit_code}, 0, "$query native succeeds") or diag($native->{stdout}, $native->{stderr});
            next if $native->{exit_code};
            my $expected = $normalize->($json->decode($native->{stdout}), $root);
            my $request = {jsonrpc => '2.0', id => 1, method => 'tools/call', params => {
                name => $methods{$query}, arguments => {source_id => $relative}}};
            my $response = $api->handle_jsonrpc_request($request);
            ok(!$response->{result}{isError}, "$query API succeeds");
            is_deeply($response->{result}{structuredContent}{report}, $expected, "$query entire native/API report agrees");
            my $wire = $capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'], $json->encode($request) . "\n");
            is($wire->{exit_code}, 0, "$query newline succeeds");
            is_deeply($json->decode($wire->{stdout}), $response, "$query entire newline/API response agrees");
        }
        subtest 'independent public-pin runtime' => sub {
            plan skip_all => 'qualified Verilator runtime unavailable'
                unless can_run('verilator') && darwin_verilator_runtime_qualified();
            my $extra_port = $kind eq 'pin' ? "logic [7:0] payload=8'hA5;" : 'wire [11:0] stored;';
            my $storage_check = $kind eq 'storage' ? 'if(stored!==12\'h123) $fatal(1,"actor storage changed through shadow");' : '';
            my $tb = write_file("$dir/tb.sv", <<SV);
module tb;
 logic clk=0, rst_n=1, start=0;
 logic [3:0] data=6;
 wire [3:0] observed; wire done;
 $extra_port
 integer completions=0;
 always #5 clk=~clk;
 always @(posedge clk) begin #1;if(rst_n && done) completions=completions+1;end
 $top dut(.*);
 initial begin
  #2;rst_n=0;#19;rst_n=1;
  @(negedge clk);start=1;@(negedge clk);start=0;
  wait(done===1);#2;
  if(observed!==4'd6 || completions!=1) \$fatal(1,"first private payload mismatch");
  $storage_check
  repeat(12) @(negedge clk);
  if(completions!=1) \$fatal(1,"activation replayed");
  rst_n=0;#19;rst_n=1;data=9;
  @(negedge clk);start=1;@(negedge clk);start=0;
  wait(done===1);#2;
  if(observed!==4'd9 || completions!=2) \$fatal(1,"reset/repeated private payload mismatch");
  $storage_check
  repeat(12) @(negedge clk);
  if(completions!=2) \$fatal(1,"repeated activation replayed");
  \$display("PRODUCTION_FORMAL_SCOPE_PASS");\$finish;
 end
 initial begin #20000;\$fatal(1,"formal scope timeout");end
endmodule
SV
            for my $language (qw(systemverilog verilog)) {
                my $hdl = "$dir/$language.sv";
                my $emit = $capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$path], '');
                is($emit->{exit_code}, 0, "$language HDL generation") or diag($emit->{stdout}, $emit->{stderr});
                next if $emit->{exit_code};
                my $obj = "$dir/obj_$language";
                my $compile = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','tb','--Mdir',$obj,$hdl,$tb]);
                ok($compile->{ok}, "$language oracle builds") or diag($compile->{diagnostic}, $compile->{stderr});
                next unless $compile->{ok};
                my $run = run_generated_binary(["$obj/Vtb"]);
                ok($run->{ok}, "$language public-pin oracle passes") or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
                like($run->{stdout}, qr/PRODUCTION_FORMAL_SCOPE_PASS/, "$language oracle completed");
            }
        };
    };
}

subtest 'automatic domain projection keeps widths and authored wait operands local' => sub {
    my $source = <<'ISF';
(actor scoped_domains
 (clock-domains (domain core (clock clk) (reset rst_n) :default)
               (domain aux (clock aux_clk) (reset aux_rst_n)))
 (interface (input start) (output done)
            (input aux_start (domain aux)) (output aux_done (domain aux)))
 (transaction main (ports (input payload (width 4)))
  (on start) (wait payload) (complete done))
 (transaction remote (domain aux) (ports (input payload (width 8)))
  (on aux_start) (wait payload) (complete aux_done)))
ISF
    my $actor = FSM::Adapter::ISF->new->parse_source($source, 'scoped_domains.isf');
    my $before = dclone($actor);
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $files = $scheduler->lower($actor)->{files};
    my $report = $json->decode($scheduler->report($actor));
    for my $case (['core','main',4], ['aux','remote',8]) {
        my ($domain,$tx,$width) = @$case;
        my $product = $context->{prepared}{domain_source_products}{$domain};
        my $physical = $context->{plan}{formals}{$tx}{payload}{physical_name};
        my $filename = $product->{domain}{scheduled_fsm};
        like($files->{$filename}, qr/\(\Q$physical\E $width\)/, "$domain owns the formal width");
        my $ir = $scheduler->{ir}->build_module(
            FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $product->{preparation}{actor})->{actor});
        my $view = FSM::Scheduler::ISF::FormalLowering->report_ir($context, $ir, $domain);
        my ($wait) = grep {exists $_->{wait_count_source}} @{$view->{states}};
        is($wait->{wait_count_source}, 'payload', "$domain source wait operand restored");
    }
    is_deeply($actor, $before, 'automatic multi-domain preparation leaves authored input unchanged');
    my $dir = "$work/domains"; mkdir $dir or die $!;
    for my $file (sort keys %$files) {write_file("$dir/$file", $files->{$file})}
    my $strict = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/scoped_domains_top.fsm"], '');
    is($strict->{exit_code}, 0, 'automatic domains exported top strict-checks') or diag($strict->{stdout}, $strict->{stderr});
};

subtest 'production coverage rejects a late undeclared helper before emission' => sub {
    my $actor = FSM::Adapter::ISF->new->parse_source($sources{pin}, 'late_helper.isf');
    my $build = \&FSM::Scheduler::ISF::LoweringIR::build_module;
    my $emitted = 0;
    no warnings 'redefine';
    local *FSM::Scheduler::ISF::LoweringIR::build_module = sub {
        my $ir = $build->(@_); $ir->{counters}{late_unreserved_helper} = 1; return $ir;
    };
    local *FSM::Scheduler::ISF::Emitter::FSM::emit = sub {$emitted++; die "emitted before coverage\n"};
    my $ok = eval {$scheduler->lower($actor); 1};
    ok(!$ok, 'injected final declaration is refused');
    like($@, qr/unreserved declarations:.*late_unreserved_helper/, 'actual production guard reports missing reservation');
    is($emitted, 0, 'no scheduled carrier emitted before the guard');
};

done_testing();
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!; return $path;
}
