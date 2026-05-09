#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);

my $sentinel = '__mutated_by_t644__';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');

subtest 'semantic composition plan_snapshot is fresh across report builds' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fixture);

    my $first = build_report($result);
    $first->{semantic}{composition}{plan_snapshot}{summary}{instance_count} = 99;
    $first->{semantic}{composition}{plan_snapshot}{top_ports}[0]{name} = $sentinel;
    $first->{semantic}{composition}{plan_snapshot}{instances}[0]{instance_name} = $sentinel;

    my $second = build_report($result);
    my $snapshot = $second->{semantic}{composition}{plan_snapshot};
    ok(!contains_sentinel($snapshot), 'fresh semantic composition plan snapshot is not polluted');
    is($snapshot->{top_name}, 'apb_tb', 'fresh semantic composition plan snapshot keeps top name');
    is($snapshot->{summary}{instance_count}, 2, 'fresh semantic composition plan snapshot keeps instance count');
    is_deeply(
        [map { $_->{instance_name} } @{$snapshot->{instances}}],
        [qw(requester completer)],
        'fresh semantic composition plan snapshot keeps child instance names',
    );
};

done_testing();

sub build_report {
    my ($result) = @_;
    return build_normalized_semantic_success_report(
        input => $fixture,
        source_file => $fixture,
        target_language => 'systemverilog',
        strict_mode => 1,
        result => $result,
        module_info => $result->{module_info},
    );
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_sentinel($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists $value->{$sentinel};
        return 1 if grep { contains_sentinel($_) } values %$value;
        return 0;
    }

    return 0;
}
