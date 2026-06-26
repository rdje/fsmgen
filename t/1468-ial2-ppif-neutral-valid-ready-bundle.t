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

my $neutral_bundle_path = File::Spec->catfile(
    $FindBin::Bin, '..', 'ppif', 'valid_ready_dual_channel_bundle.ppif',
);
my $axi_bundle_path = File::Spec->catfile(
    $FindBin::Bin, '..', 'ppif', 'axi_aw_w_valid_ready_bundle.ppif',
);

subtest 'adapter parses the protocol-neutral Valid-Ready bundle contract' => sub {
    ok(-f $neutral_bundle_path, 'tracked neutral bundle PPIF sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        slurp($neutral_bundle_path),
        $neutral_bundle_path,
    );
    my $report = $result->{report};

    is($result->{layer}, 'IAL2', 'neutral bundle adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.valid_ready_bundle', 'neutral bundle returns the aggregate bundle kind');
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.valid_ready_bundle.v1', 'neutral bundle uses the aggregate report schema');
    is($report->{bundle}{protocol}, 'valid-ready', 'neutral bundle reports the valid-ready profile');
    is($report->{bundle}{channel_count}, 2, 'neutral bundle reports both channels');
    is($report->{bundle}{inherited_source_count}, 1, 'neutral bundle reports one inherited channel source');
    is_deeply(
        $report->{bundle}{channel_object_names},
        [qw(data_downstream status_upstream)],
        'neutral bundle preserves channel order',
    );

    my @channels = @{$report->{channels}};
    is($channels[0]{source_attribution}{scope}, 'channel', 'first neutral channel has channel-local source');
    is($channels[1]{source_attribution}{scope}, 'inherited', 'second neutral channel inherits aggregate source');
    is($channels[1]{source_attribution}{inherited_from}, 'fsmgen-valid-ready-dual-channel-bundle', 'inherited source names the aggregate object');
    is($channels[0]{target_channel}{family}, 'data_downstream', 'first neutral channel reports authored family');
    is($channels[0]{target_channel}{role}, 'producer-to-consumer', 'first neutral channel reports producer-to-consumer role');
    is($channels[1]{target_channel}{family}, 'status_upstream', 'second neutral channel reports authored family');
    is($channels[1]{target_channel}{role}, 'consumer-to-producer', 'second neutral channel reports consumer-to-producer role');

    is_deeply(
        [map { $_->{name} } @{$result->{generated_ial1}{items}}],
        [qw(data_downstream_valid_ready_monitor.isf status_upstream_valid_ready_monitor.isf)],
        'neutral bundle exposes one generated IAL1 artifact per channel',
    );
    is_deeply(
        [map { $_->{entry_artifact} } @{$result->{generated_ial0}{items}}],
        [
            qw(
                data_downstream_valid_ready_monitor.fsm
                status_upstream_valid_ready_monitor.fsm
                valid_ready_dual_channel_bundle.fsm
            )
        ],
        'neutral bundle exposes channel artifacts plus aggregate wrapper/top',
    );
    is($report->{generated_artifacts}{hdl_entry}{kind}, 'aggregate_wrapper_top', 'neutral bundle selects the aggregate wrapper/top');
    is($report->{generated_artifacts}{hdl_entry}{entry_artifact}, 'valid_ready_dual_channel_bundle.fsm', 'neutral bundle reports wrapper/top artifact');

    my %aggregate_residue = residue_id_map($report->{unsupported_residue});
    ok($aggregate_residue{valid_ready_profile_bundle_behavior_outside_monitor}, 'neutral bundle reports generic aggregate residue');
    ok(!$aggregate_residue{axi_manager_concurrency}, 'neutral bundle omits AXI manager residue');
    for my $channel (@channels) {
        my %channel_residue = residue_id_map($channel->{unsupported_residue});
        ok($channel_residue{valid_ready_profile_behavior_outside_monitor}, "$channel->{object_name} reports generic channel residue");
        ok(!$channel_residue{axi_manager_concurrency}, "$channel->{object_name} omits AXI channel residue");
    }
};

subtest 'AXI bundle residue remains AXI-profile local' => sub {
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        slurp($axi_bundle_path),
        $axi_bundle_path,
    );
    my %aggregate_residue = residue_id_map($result->{report}{unsupported_residue});
    ok($aggregate_residue{axi_manager_concurrency}, 'AXI bundle preserves AXI manager-concurrency residue');
    ok(!$aggregate_residue{valid_ready_profile_bundle_behavior_outside_monitor}, 'AXI bundle does not report generic neutral aggregate residue');
};

