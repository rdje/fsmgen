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

subtest 'adapter accepts the selected AHB subordinate .ahb profile alias' => sub {
    ok(-f sample_ahb_subordinate_alias_path(), 'tracked runnable AHB subordinate .ahb alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_subordinate_alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_subordinate_ppif_path());

    is($alias->{layer}, 'IAL2', 'AHB subordinate .ahb parser result stays IAL2');
    is($alias->{kind}, 'protocol_intent.ahb_subordinate', 'AHB subordinate .ahb parser result keeps subordinate kind');
    is($alias->{mode}, 'subordinate', 'AHB subordinate .ahb parser result keeps subordinate mode');
    is($alias->{generated_ial1}{name}, 'ahb_lite_subordinate.isf', '.ahb exposes generated subordinate IAL1 artifact');
    is(
        $alias->{generated_ial1}{text},
        $ppif->{generated_ial1}{text},
        '.ahb mirrors selected subordinate .ppif generated IAL1 text',
    );
    is_deeply(
        $alias->{generated_ial0}{files},
        $ppif->{generated_ial0}{files},
        '.ahb mirrors selected subordinate .ppif generated IAL0 files',
    );
    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', '.ahb report keeps the AHB subordinate schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-lite-subordinate', '.ahb preserves subordinate source object id');
    is($alias->{report}{target_protocol}{profile}, 'ahb', '.ahb preserves explicit AHB profile');
    is($alias->{report}{target_protocol}{object}, 'ahb-subordinate', '.ahb preserves AHB subordinate object');
    is($alias->{report}{target_protocol}{role}, 'subordinate', '.ahb preserves AHB subordinate role');
    is($alias->{report}{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate.isf', '.ahb report names generated IAL1 before IAL0');
    is_deeply($alias->{report}{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate.fsm'], '.ahb report names generated IAL0 artifact');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.ahb keeps direct IAL2-to-IAL0 lowering forbidden');

    my %alias_residue = map { $_->{id} => 1 } @{$alias->{report}{unsupported_residue}};
    ok(!$alias_residue{ahb_subordinate_profile_alias_deferred}, '.ahb report removes stale subordinate profile-alias residue');
    ok($alias_residue{ahb_interconnect_generation_deferred}, '.ahb report keeps interconnect/decode residue explicit');
    ok($alias_residue{ahb_subordinate_optional_signal_residue}, '.ahb report keeps optional-signal residue explicit');
    ok($alias_residue{ahb_burst_seq_support_deferred}, '.ahb report keeps burst SEQ residue explicit');
    ok($alias_residue{ahb_verification_output_deferred}, '.ahb report keeps verification/backend residue explicit');

    my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
    ok($ppif_residue{ahb_subordinate_profile_alias_deferred}, '.ppif AHB subordinate report preserves alias-deferred residue');
};

subtest 'subordinate .ahb diagnostics stay distinct' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = sample_ahb_subordinate_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'subordinate .ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        'subordinate .ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'subordinate .ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        'subordinate .ahb suffix/profile mismatch diagnostic is targeted',
    );

    my $wrong_object_path = File::Spec->catfile($tempdir, 'wrong_object.ahb');
    my $wrong_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $wrong_object_source =~ s/\(profile valid-ready\)/(profile ahb)/;
    write_file($wrong_object_path, $wrong_object_source);
    my $wrong_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($wrong_object_path); 1 };
    ok(!$wrong_object_ok, '.ahb profile with unsupported object breadth is rejected');
    like(
        $@,
        qr/profile ahb requires exactly one \(ahb-requester \.\.\.\) object or exactly one \(ahb-subordinate \.\.\.\) object in this slice/,
        '.ahb unsupported object diagnostic is targeted',
    );

    my $mixed_path = File::Spec->catfile($tempdir, 'mixed.ahb');
    my $mixed_source = sample_ahb_subordinate_source();
    my $requester_object = sample_ahb_requester_object();
    $mixed_source =~ s/\)\s*\z/  $requester_object\)\n/s;
    write_file($mixed_path, $mixed_source);
    my $mixed_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mixed_path); 1 };
    ok(!$mixed_ok, 'mixed requester/subordinate .ahb objects are rejected');
    like(
        $@,
        qr/cannot mix \(ahb-requester \.\.\.\) with \(ahb-subordinate \.\.\.\)/,
        'mixed AHB object diagnostic is targeted',
    );

    my $duplicate_path = File::Spec->catfile($tempdir, 'duplicate.ahb');
    my $duplicate_source = sample_ahb_subordinate_source();
    my $duplicate_object = sample_ahb_subordinate_object();
    $duplicate_object =~ s/\(ahb-subordinate ahb_lite_subordinate\b/(ahb-subordinate ahb_lite_subordinate_shadow/;
    $duplicate_source =~ s/\)\s*\z/  $duplicate_object\)\n/s;
    write_file($duplicate_path, $duplicate_source);
    my $duplicate_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($duplicate_path); 1 };
    ok(!$duplicate_ok, 'duplicate subordinate .ahb objects are rejected');
    like(
        $@,
        qr/supports exactly one \(ahb-subordinate \.\.\.\) object in this slice/,
        'duplicate subordinate diagnostic is targeted',
    );

    my $malformed_path = File::Spec->catfile($tempdir, 'malformed.ahb');
    my $malformed_source = sample_ahb_subordinate_source();
    $malformed_source =~ s/\(response HRESP width 1\)/(response HRESP width 2)/;
    write_file($malformed_path, $malformed_source);
    my $malformed_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($malformed_path); 1 };
    ok(!$malformed_ok, 'malformed subordinate .ahb syntax is rejected');
    like($@, qr/bus\.response\.width must be 1/, 'malformed subordinate diagnostic is preserved');
};

