#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use FSM::Support::DiagnosticCodes qw(
    diagnostic_code_ids
    diagnostic_code_metadata
    diagnostic_code_registry
    known_diagnostic_code
);
use FSM::Test::DefensiveCopyAudit qw(
    contains_sentinel
    mutate_structure
);

my $sentinel = '__mutated_by_t490__';

subtest 'diagnostic code id list remains stable and sorted' => sub {
    my @ids = diagnostic_code_ids();
    ok(@ids, 'diagnostic code registry exposes at least one code');
    is_deeply(\@ids, [sort @ids], 'diagnostic code ids are returned in sorted order');

    my @mutated_ids = @ids;
    push @mutated_ids, $sentinel;
    is_deeply([diagnostic_code_ids()], \@ids, 'caller mutation of an id-list copy cannot affect later id lookups');
};

subtest 'diagnostic code registry returns fresh nested metadata structures' => sub {
    my @ids = diagnostic_code_ids();
    my $first = diagnostic_code_registry();
    mutate_structure($first, $sentinel);
    delete $first->{$ids[0]};

    my $second = diagnostic_code_registry();
    ok(!contains_sentinel($second, $sentinel), 'fresh registry is not affected by prior caller mutation');
    is_deeply([sort keys %{$second}], \@ids, 'fresh registry preserves the canonical code set');

    for my $code (@ids) {
        ok(ref($second->{$code}) eq 'HASH', "fresh registry keeps metadata hash for $code");
        is($second->{$code}{severity}, 'error', "fresh registry keeps severity for $code");
        ok(defined $second->{$code}{summary} && length $second->{$code}{summary}, "fresh registry keeps summary for $code");
    }
};

subtest 'single-code metadata lookups return fresh nested structures' => sub {
    my $registry = diagnostic_code_registry();

    for my $code (diagnostic_code_ids()) {
        my $first = diagnostic_code_metadata($code);
        mutate_structure($first, $sentinel);

        my $second = diagnostic_code_metadata($code);
        ok(!contains_sentinel($second, $sentinel), "fresh metadata lookup for $code is not affected by prior caller mutation");
        is_deeply($second, $registry->{$code}, "fresh metadata lookup for $code matches the registry entry");
        ok(known_diagnostic_code($code), "known_diagnostic_code recognizes $code");
    }
};

done_testing();
