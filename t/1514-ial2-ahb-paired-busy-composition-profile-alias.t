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

subtest 'paired BUSY .ahb mirrors the generic source' => sub {
    ok(-f alias_path(), 'tracked paired BUSY .ahb profile alias exists');
    is(slurp(alias_path()), slurp(ppif_path()), '.ahb source is byte-identical to generic .ppif');
};

subtest 'public CLI surfaces select the alias support identity' => sub {
    my $check = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', alias_path());
    ok($check->{success}, 'strict alias check succeeds');
    is($check->{result}{module_name}, 'ahb_tb', 'check JSON reports aggregate module');
    is($check->{result}{composition_child_count}, 3, 'check JSON reports child count');
    is($check->{support_accounting}{entry_id}, support_id(), 'check JSON reports alias support id');
    is($check->{support_accounting}{coverage}, coverage_key(), 'check JSON reports alias coverage');
    is($check->{support_accounting}{source_kind}, 'ial2_profile_alias', 'check JSON reports profile-alias source kind');
    undef $check;

    my $schedule = run_json_command('./bin/fsmgen', '--quiet', '--emit-schedule-json', alias_path());
    is($schedule->{schema}, 'fsmgen.ial2.protocol_intent.ahb_interconnect.v1', 'schedule JSON keeps aggregate report schema');
    is($schedule->{source_object}{id}, 'fsmgen-ahb-interconnect-requester-busy-insert-byte-lane-hburst-seq-busy-park', 'schedule JSON preserves source object');
    is($schedule->{source_object}{intent_name}, 'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park', 'schedule JSON preserves intent name');
    is($schedule->{target_protocol}{profile}, 'ahb', 'schedule JSON preserves explicit AHB profile');
    is($schedule->{composition}{child_instance_count}, 3, 'schedule JSON preserves three-child top');
    is_deeply(
        [sort map { $_->{name} } @{$schedule->{generated_artifacts}{ial1}{items}}],
        [qw(ahb_interconnect.isf ahb_lite_subordinate_byte_lane_hburst_seq.isf amba_requester_busy_insert.isf)],
        'schedule JSON exposes the exact shared IAL1 artifact names',
    );
    is_deeply(
        [sort @{$schedule->{generated_artifacts}{ial0}{files}}],
        [qw(ahb_interconnect.fsm ahb_lite_subordinate_byte_lane_hburst_seq.fsm ahb_tb.fsm amba_requester_busy_insert.fsm)],
        'schedule JSON exposes the exact shared IAL0 artifact names',
    );
    is($schedule->{children}[0]{busy_insertion}{htrans_busy_encoding}, "2'b01", 'schedule JSON keeps BUSY encoding');
    is($schedule->{children}[0]{busy_insertion}{before_beat}, 2, 'schedule JSON keeps BUSY insertion index');
    is($schedule->{children}[0]{busy_insertion}{beats}, 'single', 'schedule JSON keeps one-presentation bound');
    is_deeply($schedule->{children}[2]{transfer}{seq_policy}{parks_on}, [qw(busy)], 'schedule JSON keeps subordinate BUSY parking');
    is_deeply($schedule->{composition}{seq_policy_propagation}{subordinates}[0]{seq_policy}{parks_on}, [qw(busy)], 'schedule JSON propagates BUSY parking');
    ok(!exists $schedule->{composition}{busy_flow}, 'schedule JSON adds no duplicate top BUSY summary');
    ok(!residue_id_occurs($schedule, 'ahb_aggregate_profile_alias_deferred'), 'schedule JSON removes aggregate alias residue');
    ok(!residue_id_occurs($schedule, 'ahb_profile_alias_deferred'), 'schedule JSON removes requester alias residue');
    ok(!residue_id_occurs($schedule, 'ahb_subordinate_profile_alias_deferred'), 'schedule JSON removes subordinate alias residue');
    ok(!detail_pattern_occurs($schedule, qr/\.ahb alias exposure/), 'schedule JSON removes alias-exposure wording');
    ok(residue_id_occurs($schedule, 'ahb_requester_busy_insert_support'), 'schedule JSON keeps requester BUSY support residue');
    ok(residue_id_occurs($schedule, 'ahb_burst_seq_support_deferred'), 'schedule JSON keeps burst support residue');
    undef $schedule;

    my $semantic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--emit-semantic-json', alias_path());
    is($semantic->{generation_result_snapshot}{summary}{module_name}, 'ahb_tb', 'semantic JSON reports aggregate module');
    is($semantic->{generation_result_snapshot}{summary}{source_root_kind}, 'top', 'semantic JSON reports top source root');
    is($semantic->{support_accounting}{entry_id}, support_id(), 'semantic JSON reports alias support id');
    undef $semantic;

    my $generic = run_json_command('./bin/fsmgen', '--quiet', '--strict', '--check', '--json', ppif_path());
    is($generic->{support_accounting}{entry_id}, 'intent.ppif_ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park', 'generic source keeps PPIF support id');
    is($generic->{support_accounting}{source_kind}, 'ppif', 'generic source keeps PPIF source kind');
};

