#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs validate_envelope
);
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;

subtest 'persisted provider verification matches the selected plan' => sub {
    my ($raw, $route, $envelope) = exact_inputs();
    is_deeply(
        $envelope->{provider_verification},
        provider_projection($raw->{execution_plan}),
        'persisted provider projection is exact',
    );
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted provider projection admits');
};

subtest 'foreign persisted provider evidence rejects at reload' => sub {
    my @control = (
        [provider => 'ForeignVerificationProvider'],
        [version => '2026.06'],
        [root_commit => 'f' x 40],
        [root_tree => 'e' x 40],
        [materialization_manifest_sha256 => 'd' x 64],
        [provider_source_identity => 'provider-source/' . ('c' x 64)],
    );

    for my $control (@control) {
        my ($field, $foreign) = @$control;
        my ($raw, $route, $envelope) = exact_inputs();
        isnt($envelope->{provider_verification}{$field}, $foreign,
            "$field control changes the selected provider projection");
        $envelope->{provider_verification}{$field} = $foreign;
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$field rejects at persisted-envelope reload");
        like($@,
            qr/OSVVM runtime persisted provider verification changed/,
            "$field retains the exact reload diagnostic") unless $ok;
    }
};

done_testing();

sub provider_projection {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_provider_projection(
        @_,
    );
}
