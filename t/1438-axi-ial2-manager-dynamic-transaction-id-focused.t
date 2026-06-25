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
        label        => 'dynamic same-ID issue-order queue policy metadata',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-same-id-issue-order-queue-policy',
        intent_name  => 'axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_same_id_issue_order_queue_policy',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_same_id_issue_order_queue_policy_pipeline_cli',
        behavior     => 'dynamic_same_id_issue_order_queue_metadata',
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
        label        => 'multiple dynamic write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-write-response-demux-multi',
        intent_name  => 'axi_manager_capacity_status_dynamic_write_response_demux_multi',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux_multi',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_write_response_demux_multi_pipeline_cli',
        behavior     => 'dynamic_write_demux_multi',
    },
    {
        label        => 'dynamic write BID same-ID issue-order queue',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-write-same-id-issue-order-queue',
        intent_name  => 'axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_write_same_id_issue_order_queue',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_write_same_id_issue_order_queue_pipeline_cli',
        behavior     => 'dynamic_write_same_id_issue_order_queue',
    },
    {
        label        => 'dynamic read RID same-ID issue-order queue',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-same-id-issue-order-queue',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_pipeline_cli',
        behavior     => 'dynamic_read_same_id_issue_order_queue',
    },
    {
        label        => 'dynamic read RID/RLAST same-ID issue-order queue',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-burst-last-same-id-issue-order-queue',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_pipeline_cli',
        behavior     => 'dynamic_read_burst_last_same_id_issue_order_queue',
    },
    {
        label        => 'dynamic read RID same-ID issue-order queue read-data',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-same-id-issue-order-queue-read-data',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_same_id_issue_order_queue_read_data_pipeline_cli',
        behavior     => 'dynamic_read_same_id_issue_order_queue_read_data',
    },
    {
        label        => 'dynamic read RID/RLAST same-ID issue-order queue read-data',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-burst-last-same-id-issue-order-queue-read-data',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_burst_last_same_id_issue_order_queue_read_data_pipeline_cli',
        behavior     => 'dynamic_read_burst_last_same_id_issue_order_queue_read_data',
    },
    {
        label        => 'mixed dynamic/static write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux.ppif',
        object_id    => 'axi-manager-capacity-status-write-mixed-dynamic-static-response-demux',
        intent_name  => 'axi_manager_capacity_status_write_mixed_dynamic_static_response_demux',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux',
        coverage     => 'ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_pipeline_cli',
        behavior     => 'mixed_dynamic_static_write_demux',
    },
    {
        label        => 'multiple mixed dynamic/static write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif',
        object_id    => 'axi-manager-capacity-status-write-mixed-dynamic-static-response-demux-multi-static',
        intent_name  => 'axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static',
        coverage     => 'ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static_pipeline_cli',
        behavior     => 'mixed_dynamic_static_write_demux_multi_static',
    },
    {
        label        => 'three-static mixed dynamic/static write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3.ppif',
        object_id    => 'axi-manager-capacity-status-write-mixed-dynamic-static-response-demux-multi-static3',
        intent_name  => 'axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3',
        coverage     => 'ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static3_pipeline_cli',
        behavior     => 'mixed_dynamic_static_write_demux_multi_static3',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static write BID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif',
        object_id    => 'axi-manager-capacity-status-write-mixed-dynamic-static-response-demux-multi-dynamic',
        intent_name  => 'axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic',
        coverage     => 'ial2_ppif_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic_pipeline_cli',
        behavior     => 'mixed_dynamic_static_write_demux_multi_dynamic',
    },
    {
        label        => 'mixed dynamic/static read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_demux',
    },
    {
        label        => 'multiple mixed dynamic/static read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_demux_multi_static',
    },
    {
        label        => 'three-static mixed dynamic/static read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_demux_multi_static3',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_demux_multi_dynamic',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_dynamic',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_rlast_demux_multi_dynamic',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_dynamic_last_beat',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last-read-data-burst-length',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_dynamic_burst_length',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last-read-data-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion',
    },
    {
        label        => 'multi-dynamic mixed dynamic/static multi-beat read-data',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-dynamic-burst-last-read-data-multi-beat',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last_read_data_multi_beat_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_dynamic_multi_beat',
    },
    {
        label        => 'mixed dynamic/static read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_rlast_demux',
    },
    {
        label        => 'multiple mixed dynamic/static read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-burst-last',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_rlast_demux_multi_static',
    },
    {
        label        => 'three-static mixed dynamic/static read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-burst-last',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_rlast_demux_multi_static3',
    },
    {
        label        => 'three-static mixed dynamic/static read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static3',
    },
    {
        label        => 'three-static mixed dynamic/static read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-burst-last-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static3_last_beat',
    },
    {
        label        => 'three-static mixed dynamic/static read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-burst-last-read-data-burst-length',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static3_burst_length',
    },
    {
        label        => 'three-static mixed dynamic/static read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-burst-last-read-data-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion',
    },
    {
        label        => 'three-static mixed dynamic/static read-data multi-beat output bank',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static3-burst-last-read-data-multi-beat',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last_read_data_multi_beat_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static3_multi_beat',
    },
    {
        label        => 'multiple mixed dynamic/static read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static',
    },
    {
        label        => 'multiple mixed dynamic/static read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-burst-last-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static_last_beat',
    },
    {
        label        => 'multiple mixed dynamic/static read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-burst-last-read-data-burst-length',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static_burst_length',
    },
    {
        label        => 'multiple mixed dynamic/static read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-burst-last-read-data-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static_burst_length_runtime_assertion',
    },
    {
        label        => 'multiple mixed dynamic/static read-data multi-beat output bank',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-multi-static-burst-last-read-data-multi-beat',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last_read_data_multi_beat_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_static_multi_beat',
    },
    {
        label        => 'mixed dynamic/static read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data',
    },
    {
        label        => 'mixed dynamic/static read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last-read-data',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_last_beat',
    },
    {
        label        => 'mixed dynamic/static read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last-read-data-burst-length',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_burst_length',
    },
    {
        label        => 'mixed dynamic/static read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last-read-data-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_burst_length_runtime_assertion',
    },
    {
        label        => 'mixed dynamic/static read-data multi-beat output bank',
        relpath      => 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last-read-data-multi-beat',
        intent_name  => 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last_read_data_multi_beat_pipeline_cli',
        behavior     => 'mixed_dynamic_static_read_data_multi_beat',
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
        label        => 'multiple dynamic read single-beat RID response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-response-demux-multi',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_response_demux_multi',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_multi',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_response_demux_multi_pipeline_cli',
        behavior     => 'dynamic_read_demux_multi',
    },
    {
        label        => 'multiple dynamic read burst-last RID/RLAST response demux',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-response-demux-multi-burst-last',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_response_demux_multi_burst_last_pipeline_cli',
        behavior     => 'dynamic_read_rlast_demux_multi',
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
    {
        label        => 'multiple dynamic read-data single-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_pipeline_cli',
        behavior     => 'dynamic_read_data_multi',
    },
    {
        label        => 'multiple dynamic read-data last-beat capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi-last-beat',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi_last_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_last_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_last_beat_pipeline_cli',
        behavior     => 'dynamic_read_data_multi_last_beat',
    },
    {
        label        => 'multiple dynamic read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_burst_length_pipeline_cli',
        behavior     => 'dynamic_read_data_multi_burst_length',
    },
    {
        label        => 'multiple dynamic read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'dynamic_read_data_multi_burst_length_runtime_assertion',
    },
    {
        label        => 'multiple dynamic read-data multi-beat output bank',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi-transaction-multi-beat',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat_pipeline_cli',
        behavior     => 'dynamic_read_data_multi_transaction_multi_beat',
    },
    {
        label        => 'dynamic read-data report-only burst-length capture',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_burst_length.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-burst-length',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_burst_length',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_burst_length_pipeline_cli',
        behavior     => 'dynamic_read_data_burst_length',
    },
    {
        label        => 'dynamic read-data runtime burst-length validation',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-burst-length-runtime-assertion',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion_pipeline_cli',
        behavior     => 'dynamic_read_data_burst_length_runtime_assertion',
    },
    {
        label        => 'dynamic read-data multi-beat output bank',
        relpath      => 'ppif/axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif',
        object_id    => 'axi-manager-capacity-status-dynamic-read-data-multi-beat',
        intent_name  => 'axi_manager_capacity_status_dynamic_read_data_multi_beat',
        entry_id     => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_beat',
        coverage     => 'ial2_ppif_manager_capacity_status_dynamic_read_data_multi_beat_pipeline_cli',
        behavior     => 'dynamic_read_data_multi_beat',
    },
);

