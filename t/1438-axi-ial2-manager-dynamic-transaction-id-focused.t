#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use IPC::Cmd qw(run);
use JSON::PP qw(decode_json);

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::IAL2::PPIF;
use FSM::Pipeline::SourceFrontend;
use FSM::HDL::FlattenedDT;

my @DYNAMIC_CASES = (
    {
        label        => 'dynamic metadata-only transaction IDs',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_transaction_id.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-transaction-id',
        intent_name  => 'axi_manager_capacity_status_dynamic_transaction_id',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_transaction_id',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_transaction_id_pipeline_cli',
        behavior     => 'metadata_only',
    },
    {
        label        => 'dynamic write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_write_response_demux.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-write-response-demux',
        intent_name  => 'axi_manager_capacity_status_dynamic_write_response_demux',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_write_response_demux_pipeline_cli',
        behavior     => 'dynamic_write_demux',
    },
    {
        label        => 'dynamic read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-response-demux',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_response_demux',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_response_demux_pipeline_cli',
        behavior     => 'dynamic_read_demux',
    },
    {
        label        => 'dynamic read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-response-demux-burst-last',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_response_demux_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_response_demux_burst_last_pipeline_cli',
        behavior     => 'dynamic_read_rlast_demux',
    },
    {
        label        => 'dynamic read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_pipeline_cli',
        behavior     => 'dynamic_read_data',
    },
    {
        label        => 'dynamic read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_last_beat.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-last-beat',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_last_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_last_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_last_beat_pipeline_cli',
        behavior     => 'dynamic_read_data_last_beat',
    },
);

my $adapter = FSM::Adapter::IAL2::PPIF->new();
my $base = parse_ppif('ppif/axi_manager_capacity_status.ppif');

subtest 'bounded PPIF adapter checks cover the shipped dynamic transaction-ID family' => sub {
    for my $case (@DYNAMIC_CASES) {
        subtest $case->{label} => sub {
            my $result = parse_ppif($case->{relpath});
            assert_common_dynamic_case($result, $case);
            assert_dynamic_behavior($result, $case);
        };
    }
};

subtest 'bounded CLI JSON checks cover dynamic PPIF support accounting' => sub {
    for my $case (@DYNAMIC_CASES) {
        subtest $case->{label} => sub {
            my $check = run_json_command(
                ['./bin/fsmgen', '--strict', '--check', '--json', $case->{relpath}],
                "$case->{label} strict check JSON",
            );
            assert_support_accounting($check, $case, "$case->{label} check JSON");
            is($check->{result}{module_name}, 'axi0_capacity_status', "$case->{label} check names generated module");

            my $semantic = run_json_command(
                ['./bin/fsmgen', '--strict', '--emit-semantic-json', $case->{relpath}],
                "$case->{label} semantic JSON",
            );
            assert_support_accounting($semantic, $case, "$case->{label} semantic JSON");
            is($semantic->{semantic}{module}{name}, 'axi0_capacity_status', "$case->{label} semantic JSON names generated module");
            is($semantic->{semantic}{module}{source_root_kind}, 'fsm', "$case->{label} semantic JSON reports generated FSM root");
        };
    }
};

done_testing;

sub assert_common_dynamic_case {
    my ($result, $case) = @_;

    ok(-f repo_path($case->{relpath}), "$case->{label} public PPIF sample exists");
    is($result->{layer}, 'IAL2', "$case->{label} stays in IAL2");
    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', "$case->{label} uses the AXI manager capacity/status generator");
    is($result->{report}{source_object}{id}, $case->{object_id}, "$case->{label} preserves source object id");
    is($result->{report}{source_object}{intent_name}, $case->{intent_name}, "$case->{label} preserves source intent name");
    is_deeply(sorted([keys %{$result->{generated_ial0}{files}}]), ['axi0_capacity_status.fsm'], "$case->{label} emits one generated IAL0 artifact");
}

