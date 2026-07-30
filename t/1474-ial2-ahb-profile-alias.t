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

subtest 'adapter accepts the selected .ahb profile alias and preserves lowering' => sub {
    ok(-f sample_ahb_alias_path(), 'tracked runnable .ahb profile-alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_ppif_path());

    is($alias->{layer}, 'IAL2', '.ahb parser result remains IAL2');
    is($alias->{kind}, 'protocol_intent.ahb_requester', '.ahb parser result keeps AHB requester kind');
    is($alias->{mode}, 'requester', '.ahb parser result keeps requester mode');
    is($alias->{generated_ial1}{name}, 'amba_requester.isf', '.ahb exposes generated IAL1 artifact');
    is(
        $alias->{generated_ial1}{text},
        $ppif->{generated_ial1}{text},
        '.ahb mirrors selected .ppif generated IAL1 text',
    );
    is_deeply(
        $alias->{generated_ial0}{files},
        $ppif->{generated_ial0}{files},
        '.ahb mirrors selected .ppif generated IAL0 files',
    );
    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', '.ahb report keeps the AHB requester schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-requester', '.ahb preserves source object id');
    is($alias->{report}{target_protocol}{profile}, 'ahb', '.ahb preserves explicit AHB profile');
    is($alias->{report}{target_protocol}{object}, 'ahb-requester', '.ahb preserves AHB requester object');
    is($alias->{report}{generated_artifacts}{ial1}{name}, 'amba_requester.isf', '.ahb report names generated IAL1 before IAL0');
    is_deeply($alias->{report}{generated_artifacts}{ial0}{files}, ['amba_requester.fsm'], '.ahb report names generated IAL0 artifact');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.ahb keeps direct IAL2-to-IAL0 lowering forbidden');

    my %alias_residue = map { $_->{id} => 1 } @{$alias->{report}{unsupported_residue}};
    ok(!$alias_residue{ahb_profile_alias_deferred}, '.ahb report removes stale profile-alias residue');
    ok($alias_residue{ahb_completer_subordinate_deferred}, '.ahb report keeps completer/subordinate residue explicit');

    my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
    ok($ppif_residue{ahb_profile_alias_deferred}, '.ppif AHB requester report preserves existing profile-alias residue');
};

subtest 'adapter rejects .ahb profile and behavior boundaries' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = sample_ahb_ppif();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, '.ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        '.ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, '.ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        '.ahb suffix/profile mismatch diagnostic is targeted',
    );

    my $wrong_object_path = File::Spec->catfile($tempdir, 'wrong_object.ahb');
    my $wrong_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $wrong_object_source =~ s/\(profile valid-ready\)/(profile ahb)/;
    write_file($wrong_object_path, $wrong_object_source);
    my $wrong_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($wrong_object_path); 1 };
    ok(!$wrong_object_ok, '.ahb profile with non-AHB behavior is rejected');
    like(
        $@,
        qr/profile ahb requires exactly one \(ahb-requester \.\.\.\) object, exactly one \(ahb-subordinate \.\.\.\) object, the selected aggregate one-requester\/one-subordinate \(ahb-interconnect \.\.\.\) shape, or the selected aggregate one-requester\/two-subordinate \(ahb-interconnect \.\.\.\) shape in this slice/,
        '.ahb unsupported object diagnostic names the selected aggregate shape',
    );

    my $duplicate_path = File::Spec->catfile($tempdir, 'duplicate.ahb');
    my $duplicate_source = sample_ahb_ppif();
    my $duplicate_object = sample_ahb_object();
    $duplicate_object =~ s/\(ahb-requester amba_requester\b/(ahb-requester amba_requester_shadow/;
    $duplicate_source =~ s/\)\s*\z/  $duplicate_object\)\n/s;
    write_file($duplicate_path, $duplicate_source);
    my $duplicate_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($duplicate_path); 1 };
    ok(!$duplicate_ok, '.ahb duplicate requester objects are rejected');
    like(
        $@,
        qr/supports exactly one \(ahb-requester \.\.\.\) object in this slice/,
        '.ahb duplicate-object diagnostic is targeted',
    );
};

