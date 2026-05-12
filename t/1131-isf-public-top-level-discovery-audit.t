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
use FSM::Support::EmbeddingContract qw(embedding_nested_presence_key_map);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_public_top_level_keys
);

subtest 'direct ISF public top-level discovery list is exact and unique' => sub {
    my $contract = build_isf_public_interface_contract();

    assert_contract_public_keys($contract, 'direct ISF public-interface contract');
    is_deeply(
        $contract->{public_top_level_presence_keys},
        isf_public_interface_public_top_level_keys(),
        'direct contract uses the owner public top-level key list',
    );
    is_deeply(
        embedding_nested_presence_key_map()->{isf_public_interface},
        isf_public_interface_public_top_level_keys(),
        'embedding contract discovers the same ISF public top-level key list',
    );
};

subtest 'manifest ISF public top-level discovery list is exact and unique' => sub {
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
        my $contract = $view->{payload}{embedding}{isf_public_interface};
        assert_contract_public_keys($contract, "$label ISF public-interface contract");
        is_deeply(
            $view->{payload}{embedding}{section_contract}{nested_presence_key_map}{isf_public_interface},
            isf_public_interface_public_top_level_keys(),
            "$label embedding map discovers the ISF public top-level key list",
        );
    }
};

done_testing();

sub assert_contract_public_keys {
    my ($contract, $label) = @_;
    my $keys = $contract->{public_top_level_presence_keys};

    ok(ref($keys) eq 'ARRAY', "$label publishes public_top_level_presence_keys as an array");
    assert_unique_scalar_list($keys, "$label public_top_level_presence_keys");
    is_deeply(
        sorted([keys %{$contract}]),
        sorted($keys),
        "$label public_top_level_presence_keys exactly match payload keys",
    );
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    for my $value (@{$values || []}) {
        ok(!ref($value), "$label entry '$value' is scalar");
        next if ref($value);
        ok(length($value), "$label entry '$value' is non-empty");
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
