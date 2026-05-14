#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::CapabilityManifest qw(build_capability_manifest);
use FSM::Support::ISFPublicInterfaceContract qw(
    build_isf_public_interface_contract
    isf_public_interface_cli_hdl_generation_success_shape
    isf_public_interface_cli_outdir_success_shape
    isf_public_interface_cli_schedule_json_success_shape
);

subtest 'direct ISF CLI success metadata is exact' => sub {
    assert_cli_success_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF CLI success metadata is exact' => sub {
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
        assert_cli_success_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public ISF CLI success paths follow advertised shapes' => sub {
    assert_schedule_json_cli();
    assert_outdir_cli();
    assert_hdl_generation_cli();
};

done_testing();

sub assert_cli_success_metadata {
    my ($contract, $label) = @_;

    my @checks = (
        [cli_schedule_json_success_shape => isf_public_interface_cli_schedule_json_success_shape()],
        [cli_outdir_success_shape => isf_public_interface_cli_outdir_success_shape()],
        [cli_hdl_generation_success_shape => isf_public_interface_cli_hdl_generation_success_shape()],
    );

    for my $check (@checks) {
        my ($field, $expected) = @$check;
        is($contract->{$field}, $expected, "$label $field is exact");
    }
}

sub assert_schedule_json_cli {
    my $isf_file = repo_file('isf/apb_requester.isf');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $isf_file],
    );

    ok($success, '--emit-schedule-json succeeds');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr empty');

    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{scheduled_fsm}, 'apb_requester.fsm', '--emit-schedule-json writes schedule JSON to stdout');
}

sub assert_outdir_cli {
    my $isf_file = repo_file('isf/spawn_parent.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'spawn_parent.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--quiet',
            '--outdir',
            $outdir,
            '--output',
            $hdl_output,
            $isf_file,
        ],
    );

    ok($success, '--outdir succeeds');
    is(join('', @{$stderr_buf || []}), '', '--outdir keeps stderr empty');
    ok(-f File::Spec->catfile($outdir, 'spawn_parent.fsm'), '--outdir writes parent scheduled .fsm');
    ok(-f File::Spec->catfile($outdir, 'child_worker.fsm'), '--outdir writes child scheduled .fsm');
    ok(-f File::Spec->catfile($outdir, 'spawn_parent_top.fsm'), '--outdir writes generated top .fsm');
    ok(-f $hdl_output, '--outdir writes requested HDL output');
}

sub assert_hdl_generation_cli {
    my $isf_file = repo_file('isf/apb_requester.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'apb_requester.sv');
    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $hdl_output, $isf_file],
    );

    ok($success, 'plain file.isf HDL generation succeeds');
    is(join('', @{$stderr_buf || []}), '', 'plain file.isf HDL generation keeps stderr empty');
    ok(-f $hdl_output, 'plain file.isf HDL generation writes requested output');
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

sub repo_file {
    my ($relpath) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split m{/}, $relpath);
}
