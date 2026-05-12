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
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_parser_method_names
    isf_public_interface_scheduler_method_names
);

subtest 'direct ISF public method-name metadata is exact and unique' => sub {
    assert_method_names(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF public method-name metadata is exact and unique' => sub {
    my @views = (
        {
            label => 'in-process capability manifest',
            payload => build_capability_manifest(),
        },
        {
            label => 'CLI capability manifest',
            payload => run_capability_manifest('--capability-manifest'),
        },
        {
            label => 'CLI capability manifest alias',
            payload => run_capability_manifest('--emit-capability-manifest'),
        },
    );

    for my $view (@views) {
        my $label = $view->{label};
        assert_method_names(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_method_names {
    my ($contract, $label) = @_;

    is_deeply(
        $contract->{parser_method_names},
        isf_public_interface_parser_method_names(),
        "$label parser method names are exact",
    );
    assert_unique_scalar_list(
        $contract->{parser_method_names},
        "$label parser method names",
    );

    is_deeply(
        $contract->{scheduler_method_names},
        isf_public_interface_scheduler_method_names(),
        "$label scheduler method names are exact",
    );
    assert_unique_scalar_list(
        $contract->{scheduler_method_names},
        "$label scheduler method names",
    );
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
        like($value, qr/\A[A-Za-z_]\w*\z/, "$label entry '$value' is a method name");
        ok(!$seen{$value}++, "$label does not duplicate '$value'");
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
