#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::RegressionCorpus qw(regression_corpus_entries);
use FSM::Support::SupportAccountingContract qw(build_support_accounting_contract);

my @entries = regression_corpus_entries();
my $expected_section = build_expected_support_accounting_section(\@entries);

subtest 'support-accounting manifest section stays an exact bounded regression-corpus projection in-process' => sub {
    my $manifest = build_capability_manifest();

    is_deeply(
        $manifest->{support_accounting},
        $expected_section,
        'in-process support-accounting section matches the exact bounded regression-corpus projection',
    );
};

subtest 'support-accounting manifest section stays an exact bounded regression-corpus projection through the public CLI' => sub {
    my $decoded = run_capability_manifest('--capability-manifest');

    is_deeply(
        $decoded->{support_accounting},
        $expected_section,
        'CLI support-accounting section matches the exact bounded regression-corpus projection',
    );
};

subtest 'support-accounting manifest alias keeps the same exact bounded regression-corpus projection' => sub {
    my $decoded = run_capability_manifest('--emit-capability-manifest');

    is_deeply(
        $decoded->{support_accounting},
        $expected_section,
        'CLI alias support-accounting section matches the exact bounded regression-corpus projection',
    );
};

done_testing();

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}

sub build_expected_support_accounting_section {
    my ($entries) = @_;

    my %classifications = count_by($entries, 'classification');
    my %coverage_buckets = count_by($entries, 'coverage');
    my %families = count_by($entries, 'family');
    my %source_kinds = count_by($entries, 'source_kind');

    my @strict_supported_ids = map { $_->{id} } grep { $_->{strict_supported} } @{$entries || []};
    my @supported_smoke_ids = map { $_->{id} } grep { $_->{classification} eq 'supported_smoke' } @{$entries || []};
    my @expected_failure_ids = map { $_->{id} } grep { $_->{classification} eq 'expected_failure' } @{$entries || []};

    my $contract = build_support_accounting_contract();

    return {
        %{$contract},
        source => 'FSM::Support::RegressionCorpus',
        entry_count => scalar(@{$entries || []}),
        classifications => \%classifications,
        coverage_buckets => \%coverage_buckets,
        families => \%families,
        source_kinds => \%source_kinds,
        supported_smoke_ids => \@supported_smoke_ids,
        strict_supported_ids => \@strict_supported_ids,
        expected_failure_ids => \@expected_failure_ids,
        catalog_entries => [
            map { manifest_catalog_entry($_) } @{$entries || []},
        ],
        section_contract => $contract,
    };
}

sub count_by {
    my ($entries, $field) = @_;

    my %counts;
    for my $entry (@{$entries || []}) {
        my $value = $entry->{$field};
        $value = 'unknown' unless defined $value && length $value;
        $counts{$value}++;
    }

    return %counts;
}

sub manifest_catalog_entry {
    my ($entry) = @_;

    my %manifest = map { $_ => $entry->{$_} } grep { exists $entry->{$_} } qw(
        id
        relpath
        family
        classification
        coverage
        source_kind
        strict_supported
        expected_module_name
        expected_top_name
        expected_lane
        expected_instance_count
        diagnostic_code
    );

    $manifest{strict_supported} = $entry->{strict_supported} ? JSON::PP::true : JSON::PP::false;
    $manifest{expected_child_modules} = [@{$entry->{expected_child_modules}}]
        if ref($entry->{expected_child_modules}) eq 'ARRAY';
    $manifest{search_path_relpaths} = [@{$entry->{search_path_relpaths}}]
        if ref($entry->{search_path_relpaths}) eq 'ARRAY';
    $manifest{expected_hdl_pattern_count} = scalar(@{$entry->{expected_hdl_patterns}})
        if ref($entry->{expected_hdl_patterns}) eq 'ARRAY';
    $manifest{private_capabilities} = [@{$entry->{private_capabilities}}]
        if ref($entry->{private_capabilities}) eq 'ARRAY';
    $manifest{private_nonclaims} = [@{$entry->{private_nonclaims}}]
        if ref($entry->{private_nonclaims}) eq 'ARRAY';
    $manifest{has_expected_error_pattern} = $entry->{expected_error_pattern}
        ? JSON::PP::true
        : JSON::PP::false;
    $manifest{has_expected_hint_pattern} = $entry->{expected_hint_pattern}
        ? JSON::PP::true
        : JSON::PP::false;

    return \%manifest;
}
