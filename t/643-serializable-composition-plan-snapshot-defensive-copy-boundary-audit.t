#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::SerializableCompositionPlanSnapshot qw(
    build_serializable_composition_plan_snapshot
    build_serializable_composition_plan_snapshot_contract
    serializable_composition_plan_snapshot_public_top_level_keys
);

my $sentinel = '__mutated_by_t643__';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_tb.fsm');

subtest 'composition plan snapshot contract returns fresh nested containers' => sub {
    my $first = build_serializable_composition_plan_snapshot_contract();
    $first->{public_top_level_presence_keys}[0] = $sentinel;
    $first->{summary_keys}[0] = $sentinel;
    $first->{collection_keys}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_serializable_composition_plan_snapshot_contract();
    ok(!contains_sentinel($second), 'fresh contract is not polluted by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        serializable_composition_plan_snapshot_public_top_level_keys(),
        'fresh contract still advertises the public key list',
    );
};

subtest 'composition plan snapshot returns fresh report containers' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fixture);

    my $first = build_serializable_composition_plan_snapshot(
        composition_plan => $result->{composition_plan},
    );
    $first->{summary}{instance_count} = 99;
    $first->{top_ports}[0]{name} = $sentinel;
    $first->{instances}[0]{instance_name} = $sentinel;
    $first->{resolved_links}[0]{source} = $sentinel;

    my $second = build_serializable_composition_plan_snapshot(
        composition_plan => $result->{composition_plan},
    );
    ok(!contains_sentinel($second), 'fresh snapshot is not polluted by prior caller mutation');
    is($second->{top_name}, 'apb_tb', 'fresh snapshot keeps top name');
    is($second->{summary}{instance_count}, 2, 'fresh snapshot keeps instance count');
    is_deeply(
        [map { $_->{instance_name} } @{$second->{instances}}],
        [qw(requester completer)],
        'fresh snapshot keeps child instance names',
    );
};

done_testing();

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
