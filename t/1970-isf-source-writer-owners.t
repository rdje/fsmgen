#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use JSON::PP;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);
use lib 'perl', 't/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use FSM::Scheduler::ISF::SourceWriterOwners;
use FSM::Support::SemanticIntrospectionMCPAdapter;

my $owners = 'FSM::Scheduler::ISF::SourceWriterOwners';
my $scheduler = FSM::Scheduler::ISF->new;
my $work = tempdir(CLEANUP=>1);
my $json = JSON::PP->new;
my $capture = \&FSM::Test::SourceQueryRunner::_capture;
sub parse {FSM::Adapter::ISF->new->parse_source($_[0],'source_owners.isf')}
sub write_file {my ($name,$text)=@_;open my $fh,'>',"$work/$name" or die $!;print {$fh} $text;close $fh or die $!;return "$work/$name"}
sub qualify {
    my ($ir,$actor,$label) = @_;
    my $before = dclone($ir);
    my $actor_before = dclone($actor);
    my @records;
    for my $state (@{$ir->{states}}) {
        my $owner = $owners->resolve($ir,$actor,'state',$state);
        is($owner->{source_name},$state->{transaction},"$label explicit state owner");
        push @records,$owner;
    }
    for my $dt (grep {($_->{kind}//'') =~ /\A(?:latency_counter|temporal_contract_monitor|rule|drive)\z/} @{$ir->{dt_blocks}}) {
        my $owner = $owners->resolve($ir,$actor,'dt',$dt);
        is($owner->{source_name},$dt->{source_owner}{name},"$label explicit DT source");
        is($owner->{container_kind},'dt','source transaction does not turn a DT into a state');
        push @records,$owner;
    }
    is_deeply($ir,$before,"$label resolver is detached");
    is_deeply($actor,$actor_before,"$label source records stay detached");
    my $without = dclone($ir);delete $_->{source_owner} for @{$without->{dt_blocks}};
    is($scheduler->{fsm_emitter}->emit($ir),$scheduler->{fsm_emitter}->emit($without),"$label exact carrier unchanged by private metadata");
    is_deeply($json->decode($scheduler->{json_emitter}->emit($ir)),$json->decode($scheduler->{json_emitter}->emit($without)),
        "$label complete schedule unchanged by private metadata");
    return \@records;
}
my $text = <<'ISF';
(actor source_owners (clock clk) (reset rst_n)
 (interface (input start) (input other) (input ack) (input fire) (output done) (output observed (width 8)))
 (storage (var rule_value (width 8)))
 (drive (put payload) (observed payload))
 (transaction main (ports (input payload (width 8))) (on start) (assert (monitor (within ack 3))) (drive put payload) (complete done) (latency (min 1) (max 8)))
 (transaction main_cc_inc (on other) (drive put 5) (complete done))
 (rule assign_rule (when fire) (set rule_value 7)))
ISF
subtest 'actual source producers retain identities through ordering and unrelated names' => sub {
    my @products;
    for my $reverse (0,1) {
        my $actor=parse($text);@{$actor->{transactions}}=reverse @{$actor->{transactions}} if $reverse;
        my $context=FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
        my $physical=$context ? $context->{actor} : $actor;
        my $ir=$scheduler->{ir}->build_module($physical);
        my $records=qualify($ir,$physical,'parent');
        push @products,[sort map {join('|',map {defined($_)?$_:''} @{$_}{qw(module domain source_kind source_name container_kind container_name)})} @$records];
        my %by_kind=map {$_->{kind}=>$_} @{$ir->{dt_blocks}};
        for my $kind (qw(latency_counter temporal_contract_monitor)) {
            is_deeply($by_kind{$kind}{source_owner},{kind=>'transaction',name=>'main'},"$kind belongs to producing transaction");
            my $renamed=dclone($by_kind{$kind});$renamed->{name}='unrelated';
            is($owners->resolve($ir,$physical,'dt',$renamed)->{source_name},'main','DT spelling cannot reassign source');
        }
        is_deeply($by_kind{rule}{source_owner},{kind=>'rule',name=>'assign_rule'},'authored rule owns its DT');
        is_deeply($by_kind{drive}{source_owner},{kind=>'drive',name=>'put'},'shared drive remains drive-owned');
        is_deeply($by_kind{drive}{local_transaction_callers},[qw(main main_cc_inc)],'multiple callers remain intact');
        my $state=dclone($ir->{states}[0]);$state->{name}='unrelated_state';
        is($owners->resolve($ir,$physical,'state',$state)->{source_name},$state->{transaction},'state spelling cannot reassign source');
    }
    is_deeply($products[0],$products[1],'source declaration order does not change owner records');
};

subtest 'generated and realized domain modules retain actual source context' => sub {
    my $actor=parse(<<'ISF');
(actor domains
 (clock-domains (domain core (clock clk) :default) (domain bus (clock bus_clk)))
 (interface (input start (domain core)) (input event (domain bus)) (input ack (domain bus)) (output done (domain core)) (output bus_done (domain bus)))
 (transaction parent (domain core) (on start) (spawn helper as job) (complete done))
 (transaction helper (domain core) (wait 1) (complete done) (latency (min 1) (max 4)))
 (transaction worker (domain bus) (on event) (assert (monitor (within ack 3))) (complete bus_done)))
ISF
    my $ir=$scheduler->{ir}->build_module($actor);
    eval {$owners->resolve($ir,$actor,'state',$ir->{states}[0])};
    like($@,qr/actual clock-domain module/,'mixed pre-partition view is not an emitted module');
    for my $r (@{$scheduler->_multi_domain_realizations($actor,$ir->{domain_partition})}) {
        my $domain_actor=FSM::Scheduler::ISF::_domain_actor_for_scheduled_artifact($actor,$r->{domain},$ir->{domain_partition}{default_domain});
        for my $module ($r->{ir},values %{$r->{ir}{children}}) {
            my $records=qualify($module,$domain_actor,$module->{actor_name});
            is_deeply([sort keys %{{map {$_->{domain}=>1} @$records}}],[$r->{domain}{name}],'actual domain is retained');
            is_deeply([sort keys %{{map {$_->{module}=>1} @$records}}],[$module->{actor_name}],'actual module remains separate');
        }
    }
};

subtest 'omitted and malformed source identities fail closed' => sub {
    my $actor=parse($text);my $ir=$scheduler->{ir}->build_module($actor);
    my ($dt)=grep {$_->{kind} eq 'latency_counter'} @{$ir->{dt_blocks}};
    for my $case (
        [sub {delete $_[0]{source_owner}}, qr/explicit DT source owner/],
        [sub {$_[0]{source_owner}{name}='absent'}, qr/no declared transaction/],
        [sub {$_[0]{source_owner}{kind}='drive'}, qr/explicit DT source owner/],
        [sub {$_[0]{source_owner}{name}=[]}, qr/explicit DT source owner/],
        [sub {$_[0]{kind}='generated_unknown'}, qr/unsupported DT family/],
    ) {
        my $bad=dclone($dt);$case->[0]->($bad);
        eval {$owners->resolve($ir,$actor,'dt',$bad)};
        like($@,$case->[1],'DT mutation has a focused refusal');
    }
    my $state=dclone($ir->{states}[0]);delete $state->{transaction};
    eval {$owners->resolve($ir,$actor,'state',$state)};
    like($@,qr/explicit source identity/,'missing state owner cannot be recovered from name');
    my $result=$owners->resolve($ir,$actor,'dt',$dt);$result->{source_name}='mutated';
    is($owners->resolve($ir,$actor,'dt',$dt)->{source_name},'main','returned ownership cannot alter producer metadata');
};

subtest 'public reports and strict exported carrier preserve their complete contract' => sub {
    my $actor=parse($text);
    my $files=$scheduler->lower($actor)->{files};
    write_file($_,$files->{$_}) for sort keys %$files;
    my $checked=$capture->([$^X,'bin/fsmgen','--strict','--check','--json',"$work/source_owners.fsm"],'');
    is($checked->{exit_code},0,'complete exported carrier strict-checks') or diag($checked->{stdout},$checked->{stderr});
    my $root=abs_path('.');
    my $relative=File::Spec->abs2rel(write_file('source_owners.isf',$text),$root);
    my $api=FSM::Support::SemanticIntrospectionMCPAdapter->new(repo_root=>$root,workspace_root=>$root);
    for my $case (
        [[qw(--strict --check --json)],'fsmgen_check'],
        [[qw(--strict --emit-semantic-json)],'fsmgen_semantic_introspect'],
        [['--emit-schedule-json'],'fsmgen_schedule_preview'],
    ) {
        my ($flags,$method)=@$case;
        my $native=$capture->([$^X,'bin/fsmgen',@$flags,$relative],'');
        is($native->{exit_code},0,"$method native succeeds") or diag($native->{stdout},$native->{stderr});
        next if $native->{exit_code};
        my $expected=FSM::Test::SourceQueryRunner::normalize_repository_paths($json->decode($native->{stdout}),$root);
        my $request={jsonrpc=>'2.0',id=>1,method=>'tools/call',params=>{name=>$method,arguments=>{source_id=>$relative}}};
        my $response=$api->handle_jsonrpc_request($request);
        ok(!$response->{error} && !$response->{result}{isError},"$method API succeeds");
        is_deeply($response->{result}{structuredContent}{report},$expected,"$method entire native/API report agrees");
        my $wire=$capture->([$^X,'bin/fsmgen-mcp','--workspace-root','.'],$json->encode($request)."\n");
        is($wire->{exit_code},0,"$method newline succeeds");
        is_deeply($json->decode($wire->{stdout}),$response,"$method entire newline/API response agrees");
    }
};

done_testing();
