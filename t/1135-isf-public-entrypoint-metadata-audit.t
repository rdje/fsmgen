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

my $expected_entrypoints = {
    manifest => './bin/fsmgen --capability-manifest -> embedding.isf_public_interface',
    cli => [
        './bin/fsmgen path/to/file.isf',
        './bin/fsmgen --emit-schedule-json path/to/file.isf',
        './bin/fsmgen --outdir path/to/outdir path/to/file.isf',
    ],
    in_process => [
        'FSM::Adapter::ISF->new(%args)',
        'FSM::Adapter::ISF->new(%args)->parse_file($path)',
        'FSM::Adapter::ISF->new(%args)->parse_source($source_text, $source_label)',
        'FSM::Scheduler::ISF->new(%args)',
        'FSM::Scheduler::ISF->new(%args)->lower($actor)',
        'FSM::Scheduler::ISF->new(%args)->report($actor)',
    ],
};

subtest 'direct ISF public entrypoint metadata is exact and unique' => sub {
    assert_entrypoints(
        build_isf_public_interface_contract()->{entrypoints},
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF public entrypoint metadata is exact and unique' => sub {
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
        assert_entrypoints(
            $view->{payload}{embedding}{isf_public_interface}{entrypoints},
            "$label ISF public-interface contract",
        );
    }
};

done_testing();

sub assert_entrypoints {
    my ($entrypoints, $label) = @_;

    ok(ref($entrypoints) eq 'HASH', "$label publishes entrypoints as a hash");
    is_deeply(
        sorted([keys %{$entrypoints || {}}]),
        sorted([keys %$expected_entrypoints]),
        "$label entrypoint keys are exact",
    );
    is(
        $entrypoints->{manifest},
        $expected_entrypoints->{manifest},
        "$label manifest entrypoint is exact",
    );

    for my $family (qw(cli in_process)) {
        is_deeply(
            $entrypoints->{$family},
            $expected_entrypoints->{$family},
            "$label $family entrypoints are exact",
        );
        assert_unique_scalar_list($entrypoints->{$family}, "$label $family entrypoints");
    }
}

sub assert_unique_scalar_list {
    my ($values, $label) = @_;
    my %seen;

    ok(ref($values) eq 'ARRAY', "$label is an array");
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
