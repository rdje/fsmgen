#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Copy qw(copy);
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
my $base = do { open my $fh, '<', 'isf/fifo_library_use.isf' or die $!; local $/; <$fh> };
my $observed = $base;
$observed =~ s/\(interface/(interface (output echo (width 8)) (output seen (width 8)) (output saw_empty) (output saw_full)/;
$observed =~ s/\)\s*\z/ (rule observe 1 (echo data_in) (seen data_out) (saw_empty empty) (saw_full full)))/;
my $typed = $observed;
$typed =~ s/\(interface/(types (type byte_t (bits 8))) (interface/;
$typed =~ s/\(output data_out \(width 8\)\)/(output data_out (type byte_t))/;
my $domains = $observed;
$domains =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
$domains =~ s/\(interface/(interface (input aux_data (width 8) (domain aux)) (output aux_seen (width 8) (domain aux))/;
$domains =~ s/\)\s*\z/ (rule aux_tick (domain aux) 1 (aux_seen aux_data)))/;
for my $case (['fifo',$base,0,0],['observed',$observed,1,0],['typed',$typed,1,0],['domains',$domains,1,1]) {
    my ($name,$text,$observe,$domain) = @$case;
    subtest $name => sub {
        my $dir = "$work/$name"; mkdir $dir or die $!; mkdir "$dir/common" or die $!;
        copy('isf/common/fifo.isf', "$dir/common/fifo.isf") or die $!;
        my $source = write_file("$dir/source.isf", $text);
        my $actor = FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler = FSM::Scheduler::ISF->new;
        my $ir = $scheduler->{ir}->build_module($actor);
        my %public = map {$_->{name} => $_} @{$ir->{ports}};
        my %component = map {$_->{name} => $_} @{$ir->{explicit_interface_ports}};
        for my $signal (qw(full empty data_out)) {
            is($public{$signal}{direction}, 'output', 'schedule retains authored output direction');
            is($component{$signal}{direction}, 'input', 'parent component has only a readback input');
            ok(!exists $ir->{reset_values}{$signal}, 'parent has no reset writer for child-owned output');
        }
        is($ir->{signal_type_refs}{data_out}, 'byte_t', 'readback preserves authored type alias') if $name eq 'typed';
        my $files = $scheduler->lower($actor)->{files};
        write_file("$dir/$_", $files->{$_}) for sort keys %$files;
        for my $file (sort keys %$files) {
            my $check = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$file"], '');
            is($check->{exit_code},0,"$file strict scheduled replay") or diag($check->{stdout},$check->{stderr});
        }
        my $relative = File::Spec->abs2rel($source,$root);
        for my $query (['check',[qw(--strict --check --json)],'fsmgen_check'],
                       ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
                       ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview']) {
            my ($kind,$flags,$tool)=@$query;
            my $native=$capture->([$^X,'bin/fsmgen',@$flags,$relative],'');
            is($native->{exit_code},0,"native $kind accepted") or diag($native->{stdout},$native->{stderr});
            my $report=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
            my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,arguments=>{source_id=>$relative}}};
            my $response=$api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report},$report,"complete native/API $kind parity");
            my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
            is_deeply($json->decode($wire->{stdout}),$response,"complete newline/API $kind parity");
            if ($kind eq 'semantic') {
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
                    [sort qw(clk rst_n write_req read_req data_in), ($domain ? qw(aux_clk aux_rst_n aux_data) : ())],
                    'exact public inputs with no readback leakage');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [sort qw(full empty data_out), ($observe ? qw(echo seen saw_empty saw_full) : ()), ($domain ? 'aux_seen' : ())],
                    'exact authored public outputs');
            }
        }
        my $extra = $observe ? 'wire [7:0] echo,seen;wire saw_empty,saw_full;' : '';
        $extra .= 'logic aux_clk=0,aux_rst_n=1;logic [7:0] aux_data=42;wire [7:0] aux_seen;always #7 aux_clk=~aux_clk;' if $domain;
        my $reset_aux = $domain ? 'aux_rst_n=0;' : '';
        my $release_aux = $domain ? 'aux_rst_n=1;' : '';
        my $observe_check = $observe ? 'if(echo!==payload || seen!==old_data || saw_empty!==old_empty || saw_full!==old_full) $fatal(1,"parent input/readback mismatch");' : '';
        my $isolation = $domain ? 'run_core=0;aux_data=19;repeat(3) @(negedge aux_clk);if(aux_seen!==19) $fatal(1,"aux clock depended on FIFO clock");rst_n=0;#1;if(aux_seen!==19) $fatal(1,"FIFO reset escaped its domain");run_core=1;' : '';
        my $tb = <<"SV";
