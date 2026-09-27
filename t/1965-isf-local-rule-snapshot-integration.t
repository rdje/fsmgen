#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use IPC::Cmd qw(can_run);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::PreparedFormalReservations;
use FSM::Support::SemanticIntrospectionMCPAdapter;
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

my $source = 't/data/isf_local_rule_snapshot.isf';
open my $fh, '<', $source or die $!;
my $text = do {local $/; <$fh>}; close $fh;
my $scheduler = FSM::Scheduler::ISF->new;
my $root = abs_path('.');
my $work = tempdir(CLEANUP => 1);
my $json = JSON::PP->new->canonical;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
sub parse {FSM::Adapter::ISF->new->parse_source($_[0], $source)}
sub write_file {
    my ($path,$text) = @_;
    open my $out, '>', $path or die $!; print {$out} $text; close $out or die $!; return $path;
}
sub strict_carriers {
    my ($actor,$dir,$label) = @_;
    mkdir $dir or die $!;
    my $files = $scheduler->lower($actor)->{files};
    write_file("$dir/$_", $files->{$_}) for sort keys %$files;
    my $top = exists($files->{"$actor->{actor_name}_top.fsm"}) ? "$actor->{actor_name}_top" : $actor->{actor_name};
    my $r = $capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$top.fsm"], '');
    is($r->{exit_code}, 0, "$label strict carrier") or diag($r->{stdout}, $r->{stderr});
    return $files;
}

