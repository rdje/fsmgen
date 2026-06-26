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

subtest 'adapter accepts the selected .apb profile alias and preserves lowering' => sub {
    ok(-f sample_apb_path(), 'tracked runnable .apb profile-alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_apb_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ppif_path());

    is($alias->{layer}, 'IAL2', '.apb parser result remains IAL2');
    is($alias->{kind}, 'protocol_intent.apb_requester_transfer', '.apb parser result keeps APB requester-transfer kind');
    is($alias->{generated_ial1}{name}, 'apb_requester.isf', '.apb exposes generated IAL1 artifact');
    is(
        $alias->{generated_ial1}{text},
        $ppif->{generated_ial1}{text},
        '.apb mirrors selected .ppif generated IAL1 text',
    );
    is_deeply(
        $alias->{generated_ial0}{files},
        $ppif->{generated_ial0}{files},
        '.apb mirrors selected .ppif generated IAL0 files',
    );
    is($alias->{report}{source_object}{id}, 'fsmgen-apb-requester-transfer', '.apb preserves source object id');
    is($alias->{report}{target_protocol}{profile}, 'apb', '.apb preserves explicit APB profile');
    is($alias->{report}{target_protocol}{object}, 'apb-requester', '.apb preserves APB requester object');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.apb keeps direct IAL2-to-IAL0 lowering forbidden');
};

subtest 'adapter rejects .apb profile and behavior boundaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.apb');
    my $missing_profile_source = slurp(sample_ppif_path());
    $missing_profile_source =~ s/^\s*\(profile apb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, '.apb without explicit profile is rejected');
    like(
        $@,
        qr/\.apb source '.*missing_profile\.apb' is missing required \(profile \.\.\.\) clause/,
        '.apb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.apb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, '.apb with a non-APB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.apb profile alias; expected apb/,
        '.apb suffix/profile mismatch diagnostic is targeted',
    );

    my $unsupported_object_path = File::Spec->catfile($tempdir, 'valid_ready_object.apb');
    my $unsupported_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $unsupported_object_source =~ s/\(profile valid-ready\)/(profile apb)/;
    write_file($unsupported_object_path, $unsupported_object_source);
    my $unsupported_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($unsupported_object_path); 1 };
    ok(!$unsupported_object_ok, '.apb valid-ready object remains outside the first alias slice');
    like(
        $@,
        qr/profile apb requires exactly one \(apb-requester \.\.\.\) or \(apb-completer \.\.\.\) object in this slice/,
        '.apb unsupported object diagnostic is targeted',
    );
};

subtest 'CLI check and semantic JSON report .apb public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_apb_path()],
    );
    ok($success, '--check --json succeeds for .apb');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for .apb');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, '.apb check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_apb_path()),
        '.apb check JSON reports the public alias source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.apb_profile_alias_requester_transfer',
        '.apb check JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $check_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.apb check JSON records profile-alias source kind',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_apb_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for .apb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for .apb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, '.apb semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_apb_path()),
        '.apb semantic JSON reports the public alias source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.apb_profile_alias_requester_transfer',
        '.apb semantic JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $semantic_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.apb semantic JSON records profile-alias source kind',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        '.apb semantic JSON payload describes the generated .fsm semantic root',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'apb_requester',
        '.apb semantic JSON records the generated APB requester module',
    );
};

subtest 'CLI schedule JSON and outdir expose review artifacts for .apb' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_apb_path()],
    );
    ok($schedule_success, '--emit-schedule-json succeeds for .apb');
    is(join('', @{$schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for .apb');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{target_protocol}{profile}, 'apb', '.apb schedule JSON reports the APB profile');
    is($schedule_report->{target_protocol}{object}, 'apb-requester', '.apb schedule JSON reports the APB requester object');
    is($schedule_report->{layering}{direct_ial2_to_ial0}, 0, '.apb schedule JSON keeps direct IAL2-to-IAL0 forbidden');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'apb_requester_alias.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_apb_path()],
    );

    ok($success, 'CLI generation succeeds for .apb profile alias');
    is(join('', @{$stderr_buf || []}), '', '.apb generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'apb_requester.isf'), '.apb --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'apb_requester.fsm'), '.apb --outdir writes generated .fsm');
    ok(-f $hdl, '.apb --output writes generated HDL');
    like(slurp($hdl), qr/\bmodule\s+apb_requester\b/, '.apb generated HDL contains the requester module');
};

subtest 'CLI distinguishes unsupported known aliases and unknown suffixes after .apb ships' => sub {
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
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer.ppif');
}

sub sample_apb_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'apb_requester_transfer.apb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
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