if (defined($ENV{FSMGEN_DYNAMIC_CASE_FILTER}) && length($ENV{FSMGEN_DYNAMIC_CASE_FILTER})) {
    my $filter = $ENV{FSMGEN_DYNAMIC_CASE_FILTER};
    @DYNAMIC_CASES = grep {
        ($_->{label} // '') =~ /\Q$filter\E/
            || ($_->{relpath} // '') =~ /\Q$filter\E/
            || ($_->{behavior} // '') =~ /\Q$filter\E/
    } @DYNAMIC_CASES;
    die "FSMGEN_DYNAMIC_CASE_FILTER '$filter' matched no dynamic transaction-ID cases\n"
        unless @DYNAMIC_CASES;
}

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

subtest 'dynamic same-ID reject maps to two-dynamic mixed response-demux assertions' => sub {
    my $relpath = 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif';
    my $path = repo_path($relpath);
    my $source = read_file($path);
    $source =~ s/    \(response-demux/    \(same-id-ordering\n      \(read \(dynamic-id-reuse reject\)\)\)\n    \(response-demux/
        or die "failed to insert same-id-ordering block into $relpath\n";

    my $base_result = parse_ppif($relpath);
    my $result = $adapter->parse_source($source, $path);

    is(
        $result->{generated_ial1}{text},
        $base_result->{generated_ial1}{text},
        'two-dynamic mixed same-ID reject mapping does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base_result->{generated_ial0}{files},
        'two-dynamic mixed same-ID reject mapping does not alter generated IAL0 files',
    );
    is_deeply(
        $result->{report}{response_demux}{residue},
        [qw(read_data_interleaving bursts)],
        'two-dynamic mixed same-ID reject mapping removes only same-ID response-demux residue',
    );
    assert_dynamic_same_id_reject_policy_generated_report(
        $result->{report}{same_id_ordering},
        'two-dynamic mixed read report',
        family => 'read',
        response_demux_mode => 'bounded_multi_mixed_dynamic_static_read_rid_demux_contract',
        response_demux_transaction_completion_source => 'generated_multi_mixed_dynamic_static_read_demux',
        covered_dynamic_transactions => [qw(r0 r1)],
        generated_no_active_same_id_assertions => [qw(
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
        )],
        generated_active_id_uniqueness_assertions => [qw(
            axi0_r0_r1_read_dynamic_active_id_unique
        )],
    );
};

subtest 'dynamic same-ID reject maps to one-dynamic mixed response-demux static-ID exclusion assertions' => sub {
    my $relpath = 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux.ppif';
    my $path = repo_path($relpath);
    my $source = read_file($path);
    $source =~ s/    \(response-demux/    \(same-id-ordering\n      \(read \(dynamic-id-reuse reject\)\)\)\n    \(response-demux/
        or die "failed to insert same-id-ordering block into $relpath\n";

    my $base_result = parse_ppif($relpath);
    my $result = $adapter->parse_source($source, $path);

    is(
        $result->{generated_ial1}{text},
        $base_result->{generated_ial1}{text},
        'one-dynamic mixed same-ID reject mapping does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base_result->{generated_ial0}{files},
        'one-dynamic mixed same-ID reject mapping does not alter generated IAL0 files',
    );
    is_deeply(
        $result->{report}{response_demux}{residue},
        [qw(read_data_interleaving bursts)],
        'one-dynamic mixed same-ID reject mapping removes only same-ID response-demux residue',
    );
    assert_dynamic_same_id_reject_policy_mixed_static_generated_report(
        $result->{report}{same_id_ordering},
        'one-dynamic mixed read report',
        family => 'read',
        response_demux_mode => 'bounded_mixed_dynamic_static_read_rid_demux_contract',
        response_demux_transaction_completion_source => 'generated_mixed_dynamic_static_read_demux',
        covered_dynamic_transactions => [qw(r0)],
        covered_static_transactions => [qw(r1)],
        static_id_reservations => [
            {
                transaction            => 'r1',
                concrete_id            => 3,
                concrete_id_literal    => "4'd3",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
        ],
        generated_request_availability_assertions => [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_static_request_idle_or_releasing
        )],
        generated_mixed_request_onehot_assertions => [qw(
            axi0_read_mixed_dynamic_static_request_onehot0
        )],
        generated_dynamic_request_static_id_exclusion_assertions => [qw(
            axi0_r0_dynamic_request_not_static_id
        )],
        generated_dynamic_active_static_id_exclusion_assertions => [qw(
            axi0_r0_dynamic_active_not_static_id
        )],
        generated_response_active_match_assertions => [qw(
            axi0_read_mixed_dynamic_static_response_active_match
        )],
        generated_response_unique_match_assertions => [qw(
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
        )],
        generated_completion_active_assertions => [qw(
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
        )],
    );
};

subtest 'dynamic same-ID reject maps to three-static mixed response-demux static-ID exclusion assertions' => sub {
    my $relpath = 'ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif';
    my $path = repo_path($relpath);
    my $source = read_file($path);
    $source =~ s/    \(response-demux/    \(same-id-ordering\n      \(read \(dynamic-id-reuse reject\)\)\)\n    \(response-demux/
        or die "failed to insert same-id-ordering block into $relpath\n";

    my $base_result = parse_ppif($relpath);
    my $result = $adapter->parse_source($source, $path);

    is(
        $result->{generated_ial1}{text},
        $base_result->{generated_ial1}{text},
        'three-static mixed same-ID reject mapping does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base_result->{generated_ial0}{files},
        'three-static mixed same-ID reject mapping does not alter generated IAL0 files',
    );
    is_deeply(
        $result->{report}{response_demux}{residue},
        [qw(read_data_interleaving bursts)],
        'three-static mixed same-ID reject mapping removes only same-ID response-demux residue',
    );
    assert_dynamic_same_id_reject_policy_mixed_static_generated_report(
        $result->{report}{same_id_ordering},
        'three-static mixed read RLAST report',
        family => 'read',
        response_demux_mode => 'bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract',
        response_demux_transaction_completion_source => 'generated_multi_mixed_dynamic_static_read_demux_last_beat',
        covered_dynamic_transactions => [qw(r0)],
        covered_static_transactions => [qw(r1 r2 r3)],
        static_id_reservations => [
            {
                transaction            => 'r1',
                concrete_id            => 3,
                concrete_id_literal    => "4'd3",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
            {
                transaction            => 'r2',
                concrete_id            => 5,
                concrete_id_literal    => "4'd5",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
            {
                transaction            => 'r3',
                concrete_id            => 7,
                concrete_id_literal    => "4'd7",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
        ],
        generated_request_availability_assertions => [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_static_request_idle_or_releasing
            axi0_r2_static_request_idle_or_releasing
            axi0_r3_static_request_idle_or_releasing
        )],
        generated_mixed_request_onehot_assertions => [qw(
            axi0_read_mixed_dynamic_static_request_onehot0
        )],
        generated_dynamic_request_static_id_exclusion_assertions => [qw(
            axi0_r0_r1_read_dynamic_request_not_static_id
            axi0_r0_r2_read_dynamic_request_not_static_id
            axi0_r0_r3_read_dynamic_request_not_static_id
        )],
        generated_dynamic_active_static_id_exclusion_assertions => [qw(
            axi0_r0_r1_read_dynamic_active_not_static_id
            axi0_r0_r2_read_dynamic_active_not_static_id
            axi0_r0_r3_read_dynamic_active_not_static_id
        )],
        generated_response_active_match_assertions => [qw(
            axi0_read_mixed_dynamic_static_response_active_match
        )],
        generated_response_unique_match_assertions => [qw(
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r0_r3_read_mixed_dynamic_static_response_unique_match
            axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r1_r3_read_mixed_dynamic_static_response_unique_match
            axi0_r2_r3_read_mixed_dynamic_static_response_unique_match
        )],
        generated_completion_active_assertions => [qw(
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
            axi0_r2_static_completion_active
            axi0_r3_static_completion_active
        )],
    );
};

subtest 'dynamic same-ID reject maps to single-active response-demux assertions' => sub {
    my $relpath = 'ppif/axi_manager_capacity_status_dynamic_read_response_demux.ppif';
    my $path = repo_path($relpath);
    my $source = read_file($path);
    $source =~ s/    \(response-demux/    \(same-id-ordering\n      \(read \(dynamic-id-reuse reject\)\)\)\n    \(response-demux/
        or die "failed to insert same-id-ordering block into $relpath\n";

    my $base_result = parse_ppif($relpath);
    my $result = $adapter->parse_source($source, $path);

    is(
        $result->{generated_ial1}{text},
        $base_result->{generated_ial1}{text},
        'single-active same-ID reject mapping does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base_result->{generated_ial0}{files},
        'single-active same-ID reject mapping does not alter generated IAL0 files',
    );
    is_deeply(
        $result->{report}{response_demux}{residue},
        [qw(read_data_interleaving bursts)],
        'single-active same-ID reject mapping removes only same-ID response-demux residue',
    );
    assert_dynamic_same_id_reject_policy_single_active_generated_report(
        $result->{report}{same_id_ordering},
        'single-active dynamic read report',
        family => 'read',
        response_demux_mode => 'bounded_dynamic_read_rid_demux_contract',
        response_demux_transaction_completion_source => 'generated_dynamic_demux',
        covered_dynamic_transactions => [qw(r0)],
        generated_idle_or_releasing_assertions => [qw(
            axi0_r0_dynamic_request_idle_or_releasing
        )],
        generated_response_active_match_assertions => [qw(
            axi0_read_dynamic_response_active_match
        )],
        generated_completion_active_assertions => [qw(
            axi0_r0_dynamic_completion_active
        )],
    );
};

subtest 'bounded CLI JSON checks cover dynamic PPIF support accounting' => sub {
    plan skip_all => 'FSMGEN_DYNAMIC_SKIP_CLI_JSON requested by caller'
        if $ENV{FSMGEN_DYNAMIC_SKIP_CLI_JSON};

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

    if ($case->{behavior} eq 'metadata_only'
        || $case->{behavior} eq 'dynamic_same_id_issue_order_queue_metadata') {
        is($isf, $base->{generated_ial1}{text}, "$case->{label} leaves generated IAL1 unchanged");
        is_deeply($result->{generated_ial0}{files}, $base->{generated_ial0}{files}, "$case->{label} leaves generated IAL0 unchanged");
        unlike($isf, qr/\(input axi0_awid\b/, "$case->{label} does not generate AWID input");
        unlike($isf, qr/\(input axi0_bid\b/, "$case->{label} does not generate BID input");
        unlike($isf, qr/\(input axi0_arid\b/, "$case->{label} does not generate ARID input");
        unlike($isf, qr/\(input axi0_rid\b/, "$case->{label} does not generate RID input");
        ok(!exists $result->{report}{id_response_rule_engine}, "$case->{label} emits no concrete-ID assertion engine");
        assert_dynamic_transaction_metadata($result->{report}{transactions});
        assert_dynamic_residue($result->{report}, 'metadata-only dynamic IDs stay explicitly bounded');
        assert_dynamic_same_id_issue_order_queue_metadata($result->{report}{same_id_ordering})
            if $case->{behavior} eq 'dynamic_same_id_issue_order_queue_metadata';
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
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) axi0_w0_complete\)\) axi0_w0_complete axi0_w0_dynamic_busy_q\)/, 'dynamic write demux recaptures on same-cycle release');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'dynamic write demux releases active state only without same-cycle request');
        assert_dynamic_write_report($result->{report});
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers dynamic write BID match');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled FSM lowers dynamic write release-recapture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_awid\b/, 'SystemVerilog exposes AWID');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog exposes BID');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers dynamic write response guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_write_demux_multi') {
        like($isf, qr/\(input axi0_w0_request\)/, 'multiple dynamic write demux declares w0 request input');
        like($isf, qr/\(input axi0_w1_request\)/, 'multiple dynamic write demux declares w1 request input');
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'multiple dynamic write demux declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'multiple dynamic write demux declares BID input');
        like($isf, qr/\(output axi0_w0_complete\)/, 'multiple dynamic write demux exposes w0 completion output');
        like($isf, qr/\(output axi0_w1_complete\)/, 'multiple dynamic write demux exposes w1 completion output');
        like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'multiple dynamic write demux allocates w0 selected-ID storage');
        like($isf, qr/\(var axi0_w1_dynamic_id_q \(width 4\)\)/, 'multiple dynamic write demux allocates w1 selected-ID storage');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) \(! axi0_w0_dynamic_busy_q\) \(! \(& axi0_w1_request/, 'multiple dynamic write demux gates w0 capture against sibling request');
        like($isf, qr/\(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)/, 'multiple dynamic write demux gates w0 capture against active sibling ID');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) \(! axi0_w1_dynamic_busy_q\) \(! \(& axi0_w0_request/, 'multiple dynamic write demux gates w1 capture against sibling request');
        like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'multiple dynamic write demux matches active w0 BID');
        like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'multiple dynamic write demux matches active w1 BID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w0_complete axi0_w0_dynamic_busy_q \(! \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\) \(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)\)\s+\(axi0_w0_dynamic_id_q axi0_awid\)\s+\(axi0_w0_dynamic_busy_q 1\)\)/, 'multiple dynamic write demux recaptures w0 on same-cycle release');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w1_complete axi0_w1_dynamic_busy_q \(! \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\) \(! \(& axi0_w0_dynamic_busy_q \(== axi0_w0_dynamic_id_q axi0_awid\)\)\)\)\s+\(axi0_w1_dynamic_id_q axi0_awid\)\s+\(axi0_w1_dynamic_busy_q 1\)\)/, 'multiple dynamic write demux recaptures w1 on same-cycle release');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)\s+\(axi0_w0_dynamic_busy_q 0\)\)/, 'multiple dynamic write demux releases w0 only without same-cycle own request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release \(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)\s+\(axi0_w1_dynamic_busy_q 0\)\)/, 'multiple dynamic write demux releases w1 only without same-cycle own request');
        like($isf, qr/axi0 write dynamic request is idle or releasing active captured ID/, 'multiple dynamic write demux emits idle-or-releasing assertions');
        like($isf, qr/axi0 write dynamic requests are mutually exclusive/, 'multiple dynamic write demux emits request onehot assertion');
        like($isf, qr/axi0 write dynamic active IDs are unique/, 'multiple dynamic write demux emits active ID uniqueness assertion');
        like($isf, qr/axi0 write dynamic response matches at most one captured ID/, 'multiple dynamic write demux emits response unique-match assertion');
        assert_dynamic_write_multi_report($result->{report});
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi dynamic w0 BID match');
        like($fsm, qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'scheduled FSM lowers multi dynamic w1 BID match');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled FSM lowers multi dynamic w0 release-recapture');
        like($fsm, qr/\(-axi0_w1_dynamic_id_release_recapture\s+<\(& \(& axi0_w1_request/, 'scheduled FSM lowers multi dynamic w1 release-recapture');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled FSM lowers multi dynamic w0 release-only rule');
        like($fsm, qr/\(-axi0_w1_dynamic_id_release\s+<\(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)/, 'scheduled FSM lowers multi dynamic w1 release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_awid\b/, 'SystemVerilog exposes AWID for multi dynamic write');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog exposes BID for multi dynamic write');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic w0 response guard');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w1_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w1_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic w1 response guard');
        like($hdl, qr/axi0_w0_dynamic_busy_q\s*&\s*\(axi0_w0_dynamic_id_q\s*==\s*axi0_awid\)/, 'SystemVerilog lowers active sibling-ID expression for w0');
        like($hdl, qr/axi0_w1_dynamic_busy_q\s*&\s*\(axi0_w1_dynamic_id_q\s*==\s*axi0_awid\)/, 'SystemVerilog lowers active sibling-ID expression for w1');
        return;
    }

    if ($case->{behavior} eq 'dynamic_write_same_id_issue_order_queue') {
        like($isf, qr/\(input axi0_w0_request\)/, 'dynamic write issue-order queue declares w0 request input');
        like($isf, qr/\(input axi0_w1_request\)/, 'dynamic write issue-order queue declares w1 request input');
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'dynamic write issue-order queue declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'dynamic write issue-order queue declares BID input');
        like($isf, qr/\(output axi0_w0_complete\)/, 'dynamic write issue-order queue exposes w0 completion output');
        like($isf, qr/\(output axi0_w1_complete\)/, 'dynamic write issue-order queue exposes w1 completion output');
        unlike($isf, qr/axi0_w0_dynamic_id_q/, 'dynamic write issue-order queue does not allocate legacy w0 selected-ID storage');
        unlike($isf, qr/axi0_w1_dynamic_busy_q/, 'dynamic write issue-order queue does not allocate legacy w1 busy storage');
        like($isf, qr/\(var axi0_write_dynamic_same_id_issue_order_slot0_w0_q \(width 1\)\)/, 'dynamic write issue-order queue allocates slot0 w0 bit');
        like($isf, qr/\(var axi0_write_dynamic_same_id_issue_order_slot0_id_q \(width 4\)\)/, 'dynamic write issue-order queue allocates slot0 captured AWID');
        like($isf, qr/\(var axi0_write_dynamic_same_id_issue_order_slot1_w1_q \(width 1\)\)/, 'dynamic write issue-order queue allocates slot1 w1 bit');
        like($isf, qr/\(var axi0_write_dynamic_same_id_issue_order_slot1_id_q \(width 4\)\)/, 'dynamic write issue-order queue allocates slot1 captured AWID');
        like($isf, qr/\(rule axi0_write_dynamic_same_id_issue_order_empty_enqueue_w0[\s\S]*\(axi0_write_dynamic_same_id_issue_order_slot0_id_q axi0_awid\)\)/, 'dynamic write issue-order queue captures AWID into empty slot0');
        like($isf, qr/\(rule axi0_write_dynamic_same_id_issue_order_w0_w1_dequeue_enqueue_w0[\s\S]*\(axi0_write_dynamic_same_id_issue_order_slot0_id_q axi0_write_dynamic_same_id_issue_order_slot1_id_q\)[\s\S]*\(axi0_write_dynamic_same_id_issue_order_slot1_id_q axi0_awid\)\)/, 'dynamic write issue-order queue compacts retained ID and recaptures same-cycle enqueue');
        like($isf, qr/\(rule axi0_w0_response_demux [\s\S]*axi0_write_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_write_dynamic_same_id_issue_order_slot1_id_q[\s\S]*\(pulse axi0_w0_complete\)\)/, 'dynamic write issue-order queue emits earliest matching w0 BID demux');
        like($isf, qr/\(rule axi0_w1_response_demux [\s\S]*axi0_write_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_write_dynamic_same_id_issue_order_slot1_id_q[\s\S]*\(pulse axi0_w1_complete\)\)/, 'dynamic write issue-order queue emits earliest matching w1 BID demux');
        like($isf, qr/write dynamic same-ID issue-order queue admits at most one request/, 'dynamic write issue-order queue emits enqueue onehot assertion');
        like($isf, qr/write dynamic same-ID response matches at least one captured runtime ID/, 'dynamic write issue-order queue emits no-match assertion');
        like($isf, qr/write dynamic same-ID issue-order queue completion for w0 follows selected runtime-ID match/, 'dynamic write issue-order queue emits selected-match assertion');
        assert_dynamic_write_same_id_issue_order_queue_report($result->{report});
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_write_dynamic_same_id_issue_order_slot0_id_q\b/, 'SystemVerilog declares slot0 captured AWID');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_write_dynamic_same_id_issue_order_slot1_id_q\b/, 'SystemVerilog declares slot1 captured AWID');
        like($hdl, qr/axi0_write_dynamic_same_id_issue_order_slot1_id_q_next\s*=\s*axi0_awid\s*;/, 'SystemVerilog recaptures AWID into a queue slot');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_same_id_issue_order_queue') {
        like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read issue-order queue declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'dynamic read issue-order queue declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read issue-order queue declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read issue-order queue declares RID input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read issue-order queue exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'dynamic read issue-order queue exposes r1 completion output');
        unlike($isf, qr/axi0_r0_dynamic_id_q/, 'dynamic read issue-order queue does not allocate legacy r0 selected-ID storage');
        unlike($isf, qr/axi0_r1_dynamic_busy_q/, 'dynamic read issue-order queue does not allocate legacy r1 busy storage');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'dynamic read issue-order queue allocates slot0 r0 bit');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_id_q \(width 4\)\)/, 'dynamic read issue-order queue allocates slot0 captured ARID');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_r1_q \(width 1\)\)/, 'dynamic read issue-order queue allocates slot1 r1 bit');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_id_q \(width 4\)\)/, 'dynamic read issue-order queue allocates slot1 captured ARID');
        like($isf, qr/\(rule axi0_read_dynamic_same_id_issue_order_empty_enqueue_r0[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot0_id_q axi0_arid\)\)/, 'dynamic read issue-order queue captures ARID into empty slot0');
        like($isf, qr/\(rule axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot0_id_q axi0_read_dynamic_same_id_issue_order_slot1_id_q\)[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot1_id_q axi0_arid\)\)/, 'dynamic read issue-order queue compacts retained ID and recaptures same-cycle enqueue');
        like($isf, qr/\(rule axi0_r0_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_read_dynamic_same_id_issue_order_slot1_id_q[\s\S]*\(pulse axi0_r0_complete\)\)/, 'dynamic read issue-order queue emits earliest matching r0 RID demux');
        like($isf, qr/\(rule axi0_r1_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_read_dynamic_same_id_issue_order_slot1_id_q[\s\S]*\(pulse axi0_r1_complete\)\)/, 'dynamic read issue-order queue emits earliest matching r1 RID demux');
        like($isf, qr/read dynamic same-ID issue-order queue admits at most one request/, 'dynamic read issue-order queue emits enqueue onehot assertion');
        like($isf, qr/read dynamic same-ID response matches at least one captured runtime ID/, 'dynamic read issue-order queue emits no-match assertion');
        like($isf, qr/read dynamic same-ID issue-order queue completion for r0 follows selected runtime-ID match/, 'dynamic read issue-order queue emits selected-match assertion');
        assert_dynamic_read_same_id_issue_order_queue_report($result->{report});
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_read_dynamic_same_id_issue_order_slot0_id_q\b/, 'SystemVerilog declares slot0 captured ARID');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_read_dynamic_same_id_issue_order_slot1_id_q\b/, 'SystemVerilog declares slot1 captured ARID');
        like($hdl, qr/axi0_read_dynamic_same_id_issue_order_slot1_id_q_next\s*=\s*axi0_arid\s*;/, 'SystemVerilog recaptures ARID into a queue slot');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_burst_last_same_id_issue_order_queue') {
        like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read burst-last issue-order queue declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'dynamic read burst-last issue-order queue declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read burst-last issue-order queue declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read burst-last issue-order queue declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic read burst-last issue-order queue declares RLAST input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read burst-last issue-order queue exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'dynamic read burst-last issue-order queue exposes r1 completion output');
        unlike($isf, qr/axi0_r0_dynamic_id_q/, 'dynamic read burst-last issue-order queue does not allocate legacy r0 selected-ID storage');
        unlike($isf, qr/axi0_r1_dynamic_busy_q/, 'dynamic read burst-last issue-order queue does not allocate legacy r1 busy storage');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'dynamic read burst-last issue-order queue allocates slot0 r0 bit');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_id_q \(width 4\)\)/, 'dynamic read burst-last issue-order queue allocates slot0 captured ARID');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_r1_q \(width 1\)\)/, 'dynamic read burst-last issue-order queue allocates slot1 r1 bit');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_id_q \(width 4\)\)/, 'dynamic read burst-last issue-order queue allocates slot1 captured ARID');
        like($isf, qr/\(rule axi0_read_dynamic_same_id_issue_order_empty_enqueue_r0[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot0_id_q axi0_arid\)\)/, 'dynamic read burst-last issue-order queue captures ARID into empty slot0');
        like($isf, qr/\(rule axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot0_id_q axi0_read_dynamic_same_id_issue_order_slot1_id_q\)[\s\S]*\(axi0_read_dynamic_same_id_issue_order_slot1_id_q axi0_arid\)\)/, 'dynamic read burst-last issue-order queue compacts retained ID and recaptures same-cycle enqueue');
        like($isf, qr/\(rule axi0_r0_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_rlast[\s\S]*\(pulse axi0_r0_complete\)\)/, 'dynamic read burst-last issue-order queue emits final r0 RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_read_dynamic_same_id_issue_order_slot1_id_q[\s\S]*axi0_rlast[\s\S]*\(pulse axi0_r1_complete\)\)/, 'dynamic read burst-last issue-order queue emits final r1 RID/RLAST demux');
        like($isf, qr/read dynamic same-ID issue-order queue admits at most one request/, 'dynamic read burst-last issue-order queue emits enqueue onehot assertion');
        like($isf, qr/read dynamic same-ID response matches at least one captured runtime ID/, 'dynamic read burst-last issue-order queue emits raw selected-match assertion');
        like($isf, qr/read dynamic same-ID non-last response beat does not dequeue/, 'dynamic read burst-last issue-order queue emits non-last no-dequeue assertion');
        like($isf, qr/read dynamic same-ID issue-order queue completion for r0 follows selected runtime-ID match/, 'dynamic read burst-last issue-order queue emits final selected-match assertion');
        assert_dynamic_read_burst_last_same_id_issue_order_queue_report($result->{report});
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+axi0_rlast\b/, 'SystemVerilog declares RLAST input');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_read_dynamic_same_id_issue_order_slot0_id_q\b/, 'SystemVerilog declares slot0 captured ARID');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_read_dynamic_same_id_issue_order_slot1_id_q\b/, 'SystemVerilog declares slot1 captured ARID');
        like($hdl, qr/axi0_read_dynamic_same_id_issue_order_slot1_id_q_next\s*=\s*axi0_arid\s*;/, 'SystemVerilog recaptures ARID into a queue slot');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_same_id_issue_order_queue_read_data') {
        like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read issue-order queue read-data declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'dynamic read issue-order queue read-data declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read issue-order queue read-data declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read issue-order queue read-data declares RID input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic read issue-order queue read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic read issue-order queue read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read issue-order queue read-data exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'dynamic read issue-order queue read-data exposes r1 completion output');
        like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'dynamic read issue-order queue read-data exposes r0 scalar RDATA');
        like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'dynamic read issue-order queue read-data exposes r1 scalar RDATA');
        unlike($isf, qr/axi0_r0_dynamic_id_q/, 'dynamic read issue-order queue read-data does not allocate legacy r0 selected-ID storage');
        unlike($isf, qr/axi0_r1_dynamic_busy_q/, 'dynamic read issue-order queue read-data does not allocate legacy r1 busy storage');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_id_q \(width 4\)\)/, 'dynamic read issue-order queue read-data allocates slot0 captured ARID');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_id_q \(width 4\)\)/, 'dynamic read issue-order queue read-data allocates slot1 captured ARID');
        like($isf, qr/\(rule axi0_r1_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_read_dynamic_same_id_issue_order_slot1_id_q[\s\S]*\(pulse axi0_r1_complete\)\)/, 'dynamic read issue-order queue read-data keeps queue-owned r1 RID demux');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'dynamic read issue-order queue read-data captures r0 payload under queue completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/, 'dynamic read issue-order queue read-data captures r1 payload under queue completion');
        unlike($isf, qr/\baxi0_rlast\b/, 'dynamic read issue-order queue read-data keeps RLAST absent');
        unlike($isf, qr/\baxi0_arlen\b/, 'dynamic read issue-order queue read-data keeps burst-length metadata absent');
        assert_dynamic_read_same_id_issue_order_queue_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_issue_order_queue_response_demux_completion_pulse', [qw(rlast_completion bursts multi_beat_read_data_reassembly)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers r1 queue read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes RDATA for dynamic queue read-data');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes RRESP for dynamic queue read-data');
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 queue read-data capture by completion');
        like($hdl, qr/axi0_r1_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 queue RDATA');
        like($hdl, qr/axi0_r1_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 queue RRESP');
        unlike($hdl, qr/\baxi0_arlen\b/, 'SystemVerilog keeps ARLEN absent for scalar dynamic queue read-data');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_burst_last_same_id_issue_order_queue_read_data') {
        like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read burst-last issue-order queue read-data declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'dynamic read burst-last issue-order queue read-data declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read burst-last issue-order queue read-data declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read burst-last issue-order queue read-data declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic read burst-last issue-order queue read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic read burst-last issue-order queue read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic read burst-last issue-order queue read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read burst-last issue-order queue read-data exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'dynamic read burst-last issue-order queue read-data exposes r1 completion output');
        like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'dynamic read burst-last issue-order queue read-data exposes r0 scalar last RDATA');
        like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'dynamic read burst-last issue-order queue read-data exposes r1 scalar last RDATA');
        unlike($isf, qr/axi0_r0_dynamic_id_q/, 'dynamic read burst-last issue-order queue read-data does not allocate legacy r0 selected-ID storage');
        unlike($isf, qr/axi0_r1_dynamic_busy_q/, 'dynamic read burst-last issue-order queue read-data does not allocate legacy r1 busy storage');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot0_id_q \(width 4\)\)/, 'dynamic read burst-last issue-order queue read-data allocates slot0 captured ARID');
        like($isf, qr/\(var axi0_read_dynamic_same_id_issue_order_slot1_id_q \(width 4\)\)/, 'dynamic read burst-last issue-order queue read-data allocates slot1 captured ARID');
        like($isf, qr/\(rule axi0_r1_response_demux [\s\S]*axi0_read_dynamic_same_id_issue_order_slot0_id_q[\s\S]*axi0_read_dynamic_same_id_issue_order_slot1_id_q[\s\S]*axi0_rlast[\s\S]*\(pulse axi0_r1_complete\)\)/, 'dynamic read burst-last issue-order queue read-data keeps queue-owned r1 RID/RLAST demux');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'dynamic read burst-last issue-order queue read-data captures r0 payload under queue completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'dynamic read burst-last issue-order queue read-data captures r1 payload under queue completion');
        unlike($isf, qr/\baxi0_arlen\b/, 'dynamic read burst-last issue-order queue read-data keeps burst-length metadata absent');
        assert_dynamic_read_burst_last_same_id_issue_order_queue_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse', [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers r1 queue last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for dynamic queue last-beat read-data');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes RDATA for dynamic queue last-beat read-data');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes RRESP for dynamic queue last-beat read-data');
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 queue last-beat read-data capture by completion');
        like($hdl, qr/axi0_r1_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 queue last-beat RDATA');
        like($hdl, qr/axi0_r1_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 queue last-beat RRESP');
        unlike($hdl, qr/\baxi0_arlen\b/, 'SystemVerilog keeps ARLEN absent for scalar last-beat dynamic queue read-data');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_write_demux') {
        like($isf, qr/\(input axi0_w0_request\)/, 'mixed write demux declares dynamic request input');
        like($isf, qr/\(input axi0_w1_request\)/, 'mixed write demux declares static request input');
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'mixed write demux declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'mixed write demux declares BID input');
        like($isf, qr/\(output axi0_w0_complete\)/, 'mixed write demux exposes dynamic completion output');
        like($isf, qr/\(output axi0_w1_complete\)/, 'mixed write demux exposes static completion output');
        like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'mixed write demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'mixed write demux allocates dynamic busy storage');
        like($isf, qr/\(var axi0_w1_static_busy_q \(width 1\)\)/, 'mixed write demux allocates static busy storage');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture\b/, 'mixed write demux emits dynamic ID capture rule');
        like($isf, qr/\(! \(& axi0_w1_request/, 'mixed write demux prevents dynamic capture during static request');
        like($isf, qr/\(! \(== axi0_awid 4'd3\)\)/, 'mixed write demux prevents dynamic capture of the static concrete ID');
        like($isf, qr/\(axi0_w0_dynamic_id_q axi0_awid\)/, 'mixed write demux captures dynamic AWID');
        like($isf, qr/\(rule axi0_w1_static_busy_capture \(& \(& axi0_w1_request/, 'mixed write demux captures admitted static request busy state');
        like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'mixed write demux matches dynamic active BID');
        like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_static_busy_q \(== axi0_bid 4'd3\)\)/, 'mixed write demux matches static concrete BID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w0_complete axi0_w0_dynamic_busy_q \(! \(& axi0_w1_request/, 'mixed write demux recaptures dynamic ID on same-cycle dynamic completion');
        like($isf, qr/\(! \(== axi0_awid 4'd3\)\)\)/, 'mixed write demux keeps static-ID exclusion on dynamic recapture');
        like($isf, qr/\(rule axi0_w1_static_busy_release_recapture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w1_complete axi0_w1_static_busy_q \(! \(& axi0_w0_request/, 'mixed write demux recaptures static busy on same-cycle static completion');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'mixed write demux releases dynamic busy only without same-cycle dynamic request');
        like($isf, qr/\(rule axi0_w1_static_busy_release \(& axi0_w1_complete axi0_w1_static_busy_q \(! axi0_w1_request\)\)/, 'mixed write demux releases static busy only without same-cycle static request');
        like($isf, qr/axi0 write dynamic request is idle or releasing active captured ID/, 'mixed write demux emits dynamic idle-or-releasing assertion');
        like($isf, qr/axi0 write static request is idle or releasing active concrete ID/, 'mixed write demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 write mixed dynamic\/static requests are mutually exclusive/, 'mixed write demux emits request onehot assertion');
        like($isf, qr/axi0 w0 dynamic request does not use static concrete ID/, 'mixed write demux emits dynamic request static-ID reservation assertion');
        like($isf, qr/axi0 write mixed dynamic\/static response matches at most one transaction/, 'mixed write demux emits response unique-match assertion');
        assert_mixed_dynamic_static_write_report($result->{report});
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers mixed dynamic BID match');
        like($fsm, qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_static_busy_q \(== axi0_bid 4'd3\)\)/, 'scheduled FSM lowers mixed static BID match');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled FSM lowers mixed dynamic release-recapture');
        like($fsm, qr/\(-axi0_w1_static_busy_release_recapture\s+<\(& \(& axi0_w1_request/, 'scheduled FSM lowers mixed static release-recapture');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled FSM lowers mixed dynamic release-only rule');
        like($fsm, qr/\(-axi0_w1_static_busy_release\s+<\(& axi0_w1_complete axi0_w1_static_busy_q \(! axi0_w1_request\)\)/, 'scheduled FSM lowers mixed static release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_dynamic_id_q\b/, 'SystemVerilog declares mixed dynamic selected-ID state');
        like($hdl, qr/\breg\s+axi0_w1_static_busy_q\b/, 'SystemVerilog declares mixed static busy state');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers mixed dynamic response guard');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w1_static_busy_q\s*&\s*\(axi0_bid\s*==\s*4'd3\)/, 'SystemVerilog lowers mixed static response guard');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_dynamic') {
        like($isf, qr/\(input axi0_w0_request\)/, 'multi-dynamic mixed write demux declares first dynamic request input');
        like($isf, qr/\(input axi0_w1_request\)/, 'multi-dynamic mixed write demux declares second dynamic request input');
        like($isf, qr/\(input axi0_w2_request\)/, 'multi-dynamic mixed write demux declares static request input');
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'multi-dynamic mixed write demux declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'multi-dynamic mixed write demux declares BID input');
        like($isf, qr/\(output axi0_w0_complete\)/, 'multi-dynamic mixed write demux exposes first dynamic completion output');
        like($isf, qr/\(output axi0_w1_complete\)/, 'multi-dynamic mixed write demux exposes second dynamic completion output');
        like($isf, qr/\(output axi0_w2_complete\)/, 'multi-dynamic mixed write demux exposes static completion output');
        like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed write demux allocates first dynamic selected-ID storage');
        like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed write demux allocates first dynamic busy storage');
        like($isf, qr/\(var axi0_w1_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed write demux allocates second dynamic selected-ID storage');
        like($isf, qr/\(var axi0_w1_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed write demux allocates second dynamic busy storage');
        like($isf, qr/\(var axi0_w2_static_busy_q \(width 1\)\)/, 'multi-dynamic mixed write demux allocates static busy storage');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture\b/, 'multi-dynamic mixed write demux emits first dynamic ID capture rule');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture\b/, 'multi-dynamic mixed write demux emits second dynamic ID capture rule');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture[\s\S]*\(! \(& axi0_w1_request/, 'multi-dynamic mixed write demux blocks first dynamic capture during second dynamic request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture[\s\S]*\(! \(& axi0_w0_request/, 'multi-dynamic mixed write demux blocks second dynamic capture during first dynamic request');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture[\s\S]*\(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)/, 'multi-dynamic mixed write demux blocks first dynamic capture of active second dynamic ID');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture[\s\S]*\(! \(& axi0_w0_dynamic_busy_q \(== axi0_w0_dynamic_id_q axi0_awid\)\)\)/, 'multi-dynamic mixed write demux blocks second dynamic capture of active first dynamic ID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture[\s\S]*\(! \(& axi0_w2_request/, 'multi-dynamic mixed write demux blocks first dynamic capture during static request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture[\s\S]*\(! \(& axi0_w2_request/, 'multi-dynamic mixed write demux blocks second dynamic capture during static request');
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture[\s\S]*\(! \(== axi0_awid 4'd3\)\)/, 'multi-dynamic mixed write demux blocks first dynamic capture of static ID');
        like($isf, qr/\(rule axi0_w1_dynamic_id_capture[\s\S]*\(! \(== axi0_awid 4'd3\)\)/, 'multi-dynamic mixed write demux blocks second dynamic capture of static ID');
        like($isf, qr/\(axi0_w0_dynamic_id_q axi0_awid\)/, 'multi-dynamic mixed write demux captures first dynamic AWID');
        like($isf, qr/\(axi0_w1_dynamic_id_q axi0_awid\)/, 'multi-dynamic mixed write demux captures second dynamic AWID');
        like($isf, qr/\(rule axi0_w2_static_busy_capture \(& \(& axi0_w2_request/, 'multi-dynamic mixed write demux captures admitted static request busy state');
        like($isf, qr/\(rule axi0_w2_static_busy_capture[\s\S]*\(! \(& axi0_w0_request/, 'multi-dynamic mixed write demux blocks static capture during first dynamic request');
        like($isf, qr/\(rule axi0_w2_static_busy_capture[\s\S]*\(! \(& axi0_w1_request/, 'multi-dynamic mixed write demux blocks static capture during second dynamic request');
        like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'multi-dynamic mixed write demux matches first dynamic active BID');
        like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'multi-dynamic mixed write demux matches second dynamic active BID');
        like($isf, qr/\(rule axi0_w2_response_demux \(& axi0_write_complete axi0_w2_static_busy_q \(== axi0_bid 4'd3\)\)/, 'multi-dynamic mixed write demux matches static concrete BID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture\b/, 'multi-dynamic mixed write demux emits first dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture\b/, 'multi-dynamic mixed write demux emits second dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_w2_static_busy_release_recapture\b/, 'multi-dynamic mixed write demux emits static release-recapture rule');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w1_request/, 'multi-dynamic mixed write demux blocks first dynamic recapture during second dynamic request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w0_request/, 'multi-dynamic mixed write demux blocks second dynamic recapture during first dynamic request');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)/, 'multi-dynamic mixed write demux blocks first dynamic recapture of active second dynamic ID');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w0_dynamic_busy_q \(== axi0_w0_dynamic_id_q axi0_awid\)\)\)/, 'multi-dynamic mixed write demux blocks second dynamic recapture of active first dynamic ID');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w2_request/, 'multi-dynamic mixed write demux blocks first dynamic recapture during static request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_w2_request/, 'multi-dynamic mixed write demux blocks second dynamic recapture during static request');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_awid 4'd3\)\)/, 'multi-dynamic mixed write demux blocks first dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_awid 4'd3\)\)/, 'multi-dynamic mixed write demux blocks second dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_w2_static_busy_release_recapture[\s\S]*\(! \(& axi0_w0_request/, 'multi-dynamic mixed write demux blocks static recapture during first dynamic request');
        like($isf, qr/\(rule axi0_w2_static_busy_release_recapture[\s\S]*\(! \(& axi0_w1_request/, 'multi-dynamic mixed write demux blocks static recapture during second dynamic request');
        like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'multi-dynamic mixed write demux releases first dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_w1_dynamic_id_release \(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)/, 'multi-dynamic mixed write demux releases second dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_w2_static_busy_release \(& axi0_w2_complete axi0_w2_static_busy_q \(! axi0_w2_request\)\)/, 'multi-dynamic mixed write demux releases static only without same-cycle request');
        like($isf, qr/axi0 write dynamic request is idle or releasing active captured ID/, 'multi-dynamic mixed write demux emits dynamic idle-or-releasing assertions');
        like($isf, qr/axi0 write static request is idle or releasing active concrete ID/, 'multi-dynamic mixed write demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 write mixed dynamic\/static requests are mutually exclusive/, 'multi-dynamic mixed write demux emits mixed request onehot assertion');
        like($isf, qr/axi0 w0 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed write demux emits first no-active-same-ID assertion');
        like($isf, qr/axi0 w1 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed write demux emits second no-active-same-ID assertion');
        like($isf, qr/axi0 write dynamic active IDs are unique/, 'multi-dynamic mixed write demux emits active dynamic ID uniqueness assertion');
        like($isf, qr/axi0 w0 dynamic request does not use static concrete ID/, 'multi-dynamic mixed write demux emits first dynamic static-ID request assertion');
        like($isf, qr/axi0 w1 dynamic request does not use static concrete ID/, 'multi-dynamic mixed write demux emits second dynamic static-ID request assertion');
        like($isf, qr/axi0 write mixed dynamic\/static response matches at most one transaction/, 'multi-dynamic mixed write demux emits response unique-match assertions');
        assert_mixed_dynamic_static_write_multi_dynamic_report($result->{report});
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-dynamic mixed first dynamic BID match');
        like($fsm, qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-dynamic mixed second dynamic BID match');
        like($fsm, qr/\(-axi0_w2_response_demux\s+<\(& axi0_write_complete axi0_w2_static_busy_q \(== axi0_bid 4'd3\)\)/, 'scheduled FSM lowers multi-dynamic mixed static BID match');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled FSM lowers first multi-dynamic mixed dynamic release-recapture');
        like($fsm, qr/\(-axi0_w1_dynamic_id_release_recapture\s+<\(& \(& axi0_w1_request/, 'scheduled FSM lowers second multi-dynamic mixed dynamic release-recapture');
        like($fsm, qr/\(-axi0_w2_static_busy_release_recapture\s+<\(& \(& axi0_w2_request/, 'scheduled FSM lowers multi-dynamic mixed static release-recapture');
        like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled FSM lowers first multi-dynamic mixed dynamic release-only rule');
        like($fsm, qr/\(-axi0_w1_dynamic_id_release\s+<\(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)/, 'scheduled FSM lowers second multi-dynamic mixed dynamic release-only rule');
        like($fsm, qr/\(-axi0_w2_static_busy_release\s+<\(& axi0_w2_complete axi0_w2_static_busy_q \(! axi0_w2_request\)\)/, 'scheduled FSM lowers multi-dynamic mixed static release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_dynamic_id_q\b/, 'SystemVerilog declares first multi-dynamic mixed selected-ID state');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w1_dynamic_id_q\b/, 'SystemVerilog declares second multi-dynamic mixed selected-ID state');
        like($hdl, qr/\breg\s+axi0_w2_static_busy_q\b/, 'SystemVerilog declares multi-dynamic mixed static busy state');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers multi-dynamic mixed first dynamic response guard');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w1_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w1_dynamic_id_q\)/, 'SystemVerilog lowers multi-dynamic mixed second dynamic response guard');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w2_static_busy_q\s*&\s*\(axi0_bid\s*==\s*4'd3\)/, 'SystemVerilog lowers multi-dynamic mixed static response guard');
        like($hdl, qr/axi0_w0_dynamic_busy_q\s*&\s*\(axi0_w0_dynamic_id_q\s*==\s*axi0_awid\)/, 'SystemVerilog lowers first dynamic active sibling-ID expression');
        like($hdl, qr/axi0_w1_dynamic_busy_q\s*&\s*\(axi0_w1_dynamic_id_q\s*==\s*axi0_awid\)/, 'SystemVerilog lowers second dynamic active sibling-ID expression');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_static'
        || $case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_static3') {
        my @static_cases = (
            { transaction => 'w1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'w2', value => 5, literal => "4'd5", label => 'second' },
            (
                $case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_static3'
                    ? ({ transaction => 'w3', value => 7, literal => "4'd7", label => 'third' })
                    : ()
            ),
        );
        my $release_recapture_expected =
            $case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_static'
            || $case->{behavior} eq 'mixed_dynamic_static_write_demux_multi_static3';
        my $pending_limit = 1 + @static_cases;
        my $completion_terms = quotemeta(
            join ' ',
            map { "axi0_${_}_complete" } ('w0', map { $_->{transaction} } @static_cases),
        );
        like($isf, qr/\(input axi0_w0_request\)/, 'multi-static mixed write demux declares dynamic request input');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(input axi0_${transaction}_request\)/, "multi-static mixed write demux declares $label static request input");
        }
        like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'multi-static mixed write demux declares AWID input');
        like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'multi-static mixed write demux declares BID input');
        like($isf, qr/\(output axi0_w0_complete\)/, 'multi-static mixed write demux exposes dynamic completion output');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(output axi0_${transaction}_complete\)/, "multi-static mixed write demux exposes $label static completion output");
        }
        like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'multi-static mixed write demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'multi-static mixed write demux allocates dynamic busy storage');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(var axi0_${transaction}_static_busy_q \(width 1\)\)/, "multi-static mixed write demux allocates $label static busy storage");
        }
        like($isf, qr/\(rule axi0_w0_dynamic_id_capture\b/, 'multi-static mixed write demux emits dynamic ID capture rule');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(! \(& axi0_${transaction}_request/, "multi-static mixed write demux prevents dynamic capture during $label static request");
            like($isf, qr/\(! \(== axi0_awid $literal\)\)/, "multi-static mixed write demux prevents dynamic capture of $label static concrete ID");
        }
        like($isf, qr/\(axi0_w0_dynamic_id_q axi0_awid\)/, 'multi-static mixed write demux captures dynamic AWID');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(rule axi0_${transaction}_static_busy_capture \(& \(& axi0_${transaction}_request/, "multi-static mixed write demux captures $label admitted static request busy state");
            for my $sibling (grep { $_->{transaction} ne $static_case->{transaction} } @static_cases) {
                my $sibling_transaction = $sibling->{transaction};
                my $sibling_label = $sibling->{label};
                like($isf, qr/\(rule axi0_${transaction}_static_busy_capture[\s\S]*\(! \(& axi0_${sibling_transaction}_request/, "multi-static mixed write demux blocks $label static capture during $sibling_label static request");
            }
        }
        like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'multi-static mixed write demux matches dynamic active BID');
        if ($release_recapture_expected) {
            like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'multi-static mixed write demux dynamic release-only excludes same-cycle dynamic request');
        } else {
            like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q\)/, 'multi-static mixed write demux releases dynamic busy state');
        }
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_write_complete axi0_${transaction}_static_busy_q \(== axi0_bid $literal\)\)/, "multi-static mixed write demux matches $label static concrete BID");
            if ($release_recapture_expected) {
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release \(& axi0_${transaction}_complete axi0_${transaction}_static_busy_q \(! axi0_${transaction}_request\)\)/, "multi-static mixed write demux $label static release-only excludes same-cycle static request");
            } else {
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release \(& axi0_${transaction}_complete axi0_${transaction}_static_busy_q\)/, "multi-static mixed write demux releases $label static busy state");
            }
        }
        if ($release_recapture_expected) {
            like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q $pending_limit\) \(\| $completion_terms\)\)\) axi0_w0_complete axi0_w0_dynamic_busy_q/, 'multi-static mixed write demux recaptures dynamic ID on same-cycle dynamic completion');
            for my $static_case (@static_cases) {
                my $transaction = $static_case->{transaction};
                my $label = $static_case->{label};
                my $literal = quotemeta($static_case->{literal});
                like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_${transaction}_request/, "multi-static mixed write demux dynamic recapture blocks $label static request");
                like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_awid $literal\)\)/, "multi-static mixed write demux dynamic recapture excludes $label static ID");
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture \(& \(& axi0_${transaction}_request \(\| \(< axi0_pending_writes_q $pending_limit\) \(\| $completion_terms\)\)\) axi0_${transaction}_complete axi0_${transaction}_static_busy_q/, "multi-static mixed write demux recaptures $label static busy on same-cycle static completion");
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture[\s\S]*\(! \(& axi0_w0_request/, "multi-static mixed write demux $label static recapture blocks dynamic request");
                for my $sibling (grep { $_->{transaction} ne $transaction } @static_cases) {
                    my $sibling_transaction = $sibling->{transaction};
                    my $sibling_label = $sibling->{label};
                    like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture[\s\S]*\(! \(& axi0_${sibling_transaction}_request/, "multi-static mixed write demux $label static recapture blocks $sibling_label static request");
                }
            }
        }
        like($isf, qr/axi0 write mixed dynamic\/static requests are mutually exclusive/, 'multi-static mixed write demux emits request onehot assertion');
        if ($release_recapture_expected) {
            like($isf, qr/axi0 write dynamic request is idle or releasing active captured ID/, 'multi-static mixed write demux emits dynamic idle-or-releasing assertion');
            like($isf, qr/axi0 write static request is idle or releasing active concrete ID/, 'multi-static mixed write demux emits static idle-or-releasing assertions');
        }
        like($isf, qr/axi0 w0 dynamic request does not use static concrete ID/, 'multi-static mixed write demux emits dynamic request static-ID reservation assertions');
        like($isf, qr/axi0 write mixed dynamic\/static response matches at most one transaction/, 'multi-static mixed write demux emits response unique-match assertions');
        my $last_static_transaction = $static_cases[-1]{transaction};
        like($isf, qr/axi0 $last_static_transaction static completion releases active concrete ID/, 'multi-static mixed write demux emits last static completion-active assertion');
        assert_mixed_dynamic_static_write_multi_static_report($result->{report}, \@static_cases);
        like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-static mixed dynamic BID match');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($fsm, qr/\(-axi0_${transaction}_response_demux\s+<\(& axi0_write_complete axi0_${transaction}_static_busy_q \(== axi0_bid $literal\)\)/, "scheduled FSM lowers multi-static mixed $label static BID match");
            like($fsm, qr/\(-axi0_w0_dynamic_id_capture[\s\S]*\(! \(== axi0_awid $literal\)\)/, "scheduled FSM lowers dynamic capture exclusion for $label static ID");
        }
        if ($release_recapture_expected) {
            like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled FSM lowers multi-static mixed dynamic release-recapture');
            for my $static_case (@static_cases) {
                my $transaction = $static_case->{transaction};
                my $label = $static_case->{label};
                like($fsm, qr/\(-axi0_${transaction}_static_busy_release_recapture\s+<\(& \(& axi0_${transaction}_request/, "scheduled FSM lowers multi-static mixed $label static release-recapture");
            }
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_dynamic_id_q\b/, 'SystemVerilog declares multi-static mixed dynamic selected-ID state');
        like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers multi-static mixed dynamic response guard');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($hdl, qr/\breg\s+axi0_${transaction}_static_busy_q\b/, "SystemVerilog declares $label mixed static busy state");
            like($hdl, qr/axi0_write_complete\s*&\s*axi0_${transaction}_static_busy_q\s*&\s*\(axi0_bid\s*==\s*$literal\)/, "SystemVerilog lowers multi-static mixed $label static response guard");
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_demux') {
        like($isf, qr/\(input axi0_r0_request\)/, 'mixed read demux declares dynamic request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'mixed read demux declares static request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'mixed read demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'mixed read demux declares RID input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'mixed read demux exposes dynamic completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'mixed read demux exposes static completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'mixed read demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'mixed read demux allocates dynamic busy storage');
        like($isf, qr/\(var axi0_r1_static_busy_q \(width 1\)\)/, 'mixed read demux allocates static busy storage');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture\b/, 'mixed read demux emits dynamic ID capture rule');
        like($isf, qr/\(! \(& axi0_r1_request/, 'mixed read demux prevents dynamic capture during static request');
        like($isf, qr/\(! \(== axi0_arid 4'd3\)\)/, 'mixed read demux prevents dynamic capture of the static concrete ID');
        like($isf, qr/\(axi0_r0_dynamic_id_q axi0_arid\)/, 'mixed read demux captures dynamic ARID');
        like($isf, qr/\(rule axi0_r1_static_busy_capture \(& \(& axi0_r1_request/, 'mixed read demux captures admitted static request busy state');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'mixed read demux matches dynamic active RID');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)/, 'mixed read demux matches static concrete RID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'mixed read demux dynamic release-only excludes same-cycle dynamic request');
        like($isf, qr/\(rule axi0_r1_static_busy_release \(& axi0_r1_complete axi0_r1_static_busy_q \(! axi0_r1_request\)\)/, 'mixed read demux static release-only excludes same-cycle static request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request/, 'mixed read demux recaptures dynamic ID on same-cycle dynamic completion');
        like($isf, qr/\(rule axi0_r1_static_busy_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_static_busy_q \(! \(& axi0_r0_request/, 'mixed read demux recaptures static busy on same-cycle static completion');
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'mixed read demux emits request onehot assertion');
        like($isf, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'mixed read demux emits dynamic idle-or-releasing assertion');
        like($isf, qr/axi0 read static request is idle or releasing active concrete ID/, 'mixed read demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 r0 dynamic request does not use static concrete ID/, 'mixed read demux emits dynamic request static-ID reservation assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'mixed read demux emits response unique-match assertion');
        assert_mixed_dynamic_static_read_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers mixed dynamic RID match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)/, 'scheduled FSM lowers mixed static RID match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers mixed dynamic read release-recapture');
        like($fsm, qr/\(-axi0_r1_static_busy_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers mixed static read release-recapture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares mixed read dynamic selected-ID state');
        like($hdl, qr/\breg\s+axi0_r1_static_busy_q\b/, 'SystemVerilog declares mixed read static busy state');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers mixed dynamic read response guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)/, 'SystemVerilog lowers mixed static read response guard');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_demux_multi_dynamic') {
        like($isf, qr/\(input axi0_r0_request\)/, 'multi-dynamic mixed read demux declares first dynamic request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'multi-dynamic mixed read demux declares second dynamic request input');
        like($isf, qr/\(input axi0_r2_request\)/, 'multi-dynamic mixed read demux declares static request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-dynamic mixed read demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-dynamic mixed read demux declares RID input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multi-dynamic mixed read demux exposes first dynamic completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'multi-dynamic mixed read demux exposes second dynamic completion output');
        like($isf, qr/\(output axi0_r2_complete\)/, 'multi-dynamic mixed read demux exposes static completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read demux allocates first dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed read demux allocates first dynamic busy storage');
        like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read demux allocates second dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r1_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed read demux allocates second dynamic busy storage');
        like($isf, qr/\(var axi0_r2_static_busy_q \(width 1\)\)/, 'multi-dynamic mixed read demux allocates static busy storage');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture\b/, 'multi-dynamic mixed read demux emits first dynamic ID capture rule');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture\b/, 'multi-dynamic mixed read demux emits second dynamic ID capture rule');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read demux blocks first dynamic capture during second dynamic request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read demux blocks second dynamic capture during first dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read demux blocks first dynamic capture of active second dynamic ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read demux blocks second dynamic capture of active first dynamic ID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read demux blocks first dynamic capture during static request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read demux blocks second dynamic capture during static request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read demux blocks first dynamic capture of static ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read demux blocks second dynamic capture of static ID');
        like($isf, qr/\(axi0_r0_dynamic_id_q axi0_arid\)/, 'multi-dynamic mixed read demux captures first dynamic ARID');
        like($isf, qr/\(axi0_r1_dynamic_id_q axi0_arid\)/, 'multi-dynamic mixed read demux captures second dynamic ARID');
        like($isf, qr/\(rule axi0_r2_static_busy_capture \(& \(& axi0_r2_request/, 'multi-dynamic mixed read demux captures admitted static request busy state');
        like($isf, qr/\(rule axi0_r2_static_busy_capture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read demux blocks static capture during first dynamic request');
        like($isf, qr/\(rule axi0_r2_static_busy_capture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read demux blocks static capture during second dynamic request');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multi-dynamic mixed read demux matches first dynamic active RID');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multi-dynamic mixed read demux matches second dynamic active RID');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)/, 'multi-dynamic mixed read demux matches static concrete RID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture\b/, 'multi-dynamic mixed read demux emits first dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture\b/, 'multi-dynamic mixed read demux emits second dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture\b/, 'multi-dynamic mixed read demux emits static release-recapture rule');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read demux blocks first dynamic recapture during second dynamic request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read demux blocks second dynamic recapture during first dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read demux blocks first dynamic recapture of active second dynamic ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read demux blocks second dynamic recapture of active first dynamic ID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read demux blocks first dynamic recapture during static request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read demux blocks second dynamic recapture during static request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read demux blocks first dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read demux blocks second dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read demux blocks static recapture during first dynamic request');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read demux blocks static recapture during second dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'multi-dynamic mixed read demux releases first dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'multi-dynamic mixed read demux releases second dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_r2_static_busy_release \(& axi0_r2_complete axi0_r2_static_busy_q \(! axi0_r2_request\)\)/, 'multi-dynamic mixed read demux releases static only without same-cycle request');
        like($isf, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'multi-dynamic mixed read demux emits dynamic idle-or-releasing assertions');
        like($isf, qr/axi0 read static request is idle or releasing active concrete ID/, 'multi-dynamic mixed read demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'multi-dynamic mixed read demux emits mixed request onehot assertion');
        like($isf, qr/axi0 r0 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed read demux emits first no-active-same-ID assertion');
        like($isf, qr/axi0 r1 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed read demux emits second no-active-same-ID assertion');
        like($isf, qr/axi0 read dynamic active IDs are unique/, 'multi-dynamic mixed read demux emits active dynamic ID uniqueness assertion');
        like($isf, qr/axi0 r0 dynamic request does not use static concrete ID/, 'multi-dynamic mixed read demux emits first dynamic static-ID request assertion');
        like($isf, qr/axi0 r1 dynamic request does not use static concrete ID/, 'multi-dynamic mixed read demux emits second dynamic static-ID request assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-dynamic mixed read demux emits response unique-match assertions');
        assert_mixed_dynamic_static_read_multi_dynamic_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-dynamic mixed first dynamic RID match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-dynamic mixed second dynamic RID match');
        like($fsm, qr/\(-axi0_r2_response_demux\s+<\(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)/, 'scheduled FSM lowers multi-dynamic mixed static RID match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers first multi-dynamic mixed dynamic read release-recapture');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers second multi-dynamic mixed dynamic read release-recapture');
        like($fsm, qr/\(-axi0_r2_static_busy_release_recapture\s+<\(& \(& axi0_r2_request/, 'scheduled FSM lowers multi-dynamic mixed static read release-recapture');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled FSM lowers first multi-dynamic mixed dynamic read release-only rule');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release\s+<\(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'scheduled FSM lowers second multi-dynamic mixed dynamic read release-only rule');
        like($fsm, qr/\(-axi0_r2_static_busy_release\s+<\(& axi0_r2_complete axi0_r2_static_busy_q \(! axi0_r2_request\)\)/, 'scheduled FSM lowers multi-dynamic mixed static read release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares first multi-dynamic mixed read selected-ID state');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r1_dynamic_id_q\b/, 'SystemVerilog declares second multi-dynamic mixed read selected-ID state');
        like($hdl, qr/\breg\s+axi0_r2_static_busy_q\b/, 'SystemVerilog declares multi-dynamic mixed read static busy state');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers multi-dynamic mixed first dynamic read response guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)/, 'SystemVerilog lowers multi-dynamic mixed second dynamic read response guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r2_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)/, 'SystemVerilog lowers multi-dynamic mixed static read response guard');
        like($hdl, qr/axi0_r0_dynamic_busy_q\s*&\s*\(axi0_r0_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers first dynamic read active sibling-ID expression');
        like($hdl, qr/axi0_r1_dynamic_busy_q\s*&\s*\(axi0_r1_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers second dynamic read active sibling-ID expression');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic') {
        for my $tx (qw(r0 r1 r2)) {
            like($isf, qr/\(input axi0_${tx}_request\)/, "multi-dynamic mixed read-data declares $tx request input");
            like($isf, qr/\(output axi0_${tx}_complete\)/, "multi-dynamic mixed read-data exposes $tx completion output");
            like($isf, qr/\(output axi0_${tx}_rdata \(width 32\)\)/, "multi-dynamic mixed read-data declares $tx scalar data output");
            like($isf, qr/\(output axi0_${tx}_rresp \(width 2\)\)/, "multi-dynamic mixed read-data declares $tx scalar status output");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_rdata axi0_rdata\)\s+\(axi0_${tx}_rresp axi0_rresp\)\)/, "multi-dynamic mixed read-data captures $tx payload under generated completion");
        }
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-dynamic mixed read-data declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-dynamic mixed read-data declares RID input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-dynamic mixed read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-dynamic mixed read-data declares RRESP input');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read-data allocates first dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read-data allocates second dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r2_static_busy_q \(width 1\)\)/, 'multi-dynamic mixed read-data allocates static busy storage');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multi-dynamic mixed read-data keeps first dynamic RID demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multi-dynamic mixed read-data keeps second dynamic RID demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)/, 'multi-dynamic mixed read-data keeps static RID demux');
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'multi-dynamic mixed read-data keeps mixed request onehot assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-dynamic mixed read-data keeps response unique-match assertions');
        unlike($isf, qr/\baxi0_rlast\b/, 'multi-dynamic mixed read-data keeps RLAST absent');
        unlike($isf, qr/\baxi0_arlen\b/, 'multi-dynamic mixed read-data keeps burst-length metadata absent');
        assert_mixed_dynamic_static_read_multi_dynamic_report($result->{report});
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse',
            [qw(rlast_completion bursts multi_beat_read_data_reassembly)],
            [qw(r0 r1 r2)],
        );
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers second dynamic read-data capture');
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers static read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes RDATA for multi-dynamic mixed read-data');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes RRESP for multi-dynamic mixed read-data');
        unlike($hdl, qr/\baxi0_rlast\b/, 'SystemVerilog keeps RLAST absent for single-beat read-data');
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards second dynamic read-data capture by completion');
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog guards static read-data capture by completion');
        like($hdl, qr/axi0_r1_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures second dynamic RDATA');
        like($hdl, qr/axi0_r1_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures second dynamic RRESP');
        like($hdl, qr/axi0_r2_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures static RDATA');
        like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures static RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_demux_multi_static'
        || $case->{behavior} eq 'mixed_dynamic_static_read_demux_multi_static3') {
        my @static_cases = (
            { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            (
                $case->{behavior} eq 'mixed_dynamic_static_read_demux_multi_static3'
                    ? ({ transaction => 'r3', value => 7, literal => "4'd7", label => 'third' })
                    : ()
            ),
        );
        like($isf, qr/\(input axi0_r0_request\)/, 'multi-static mixed read demux declares dynamic request input');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(input axi0_${transaction}_request\)/, "multi-static mixed read demux declares $label static request input");
        }
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-static mixed read demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-static mixed read demux declares RID input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multi-static mixed read demux exposes dynamic completion output');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(output axi0_${transaction}_complete\)/, "multi-static mixed read demux exposes $label static completion output");
        }
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-static mixed read demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'multi-static mixed read demux allocates dynamic busy storage');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(var axi0_${transaction}_static_busy_q \(width 1\)\)/, "multi-static mixed read demux allocates $label static busy storage");
        }
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture\b/, 'multi-static mixed read demux emits dynamic ID capture rule');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(! \(& axi0_${transaction}_request/, "multi-static mixed read demux prevents dynamic capture during $label static request");
            like($isf, qr/\(! \(== axi0_arid $literal\)\)/, "multi-static mixed read demux prevents dynamic capture of $label static concrete ID");
        }
        like($isf, qr/\(axi0_r0_dynamic_id_q axi0_arid\)/, 'multi-static mixed read demux captures dynamic ARID');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(rule axi0_${transaction}_static_busy_capture \(& \(& axi0_${transaction}_request/, "multi-static mixed read demux captures $label admitted static request busy state");
            like($isf, qr/\(rule axi0_${transaction}_static_busy_capture[\s\S]*\(! \(& axi0_r0_request/, "multi-static mixed read demux blocks $label static capture during dynamic request");
            for my $sibling (grep { $_->{transaction} ne $static_case->{transaction} } @static_cases) {
                my $sibling_transaction = $sibling->{transaction};
                my $sibling_label = $sibling->{label};
                like($isf, qr/\(rule axi0_${transaction}_static_busy_capture[\s\S]*\(! \(& axi0_${sibling_transaction}_request/, "multi-static mixed read demux blocks $label static capture during $sibling_label static request");
            }
        }
        my $release_recapture_expected = @static_cases == 2 || @static_cases == 3;
        if ($release_recapture_expected) {
            like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'multi-static mixed read demux dynamic release excludes same-cycle dynamic request');
            like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture\b/, 'multi-static mixed read demux emits dynamic release-recapture rule');
            for my $static_case (@static_cases) {
                my $transaction = $static_case->{transaction};
                my $label = $static_case->{label};
                my $literal = quotemeta($static_case->{literal});
                like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_${transaction}_request/, "multi-static mixed read demux dynamic recapture blocks $label static request");
                like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_arid $literal\)\)/, "multi-static mixed read demux dynamic recapture excludes $label static ID");
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release \(& axi0_${transaction}_complete axi0_${transaction}_static_busy_q \(! axi0_${transaction}_request\)\)/, "multi-static mixed read demux $label static release excludes same-cycle static request");
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture\b/, "multi-static mixed read demux emits $label static release-recapture rule");
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture[\s\S]*\(! \(& axi0_r0_request/, "multi-static mixed read demux $label static recapture blocks dynamic request");
                for my $sibling (grep { $_->{transaction} ne $transaction } @static_cases) {
                    my $sibling_transaction = $sibling->{transaction};
                    my $sibling_label = $sibling->{label};
                    like($isf, qr/\(rule axi0_${transaction}_static_busy_release_recapture[\s\S]*\(! \(& axi0_${sibling_transaction}_request/, "multi-static mixed read demux $label static recapture blocks $sibling_label static request");
                }
            }
        }
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multi-static mixed read demux matches dynamic active RID');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\)\)/, "multi-static mixed read demux matches $label static concrete RID");
            if ($release_recapture_expected) {
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release \(& axi0_${transaction}_complete axi0_${transaction}_static_busy_q \(! axi0_${transaction}_request\)\)/, "multi-static mixed read demux releases $label static busy state without same-cycle recapture request");
            } else {
                like($isf, qr/\(rule axi0_${transaction}_static_busy_release \(& axi0_${transaction}_complete axi0_${transaction}_static_busy_q\)/, "multi-static mixed read demux releases $label static busy state");
            }
        }
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'multi-static mixed read demux emits request onehot assertion');
        like($isf, qr/axi0 r0 dynamic request does not use static concrete ID/, 'multi-static mixed read demux emits dynamic request static-ID reservation assertions');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-static mixed read demux emits response unique-match assertions');
        my $last_static_transaction = $static_cases[-1]{transaction};
        like($isf, qr/axi0 $last_static_transaction static completion releases active concrete ID/, 'multi-static mixed read demux emits last static completion-active assertion');
        assert_mixed_dynamic_static_read_multi_static_report($result->{report}, \@static_cases);
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi-static mixed dynamic RID match');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($fsm, qr/\(-axi0_${transaction}_response_demux\s+<\(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\)\)/, "scheduled FSM lowers multi-static mixed $label static RID match");
            like($fsm, qr/\(-axi0_r0_dynamic_id_capture[\s\S]*\(! \(== axi0_arid $literal\)\)/, "scheduled FSM lowers dynamic read capture exclusion for $label static ID");
        }
        if ($release_recapture_expected) {
            like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers multi-static mixed dynamic read release-recapture');
            for my $static_case (@static_cases) {
                my $transaction = $static_case->{transaction};
                my $label = $static_case->{label};
                like($fsm, qr/\(-axi0_${transaction}_static_busy_release_recapture\s+<\(& \(& axi0_${transaction}_request/, "scheduled FSM lowers multi-static mixed $label static read release-recapture");
            }
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares multi-static mixed read dynamic selected-ID state');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers multi-static mixed dynamic read response guard');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($hdl, qr/\breg\s+axi0_${transaction}_static_busy_q\b/, "SystemVerilog declares $label mixed read static busy state");
            like($hdl, qr/axi0_read_complete\s*&\s*axi0_${transaction}_static_busy_q\s*&\s*\(axi0_rid\s*==\s*$literal\)/, "SystemVerilog lowers multi-static mixed $label static read response guard");
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_rlast_demux') {
        like($isf, qr/\(input axi0_r0_request\)/, 'mixed read RLAST demux declares dynamic request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'mixed read RLAST demux declares static request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'mixed read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'mixed read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'mixed read RLAST demux declares RLAST input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'mixed read RLAST demux exposes dynamic completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'mixed read RLAST demux exposes static completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'mixed read RLAST demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r1_static_busy_q \(width 1\)\)/, 'mixed read RLAST demux allocates static busy storage');
        like($isf, qr/\(! \(== axi0_arid 4'd3\)\)/, 'mixed read RLAST demux prevents dynamic capture of the static concrete ID');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'mixed read RLAST demux matches dynamic active RID and RLAST');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'mixed read RLAST demux matches static concrete RID and RLAST');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(== axi0_arid 4'd3\)\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/, 'mixed read RLAST demux recaptures dynamic ID on same-cycle final dynamic completion');
        like($isf, qr/\(rule axi0_r1_static_busy_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_static_busy_q \(! \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\)\)\s+\(axi0_r1_static_busy_q 1\)\)/, 'mixed read RLAST demux recaptures static busy on same-cycle final static completion');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'mixed read RLAST release-only dynamic path excludes same-cycle request');
        like($isf, qr/\(rule axi0_r1_static_busy_release \(& axi0_r1_complete axi0_r1_static_busy_q \(! axi0_r1_request\)\)/, 'mixed read RLAST release-only static path excludes same-cycle request');
        like($isf, qr/\(assert \(\| \(! axi0_read_complete\) \(\| \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\) \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\)\) "axi0 read mixed dynamic\/static response matches active transaction"\)/, 'mixed read RLAST demux keeps active-response assertion on raw RID match');
        like($isf, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'mixed read RLAST demux emits dynamic idle-or-releasing assertion');
        like($isf, qr/axi0 read static request is idle or releasing active concrete ID/, 'mixed read RLAST demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'mixed read RLAST demux emits raw response unique-match assertion');
        like($isf, qr/axi0 r1 static completion releases active concrete ID/, 'mixed read RLAST demux emits static completion-active assertion');
        assert_mixed_dynamic_static_read_rlast_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers mixed dynamic RID/RLAST match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'scheduled FSM lowers mixed static RID/RLAST match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers mixed dynamic RLAST release-recapture');
        like($fsm, qr/\(-axi0_r1_static_busy_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers mixed static RLAST release-recapture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID for mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID for mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for mixed read RLAST');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers mixed dynamic RID/RLAST guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers mixed static RID/RLAST guard');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_rlast_demux_multi_dynamic') {
        like($isf, qr/\(input axi0_r0_request\)/, 'multi-dynamic mixed read RLAST demux declares first dynamic request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'multi-dynamic mixed read RLAST demux declares second dynamic request input');
        like($isf, qr/\(input axi0_r2_request\)/, 'multi-dynamic mixed read RLAST demux declares static request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-dynamic mixed read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-dynamic mixed read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'multi-dynamic mixed read RLAST demux declares RLAST input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multi-dynamic mixed read RLAST demux exposes first dynamic completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'multi-dynamic mixed read RLAST demux exposes second dynamic completion output');
        like($isf, qr/\(output axi0_r2_complete\)/, 'multi-dynamic mixed read RLAST demux exposes static completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read RLAST demux allocates first dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed read RLAST demux allocates first dynamic busy storage');
        like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed read RLAST demux allocates second dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r1_dynamic_busy_q \(width 1\)\)/, 'multi-dynamic mixed read RLAST demux allocates second dynamic busy storage');
        like($isf, qr/\(var axi0_r2_static_busy_q \(width 1\)\)/, 'multi-dynamic mixed read RLAST demux allocates static busy storage');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture\b/, 'multi-dynamic mixed read RLAST demux emits first dynamic ID capture rule');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture\b/, 'multi-dynamic mixed read RLAST demux emits second dynamic ID capture rule');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read RLAST demux blocks first dynamic capture during second dynamic request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read RLAST demux blocks second dynamic capture during first dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read RLAST demux blocks first dynamic capture of active second dynamic ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read RLAST demux blocks second dynamic capture of active first dynamic ID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read RLAST demux blocks first dynamic capture during static request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read RLAST demux blocks second dynamic capture during static request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read RLAST demux blocks first dynamic capture of static ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read RLAST demux blocks second dynamic capture of static ID');
        like($isf, qr/\(axi0_r0_dynamic_id_q axi0_arid\)/, 'multi-dynamic mixed read RLAST demux captures first dynamic ARID');
        like($isf, qr/\(axi0_r1_dynamic_id_q axi0_arid\)/, 'multi-dynamic mixed read RLAST demux captures second dynamic ARID');
        like($isf, qr/\(rule axi0_r2_static_busy_capture \(& \(& axi0_r2_request/, 'multi-dynamic mixed read RLAST demux captures admitted static request busy state');
        like($isf, qr/\(rule axi0_r2_static_busy_capture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read RLAST demux blocks static capture during first dynamic request');
        like($isf, qr/\(rule axi0_r2_static_busy_capture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read RLAST demux blocks static capture during second dynamic request');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed read RLAST demux matches first dynamic active RID and RLAST');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed read RLAST demux matches second dynamic active RID and RLAST');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-dynamic mixed read RLAST demux matches static concrete RID and RLAST');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture\b/, 'multi-dynamic mixed read RLAST demux emits first dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture\b/, 'multi-dynamic mixed read RLAST demux emits second dynamic release-recapture rule');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture\b/, 'multi-dynamic mixed read RLAST demux emits static release-recapture rule');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read RLAST demux blocks first dynamic recapture during second dynamic request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read RLAST demux blocks second dynamic recapture during first dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read RLAST demux blocks first dynamic recapture of active second dynamic ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)/, 'multi-dynamic mixed read RLAST demux blocks second dynamic recapture of active first dynamic ID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read RLAST demux blocks first dynamic recapture during static request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(& axi0_r2_request/, 'multi-dynamic mixed read RLAST demux blocks second dynamic recapture during static request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read RLAST demux blocks first dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture[\s\S]*\(! \(== axi0_arid 4'd3\)\)/, 'multi-dynamic mixed read RLAST demux blocks second dynamic recapture of static ID');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture[\s\S]*\(! \(& axi0_r0_request/, 'multi-dynamic mixed read RLAST demux blocks static recapture during first dynamic request');
        like($isf, qr/\(rule axi0_r2_static_busy_release_recapture[\s\S]*\(! \(& axi0_r1_request/, 'multi-dynamic mixed read RLAST demux blocks static recapture during second dynamic request');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'multi-dynamic mixed read RLAST demux releases first dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'multi-dynamic mixed read RLAST demux releases second dynamic only without same-cycle request');
        like($isf, qr/\(rule axi0_r2_static_busy_release \(& axi0_r2_complete axi0_r2_static_busy_q \(! axi0_r2_request\)\)/, 'multi-dynamic mixed read RLAST demux releases static only without same-cycle request');
        my $active_match_assertion =
            q{(assert (| (! axi0_read_complete) (| (& axi0_r0_dynamic_busy_q (== axi0_rid axi0_r0_dynamic_id_q)) (& axi0_r1_dynamic_busy_q (== axi0_rid axi0_r1_dynamic_id_q)) (& axi0_r2_static_busy_q (== axi0_rid 4'd3)))) "axi0 read mixed dynamic/static response matches active transaction")};
        like($isf, qr/\Q$active_match_assertion\E/, 'multi-dynamic mixed read RLAST demux keeps active-response assertion on raw RID match');
        like($isf, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'multi-dynamic mixed read RLAST demux emits dynamic idle-or-releasing assertions');
        like($isf, qr/axi0 read static request is idle or releasing active concrete ID/, 'multi-dynamic mixed read RLAST demux emits static idle-or-releasing assertion');
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'multi-dynamic mixed read RLAST demux emits mixed request onehot assertion');
        like($isf, qr/axi0 r0 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed read RLAST demux emits first no-active-same-ID assertion');
        like($isf, qr/axi0 r1 dynamic request does not reuse an active sibling ID/, 'multi-dynamic mixed read RLAST demux emits second no-active-same-ID assertion');
        like($isf, qr/axi0 read dynamic active IDs are unique/, 'multi-dynamic mixed read RLAST demux emits active dynamic ID uniqueness assertion');
        like($isf, qr/axi0 r0 dynamic request does not use static concrete ID/, 'multi-dynamic mixed read RLAST demux emits first dynamic static-ID request assertion');
        like($isf, qr/axi0 r1 dynamic request does not use static concrete ID/, 'multi-dynamic mixed read RLAST demux emits second dynamic static-ID request assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-dynamic mixed read RLAST demux emits raw response unique-match assertions');
        like($isf, qr/axi0 r2 static completion releases active concrete ID/, 'multi-dynamic mixed read RLAST demux emits static completion-active assertion');
        assert_mixed_dynamic_static_read_rlast_multi_dynamic_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers multi-dynamic mixed first dynamic RID/RLAST match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers multi-dynamic mixed second dynamic RID/RLAST match');
        like($fsm, qr/\(-axi0_r2_response_demux\s+<\(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'scheduled FSM lowers multi-dynamic mixed static RID/RLAST match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers first multi-dynamic mixed dynamic RLAST release-recapture');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers second multi-dynamic mixed dynamic RLAST release-recapture');
        like($fsm, qr/\(-axi0_r2_static_busy_release_recapture\s+<\(& \(& axi0_r2_request/, 'scheduled FSM lowers multi-dynamic mixed static RLAST release-recapture');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled FSM lowers first multi-dynamic mixed dynamic RLAST release-only rule');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release\s+<\(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'scheduled FSM lowers second multi-dynamic mixed dynamic RLAST release-only rule');
        like($fsm, qr/\(-axi0_r2_static_busy_release\s+<\(& axi0_r2_complete axi0_r2_static_busy_q \(! axi0_r2_request\)\)/, 'scheduled FSM lowers multi-dynamic mixed static RLAST release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID for multi-dynamic mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID for multi-dynamic mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for multi-dynamic mixed read RLAST');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares first multi-dynamic mixed read RLAST selected-ID state');
        like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r1_dynamic_id_q\b/, 'SystemVerilog declares second multi-dynamic mixed read RLAST selected-ID state');
        like($hdl, qr/\breg\s+axi0_r2_static_busy_q\b/, 'SystemVerilog declares multi-dynamic mixed read RLAST static busy state');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi-dynamic mixed first dynamic RID/RLAST guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi-dynamic mixed second dynamic RID/RLAST guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r2_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi-dynamic mixed static RID/RLAST guard');
        like($hdl, qr/axi0_r0_dynamic_busy_q\s*&\s*\(axi0_r0_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers first dynamic read RLAST active sibling-ID expression');
        like($hdl, qr/axi0_r1_dynamic_busy_q\s*&\s*\(axi0_r1_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers second dynamic read RLAST active sibling-ID expression');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic_last_beat') {
        for my $tx (qw(r0 r1 r2)) {
            like($isf, qr/\(input axi0_${tx}_request\)/, "multi-dynamic mixed last-beat read-data declares $tx request input");
            like($isf, qr/\(output axi0_${tx}_complete\)/, "multi-dynamic mixed last-beat read-data exposes $tx completion output");
        }
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-dynamic mixed last-beat read-data declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-dynamic mixed last-beat read-data declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'multi-dynamic mixed last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-dynamic mixed last-beat read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-dynamic mixed last-beat read-data declares RRESP input');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed last-beat read-data allocates first dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multi-dynamic mixed last-beat read-data allocates second dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r2_static_busy_q \(width 1\)\)/, 'multi-dynamic mixed last-beat read-data allocates static busy storage');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed last-beat read-data keeps first dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed last-beat read-data keeps second dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-dynamic mixed last-beat read-data keeps static RID/RLAST demux');
        like($isf, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'multi-dynamic mixed last-beat read-data keeps mixed request onehot assertion');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-dynamic mixed last-beat read-data keeps raw response unique-match assertions');
        for my $tx (qw(r0 r1 r2)) {
            like($isf, qr/\(output axi0_${tx}_last_rdata \(width 32\)\)/, "multi-dynamic mixed last-beat read-data declares $tx scalar last data output");
            like($isf, qr/\(output axi0_${tx}_last_rresp \(width 2\)\)/, "multi-dynamic mixed last-beat read-data declares $tx scalar last status output");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/, "multi-dynamic mixed last-beat read-data captures $tx payload under generated completion");
        }
        unlike($isf, qr/\baxi0_arlen\b/, 'multi-dynamic mixed last-beat read-data keeps burst-length metadata absent');
        assert_mixed_dynamic_static_read_rlast_multi_dynamic_report($result->{report});
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
            [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)],
            [qw(r0 r1 r2)],
        );
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers second dynamic last-beat read-data capture');
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers static last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes RDATA for multi-dynamic mixed last-beat read-data');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes RRESP for multi-dynamic mixed last-beat read-data');
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards second dynamic last-beat read-data capture by completion');
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog guards static last-beat read-data capture by completion');
        like($hdl, qr/axi0_r1_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures second dynamic last-beat RDATA');
        like($hdl, qr/axi0_r1_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures second dynamic last-beat RRESP');
        like($hdl, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures static last-beat RDATA');
        like($hdl, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures static last-beat RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic_burst_length'
        || $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic_burst_length_runtime_assertion';
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed burst-length read-data keeps first dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed burst-length read-data keeps second dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-dynamic mixed burst-length read-data keeps static RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-dynamic mixed burst-length read-data declares ARLEN input');
        for my $tx (qw(r0 r1 r2)) {
            like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "multi-dynamic mixed burst-length read-data allocates $tx raw ARLEN storage");
            like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "multi-dynamic mixed burst-length read-data captures $tx raw ARLEN under request");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/, "multi-dynamic mixed burst-length read-data keeps $tx payload capture under generated completion");
        }
        if ($runtime_validation) {
            for my $tx (qw(r0 r1 r2)) {
                like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "multi-dynamic mixed runtime burst-length declares $tx expected-beat storage");
                like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "multi-dynamic mixed runtime burst-length declares $tx beat-count storage");
                like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "multi-dynamic mixed runtime burst-length initializes $tx expected count on request");
                like($isf, qr/axi0 $tx ARLEN is within configured max beats/, "multi-dynamic mixed runtime burst-length emits $tx ARLEN bound assertion");
                like($isf, qr/axi0 $tx RLAST appears only on the expected final read beat/, "multi-dynamic mixed runtime burst-length emits $tx early-RLAST assertion");
                like($isf, qr/axi0 $tx expected final read beat has RLAST/, "multi-dynamic mixed runtime burst-length emits $tx missing-RLAST assertion");
            }
            like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'multi-dynamic mixed runtime burst-length increments first dynamic count on matched RID beat');
            like($isf, qr/\(rule axi0_r1_read_beat_count \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\)\)\s+\(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'multi-dynamic mixed runtime burst-length increments second dynamic count on matched RID beat');
            like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r2_request\)\)\s+\(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'multi-dynamic mixed runtime burst-length increments static count on matched RID beat');
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'multi-dynamic mixed report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_mixed_dynamic_static_read_rlast_multi_dynamic_report($result->{report});
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
            [qw(r0 r1 r2)],
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        like($fsm, qr/\(-axi0_r2_burst_length_capture\s+<axi0_r2_request\s+\(<- \(axi0_r2_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers multi-dynamic mixed static raw ARLEN capture');
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps multi-dynamic mixed static payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r1_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers multi-dynamic mixed second dynamic expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers multi-dynamic mixed second dynamic beat-count increment');
            like($fsm, qr/\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers multi-dynamic mixed static expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers multi-dynamic mixed static beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes multi-dynamic mixed ARLEN');
        like($hdl, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog guards multi-dynamic mixed static ARLEN capture by request');
        like($hdl, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures multi-dynamic mixed static raw ARLEN');
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog still guards multi-dynamic mixed static last-beat payload capture by completion');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_expected_beats_q\b/, 'SystemVerilog declares multi-dynamic mixed second dynamic expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_read_beat_count_q\b/, 'SystemVerilog declares multi-dynamic mixed second dynamic beat-count storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'SystemVerilog declares multi-dynamic mixed static expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'SystemVerilog declares multi-dynamic mixed static beat-count storage');
            like($hdl, qr/assign\s+axi0_r1_read_beat_count_en\s*=/, 'SystemVerilog emits multi-dynamic mixed second dynamic beat-count increment enable');
            like($hdl, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'SystemVerilog emits multi-dynamic mixed static beat-count increment enable');
            like($hdl, qr/axi0_r1_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes multi-dynamic mixed second dynamic expected count from ARLEN+1');
            like($hdl, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes multi-dynamic mixed static expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps multi-dynamic mixed report-only burst-length free of runtime validation');
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_rlast_demux_multi_static'
        || $case->{behavior} eq 'mixed_dynamic_static_read_rlast_demux_multi_static3') {
        my @static_cases = (
            { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            (
                $case->{behavior} eq 'mixed_dynamic_static_read_rlast_demux_multi_static3'
                    ? ({ transaction => 'r3', value => 7, literal => "4'd7", label => 'third' })
                    : ()
            ),
        );
        like($isf, qr/\(input axi0_r0_request\)/, 'multi-static mixed read RLAST demux declares dynamic request input');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(input axi0_${transaction}_request\)/, "multi-static mixed read RLAST demux declares $label static request input");
        }
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multi-static mixed read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multi-static mixed read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'multi-static mixed read RLAST demux declares RLAST input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multi-static mixed read RLAST demux exposes dynamic completion output');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            like($isf, qr/\(output axi0_${transaction}_complete\)/, "multi-static mixed read RLAST demux exposes $label static completion output");
        }
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multi-static mixed read RLAST demux allocates dynamic selected-ID storage');
        like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'multi-static mixed read RLAST demux allocates dynamic busy storage');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(var axi0_${transaction}_static_busy_q \(width 1\)\)/, "multi-static mixed read RLAST demux allocates $label static busy storage");
            like($isf, qr/\(! \(== axi0_arid $literal\)\)/, "multi-static mixed read RLAST demux prevents dynamic capture of $label static concrete ID");
        }
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-static mixed read RLAST demux matches dynamic active RID and RLAST');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\) axi0_rlast\)/, "multi-static mixed read RLAST demux matches $label static concrete RID and RLAST");
        }
        my @raw_match_exprs = ('(& axi0_r0_dynamic_busy_q (== axi0_rid axi0_r0_dynamic_id_q))');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $literal = $static_case->{literal};
            push @raw_match_exprs, "(& axi0_${transaction}_static_busy_q (== axi0_rid $literal))";
        }
        my $active_match_assertion =
            '(assert (| (! axi0_read_complete) (| '
            . join(' ', @raw_match_exprs)
            . ')) "axi0 read mixed dynamic/static response matches active transaction")';
        like($isf, qr/\Q$active_match_assertion\E/, 'multi-static mixed read RLAST demux keeps active-response assertion on raw RID match');
        like($isf, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'multi-static mixed read RLAST demux emits raw response unique-match assertions');
        my $last_static_transaction = $static_cases[-1]{transaction};
        like($isf, qr/axi0 $last_static_transaction static completion releases active concrete ID/, 'multi-static mixed read RLAST demux emits last static completion-active assertion');
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report}, \@static_cases);
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers multi-static mixed dynamic RID/RLAST match');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($fsm, qr/\(-axi0_${transaction}_response_demux\s+<\(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\) axi0_rlast\)/, "scheduled FSM lowers multi-static mixed $label static RID/RLAST match");
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID for multi-static mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID for multi-static mixed read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for multi-static mixed read RLAST');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi-static mixed dynamic RID/RLAST guard');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($hdl, qr/axi0_read_complete\s*&\s*axi0_${transaction}_static_busy_q\s*&\s*\(axi0_rid\s*==\s*$literal\)\s*&\s*axi0_rlast/, "SystemVerilog lowers multi-static mixed $label static RID/RLAST guard");
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multi-static mixed read-data keeps dynamic RID demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)/, 'multi-static mixed read-data keeps first static RID demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd5\)\)/, 'multi-static mixed read-data keeps second static RID demux');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-static mixed read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-static mixed read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'multi-static mixed read-data declares dynamic scalar data output');
        like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'multi-static mixed read-data declares first static scalar data output');
        like($isf, qr/\(output axi0_r2_rdata \(width 32\)\)/, 'multi-static mixed read-data declares second static scalar data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'multi-static mixed read-data captures dynamic payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/, 'multi-static mixed read-data captures first static payload under generated completion');
        like($isf, qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_rdata axi0_rdata\)\s+\(axi0_r2_rresp axi0_rresp\)\)/, 'multi-static mixed read-data captures second static payload under generated completion');
        assert_mixed_dynamic_static_read_multi_static_report($result->{report});
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse',
            [qw(rlast_completion bursts multi_beat_read_data_reassembly)],
            [qw(r0 r1 r2)],
        );
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers multi-static second static read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog guards multi-static second static read-data capture by completion');
        like($hdl, qr/axi0_r2_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-static second static RDATA');
        like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures multi-static second static RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static_last_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-static mixed last-beat read-data keeps dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-static mixed last-beat read-data keeps first static RID/RLAST demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd5\) axi0_rlast\)/, 'multi-static mixed last-beat read-data keeps second static RID/RLAST demux');
        like($isf, qr/\(input axi0_rlast\)/, 'multi-static mixed last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-static mixed last-beat read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-static mixed last-beat read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'multi-static mixed last-beat read-data declares dynamic scalar last data output');
        like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'multi-static mixed last-beat read-data declares first static scalar last data output');
        like($isf, qr/\(output axi0_r2_last_rdata \(width 32\)\)/, 'multi-static mixed last-beat read-data declares second static scalar last data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'multi-static mixed last-beat read-data captures dynamic payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'multi-static mixed last-beat read-data captures first static payload under generated completion');
        like($isf, qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/, 'multi-static mixed last-beat read-data captures second static payload under generated completion');
        unlike($isf, qr/\baxi0_arlen\b/, 'multi-static mixed last-beat read-data keeps burst-length metadata absent');
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report});
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
            [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)],
            [qw(r0 r1 r2)],
        );
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers multi-static second static last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog guards multi-static second static last-beat read-data capture by completion');
        like($hdl, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-static second static last-beat RDATA');
        like($hdl, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures multi-static second static last-beat RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3') {
        my @static_cases = (
            { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            { transaction => 'r3', value => 7, literal => "4'd7", label => 'third' },
        );
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'three-static mixed read-data keeps dynamic RID demux');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\)\)/, "three-static mixed read-data keeps $label static RID demux");
        }
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'three-static mixed read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'three-static mixed read-data declares RRESP input');
        for my $tx (qw(r0 r1 r2 r3)) {
            like($isf, qr/\(output axi0_${tx}_rdata \(width 32\)\)/, "three-static mixed read-data declares $tx scalar data output");
            like($isf, qr/\(output axi0_${tx}_rresp \(width 2\)\)/, "three-static mixed read-data declares $tx scalar status output");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_rdata axi0_rdata\)\s+\(axi0_${tx}_rresp axi0_rresp\)\)/, "three-static mixed read-data captures $tx payload under generated completion");
        }
        assert_mixed_dynamic_static_read_multi_static_report($result->{report}, \@static_cases);
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_completion_pulse',
            [qw(rlast_completion bursts multi_beat_read_data_reassembly)],
            [qw(r0 r1 r2 r3)],
        );
        like($fsm, qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers three-static third static read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r3_read_data_capture_en\s*=\s*axi0_r3_complete\s*;/, 'SystemVerilog guards three-static third static read-data capture by completion');
        like($hdl, qr/axi0_r3_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures three-static third static RDATA');
        like($hdl, qr/axi0_r3_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures three-static third static RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_last_beat') {
        my @static_cases = (
            { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            { transaction => 'r3', value => 7, literal => "4'd7", label => 'third' },
        );
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'three-static mixed last-beat read-data keeps dynamic RID/RLAST demux');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\) axi0_rlast\)/, "three-static mixed last-beat read-data keeps $label static RID/RLAST demux");
        }
        like($isf, qr/\(input axi0_rlast\)/, 'three-static mixed last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'three-static mixed last-beat read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'three-static mixed last-beat read-data declares RRESP input');
        for my $tx (qw(r0 r1 r2 r3)) {
            like($isf, qr/\(output axi0_${tx}_last_rdata \(width 32\)\)/, "three-static mixed last-beat read-data declares $tx scalar last data output");
            like($isf, qr/\(output axi0_${tx}_last_rresp \(width 2\)\)/, "three-static mixed last-beat read-data declares $tx scalar last status output");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/, "three-static mixed last-beat read-data captures $tx payload under generated completion");
        }
        unlike($isf, qr/\baxi0_arlen\b/, 'three-static mixed last-beat read-data keeps burst-length metadata absent');
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report}, \@static_cases);
        assert_read_data_report(
            $result->{report}{read_data},
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
            [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)],
            [qw(r0 r1 r2 r3)],
        );
        like($fsm, qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers three-static third static last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r3_read_data_capture_en\s*=\s*axi0_r3_complete\s*;/, 'SystemVerilog guards three-static third static last-beat read-data capture by completion');
        like($hdl, qr/axi0_r3_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures three-static third static last-beat RDATA');
        like($hdl, qr/axi0_r3_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures three-static third static last-beat RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_burst_length'
        || $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_burst_length_runtime_assertion';
        my @static_cases = (
            { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
            { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            { transaction => 'r3', value => 7, literal => "4'd7", label => 'third' },
        );
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'three-static mixed burst-length read-data keeps dynamic RID/RLAST demux');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $label = $static_case->{label};
            my $literal = quotemeta($static_case->{literal});
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\) axi0_rlast\)/, "three-static mixed burst-length read-data keeps $label static RID/RLAST demux");
        }
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'three-static mixed burst-length read-data declares ARLEN input');
        for my $tx (qw(r0 r1 r2 r3)) {
            like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "three-static mixed burst-length read-data allocates $tx raw ARLEN storage");
            like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "three-static mixed burst-length read-data captures $tx raw ARLEN under request");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/, "three-static mixed burst-length read-data keeps $tx payload capture under generated completion");
        }
        if ($runtime_validation) {
            for my $tx (qw(r0 r1 r2 r3)) {
                like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "three-static mixed runtime burst-length declares $tx expected-beat storage");
                like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "three-static mixed runtime burst-length declares $tx beat-count storage");
                like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "three-static mixed runtime burst-length initializes $tx expected count on request");
                like($isf, qr/axi0 $tx ARLEN is within configured max beats/, "three-static mixed runtime burst-length emits $tx ARLEN bound assertion");
                like($isf, qr/axi0 $tx RLAST appears only on the expected final read beat/, "three-static mixed runtime burst-length emits $tx early-RLAST assertion");
                like($isf, qr/axi0 $tx expected final read beat has RLAST/, "three-static mixed runtime burst-length emits $tx missing-RLAST assertion");
            }
            like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'three-static mixed runtime burst-length increments dynamic count on matched RID beat');
            for my $static_case (@static_cases) {
                my $transaction = $static_case->{transaction};
                my $label = $static_case->{label};
                my $literal = quotemeta($static_case->{literal});
                like($isf, qr/\(rule axi0_${transaction}_read_beat_count \(& \(& axi0_read_complete \(& axi0_${transaction}_static_busy_q \(== axi0_rid $literal\)\)\) \(! axi0_${transaction}_request\)\)\s+\(axi0_${transaction}_read_beat_count_q \(\+ axi0_${transaction}_read_beat_count_q 5'd1\)\)\)/, "three-static mixed runtime burst-length increments $label static count on matched RID beat");
            }
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'three-static mixed report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report}, \@static_cases);
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
            [qw(r0 r1 r2 r3)],
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        like($fsm, qr/\(-axi0_r3_burst_length_capture\s+<axi0_r3_request\s+\(<- \(axi0_r3_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers three-static third static raw ARLEN capture');
        like($fsm, qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps three-static third static payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r3_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers three-static third static expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r3_read_beat_count_q \(\+ axi0_r3_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers three-static third static beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes three-static mixed ARLEN');
        like($hdl, qr/assign\s+axi0_r3_burst_length_capture_en\s*=\s*axi0_r3_request\s*;/, 'SystemVerilog guards three-static third static ARLEN capture by request');
        like($hdl, qr/axi0_r3_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures three-static third static raw ARLEN');
        like($hdl, qr/assign\s+axi0_r3_read_data_capture_en\s*=\s*axi0_r3_complete\s*;/, 'SystemVerilog still guards three-static third static last-beat payload capture by completion');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r3_expected_beats_q\b/, 'SystemVerilog declares three-static third static expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r3_read_beat_count_q\b/, 'SystemVerilog declares three-static third static beat-count storage');
            like($hdl, qr/assign\s+axi0_r3_beat_count_init_en\s*=\s*axi0_r3_request\s*;/, 'SystemVerilog guards three-static third static beat-count init by request');
            like($hdl, qr/assign\s+axi0_r3_read_beat_count_en\s*=/, 'SystemVerilog emits three-static third static beat-count increment enable');
            like($hdl, qr/axi0_r3_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes three-static third static expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps three-static mixed report-only burst-length free of runtime validation');
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static_burst_length'
        || $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static_burst_length_runtime_assertion';
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-static mixed burst-length read-data keeps dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-static mixed burst-length read-data keeps first static RID/RLAST demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd5\) axi0_rlast\)/, 'multi-static mixed burst-length read-data keeps second static RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-static mixed burst-length read-data declares ARLEN input');
        for my $tx (qw(r0 r1 r2)) {
            like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "multi-static mixed burst-length read-data allocates $tx raw ARLEN storage");
            like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "multi-static mixed burst-length read-data captures $tx raw ARLEN under request");
            like($isf, qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/, "multi-static mixed burst-length read-data keeps $tx payload capture under generated completion");
        }
        if ($runtime_validation) {
            for my $tx (qw(r0 r1 r2)) {
                like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "multi-static mixed runtime burst-length declares $tx expected-beat storage");
                like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "multi-static mixed runtime burst-length declares $tx beat-count storage");
                like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "multi-static mixed runtime burst-length initializes $tx expected count on request");
                like($isf, qr/axi0 $tx ARLEN is within configured max beats/, "multi-static mixed runtime burst-length emits $tx ARLEN bound assertion");
                like($isf, qr/axi0 $tx RLAST appears only on the expected final read beat/, "multi-static mixed runtime burst-length emits $tx early-RLAST assertion");
                like($isf, qr/axi0 $tx expected final read beat has RLAST/, "multi-static mixed runtime burst-length emits $tx missing-RLAST assertion");
            }
            like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'multi-static mixed runtime burst-length increments dynamic count on matched RID beat');
            like($isf, qr/\(rule axi0_r1_read_beat_count \(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\)\)\s+\(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'multi-static mixed runtime burst-length increments first static count on matched RID beat');
            like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd5\)\)\) \(! axi0_r2_request\)\)\s+\(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'multi-static mixed runtime burst-length increments second static count on matched RID beat');
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'multi-static mixed report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report});
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
            [qw(r0 r1 r2)],
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        like($fsm, qr/\(-axi0_r2_burst_length_capture\s+<axi0_r2_request\s+\(<- \(axi0_r2_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers multi-static second static raw ARLEN capture');
        like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps multi-static second static payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers multi-static second static expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers multi-static second static beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes multi-static mixed ARLEN');
        like($hdl, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog guards multi-static second static ARLEN capture by request');
        like($hdl, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures multi-static second static raw ARLEN');
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog still guards multi-static second static last-beat payload capture by completion');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'SystemVerilog declares multi-static second static expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'SystemVerilog declares multi-static second static beat-count storage');
            like($hdl, qr/assign\s+axi0_r2_beat_count_init_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog guards multi-static second static beat-count init by request');
            like($hdl, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'SystemVerilog emits multi-static second static beat-count increment enable');
            like($hdl, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes multi-static second static expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps multi-static mixed report-only burst-length free of runtime validation');
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'mixed read-data keeps dynamic RID demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)/, 'mixed read-data keeps static RID demux');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'mixed read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'mixed read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'mixed read-data declares dynamic scalar data output');
        like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'mixed read-data declares static scalar data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'mixed read-data captures dynamic payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/, 'mixed read-data captures static payload under generated completion');
        assert_mixed_dynamic_static_read_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_mixed_dynamic_static_read_response_demux_completion_pulse', [qw(rlast_completion bursts multi_beat_read_data_reassembly)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers mixed static read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards mixed static read-data capture by completion');
        like($hdl, qr/axi0_r1_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures mixed static RDATA');
        like($hdl, qr/axi0_r1_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures mixed static RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_last_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'mixed last-beat read-data keeps dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'mixed last-beat read-data keeps static RID/RLAST demux');
        like($isf, qr/\(input axi0_rlast\)/, 'mixed last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'mixed last-beat read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'mixed last-beat read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'mixed last-beat read-data declares dynamic scalar last data output');
        like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'mixed last-beat read-data declares static scalar last data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'mixed last-beat read-data captures dynamic payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'mixed last-beat read-data captures static payload under generated completion');
        unlike($isf, qr/\baxi0_arlen\b/, 'mixed last-beat read-data keeps burst-length metadata absent');
        assert_mixed_dynamic_static_read_rlast_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse', [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers mixed static last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards mixed static last-beat read-data capture by completion');
        like($hdl, qr/axi0_r1_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures mixed static last-beat RDATA');
        like($hdl, qr/axi0_r1_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures mixed static last-beat RRESP');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_burst_length'
        || $case->{behavior} eq 'mixed_dynamic_static_read_data_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'mixed_dynamic_static_read_data_burst_length_runtime_assertion';
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'mixed burst-length read-data keeps dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'mixed burst-length read-data keeps static RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'mixed burst-length read-data declares ARLEN input');
        like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'mixed burst-length read-data allocates dynamic raw ARLEN storage');
        like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'mixed burst-length read-data allocates static raw ARLEN storage');
        like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'mixed burst-length read-data captures dynamic raw ARLEN under request');
        like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'mixed burst-length read-data captures static raw ARLEN under request');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'mixed burst-length read-data keeps dynamic payload capture under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'mixed burst-length read-data keeps static payload capture under generated completion');
        if ($runtime_validation) {
            for my $tx (qw(r0 r1)) {
                like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "mixed runtime burst-length declares $tx expected-beat storage");
                like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "mixed runtime burst-length declares $tx beat-count storage");
                like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "mixed runtime burst-length initializes $tx expected count on request");
                like($isf, qr/axi0 $tx ARLEN is within configured max beats/, "mixed runtime burst-length emits $tx ARLEN bound assertion");
                like($isf, qr/axi0 $tx RLAST appears only on the expected final read beat/, "mixed runtime burst-length emits $tx early-RLAST assertion");
                like($isf, qr/axi0 $tx expected final read beat has RLAST/, "mixed runtime burst-length emits $tx missing-RLAST assertion");
            }
            like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'mixed runtime burst-length increments dynamic count on matched RID beat');
            like($isf, qr/\(rule axi0_r1_read_beat_count \(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\)\)\s+\(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'mixed runtime burst-length increments static count on matched RID beat');
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'mixed report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_mixed_dynamic_static_read_rlast_report($result->{report});
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
            [qw(r0 r1)],
            'generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        like($fsm, qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers mixed static raw ARLEN capture');
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps mixed static payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r1_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers mixed static expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers mixed static beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes mixed ARLEN');
        like($hdl, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards mixed static ARLEN capture by request');
        like($hdl, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures mixed static raw ARLEN');
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog still guards mixed static last-beat payload capture by completion');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_expected_beats_q\b/, 'SystemVerilog declares mixed static expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_read_beat_count_q\b/, 'SystemVerilog declares mixed static beat-count storage');
            like($hdl, qr/assign\s+axi0_r1_read_beat_count_en\s*=/, 'SystemVerilog emits mixed static beat-count increment enable');
            like($hdl, qr/axi0_r1_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes mixed static expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps mixed report-only burst-length free of runtime validation');
        }
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
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) axi0_r0_complete axi0_r0_dynamic_busy_q\)/, 'dynamic read demux recaptures on same-cycle release');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'dynamic read demux releases active state only without same-cycle request');
        assert_dynamic_read_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers dynamic read RID match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers dynamic read release-recapture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers dynamic read response guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_demux_multi') {
        like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read demux declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read demux declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read demux declares RID input');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read demux exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read demux exposes r1 completion output');
        like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read demux allocates r0 selected-ID storage');
        like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read demux allocates r1 selected-ID storage');
        like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) \(! axi0_r0_dynamic_busy_q\) \(! \(& axi0_r1_request/, 'multiple dynamic read demux gates r0 capture against sibling request');
        like($isf, qr/\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multiple dynamic read demux gates r0 capture against active sibling ID');
        like($isf, qr/\(rule axi0_r1_dynamic_id_capture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) \(! axi0_r1_dynamic_busy_q\) \(! \(& axi0_r0_request/, 'multiple dynamic read demux gates r1 capture against sibling request');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multiple dynamic read demux matches active r0 RID');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multiple dynamic read demux matches active r1 RID');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/, 'multiple dynamic read demux recaptures r0 on same-cycle release');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_dynamic_busy_q \(! \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r1_dynamic_id_q axi0_arid\)\s+\(axi0_r1_dynamic_busy_q 1\)\)/, 'multiple dynamic read demux recaptures r1 on same-cycle release');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)\s+\(axi0_r0_dynamic_busy_q 0\)\)/, 'multiple dynamic read demux releases r0 only without same-cycle own request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)\s+\(axi0_r1_dynamic_busy_q 0\)\)/, 'multiple dynamic read demux releases r1 only without same-cycle own request');
        like($isf, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'multiple dynamic read demux emits idle-or-releasing assertions');
        like($isf, qr/axi0 read dynamic requests are mutually exclusive/, 'multiple dynamic read demux emits request onehot assertion');
        like($isf, qr/axi0 read dynamic active IDs are unique/, 'multiple dynamic read demux emits active ID uniqueness assertion');
        like($isf, qr/axi0 read dynamic response matches at most one captured ID/, 'multiple dynamic read demux emits response unique-match assertion');
        assert_dynamic_read_multi_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled FSM lowers multi dynamic r0 RID match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'scheduled FSM lowers multi dynamic r1 RID match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers multi dynamic r0 release-recapture');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers multi dynamic r1 release-recapture');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled FSM lowers multi dynamic r0 release-only rule');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release\s+<\(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'scheduled FSM lowers multi dynamic r1 release-only rule');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID for multi dynamic read');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID for multi dynamic read');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic r0 response guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic r1 response guard');
        like($hdl, qr/axi0_r0_dynamic_busy_q\s*&\s*\(axi0_r0_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers active sibling-ID expression for r0');
        like($hdl, qr/axi0_r1_dynamic_busy_q\s*&\s*\(axi0_r1_dynamic_id_q\s*==\s*axi0_arid\)/, 'SystemVerilog lowers active sibling-ID expression for r1');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_rlast_demux_multi') {
        like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read RLAST demux declares r0 request input');
        like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read RLAST demux declares r1 request input');
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic read RLAST demux declares RLAST input');
        unlike($isf, qr/\(input axi0_r0_complete\b/, 'multiple dynamic read RLAST demux owns generated r0 completion');
        unlike($isf, qr/\(input axi0_r1_complete\b/, 'multiple dynamic read RLAST demux owns generated r1 completion');
        like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read RLAST demux exposes r0 completion output');
        like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read RLAST demux exposes r1 completion output');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic read RLAST demux matches active r0 RID and RLAST');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic read RLAST demux matches active r1 RID and RLAST');
        like($isf, qr/\(assert \(\| \(! axi0_read_complete\) \(\| \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\) \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\)\) "axi0 read dynamic response matches active captured ID"\)/, 'multiple dynamic read RLAST demux keeps active-response assertion on raw RID match');
        like($isf, qr/axi0 read dynamic response matches at most one captured ID/, 'multiple dynamic read RLAST demux emits raw response unique-match assertion');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)\)/, 'multiple dynamic read RLAST demux recaptures r0 on same-cycle final completion');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_dynamic_busy_q \(! \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)\)/, 'multiple dynamic read RLAST demux recaptures r1 on same-cycle final completion');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'multiple dynamic read RLAST release-only r0 excludes same-cycle r0 request');
        like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'multiple dynamic read RLAST release-only r1 excludes same-cycle r1 request');
        assert_dynamic_read_multi_rlast_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers multi dynamic r0 RID/RLAST match');
        like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers multi dynamic r1 RID/RLAST match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers multi dynamic RLAST r0 release-recapture');
        like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled FSM lowers multi dynamic RLAST r1 release-recapture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog exposes ARID for multi dynamic read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes RID for multi dynamic read RLAST');
        like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for multi dynamic read');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi dynamic r0 RID/RLAST guard');
        like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi dynamic r1 RID/RLAST guard');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_rlast_demux') {
        like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read RLAST demux declares ARID input');
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read RLAST demux declares RID input');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic read RLAST demux declares RLAST input');
        unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read RLAST demux owns generated completion');
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic read RLAST demux matches active RID and RLAST');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) axi0_r0_complete axi0_r0_dynamic_busy_q\)/, 'dynamic read RLAST demux recaptures on same-cycle final completion');
        like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'dynamic read RLAST release-only excludes same-cycle request');
        assert_dynamic_read_rlast_report($result->{report});
        like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled FSM lowers dynamic RID/RLAST match');
        like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled FSM lowers dynamic RLAST release-recapture');
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

    if ($case->{behavior} eq 'dynamic_read_data_multi') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multiple dynamic read-data keeps r0 generated RID demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multiple dynamic read-data keeps r1 generated RID demux');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multiple dynamic read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multiple dynamic read-data declares RRESP input');
        like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'multiple dynamic read-data declares r0 scalar data output');
        like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'multiple dynamic read-data declares r1 scalar data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'multiple dynamic read-data captures r0 payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/, 'multiple dynamic read-data captures r1 payload under generated completion');
        assert_dynamic_read_multi_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_response_demux_completion_pulse', [qw(rlast_completion bursts multi_beat_read_data_reassembly)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers r1 multiple dynamic read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 multiple dynamic read-data capture by completion');
        like($hdl, qr/axi0_r1_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 dynamic RDATA');
        like($hdl, qr/axi0_r1_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 dynamic RRESP');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_multi_last_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic last-beat read-data keeps r0 generated RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic last-beat read-data keeps r1 generated RID/RLAST demux');
        like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic last-beat read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares RDATA input');
        like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares r0 scalar last data output');
        like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares r1 scalar last data output');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'multiple dynamic last-beat read-data captures r0 payload under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'multiple dynamic last-beat read-data captures r1 payload under generated completion');
        unlike($isf, qr/\baxi0_arlen\b/, 'multiple dynamic last-beat read-data keeps burst-length metadata absent');
        assert_dynamic_read_multi_rlast_report($result->{report});
        assert_read_data_report($result->{report}{read_data}, 'generated_dynamic_read_response_demux_last_beat_completion_pulse', [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)], [qw(r0 r1)]);
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM lowers r1 multiple dynamic last-beat read-data capture');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 multiple dynamic last-beat read-data capture by completion');
        like($hdl, qr/axi0_r1_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 dynamic last-beat RDATA');
        like($hdl, qr/axi0_r1_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 dynamic last-beat RRESP');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_multi_burst_length'
        || $case->{behavior} eq 'dynamic_read_data_multi_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'dynamic_read_data_multi_burst_length_runtime_assertion';
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic burst-length read-data keeps r0 generated RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic burst-length read-data keeps r1 generated RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multiple dynamic burst-length read-data declares ARLEN input');
        like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data allocates r0 raw ARLEN storage');
        like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data allocates r1 raw ARLEN storage');
        like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'multiple dynamic burst-length read-data captures r0 raw ARLEN under request');
        like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'multiple dynamic burst-length read-data captures r1 raw ARLEN under request');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'multiple dynamic burst-length read-data keeps r0 payload capture under generated completion');
        like($isf, qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/, 'multiple dynamic burst-length read-data keeps r1 payload capture under generated completion');
        if ($runtime_validation) {
            for my $tx (qw(r0 r1)) {
                like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "multiple dynamic runtime burst-length declares $tx expected-beat storage");
                like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "multiple dynamic runtime burst-length declares $tx beat-count storage");
                like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "multiple dynamic runtime burst-length initializes $tx expected count on request");
                like($isf, qr/\(rule axi0_${tx}_read_beat_count \(& \(& axi0_read_complete \(& axi0_${tx}_dynamic_busy_q \(== axi0_rid axi0_${tx}_dynamic_id_q\)\)\) \(! axi0_${tx}_request\)\)\s+\(axi0_${tx}_read_beat_count_q \(\+ axi0_${tx}_read_beat_count_q 5'd1\)\)\)/, "multiple dynamic runtime burst-length increments $tx on matched RID beat");
                like($isf, qr/axi0 $tx ARLEN is within configured max beats/, "multiple dynamic runtime burst-length emits $tx ARLEN bound assertion");
                like($isf, qr/axi0 $tx RLAST appears only on the expected final read beat/, "multiple dynamic runtime burst-length emits $tx early-RLAST assertion");
                like($isf, qr/axi0 $tx expected final read beat has RLAST/, "multiple dynamic runtime burst-length emits $tx missing-RLAST assertion");
            }
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'multiple dynamic report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_dynamic_read_multi_rlast_report($result->{report});
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
            [qw(r0 r1)],
        );
        like($fsm, qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers r1 multiple dynamic raw ARLEN capture');
        like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps r1 multiple dynamic payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r1_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers r1 multiple dynamic expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers r1 multiple dynamic beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes multiple dynamic ARLEN');
        like($hdl, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 multiple dynamic ARLEN capture by request');
        like($hdl, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures r1 multiple dynamic raw ARLEN');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_expected_beats_q\b/, 'SystemVerilog declares r1 multiple dynamic expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_read_beat_count_q\b/, 'SystemVerilog declares r1 multiple dynamic beat-count storage');
            like($hdl, qr/assign\s+axi0_r1_beat_count_init_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 multiple dynamic beat-count init by request');
            like($hdl, qr/assign\s+axi0_r1_read_beat_count_en\s*=/, 'SystemVerilog emits r1 multiple dynamic beat-count increment enable');
            like($hdl, qr/axi0_r1_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes r1 multiple dynamic expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps multiple dynamic report-only burst-length free of runtime validation');
        }
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'mixed multi-beat read-data keeps dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'mixed multi-beat read-data keeps static RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'mixed multi-beat read-data declares ARLEN input');
        like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'mixed multi-beat read-data declares first dynamic RDATA lane');
        like($isf, qr/\(output axi0_r1_beat_rdata_15 \(width 32\)\)/, 'mixed multi-beat read-data declares final static RDATA lane');
        like($isf, qr/\(output axi0_r1_beat_rresp_15 \(width 2\)\)/, 'mixed multi-beat read-data declares final static RRESP lane');
        like($isf, qr/\(output axi0_r1_beat_valid \(width 16\)\)/, 'mixed multi-beat read-data declares static valid-mask output');
        like($isf, qr/\(output axi0_r1_read_beats \(width 5\)\)/, 'mixed multi-beat read-data declares static length output');
        like($isf, qr/\(output axi0_r1_rresp \(width 2\)\)/, 'mixed multi-beat read-data declares static scalar aggregate RRESP output');
        like($isf, qr/\(rule axi0_r1_read_data_output_init axi0_r1_request\s+\(axi0_r1_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r1_beat_valid 16'b0\)\s+\(axi0_r1_read_beats 5'd0\)\)/, 'mixed multi-beat read-data clears static output bank on request');
        like($isf, qr/\(rule axi0_r1_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(axi0_r1_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r1_beat_valid 16'b0000000000000001\)\s+\(axi0_r1_read_beats 5'd1\)\)/, 'mixed multi-beat read-data captures static first matched beat lane');
        like($isf, qr/\(rule axi0_r1_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'mixed multi-beat read-data updates static scalar RRESP aggregate on worse status');
        assert_mixed_dynamic_static_read_rlast_report($result->{report});
        assert_dynamic_read_data_multi_beat_report(
            $result->{report}{read_data},
            [qw(r0 r1)],
            'generated_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'mixed multi-beat read-data removes read-data interleaving and burst residue from demux report');
        like($fsm, qr/\(-axi0_r1_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r1_beat_rdata_0> axi0_rdata\)\)/, 'scheduled FSM lowers mixed static first-beat lane capture');
        like($fsm, qr/\(-axi0_r1_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'scheduled FSM lowers mixed static scalar RRESP aggregation');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_beat_rdata_0\b/, 'SystemVerilog exposes static first mixed multi-beat RDATA lane');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_beat_rresp_15\b/, 'SystemVerilog exposes static final mixed multi-beat RRESP lane');
        like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r1_beat_valid\b/, 'SystemVerilog exposes static mixed multi-beat valid mask');
        like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r1_read_beats\b/, 'SystemVerilog exposes static mixed multi-beat length');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_rresp\b/, 'SystemVerilog exposes static mixed scalar RRESP aggregate');
        like($hdl, qr/assign\s+axi0_r1_read_beat_0_capture_en\s*=/, 'SystemVerilog emits static first-lane capture enable');
        like($hdl, qr/axi0_r1_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures static first-lane RDATA');
        like($hdl, qr/axi0_r1_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog captures static valid mask for first beat');
        like($hdl, qr/axi0_r1_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog captures static length for first beat');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_dynamic_multi_beat') {
        my @transactions = qw(r0 r1 r2);

        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed multi-beat read-data keeps first dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multi-dynamic mixed multi-beat read-data keeps second dynamic RID/RLAST demux');
        like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete axi0_r2_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'multi-dynamic mixed multi-beat read-data keeps static RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-dynamic mixed multi-beat read-data declares ARLEN input');
        like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multi-dynamic mixed multi-beat read-data declares first dynamic RDATA lane');
        like($isf, qr/\(output axi0_r1_beat_rdata_15 \(width 32\)\)/, 'multi-dynamic mixed multi-beat read-data declares final second dynamic RDATA lane');
        like($isf, qr/\(output axi0_r2_beat_rresp_15 \(width 2\)\)/, 'multi-dynamic mixed multi-beat read-data declares final static RRESP lane');
        like($isf, qr/\(output axi0_r2_beat_valid \(width 16\)\)/, 'multi-dynamic mixed multi-beat read-data declares static valid-mask output');
        like($isf, qr/\(output axi0_r2_read_beats \(width 5\)\)/, 'multi-dynamic mixed multi-beat read-data declares static length output');
        like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'multi-dynamic mixed multi-beat read-data declares static scalar aggregate RRESP output');
        for my $tx (@transactions) {
            like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "multi-dynamic mixed multi-beat read-data allocates $tx raw ARLEN storage");
            like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "multi-dynamic mixed multi-beat read-data declares $tx expected-beat storage");
            like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "multi-dynamic mixed multi-beat read-data declares $tx beat-count storage");
        }
        like($isf, qr/\(rule axi0_r2_read_data_output_init axi0_r2_request\s+\(axi0_r2_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r2_beat_valid 16'b0\)\s+\(axi0_r2_read_beats 5'd0\)\)/, 'multi-dynamic mixed multi-beat read-data clears static output bank on request');
        like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)\s+\(axi0_r0_beat_rdata_0 axi0_rdata\)/, 'multi-dynamic mixed multi-beat read-data captures first dynamic first matched beat lane');
        like($isf, qr/\(rule axi0_r1_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(axi0_r1_beat_rdata_0 axi0_rdata\)/, 'multi-dynamic mixed multi-beat read-data captures second dynamic first matched beat lane');
        like($isf, qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)\s+\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)\s+\(axi0_r2_read_beats 5'd1\)\)/, 'multi-dynamic mixed multi-beat read-data captures static first matched beat lane');
        like($isf, qr/\(rule axi0_r2_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)/, 'multi-dynamic mixed multi-beat read-data updates static scalar RRESP aggregate on worse status');
        assert_mixed_dynamic_static_read_rlast_multi_dynamic_report($result->{report});
        assert_dynamic_read_data_multi_beat_report(
            $result->{report}{read_data},
            \@transactions,
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'multi-dynamic mixed multi-beat read-data removes read-data interleaving and burst residue from demux report');
        like($fsm, qr/\(-axi0_r1_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r1_beat_rdata_0> axi0_rdata\)\)/, 'scheduled FSM lowers second dynamic first-beat lane capture');
        like($fsm, qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)/, 'scheduled FSM lowers static first-beat lane capture');
        like($fsm, qr/\(-axi0_r2_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r2_static_busy_q \(== axi0_rid 4'd3\)\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)/, 'scheduled FSM lowers static scalar RRESP aggregation');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_beat_rdata_0\b/, 'SystemVerilog exposes second dynamic first multi-beat RDATA lane');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_beat_rresp_15\b/, 'SystemVerilog exposes second dynamic final multi-beat RRESP lane');
        like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, 'SystemVerilog exposes static multi-beat valid mask');
        like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r2_read_beats\b/, 'SystemVerilog exposes static multi-beat length');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'SystemVerilog exposes static scalar RRESP aggregate');
        like($hdl, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, 'SystemVerilog emits static first-lane capture enable');
        like($hdl, qr/axi0_r2_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures static first-lane RDATA');
        like($hdl, qr/axi0_r2_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog captures static valid mask for first beat');
        like($hdl, qr/axi0_r2_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog captures static length for first beat');
        return;
    }

    if ($case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static_multi_beat'
        || $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_multi_beat') {
        my @static_cases = $case->{behavior} eq 'mixed_dynamic_static_read_data_multi_static3_multi_beat'
            ? (
                { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
                { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
                { transaction => 'r3', value => 7, literal => "4'd7", label => 'third' },
            )
            : (
                { transaction => 'r1', value => 3, literal => "4'd3", label => 'first' },
                { transaction => 'r2', value => 5, literal => "4'd5", label => 'second' },
            );
        my @transactions = ('r0', map { $_->{transaction} } @static_cases);
        my $last_static = $static_cases[-1];
        my $last_tx = $last_static->{transaction};
        my $last_literal = quotemeta($last_static->{literal});
        my $last_label = $last_static->{label};

        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multi-static mixed multi-beat read-data keeps dynamic RID/RLAST demux');
        for my $static_case (@static_cases) {
            my $transaction = $static_case->{transaction};
            my $literal = quotemeta($static_case->{literal});
            my $label = $static_case->{label};
            like($isf, qr/\(rule axi0_${transaction}_response_demux \(& axi0_read_complete axi0_${transaction}_static_busy_q \(== axi0_rid $literal\) axi0_rlast\)/, "multi-static mixed multi-beat read-data keeps $label static RID/RLAST demux");
        }
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-static mixed multi-beat read-data declares ARLEN input');
        like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multi-static mixed multi-beat read-data declares first dynamic RDATA lane');
        like($isf, qr/\(output axi0_${last_tx}_beat_rdata_15 \(width 32\)\)/, "multi-static mixed multi-beat read-data declares final $last_label static RDATA lane");
        like($isf, qr/\(output axi0_${last_tx}_beat_rresp_15 \(width 2\)\)/, "multi-static mixed multi-beat read-data declares final $last_label static RRESP lane");
        like($isf, qr/\(output axi0_${last_tx}_beat_valid \(width 16\)\)/, "multi-static mixed multi-beat read-data declares $last_label static valid-mask output");
        like($isf, qr/\(output axi0_${last_tx}_read_beats \(width 5\)\)/, "multi-static mixed multi-beat read-data declares $last_label static length output");
        like($isf, qr/\(output axi0_${last_tx}_rresp \(width 2\)\)/, "multi-static mixed multi-beat read-data declares $last_label static scalar aggregate RRESP output");
        for my $tx (@transactions) {
            like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "multi-static mixed multi-beat read-data allocates $tx raw ARLEN storage");
            like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "multi-static mixed multi-beat read-data declares $tx expected-beat storage");
            like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "multi-static mixed multi-beat read-data declares $tx beat-count storage");
        }
        like($isf, qr/\(rule axi0_${last_tx}_read_data_output_init axi0_${last_tx}_request\s+\(axi0_${last_tx}_beat_rdata_0 32'd0\)[\s\S]*\(axi0_${last_tx}_beat_valid 16'b0\)\s+\(axi0_${last_tx}_read_beats 5'd0\)\)/, "multi-static mixed multi-beat read-data clears $last_label static output bank on request");
        like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)\s+\(axi0_r0_beat_rdata_0 axi0_rdata\)/, 'multi-static mixed multi-beat read-data captures dynamic first matched beat lane');
        like($isf, qr/\(rule axi0_${last_tx}_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_${last_tx}_static_busy_q \(== axi0_rid $last_literal\)\)\) \(! axi0_${last_tx}_request\) \(== axi0_${last_tx}_read_beat_count_q 5'd0\)\)\s+\(axi0_${last_tx}_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_${last_tx}_beat_valid 16'b0000000000000001\)\s+\(axi0_${last_tx}_read_beats 5'd1\)\)/, "multi-static mixed multi-beat read-data captures $last_label static first matched beat lane");
        like($isf, qr/\(rule axi0_${last_tx}_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_${last_tx}_static_busy_q \(== axi0_rid $last_literal\)\)\) \(! axi0_${last_tx}_request\) \(< axi0_${last_tx}_rresp axi0_rresp\)\)/, "multi-static mixed multi-beat read-data updates $last_label static scalar RRESP aggregate on worse status");
        assert_mixed_dynamic_static_read_rlast_multi_static_report($result->{report}, \@static_cases);
        assert_dynamic_read_data_multi_beat_report(
            $result->{report}{read_data},
            \@transactions,
            'generated_multi_mixed_dynamic_static_read_response_demux_last_beat_completion_pulse',
        );
        is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'multi-static mixed multi-beat read-data removes read-data interleaving and burst residue from demux report');
        like($fsm, qr/\(-axi0_${last_tx}_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_${last_tx}_static_busy_q \(== axi0_rid $last_literal\)\)\) \(! axi0_${last_tx}_request\) \(== axi0_${last_tx}_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_${last_tx}_beat_rdata_0> axi0_rdata\)\)/, "scheduled FSM lowers multi-static $last_label static first-beat lane capture");
        like($fsm, qr/\(-axi0_${last_tx}_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_${last_tx}_static_busy_q \(== axi0_rid $last_literal\)\)\) \(! axi0_${last_tx}_request\) \(< axi0_${last_tx}_rresp axi0_rresp\)\)/, "scheduled FSM lowers multi-static $last_label static scalar RRESP aggregation");
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_${last_tx}_beat_rdata_0\b/, "SystemVerilog exposes $last_label static first multi-beat RDATA lane");
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${last_tx}_beat_rresp_15\b/, "SystemVerilog exposes $last_label static final multi-beat RRESP lane");
        like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_${last_tx}_beat_valid\b/, "SystemVerilog exposes $last_label static multi-beat valid mask");
        like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_${last_tx}_read_beats\b/, "SystemVerilog exposes $last_label static multi-beat length");
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${last_tx}_rresp\b/, "SystemVerilog exposes $last_label static scalar RRESP aggregate");
        like($hdl, qr/assign\s+axi0_${last_tx}_read_beat_0_capture_en\s*=/, "SystemVerilog emits $last_label static first-lane capture enable");
        like($hdl, qr/axi0_${last_tx}_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, "SystemVerilog captures $last_label static first-lane RDATA");
        like($hdl, qr/axi0_${last_tx}_beat_valid_next\s*=\s*16'b1\s*;/, "SystemVerilog captures $last_label static valid mask for first beat");
        like($hdl, qr/axi0_${last_tx}_read_beats_next\s*=\s*5'd1\s*;/, "SystemVerilog captures $last_label static length for first beat");
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_burst_length'
        || $case->{behavior} eq 'dynamic_read_data_burst_length_runtime_assertion') {
        my $runtime_validation = $case->{behavior} eq 'dynamic_read_data_burst_length_runtime_assertion';
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic burst-length read-data keeps generated RID/RLAST demux');
        like($isf, qr/\(input axi0_rlast\)/, 'dynamic burst-length read-data declares RLAST input');
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic burst-length read-data declares RDATA input');
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic burst-length read-data declares RRESP input');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'dynamic burst-length read-data declares ARLEN input');
        like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'dynamic burst-length read-data allocates raw ARLEN storage');
        like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'dynamic burst-length read-data captures raw ARLEN under request');
        like($isf, qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/, 'dynamic burst-length read-data keeps payload capture under generated completion');
        if ($runtime_validation) {
            like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'dynamic runtime burst-length declares expected-beat storage');
            like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'dynamic runtime burst-length declares beat-count storage');
            like($isf, qr/\(rule axi0_r0_beat_count_init axi0_r0_request\s+\(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r0_read_beat_count_q 0\)\)/, 'dynamic runtime burst-length initializes expected count on request');
            like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'dynamic runtime burst-length increments on matched RID beat before RLAST');
            like($isf, qr/axi0 r0 ARLEN is within configured max beats/, 'dynamic runtime burst-length emits ARLEN bound assertion');
            like($isf, qr/axi0 r0 RLAST appears only on the expected final read beat/, 'dynamic runtime burst-length emits early-RLAST assertion');
            like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'dynamic runtime burst-length emits missing-RLAST assertion');
        } else {
            unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'dynamic report-only burst-length emits no runtime beat-count state or assertions');
        }
        assert_dynamic_read_rlast_report($result->{report});
        assert_dynamic_read_data_burst_length_report(
            $result->{report}{read_data},
            $runtime_validation ? 'runtime_assertion' : 'report_only',
        );
        like($fsm, qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled FSM lowers dynamic raw ARLEN capture');
        like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/, 'scheduled FSM keeps dynamic payload capture');
        if ($runtime_validation) {
            like($fsm, qr/\(<- \(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled FSM lowers dynamic expected-beat initialization');
            like($fsm, qr/\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'scheduled FSM lowers dynamic beat-count increment');
        }
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes ARLEN');
        like($hdl, qr/assign\s+axi0_r0_burst_length_capture_en\s*=\s*axi0_r0_request\s*;/, 'SystemVerilog guards dynamic ARLEN capture by request');
        like($hdl, qr/axi0_r0_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures dynamic raw ARLEN');
        like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog still guards dynamic last-beat payload capture by completion');
        if ($runtime_validation) {
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'SystemVerilog declares dynamic expected-beat storage');
            like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'SystemVerilog declares dynamic beat-count storage');
            like($hdl, qr/assign\s+axi0_r0_read_beat_count_en\s*=/, 'SystemVerilog emits dynamic beat-count increment enable');
            like($hdl, qr/axi0_r0_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes dynamic expected count from ARLEN+1');
        } else {
            unlike($hdl, qr/arlen_within_max|read_beat_count|expected_beats/, 'SystemVerilog keeps dynamic report-only burst-length free of runtime validation');
        }
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_multi_transaction_multi_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic multi-beat read-data keeps generated r0 RID/RLAST demux');
        like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic multi-beat read-data keeps generated r1 RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multiple dynamic multi-beat read-data declares ARLEN input');
        like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multiple dynamic multi-beat read-data declares first r0 RDATA lane');
        like($isf, qr/\(output axi0_r1_beat_rdata_15 \(width 32\)\)/, 'multiple dynamic multi-beat read-data declares final r1 RDATA lane');
        like($isf, qr/\(output axi0_r1_beat_rresp_15 \(width 2\)\)/, 'multiple dynamic multi-beat read-data declares final r1 RRESP lane');
        like($isf, qr/\(output axi0_r1_beat_valid \(width 16\)\)/, 'multiple dynamic multi-beat read-data declares r1 valid-mask output');
        like($isf, qr/\(output axi0_r1_read_beats \(width 5\)\)/, 'multiple dynamic multi-beat read-data declares r1 length output');
        like($isf, qr/\(output axi0_r1_rresp \(width 2\)\)/, 'multiple dynamic multi-beat read-data declares r1 scalar aggregate RRESP output');
        like($isf, qr/\(rule axi0_r1_read_data_output_init axi0_r1_request\s+\(axi0_r1_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r1_beat_valid 16'b0\)\s+\(axi0_r1_read_beats 5'd0\)\)/, 'multiple dynamic multi-beat read-data clears r1 output bank on request');
        like($isf, qr/\(rule axi0_r1_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(axi0_r1_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r1_beat_valid 16'b0000000000000001\)\s+\(axi0_r1_read_beats 5'd1\)\)/, 'multiple dynamic multi-beat read-data captures r1 first matched beat lane');
        like($isf, qr/\(rule axi0_r1_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'multiple dynamic multi-beat read-data updates r1 scalar RRESP aggregate on worse status');
        assert_dynamic_read_multi_rlast_report($result->{report});
        assert_dynamic_read_data_multi_beat_report($result->{report}{read_data}, [qw(r0 r1)]);
        is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'multiple dynamic multi-beat read-data removes read-data interleaving and burst residue from demux report');
        like($fsm, qr/\(-axi0_r1_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r1_beat_rdata_0> axi0_rdata\)\)/, 'scheduled FSM lowers multiple dynamic first-beat r1 lane capture');
        like($fsm, qr/\(-axi0_r1_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'scheduled FSM lowers multiple dynamic r1 scalar RRESP aggregation');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_beat_rdata_0\b/, 'SystemVerilog exposes r1 first multiple dynamic multi-beat RDATA lane');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_beat_rresp_15\b/, 'SystemVerilog exposes r1 final multiple dynamic multi-beat RRESP lane');
        like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r1_beat_valid\b/, 'SystemVerilog exposes r1 multiple dynamic multi-beat valid mask');
        like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r1_read_beats\b/, 'SystemVerilog exposes r1 multiple dynamic multi-beat length');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_rresp\b/, 'SystemVerilog exposes r1 multiple dynamic scalar RRESP aggregate');
        like($hdl, qr/assign\s+axi0_r1_read_beat_0_capture_en\s*=/, 'SystemVerilog emits r1 first-lane capture enable');
        like($hdl, qr/axi0_r1_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 first-lane RDATA');
        like($hdl, qr/axi0_r1_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog captures r1 valid mask for first beat');
        like($hdl, qr/axi0_r1_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog captures r1 length for first beat');
        return;
    }

    if ($case->{behavior} eq 'dynamic_read_data_multi_beat') {
        like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic multi-beat read-data keeps generated RID/RLAST demux');
        like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'dynamic multi-beat read-data declares ARLEN input');
        like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'dynamic multi-beat read-data declares first RDATA lane');
        like($isf, qr/\(output axi0_r0_beat_rresp_15 \(width 2\)\)/, 'dynamic multi-beat read-data declares final RRESP lane');
        like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'dynamic multi-beat read-data declares valid-mask output');
        like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'dynamic multi-beat read-data declares length output');
        like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'dynamic multi-beat read-data declares scalar aggregate RRESP output');
        like($isf, qr/\(rule axi0_r0_read_data_output_init axi0_r0_request\s+\(axi0_r0_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r0_beat_valid 16'b0\)\s+\(axi0_r0_read_beats 5'd0\)\)/, 'dynamic multi-beat read-data clears output bank on request');
        like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)\s+\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)\s+\(axi0_r0_read_beats 5'd1\)\)/, 'dynamic multi-beat read-data captures first matched beat lane');
        like($isf, qr/\(rule axi0_r0_read_beat_15_capture \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd15\)\)[\s\S]*\(axi0_r0_beat_rresp_15 axi0_rresp\)\s+\(axi0_r0_beat_valid 16'b1111111111111111\)\s+\(axi0_r0_read_beats 5'd16\)\)/, 'dynamic multi-beat read-data captures final matched beat lane');
        like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)/, 'dynamic multi-beat read-data updates scalar RRESP aggregate on worse status');
        assert_dynamic_read_rlast_report($result->{report});
        assert_dynamic_read_data_multi_beat_report($result->{report}{read_data});
        is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'dynamic multi-beat read-data removes read-data interleaving and burst residue from demux report');
        like($fsm, qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r0_beat_rdata_0> axi0_rdata\)\)/, 'scheduled FSM lowers dynamic first-beat lane capture');
        like($fsm, qr/\(-axi0_r0_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)/, 'scheduled FSM lowers dynamic scalar RRESP aggregation');
        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_beat_rdata_0\b/, 'SystemVerilog exposes first dynamic multi-beat RDATA lane');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_beat_rresp_15\b/, 'SystemVerilog exposes final dynamic multi-beat RRESP lane');
        like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r0_beat_valid\b/, 'SystemVerilog exposes dynamic multi-beat valid mask');
        like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r0_read_beats\b/, 'SystemVerilog exposes dynamic multi-beat length');
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'SystemVerilog exposes dynamic scalar RRESP aggregate');
        like($hdl, qr/assign\s+axi0_r0_read_beat_0_capture_en\s*=/, 'SystemVerilog emits first-lane capture enable');
        like($hdl, qr/axi0_r0_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures dynamic first-lane RDATA');
        like($hdl, qr/axi0_r0_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog captures dynamic valid mask for first beat');
        like($hdl, qr/axi0_r0_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog captures dynamic length for first beat');
        like($hdl, qr/assign\s+axi0_r0_rresp_aggregate_en\s*=/, 'SystemVerilog emits scalar RRESP aggregate enable');
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

sub assert_dynamic_same_id_issue_order_queue_metadata {
    my ($ordering) = @_;

    is($ordering->{mode}, 'dynamic_id_reuse_policy', 'dynamic issue-order queue metadata reports dynamic policy mode');
    ok(!$ordering->{generated_behavior}, 'dynamic issue-order queue metadata is not generated behavior');
    ok(!exists($ordering->{families}), 'dynamic issue-order queue metadata does not report generated same-ID families');
    is_deeply(
        $ordering->{residue},
        [qw(dynamic_id_same_id_ordering dynamic_per_id_issue_order_queues)],
        'dynamic issue-order queue metadata keeps dynamic queue residue explicit',
    );
    is_deeply(
        [sort keys %{$ordering->{dynamic_id_reuse_policy}}],
        ['read'],
        'dynamic issue-order queue metadata reports the selected read family',
    );
    is_deeply(
        $ordering->{dynamic_id_reuse_policy}{read},
        {
            policy                       => 'issue_order_queue',
            implementation_status        => 'selected_not_generated',
            enforcement                  => 'not_generated',
            accepted_same_id_reuse       => JSON::PP::false(),
            request_conflict_policy      => 'dynamic_issue_order_queue_selected_not_generated',
            generated_queue_behavior     => JSON::PP::false(),
            generated_scoreboard_behavior => JSON::PP::false(),
        },
        'dynamic issue-order queue metadata reports selected-not-generated policy fields',
    );
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
    is_deeply($write->{generated_assertions}, [qw(axi0_w0_dynamic_request_idle_or_releasing axi0_write_dynamic_response_active_match axi0_w0_dynamic_completion_active)], 'dynamic write report names generated assertions');
    is_deeply(
        $write->{dynamic_capture},
        {
            request_id_source    => 'axi0_awid',
            capture_event_source => 'admitted_dynamic_write_request',
            ownership            => 'single_active_dynamic_write',
            selected_id_signal   => 'axi0_w0_dynamic_id_q',
            busy_signal          => 'axi0_w0_dynamic_busy_q',
            capture_rule         => 'axi0_w0_dynamic_id_capture',
            release_rule         => 'axi0_w0_dynamic_id_release',
            release_recapture_rule => 'axi0_w0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_write',
            release_recapture_source => 'generated_dynamic_demux_completion',
            release_recapture_transaction => 'w0',
        },
        'dynamic write report names single-active release-recapture update ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic write transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic write demux keeps future dynamic residue visible');
}

sub assert_dynamic_write_multi_report {
    my ($report) = @_;
    my $write = $report->{response_demux}{write};

    is($report->{response_demux}{mode}, 'bounded_multi_dynamic_write_bid_demux_contract', 'multiple dynamic write report marks multi BID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multiple dynamic write report marks generated demux behavior');
    is($write->{mode}, 'bounded_multi_dynamic_write_bid_demux_contract', 'multiple dynamic write report marks write mode');
    is($write->{transaction_completion_source}, 'generated_dynamic_demux', 'multiple dynamic write report marks generated completion source');
    is($write->{transaction_completion_semantics}, 'matched_dynamic_id', 'multiple dynamic write report marks matched dynamic ID completion');
    is_deeply($write->{dynamic_transactions}, [qw(w0 w1)], 'multiple dynamic write report names covered dynamic transactions');
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], 'multiple dynamic write report names generated response-demux rules');
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], 'multiple dynamic write report names generated completions');
    is_deeply(
        $write->{generated_assertions},
        [qw(
            axi0_w0_dynamic_request_idle_or_releasing
            axi0_w1_dynamic_request_idle_or_releasing
            axi0_write_dynamic_request_onehot0
            axi0_w0_dynamic_request_no_active_same_id
            axi0_w1_dynamic_request_no_active_same_id
            axi0_w0_w1_write_dynamic_active_id_unique
            axi0_write_dynamic_response_active_match
            axi0_w0_w1_write_dynamic_response_unique_match
            axi0_w0_dynamic_completion_active
            axi0_w1_dynamic_completion_active
        )],
        'multiple dynamic write report names generated assertions',
    );
    is_deeply(
        $write->{dynamic_capture},
        {
            request_id_source           => 'axi0_awid',
            capture_event_source        => 'admitted_dynamic_write_request',
            ownership                   => 'multi_active_unique_dynamic_write_ids',
            simultaneous_request_policy => 'onehot0_dynamic_write_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            transactions                => [
                {
                    transaction        => 'w0',
                    selected_id_signal => 'axi0_w0_dynamic_id_q',
                    busy_signal        => 'axi0_w0_dynamic_busy_q',
                    capture_rule       => 'axi0_w0_dynamic_id_capture',
                    release_rule       => 'axi0_w0_dynamic_id_release',
                    release_recapture_rule => 'axi0_w0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_write',
                    release_recapture_source => 'generated_dynamic_demux_completion',
                    release_recapture_transaction => 'w0',
                },
                {
                    transaction        => 'w1',
                    selected_id_signal => 'axi0_w1_dynamic_id_q',
                    busy_signal        => 'axi0_w1_dynamic_busy_q',
                    capture_rule       => 'axi0_w1_dynamic_id_capture',
                    release_rule       => 'axi0_w1_dynamic_id_release',
                    release_recapture_rule => 'axi0_w1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_write',
                    release_recapture_source => 'generated_dynamic_demux_completion',
                    release_recapture_transaction => 'w1',
                },
            ],
        },
        'multiple dynamic write report describes per-transaction dynamic capture',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        'multiple dynamic write transactions report generated capture/matching',
    );
    assert_dynamic_residue($report, 'multiple dynamic write demux keeps future dynamic residue visible');
}

