#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

my $repo_root = abs_path(File::Spec->catdir($FindBin::Bin, '..'));
my $fsmgen = File::Spec->catfile($repo_root, 'bin', 'fsmgen');
my $fixture = File::Spec->catfile($repo_root, 'isf', 'verification_observation_metadata.isf');
my $fsm_fixture = File::Spec->catfile($repo_root, 'fsm', 'trial_0.fsm');

subtest 'CLI emits inert UVM passive monitor skeleton and artifact manifest' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($workdir, 'verification');

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => [
            $fsmgen,
            '--quiet',
            '--emit-verification-output', 'uvm-passive-monitor',
            '--verification-outdir', $outdir,
            $fixture,
        ],
    );

    ok($success, 'verification-output CLI succeeds');
    is(join('', @{$stdout_buf || []}), '', 'quiet verification-output CLI keeps stdout clean');
    is(join('', @{$stderr_buf || []}), '', 'verification-output CLI keeps stderr clean');

    my $package_path = File::Spec->catfile(
        $outdir,
        'uvm',
        'verification_observation_metadata_observation_uvm_pkg.sv',
    );
    my $manifest_path = File::Spec->catfile($outdir, 'verification-output-manifest.json');

    ok(-f $package_path, 'UVM package skeleton is written under uvm/');
    ok(-f $manifest_path, 'verification-output manifest is written at outdir root');

    my $package = read_file($package_path);
    like($package, qr/package verification_observation_metadata_observation_uvm_pkg;/, 'package name is actor-derived');
    like($package, qr/class link_rx_snapshot extends uvm_sequence_item;/, 'snapshot item class is emitted');
    like($package, qr/class link_rx_monitor extends uvm_monitor;/, 'monitor class is emitted');
    like($package, qr/uvm_analysis_port #\(link_rx_snapshot\) observed_ap;/, 'analysis port declaration is emitted');
    like($package, qr/\bbit valid;/, 'scalar input signal field is emitted');
    like($package, qr/\bbit ready;/, 'scalar output signal field is emitted');
    like($package, qr/\bbit \[7:0\] data;/, 'vector signal field is emitted');
    like($package, qr/OBSERVATION_CLOCK = "clk"/, 'clock metadata is emitted');
    like($package, qr/OBSERVATION_RESET = "rst_n"/, 'reset metadata is emitted');
    unlike($package, qr/run_phase/, 'skeleton has no run_phase');
    unlike($package, qr/virtual\s+interface/, 'skeleton has no virtual interface');
    unlike($package, qr/uvm_config_db/, 'skeleton has no config_db lookup');
    unlike($package, qr/observed_ap\.write/, 'skeleton does not publish transactions');
    unlike($package, qr/scoreboard/i, 'skeleton has no scoreboard behavior');
    unlike($package, qr/coverage/i, 'skeleton has no coverage behavior');

    my $manifest = decode_json(read_file($manifest_path));
    is($manifest->{schema_version}, 1, 'manifest schema version is stable');
    is($manifest->{mode}, 'verification_output', 'manifest records verification-output mode');
    is($manifest->{target}, 'uvm_passive_monitor_skeleton', 'manifest records canonical target id');
    is($manifest->{source}{resolved_path}, $fixture, 'manifest preserves resolved source path');
    is($manifest->{source}{source_kind}, 'isf', 'manifest records ISF source kind');
    is($manifest->{actor}, 'verification_observation_metadata', 'manifest records actor name');

    my $artifact = $manifest->{artifacts}[0];
    is($artifact->{kind}, 'uvm_passive_monitor_skeleton_package', 'manifest records artifact kind');
    is($artifact->{language}, 'systemverilog', 'manifest records artifact language');
    is($artifact->{uvm_version}, '1.2', 'manifest records UVM version');
    is($artifact->{relpath}, 'uvm/verification_observation_metadata_observation_uvm_pkg.sv', 'manifest records package relpath');
    is($artifact->{package_name}, 'verification_observation_metadata_observation_uvm_pkg', 'manifest records package name');

    my $observation = $artifact->{observations}[0];
    is($observation->{name}, 'link_rx', 'manifest records observation name');
    is($observation->{role}, 'passive_monitor', 'manifest records observation role');
    is($observation->{snapshot_class}, 'link_rx_snapshot', 'manifest records snapshot class');
    is($observation->{monitor_class}, 'link_rx_monitor', 'manifest records monitor class');
    is_deeply(
        $observation->{signals},
        [
            { name => 'valid', direction => 'input',  width => 1 },
            { name => 'ready', direction => 'output', width => 1 },
            { name => 'data',  direction => 'input',  width => 8 },
        ],
        'manifest records source-ordered observed signals',
    );

    ok(!$manifest->{validation}{claimed_uvm_compile_support}, 'manifest does not claim UVM compile support');
    is($manifest->{validation}{uvm_compile_validator}, 'none', 'manifest records no UVM compile validator');
    ok($manifest->{validation}{artifact_shape_checked}, 'manifest records artifact-shape validation');
    ok($manifest->{validation}{inert_behavior_checked}, 'manifest records inert-behavior validation');
};

subtest 'CLI rejects unsupported verification-output requests before artifacts' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($workdir, 'verification');

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'bad-target',
            '--verification-outdir', $outdir,
            $fixture,
        ],
        qr/unsupported verification output target 'bad-target'/,
        'unsupported target fails closed',
    );

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'uvm-passive-monitor',
            $fixture,
        ],
        qr/--verification-outdir is required/,
        'missing verification outdir fails closed',
    );

    assert_failure(
        [
            $fsmgen,
            '--emit-schedule-json',
            '--emit-verification-output', 'uvm-passive-monitor',
            '--verification-outdir', $outdir,
            $fixture,
        ],
        qr/--emit-verification-output cannot be combined/,
        'report mode combination fails closed',
    );

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'uvm-passive-monitor',
            '--verification-outdir', $outdir,
            $fsm_fixture,
        ],
        qr/currently supports \.isf sources only/,
        'direct FSM source fails closed',
    );

    my $no_observe = File::Spec->catfile($workdir, 'no_observe.isf');
    write_file($no_observe, <<'ISF');
(actor no_observe
  (clock clk)
  (interface
    (input valid)
    (output done))
  (transaction main
    (on valid)
    (complete done)))
ISF

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'uvm-passive-monitor',
            '--verification-outdir', File::Spec->catdir($workdir, 'no-observe-out'),
            $no_observe,
        ],
        qr/requires at least one passive_monitor observation/,
        'ISF without observation metadata fails closed',
    );
};

done_testing();

sub assert_failure {
    my ($command, $pattern, $label) = @_;

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(command => $command);
    ok(!$success, $label);
    is(join('', @{$stdout_buf || []}), '', "$label keeps stdout clean");
    like(join('', @{$stderr_buf || []}), $pattern, "$label reports targeted diagnostic");
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "cannot write $path: $!";
    print {$fh} $text;
    close $fh;
}