subtest 'alias emits the shared artifacts and clean HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my ($generate_ok, undef, undef, $stdout, $stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--outdir', $outdir, '--output', $hdl, alias_path()],
    );
    ok($generate_ok, 'alias emits HDL and review artifacts')
        or diag(join('', @{$stdout || []}), join('', @{$stderr || []}));
    is(join('', @{$stderr || []}), '', 'alias generation keeps stderr clean');

    for my $artifact (qw(
        amba_requester_busy_insert.isf
        ahb_lite_subordinate_byte_lane_hburst_seq.isf
        ahb_interconnect.isf
        amba_requester_busy_insert.fsm
        ahb_lite_subordinate_byte_lane_hburst_seq.fsm
        ahb_interconnect.fsm
        ahb_tb.fsm
    )) {
        ok(-f File::Spec->catfile($outdir, $artifact), "outdir contains $artifact");
    }
    my $requester_isf = slurp(File::Spec->catfile($outdir, 'amba_requester_busy_insert.isf'));
    like($requester_isf, qr/\(drive transfer_busy\b/, 'requester IAL1 keeps BUSY drive');
    like($requester_isf, qr/\(rule ahb_busy_accept \(& HGRANT HREADY \(== HTRANS 2'b01\)\)/, 'alias requester IAL1 keeps qualified BUSY acceptance');
    like(slurp(File::Spec->catfile($outdir, 'ahb_lite_subordinate_byte_lane_hburst_seq.isf')), qr/ahb_phase_pending_q/, 'subordinate IAL1 keeps one accepted next phase');
    like(slurp($hdl), qr/\bmodule\s+ahb_tb\b/, 'generated HDL contains aggregate module');
    like(slurp($hdl), qr/\bahb_interconnect\s+fabric\b/, 'generated HDL keeps legal fabric instance');

    my ($verify_ok, undef, undef, $verify_stdout, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--verify-hdl', alias_path()],
    );
    ok($verify_ok, 'public verify-hdl accepts the alias')
        or diag(join('', @{$verify_stdout || []}), join('', @{$verify_stderr || []}));
};

subtest 'alias generated HDL retires one qualified paired BUSY event' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'ahb_tb.sv');
    my $objdir = File::Spec->catdir($tempdir, 'obj');
    my ($generate_ok, undef, undef, $generate_stdout, $generate_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--strict', '--output', $hdl, alias_path()],
    );
    ok($generate_ok, 'paired BUSY alias emits generated HDL for runtime proof')
        or diag(join('', @{$generate_stdout || []}), join('', @{$generate_stderr || []}));
    return unless $generate_ok;

    my ($compile_ok, undef, undef, $compile_stdout, $compile_stderr) = run(
        command => [
            'verilator', '--binary', '--timing', '--no-assert', '-Wno-fatal',
            '-j', '1', '--top-module', 'ahb_paired_busy_composition_tb',
            '--Mdir', $objdir, $hdl, testbench_path(),
        ],
    );
    ok($compile_ok, 'Verilator builds the paired BUSY alias harness')
        or diag(join('', @{$compile_stdout || []}), join('', @{$compile_stderr || []}));
    return unless $compile_ok;

    my $binary = File::Spec->catfile($objdir, 'Vahb_paired_busy_composition_tb');
    my ($run_ok, undef, undef, $run_stdout, $run_stderr) = run(command => [$binary]);
    ok($run_ok, 'generated-HDL paired BUSY alias proof passes')
        or diag(join('', @{$run_stdout || []}), join('', @{$run_stderr || []}));
    like(
        join('', @{$run_stdout || []}),
        qr/PASS transfers=5 beats=4 busy=1 qualified_busy=1 storage=44332211/,
        'alias runtime observes one qualified BUSY event, parking, and four byte writes',
    );
};

subtest 'malformed profile aliases fail closed' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $missing_profile = File::Spec->catfile($tempdir, 'missing_profile.ahb');
    my $source = slurp(ppif_path());
    $source =~ s/^\s*\(profile ahb\)\n//m;
    write_file($missing_profile, $source);
    my $missing_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($missing_profile); 1 };
    ok(!$missing_ok, 'alias without explicit AHB profile is rejected');
    like($@, qr/is missing required \(profile \.\.\.\) clause/, 'missing-profile diagnostic is targeted');

    my $mismatch = File::Spec->catfile($tempdir, 'wrong_profile.ahb');
    write_file($mismatch, slurp(valid_ready_path()));
    my $mismatch_ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_file($mismatch); 1 };
    ok(!$mismatch_ok, 'non-AHB profile under .ahb is rejected');
    like($@, qr/profile 'valid-ready' does not match \.ahb profile alias; expected ahb/, 'profile mismatch diagnostic is targeted');
};

done_testing();

sub alias_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb');
}

sub ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif');
}

sub valid_ready_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'valid_ready_handshake.ppif');
}

sub testbench_path {
    return File::Spec->catfile($FindBin::Bin, 'data', 'ahb_paired_busy_composition_tb.svt');
}

sub support_id {
    return 'intent.ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park';
}

sub coverage_key {
    return 'ial2_ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli';
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

sub residue_id_occurs {
    my ($node, $id) = @_;
    return 0 unless ref($node);
    if (ref($node) eq 'ARRAY') {
        return scalar grep { residue_id_occurs($_, $id) } @{$node};
    }
    return 0 unless ref($node) eq 'HASH';
    return 1 if exists($node->{id}) && ($node->{id} // '') eq $id;
    return scalar grep { residue_id_occurs($node->{$_}, $id) } keys %{$node};
}

sub detail_pattern_occurs {
    my ($node, $pattern) = @_;
    return 0 unless ref($node);
    if (ref($node) eq 'ARRAY') {
        return scalar grep { detail_pattern_occurs($_, $pattern) } @{$node};
    }
    return 0 unless ref($node) eq 'HASH';
    return 1 if exists($node->{detail}) && ($node->{detail} // '') =~ $pattern;
    return scalar grep { detail_pattern_occurs($node->{$_}, $pattern) } keys %{$node};
}

sub write_file {
    my ($path, $text) = @_;
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $text;
    close $fh or die "close $path: $!";
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
