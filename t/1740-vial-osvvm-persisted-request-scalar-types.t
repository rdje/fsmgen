#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP ();
use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs provider_cache_present provider_cache_skip validate_envelope
);

my $JSON = JSON::PP->new->canonical(1);

subtest 'persisted request retains canonical JSON integers' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my ($raw, $route, $envelope) = exact_inputs();
    is($JSON->encode($envelope->{schema_version}), '1',
        'envelope schema version is a JSON number');
    is($JSON->encode(
            $envelope->{request}{validation}{run_repetitions}), '1',
        'persisted repetition count is a JSON number');

    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'exact persisted request envelope admits');
    is($request->{repo_root}, $raw->{repository_root},
        'admitted request receives the selected repository root');
};

subtest 'numeric-looking persisted values do not impersonate numbers' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my @control = (
        ['envelope schema-version string', '"1"', sub {
            $_[0]{schema_version} = sprintf('%d', 1);
            return $_[0]{schema_version};
        }],
        ['envelope schema-version boolean', 'true', sub {
            $_[0]{schema_version} = JSON::PP::true;
            return $_[0]{schema_version};
        }],
        ['repetition-count string', '"1"', sub {
            $_[0]{request}{validation}{run_repetitions} =
                sprintf('%d', 1);
            return $_[0]{request}{validation}{run_repetitions};
        }],
        ['repetition-count boolean', 'true', sub {
            $_[0]{request}{validation}{run_repetitions} =
                JSON::PP::true;
            return $_[0]{request}{validation}{run_repetitions};
        }],
    );

    for my $control (@control) {
        my ($label, $encoded, $mutate) = @$control;
        my ($raw, $route, $envelope) = exact_inputs();
        my $forged = $mutate->($envelope);
        is($JSON->encode($forged), $encoded,
            "$label uses the intended foreign JSON type");
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$label rejects at persisted-envelope reload");
        like($@, qr/OSVVM runtime (?:lifecycle request envelope|persisted lifecycle validation) changed/,
            "$label retains the exact reload diagnostic") unless $ok;
    }
};

done_testing();
