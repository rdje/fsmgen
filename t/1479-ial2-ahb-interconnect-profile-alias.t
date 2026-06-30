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

subtest 'adapter accepts the selected aggregate AHB interconnect .ahb profile alias' => sub {
    ok(-f sample_ahb_interconnect_alias_path(), 'tracked runnable aggregate AHB interconnect .ahb alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_interconnect_alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_ahb_interconnect_ppif_path());

    is($alias->{layer}, 'IAL2', 'AHB interconnect .ahb parser result stays IAL2');
    is($alias->{kind}, 'protocol_intent.ahb_interconnect', 'AHB interconnect .ahb parser result keeps interconnect kind');
    is($alias->{mode}, 'requester-subordinate-interconnect', 'AHB interconnect .ahb parser result keeps aggregate mode');
    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', '.ahb report keeps the AHB interconnect schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-interconnect', '.ahb preserves aggregate source object id');
    is($alias->{report}{target_protocol}{profile}, 'ahb', '.ahb preserves explicit AHB profile');
    is($alias->{report}{target_protocol}{object}, 'ahb-interconnect', '.ahb preserves AHB interconnect object');
    is($alias->{report}{target_protocol}{role}, 'interconnect', '.ahb preserves AHB interconnect role');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.ahb keeps direct IAL2-to-IAL0 lowering forbidden');

    is_deeply(
        [map { $_->{name} } @{$alias->{generated_ial1}{items}}],
        [qw(amba_requester.isf ahb_lite_subordinate.isf ahb_interconnect.isf)],
        '.ahb exposes generated requester, subordinate, and interconnect IAL1 artifacts',
    );
    is_deeply(
        [map { $_->{entry_artifact} } @{$alias->{generated_ial0}{items}}],
        [qw(amba_requester.fsm ahb_lite_subordinate.fsm ahb_interconnect.fsm ahb_tb.fsm)],
        '.ahb exposes generated requester, subordinate, interconnect, and aggregate IAL0 artifacts in lowering order',
    );
    is_deeply(
        sorted([keys %{$alias->{generated_ial0}{files}}]),
        [qw(ahb_interconnect.fsm ahb_lite_subordinate.fsm ahb_tb.fsm amba_requester.fsm)],
        '.ahb exposes the same generated IAL0 file set as generic PPIF',
    );

    is_deeply($alias->{generated_ial1}{items}, $ppif->{generated_ial1}{items}, '.ahb mirrors generic PPIF generated IAL1 artifacts');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.ahb mirrors generic PPIF generated IAL0 files');
    is($alias->{report}{composition}{name}, 'ahb_tb', '.ahb report captures aggregate top name');
    is($alias->{report}{composition}{topology}, 'one_requester_one_subordinate_static_window_interconnect', '.ahb report captures selected topology');
    is($alias->{report}{composition}{child_instance_count}, 3, '.ahb report captures requester/interconnect/subordinate child count');
    is($alias->{report}{composition}{generated_interconnect}{ial1_artifact}, 'ahb_interconnect.isf', '.ahb report captures generated interconnect IAL1 artifact');
    is($alias->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'ahb_tb.fsm', '.ahb report selects generated aggregate HDL entry');

    my %alias_residue = map { $_->{id} => 1 } @{$alias->{report}{unsupported_residue}};
    ok(!$alias_residue{ahb_aggregate_profile_alias_deferred}, '.ahb report removes stale aggregate profile-alias residue');
    ok(!residue_id_occurs($alias->{report}, 'ahb_aggregate_profile_alias_deferred'), '.ahb report removes stale aggregate profile-alias residue from nested children');
    ok($alias_residue{ahb_multi_subordinate_decode_deferred}, '.ahb report keeps multi-subordinate residue explicit');
    ok($alias_residue{ahb_optional_signal_residue}, '.ahb report keeps optional-signal residue explicit');
    ok($alias_residue{ahb_burst_seq_support_deferred}, '.ahb report keeps burst SEQ residue explicit');
    ok($alias_residue{ahb_direct_backend_deferred}, '.ahb report keeps direct-backend residue explicit');
    ok($alias_residue{ahb_verification_output_deferred}, '.ahb report keeps verification/backend residue explicit');

    my %ppif_residue = map { $_->{id} => 1 } @{$ppif->{report}{unsupported_residue}};
    ok($ppif_residue{ahb_aggregate_profile_alias_deferred}, 'generic PPIF report preserves aggregate profile-alias residue');
};

subtest 'aggregate interconnect .ahb diagnostics stay distinct' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = sample_ahb_interconnect_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'aggregate .ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        'aggregate .ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'aggregate .ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        'aggregate .ahb suffix/profile mismatch diagnostic is targeted',
    );

    my $wrong_object_path = File::Spec->catfile($tempdir, 'wrong_object.ahb');
    my $wrong_object_source = slurp(sample_valid_ready_handshake_ppif_path());
    $wrong_object_source =~ s/\(profile valid-ready\)/(profile ahb)/;
    write_file($wrong_object_path, $wrong_object_source);
    my $wrong_object_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($wrong_object_path); 1 };
    ok(!$wrong_object_ok, '.ahb profile with unsupported object breadth is rejected');
    like(
        $@,
        qr/profile ahb requires exactly one \(ahb-requester \.\.\.\) object, exactly one \(ahb-subordinate \.\.\.\) object, the selected aggregate one-requester\/one-subordinate \(ahb-interconnect \.\.\.\) shape, or the selected aggregate one-requester\/two-subordinate \(ahb-interconnect \.\.\.\) shape in this slice/,
        '.ahb unsupported object diagnostic names the selected aggregate shape',
    );

    my $missing_subordinate_path = File::Spec->catfile($tempdir, 'missing_subordinate.ahb');
    my $missing_subordinate_source = sample_ahb_interconnect_source();
    $missing_subordinate_source =~ s/\n  \(ahb-subordinate\b.*?\n  \(ahb-interconnect/\n  (ahb-interconnect/s;
    write_file($missing_subordinate_path, $missing_subordinate_source);
    my $missing_subordinate_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_subordinate_path); 1 };
    ok(!$missing_subordinate_ok, 'aggregate .ahb without the subordinate object is rejected');
    like(
        $@,
        qr/AHB interconnect requires exactly one \(ahb-requester \.\.\.\), one or two \(ahb-subordinate \.\.\.\) objects, and one \(ahb-interconnect \.\.\.\) object in this slice/,
        'aggregate .ahb missing-subordinate diagnostic is targeted',
    );
};