subtest 'CLI check and semantic JSON report .ahb public source identity' => sub {
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_alias_path()],
    );
    ok($check_success, '--check --json succeeds for .ahb');
    is(join('', @{$check_stderr || []}), '', '--check --json keeps stderr clean for .ahb');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, '.ahb check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_alias_path()),
        '.ahb check JSON reports the public alias source path',
    );
    is(
        $check_report->{result}{module_name},
        'amba_requester',
        '.ahb check JSON reports generated module name',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ahb_profile_alias_requester',
        '.ahb check JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $check_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.ahb check JSON records profile-alias source kind',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_alias_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for .ahb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for .ahb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, '.ahb semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_alias_path()),
        '.ahb semantic JSON reports the public alias source path',
    );
    is(
        $semantic_report->{generation_result_snapshot}{summary}{module_name},
        'amba_requester',
        '.ahb semantic JSON reports generated module name',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        '.ahb semantic JSON payload describes the generated .fsm semantic root',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ahb_profile_alias_requester',
        '.ahb semantic JSON support accounting names the profile-alias corpus entry',
    );
    is(
        $semantic_report->{support_accounting}{source_kind},
        'ial2_profile_alias',
        '.ahb semantic JSON records profile-alias source kind',
    );
};

subtest 'CLI schedule JSON and outdir expose review artifacts for .ahb' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_alias_path()],
    );
    ok($schedule_success, '--emit-schedule-json succeeds for .ahb');
    is(join('', @{$schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for .ahb');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.ahb_requester.v1', '.ahb schedule JSON reports the AHB requester schema');
    is($schedule_report->{target_protocol}{profile}, 'ahb', '.ahb schedule JSON reports the AHB profile');
    is($schedule_report->{generated_artifacts}{ial1}{name}, 'amba_requester.isf', '.ahb schedule JSON exposes generated IAL1 artifact');
    is_deeply($schedule_report->{generated_artifacts}{ial0}{files}, ['amba_requester.fsm'], '.ahb schedule JSON exposes generated IAL0 artifact');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{ahb_profile_alias_deferred}, '.ahb schedule JSON removes stale profile-alias residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'amba_requester.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_alias_path()],
    );

    ok($success, 'CLI generation succeeds for .ahb profile alias');
    is(join('', @{$stderr_buf || []}), '', '.ahb generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.isf'), '.ahb --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.fsm'), '.ahb --outdir writes generated .fsm');
    ok(-f $hdl, '.ahb --output writes generated HDL');
    like(slurp($hdl), qr/\bmodule\s+amba_requester\b/, '.ahb generated HDL contains the requester module');
};

subtest 'CLI distinguishes unsupported known aliases and unknown suffixes after .ahb ships' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $chi_path = File::Spec->catfile($tempdir, 'sample.chi');
    write_file($chi_path, sample_ahb_ppif());
    my ($chi_success, undef, undef, $chi_stdout, undef) = run(
        command => ['./bin/fsmgen', '--quiet', '--check', '--json', $chi_path],
    );
    ok(!$chi_success, '.chi remains unsupported');
    my $chi_report = decode_json(join('', @{$chi_stdout || []}));
    ok(!$chi_report->{success}, '.chi check JSON reports failure');
    like(
        $chi_report->{diagnostics}[0]{message},
        qr/source suffix '\.chi' is a known IAL2 alias candidate but is not supported in this slice/,
        '.chi failure is reported as unsupported known alias',
    );

    my $unknown_path = File::Spec->catfile($tempdir, 'sample.foo');
    write_file($unknown_path, sample_ahb_ppif());
    my ($unknown_success, undef, undef, $unknown_stdout, undef) = run(
        command => ['./bin/fsmgen', '--quiet', '--check', '--json', $unknown_path],
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

sub sample_ahb_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub sample_ahb_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub sample_ahb_ppif {
    return slurp(sample_ahb_ppif_path());
}

sub sample_ahb_object {
    my $source = sample_ahb_ppif();
    $source =~ /\n  (\(ahb-requester\b.*)\)\s*\z/s
        or die 'Cannot extract AHB requester object from sample';
    return $1;
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
