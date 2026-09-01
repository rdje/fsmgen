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

subtest 'persisted request retains canonical JSON integers' => sub {
    my ($raw, $route, $envelope) = exact_inputs();
    is($JSON->encode($envelope->{schema_version}), '1',
        'envelope schema version is a JSON number');
    is($JSON->encode(
            $envelope->{request}{validation}{run_repetitions}), '1',
        'persisted repetition count is a JSON number');

    my $request = validate_envelope($raw, $route, $envelope);
    ok($request, 'exact persisted request envelope admits');
    is($request->{repo_root}, $raw->{repository_root},
        'admitted request receives the selected repository root');
};

subtest 'numeric-looking persisted values do not impersonate numbers' => sub {
    my @control = (
        ['envelope schema-version string', '"1"', sub {
            $_[0]{schema_version} = sprintf('%d', 1);
            return $_[0]{schema_version};
        }],
        ['envelope schema-version boolean', 'true', sub {
            $_[0]{schema_version} = JSON::PP::true;
            return $_[0]{schema_version};
        }],
        ['repetition-count string', '"1"', sub {
            $_[0]{request}{validation}{run_repetitions} =
                sprintf('%d', 1);
            return $_[0]{request}{validation}{run_repetitions};
        }],
        ['repetition-count boolean', 'true', sub {
            $_[0]{request}{validation}{run_repetitions} =
                JSON::PP::true;
            return $_[0]{request}{validation}{run_repetitions};
        }],
    );

    for my $control (@control) {
        my ($label, $encoded, $mutate) = @$control;
        my ($raw, $route, $envelope) = exact_inputs();
        my $forged = $mutate->($envelope);
        is($JSON->encode($forged), $encoded,
            "$label uses the intended foreign JSON type");
        my $ok = eval {
            validate_envelope($raw, $route, $envelope);
            1;
        };
        ok(!$ok, "$label rejects at persisted-envelope reload");
        like($@, qr/OSVVM runtime (?:lifecycle request envelope|persisted validation plan) changed/,
            "$label retains the exact reload diagnostic") unless $ok;
    }
};

done_testing();

sub exact_inputs {
    my $plan_identity = 'osvvm-plan/' . ('2' x 64);
    my $execution_plan_id = 'plan/' . ('3' x 64);
    my $materialization_identity = 'osvvm-materialization/' . ('4' x 64);
    my $staging_identity = '.artifacts/tmp/vial-scale/' . ('5' x 64)
        . '/validation/00';
    my $source_set = [];
    my $raw = {
        repository_root => abs_path('.'),
        materialization => {report_identity => $materialization_identity},
        execution_plan => {plan_identity => $plan_identity},
        context => {staging_identity => $staging_identity},
    };
    my $route = {
        projection => {execution_ir => {plan_id => $execution_plan_id}},
    };
    my $request = {
        provider => {},
        source_set => $source_set,
        source_identity =>
            'source/' . sha256_hex($JSON->encode($source_set)),
        emission_identity => 'emission/' . ('6' x 64),
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
        provider_verification => {},
        request => $request,
    };
    return ($raw, $route, $envelope);
}

sub validate_envelope {
    return FSM::VIAL::ArchitectureScaleOSVVMRuntimeMeasurement::_validated_request_envelope(
        @_,
    );
}