sub assert_dynamic_write_same_id_issue_order_queue_report {
    my ($report) = @_;
    my $demux = $report->{response_demux};
    my $write = $demux->{write};
    my $ordering = $report->{same_id_ordering};
    my $policy = $ordering->{dynamic_id_reuse_policy}{write};
    my $queue = $policy->{generated_queues}[0];

    is($demux->{mode}, 'bounded_dynamic_write_bid_issue_order_queue_demux_contract', 'dynamic write issue-order queue report marks demux contract');
    ok($demux->{generated_behavior}, 'dynamic write issue-order queue report marks generated demux behavior');
    is_deeply($demux->{residue}, [qw(read_response_demux read_data_interleaving bursts)], 'dynamic write issue-order queue removes same-ID residue from response demux');
    is($write->{transaction_completion_source}, 'generated_dynamic_issue_order_queue_demux', 'dynamic write issue-order queue report marks generated queue completion source');
    is($write->{transaction_completion_semantics}, 'earliest_matching_captured_runtime_id', 'dynamic write issue-order queue report marks earliest matching semantics');
    is($write->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic write issue-order queue report marks compact runtime-ID slots');
    is($write->{runtime_id_queue_key}, 'captured_request_id', 'dynamic write issue-order queue report marks captured request ID key');
    is($write->{response_demux_strategy}, 'dynamic_issue_order_earliest_matching_slot', 'dynamic write issue-order queue report marks earliest matching strategy');
    is_deeply($write->{dynamic_transactions}, [qw(w0 w1)], 'dynamic write issue-order queue report names covered dynamic writes');
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], 'dynamic write issue-order queue report names generated response-demux rules');
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], 'dynamic write issue-order queue report names generated completions');
    is_deeply($write->{generated_assertions}, [qw(axi0_write_response_demux_active_match axi0_w0_w1_write_response_demux_unique_match)], 'dynamic write issue-order queue report names response-demux assertions');
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_issue_order_queue_matching generated_issue_order_queue_matching)],
        'dynamic write issue-order queue transactions report generated queue matching',
    );

    is($ordering->{mode}, 'dynamic_id_reuse_policy', 'dynamic write issue-order queue same-ID report marks dynamic mode');
    ok($ordering->{generated_behavior}, 'dynamic write issue-order queue same-ID report is generated');
    is_deeply($ordering->{residue}, [], 'dynamic write issue-order queue same-ID report clears dynamic residue');
    is($policy->{implementation_status}, 'generated_dynamic_write_bid_issue_order_queue', 'dynamic write issue-order queue policy reports generated implementation');
    is($policy->{enforcement}, 'generated_dynamic_issue_order_queue', 'dynamic write issue-order queue policy reports generated enforcement');
    ok($policy->{accepted_same_id_reuse}, 'dynamic write issue-order queue policy accepts same-ID reuse');
    ok($policy->{generated_queue_behavior}, 'dynamic write issue-order queue policy marks generated queue behavior');
    ok($policy->{dynamic_issue_order_queue_covered}, 'dynamic write issue-order queue policy marks dynamic coverage');
    is_deeply($policy->{covered_dynamic_transactions}, [qw(w0 w1)], 'dynamic write issue-order queue policy names covered transactions');
    is($policy->{active_id_uniqueness_policy}, 'not_required_for_issue_order_queue', 'dynamic write issue-order queue policy does not require active ID uniqueness');

    is($queue->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic write issue-order queue report names queue representation');
    is($queue->{request_id_source}, 'axi0_awid', 'dynamic write issue-order queue report names AWID capture source');
    is_deeply($queue->{transactions}, [qw(w0 w1)], 'dynamic write issue-order queue report names queue transactions');
    is_deeply(
        $queue->{slot_storage},
        [
            { name => 'axi0_write_dynamic_same_id_issue_order_slot0_w0_q', width => 1 },
            { name => 'axi0_write_dynamic_same_id_issue_order_slot0_w1_q', width => 1 },
            { name => 'axi0_write_dynamic_same_id_issue_order_slot0_id_q', width => 4 },
            { name => 'axi0_write_dynamic_same_id_issue_order_slot1_w0_q', width => 1 },
            { name => 'axi0_write_dynamic_same_id_issue_order_slot1_w1_q', width => 1 },
            { name => 'axi0_write_dynamic_same_id_issue_order_slot1_id_q', width => 4 },
        ],
        'dynamic write issue-order queue report names slot-local transaction and ID storage',
    );
    is_deeply(
        $queue->{generated_assertions},
        [qw(
            axi0_write_dynamic_same_id_issue_order_slot0_onehot0
            axi0_write_dynamic_same_id_issue_order_slot1_onehot0
            axi0_write_dynamic_same_id_issue_order_compact
            axi0_write_dynamic_same_id_issue_order_request_onehot0
            axi0_write_dynamic_same_id_issue_order_enqueue_requires_space_or_dequeue
            axi0_write_dynamic_same_id_issue_order_response_requires_nonempty
            axi0_write_dynamic_same_id_issue_order_response_has_selected_match
            axi0_write_dynamic_same_id_issue_order_response_selected_match_onehot0
            axi0_write_dynamic_same_id_issue_order_dequeue_requires_nonempty
            axi0_write_dynamic_same_id_issue_order_w0_unique_slot
            axi0_write_dynamic_same_id_issue_order_w0_no_duplicate_after_dequeue
            axi0_write_dynamic_same_id_issue_order_w0_completion_selected_match
            axi0_write_dynamic_same_id_issue_order_w1_unique_slot
            axi0_write_dynamic_same_id_issue_order_w1_no_duplicate_after_dequeue
            axi0_write_dynamic_same_id_issue_order_w1_completion_selected_match
        )],
        'dynamic write issue-order queue report names generated queue assertions',
    );
    ok(grep { $_ eq 'axi0_write_dynamic_same_id_issue_order_w0_w1_dequeue_enqueue_w0' } @{$queue->{generated_update_rules}}, 'dynamic write issue-order queue reports same-cycle selected dequeue plus enqueue rule');
    assert_dynamic_residue($report, 'dynamic write issue-order queue keeps future dynamic residue visible');
}

