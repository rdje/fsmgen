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
    isf_public_interface_cli_strict_hdl_generation_success_shape
);

subtest 'direct ISF strict CLI success metadata is exact' => sub {
    assert_strict_success_metadata(
        build_isf_public_interface_contract(),
        'direct ISF public-interface contract',
    );
};

subtest 'manifest ISF strict CLI success metadata is exact' => sub {
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
        assert_strict_success_metadata(
            $view->{payload}{embedding}{isf_public_interface},
            "$label ISF public-interface contract",
        );
    }
};

subtest 'public strict ISF CLI success path follows advertised shape' => sub {
    my $isf_file = repo_file('isf/apb_requester.isf');
    my $outdir = tempdir(CLEANUP => 1);
    my $hdl_output = File::Spec->catfile($outdir, 'apb_requester_strict.sv');

    my ($success, $error_message, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => [
            './bin/fsmgen',
            '--strict',
            '--quiet',
            '--output',
            $hdl_output,
            $isf_file,
        ],
    );

    ok($success, '--strict file.isf HDL generation succeeds for APB');
    is(join('', @{$stderr_buf || []}), '', '--strict file.isf HDL generation keeps stderr empty');
    ok(-f $hdl_output, '--strict file.isf HDL generation writes requested output');
    like(slurp($hdl_output), qr/\bmodule\s+apb_requester\b/, '--strict generated HDL contains APB module');
};

done_testing();

sub assert_strict_success_metadata {
    my ($contract, $label) = @_;

    is(
        $contract->{cli_strict_hdl_generation_success_shape},
        isf_public_interface_cli_strict_hdl_generation_success_shape(),
        "$label cli_strict_hdl_generation_success_shape is exact",
    );
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

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "cannot close $path: $!";
    return $text;
}