module tb;
 logic clk=0,rst_n=1,run_core=1,write_req=0,read_req=0;
 logic [7:0] data_in=0;
 wire [7:0] data_out;wire full,empty;
 $extra
 byte unsigned queue_data[\$];
 logic [7:0] expected_data=0;
 logic expected_empty=0,expected_full=0;
 always #5 if(run_core) clk=~clk;
 fifo_library_use_top dut(.*);
 task automatic step(input bit wr,input bit rd,input byte unsigned payload);
  integer before_count;
  logic [7:0] old_data;logic old_empty,old_full;
  @(negedge clk);write_req=wr;read_req=rd;data_in=payload;
  before_count=queue_data.size();old_data=expected_data;old_empty=expected_empty;old_full=expected_full;
  if(rd && before_count>0) expected_data=queue_data.pop_front();
  if(wr && (before_count<4 || rd)) queue_data.push_back(payload);
  expected_empty=(queue_data.size()==0);expected_full=(queue_data.size()==4);
  @(posedge clk);#1;
  if(data_out!==expected_data || empty!==expected_empty || full!==expected_full)
   \$fatal(1,"FIFO mismatch wr=%d rd=%d size=%d data=%d expected=%d empty=%d full=%d",wr,rd,queue_data.size(),data_out,expected_data,empty,full);
  $observe_check
 endtask
 task automatic reset_core;
  @(negedge clk);write_req=0;read_req=0;rst_n=0;#1;
  if(data_out!==0 || full!==0 || empty!==0) \$fatal(1,"FIFO default reset mismatch");
  queue_data.delete();expected_data=0;expected_empty=0;expected_full=0;
  @(negedge clk);rst_n=1;
  @(posedge clk);#1;expected_empty=1;
  if(empty!==1 || full!==0 || data_out!==0) \$fatal(1,"FIFO idle state after reset mismatch");
 endtask
 initial begin
  #2;$reset_aux
  reset_core();$release_aux
  repeat(2) begin
   step(0,0,0);
   step(1,0,11);step(1,0,22);step(1,0,33);step(1,0,44);
   step(1,0,99);step(1,1,55);step(0,1,0);step(0,1,0);step(0,1,0);step(0,1,0);
   step(1,1,66);step(0,1,0);step(0,1,0);
   for(integer i=0;i<32;i=i+1) step((i%3)!=0,(i%5)!=0,i+80);
   reset_core();
  end
  $isolation
  \$display("LIBRARY_PARENT_PASS");\$finish;
 end
 initial begin #20000;\$fatal(1,"FIFO ownership timeout");end
