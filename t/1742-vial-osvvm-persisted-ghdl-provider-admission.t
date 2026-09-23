#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'perl', 't/lib';

use FSM::Test::OSVVMRuntimePersistedRequest qw(
    exact_inputs provider_cache_present provider_cache_skip validate_envelope
);
use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;

subtest 'persisted GHDL provider matches the selected plan' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my ($raw, $route, $envelope) = exact_inputs();
    is_deeply(
        $envelope->{request}{provider},
        ghdl_provider_projection($raw->{execution_plan}),
        'persisted GHDL provider projection is exact',
    );
    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'selected persisted GHDL provider admits');
};

subtest 'foreign persisted GHDL provider rejects at reload' => sub {
    plan skip_all => provider_cache_skip() unless provider_cache_present();
    my @control = (
        [root => '.artifacts/cache/tools/ghdl/foreign'],
        [archive => '.artifacts/cache/downloads/ghdl-foreign.tar.gz'],
        [archive_bytes => 54_321],
        [archive_sha256 => 'f' x 64],
        [binary => '.artifacts/cache/tools/ghdl/foreign/bin/ghdl'],
        [binary_sha256 => 'e' x 64],
        [version_output => "GHDL 6.0.1 (foreign)\n"],
    );

    for my $control (@control) {
        my ($field, $foreign) = @$control;
        my ($raw, $route, $envelope) = exact_inputs();
        isnt($envelope->{request}{provider}{$field}, $foreign,
            "$field control changes the selected GHDL provider");
        $envelope->{request}{provider}{$field} = $foreign;
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$field rejects at persisted-envelope reload");
        like($@,
            qr/OSVVM runtime persisted GHDL provider changed/,
            "$field retains the exact reload diagnostic") unless $ok;
    }
};

done_testing();

sub ghdl_provider_projection {
    my ($plan) = @_;
    my $tool = $plan->{tool_authority};
    return {
        root => $tool->{root},
        archive => $tool->{archive}{relpath},
        archive_bytes => 0 + $tool->{archive}{bytes},
        archive_sha256 => $tool->{archive}{sha256},
        binary => $tool->{binary}{relpath},
        binary_sha256 => $tool->{binary}{sha256},
        version_output => $tool->{version_output},
    };
}
