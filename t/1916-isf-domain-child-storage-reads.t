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
my $text=<<'ISF';
(actor domain_reads
 (clock-domains
  (domain core (clock clk) (reset (rst_n async active_low)) :default)
  (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))
 (types (type byte_t (signed (bits 8)))
        (type packet_t (record (inner (list (record (payload (bits 7)) (flag bit)))))))
 (interface (input start) (input write_core) (input data (width 8)) (input index)
  (output core_done) (output scalar_value (width 8)) (output typed_value (width 8))
  (output whole_value (width 8)) (output record_value (width 7)) (output bank_value (width 8))
  (input aux_start (domain aux)) (input write_aux (domain aux))
  (input aux_data (width 8) (domain aux)) (output aux_done (domain aux))
  (output aux_value (width 8) (domain aux)))
 (storage (var status (width 8) (reset 19)) (var typed (type byte_t) (reset 5))
  (var packet (type packet_t) (reset 21)) (bank slots (width 8) (depth 2))
  (var unused (width 7) (reset 3)) (var aux_status (width 8) (reset 7) (domain aux)))
 (rule core_write write_core (status data) (typed data) (packet data)
  (store slots 0 data) (store slots 1 (+ data 1)))
 (rule aux_write (domain aux) write_aux (aux_status aux_data))
 (transaction worker (ports (output scalar_result (width 8)) (output typed_result (width 8))
   (output whole_result (width 8)) (output record_result (width 7)) (output bank_result (width 8)))
  (wait 6) (set scalar_result status) (set typed_result typed)
  (set whole_result packet) (set record_result packet.inner[0].payload) (load slots index as bank_result) (complete done))
 (transaction aux_worker (domain aux) (ports (output aux_result (width 8)))
  (wait 6) (set aux_result aux_status) (complete done))
 (transaction parent (on start)
  (spawn worker as reader (bind (output scalar_result scalar_value) (output typed_result typed_value)
   (output whole_result whole_value) (output record_result record_value) (output bank_result bank_value)))
  (await_all done) (complete core_done))
 (transaction aux_parent (domain aux) (on aux_start)
  (spawn aux_worker as aux_reader (bind (output aux_result aux_value)))
  (await_all done) (complete aux_done)))
