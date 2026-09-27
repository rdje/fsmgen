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

my $workspace=tempdir(CLEANUP=>1);
my $root=abs_path('.');
my $capture=\&FSM::Test::SourceQueryRunner::_capture;
my $json=JSON::PP->new->canonical;
my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
my $base=<<'ISF';
(actor edge_writer
 (clock clk) (reset (rst_n async active_low))
 (interface (input start) (input enable) (input data (width 8))
  (output done) (output observed (width 8)) (output child_seen (width 8)))
 (storage (var status (width 8) (reset 19)) (var unused (width 7) (reset 3)))
 (rule watch 1 (observed status))
 (transaction worker (ports (output result (width 8)))
  (wait 2) (when enable (set status data)) (set result status) (complete done))
 (transaction parent (on start)
  (spawn worker as w0 (bind (output result child_seen))) (await_all done) (complete done)))
ISF
for my $name (qw(scalar typed default_reset read_modify named_domain collision field_metadata generated_do two_scalars)) {
    subtest $name => sub {
        my $work="$workspace/$name";mkdir $work or die $!;
        my $text=$base;
        if ($name eq 'typed') {
            $text =~ s/\(storage/(types (type byte_t (signed (bits 8)))) (storage/;
            $text =~ s/\(var status \(width 8\)/(var status (type byte_t)/;
        }
        $text =~ s/ \(reset 19\)// if $name eq 'default_reset';
        $text =~ s/\(set status data\)/(update status (+ status data))/ if $name eq 'read_modify';
        $text =~ s/\(clock clk\) \(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low))))/ if $name eq 'named_domain';
        $text =~ s/\(interface/(interface (input w0_isf_write_status_data (width 8))/ if $name eq 'collision';
        if ($name eq 'field_metadata') {
            $text =~ s/\(var status \(width 8\) \(reset 19\)\)/(var status (width 8) (reset 19) (fields (field value (bits 7 0) (access rw))))/;
        }
        if ($name eq 'generated_do') {
            $text =~ s/\(transaction worker/(transaction worker (params (MODE 0))/;
            $text =~ s/\(spawn worker as w0/(do worker (params (MODE 1))/;
            $text =~ s/\(await_all done\) //;
        }
        if ($name eq 'two_scalars') {
            $text =~ s/\(output done\)/(output extra (width 7)) (output done)/;
            $text =~ s/\(observed status\)/(observed status) (extra unused)/;
            $text =~ s/\(set status data\)/(set status data) (set unused (\& data 127))/;
        }
        my $source=write_file("$work/source.isf",$text);
        my $actor=FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler=FSM::Scheduler::ISF->new;
        my $ir=$scheduler->{ir}->build_module($actor);
        my $child=$ir->{children}{worker};
        is_deeply([map {$_->{name}} @{$child->{actor_storage_writes}}],[$name eq 'two_scalars' ? qw(status unused) : 'status'],'exact scalar writer ownership');
        is_deeply($child->{declared_storage},[],'child does not keep a private actor register');
        ok(!exists $child->{reset_values}{status},'child has no independent actor reset');
        my ($write)=@{$child->{actor_storage_writes}};
        my %ports=map {$_->{name}=>$_} @{$child->{ports}};
        is($ports{$write->{data_port}}{direction},'output','child emits write data');
        is($ports{$write->{enable_port}}{width},1,'write enable has one bit');
        is($ports{status}{direction},'input','child reads the same owner state live');
        if ($name eq 'typed') {
            is($child->{signal_type_refs}{$write->{data_port}},'byte_t','write data retains signed scalar alias');
        }
        my $files=$scheduler->lower($actor)->{files};
        for my $file (sort keys %$files) {
            my $path=write_file("$work/$file",$files->{$file});
            my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
            is($r->{exit_code},0,"$file strict replay") or diag($r->{stdout},$r->{stderr});
        }
        my $relative=File::Spec->abs2rel($source,$root);
        for my $query (['check',[qw(--strict --check --json)],'fsmgen_check'],
                       ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
                       ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview']) {
            my ($kind,$flags,$tool)=@$query;
            my $native=$capture->([$^X,'bin/fsmgen',@$flags,$relative],'');
            is($native->{exit_code},0,"native $kind") or diag($native->{stdout},$native->{stderr});
            my $report=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
            my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,arguments=>{source_id=>$relative}}};
            my $response=$api->handle_jsonrpc_request($request);
            is_deeply($response->{result}{structuredContent}{report},$report,"complete native/API $kind parity");
            my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
            is_deeply($json->decode($wire->{stdout}),$response,"complete newline/API $kind parity");
            if ($kind eq 'semantic') {
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
                    [sort qw(clk rst_n start enable data),($name eq 'collision' ? 'w0_isf_write_status_data' : ())], 'no public storage or write handoff inputs');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [sort qw(done observed child_seen),($name eq 'two_scalars' ? 'extra' : ())],'exact authored outputs');
            }
        }
        my $initial=$name eq 'default_reset' ? 0 : 19;
        my $next=$name eq 'read_modify' ? '(expected+payload)&255' : 'payload';
        my $extra=$name eq 'collision' ? 'logic [7:0] w0_isf_write_status_data=0;' : '';
        $extra='wire [6:0] extra;integer expected_extra=3;' if $name eq 'two_scalars';
        my $child_check=$name eq 'generated_do' ? 'sampled_seen' : 'child_seen';
        my $monitor=$name eq 'generated_do' ? 'logic [7:0] sampled_seen; always @(posedge clk) if(child_seen!=0) sampled_seen=child_seen;' : '';
        my $extra_check=$name eq 'two_scalars' ? 'if(extra!==((cycle>=7 && do_write) ? (payload&127) : expected_extra)) $fatal(1,"second scalar original edge");' : '';
        my $extra_update=$name eq 'two_scalars' ? 'if(do_write) expected_extra=payload&127;' : '';
        my $extra_reset=$name eq 'two_scalars' ? 'expected_extra=3;' : '';
        my $tb=<<"SV";
module tb;
 logic clk=0,rst_n=1,start=0,enable=0;logic [7:0] data=0;
 wire done;wire [7:0] observed,child_seen;$extra
 integer expected=$initial;
 $monitor
 always #5 clk=~clk;
 edge_writer_top dut(.*);
 task activate(input bit do_write,input integer payload);
  integer next_value,pulses;
  next_value=do_write ? $next : expected;pulses=0;
  @(negedge clk);start=1;enable=do_write;data=3;
  for(integer cycle=0;cycle<16;cycle++) begin
   @(posedge clk);#1;
   // Two wait states and a conditional branch put the child write on edge 5.
   // The parent's sequential observer sees that write on edge 6.
   if(observed!==((cycle>=6) ? next_value : expected))
    \$fatal(1,"original-edge mismatch cycle=%d observed=%d before=%d after=%d",cycle,observed,expected,next_value);
   $extra_check
   if(done) pulses++;
   @(negedge clk);start=0;
   if(cycle==4) data=payload; // Live data just before the write, no payload register.
  end
  if($child_check!==next_value || pulses!=1) \$fatal(1,"shared readback or completion mismatch");
  expected=next_value;$extra_update
 endtask
 task reset_owner;
  @(negedge clk);rst_n=0;#1;
  if(observed!==0 || child_seen!==0) \$fatal(1,"output reset mismatch");
  @(negedge clk);rst_n=1;repeat(2) @(negedge clk);expected=$initial;$extra_reset
  if(observed!==expected) \$fatal(1,"owner scalar reset mismatch");
 endtask
 initial begin
  reset_owner();activate(0,99);activate(1,37);activate(1,229);activate(0,77);
  reset_owner();activate(1,71);
  \$display("SCALAR_WRITE_PASS");\$finish;
 end
 initial begin #10000;\$fatal(1,"scalar writer timeout");end
endmodule
SV
        my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($work,$hdl,$tb);
    };
}
subtest 'retained original 19-to-37 defect' => sub {
    open my $fh,'<','docs/audits/generated-child-storage-ownership-20260926.json' or die $!;
    my $audit=$json->decode(do {local $/;<$fh>});close $fh;
    my ($writer)=grep {$_->{name} eq 'writer'} @{$audit->{cases}};
    my $work="$workspace/retained";mkdir $work or die $!;
    my $source=write_file("$work/source.isf",$writer->{source}{text});
    my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
    simulate($work,$hdl,<<'SV');
module tb;
 logic clk=0,rst_n=1,start=0;wire done;wire [7:0] observed;
 always #5 clk=~clk;
 child_storage_writer_top dut(.*);
 initial begin
  #2;rst_n=0;#10;rst_n=1;
  repeat(2) begin
   @(negedge clk);start=1;@(negedge clk);start=0;wait(done);#1;
   if(observed!==37) $fatal(1,"retained writer left owner unchanged");
   repeat(5) @(negedge clk);
  end
  $display("SCALAR_WRITE_PASS");$finish;
 end
 initial begin #3000;$fatal(1,"retained writer timeout");end
endmodule
SV
};
subtest 'unqualified writers remain rejected' => sub {
    my $parent=$base;$parent =~ s/\)\s*\z/ (rule competing enable (status data)))/;
    my $multiple=$base;$multiple =~ s/\(await_all done\)/(spawn worker as w1 (bind (output result child_seen))) (await_all done)/;
    my $aggregate=$base;$aggregate =~ s/\(storage/(types (type rec_t (record (payload (bits 8))))) (storage/;
    $aggregate =~ s/\(var status \(width 8\)/(var status (type rec_t)/;
    my $domains=$base;$domains =~ s/\(clock clk\) \(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk)))/;
    my $bank=$base;$bank =~ s/\(storage/(storage (bank slots (width 8) (depth 2))/;
    $bank =~ s/\(set status data\)/(store slots 1 data)/;
    for my $case (['parent',$parent,qr/parent writer and generated child writer/],
                  ['multiple',$multiple,qr/competing generated child writers/],
                  ['aggregate',$aggregate,qr/only full-width scalar sequential writes are qualified/],
                  ['bank',$bank,qr/only full-width scalar sequential writes are qualified/],
                  ['domains',$domains,qr/multi-domain actor require qualified domain writer handoffs/]) {
        my ($name,$text,$error)=@$case;my $path=write_file("$workspace/$name.isf",$text);
        my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
        isnt($r->{exit_code},0,"$name refused");like($r->{stdout}.$r->{stderr},$error,"$name exact ownership boundary");
    }
};
done_testing();
sub simulate {
    my ($work,$hdl,$tb)=@_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable',3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv=write_file("$work/dut.sv",$hdl);my $test=write_file("$work/tb.sv",$tb);my $obj="$work/obj";
        my $compile=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','--top-module','tb','--Mdir',$obj,$sv,$test]);
        ok($compile->{ok},'scalar write HDL compiles') or diag($compile->{diagnostic},$compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed');fail('observations absent'); }
        else {my $run=run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok},'owner write edge, reset and readback pass') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout},qr/SCALAR_WRITE_PASS/,'independent scalar write observations complete');}
    }
}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path;}