sub assert_dynamic_read_same_id_issue_order_queue_report {
    my ($report) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};
    my $ordering = $report->{same_id_ordering};
    my $policy = $ordering->{dynamic_id_reuse_policy}{read};
    my $queue = $policy->{generated_queues}[0];

    is($demux->{mode}, 'bounded_dynamic_read_rid_issue_order_queue_demux_contract', 'dynamic read issue-order queue report marks demux contract');
    ok($demux->{generated_behavior}, 'dynamic read issue-order queue report marks generated demux behavior');
    is_deeply($demux->{residue}, [qw(read_data_interleaving bursts)], 'dynamic read issue-order queue removes same-ID residue from response demux');
    is($read->{response_scope}, 'single_beat', 'dynamic read issue-order queue report marks single-beat response scope');
    is($read->{transaction_completion_source}, 'generated_dynamic_issue_order_queue_demux', 'dynamic read issue-order queue report marks generated queue completion source');
    is($read->{transaction_completion_semantics}, 'earliest_matching_captured_runtime_id', 'dynamic read issue-order queue report marks earliest matching semantics');
    is($read->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic read issue-order queue report marks compact runtime-ID slots');
    is($read->{runtime_id_queue_key}, 'captured_request_id', 'dynamic read issue-order queue report marks captured request ID key');
    is($read->{response_demux_strategy}, 'dynamic_issue_order_earliest_matching_slot', 'dynamic read issue-order queue report marks earliest matching strategy');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'dynamic read issue-order queue report names covered dynamic reads');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'dynamic read issue-order queue report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'dynamic read issue-order queue report names generated completions');
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_issue_order_queue_matching generated_issue_order_queue_matching)],
        'dynamic read issue-order queue transactions report generated queue matching',
    );

    is($ordering->{mode}, 'dynamic_id_reuse_policy', 'dynamic read issue-order queue same-ID report marks dynamic mode');
    ok($ordering->{generated_behavior}, 'dynamic read issue-order queue same-ID report is generated');
    is_deeply($ordering->{residue}, [], 'dynamic read issue-order queue same-ID report clears dynamic residue');
    is($policy->{implementation_status}, 'generated_dynamic_read_rid_issue_order_queue', 'dynamic read issue-order queue policy reports generated implementation');
    is($policy->{enforcement}, 'generated_dynamic_issue_order_queue', 'dynamic read issue-order queue policy reports generated enforcement');
    ok($policy->{accepted_same_id_reuse}, 'dynamic read issue-order queue policy accepts same-ID reuse');
    ok($policy->{generated_queue_behavior}, 'dynamic read issue-order queue policy marks generated queue behavior');
    ok($policy->{dynamic_issue_order_queue_covered}, 'dynamic read issue-order queue policy marks dynamic coverage');
    is_deeply($policy->{covered_dynamic_transactions}, [qw(r0 r1)], 'dynamic read issue-order queue policy names covered transactions');
    is($policy->{first_generated_scope}, 'read_rid_two_dynamic_transactions', 'dynamic read issue-order queue policy reports first generated scope');
    is($policy->{active_id_uniqueness_policy}, 'not_required_for_issue_order_queue', 'dynamic read issue-order queue policy does not require active ID uniqueness');

    is($queue->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic read issue-order queue report names queue representation');
    is($queue->{request_id_source}, 'axi0_arid', 'dynamic read issue-order queue report names ARID capture source');
    is_deeply($queue->{transactions}, [qw(r0 r1)], 'dynamic read issue-order queue report names queue transactions');
    is_deeply(
        $queue->{slot_storage},
        [
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_r0_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_r1_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_id_q', width => 4 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_r0_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_r1_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_id_q', width => 4 },
        ],
        'dynamic read issue-order queue report names slot-local transaction and ID storage',
    );
    is_deeply(
        $queue->{generated_assertions},
        [qw(
            axi0_read_dynamic_same_id_issue_order_slot0_onehot0
            axi0_read_dynamic_same_id_issue_order_slot1_onehot0
            axi0_read_dynamic_same_id_issue_order_compact
            axi0_read_dynamic_same_id_issue_order_request_onehot0
            axi0_read_dynamic_same_id_issue_order_enqueue_requires_space_or_dequeue
            axi0_read_dynamic_same_id_issue_order_response_requires_nonempty
            axi0_read_dynamic_same_id_issue_order_response_has_selected_match
            axi0_read_dynamic_same_id_issue_order_response_selected_match_onehot0
            axi0_read_dynamic_same_id_issue_order_dequeue_requires_nonempty
            axi0_read_dynamic_same_id_issue_order_r0_unique_slot
            axi0_read_dynamic_same_id_issue_order_r0_no_duplicate_after_dequeue
            axi0_read_dynamic_same_id_issue_order_r0_completion_selected_match
            axi0_read_dynamic_same_id_issue_order_r1_unique_slot
            axi0_read_dynamic_same_id_issue_order_r1_no_duplicate_after_dequeue
            axi0_read_dynamic_same_id_issue_order_r1_completion_selected_match
        )],
        'dynamic read issue-order queue report names generated queue assertions',
    );
    ok(grep { $_ eq 'axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0' } @{$queue->{generated_update_rules}}, 'dynamic read issue-order queue reports same-cycle selected dequeue plus enqueue rule');
    assert_dynamic_residue($report, 'dynamic read issue-order queue keeps future dynamic residue visible');
}