subtest 'CLI schedule/check/semantic surfaces support-account the neutral bundle' => sub {
    my ($schedule_success, undef, undef, $schedule_stdout, $schedule_stderr) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $neutral_bundle_path],
    );
    ok($schedule_success, 'neutral bundle --emit-schedule-json succeeds');
    is(join('', @{$schedule_stderr || []}), '', 'neutral bundle schedule JSON keeps stderr clean');
    my $schedule_report = decode_json(join('', @{$schedule_stdout || []}));
    is($schedule_report->{bundle}{protocol}, 'valid-ready', 'neutral bundle schedule JSON reports protocol');
    is($schedule_report->{bundle}{channel_count}, 2, 'neutral bundle schedule JSON reports channel count');

    my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $neutral_bundle_path],
    );
    ok($check_success, 'neutral bundle --check --json succeeds');
    is(join('', @{$check_stderr || []}), '', 'neutral bundle check JSON keeps stderr clean');
    my $check_report = decode_json(join('', @{$check_stdout || []}));
    ok($check_report->{success}, 'neutral bundle check JSON reports success');
    ok($check_report->{support_accounting}{matched}, 'neutral bundle check JSON matches support accounting');
    is($check_report->{support_accounting}{entry_id}, 'intent.ppif_valid_ready_dual_channel_bundle', 'neutral bundle check JSON reports support id');
    is($check_report->{result}{composition_child_count}, 2, 'neutral bundle check JSON reports aggregate child count');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $neutral_bundle_path],
    );
    ok($semantic_success, 'neutral bundle --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'neutral bundle semantic JSON keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'neutral bundle semantic JSON reports success');
    is($semantic_report->{support_accounting}{entry_id}, 'intent.ppif_valid_ready_dual_channel_bundle', 'neutral bundle semantic JSON reports support id');
    is($semantic_report->{semantic}{module}{source_root_kind}, 'ppif_bundle', 'neutral bundle semantic JSON uses aggregate PPIF root');
    is($semantic_report->{semantic}{protocol_intent_bundle}{bundle}{channel_count}, 2, 'neutral bundle semantic JSON reports bundle channel count');
    is($semantic_report->{semantic}{protocol_intent_bundle}{generated_artifacts}{hdl_entry}{entry_artifact}, 'valid_ready_dual_channel_bundle.fsm', 'neutral bundle semantic JSON reports wrapper/top entry');
};

subtest 'CLI materializes neutral bundle review artifacts and aggregate HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'neutral-bundle.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, $neutral_bundle_path],
    );
    ok($success, 'neutral bundle --outdir --output succeeds');
    is(join('', @{$stderr_buf || []}), '', 'neutral bundle --outdir --output keeps stderr clean');

    for my $artifact (
        qw(
            data_downstream_valid_ready_monitor.isf
            status_upstream_valid_ready_monitor.isf
            data_downstream_valid_ready_monitor.fsm
            status_upstream_valid_ready_monitor.fsm
            valid_ready_dual_channel_bundle.fsm
        )
    ) {
        ok(-f File::Spec->catfile($outdir, $artifact), "neutral bundle writes $artifact");
    }
    ok(-f $hdl, 'neutral bundle writes aggregate HDL output');
    like(slurp(File::Spec->catfile($outdir, 'valid_ready_dual_channel_bundle.fsm')), qr/\(\?top:valid_ready_dual_channel_bundle\b/, 'neutral bundle wrapper/top .fsm is inspectable');
    my $sv = slurp($hdl);
    like($sv, qr/\bmodule\s+valid_ready_dual_channel_bundle\b/, 'neutral bundle HDL contains wrapper/top module');
    like($sv, qr/\bdata_downstream_valid_ready_monitor\s+data_downstream_valid_ready_monitor\b/, 'neutral bundle HDL instantiates downstream child');
    like($sv, qr/\bstatus_upstream_valid_ready_monitor\s+status_upstream_valid_ready_monitor\b/, 'neutral bundle HDL instantiates upstream child');
};

done_testing();

sub residue_id_map {
    my ($entries) = @_;
    return map { $_->{id} => 1 } @{$entries || []};
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "open $path: $!";
    local $/;
    return <$fh>;
}
