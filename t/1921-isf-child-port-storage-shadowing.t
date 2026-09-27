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
for my $name (qw(input output typed_input typed_output domain_input domain_output generated_do_input generated_do_output bank_input trigger_input trigger_output)) {
 subtest $name => sub {
  my $dir="$workspace/$name";mkdir $dir or die $!;
  my $output=$name =~ /output$/;
  my $domain=$name =~ /^domain_/;
  my $generated_do=$name =~ /^generated_do_/;
  my $trigger=$name =~ /^trigger_/;
  my $bank=$name eq 'bank_input';
  my $signal=$bank ? 'slots_0' : 'status';
  my $type=$name =~ /^typed_/ ? '(type local_t)' : '(width 4)';
  my $owner_reset=$bank ? 0 : 19;
  my $timing=$domain
   ? '(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst async active_high))))'
   : '(clock clk) (reset (rst_n async active_low))';
  my $owner_domain=$domain ? '(domain aux)' : '';
  my $storage=$bank ? '(bank slots (width 8) (depth 2))' : "(var status (type owner_t) (reset 19) $owner_domain)";
  my $ports=$output ? "(output $signal $type)" : "(input $signal $type) (output result (width 4))";
  my $assignment=$output ? "(set $signal data)" : "(set result $signal)";
  my $bindings=$output ? "(output $signal child_seen)" : "(input $signal data) (output result child_seen)";
  my $completion=$trigger ? 'finished' : 'done';
  if ($trigger) {
   $ports.=' (output finished)';
   $bindings.=' (output finished done)';
   if ($output) {
    $ports.=' (input payload (width 4))';
    $bindings.=' (input payload data)';
    $assignment="(set $signal payload)";
   }
  }
  my $activation=$generated_do ? "(do worker (params (MODE 1)) (bind $bindings))"
                              : "(spawn worker as w0 (bind $bindings)) (await_all done)";
  my $params=($generated_do || $trigger) ? '(params (MODE 0))' : '';
  my $caller=$trigger
   ? "(rule activate start (trigger worker (params (MODE 1)) (bind $bindings)))"
   : "(transaction parent (on start) $activation (complete done))";
  my $source=write_file("$dir/source.isf",<<"ISF");
(actor child_shadow
 $timing
 (types (type owner_t (signed (bits 8))) (type local_t (signed (bits 4))))
 (interface (input start) (input data (width 4)) (output child_seen (width 4)) (output done)
  (input owner_we $owner_domain) (input owner_data (width 8) $owner_domain)
  (output owner_seen (width 8) $owner_domain))
 (storage $storage)
 (rule observe $owner_domain 1 (owner_seen $signal))
 (rule owner_write $owner_domain owner_we ($signal owner_data))
 (transaction worker $params (ports $ports) (wait 2) $assignment (complete $completion))
 $caller)
ISF
  my $actor=FSM::Adapter::ISF->new->parse_file($source);
  my $scheduler=FSM::Scheduler::ISF->new;
  my $ir=$scheduler->{ir}->build_module($actor);
  my $child=$ir->{children}{worker};
  is_deeply($child->{actor_storage_reads},[],'local name does not request an actor storage read');
  is_deeply($child->{actor_storage_writes},[],'local output does not request an actor storage write');
  is_deeply($child->{declared_storage},[],'child does not copy actor storage');
  is($child->{signal_widths}{$signal},4,'local width wins over actor width');
  is($child->{storage_roles}{$signal},'transaction_port','local port role survives cleanup');
  is($child->{signal_type_refs}{$signal},$name =~ /^typed_/ ? 'local_t' : undef,'local type is independent of actor type');
  ok(!exists($child->{reset_values}{$signal}),'actor reset does not leak into the local port');
  my ($port)=grep {$_->{name} eq $signal} @{$child->{ports}};
  is($port->{direction},$output ? 'output' : 'input','local direction is retained');
  my $files=$scheduler->lower($actor)->{files};
  for my $file (sort keys %$files) {
   my $path=write_file("$dir/$file",$files->{$file});
   my $result=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
   is($result->{exit_code},0,"$file strict replay") or diag($result->{stdout},$result->{stderr});
  }
  my $relative=File::Spec->abs2rel($source,$root);
  for my $query (['check',[qw(--strict --check --json)],'fsmgen_check'],
                 ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
                 ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview']) {
   my ($kind,$flags,$tool)=@$query;
   my $native=$capture->([$^X,'bin/fsmgen',@$flags,$relative],'');
   is($native->{exit_code},0,"native $kind succeeds") or diag($native->{stdout},$native->{stderr});
   my $report=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
   my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tool,arguments=>{source_id=>$relative}}};
   my $response=$api->handle_jsonrpc_request($request);
   is_deeply($response->{result}{structuredContent}{report},$report,"complete native/API $kind parity");
   my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
   is_deeply($json->decode($wire->{stdout}),$response,"complete newline/API $kind parity") or diag($wire->{stdout},$wire->{stderr});
   if ($kind eq 'semantic') {
    is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{inputs}}],
     [sort qw(clk rst_n start data owner_we owner_data),($domain ? qw(aux_clk aux_rst) : ())],'exact public inputs');
    is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
     [qw(child_seen done owner_seen)],'exact public outputs');
   }
  }
  my $owner_clock=$domain ? 'aux_clk' : 'clk';
  my $extra=$domain ? 'logic aux_clk=0,aux_rst=0;always #7 aux_clk=~aux_clk;' : '';
  my $initial_reset=$domain ? 'aux_rst=1;' : '';
  my $release_reset=$domain ? 'aux_rst=0;' : '';
  my $independent_reset=$domain ? <<'SV' : '';
  aux_rst=1;#1;if(child_seen!==13) $fatal(1,"owner reset changed local child output");
  aux_rst=0;repeat(2) @(negedge aux_clk);
  if(owner_seen!==19) $fatal(1,"owner reset value lost");
  write_owner(91);
