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
(actor domain_writes
 (clock-domains
  (domain core (clock core_clk) (reset (core_rst_n async active_low)) :default)
  (domain aux (clock aux_clk) (reset (aux_rst sync active_high))))
 (interface
  (input core_start (domain core)) (input core_enable (domain core))
  (input core_data (width 8) (domain core)) (output core_done (domain core))
  (output core_seen (width 8) (domain core))
  (input aux_start (domain aux)) (input aux_enable (domain aux))
  (input aux_data (width 8) (domain aux)) (output aux_done (domain aux))
  (output aux_seen (width 8) (domain aux)))
 (storage (var core_status (width 8) (reset 19) (domain core))
          (var aux_status (width 8) (reset 7) (domain aux)))
 (rule core_watch (domain core) 1 (core_seen core_status))
 (rule aux_watch (domain aux) 1 (aux_seen aux_status))
 (transaction core_worker (domain core)
  (wait 2) (when core_enable (set core_status (+ core_status core_data))
    (wait 2) (set core_status (+ core_status 1))) (complete done))
 (transaction aux_worker (domain aux)
  (wait 2) (when aux_enable (set aux_status (+ aux_status aux_data))
    (wait 2) (set aux_status (+ aux_status 1))) (complete done))
 (transaction core_parent (domain core) (on core_start)
  (spawn core_worker as core_writer) (await_all done) (complete core_done))
 (transaction aux_parent (domain aux) (on aux_start)
  (spawn aux_worker as aux_writer) (await_all done) (complete aux_done)))