sub assert_dynamic_behavior {
    my ($result, $case) = @_;
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    if ($case->{behavior} eq 'metadata_only') {
        is($isf, $base->{generated_ial1}{text}, 'dynamic metadata-only sample leaves generated IAL1 unchanged');
        is_deeply($result->{generated_ial0}{files}, $base->{generated_ial0}{files}, 'dynamic metadata-only sample leaves generated IAL0 unchanged');
        unlike($isf, qr/\(input axi0_awid\b/, 'dynamic metadata-only sample does not generate AWID input');
        unlike($isf, qr/\(input axi0_bid\b/, 'dynamic metadata-only sample does not generate BID input');
        unlike($isf, qr/\(input axi0_arid\b/, 'dynamic metadata-only sample does not generate ARID input');
        unlike($isf, qr/\(input axi0_rid\b/, 'dynamic metadata-only sample does not generate RID input');
        ok(!exists $result->{report}{id_response_rule_engine}, 'dynamic metadata-only sample emits no concrete-ID assertion engine');
        assert_dynamic_transaction_metadata($result->{report}{transactions});
        assert_dynamic_residue($result->{report}, 'metadata-only dynamic IDs stay explicitly bounded');
        return;
    }

    if ($case->{behavior} eq 'dynamic_write_demux') {
        like($isf, qr/\(input axi0_w0_request\)/, 'dynamic write demux declares transaction request input');
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'dynamic write demux declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'dynamic write demux declares BID input');
        unlike($isf, qr/\(input axi0_w0_complete\b/, 'dynamic write demux owns generated completion');
        like($isf, qr/\(output axi0_w0_complete\)/, 'dynamic write demux exposes matched completion output');
        like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'dynamic write demux allocates selected-ID storage');
        like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'dynamic write demux allocates busy storage');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) axi0_w0_complete\)\) \(! axi0_w0_dynamic_busy_q\)\)/, 'dynamic write demux captures admitted AWID');
        like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'dynamic write demux matches active BID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q\)/, 'dynamic write demux releases active state');
        assert_dynamic_write_report($result->{report});
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers dynamic write BID match');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_awid\b/, 'SystemVerilog exposes AWID');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog exposes BID');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers dynamic write response guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_demux') {
        like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read demux declares transaction request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read demux declares RID input');
        unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read demux owns generated completion');
        like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read demux exposes matched completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'dynamic read demux allocates selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'dynamic read demux allocates busy storage');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) \(! axi0_r0_dynamic_busy_q\)\)/, 'dynamic read demux captures admitted ARID');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'dynamic read demux matches active RID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q\)/, 'dynamic read demux releases active state');
        assert_dynamic_read_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers dynamic read RID match');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers dynamic read response guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_rlast_demux') {
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic read RLAST demux declares RLAST input');
        unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read RLAST demux owns generated completion');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic read RLAST demux matches active RID and RLAST');
        assert_dynamic_read_rlast_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers dynamic RID/RLAST match');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers dynamic RID/RLAST guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'dynamic read-data keeps generated RID demux');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'dynamic read-data declares scalar data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'dynamic read-data captures payload under generated completion');
        assert_dynamic_read_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_response_demux_completion_pulse', [qw(rlast_completion bursts multi_beat_read_data_reassembly)]);
        like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers dynamic read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog guards dynamic read-data capture by completion');
        like($hdl, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures dynamic RDATA');
        like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures dynamic RRESP');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_last_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic last-beat read-data keeps generated RID/RLAST demux');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic last-beat read-data declares RDATA input');
        like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'dynamic last-beat read-data declares scalar last data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'dynamic last-beat read-data captures payload under generated completion');
        unlike($isf, qr/\baxi0_arlen\b/, 'dynamic last-beat read-data keeps burst-length metadata absent');
        assert_dynamic_read_rlast_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_response_demux_last_beat_completion_pulse', [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)]);
        like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers dynamic last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog guards dynamic last-beat read-data capture by completion');
        like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures dynamic last-beat RDATA');
        like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures dynamic last-beat RRESP');
        return;
    }

    fail("unknown dynamic behavior '$case->{behavior}'");
}

sub assert_dynamic_transaction_metadata {
    my ($transactions) = @_;

    is(scalar(@$transactions), 2, 'metadata-only dynamic sample reports both dynamic transactions');
    is_deeply(
        [map { $_->{id}{implementation_status} } @$transactions],
        [qw(selected_not_generated selected_not_generated)],
        'metadata-only dynamic sample reports selected_not_generated ownership',
    );
    is_deeply([map { $_->{id}{policy} } @$transactions], [qw(dynamic dynamic)], 'metadata-only dynamic sample reports dynamic policies');
    is_deeply([map { $_->{id}{family} } @$transactions], [qw(write read)], 'metadata-only dynamic sample reports write/read families');
    is_deeply([map { $_->{id}{request_id_source} } @$transactions], [qw(axi0_awid axi0_arid)], 'metadata-only dynamic sample reports request ID sources');
    is_deeply([map { $_->{id}{response_id_signal} } @$transactions], [qw(axi0_bid axi0_rid)], 'metadata-only dynamic sample reports response ID signals');
}

sub assert_dynamic_write_report {
    my ($report) = @_;
    my $write = $report->{response_demux}{write};

    is($report->{response_demux}{mode}, 'bounded_dynamic_write_bid_demux_contract', 'dynamic write report marks BID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'dynamic write report marks generated demux behavior');
    is($write->{transaction_completion_source}, 'generated_dynamic_demux', 'dynamic write report marks generated completion source');
    is($write->{transaction_completion_semantics}, 'matched_dynamic_id', 'dynamic write report marks matched dynamic ID completion');
    is_deeply($write->{dynamic_transactions}, [qw(w0)], 'dynamic write report names the covered dynamic transaction');
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux)], 'dynamic write report names generated response-demux rule');
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete)], 'dynamic write report names generated completion');
    is_deeply($write->{generated_assertions}, [qw(axi0_w0_dynamic_request_not_busy axi0_write_dynamic_response_active_match axi0_w0_dynamic_completion_active)], 'dynamic write report names generated assertions');
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic write transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic write demux keeps future dynamic residue visible');
}

