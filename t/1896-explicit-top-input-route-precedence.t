#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use JSON::PP ();
use lib 'perl','t/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Test::VerilatorRuntime qw(darwin_verilator_runtime_qualified run_verilator_compile run_generated_binary);
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::SemanticIntrospectionMCPAdapter;
my $root=abs_path('.');
my $work=tempdir(CLEANUP=>1);
my $json=JSON::PP->new->canonical->utf8;
my $capture=\&FSM::Test::SourceQueryRunner::_capture;
my $normalize=\&FSM::Test::SourceQueryRunner::normalize_repository_paths;
my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
# An explicit transaction entry initializes the watchdog before await. The original
# body-first await watchdog failure is retained and owned by .32.1.3.3.3.
my $isf=<<'ISF';
(actor activation_ready
  (clock-domains
    (domain core (clock clk) (reset rst_n) :default)
    (domain bus (clock bus_clk) (reset bus_rst_n)))
  (crossings (activation worker (from core) (to bus)))
  (interface (input start (domain core)) (output done (domain core))
    (input ready (domain bus)) (output observed (domain bus)))
  (transaction parent (domain core) (on start) (do worker) (complete done))
  (transaction worker (domain bus)
    (on ready) (await ready) (complete observed)))
ISF
(my $control=$isf)=~s/ready/work_ready/g;
my $fsm=<<'FSM';
(?top:explicit_ready
  (?ports:public_io ready result> observed>8)
  (?rtl:worker worker_if)
  (?rtl:noise noise_if)
  (?wiring:routes
    (ready worker.ready)
    (worker.done result)
    (noise.ready observed)))
(?rtlif:worker_if ready<:data done>:data)
(?rtlif:noise_if ready>8:data)
FSM
my @cases=(['ready.isf',$isf],['work_ready.isf',$control],['explicit_ready.fsm',$fsm]);
for my $entry (
    ['bad_width', '(ready worker.ready)', '(ready worker.ready)', qr/explicit link is blocked.*exact width agreement/],
    ['bad_target_role','(ready worker.ready)','(ready worker.done)',qr/explicit link is blocked.*output instead of input/],
    ['bad_source_role','(ready worker.ready)','(worker.ready ready)',qr/explicit link is blocked.*input instead of output/],
    ['duplicate_driver','(ready worker.ready)',"(ready worker.ready)\n    (ready worker.ready)",qr/explicit link is blocked.*already driven/],
    ['missing_route','(ready worker.ready)','',qr/same-name top-input convention is blocked/],
) {
    my ($name,$from,$to,$error)=@$entry;
    my $text=$fsm;
    $text =~ s/\Q$from\E/$to/;
    $text =~ s/public_io ready /public_io ready<2 / if $name eq 'bad_width';
    push @cases,["$name.fsm",$text,$error];
}
for my $case (@cases) {
    my ($name,$text,$error)=@$case;
    subtest "$name public source/query contract" => sub {
        my $path="$work/$name"; write_file($path,$text);
        my $relative=File::Spec->abs2rel($path,$root);
        my $is_actor=$name =~ /\.isf\z/;
        for my $kind (qw(check semantic), $is_actor ? ('schedule') : ()) {
            my %flags=(check=>[qw(--strict --check --json)],semantic=>[qw(--strict --emit-semantic-json)],schedule=>['--emit-schedule-json']);
            my %tools=(check=>'fsmgen_check',semantic=>'fsmgen_semantic_introspect',schedule=>'fsmgen_schedule_preview');
            my $r=$capture->([$^X,'bin/fsmgen',@{$flags{$kind}},$relative],'');
            is($r->{exit_code},$error ? 1 : 0,"$kind has the expected source result") or diag($r->{stdout},$r->{stderr});
            like($r->{stdout},$error,"$kind refuses through the intended validation boundary") if $error;
            my $native=$normalize->($json->decode($r->{stdout}),$root);
            my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$tools{$kind},arguments=>{source_id=>$relative}}};
            my $response=$api->handle_jsonrpc_request($request);
            is($response->{result}{isError} ? 1 : 0,$error ? 1 : 0,"$kind adapter success/failure agrees");
            is_deeply($response->{result}{structuredContent}{report},$native,"$kind complete native/API report agrees");
            my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
            is($wire->{exit_code},0,"$kind newline MCP transport succeeds");
            is_deeply($json->decode($wire->{stdout}),$response,"$kind complete newline/API response agrees");
        }
        return unless $is_actor;
        my $actor=FSM::Adapter::ISF->new->parse_file($path);
        my $lowered=FSM::Scheduler::ISF->new->lower($actor);
        my $dir="$work/$name-artifacts";mkdir $dir or die $!;
        write_file("$dir/$_",$lowered->{files}{$_}) for keys %{$lowered->{files}};
        for my $file (sort keys %{$lowered->{files}}) {
            my $r=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$dir/$file"],'');
            is($r->{exit_code},0,"$file is independently strict-admissible") or diag($r->{stdout});
        }
        subtest 'authored ready input controls independent HDL behavior' => sub {
            plan skip_all => 'Verilator runtime provider unavailable or not qualified'
                unless can_run('verilator') && darwin_verilator_runtime_qualified();
            for my $language (qw(systemverilog verilog)) {
                my $hdl="$dir/$language.sv";
                my $r=$capture->([$^X,'bin/fsmgen','--strict','--quiet','--language',$language,'--output',$hdl,$path],'');
                is($r->{exit_code},0,"$language strict HDL emission succeeds") or diag($r->{stderr});
                next if $r->{exit_code};
                my @defines=$name eq 'work_ready.isf' ? ('-DUSE_WORK_READY','-DACTIVATION_TOP=activation_work_ready_top') : ();
                my $build=run_verilator_compile(['verilator','--binary','--timing','--assert','-Wno-fatal','-j','1',@defines,
                    '--top-module','activation_ready_tb','--Mdir',"$dir/obj_$language",$hdl,'t/data/isf_activation_ready_tb.sv']);
                ok($build->{ok},"$language independent oracle builds") or diag($build->{diagnostic},$build->{stderr});
                next unless $build->{ok};
                my $run=run_generated_binary(["$dir/obj_$language/Vactivation_ready_tb"]);
                ok($run->{ok},"$language external ready holds and releases the worker") or diag($run->{diagnostic},$run->{stdout},$run->{stderr});
                like($run->{stdout},qr/ISF_ACTIVATION_READY_PASS/,"$language oracle completes repeated/reset controls");
            }
        };
    };
}
done_testing();
sub write_file {
    open my $fh,'>',$_[0] or die $!;print {$fh} $_[1] or die $!;close $fh or die $!;
}
