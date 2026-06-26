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

subtest 'CLI emits inert VHDL observation package skeleton and artifact manifest' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($workdir, 'verification');

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => [
            $fsmgen,
            '--quiet',
            '--emit-verification-output', 'vhdl-observation-package',
            '--verification-outdir', $outdir,
            $fixture,
        ],
    );

    ok($success, 'verification-output CLI succeeds');
    is(join('', @{$stdout_buf || []}), '', 'quiet verification-output CLI keeps stdout clean');
    is(join('', @{$stderr_buf || []}), '', 'verification-output CLI keeps stderr clean');

    my $package_path = File::Spec->catfile(
        $outdir,
        'vhdl',
        'verification_observation_metadata_observation_vhdl_pkg.vhd',
    );
    my $manifest_path = File::Spec->catfile($outdir, 'verification-output-manifest.json');

    ok(-f $package_path, 'VHDL package skeleton is written under vhdl/');
    ok(-f $manifest_path, 'verification-output manifest is written at outdir root');

    my $package = read_file($package_path);
    like($package, qr/package verification_observation_metadata_observation_vhdl_pkg is/, 'package name is actor-derived');
    like($package, qr/end package verification_observation_metadata_observation_vhdl_pkg;/, 'package closes with the actor-derived name');
    like($package, qr/LINK_RX_OBSERVATION_NAME : string := "link_rx";/, 'observation name metadata is emitted');
    like($package, qr/LINK_RX_OBSERVATION_ROLE : string := "passive_monitor";/, 'observation role metadata is emitted');
    like($package, qr/LINK_RX_OBSERVATION_CLOCK : string := "clk";/, 'clock metadata is emitted');
    like($package, qr/LINK_RX_OBSERVATION_RESET : string := "rst_n";/, 'reset metadata is emitted');
    like($package, qr/LINK_RX_SIGNAL_COUNT : natural := 3;/, 'signal count metadata is emitted');
    like($package, qr/LINK_RX_SIGNAL_0_NAME : string := "valid";/, 'first signal name is emitted');
    like($package, qr/LINK_RX_SIGNAL_0_DIRECTION : string := "input";/, 'first signal direction is emitted');
    like($package, qr/LINK_RX_SIGNAL_0_WIDTH : natural := 1;/, 'first signal width is emitted');
    like($package, qr/LINK_RX_SIGNAL_1_NAME : string := "ready";/, 'second signal name is emitted');
    like($package, qr/LINK_RX_SIGNAL_1_DIRECTION : string := "output";/, 'second signal direction is emitted');
    like($package, qr/LINK_RX_SIGNAL_1_WIDTH : natural := 1;/, 'second signal width is emitted');
    like($package, qr/LINK_RX_SIGNAL_2_NAME : string := "data";/, 'third signal name is emitted');
    like($package, qr/LINK_RX_SIGNAL_2_DIRECTION : string := "input";/, 'third signal direction is emitted');
    like($package, qr/LINK_RX_SIGNAL_2_WIDTH : natural := 8;/, 'third signal width is emitted');
    unlike($package, qr/\blibrary\b/i, 'skeleton has no library clause');
    unlike($package, qr/\buse\b/i, 'skeleton has no use clause');
    unlike($package, qr/\bentity\b/i, 'skeleton has no entity');
    unlike($package, qr/\barchitecture\b/i, 'skeleton has no architecture');
    unlike($package, qr/\bprocess\b/i, 'skeleton has no process');
    unlike($package, qr/\bassert\b/i, 'skeleton has no VHDL assert');
    unlike($package, qr/\bpsl\b/i, 'skeleton has no PSL');
    unlike($package, qr/scoreboard/i, 'skeleton has no scoreboard behavior');
    unlike($package, qr/coverage/i, 'skeleton has no coverage behavior');

    my $manifest = decode_json(read_file($manifest_path));
    is($manifest->{schema_version}, 1, 'manifest schema version is stable');
    is($manifest->{mode}, 'verification_output', 'manifest records verification-output mode');
    is($manifest->{target}, 'vhdl_observation_package_skeleton', 'manifest records canonical target id');
    is($manifest->{source}{resolved_path}, $fixture, 'manifest preserves resolved source path');
    is($manifest->{source}{source_kind}, 'isf', 'manifest records ISF source kind');
    is($manifest->{actor}, 'verification_observation_metadata', 'manifest records actor name');

    my $artifact = $manifest->{artifacts}[0];
    is($artifact->{kind}, 'vhdl_observation_package_skeleton', 'manifest records artifact kind');
    is($artifact->{language}, 'vhdl', 'manifest records artifact language');
    is($artifact->{relpath}, 'vhdl/verification_observation_metadata_observation_vhdl_pkg.vhd', 'manifest records package relpath');
    is($artifact->{package_name}, 'verification_observation_metadata_observation_vhdl_pkg', 'manifest records package name');

    my $observation = $artifact->{observations}[0];
    is($observation->{name}, 'link_rx', 'manifest records observation name');
    is($observation->{role}, 'passive_monitor', 'manifest records observation role');
    is($observation->{constant_prefix}, 'LINK_RX', 'manifest records constant prefix');
    is_deeply(
        $observation->{signals},
        [
            { name => 'valid', direction => 'input',  width => 1 },
            { name => 'ready', direction => 'output', width => 1 },
            { name => 'data',  direction => 'input',  width => 8 },
        ],
        'manifest records source-ordered observed signals',
    );

    ok(!$manifest->{validation}{claimed_vhdl_compile_support}, 'manifest does not claim VHDL compile support');
    is($manifest->{validation}{vhdl_syntax_validator}, 'none', 'manifest records no VHDL syntax validator');
    ok(!$manifest->{validation}{claimed_psl_support}, 'manifest does not claim PSL support');
    is($manifest->{validation}{psl_validator}, 'none', 'manifest records no PSL validator');
    ok($manifest->{validation}{artifact_shape_checked}, 'manifest records artifact-shape validation');
    ok($manifest->{validation}{inert_behavior_checked}, 'manifest records inert-behavior validation');
};

subtest 'CLI rejects unsupported VHDL verification-output requests before artifacts' => sub {
    my $workdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($workdir, 'verification');

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'vhdl-observation-package',
            $fixture,
        ],
        qr/--verification-outdir is required/,
        'missing verification outdir fails closed',
    );

    assert_failure(
        [
            $fsmgen,
            '--emit-schedule-json',
            '--emit-verification-output', 'vhdl-observation-package',
            '--verification-outdir', $outdir,
            $fixture,
        ],
        qr/--emit-verification-output cannot be combined/,
        'report mode combination fails closed',
    );

    assert_failure(
        [
            $fsmgen,
            '--emit-verification-output', 'vhdl-observation-package',
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
            '--emit-verification-output', 'vhdl-observation-package',
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