sub assert_dynamic_read_burst_last_same_id_issue_order_queue_report {
    my ($report) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};
    my $ordering = $report->{same_id_ordering};
    my $policy = $ordering->{dynamic_id_reuse_policy}{read};
    my $queue = $policy->{generated_queues}[0];

    is($demux->{mode}, 'bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract', 'dynamic read burst-last issue-order queue report marks demux contract');
    ok($demux->{generated_behavior}, 'dynamic read burst-last issue-order queue report marks generated demux behavior');
    is_deeply($demux->{residue}, [qw(read_data_interleaving bursts)], 'dynamic read burst-last issue-order queue removes same-ID residue from response demux');
    is($read->{mode}, 'bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract', 'dynamic read burst-last issue-order queue report marks read mode');
    is($read->{response_scope}, 'burst_last', 'dynamic read burst-last issue-order queue report marks burst-last response scope');
    is($read->{last_signal}, 'axi0_rlast', 'dynamic read burst-last issue-order queue report marks RLAST signal');
    is($read->{last_signal_width}, 1, 'dynamic read burst-last issue-order queue report marks one-bit RLAST');
    is($read->{transaction_completion_source}, 'generated_dynamic_issue_order_queue_demux_last_beat', 'dynamic read burst-last issue-order queue report marks last-beat queue completion source');
    is($read->{transaction_completion_semantics}, 'earliest_matching_captured_runtime_id_and_last_signal', 'dynamic read burst-last issue-order queue report marks earliest matching RID/RLAST semantics');
    is($read->{beat_valid_output}, 'none', 'dynamic read burst-last issue-order queue report marks no beat-valid output');
    is($read->{burst_length_source}, 'rlast_only', 'dynamic read burst-last issue-order queue report marks RLAST-only burst-length source');
    is($read->{burst_length_validation}, 'not_generated', 'dynamic read burst-last issue-order queue report marks deferred burst-length validation');
    is($read->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic read burst-last issue-order queue report marks compact runtime-ID slots');
    is($read->{runtime_id_queue_key}, 'captured_request_id', 'dynamic read burst-last issue-order queue report marks captured request ID key');
    is($read->{response_demux_strategy}, 'dynamic_issue_order_earliest_matching_slot', 'dynamic read burst-last issue-order queue report marks earliest matching strategy');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'dynamic read burst-last issue-order queue report names covered dynamic reads');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'dynamic read burst-last issue-order queue report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'dynamic read burst-last issue-order queue report names generated completions');
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_issue_order_queue_matching generated_issue_order_queue_matching)],
        'dynamic read burst-last issue-order queue transactions report generated queue matching',
    );

    is($ordering->{mode}, 'dynamic_id_reuse_policy', 'dynamic read burst-last issue-order queue same-ID report marks dynamic mode');
    ok($ordering->{generated_behavior}, 'dynamic read burst-last issue-order queue same-ID report is generated');
    is_deeply($ordering->{residue}, [], 'dynamic read burst-last issue-order queue same-ID report clears dynamic residue');
    is($policy->{implementation_status}, 'generated_dynamic_read_rid_rlast_issue_order_queue', 'dynamic read burst-last issue-order queue policy reports generated implementation');
    is($policy->{enforcement}, 'generated_dynamic_issue_order_queue', 'dynamic read burst-last issue-order queue policy reports generated enforcement');
    ok($policy->{accepted_same_id_reuse}, 'dynamic read burst-last issue-order queue policy accepts same-ID reuse');
    ok($policy->{generated_queue_behavior}, 'dynamic read burst-last issue-order queue policy marks generated queue behavior');
    ok($policy->{dynamic_issue_order_queue_covered}, 'dynamic read burst-last issue-order queue policy marks dynamic coverage');
    is_deeply($policy->{covered_dynamic_transactions}, [qw(r0 r1)], 'dynamic read burst-last issue-order queue policy names covered transactions');
    is($policy->{first_generated_scope}, 'read_rid_rlast_two_dynamic_transactions', 'dynamic read burst-last issue-order queue policy reports first generated scope');
    is($policy->{active_id_uniqueness_policy}, 'not_required_for_issue_order_queue', 'dynamic read burst-last issue-order queue policy does not require active ID uniqueness');

    is($queue->{queue_state_representation}, 'compact_runtime_id_issue_order_slots', 'dynamic read burst-last issue-order queue report names queue representation');
    is($queue->{request_id_source}, 'axi0_arid', 'dynamic read burst-last issue-order queue report names ARID capture source');
    is($queue->{response_id_signal}, 'axi0_rid', 'dynamic read burst-last issue-order queue report names RID response source');
    is($queue->{last_signal}, 'axi0_rlast', 'dynamic read burst-last issue-order queue report names RLAST gate');
    is_deeply($queue->{transactions}, [qw(r0 r1)], 'dynamic read burst-last issue-order queue report names queue transactions');
    is_deeply(
        $queue->{slot_storage},
        [
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_r0_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_r1_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot0_id_q', width => 4 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_r0_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_r1_q', width => 1 },
            { name => 'axi0_read_dynamic_same_id_issue_order_slot1_id_q', width => 4 },
        ],
        'dynamic read burst-last issue-order queue report names slot-local transaction and ID storage',
    );
    is_deeply(
        $queue->{generated_assertions},
        [qw(
            axi0_read_dynamic_same_id_issue_order_slot0_onehot0
            axi0_read_dynamic_same_id_issue_order_slot1_onehot0
            axi0_read_dynamic_same_id_issue_order_compact
            axi0_read_dynamic_same_id_issue_order_request_onehot0
            axi0_read_dynamic_same_id_issue_order_enqueue_requires_space_or_dequeue
            axi0_read_dynamic_same_id_issue_order_response_requires_nonempty
            axi0_read_dynamic_same_id_issue_order_response_has_selected_match
            axi0_read_dynamic_same_id_issue_order_response_selected_match_onehot0
            axi0_read_dynamic_same_id_issue_order_dequeue_requires_nonempty
            axi0_read_dynamic_same_id_issue_order_nonlast_no_dequeue
            axi0_read_dynamic_same_id_issue_order_r0_unique_slot
            axi0_read_dynamic_same_id_issue_order_r0_no_duplicate_after_dequeue
            axi0_read_dynamic_same_id_issue_order_r0_completion_selected_match
            axi0_read_dynamic_same_id_issue_order_r1_unique_slot
            axi0_read_dynamic_same_id_issue_order_r1_no_duplicate_after_dequeue
            axi0_read_dynamic_same_id_issue_order_r1_completion_selected_match
        )],
        'dynamic read burst-last issue-order queue report names generated queue assertions',
    );
    ok(grep { $_ eq 'axi0_read_dynamic_same_id_issue_order_r0_r1_dequeue_enqueue_r0' } @{$queue->{generated_update_rules}}, 'dynamic read burst-last issue-order queue reports same-cycle selected dequeue plus enqueue rule');
    assert_dynamic_residue($report, 'dynamic read burst-last issue-order queue keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_write_report {
    my ($report) = @_;
    my $write = $report->{response_demux}{write};

    is($report->{response_demux}{mode}, 'bounded_mixed_dynamic_static_write_bid_demux_contract', 'mixed write report marks mixed BID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'mixed write report marks generated demux behavior');
    is($write->{mode}, 'bounded_mixed_dynamic_static_write_bid_demux_contract', 'mixed write report marks write mode');
    is($write->{transaction_completion_source}, 'generated_mixed_dynamic_static_demux', 'mixed write report marks generated mixed completion source');
    is($write->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id', 'mixed write report marks mixed completion semantics');
    is_deeply($write->{dynamic_transactions}, [qw(w0)], 'mixed write report names covered dynamic transaction');
    is_deeply($write->{static_transactions}, [qw(w1)], 'mixed write report names covered static transaction');
    is_deeply($write->{mixed_transactions}, { dynamic => 'w0', static => 'w1' }, 'mixed write report names dynamic/static transaction roles');
    is_deeply(
        $write->{static_id_reservation},
        {
            transaction            => 'w1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        'mixed write report records static-ID reservation policy',
    );
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], 'mixed write report names generated response-demux rules');
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], 'mixed write report names generated completions');
    is_deeply(
        $write->{generated_assertions},
        [qw(
            axi0_w0_dynamic_request_idle_or_releasing
            axi0_w1_static_request_idle_or_releasing
            axi0_write_mixed_dynamic_static_request_onehot0
            axi0_w0_dynamic_request_not_static_id
            axi0_w0_dynamic_active_not_static_id
            axi0_write_mixed_dynamic_static_response_active_match
            axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
            axi0_w0_dynamic_completion_active
            axi0_w1_static_completion_active
        )],
        'mixed write report names generated assertions',
    );
    is_deeply(
        $write->{dynamic_capture},
        {
            request_id_source           => 'axi0_awid',
            capture_event_source        => 'admitted_dynamic_write_request',
            ownership                   => 'mixed_dynamic_static_unique_write_ids',
            simultaneous_request_policy => 'onehot0_mixed_write_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            selected_id_signal          => 'axi0_w0_dynamic_id_q',
            busy_signal                 => 'axi0_w0_dynamic_busy_q',
            capture_rule                => 'axi0_w0_dynamic_id_capture',
            release_rule                => 'axi0_w0_dynamic_id_release',
            release_recapture_rule      => 'axi0_w0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_dynamic_write',
            release_recapture_source    => 'generated_mixed_dynamic_static_demux_completion',
            release_recapture_transaction => 'w0',
        },
        'mixed write report describes dynamic capture ownership',
    );
    is_deeply(
        $write->{static_capture},
        {
            transaction                         => 'w1',
            concrete_id                         => 3,
            concrete_id_literal                 => "4'd3",
            capture_event_source                => 'admitted_static_write_request',
            ownership                           => 'mixed_dynamic_static_concrete_write_id',
            simultaneous_request_policy         => 'onehot0_mixed_write_request',
            busy_signal                         => 'axi0_w1_static_busy_q',
            capture_rule                        => 'axi0_w1_static_busy_capture',
            release_rule                        => 'axi0_w1_static_busy_release',
            release_recapture_rule              => 'axi0_w1_static_busy_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_write',
            release_recapture_source            => 'generated_mixed_dynamic_static_demux_completion',
            release_recapture_transaction       => 'w1',
        },
        'mixed write report describes static capture ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'mixed write dynamic transaction reports generated capture/matching');
    is_deeply(
        {
            map { $_ => $report->{transactions}[1]{id}{$_} }
            qw(policy value family family_width)
        },
        {
            policy       => 'concrete',
            value        => 3,
            family       => 'write',
            family_width => 4,
        },
        'mixed write static transaction keeps concrete ID metadata',
    );
    ok($report->{transactions}[1]{id}{fits}, 'mixed write static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'mixed write demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_write_multi_static_report {
    my ($report, $static_cases) = @_;
    my @static_cases = @{$static_cases || [
        { transaction => 'w1', index => 1, value => 3, literal => "4'd3", label => 'first' },
        { transaction => 'w2', index => 2, value => 5, literal => "4'd5", label => 'second' },
    ]};
    for my $index (0 .. $#static_cases) {
        $static_cases[$index]{index} = $index + 1 unless exists $static_cases[$index]{index};
    }
    my $release_recapture_expected = @static_cases == 2 || @static_cases == 3;
    my @static_names = map { $_->{transaction} } @static_cases;
    my @transaction_names = ('w0', @static_names);
    my @unique_match_assertions;
    for my $left_index (0 .. $#transaction_names - 1) {
        for my $right_index ($left_index + 1 .. $#transaction_names) {
            push @unique_match_assertions,
                "axi0_$transaction_names[$left_index]_$transaction_names[$right_index]_write_mixed_dynamic_static_response_unique_match";
        }
    }
    my $write = $report->{response_demux}{write};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_write_bid_demux_contract', 'multi-static mixed write report marks multi-static mixed BID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-static mixed write report marks generated demux behavior');
    is($write->{mode}, 'bounded_multi_mixed_dynamic_static_write_bid_demux_contract', 'multi-static mixed write report marks write mode');
    is($write->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_demux', 'multi-static mixed write report marks generated multi mixed completion source');
    is($write->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id', 'multi-static mixed write report marks mixed completion semantics');
    is_deeply($write->{dynamic_transactions}, [qw(w0)], 'multi-static mixed write report names covered dynamic transaction');
    is_deeply($write->{static_transactions}, \@static_names, 'multi-static mixed write report names covered static transactions');
    is_deeply($write->{mixed_transactions}, { dynamic => [qw(w0)], static => \@static_names }, 'multi-static mixed write report names dynamic/static transaction roles as lists');
    is_deeply(
        $write->{static_id_reservations},
        [
            map {
                +{
                    transaction            => $_->{transaction},
                    concrete_id            => $_->{value},
                    concrete_id_literal    => $_->{literal},
                    dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
                }
            } @static_cases
        ],
        'multi-static mixed write report records list-shaped static-ID reservations',
    );
    is_deeply($write->{generated_rules}, [map { "axi0_${_}_response_demux" } @transaction_names], 'multi-static mixed write report names generated response-demux rules');
    is_deeply($write->{generated_completion_signals}, [map { "axi0_${_}_complete" } @transaction_names], 'multi-static mixed write report names generated completions');
    is_deeply(
        $write->{generated_assertions},
        [
            $release_recapture_expected
                ? 'axi0_w0_dynamic_request_idle_or_releasing'
                : 'axi0_w0_dynamic_request_not_busy',
            (map {
                my $transaction = $_->{transaction};
                $release_recapture_expected
                    ? "axi0_${transaction}_static_request_idle_or_releasing"
                    : "axi0_${transaction}_static_request_not_busy";
            } @static_cases),
            'axi0_write_mixed_dynamic_static_request_onehot0',
            (map {
                my $transaction = $_->{transaction};
                (
                    "axi0_w0_${transaction}_write_dynamic_request_not_static_id",
                    "axi0_w0_${transaction}_write_dynamic_active_not_static_id",
                )
            } @static_cases),
            'axi0_write_mixed_dynamic_static_response_active_match',
            @unique_match_assertions,
            'axi0_w0_dynamic_completion_active',
            (map {
                my $transaction = $_->{transaction};
                "axi0_${transaction}_static_completion_active";
            } @static_cases),
        ],
        'multi-static mixed write report names generated assertions',
    );
    my %dynamic_transaction_capture = (
        transaction        => 'w0',
        selected_id_signal => 'axi0_w0_dynamic_id_q',
        busy_signal        => 'axi0_w0_dynamic_busy_q',
        capture_rule       => 'axi0_w0_dynamic_id_capture',
        release_rule       => 'axi0_w0_dynamic_id_release',
    );
    if ($release_recapture_expected) {
        $dynamic_transaction_capture{release_recapture_rule} = 'axi0_w0_dynamic_id_release_recapture';
        $dynamic_transaction_capture{same_cycle_release_recapture_policy} = 'mixed_dynamic_static_dynamic_write';
        $dynamic_transaction_capture{release_recapture_source} = 'generated_multi_mixed_dynamic_static_demux_completion';
        $dynamic_transaction_capture{release_recapture_transaction} = 'w0';
    }
    is_deeply(
        $write->{dynamic_capture},
        {
            request_id_source           => 'axi0_awid',
            capture_event_source        => 'admitted_dynamic_write_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_write_ids',
            simultaneous_request_policy => 'onehot0_mixed_write_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => [map { $_->{literal} } @static_cases],
            transactions                => [
                \%dynamic_transaction_capture,
            ],
        },
        'multi-static mixed write report describes dynamic capture ownership and all static exclusions',
    );
    if ($release_recapture_expected) {
        is_deeply(
            $write->{static_capture},
            [
                map {
                    my $transaction = $_->{transaction};
                    +{
                        transaction                         => $transaction,
                        concrete_id                         => $_->{value},
                        concrete_id_literal                 => $_->{literal},
                        capture_event_source                => 'admitted_static_write_request',
                        ownership                           => 'mixed_dynamic_static_concrete_write_id',
                        simultaneous_request_policy         => 'onehot0_mixed_write_request',
                        busy_signal                         => "axi0_${transaction}_static_busy_q",
                        capture_rule                        => "axi0_${transaction}_static_busy_capture",
                        release_rule                        => "axi0_${transaction}_static_busy_release",
                        release_recapture_rule              => "axi0_${transaction}_static_busy_release_recapture",
                        same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_write',
                        release_recapture_source            => 'generated_multi_mixed_dynamic_static_demux_completion',
                        release_recapture_transaction       => $transaction,
                    }
                } @static_cases
            ],
            'multi-static mixed write report records list-shaped static recapture ownership',
        );
    } else {
        ok(!exists $write->{static_capture}, 'multi-static mixed write report leaves static recapture absent outside the selected two-static owner');
    }
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'multi-static mixed write dynamic transaction reports generated capture/matching');
    for my $case (@static_cases) {
        is_deeply(
            {
                map { $_ => $report->{transactions}[$case->{index}]{id}{$_} }
                qw(policy value family family_width)
            },
            {
                policy       => 'concrete',
                value        => $case->{value},
                family       => 'write',
                family_width => 4,
            },
            "multi-static mixed write $case->{label} static transaction keeps concrete ID metadata",
        );
        ok($report->{transactions}[$case->{index}]{id}{fits}, "multi-static mixed write $case->{label} static transaction reports concrete ID fits the family width");
    }
    assert_dynamic_residue($report, 'multi-static mixed write demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_write_multi_dynamic_report {
    my ($report) = @_;
    my $write = $report->{response_demux}{write};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_write_bid_demux_contract', 'multi-dynamic mixed write report marks multi mixed BID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-dynamic mixed write report marks generated demux behavior');
    is($write->{mode}, 'bounded_multi_mixed_dynamic_static_write_bid_demux_contract', 'multi-dynamic mixed write report marks write mode');
    is($write->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_demux', 'multi-dynamic mixed write report marks generated multi mixed completion source');
    is($write->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id', 'multi-dynamic mixed write report marks mixed completion semantics');
    is_deeply($write->{dynamic_transactions}, [qw(w0 w1)], 'multi-dynamic mixed write report names covered dynamic transactions');
    is_deeply($write->{static_transactions}, [qw(w2)], 'multi-dynamic mixed write report names covered static transaction');
    is_deeply($write->{mixed_transactions}, { dynamic => [qw(w0 w1)], static => [qw(w2)] }, 'multi-dynamic mixed write report names dynamic/static transaction roles as lists');
    is_deeply(
        $write->{static_id_reservations},
        [
            {
                transaction            => 'w2',
                concrete_id            => 3,
                concrete_id_literal    => "4'd3",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
        ],
        'multi-dynamic mixed write report records list-shaped static-ID reservation',
    );
    is_deeply(
        $write->{generated_rules},
        [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux)],
        'multi-dynamic mixed write report names generated response-demux rules',
    );
    is_deeply(
        $write->{generated_completion_signals},
        [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete)],
        'multi-dynamic mixed write report names generated completions',
    );
    is_deeply(
        $write->{generated_assertions},
        [qw(
            axi0_w0_dynamic_request_idle_or_releasing
            axi0_w1_dynamic_request_idle_or_releasing
            axi0_w2_static_request_idle_or_releasing
            axi0_write_mixed_dynamic_static_request_onehot0
            axi0_w0_dynamic_request_no_active_same_id
            axi0_w1_dynamic_request_no_active_same_id
            axi0_w0_w1_write_dynamic_active_id_unique
            axi0_w0_w2_write_dynamic_request_not_static_id
            axi0_w0_w2_write_dynamic_active_not_static_id
            axi0_w1_w2_write_dynamic_request_not_static_id
            axi0_w1_w2_write_dynamic_active_not_static_id
            axi0_write_mixed_dynamic_static_response_active_match
            axi0_w0_w1_write_mixed_dynamic_static_response_unique_match
            axi0_w0_w2_write_mixed_dynamic_static_response_unique_match
            axi0_w1_w2_write_mixed_dynamic_static_response_unique_match
            axi0_w0_dynamic_completion_active
            axi0_w1_dynamic_completion_active
            axi0_w2_static_completion_active
        )],
        'multi-dynamic mixed write report names generated assertions',
    );
    is_deeply(
        $write->{dynamic_capture},
        {
            request_id_source           => 'axi0_awid',
            capture_event_source        => 'admitted_dynamic_write_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_write_ids',
            simultaneous_request_policy => 'onehot0_mixed_write_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => ["4'd3"],
            transactions                => [
                {
                    transaction        => 'w0',
                    selected_id_signal => 'axi0_w0_dynamic_id_q',
                    busy_signal        => 'axi0_w0_dynamic_busy_q',
                    capture_rule       => 'axi0_w0_dynamic_id_capture',
                    release_rule       => 'axi0_w0_dynamic_id_release',
                    release_recapture_rule => 'axi0_w0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_write',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_demux_completion',
                    release_recapture_transaction => 'w0',
                },
                {
                    transaction        => 'w1',
                    selected_id_signal => 'axi0_w1_dynamic_id_q',
                    busy_signal        => 'axi0_w1_dynamic_busy_q',
                    capture_rule       => 'axi0_w1_dynamic_id_capture',
                    release_rule       => 'axi0_w1_dynamic_id_release',
                    release_recapture_rule => 'axi0_w1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_write',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_demux_completion',
                    release_recapture_transaction => 'w1',
                },
            ],
        },
        'multi-dynamic mixed write report describes dynamic capture ownership and static exclusions',
    );
    is_deeply(
        $write->{static_capture},
        [
            {
                transaction                         => 'w2',
                concrete_id                         => 3,
                concrete_id_literal                 => "4'd3",
                capture_event_source                => 'admitted_static_write_request',
                ownership                           => 'mixed_dynamic_static_concrete_write_id',
                simultaneous_request_policy         => 'onehot0_mixed_write_request',
                busy_signal                         => 'axi0_w2_static_busy_q',
                capture_rule                        => 'axi0_w2_static_busy_capture',
                release_rule                        => 'axi0_w2_static_busy_release',
                release_recapture_rule              => 'axi0_w2_static_busy_release_recapture',
                same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_write',
                release_recapture_source            => 'generated_multi_mixed_dynamic_static_demux_completion',
                release_recapture_transaction       => 'w2',
            },
        ],
        'multi-dynamic mixed write report records list-shaped static recapture ownership',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}[0, 1]],
        [qw(generated_capture_matching generated_capture_matching)],
        'multi-dynamic mixed write dynamic transactions report generated capture/matching',
    );
    is_deeply(
        {
            map { $_ => $report->{transactions}[2]{id}{$_} }
            qw(policy value family family_width)
        },
        {
            policy       => 'concrete',
            value        => 3,
            family       => 'write',
            family_width => 4,
        },
        'multi-dynamic mixed write static transaction keeps concrete ID metadata',
    );
    ok($report->{transactions}[2]{id}{fits}, 'multi-dynamic mixed write static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'multi-dynamic mixed write demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_mixed_dynamic_static_read_rid_demux_contract', 'mixed read report marks mixed RID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'mixed read report marks generated demux behavior');
    is($read->{mode}, 'bounded_mixed_dynamic_static_read_rid_demux_contract', 'mixed read report marks read mode');
    is($read->{response_scope}, 'single_beat', 'mixed read report marks single-beat scope');
    is($read->{transaction_completion_source}, 'generated_mixed_dynamic_static_read_demux', 'mixed read report marks generated mixed read completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_single_beat', 'mixed read report marks mixed read completion semantics');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'mixed read report names covered dynamic transaction');
    is_deeply($read->{static_transactions}, [qw(r1)], 'mixed read report names covered static transaction');
    is_deeply($read->{mixed_transactions}, { dynamic => 'r0', static => 'r1' }, 'mixed read report names dynamic/static transaction roles');
    is_deeply(
        $read->{static_id_reservation},
        {
            transaction            => 'r1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        'mixed read report records static-ID reservation policy',
    );
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'mixed read report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'mixed read report names generated completions');
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_static_request_idle_or_releasing
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_not_static_id
            axi0_r0_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
        )],
        'mixed read report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            selected_id_signal          => 'axi0_r0_dynamic_id_q',
            busy_signal                 => 'axi0_r0_dynamic_busy_q',
            capture_rule                => 'axi0_r0_dynamic_id_capture',
            release_rule                => 'axi0_r0_dynamic_id_release',
            release_recapture_rule      => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_dynamic_read',
            release_recapture_source    => 'generated_mixed_dynamic_static_read_demux_completion',
            release_recapture_transaction => 'r0',
        },
        'mixed read report describes dynamic capture ownership',
    );
    is_deeply(
        $read->{static_capture},
        {
            transaction                         => 'r1',
            concrete_id                         => 3,
            concrete_id_literal                 => "4'd3",
            capture_event_source                => 'admitted_static_read_request',
            ownership                           => 'mixed_dynamic_static_concrete_read_id',
            simultaneous_request_policy         => 'onehot0_mixed_read_request',
            busy_signal                         => 'axi0_r1_static_busy_q',
            capture_rule                        => 'axi0_r1_static_busy_capture',
            release_rule                        => 'axi0_r1_static_busy_release',
            release_recapture_rule              => 'axi0_r1_static_busy_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
            release_recapture_source            => 'generated_mixed_dynamic_static_read_demux_completion',
            release_recapture_transaction       => 'r1',
        },
        'mixed read report describes static capture and recapture ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'mixed read dynamic transaction reports generated capture/matching');
    is_deeply(
        {
            map { $_ => $report->{transactions}[1]{id}{$_} }
            qw(policy value family family_width)
        },
        {
            policy       => 'concrete',
            value        => 3,
            family       => 'read',
            family_width => 4,
        },
        'mixed read static transaction keeps concrete ID metadata',
    );
    ok($report->{transactions}[1]{id}{fits}, 'mixed read static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'mixed read demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_multi_static_report {
    my ($report, $static_cases) = @_;
    my @static_cases = @{$static_cases || [
        { transaction => 'r1', index => 1, value => 3, literal => "4'd3", label => 'first' },
        { transaction => 'r2', index => 2, value => 5, literal => "4'd5", label => 'second' },
    ]};
    for my $index (0 .. $#static_cases) {
        $static_cases[$index]{index} = $index + 1 unless exists $static_cases[$index]{index};
    }
    my @static_names = map { $_->{transaction} } @static_cases;
    my @transaction_names = ('r0', @static_names);
    my $release_recapture_expected = @static_cases == 2 || @static_cases == 3;
    my @unique_match_assertions;
    for my $left_index (0 .. $#transaction_names - 1) {
        for my $right_index ($left_index + 1 .. $#transaction_names) {
            push @unique_match_assertions,
                "axi0_$transaction_names[$left_index]_$transaction_names[$right_index]_read_mixed_dynamic_static_response_unique_match";
        }
    }
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_demux_contract', 'multi-static mixed read report marks multi-static mixed RID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-static mixed read report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_demux_contract', 'multi-static mixed read report marks read mode');
    is($read->{response_event_role}, 'raw_accepted_read_response', 'multi-static mixed read report marks raw single-beat read response role');
    is($read->{response_scope}, 'single_beat', 'multi-static mixed read report marks single-beat scope');
    is($read->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_read_demux', 'multi-static mixed read report marks generated multi mixed read completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_single_beat', 'multi-static mixed read report marks mixed read completion semantics');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'multi-static mixed read report names covered dynamic transaction');
    is_deeply($read->{static_transactions}, \@static_names, 'multi-static mixed read report names covered static transactions');
    is_deeply($read->{mixed_transactions}, { dynamic => [qw(r0)], static => \@static_names }, 'multi-static mixed read report names dynamic/static transaction roles as lists');
    is_deeply(
        $read->{static_id_reservations},
        [
            map {
                +{
                    transaction            => $_->{transaction},
                    concrete_id            => $_->{value},
                    concrete_id_literal    => $_->{literal},
                    dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
                }
            } @static_cases
        ],
        'multi-static mixed read report records list-shaped static-ID reservations',
    );
    is_deeply($read->{generated_rules}, [map { "axi0_${_}_response_demux" } @transaction_names], 'multi-static mixed read report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [map { "axi0_${_}_complete" } @transaction_names], 'multi-static mixed read report names generated completions');
    is_deeply(
        $read->{generated_assertions},
        [
            $release_recapture_expected
                ? 'axi0_r0_dynamic_request_idle_or_releasing'
                : 'axi0_r0_dynamic_request_not_busy',
            (map {
                my $transaction = $_->{transaction};
                $release_recapture_expected
                    ? "axi0_${transaction}_static_request_idle_or_releasing"
                    : "axi0_${transaction}_static_request_not_busy";
            } @static_cases),
            'axi0_read_mixed_dynamic_static_request_onehot0',
            (map {
                my $transaction = $_->{transaction};
                (
                    "axi0_r0_${transaction}_read_dynamic_request_not_static_id",
                    "axi0_r0_${transaction}_read_dynamic_active_not_static_id",
                )
            } @static_cases),
            'axi0_read_mixed_dynamic_static_response_active_match',
            @unique_match_assertions,
            'axi0_r0_dynamic_completion_active',
            (map {
                my $transaction = $_->{transaction};
                "axi0_${transaction}_static_completion_active";
            } @static_cases),
        ],
        'multi-static mixed read report names generated assertions',
    );
    my %dynamic_capture_transaction = (
        transaction        => 'r0',
        selected_id_signal => 'axi0_r0_dynamic_id_q',
        busy_signal        => 'axi0_r0_dynamic_busy_q',
        capture_rule       => 'axi0_r0_dynamic_id_capture',
        release_rule       => 'axi0_r0_dynamic_id_release',
    );
    if ($release_recapture_expected) {
        $dynamic_capture_transaction{release_recapture_rule} = 'axi0_r0_dynamic_id_release_recapture';
        $dynamic_capture_transaction{same_cycle_release_recapture_policy} =
            'mixed_dynamic_static_dynamic_read';
        $dynamic_capture_transaction{release_recapture_source} =
            'generated_multi_mixed_dynamic_static_read_demux_completion';
        $dynamic_capture_transaction{release_recapture_transaction} = 'r0';
    }
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => [map { $_->{literal} } @static_cases],
            transactions                => [\%dynamic_capture_transaction],
        },
        'multi-static mixed read report describes dynamic capture ownership and all static exclusions',
    );
    if ($release_recapture_expected) {
        is_deeply(
            $read->{static_capture},
            [
                map {
                    my $transaction = $_->{transaction};
                    +{
                        transaction                         => $transaction,
                        concrete_id                         => $_->{value},
                        concrete_id_literal                 => $_->{literal},
                        capture_event_source                => 'admitted_static_read_request',
                        ownership                           => 'mixed_dynamic_static_concrete_read_id',
                        simultaneous_request_policy         => 'onehot0_mixed_read_request',
                        busy_signal                         => "axi0_${transaction}_static_busy_q",
                        capture_rule                        => "axi0_${transaction}_static_busy_capture",
                        release_rule                        => "axi0_${transaction}_static_busy_release",
                        release_recapture_rule              => "axi0_${transaction}_static_busy_release_recapture",
                        same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
                        release_recapture_source            => 'generated_multi_mixed_dynamic_static_read_demux_completion',
                        release_recapture_transaction       => $transaction,
                    }
                } @static_cases
            ],
            'multi-static mixed read report lists static release-recapture capture entries',
        );
    } else {
        ok(!exists $read->{static_capture}, 'multi-static mixed read report leaves static recapture absent outside the selected two-static owner');
    }
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'multi-static mixed read dynamic transaction reports generated capture/matching');
    for my $case (@static_cases) {
        is_deeply(
            {
                map { $_ => $report->{transactions}[$case->{index}]{id}{$_} }
                qw(policy value family family_width)
            },
            {
                policy       => 'concrete',
                value        => $case->{value},
                family       => 'read',
                family_width => 4,
            },
            "multi-static mixed read $case->{label} static transaction keeps concrete ID metadata",
        );
        ok($report->{transactions}[$case->{index}]{id}{fits}, "multi-static mixed read $case->{label} static transaction reports concrete ID fits the family width");
    }
    assert_dynamic_residue($report, 'multi-static mixed read demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_multi_dynamic_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_demux_contract', 'multi-dynamic mixed read report marks multi mixed RID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-dynamic mixed read report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_demux_contract', 'multi-dynamic mixed read report marks read mode');
    is($read->{response_event_role}, 'raw_accepted_read_response', 'multi-dynamic mixed read report marks raw single-beat read response role');
    is($read->{response_scope}, 'single_beat', 'multi-dynamic mixed read report marks single-beat scope');
    is($read->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_read_demux', 'multi-dynamic mixed read report marks generated multi mixed read completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_single_beat', 'multi-dynamic mixed read report marks mixed completion semantics');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'multi-dynamic mixed read report names covered dynamic transactions');
    is_deeply($read->{static_transactions}, [qw(r2)], 'multi-dynamic mixed read report names covered static transaction');
    is_deeply($read->{mixed_transactions}, { dynamic => [qw(r0 r1)], static => [qw(r2)] }, 'multi-dynamic mixed read report names dynamic/static transaction roles as lists');
    is_deeply(
        $read->{static_id_reservations},
        [
            {
                transaction            => 'r2',
                concrete_id            => 3,
                concrete_id_literal    => "4'd3",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
        ],
        'multi-dynamic mixed read report records list-shaped static-ID reservation',
    );
    is_deeply(
        $read->{generated_rules},
        [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        'multi-dynamic mixed read report names generated response-demux rules',
    );
    is_deeply(
        $read->{generated_completion_signals},
        [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        'multi-dynamic mixed read report names generated completions',
    );
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_dynamic_request_idle_or_releasing
            axi0_r2_static_request_idle_or_releasing
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_r0_r2_read_dynamic_request_not_static_id
            axi0_r0_r2_read_dynamic_active_not_static_id
            axi0_r1_r2_read_dynamic_request_not_static_id
            axi0_r1_r2_read_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
            axi0_r2_static_completion_active
        )],
        'multi-dynamic mixed read report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => ["4'd3"],
            transactions                => [
                {
                    transaction        => 'r0',
                    selected_id_signal => 'axi0_r0_dynamic_id_q',
                    busy_signal        => 'axi0_r0_dynamic_busy_q',
                    capture_rule       => 'axi0_r0_dynamic_id_capture',
                    release_rule       => 'axi0_r0_dynamic_id_release',
                    release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_read',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_read_demux_completion',
                    release_recapture_transaction => 'r0',
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                    release_recapture_rule => 'axi0_r1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_read',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_read_demux_completion',
                    release_recapture_transaction => 'r1',
                },
            ],
        },
        'multi-dynamic mixed read report describes dynamic capture ownership and static exclusions',
    );
    is_deeply(
        $read->{static_capture},
        [
            {
                transaction                         => 'r2',
                concrete_id                         => 3,
                concrete_id_literal                 => "4'd3",
                capture_event_source                => 'admitted_static_read_request',
                ownership                           => 'mixed_dynamic_static_concrete_read_id',
                simultaneous_request_policy         => 'onehot0_mixed_read_request',
                busy_signal                         => 'axi0_r2_static_busy_q',
                capture_rule                        => 'axi0_r2_static_busy_capture',
                release_rule                        => 'axi0_r2_static_busy_release',
                release_recapture_rule              => 'axi0_r2_static_busy_release_recapture',
                same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
                release_recapture_source            => 'generated_multi_mixed_dynamic_static_read_demux_completion',
                release_recapture_transaction       => 'r2',
            },
        ],
        'multi-dynamic mixed read report records list-shaped static recapture ownership',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}[0, 1]],
        [qw(generated_capture_matching generated_capture_matching)],
        'multi-dynamic mixed read dynamic transactions report generated capture/matching',
    );
    is_deeply(
        {
            map { $_ => $report->{transactions}[2]{id}{$_} }
            qw(policy value family family_width)
        },
        {
            policy       => 'concrete',
            value        => 3,
            family       => 'read',
            family_width => 4,
        },
        'multi-dynamic mixed read static transaction keeps concrete ID metadata',
    );
    ok($report->{transactions}[2]{id}{fits}, 'multi-dynamic mixed read static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'multi-dynamic mixed read demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_rlast_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_mixed_dynamic_static_read_rid_rlast_demux_contract', 'mixed read RLAST report marks mixed RID/RLAST-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'mixed read RLAST report marks generated demux behavior');
    is($read->{mode}, 'bounded_mixed_dynamic_static_read_rid_rlast_demux_contract', 'mixed read RLAST report marks read mode');
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', 'mixed read RLAST report marks raw response-beat event role');
    is($read->{response_scope}, 'burst_last', 'mixed read RLAST report marks burst-last scope');
    is($read->{last_signal}, 'axi0_rlast', 'mixed read RLAST report names last signal');
    is($read->{last_signal_direction}, 'generated_input', 'mixed read RLAST report marks last signal as generated input');
    is($read->{last_signal_width}, 1, 'mixed read RLAST report marks one-bit last signal');
    is($read->{transaction_completion_source}, 'generated_mixed_dynamic_static_read_demux_last_beat', 'mixed read RLAST report marks generated mixed read last-beat completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_and_last_signal', 'mixed read RLAST report marks mixed read last-beat completion semantics');
    is($read->{beat_valid_output}, 'none', 'mixed read RLAST report keeps beat-valid output absent');
    is($read->{burst_length_source}, 'rlast_only', 'mixed read RLAST report marks RLAST-only burst length source');
    is($read->{burst_length_validation}, 'not_generated', 'mixed read RLAST report leaves burst-length validation ungenerated');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'mixed read RLAST report names covered dynamic transaction');
    is_deeply($read->{static_transactions}, [qw(r1)], 'mixed read RLAST report names covered static transaction');
    is_deeply($read->{mixed_transactions}, { dynamic => 'r0', static => 'r1' }, 'mixed read RLAST report names dynamic/static transaction roles');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'mixed read RLAST report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'mixed read RLAST report names generated completions');
    is_deeply(
        $read->{static_id_reservation},
        {
            transaction            => 'r1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        'mixed read RLAST report records static-ID reservation policy',
    );
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_static_request_idle_or_releasing
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_not_static_id
            axi0_r0_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
        )],
        'mixed read RLAST report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            selected_id_signal          => 'axi0_r0_dynamic_id_q',
            busy_signal                 => 'axi0_r0_dynamic_busy_q',
            capture_rule                => 'axi0_r0_dynamic_id_capture',
            release_rule                => 'axi0_r0_dynamic_id_release',
            release_recapture_rule      => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_dynamic_read',
            release_recapture_source    => 'generated_mixed_dynamic_static_read_demux_last_beat_completion',
            release_recapture_transaction => 'r0',
        },
        'mixed read RLAST report describes dynamic capture ownership',
    );
    is_deeply(
        $read->{static_capture},
        {
            transaction                         => 'r1',
            concrete_id                         => 3,
            concrete_id_literal                 => "4'd3",
            capture_event_source                => 'admitted_static_read_request',
            ownership                           => 'mixed_dynamic_static_concrete_read_id',
            simultaneous_request_policy         => 'onehot0_mixed_read_request',
            busy_signal                         => 'axi0_r1_static_busy_q',
            capture_rule                        => 'axi0_r1_static_busy_capture',
            release_rule                        => 'axi0_r1_static_busy_release',
            release_recapture_rule              => 'axi0_r1_static_busy_release_recapture',
            same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
            release_recapture_source            => 'generated_mixed_dynamic_static_read_demux_last_beat_completion',
            release_recapture_transaction       => 'r1',
        },
        'mixed read RLAST report describes static capture and recapture ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'mixed read RLAST dynamic transaction reports generated capture/matching');
    ok($report->{transactions}[1]{id}{fits}, 'mixed read RLAST static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'mixed read RLAST demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_rlast_multi_static_report {
    my ($report, $static_cases) = @_;
    my @static_cases = @{$static_cases || [
        { transaction => 'r1', index => 1, value => 3, literal => "4'd3", label => 'first' },
        { transaction => 'r2', index => 2, value => 5, literal => "4'd5", label => 'second' },
    ]};
    for my $index (0 .. $#static_cases) {
        $static_cases[$index]{index} = $index + 1 unless exists $static_cases[$index]{index};
    }
    my @static_names = map { $_->{transaction} } @static_cases;
    my @transaction_names = ('r0', @static_names);
    my $release_recapture_expected = @static_cases == 2 || @static_cases == 3;
    my @unique_match_assertions;
    for my $left_index (0 .. $#transaction_names - 1) {
        for my $right_index ($left_index + 1 .. $#transaction_names) {
            push @unique_match_assertions,
                "axi0_$transaction_names[$left_index]_$transaction_names[$right_index]_read_mixed_dynamic_static_response_unique_match";
        }
    }
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract', 'multi-static mixed read RLAST report marks multi-static mixed RID/RLAST-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-static mixed read RLAST report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract', 'multi-static mixed read RLAST report marks read mode');
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', 'multi-static mixed read RLAST report marks raw response-beat event role');
    is($read->{response_scope}, 'burst_last', 'multi-static mixed read RLAST report marks burst-last scope');
    is($read->{last_signal}, 'axi0_rlast', 'multi-static mixed read RLAST report names last signal');
    is($read->{last_signal_direction}, 'generated_input', 'multi-static mixed read RLAST report marks last signal as generated input');
    is($read->{last_signal_width}, 1, 'multi-static mixed read RLAST report marks one-bit last signal');
    is($read->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_read_demux_last_beat', 'multi-static mixed read RLAST report marks generated multi mixed read last-beat completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_and_last_signal', 'multi-static mixed read RLAST report marks mixed read last-beat completion semantics');
    is($read->{beat_valid_output}, 'none', 'multi-static mixed read RLAST report keeps beat-valid output absent');
    is($read->{burst_length_source}, 'rlast_only', 'multi-static mixed read RLAST report marks RLAST-only burst length source');
    is($read->{burst_length_validation}, 'not_generated', 'multi-static mixed read RLAST report leaves burst-length validation ungenerated');
    is_deeply($read->{dynamic_transactions}, [qw(r0)], 'multi-static mixed read RLAST report names covered dynamic transaction');
    is_deeply($read->{static_transactions}, \@static_names, 'multi-static mixed read RLAST report names covered static transactions');
    is_deeply($read->{mixed_transactions}, { dynamic => [qw(r0)], static => \@static_names }, 'multi-static mixed read RLAST report names dynamic/static transaction roles as lists');
    is_deeply($read->{generated_rules}, [map { "axi0_${_}_response_demux" } @transaction_names], 'multi-static mixed read RLAST report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [map { "axi0_${_}_complete" } @transaction_names], 'multi-static mixed read RLAST report names generated completions');
    is_deeply(
        $read->{static_id_reservations},
        [
            map {
                +{
                    transaction            => $_->{transaction},
                    concrete_id            => $_->{value},
                    concrete_id_literal    => $_->{literal},
                    dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
                }
            } @static_cases
        ],
        'multi-static mixed read RLAST report records list-shaped static-ID reservations',
    );
    is_deeply(
        $read->{generated_assertions},
        [
            $release_recapture_expected
                ? 'axi0_r0_dynamic_request_idle_or_releasing'
                : 'axi0_r0_dynamic_request_not_busy',
            (map {
                my $transaction = $_->{transaction};
                $release_recapture_expected
                    ? "axi0_${transaction}_static_request_idle_or_releasing"
                    : "axi0_${transaction}_static_request_not_busy";
            } @static_cases),
            'axi0_read_mixed_dynamic_static_request_onehot0',
            (map {
                my $transaction = $_->{transaction};
                (
                    "axi0_r0_${transaction}_read_dynamic_request_not_static_id",
                    "axi0_r0_${transaction}_read_dynamic_active_not_static_id",
                )
            } @static_cases),
            'axi0_read_mixed_dynamic_static_response_active_match',
            @unique_match_assertions,
            'axi0_r0_dynamic_completion_active',
            (map {
                my $transaction = $_->{transaction};
                "axi0_${transaction}_static_completion_active";
            } @static_cases),
        ],
        'multi-static mixed read RLAST report names generated assertions',
    );
    my %dynamic_capture_transaction = (
        transaction        => 'r0',
        selected_id_signal => 'axi0_r0_dynamic_id_q',
        busy_signal        => 'axi0_r0_dynamic_busy_q',
        capture_rule       => 'axi0_r0_dynamic_id_capture',
        release_rule       => 'axi0_r0_dynamic_id_release',
    );
    if ($release_recapture_expected) {
        $dynamic_capture_transaction{release_recapture_rule} =
            'axi0_r0_dynamic_id_release_recapture';
        $dynamic_capture_transaction{same_cycle_release_recapture_policy} =
            'mixed_dynamic_static_dynamic_read';
        $dynamic_capture_transaction{release_recapture_source} =
            'generated_multi_mixed_dynamic_static_read_demux_last_beat_completion';
        $dynamic_capture_transaction{release_recapture_transaction} = 'r0';
    }
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => [map { $_->{literal} } @static_cases],
            transactions                => [\%dynamic_capture_transaction],
        },
        'multi-static mixed read RLAST report describes dynamic capture ownership and all static exclusions',
    );
    if ($release_recapture_expected) {
        is_deeply(
            $read->{static_capture},
            [
                map {
                    my $transaction = $_->{transaction};
                    +{
                        transaction                         => $transaction,
                        concrete_id                         => $_->{value},
                        concrete_id_literal                 => $_->{literal},
                        capture_event_source                => 'admitted_static_read_request',
                        ownership                           => 'mixed_dynamic_static_concrete_read_id',
                        simultaneous_request_policy         => 'onehot0_mixed_read_request',
                        busy_signal                         => "axi0_${transaction}_static_busy_q",
                        capture_rule                        => "axi0_${transaction}_static_busy_capture",
                        release_rule                        => "axi0_${transaction}_static_busy_release",
                        release_recapture_rule              => "axi0_${transaction}_static_busy_release_recapture",
                        same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
                        release_recapture_source            => 'generated_multi_mixed_dynamic_static_read_demux_last_beat_completion',
                        release_recapture_transaction       => $transaction,
                    }
                } @static_cases
            ],
            'multi-static mixed read RLAST report lists static release-recapture capture entries',
        );
    } else {
        ok(!exists $read->{static_capture}, 'multi-static mixed read RLAST report leaves static recapture absent outside the selected two-static owner');
    }
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'multi-static mixed read RLAST dynamic transaction reports generated capture/matching');
    for my $case (@static_cases) {
        is_deeply(
            {
                map { $_ => $report->{transactions}[$case->{index}]{id}{$_} }
                qw(policy value family family_width)
            },
            {
                policy       => 'concrete',
                value        => $case->{value},
                family       => 'read',
                family_width => 4,
            },
            "multi-static mixed read RLAST $case->{label} static transaction keeps concrete ID metadata",
        );
        ok($report->{transactions}[$case->{index}]{id}{fits}, "multi-static mixed read RLAST $case->{label} static transaction reports concrete ID fits the family width");
    }
    assert_dynamic_residue($report, 'multi-static mixed read RLAST demux keeps future dynamic residue visible');
}

sub assert_mixed_dynamic_static_read_rlast_multi_dynamic_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract', 'multi-dynamic mixed read RLAST report marks multi mixed RID/RLAST-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multi-dynamic mixed read RLAST report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_mixed_dynamic_static_read_rid_rlast_demux_contract', 'multi-dynamic mixed read RLAST report marks read mode');
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', 'multi-dynamic mixed read RLAST report marks raw response-beat event role');
    is($read->{response_scope}, 'burst_last', 'multi-dynamic mixed read RLAST report marks burst-last scope');
    is($read->{last_signal}, 'axi0_rlast', 'multi-dynamic mixed read RLAST report names last signal');
    is($read->{last_signal_direction}, 'generated_input', 'multi-dynamic mixed read RLAST report marks last signal as generated input');
    is($read->{last_signal_width}, 1, 'multi-dynamic mixed read RLAST report marks one-bit last signal');
    is($read->{transaction_completion_source}, 'generated_multi_mixed_dynamic_static_read_demux_last_beat', 'multi-dynamic mixed read RLAST report marks generated multi mixed read last-beat completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_and_last_signal', 'multi-dynamic mixed read RLAST report marks mixed last-beat completion semantics');
    is($read->{beat_valid_output}, 'none', 'multi-dynamic mixed read RLAST report keeps beat-valid output absent');
    is($read->{burst_length_source}, 'rlast_only', 'multi-dynamic mixed read RLAST report marks RLAST-only burst length source');
    is($read->{burst_length_validation}, 'not_generated', 'multi-dynamic mixed read RLAST report leaves burst-length validation ungenerated');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'multi-dynamic mixed read RLAST report names covered dynamic transactions');
    is_deeply($read->{static_transactions}, [qw(r2)], 'multi-dynamic mixed read RLAST report names covered static transaction');
    is_deeply($read->{mixed_transactions}, { dynamic => [qw(r0 r1)], static => [qw(r2)] }, 'multi-dynamic mixed read RLAST report names dynamic/static transaction roles as lists');
    is_deeply(
        $read->{static_id_reservations},
        [
            {
                transaction            => 'r2',
                concrete_id            => 3,
                concrete_id_literal    => "4'd3",
                dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            },
        ],
        'multi-dynamic mixed read RLAST report records list-shaped static-ID reservation',
    );
    is_deeply(
        $read->{generated_rules},
        [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        'multi-dynamic mixed read RLAST report names generated response-demux rules',
    );
    is_deeply(
        $read->{generated_completion_signals},
        [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        'multi-dynamic mixed read RLAST report names generated completions',
    );
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_dynamic_request_idle_or_releasing
            axi0_r2_static_request_idle_or_releasing
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_r0_r2_read_dynamic_request_not_static_id
            axi0_r0_r2_read_dynamic_active_not_static_id
            axi0_r1_r2_read_dynamic_request_not_static_id
            axi0_r1_r2_read_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r1_r2_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
            axi0_r2_static_completion_active
        )],
        'multi-dynamic mixed read RLAST report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_mixed_dynamic_static_unique_read_ids',
            simultaneous_request_policy => 'onehot0_mixed_read_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            static_id_conflict_policy   => 'static_concrete_ids_reserved',
            static_id_exclusions        => ["4'd3"],
            transactions                => [
                {
                    transaction        => 'r0',
                    selected_id_signal => 'axi0_r0_dynamic_id_q',
                    busy_signal        => 'axi0_r0_dynamic_busy_q',
                    capture_rule       => 'axi0_r0_dynamic_id_capture',
                    release_rule       => 'axi0_r0_dynamic_id_release',
                    release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_read',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_read_demux_last_beat_completion',
                    release_recapture_transaction => 'r0',
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                    release_recapture_rule => 'axi0_r1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'mixed_dynamic_static_multi_active_dynamic_read',
                    release_recapture_source => 'generated_multi_mixed_dynamic_static_read_demux_last_beat_completion',
                    release_recapture_transaction => 'r1',
                },
            ],
        },
        'multi-dynamic mixed read RLAST report describes dynamic capture ownership and static exclusions',
    );
    is_deeply(
        $read->{static_capture},
        [
            {
                transaction                         => 'r2',
                concrete_id                         => 3,
                concrete_id_literal                 => "4'd3",
                capture_event_source                => 'admitted_static_read_request',
                ownership                           => 'mixed_dynamic_static_concrete_read_id',
                simultaneous_request_policy         => 'onehot0_mixed_read_request',
                busy_signal                         => 'axi0_r2_static_busy_q',
                capture_rule                        => 'axi0_r2_static_busy_capture',
                release_rule                        => 'axi0_r2_static_busy_release',
                release_recapture_rule              => 'axi0_r2_static_busy_release_recapture',
                same_cycle_release_recapture_policy => 'mixed_dynamic_static_static_read',
                release_recapture_source            => 'generated_multi_mixed_dynamic_static_read_demux_last_beat_completion',
                release_recapture_transaction       => 'r2',
            },
        ],
        'multi-dynamic mixed read RLAST report records list-shaped static recapture ownership',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}[0, 1]],
        [qw(generated_capture_matching generated_capture_matching)],
        'multi-dynamic mixed read RLAST dynamic transactions report generated capture/matching',
    );
    is_deeply(
        {
            map { $_ => $report->{transactions}[2]{id}{$_} }
            qw(policy value family family_width)
        },
        {
            policy       => 'concrete',
            value        => 3,
            family       => 'read',
            family_width => 4,
        },
        'multi-dynamic mixed read RLAST static transaction keeps concrete ID metadata',
    );
    ok($report->{transactions}[2]{id}{fits}, 'multi-dynamic mixed read RLAST static transaction reports concrete ID fits the family width');
    assert_dynamic_residue($report, 'multi-dynamic mixed read RLAST demux keeps future dynamic residue visible');
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
    is_deeply($read->{generated_assertions}, [qw(axi0_r0_dynamic_request_idle_or_releasing axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)], 'dynamic read report names generated assertions');
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source    => 'axi0_arid',
            capture_event_source => 'admitted_dynamic_read_request',
            ownership            => 'single_active_dynamic_read',
            selected_id_signal   => 'axi0_r0_dynamic_id_q',
            busy_signal          => 'axi0_r0_dynamic_busy_q',
            capture_rule         => 'axi0_r0_dynamic_id_capture',
            release_rule         => 'axi0_r0_dynamic_id_release',
            release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_read',
            release_recapture_source => 'generated_dynamic_demux_completion',
            release_recapture_transaction => 'r0',
        },
        'dynamic read report names release-recapture capture ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic read transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic read demux keeps future dynamic residue visible');
}

