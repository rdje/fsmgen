#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(
    build_serializable_diagnostic_summary
    build_serializable_diagnostic_summary_contract
    serializable_diagnostic_summary_public_top_level_keys
);

my $sentinel = '__mutated_by_t638__';

subtest 'diagnostic summary contract returns fresh nested containers' => sub {
    my $first = build_serializable_diagnostic_summary_contract();
    $first->{public_top_level_presence_keys}[0] = $sentinel;
    $first->{summary_keys}[0] = $sentinel;
    push @{$first->{guidance}}, $sentinel;

    my $second = build_serializable_diagnostic_summary_contract();
    ok(!contains_sentinel($second), 'fresh contract is not polluted by prior caller mutation');
    is_deeply(
        $second->{public_top_level_presence_keys},
        serializable_diagnostic_summary_public_top_level_keys(),
        'fresh contract still advertises the public key list',
    );
};

subtest 'diagnostic summary returns fresh report containers' => sub {
    my $first = build_serializable_diagnostic_summary(
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
            ],
        },
    );

    $first->{codes}[0] = $sentinel;
    $first->{unique_codes}[0] = $sentinel;
    $first->{code_counts}{$sentinel} = 99;
    $first->{severity_counts}{error} = 99;

    my $second = build_serializable_diagnostic_summary(
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
            ],
        },
    );

    ok(!contains_sentinel($second), 'fresh summary is not polluted by prior caller mutation');
    is_deeply($second->{codes}, ['FSMGEN_STRICT_INFIX_ASSIGNMENT'], 'fresh summary keeps original code list');
    is($second->{code_counts}{FSMGEN_STRICT_INFIX_ASSIGNMENT}, 1, 'fresh summary keeps original code count');
    is($second->{severity_counts}{error}, 1, 'fresh summary keeps original severity count');
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
