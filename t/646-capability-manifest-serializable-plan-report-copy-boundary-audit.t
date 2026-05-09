#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::EmbeddingContract qw(embedding_nested_presence_key_map);
use FSM::Support::SerializablePlanReportContract qw(build_serializable_plan_report_contract);

my $sentinel = '__mutated_by_t646__';

subtest 'capability manifest rebuilds serializable_plan_reports child cleanly' => sub {
    my $first = build_capability_manifest();
    $first->{embedding}{serializable_plan_reports}{json_safe_surface_keys}[0] = $sentinel;
    $first->{embedding}{serializable_plan_reports}{nested_contract_source_map}{$sentinel} = $sentinel;
    $first->{embedding}{serializable_plan_reports}{composition_plan_snapshot_contract}{summary_keys}[0] = $sentinel;
    $first->{embedding}{serializable_plan_reports}{generation_result_snapshot_contract}{summary_keys}[0] = $sentinel;
    $first->{embedding}{serializable_plan_reports}{diagnostic_summary_contract}{summary_keys}[0] = $sentinel;
    push @{$first->{embedding}{section_contract}{nested_presence_key_map}{serializable_plan_reports}}, $sentinel;

    my $second = build_capability_manifest();
    ok(!contains_sentinel($second->{embedding}{serializable_plan_reports}), 'fresh manifest child is not polluted');
    ok(!contains_sentinel($second->{embedding}{section_contract}{nested_presence_key_map}), 'fresh embedding nested map is not polluted');
    is_deeply(
        $second->{embedding}{serializable_plan_reports},
        build_serializable_plan_report_contract(),
        'fresh manifest embeds a clean serializable plan/report contract',
    );
    is_deeply(
        $second->{embedding}{section_contract}{nested_presence_key_map}{serializable_plan_reports},
        embedding_nested_presence_key_map()->{serializable_plan_reports},
        'fresh manifest embeds the clean serializable plan/report presence key family',
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