sub assert_dynamic_read_multi_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_dynamic_read_rid_demux_contract', 'multiple dynamic read report marks multi RID-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multiple dynamic read report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_dynamic_read_rid_demux_contract', 'multiple dynamic read report marks read mode');
    is($read->{response_scope}, 'single_beat', 'multiple dynamic read report marks single-beat scope');
    is($read->{transaction_completion_source}, 'generated_dynamic_demux', 'multiple dynamic read report marks generated completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_single_beat', 'multiple dynamic read report marks matched dynamic RID completion');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'multiple dynamic read report names covered dynamic transactions');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'multiple dynamic read report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'multiple dynamic read report names generated completions');
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_dynamic_request_idle_or_releasing
            axi0_read_dynamic_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_read_dynamic_response_active_match
            axi0_r0_r1_read_dynamic_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
        )],
        'multiple dynamic read report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_active_unique_dynamic_read_ids',
            simultaneous_request_policy => 'onehot0_dynamic_read_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            transactions                => [
                {
                    transaction        => 'r0',
                    selected_id_signal => 'axi0_r0_dynamic_id_q',
                    busy_signal        => 'axi0_r0_dynamic_busy_q',
                    capture_rule       => 'axi0_r0_dynamic_id_capture',
                    release_rule       => 'axi0_r0_dynamic_id_release',
                    release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_read',
                    release_recapture_source => 'generated_dynamic_demux_completion',
                    release_recapture_transaction => 'r0',
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                    release_recapture_rule => 'axi0_r1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_read',
                    release_recapture_source => 'generated_dynamic_demux_completion',
                    release_recapture_transaction => 'r1',
                },
            ],
        },
        'multiple dynamic read report describes per-transaction dynamic capture',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        'multiple dynamic read transactions report generated capture/matching',
    );
    assert_dynamic_residue($report, 'multiple dynamic read demux keeps future dynamic residue visible');
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
    is_deeply($read->{generated_assertions}, [qw(axi0_r0_dynamic_request_idle_or_releasing axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)], 'dynamic read RLAST report names release-recapture assertions');
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source    => 'axi0_arid',
            capture_event_source => 'admitted_dynamic_read_request',
            ownership            => 'single_active_dynamic_read',
            selected_id_signal   => 'axi0_r0_dynamic_id_q',
            busy_signal          => 'axi0_r0_dynamic_busy_q',
            capture_rule         => 'axi0_r0_dynamic_id_capture',
            release_rule         => 'axi0_r0_dynamic_id_release',
            release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_read',
            release_recapture_source => 'generated_dynamic_demux_last_beat_completion',
            release_recapture_transaction => 'r0',
        },
        'dynamic read RLAST report names release-recapture capture ownership',
    );
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', 'dynamic read RLAST transaction reports generated capture/matching');
    assert_dynamic_residue($report, 'dynamic read RLAST demux keeps future dynamic residue visible');
}

