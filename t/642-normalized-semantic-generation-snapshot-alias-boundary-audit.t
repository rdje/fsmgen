#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Pipeline::HDLGenerator;
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);

my $sentinel = '__mutated_by_t642__';
my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $fixture = File::Spec->catfile($repo_root, 'fsm', 'apb_requester.fsm');

subtest 'semantic generation_result_snapshot is fresh across report builds' => sub {
    my $result = FSM::Pipeline::HDLGenerator->new(
        target_language => 'systemverilog',
    )->generate_hdl_from_file($fixture);

    my $first = build_report($result);
    $first->{generation_result_snapshot}{summary}{module_name} = $sentinel;
    $first->{generation_result_snapshot}{top_level_keys}[0] = $sentinel;
    $first->{generation_result_snapshot}{semantic_layer_presence}{intent_hir} = $sentinel;

    my $second = build_report($result);
    ok(!contains_sentinel($second->{generation_result_snapshot}), 'fresh semantic generation snapshot is not polluted');
    is(
        $second->{generation_result_snapshot}{summary}{module_name},
        'apb_requester',
        'fresh semantic generation snapshot keeps module name',
    );
    ok(
        grep { $_ eq 'module_info' } @{$second->{generation_result_snapshot}{top_level_keys}},
        'fresh semantic generation snapshot keeps top-level key list',
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