subtest 'CLI JSON surfaces report aggregate .ahb source identity and support accounting' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_ahb_interconnect_alias_path());
    ok($check->{success}, '--check --json succeeds for aggregate .ahb');
    is(
        $check->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_interconnect_alias_path()),
        'aggregate .ahb check JSON reports the public alias source path',
    );
    is($check->{result}{module_name}, 'ahb_tb', 'aggregate .ahb check JSON reports generated aggregate module name');
    is($check->{result}{composition_child_count}, 3, 'aggregate .ahb check JSON reports requester/interconnect/subordinate children');
    is($check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_interconnect', 'aggregate .ahb support accounting names the profile-alias corpus entry');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'aggregate .ahb records profile-alias source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_interconnect_pipeline_cli', 'aggregate .ahb records selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_ahb_interconnect_alias_path());
    ok($semantic->{success}, '--emit-semantic-json succeeds for aggregate .ahb');
    is(
        $semantic->{source}{resolved_path},
        File::Spec->rel2abs(sample_ahb_interconnect_alias_path()),
        'aggregate .ahb semantic JSON reports the public alias source path',
    );
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'aggregate .ahb semantic JSON reports generated aggregate module name');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'aggregate .ahb semantic JSON reports generated composition top source root');
    is($semantic->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_interconnect', 'aggregate .ahb semantic JSON support accounting names the profile-alias corpus entry');
    is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', 'aggregate .ahb semantic JSON records profile-alias source kind');
};