sub assert_dynamic_read_multi_rlast_report {
    my ($report) = @_;
    my $read = $report->{response_demux}{read};

    is($report->{response_demux}{mode}, 'bounded_multi_dynamic_read_rid_rlast_demux_contract', 'multiple dynamic read RLAST report marks multi RID/RLAST-demux contract');
    ok($report->{response_demux}{generated_behavior}, 'multiple dynamic read RLAST report marks generated demux behavior');
    is($read->{mode}, 'bounded_multi_dynamic_read_rid_rlast_demux_contract', 'multiple dynamic read RLAST report marks read mode');
    is($read->{response_scope}, 'burst_last', 'multiple dynamic read RLAST report marks burst-last scope');
    is($read->{last_signal}, 'axi0_rlast', 'multiple dynamic read RLAST report names RLAST signal');
    is($read->{transaction_completion_source}, 'generated_dynamic_demux_last_beat', 'multiple dynamic read RLAST report marks generated last-beat completion source');
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_and_last_signal', 'multiple dynamic read RLAST report marks matched dynamic ID and last-signal completion');
    is($read->{beat_valid_output}, 'none', 'multiple dynamic read RLAST report marks no beat-valid output');
    is($read->{burst_length_source}, 'rlast_only', 'multiple dynamic read RLAST report marks RLAST-only burst source');
    is($read->{burst_length_validation}, 'not_generated', 'multiple dynamic read RLAST report marks no burst-length validation');
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], 'multiple dynamic read RLAST report names covered dynamic transactions');
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'multiple dynamic read RLAST report names generated response-demux rules');
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'multiple dynamic read RLAST report names generated completions');
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_idle_or_releasing
            axi0_r1_dynamic_request_idle_or_releasing
            axi0_read_dynamic_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_read_dynamic_response_active_match
            axi0_r0_r1_read_dynamic_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
        )],
        'multiple dynamic read RLAST report names generated assertions',
    );
    is_deeply(
        $read->{dynamic_capture},
        {
            request_id_source           => 'axi0_arid',
            capture_event_source        => 'admitted_dynamic_read_request',
            ownership                   => 'multi_active_unique_dynamic_read_ids',
            simultaneous_request_policy => 'onehot0_dynamic_read_request',
            same_id_conflict_policy     => 'active_dynamic_ids_must_be_unique',
            transactions                => [
                {
                    transaction        => 'r0',
                    selected_id_signal => 'axi0_r0_dynamic_id_q',
                    busy_signal        => 'axi0_r0_dynamic_busy_q',
                    capture_rule       => 'axi0_r0_dynamic_id_capture',
                    release_rule       => 'axi0_r0_dynamic_id_release',
                    release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_read',
                    release_recapture_source => 'generated_dynamic_demux_last_beat_completion',
                    release_recapture_transaction => 'r0',
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                    release_recapture_rule => 'axi0_r1_dynamic_id_release_recapture',
                    same_cycle_release_recapture_policy => 'multi_active_unique_dynamic_read',
                    release_recapture_source => 'generated_dynamic_demux_last_beat_completion',
                    release_recapture_transaction => 'r1',
                },
            ],
        },
        'multiple dynamic read RLAST report describes per-transaction dynamic capture',
    );
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        'multiple dynamic read RLAST transactions report generated capture/matching',
    );
    assert_dynamic_residue($report, 'multiple dynamic read RLAST demux keeps future dynamic residue visible');
}

