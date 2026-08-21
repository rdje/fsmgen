#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::OSVVM2026_05Materialization;
use FSM::VIAL::Backend::VHDLOSVVM2026_05;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $json = JSON::PP->new->canonical(1);
my $dependency_root = '.artifacts/cache/providers/osvvm/2026.05/source';
my @requirements = qw(
    advanced_coverage advanced_data_structure advanced_randomization
    advanced_reporting advanced_scoreboard advanced_synchronization
    verification_component_adapter
);
my $provider_manifest = $json->decode(slurp_raw(repo_path(
    'vial', 'review_gallery', 'vhdl_osvvm_qualified',
    'ahb_base_output_advanced_services', 'evidence',
    'provider-materialization.json',
)));
my $built = build_plan();

ok(FSM::VIAL::Backend::VHDLOSVVM2026_05->can('with_provider_evaluation'),
    'backend exposes one sealed provider-evaluation boundary');
BAIL_OUT('provider-evaluation boundary is not implemented')
    unless FSM::VIAL::Backend::VHDLOSVVM2026_05->can('with_provider_evaluation');

my $verify_calls = 0;
my ($leaked_evaluation, $first_snapshot);
{
    no warnings 'redefine';
    local *FSM::VIAL::Backend::OSVVM2026_05Materialization::verify = sub {
        my ($class, $args) = @_;
        is($class, 'FSM::VIAL::Backend::OSVVM2026_05Materialization',
            'evaluation invokes the exact materialization authority');
        is_deeply($args, {dependency_root => $dependency_root},
            'evaluation verifies the exact repository-local provider source');
        $verify_calls++;
        return {
            ok => JSON::PP::true,
            status => 'complete_recursive_verified',
            manifest => clone($provider_manifest),
            diagnostics => [],
        };
    };

    my $evaluated = FSM::VIAL::Backend::VHDLOSVVM2026_05
        ->with_provider_evaluation({
            dependency_root => $dependency_root,
            consumer => sub {
                my ($evaluation) = @_;
                $leaked_evaluation = $evaluation;
                is(ref($evaluation),
                    'FSM::VIAL::Backend::VHDLOSVVM2026_05::ProviderEvaluation',
                    'consumer receives only the opaque evaluation object');

                my $first = $evaluation->emit(backend_args());
                ok($first->{ok}, 'first evaluation-local emission succeeds');
                diag($json->encode($first->{diagnostics})) unless $first->{ok};
                $first_snapshot = clone($first);
                $first->{provider_materialization}{root_commit} = '0' x 40;

                my $second = $evaluation->emit(backend_args());
                ok($second->{ok}, 'second evaluation-local emission succeeds');
                is($json->encode($second), $json->encode($first_snapshot),
                    'reused verification remains defensive and byte-identical');

                my $mismatch = backend_args();
                $mismatch->{dependency_root} =
                    '.artifacts/cache/providers/osvvm/2026.05/different';
                provider_evaluation_failure(
                    $evaluation->emit($mismatch),
                    qr/provider source identity does not match/,
                    'mismatched provider source',
                );
                return $second;
            },
        });
    ok($evaluated->{ok}, 'sealed provider evaluation returns its consumer result');
    is($verify_calls, 1,
        'two accepted emissions perform one complete provider verification');
    is($json->encode($evaluated), $json->encode($first_snapshot),
        'evaluation result preserves unchanged canonical emission bytes');

    provider_evaluation_failure(
        $leaked_evaluation->emit(backend_args()),
        qr/provider evaluation is stale or forged/,
        'evaluation retained after its callback',
    );

    my $forged_value = 1;
    my $forged = bless \$forged_value,
        'FSM::VIAL::Backend::VHDLOSVVM2026_05::ProviderEvaluation';
    provider_evaluation_failure(
        $forged->emit(backend_args()),
        qr/provider evaluation is stale or forged/,
        'caller-forged evaluation object',
    );

    my $failed_evaluation;
    my $consumer_failure = FSM::VIAL::Backend::VHDLOSVVM2026_05
        ->with_provider_evaluation({
            dependency_root => $dependency_root,
            consumer => sub {
                ($failed_evaluation) = @_;
                die "deliberate evaluation consumer failure\n";
            },
        });
    ok(!$consumer_failure->{ok}, 'consumer failure closes the evaluation');
    is($consumer_failure->{diagnostics}[0]{code},
        'VIAL_OSVVM_PROVIDER_EVALUATION_ERROR',
        'consumer failure uses the exact evaluation diagnostic family');
    like($consumer_failure->{diagnostics}[0]{message},
        qr/deliberate evaluation consumer failure/,
        'consumer failure retains its sanitized cause');
    provider_evaluation_failure(
        $failed_evaluation->emit(backend_args()),
        qr/provider evaluation is stale or forged/,
        'evaluation retained after consumer failure',
    );

    my $invalid_result_evaluation;
    my $invalid_result = FSM::VIAL::Backend::VHDLOSVVM2026_05
        ->with_provider_evaluation({
            dependency_root => $dependency_root,
            consumer => sub {
                ($invalid_result_evaluation) = @_;
                return [];
            },
        });
    provider_evaluation_failure(
        $invalid_result,
        qr/consumer must return one closed backend result/,
        'consumer result outside the closed backend contract',
    );
    provider_evaluation_failure(
        $invalid_result_evaluation->emit(backend_args()),
        qr/provider evaluation is stale or forged/,
        'evaluation retained after invalid consumer result',
    );

    my $standalone = FSM::VIAL::Backend::VHDLOSVVM2026_05->emit(backend_args());
    ok($standalone->{ok}, 'standalone emission still verifies and succeeds');
    is($json->encode($standalone), $json->encode($first_snapshot),
        'standalone and evaluation-local emission remain byte-identical');
    is($verify_calls, 4,
        'later evaluations and standalone emission each verify independently');
}

done_testing;

sub provider_evaluation_failure {
    my ($result, $message_re, $label) = @_;
    ok(!$result->{ok}, "$label fails closed");
    is($result->{diagnostics}[0]{code},
        'VIAL_OSVVM_PROVIDER_EVALUATION_ERROR',
        "$label uses the exact evaluation diagnostic family");
    like($result->{diagnostics}[0]{message}, $message_re,
        "$label retains an actionable diagnostic");
    is_deeply($result->{artifacts}, [], "$label publishes no artifact graph");
}

sub build_plan {
    my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
    my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    my $result = FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    die 'checked provider-evaluation plan did not build: '
        . $json->encode($result->{diagnostics}) unless $result->{ok};
    return $result;
}

sub backend_args {
    return {
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-vhdl-osvvm-provider-evaluation',
        backend_profile => 'vhdl_osvvm_qualified',
        dependency_root => $dependency_root,
        advanced_requirements => [@requirements],
    };
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if ref($value) eq 'JSON::PP::Boolean';
    return {map { $_ => clone($value->{$_}) } keys %$value}
        if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh> // '';
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
