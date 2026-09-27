#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use IPC::Cmd qw(can_run);
use JSON::PP;
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::ProcessSupervisor qw(supervise_process);
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Pipeline::HDLGenerator;

my $work = tempdir(CLEANUP => 1);
my $root = abs_path('.');
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root => $root, workspace_root => $root);
sub source {
    my ($kind, $name) = @_;
    my $decl = $kind eq 'bank' ? "(bank $name (width 4) (depth 2))" : "($kind $name (width 4) (reset 3))";
    my $read = $kind eq 'bank' ? "(store $name 1 3) (load $name 1 as observed)" : "(set observed $name)";
    return "(actor storage_identifier (clock clk) (reset rst_n)\n"
        . "(interface (input fire) (output done) (output observed (width 4)))\n"
        . "(storage $decl) (transaction read_value (on fire) $read (complete done)))\n";
}
sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die $!; print {$fh} $text; close $fh or die $!;
    return $path;
}
subtest 'actor variables reject target keywords with source-specific guidance' => sub {
    for my $kind (qw(var variable)) {
        for my $case (['cell','SystemVerilog'], ['logic','SystemVerilog'], ['process','VHDL'], ['PROCESS','VHDL'], ['and','SystemVerilog and VHDL']) {
            my ($name, $targets) = @$case;
            eval {FSM::Adapter::ISF->new->parse_source(source($kind,$name), 'keyword.isf')};
            like($@, qr/actor 'storage_identifier' storage variable '\Q$name\E' is reserved in \Q$targets\E;/, "$kind $name identifies actor and reserving target");
            like($@, qr/choose a non-keyword simple identifier/, 'rename guidance is explicit');
        }
    }
    for my $name (qw(value_reg Cell CELL)) {
        my $a = FSM::Adapter::ISF->new->parse_source(source('var',$name), 'legal.isf');
        is($a->{storage}[0]{signals}[0]{name}, $name, 'legal spelling and SystemVerilog case sensitivity preserved');
    }
    for my $name (qw(cell process)) {
        my $a = FSM::Adapter::ISF->new->parse_source(source('bank',$name), 'bank.isf');
        is($a->{storage}[0]{name}, $name, 'logical keyword bank identity retained');
        is_deeply([map {$_->{name}} @{$a->{storage}[0]{signals}}], ["${name}_0","${name}_1"], 'actual bank elements remain legal suffixed signals');
    }
};
subtest 'native API and newline routes retain complete classified failures' => sub {
    my $path = 't/corpus/isf_storage_identifier.isf';
    for my $strict (0,1) {
        my $r = $capture->([$^X,'bin/fsmgen',($strict ? '--strict' : ()),'--check','--json',$path], '');
        is($r->{exit_code}, 1, 'keyword fails before HDL in default and strict mode');
        my $report = $json->decode($r->{stdout});
        is($report->{diagnostics}[0]{code}, 'FSMGEN_LANGUAGE_ISF_STORAGE_IDENTIFIER', 'stable language diagnostic');
        like($report->{diagnostics}[0]{message}, qr/storage variable 'cell' is reserved in SystemVerilog/, 'precise authored failure preserved');
    }
    for my $query (['check',[qw(--strict --check --json)],'fsmgen_check'],
                   ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
                   ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview']) {
        my ($kind,$flags,$tool) = @$query;
        my $native = $capture->([$^X,'bin/fsmgen',@$flags,$path], '');
        isnt($native->{exit_code}, 0, "$kind rejects keyword source");
        my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,arguments=>{source_id=>$path}}};
        my $response = $api->handle_jsonrpc_request($request);
        if ($kind eq 'schedule') {
            is($native->{stdout}, '', 'failed schedule emits no success report');
            like($native->{stderr}, qr/storage variable 'cell' is reserved in SystemVerilog/, 'native schedule retains precise reason');
            is_deeply($response->{error}, {code=>-32000,
                message=>'FSMGen command failed without a matching public failure report'},
                'schedule retains its documented message-only failure contract');
        } else {
            is($native->{stderr}, '', 'structured failure keeps stderr empty');
            my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}), $root);
            ok($response->{result}{isError}, 'adapter marks tool failure');
            is_deeply($response->{result}{structuredContent}{report}, $report, 'complete native/API failure agreement');
        }
        my $wire = $capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'], $json->encode($request)."\n");
        is($wire->{exit_code}, 0, 'newline transport succeeds for tool failure');
        is($wire->{stderr}, '', 'newline failure keeps stderr empty');
        is_deeply($json->decode($wire->{stdout}), $response, 'complete newline/API failure agreement');
    }
};
subtest 'legal variable and keyword-bank controls compile independently' => sub {
    for my $case (['var','value_reg'], ['var','Cell'], ['bank','cell'], ['bank','process']) {
        my ($kind,$name) = @$case;
        my $dir = "$work/${kind}_$name"; mkdir $dir or die $!;
        my $path = write_file("$dir/source.isf", source($kind,$name));
        for my $language (qw(systemverilog verilog vhdl)) {
            my $hdl = FSM::Pipeline::HDLGenerator->new(quiet=>1,target_language=>$language)->generate_hdl_from_file($path)->{hdl_code};
            ok(length($hdl), "$kind $name emits $language");
            if ($language eq 'vhdl') {
                SKIP: {
                    skip 'GHDL unavailable', 1 unless can_run('ghdl');
                    my $file = write_file("$dir/dut.vhd", $hdl);
                    my $result = supervise_process(schema=>'fsmgen.test.storage_identifier.v1',stage=>'ghdl',
                        bounds=>{timeout_seconds=>60,capture_limit_bytes=>1_048_576},containment=>'test_runtime_process_group',
                        cwd=>$dir,argv=>['ghdl','-a','--std=08',File::Spec->rel2abs($file)]);
                    ok($result->{ok}, 'independent VHDL analysis accepts legal names') or diag($result->{diagnostic},$result->{stdout},$result->{stderr});
                }
            } else {
                SKIP: {
                    skip 'Verilator unavailable', 1 unless can_run('verilator');
                    my $file = write_file("$dir/$language.sv", $hdl);
                    my $result = supervise_process(schema=>'fsmgen.test.storage_identifier.v1',stage=>'verilator_lint',cwd=>$root,
                        bounds=>{timeout_seconds=>60,capture_limit_bytes=>1_048_576},containment=>'test_runtime_process_group',
                        argv=>['verilator','--lint-only','-Wno-fatal','--top-module','storage_identifier',
                            '--Mdir',"$dir/obj_$language",$file]);
                    ok($result->{ok}, 'independent Verilog-family analysis accepts legal names') or diag($result->{diagnostic},$result->{stderr});
                }
            }
        }
    }
};
done_testing;
