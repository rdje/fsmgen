#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Test::More;

use lib 'perl';

use FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement;

my $JSON = JSON::PP->new->canonical(1);

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

sub exact_inputs {
    my $provider_authority = {
        provider => 'OSVVM',
        version => '2026.05',
        root_commit => '1' x 40,
        root_tree => '2' x 40,
        materialization_manifest_sha256 => '3' x 64,
        provider_source_identity => 'provider-source/' . ('4' x 64),
    };
    my $tool_authority = exact_tool_authority();
    my $plan_identity = 'osvvm-plan/' . ('5' x 64);
    my $execution_plan_id = 'plan/' . ('6' x 64);
    my $materialization_identity = 'osvvm-materialization/' . ('7' x 64);
    my $workload_identity = 'workload/' . ('9' x 64);
    my $staging_identity = '.artifacts/tmp/vial-scale/' . ('8' x 64)
        . '/validation/00';
    my $source_set = [];
    my $raw = {
        repository_root => abs_path('.'),
        construction => {workload_identity => $workload_identity},
        materialization => {report_identity => $materialization_identity},
        execution_plan => {
            plan_identity => $plan_identity,
            provider_authority => $provider_authority,
            tool_authority => $tool_authority,
        },
        context => {staging_identity => $staging_identity},
    };
    my $route = {
        projection => {execution_ir => {plan_id => $execution_plan_id}},
    };
    my $request = {
        provider =>
            FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_ghdl_provider_projection(
                $raw->{execution_plan},
            ),
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity => undef,
        commands => {},
        validation => {
            expected_plan_id => $execution_plan_id,
            run_repetitions => 1,
        },
        storage_context => {
            schema => 'fsmgen.vial_ghdl_lifecycle_storage.v1',
            schema_version => 1,
            mode => 'osvvm_architecture_scale_measurement',
            staging_identity => "$staging_identity/lifecycle",
            containment => 'outer_worker_process_group',
        },
    };
    $request->{emission_identity} =
        FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_emission_identity(
            $raw, $plan_identity, $request->{source_identity},
            $request->{commands},
        );
    my $envelope = {
        schema => 'fsmgen.vial_osvvm_runtime_lifecycle_request.v1',
        schema_version => 1,
        materialization_identity => $materialization_identity,
        plan_identity => $plan_identity,
        provider_verification => provider_projection(
            $raw->{execution_plan},
        ),
        request => $request,
    };
    return ($raw, $route, $envelope);
}

sub exact_tool_authority {
    return {
        root => '.artifacts/cache/tools/ghdl/6.0.0',
        archive => {
            relpath => '.artifacts/cache/downloads/ghdl-6.0.0.tar.gz',
            bytes => 12_345,
            sha256 => '5' x 64,
        },
        binary => {
            relpath => '.artifacts/cache/tools/ghdl/6.0.0/bin/ghdl',
            sha256 => '6' x 64,
        },
        version_output => "GHDL 6.0.0 (selected)\n",
    };
}

sub provider_projection {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_provider_projection(
        @_,
    );
}

sub validate_envelope {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_validated_request_envelope(
        @_,
    );
}
