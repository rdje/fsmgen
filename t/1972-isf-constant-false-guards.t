#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $source='t/data/isf_constant_false_guards.isf';
my $scheduler=FSM::Scheduler::ISF->new;
my $actor=FSM::Adapter::ISF->new->parse_file($source);
my $ir=$scheduler->{ir}->build_module($actor);
my $work=tempdir(CLEANUP=>1);
my $capture=\&FSM::Test::SourceQueryRunner::_capture;
my $json=JSON::PP->new;
sub read_file {open my $fh,'<',$_[0] or die $!;local $/;return <$fh>}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path}

subtest 'admitted false rule and inline-sample entry guards survive emission' => sub {
    my $before=dclone($ir);
    my ($rule)=grep {$_->{name} eq 'never'} @{$ir->{dt_blocks}};
    is_deeply($rule->{dte_guard},{port=>'0'},'lowering retains false rule predicate');
    is_deeply($ir->{states}[0]{guard},{port=>'0'},'lowering retains false entry predicate');
    my $fsm=$scheduler->{fsm_emitter}->emit($ir);
    like($fsm,qr/\(-never < \(!= 0 0\)\s+\(<- \(disabled> 5\)\)/,'false rule enable remains in actual carrier');
    like($fsm,qr/\(<= \(captured> data\) < \(!= 0 0\)\)/,'false inline sample guard remains in carrier');
    like($fsm,qr/\(< \(!= 0 0\)\s+\(-> main_set_1\)/,'false entry transition remains conditional');
    like($fsm,qr/\(= \(can_accept 1\)\)/,'unguarded entry bookkeeping stays unguarded');
    like($fsm,qr/\(-always\s+\(<- \(enabled> 6\)\)/,'true rule keeps its existing unconditional carrier');
    like($fsm,qr/\(-requested <allow/,'symbolic guard remains intact');
    is_deeply($ir,$before,'emission does not alter lowering records');
    my $expr=dclone($ir);$expr->{states}[0]{transitions}[0]{condition}={expr=>'0'};
    like($scheduler->{fsm_emitter}->emit($expr),qr/\(-> main_set_1 < \(!= 0 0\)\)/,'explicit expression zero also survives transition emission');
    my $grouped=dclone($ir);
    my ($always)=grep {$_->{name} eq 'always'} @{$grouped->{dt_blocks}};
    $always->{assignments}[0]{guard}={port=>'0'};
    my $grouped_fsm=$scheduler->{fsm_emitter}->emit($grouped);
    like($grouped_fsm,qr/\(-always\s+\(< \(!= 0 0\)\s+\(<- \(enabled> 6\)\)/,'numeric rule assignment group uses unambiguous expression syntax');
    my $grouped_path=write_file("$work/grouped.fsm",$grouped_fsm);
    my $grouped_check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$grouped_path],'');
    is($grouped_check->{exit_code},0,'false rule assignment group strict-checks') or diag($grouped_check->{stdout},$grouped_check->{stderr});
    for my $case ([{port=>'0'},' < (!= 0 0)'],[{expr=>'0'},' < (!= 0 0)'],[{port=>'1'},''],[{port=>'allow'},' <allow'],[undef,''],[{},'']) {
        is(FSM::Scheduler::ISF::Emitter::FSM::_format_guard_suffix($case->[0]),$case->[1],'guard presence is independent of Perl truthiness');
    }
};

subtest 'false, true and symbolic guards execute correctly through both HDL targets' => sub {
    plan skip_all=>'qualified Verilator runtime unavailable' unless can_run('verilator') && darwin_verilator_runtime_qualified();
    for my $entry (0,1) {
        my $text=read_file($source);$text=~s/\(when 0 \(sample/\(when $entry \(sample/;
        my $dir="$work/entry_$entry";mkdir $dir or die $!;
        my $path=write_file("$dir/source.isf",$text);
        my $captured=$entry ? 42 : 0;my $observed=$entry ? 9 : 0;
        my $tb=write_file("$dir/tb.sv",<<SV);
module tb;
 logic clk=0,rst_n=1,allow=0;logic [7:0] data=42;
 wire [7:0] disabled,enabled,symbolic,captured,observed;
 constant_false_guards dut(.*);always #5 clk=~clk;
 initial begin
  #2;rst_n=0;#19;rst_n=1;
  repeat(5) @(negedge clk);
  \$display("GUARD_VALUES disabled=%0d enabled=%0d symbolic=%0d captured=%0d observed=%0d",disabled,enabled,symbolic,captured,observed);
  if(disabled!==0 || enabled!==6 || symbolic!==0 || captured!==$captured || observed!==$observed) \$fatal(1,"constant or entry guard violated");
  allow=1;repeat(2) @(negedge clk);
  if(symbolic!==7 || disabled!==0) \$fatal(1,"symbolic/false rule control violated");
  // The register-in sample exposes its entry bypass even during reset.
  rst_n=0;#1;
  if(disabled!==0 || enabled!==0 || symbolic!==0 || captured!==$captured || observed!==0) \$fatal(1,"reset control violated");
  allow=0;rst_n=1;repeat(5) @(negedge clk);
  if(disabled!==0 || enabled!==6 || symbolic!==0 || captured!==$captured || observed!==$observed) \$fatal(1,"repeated guard control violated");
  \$display("CONSTANT_GUARDS_PASS");\$finish;
 end
endmodule
SV
        for my $language (qw(systemverilog verilog)) {
            my $hdl=write_file("$dir/design_$language.sv",'');
            my $emit=$capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$path],'');
            is($emit->{exit_code},0,"$language entry=$entry production emission") or diag($emit->{stdout},$emit->{stderr});
            next if $emit->{exit_code};
            my $obj="$dir/obj_$language";
            my $build=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','tb','--Mdir',$obj,$hdl,$tb]);
            ok($build->{ok},"$language entry=$entry public-pin testbench builds") or diag($build->{diagnostic},$build->{stderr});
            next unless $build->{ok};
            my $run=run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok},"$language entry=$entry runtime respects guards") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout},qr/CONSTANT_GUARDS_PASS/,"$language entry=$entry completes independent oracle");
        }
    }
};

subtest 'complete native/API/newline reports and strict carrier replay agree' => sub {
    my $root=abs_path('.');my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    my $files=$scheduler->lower($actor)->{files};
    my $carrier=write_file("$work/constant_false_guards.fsm",$files->{'constant_false_guards.fsm'});
    my $check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$carrier],'');
    is($check->{exit_code},0,'corrected carrier strict-checks') or diag($check->{stdout},$check->{stderr});
    my $grouped=dclone($ir);
    my ($always)=grep {$_->{name} eq 'always'} @{$grouped->{dt_blocks}};
    $always->{assignments}[0]{guard}={port=>'0'};
    my $grouped_fsm=$scheduler->{fsm_emitter}->emit($grouped);
    like($grouped_fsm,qr/\(-always\s+\(< \(!= 0 0\)\s+\(<- \(enabled> 6\)\)/,'numeric rule assignment group uses unambiguous expression syntax');
    my $grouped_path=write_file("$work/grouped.fsm",$grouped_fsm);
    my $grouped_check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$grouped_path],'');
    is($grouped_check->{exit_code},0,'false rule assignment group strict-checks') or diag($grouped_check->{stdout},$grouped_check->{stderr});
    for my $case (
        [[qw(--strict --check --json)],'fsmgen_check'],
        [[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [['--emit-schedule-json'],'fsmgen_schedule_preview'],
    ) {
        my ($flags,$method)=@$case;
        my $native=$capture->([$^X,'bin/fsmgen',@$flags,$source],'');
        is($native->{exit_code},0,"$method native succeeds") or diag($native->{stdout},$native->{stderr});
        next if $native->{exit_code};
        my $expected=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$method,arguments=>{source_id=>$source}}};
        my $response=$api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError},"$method API succeeds");
        is_deeply($response->{result}{structuredContent}{report},$expected,"$method complete native/API agreement");
        my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$method newline succeeds");
        is_deeply($json->decode($wire->{stdout}),$response,"$method complete API/newline agreement");
    }
};
done_testing();
