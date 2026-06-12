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

subtest 'PPIF adapter parses the selected Valid-Ready source shape' => sub {
    my $sample_path = sample_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_ppif(), $sample_path);

    is($result->{layer}, 'IAL2', 'adapter returns an IAL2 result');
    is($result->{generated_ial1}{name}, 'axi_aw_valid_ready_monitor.isf', 'adapter exposes generated IAL1 artifact');
    like($result->{generated_ial1}{text}, qr/\A\(actor axi_aw_valid_ready_monitor\b/, 'generated IAL1 is .isf text');
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi_aw_valid_ready_monitor.fsm'],
        'adapter exposes generated IAL0 .fsm file map',
    );
    is($result->{report}{source_object}{id}, 'axi-valid-ready-aw', 'source object id is preserved');
    is($result->{report}{target_channel}{protocol}, 'axi4', 'profile maps to generator protocol');
    is($result->{report}{target_channel}{family}, 'AW', 'channel maps to target channel family');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'direct IAL2-to-IAL0 remains forbidden');
};

subtest 'PPIF adapter diagnostics fail closed before generation claims' => sub {
    my @cases = (
        ['missing profile',
            '(protocol-platform-intent p (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel axi_aw (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid awvalid) (ready awready) (payload (awaddr width 32))))',
            qr/missing required \(profile \.\.\.\) clause/],
        ['duplicate channel object',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v) (ready r) (payload (x width 1))) (valid-ready-channel b (channel W) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v2) (ready r2) (payload (x2 width 1))))',
            qr/supports exactly one \(valid-ready-channel \.\.\.\) object/],
        ['bad reset tuple',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n async)) (valid v) (ready r) (payload (x width 1))))',
            qr/reset tuple must include exactly one of active_low or active_high/],
        ['duplicate reset attribute',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low active_low async)) (valid v) (ready r) (payload (x width 1))))',
            qr/reset tuple has duplicate 'active_low' attribute/],
        ['duplicate source anchor field',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (document d2) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v) (ready r) (payload (x width 1))))',
            qr/\(anchor \.\.\.\) has duplicate \(document \.\.\.\) field/],
        ['bad payload width syntax',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v) (ready r) (payload (x bits 1))))',
            qr/payload entry 'x' supports only '\(width N\)'/],
    );

    for my $case (@cases) {
        my ($label, $source, $pattern) = @$case;
        my $ok = eval { FSM::Adapter::IAL2::PPIF->new()->parse_source($source, "$label.ppif"); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

subtest 'CLI emits IAL2 report JSON for .ppif without writing HDL' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for .ppif');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_channel.v1', 'CLI emits the IAL2 report schema');
    is($report->{generated_artifacts}{ial1}{name}, 'axi_aw_valid_ready_monitor.isf', 'CLI report names generated .isf');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi_aw_valid_ready_monitor.fsm'], 'CLI report names generated .fsm');
    is($report->{transfer_fire_condition}, 'awvalid && awready', 'CLI report carries fire condition');
};

subtest 'CLI --outdir materializes generated .isf, .fsm, and HDL for .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_aw.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, sample_ppif_path()],
    );

    ok($success, 'CLI generation succeeds for .ppif');
    is(join('', @{$stderr_buf || []}), '', 'CLI generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.isf'), '--outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.fsm'), '--outdir writes generated .fsm');
    ok(-f $hdl, '--output writes generated HDL');
    like(slurp(File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.isf')), qr/\(protocol-platform-intent\b|\(actor axi_aw_valid_ready_monitor\b/, 'generated .isf is inspectable text');
    like(slurp($hdl), qr/\bmodule\s+axi_aw_valid_ready_monitor\b/, 'generated HDL contains the monitor module');
};

subtest 'CLI check JSON and semantic JSON accept .ppif public source identity' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_ppif_path()],
    );
    ok($success, '--check --json succeeds for .ppif');
    is(join('', @{$stderr_buf || []}), '', '--check --json keeps stderr clean for .ppif');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ppif_path()),
        'check JSON reports the public .ppif source path, not the generated .fsm temporary',
    );
    ok($check_report->{support_accounting}{matched}, 'check JSON support accounting matches the PPIF sample');
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_aw_valid_ready',
        'check JSON support accounting names the PPIF corpus entry',
    );
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'check JSON support accounting records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_ppif_path()],
    );
    ok($semantic_success, '--emit-semantic-json succeeds for .ppif');
    is(join('', @{$semantic_stderr || []}), '', '--emit-semantic-json keeps stderr clean for .ppif');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_ppif_path()),
        'semantic JSON reports the public .ppif source path, not the generated .fsm temporary',
    );
    ok($semantic_report->{support_accounting}{matched}, 'semantic JSON support accounting matches the PPIF sample');
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_aw_valid_ready',
        'semantic JSON support accounting names the PPIF corpus entry',
    );
    is($semantic_report->{support_accounting}{source_kind}, 'ppif', 'semantic JSON support accounting records PPIF source kind');
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        'semantic JSON payload still describes the generated .fsm semantic root',
    );

    my $pif_path = File::Spec->catfile($tempdir, 'sample.pif');
    write_file($pif_path, sample_ppif());
    my ($alias_success, undef, undef, $alias_stdout, undef) = run(
        command => ['./bin/fsmgen', '--check', '--json', $pif_path],
    );
    ok(!$alias_success, '.pif alias is not accepted in the first public slice');
    ok(!decode_json(join('', @{$alias_stdout || []}))->{success}, '.pif alias check JSON reports failure');
};

done_testing();

sub sample_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_valid_ready.ppif');
}

sub sample_ppif {
    return slurp(sample_ppif_path());
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

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
