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
    is($result->{report}{source_object}{intent_name}, 'axi_aw_valid_ready', 'source intent name is preserved');
    is($result->{report}{target_channel}{protocol}, 'axi4', 'profile maps to generator protocol');
    is($result->{report}{target_channel}{family}, 'AW', 'channel maps to target channel family');
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'direct IAL2-to-IAL0 remains forbidden');
};

subtest 'PPIF adapter parses a multi-channel Valid-Ready bundle' => sub {
    my $sample_path = sample_bundle_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF bundle sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_bundle_ppif(), $sample_path);

    is($result->{layer}, 'IAL2', 'bundle adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.valid_ready_bundle', 'adapter returns the aggregate bundle kind');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_bundle.v1', 'bundle report schema is selected');
    is($result->{report}{bundle}{channel_count}, 2, 'bundle report counts both channels');
    is_deeply(
        [map { $_->{object_name} } @{$result->{report}{channels}}],
        [qw(axi_aw axi_w)],
        'bundle report preserves source channel order',
    );
    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(axi_aw_valid_ready_monitor.isf axi_w_valid_ready_monitor.isf)],
        'bundle exposes one generated IAL1 artifact per channel',
    );
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        [qw(axi_aw_valid_ready_monitor.fsm axi_aw_w_valid_ready_bundle.fsm axi_w_valid_ready_monitor.fsm)],
        'bundle exposes both channel IAL0 artifacts plus the aggregate wrapper/top artifact',
    );
    my $hdl_entry = $result->{report}{generated_artifacts}{hdl_entry};
    is($hdl_entry->{selected}, 1, 'bundle reports a selected HDL entry');
    is($hdl_entry->{kind}, 'aggregate_wrapper_top', 'bundle selects the aggregate wrapper/top entry kind');
    is($hdl_entry->{entry_artifact}, 'axi_aw_w_valid_ready_bundle.fsm', 'bundle HDL entry points at the wrapper/top .fsm');
    is_deeply(
        $hdl_entry->{child_artifacts},
        [qw(axi_aw_valid_ready_monitor.fsm axi_w_valid_ready_monitor.fsm)],
        'bundle HDL entry keeps per-channel child artifacts listed',
    );
    is($result->{report}{channels}[0]{source_attribution}{scope}, 'channel', 'channel-local source attribution is reported');
};

