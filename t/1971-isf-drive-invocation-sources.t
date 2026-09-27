#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::DriveInvocationSources;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $invocations='FSM::Scheduler::ISF::DriveInvocationSources';
my $scheduler=FSM::Scheduler::ISF->new;
my $json=JSON::PP->new;
my $source='t/data/isf_drive_invocation_sources.isf';
my $actor=FSM::Adapter::ISF->new->parse_file($source);
my $ir=$scheduler->{ir}->build_module($actor);
my ($drive)=grep {$_->{kind} eq 'drive'} @{$ir->{dt_blocks}};
my $work=tempdir(CLEANUP=>1);
my $capture=\&FSM::Test::SourceQueryRunner::_capture;
sub write_file {my ($name,$text)=@_;open my $fh,'>',"$work/$name" or die $!;print {$fh} $text;close $fh or die $!;return "$work/$name"}
sub products {my ($dt)=@_;return [map {$invocations->resolve($dt,$_)} 0..$#{$dt->{assignments}}]}
sub strip {
    my ($module)=@_;
    delete $_->{drive_invocation} for map {@{$_->{assignments}||[]}} @{$module->{dt_blocks}||[]};
}

subtest 'actual mixed local/spawn/do/trigger assignments have distinct producer associations' => sub {
    my $before=dclone($ir);my $records=products($drive);
    my @local=grep {$_->{kind} eq 'local'} @$records;
    is(scalar @local,2,'local caller group has one record per body assignment');
    is_deeply($local[0],{kind=>'local',drive=>'put',request_signal=>'put_start',local_transactions=>[qw(main second)]},
        'local group keeps exact sorted caller set');
    my @generated=grep {$_->{kind} eq 'generated'} @$records;
    is(scalar @generated,6,'each generated invocation has every body assignment');
    my %by_activation;
    push @{$by_activation{$_->{generated_source}{activation_kind}}},$_ for @generated;
    is_deeply([sort keys %by_activation],[qw(do spawn trigger)],'actual activation families are represented');
    for my $case (['spawn','main','transaction'],['do','third','transaction'],['trigger','launch','rule']) {
        my ($kind,$owner,$owner_kind)=@$case;
        my $record=$by_activation{$kind}[0];
        is_deeply([@{$record->{generated_source}}{qw(owner owner_kind child_transaction)}],[$owner,$owner_kind,'worker'],
            "$kind names its actual source owner and child");
        ok(!exists $record->{local_transactions},'generated assignment does not inherit unrelated local callers');
    }
    is_deeply($ir,$before,'collection never edits source IR');
    $records->[0]{local_transactions}[0]='mutated';
    is_deeply(products($drive)->[0]{local_transactions},[qw(main second)],'returned local list is detached');
    $generated[0]{generated_source}{owner}='mutated';
    is_deeply($ir,$before,'returned generated descriptor is detached');
    my $renamed=dclone($drive);$renamed->{name}='unrelated_dt_name';
    is_deeply(products($renamed),products($drive),'DT spelling cannot select invocation ownership');
    my $reverse=dclone($actor);@{$reverse->{transactions}}=reverse @{$reverse->{transactions}};
    my $reverse_ir=$scheduler->{ir}->build_module($reverse);
    my ($reverse_drive)=grep {$_->{kind} eq 'drive'} @{$reverse_ir->{dt_blocks}};
    is_deeply([sort map {$json->canonical->encode($_)} @{products($reverse_drive)}],
        [sort map {$json->canonical->encode($_)} @{products($drive)}],'source permutations retain the same invocation associations');
};

subtest 'producer omission and source mutation cannot become silent ownership evidence' => sub {
    my ($generated_index)=grep {$drive->{assignments}[$_]{drive_invocation}{kind} eq 'generated'} 0..$#{$drive->{assignments}};
    for my $case (
        [0,sub {delete $_[0]{assignments}[0]{drive_invocation}},qr/explicit per-assignment source/],
        [0,sub {pop @{$_[0]{assignments}[0]{drive_invocation}{local_transactions}}},qr/inconsistent local callers/],
        [0,sub {$_[0]{assignments}[0]{drive_invocation}{drive}='different'},qr/explicit per-assignment source/],
        [$generated_index,sub {$_[0]{assignments}[$generated_index]{drive_invocation}{generated_source}{owner}='wrong'},qr/no matching generated/],
        [$generated_index,sub {$_[0]{assignments}[$generated_index]{drive_invocation}{request_signal}='wrong_start'},qr/no matching generated/],
        [$generated_index,sub {$_[0]{generated_call_sources}=[]},qr/no matching generated/],
    ) {
        my $bad=dclone($drive);$case->[1]->($bad);
        eval {$invocations->resolve($bad,$case->[0])};
        like($@,$case->[2],'missing or inconsistent association is refused');
    }
    eval {$invocations->resolve($drive,scalar @{$drive->{assignments}})};
    like($@,qr/assignment index/,'out-of-range assignment is refused');
};

subtest 'empty caller sets and target-local priority keep their actual contracts' => sub {
    my $unused=FSM::Adapter::ISF->new->parse_source('(actor unused (interface (output value)) (drive put (value 0)))','unused.isf');
    my $unused_ir=$scheduler->{ir}->build_module($unused);
    my ($unused_drive)=grep {$_->{kind} eq 'drive'} @{$unused_ir->{dt_blocks}};
    is_deeply(products($unused_drive)->[0]{local_transactions},[],'unused drive gains no fabricated local owner');
    my $priority=FSM::Adapter::ISF->new->parse_file('t/data/isf_rule_transaction_named_drive_priority_probe.isf');
    my $priority_ir=$scheduler->{ir}->build_module($priority);
    my ($priority_drive)=grep {$_->{kind} eq 'drive'} @{$priority_ir->{dt_blocks}};
    my $records=products($priority_drive);
    is_deeply($records->[0]{local_transactions},['main'],'priority preserves the unique actual caller');
    my %assignment=map {$_->{lhs}=>$_} @{$priority_drive->{assignments}};
    is_deeply($assignment{out}{priority_suppressed_by},['force_out'],'conflicting target retains suppressor');
    is_deeply($assignment{out}{guard},{expr=>'(& drive_zero_start (! override_req))'},'conflicting target retains actual combined guard');
    is_deeply($assignment{side}{guard},{port=>'drive_zero_start'},'non-conflicting target retains request-only guard');
    for my $module ($ir,$unused_ir,$priority_ir) {
        my $without=dclone($module);strip($without);
        is($scheduler->{fsm_emitter}->emit($module),$scheduler->{fsm_emitter}->emit($without),'exact carrier ignores private invocation records');
        is_deeply($json->decode($scheduler->{json_emitter}->emit($module)),
            $json->decode($scheduler->{json_emitter}->emit($without)),'complete schedule ignores private invocation records');
    }
};

subtest 'mixed invocation public reports and complete exported carriers stay unchanged' => sub {
    my $files=$scheduler->lower($actor)->{files};write_file($_,$files->{$_}) for sort keys %$files;
    my $check=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$work/drive_invocation_sources_top.fsm"],'');
    is($check->{exit_code},0,'complete generated carrier strict-checks') or diag($check->{stdout},$check->{stderr});
    my $root=abs_path('.');my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
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
        is_deeply($response->{result}{structuredContent}{report},$expected,"$method entire native/API report agrees");
        my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$method newline succeeds");
        is_deeply($json->decode($wire->{stdout}),$response,"$method entire newline/API response agrees");
    }
};
done_testing();