subtest 'actual source preparation and production share collision-safe typed storage' => sub {
    my $typed = $text;
    $typed =~ s/\(interface/(types (type nibble (signed (bits 4))))\n (interface/;
    $typed =~ s/\(input payload \(width 4\)\)/(input payload (type nibble))/;
    $typed =~ s/\(rule fire/(transaction sibling (ports (input isf_snapshot_worker_payload)) (wait 1))\n (rule fire/;
    my $actor = parse($typed);
    my $before = dclone($actor);
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $prepared = $context->{prepared};
    my $products = $prepared->{parent_payload_snapshot_products};
    is(scalar @{$products->{bindings}}, 1, 'one accepted-payload owner');
    my $held = $products->{bindings}[0]{held_signal};
    isnt(lc($held), 'isf_snapshot_worker_payload', 'helper avoids raw sibling formal');
    my $projected = $scheduler->{ir}->prepare_formal_source($context->{actor});
    is($projected->{parent_payload_snapshot_products}{bindings}[0]{held_signal}, $held,
        'helper remains stable after raw sibling name is freed by projection');
    my $ir = $scheduler->{ir}->build_module($context->{actor});
    is($ir->{signal_widths}{$held}, 4, 'actual retained width');
    is($ir->{signal_type_refs}{$held}, 'nibble', 'actual retained signed type');
    is($ir->{storage_roles}{$held}, 'transaction_port_binding', 'advertised binding ownership');
    ok((grep {$_ eq $held} @{$ir->{explicit_internal_signals}}), 'snapshot stays internal');
    ok(!exists $ir->{reset_values}{$held}, 'does not invent a source reset value');
    ok(FSM::Scheduler::ISF::FormalLowering->verify($context, {local_snapshot=>$ir}), 'actual final declarations covered');
    my $bad_ir = dclone($ir);
    $bad_ir->{counters}{unreserved_snapshot_probe} = 4;
    eval {FSM::Scheduler::ISF::FormalLowering->verify($context, {local_snapshot=>$bad_ir})};
    like($@, qr/unreserved declarations:.*unreserved_snapshot_probe/, 'late unreserved snapshot declaration is rejected');
    my $bad = dclone($prepared); delete $bad->{parent_payload_snapshot_products};
    eval {FSM::Scheduler::ISF::PreparedFormalReservations->collect($bad)};
    like($@, qr/incomplete preparation.*parent_payload_snapshot_products/, 'snapshot producer category is mandatory');
    is_deeply($actor, $before, 'preparation/build do not mutate authored source');
    strict_carriers($actor,"$work/typed",'typed collision');
};

subtest 'domain realization retains the same local helper reservation' => sub {
    my $domains = $text;
    $domains =~ s/\(clock clk\) \(reset \(rst_n async active_low\)\)/(clock-domains (domain core (clock clk) (reset (rst_n async active_low)) :default) (domain aux (clock aux_clk) (reset (aux_rst_n async active_low))))/;
    $domains =~ s/\(input start\)/(input aux_start (domain aux)) (input start)/;
    $domains =~ s/\(rule fire/(transaction other (domain aux) (on aux_start) (wait 1))\n (rule fire/;
    my $actor = parse($domains);
    my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir}, $actor);
    my $local = $context->{prepared}{domain_source_products};
    is(scalar @{$local->{core}{preparation}{parent_payload_snapshot_products}{bindings}},1,'core owns snapshot');
    is_deeply($local->{aux}{preparation}{parent_payload_snapshot_products}{bindings},[],'sibling does not acquire snapshot');
    strict_carriers($actor,"$work/domains",'domain-local snapshot');
};

subtest 'entire public reports agree and binding provenance remains authored' => sub {
    my $api = FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $query (
        ['check',[qw(--strict --check --json)],'fsmgen_check'],
        ['semantic',[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        ['schedule',['--emit-schedule-json'],'fsmgen_schedule_preview'],
    ) {
        my ($label,$flags,$method) = @$query;
        my $native = $capture->([$^X,'bin/fsmgen',@$flags,$source], '');
        is($native->{exit_code},0,"$label native succeeds") or diag($native->{stdout},$native->{stderr});
        next if $native->{exit_code};
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
        my $request = {jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$method,arguments=>{source_id=>$source}}};
        my $response = $api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError},"$label API succeeds");
        is_deeply($response->{result}{structuredContent}{report},$report,"$label complete native/API equality");
        my $wire = $capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$label newline succeeds");
        is_deeply($json->decode($wire->{stdout}),$response,"$label complete API/newline equality");
        if ($label eq 'schedule') {
            is($report->{transaction_port_bindings}[0]{port},'payload','binding reports authored formal');
            my $contract = build_isf_public_interface_contract();
            my %roles = map {$_=>1} @{$contract->{schedule_report_storage_role_values}};
            my %kinds = map {$_=>1} @{$contract->{schedule_report_dt_kind_values}};
            is_deeply([grep {defined($_->{role}) && !$roles{$_->{role}}} @{$report->{inferred_storage}}],[],'all emitted roles advertised');
            is_deeply([grep {!$kinds{$_->{kind}}} @{$report->{dt_blocks}}],[],'all emitted DT kinds advertised');
        }
    }
    strict_carriers(parse($text),"$work/carriers",'payload-qualified inline sample');
};

subtest 'entry sample and delayed read observe accepted payload on public pins' => sub {
    plan skip_all => 'qualified Verilator runtime unavailable' unless can_run('verilator') && darwin_verilator_runtime_qualified();
    my $tb = write_file("$work/tb.sv", <<'SV');
module tb;
 logic clk=0, rst_n=1, start=0, allow=1;
 logic [3:0] data=7;
 wire [3:0] early, observed; wire done;
 integer completions=0;
 always #5 clk=~clk;
 always @(posedge clk) begin #1; if(rst_n && done) completions++; end
 local_snapshot dut(.*);
 initial begin
  #2; rst_n=0; #19; rst_n=1;
  @(negedge clk); start=1;
  @(negedge clk); start=0; data=13;
  @(negedge clk);
  if(early!==4'd7) $fatal(1,"entry sample did not see requesting payload");
  wait(done===1); #2;
  if(observed!==4'd7 || completions!=1) $fatal(1,"accepted delayed snapshot lost");
  repeat(12) @(negedge clk);
  if(completions!=1) $fatal(1,"request replayed");
  $display("LOCAL_RULE_SNAPSHOT_ENTRY_PASS"); $finish;
 end
 initial begin #20000; $fatal(1,"payload entry timeout or combinational cycle"); end
endmodule
SV
    for my $language (qw(systemverilog verilog)) {
        my $hdl = "$work/$language.sv";
        my $emit = $capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$source], '');
        is($emit->{exit_code},0,"$language emits") or diag($emit->{stdout},$emit->{stderr});
        next if $emit->{exit_code};
        my $obj = "$work/obj_$language";
        my $compile = run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1','--top-module','tb','--Mdir',$obj,$hdl,$tb]);
        ok($compile->{ok},"$language oracle builds") or diag($compile->{diagnostic},$compile->{stderr});
        next unless $compile->{ok};
        my $run = run_generated_binary(["$obj/Vtb"]);
        ok($run->{ok},"$language public-pin oracle passes") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
        like($run->{stdout},qr/LOCAL_RULE_SNAPSHOT_ENTRY_PASS/,"$language oracle completed");
    }
};
done_testing();
