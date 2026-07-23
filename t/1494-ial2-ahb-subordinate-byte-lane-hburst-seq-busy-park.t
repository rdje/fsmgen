#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;

# IAL2-FEATURE-COMPLETENESS-FRONTIER.776: bounded endpoint AHB subordinate
# BUSY-in-burst parking. The busy-park source is a new additive stem that holds
# the in-word SEQ burst context across an HTRANS=BUSY beat instead of clearing
# it, by declaring (parked-transfer busy) in place of (ignored-transfer busy).

subtest 'adapter parses the BUSY-park AHB subordinate PPIF and parks BUSY' => sub {
    ok(-f sample_busy_park_path(), 'tracked runnable BUSY-park PPIF sample exists');
    like(sample_busy_park(), qr/\(seq-policy hburst-in-word-progressive\)/, 'sample keeps the HBURST SEQ policy clause');
    like(sample_busy_park(), qr/\(ignored-transfer idle\)/, 'sample still ignores IDLE');
    like(sample_busy_park(), qr/\(parked-transfer busy\)/, 'sample parks BUSY instead of ignoring it');
    unlike(sample_busy_park(), qr/\(ignored-transfer busy\)/, 'sample no longer ignores BUSY');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_busy_park_path());
    is($result->{layer}, 'IAL2', 'BUSY-park adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.ahb_subordinate', 'adapter returns the AHB subordinate kind');
    is($result->{report}{source_object}{id}, 'fsmgen-ahb-lite-subordinate-byte-lane-hburst-seq-busy-park', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', 'source intent name is preserved');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf', 'generated IAL1 artifact is named');

    # The BUSY-park delta: the concurrent idle-clear rule fires on IDLE only, so a
    # BUSY beat leaves the seq_* registers unassigned (parked) instead of cleared.
    like($isf, qr/\(rule ahb_access_release \(& ahb_access_active_q \(\| \(! HSEL\) \(== HTRANS 2'b00\) \(== HTRANS 2'b01\)\)\)/, 'generated IAL1 releases the completed active transfer at the parked BUSY boundary');
    like($isf, qr/\(rule ahb_seq_idle_clear \(& HSEL HREADY \(== HTRANS 2'b00\)\)/s, 'generated IAL1 concurrently clears continuation history on accepted IDLE only');
    unlike($isf, qr/\(rule ahb_seq_idle_clear \(& HSEL HREADY \(\| \(== HTRANS 2'b00\) \(== HTRANS 2'b01\)\)\)/s, 'generated IAL1 idle-clear no longer fires on BUSY');

    # The shipped burst machinery is preserved: BUSY still stores no register
    # write (it is neither NONSEQ nor SEQ), the WRAP4/INCR4 arm/advance path is
    # intact, and the burst context registers are still declared.
    like($isf, qr/\(var seq_hburst_q \(width 3\) \(reset 0\)\)/, 'generated IAL1 keeps the prior-HBURST register');
    like($isf, qr/\(var seq_beats_remaining_q \(width 2\) \(reset 0\)\)/, 'generated IAL1 keeps the four-beat remaining count');
    like($isf, qr/\(when \(& \(== trans_q 2'b10\) \(== burst_q 3\).*32'h00000000.*write_q\).*?\(set seq_hburst_q burst_q\)\s+\(set seq_beats_remaining_q 3\)/s, 'INCR4 NONSEQ still arms a burst');
    like($isf, qr/\(when \(& \(== trans_q 2'b11\).*seq_hburst_q.*seq_beats_remaining_q.*write_q\).*?\(set seq_beats_remaining_q \(- seq_beats_remaining_q 1\)\)/s, 'accepted SEQ beat still advances and decrements the burst, so a parked BUSY resumes cleanly');

    my $sp = $result->{report}{transfer}{seq_policy};
    is($sp->{mode}, 'hburst_in_word_progressive', 'report keeps the HBURST SEQ policy mode');
    is_deeply($sp->{supported_hburst_modes}, [qw(WRAP4 INCR4)], 'report keeps the supported HBURST modes');
    is_deeply($sp->{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'report drops BUSY from clears_on');
    is_deeply($sp->{parks_on}, [qw(busy)], 'report records BUSY as a parked (held) transfer');

    my %residue = map { $_->{id} => $_->{detail} } @{$result->{report}{unsupported_residue}};
    like($residue{ahb_burst_seq_support_deferred}, qr/with BUSY-in-burst parking is shipped/, 'residue records shipped BUSY-in-burst parking');
    unlike($residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst continuation/, 'residue no longer defers BUSY-in-burst continuation');
    like($residue{ahb_burst_seq_support_deferred}, qr/halfword\/word burst SEQ/, 'residue keeps larger burst sizes deferred');
    like($residue{ahb_burst_seq_support_deferred}, qr/\.ahb alias exposure, aggregate propagation/, 'residue keeps alias and aggregate propagation deferred');
};

subtest 'BUSY-park CLI check, semantic export, and schedule report agree' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', sample_busy_park_path());
    ok($check->{success}, 'strict check JSON succeeds for the BUSY-park source');
    is($check->{result}{module_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', 'check JSON reports the BUSY-park module name');
    is($check->{support_accounting}{entry_id}, 'intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park', 'check JSON matches BUSY-park support accounting');
    is($check->{support_accounting}{coverage}, 'ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli', 'check JSON reports the selected coverage key');
    is($check->{support_accounting}{source_kind}, 'ppif', 'check JSON reports the PPIF source kind');

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', sample_busy_park_path());
    is($schedule->{transfer}{seq_policy}{mode}, 'hburst_in_word_progressive', 'schedule JSON keeps the HBURST SEQ policy mode');
    is_deeply($schedule->{transfer}{seq_policy}{parks_on}, [qw(busy)], 'schedule JSON exposes the parks_on field');
    is_deeply($schedule->{transfer}{seq_policy}{clears_on}, [qw(reset idle error new_nonseq final_beat)], 'schedule JSON drops BUSY from clears_on');
};

subtest 'malformed BUSY-park sources fail closed' => sub {
    my @cases = (
        [
            'parked BUSY without the HBURST SEQ policy',
            sub {
                my $source = sample_busy_park();
                $source =~ s/\n      \(seq-policy hburst-in-word-progressive\)//;
                $source =~ s/\n      \(burst HBURST width 3\)//;
                return $source;
            },
            qr/parked-transfer busy requires transfer\.seq_policy hburst-in-word-progressive/,
        ],
        [
            'both IDLE and BUSY ignored plus BUSY parked',
            sub {
                my $source = sample_busy_park();
                $source =~ s/\(ignored-transfer idle\)/(ignored-transfer idle)\n      (ignored-transfer busy)/;
                return $source;
            },
            qr/must either ignore \{idle, busy\} or ignore \{idle\} and park \{busy\}/,
        ],
        [
            'IDLE parked instead of BUSY',
            sub {
                my $source = sample_busy_park();
                $source =~ s/\(ignored-transfer idle\)/(ignored-transfer busy)/;
                $source =~ s/\(parked-transfer busy\)/(parked-transfer idle)/;
                return $source;
            },
            qr/must either ignore \{idle, busy\} or ignore \{idle\} and park \{busy\}/,
        ],
    );

    for my $case (@cases) {
        my ($label, $build_source, $pattern) = @$case;
        my $ok = eval {
            FSM::Adapter::IAL2::PPIF->new()->parse_source($build_source->(), "$label.ppif");
            1;
        };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'the shipped HBURST SEQ source and its clear-on-BUSY behavior stay unchanged' => sub {
    my $shipped = FSM::Adapter::IAL2::PPIF->new()->parse_file(sample_shipped_path());
    is($shipped->{report}{source_object}{intent_name}, 'ahb_lite_subordinate_byte_lane_hburst_seq', 'shipped source intent name is unchanged');
    is_deeply($shipped->{report}{transfer}{seq_policy}{clears_on}, [qw(reset idle busy error new_nonseq final_beat)], 'shipped source still clears on BUSY');
    ok(!exists $shipped->{report}{transfer}{seq_policy}{parks_on}, 'shipped source has no parks_on field');
    like($shipped->{generated_ial1}{text}, qr/\(rule ahb_seq_idle_clear \(& HSEL HREADY \(\| \(== HTRANS 2'b00\) \(== HTRANS 2'b01\)\)\)/s, 'shipped source idle-clear still fires on IDLE or BUSY');
    my %residue = map { $_->{id} => $_->{detail} } @{$shipped->{report}{unsupported_residue}};
    like($residue{ahb_burst_seq_support_deferred}, qr/BUSY-in-burst continuation/, 'shipped source still defers BUSY-in-burst continuation');
};

done_testing();

sub sample_busy_park_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif');
}

sub sample_shipped_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_lite_subordinate_byte_lane_hburst_seq.ppif');
}

sub sample_busy_park {
    return slurp(sample_busy_park_path());
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

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}
