#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CheckDiagnostics qw(build_check_failure_report);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_failure_report);

my $sentinel = '__mutated_by_t640__';
my %failure_args = (
    input => 'bad.fsm',
    source_file => 'bad.fsm',
    target_language => 'systemverilog',
    strict_mode => 1,
    message => "Strict mode rejects infix assignment '(OUT = SRC)'.\n",
);

subtest 'check JSON diagnostic_summary is fresh across report builds' => sub {
    my $first = build_check_failure_report(%failure_args);
    mutate_summary($first->{diagnostic_summary});

    my $second = build_check_failure_report(%failure_args);
    ok(!contains_sentinel($second->{diagnostic_summary}), 'fresh check report summary is not polluted');
    is($second->{diagnostic_summary}{diagnostic_count}, 1, 'fresh check report summary keeps diagnostic count');
};

subtest 'semantic JSON diagnostic_summary is fresh across report builds' => sub {
    my $first = build_normalized_semantic_failure_report(%failure_args);
    mutate_summary($first->{diagnostic_summary});

    my $second = build_normalized_semantic_failure_report(%failure_args);
    ok(!contains_sentinel($second->{diagnostic_summary}), 'fresh semantic report summary is not polluted');
    is($second->{diagnostic_summary}{diagnostic_count}, 1, 'fresh semantic report summary keeps diagnostic count');
};

done_testing();

sub mutate_summary {
    my ($summary) = @_;
    $summary->{codes}[0] = $sentinel;
    $summary->{unique_codes}[0] = $sentinel;
    $summary->{code_counts}{$sentinel} = 99;
    $summary->{severity_counts}{error} = 99;
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
