#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json encode_json);
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(
    build_serializable_diagnostic_summary
    build_serializable_diagnostic_summary_contract
    serializable_diagnostic_summary_contract_source
    serializable_diagnostic_summary_public_top_level_keys
    serializable_diagnostic_summary_summary_keys
);

subtest 'diagnostic summary contract describes a bounded JSON-safe surface' => sub {
    my $contract = build_serializable_diagnostic_summary_contract();

    is($contract->{schema_version}, 1, 'contract exposes schema version');
    is($contract->{status}, 'bounded_public', 'contract marks summary as bounded public');
    is(
        $contract->{contract_source},
        serializable_diagnostic_summary_contract_source(),
        'contract records its owner',
    );
    is_deeply(
        $contract->{public_top_level_presence_keys},
        serializable_diagnostic_summary_public_top_level_keys(),
        'contract publishes top-level keys',
    );
    is_deeply(
        $contract->{summary_keys},
        serializable_diagnostic_summary_summary_keys(),
        'contract publishes summary keys',
    );
    ok($contract->{json_safe_as_whole}, 'contract marks summary JSON-safe');
};

subtest 'successful report produces an empty diagnostic summary' => sub {
    my $summary = build_serializable_diagnostic_summary(
        report => {
            success => 1,
            diagnostics => [],
        },
    );

    assert_public_keys($summary);
    ok($summary->{success}, 'summary records success');
    is($summary->{diagnostic_count}, 0, 'summary records no diagnostics');
    is_deeply($summary->{codes}, [], 'summary records no codes');
    ok(!$summary->{has_diagnostics}, 'summary records no diagnostic presence');
    ok(length(encode_json($summary)), 'empty summary encodes as JSON');
};

subtest 'failed report summarizes stable codes and support matches' => sub {
    my $summary = build_serializable_diagnostic_summary(
        report => {
            success => 0,
            diagnostics => [
                {
                    code => 'FSMGEN_STRICT_INFIX_ASSIGNMENT',
                    severity => 'error',
                    support_accounting => {
                        matched => 1,
                    },
                },
                {
                    code => 'FSMGEN_STRICT_INFIX_ASSIGNMENT',
                    severity => 'error',
                },
            ],
        },
    );

    assert_public_keys($summary);
    ok(!$summary->{success}, 'summary records failure');
    is($summary->{diagnostic_count}, 2, 'summary records diagnostic count');
    is_deeply($summary->{unique_codes}, ['FSMGEN_STRICT_INFIX_ASSIGNMENT'], 'summary records unique code list');
    is($summary->{code_counts}{FSMGEN_STRICT_INFIX_ASSIGNMENT}, 2, 'summary records code counts');
    is($summary->{severity_counts}{error}, 2, 'summary records severity counts');
    ok($summary->{has_diagnostics}, 'summary records diagnostic presence');
    ok($summary->{has_stable_codes}, 'summary records stable code presence');
    ok($summary->{matched_support_accounting}, 'summary records matched support accounting');
    my $decoded = decode_json(encode_json($summary));
    is($decoded->{diagnostic_count}, 2, 'encoded summary decodes with count intact');
};

done_testing();

sub assert_public_keys {
    my ($summary) = @_;
    for my $key (@{serializable_diagnostic_summary_public_top_level_keys()}) {
        ok(exists $summary->{$key}, "summary keeps key $key");
    }
}
