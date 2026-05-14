#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(build_isf_public_interface_contract);

subtest 'schedule report freeze boundary is explicit in every contract view' => sub {
    my @views = (
        {
            label => 'direct ISF public-interface contract',
            contract => build_isf_public_interface_contract(),
        },
        {
            label => 'in-process capability manifest',
            contract => build_capability_manifest()->{embedding}{isf_public_interface},
        },
        {
            label => 'CLI capability manifest',
            contract => run_capability_manifest('--capability-manifest')->{embedding}{isf_public_interface},
        },
        {
            label => 'CLI capability manifest alias',
            contract => run_capability_manifest('--emit-capability-manifest')->{embedding}{isf_public_interface},
        },
    );

    for my $view (@views) {
        assert_freeze_boundary($view->{contract}, $view->{label});
    }
};

done_testing();

sub assert_freeze_boundary {
    my ($contract, $label) = @_;

    is($contract->{status}, 'bounded_public', "$label remains bounded public");
    ok(
        !$contract->{schedule_report_full_schema_stable},
        "$label does not claim full schedule-report schema stability",
    );
    ok(
        $contract->{evolves_with_isf_implementation},
        "$label remains implementation-coupled",
    );
    ok(
        ref($contract->{schedule_report_top_level_keys}) eq 'ARRAY'
            && @{$contract->{schedule_report_top_level_keys}},
        "$label advertises the bounded top-level key family",
    );
    ok(
        ref($contract->{schedule_report_presence_key_family_map}) eq 'HASH',
        "$label advertises grouped presence key families",
    );

    for my $family (sort keys %{$contract->{schedule_report_presence_key_family_map} || {}}) {
        like($family, qr/_keys\z/, "$label presence family '$family' is a key family");
        my $values = $contract->{schedule_report_presence_key_family_map}{$family};
        ok(ref($values) eq 'ARRAY', "$label presence family '$family' is an array");
        next unless ref($values) eq 'ARRAY';
        ok(@$values, "$label presence family '$family' is non-empty");
    }
}

sub run_capability_manifest {
    my ($mode) = @_;
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', $mode],
    );

    ok($success, "$mode succeeds");
    is(join('', @{$stderr_buf || []}), '', "$mode keeps stderr clean");

    return decode_json(join('', @{$stdout_buf || []}));
}
