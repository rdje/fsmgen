#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use JSON::PP qw(decode_json encode_json);
use Scalar::Util qw(blessed);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::SerializableDiagnosticSummary qw(build_serializable_diagnostic_summary);

subtest 'diagnostic summary remains plain data after JSON round trip' => sub {
    my $summary = build_serializable_diagnostic_summary(
        report => {
            success => 0,
            diagnostics => [
                {
                    code => 'FSMGEN_STRICT_INFIX_ASSIGNMENT',
                    severity => 'error',
                    support_accounting => {matched => 1},
                },
                {
                    code => 'FSMGEN_MISSING_DECLARATION',
                    severity => 'warning',
                    support_accounting => {matched => 0},
                },
            ],
        },
    );

    ok(length(encode_json($summary)), 'summary encodes as JSON');
    my $decoded = decode_json(encode_json($summary));

    ok(!contains_blessed($decoded), 'decoded summary contains no blessed values');
    is($decoded->{diagnostic_count}, 2, 'round-trip summary keeps diagnostic count');
    is_deeply(
        $decoded->{unique_codes},
        [qw(FSMGEN_MISSING_DECLARATION FSMGEN_STRICT_INFIX_ASSIGNMENT)],
        'round-trip summary keeps sorted unique codes',
    );
    is($decoded->{severity_counts}{error}, 1, 'round-trip summary keeps error count');
    is($decoded->{severity_counts}{warning}, 1, 'round-trip summary keeps warning count');
};

done_testing();

sub contains_blessed {
    my ($value) = @_;
    return 0 if blessed($value) && blessed($value) eq 'JSON::PP::Boolean';
    return 1 if blessed($value);
    return 0 unless ref($value);

    if (ref($value) eq 'ARRAY') {
        return 1 if grep { contains_blessed($_) } @$value;
        return 0;
    }

    if (ref($value) eq 'HASH') {
        return 1 if grep { contains_blessed($_) } values %$value;
        return 0;
    }

    return 0;
}
