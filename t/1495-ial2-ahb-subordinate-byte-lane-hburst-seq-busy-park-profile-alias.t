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

subtest 'adapter accepts the selected AHB byte-lane HBURST SEQ BUSY-park subordinate .ahb profile alias' => sub {
    ok(-f sample_busy_park_alias_path(), 'tracked runnable AHB byte-lane HBURST SEQ BUSY-park subordinate .ahb alias sample exists');

    my $alias = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_busy_park_alias_path());
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_busy_park_ppif_path());

    is(slurp(sample_busy_park_alias_path()), slurp(sample_busy_park_ppif_path()), '.ahb alias source is a byte-identical mirror of the generic BUSY-park .ppif source');

    is($alias->{layer}, 'IAL2', 'AHB byte-lane HBURST SEQ BUSY-park .ahb parser result stays IAL2');
    is($alias->{kind}, 'protocol_intent.ahb_subordinate', 'AHB byte-lane HBURST SEQ BUSY-park .ahb parser result keeps subordinate kind');
    is($alias->{mode}, 'subordinate', 'AHB byte-lane HBURST SEQ BUSY-park .ahb parser result keeps subordinate mode');
    is($alias->{generated_ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf', '.ahb exposes generated BUSY-park IAL1 artifact');
    is($alias->{generated_ial1}{text}, $ppif->{generated_ial1}{text}, '.ahb mirrors BUSY-park .ppif generated IAL1 text');
    is_deeply($alias->{generated_ial0}{files}, $ppif->{generated_ial0}{files}, '.ahb mirrors BUSY-park .ppif generated IAL0 files');
    is($alias->{report}{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', '.ahb report keeps the AHB subordinate schema');
    is($alias->{report}{source_object}{id}, 'fsmgen-ahb-lite-subordinate-byte-lane-hburst-seq-busy-park', '.ahb preserves BUSY-park source object id');
    is($alias->{report}{source_object}{intent_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', '.ahb preserves BUSY-park intent name');
    is($alias->{report}{target_protocol}{profile}, 'ahb', '.ahb preserves explicit AHB profile');
    is($alias->{report}{target_protocol}{object}, 'ahb-subordinate', '.ahb preserves AHB subordinate object');
    is($alias->{report}{target_protocol}{transfer}, 'ahb_lite_byte_lane_hburst_seq_access', '.ahb preserves selected byte-lane HBURST SEQ transfer');
    is($alias->{report}{bindings}{bus}{burst}{name}, 'HBURST', '.ahb report preserves HBURST bus binding');
    is($alias->{report}{bindings}{bus}{burst}{width}, 3, '.ahb report preserves HBURST bus width');
    is($alias->{report}{layering}{direct_ial2_to_ial0}, 0, '.ahb keeps direct IAL2-to-IAL0 lowering forbidden');
    is_deeply($alias->{report}{transfer}{supported_size}, [qw(byte halfword word)], '.ahb report preserves byte/halfword/word supported sizes');
    is($alias->{report}{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', '.ahb report preserves selected HBURST SEQ policy');
    is($alias->{report}{transfer}{seq_policy}{length_source}, 'HBURST', '.ahb report preserves HBURST as length source');
    is_deeply($alias->{report}{transfer}{seq_policy}{supported_hburst_modes}, [qw(WRAP4 INCR4)], '.ahb report preserves supported HBURST modes');

    # The distinctive BUSY-park report shape: BUSY parks the burst rather than clearing it.
    is_deeply($alias->{report}{transfer}{seq_policy}{parks_on}, ['busy'], '.ahb report preserves BUSY-park parks_on shape');
    is_deeply($alias->{report}{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], '.ahb report preserves BUSY-free clears_on shape');
    is_deeply($alias->{report}{transfer}{seq_policy}{parks_on}, $ppif->{report}{transfer}{seq_policy}{parks_on}, '.ahb mirrors the generic BUSY-park parks_on shape');
    is_deeply($alias->{report}{transfer}{seq_policy}{clears_on}, $ppif->{report}{transfer}{seq_policy}{clears_on}, '.ahb mirrors the generic BUSY-park clears_on shape');

    is($alias->{report}{narrow_transfer_policy}{byte_lanes}[3]{mask}, "32'hff000000", '.ahb report preserves byte-lane mask policy');
    is($alias->{report}{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf', '.ahb report names generated IAL1 before IAL0');
    is_deeply($alias->{report}{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm'], '.ahb report names generated IAL0 artifact');
    is($alias->{report}{generated_artifacts}{hdl_entry}{entry_artifact}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm', '.ahb report selects generated BUSY-park .fsm as HDL entry');

    my %alias_residue = map { $_->{id} => $_->{detail} } @{$alias->{report}{unsupported_residue}};
    ok(!exists $alias_residue{ahb_subordinate_profile_alias_deferred}, '.ahb report removes stale subordinate profile-alias residue');
    ok($alias_residue{ahb_burst_seq_support_deferred}, '.ahb report keeps remaining HBURST SEQ residue explicit');
    unlike($alias_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, '.ahb report no longer says alias exposure is deferred');
    like($alias_residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, '.ahb report keeps aggregate HBURST propagation deferred');
    like($alias_residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst parking is shipped/, '.ahb report keeps shipped BUSY-in-burst parking behavior explicit');

    my %ppif_residue = map { $_->{id} => $_->{detail} } @{$ppif->{report}{unsupported_residue}};
    ok($ppif_residue{ahb_subordinate_profile_alias_deferred}, 'generic BUSY-park PPIF report preserves alias-deferred residue');
    like($ppif_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, 'generic BUSY-park PPIF report keeps alias exposure deferred');
};

subtest 'byte-lane HBURST SEQ BUSY-park subordinate .ahb diagnostics stay fail-closed for malformed aliases' => sub {
    my $tempdir = tempdir(CLEANUP => 1);

    my $missing_profile_path = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $missing_profile_source = sample_busy_park_alias_source();
    $missing_profile_source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile_path, $missing_profile_source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile_path); 1 };
    ok(!$missing_ok, 'BUSY-park .ahb without explicit profile is rejected');
    like(
        $@,
        qr/\.ahb source '.*missing_profile\.ahb' is missing required \(profile \.\.\.\) clause/,
        'BUSY-park .ahb missing-profile diagnostic is targeted',
    );

    my $mismatch_path = File::Spec->catfile($tempdir, 'valid_ready_profile.ahb');
    write_file($mismatch_path, slurp(sample_valid_ready_handshake_ppif_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch_path); 1 };
    ok(!$mismatch_ok, 'BUSY-park .ahb with a non-AHB profile is rejected');
    like(
        $@,
        qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/,
        'BUSY-park .ahb suffix/profile mismatch diagnostic is targeted',
    );

    my @cases = (
        [
            'parked-transfer busy without hburst seq policy',
            sub {
                my $source = sample_busy_park_alias_source();
                $source =~ s/\(seq-policy hburst-in-word-progressive\)/(seq-policy in-word-progressive)/;
                return $source;
            },
            qr/parked-transfer busy requires transfer\.seq_policy hburst-in-word-progressive/,
        ],
        [
            'duplicate burst binding',
            sub {
                my $source = sample_busy_park_alias_source();
                $source =~ s/\(burst HBURST width 3\)/(burst HBURST width 3)\n      (burst HBURST2 width 3)/;
                return $source;
            },
            qr/duplicate \(burst \.\.\.\) clause/,
        ],
        [
            'wrong burst width',
            sub {
                my $source = sample_busy_park_alias_source();
                $source =~ s/\(burst HBURST width 3\)/(burst HBURST width 2)/;
                return $source;
            },
            qr/bus\.burst\.width must be 3/,
        ],
        [
            'hburst seq policy without burst binding',
            sub {
                my $source = sample_busy_park_alias_source();
                $source =~ s/\n      \(burst HBURST width 3\)//;
                return $source;
            },
            qr/transfer\.seq_policy hburst-in-word-progressive requires bus\.burst/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $path = File::Spec->catfile($tempdir, "$label.ahb");
        write_file($path, $build_source->());
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($path); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI JSON surfaces report byte-lane HBURST SEQ BUSY-park subordinate .ahb source identity and support accounting' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_busy_park_alias_path());
    ok($check->{success}, '--check --json succeeds for byte-lane HBURST SEQ BUSY-park subordinate .ahb');
    is(
        $check->{source}{resolved_path},
        File::Spec->rel2abs(sample_busy_park_alias_path()),
        'BUSY-park subordinate .ahb check JSON reports the public alias source path',
    );
    is($check->{result}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', 'BUSY-park subordinate .ahb check JSON reports generated module name');
    is($check->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park', 'BUSY-park subordinate .ahb support accounting names the profile-alias corpus entry');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'BUSY-park subordinate .ahb records profile-alias source kind');
    is($check->{support_accounting}{coverage}, 'ial2_ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli', 'BUSY-park subordinate .ahb records selected coverage key');

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', sample_busy_park_alias_path());
    ok($semantic->{success}, '--emit-semantic-json succeeds for byte-lane HBURST SEQ BUSY-park subordinate .ahb');
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', 'BUSY-park subordinate .ahb semantic JSON reports generated module name');
    is($semantic->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq_busy_park', 'BUSY-park subordinate .ahb semantic JSON support accounting names the profile-alias corpus entry');
    is($semantic->{support_accounting}{source_kind}, 'ial2_profile_alias', 'BUSY-park subordinate .ahb semantic JSON records profile-alias source kind');
};

subtest 'schedule JSON and outdir expose byte-lane HBURST SEQ BUSY-park subordinate .ahb review artifacts' => sub {
    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_busy_park_alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_subordinate.v1', 'BUSY-park subordinate .ahb schedule JSON reports the AHB subordinate schema');
    is($schedule->{target_protocol}{profile}, 'ahb', 'BUSY-park subordinate .ahb schedule JSON reports the AHB profile');
    is($schedule->{generated_artifacts}{ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf', 'BUSY-park subordinate .ahb schedule JSON exposes generated IAL1 artifact');
    is_deeply($schedule->{generated_artifacts}{ial0}{files}, ['ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm'], 'BUSY-park subordinate .ahb schedule JSON exposes generated IAL0 artifact');
    is($schedule->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'BUSY-park subordinate .ahb schedule JSON exposes SEQ policy');
    is_deeply($schedule->{transfer}{seq_policy}{parks_on}, ['busy'], 'BUSY-park subordinate .ahb schedule JSON exposes parks_on shape');
    is_deeply($schedule->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'BUSY-park subordinate .ahb schedule JSON exposes BUSY-free clears_on shape');
    my %schedule_residue = map { $_->{id} => $_->{detail} } @{$schedule->{unsupported_residue}};
    ok(!exists $schedule_residue{ahb_subordinate_profile_alias_deferred}, 'BUSY-park subordinate .ahb schedule JSON removes stale profile-alias residue');
    unlike($schedule_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, 'BUSY-park subordinate .ahb schedule JSON removes alias-exposure residue wording');
    like($schedule_residue{ahb_burst_seq_support_deferred}, qr/aggregate propagation/, 'BUSY-park subordinate .ahb schedule JSON keeps aggregate propagation deferred');

    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.sv');
    my ($success, undef, undef, undef, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_busy_park_alias_path()],
    );
    ok($success, 'BUSY-park subordinate .ahb emits HDL and review artifacts through --outdir');
    is(join('', @{$stderr || []}), '', 'BUSY-park subordinate .ahb outdir generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf'), 'outdir contains generated BUSY-park IAL1 artifact');
    ok(-f File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm'), 'outdir contains generated BUSY-park IAL0 artifact');
    ok(-f $hdl, 'outdir command emits selected BUSY-park subordinate HDL output');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf')), qr/seq_hburst_q/, 'outdir generated .isf keeps HBURST stability state');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm')), qr/seq_beats_remaining_q/, 'outdir generated .fsm keeps four-beat remaining state');
    like(slurp($hdl), qr/\bmodule\s+ahb_lite_subordinate_byte_lane_hburst_seq_busy_park\b/, 'generated HDL contains BUSY-park AHB subordinate module');
    like(slurp($hdl), qr/\binput\s+wire\s+\[2:0\]\s+HBURST\b/, 'generated HDL exposes HBURST input');
};

subtest 'existing generic BUSY-park PPIF and endpoint HBURST SEQ .ahb alias surfaces stay unchanged' => sub {
    my $busy_park_ppif = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_busy_park_ppif_path());
    my %busy_park_ppif_residue = map { $_->{id} => $_->{detail} } @{$busy_park_ppif->{report}{unsupported_residue}};
    ok($busy_park_ppif_residue{ahb_subordinate_profile_alias_deferred}, 'generic BUSY-park PPIF still keeps .ahb alias residue explicit');
    like($busy_park_ppif_residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure/, 'generic BUSY-park PPIF still names alias exposure deferred');
    is_deeply($busy_park_ppif->{report}{transfer}{seq_policy}{parks_on}, ['busy'], 'generic BUSY-park PPIF keeps parks_on shape');

    my $hburst_alias = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_hburst_seq_alias_path());
    ok($hburst_alias->{success}, 'existing endpoint HBURST SEQ subordinate .ahb alias still checks successfully');
    is($hburst_alias->{result}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq', 'existing endpoint HBURST SEQ subordinate .ahb alias keeps module name');
    is($hburst_alias->{support_accounting}{entry_id}, 'intent.ahb_profile_alias_subordinate_byte_lane_hburst_seq', 'existing endpoint HBURST SEQ subordinate .ahb alias keeps support identity');
};

done_testing();

sub sample_busy_park_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub sample_busy_park_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb');
}

sub sample_hburst_seq_alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq.ahb');
}

sub sample_valid_ready_handshake_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub sample_busy_park_alias_source {
    return slurp(sample_busy_park_alias_path());
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