subtest 'PPIF adapter diagnostics fail closed before generation claims' => sub {
    my @cases = (
        ['missing profile',
            '(protocol-platform-intent p (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel axi_aw (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid awvalid) (ready awready) (payload (awaddr width 32))))',
            qr/missing required \(profile \.\.\.\) clause/],
        ['duplicate channel object name',
            '(protocol-platform-intent p (profile axi4) (source (object o) (anchor (document d) (section s) (page p))) (valid-ready-channel a (channel AW) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v) (ready r) (payload (x width 1))) (valid-ready-channel a (channel W) (role manager-to-subordinate) (clock clk) (reset (rst_n active_low async)) (valid v2) (ready r2) (payload (x2 width 1))))',
            qr/duplicate valid-ready-channel object name 'a'/],
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

subtest 'CLI emits IAL2 bundle report JSON for multi-channel .ppif' => sub {
    my $bundle_path = sample_bundle_ppif_path();

    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $bundle_path],
    );

    ok($success, '--emit-schedule-json succeeds for a multi-channel .ppif bundle');
    is(join('', @{$stderr_buf || []}), '', 'bundle report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_bundle.v1', 'CLI emits the bundle report schema');
    is($report->{source_object}{intent_name}, 'axi_aw_w_valid_ready_bundle', 'bundle report carries the PPIF top-level intent name');
    is($report->{bundle}{channel_count}, 2, 'bundle report carries channel count');
    is_deeply(
        [map { $_->{object_name} } @{$report->{channels}}],
        [qw(axi_aw axi_w)],
        'CLI bundle report preserves channel order',
    );
    is($report->{generated_artifacts}{hdl_entry}{selected}, 1, 'CLI bundle report records selected HDL entry');
    is($report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_aw_w_valid_ready_bundle.fsm', 'CLI bundle report names wrapper/top entry artifact');
};

subtest 'CLI emits IAL2 report JSON for .ppif without writing HDL' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for .ppif');
    is(join('', @{$stderr_buf || []}), '', '--emit-schedule-json keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_channel.v1', 'CLI emits the IAL2 report schema');
    is($report->{source_object}{intent_name}, 'axi_aw_valid_ready', 'CLI report carries the PPIF top-level intent name');
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

subtest 'CLI --outdir materializes bundle review artifacts and HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $bundle_path = sample_bundle_ppif_path();
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'bundle.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $bundle_path],
    );

    ok($success, 'bundle --outdir succeeds');
    is(join('', @{$stderr_buf || []}), '', 'bundle --outdir keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.isf'), 'bundle --outdir writes AW generated .isf');
    ok(-f File::Spec->catfile($outdir, 'axi_w_valid_ready_monitor.isf'), 'bundle --outdir writes W generated .isf');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_valid_ready_monitor.fsm'), 'bundle --outdir writes AW generated .fsm');
    ok(-f File::Spec->catfile($outdir, 'axi_w_valid_ready_monitor.fsm'), 'bundle --outdir writes W generated .fsm');
    ok(-f File::Spec->catfile($outdir, 'axi_aw_w_valid_ready_bundle.fsm'), 'bundle --outdir writes aggregate wrapper/top .fsm');
    ok(-f $hdl, 'bundle --output writes aggregate wrapper/top HDL');
    like(slurp(File::Spec->catfile($outdir, 'axi_aw_w_valid_ready_bundle.fsm')), qr/\(\?top:axi_aw_w_valid_ready_bundle\b/, 'aggregate wrapper/top .fsm is inspectable text');
    like(slurp($hdl), qr/\bmodule\s+axi_aw_w_valid_ready_bundle\b/, 'bundle HDL contains the aggregate wrapper/top module');
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

subtest 'CLI bundle HDL modes use aggregate wrapper entry' => sub {
    my $bundle_path = sample_bundle_ppif_path();
    my $tempdir = tempdir(CLEANUP => 1);

    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $bundle_path],
    );
    ok($check_success, 'bundle --check --json succeeds without HDL emission');
    is(join('', @{$check_stderr || []}), '', 'bundle --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'bundle check JSON reports success');
    is($check_report->{result}{composition_child_count}, 2, 'bundle check JSON discloses channel count as child-count summary');

    my $default_hdl = File::Spec->catfile($tempdir, 'default-bundle.sv');
    my ($default_success, undef, undef, undef, $default_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--output', $default_hdl, $bundle_path],
    );
    ok($default_success, 'bundle default HDL generation succeeds through the aggregate wrapper/top');
    is(join('', @{$default_stderr || []}), '', 'bundle default HDL generation keeps stderr clean');
    ok(-f $default_hdl, 'bundle default HDL writes the requested output file');
    my $default_hdl_text = slurp($default_hdl);
    like($default_hdl_text, qr/\bmodule\s+axi_aw_w_valid_ready_bundle\b/, 'bundle default HDL contains the wrapper/top module');
    like($default_hdl_text, qr/\baxi_aw_valid_ready_monitor\s+axi_aw_valid_ready_monitor\b/, 'bundle default HDL instantiates the AW child');
    like($default_hdl_text, qr/\baxi_w_valid_ready_monitor\s+axi_w_valid_ready_monitor\b/, 'bundle default HDL instantiates the W child');
    unlike($default_hdl_text, qr/\bassign\s+functioncall_expr\b/, 'sampled-value helpers are not emitted as unclocked combinational assigns');
    like($default_hdl_text, qr/\$past\(awvalid\)/, 'sampled-value property text stays inline in assertions');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $bundle_path],
    );
    ok($semantic_success, 'bundle semantic JSON succeeds without HDL emission');
    is(join('', @{$semantic_stderr || []}), '', 'bundle semantic JSON keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'bundle semantic JSON report is successful');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($bundle_path),
        'bundle semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_aw_w_valid_ready_bundle',
        'bundle semantic JSON support accounting names the bundle corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'ppif_bundle',
        'bundle semantic JSON uses an aggregate PPIF bundle semantic root',
    );
    is(
        $semantic_report->{semantic}{module}{composition_child_count},
        2,
        'bundle semantic JSON reports the channel count as aggregate children',
    );
    my $bundle_semantic = $semantic_report->{semantic}{protocol_intent_bundle};
    is($bundle_semantic->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_bundle.v1', 'bundle semantic child records schema');
    is($bundle_semantic->{bundle}{channel_count}, 2, 'bundle semantic child records channel count');
    is_deeply(
        $bundle_semantic->{bundle}{channel_object_names},
        ['axi_aw', 'axi_w'],
        'bundle semantic child preserves channel order',
    );
    is($bundle_semantic->{generated_ial1_schedule_report_count}, 2, 'bundle semantic child records per-channel schedule report count');
    ok($bundle_semantic->{generated_artifacts}{hdl_entry}{selected}, 'bundle semantic child selects the HDL entry');
    is($bundle_semantic->{generated_artifacts}{hdl_entry}{kind}, 'aggregate_wrapper_top', 'bundle semantic child records wrapper/top entry kind');
    is($bundle_semantic->{generated_artifacts}{hdl_entry}{entry_artifact}, 'axi_aw_w_valid_ready_bundle.fsm', 'bundle semantic child records wrapper/top entry artifact');
    is_deeply(
        [map { $_->{name} } @{$bundle_semantic->{generated_artifacts}{ial1}{items} || []}],
        ['axi_aw_valid_ready_monitor.isf', 'axi_w_valid_ready_monitor.isf'],
        'bundle semantic child lists generated IAL1 review artifacts',
    );
    is_deeply(
        [map { $_->{entry_artifact} } @{$bundle_semantic->{generated_artifacts}{ial0}{items} || []}],
        ['axi_aw_valid_ready_monitor.fsm', 'axi_w_valid_ready_monitor.fsm', 'axi_aw_w_valid_ready_bundle.fsm'],
        'bundle semantic child lists generated IAL0 review artifacts plus wrapper/top',
    );

    my $verify_outdir = File::Spec->catdir($tempdir, 'verify-out');
    my $verify_hdl = File::Spec->catfile($tempdir, 'verify-bundle.sv');
    my ($verify_success, undef, undef, undef, $verify_stderr) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $verify_outdir, '--output', $verify_hdl, '--verify-hdl', $bundle_path],
    );
    ok($verify_success, 'bundle --verify-hdl validates the aggregate wrapper/top HDL');
    is(join('', @{$verify_stderr || []}), '', 'bundle --verify-hdl keeps stderr clean');
    ok(-f $verify_hdl, 'bundle --verify-hdl writes the requested HDL output');
    ok(-f File::Spec->catfile($verify_outdir, 'axi_aw_w_valid_ready_bundle.fsm'), 'bundle --verify-hdl keeps wrapper/top review artifact in --outdir');
};

done_testing();

sub sample_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_valid_ready.ppif');
}

sub sample_bundle_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_w_valid_ready_bundle.ppif');
}

sub sample_ppif {
    return slurp(sample_ppif_path());
}

sub sample_bundle_ppif {
    return slurp(sample_bundle_ppif_path());
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
