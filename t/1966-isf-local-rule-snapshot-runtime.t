#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $root = abs_path('.');
my $work = tempdir(CLEANUP=>1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $runtime = can_run('verilator') && darwin_verilator_runtime_qualified();
sub read_file {open my $fh,'<',$_[0] or die $!; my $s=do {local $/;<$fh>};close $fh;return $s}
sub write_file {open my $fh,'>',$_[0] or die $!;print {$fh} $_[1];close $fh or die $!;return $_[0]}
my $source = read_file('t/data/isf_local_rule_snapshot_runtime.isf');
my $tb = read_file('t/data/isf_local_rule_snapshot_runtime_tb.sv');
sub compile {
    my ($path,$testbench,$language,$dir) = @_;
    my $hdl = "$dir/design.sv";
    my $emit = $capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$path], '');
    is($emit->{exit_code},0,"$language production emission") or diag($emit->{stdout},$emit->{stderr});
    return if $emit->{exit_code};
    my $obj = "$dir/obj";
    my $build = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','tb','--Mdir',$obj,$hdl,$testbench]);
    ok($build->{ok},"$language public-pin testbench builds") or diag($build->{diagnostic},$build->{stderr});
    return $build->{ok} ? "$obj/Vtb" : undef;
}
sub reports {
    my ($path) = @_;
    my $relative = File::Spec->abs2rel($path,$root);
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $query (
        ['check',[qw(--strict --check --json)],'fsmgen_check'],
        ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview'],
    ) {
        my ($label,$flags,$method) = @$query;
        my $native = $capture->([$^X,'bin/fsmgen',@$flags,$relative], '');
        is($native->{exit_code},0,"$label native succeeds") or diag($native->{stdout},$native->{stderr});
        next if $native->{exit_code};
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
        my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$method,arguments=>{source_id=>$relative}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError},"$label API succeeds");
        is_deeply($response->{result}{structuredContent}{report},$report,"$label complete native/API agreement");
        my $wire = $capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$label newline succeeds");
        is_deeply($json->decode($wire->{stdout}),$response,"$label complete API/newline agreement");
        if ($label eq 'semantic') {
            is_deeply([sort map {$_->{name}} @{$report->{semantic}{forward_ir}{structural_rtl_ir}{ports}}],
                [sort qw(clk rst_n request_a request_b allow proceed data_a data_b early observed done)],
                'exact public interface contains no snapshot or formal helper');
        }
    }
    my $actor = FSM::Adapter::ISF->new->parse_source(read_file($path),$path);
    my $files = FSM::Scheduler::ISF->new->lower($actor)->{files};
    my $carrier = write_file("$path.fsm",$files->{'snapshot_runtime.fsm'});
    my $r = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',$carrier],'');
    is($r->{exit_code},0,'exported public carrier strict-replays') or diag($r->{stdout},$r->{stderr});
}
for my $arbiter (qw(priority round_robin)) {
    subtest "$arbiter accepted-payload invocation lifecycle" => sub {
        my $dir = "$work/$arbiter"; mkdir $dir or die $!;
        my $variant = $source;
        if ($arbiter eq 'round_robin') {
            $variant =~ s/\(arbiter priority\)/(arbiter round_robin)/;
            $variant =~ s/\s*\(priority first over second\)//;
        }
        my $path = write_file("$dir/source.isf",$variant);
        my $testbench = write_file("$dir/tb.sv",$tb);
        reports($path);
        subtest 'independent public-pin runtime' => sub {
            plan skip_all=>'qualified Verilator runtime unavailable' unless $runtime;
            for my $language (qw(systemverilog verilog)) {
                my $run_dir = "$dir/$language"; mkdir $run_dir or die $!;
                my $binary = compile($path,$testbench,$language,$run_dir) || next;
                my $run = run_generated_binary([$binary,$arbiter eq 'round_robin' ? '+ROUND_ROBIN' : ()]);
                ok($run->{ok},"$language invocation lifecycle passes") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
                for my $checkpoint (qw(CHANGED_INPUT REPEATED_SOURCE REJECTED_ENTRY BUSY_LATER_ENTRY RESET_ABORT HELD_LEVEL GRANTED_SOURCES)) {
                    like($run->{stdout},qr/SNAPSHOT_${checkpoint}_PASS/,"$language $checkpoint completed");
                }
                like($run->{stdout},qr/LOCAL_RULE_SNAPSHOT_RUNTIME_PASS/,"$language whole oracle completed");
            }
        };
    };
}
subtest 'ungranted overlap remains a conflict, never an implicit winner' => sub {
    plan skip_all=>'qualified Verilator runtime unavailable' unless $runtime;
    my $dir = "$work/overlap"; mkdir $dir or die $!;
    my $variant = $source;
    $variant =~ s/\s*\(resources[^\n]*\)//;
    $variant =~ s/\s*\(priority first over second\)//;
    my $path = write_file("$dir/source.isf",$variant);
    my $overlap_tb = <<'SV';
module tb;
 logic clk=0,rst_n=1,request_a=0,request_b=0,allow=1,proceed=1;
 logic [3:0] data_a=4,data_b=14; wire [3:0] early,observed; wire done;
 snapshot_runtime dut(.*); always #5 clk=~clk;
 initial begin
  #2;rst_n=0;#19;rst_n=1;
  @(negedge clk);request_a=1;request_b=1;
  repeat(5) @(negedge clk);
  $display("UNGRANTED_OVERLAP_ESCAPED");$finish;
 end
endmodule
SV
    my $testbench = write_file("$dir/tb.sv",$overlap_tb);
    my $binary = compile($path,$testbench,'systemverilog',$dir) || return;
    my $run = run_generated_binary([$binary]);
    ok(!$run->{ok},'simultaneous ungranted sources fail');
    like($run->{stdout}.$run->{stderr},qr/selector multi-value conflict: isf_(?:port|snapshot)_worker_payload/,
        'the actual payload selector detects the overlap');
    unlike($run->{stdout},qr/UNGRANTED_OVERLAP_ESCAPED/,'cannot complete by selecting a declaration-order winner');
};
subtest 'an unguarded local target still free-runs without rule requests' => sub {
    plan skip_all=>'qualified Verilator runtime unavailable' unless $runtime;
    my $dir = "$work/unguarded"; mkdir $dir or die $!;
    my $ungated = <<'ISF';
(actor ungated (clock clk) (reset (rst_n async active_low))
 (interface (input request) (input data (width 4)) (output observed (width 4)) (output done))
 (transaction worker (ports (input payload (width 4)))
  (set observed payload) (wait 3) (complete done))
 (rule fire request (trigger worker (bind (input payload data)))))
ISF
    my $path = write_file("$dir/source.isf",$ungated);
    my $testbench = write_file("$dir/tb.sv", <<'SV');
module tb;
 logic clk=0,rst_n=1,request=0; logic [3:0] data=7;
 wire [3:0] observed; wire done; integer completions=0;
 ungated dut(.*); always #5 clk=~clk;
 always @(posedge clk) begin #1;if(rst_n && done) completions++;end
 initial begin
  #2;rst_n=0;#19;rst_n=1;
  repeat(40) @(negedge clk);
  if(completions<2) $fatal(1,"rule target acquired an implicit entry guard");
  $display("LOCAL_RULE_UNGUARDED_PASS");$finish;
 end
endmodule
SV
    for my $language (qw(systemverilog verilog)) {
        my $run_dir = "$dir/$language"; mkdir $run_dir or die $!;
        my $binary = compile($path,$testbench,$language,$run_dir) || next;
        my $run = run_generated_binary([$binary]);
        ok($run->{ok},"$language unguarded target free-runs") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
        like($run->{stdout},qr/LOCAL_RULE_UNGUARDED_PASS/,"$language unguarded oracle completed");
    }
};
subtest 'generated do remains a live handoff for both emitted Verilog families' => sub {
    plan skip_all=>'qualified Verilator runtime unavailable' unless $runtime;
    my $audit = $json->decode(read_file('docs/audits/direct-controller-binding-timing-20260927.json'));
    my ($case) = grep {$_->{case_id} eq 'generated_live'} @{$audit->{cases}};
    is(sha256_hex($case->{source}),$case->{source_sha256},'canonical live source authenticated');
    is(sha256_hex($case->{testbench}),$case->{testbench_sha256},'independent live oracle authenticated');
    my $dir = "$work/live"; mkdir $dir or die $!;
    my $path = write_file("$dir/source.isf",$case->{source});
    my $testbench = write_file("$dir/tb.sv",$case->{testbench});
    for my $language (qw(systemverilog verilog)) {
        my $run_dir = "$dir/$language"; mkdir $run_dir or die $!;
        my $binary = compile($path,$testbench,$language,$run_dir) || next;
        for my $change (0,1) {
            my $run = run_generated_binary([$binary,$change ? '+CHANGE' : ()]);
            ok($run->{ok},"$language live changed=$change passes") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            my $expected = $change ? 13 : 7;
            like($run->{stdout},qr/BINDING_OBSERVED value=$expected completions=1 expected=$expected/,
                "$language observes actual live value $expected once");
            like($run->{stdout},qr/BINDING_PASS/,"$language live oracle completed");
        }
    }
};
done_testing();
