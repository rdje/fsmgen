#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CompositionReportContract qw(
    build_composition_report_contract
    composition_report_collection_keys
    composition_report_count_map_keys
    composition_report_example_map_keys
    composition_report_ordered_list_keys
    composition_report_presence_key_family_map
    composition_report_public_top_level_keys
    composition_report_summary_keys
    sanitize_composition_report
);

my $sentinel = '__mutated_by_t441__';
my $audit_test = 't/441-composition-report-contract-defensive-copy-boundary-audit.t';

subtest 'composition report contract builder returns fresh nested structures' => sub {
    my $first = build_composition_report_contract();
    mutate_structure($first);

    my $second = build_composition_report_contract();
    ok(!contains_sentinel($second), 'fresh composition report contract is not affected by prior caller mutation');
    ok(contains_scalar($second->{tested_by}, $audit_test), 'contract provenance lists this defensive-copy audit');
    is_deeply(
        $second->{presence_key_family_map},
        composition_report_presence_key_family_map(),
        'fresh contract grouped presence family map matches its helper',
    );
};

subtest 'composition report helper builders return fresh nested structures' => sub {
    for my $case (
        {
            label => 'public_top_level_keys',
            build => \&composition_report_public_top_level_keys,
        },
        {
            label => 'summary_keys',
            build => \&composition_report_summary_keys,
        },
        {
            label => 'collection_keys',
            build => \&composition_report_collection_keys,
        },
        {
            label => 'count_map_keys',
            build => \&composition_report_count_map_keys,
        },
        {
            label => 'example_map_keys',
            build => \&composition_report_example_map_keys,
        },
        {
            label => 'ordered_list_keys',
            build => \&composition_report_ordered_list_keys,
        },
        {
            label => 'presence_key_family_map',
            build => \&composition_report_presence_key_family_map,
        },
    ) {
        my $first = $case->{build}->();
        mutate_structure($first);

        my $second = $case->{build}->();
        ok(!contains_sentinel($second), "$case->{label} returns fresh nested structures");
    }
};

subtest 'fresh grouped composition report map stays aligned with helper families' => sub {
    my $family_map = composition_report_presence_key_family_map();

    is_deeply(
        $family_map->{summary_keys},
        composition_report_summary_keys(),
        'summary map entry matches helper',
    );
    is_deeply(
        $family_map->{collection_keys},
        composition_report_collection_keys(),
        'collection map entry matches helper',
    );
    is_deeply(
        $family_map->{count_map_keys},
        composition_report_count_map_keys(),
        'count map entry matches helper',
    );
    is_deeply(
        $family_map->{example_map_keys},
        composition_report_example_map_keys(),
        'example map entry matches helper',
    );
    is_deeply(
        $family_map->{ordered_list_keys},
        composition_report_ordered_list_keys(),
        'ordered-list map entry matches helper',
    );
    is_deeply(
        unique_sorted([
            @{$family_map->{summary_keys}},
            @{$family_map->{collection_keys}},
            @{$family_map->{count_map_keys}},
            @{$family_map->{example_map_keys}},
            @{$family_map->{ordered_list_keys}},
        ]),
        unique_sorted(composition_report_public_top_level_keys()),
        'grouped composition report key families cover the public top-level key helper',
    );
};

subtest 'composition report sanitizer returns fresh nested structures' => sub {
    my $raw = sample_raw_report();
    my $first = sanitize_composition_report($raw);
    mutate_structure($first);

    my $second = sanitize_composition_report($raw);
    ok(!contains_sentinel($second), 'fresh sanitized report is not affected by prior sanitized-output mutation');
    ok(!contains_sentinel($raw), 'sanitized-output mutation does not affect the raw report input');
    is_deeply(
        unknown_top_level_keys($second),
        [],
        'fresh sanitized report still contains only declared public top-level keys',
    );
};

done_testing();

sub sample_raw_report {
    return {
        lane => 'C4',
        top_port_count => 1,
        resolved_link_count => 1,
        override_count => 0,
        block_count => 0,
        ports => [
            {
                name => 'clk',
                origin => 'top',
                notes => ['clock'],
            },
        ],
        resolved_links => [
            {
                source => 'top.clk',
                sink => 'child.clk',
            },
        ],
        override_events => [],
        block_events => [],
        port_origin_counts => {top => 1},
        port_category_counts => {clock => 1},
        port_origin_examples => {top => ['clk']},
        resolved_link_origin_counts => {authored => 1},
        resolved_link_category_counts => {clock => 1},
        resolved_link_origin_examples => {authored => ['top.clk']},
        override_kind_counts => {},
        block_kind_counts => {},
        override_kind_examples => {},
        block_kind_examples => {},
        ordered_port_origins => ['top'],
        ordered_resolved_link_origins => ['authored'],
        ordered_override_kinds => [],
        ordered_block_kinds => [],
        private_object => bless({}, 'T441::PrivateObject'),
    };
}

sub unknown_top_level_keys {
    my ($report) = @_;
    my %known = map { $_ => 1 } @{composition_report_public_top_level_keys()};
    return [grep { !$known{$_} } sort keys %{$report || {}}];
}

sub mutate_structure {
    my ($value) = @_;
    return unless ref($value);

    if (ref($value) eq 'ARRAY') {
        push @{$value}, $sentinel;
        mutate_structure($_) for @{$value};
        return;
    }

    if (ref($value) eq 'HASH') {
        $value->{$sentinel} = $sentinel;
        mutate_structure($_) for values %{$value};
        return;
    }
}

sub contains_sentinel {
    my ($value) = @_;
    return 1 if defined($value) && !ref($value) && $value eq $sentinel;
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        for my $entry (@{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if exists($value->{$sentinel});
        for my $entry (values %{$value}) {
            return 1 if contains_sentinel($entry);
        }
        return 0;
    }

    return 0;
}

sub contains_scalar {
    my ($values, $wanted) = @_;
    return 0 unless ref($values) eq 'ARRAY';

    for my $value (@{$values}) {
        return 1 if defined($value) && !ref($value) && $value eq $wanted;
    }

    return 0;
}

sub unique_sorted {
    my ($values) = @_;
    my %seen;
    return [sort grep { !$seen{$_}++ } @{$values || []}];
}
