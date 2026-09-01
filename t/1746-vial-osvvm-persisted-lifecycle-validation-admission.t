#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs validate_envelope
);

subtest 'selected persisted lifecycle validation admits' => sub {
    my ($raw, $route, $envelope) = exact_inputs();
    my $validation = $envelope->{request}{validation};
    is_deeply(
        [sort keys %$validation],
        [sort qw(
            expected_record_counts expected_diagnostic_codes
            expected_domain_id expected_fixture_id expected_plan_id
            expected_random_decisions_sha256 expected_run_ids
            expected_observation_catalog run_repetitions
        )],
        'fixture carries the closed selected lifecycle-validation projection',
    );
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted lifecycle validation admits');
    ok(!-e File::Spec->catfile(
            $raw->{repository_root}, $raw->{context}{staging_identity}),
        'selected admission creates no lifecycle stage');
};

subtest 'foreign lifecycle-validation authority rejects at reload' => sub {
    my @cases = (
        [
            'record count',
            sub { ++$_[0]{expected_record_counts}{samples} },
        ],
        [
            'diagnostic code',
            sub { $_[0]{expected_diagnostic_codes}[0] = 'VIAL_EXPECT_ERROR' },
        ],
        [
            'domain identity',
            sub { $_[0]{expected_domain_id} = 'domain/foreign' },
        ],
        [
            'fixture identity',
            sub { $_[0]{expected_fixture_id} = 'foreign::fixture' },
        ],
        [
            'random-decision digest',
            sub { $_[0]{expected_random_decisions_sha256} = 'f' x 64 },
        ],
        [
            'run order',
            sub {
                @{$_[0]{expected_run_ids}}[0, 1] =
                    @{$_[0]{expected_run_ids}}[1, 0];
            },
        ],
        [
            'observation catalog',
            sub { ++$_[0]{expected_observation_catalog}{total_width} },
        ],
        [
            'unknown field',
            sub { $_[0]{foreign} = 'value' },
        ],
    );

    for my $case (@cases) {
        my ($label, $mutate) = @$case;
        my ($raw, $route, $envelope) = exact_inputs();
        $mutate->($envelope->{request}{validation});
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$label rejects at persisted reload");
        like(
            $@,
            $label eq 'unknown field'
                ? qr/OSVVM runtime persisted lifecycle validation has unknown key 'foreign'/
                : qr/OSVVM runtime persisted lifecycle validation changed/,
            "$label retains its admission diagnostic",
        ) unless $ok;
        ok(!-e File::Spec->catfile(
                $raw->{repository_root}, $raw->{context}{staging_identity}),
            "$label creates no lifecycle stage");
    }
};

done_testing();
