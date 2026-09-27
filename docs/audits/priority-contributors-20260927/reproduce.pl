#!/usr/bin/env perl
use strict;
use warnings;
use lib 'perl', 't/lib';
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP;
use FSM::Test::ProjectDataLocality;
use FSM::Test::SourceQueryRunner;
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $base = 'docs/audits/priority-contributors-20260927';
my $name = shift(@ARGV) // 'baseline';
die "invalid exclusive capture name\n" unless $name =~ /\A[a-z0-9_]+\z/ && !@ARGV;
my $work = ".artifacts/priority-contributors/$name";
mkdir $work or die "exclusive capture directory: $!";
my $json = JSON::PP->new->canonical->pretty;
my $scheduler = FSM::Scheduler::ISF->new;
my @results;
for my $case (qw(single_state multi_state reversed_values)) {
    my $path = "$base/$case.isf";
    open my $fh, '<:raw', $path or die $!;
    my $source = do {local $/; <$fh>}; close $fh or die $!;
    my %reports;
    for my $query ([check => qw(--strict --check --json)], [schedule => '--emit-schedule-json'],
            [semantic => qw(--strict --emit-semantic-json)]) {
        my ($kind, @flags) = @$query;
        my $result = FSM::Test::SourceQueryRunner::_capture([$^X, 'bin/fsmgen', @flags, $path], '');
        die "$case $kind rejected: $result->{stdout} $result->{stderr}\n" if $result->{exit_code};
        die "$case $kind unexpected stderr: $result->{stderr}\n" if length($result->{stderr});
        my $report = FSM::Test::SourceQueryRunner::normalize_repository_paths(
            $json->decode($result->{stdout}), abs_path('.'));
        save("$work/$case-$kind.json", $json->encode($report));
        $reports{$kind} = $report;
    }
    my $actor = FSM::Adapter::ISF->new->parse_source($source, $path);
    my $ir = $scheduler->{ir}->build_module($actor);
    my $files = $scheduler->lower($actor)->{files};
    my $carrier = $files->{'priority_contributors.fsm'};
    die "missing production carrier\n" unless defined $carrier;
    save("$work/$case.fsm", $carrier);
    my @writers;
    for my $state (@{$ir->{states}}) {
        for my $assignment (@{$state->{assignments}}) {
            next unless $assignment->{lhs} eq 'out';
            push @writers, {state => $state->{name}, transaction => $state->{transaction},
                operator => $assignment->{op}, rhs => $assignment->{rhs}, guard => $assignment->{guard}};
        }
    }
    my ($rule) = grep {$_->{kind} eq 'rule' && $_->{source_owner}{name} eq 'fallback'} @{$ir->{dt_blocks}};
    my ($output) = grep {$_->{lhs} eq 'out'} @{$rule->{assignments}};
    my ($side) = grep {$_->{lhs} eq 'side'} @{$rule->{assignments}};
    my $guard = $output->{guard}{expr};
    die "unexpected priority guard form\n" unless defined $guard;
    my @selected = $guard =~ /\(state_active ([A-Za-z0-9_]+)\)/g;
    push @results, {case => $case, source_sha256 => sha256_hex($source),
        check_success => $reports{check}{success}, compile_issues => $reports{schedule}{compile_issues},
        higher_writers => \@writers, rule_header => $rule->{dte_guard},
        rule_output => $output, unrelated_output => $side,
        retained_states => \@selected, priority_resolutions => $reports{schedule}{priority_resolutions}};
    print "$case: admitted; writers=[", join(',', map {$_->{state}} @writers),
        "]; retained=[", join(',', @selected), "]\n";
}
save("$work/result.json", $json->encode(\@results));

sub save {
    my ($path, $bytes) = @_;
    open my $fh, '>:raw', $path or die $!;
    print {$fh} $bytes or die $!;
    close $fh or die $!;
}