ISF
my $do = $text;
$do =~ s/\(transaction worker/\(transaction worker (params (MODE 0))/;
$do =~ s/\(spawn worker as reader/\(do worker (params (MODE 1))/;
$do =~ s/\(await_all done\) \(complete core_done\)/(complete core_done)/;
my $bound_do = $do;
$bound_do =~ s/\(transaction worker \(params \(MODE 0\)\) \(ports/(transaction worker (params (MODE 0)) (ports (input index)/;
$bound_do =~ s/\(do worker \(params \(MODE 1\)\) \(bind/(do worker (params (MODE 1)) (bind (input index (! index))/;
for my $case (['spawn',$text],['do',$do],['do_bound',$bound_do]) {
    my ($name,$text)=@$case;
    subtest $name => sub {
        my $work="$workspace/$name";mkdir $work or die $!;
        my $source=write_file("$work/source.isf",$text);
        my $actor=FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler=FSM::Scheduler::ISF->new;
        my $ir=$scheduler->{ir}->build_module($actor);
        for my $case (['worker',[qw(packet slots_0 slots_1 status typed)]],['aux_worker',['aux_status']]) {
            my ($name,$reads)=@$case;my $child=$ir->{children}{$name};
            is_deeply([map {$_->{name}} @{$child->{actor_storage_reads}}],$reads,"$name exact live reads");
            is_deeply($child->{declared_storage},[],"$name has no private actor state");
            ok(!exists $child->{reset_values}{$_},"$name does not reset $_") for @$reads;
        }
        is($ir->{children}{worker}{signal_type_refs}{packet},'packet_t','aggregate alias reaches child input');
        is($ir->{children}{worker}{signal_type_refs}{typed},'byte_t','signed scalar alias reaches child input');
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
                    [sort qw(clk rst_n aux_clk aux_rst_n start write_core data index aux_start write_aux aux_data)],'exact public inputs; storage stays private');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [sort qw(core_done scalar_value typed_value whole_value record_value bank_value aux_done aux_value)],'exact public outputs; handoffs stay private');
            }
        }
        my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
        my $tb=<<'SV';
module tb;
 logic clk=0,aux_clk=0,rst_n=1,aux_rst_n=1,run_core=1;
 logic start=0,aux_start=0,write_core=0,write_aux=0,index=1;
 logic [7:0] data=0,aux_data=0;
 wire core_done,aux_done;wire [7:0] scalar_value,typed_value,whole_value,bank_value,aux_value;
 wire [6:0] record_value;
 integer core_count=0,aux_count=0;
 always #5 if(run_core) clk=~clk;
 always #7 aux_clk=~aux_clk;
 always @(posedge clk) if(core_done) core_count++;
 always @(posedge aux_clk) if(aux_done) aux_count++;
 domain_reads_top dut(.*);
 task core_start;@(negedge clk);start=1;@(negedge clk);start=0;endtask
 task aux_launch;@(negedge aux_clk);aux_start=1;@(negedge aux_clk);aux_start=0;endtask
 task check_core(input integer scalar_expected,typed_expected,packet_expected,bank_expected);
  if(scalar_value!==scalar_expected || typed_value!==typed_expected || whole_value!==packet_expected || record_value!==(packet_expected>>1) || bank_value!==bank_expected)
   $fatal(1,"core live storage mismatch scalar=%d typed=%d record=%d bank=%d",scalar_value,typed_value,record_value,bank_value);
 endtask
 task paired(input bit update_values,input integer core_new,aux_new);
  integer core_target,aux_target;
  core_target=core_count+1;aux_target=aux_count+1;
  fork core_start();aux_launch();join
  if(update_values) begin
   // Update the owner after child activation, before its delayed read.
   @(negedge clk);data=core_new;write_core=1;@(negedge clk);write_core=0;
   @(negedge aux_clk);aux_data=aux_new;write_aux=1;@(negedge aux_clk);write_aux=0;
  end
  wait(core_count==core_target && aux_count==aux_target);#1;
  if(update_values) check_core(core_new,core_new,core_new,core_new+index);
  else check_core(19,5,21,0);
  if(aux_value!==(update_values ? aux_new : 7)) $fatal(1,"aux live storage mismatch");
  repeat(5) @(negedge clk);
 endtask
 initial begin
  integer target;
  #2;rst_n=0;aux_rst_n=0;#20;rst_n=1;aux_rst_n=1;
  paired(0,0,0);paired(1,91,166);index=0;paired(1,167,53);
  @(negedge clk);run_core=0;aux_rst_n=0;#2;aux_rst_n=1;
  target=aux_count+1;aux_launch();wait(aux_count==target);#1;
  check_core(167,167,167,167);
  if(aux_value!==7) $fatal(1,"aux reset ownership lost");
  rst_n=0;#2;if(aux_value!==7) $fatal(1,"core reset escaped its domain");
  rst_n=1;run_core=1;target=core_count+1;core_start();wait(core_count==target);#1;
  check_core(19,5,21,0);
  $display("DOMAIN_STORAGE_PASS");$finish;
 end
 initial begin #10000;$fatal(1,"domain storage completion timeout");end
endmodule
SV
        if ($name ne 'spawn') {
            # Generated-do payload bindings are valid during the child done
            # pulse, before the parent's later completion pulse. Sample there.
            $tb =~ s/integer core_count=0,aux_count=0;/integer core_count=0,aux_count=0,payload_count=0;
 logic [7:0] sampled_scalar,sampled_typed,sampled_whole,sampled_bank;
 logic [6:0] sampled_record;
 always @(posedge clk) if(scalar_value!=0) begin
  payload_count++;sampled_scalar=scalar_value;sampled_typed=typed_value;
  sampled_whole=whole_value;sampled_record=record_value;sampled_bank=bank_value;
 end/;
            $tb =~ s/scalar_value!==scalar_expected/sampled_scalar!==scalar_expected/;
            $tb =~ s/typed_value!==typed_expected/sampled_typed!==typed_expected/;
            $tb =~ s/whole_value!==packet_expected/sampled_whole!==packet_expected/;
            $tb =~ s/record_value!==\(packet_expected>>1\)/sampled_record!==(packet_expected>>1)/;
            $tb =~ s/bank_value!==bank_expected/sampled_bank!==bank_expected/;
            $tb =~ s/integer core_target,aux_target;/integer core_target,aux_target,payload_before;
  payload_before=payload_count;/;
            $tb =~ s/repeat\(5\) @\(negedge clk\);/repeat(5) @(negedge clk);
  if(payload_count!=payload_before+1) \$fatal(1,"generated do payload pulse count");/;
        }
        if ($name eq 'do_bound') {
            $tb =~ s/core_new\+index/core_new+(1-index)/;
            $tb =~ s/check_core\(167,167,167,167\)/check_core(167,167,167,168)/;
        }
        simulate($work,$hdl,$tb);
        for my $case (
            ['cross_read', '(set scalar_result aux_status)', qr/clock-domain violation: transaction 'worker'.*read signal 'aux_status' owned by domain 'aux' from domain 'core' without a crossing primitive/],
            ['writer', '(set status 37)', qr/parent writer and generated child writer/],
        ) {
            my ($name,$replacement,$error)=@$case;my $bad=$text;
            $bad =~ s/\(set scalar_result status\)/$replacement/;
            my $path=write_file("$work/$name.isf",$bad);
            my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
            isnt($r->{exit_code},0,"$name remains rejected");
            like($r->{stdout}.$r->{stderr},$error,"$name ownership diagnostic");
        }
    };
}
done_testing();
sub simulate {
    my ($work,$hdl,$tb)=@_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable',3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv=write_file("$work/dut.sv",$hdl);my $test=write_file("$work/tb.sv",$tb);my $obj="$work/obj";
        my $compile=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','--top-module','tb','--Mdir',$obj,$sv,$test]);
        ok($compile->{ok},'domain storage HDL compiles') or diag($compile->{diagnostic},$compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed');fail('observations absent'); }
        else {my $run=run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok},'live reads, repeated activation and owner reset pass') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout},qr/DOMAIN_STORAGE_PASS/,'independent domain storage observations complete');}
    }
}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path;}
