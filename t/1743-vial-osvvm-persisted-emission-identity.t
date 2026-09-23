#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs provider_cache_present provider_cache_skip validate_envelope
);

my $JSON = JSON::PP->new->canonical(1);

subtest 'persisted emission identity binds its exact authority' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my ($raw, $route, $envelope) = exact_inputs();
    is(
        $envelope->{request}{emission_identity},
        expected_emission_identity($raw, $envelope->{request}),
        'persisted emission identity is reconstructed exactly',
    );
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted emission identity admits');
};

subtest 'foreign persisted emission identity rejects at reload' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my ($raw, $route, $envelope) = exact_inputs();
    my $foreign = 'emission/' . ('f' x 64);
    isnt($envelope->{request}{emission_identity}, $foreign,
        'control changes the well-formed emission identity');
    $envelope->{request}{emission_identity} = $foreign;
    my $ok = eval {
        validate_envelope($raw, $route, $envelope);
        1;
    };
    ok(!$ok, 'foreign emission identity rejects at persisted reload');
    like($@, qr/OSVVM runtime persisted emission identity changed/,
        'foreign emission identity retains the exact reload diagnostic')
        unless $ok;
};

done_testing();

sub expected_emission_identity {
    my ($raw, $request) = @_;
    return 'emission/' . sha256_hex($JSON->encode({
        workload_identity => $raw->{construction}{workload_identity},
        materialization_identity =>
            $raw->{materialization}{report_identity},
        plan_identity => $raw->{execution_plan}{plan_identity},
        source_identity => $request->{source_identity},
        commands => $request->{commands},
    }));
}