ISF
for my $name (qw(spawn generated_do typed_aux_default)) {
    subtest $name => sub {
        my $work="$workspace/$name";mkdir $work or die $!;
        my $text=$base;
        if ($name eq 'generated_do') {
            $text =~ s/(\(transaction (?:core|aux)_worker \(domain \w+\))/$1 (params (MODE 0))/g;
            $text =~ s/\(spawn (\w+) as \w+\)/(do $1 (params (MODE 1)))/g;
            $text =~ s/\(await_all done\) //g;
        }
        if ($name eq 'typed_aux_default') {
            $text =~ s/ :default//;
            $text =~ s/(\(domain aux \(clock aux_clk\) \(reset \(aux_rst sync active_high\)\))\)/$1 :default)/;
            $text =~ s/\(storage/(types (type byte_t (signed (bits 8)))) (storage/;
            $text =~ s/(\(var \w+_status) \(width 8\)/$1 (type byte_t)/g;
        }
        my $source=write_file("$work/source.isf",$text);
        my $actor=FSM::Adapter::ISF->new->parse_file($source);
        my $scheduler=FSM::Scheduler::ISF->new;
        my $ir=$scheduler->{ir}->build_module($actor);
        for my $domain (qw(core aux)) {
            my $child=$ir->{children}{"${domain}_worker"};
            is_deeply([map {$_->{name}} @{$child->{actor_storage_writes}}],["${domain}_status"],"$domain writes only its own scalar");
            is_deeply([map {$_->{name}} @{$child->{actor_storage_reads}}],["${domain}_status"],"$domain reads its live owner for repeated updates");
            is_deeply($child->{declared_storage},[],"$domain child has no actor register copy");
            ok(!exists $child->{reset_values}{"${domain}_status"},"$domain reset remains with owner");
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
                    [sort qw(core_clk core_rst_n aux_clk aux_rst core_start core_enable core_data aux_start aux_enable aux_data)],'exact public inputs; all storage and handoffs remain private');
                is_deeply([sort map {$_->{name}} @{$report->{semantic}{signal_analysis}{outputs}}],
                    [sort qw(core_done core_seen aux_done aux_seen)],'exact authored outputs');
            }
        }
        my $tasks=join "\n",map { activation_task($_) } qw(core aux);
        my $tb=<<"SV";
module tb;
 logic core_clk=0,aux_clk=0,core_rst_n=1,aux_rst=0,core_run=1,aux_run=1;
 logic core_start=0,aux_start=0,core_enable=0,aux_enable=0;
 logic [7:0] core_data=0,aux_data=0;wire core_done,aux_done;
 wire [7:0] core_seen,aux_seen;
 integer core_expected=19,aux_expected=7;
 always #5 if(core_run) core_clk=~core_clk;
 always #7 if(aux_run) aux_clk=~aux_clk;
 domain_writes_top dut(.*);
 $tasks
 task reset_aux;
  @(negedge aux_clk);aux_rst=1;
  @(posedge aux_clk);#1;if(aux_seen!==0) \$fatal(1,"aux synchronous reset failed");
  @(negedge aux_clk);aux_rst=0;
  @(posedge aux_clk);#1;aux_expected=7;if(aux_seen!==7) \$fatal(1,"aux owner reset value lost");
 endtask
 initial begin
  #2;core_rst_n=0;aux_rst=1;
  repeat(2) @(negedge aux_clk);aux_rst=0;core_rst_n=1;
  repeat(2) @(negedge core_clk);
  fork activate_core(1,37);activate_aux(1,53);join
  fork activate_core(0,99);activate_aux(1,229);join
  @(negedge core_clk);core_run=0;
  activate_aux(1,71);reset_aux();
  if(core_seen!==core_expected) \$fatal(1,"aux clock/reset changed frozen core owner");
  @(negedge aux_clk);aux_run=0;
  core_rst_n=0;#1;if(core_seen!==0 || aux_seen!==7) \$fatal(1,"core asynchronous reset isolation failed");
  core_rst_n=1;core_run=1;repeat(2) @(negedge core_clk);core_expected=19;
  if(core_seen!==19) \$fatal(1,"core owner reset value lost");
  activate_core(1,237); // First update becomes zero, then the live read increments it.
  if(aux_seen!==7) \$fatal(1,"core writer advanced frozen aux owner");
  aux_run=1;activate_aux(1,249); // Exercise zero-valued write data in the other domain.
  \$display("DOMAIN_WRITE_PASS");\$finish;
 end
 initial begin #20000;\$fatal(1,"domain writer timeout");end
endmodule
SV
        my $hdl=FSM::Pipeline::HDLGenerator->new(quiet=>1)->generate_hdl_from_file($source)->{hdl_code};
        simulate($work,$hdl,$tb);
    };
}
subtest 'unowned or competing domain writers remain rejected' => sub {
    my $cross=$base;$cross =~ s/\(\+ core_status core_data\)/aux_status/;
    my $parent=$base;$parent =~ s/\)\s*\z/ (rule competing (domain core) core_enable (core_status core_data)))/;
    my $multiple=$base;$multiple =~ s/\(spawn core_worker as core_writer\)/(spawn core_worker as core_writer) (spawn core_worker as second_writer)/;
    for my $case (['crossing',$cross,qr/clock-domain violation.*aux_status.*without a crossing primitive/],
                  ['parent',$parent,qr/parent writer and generated child writer/],
                  ['instances',$multiple,qr/competing generated child writers/]) {
        my ($name,$text,$error)=@$case;my $source=write_file("$workspace/$name.isf",$text);
        my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',$source],'');
        isnt($r->{exit_code},0,"$name refused");like($r->{stdout}.$r->{stderr},$error,"$name exact ownership diagnosis");
    }
};
done_testing();
sub activation_task {
    my ($d)=@_;
    return <<"SV";
 task activate_$d(input bit wr,input integer payload);
  integer first_value,last_value,pulses;
  first_value=(${d}_expected+payload)&255;last_value=(first_value+1)&255;pulses=0;
  @(negedge ${d}_clk);${d}_start=1;${d}_enable=wr;${d}_data=3;
  for(integer cycle=0;cycle<18;cycle++) begin
   @(posedge ${d}_clk);#1;
   // Child write edges are 5 and 8; the sequential observer updates at 6 and 9.
   if(${d}_seen!==((wr && cycle>=9) ? last_value : ((wr && cycle>=6) ? first_value : ${d}_expected)))
    \$fatal(1,"$d original write edge mismatch cycle=%d observed=%d",cycle,${d}_seen);
   if(${d}_done) pulses++;
   @(negedge ${d}_clk);${d}_start=0;
   if(cycle==4) ${d}_data=payload;
  end
  if(pulses!=1) \$fatal(1,"$d completion count mismatch");
  if(wr) ${d}_expected=last_value;
 endtask
SV
}
sub simulate {
    my ($work,$hdl,$tb)=@_;
    SKIP: {
        skip 'qualified Verilator runtime unavailable',3 unless can_run('verilator') && darwin_verilator_runtime_qualified();
        my $sv=write_file("$work/dut.sv",$hdl);my $test=write_file("$work/tb.sv",$tb);my $obj="$work/obj";
        my $compile=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','--top-module','tb','--Mdir',$obj,$sv,$test]);
        ok($compile->{ok},'domain writer HDL compiles') or diag($compile->{diagnostic},$compile->{stderr});
        if (!$compile->{ok}) { fail('runtime compilation failed');fail('observations absent'); }
        else {my $run=run_generated_binary(["$obj/Vtb"]);
            ok($run->{ok},'independent domain write edges and reset ownership pass') or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
            like($run->{stdout},qr/DOMAIN_WRITE_PASS/,'domain writer observations complete');}
    }
}
sub write_file {my ($path,$text)=@_;open my $fh,'>',$path or die $!;print {$fh} $text;close $fh or die $!;return $path;}