sub assert_read_data_report {
    my ($read_data, $completion_validity, $expected_residue, $expected_transactions) = @_;
    $expected_transactions //= [qw(r0)];
    my @completion_signals = map { "axi0_${_}_complete" } @$expected_transactions;
    my @capture_rules = map { "axi0_${_}_read_data_capture" } @$expected_transactions;
    my $read = $read_data->{read};

    ok($read_data->{generated_behavior}, 'dynamic read-data report marks generated behavior');
    is($read->{completion_source}, 'response_demux', 'dynamic read-data report binds capture to response-demux completion');
    is($read->{completion_validity}, $completion_validity, 'dynamic read-data report names generated dynamic completion validity');
    is($read->{data_signal}, 'axi0_rdata', 'dynamic read-data report names RDATA input');
    is($read->{status_signal}, 'axi0_rresp', 'dynamic read-data report names RRESP input');
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], $expected_transactions, 'dynamic read-data report binds expected transactions');
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], \@completion_signals, 'dynamic read-data report uses generated completion pulses');
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp)], 'dynamic read-data report names generated inputs');
    is_deeply($read->{generated_rules}, \@capture_rules, 'dynamic read-data report names capture rules');
    is_deeply($read_data->{residue}, $expected_residue, 'dynamic read-data report keeps explicit residue');
}

sub assert_dynamic_read_data_burst_length_report {
    my ($read_data, $validation, $expected_transactions, $completion_validity) = @_;
    $validation //= 'report_only';
    $expected_transactions //= [qw(r0)];
    $completion_validity //= 'generated_dynamic_read_response_demux_last_beat_completion_pulse';
    my $runtime_validation = $validation eq 'runtime_assertion';
    my @transactions = @$expected_transactions;
    my @completion_signals = map { "axi0_${_}_complete" } @transactions;
    my @burst_length_storage = map { "axi0_${_}_arlen_q" } @transactions;
    my @burst_length_rules = map { "axi0_${_}_burst_length_capture" } @transactions;
    my @read_data_rules = map { "axi0_${_}_read_data_capture" } @transactions;
    my @expected_beat_storage = map { "axi0_${_}_expected_beats_q" } @transactions;
    my @beat_count_storage = map { "axi0_${_}_read_beat_count_q" } @transactions;
    my @beat_count_rules = map { ("axi0_${_}_beat_count_init", "axi0_${_}_read_beat_count") } @transactions;
    my @beat_count_assertions = map {
        (
            "axi0_${_}_arlen_within_max",
            "axi0_${_}_read_beat_before_expected_count",
            "axi0_${_}_rlast_on_expected_beat",
            "axi0_${_}_expected_final_beat_has_rlast",
        )
    } @transactions;
    my $read = $read_data->{read};

    ok($read_data->{generated_behavior}, 'dynamic burst-length read-data report marks generated behavior');
    is($read_data->{mode}, 'bounded_last_beat_read_data_contract', 'dynamic burst-length read-data report marks last-beat mode');
    is($read->{completion_source}, 'response_demux', 'dynamic burst-length read-data report binds capture to response-demux completion');
    is($read->{completion_validity}, $completion_validity, 'dynamic burst-length read-data report names generated last-beat validity');
    is($read->{capture_scope}, 'last_beat', 'dynamic burst-length read-data report marks last-beat capture scope');
    is($read->{interleaving_policy}, 'last_beat_by_rid', 'dynamic burst-length read-data report marks last-beat-by-RID interleaving');
    is($read->{burst_length_source}, 'arlen_signal', 'dynamic burst-length read-data report names ARLEN source');
    is($read->{burst_length_signal}, 'axi0_arlen', 'dynamic burst-length read-data report names ARLEN signal');
    is($read->{burst_length_signal_direction}, 'generated_input', 'dynamic burst-length read-data report marks ARLEN input direction');
    is($read->{burst_length_signal_width}, 8, 'dynamic burst-length read-data report marks ARLEN width');
    is($read->{burst_length_encoding}, 'axlen_plus_one', 'dynamic burst-length read-data report marks AXI LEN+1 encoding');
    is($read->{burst_length_capture}, 'transaction_request', 'dynamic burst-length read-data report marks request capture');
    is($read->{max_beats}, 16, 'dynamic burst-length read-data report marks max-beats');
    ok($read->{burst_length_generated_behavior}, 'dynamic burst-length read-data report marks generated raw ARLEN behavior');
    is($read->{burst_length_validation}, $validation, 'dynamic burst-length read-data report marks selected validation mode');
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], \@transactions, 'dynamic burst-length read-data report binds expected transactions');
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], \@completion_signals, 'dynamic burst-length read-data report uses generated completions');
    is_deeply([map { $_->{burst_length_storage} } @{$read->{transactions}}], \@burst_length_storage, 'dynamic burst-length read-data report names raw ARLEN storage');
    is_deeply([map { $_->{burst_length_capture_rule} } @{$read->{transactions}}], \@burst_length_rules, 'dynamic burst-length read-data report names ARLEN capture rules');
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp axi0_arlen)], 'dynamic burst-length read-data report adds ARLEN to generated inputs');
    is_deeply($read->{generated_burst_length_inputs}, [qw(axi0_arlen)], 'dynamic burst-length read-data report names generated ARLEN input');
    is_deeply($read->{generated_burst_length_storage}, \@burst_length_storage, 'dynamic burst-length read-data report names generated ARLEN storage');
    is_deeply($read->{generated_burst_length_rules}, \@burst_length_rules, 'dynamic burst-length read-data report names generated ARLEN rules');
    if ($runtime_validation) {
        ok($read->{beat_count_validation_generated_behavior}, 'dynamic runtime burst-length read-data report marks beat-count validation generated');
        is($read->{expected_beat_count_encoding}, 'arlen_plus_one', 'dynamic runtime burst-length read-data report marks ARLEN+1 expected-count encoding');
        is($read->{beat_count_match_source}, 'response_demux_matched_read_beat', 'dynamic runtime burst-length read-data report uses raw matched RID beat source');
        is($read->{beat_count_width}, 5, 'dynamic runtime burst-length read-data report marks beat-count width');
        is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], \@expected_beat_storage, 'dynamic runtime burst-length read-data report names expected-beat storage');
        is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], \@beat_count_storage, 'dynamic runtime burst-length read-data report names beat-count storage');
        is_deeply([map { $_->{beat_count_init_rule} } @{$read->{transactions}}], [map { "axi0_${_}_beat_count_init" } @transactions], 'dynamic runtime burst-length read-data report names beat-count init rules');
        is_deeply([map { $_->{beat_count_increment_rule} } @{$read->{transactions}}], [map { "axi0_${_}_read_beat_count" } @transactions], 'dynamic runtime burst-length read-data report names beat-count increment rules');
        is_deeply(
            $read->{transactions}[0]{beat_count_assertions},
            [
                "axi0_$transactions[0]_arlen_within_max",
                "axi0_$transactions[0]_read_beat_before_expected_count",
                "axi0_$transactions[0]_rlast_on_expected_beat",
                "axi0_$transactions[0]_expected_final_beat_has_rlast",
            ],
            'dynamic runtime burst-length read-data report names beat-count assertions',
        );
        is_deeply($read->{generated_expected_beat_count_storage}, \@expected_beat_storage, 'dynamic runtime burst-length read-data report names generated expected-beat storage');
        is_deeply($read->{generated_beat_count_storage}, \@beat_count_storage, 'dynamic runtime burst-length read-data report names generated beat-count storage');
        is_deeply($read->{generated_beat_count_rules}, \@beat_count_rules, 'dynamic runtime burst-length read-data report names generated beat-count rules');
        is_deeply($read->{generated_beat_count_assertions}, \@beat_count_assertions, 'dynamic runtime burst-length read-data report names generated beat-count assertions');
        is_deeply($read->{generated_rules}, [@read_data_rules, @burst_length_rules, @beat_count_rules], 'dynamic runtime burst-length read-data report names payload, ARLEN, and beat-count rules');
        is_deeply($read_data->{residue}, [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation)], 'dynamic runtime burst-length read-data report removes generated beat-count residue');
    } else {
        is_deeply($read->{generated_rules}, [@read_data_rules, @burst_length_rules], 'dynamic burst-length read-data report names payload and ARLEN capture rules');
        ok(!exists $read->{beat_count_validation_generated_behavior}, 'dynamic burst-length read-data report keeps runtime validation absent');
        ok(!exists $read->{generated_beat_count_rules}, 'dynamic burst-length read-data report has no beat-count rules');
        is_deeply($read_data->{residue}, [qw(generated_beat_count_validation multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation)], 'dynamic burst-length read-data report keeps explicit report-only residue');
    }
}

sub assert_dynamic_read_data_multi_beat_report {
    my ($read_data, $expected_transactions, $completion_validity) = @_;
    $expected_transactions //= [qw(r0)];
    $completion_validity //= 'generated_dynamic_read_response_demux_last_beat_completion_pulse';
    my $read = $read_data->{read};
    my @transactions = @$expected_transactions;
    my (%data_outputs, %status_outputs, %capture_rules);
    for my $transaction (@transactions) {
        $data_outputs{$transaction} = [map { "axi0_${transaction}_beat_rdata_$_" } 0 .. 15];
        $status_outputs{$transaction} = [map { "axi0_${transaction}_beat_rresp_$_" } 0 .. 15];
        $capture_rules{$transaction} = [map { "axi0_${transaction}_read_beat_${_}_capture" } 0 .. 15];
    }
    my @all_data_outputs = map { @{$data_outputs{$_}} } @transactions;
    my @all_status_outputs = map { @{$status_outputs{$_}} } @transactions;
    my @all_capture_rules = map { @{$capture_rules{$_}} } @transactions;

    ok($read_data->{generated_behavior}, 'dynamic multi-beat read-data report marks generated behavior');
    is($read_data->{mode}, 'bounded_multi_beat_read_data_contract', 'dynamic multi-beat read-data report marks multi-beat mode');
    is($read->{completion_source}, 'response_demux', 'dynamic multi-beat read-data report binds to response-demux completion');
    is($read->{completion_validity}, $completion_validity, 'dynamic multi-beat read-data report names generated last-beat validity');
    is($read->{capture_scope}, 'multi_beat', 'dynamic multi-beat read-data report marks multi-beat capture');
    is($read->{status_policy}, 'per_beat', 'dynamic multi-beat read-data report marks per-beat status');
    is($read->{status_aggregation}, 'worst_observed', 'dynamic multi-beat read-data report marks worst-observed aggregation');
    ok($read->{status_aggregation_generated_behavior}, 'dynamic multi-beat read-data report marks generated status aggregation');
    is($read->{interleaving_policy}, 'multi_beat_by_rid', 'dynamic multi-beat read-data report marks multi-beat-by-RID interleaving');
    is($read->{burst_length_source}, 'arlen_signal', 'dynamic multi-beat read-data report names ARLEN source');
    is($read->{burst_length_validation}, 'runtime_assertion', 'dynamic multi-beat read-data report marks runtime validation');
    is($read->{beat_match_source}, 'response_demux_matched_read_beat', 'dynamic multi-beat read-data report uses raw matched beat source');
    is($read->{beat_count_match_source}, 'response_demux_matched_read_beat', 'dynamic multi-beat read-data report uses matched beat-count source');
    is($read->{output_shape}, 'per_beat_output_bank', 'dynamic multi-beat read-data report marks output-bank shape');
    ok($read->{multi_beat_reassembly_generated_behavior}, 'dynamic multi-beat read-data report marks generated reassembly');
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], \@transactions, 'dynamic multi-beat read-data report binds expected transactions');
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], [map { "axi0_${_}_complete" } @transactions], 'dynamic multi-beat read-data report uses generated completions');
    is_deeply($read->{transactions}[0]{generated_data_outputs}, $data_outputs{$transactions[0]}, 'dynamic multi-beat read-data report names first transaction generated data lanes');
    is_deeply($read->{transactions}[0]{generated_status_outputs}, $status_outputs{$transactions[0]}, 'dynamic multi-beat read-data report names first transaction generated status lanes');
    is_deeply($read->{transactions}[0]{multi_beat_capture_rules}, $capture_rules{$transactions[0]}, 'dynamic multi-beat read-data report names first transaction per-lane capture rules');
    is_deeply($read->{generated_multi_beat_data_outputs}, \@all_data_outputs, 'dynamic multi-beat read-data report names generated data output banks');
    is_deeply($read->{generated_multi_beat_status_outputs}, \@all_status_outputs, 'dynamic multi-beat read-data report names generated status output banks');
    is_deeply($read->{generated_multi_beat_valid_outputs}, [map { "axi0_${_}_beat_valid" } @transactions], 'dynamic multi-beat read-data report names valid-mask outputs');
    is_deeply($read->{generated_multi_beat_length_outputs}, [map { "axi0_${_}_read_beats" } @transactions], 'dynamic multi-beat read-data report names length outputs');
    is_deeply($read->{generated_status_aggregate_outputs}, [map { "axi0_${_}_rresp" } @transactions], 'dynamic multi-beat read-data report names scalar aggregate outputs');
    is_deeply($read->{generated_multi_beat_output_init_rules}, [map { "axi0_${_}_read_data_output_init" } @transactions], 'dynamic multi-beat read-data report names output init rules');
    is_deeply($read->{generated_multi_beat_capture_rules}, \@all_capture_rules, 'dynamic multi-beat read-data report names generated capture rules');
    is_deeply($read->{generated_status_aggregate_update_rules}, [map { "axi0_${_}_rresp_aggregate" } @transactions], 'dynamic multi-beat read-data report names aggregate update rules');
    is_deeply($read_data->{residue}, [], 'dynamic multi-beat read-data report removes generated read-data residue');
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

sub assert_dynamic_same_id_reject_policy_generated_report {
    my ($ordering, $owner, %args) = @_;
    my $family = $args{family} // 'read';

    is($ordering->{mode}, 'dynamic_id_reuse_policy', "$owner marks dynamic same-ID policy mode");
    ok($ordering->{generated_behavior}, "$owner marks dynamic same-ID policy generated behavior true");
    ok(!exists($ordering->{families}), "$owner does not report generated concrete same-ID avoidance families");
    is_deeply($ordering->{residue}, [], "$owner reports generated dynamic same-ID residue");
    ok(@{$ordering->{source_anchors}}, "$owner carries source anchors into dynamic same-ID policy metadata");
    is_deeply(
        [sort keys %{$ordering->{dynamic_id_reuse_policy}}],
        [$family],
        "$owner reports the covered $family dynamic-ID reuse policy",
    );
    is_deeply(
        $ordering->{dynamic_id_reuse_policy}{$family},
        {
            policy => 'reject',
            implementation_status => 'generated_no_active_same_id_reject',
            enforcement => 'generated_no_active_same_id_assertions',
            assertion_enforcement => 'runtime_assertion',
            accepted_same_id_reuse => JSON::PP::false(),
            request_conflict_policy => 'no_active_same_id',
            generated_queue_behavior => JSON::PP::false(),
            generated_scoreboard_behavior => JSON::PP::false(),
            response_demux_covered => JSON::PP::true(),
            response_demux_mode => $args{response_demux_mode},
            response_demux_transaction_completion_source =>
                $args{response_demux_transaction_completion_source},
            covered_dynamic_transactions =>
                $args{covered_dynamic_transactions},
            generated_no_active_same_id_assertions =>
                $args{generated_no_active_same_id_assertions},
            generated_active_id_uniqueness_assertions =>
                $args{generated_active_id_uniqueness_assertions},
        },
        "$owner reports generated dynamic same-ID reject enforcement metadata",
    );
}

sub assert_dynamic_same_id_reject_policy_single_active_generated_report {
    my ($ordering, $owner, %args) = @_;
    my $family = $args{family} // 'read';

    is($ordering->{mode}, 'dynamic_id_reuse_policy', "$owner marks dynamic same-ID policy mode");
    ok($ordering->{generated_behavior}, "$owner marks dynamic same-ID policy generated behavior true");
    ok(!exists($ordering->{families}), "$owner does not report generated concrete same-ID avoidance families");
    is_deeply($ordering->{residue}, [], "$owner reports generated dynamic same-ID residue");
    ok(@{$ordering->{source_anchors}}, "$owner carries source anchors into dynamic same-ID policy metadata");
    is_deeply(
        [sort keys %{$ordering->{dynamic_id_reuse_policy}}],
        [$family],
        "$owner reports the covered $family dynamic-ID reuse policy",
    );
    is_deeply(
        $ordering->{dynamic_id_reuse_policy}{$family},
        {
            policy => 'reject',
            implementation_status => 'generated_single_active_reject',
            enforcement => 'generated_idle_or_releasing_assertions',
            assertion_enforcement => 'runtime_assertion',
            accepted_same_id_reuse => JSON::PP::false(),
            request_conflict_policy => 'no_active_same_id',
            generated_queue_behavior => JSON::PP::false(),
            generated_scoreboard_behavior => JSON::PP::false(),
            response_demux_covered => JSON::PP::true(),
            single_active_covered => JSON::PP::true(),
            single_active_request_policy => 'idle_or_releasing',
            response_demux_mode => $args{response_demux_mode},
            response_demux_transaction_completion_source =>
                $args{response_demux_transaction_completion_source},
            covered_dynamic_transactions =>
                $args{covered_dynamic_transactions},
            generated_idle_or_releasing_assertions =>
                $args{generated_idle_or_releasing_assertions},
            generated_response_active_match_assertions =>
                $args{generated_response_active_match_assertions},
            generated_completion_active_assertions =>
                $args{generated_completion_active_assertions},
        },
        "$owner reports generated single-active dynamic same-ID reject enforcement metadata",
    );
}

sub assert_dynamic_same_id_reject_policy_mixed_static_generated_report {
    my ($ordering, $owner, %args) = @_;
    my $family = $args{family} // 'read';

    is($ordering->{mode}, 'dynamic_id_reuse_policy', "$owner marks dynamic same-ID policy mode");
    ok($ordering->{generated_behavior}, "$owner marks dynamic same-ID policy generated behavior true");
    ok(!exists($ordering->{families}), "$owner does not report generated concrete same-ID avoidance families");
    is_deeply($ordering->{residue}, [], "$owner reports generated dynamic same-ID residue");
    ok(@{$ordering->{source_anchors}}, "$owner carries source anchors into dynamic same-ID policy metadata");
    is_deeply(
        [sort keys %{$ordering->{dynamic_id_reuse_policy}}],
        [$family],
        "$owner reports the covered $family dynamic-ID reuse policy",
    );
    is_deeply(
        $ordering->{dynamic_id_reuse_policy}{$family},
        {
            policy => 'reject',
            implementation_status => 'generated_mixed_static_id_exclusion_reject',
            enforcement => 'generated_static_id_exclusion_assertions',
            assertion_enforcement => 'runtime_assertion',
            accepted_same_id_reuse => JSON::PP::false(),
            request_conflict_policy => 'no_active_same_id',
            generated_queue_behavior => JSON::PP::false(),
            generated_scoreboard_behavior => JSON::PP::false(),
            response_demux_covered => JSON::PP::true(),
            mixed_dynamic_static_covered => JSON::PP::true(),
            mixed_dynamic_static_request_policy => 'onehot0_mixed_request',
            static_id_conflict_policy => 'static_concrete_ids_reserved',
            static_id_exclusion_policy => 'dynamic_id_must_not_equal_static_concrete_id',
            response_demux_mode => $args{response_demux_mode},
            response_demux_transaction_completion_source =>
                $args{response_demux_transaction_completion_source},
            covered_dynamic_transactions =>
                $args{covered_dynamic_transactions},
            covered_static_transactions =>
                $args{covered_static_transactions},
            static_id_reservations =>
                $args{static_id_reservations},
            generated_request_availability_assertions =>
                $args{generated_request_availability_assertions},
            generated_mixed_request_onehot_assertions =>
                $args{generated_mixed_request_onehot_assertions},
            generated_dynamic_request_static_id_exclusion_assertions =>
                $args{generated_dynamic_request_static_id_exclusion_assertions},
            generated_dynamic_active_static_id_exclusion_assertions =>
                $args{generated_dynamic_active_static_id_exclusion_assertions},
            generated_response_active_match_assertions =>
                $args{generated_response_active_match_assertions},
            generated_response_unique_match_assertions =>
                $args{generated_response_unique_match_assertions},
            generated_completion_active_assertions =>
                $args{generated_completion_active_assertions},
        },
        "$owner reports generated mixed dynamic/static dynamic same-ID reject enforcement metadata",
    );
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