endmodule
SV
        my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($dir,$hdl,$tb);
    };
}
subtest 'competing output owners are rejected' => sub {
    my $dir="$work/refused";mkdir $dir or die $!;mkdir "$dir/common" or die $!;
    copy('isf/common/fifo.isf',"$dir/common/fifo.isf") or die $!;
    for my $case (['writer','(rule competing 1 (full 1))',qr/Library-owned output 'full' also has a parent writer/],
                  ['reset','',qr/Library-owned output 'full' cannot have a parent reset or default/],
                  ['default','',qr/Library-owned output 'full' cannot have a parent reset or default/]) {
        my ($name,$body,$error)=@$case;
        my $text=$base;
        $text =~ s/\)\s*\z/ $body)/;
        $text =~ s/\(output full\)/(output full ($name 0))/ if $name ne 'writer';
        my $source=write_file("$dir/$name.isf",$text);
        my $check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$source],'');
        isnt($check->{exit_code},0,"$name cannot introduce a second owner");
        like($check->{stdout}.$check->{stderr},$error,"$name ownership diagnosis is explicit");
    }
};
subtest 'library ownership also excludes generated completion and duplicate children' => sub {
    my $dir="$work/owners";mkdir $dir or die $!;mkdir "$dir/common" or die $!;
    copy('isf/common/fifo.isf',"$dir/common/fifo.isf") or die $!;
    my $completion=$base;
    $completion =~ s/\(interface/(interface (input start) (output done)/;
    $completion =~ s/\)\s*\z/ (transaction worker (complete full)) (transaction parent (on start) (spawn worker as w0) (await_all done) (complete done)))/;
    my $duplicate=$base;
    $duplicate =~ s/\)\s*\z/ (use fifo_lib.fifo as second_fifo (bind (clock clk) (reset rst_n) (input write_req write_req) (input data_in data_in) (input read_req read_req) (output full full) (output empty empty) (output data_out data_out))))/;
    for my $case (['completion',$completion,qr/Library-owned output 'full' also has a parent writer/],
                  ['duplicate',$duplicate,qr/Library output 'full' is driven by both 'u_fifo' and 'second_fifo'/]) {
        my ($name,$text,$error)=@$case;
        my $source=write_file("$dir/$name.isf",$text);
        my $check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$source],'');
        isnt($check->{exit_code},0,"$name has no invented arbitration");
        like($check->{stdout}.$check->{stderr},$error,"$name preserves sole output ownership");
    }
};
subtest 'nondefault library system bindings remain owned by .48' => sub {
    my $dir="$work/nondefault";mkdir $dir or die $!;mkdir "$dir/common" or die $!;
    copy('isf/common/fifo.isf',"$dir/common/fifo.isf") or die $!;
    my $text=$base;
    $text =~ s/\(clock clk\)\s*\(reset \(rst_n async active_low\)\)/(clock-domains (domain idle (clock aux_clk) (reset (aux_rst_n async active_low)) :default) (domain fifo (clock clk) (reset (rst_n async active_low))))/;
    $text =~ s/(\((?:input|output) \w+(?: \(width \d+\))?)\)/$1 (domain fifo))/g;
    $text =~ s/\(use fifo_lib.fifo as u_fifo/(use fifo_lib.fifo as u_fifo (domain fifo)/;
    my $source=write_file("$dir/source.isf",$text);
    my $check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$source],'');
    isnt($check->{exit_code},0,'unqualified nondefault-domain binding is not called successful');
    like($check->{stdout},qr/clock binding references unknown parent signal 'clk'/,
        'retain the exact parser omission for the immediate next repair');
};
done_testing();
sub simulate {
    my ($dir, $hdl, $tb) = @_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable', 3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv = write_file("$dir/dut.sv", $hdl); my $test = write_file("$dir/tb.sv", $tb); my $obj = "$dir/obj";
        my $compile = run_verilator_compile(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
            '--top-module', 'tb', '--Mdir', $obj, $sv, $test]);
        ok($compile->{ok}, 'independent library-parent HDL compile') or diag($compile->{diagnostic}, $compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed'); fail('runtime observation absent'); }
        else {
            my $run = run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok}, 'FIFO ownership, readback and reset pass') or diag($run->{diagnostic}, $run->{stdout}, $run->{stderr});
            like($run->{stdout}, qr/LIBRARY_PARENT_PASS/, 'independent library-parent observations complete');
        }
    }
}
sub write_file { my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path; }
