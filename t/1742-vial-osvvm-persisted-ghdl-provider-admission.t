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

subtest 'persisted GHDL provider matches the selected plan' => sub {
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
    my $staging_identity = '.artifacts/tmp/vial-scale/' . ('a' x 64)
        . '/validation/00';
    my $source_set = [];
    my $raw = {
        repository_root => abs_path('.'),
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
        provider => ghdl_provider_projection($raw->{execution_plan}),
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity => 'emission/' . ('b' x 64),
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

sub validate_envelope {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_validated_request_envelope(
        @_,
    );
}