SV
  my $owner_after_core_reset=$domain ? 91 : $owner_reset;
  my $activate_data=$trigger ? 'data=payload' : 'data=3';
  my $later_data=$trigger ? 'data=3' : 'data=payload';
  # Generated call outputs are completion-qualified buses. All exercised payloads
  # are nonzero; observe their valid window instead of requiring an idle hold.
  my $result_check=($generated_do || $trigger) ? 'seen_payload' : '(child_seen===payload)';
  my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
  simulate($dir,$hdl,<<"SV");
module tb;
 logic clk=0,rst_n=1,start=0,owner_we=0;
 logic [3:0] data=0;logic [7:0] owner_data=0;
 wire [3:0] child_seen;wire [7:0] owner_seen;wire done;
 $extra
 always #5 clk=~clk;
 child_shadow_top dut(.*);
 task write_owner(input integer value);
  @(negedge $owner_clock);owner_we=1;owner_data=value;
  @(negedge $owner_clock);owner_we=0;
  repeat(2) @(negedge $owner_clock);
  if(owner_seen!==value) \$fatal(1,"actor register update lost");
 endtask
 task activate(input integer payload);
  integer pulses;bit seen_payload;
  pulses=0;seen_payload=0;
  @(negedge clk);$activate_data;start=1;
  @(negedge clk);start=0;$later_data;
  for(integer cycle=0;cycle<18;cycle++) begin
   @(posedge clk);#1;if(done) pulses++;
   if(child_seen===payload) seen_payload=1;
   @(negedge clk);
  end
  if(pulses!=1 || !($result_check)) \$fatal(1,"local payload/completion lost: payload=%d seen=%d pulses=%d",payload,child_seen,pulses);
 endtask
 initial begin
  #2;rst_n=0;$initial_reset
  #20;rst_n=1;$release_reset
  repeat(3) @(negedge $owner_clock);
  if(child_seen!==0 || owner_seen!==$owner_reset) \$fatal(1,"local/actor reset identities merged");
  write_owner(53);activate(7);
  if(owner_seen!==53) \$fatal(1,"local child write changed actor storage");
  write_owner(91);activate(13);
  if(owner_seen!==91) \$fatal(1,"repeated local call changed actor storage");
  $independent_reset
  rst_n=0;#1;if(child_seen!==0) \$fatal(1,"local reset lost");
  rst_n=1;repeat(3) @(negedge $owner_clock);
  if(owner_seen!==$owner_after_core_reset) \$fatal(1,"core reset changed wrong owner");
  activate(5);
  \$display("CHILD_SHADOW_PASS");\$finish;
 end
 initial begin #10000;\$fatal(1,"shadowing timeout");end
endmodule
SV
 };
}
done_testing();
sub simulate {
 my ($dir,$hdl,$tb)=@_;
 SKIP: {
  skip 'qualified Verilator runtime unavailable',3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
  my $sv=write_file("$dir/dut.sv",$hdl);my $test=write_file("$dir/tb.sv",$tb);my $obj="$dir/obj";
  my $compile=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','--top-module','tb','--Mdir',$obj,$sv,$test]);
  ok($compile->{ok},'independent child shadowing HDL compiles') or diag($compile->{diagnostic},$compile->{stderr});
  if (!$compile->{ok}) {fail('runtime compilation failed');fail('runtime observations absent');}
  else {my $run=run_generated_binary(["$obj/Vtb"]);
   ok($run->{ok},'local payload and actor register remain independent') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
   like($run->{stdout},qr/CHILD_SHADOW_PASS/,'runtime observations complete');}
 }
}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path;}