subtest 'schedule JSON and outdir expose aggregate .ahb review artifacts' => sub {
    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_ahb_interconnect_alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'aggregate .ahb schedule JSON reports the AHB interconnect schema');
    is($schedule->{target_protocol}{profile}, 'ahb', 'aggregate .ahb schedule JSON reports the AHB profile');
    is($schedule->{target_protocol}{object}, 'ahb-interconnect', 'aggregate .ahb schedule JSON reports the AHB interconnect object');
    is($schedule->{composition}{name}, 'ahb_tb', 'aggregate .ahb schedule JSON exposes aggregate top');
    is($schedule->{composition}{generated_interconnect}{ial1_artifact}, 'ahb_interconnect.isf', 'aggregate .ahb schedule JSON exposes generated interconnect IAL1 artifact');
    is_deeply(
        $schedule->{generated_artifacts}{hdl_entry}{child_artifacts},
        [qw(amba_requester.fsm ahb_interconnect.fsm ahb_lite_subordinate.fsm)],
        'aggregate .ahb schedule JSON exposes child artifacts under selected HDL entry',
    );
    my %schedule_residue = map { $_->{id} => 1 } @{$schedule->{unsupported_residue}};
    ok(!$schedule_residue{ahb_aggregate_profile_alias_deferred}, 'aggregate .ahb schedule JSON removes stale aggregate profile-alias residue');
    ok(!residue_id_occurs($schedule, 'ahb_aggregate_profile_alias_deferred'), 'aggregate .ahb schedule JSON removes stale aggregate profile-alias residue from nested children');
    ok($schedule_residue{ahb_multi_subordinate_decode_deferred}, 'aggregate .ahb schedule JSON keeps multi-subordinate residue');
    ok($schedule_residue{ahb_optional_signal_residue}, 'aggregate .ahb schedule JSON keeps optional-signal residue');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ahb_interconnect_alias_path()],
    );

    ok($success, 'CLI generation succeeds for aggregate .ahb profile alias');
    is(join('', @{$stderr_buf || []}), '', 'aggregate .ahb generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.isf'), 'aggregate .ahb --outdir writes generated requester .isf');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.isf'), 'aggregate .ahb --outdir writes generated subordinate .isf');
    ok(-f File::Spec->catfile($outdir, 'ahb_interconnect.isf'), 'aggregate .ahb --outdir writes generated interconnect .isf');
    ok(-f File::Spec->catfile($outdir, 'amba_requester.fsm'), 'aggregate .ahb --outdir writes generated requester .fsm');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate.fsm'), 'aggregate .ahb --outdir writes generated subordinate .fsm');
    ok(-f File::Spec->catfile($outdir, 'ahb_interconnect.fsm'), 'aggregate .ahb --outdir writes generated interconnect .fsm');
    ok(-f File::Spec->catfile($outdir, 'ahb_tb.fsm'), 'aggregate .ahb --outdir writes generated top .fsm');
    ok(-f $hdl, 'aggregate .ahb --output writes generated HDL');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'aggregate .ahb generated HDL contains the aggregate module');
    like(slurp(File::Spec->catfile($outdir, 'ahb_interconnect.fsm')), qr/unmapped_error_complete/, 'aggregate .ahb generated interconnect FSM keeps unmapped ERROR state');
};

done_testing();

sub sample_ahb_interconnect_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ppif');
}

sub sample_ahb_interconnect_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub sample_ahb_interconnect_source {
    return slurp(sample_ahb_interconnect_ppif_path());
}

sub run_json_command {
    my @command = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => \@command);
    my $json = join('', @{$stdout || []});
    my $decoded = eval { decode_json($json) };
    ok($decoded, join(' ', @command) . ' emits decodable JSON')
        or do {
            diag($json);
            diag(join('', @{$stderr || []}));
            diag('command failed') unless $success;
            return {};
        };
    return $decoded;
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

sub sorted {
    my ($values) = @_;
    return [sort @$values];
}

sub residue_id_occurs {
    my ($node, $residue_id) = @_;
    return 0 unless ref($node);

    if (ref($node) eq 'HASH') {
        if (ref($node->{unsupported_residue}) eq 'ARRAY') {
            for my $entry (@{$node->{unsupported_residue}}) {
                return 1 if ref($entry) eq 'HASH'
                    && defined($entry->{id})
                    && $entry->{id} eq $residue_id;
            }
        }
        for my $value (values %$node) {
            return 1 if residue_id_occurs($value, $residue_id);
        }
        return 0;
    }

    if (ref($node) eq 'ARRAY') {
        for my $value (@$node) {
            return 1 if residue_id_occurs($value, $residue_id);
        }
    }

    return 0;
}