sub assert_dynamic_read_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_dynamic_read_rid_demux_contract', 'dynamic read report marks RID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'dynamic read report marks generated demux behavior');
    is($read->{response_scope}, 'single_beat', 'dynamic read report marks single-beat scope');
    is($read->{transaction_completion_source}, 'generated_dynamic_demux', 'dynamic read report marks generated completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_single_beat', 'dynamic read report marks matched dynamic RID completion');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'dynamic read report names the covered dynamic transaction');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux)], 'dynamic read report names generated response-demux rule');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete)], 'dynamic read report names generated completion');
    is_deeply($read->{generated_assertions}, [qw(axi0_r0_dynamic_request_not_busy axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)], 'dynamic read report names generated assertions');
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic read transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic read demux keeps future dynamic residue visible');
}

sub assert_dynamic_read_rlast_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_dynamic_read_rid_rlast_demux_contract', 'dynamic read RLAST report marks RID/RLAST-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'dynamic read RLAST report marks generated demux behavior');
    is($read->{response_scope}, 'burst_last', 'dynamic read RLAST report marks burst-last scope');
    is($read->{last_signal}, 'axi0_rlast', 'dynamic read RLAST report names RLAST signal');
    is($read->{transaction_completion_source}, 'generated_dynamic_demux_last_beat', 'dynamic read RLAST report marks generated last-beat completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_and_last_signal', 'dynamic read RLAST report marks matched dynamic ID and last-signal completion');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'dynamic read RLAST report names the covered dynamic transaction');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux)], 'dynamic read RLAST report names generated response-demux rule');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete)], 'dynamic read RLAST report names generated completion');
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic read RLAST transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic read RLAST demux keeps future dynamic residue visible');
}

sub assert_read_data_report {
    my ($read_data, $completion_validity, $expected_residue) = @_;
    my $read = $read_data->{read};

    ok($read_data->{generated_behavior}, 'dynamic read-data report marks generated behavior');
    is($read->{completion_source}, 'response_demux', 'dynamic read-data report binds capture to response-demux completion');
    is($read->{completion_validity}, $completion_validity, 'dynamic read-data report names generated dynamic completion validity');
    is($read->{data_signal}, 'axi0_rdata', 'dynamic read-data report names RDATA input');
    is($read->{status_signal}, 'axi0_rresp', 'dynamic read-data report names RRESP input');
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], [qw(r0)], 'dynamic read-data report binds r0 only');
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], [qw(axi0_r0_complete)], 'dynamic read-data report uses generated r0 completion');
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp)], 'dynamic read-data report names generated inputs');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_read_data_capture)], 'dynamic read-data report names capture rule');
    is_deeply($read_data->{residue}, $expected_residue, 'dynamic read-data report keeps explicit residue');
}

sub assert_dynamic_residue {
    my ($report, $message) = @_;
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue} || []};
    ok($residue{dynamic_transaction_id_behavior}, $message);
}

sub assert_support_accounting {
    my ($json, $case, $owner) = @_;

    ok($json->{success}, "$owner succeeds");
    is($json->{support_accounting}{entry_id}, $case->{entry_id}, "$owner reports expected support entry");
    is($json->{support_accounting}{coverage}, $case->{coverage}, "$owner reports expected support coverage");
    ok($json->{support_accounting}{strict_supported}, "$owner reports strict support");
    is($json->{source}{resolved_path}, abs_path(repo_path($case->{relpath})), "$owner reports resolved public PPIF path");
}

sub parse_ppif {
    my ($relpath) = @_;
    my $path = repo_path($relpath);
    my $source = read_file($path);
    return $adapter->parse_source($source, $path);
}

sub run_json_command {
    my ($command, $owner) = @_;
    my ($success, undef, undef, $stdout, $stderr) = run(command => $command);

    ok($success, "$owner command succeeds");
    is(join('', @{$stderr || []}), '', "$owner keeps stderr clean");
    return decode_json(join('', @{$stdout || []}));
}

sub hdl_for {
    my ($module_name, $fsm_text) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, "$module_name.fsm");
    write_file($fsm_path, $fsm_text);

    my $raw_ast = FSM::Pipeline::SourceFrontend->parse_fsm_file(
        fsm_file    => $fsm_path,
        debug_level => 0,
    );
    my $fsm_module = FSM::Pipeline::SourceFrontend->create_fsm_module(
        raw_ast     => $raw_ast,
        debug_level => 0,
    );
    ok($fsm_module, "$module_name scheduled FSM parses through the normal frontend");

    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot open $path for read: $!";
    local $/;
    return <$fh>;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub repo_path {
    my ($relpath) = @_;
    return File::Spec->catfile($FindBin::Bin, '..', split('/', $relpath));
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
