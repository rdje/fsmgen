#!/usr/bin/env perl
# Bounded admission/provenance baseline, not an independent execution claim.
use strict;
use warnings;
use lib 'perl','t/lib';
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Scheduler::ISF::FormalLowering;
use JSON::PP;
use File::Path qw(make_path);
use Digest::SHA qw(sha256_hex);
my $json = JSON::PP->new->canonical->pretty;
my $base = 'docs/audits/direct-writer-admission-20260927';
open my $fh,'<',"$base/cases.json" or die $!;
my $cases = $json->decode(do {local $/;<$fh>});close $fh;
my $workspace = '.artifacts/direct-writer-admission';make_path($workspace);
my $scheduler = FSM::Scheduler::ISF->new;
my @results;
for my $case (@$cases) {
    my $path = "$workspace/$case->{case_id}.isf";
    open my $out,'>',$path or die $!;print {$out} $case->{source};close $out or die $!;
    my $check = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--strict','--check','--json',$path],'');
    my $checked = $json->decode($check->{stdout});
    my $record = {case_id=>$case->{case_id},source_sha256=>sha256_hex($case->{source}),
        check_exit=>$check->{exit_code},check_success=>$checked->{success},
        diagnostic_codes=>$checked->{diagnostic_summary}{codes},
        diagnostic_messages=>[map {$_->{message}} @{$checked->{diagnostics}}]};
    if ($check->{exit_code}==0) {
        my $query = FSM::Test::SourceQueryRunner::_capture([$^X,'bin/fsmgen','--emit-schedule-json',$path],'');
        die "schedule failed: $query->{stderr}" if $query->{exit_code};
        my $report = $json->decode($query->{stdout});
        $record->{$_}=$report->{$_} for qw(compile_issues priority_resolutions compatible_fanin_groups);
        my $actor = FSM::Adapter::ISF->new->parse_source($case->{source},$path);
        my $context = FSM::Scheduler::ISF::FormalLowering->prepare($scheduler->{ir},$actor);
        my $ir = $scheduler->{ir}->build_module($context ? $context->{actor} : $actor);
        FSM::Scheduler::ISF::FormalLowering->verify($context,{$ir->{actor_name}=>$ir});
        $record->{controllers}=[map { {transaction=>$_->{transaction},initial_state=>$_->{initial_state},states=>$_->{states}} }
            @{$ir->{logical_controllers}{controllers}}];
        my %state_owner = map {$_->{name}=>$_->{transaction}} @{$ir->{states}};
        $record->{writers}=[map {
            my $r=$_;
            +{(map {$_=>$r->{$_}} qw(owner owner_kind source_kind target operator rhs domain activation)),
              ($r->{activation}{container_kind} eq 'state'
                ? (explicit_state_owner=>$state_owner{$r->{activation}{container_name}}) : ())};
        } @{$ir->{assignment_provenance}}];
        $record->{private_formals}=$context ? [map { {identity=>$_->{identity},physical_name=>$_->{physical_name}} }
            @{$context->{plan}{ordered}}] : [];
        die "unexpected admission for $case->{case_id}\n" unless $case->{expected_admission} eq 'admitted';
    } else {
        die "unexpected rejection for $case->{case_id}: $check->{stdout} $check->{stderr}\n"
            unless $case->{expected_admission} eq 'rejected';
    }
    push @results,$record;
    print "$case->{case_id}: ".($check->{exit_code} ? 'rejected' : 'admitted')."\n";
}
open my $out,'>',"$workspace/current.json" or die $!;
print {$out} $json->encode({schema_version=>1,scope=>'admission_and_physical_provenance_only',cases=>\@results});
close $out or die $!;
