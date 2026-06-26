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

use FSM::Adapter::IAL2::PPIF;

subtest 'adapter accepts the selected .axi profile alias and preserves lowering' => sub {
    ok(-f sample_axi_path(), 'tracked runnable .axi profile-alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_axi_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_path());

    is($alias->{layer}, 'IAL2', '.axi parser result remains IAL2');
    is($alias->{generated_ial1}{name}, 'axi_aw_valid_ready_monitor.isf', '.axi exposes generated IAL1 artifact');
    is(
        $alias->{generated_ial1}{text},
        $ppif->{generated_ial1}{text},
        '.axi mirrors selected .ppif generated IAL1 text',
    );
    is_deeply(
        $alias->{generated_ial0}{files},
        $ppif->{generated_ial0}{files},
        '.axi mirrors selected .ppif generated IAL0 files',
    );
    is($alias->{report}{source_object}{id}, 'axi-valid-ready-aw', '.axi preserves source object id');
    is($alias->{report}{target_channel}{protocol}, 'axi4', '.axi preserves explicit AXI-family profile');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.axi keeps direct IAL2-to-IAL0 lowering forbidden');
};

subtest 'adapter rejects .axi profile and behavior boundaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.axi');
    my $missing_profile_source = slurp(sample_ppif_path());
    $missing_profile_source =~ s/^\s*\(profile axi4\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, '.axi without explicit profile is rejected');
    like(
        $@,
        qr/\.axi source '.*missing_profile\.axi' is missing required \(profile \.\.\.\) clause/,
        '.axi missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.axi');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, '.axi with a non-AXI profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.axi profile alias; expected axi, axi3, axi4, or axi5/,
        '.axi suffix/profile mismatch diagnostic is targeted',
    );

    my $bundle_path = File::Spec->catfile($tempdir, 'bundle.axi');
    write_file($bundle_path, slurp(sample_bundle_ppif_path()));
    my $bundle_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($bundle_path); 1 };
    ok(!$bundle_ok, '.axi bundle behavior remains outside the first alias slice');
    like(
        $@,
        qr/supports only one AXI-family valid-ready-channel object in this slice/,
        '.axi unsupported AXI behavior diagnostic is targeted',
    );
};

subtest 'CLI check and semantic JSON report .axi public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_axi_path()],
    );
    ok($success, '--check --json succeeds for .axi');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for .axi');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, '.axi check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_axi_path()),
        '.axi check JSON reports the public alias source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.axi_profile_alias_aw_valid_ready',
        '.axi check JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $check_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.axi check JSON records profile-alias source kind',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_axi_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for .axi');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for .axi');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, '.axi semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_axi_path()),
        '.axi semantic JSON reports the public alias source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.axi_profile_alias_aw_valid_ready',
        '.axi semantic JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $semantic_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.axi semantic JSON records profile-alias source kind',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        '.axi semantic JSON payload describes the generated .fsm semantic root',
    );
};

subtest 'CLI schedule JSON and outdir expose review artifacts for .axi' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_axi_path()],
    );
    ok($schedule_success, '--emit-schedule-json succeeds for .axi');
    is(join('', @{$schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for .axi');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{target_channel}{protocol}, 'axi4', '.axi schedule JSON reports the AXI-family profile');
    is($schedule_report->{layering}{direct_ial2_to_ial0}, 0, '.axi schedule JSON keeps direct IAL2-to-IAL0 forbidden');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_aw_alias.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_axi_path()],
    );

    ok($success, 'CLI generation succeeds for .axi profile alias');
    is(join('', @{$stderr_buf || []}), '', '.axi generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.isf'), '.axi --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.fsm'), '.axi --outdir writes generated .fsm');
    ok(-f $hdl, '.axi --output writes generated HDL');
    like(slurp($hdl), qr/\bmodule\s+axi_aw_valid_ready_monitor\b/, '.axi generated HDL contains the monitor module');
};

subtest 'CLI distinguishes unsupported known aliases and unknown suffixes' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $chi_path = File::Spec->catfile($tempdir, 'sample.chi');
    write_file($chi_path, slurp(sample_ppif_path()));
    my ($chi_success, undef, undef, $chi_stdout, undef) = run(
        command => ['./bin/fsmgen', '--check', '--json', $chi_path],
    );
    ok(!$chi_success, '.chi remains unsupported');
    my $chi_report = decode_json(join('', @{$chi_stdout || []}));
    ok(!$chi_report->{success}, '.chi check JSON reports failure');
    like(
        $chi_report->{diagnostics}[0]{message},
        qr/known IAL2 alias candidate but is not supported in this slice/,
        '.chi failure is reported as unsupported known alias',
    );

    my $unknown_path = File::Spec->catfile($tempdir, 'sample.foo');
    write_file($unknown_path, slurp(sample_ppif_path()));
    my ($unknown_success, undef, undef, $unknown_stdout, undef) = run(
        command => ['./bin/fsmgen', '--check', '--json', $unknown_path],
    );
    ok(!$unknown_success, '.foo remains an unknown suffix');
    my $unknown_report = decode_json(join('', @{$unknown_stdout || []}));
    ok(!$unknown_report->{success}, '.foo check JSON reports failure');
    like(
        $unknown_report->{diagnostics}[0]{message},
        qr/source suffix '\.foo' is not a known FSMGen source suffix/,
        '.foo failure is reported as unknown suffix',
    );
};

done_testing();

sub sample_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_valid_ready.ppif');
}

sub sample_axi_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_valid_ready.axi');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub sample_bundle_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_w_valid_ready_bundle.ppif');
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    my $text = do { local $/; <$fh> };
    close $fh or die "close $path: $!";
    return $text;
}