subtest 'CLI JSON surfaces report subordinate .ahb source identity and support accounting' => sub {
    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_subordinate_alias_path()],
    );
    ok($check_success, '--check --json succeeds for subordinate .ahb');
    is(join('', @{$check_stderr || []}), '', '--check --json keeps stderr clean for subordinate .ahb');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'subordinate .ahb check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_subordinate_alias_path()),
        'subordinate .ahb check JSON reports the public alias source path',
    );
    is($check_report->{result}{module_name}, 'ahb_lite_subordinate', 'subordinate .ahb check JSON reports generated module name');
    is($check_report->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate', 'subordinate .ahb support accounting names the profile-alias corpus entry');
    is($check_report->{support_accounting}{source_kind}, 'ial2_profile_alias', 'subordinate .ahb records profile-alias source kind');
    is($check_report->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_subordinate_pipeline_cli', 'subordinate .ahb records selected coverage key');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_subordinate_alias_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for subordinate .ahb');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for subordinate .ahb');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'subordinate .ahb semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_subordinate_alias_path()),
        'subordinate .ahb semantic JSON reports the public alias source path',
    );
    is($semantic_report->{generation_result_snapshot}{summary}{module_name}, 'ahb_lite_subordinate', 'subordinate .ahb semantic JSON reports generated module name');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'fsm', 'subordinate .ahb semantic JSON payload describes the generated .fsm semantic root');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate', 'subordinate .ahb semantic JSON support accounting names the profile-alias corpus entry');
    is($semantic_report->{support_accounting}{source_kind}, 'ial2_profile_alias', 'subordinate .ahb semantic JSON records profile-alias source kind');
};

subtest 'schedule JSON and outdir expose subordinate .ahb review artifacts' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_subordinate_alias_path()],
    );
    ok($schedule_success, '--emit-schedule-json succeeds for subordinate .ahb');
    is(join('', @{$schedule_stderr || []}), '', '--emit-schedule-json keeps stderr clean for subordinate .ahb');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', 'subordinate .ahb schedule JSON reports the AHB subordinate schema');
    is($schedule_report->{target_protocol}{profile}, 'ahb', 'subordinate .ahb schedule JSON reports the AHB profile');
    is($schedule_report->{target_protocol}{object}, 'ahb-subordinate', 'subordinate .ahb schedule JSON reports the AHB subordinate object');
    is($schedule_report->{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate.isf', 'subordinate .ahb schedule JSON exposes generated IAL1 artifact');
    is_deeply($schedule_report->{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate.fsm'], 'subordinate .ahb schedule JSON exposes generated IAL0 artifact');
    is($schedule_report->{output_defaults}{HREADYOUT}{default}, 1, 'subordinate .ahb schedule JSON exposes HREADYOUT default high');
    my %residue = map { $_->{id} => 1 } @{$schedule_report->{unsupported_residue}};
    ok(!$residue{ahb_subordinate_profile_alias_deferred}, 'subordinate .ahb schedule JSON removes stale profile-alias residue');
    ok($residue{ahb_interconnect_generation_deferred}, 'subordinate .ahb schedule JSON keeps interconnect residue');
    ok($residue{ahb_subordinate_optional_signal_residue}, 'subordinate .ahb schedule JSON keeps optional-signal residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_subordinate_alias_path()],
    );

    ok($success, 'CLI generation succeeds for subordinate .ahb profile alias');
    is(join('', @{$stderr_buf || []}), '', 'subordinate .ahb generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf'), 'subordinate .ahb --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm'), 'subordinate .ahb --outdir writes generated .fsm');
    ok(-f $hdl, 'subordinate .ahb --output writes generated HDL');
    like(slurp($hdl), qr/\bmodule\s+ahb_lite_subordinate\b/, 'subordinate .ahb generated HDL contains the subordinate module');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf')), qr/\(output HREADYOUT \(reset 1\) \(default 1\)\)/, 'subordinate .ahb generated .isf keeps reset/default metadata');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm')), qr/\(HREADYOUT 1 \(reset 1\)\)/, 'subordinate .ahb generated .fsm keeps reset metadata');
};

done_testing();

sub sample_ahb_subordinate_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate.ppif');
}

sub sample_ahb_subordinate_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate.ahb');
}

sub sample_ahb_requester_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_requester.ppif');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub sample_ahb_subordinate_source {
    return slurp(sample_ahb_subordinate_ppif_path());
}

sub sample_ahb_subordinate_object {
    my $source = sample_ahb_subordinate_source();
    $source =~ /\n  (\(ahb-subordinate\b.*)\)\s*\z/s
        or die 'Cannot extract AHB subordinate object from sample';
    return $1;
}

sub sample_ahb_requester_object {
    my $source = slurp(sample_ahb_requester_ppif_path());
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
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}
