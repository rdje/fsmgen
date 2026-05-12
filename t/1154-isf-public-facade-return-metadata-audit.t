#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;
use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_actor_shell_required_keys
    isf_public_interface_lower_return_shape
    isf_public_interface_parse_file_return_shape
    isf_public_interface_parse_source_return_shape
    isf_public_interface_report_return_shape
    isf_public_interface_schedule_report_top_level_keys
);

subtest 'direct ISF facade return metadata is exact' => sub {
    assert_return_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF facade return metadata is exact' => sub {
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
        assert_return_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public in-process facades return advertised value shapes' => sub {
    my $path = File::Spec->catfile($FindBin::Bin, '..', 'isf', 'apb_requester.isf');
    my $source = slurp($path);
    my $adapter = FSM::Adapter::ISF->new();
    my $scheduler = FSM::Scheduler::ISF->new();

    my $file_actor = $adapter->parse_file($path);
    my $source_actor = $adapter->parse_source($source, 'inline-apb-requester.isf');
    assert_actor_shell($file_actor, 'parse_file return');
    assert_actor_shell($source_actor, 'parse_source return');

    my $lowered = $scheduler->lower($file_actor);
    ok(ref($lowered) eq 'HASH', 'lower return is a hash reference');
    ok(ref($lowered->{files}) eq 'HASH', 'lower return exposes files map');
    ok(exists $lowered->{files}{'apb_requester.fsm'}, 'lower files map contains APB scheduled .fsm');

    my $report_json = $scheduler->report($file_actor);
    ok(!ref($report_json), 'report return is a scalar JSON string');
    my $report = decode_json($report_json);
    for my $key (@{isf_public_interface_schedule_report_top_level_keys()}) {
        ok(exists $report->{$key}, "report JSON includes top-level key $key");
    }
};

done_testing();

sub assert_return_metadata {
    my ($contract, $label) = @_;

    my @checks = (
        [parse_file_return_shape => isf_public_interface_parse_file_return_shape()],
        [parse_source_return_shape => isf_public_interface_parse_source_return_shape()],
        [lower_return_shape => isf_public_interface_lower_return_shape()],
        [report_return_shape => isf_public_interface_report_return_shape()],
    );

    for my $check (@checks) {
        my ($field, $expected) = @$check;
        is($contract->{$field}, $expected, "$label $field is exact");
    }
}

sub assert_actor_shell {
    my ($actor, $label) = @_;

    ok(ref($actor) eq 'HASH', "$label is a hash reference");
    for my $key (@{isf_public_interface_actor_shell_required_keys()}) {
        ok(exists $actor->{$key}, "$label includes actor shell key $key");
    }
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
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
