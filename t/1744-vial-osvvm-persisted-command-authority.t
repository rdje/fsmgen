#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs rehash_request validate_envelope
);

subtest 'selected persisted command and source plan admits' => sub {
    my ($raw, $route, $envelope) = exact_inputs();
    is(scalar(@{$envelope->{request}{source_set}}), 68,
        'fixture carries the complete selected lifecycle source set');
    is(scalar(@{$envelope->{request}{commands}{provider_analyze}}), 61,
        'fixture carries every selected provider-analysis command');
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted command and source plan admits');
    ok(!-e File::Spec->catfile(
            $raw->{repository_root}, $raw->{context}{staging_identity}),
        'selected admission creates no lifecycle stage');
};

subtest 'self-consistent provider order change rejects at reload' => sub {
    my ($raw, $route, $envelope) = exact_inputs();
    my $request = $envelope->{request};
    @{$request->{commands}{provider_analyze}}[0, 1] =
        @{$request->{commands}{provider_analyze}}[1, 0];
    @{$request->{source_set}}[0, 1] = @{$request->{source_set}}[1, 0];
    rehash_request($raw, $envelope);
    isnt(
        $request->{commands}{provider_analyze}[0][-1],
        $raw->{execution_plan}{commands}{provider_analyze}[0]{argv}[-1],
        'control changes the first selected provider-analysis source',
    );
    my $ok = eval {
        validate_envelope($raw, $route, $envelope);
        1;
    };
    ok(!$ok, 'self-consistent provider order rejects at persisted reload');
    like($@, qr/OSVVM runtime lifecycle source authority changed/,
        'provider order retains the exact selected-plan diagnostic')
        unless $ok;
    ok(!-e File::Spec->catfile(
            $raw->{repository_root}, $raw->{context}{staging_identity}),
        'rejected admission creates no lifecycle stage');
};

done_testing();
