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

subtest 'persisted emission identity binds its exact authority' => sub {
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

sub exact_inputs {
    my $osvvm_authority = {
        provider => 'OSVVM',
        version => '2026.05',
        root_commit => '1' x 40,
        root_tree => '2' x 40,
        materialization_manifest_sha256 => '3' x 64,
        provider_source_identity => 'provider-source/' . ('4' x 64),
    };
    my $tool_authority = {
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
    my $plan_identity = 'osvvm-plan/' . ('7' x 64);
    my $execution_plan_id = 'plan/' . ('8' x 64);
    my $materialization_identity = 'osvvm-materialization/' . ('9' x 64);
    my $workload_identity = 'workload/' . ('a' x 64);
    my $staging_identity = '.artifacts/tmp/vial-scale/' . ('b' x 64)
        . '/validation/00';
    my $source_set = [];
    my $raw = {
        repository_root => abs_path('.'),
        construction => {workload_identity => $workload_identity},
        materialization => {report_identity => $materialization_identity},
        execution_plan => {
            plan_identity => $plan_identity,
            provider_authority => $osvvm_authority,
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
        expected_emission_identity($raw, $request);
    my $envelope = {
        schema => 'fsmgen.vial_osvvm_runtime_lifecycle_request.v1',
        schema_version => 1,
        materialization_identity => $materialization_identity,
        plan_identity => $plan_identity,
        provider_verification =>
            FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_provider_projection(
                $raw->{execution_plan},
            ),
        request => $request,
    };
    return ($raw, $route, $envelope);
}

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

sub validate_envelope {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_validated_request_envelope(
        @_,
    );
}
