#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use JSON::PP ();
use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs provider_cache_present provider_cache_skip validate_envelope
);

subtest 'selected persisted lifecycle storage admits' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my ($raw, $route, $envelope) = exact_inputs();
    my $storage = $envelope->{request}{storage_context};
    is_deeply(
        [sort keys %$storage],
        [sort qw(schema schema_version mode staging_identity containment)],
        'fixture carries the closed selected lifecycle-storage projection',
    );
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted lifecycle storage admits');
    ok(!-e File::Spec->catfile(
            $raw->{repository_root}, $raw->{context}{staging_identity}),
        'selected admission creates no lifecycle stage');
};

subtest 'foreign lifecycle-storage authority rejects at reload' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my @cases = (
        [
            'foreign schema',
            sub { $_[0]{schema} = 'fsmgen.vial_ghdl_lifecycle_storage.v9' },
            qr/OSVVM runtime persisted lifecycle storage changed/,
        ],
        [
            'string schema version',
            sub { $_[0]{schema_version} = '1' },
            qr/OSVVM runtime persisted lifecycle storage changed/,
        ],
        [
            'boolean schema version',
            sub { $_[0]{schema_version} = JSON::PP::true },
            qr/OSVVM runtime persisted lifecycle storage changed/,
        ],
        [
            'unknown field',
            sub { $_[0]{foreign} = 'value' },
            qr/OSVVM runtime persisted lifecycle storage has unknown key 'foreign'/,
        ],
    );

    for my $case (@cases) {
        my ($label, $mutate, $diagnostic) = @$case;
        my ($raw, $route, $envelope) = exact_inputs();
        $mutate->($envelope->{request}{storage_context});
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$label rejects at persisted reload");
        like($@, $diagnostic, "$label retains its admission diagnostic")
            unless $ok;
        ok(!-e File::Spec->catfile(
                $raw->{repository_root}, $raw->{context}{staging_identity}),
            "$label creates no lifecycle stage");
    }
};

done_testing();
