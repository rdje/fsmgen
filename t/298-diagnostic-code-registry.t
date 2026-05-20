#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::DiagnosticCodes qw(
    diagnostic_code_ids
    diagnostic_code_metadata
    diagnostic_code_registry
    known_diagnostic_code
);

my @codes = diagnostic_code_ids();
ok(@codes >= 62, 'diagnostic registry starts with the current expected-failure corpus surface');
is(scalar(diagnostic_code_ids()), scalar(@codes), 'diagnostic_code_ids is scalar-context safe');

my %seen;
for my $code (@codes) {
    like($code, qr/\AFSMGEN_[A-Z0-9_]+\z/, "diagnostic code $code uses the public code shape");
    ok(!$seen{$code}++, "diagnostic code $code is unique");
    ok(known_diagnostic_code($code), "diagnostic code $code is known through lookup");

    my $metadata = diagnostic_code_metadata($code);
    is(ref($metadata), 'HASH', "diagnostic code $code exposes metadata");
    is($metadata->{severity}, 'error', "diagnostic code $code is an error diagnostic");
    is($metadata->{stability}, 'stable', "diagnostic code $code is stable");
    like($metadata->{family} || '', qr/\A(?:strict_mode|language_contract|direct_generation_contract|composition_contract)\z/,
        "diagnostic code $code records a known family");
    ok($metadata->{summary}, "diagnostic code $code records a summary");
}

my $registry = diagnostic_code_registry();
is_deeply([sort keys %{$registry}], \@codes, 'registry keys match diagnostic_code_ids');

my $mutable = diagnostic_code_metadata('FSMGEN_STRICT_INFIX_ASSIGNMENT');
$mutable->{severity} = 'warning';
is(
    diagnostic_code_metadata('FSMGEN_STRICT_INFIX_ASSIGNMENT')->{severity},
    'error',
    'metadata lookup returns defensive copies',
);

$registry->{FSMGEN_STRICT_INFIX_ASSIGNMENT}{severity} = 'warning';
is(
    diagnostic_code_registry()->{FSMGEN_STRICT_INFIX_ASSIGNMENT}{severity},
    'error',
    'registry lookup returns defensive copies',
);

ok(!known_diagnostic_code('FSMGEN_DOES_NOT_EXIST'), 'unknown diagnostic codes are rejected');
is(diagnostic_code_metadata('FSMGEN_DOES_NOT_EXIST'), undef, 'unknown diagnostic metadata lookup returns undef');

done_testing();
