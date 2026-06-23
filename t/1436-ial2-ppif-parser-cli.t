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
use FSM::Support::HDLExternalValidation qw(missing_systemverilog_validation_tools);

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

subtest 'PPIF adapter parses the AXI manager capacity/status source shape' => sub {
    my $sample_path = sample_capacity_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_ppif(), $sample_path);

    is($result->{layer}, 'IAL2', 'capacity/status adapter result stays IAL2');
    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'adapter returns the manager capacity/status kind');
    is($result->{mode}, 'capacity-status-shell', 'adapter keeps the shell mode explicit');
    is($result->{report}{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'capacity/status report schema is selected');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status', 'source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status', 'source intent name is preserved');
    is($result->{report}{manager}{name}, 'axi0', 'manager object name is reported');
    is($result->{report}{manager}{protocol}, 'axi4', 'profile maps to manager protocol');
    is($result->{report}{capacity}{read}{max_pending}, 4, 'read pending capacity is reported');
    is($result->{report}{capacity}{write}{max_pending}, 2, 'write pending capacity is reported');
    is($result->{generated_ial1}{name}, 'axi0_capacity_status.isf', 'adapter exposes generated capacity/status IAL1 artifact');
    like($result->{generated_ial1}{text}, qr/\A\(actor axi0_capacity_status\b/, 'generated capacity/status IAL1 is .isf text');
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi0_capacity_status.fsm'],
        'adapter exposes generated capacity/status IAL0 .fsm file map',
    );
    is($result->{report}{layering}{direct_ial2_to_ial0}, 0, 'direct IAL2-to-IAL0 remains forbidden for capacity/status');
};

subtest 'PPIF adapter parses optional AXI manager ID-family metadata' => sub {
    my $sample_path = sample_capacity_id_family_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status ID-family sample exists');

    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_ppif(), sample_capacity_ppif_path());
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_id_family_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'ID-family sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-id-family', 'ID-family source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_id_family', 'ID-family source intent name is preserved');
    is($result->{report}{id_families}{write}{width}, 4, 'write ID-family width is reported');
    ok($result->{report}{id_families}{write}{present}, 'write ID-family is present');
    is($result->{report}{id_families}{write}{request_id_signal}, 'axi0_awid', 'write request ID signal is reported');
    is($result->{report}{id_families}{write}{response_id_signal}, 'axi0_bid', 'write response ID signal is reported');
    is($result->{report}{id_families}{read}{request_id_signal}, 'axi0_arid', 'read request ID signal is reported');
    is($result->{report}{id_families}{read}{response_id_signal}, 'axi0_rid', 'read response ID signal is reported');
    ok(scalar(@{$result->{report}{id_families}{read}{source_anchors} || []}) >= 6, 'ID-family report carries source anchors');
    is(
        $result->{generated_ial1}{text},
        $base->{generated_ial1}{text},
        'ID-family metadata does not change generated IAL1',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base->{generated_ial0}{files},
        'ID-family metadata does not change generated IAL0',
    );
};

subtest 'PPIF adapter parses optional AXI manager transaction-envelope metadata' => sub {
    my $sample_path = sample_capacity_transaction_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status transaction-envelope sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_transaction_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'transaction sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-transaction-envelope', 'transaction source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_transaction_envelope', 'transaction source intent name is preserved');
    is($result->{report}{transactions}[0]{kind}, 'write', 'write transaction kind is reported');
    is($result->{report}{transactions}[0]{name}, 'w0', 'write transaction name is reported');
    is($result->{report}{transactions}[0]{tag}, 'wr0', 'write transaction tag is reported');
    is_deeply($result->{report}{transactions}[0]{id}, { policy => 'auto' }, 'write transaction reports auto ID policy');
    is($result->{report}{transactions}[1]{kind}, 'read', 'read transaction kind is reported');
    is($result->{report}{transactions}[1]{request_event}, 'axi0_read_submit', 'read request event is reported as a structural field');
    is($result->{report}{transactions}[1]{completion_event}, 'axi0_read_complete', 'read completion event is reported as a structural field');
    is($result->{report}{transactions}[1]{id}{policy}, 'concrete', 'read transaction reports concrete ID policy');
    is($result->{report}{transactions}[1]{id}{value}, 3, 'read transaction reports concrete ID value');
    is($result->{report}{transactions}[1]{id}{family}, 'read', 'read transaction reports matching ID family');
    ok(scalar(@{$result->{report}{transactions}[1]{source_anchors} || []}) >= 6, 'transaction report carries source anchors');
    like($result->{generated_ial1}{text}, qr/\(input axi0_arid \(width 4\)\)/, 'transaction generated IAL1 declares concrete read request ID input');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rid \(width 4\)\)/, 'transaction generated IAL1 declares concrete read response ID input');
    like(
        $result->{generated_ial1}{text},
        qr/\(assert \(=> axi0_read_submit \(== axi0_arid 3\)\) "axi0 r0 request ID matches concrete ID"\)/,
        'transaction generated IAL1 asserts the concrete read request ID',
    );
    like(
        $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'},
        qr/\(\+assert[\s\S]*\(axi0_id_response_checks_assert_1 assert \(=> axi0_read_complete \(== axi0_rid 3\)\)/,
        'transaction generated IAL0 carries concrete read response ID assertion',
    );
    is($result->{report}{id_response_rule_engine}{mode}, 'concrete_id_assertions', 'transaction report exposes concrete-ID assertion engine');
    is_deeply($result->{report}{id_response_rule_engine}{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'transaction report lists used concrete-ID inputs');
    is_deeply(
        [map { $_->{event} } @{$result->{report}{id_response_rule_engine}{checks}}],
        [qw(axi0_read_submit axi0_read_complete)],
        'transaction report binds concrete-ID checks to direction-level events',
    );
};

subtest 'PPIF adapter parses AXI manager dynamic transaction-ID metadata without generated behavior' => sub {
    my $sample_path = sample_capacity_dynamic_transaction_id_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic transaction-ID sample exists');

    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_ppif(), sample_capacity_ppif_path());
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_transaction_id_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic transaction-ID sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-transaction-id', 'dynamic transaction-ID source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_transaction_id', 'dynamic transaction-ID source intent name is preserved');
    is(
        $result->{generated_ial1}{text},
        $base->{generated_ial1}{text},
        'dynamic transaction-ID metadata does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base->{generated_ial0}{files},
        'dynamic transaction-ID metadata does not alter generated IAL0 files',
    );
    unlike($isf, qr/\(input axi0_awid\b/, 'dynamic write request ID signal is not generated before capture behavior is owned');
    unlike($isf, qr/\(input axi0_bid\b/, 'dynamic write response ID signal is not generated before response matching is owned');
    unlike($isf, qr/\(input axi0_arid\b/, 'dynamic read request ID signal is not generated before capture behavior is owned');
    unlike($isf, qr/\(input axi0_rid\b/, 'dynamic read response ID signal is not generated before response matching is owned');
    ok(!exists $result->{report}{id_response_rule_engine}, 'dynamic metadata does not emit a concrete-ID assertion engine');
    assert_dynamic_transaction_id_report($result->{report}{transactions}, 'adapter report');
    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, 'dynamic behavior boundary remains explicit unsupported residue');
};

subtest 'PPIF adapter parses AXI manager dynamic write response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_write_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic write response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_write_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic write response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-write-response-demux', 'dynamic write response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_write_response_demux', 'dynamic write response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_w0_request\)/, 'dynamic write response-demux generated IAL1 declares the transaction request event');
    like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'dynamic write response-demux generated IAL1 declares AWID');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'dynamic write response-demux generated IAL1 declares BID');
    unlike($isf, qr/\(input axi0_w0_complete\b/, 'dynamic write response-demux generated IAL1 treats transaction completion as generated');
    like($isf, qr/\(output axi0_w0_complete\)/, 'dynamic write response-demux generated IAL1 exposes matched completion output');
    like($isf, qr/\(rule axi0_w0_dynamic_id_capture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) axi0_w0_complete\)\) \(! axi0_w0_dynamic_busy_q\)\)/, 'dynamic write response-demux generated IAL1 captures AWID on admitted requests');
    like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'dynamic write response-demux generated IAL1 matches BID before completion');
    like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q\)/, 'dynamic write response-demux generated IAL1 releases busy state on completion');
    assert_dynamic_write_response_demux_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager multiple dynamic write response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_write_response_demux_multi_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic write response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_write_response_demux_multi_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic write response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-write-response-demux-multi', 'multiple dynamic write response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_write_response_demux_multi', 'multiple dynamic write response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_w0_request\)/, 'multiple dynamic write response-demux generated IAL1 declares w0 request');
    like($isf, qr/\(input axi0_w1_request\)/, 'multiple dynamic write response-demux generated IAL1 declares w1 request');
    like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'multiple dynamic write response-demux generated IAL1 declares AWID');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'multiple dynamic write response-demux generated IAL1 declares BID');
    like($isf, qr/\(output axi0_w0_complete\)/, 'multiple dynamic write response-demux generated IAL1 exposes w0 completion');
    like($isf, qr/\(output axi0_w1_complete\)/, 'multiple dynamic write response-demux generated IAL1 exposes w1 completion');
    like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'multiple dynamic write response-demux generated IAL1 matches w0 BID before completion');
    like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'multiple dynamic write response-demux generated IAL1 matches w1 BID before completion');
    like($isf, qr/"axi0 write dynamic requests are mutually exclusive"/, 'multiple dynamic write response-demux generated IAL1 emits request onehot assertion');
    like($isf, qr/"axi0 write dynamic response matches at most one captured ID"/, 'multiple dynamic write response-demux generated IAL1 emits response unique-match assertion');
    assert_dynamic_write_response_demux_multi_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager dynamic read response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic read response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic read response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-response-demux', 'dynamic read response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux', 'dynamic read response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read response-demux generated IAL1 declares the transaction request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read response-demux generated IAL1 declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read response-demux generated IAL1 declares RID');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read response-demux generated IAL1 treats transaction completion as generated');
    like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read response-demux generated IAL1 exposes matched completion output');
    like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) \(! axi0_r0_dynamic_busy_q\)\)/, 'dynamic read response-demux generated IAL1 captures ARID on admitted requests');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'dynamic read response-demux generated IAL1 matches RID before completion');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q\)/, 'dynamic read response-demux generated IAL1 releases busy state on completion');
    assert_dynamic_read_response_demux_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager multiple dynamic read response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_response_demux_multi_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic read response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_response_demux_multi_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic read response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-response-demux-multi', 'multiple dynamic read response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_multi', 'multiple dynamic read response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read response-demux generated IAL1 declares r0 request');
    like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read response-demux generated IAL1 declares r1 request');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read response-demux generated IAL1 declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read response-demux generated IAL1 declares RID');
    like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read response-demux generated IAL1 exposes r0 completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read response-demux generated IAL1 exposes r1 completion');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multiple dynamic read response-demux generated IAL1 matches r0 RID before completion');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multiple dynamic read response-demux generated IAL1 matches r1 RID before completion');
    like($isf, qr/"axi0 read dynamic requests are mutually exclusive"/, 'multiple dynamic read response-demux generated IAL1 emits request onehot assertion');
    like($isf, qr/"axi0 read dynamic response matches at most one captured ID"/, 'multiple dynamic read response-demux generated IAL1 emits response unique-match assertion');
    assert_dynamic_read_response_demux_multi_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager multiple dynamic read burst-last response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic read burst-last response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic read burst-last response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-response-demux-multi-burst-last', 'multiple dynamic read burst-last response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last', 'multiple dynamic read burst-last response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read burst-last response-demux generated IAL1 declares r0 request');
    like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read burst-last response-demux generated IAL1 declares r1 request');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read burst-last response-demux generated IAL1 declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read burst-last response-demux generated IAL1 declares RID');
    like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic read burst-last response-demux generated IAL1 declares RLAST');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'multiple dynamic read burst-last response-demux generated IAL1 treats r0 completion as generated');
    unlike($isf, qr/\(input axi0_r1_complete\b/, 'multiple dynamic read burst-last response-demux generated IAL1 treats r1 completion as generated');
    like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read burst-last response-demux generated IAL1 exposes r0 matched last-beat completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read burst-last response-demux generated IAL1 exposes r1 matched last-beat completion');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic read burst-last response-demux generated IAL1 matches r0 RID and RLAST before completion');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic read burst-last response-demux generated IAL1 matches r1 RID and RLAST before completion');
    like($isf, qr/\(assert \(\| \(! axi0_read_complete\) \(\| \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\) \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\)\) "axi0 read dynamic response matches active captured ID"\)/, 'multiple dynamic read burst-last active-response assertion remains raw RID based');
    like($isf, qr/"axi0 read dynamic response matches at most one captured ID"/, 'multiple dynamic read burst-last response-demux generated IAL1 emits raw unique-match assertion');
    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager dynamic read burst-last response-demux behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_response_demux_burst_last_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic read burst-last response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_response_demux_burst_last_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic read burst-last response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-response-demux-burst-last', 'dynamic read burst-last response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_burst_last', 'dynamic read burst-last response-demux source intent name is preserved');
    like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read burst-last response-demux generated IAL1 declares the transaction request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read burst-last response-demux generated IAL1 declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read burst-last response-demux generated IAL1 declares RID');
    like($isf, qr/\(input axi0_rlast\)/, 'dynamic read burst-last response-demux generated IAL1 declares RLAST');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read burst-last response-demux generated IAL1 treats transaction completion as generated');
    like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read burst-last response-demux generated IAL1 exposes matched last-beat completion output');
    like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) \(! axi0_r0_dynamic_busy_q\)\)/, 'dynamic read burst-last response-demux generated IAL1 captures ARID on admitted requests');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic read burst-last response-demux generated IAL1 matches RID and RLAST before completion');
    like($isf, qr/\(assert \(\| \(! axi0_read_complete\) \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) "axi0 read dynamic response matches active captured ID"\)/, 'dynamic read burst-last active-response assertion remains raw RID based');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q\)/, 'dynamic read burst-last response-demux generated IAL1 releases busy state on completion');
    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager dynamic single-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data', 'dynamic read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data', 'dynamic read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'dynamic read-data sample keeps generated RID demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic read-data sample generates RRESP input');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'dynamic read-data sample generates scalar data output');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'dynamic read-data sample captures payload under generated dynamic completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/,
        'dynamic read-data sample lowers capture rule into generated .fsm',
    );
    assert_dynamic_read_response_demux_report($result->{report}, 'adapter dynamic read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'adapter dynamic read-data report',
        'generated_dynamic_read_response_demux_completion_pulse',
        transactions => [qw(r0)],
    );
};

subtest 'PPIF adapter parses AXI manager dynamic last-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_last_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic last-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_last_beat_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic last-beat read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-last-beat', 'dynamic last-beat read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_last_beat', 'dynamic last-beat read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic last-beat read-data sample keeps generated RID/RLAST demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'dynamic last-beat read-data sample generates RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic last-beat read-data sample generates RDATA input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'dynamic last-beat read-data sample generates scalar last data output');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'dynamic last-beat read-data sample captures payload under generated dynamic last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'dynamic last-beat read-data sample keeps dynamic burst-length metadata absent');
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'dynamic last-beat read-data sample lowers capture rule into generated .fsm',
    );
    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'adapter dynamic last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'adapter dynamic last-beat read-data report',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0)],
    );
};

subtest 'PPIF adapter parses AXI manager multiple dynamic single-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi', 'multiple dynamic read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi', 'multiple dynamic read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multiple dynamic read-data sample keeps r0 generated RID demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multiple dynamic read-data sample keeps r1 generated RID demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multiple dynamic read-data sample generates RDATA input');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'multiple dynamic read-data sample generates r0 scalar data output');
    like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'multiple dynamic read-data sample generates r1 scalar data output');
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/,
        'multiple dynamic read-data sample captures r1 payload under generated dynamic completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/,
        'multiple dynamic read-data sample lowers r1 capture rule into generated .fsm',
    );
    assert_dynamic_read_response_demux_multi_report($result->{report}, 'adapter multiple dynamic read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'adapter multiple dynamic read-data report',
        'generated_dynamic_read_response_demux_completion_pulse',
        transactions => [qw(r0 r1)],
    );
};

subtest 'PPIF adapter parses AXI manager multiple dynamic last-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_last_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic last-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_last_beat_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic last-beat read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi-last-beat', 'multiple dynamic last-beat read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi_last_beat', 'multiple dynamic last-beat read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic last-beat read-data sample keeps r0 generated RID/RLAST demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic last-beat read-data sample keeps r1 generated RID/RLAST demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic last-beat read-data sample generates RLAST input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data sample generates r0 scalar last data output');
    like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data sample generates r1 scalar last data output');
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/,
        'multiple dynamic last-beat read-data sample captures r1 payload under generated dynamic last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'multiple dynamic last-beat read-data sample keeps dynamic burst-length metadata absent');
    like(
        $fsm,
        qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/,
        'multiple dynamic last-beat read-data sample lowers r1 capture rule into generated .fsm',
    );
    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'adapter multiple dynamic last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'adapter multiple dynamic last-beat read-data report',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );
};

subtest 'PPIF adapter parses AXI manager multiple dynamic report-only burst-length read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_burst_length_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_burst_length_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic burst-length read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length', 'multiple dynamic burst-length read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length', 'multiple dynamic burst-length read-data source intent name is preserved');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multiple dynamic burst-length read-data sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data sample allocates r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data sample allocates r1 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'multiple dynamic burst-length read-data sample captures r1 raw ARLEN under request');
    unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'multiple dynamic burst-length read-data sample keeps runtime validation ungenerated');
    like(
        $fsm,
        qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/,
        'multiple dynamic burst-length read-data sample lowers r1 raw ARLEN capture into generated .fsm',
    );
    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'adapter multiple dynamic burst-length read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter multiple dynamic burst-length read-data report',
        'report_only',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );
};

subtest 'PPIF adapter parses AXI manager multiple dynamic runtime burst-length read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic runtime burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic runtime burst-length read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length-runtime-assertion', 'multiple dynamic runtime burst-length read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion', 'multiple dynamic runtime burst-length read-data source intent name is preserved');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multiple dynamic runtime burst-length read-data sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'multiple dynamic runtime burst-length read-data sample allocates r0 expected-beat storage');
    like($isf, qr/\(var axi0_r1_expected_beats_q \(width 5\)\)/, 'multiple dynamic runtime burst-length read-data sample allocates r1 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'multiple dynamic runtime burst-length read-data sample allocates r0 beat-count storage');
    like($isf, qr/\(var axi0_r1_read_beat_count_q \(width 5\)\)/, 'multiple dynamic runtime burst-length read-data sample allocates r1 beat-count storage');
    like($isf, qr/\(rule axi0_r1_beat_count_init axi0_r1_request\s+\(axi0_r1_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r1_read_beat_count_q 0\)\)/, 'multiple dynamic runtime burst-length read-data sample initializes r1 expected count under request');
    like($isf, qr/\(rule axi0_r1_read_beat_count \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\)\)\s+\(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'multiple dynamic runtime burst-length read-data sample increments r1 matched read-beat count');
    like($isf, qr/axi0 r1 ARLEN is within configured max beats/, 'multiple dynamic runtime burst-length read-data sample emits r1 ARLEN bound assertion');
    like($isf, qr/axi0 r1 RLAST appears only on the expected final read beat/, 'multiple dynamic runtime burst-length read-data sample emits r1 early-RLAST assertion');
    like($isf, qr/axi0 r1 expected final read beat has RLAST/, 'multiple dynamic runtime burst-length read-data sample emits r1 missing-RLAST assertion');
    like(
        $fsm,
        qr/\(-axi0_r1_read_beat_count\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\)\)\s+\(<- \(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/,
        'multiple dynamic runtime burst-length read-data sample lowers r1 beat-count increment into generated .fsm',
    );
    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'adapter multiple dynamic runtime burst-length read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter multiple dynamic runtime burst-length read-data report',
        'runtime_assertion',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );
};

subtest 'PPIF adapter parses AXI manager dynamic report-only burst-length read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_burst_length_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_burst_length_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic burst-length read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-burst-length', 'dynamic burst-length read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_burst_length', 'dynamic burst-length read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic burst-length read-data sample keeps generated RID/RLAST demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'dynamic burst-length read-data sample generates RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic burst-length read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic burst-length read-data sample generates RRESP input');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'dynamic burst-length read-data sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'dynamic burst-length read-data sample allocates raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'dynamic burst-length read-data sample captures raw ARLEN under request');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'dynamic burst-length read-data sample captures payload under generated dynamic last-beat completion',
    );
    unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'dynamic burst-length read-data sample keeps runtime validation ungenerated');
    like(
        $fsm,
        qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/,
        'dynamic burst-length read-data sample lowers raw ARLEN capture into generated .fsm',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'dynamic burst-length read-data sample lowers payload capture into generated .fsm',
    );
    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'adapter dynamic burst-length read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter dynamic burst-length read-data report',
        'report_only',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0)],
    );
};

subtest 'PPIF adapter parses AXI manager dynamic runtime burst-length read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic runtime burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic runtime burst-length read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-burst-length-runtime-assertion', 'dynamic runtime burst-length read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion', 'dynamic runtime burst-length read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic runtime burst-length read-data sample keeps generated RID/RLAST demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'dynamic runtime burst-length read-data sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'dynamic runtime burst-length read-data sample declares expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'dynamic runtime burst-length read-data sample declares beat-count storage');
    like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\)\)/, 'dynamic runtime burst-length read-data sample counts raw matched RID beats');
    like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'dynamic runtime burst-length read-data sample emits missing-RLAST assertion');
    like(
        $fsm,
        qr/\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/,
        'dynamic runtime burst-length read-data sample lowers beat-count increment into generated .fsm',
    );
    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'adapter dynamic runtime burst-length read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter dynamic runtime burst-length read-data report',
        'runtime_assertion',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0)],
    );
};

subtest 'PPIF adapter parses AXI manager dynamic multi-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status dynamic multi-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_beat_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dynamic multi-beat read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi-beat', 'dynamic multi-beat read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi_beat', 'dynamic multi-beat read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'dynamic multi-beat read-data sample keeps generated RID/RLAST demux rule');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'dynamic multi-beat read-data sample generates first RDATA lane');
    like($isf, qr/\(output axi0_r0_beat_rresp_15 \(width 2\)\)/, 'dynamic multi-beat read-data sample generates final RRESP lane');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'dynamic multi-beat read-data sample generates valid-mask output');
    like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'dynamic multi-beat read-data sample generates length output');
    like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)/, 'dynamic multi-beat read-data sample captures lane zero on raw matched beat');
    like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)/, 'dynamic multi-beat read-data sample updates scalar RRESP aggregate on worse status');
    like(
        $fsm,
        qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)/,
        'dynamic multi-beat read-data sample lowers first lane capture into generated .fsm',
    );
    assert_dynamic_read_response_demux_burst_last_report(
        $result->{report},
        'adapter dynamic multi-beat read-data response-demux report',
        residue => [qw(same_id_ordering)],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'adapter dynamic multi-beat read-data report',
        completion_validity => 'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0)],
    );
    is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'dynamic multi-beat read-data removes read-data/burst demux residue');
};

subtest 'PPIF adapter parses AXI manager multiple dynamic multi-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multiple dynamic multi-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multiple dynamic multi-beat read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-read-data-multi-transaction-multi-beat', 'multiple dynamic multi-beat read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat', 'multiple dynamic multi-beat read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic multi-beat read-data sample keeps generated r0 RID/RLAST demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'multiple dynamic multi-beat read-data sample keeps generated r1 RID/RLAST demux rule');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multiple dynamic multi-beat read-data sample generates first r0 RDATA lane');
    like($isf, qr/\(output axi0_r1_beat_rdata_15 \(width 32\)\)/, 'multiple dynamic multi-beat read-data sample generates final r1 RDATA lane');
    like($isf, qr/\(output axi0_r1_beat_rresp_15 \(width 2\)\)/, 'multiple dynamic multi-beat read-data sample generates final r1 RRESP lane');
    like($isf, qr/\(output axi0_r1_beat_valid \(width 16\)\)/, 'multiple dynamic multi-beat read-data sample generates r1 valid-mask output');
    like($isf, qr/\(output axi0_r1_read_beats \(width 5\)\)/, 'multiple dynamic multi-beat read-data sample generates r1 length output');
    like($isf, qr/\(rule axi0_r1_read_data_output_init axi0_r1_request\s+\(axi0_r1_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r1_beat_valid 16'b0\)\s+\(axi0_r1_read_beats 5'd0\)\)/, 'multiple dynamic multi-beat read-data sample clears r1 output bank on request');
    like($isf, qr/\(rule axi0_r1_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)/, 'multiple dynamic multi-beat read-data sample captures r1 lane zero on raw matched beat');
    like($isf, qr/\(rule axi0_r1_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'multiple dynamic multi-beat read-data sample updates r1 scalar RRESP aggregate on worse status');
    like(
        $fsm,
        qr/\(-axi0_r1_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)/,
        'multiple dynamic multi-beat read-data sample lowers r1 first lane capture into generated .fsm',
    );
    assert_dynamic_read_response_demux_multi_burst_last_report(
        $result->{report},
        'adapter multiple dynamic multi-beat read-data response-demux report',
        residue => [qw(same_id_ordering)],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'adapter multiple dynamic multi-beat read-data report',
        completion_validity => 'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );
    is_deeply($result->{report}{response_demux}{residue}, [qw(same_id_ordering)], 'multiple dynamic multi-beat read-data removes read-data/burst demux residue');
};

subtest 'PPIF adapter parses AXI manager transaction event dispatch' => sub {
    my $sample_path = sample_capacity_transaction_dispatch_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status transaction-event dispatch sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_transaction_dispatch_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'dispatch sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-transaction-event-dispatch', 'dispatch source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_transaction_event_dispatch', 'dispatch source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_w0_request\)/, 'dispatch generated IAL1 declares first write transaction request input');
    like($result->{generated_ial1}{text}, qr/\(input axi0_arid \(width 4\)\)/, 'dispatch generated IAL1 declares concrete read request ID input');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rid \(width 4\)\)/, 'dispatch generated IAL1 declares concrete read response ID input');
    like($result->{generated_ial1}{text}, qr/\(rule write_submit_only_occ0 \(& \(\| axi0_w0_request axi0_w1_request\)/, 'dispatch generated IAL1 uses write request OR fan-in');
    my %direction = map { $_->{direction} => $_ } @{$result->{report}{transaction_event_dispatch}{directions}};
    is($result->{report}{transaction_event_dispatch}{mode}, 'per_transaction_event_fanin', 'dispatch report marks fan-in mode');
    is_deeply($direction{write}{request_events}, [qw(axi0_w0_request axi0_w1_request)], 'dispatch report lists write request events');
    is($direction{write}{request_fanin}, '(| axi0_w0_request axi0_w1_request)', 'dispatch report carries write request fan-in expression');
    is($direction{read}{request_fanin}, 'axi0_r0_request', 'dispatch report keeps scalar read request fan-in');
    assert_boolean_capacity_accounting($result->{report}, 'adapter dispatch write accounting report', direction => 'write', rule_count => 12);
    assert_boolean_capacity_accounting($result->{report}, 'adapter dispatch read accounting report', direction => 'read', rule_count => 20);
    is($result->{report}{id_response_rule_engine}{mode}, 'concrete_id_assertions', 'dispatch report exposes concrete-ID assertion engine');
    is_deeply(
        [map { $_->{event} } @{$result->{report}{id_response_rule_engine}{checks}}],
        [qw(axi0_r0_request axi0_r0_complete)],
        'dispatch report binds concrete-ID checks to per-transaction events',
    );
};

subtest 'PPIF adapter parses AXI manager same-ID reject policy metadata' => sub {
    my $sample_path = sample_capacity_same_id_reject_policy_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status same-ID reject policy sample exists');

    my $base = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_transaction_dispatch_ppif(), sample_capacity_transaction_dispatch_ppif_path());
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_same_id_reject_policy_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'same-ID reject sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-same-id-reject-policy', 'same-ID reject source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_reject_policy', 'same-ID reject source intent name is preserved');
    is(
        $result->{generated_ial1}{text},
        $base->{generated_ial1}{text},
        'same-ID reject policy metadata does not alter generated IAL1 text',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base->{generated_ial0}{files},
        'same-ID reject policy metadata does not alter generated IAL0 files',
    );
    assert_same_id_reject_policy_report($result->{report}{same_id_ordering}, 'adapter report');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release same_id_ordering response_demux)],
        'same-ID reject policy report keeps generated queue behavior as residue',
    );
};

subtest 'PPIF adapter parses AXI manager same-ID issue-order queue policy admitted request pulses' => sub {
    my $sample_path = sample_capacity_same_id_issue_order_queue_policy_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status same-ID issue-order queue policy sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_same_id_issue_order_queue_policy_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'same-ID issue-order queue sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-same-id-issue-order-queue-policy', 'same-ID issue-order queue source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_issue_order_queue_policy', 'same-ID issue-order queue source intent name is preserved');
    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'same-ID issue-order queue sample declares admitted request pulse storage');
    like($isf, qr/\(rule axi0_r0_admitted_request \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\)\s+\(pulse axi0_r0_admitted_request_pulse_q\)\)/, 'same-ID issue-order queue sample emits admitted request pulse rule');
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi0_capacity_status.fsm'],
        'same-ID issue-order queue policy keeps the generated IAL0 artifact name stable',
    );
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(<1 \(axi0_r0_admitted_request_pulse_q 1\)\)/, 'same-ID issue-order queue sample lowers the admitted request pulse into IAL0');
    assert_same_id_issue_order_queue_policy_report($result->{report}{same_id_ordering}, 'adapter report');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release same_id_ordering response_demux)],
        'same-ID issue-order queue policy report keeps generated queue behavior as ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager same-ID queue-head response-demux metadata' => sub {
    my $sample_path = sample_capacity_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-same-id-queue-head-response-demux', 'same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_queue_head_response_demux', 'same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'same-ID queue-head demux sample keeps r0 admitted request pulse');
    like($isf, qr/\(var axi0_r1_admitted_request_pulse_q \(width 1\)\)/, 'same-ID queue-head demux sample keeps r1 admitted request pulse');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'same-ID queue-head demux sample declares generated queue slot state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_dequeue_enqueue_r1\b/, 'same-ID queue-head demux sample emits generated queue transition rules');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'same-ID queue-head demux sample emits generated r0 response-demux rule');
    like($isf, qr/\(output axi0_r0_complete\)/, 'same-ID queue-head demux sample emits generated r0 completion output');
    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter report');
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'adapter report marks queue-head demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'adapter report marks generated response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'adapter report accepts same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'adapter report marks generated queue behavior true');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager read multi-group same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read multi-group same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read multi-group same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-multi-group-same-id-queue-head-response-demux', 'read multi-group same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux', 'read multi-group same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_r2_admitted_request_pulse_q \(width 1\)\)/, 'read multi-group same-ID queue-head demux sample keeps r2 admitted request pulse');
    like($isf, qr/\(var axi0_r3_admitted_request_pulse_q \(width 1\)\)/, 'read multi-group same-ID queue-head demux sample keeps r3 admitted request pulse');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot0_r2_q \(width 1\)\)/, 'read multi-group same-ID queue-head demux sample declares generated RID 5 queue slot state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r2_dequeue_enqueue_r3\b/, 'read multi-group same-ID queue-head demux sample emits generated RID 5 transition rules');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read multi-group same-ID queue-head demux sample emits generated r2 response-demux rule');
    like($isf, qr/\(output axi0_r3_complete\)/, 'read multi-group same-ID queue-head demux sample emits generated r3 completion output');
    unlike($isf, qr/\baxi0_rdata\b/, 'read multi-group response-demux-only sample does not generate read-data inputs');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    assert_counted_admitted_request_boundary(
        $read_policy->{admitted_request_boundary},
        'adapter read multi-group admitted boundary',
        pending_storage => 'axi0_pending_reads_q',
        max_pending => 4,
        completion_fanin => '(| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)',
        request_count_expression => '(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))',
        generated_assertions => [
            qw(
                axi0_read_id3_same_id_issue_order_request_onehot0
                axi0_read_id5_same_id_issue_order_request_onehot0
            )
        ],
    );
    is_deeply(
        [map { $_->{concrete_id} } @{$read_policy->{generated_queues} || []}],
        [3, 5],
        'read multi-group same-ID policy reports both generated queue groups',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'read multi-group same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
    assert_counted_same_id_capacity_accounting(
        $result->{report},
        'adapter read multi-group counted capacity report',
        direction => 'read',
        rule_count => 30,
        request_count_expression => '(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))',
        counted_request_events => [qw(axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)],
        counted_request_terms => [
            '(| axi0_r0_request axi0_r1_request)',
            '(| axi0_r2_request axi0_r3_request)',
        ],
        counted_request_groups => [
            {
                concrete_id    => 3,
                request_events => [qw(axi0_r0_request axi0_r1_request)],
                request_fanin  => '(| axi0_r0_request axi0_r1_request)',
            },
            {
                concrete_id    => 5,
                request_events => [qw(axi0_r2_request axi0_r3_request)],
                request_fanin  => '(| axi0_r2_request axi0_r3_request)',
            },
        ],
    );
    assert_boolean_capacity_accounting($result->{report}, 'adapter read multi-group write capacity report', direction => 'write', rule_count => 12);
};

subtest 'PPIF adapter parses AXI manager read single-beat multi-group same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read single-beat multi-group same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read single-beat multi-group same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-single-beat-multi-group-same-id-queue-head-response-demux', 'read single-beat multi-group same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux', 'read single-beat multi-group same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_r2_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat multi-group same-ID queue-head demux sample keeps r2 admitted request pulse');
    like($isf, qr/\(var axi0_r3_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat multi-group same-ID queue-head demux sample keeps r3 admitted request pulse');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot0_r2_q \(width 1\)\)/, 'read single-beat multi-group same-ID queue-head demux sample declares generated RID 5 queue slot state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r2_dequeue_enqueue_r3\b/, 'read single-beat multi-group same-ID queue-head demux sample emits generated RID 5 transition rules');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read single-beat multi-group same-ID queue-head demux sample emits generated r2 response-demux rule without RLAST');
    like($isf, qr/\(output axi0_r3_complete\)/, 'read single-beat multi-group same-ID queue-head demux sample emits generated r3 completion output');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat multi-group response-demux-only sample does not generate or consume RLAST');
    unlike($isf, qr/\baxi0_rdata\b/, 'read single-beat multi-group response-demux-only sample does not generate read-data inputs');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read single-beat multi-group report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{implementation_status}, 'generated_read_single_beat_queue_head_demux', 'read single-beat multi-group same-ID policy reports generated single-beat queue boundary');
    is_deeply(
        [map { $_->{concrete_id} } @{$read_policy->{generated_queues} || []}],
        [3, 5],
        'read single-beat multi-group same-ID policy reports both generated queue groups',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'read single-beat multi-group same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager read single-beat same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read single-beat same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read single-beat same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-single-beat-same-id-queue-head-response-demux', 'read single-beat same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux', 'read single-beat same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat same-ID queue-head demux sample keeps r0 admitted request pulse');
    like($isf, qr/\(var axi0_r1_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat same-ID queue-head demux sample keeps r1 admitted request pulse');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'read single-beat same-ID queue-head demux sample declares generated queue slot state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_dequeue_enqueue_r1\b/, 'read single-beat same-ID queue-head demux sample emits generated queue transition rules');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read single-beat same-ID queue-head demux sample emits generated r0 response-demux rule');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat same-ID queue-head demux sample does not generate or consume RLAST');
    like($isf, qr/\(output axi0_r0_complete\)/, 'read single-beat same-ID queue-head demux sample emits generated r0 completion output');
    assert_same_id_read_single_beat_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter report');
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'adapter report marks read single-beat queue-head demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'adapter report marks generated read single-beat response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'adapter report accepts read single-beat same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'adapter report marks generated read single-beat queue behavior true');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'read single-beat same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager read single-beat same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read single-beat same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read single-beat same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-single-beat-same-id-queue-head-read-data', 'read single-beat same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data', 'read single-beat same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read single-beat queue-head read-data sample emits generated r0 queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read single-beat queue-head read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read single-beat queue-head read-data sample generates RRESP input');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'read single-beat queue-head read-data sample captures r0 payload under generated completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/,
        'read single-beat queue-head read-data sample lowers r0 capture rule into generated .fsm',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat queue-head read-data sample does not generate or consume RLAST');
    assert_same_id_read_single_beat_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter queue-head read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'adapter queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
    );
};

subtest 'PPIF adapter parses AXI manager read single-beat depth-3 same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read single-beat depth-3 same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read single-beat depth-3 same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-single-beat-depth3-same-id-queue-head-read-data', 'read single-beat depth-3 same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data', 'read single-beat depth-3 same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read single-beat depth-3 queue-head read-data sample emits generated r2 queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read single-beat depth-3 queue-head read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read single-beat depth-3 queue-head read-data sample generates RRESP input');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_rdata axi0_rdata\)\s+\(axi0_r2_rresp axi0_rresp\)\)/,
        'read single-beat depth-3 queue-head read-data sample captures r2 payload under generated completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_rresp> axi0_rresp\)\)/,
        'read single-beat depth-3 queue-head read-data sample lowers r2 capture rule into generated .fsm',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat depth-3 queue-head read-data sample does not generate or consume RLAST');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $result->{report}{read_data},
        'adapter depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
};

subtest 'PPIF adapter parses AXI manager read burst-last depth-3 same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read burst-last depth-3 same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read burst-last depth-3 same-ID queue-head response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-response-demux', 'read burst-last depth-3 same-ID queue-head response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux', 'read burst-last depth-3 same-ID queue-head response-demux source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read burst-last depth-3 queue-head response-demux sample emits RLAST-gated r2 queue-head demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'read burst-last depth-3 queue-head response-demux sample generates RLAST input');
    like($isf, qr/\(output axi0_r2_complete\)/, 'read burst-last depth-3 queue-head response-demux sample generates r2 completion output');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot2_r2_q \(width 1\)\)/, 'read burst-last depth-3 queue-head response-demux sample declares slot2 r2 queue state');
    like($isf, qr/read same-ID non-last response beat does not dequeue/, 'read burst-last depth-3 queue-head response-demux sample emits non-last no-dequeue assertion');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read burst-last depth-3 queue-head response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
};

subtest 'PPIF adapter parses AXI manager read burst-last depth-3 same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read burst-last depth-3 same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read burst-last depth-3 same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-read-data', 'read burst-last depth-3 same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data', 'read burst-last depth-3 same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read burst-last depth-3 queue-head read-data sample emits RLAST-gated r2 queue-head demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'read burst-last depth-3 queue-head read-data sample generates RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read burst-last depth-3 queue-head read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read burst-last depth-3 queue-head read-data sample generates RRESP input');
    like($isf, qr/\(output axi0_r2_last_rdata \(width 32\)\)/, 'read burst-last depth-3 queue-head read-data sample generates r2 last data output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'read burst-last depth-3 queue-head read-data sample captures r2 payload under generated last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'read burst-last depth-3 queue-head read-data sample does not generate ARLEN capture');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'read burst-last depth-3 queue-head read-data sample lowers r2 scalar last-beat capture');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read burst-last depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'adapter read burst-last depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
};

subtest 'PPIF adapter parses AXI manager read burst-last depth-3 same-ID queue-head burst-length behavior' => sub {
    my $sample_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read burst-last depth-3 same-ID queue-head burst-length sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read burst-last depth-3 same-ID queue-head burst-length sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-burst-length', 'read burst-last depth-3 same-ID queue-head burst-length source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length', 'read burst-last depth-3 same-ID queue-head burst-length source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read burst-last depth-3 queue-head burst-length sample emits RLAST-gated r2 queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read burst-last depth-3 queue-head burst-length sample generates ARLEN input');
    like($isf, qr/\(var axi0_r2_arlen_q \(width 8\)\)/, 'read burst-last depth-3 queue-head burst-length sample declares r2 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r2_burst_length_capture axi0_r2_request\s+\(axi0_r2_arlen_q axi0_arlen\)\)/, 'read burst-last depth-3 queue-head burst-length sample captures r2 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'read burst-last depth-3 queue-head burst-length sample captures r2 payload under generated last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'read burst-last depth-3 queue-head burst-length sample does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'read burst-last depth-3 queue-head burst-length sample does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r2_burst_length_capture\s+<axi0_r2_request\s+\(<- \(axi0_r2_arlen_q axi0_arlen\)\)\s+\)/, 'read burst-last depth-3 queue-head burst-length sample lowers r2 raw ARLEN capture');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'read burst-last depth-3 queue-head burst-length sample lowers r2 scalar last-beat capture');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read burst-last depth-3 queue-head burst-length response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter read burst-last depth-3 queue-head burst-length report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
};

subtest 'PPIF adapter parses AXI manager read burst-last depth-3 same-ID queue-head burst-length runtime validation behavior' => sub {
    my $sample_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read burst-last depth-3 same-ID queue-head burst-length runtime sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-burst-length-runtime-assertion', 'read burst-last depth-3 same-ID queue-head burst-length runtime source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion', 'read burst-last depth-3 same-ID queue-head burst-length runtime source intent name is preserved');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read burst-last depth-3 queue-head runtime sample declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'read burst-last depth-3 queue-head runtime sample declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'read burst-last depth-3 queue-head runtime sample declares r2 beat-count storage');
    like($isf, qr/\(rule axi0_r2_beat_count_init axi0_r2_request\s+\(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r2_read_beat_count_q 0\)\)/, 'read burst-last depth-3 queue-head runtime sample initializes r2 expected count from ARLEN');
    like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)/, 'read burst-last depth-3 queue-head runtime sample counts raw matched r2 queue-head read beats');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'read burst-last depth-3 queue-head runtime sample keeps r2 scalar last-beat capture',
    );
    like($fsm, qr/\(-axi0_r2_beat_count_init\s+<axi0_r2_request\s+\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r2_read_beat_count_q 0\)\)/, 'read burst-last depth-3 queue-head runtime sample lowers r2 expected-beat initialization');
    like(
        $fsm,
        qr/\(-axi0_r2_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/,
        'read burst-last depth-3 queue-head runtime sample lowers r2 matched-beat increment',
    );
    unlike($isf, qr/\baxi0_r2_beat_valid\b/, 'read burst-last depth-3 queue-head runtime sample does not generate multi-beat valid output');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read burst-last depth-3 queue-head runtime validation response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter read burst-last depth-3 queue-head runtime validation report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
};

subtest 'PPIF adapter parses AXI manager read burst-last depth-3 same-ID queue-head multi-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read burst-last depth-3 same-ID queue-head multi-beat sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-multi-beat-read-data', 'read burst-last depth-3 same-ID queue-head multi-beat source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data', 'read burst-last depth-3 same-ID queue-head multi-beat source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read burst-last depth-3 multi-beat sample keeps r2 RLAST-gated queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read burst-last depth-3 multi-beat sample declares ARLEN as a generated width-8 input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read burst-last depth-3 multi-beat sample declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read burst-last depth-3 multi-beat sample declares generated RRESP input');
    like($isf, qr/\(output axi0_r2_beat_rdata_0 \(width 32\)\)/, 'read burst-last depth-3 multi-beat sample declares r2 beat data output bank');
    like($isf, qr/\(output axi0_r2_beat_rresp_0 \(width 2\)\)/, 'read burst-last depth-3 multi-beat sample declares r2 beat status output bank');
    like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'read burst-last depth-3 multi-beat sample declares r2 scalar status aggregate output');
    like($isf, qr/\(output axi0_r2_beat_valid \(width 16\)\)/, 'read burst-last depth-3 multi-beat sample declares r2 valid-mask output');
    like($isf, qr/\(output axi0_r2_read_beats \(width 5\)\)/, 'read burst-last depth-3 multi-beat sample declares r2 length output');
    like($isf, qr/\(rule axi0_r2_read_data_output_init axi0_r2_request[\s\S]*\(axi0_r2_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r2_rresp 2'd0\)[\s\S]*\(axi0_r2_beat_valid 16'b0\)[\s\S]*\(axi0_r2_read_beats 5'd0\)\)/, 'read burst-last depth-3 multi-beat sample clears r2 output bank on request');
    like($isf, qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r2_read_beats 5'd1\)\)/, 'read burst-last depth-3 multi-beat sample captures r2 lane 0 under raw matched queue-head beat');
    like($isf, qr/\(rule axi0_r2_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)\s+\(axi0_r2_rresp axi0_rresp\)\)/, 'read burst-last depth-3 multi-beat sample updates r2 scalar aggregate under raw matched queue-head beat');
    like($fsm, qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r2_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r2_read_beats> 5'd1\)\)/, 'read burst-last depth-3 multi-beat sample lowers r2 lane 0 payload, valid mask, and length');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter read burst-last depth-3 multi-beat response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'adapter read burst-last depth-3 multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'adapter depth-3 multi-beat report accepts read same-ID queue-head reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'adapter depth-3 multi-beat report marks generated queue behavior true');
};

subtest 'PPIF adapter parses AXI manager read single-beat multi-group same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read single-beat multi-group same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read single-beat multi-group same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-single-beat-multi-group-same-id-queue-head-read-data', 'read single-beat multi-group same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data', 'read single-beat multi-group same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read single-beat multi-group queue-head read-data sample emits generated r2 queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read single-beat multi-group queue-head read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read single-beat multi-group queue-head read-data sample generates RRESP input');
    like(
        $isf,
        qr/\(rule axi0_r3_read_data_capture axi0_r3_complete\s+\(axi0_r3_rdata axi0_rdata\)\s+\(axi0_r3_rresp axi0_rresp\)\)/,
        'read single-beat multi-group queue-head read-data sample captures r3 payload under generated completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_rresp> axi0_rresp\)\)/,
        'read single-beat multi-group queue-head read-data sample lowers r3 capture rule into generated .fsm',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat multi-group queue-head read-data sample does not generate or consume RLAST');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $result->{report}{read_data},
        'adapter multi-group queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_read_data_case_args($case_name);
    subtest "PPIF adapter parses AXI manager $case{owner} behavior" => sub {
        ok(-f $case{path}->(), "tracked runnable PPIF capacity/status $case{owner} sample exists");
        assert_ppif_queue_head_read_data_adapter_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_last_beat_read_data_case_args($case_name);
    subtest "PPIF adapter parses AXI manager $case{owner} behavior" => sub {
        ok(-f $case{path}->(), "tracked runnable PPIF capacity/status $case{owner} sample exists");
        assert_ppif_queue_head_last_beat_read_data_adapter_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    read_burst_multi_depth3_runtime_assertion
    read_burst_mixed_depth3_depth2_runtime_assertion
)) {
    my %case = queue_head_depth3_last_beat_burst_length_case_args($case_name);
    subtest "PPIF adapter parses AXI manager $case{owner} behavior" => sub {
        ok(-f $case{path}->(), "tracked runnable PPIF capacity/status $case{owner} sample exists");
        assert_ppif_queue_head_last_beat_burst_length_adapter_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_multi_beat_read_data_case_args($case_name);
    subtest "PPIF adapter parses AXI manager $case{owner} behavior" => sub {
        ok(-f $case{path}->(), "tracked runnable PPIF capacity/status $case{owner} sample exists");
        assert_ppif_queue_head_multi_beat_read_data_adapter_case(%case);
    };
}

subtest 'PPIF adapter parses AXI manager read last-beat same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read last-beat same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read last-beat same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-read-data', 'read last-beat same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data', 'read last-beat same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read last-beat queue-head read-data sample emits generated RLAST-gated r0 queue-head demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'read last-beat queue-head read-data sample generates RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read last-beat queue-head read-data sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read last-beat queue-head read-data sample generates RRESP input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'read last-beat queue-head read-data sample generates r0 last data output');
    like($isf, qr/\(output axi0_r0_last_rresp \(width 2\)\)/, 'read last-beat queue-head read-data sample generates r0 last status output');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'read last-beat queue-head read-data sample captures r0 payload under generated queue-head last-beat completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'read last-beat queue-head read-data sample lowers r0 capture rule into generated .fsm',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'read last-beat queue-head read-data sample does not generate ARLEN capture');
    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter queue-head last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'adapter queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
};

subtest 'PPIF adapter parses AXI manager read multi-group last-beat same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read multi-group last-beat same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read multi-group last-beat same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-multi-group-last-beat-same-id-queue-head-read-data', 'read multi-group last-beat same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data', 'read multi-group last-beat same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read multi-group last-beat queue-head read-data sample emits r2 RID5 response-demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'read multi-group last-beat queue-head read-data sample emits r3 RID5 response-demux rule');
    like($isf, qr/\(output axi0_r2_last_rdata \(width 32\)\)/, 'read multi-group last-beat queue-head read-data sample generates r2 scalar data output');
    like($isf, qr/\(output axi0_r2_last_rresp \(width 2\)\)/, 'read multi-group last-beat queue-head read-data sample generates r2 scalar status output');
    like($isf, qr/\(output axi0_r3_last_rdata \(width 32\)\)/, 'read multi-group last-beat queue-head read-data sample generates r3 scalar data output');
    like($isf, qr/\(output axi0_r3_last_rresp \(width 2\)\)/, 'read multi-group last-beat queue-head read-data sample generates r3 scalar status output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'read multi-group last-beat queue-head read-data sample captures r2 payload under generated queue-head last-beat completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/,
        'read multi-group last-beat queue-head read-data sample lowers r2 scalar capture into generated .fsm',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'read multi-group last-beat queue-head read-data sample does not generate ARLEN capture');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group queue-head last-beat read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'adapter multi-group queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
};

subtest 'PPIF adapter parses AXI manager read last-beat same-ID queue-head burst-length behavior' => sub {
    my $sample_path = sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read last-beat same-ID queue-head burst-length sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read last-beat same-ID queue-head burst-length sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-burst-length', 'read last-beat same-ID queue-head burst-length source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length', 'read last-beat same-ID queue-head burst-length source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read last-beat queue-head burst-length sample emits generated RLAST-gated r0 queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read last-beat queue-head burst-length sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'read last-beat queue-head burst-length sample declares r0 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'read last-beat queue-head burst-length sample captures r0 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'read last-beat queue-head burst-length sample keeps r0 payload capture under generated queue-head last-beat completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/,
        'read last-beat queue-head burst-length sample lowers r0 raw ARLEN capture into generated .fsm',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'read last-beat queue-head burst-length sample lowers r0 read-data capture into generated .fsm',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'read last-beat queue-head report-only burst-length sample does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'read last-beat queue-head report-only burst-length sample does not generate beat-count storage');
    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter queue-head burst-length response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
};

subtest 'PPIF adapter parses AXI manager read last-beat same-ID queue-head burst-length runtime validation' => sub {
    my $sample_path = sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read last-beat same-ID queue-head burst-length runtime sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read last-beat same-ID queue-head burst-length runtime sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-burst-length-runtime-assertion', 'read last-beat same-ID queue-head burst-length runtime source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion', 'read last-beat same-ID queue-head burst-length runtime source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read last-beat queue-head runtime sample keeps RLAST-gated r0 queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read last-beat queue-head runtime sample generates ARLEN input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'read last-beat queue-head runtime sample declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'read last-beat queue-head runtime sample declares r0 beat-count storage');
    like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\)\)/, 'read last-beat queue-head runtime sample counts raw matched queue-head read beats');
    like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'read last-beat queue-head runtime sample emits r0 missing-RLAST assertion');
    like(
        $fsm,
        qr/\(axi0_read_data_beat_count_checks_assert_1 assert \(\| \(! \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\)\) \(< axi0_r0_read_beat_count_q axi0_r0_expected_beats_q\)\)/,
        'read last-beat queue-head runtime sample lowers r0 queue-head over-count assertion into generated .fsm',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\)\)\s+\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/,
        'read last-beat queue-head runtime sample lowers r0 matched-beat increment into generated .fsm',
    );
    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter queue-head burst-length runtime response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter queue-head burst-length runtime read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
};

subtest 'PPIF adapter parses AXI manager read multi-group last-beat same-ID queue-head burst-length runtime validation' => sub {
    my $sample_path = sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read multi-group last-beat same-ID queue-head burst-length runtime sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read multi-group last-beat same-ID queue-head burst-length runtime sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-multi-group-last-beat-same-id-queue-head-burst-length-runtime-assertion', 'read multi-group last-beat same-ID queue-head burst-length runtime source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion', 'read multi-group last-beat same-ID queue-head burst-length runtime source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read multi-group last-beat queue-head runtime sample emits r2 RID5 response-demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'read multi-group last-beat queue-head runtime sample emits r3 RID5 response-demux rule');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'read multi-group last-beat queue-head runtime sample declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'read multi-group last-beat queue-head runtime sample declares r2 beat-count storage');
    like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)/, 'read multi-group last-beat queue-head runtime sample counts raw matched r2 queue-head read beats');
    like($isf, qr/axi0 r2 expected final read beat has RLAST/, 'read multi-group last-beat queue-head runtime sample emits r2 missing-RLAST assertion');
    like(
        $fsm,
        qr/\(-axi0_r2_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/,
        'read multi-group last-beat queue-head runtime sample lowers r2 matched-beat increment into generated .fsm',
    );
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group queue-head burst-length runtime response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'adapter multi-group queue-head burst-length runtime read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
};

subtest 'PPIF adapter parses AXI manager read multi-beat same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read multi-beat same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read multi-beat same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-multi-beat-same-id-queue-head-read-data', 'read multi-beat same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data', 'read multi-beat same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read multi-beat queue-head sample keeps RLAST-gated r0 queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'read multi-beat queue-head sample generates ARLEN input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read multi-beat queue-head sample generates RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read multi-beat queue-head sample generates RRESP input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'read multi-beat queue-head sample declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'read multi-beat queue-head sample declares r0 beat-count storage');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'read multi-beat queue-head sample generates r0 beat data output bank');
    like($isf, qr/\(output axi0_r0_beat_rresp_0 \(width 2\)\)/, 'read multi-beat queue-head sample generates r0 beat status output bank');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'read multi-beat queue-head sample generates r0 scalar status aggregate output');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'read multi-beat queue-head sample generates r0 valid-mask output');
    like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'read multi-beat queue-head sample generates r0 length output');
    like($isf, qr/\(rule axi0_r0_read_data_output_init axi0_r0_request[\s\S]*\(axi0_r0_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r0_rresp 2'd0\)[\s\S]*\(axi0_r0_beat_valid 16'b0\)[\s\S]*\(axi0_r0_read_beats 5'd0\)\)/, 'read multi-beat queue-head sample clears the r0 output bank on request');
    like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r0_read_beats 5'd1\)\)/, 'read multi-beat queue-head sample captures lane 0 under raw matched queue-head beat plus beat index');
    like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'read multi-beat queue-head sample updates scalar aggregate under raw matched queue-head beat');
    like($fsm, qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd1\)\)/, 'read multi-beat queue-head sample lowers lane 0 payload, valid mask, and length into generated .fsm');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter queue-head multi-beat read-data response-demux report',
        residue => [],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'adapter queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'adapter report accepts read multi-beat same-ID queue-head reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'adapter report marks read multi-beat queue-head generated queue behavior true');
};

subtest 'PPIF adapter parses AXI manager read multi-group same-ID queue-head read-data behavior' => sub {
    my $sample_path = sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read multi-group same-ID queue-head read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read multi-group same-ID queue-head read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-multi-group-same-id-queue-head-read-data', 'read multi-group same-ID queue-head read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data', 'read multi-group same-ID queue-head read-data source intent name is preserved');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read multi-group queue-head read-data sample emits r2 RID5 response-demux rule');
    like($isf, qr/\(output axi0_r2_beat_rdata_0 \(width 32\)\)/, 'read multi-group queue-head read-data sample generates r2 beat data output bank');
    like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'read multi-group queue-head read-data sample generates r2 scalar status aggregate output');
    like($isf, qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r2_read_beats 5'd1\)\)/, 'read multi-group queue-head read-data sample captures r2 lane 0 under RID5 queue-head match');
    like($fsm, qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r2_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r2_read_beats> 5'd1\)\)/, 'read multi-group queue-head read-data sample lowers r2 lane 0 payload, valid mask, and length');
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group queue-head read-data response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'adapter multi-group queue-head read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{concrete_id} } @{$read_policy->{generated_queues} || []}], [3, 5], 'adapter multi-group read-data report keeps both generated queue groups');
    ok($read_policy->{accepted_same_id_reuse}, 'adapter report accepts read multi-group same-ID queue-head reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'adapter report marks read multi-group queue-head generated queue behavior true');
};

subtest 'PPIF adapter parses AXI manager write same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_write_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status write same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_write_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'write same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-write-same-id-queue-head-response-demux', 'write same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_write_same_id_queue_head_response_demux', 'write same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_w0_admitted_request_pulse_q \(width 1\)\)/, 'write same-ID queue-head demux sample keeps w0 admitted request pulse');
    like($isf, qr/\(var axi0_w1_admitted_request_pulse_q \(width 1\)\)/, 'write same-ID queue-head demux sample keeps w1 admitted request pulse');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot0_w0_q \(width 1\)\)/, 'write same-ID queue-head demux sample declares generated queue slot state');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_dequeue_enqueue_w1\b/, 'write same-ID queue-head demux sample emits generated queue transition rules');
    like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete \(== axi0_bid 4'd3\) axi0_write_id3_same_id_issue_order_slot0_w0_q\)/, 'write same-ID queue-head demux sample emits generated w0 response-demux rule');
    like($isf, qr/\(output axi0_w0_complete\)/, 'write same-ID queue-head demux sample emits generated w0 completion output');
    assert_same_id_write_queue_head_response_demux_report($result->{report}{response_demux}, 'adapter report');
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'adapter report marks write queue-head demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'adapter report marks generated write response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'adapter report accepts write same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'adapter report marks generated write queue behavior true');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'write same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager write depth-3 same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status write depth-3 same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'write depth-3 same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-write-depth3-same-id-queue-head-response-demux', 'write depth-3 same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux', 'write depth-3 same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_w2_admitted_request_pulse_q \(width 1\)\)/, 'write depth-3 same-ID queue-head demux sample keeps w2 admitted request pulse');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot2_w2_q \(width 1\)\)/, 'write depth-3 same-ID queue-head demux sample declares slot2 queue state');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_w1_enqueue_w2\b/, 'write depth-3 same-ID queue-head demux sample emits third-slot fill transition rules');
    like($isf, qr/\(rule axi0_w2_response_demux \(& axi0_write_complete \(== axi0_bid 4'd3\) axi0_write_id3_same_id_issue_order_slot0_w2_q\)/, 'write depth-3 same-ID queue-head demux sample emits generated w2 response-demux rule');
    like($isf, qr/\(output axi0_w2_complete\)/, 'write depth-3 same-ID queue-head demux sample emits generated w2 completion output');
    unlike($isf, qr/\baxi0_rlast\b/, 'write depth-3 same-ID queue-head demux sample does not consume RLAST');
    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter depth-3 write report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1 w2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
        )],
    );
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is($write_policy->{implementation_status}, 'generated_write_bid_queue_head_demux', 'adapter depth-3 write policy reports generated write queue boundary');
    is_deeply([map { $_->{depth} } @{$write_policy->{generated_queues} || []}], [3], 'adapter depth-3 write policy reports one generated depth-3 queue');
    my ($queue) = @{$write_policy->{generated_queues} || []};
    is(scalar(@{$queue->{slot_storage} || []}), 9, 'adapter depth-3 write report lists 9 queue slot storage signals');
    is(scalar(@{$queue->{generated_update_rules} || []}), 54, 'adapter depth-3 write report lists 54 generated update rules');
    is(scalar(@{$queue->{generated_assertions} || []}), 14, 'adapter depth-3 write report lists 14 generated queue assertions');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'write depth-3 same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
};

subtest 'PPIF adapter parses AXI manager write multi-group same-ID queue-head response-demux behavior' => sub {
    my $sample_path = sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status write multi-group same-ID queue-head response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'write multi-group same-ID queue-head demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-write-multi-group-same-id-queue-head-response-demux', 'write multi-group same-ID queue-head demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux', 'write multi-group same-ID queue-head demux source intent name is preserved');
    like($isf, qr/\(var axi0_w0_admitted_request_pulse_q \(width 1\)\)/, 'write multi-group same-ID queue-head demux sample keeps w0 admitted request pulse');
    like($isf, qr/\(var axi0_w3_admitted_request_pulse_q \(width 1\)\)/, 'write multi-group same-ID queue-head demux sample keeps w3 admitted request pulse');
    like($isf, qr/\(var axi0_write_id5_same_id_issue_order_slot0_w2_q \(width 1\)\)/, 'write multi-group same-ID queue-head demux sample declares second generated queue slot state');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_w2_dequeue_enqueue_w3\b/, 'write multi-group same-ID queue-head demux sample emits second generated queue transition rules');
    like($isf, qr/\(rule axi0_w2_response_demux \(& axi0_write_complete \(== axi0_bid 4'd5\) axi0_write_id5_same_id_issue_order_slot0_w2_q\)/, 'write multi-group same-ID queue-head demux sample emits generated w2 response-demux rule');
    like($isf, qr/\(output axi0_w3_complete\)/, 'write multi-group same-ID queue-head demux sample emits generated w3 completion output');
    unlike($isf, qr/\baxi0_rlast\b/, 'write multi-group same-ID queue-head demux sample does not consume RLAST');
    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'adapter multi-group write report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(w2 w3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w0_w3_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
            axi0_w1_w3_write_response_demux_unique_match
            axi0_w2_w3_write_response_demux_unique_match
        )],
    );
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is_deeply(
        $write_policy->{admitted_request_boundary}{generated_assertions},
        [
            qw(
                axi0_write_id3_same_id_issue_order_request_onehot0
                axi0_write_id5_same_id_issue_order_request_onehot0
            )
        ],
        'adapter report keeps group-local admitted-request onehots for write multi-group queue-head demux',
    );
    assert_counted_admitted_request_boundary(
        $write_policy->{admitted_request_boundary},
        'adapter write multi-group admitted boundary',
        pending_storage => 'axi0_pending_writes_q',
        max_pending => 4,
        completion_fanin => '(| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)',
        request_count_expression => '(+ (| axi0_w0_request axi0_w1_request) (| axi0_w2_request axi0_w3_request))',
        generated_assertions => [
            qw(
                axi0_write_id3_same_id_issue_order_request_onehot0
                axi0_write_id5_same_id_issue_order_request_onehot0
            )
        ],
    );
    is_deeply([map { $_->{concrete_id} } @{$write_policy->{generated_queues} || []}], [3, 5], 'adapter report keeps both generated write queue groups');
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'adapter report marks write multi-group queue-head demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'adapter report marks generated write multi-group response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'adapter report accepts write multi-group same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'adapter report marks generated write multi-group queue behavior true');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'write multi-group same-ID queue-head demux generated behavior removes same-ID and response-demux ID/response residue',
    );
    assert_counted_same_id_capacity_accounting(
        $result->{report},
        'adapter write multi-group counted capacity report',
        direction => 'write',
        rule_count => 30,
        request_count_expression => '(+ (| axi0_w0_request axi0_w1_request) (| axi0_w2_request axi0_w3_request))',
        counted_request_events => [qw(axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)],
        counted_request_terms => [
            '(| axi0_w0_request axi0_w1_request)',
            '(| axi0_w2_request axi0_w3_request)',
        ],
        counted_request_groups => [
            {
                concrete_id    => 3,
                request_events => [qw(axi0_w0_request axi0_w1_request)],
                request_fanin  => '(| axi0_w0_request axi0_w1_request)',
            },
            {
                concrete_id    => 5,
                request_events => [qw(axi0_w2_request axi0_w3_request)],
                request_fanin  => '(| axi0_w2_request axi0_w3_request)',
            },
        ],
    );
    assert_boolean_capacity_accounting($result->{report}, 'adapter write multi-group read capacity report', direction => 'read', rule_count => 20);
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    write_multi_depth3
    write_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_case_args($case_name);
    subtest "PPIF adapter parses $case{owner} behavior" => sub {
        ok(-f $case{path}->(), "tracked runnable PPIF $case{owner} sample exists");
        assert_ppif_queue_head_adapter_case(%case);
    };
}

subtest 'PPIF adapter parses AXI manager auto-ID lifecycle behavior' => sub {
    my $sample_path = sample_capacity_auto_id_lifecycle_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status auto-ID lifecycle sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_auto_id_lifecycle_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'auto-ID lifecycle sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-auto-id-lifecycle', 'auto-ID lifecycle source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_auto_id_lifecycle', 'auto-ID lifecycle source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(output axi0_awid \(width 4\)\)/, 'auto-ID lifecycle drives AWID as a generated output');
    unlike($result->{generated_ial1}{text}, qr/\(input axi0_awid\b/, 'auto-ID lifecycle does not treat AWID as an input');
    unlike($result->{generated_ial1}{text}, qr/\(input axi0_bid\b/, 'auto-ID lifecycle does not add unused BID input');
    like($result->{generated_ial1}{text}, qr/\(var axi0_w0_auto_id_q \(width 4\)\)/, 'auto-ID lifecycle declares w0 selected-ID state');
    like($result->{generated_ial1}{text}, qr/\(priority axi0_w0_auto_id_alloc_0 over axi0_w0_auto_id_alloc_1\)/, 'auto-ID lifecycle emits allocation priority edges');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_w0_auto_id_alloc_0\b[\s\S]*\(axi0_awid 0\)\)/, 'auto-ID lifecycle emits allocation rule for pool ID 0');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_w0_auto_id_release\b[\s\S]*\(axi0_w0_auto_id_busy_q 0\)\)/, 'auto-ID lifecycle emits completion release rule');
    like($result->{generated_ial1}{text}, qr/"axi0 write auto ID active selected IDs are unique"/, 'auto-ID lifecycle emits same-ID avoidance assertion');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(\+size[\s\S]*\(axi0_awid 4\)/, 'auto-ID lifecycle scheduled .fsm carries AWID width');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(\+assert[\s\S]*axi0 w0 auto ID available/, 'auto-ID lifecycle scheduled .fsm carries runtime assertions');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(\+assert[\s\S]*axi0 write auto ID active selected IDs are unique/, 'auto-ID lifecycle scheduled .fsm carries same-ID avoidance assertions');
    assert_write_auto_id_lifecycle_report($result->{report}{auto_id_lifecycle}, 'adapter report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'adapter report', 0);
    is_deeply($result->{report}{id_response_rule_engine}{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'auto-ID lifecycle keeps response ID inputs tied to concrete checks only');
};

subtest 'PPIF adapter parses AXI manager write response-demux behavior' => sub {
    my $sample_path = sample_capacity_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_response_demux_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-response-demux', 'response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_response_demux', 'response-demux source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_bid \(width 4\)\)/, 'response-demux generated IAL1 declares BID input');
    unlike($result->{generated_ial1}{text}, qr/\(input axi0_w0_complete\b/, 'response-demux generated IAL1 does not declare generated completion as input');
    like($result->{generated_ial1}{text}, qr/\(output axi0_w0_complete\)/, 'response-demux generated IAL1 declares generated completion output');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_w0_response_demux\b[\s\S]*\(pulse axi0_w0_complete\)\)/, 'response-demux generated IAL1 emits w0 pulse rule');
    like($result->{generated_ial1}{text}, qr/"axi0 write auto ID active selected IDs are unique"/, 'response-demux generated IAL1 keeps same-ID avoidance assertion');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(-axi0_w0_response_demux\b[\s\S]*\(<1 \(axi0_w0_complete> 1\)\)/, 'response-demux generated IAL0 emits w0 completion pulse');
    assert_write_response_demux_report($result->{report}{response_demux}, 'adapter report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'adapter report', 1);
    is_deeply($result->{report}{auto_id_lifecycle}{residue}, [], 'adapter report removes response_demux and same-ID residue from auto-ID lifecycle residue');
    is_deeply($result->{report}{id_response_rule_engine}{residue}, [qw(same_id_ordering)], 'adapter report removes response_demux from ID/response residue');
};

subtest 'PPIF adapter parses AXI manager read response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_response_demux_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_response_demux_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-response-demux', 'read response-demux source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_response_demux', 'read response-demux source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_read_complete\)/, 'read response-demux generated IAL1 declares the raw read response event');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rid \(width 4\)\)/, 'read response-demux generated IAL1 declares RID input');
    unlike($result->{generated_ial1}{text}, qr/\(input axi0_r0_complete\b/, 'read response-demux generated IAL1 does not declare generated completion as input');
    like($result->{generated_ial1}{text}, qr/\(output axi0_r0_complete\)/, 'read response-demux generated IAL1 declares generated completion output');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_r0_response_demux\b[\s\S]*\(pulse axi0_r0_complete\)\)/, 'read response-demux generated IAL1 emits r0 pulse rule');
    like($result->{generated_ial1}{text}, qr/"axi0 read auto ID active selected IDs are unique"/, 'read response-demux generated IAL1 keeps same-ID avoidance assertion');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(-axi0_r0_response_demux\b[\s\S]*\(<1 \(axi0_r0_complete> 1\)\)/, 'read response-demux generated IAL0 emits r0 completion pulse');
    assert_read_response_demux_report($result->{report}{response_demux}, 'adapter report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'adapter report', 1, 'read');
    is_deeply($result->{report}{auto_id_lifecycle}{residue}, [], 'adapter report removes response_demux and same-ID residue from read auto-ID lifecycle residue');
};

subtest 'PPIF adapter parses AXI manager burst-last read response-demux behavior' => sub {
    my $sample_path = sample_capacity_read_response_demux_burst_last_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status burst-last read response-demux sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_response_demux_burst_last_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'burst-last read response-demux sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-response-demux-burst-last', 'burst-last source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_response_demux_burst_last', 'burst-last source intent name is preserved');
    like($isf, qr/\(input axi0_read_complete\)/, 'burst-last behavior declares raw read response beat input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'burst-last behavior declares RID input');
    like($isf, qr/\(input axi0_rlast\)/, 'burst-last behavior declares RLAST input');
    unlike($isf, qr/\(input axi0_r0_complete\)/, 'burst-last behavior removes generated transaction completion from authored inputs');
    like($isf, qr/\(output axi0_r0_complete\)/, 'burst-last behavior exposes generated transaction completion output');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/s,
        'burst-last behavior emits RLAST-gated r0 completion rule',
    );
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'adapter burst-last report');
    assert_rlast_report_prose_alignment($result->{report}, 'adapter burst-last report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'adapter burst-last report', 1, 'read');
    is_deeply($result->{report}{auto_id_lifecycle}{residue}, [], 'adapter burst-last report removes generated read demux from lifecycle residue');
};

subtest 'PPIF adapter parses AXI manager read-data behavior' => sub {
    my $sample_path = sample_capacity_read_data_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_data_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-data', 'read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_data', 'read-data source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rdata \(width 32\)\)/, 'read-data PPIF generates RDATA input with declared width');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rresp \(width 2\)\)/, 'read-data PPIF generates RRESP input with declared width');
    like($result->{generated_ial1}{text}, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'read-data PPIF generates r0 data output with inherited width');
    like($result->{generated_ial1}{text}, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'read-data PPIF generates r0 status output with inherited width');
    like(
        $result->{generated_ial1}{text},
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'read-data PPIF generates r0 normal capture rule',
    );
    like(
        $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'},
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/,
        'read-data PPIF lowers r0 capture rule into generated .fsm',
    );
    assert_read_response_demux_report($result->{report}{response_demux}, 'adapter read-data report');
    assert_read_data_report($result->{report}{read_data}, 'adapter report');
};

subtest 'PPIF adapter parses AXI manager last-beat read-data behavior' => sub {
    my $sample_path = sample_capacity_read_data_last_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status last-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_data_last_beat_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'last-beat read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-data-last-beat', 'last-beat read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_last_beat', 'last-beat read-data source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rdata \(width 32\)\)/, 'last-beat read-data PPIF generates RDATA input with declared width');
    like($result->{generated_ial1}{text}, qr/\(input axi0_rresp \(width 2\)\)/, 'last-beat read-data PPIF generates RRESP input with declared width');
    like($result->{generated_ial1}{text}, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'last-beat read-data PPIF generates r0 last data output with inherited width');
    like($result->{generated_ial1}{text}, qr/\(output axi0_r0_last_rresp \(width 2\)\)/, 'last-beat read-data PPIF generates r0 last status output with inherited width');
    like(
        $result->{generated_ial1}{text},
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'last-beat read-data PPIF generates r0 normal capture rule',
    );
    like(
        $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'},
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'last-beat read-data PPIF lowers r0 capture rule into generated .fsm',
    );
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'adapter last-beat read-data report');
    assert_read_data_last_beat_report($result->{report}{read_data}, 'adapter last-beat read-data report');
};

subtest 'PPIF adapter parses AXI manager burst-length read-data metadata' => sub {
    my $sample_path = sample_capacity_read_data_burst_length_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_data_burst_length_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'burst-length read-data sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-data-burst-length', 'burst-length read-data source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_burst_length', 'burst-length read-data source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(input axi0_arlen \(width 8\)\)/, 'burst-length read-data PPIF generates a width-8 ARLEN input');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'burst-length read-data PPIF generates r0 raw ARLEN capture');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/, 'burst-length read-data PPIF lowers r0 raw ARLEN capture into generated .fsm');
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'adapter burst-length read-data report');
    assert_read_data_burst_length_report($result->{report}{read_data}, 'adapter burst-length read-data report');
};

subtest 'PPIF adapter parses AXI manager runtime-assertion burst-length read-data metadata' => sub {
    my $sample_path = sample_capacity_read_data_burst_length_runtime_assertion_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status runtime-assertion burst-length read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_data_burst_length_runtime_assertion_ppif(), $sample_path);

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'runtime-assertion burst-length sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-data-burst-length-runtime-assertion', 'runtime-assertion burst-length source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_burst_length_runtime_assertion', 'runtime-assertion burst-length source intent name is preserved');
    like($result->{generated_ial1}{text}, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'runtime-assertion PPIF generates r0 expected-beat storage');
    like($result->{generated_ial1}{text}, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'runtime-assertion PPIF generates r0 beat-count storage');
    like($result->{generated_ial1}{text}, qr/\(rule axi0_r0_beat_count_init axi0_r0_request\s+\(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r0_read_beat_count_q 0\)\)/, 'runtime-assertion PPIF generates r0 beat-count initialization');
    like($result->{generated_ial1}{text}, qr/axi0 r0 RLAST appears only on the expected final read beat/, 'runtime-assertion PPIF generates r0 early-RLAST assertion');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(\| \(! axi0_r0_request\) \(< axi0_arlen 8'd16\)\)/, 'runtime-assertion PPIF lowers r0 ARLEN bound assertion into generated .fsm');
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'runtime-assertion PPIF lowers r0 beat-count increment into generated .fsm');
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'adapter runtime-assertion burst-length read-data report');
    assert_read_data_burst_length_report($result->{report}{read_data}, 'adapter runtime-assertion burst-length read-data report', 'runtime_assertion');
};

subtest 'PPIF adapter parses AXI manager multi-beat read-data output-bank behavior' => sub {
    my $sample_path = sample_capacity_read_data_multi_beat_ppif_path();
    ok(-f $sample_path, 'tracked runnable PPIF capacity/status multi-beat read-data sample exists');

    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source(sample_capacity_read_data_multi_beat_ppif(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'multi-beat sample still uses the capacity/status generator');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-read-data-multi-beat', 'multi-beat source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_multi_beat', 'multi-beat source intent name is preserved');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-beat PPIF keeps generated ARLEN input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-beat PPIF declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-beat PPIF declares generated RRESP input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'multi-beat PPIF keeps expected-beat storage');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multi-beat PPIF declares r0 beat 0 data output');
    like($isf, qr/\(output axi0_r0_beat_rresp_0 \(width 2\)\)/, 'multi-beat PPIF declares r0 beat 0 status output');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'multi-beat PPIF declares scalar r0 aggregate status output');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'multi-beat PPIF declares r0 valid-mask output');
    like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'multi-beat PPIF declares r0 length output');
    like($isf, qr/\(rule axi0_r0_read_data_output_init axi0_r0_request[\s\S]*\(axi0_r0_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r0_rresp 2'd0\)[\s\S]*\(axi0_r0_beat_valid 16'b0\)[\s\S]*\(axi0_r0_read_beats 5'd0\)\)/, 'multi-beat PPIF clears output bank and initializes scalar aggregate on request');
    like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r0_read_beats 5'd1\)\)/, 'multi-beat PPIF captures lane 0 with matched beat and current beat index');
    like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'multi-beat PPIF updates scalar aggregate when the current beat RRESP is worse');
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(\| \(! axi0_r0_request\) \(< axi0_arlen 8'd16\)\)/, 'multi-beat PPIF lowers runtime validation assertions');
    like($fsm, qr/\(-axi0_r0_read_data_output_init\s+<axi0_r0_request[\s\S]*\(<- \(axi0_r0_beat_rdata_0> 32'd0\)\)[\s\S]*\(<- \(axi0_r0_rresp> 2'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd0\)\)/, 'multi-beat PPIF lowers output-bank clear and scalar aggregate init rule');
    like($fsm, qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r0_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd1\)\)/, 'multi-beat PPIF lowers lane 0 payload capture rule');
    like($fsm, qr/\(-axi0_r0_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'multi-beat PPIF lowers scalar aggregate update rule');
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'adapter multi-beat read-data report', 1, 1);
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'adapter multi-beat read-data report', 1, 'read', 1, 1);
    assert_read_data_multi_beat_report($result->{report}{read_data}, 'adapter multi-beat read-data report');
};

subtest 'PPIF adapter keeps no-aggregation multi-beat read-data valid' => sub {
    my $source = capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
        '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
        multi_beat_read_data_clause_without_status_aggregation(),
    ));
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($source, 'multi-beat-no-aggregation.ppif');
    my $read_data = $result->{report}{read_data};
    my $read = $read_data->{read};

    is($read->{status_aggregation}, 'none', 'adapter no-aggregation multi-beat contract keeps status_aggregation none');
    ok(!exists($read->{status_aggregation_generated_behavior}), 'adapter no-aggregation multi-beat contract has no scalar aggregation generated flag');
    ok(!exists($read->{status_aggregate_output}), 'adapter no-aggregation multi-beat contract has no scalar aggregate output shape');
    is_deeply($read_data->{residue}, [qw(rresp_aggregation)], 'adapter no-aggregation multi-beat contract keeps broad RRESP aggregation residue');
    is_deeply($result->{report}{response_demux}{residue}, [], 'adapter no-aggregation multi-beat report removes covered read-data interleaving and bursts from response-demux residue');
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(concrete_id_same_id_ordering per_id_issue_order_queues)],
        'adapter no-aggregation multi-beat report removes covered read-data interleaving and bursts from same-ID residue',
    );
    is($read->{generated_multi_beat_status_outputs}[0], 'r0_beat_resp_0', 'adapter no-aggregation contract still reports generated per-beat status outputs');
};

subtest 'PPIF adapter parses mixed AXI manager response-demux arms' => sub {
    my $source = capacity_ppif_with_objects(
        manager_capacity_object_with_mixed_response_demux(
            '(write (response-event axi0_write_complete) (transaction-completion generated)) ' .
            '(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))',
        ),
    );
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($source, 'mixed-response-demux.ppif');
    my $isf = $result->{generated_ial1}{text};
    my $demux = $result->{report}{response_demux};

    like($isf, qr/\(input bid \(width 4\)\)/, 'mixed response-demux generated IAL1 declares BID input');
    like($isf, qr/\(output axi0_w0_complete\)/, 'mixed response-demux generated IAL1 declares write completion output');
    like($isf, qr/\(rule axi0_w0_response_demux\b[\s\S]*\(pulse axi0_w0_complete\)\)/, 'mixed response-demux generated IAL1 emits write pulse rule');
    like($isf, qr/\(input rid \(width 4\)\)/, 'mixed response-demux generated IAL1 declares RID input');
    like($isf, qr/\(output axi0_r0_complete\)/, 'mixed response-demux generated IAL1 declares read completion output');
    like($isf, qr/\(rule axi0_r0_response_demux\b[\s\S]*\(pulse axi0_r0_complete\)\)/, 'mixed response-demux generated IAL1 emits read pulse rule');

    is($demux->{mode}, 'bounded_response_demux_contract', 'mixed response-demux report uses combined mode');
    ok($demux->{generated_behavior}, 'mixed response-demux report keeps top-level generated behavior true');
    is($demux->{write}{mode}, 'bounded_write_bid_demux_contract', 'mixed response-demux report keeps write mode');
    ok($demux->{write}{generated_behavior}, 'mixed response-demux report keeps write generated behavior true');
    is_deeply($demux->{write}{auto_transactions}, [qw(w0 w1)], 'mixed response-demux report keeps write auto transactions');
    is($demux->{read}{mode}, 'bounded_read_rid_demux_contract', 'mixed response-demux report adds read mode');
    ok($demux->{read}{generated_behavior}, 'mixed response-demux report marks read generated behavior true');
    is_deeply($demux->{read}{auto_transactions}, [qw(r0 r1)], 'mixed response-demux report keeps read auto transactions');
    is_deeply($demux->{read}{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'mixed response-demux report lists generated read rules');
    is_deeply($demux->{read}{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'mixed response-demux report lists generated read completion signals');
    is_deeply($demux->{residue}, [qw(read_data_interleaving bursts)], 'mixed response-demux report keeps only read data/interleaving and burst residue');
    is_deeply($result->{report}{auto_id_lifecycle}{residue}, [], 'mixed response-demux report removes lifecycle response_demux residue after both families are covered');
    my %same_id_families = map { $_->{family} => $_ } @{$result->{report}{same_id_ordering}{families}};
    is_deeply(sorted([keys %same_id_families]), [qw(read write)], 'mixed same-ID report carries write and read families');
    assert_same_id_ordering_family($same_id_families{write}, 'adapter report mixed write', 'write', 1);
    assert_same_id_ordering_family($same_id_families{read}, 'adapter report mixed read', 'read', 1);
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
        ['mixed object families',
            capacity_ppif_with_objects(valid_ready_object(), manager_capacity_object()),
            qr/cannot mix \(valid-ready-channel \.\.\.\) and \(manager-capacity-status \.\.\.\) objects/],
        ['multiple manager objects',
            capacity_ppif_with_objects(manager_capacity_object('axi0'), manager_capacity_object('axi1')),
            qr/supports exactly one \(manager-capacity-status \.\.\.\) object/],
        ['missing manager read depth',
            capacity_ppif_with_objects(manager_capacity_object_without('(read-max-pending 4)')),
            qr/missing required \(read-max-pending \.\.\.\) clause/],
        ['unsupported manager policy',
            capacity_ppif_with_objects(manager_capacity_object_with('(submit-policy blocking)')),
            qr/submit_policy must be try/],
        ['unsupported manager status clause',
            capacity_ppif_with_objects(manager_capacity_object_with_status('(can-accept cap_ok)')),
            qr/unsupported status clause '\(can-accept \.\.\.\)'/],
        ['unsupported manager ID-family clause',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families('(address (width 4))')),
            qr/unsupported family clause '\(address \.\.\.\)'/],
        ['duplicate manager ID-family clause',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families('(read (width 4) (request-id arid) (response-id rid)) (read (width 4) (request-id arid2) (response-id rid2)) (write (width 4) (request-id awid) (response-id bid))')),
            qr/duplicate \(read \.\.\.\) family clause/],
        ['missing manager ID-family width',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families('(read (request-id arid) (response-id rid)) (write (width 4) (request-id awid) (response-id bid))')),
            qr/\(read \.\.\.\)\)\) is missing required \(width \.\.\.\) clause/],
        ['zero-width manager ID-family with signal',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families('(read (width 0) (request-id arid)) (write (width 0))')),
            qr/zero width must not include \(request-id \.\.\.\)/],
        ['positive-width manager ID-family missing signal',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families('(read (width 4) (request-id arid)) (write (width 4) (request-id awid) (response-id bid))')),
            qr/positive width requires \(response-id \.\.\.\)/],
        ['unsupported manager transaction kind',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(burst b0 (tag x) (request axi0_read_submit) (completion axi0_read_complete) (id auto))')),
            qr/unsupported transaction kind '\(burst \.\.\.\)'/],
        ['duplicate manager transaction tag',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(write w0 (tag same) (request axi0_write_submit) (completion axi0_write_complete) (id auto)) (read r0 (tag same) (request axi0_read_submit) (completion axi0_read_complete) (id auto))')),
            qr/duplicate transaction tag 'same'/],
        ['manager transaction wrong direction event',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(write w0 (tag wr0) (request axi0_read_submit) (completion axi0_write_complete) (id auto))',
            )),
            qr/write request_event must not reference read direction-level event 'axi0_read_submit'/],
        ['manager transaction duplicate dispatch request event',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto)) (write w1 (tag wr1) (request axi0_w0_request) (completion axi0_w1_complete) (id auto))',
            )),
            qr/write request_event 'axi0_w0_request' is reused by transactions 'w0' and 'w1' while using per-transaction dispatch/],
        ['manager transaction malformed id',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(write w0 (tag wr0) (request axi0_write_submit) (completion axi0_write_complete) (id (policy auto)))')),
            qr/requires \(id auto\), \(id dynamic\), or \(id \(value N\)\)/],
        ['manager transaction unsupported id policy token',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(write w0 (tag wr0) (request axi0_write_submit) (completion axi0_write_complete) (id user))')),
            qr/requires \(id auto\), \(id dynamic\), or \(id \(value N\)\)/],
        ['manager transaction unsupported parenthesized dynamic id',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(write w0 (tag wr0) (request axi0_write_submit) (completion axi0_write_complete) (id (dynamic)))')),
            qr/requires \(id auto\), \(id dynamic\), or \(id \(value N\)\)/],
        ['manager transaction unsupported signal id',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(write w0 (tag wr0) (request axi0_write_submit) (completion axi0_write_complete) (id (signal axi0_awid)))')),
            qr/requires \(id auto\), \(id dynamic\), or \(id \(value N\)\)/],
        ['manager transaction concrete ID too wide',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id (value 16)))',
            )),
            qr/concrete read ID value 16 does not fit width 4/],
        ['manager transaction dynamic ID without family metadata',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions('(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))')),
            qr/dynamic ID requires id_families metadata/],
        ['manager transaction dynamic ID with zero-width family',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 0))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))',
            )),
            qr/dynamic read ID requires positive read ID-family width/],
        ['manager transaction concrete same-family same-ID reuse',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))) (read r1 (tag rd1) (request axi0_r1_request) (completion axi0_r1_complete) (id (value 3)))',
            )),
            qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue/],
        ['duplicate manager same-ID ordering clause',
            capacity_ppif_with_objects(manager_capacity_object_with_duplicate_same_id_ordering()),
            qr/duplicate \(same-id-ordering \.\.\.\) clause/],
        ['unsupported manager same-ID ordering family',
            capacity_ppif_with_objects(manager_capacity_object_with_same_id_ordering('(address (concrete-id-reuse reject))')),
            qr/unsupported family clause '\(address \.\.\.\)'; this slice supports \(read \.\.\.\) and \(write \.\.\.\)/],
        ['duplicate manager same-ID ordering read family',
            capacity_ppif_with_objects(manager_capacity_object_with_same_id_ordering('(read (concrete-id-reuse reject)) (read (concrete-id-reuse reject))')),
            qr/duplicate \(read \.\.\.\) family clause/],
        ['missing manager same-ID ordering concrete reuse policy',
            capacity_ppif_with_objects(manager_capacity_object_with_same_id_ordering('(read)')),
            qr/is missing required \(concrete-id-reuse \.\.\.\) clause/],
        ['duplicate manager same-ID ordering concrete reuse policy',
            capacity_ppif_with_objects(manager_capacity_object_with_same_id_ordering('(read (concrete-id-reuse reject) (concrete-id-reuse reject))')),
            qr/duplicate \(concrete-id-reuse \.\.\.\) clause/],
        ['unsupported manager same-ID ordering scoreboard policy',
            capacity_ppif_with_objects(manager_capacity_object_with_same_id_ordering('(write (concrete-id-reuse scoreboard))')),
            qr/supports only reject or issue-order-queue in this slice/],
        ['manager same-ID ordering reject blocks concrete same-ID reuse',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_same_id_ordering(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))) (read r1 (tag rd1) (request axi0_r1_request) (completion axi0_r1_complete) (id (value 3)))',
                '(read (concrete-id-reuse reject))',
            )),
            qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering\.read concrete-id-reuse reject policy rejects concrete same-ID reuse/],
        ['manager same-ID ordering issue-order queue keeps duplicated concrete same-ID reuse fail-closed',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_same_id_ordering(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))) (read r1 (tag rd1) (request axi0_r1_request) (completion axi0_r1_complete) (id (value 3)))',
                '(read (concrete-id-reuse issue-order-queue))',
            )),
            qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering\.read concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships/],
        ['manager transaction duplicate concrete ID assertion event',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id (value 3))) (read r1 (tag rd1) (request axi0_read_submit) (completion axi0_read_complete) (id (value 4)))',
            )),
            qr/concrete ID assertions require unique request events; event 'axi0_read_submit' is shared by transactions 'r0' and 'r1'/],
        ['manager dynamic transaction ID blocks same-family auto lifecycle behavior',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))',
                '(read (pool 0))',
            )),
            qr/auto_id_lifecycle\.read cannot be combined with dynamic read transaction ID metadata/],
        ['manager dynamic read response demux requires generated completion distinct from raw response event',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_response_demux(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))',
                '(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))',
            )),
            qr/response_demux\.read generated transaction completion signal 'axi0_read_complete' must be distinct from response_event 'axi0_read_complete'/],
        ['manager dynamic transaction ID blocks same-family same-ID ordering behavior',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_same_id_ordering(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))',
                '(read (concrete-id-reuse issue-order-queue))',
            )),
            qr/same_id_ordering_policy\.read cannot be combined with dynamic read transaction ID metadata/],
        ['manager dynamic read-data without response-demux metadata remains unsupported',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_read_data(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id dynamic))',
                default_manager_read_data_clause(),
            )),
            qr/read_data requires generated read response_demux metadata/],
        ['duplicate manager auto-ID lifecycle clause',
            capacity_ppif_with_objects(manager_capacity_object_with_duplicate_auto_id_lifecycle()),
            qr/duplicate \(auto-id-lifecycle \.\.\.\) clause/],
        ['unsupported manager auto-ID lifecycle family',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(address (pool 0))')),
            qr/unsupported family clause '\(address \.\.\.\)'/],
        ['missing manager auto-ID lifecycle pool',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(write)')),
            qr/is missing required \(pool \.\.\.\) clause/],
        ['duplicate manager auto-ID lifecycle pool clause',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(write (pool 0) (pool 1))')),
            qr/duplicate \(pool \.\.\.\) clause/],
        ['bad manager auto-ID lifecycle pool value',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(write (pool -1))')),
            qr/pool value must be an unsigned integer/],
        ['oversized manager auto-ID lifecycle pool',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(write (pool 0 1 2 3 4))')),
            qr/pool supports 1\.\.4 unsigned integer values/],
        ['duplicate manager auto-ID lifecycle pool value',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(write (pool 0 0))')),
            qr/pool duplicates ID value 0/],
        ['manager auto-ID lifecycle without ID families',
            capacity_ppif_with_objects(manager_capacity_object_with_transactions_and_auto_id_lifecycle(
                '(write w0 (tag wr0) (request axi0_write_submit) (completion axi0_write_complete) (id auto))',
                '(write (pool 0))',
            )),
            qr/auto_id_lifecycle requires id_families metadata/],
        ['manager auto-ID lifecycle listed family without auto transaction',
            capacity_ppif_with_objects(manager_capacity_object_with_auto_id_lifecycle('(read (pool 0))')),
            qr/auto_id_lifecycle\.read requires at least one auto-ID transaction in the read family/],
        ['manager auto-ID lifecycle value exceeds width',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
                '(write (width 1) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                default_manager_transactions(),
                '(write (pool 2))',
            )),
            qr/auto_id_lifecycle\.write\.pool value 2 does not fit width 1/],
        ['duplicate manager response-demux clause',
            capacity_ppif_with_objects(manager_capacity_object_with_duplicate_response_demux()),
            qr/duplicate \(response-demux \.\.\.\) clause/],
        ['unsupported manager response-demux family',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(address (response-event axi0_read_complete) (transaction-completion generated))')),
            qr/unsupported family clause '\(address \.\.\.\)'; this slice supports \(read \.\.\.\) and \(write \.\.\.\)/],
        ['duplicate manager response-demux write family',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(write (response-event axi0_write_complete) (transaction-completion generated)) (write (response-event axi0_write_complete) (transaction-completion generated))')),
            qr/duplicate \(write \.\.\.\) family clause/],
        ['duplicate manager response-demux read family',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated)) (read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))')),
            qr/duplicate \(read \.\.\.\) family clause/],
        ['missing manager response-demux response event',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(write (transaction-completion generated))')),
            qr/is missing required \(response-event \.\.\.\) clause/],
        ['duplicate manager response-demux response event',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(write (response-event axi0_write_complete) (response-event axi0_write_complete) (transaction-completion generated))')),
            qr/duplicate \(response-event \.\.\.\) clause/],
        ['unsupported manager response-demux completion ownership',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(write (response-event axi0_write_complete) (transaction-completion authored))')),
            qr/supports only generated in this slice/],
        ['missing manager read response-demux response scope',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (transaction-completion generated))')),
            qr/is missing required \(response-scope \.\.\.\) clause/],
        ['duplicate manager read response-demux response scope',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope single-beat) (response-scope single-beat) (transaction-completion generated))')),
            qr/duplicate \(response-scope \.\.\.\) clause/],
        ['unsupported manager read response-demux response scope',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope burst) (transaction-completion generated))')),
            qr/supports only single-beat or burst-last in this slice/],
        ['missing manager burst-last read response-demux last signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope burst-last) (transaction-completion generated))')),
            qr/burst-last response-scope requires exactly one \(last-signal NAME \(width 1\)\) clause/],
        ['duplicate manager burst-last read response-demux last signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (last-signal rlast2 (width 1)) (transaction-completion generated))')),
            qr/duplicate \(last-signal \.\.\.\) clause/],
        ['bad-width manager burst-last read response-demux last signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 2)) (transaction-completion generated))')),
            qr/width must be 1 in this slice/],
        ['malformed manager burst-last read response-demux last signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast) (transaction-completion generated))')),
            qr/requires \(NAME \(width 1\)\)/],
        ['manager single-beat read response-demux with last signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope single-beat) (last-signal rlast (width 1)) (transaction-completion generated))')),
            qr/single-beat response-scope must not include \(last-signal \.\.\.\)/],
        ['unsupported manager read response-demux completion ownership',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion authored))')),
            qr/supports only generated in this slice/],
        ['manager response-demux event mismatch',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux('(write (response-event axi0_other_write_complete) (transaction-completion generated))')),
            qr/response_demux\.write\.response_event must equal write_complete event 'axi0_write_complete'/],
        ['manager read response-demux event mismatch',
            capacity_ppif_with_objects(manager_capacity_object_with_read_response_demux('(read (response-event axi0_other_read_complete) (response-scope single-beat) (transaction-completion generated))')),
            qr/response_demux\.read\.response_event must equal read_complete event 'axi0_read_complete'/],
        ['manager response-demux without ID-family metadata',
            capacity_ppif_with_objects(manager_capacity_object_with_response_demux_only('(write (response-event axi0_write_complete) (transaction-completion generated))')),
            qr/response_demux requires id_families metadata/],
        ['manager response-demux without auto lifecycle metadata',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_and_response_demux(
                default_manager_id_families(),
                default_manager_transactions(),
                '(write (response-event axi0_write_complete) (transaction-completion generated))',
            )),
            qr/response_demux\.write requires write auto_id_lifecycle metadata or selected same-id-ordering\.write concrete-id-reuse issue-order-queue with a duplicate concrete-ID group/],
        ['manager same-ID queue-head response-demux without duplicate concrete-ID group',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_transactions_same_id_ordering_and_response_demux(
                default_manager_id_families(),
                default_manager_transactions(),
                '(read (concrete-id-reuse issue-order-queue))',
                '(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))',
            )),
            qr/response_demux\.read concrete same-ID queue-head demux requires at least one duplicate concrete read ID group/],
        ['duplicate manager read-data clause',
            capacity_ppif_with_objects(manager_capacity_object_with_duplicate_read_data()),
            qr/duplicate \(read-data \.\.\.\) clause/],
        ['unsupported manager read-data family',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data('(write (capture-scope single-beat))')),
            qr/unsupported family clause '\(write \.\.\.\)'; this slice supports \(read \.\.\.\)/],
        ['duplicate manager read-data read family',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(default_manager_read_data_clause() . ' ' . default_manager_read_data_clause())),
            qr/duplicate \(read \.\.\.\) family clause/],
        ['missing manager read-data capture scope',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data('(read (completion-source response-demux) (data-signal rdata (width 32)) (status-signal rresp (width 2)) (interleaving single-beat-by-rid) (transaction r0 (data-output r0_data) (status-output r0_resp)) (transaction r1 (data-output r1_data) (status-output r1_resp)))')),
            qr/is missing required \(capture-scope \.\.\.\) clause/],
        ['unsupported manager read-data capture scope',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(capture-scope burst)'))),
            qr/supports only single-beat, last-beat, or multi-beat in this slice/],
        ['unsupported manager read-data completion source',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(completion-source read-complete)'))),
            qr/supports only response-demux in this slice/],
        ['zero-width manager read-data data signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(data-signal rdata (width 0))'))),
            qr/width must be a positive integer/],
        ['bad-width manager read-data status signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(status-signal rresp (width 1))'))),
            qr/status width must be 2 in this slice/],
        ['unsupported manager read-data interleaving',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(interleaving burst-by-rid)'))),
            qr/supports only single-beat-by-rid with capture-scope single-beat/],
        ['single-beat manager read-data with status policy',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(status-policy last-beat)'))),
            qr/status-policy .* only supported with capture-scope last-beat/],
        ['single-beat manager read-data with status aggregation',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(status-aggregation (policy worst-observed))'))),
            qr/status-aggregation .* only supported with capture-scope multi-beat/],
        ['last-beat manager read-data missing status policy',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_manager_read_data_clause_without_status_policy(),
            )),
            qr/capture-scope last-beat requires status-policy last-beat/],
        ['last-beat manager read-data bad status policy',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with('(status-policy aggregate)'),
            )),
            qr/capture-scope last-beat requires status-policy last-beat/],
        ['last-beat manager read-data with status aggregation',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with('(status-aggregation (policy worst-observed))'),
            )),
            qr/status-aggregation .* only supported with capture-scope multi-beat/],
        ['last-beat manager read-data bad interleaving',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with('(interleaving single-beat-by-rid)'),
            )),
            qr/supports only last-beat-by-rid with capture-scope last-beat/],
        ['single-beat manager read-data with burst-length',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with_burst_length(default_manager_burst_length_clause()))),
            qr/burst-length .* only supported with capture-scope last-beat/],
        ['multi-beat manager read-data with report-only burst-length validation',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_manager_read_data_clause(default_manager_burst_length_clause()),
            )),
            qr/capture-scope multi-beat requires validation runtime-assertion/],
        ['multi-beat manager read-data missing status policy',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_without('(status-policy per-beat)'),
            )),
            qr/capture-scope multi-beat requires status-policy per-beat/],
        ['multi-beat manager read-data bad status aggregation policy',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(status-aggregation (policy last-beat))'),
            )),
            qr/status-aggregation .* supports only worst-observed/],
        ['multi-beat manager read-data aggregate output without aggregation',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_without('(status-aggregation (policy worst-observed))'),
            )),
            qr/status-aggregate-output .* requires a read-level \(status-aggregation \.\.\.\) clause/],
        ['multi-beat manager read-data missing aggregate output',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(transaction r0 (data-output-prefix r0_beat_data) (status-output-prefix r0_beat_resp) (valid-mask-output r0_beat_valid) (length-output r0_read_beats))'),
            )),
            qr/capture-scope multi-beat is missing required \(status-aggregate-output \.\.\.\) clause/],
        ['multi-beat manager read-data bad interleaving',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(interleaving last-beat-by-rid)'),
            )),
            qr/supports only multi-beat-by-rid with capture-scope multi-beat/],
        ['multi-beat manager read-data legacy transaction output',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(transaction r0 (data-output r0_last_data) (status-output-prefix r0_beat_resp) (valid-mask-output r0_beat_valid) (length-output r0_read_beats))'),
            )),
            qr/capture-scope multi-beat does not support legacy \(data-output \.\.\.\) clauses/],
        ['multi-beat manager read-data missing length output',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(transaction r0 (data-output-prefix r0_beat_data) (status-output-prefix r0_beat_resp) (valid-mask-output r0_beat_valid))'),
            )),
            qr/capture-scope multi-beat is missing required \(length-output \.\.\.\) clause/],
        ['multi-beat manager read-data aggregate output collision',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                multi_beat_read_data_clause_with('(transaction r0 (data-output-prefix r0_beat_data) (status-output-prefix r0_beat_resp) (status-aggregate-output rid) (valid-mask-output r0_beat_valid) (length-output r0_read_beats))'),
            )),
            qr/duplicates signal 'rid'/],
        ['duplicate manager read-data burst-length',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(default_manager_burst_length_clause() . ' ' . default_manager_burst_length_clause()),
            )),
            qr/duplicate \(burst-length \.\.\.\) clause/],
        ['unsupported manager read-data burst-length subclause',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with_extra('(depth 16)')),
            )),
            qr/burst-length .* unsupported clause '\(depth \.\.\.\)'/],
        ['missing manager read-data burst-length source',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_without('(source arlen)')),
            )),
            qr/burst-length .* missing required \(source \.\.\.\) clause/],
        ['unsupported manager read-data burst-length source',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(source beat-count)')),
            )),
            qr/supports only arlen in this slice/],
        ['bad-width manager read-data burst-length signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(signal arlen (width 4))')),
            )),
            qr/width must be 8 for source arlen/],
        ['malformed manager read-data burst-length signal',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(signal arlen)')),
            )),
            qr/requires \(NAME \(width 8\)\)/],
        ['unsupported manager read-data burst-length encoding',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(encoding raw)')),
            )),
            qr/supports only axlen-plus-one in this slice/],
        ['unsupported manager read-data burst-length capture',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(capture response)')),
            )),
            qr/supports only request in this slice/],
        ['bad manager read-data burst-length max-beats',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(max-beats 257)')),
            )),
            qr/max-beats must be an integer in 1\.\.256/],
        ['unsupported manager read-data burst-length validation',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                last_beat_read_data_clause_with_burst_length(burst_length_clause_with('(validation generated)')),
            )),
            qr/supports only report-only or runtime-assertion in this slice/],
        ['explicit-width manager read-data output',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(transaction r0 (data-output r0_data (width 32)) (status-output r0_resp))'))),
            qr/requires exactly one scalar value/],
        ['manager read-data unknown transaction',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(read_data_clause_with('(transaction r2 (data-output r2_data) (status-output r2_resp))'))),
            qr/read_data\.read transaction 'r2' is not covered/],
        ['manager read-data without response-demux prerequisite',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_only(default_manager_read_data_clause())),
            qr/read_data requires generated read response_demux metadata/],
        ['manager read-data with burst-last response-demux',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data_after_response_demux(
                '(read (response-event axi0_read_complete) (response-scope burst-last) (last-signal rlast (width 1)) (transaction-completion generated))',
                default_manager_read_data_clause(),
            )),
            qr/read_data requires response_demux\.read\.response_scope single_beat/],
        ['last-beat manager read-data with single-beat response-demux',
            capacity_ppif_with_objects(manager_capacity_object_with_read_data(last_beat_manager_read_data_clause())),
            qr/capture_scope last-beat requires response_demux\.read\.response_scope burst_last/],
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

subtest 'CLI emits IAL2 report JSON for AXI manager capacity/status .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI emits the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status', 'capacity/status report carries the PPIF top-level intent name');
    is($report->{generated_artifacts}{ial1}{name}, 'axi0_capacity_status.isf', 'capacity/status report names generated .isf');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'capacity/status report names generated .fsm');
    is($report->{capacity}{read}{max_pending}, 4, 'capacity/status report carries read capacity');
    is($report->{status_outputs}{read_can_accept}, 'axi0_read_can_accept', 'capacity/status report carries namespaced status output');
};

subtest 'CLI emits IAL2 report JSON for AXI manager ID-family metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_id_family_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status ID-family .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status ID-family report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_id_family', 'ID-family report carries the PPIF top-level intent name');
    is($report->{id_families}{write}{width}, 4, 'CLI report carries write ID width');
    ok($report->{id_families}{write}{present}, 'CLI report marks write ID family present');
    is($report->{id_families}{write}{request_id_signal}, 'axi0_awid', 'CLI report carries write request ID signal');
    is($report->{id_families}{read}{response_id_signal}, 'axi0_rid', 'CLI report carries read response ID signal');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'ID-family metadata leaves generated .fsm artifact unchanged');
};

subtest 'CLI emits IAL2 report JSON for AXI manager transaction-envelope metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_transaction_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status transaction-envelope .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status transaction-envelope report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_transaction_envelope', 'transaction-envelope report carries the PPIF top-level intent name');
    is($report->{transactions}[0]{kind}, 'write', 'CLI report carries write transaction kind');
    is($report->{transactions}[0]{id}{policy}, 'auto', 'CLI report carries write auto ID policy');
    is($report->{transactions}[1]{kind}, 'read', 'CLI report carries read transaction kind');
    is($report->{transactions}[1]{id}{policy}, 'concrete', 'CLI report carries read concrete ID policy');
    is($report->{transactions}[1]{id}{value}, 3, 'CLI report carries read concrete ID value');
    is($report->{transactions}[1]{id}{family_width}, 4, 'CLI report carries read concrete ID family width');
    ok($report->{transactions}[1]{id}{fits}, 'CLI report marks the read concrete ID as fitting');
    is($report->{id_response_rule_engine}{mode}, 'concrete_id_assertions', 'CLI report exposes concrete-ID assertion mode');
    is_deeply($report->{id_response_rule_engine}{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'CLI report lists concrete-ID assertion inputs');
    is_deeply(
        [map { $_->{phase} } @{$report->{id_response_rule_engine}{checks}}],
        [qw(request response)],
        'CLI report exposes request and response concrete-ID checks',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'transaction metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager dynamic transaction-ID metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_transaction_id_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status dynamic transaction-ID .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic transaction-ID report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_transaction_id', 'dynamic transaction-ID report carries the PPIF top-level intent name');
    assert_dynamic_transaction_id_report($report->{transactions}, 'CLI report');
    ok(!exists $report->{id_response_rule_engine}, 'CLI dynamic metadata report does not emit a concrete-ID assertion engine');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'dynamic transaction-ID metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager dynamic write response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_write_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status dynamic write response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic write response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_write_response_demux', 'dynamic write response-demux report carries the PPIF top-level intent name');
    assert_dynamic_write_response_demux_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'dynamic write response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager multiple dynamic write response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_write_response_demux_multi_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status multiple dynamic write response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multiple dynamic write response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_write_response_demux_multi', 'multiple dynamic write response-demux report carries the PPIF top-level intent name');
    assert_dynamic_write_response_demux_multi_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'multiple dynamic write response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager dynamic read response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_read_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status dynamic read response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic read response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux', 'dynamic read response-demux report carries the PPIF top-level intent name');
    assert_dynamic_read_response_demux_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'dynamic read response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager multiple dynamic read response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_read_response_demux_multi_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status multiple dynamic read response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multiple dynamic read response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_multi', 'multiple dynamic read response-demux report carries the PPIF top-level intent name');
    assert_dynamic_read_response_demux_multi_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'multiple dynamic read response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager multiple dynamic read burst-last response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status multiple dynamic read burst-last response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multiple dynamic read burst-last response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last', 'multiple dynamic read burst-last response-demux report carries the PPIF top-level intent name');
    assert_dynamic_read_response_demux_multi_burst_last_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'multiple dynamic read burst-last response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager dynamic read burst-last response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_dynamic_read_response_demux_burst_last_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status dynamic read burst-last response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic read burst-last response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_read_response_demux_burst_last', 'dynamic read burst-last response-demux report carries the PPIF top-level intent name');
    assert_dynamic_read_response_demux_burst_last_report($report, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'dynamic read burst-last response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager transaction event dispatch .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_transaction_dispatch_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status transaction-event dispatch .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status transaction-event dispatch report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_transaction_event_dispatch', 'dispatch report carries the PPIF top-level intent name');
    my %direction = map { $_->{direction} => $_ } @{$report->{transaction_event_dispatch}{directions}};
    is($report->{transaction_event_dispatch}{mode}, 'per_transaction_event_fanin', 'CLI report marks transaction event fan-in mode');
    is_deeply($direction{write}{request_events}, [qw(axi0_w0_request axi0_w1_request)], 'CLI report carries write request fan-in events');
    is($direction{write}{completion_fanin}, '(| axi0_w0_complete axi0_w1_complete)', 'CLI report carries write completion fan-in expression');
    is($direction{read}{request_fanin}, 'axi0_r0_request', 'CLI report carries scalar read request fan-in');
    assert_boolean_capacity_accounting($report, 'CLI dispatch write accounting report', direction => 'write', rule_count => 12);
    assert_boolean_capacity_accounting($report, 'CLI dispatch read accounting report', direction => 'read', rule_count => 20);
    is($report->{id_response_rule_engine}{mode}, 'concrete_id_assertions', 'CLI dispatch report exposes concrete-ID assertion mode');
    is_deeply(
        [map { $_->{event} } @{$report->{id_response_rule_engine}{checks}}],
        [qw(axi0_r0_request axi0_r0_complete)],
        'CLI dispatch report binds concrete-ID checks to per-transaction events',
    );
};

subtest 'CLI emits IAL2 report JSON for AXI manager same-ID reject policy .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_same_id_reject_policy_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status same-ID reject policy .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID reject policy report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_reject_policy', 'same-ID reject report carries the PPIF top-level intent name');
    assert_same_id_reject_policy_report($report->{same_id_ordering}, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'same-ID reject metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager same-ID issue-order queue policy .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_same_id_issue_order_queue_policy_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status same-ID issue-order queue policy .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID issue-order queue policy report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_issue_order_queue_policy', 'same-ID issue-order queue report carries the PPIF top-level intent name');
    assert_same_id_issue_order_queue_policy_report($report->{same_id_ordering}, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'same-ID issue-order queue metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_queue_head_response_demux', 'same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report($report->{response_demux}, 'CLI report');
    my $read_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'CLI report marks queue-head response-demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'CLI report marks generated response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'CLI report accepts same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'CLI report marks generated queue behavior true');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read multi-group same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read multi-group same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux', 'read multi-group same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group read report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_counted_same_id_capacity_accounting(
        $report,
        'CLI read multi-group counted capacity report',
        direction => 'read',
        rule_count => 30,
        request_count_expression => '(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))',
        counted_request_events => [qw(axi0_r0_request axi0_r1_request axi0_r2_request axi0_r3_request)],
        counted_request_terms => [
            '(| axi0_r0_request axi0_r1_request)',
            '(| axi0_r2_request axi0_r3_request)',
        ],
        counted_request_groups => [
            {
                concrete_id    => 3,
                request_events => [qw(axi0_r0_request axi0_r1_request)],
                request_fanin  => '(| axi0_r0_request axi0_r1_request)',
            },
            {
                concrete_id    => 5,
                request_events => [qw(axi0_r2_request axi0_r3_request)],
                request_fanin  => '(| axi0_r2_request axi0_r3_request)',
            },
        ],
    );
    assert_boolean_capacity_accounting($report, 'CLI read multi-group write capacity report', direction => 'write', rule_count => 12);
};

subtest 'CLI emits IAL2 report JSON for AXI manager read single-beat same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read single-beat same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux', 'read single-beat same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_read_single_beat_queue_head_response_demux_report($report->{response_demux}, 'CLI report');
    my $read_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'CLI report marks read single-beat queue-head response-demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'CLI report marks generated read single-beat response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'CLI report accepts read single-beat same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'CLI report marks generated read single-beat queue behavior true');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read single-beat same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read single-beat multi-group same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read single-beat multi-group same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux', 'read single-beat multi-group same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read single-beat multi-group report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    my $read_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{implementation_status}, 'generated_read_single_beat_queue_head_demux', 'CLI read single-beat multi-group report marks the generated single-beat boundary');
    is_deeply([map { $_->{concrete_id} } @{$read_policy->{generated_queues} || []}], [3, 5], 'CLI read single-beat multi-group report lists both generated queue groups');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read single-beat multi-group same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read single-beat same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read single-beat same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data', 'read single-beat same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_read_single_beat_queue_head_response_demux_report($report->{response_demux}, 'CLI queue-head read-data response-demux report');
    assert_read_data_report(
        $report->{read_data},
        'CLI queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read single-beat same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read single-beat depth-3 same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read single-beat depth-3 same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data', 'read single-beat depth-3 same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $report->{read_data},
        'CLI depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read single-beat depth-3 same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read burst-last depth-3 same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read burst-last depth-3 same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux', 'read burst-last depth-3 same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read burst-last depth-3 queue-head response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read burst-last depth-3 same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read burst-last depth-3 same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read burst-last depth-3 same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data', 'read burst-last depth-3 same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read burst-last depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $report->{read_data},
        'CLI read burst-last depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read burst-last depth-3 same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read burst-last depth-3 same-ID queue-head burst-length .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read burst-last depth-3 same-ID queue-head burst-length .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length', 'read burst-last depth-3 same-ID queue-head burst-length report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read burst-last depth-3 queue-head burst-length response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $report->{read_data},
        'CLI read burst-last depth-3 queue-head burst-length report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read burst-last depth-3 same-ID queue-head burst-length keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read burst-last depth-3 same-ID queue-head burst-length runtime validation .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion', 'read burst-last depth-3 same-ID queue-head burst-length runtime report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read burst-last depth-3 queue-head runtime validation response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $report->{read_data},
        'CLI read burst-last depth-3 queue-head runtime validation report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read burst-last depth-3 same-ID queue-head burst-length runtime validation keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read burst-last depth-3 same-ID queue-head multi-beat read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data', 'read burst-last depth-3 same-ID queue-head multi-beat report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI read burst-last depth-3 multi-beat response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $report->{read_data},
        'CLI read burst-last depth-3 multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read burst-last depth-3 same-ID queue-head multi-beat read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read single-beat multi-group same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read single-beat multi-group same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data', 'read single-beat multi-group same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $report->{read_data},
        'CLI multi-group queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read single-beat multi-group same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_read_data_case_args($case_name);
    subtest "CLI emits IAL2 report JSON for AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_read_data_schedule_json_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_last_beat_read_data_case_args($case_name);
    subtest "CLI emits IAL2 report JSON for AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_last_beat_read_data_schedule_json_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    read_burst_multi_depth3_runtime_assertion
    read_burst_mixed_depth3_depth2_runtime_assertion
)) {
    my %case = queue_head_depth3_last_beat_burst_length_case_args($case_name);
    subtest "CLI emits IAL2 report JSON for AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_last_beat_burst_length_schedule_json_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_multi_beat_read_data_case_args($case_name);
    subtest "CLI emits IAL2 report JSON for AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_multi_beat_read_data_schedule_json_case(%case);
    };
}

subtest 'CLI emits IAL2 report JSON for AXI manager read last-beat same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read last-beat same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data', 'read last-beat same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report($report->{response_demux}, 'CLI queue-head last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $report->{read_data},
        'CLI queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read last-beat same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read multi-group last-beat same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read multi-group last-beat same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data', 'read multi-group last-beat same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group queue-head last-beat read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $report->{read_data},
        'CLI multi-group queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read multi-group last-beat same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read last-beat same-ID queue-head burst-length .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read last-beat same-ID queue-head burst-length .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length', 'read last-beat same-ID queue-head burst-length report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report($report->{response_demux}, 'CLI queue-head burst-length response-demux report');
    assert_read_data_burst_length_report(
        $report->{read_data},
        'CLI queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read last-beat same-ID queue-head burst-length keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read last-beat same-ID queue-head burst-length runtime .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read last-beat same-ID queue-head burst-length runtime .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length runtime report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion', 'read last-beat same-ID queue-head burst-length runtime report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report($report->{response_demux}, 'CLI queue-head burst-length runtime response-demux report');
    assert_read_data_burst_length_report(
        $report->{read_data},
        'CLI queue-head burst-length runtime read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read last-beat same-ID queue-head burst-length runtime keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read multi-group last-beat same-ID queue-head burst-length runtime .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read multi-group last-beat same-ID queue-head burst-length runtime .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion', 'read multi-group last-beat same-ID queue-head burst-length runtime report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group queue-head burst-length runtime response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $report->{read_data},
        'CLI multi-group queue-head burst-length runtime read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read multi-group last-beat same-ID queue-head burst-length runtime keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read multi-beat same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read multi-beat same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-beat same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data', 'read multi-beat same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI queue-head multi-beat read-data response-demux report',
        residue => [],
    );
    assert_read_data_multi_beat_report(
        $report->{read_data},
        'CLI queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read multi-beat same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read multi-group same-ID queue-head read-data .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read multi-group same-ID queue-head read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group same-ID queue-head read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data', 'read multi-group same-ID queue-head read-data report carries the PPIF top-level intent name');
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group queue-head read-data response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r2 r3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $report->{read_data},
        'CLI multi-group queue-head read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read multi-group same-ID queue-head read-data keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager write same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_write_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status write same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_write_same_id_queue_head_response_demux', 'write same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_write_queue_head_response_demux_report($report->{response_demux}, 'CLI report');
    my $write_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{write};
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'CLI report marks write queue-head response-demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'CLI report marks generated write response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'CLI report accepts write same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'CLI report marks generated write queue behavior true');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'write same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager write depth-3 same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status write depth-3 same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write depth-3 same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux', 'write depth-3 same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_write_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI depth-3 write report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1 w2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
        )],
    );
    my $write_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{write};
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'CLI report marks write depth-3 queue-head response-demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'CLI report marks generated write depth-3 response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'CLI report accepts write depth-3 same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'CLI report marks write depth-3 queue behavior true');
    is_deeply([map { $_->{depth} } @{$write_policy->{generated_queues} || []}], [3], 'CLI report keeps one generated write depth-3 queue');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'write depth-3 same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager write multi-group same-ID queue-head response-demux .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status write multi-group same-ID queue-head response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write multi-group same-ID queue-head response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux', 'write multi-group same-ID queue-head response-demux report carries the PPIF top-level intent name');
    assert_same_id_write_queue_head_response_demux_report(
        $report->{response_demux},
        'CLI multi-group write report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(w2 w3)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w0_w3_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
            axi0_w1_w3_write_response_demux_unique_match
            axi0_w2_w3_write_response_demux_unique_match
        )],
    );
    my $write_policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{write};
    is_deeply([map { $_->{concrete_id} } @{$write_policy->{generated_queues} || []}], [3, 5], 'CLI report keeps both generated write queue groups');
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'CLI report marks write multi-group queue-head response-demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'CLI report marks generated write multi-group response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'CLI report accepts write multi-group same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'CLI report marks generated write multi-group queue behavior true');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'write multi-group same-ID queue-head response-demux keeps the generated .fsm artifact name stable');
    assert_counted_same_id_capacity_accounting(
        $report,
        'CLI write multi-group counted capacity report',
        direction => 'write',
        rule_count => 30,
        request_count_expression => '(+ (| axi0_w0_request axi0_w1_request) (| axi0_w2_request axi0_w3_request))',
        counted_request_events => [qw(axi0_w0_request axi0_w1_request axi0_w2_request axi0_w3_request)],
        counted_request_terms => [
            '(| axi0_w0_request axi0_w1_request)',
            '(| axi0_w2_request axi0_w3_request)',
        ],
        counted_request_groups => [
            {
                concrete_id    => 3,
                request_events => [qw(axi0_w0_request axi0_w1_request)],
                request_fanin  => '(| axi0_w0_request axi0_w1_request)',
            },
            {
                concrete_id    => 5,
                request_events => [qw(axi0_w2_request axi0_w3_request)],
                request_fanin  => '(| axi0_w2_request axi0_w3_request)',
            },
        ],
    );
    assert_boolean_capacity_accounting($report, 'CLI write multi-group read capacity report', direction => 'read', rule_count => 20);
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    write_multi_depth3
    write_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_case_args($case_name);
    subtest "CLI emits IAL2 report JSON for AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_schedule_json_case(%case);
    };
}

subtest 'CLI emits IAL2 report JSON for AXI manager auto-ID lifecycle behavior .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_auto_id_lifecycle_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status auto-ID lifecycle .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status auto-ID lifecycle report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_auto_id_lifecycle', 'auto-ID lifecycle report carries the PPIF top-level intent name');
    assert_write_auto_id_lifecycle_report($report->{auto_id_lifecycle}, 'CLI report');
    assert_same_id_ordering_report($report->{same_id_ordering}, 'CLI report', 0);
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'auto-ID lifecycle behavior keeps the generated .fsm artifact name stable');
    is_deeply($report->{id_response_rule_engine}{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'CLI report keeps auto-ID response ID signals out until concrete response checks need them');
};

subtest 'CLI emits IAL2 report JSON for AXI manager response-demux behavior .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_response_demux', 'response-demux report carries the PPIF top-level intent name');
    assert_write_response_demux_report($report->{response_demux}, 'CLI report');
    assert_same_id_ordering_report($report->{same_id_ordering}, 'CLI report', 1);
    is_deeply($report->{auto_id_lifecycle}{residue}, [], 'CLI report removes response_demux and same-ID residue from auto-ID lifecycle residue');
    is_deeply($report->{id_response_rule_engine}{residue}, [qw(same_id_ordering)], 'CLI report removes response demux from ID/response residue');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'response-demux behavior keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager read response-demux behavior .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_response_demux_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_response_demux', 'read response-demux report carries the PPIF top-level intent name');
    assert_read_response_demux_report($report->{response_demux}, 'CLI report');
    assert_same_id_ordering_report($report->{same_id_ordering}, 'CLI report', 1, 'read');
    is_deeply($report->{auto_id_lifecycle}{residue}, [], 'CLI report removes generated read demux behavior from auto-ID lifecycle residue');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read response-demux behavior keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager burst-last read response-demux behavior .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_response_demux_burst_last_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status burst-last read response-demux .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status burst-last read response-demux report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_response_demux_burst_last', 'burst-last report carries the PPIF top-level intent name');
    assert_read_response_demux_burst_last_report($report->{response_demux}, 'CLI burst-last report');
    assert_rlast_report_prose_alignment($report, 'CLI burst-last report');
    assert_same_id_ordering_report($report->{same_id_ordering}, 'CLI burst-last report', 1, 'read');
    is_deeply($report->{auto_id_lifecycle}{residue}, [], 'CLI burst-last report removes generated read demux from lifecycle residue');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'burst-last behavior keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for mixed auto-ID and same-ID queue-head response-demux .ppif' => sub {
    my @cases = (
        {
            label      => 'read single-beat',
            path       => sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux_ppif_path(),
            intent     => 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux',
            family     => 'read',
            mode       => 'bounded_read_rid_mixed_auto_id_queue_head_demux_contract',
            request_id => 'axi0_arid',
            response_id => 'axi0_rid',
            transactions => [qw(r0 r1 r2)],
            queue_boundary => 'generated_read_single_beat_queue_head_demux',
            scope      => 'single_beat',
        },
        {
            label      => 'read burst-last',
            path       => sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux_ppif_path(),
            intent     => 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux',
            family     => 'read',
            mode       => 'bounded_read_rid_mixed_auto_id_queue_head_demux_contract',
            request_id => 'axi0_arid',
            response_id => 'axi0_rid',
            transactions => [qw(r0 r1 r2)],
            queue_boundary => 'generated_read_burst_last_queue_head_demux',
            scope      => 'burst_last',
            last_signal => 'axi0_rlast',
        },
        {
            label      => 'write',
            path       => sample_capacity_write_mixed_auto_id_same_id_queue_head_response_demux_ppif_path(),
            intent     => 'axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux',
            family     => 'write',
            mode       => 'bounded_write_bid_mixed_auto_id_queue_head_demux_contract',
            request_id => 'axi0_awid',
            response_id => 'axi0_bid',
            transactions => [qw(w0 w1 w2)],
            queue_boundary => 'generated_write_bid_queue_head_demux',
        },
    );

    for my $case (@cases) {
        my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--emit-schedule-json', $case->{path}],
        );
        ok($success, "mixed $case->{label} --emit-schedule-json succeeds");
        is(join('', @{$stderr_buf || []}), '', "mixed $case->{label} report keeps stderr clean");
        my $report = decode_json(join('', @{$stdout_buf || []}));
        is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "mixed $case->{label} report keeps schema");
        is($report->{source_object}{intent_name}, $case->{intent}, "mixed $case->{label} report carries the PPIF intent name");

        my $lifecycle = $report->{auto_id_lifecycle}{families}[0];
        is($lifecycle->{request_id_signal}, $case->{request_id}, "mixed $case->{label} reports generated request-ID signal");
        is($lifecycle->{request_id_direction}, 'generated_output', "mixed $case->{label} reports generated request-ID direction");
        is_deeply($report->{id_response_rule_engine}{id_signal_inputs}, [$case->{response_id}], "mixed $case->{label} reports only the response ID as concrete-ID input");

        my $entry = $report->{response_demux}{$case->{family}};
        is($entry->{mode}, $case->{mode}, "mixed $case->{label} reports mixed response-demux mode");
        is($entry->{transaction_completion_source}, 'generated_demux_and_queue_head_demux', "mixed $case->{label} reports combined completion source");
        is($entry->{generated_queue_behavior_boundary}, $case->{queue_boundary}, "mixed $case->{label} reports generated queue boundary");
        is_deeply($entry->{auto_transactions}, [$case->{transactions}[0]], "mixed $case->{label} reports the auto-ID transaction");
        is_deeply(
            $entry->{generated_completion_signals},
            [map { "axi0_${_}_complete" } @{$case->{transactions}}],
            "mixed $case->{label} reports combined completion outputs",
        );
        is_deeply(
            $entry->{same_id_issue_order_queues}[0]{transactions},
            [@{$case->{transactions}}[1, 2]],
            "mixed $case->{label} reports the concrete queue-head transactions",
        );
        is($entry->{generated_queue_behavior}, 1, "mixed $case->{label} reports generated queue behavior");
        is($entry->{response_id_signal}, $case->{response_id}, "mixed $case->{label} reports response ID signal");
        is($entry->{response_id_direction}, 'generated_input', "mixed $case->{label} reports response ID direction");
        is($entry->{response_scope}, $case->{scope}, "mixed $case->{label} reports read scope")
            if $case->{family} eq 'read';
        is($entry->{last_signal}, $case->{last_signal}, "mixed $case->{label} reports RLAST")
            if defined $case->{last_signal};

        my ($check_success, undef, undef, $check_stdout, $check_stderr) = run(
            command => ['./bin/fsmgen', '--strict', '--check', '--json', $case->{path}],
        );
        ok($check_success, "mixed $case->{label} --check --json succeeds");
        is(join('', @{$check_stderr || []}), '', "mixed $case->{label} check keeps stderr clean");
        my $check_report = decode_json(join('', @{$check_stdout || []}));
        ok($check_report->{success}, "mixed $case->{label} check reports success");
        is($check_report->{support_accounting}{entry_id}, $case->{entry_id}, "mixed $case->{label} check names the support-accounting entry");
        ok($check_report->{support_accounting}{strict_supported}, "mixed $case->{label} check reports strict support");
    }
};

subtest 'CLI emits IAL2 report JSON for mixed auto-ID and same-ID queue-head read-data .ppif' => sub {
    my @cases = (
        {
            label      => 'read-data single-beat',
            owner      => 'mixed auto-ID queue-head read-data single-beat',
            path       => \&sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_read_data_ppif_path,
            intent     => 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data',
            queue_boundary => 'generated_read_single_beat_queue_head_demux',
            scope      => 'single_beat',
            completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_completion_pulse',
            report_assertion => \&assert_read_data_report,
            report_assertion_args => ['generated_mixed_auto_id_queue_head_response_demux_completion_pulse'],
        },
        {
            label      => 'read-data burst-last',
            owner      => 'mixed auto-ID queue-head read-data burst-last',
            path       => \&sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_read_data_ppif_path,
            intent     => 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data',
            queue_boundary => 'generated_read_burst_last_queue_head_demux',
            scope      => 'burst_last',
            last_signal => 'axi0_rlast',
            completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
            report_assertion => \&assert_read_data_last_beat_report,
            report_assertion_args => ['generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
        },
        {
            label      => 'read-data burst-last report-only burst-length',
            owner      => 'mixed auto-ID queue-head read-data burst-last report-only burst-length',
            path       => \&sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_ppif_path,
            intent     => 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length',
            queue_boundary => 'generated_read_burst_last_queue_head_demux',
            scope      => 'burst_last',
            last_signal => 'axi0_rlast',
            completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
            report_assertion => \&assert_read_data_burst_length_report,
            report_assertion_args => ['report_only', 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
            burst_length => 1,
        },
        {
            label      => 'read-data burst-last runtime burst-length',
            owner      => 'mixed auto-ID queue-head read-data burst-last runtime burst-length',
            path       => \&sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion_ppif_path,
            intent     => 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion',
            queue_boundary => 'generated_read_burst_last_queue_head_demux',
            scope      => 'burst_last',
            last_signal => 'axi0_rlast',
            completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
            report_assertion => \&assert_read_data_burst_length_report,
            report_assertion_args => ['runtime_assertion', 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
            burst_length => 1,
            runtime_validation => 1,
        },
        {
            label      => 'read-data burst-last multi-beat output-bank',
            owner      => 'mixed auto-ID queue-head read-data burst-last multi-beat output-bank',
            path       => \&sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data_ppif_path,
            intent     => 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data',
            entry_id   => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data',
            queue_boundary => 'generated_read_burst_last_queue_head_demux',
            scope      => 'burst_last',
            last_signal => 'axi0_rlast',
            completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
            report_assertion => \&assert_read_data_multi_beat_report,
            report_assertion_args => [
                completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
            ],
            burst_length => 1,
            runtime_validation => 1,
            multi_beat => 1,
        },
    );

    for my $case (@cases) {
        my $path = $case->{path}->();
        my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
            command => ['./bin/fsmgen', '--emit-schedule-json', $path],
        );
        ok($success, "mixed $case->{label} --emit-schedule-json succeeds");
        is(join('', @{$stderr_buf || []}), '', "mixed $case->{label} report keeps stderr clean");
        my $report = decode_json(join('', @{$stdout_buf || []}));
        is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "mixed $case->{label} report keeps schema");
        is($report->{source_object}{intent_name}, $case->{intent}, "mixed $case->{label} report carries the PPIF intent name");

        my $lifecycle = $report->{auto_id_lifecycle}{families}[0];
        is($lifecycle->{request_id_signal}, 'axi0_arid', "mixed $case->{label} reports generated ARID output");
        is($lifecycle->{request_id_direction}, 'generated_output', "mixed $case->{label} reports generated ARID direction");
        is_deeply($report->{id_response_rule_engine}{id_signal_inputs}, ['axi0_rid'], "mixed $case->{label} reports only RID as concrete-ID input");

        my $entry = $report->{response_demux}{read};
        is($entry->{mode}, 'bounded_read_rid_mixed_auto_id_queue_head_demux_contract', "mixed $case->{label} reports mixed response-demux mode");
        is($entry->{transaction_completion_source}, 'generated_demux_and_queue_head_demux', "mixed $case->{label} reports combined completion source");
        is($entry->{generated_queue_behavior_boundary}, $case->{queue_boundary}, "mixed $case->{label} reports generated queue boundary");
        is($entry->{response_scope}, $case->{scope}, "mixed $case->{label} reports read response scope");
        is($entry->{last_signal}, $case->{last_signal}, "mixed $case->{label} reports RLAST")
            if defined $case->{last_signal};
        is_deeply($entry->{auto_transactions}, [qw(r0)], "mixed $case->{label} reports the auto-ID transaction");
        is_deeply($entry->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete)], "mixed $case->{label} reports combined completion outputs");
        is_deeply($entry->{same_id_issue_order_queues}[0]{transactions}, [qw(r1 r2)], "mixed $case->{label} reports the concrete queue-head transactions");
        ok($entry->{generated_queue_behavior}, "mixed $case->{label} reports generated queue behavior");

        $case->{report_assertion}->(
            $report->{read_data},
            "mixed $case->{label} CLI read-data report",
            @{$case->{report_assertion_args}},
            transactions => [qw(r0 r1 r2)],
        );
        is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "mixed $case->{label} keeps the generated .fsm artifact name stable");

        assert_ppif_strict_json_support_case(
            owner    => $case->{owner},
            path     => $case->{path},
            entry_id => $case->{entry_id},
        );

        if ($case->{burst_length}) {
            my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
                command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $path],
            );
            ok($semantic_success, "mixed $case->{label} semantic JSON succeeds");
            is(join('', @{$semantic_stderr || []}), '', "mixed $case->{label} semantic JSON keeps stderr clean");
            my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
            ok($semantic_report->{success}, "mixed $case->{label} semantic JSON reports success");
            is($semantic_report->{support_accounting}{entry_id}, $case->{entry_id}, "mixed $case->{label} semantic JSON names the support-accounting entry");

            SKIP: {
                my $skip_reason = external_systemverilog_validation_skip_reason();
                my $verify_test_count = $case->{runtime_validation} ? 7 : 6;
                $verify_test_count += 5 if $case->{multi_beat};
                skip $skip_reason, $verify_test_count if defined $skip_reason;

                my $tempdir = tempdir(CLEANUP => 1);
                my $hdl = File::Spec->catfile($tempdir, 'mixed-auto-id-queue-head-burst-length.sv');
                my ($verify_success, undef, undef, undef, $verify_stderr) = run(
                    command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $path],
                );
                ok($verify_success, "mixed $case->{label} --verify-hdl succeeds");
                is(join('', @{$verify_stderr || []}), '', "mixed $case->{label} --verify-hdl keeps stderr clean");
                ok(-f $hdl, "mixed $case->{label} --verify-hdl writes generated HDL");
                my $sv = slurp($hdl);
                like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, "mixed $case->{label} HDL exposes generated ARLEN input");
                like($sv, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, "mixed $case->{label} HDL declares r2 raw ARLEN storage");
                if ($case->{runtime_validation}) {
                    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, "mixed $case->{label} HDL declares r2 expected-beat storage");
                    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, "mixed $case->{label} HDL declares r2 beat-count storage");
                } else {
                    unlike($sv, qr/\bexpected_beats_q\b/, "mixed $case->{label} report-only HDL omits expected-beat storage");
                }
                if ($case->{multi_beat}) {
                    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, "mixed $case->{label} HDL exposes r2 beat 0 data output");
                    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, "mixed $case->{label} HDL exposes r2 valid-mask output");
                    like($sv, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, "mixed $case->{label} HDL guards r2 output-bank clear with request");
                    like($sv, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, "mixed $case->{label} HDL emits r2 lane 0 capture enable");
                    like($sv, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, "mixed $case->{label} HDL updates r2 scalar aggregate");
                }
            }
        }
    }
};

subtest 'CLI emits IAL2 report JSON for AXI manager read-data metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_data_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_data', 'read-data report carries the PPIF top-level intent name');
    assert_read_response_demux_report($report->{response_demux}, 'CLI read-data report');
    assert_read_data_report($report->{read_data}, 'CLI report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'read-data metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager last-beat read-data metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_data_last_beat_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status last-beat read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status last-beat read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_last_beat', 'last-beat read-data report carries the PPIF top-level intent name');
    assert_read_response_demux_burst_last_report($report->{response_demux}, 'CLI last-beat read-data report');
    assert_read_data_last_beat_report($report->{read_data}, 'CLI last-beat read-data report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'last-beat read-data metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager burst-length read-data metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_data_burst_length_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status burst-length read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status burst-length read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_burst_length', 'burst-length read-data report carries the PPIF top-level intent name');
    assert_read_response_demux_burst_last_report($report->{response_demux}, 'CLI burst-length read-data report');
    assert_read_data_burst_length_report($report->{read_data}, 'CLI burst-length read-data report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'burst-length read-data metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager runtime-assertion burst-length read-data metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_data_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status runtime-assertion burst-length read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status runtime-assertion burst-length read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_burst_length_runtime_assertion', 'runtime-assertion burst-length read-data report carries the PPIF top-level intent name');
    assert_read_response_demux_burst_last_report($report->{response_demux}, 'CLI runtime-assertion burst-length read-data report');
    assert_read_data_burst_length_report($report->{read_data}, 'CLI runtime-assertion burst-length read-data report', 'runtime_assertion');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'runtime-assertion burst-length read-data metadata keeps the generated .fsm artifact name stable');
};

subtest 'CLI emits IAL2 report JSON for AXI manager multi-beat read-data metadata .ppif' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', sample_capacity_read_data_multi_beat_ppif_path()],
    );

    ok($success, '--emit-schedule-json succeeds for capacity/status multi-beat read-data .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multi-beat read-data report keeps stderr clean');
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'CLI keeps the capacity/status report schema');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status_read_data_multi_beat', 'multi-beat read-data report carries the PPIF top-level intent name');
    assert_read_response_demux_burst_last_report($report->{response_demux}, 'CLI multi-beat read-data report', 1, 1);
    assert_same_id_ordering_report($report->{same_id_ordering}, 'CLI multi-beat read-data report', 1, 'read', 1, 1);
    assert_read_data_multi_beat_report($report->{read_data}, 'CLI multi-beat read-data report');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'multi-beat read-data metadata keeps the generated .fsm artifact name stable');
};

SKIP: {
    my $skip_reason = external_systemverilog_validation_skip_reason();
    skip $skip_reason, 21 if defined $skip_reason;

subtest 'CLI --verify-hdl accepts AXI manager auto-ID lifecycle behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_auto_id_lifecycle.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_auto_id_lifecycle_ppif_path()],
    );

    ok($success, 'capacity/status auto-ID lifecycle --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status auto-ID lifecycle --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'auto-ID lifecycle --output writes generated HDL');
    like(slurp($hdl), qr/\boutput\s+reg\s+\[3:0\]\s+axi0_awid\b/, 'auto-ID lifecycle HDL exposes generated AWID output');
    like(slurp($hdl), qr/\breg\s+\[3:0\]\s+axi0_w0_auto_id_q\b/, 'auto-ID lifecycle HDL exposes selected-ID state');
};

subtest 'CLI --verify-hdl accepts AXI manager response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'response-demux HDL exposes generated BID input');
    like($sv, qr/\boutput\s+reg\s+axi0_w0_complete\b/, 'response-demux HDL exposes generated completion output');
    like($sv, qr/axi0_write_complete\s*&\s*axi0_w0_auto_id_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_auto_id_q\)/, 'response-demux HDL lowers the BID match guard');
};

subtest 'CLI --verify-hdl accepts AXI manager write same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_write_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status write same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'write same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'write same-ID queue-head HDL exposes generated BID input');
    like($sv, qr/\boutput\s+reg\s+axi0_w0_complete\b/, 'write same-ID queue-head HDL exposes generated completion output');
    like($sv, qr/\breg\s+axi0_write_id3_same_id_issue_order_slot0_w0_q\b/, 'write same-ID queue-head HDL exposes queue-head slot state');
    like($sv, qr/axi0_write_complete\s*&\s*\(axi0_bid\s*==\s*4'd3\)\s*&\s*axi0_write_id3_same_id_issue_order_slot0_w0_q/, 'write same-ID queue-head HDL lowers the concrete BID head match guard');
};

subtest 'CLI --verify-hdl accepts AXI manager write depth-3 same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_depth3_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status write depth-3 same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write depth-3 same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'write depth-3 same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'write depth-3 same-ID queue-head HDL exposes generated BID input');
    like($sv, qr/\boutput\s+reg\s+axi0_w2_complete\b/, 'write depth-3 same-ID queue-head HDL exposes generated w2 completion output');
    like($sv, qr/\breg\s+axi0_write_id3_same_id_issue_order_slot2_w2_q\b/, 'write depth-3 same-ID queue-head HDL exposes slot2 queue state');
    like($sv, qr/axi0_write_complete\s*&\s*\(axi0_bid\s*==\s*4'd3\)\s*&\s*axi0_write_id3_same_id_issue_order_slot0_w2_q/, 'write depth-3 same-ID queue-head HDL lowers the concrete BID head match guard for w2');
};

subtest 'CLI --verify-hdl accepts AXI manager write multi-group same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_write_multi_group_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status write multi-group same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write multi-group same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'write multi-group same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'write multi-group same-ID queue-head HDL exposes generated BID input');
    like($sv, qr/\boutput\s+reg\s+axi0_w3_complete\b/, 'write multi-group same-ID queue-head HDL exposes generated w3 completion output');
    like($sv, qr/\breg\s+axi0_write_id5_same_id_issue_order_slot0_w2_q\b/, 'write multi-group same-ID queue-head HDL exposes second queue-head slot state');
    like($sv, qr/axi0_write_complete\s*&\s*\(axi0_bid\s*==\s*4'd5\)\s*&\s*axi0_write_id5_same_id_issue_order_slot0_w2_q/, 'write multi-group same-ID queue-head HDL lowers the concrete BID 5 head match guard');
};

subtest 'CLI --verify-hdl accepts AXI manager read single-beat same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat same-ID queue-head HDL exposes generated RID input');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat same-ID queue-head HDL does not expose RLAST');
    like($sv, qr/\boutput\s+reg\s+axi0_r0_complete\b/, 'read single-beat same-ID queue-head HDL exposes generated completion output');
    like($sv, qr/\breg\s+axi0_read_id3_same_id_issue_order_slot0_r0_q\b/, 'read single-beat same-ID queue-head HDL exposes queue-head slot state');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r0_q/, 'read single-beat same-ID queue-head HDL lowers the concrete RID head match guard');
};

subtest 'CLI --verify-hdl accepts AXI manager read single-beat depth-3 same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_depth3_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_depth3_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat depth-3 same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat depth-3 same-ID queue-head HDL exposes generated RID input');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat depth-3 same-ID queue-head HDL does not expose RLAST');
    like($sv, qr/\boutput\s+reg\s+axi0_r2_complete\b/, 'read single-beat depth-3 same-ID queue-head HDL exposes generated r2 completion output');
    like($sv, qr/\breg\s+axi0_read_id3_same_id_issue_order_slot2_r2_q\b/, 'read single-beat depth-3 same-ID queue-head HDL exposes slot2 queue state');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read single-beat depth-3 same-ID queue-head HDL lowers the concrete RID head match guard for r2');
};

subtest 'CLI --verify-hdl accepts AXI manager read burst-last depth-3 same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_burst_last_depth3_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read burst-last depth-3 same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read burst-last depth-3 same-ID queue-head HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read burst-last depth-3 same-ID queue-head HDL exposes generated RLAST input');
    like($sv, qr/\boutput\s+reg\s+axi0_r2_complete\b/, 'read burst-last depth-3 same-ID queue-head HDL exposes generated r2 completion output');
    like($sv, qr/\breg\s+axi0_read_id3_same_id_issue_order_slot2_r2_q\b/, 'read burst-last depth-3 same-ID queue-head HDL exposes slot2 queue state');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read burst-last depth-3 same-ID queue-head HDL lowers the RLAST-gated concrete RID head match guard for r2');
};

subtest 'CLI --verify-hdl accepts AXI manager read burst-last depth-3 same-ID queue-head read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_burst_last_depth3_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read burst-last depth-3 same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read burst-last depth-3 same-ID queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read burst-last depth-3 same-ID queue-head read-data HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read burst-last depth-3 same-ID queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'read burst-last depth-3 same-ID queue-head read-data HDL exposes r2 last data output');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read burst-last depth-3 same-ID queue-head read-data HDL drives r2 capture from generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read burst-last depth-3 same-ID queue-head read-data HDL lowers the RLAST-gated concrete RID head match guard for r2');
    like($sv, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'read burst-last depth-3 same-ID queue-head read-data HDL captures RDATA into r2 last output');
};

subtest 'CLI --verify-hdl accepts AXI manager read burst-last depth-3 same-ID queue-head burst-length behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_burst_last_depth3_same_id_queue_head_burst_length.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path()],
    );

    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read burst-last depth-3 same-ID queue-head burst-length --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL declares r2 raw ARLEN storage');
    like($sv, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length HDL guards r2 raw ARLEN capture with request');
    like($sv, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length HDL captures raw ARLEN into r2 storage');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length HDL drives r2 read-data capture from generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read burst-last depth-3 same-ID queue-head burst-length HDL lowers the RLAST-gated concrete RID head match guard for r2');
    unlike($sv, qr/\bexpected_beats_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL omits expected-beat storage');
    unlike($sv, qr/\bread_beat_count_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length HDL omits beat-count storage');
};

subtest 'CLI --verify-hdl accepts AXI manager read burst-last depth-3 same-ID queue-head burst-length runtime validation behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read burst-last depth-3 same-ID queue-head burst-length runtime validation --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL declares r2 raw ARLEN storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL declares r2 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL declares r2 beat-count storage');
    like($sv, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL initializes r2 expected count from ARLEN+1');
    like($sv, qr/axi0_r2_read_beat_count_q_next\s*=\s*axi0_r2_read_beat_count_q\s*\+\s*5'd1\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL increments r2 beat count');
    like($sv, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL emits r2 beat-count enable');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL keeps r2 read-data capture on generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(?axi0_rid\s*==\s*4'd3\)?\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL counts raw matched RID3 queue-head beats');
    unlike($sv, qr/\baxi0_r2_beat_valid\b/, 'read burst-last depth-3 same-ID queue-head burst-length runtime HDL does not expose r2 multi-beat valid output');
};

subtest 'CLI --verify-hdl accepts AXI manager read burst-last depth-3 same-ID queue-head multi-beat read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read burst-last depth-3 same-ID queue-head multi-beat read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read burst-last depth-3 multi-beat HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read burst-last depth-3 multi-beat HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read burst-last depth-3 multi-beat HDL exposes generated ARLEN input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read burst-last depth-3 multi-beat HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read burst-last depth-3 multi-beat HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, 'read burst-last depth-3 multi-beat HDL exposes r2 per-beat data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_beat_rresp_0\b/, 'read burst-last depth-3 multi-beat HDL exposes r2 per-beat status output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'read burst-last depth-3 multi-beat HDL exposes r2 scalar status aggregate output');
    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, 'read burst-last depth-3 multi-beat HDL exposes r2 valid-mask output');
    like($sv, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r2_read_beats\b/, 'read burst-last depth-3 multi-beat HDL exposes r2 length output');
    like($sv, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, 'read burst-last depth-3 multi-beat HDL clears r2 output bank on request');
    like($sv, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, 'read burst-last depth-3 multi-beat HDL emits r2 lane 0 capture enable');
    like($sv, qr/axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read burst-last depth-3 multi-beat HDL references RID3 slot-0 transaction identity for r2');
    like($sv, qr/axi0_r2_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'read burst-last depth-3 multi-beat HDL captures r2 lane 0 RDATA');
    like($sv, qr/axi0_r2_beat_rresp_0_next\s*=\s*axi0_rresp\s*;/, 'read burst-last depth-3 multi-beat HDL captures r2 lane 0 RRESP');
    like($sv, qr/axi0_r2_beat_valid_next\s*=\s*16'b1\s*;/, 'read burst-last depth-3 multi-beat HDL sets the first r2 valid-mask prefix');
    like($sv, qr/axi0_r2_read_beats_next\s*=\s*5'd1\s*;/, 'read burst-last depth-3 multi-beat HDL sets r2 length after first beat');
    like($sv, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'read burst-last depth-3 multi-beat HDL updates r2 scalar aggregate from current RRESP');
};

subtest 'CLI --verify-hdl accepts AXI manager read single-beat multi-group same-ID queue-head response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_multi_group_same_id_queue_head_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat multi-group same-ID queue-head response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat multi-group same-ID queue-head response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat multi-group same-ID queue-head HDL exposes generated RID input');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat multi-group same-ID queue-head HDL does not expose RLAST');
    like($sv, qr/\boutput\s+reg\s+axi0_r3_complete\b/, 'read single-beat multi-group same-ID queue-head HDL exposes generated r3 completion output');
    like($sv, qr/\breg\s+axi0_read_id5_same_id_issue_order_slot0_r2_q\b/, 'read single-beat multi-group same-ID queue-head HDL exposes second queue-head slot state');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r2_q/, 'read single-beat multi-group same-ID queue-head HDL lowers the concrete RID 5 head match guard');
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    write_multi_depth3
    write_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_case_args($case_name);
    subtest "CLI --verify-hdl accepts AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_verify_hdl_case(%case);
    };
}

subtest 'CLI --verify-hdl accepts AXI manager read single-beat same-ID queue-head read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read single-beat queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read single-beat queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_rdata\b/, 'read single-beat queue-head read-data HDL exposes r0 captured data output');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'read single-beat queue-head read-data HDL guards r0 capture with generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r0_q/, 'read single-beat queue-head read-data HDL keeps concrete RID queue-head demux guard');
    like($sv, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'read single-beat queue-head read-data HDL captures RDATA into r0 output');
    like($sv, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'read single-beat queue-head read-data HDL captures RRESP into r0 output');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat queue-head read-data HDL does not expose RLAST');
};

subtest 'CLI --verify-hdl accepts AXI manager read single-beat depth-3 same-ID queue-head read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_depth3_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat depth-3 same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat depth-3 same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat depth-3 queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read single-beat depth-3 queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read single-beat depth-3 queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_rdata\b/, 'read single-beat depth-3 queue-head read-data HDL exposes r2 captured data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'read single-beat depth-3 queue-head read-data HDL exposes r2 captured status output');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read single-beat depth-3 queue-head read-data HDL guards r2 capture with generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'read single-beat depth-3 queue-head read-data HDL keeps concrete RID 3 queue-head demux guard');
    like($sv, qr/axi0_r2_rdata_next\s*=\s*axi0_rdata\s*;/, 'read single-beat depth-3 queue-head read-data HDL captures RDATA into r2 output');
    like($sv, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'read single-beat depth-3 queue-head read-data HDL captures RRESP into r2 output');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat depth-3 queue-head read-data HDL does not expose RLAST');
};

subtest 'CLI --verify-hdl accepts AXI manager read single-beat multi-group same-ID queue-head read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_single_beat_multi_group_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read single-beat multi-group same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read single-beat multi-group same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read single-beat multi-group queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read single-beat multi-group queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read single-beat multi-group queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r3_rdata\b/, 'read single-beat multi-group queue-head read-data HDL exposes r3 captured data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r3_rresp\b/, 'read single-beat multi-group queue-head read-data HDL exposes r3 captured status output');
    like($sv, qr/assign\s+axi0_r3_read_data_capture_en\s*=\s*axi0_r3_complete\s*;/, 'read single-beat multi-group queue-head read-data HDL guards r3 capture with generated completion');
    like($sv, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r3_q/, 'read single-beat multi-group queue-head read-data HDL keeps concrete RID 5 queue-head demux guard');
    like($sv, qr/axi0_r3_rdata_next\s*=\s*axi0_rdata\s*;/, 'read single-beat multi-group queue-head read-data HDL captures RDATA into r3 output');
    like($sv, qr/axi0_r3_rresp_next\s*=\s*axi0_rresp\s*;/, 'read single-beat multi-group queue-head read-data HDL captures RRESP into r3 output');
    unlike($sv, qr/\baxi0_rlast\b/, 'read single-beat multi-group queue-head read-data HDL does not expose RLAST');
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_read_data_case_args($case_name);
    subtest "CLI --verify-hdl accepts AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_read_data_verify_hdl_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_last_beat_read_data_case_args($case_name);
    subtest "CLI --verify-hdl accepts AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_last_beat_read_data_verify_hdl_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    read_burst_multi_depth3_runtime_assertion
    read_burst_mixed_depth3_depth2_runtime_assertion
)) {
    my %case = queue_head_depth3_last_beat_burst_length_case_args($case_name);
    subtest "CLI --verify-hdl accepts AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_last_beat_burst_length_verify_hdl_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_multi_beat_read_data_case_args($case_name);
    subtest "CLI --verify-hdl accepts AXI manager $case{owner} .ppif" => sub {
        assert_ppif_queue_head_multi_beat_read_data_verify_hdl_case(%case);
    };
}

subtest 'CLI --verify-hdl accepts AXI manager read response-demux behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_response_demux.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_response_demux_ppif_path()],
    );

    ok($success, 'capacity/status read response-demux --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read response-demux --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read response-demux --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read response-demux HDL exposes generated RID input');
    like($sv, qr/\boutput\s+reg\s+axi0_r0_complete\b/, 'read response-demux HDL exposes generated completion output');
    like($sv, qr/axi0_read_complete\s*&\s*axi0_r0_auto_id_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_auto_id_q\)/, 'read response-demux HDL lowers the RID match guard');
};

subtest 'CLI --verify-hdl accepts AXI manager read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read-data HDL keeps generated RID input from read response-demux');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_rdata\b/, 'read-data HDL exposes r0 captured data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'read-data HDL exposes r0 captured status output');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'read-data HDL guards r0 capture with generated completion');
    like($sv, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'read-data HDL captures RDATA into r0 data output');
    like($sv, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'read-data HDL captures RRESP into r0 status output');
};

subtest 'CLI --verify-hdl accepts AXI manager read last-beat same-ID queue-head read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_last_beat_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read last-beat same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read last-beat same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read last-beat queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read last-beat queue-head read-data HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read last-beat queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read last-beat queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_last_rdata\b/, 'read last-beat queue-head read-data HDL exposes r0 last captured data output');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'read last-beat queue-head read-data HDL guards r0 capture with generated last-beat completion');
    like($sv, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'read last-beat queue-head read-data HDL captures RRESP into r0 last status output');
};

subtest 'CLI --verify-hdl accepts AXI manager read last-beat same-ID queue-head burst-length behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_last_beat_same_id_queue_head_burst_length.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path()],
    );

    ok($success, 'capacity/status read last-beat same-ID queue-head burst-length --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read last-beat same-ID queue-head burst-length --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read last-beat queue-head burst-length HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read last-beat queue-head burst-length HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read last-beat queue-head burst-length HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r0_arlen_q\b/, 'read last-beat queue-head burst-length HDL declares r0 raw ARLEN storage');
    like($sv, qr/assign\s+axi0_r0_burst_length_capture_en\s*=\s*axi0_r0_request\s*;/, 'read last-beat queue-head burst-length HDL guards r0 ARLEN capture with request');
    like($sv, qr/axi0_r0_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'read last-beat queue-head burst-length HDL captures raw ARLEN into r0 storage');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'read last-beat queue-head burst-length HDL guards r0 read-data capture with generated last-beat completion');
    like($sv, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'read last-beat queue-head burst-length HDL captures RDATA into r0 last data output');
    like($sv, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'read last-beat queue-head burst-length HDL captures RRESP into r0 last status output');
    unlike($sv, qr/\bexpected_beats_q\b/, 'read last-beat queue-head report-only burst-length HDL does not declare expected-beat storage');
    unlike($sv, qr/\bread_beat_count_q\b/, 'read last-beat queue-head report-only burst-length HDL does not declare beat-count storage');
};

subtest 'CLI --verify-hdl accepts AXI manager read last-beat same-ID queue-head burst-length runtime .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, 'capacity/status read last-beat same-ID queue-head burst-length runtime --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length runtime --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read last-beat same-ID queue-head burst-length runtime --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read last-beat queue-head burst-length runtime HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'read last-beat queue-head burst-length runtime HDL declares r0 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'read last-beat queue-head burst-length runtime HDL declares r0 beat-count storage');
    like($sv, qr/axi0_r0_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'read last-beat queue-head burst-length runtime HDL initializes r0 expected count from ARLEN+1');
    like($sv, qr/axi0_r0_read_beat_count_q_next\s*=\s*axi0_r0_read_beat_count_q\s*\+\s*5'd1\s*;/, 'read last-beat queue-head burst-length runtime HDL increments r0 beat count');
};

subtest 'CLI --verify-hdl accepts AXI manager read multi-beat same-ID queue-head read-data .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_multi_beat_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read multi-beat same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-beat same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read multi-beat same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read multi-beat queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read multi-beat queue-head read-data HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read multi-beat queue-head read-data HDL exposes generated ARLEN input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read multi-beat queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read multi-beat queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_beat_rdata_0\b/, 'read multi-beat queue-head read-data HDL exposes r0 per-beat data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_beat_rresp_0\b/, 'read multi-beat queue-head read-data HDL exposes r0 per-beat status output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'read multi-beat queue-head read-data HDL exposes r0 scalar status aggregate output');
    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r0_beat_valid\b/, 'read multi-beat queue-head read-data HDL exposes r0 valid-mask output');
    like($sv, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r0_read_beats\b/, 'read multi-beat queue-head read-data HDL exposes r0 length output');
    like($sv, qr/assign\s+axi0_r0_read_data_output_init_en\s*=\s*axi0_r0_request\s*;/, 'read multi-beat queue-head read-data HDL clears r0 output bank on request');
    like($sv, qr/assign\s+axi0_r0_read_beat_0_capture_en\s*=/, 'read multi-beat queue-head read-data HDL emits lane 0 capture enable');
    like($sv, qr/axi0_read_id3_same_id_issue_order_slot0_r0_q/, 'read multi-beat queue-head read-data HDL references slot-0 transaction identity');
    like($sv, qr/axi0_r0_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'read multi-beat queue-head read-data HDL captures lane 0 RDATA');
    like($sv, qr/axi0_r0_beat_rresp_0_next\s*=\s*axi0_rresp\s*;/, 'read multi-beat queue-head read-data HDL captures lane 0 RRESP');
    like($sv, qr/axi0_r0_beat_valid_next\s*=\s*16'b1\s*;/, 'read multi-beat queue-head read-data HDL sets the first valid-mask prefix');
    like($sv, qr/axi0_r0_read_beats_next\s*=\s*5'd1\s*;/, 'read multi-beat queue-head read-data HDL sets r0 length after first beat');
    like($sv, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'read multi-beat queue-head read-data HDL updates scalar aggregate from current RRESP');
};

subtest 'CLI --verify-hdl accepts AXI manager read multi-group same-ID queue-head read-data .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_multi_group_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read multi-group same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read multi-group same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read multi-group queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read multi-group queue-head read-data HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read multi-group queue-head read-data HDL exposes generated ARLEN input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read multi-group queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read multi-group queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, 'read multi-group queue-head read-data HDL exposes r2 per-beat data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_beat_rresp_0\b/, 'read multi-group queue-head read-data HDL exposes r2 per-beat status output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'read multi-group queue-head read-data HDL exposes r2 scalar status aggregate output');
    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, 'read multi-group queue-head read-data HDL exposes r2 valid-mask output');
    like($sv, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r2_read_beats\b/, 'read multi-group queue-head read-data HDL exposes r2 length output');
    like($sv, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, 'read multi-group queue-head read-data HDL clears r2 output bank on request');
    like($sv, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, 'read multi-group queue-head read-data HDL emits r2 lane 0 capture enable');
    like($sv, qr/axi0_read_id5_same_id_issue_order_slot0_r2_q/, 'read multi-group queue-head read-data HDL references RID5 slot-0 transaction identity');
    like($sv, qr/axi0_r2_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'read multi-group queue-head read-data HDL captures r2 lane 0 RDATA');
    like($sv, qr/axi0_r2_beat_rresp_0_next\s*=\s*axi0_rresp\s*;/, 'read multi-group queue-head read-data HDL captures r2 lane 0 RRESP');
    like($sv, qr/axi0_r2_beat_valid_next\s*=\s*16'b1\s*;/, 'read multi-group queue-head read-data HDL sets r2 first valid-mask prefix');
    like($sv, qr/axi0_r2_read_beats_next\s*=\s*5'd1\s*;/, 'read multi-group queue-head read-data HDL sets r2 length after first beat');
    like($sv, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'read multi-group queue-head read-data HDL updates r2 scalar aggregate from current RRESP');
};

subtest 'CLI --verify-hdl accepts AXI manager read multi-group last-beat same-ID queue-head read-data .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_multi_group_last_beat_same_id_queue_head_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path()],
    );

    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read multi-group last-beat same-ID queue-head read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read multi-group last-beat queue-head read-data HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read multi-group last-beat queue-head read-data HDL exposes generated RLAST input');
    unlike($sv, qr/\baxi0_arlen\b/, 'read multi-group last-beat queue-head read-data HDL does not expose ARLEN');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read multi-group last-beat queue-head read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read multi-group last-beat queue-head read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'read multi-group last-beat queue-head read-data HDL exposes r2 scalar data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_last_rresp\b/, 'read multi-group last-beat queue-head read-data HDL exposes r2 scalar status output');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r3_last_rdata\b/, 'read multi-group last-beat queue-head read-data HDL exposes r3 scalar data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r3_last_rresp\b/, 'read multi-group last-beat queue-head read-data HDL exposes r3 scalar status output');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read multi-group last-beat queue-head read-data HDL drives r2 scalar capture from generated completion');
    like($sv, qr/axi0_read_id5_same_id_issue_order_slot0_r2_q/, 'read multi-group last-beat queue-head read-data HDL references RID5 slot-0 transaction identity');
    like($sv, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'read multi-group last-beat queue-head read-data HDL captures r2 scalar RDATA');
    like($sv, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'read multi-group last-beat queue-head read-data HDL captures r2 scalar RRESP');
};

subtest 'CLI --verify-hdl accepts AXI manager read multi-group last-beat same-ID queue-head burst-length .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_multi_group_last_beat_same_id_queue_head_burst_length.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_ppif_path()],
    );

    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read multi-group last-beat same-ID queue-head burst-length --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read multi-group last-beat queue-head burst-length HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read multi-group last-beat queue-head burst-length HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read multi-group last-beat queue-head burst-length HDL exposes generated ARLEN input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read multi-group last-beat queue-head burst-length HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read multi-group last-beat queue-head burst-length HDL exposes generated RRESP input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'read multi-group last-beat queue-head burst-length HDL declares r2 raw ARLEN storage');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r3_arlen_q\b/, 'read multi-group last-beat queue-head burst-length HDL declares r3 raw ARLEN storage');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'read multi-group last-beat queue-head burst-length HDL exposes r2 scalar data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_last_rresp\b/, 'read multi-group last-beat queue-head burst-length HDL exposes r2 scalar status output');
    like($sv, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'read multi-group last-beat queue-head burst-length HDL guards r2 ARLEN capture with request');
    like($sv, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'read multi-group last-beat queue-head burst-length HDL captures raw ARLEN into r2 storage');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read multi-group last-beat queue-head burst-length HDL drives r2 scalar capture from generated completion');
    like($sv, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'read multi-group last-beat queue-head burst-length HDL captures r2 scalar RDATA');
    like($sv, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'read multi-group last-beat queue-head burst-length HDL captures r2 scalar RRESP');
    unlike($sv, qr/\bexpected_beats_q\b/, 'read multi-group last-beat queue-head report-only burst-length HDL omits expected-beat storage');
    unlike($sv, qr/\bread_beat_count_q\b/, 'read multi-group last-beat queue-head report-only burst-length HDL omits beat-count storage');
};

subtest 'CLI --verify-hdl accepts AXI manager read multi-group last-beat same-ID queue-head burst-length runtime .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'read multi-group last-beat same-ID queue-head burst-length runtime --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes generated RID input');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes generated RLAST input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes generated ARLEN input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes generated RRESP input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'read multi-group last-beat queue-head burst-length runtime HDL declares r2 raw ARLEN storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'read multi-group last-beat queue-head burst-length runtime HDL declares r2 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'read multi-group last-beat queue-head burst-length runtime HDL declares r2 beat-count storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r3_expected_beats_q\b/, 'read multi-group last-beat queue-head burst-length runtime HDL declares r3 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r3_read_beat_count_q\b/, 'read multi-group last-beat queue-head burst-length runtime HDL declares r3 beat-count storage');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes r2 scalar data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_last_rresp\b/, 'read multi-group last-beat queue-head burst-length runtime HDL exposes r2 scalar status output');
    like($sv, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL guards r2 ARLEN capture with request');
    like($sv, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL initializes r2 expected count from ARLEN+1');
    like($sv, qr/axi0_r2_read_beat_count_q_next\s*=\s*axi0_r2_read_beat_count_q\s*\+\s*5'd1\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL increments r2 beat count');
    like($sv, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'read multi-group last-beat queue-head burst-length runtime HDL emits r2 beat-count enable');
    like($sv, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL drives r2 scalar capture from generated completion');
    like($sv, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL captures r2 scalar RDATA');
    like($sv, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'read multi-group last-beat queue-head burst-length runtime HDL captures r2 scalar RRESP');
};

subtest 'CLI --verify-hdl accepts AXI manager last-beat read-data behavior .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_last_beat_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_data_last_beat_ppif_path()],
    );

    ok($success, 'capacity/status last-beat read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status last-beat read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'last-beat read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'last-beat read-data HDL keeps generated RID input from burst-last response-demux');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'last-beat read-data HDL keeps generated RLAST input from burst-last response-demux');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'last-beat read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'last-beat read-data HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_last_rdata\b/, 'last-beat read-data HDL exposes r0 captured last data output');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_last_rresp\b/, 'last-beat read-data HDL exposes r0 captured last status output');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'last-beat read-data HDL guards r0 capture with generated last-beat completion');
    like($sv, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'last-beat read-data HDL captures RDATA into r0 last data output');
    like($sv, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'last-beat read-data HDL captures RRESP into r0 last status output');
};

subtest 'CLI --verify-hdl accepts AXI manager burst-length read-data metadata .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_burst_length_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_data_burst_length_ppif_path()],
    );

    ok($success, 'capacity/status burst-length read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status burst-length read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'burst-length read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'burst-length read-data HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r0_arlen_q\b/, 'burst-length read-data HDL declares r0 raw ARLEN storage');
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_r1_arlen_q\b/, 'burst-length read-data HDL declares r1 raw ARLEN storage');
    like($sv, qr/assign\s+axi0_r0_burst_length_capture_en\s*=\s*axi0_r0_request\s*;/, 'burst-length read-data HDL guards r0 ARLEN capture with request');
    like($sv, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'burst-length read-data HDL guards r1 ARLEN capture with request');
    like($sv, qr/axi0_r0_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'burst-length read-data HDL captures raw ARLEN into r0 storage');
    like($sv, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'burst-length read-data HDL captures raw ARLEN into r1 storage');
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'burst-length read-data HDL keeps generated RID input from burst-last response-demux');
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'burst-length read-data HDL keeps generated RLAST input from burst-last response-demux');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'burst-length read-data HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'burst-length read-data HDL exposes generated RRESP input');
    like($sv, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'burst-length read-data HDL guards r0 capture with generated last-beat completion');
    like($sv, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'burst-length read-data HDL captures RDATA into r0 last data output');
    like($sv, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'burst-length read-data HDL captures RRESP into r0 last status output');
};

subtest 'CLI --verify-hdl accepts AXI manager runtime-assertion burst-length read-data metadata .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_runtime_assertion_burst_length_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_data_burst_length_runtime_assertion_ppif_path()],
    );

    ok($success, 'capacity/status runtime-assertion burst-length read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status runtime-assertion burst-length read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'runtime-assertion burst-length read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'runtime-assertion burst-length read-data HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'runtime-assertion HDL declares r0 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'runtime-assertion HDL declares r0 beat-count storage');
    like($sv, qr/axi0_r0_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'runtime-assertion HDL initializes r0 expected count from ARLEN+1');
    like($sv, qr/axi0_r0_read_beat_count_q_next\s*=\s*axi0_r0_read_beat_count_q\s*\+\s*5'd1\s*;/, 'runtime-assertion HDL increments r0 beat count');
    like($sv, qr/assert property .*axi0_arlen\s*<\s*8'd16.*axi0 r0 ARLEN is within configured max beats/, 'runtime-assertion HDL emits r0 ARLEN bound assertion');
    like($sv, qr/assert property .*axi0_rlast.*axi0 r0 RLAST appears only on the expected final read beat/, 'runtime-assertion HDL emits r0 early-RLAST assertion');
    like($sv, qr/assert property .*axi0_rlast.*axi0 r0 expected final read beat has RLAST/, 'runtime-assertion HDL emits r0 missing-RLAST assertion');
    like($sv, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'runtime-assertion HDL still captures RDATA into r0 last data output');
    like($sv, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'runtime-assertion HDL still captures RRESP into r0 last status output');
};

subtest 'CLI --verify-hdl accepts AXI manager multi-beat read-data output-bank .ppif' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, 'axi_multi_beat_read_data.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, sample_capacity_read_data_multi_beat_ppif_path()],
    );

    ok($success, 'capacity/status multi-beat read-data --verify-hdl succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multi-beat read-data --verify-hdl keeps stderr clean');
    ok(-f $hdl, 'multi-beat read-data --output writes generated HDL');
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'multi-beat HDL exposes generated ARLEN input');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'multi-beat HDL declares r0 expected-beat storage');
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'multi-beat HDL declares r0 beat-count storage');
    like($sv, qr/assert property .*axi0_arlen\s*<\s*8'd16.*axi0 r0 ARLEN is within configured max beats/, 'multi-beat HDL emits r0 ARLEN bound assertion');
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'multi-beat HDL exposes generated RDATA input');
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'multi-beat HDL exposes generated RRESP input');
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_beat_rdata_0\b/, 'multi-beat HDL exposes data lanes');
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_beat_rresp_0\b/, 'multi-beat HDL exposes status lanes');
    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r0_beat_valid\b/, 'multi-beat HDL exposes valid-mask outputs');
    like($sv, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r0_read_beats\b/, 'multi-beat HDL exposes length outputs');
    like($sv, qr/assign\s+axi0_r0_read_data_output_init_en\s*=\s*axi0_r0_request\s*;/, 'multi-beat HDL drives output-bank clear from request');
    like($sv, qr/assign\s+axi0_r0_read_beat_0_capture_en\s*=/, 'multi-beat HDL emits lane 0 capture enable');
    like($sv, qr/axi0_r0_beat_rdata_0_next\s*=\s*32'd0\s*;/, 'multi-beat HDL clears lane 0 data');
    like($sv, qr/axi0_r0_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'multi-beat HDL captures lane 0 data');
    like($sv, qr/axi0_r0_beat_valid_next\s*=\s*16'b1\s*;/, 'multi-beat HDL sets first valid-mask prefix');
    like($sv, qr/axi0_r0_read_beats_next\s*=\s*5'd1\s*;/, 'multi-beat HDL sets first length value');
};

}

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

SKIP: {
    my $skip_reason = external_systemverilog_validation_skip_reason();
    skip $skip_reason, 2 if defined $skip_reason;

subtest 'CLI --outdir and --verify-hdl materialize capacity/status review artifacts and HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_capacity.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, '--verify-hdl', sample_capacity_ppif_path()],
    );

    ok($success, 'capacity/status CLI generation and --verify-hdl succeed');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status generation keeps stderr clean');
    ok(-f File::Spec->catfile($outdir, 'axi0_capacity_status.isf'), 'capacity/status --outdir writes generated .isf');
    ok(-f File::Spec->catfile($outdir, 'axi0_capacity_status.fsm'), 'capacity/status --outdir writes generated .fsm');
    ok(-f $hdl, 'capacity/status --output writes generated HDL');
    like(slurp(File::Spec->catfile($outdir, 'axi0_capacity_status.isf')), qr/\(actor axi0_capacity_status\b/, 'capacity/status generated .isf is inspectable text');
    like(slurp($hdl), qr/\bmodule\s+axi0_capacity_status\b/, 'capacity/status HDL contains the generated module');
    like(slurp($hdl), qr/\baxi0_read_can_accept\b/, 'capacity/status HDL contains the namespaced read can_accept status');
};

subtest 'CLI --outdir and --verify-hdl materialize transaction dispatch review artifacts and HDL' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $outdir = File::Spec->catdir($tempdir, 'out');
    my $hdl = File::Spec->catfile($tempdir, 'axi_dispatch.sv');

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--outdir', $outdir, '--output', $hdl, '--verify-hdl', sample_capacity_transaction_dispatch_ppif_path()],
    );

    ok($success, 'transaction dispatch CLI generation and --verify-hdl succeed');
    is(join('', @{$stderr_buf || []}), '', 'transaction dispatch generation keeps stderr clean');
    my $isf = slurp(File::Spec->catfile($outdir, 'axi0_capacity_status.isf'));
    my $fsm = slurp(File::Spec->catfile($outdir, 'axi0_capacity_status.fsm'));
    my $sv = slurp($hdl);
    like($isf, qr/\(input axi0_w0_request\)/, 'transaction dispatch --outdir writes generated .isf with transaction event input');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'transaction dispatch --outdir writes generated .isf with request ID input');
    like($isf, qr/\(assert \(=> axi0_r0_request \(== axi0_arid 3\)\)/, 'transaction dispatch --outdir writes generated .isf with concrete request ID assertion');
    like($fsm, qr/\(-write_submit_only_occ0\s+<\(& \(\| axi0_w0_request axi0_w1_request\)/, 'transaction dispatch --outdir writes generated .fsm with OR fan-in guard');
    like($fsm, qr/\(\+assert[\s\S]*\(axi0_id_response_checks_assert_1 assert \(=> axi0_r0_complete \(== axi0_rid 3\)\)/, 'transaction dispatch --outdir writes generated .fsm with concrete response ID assertion');
    like($sv, qr/\bmodule\s+axi0_capacity_status\b/, 'transaction dispatch HDL contains the generated module');
    like($sv, qr/\baxi0_w0_request\s*\|\s*axi0_w1_request\b/, 'transaction dispatch HDL lowers request OR fan-in');
    my $request_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_r0_request) |-> (axi0_arid == 3))) else $error("axi0 r0 request ID matches concrete ID");';
    my $response_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_r0_complete) |-> (axi0_rid == 3))) else $error("axi0 r0 response ID matches concrete ID");';
    like($sv, qr/\Q$request_assert\E/, 'transaction dispatch HDL emits the concrete request ID assertion');
    like($sv, qr/\Q$response_assert\E/, 'transaction dispatch HDL emits the concrete response ID assertion');
};

}

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

subtest 'CLI check JSON and semantic JSON accept capacity/status .ppif public source identity' => sub {
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', sample_capacity_ppif_path()],
    );
    ok($success, 'capacity/status --check --json succeeds for .ppif');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_capacity_ppif_path()),
        'capacity/status check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status',
        'capacity/status check JSON support accounting names the PPIF corpus entry',
    );
    is($check_report->{support_accounting}{source_kind}, 'ppif', 'capacity/status check JSON records PPIF source kind');

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', sample_capacity_ppif_path()],
    );
    ok($semantic_success, 'capacity/status --emit-semantic-json succeeds for .ppif');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs(sample_capacity_ppif_path()),
        'capacity/status semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status',
        'capacity/status semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{source_root_kind},
        'fsm',
        'capacity/status semantic JSON payload still describes the generated .fsm semantic root',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status semantic JSON records the generated capacity/status module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account ID-family .ppif separately' => sub {
    my $id_family_path = sample_capacity_id_family_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $id_family_path],
    );
    ok($success, 'capacity/status ID-family --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status ID-family --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status ID-family check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($id_family_path),
        'capacity/status ID-family check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_id_family',
        'capacity/status ID-family check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $id_family_path],
    );
    ok($semantic_success, 'capacity/status ID-family --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status ID-family --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status ID-family semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($id_family_path),
        'capacity/status ID-family semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_id_family',
        'capacity/status ID-family semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status ID-family semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account transaction-envelope .ppif separately' => sub {
    my $transaction_path = sample_capacity_transaction_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $transaction_path],
    );
    ok($success, 'capacity/status transaction-envelope --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status transaction-envelope --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status transaction-envelope check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($transaction_path),
        'capacity/status transaction-envelope check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_transaction_envelope',
        'capacity/status transaction-envelope check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $transaction_path],
    );
    ok($semantic_success, 'capacity/status transaction-envelope --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status transaction-envelope --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status transaction-envelope semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($transaction_path),
        'capacity/status transaction-envelope semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_transaction_envelope',
        'capacity/status transaction-envelope semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status transaction-envelope semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic transaction-ID .ppif separately' => sub {
    my $dynamic_path = sample_capacity_dynamic_transaction_id_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $dynamic_path],
    );
    ok($success, 'capacity/status dynamic transaction-ID --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic transaction-ID --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status dynamic transaction-ID check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic transaction-ID check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_transaction_id',
        'capacity/status dynamic transaction-ID check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $dynamic_path],
    );
    ok($semantic_success, 'capacity/status dynamic transaction-ID --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status dynamic transaction-ID --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status dynamic transaction-ID semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic transaction-ID semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_transaction_id',
        'capacity/status dynamic transaction-ID semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status dynamic transaction-ID semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic write response-demux .ppif separately' => sub {
    my $dynamic_path = sample_capacity_dynamic_write_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $dynamic_path],
    );
    ok($success, 'capacity/status dynamic write response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic write response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status dynamic write response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic write response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux',
        'capacity/status dynamic write response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $dynamic_path],
    );
    ok($semantic_success, 'capacity/status dynamic write response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status dynamic write response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status dynamic write response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic write response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux',
        'capacity/status dynamic write response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status dynamic write response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic write response-demux .ppif separately' => sub {
    my $dynamic_path = sample_capacity_dynamic_write_response_demux_multi_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $dynamic_path],
    );
    ok($success, 'capacity/status multiple dynamic write response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multiple dynamic write response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status multiple dynamic write response-demux check JSON reports success');
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux_multi',
        'capacity/status multiple dynamic write response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $dynamic_path],
    );
    ok($semantic_success, 'capacity/status multiple dynamic write response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status multiple dynamic write response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status multiple dynamic write response-demux semantic JSON reports success');
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_write_response_demux_multi',
        'capacity/status multiple dynamic write response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status multiple dynamic write response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic read response-demux .ppif separately' => sub {
    my $dynamic_path = sample_capacity_dynamic_read_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $dynamic_path],
    );
    ok($success, 'capacity/status dynamic read response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status dynamic read response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status dynamic read response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic read response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux',
        'capacity/status dynamic read response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $dynamic_path],
    );
    ok($semantic_success, 'capacity/status dynamic read response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status dynamic read response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status dynamic read response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($dynamic_path),
        'capacity/status dynamic read response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux',
        'capacity/status dynamic read response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status dynamic read response-demux semantic JSON records the generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic read response-demux .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic read response-demux',
        path     => \&sample_capacity_dynamic_read_response_demux_multi_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_multi',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic read burst-last response-demux .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic read burst-last response-demux',
        path     => \&sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status dynamic read-data',
        path     => \&sample_capacity_dynamic_read_data_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic last-beat read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status dynamic last-beat read-data',
        path     => \&sample_capacity_dynamic_read_data_last_beat_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_last_beat',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic last-beat read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic last-beat read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_last_beat_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_last_beat',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic burst-length read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic burst-length read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_burst_length_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_burst_length',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic runtime burst-length read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic runtime burst-length read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic burst-length read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status dynamic burst-length read-data',
        path     => \&sample_capacity_dynamic_read_data_burst_length_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic runtime burst-length read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status dynamic runtime burst-length read-data',
        path     => \&sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion',
    );
};

subtest 'CLI check JSON and semantic JSON support-account dynamic multi-beat read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status dynamic multi-beat read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_beat_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_beat',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multiple dynamic multi-beat read-data .ppif separately' => sub {
    assert_ppif_strict_json_support_case(
        owner    => 'capacity/status multiple dynamic multi-beat read-data',
        path     => \&sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif_path,
        entry_id => 'intent.ppif_axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat',
    );
};

subtest 'CLI check JSON and semantic JSON support-account transaction-event dispatch .ppif separately' => sub {
    my $dispatch_path = sample_capacity_transaction_dispatch_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $dispatch_path],
    );
    ok($success, 'capacity/status transaction-event dispatch --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status transaction-event dispatch --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status transaction-event dispatch check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($dispatch_path),
        'capacity/status transaction-event dispatch check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_transaction_event_dispatch',
        'capacity/status transaction-event dispatch check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $dispatch_path],
    );
    ok($semantic_success, 'capacity/status transaction-event dispatch --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status transaction-event dispatch --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status transaction-event dispatch semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($dispatch_path),
        'capacity/status transaction-event dispatch semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_transaction_event_dispatch',
        'capacity/status transaction-event dispatch semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status transaction-event dispatch semantic JSON records the generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account same-ID reject policy .ppif separately' => sub {
    my $policy_path = sample_capacity_same_id_reject_policy_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status same-ID reject policy --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID reject policy --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status same-ID reject policy check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID reject policy check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_reject_policy',
        'capacity/status same-ID reject policy check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status same-ID reject policy --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status same-ID reject policy --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status same-ID reject policy semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID reject policy semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_reject_policy',
        'capacity/status same-ID reject policy semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status same-ID reject policy semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account same-ID issue-order queue policy .ppif separately' => sub {
    my $policy_path = sample_capacity_same_id_issue_order_queue_policy_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status same-ID issue-order queue policy --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID issue-order queue policy --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status same-ID issue-order queue policy check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID issue-order queue policy check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_issue_order_queue_policy',
        'capacity/status same-ID issue-order queue policy check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status same-ID issue-order queue policy --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status same-ID issue-order queue policy --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status same-ID issue-order queue policy semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID issue-order queue policy semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_issue_order_queue_policy',
        'capacity/status same-ID issue-order queue policy semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status same-ID issue-order queue policy semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_queue_head_response_demux',
        'capacity/status same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_same_id_queue_head_response_demux',
        'capacity/status same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-group same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-group same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-group same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux',
        'capacity/status read multi-group same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-group same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-group same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-group same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux',
        'capacity/status read multi-group same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-group same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat multi-group same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat multi-group same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat multi-group same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat multi-group same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux',
        'capacity/status read single-beat multi-group same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat multi-group same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat multi-group same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat multi-group same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux',
        'capacity/status read single-beat multi-group same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat multi-group same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-group last-beat same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data',
        'capacity/status read multi-group last-beat same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-group last-beat same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data',
        'capacity/status read multi-group last-beat same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-group last-beat same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-group last-beat same-ID queue-head burst-length .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head burst-length check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head burst-length check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head burst-length semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head burst-length semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-group last-beat same-ID queue-head burst-length runtime .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-group last-beat same-ID queue-head burst-length runtime semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-group same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-group same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-group same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-group same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data',
        'capacity/status read multi-group same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-group same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-group same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-group same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-group same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data',
        'capacity/status read multi-group same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-group same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux',
        'capacity/status read single-beat same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux',
        'capacity/status read single-beat same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat depth-3 same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_depth3_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat depth-3 same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat depth-3 same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux',
        'capacity/status read single-beat depth-3 same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat depth-3 same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat depth-3 same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux',
        'capacity/status read single-beat depth-3 same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat depth-3 same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read burst-last depth-3 same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux',
        'capacity/status read burst-last depth-3 same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux',
        'capacity/status read burst-last depth-3 same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read burst-last depth-3 same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read burst-last depth-3 same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data',
        'capacity/status read burst-last depth-3 same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read burst-last depth-3 same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data',
        'capacity/status read burst-last depth-3 same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read burst-last depth-3 same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read burst-last depth-3 same-ID queue-head burst-length .ppif separately' => sub {
    my $policy_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read burst-last depth-3 same-ID queue-head burst-length runtime validation .ppif separately' => sub {
    my $policy_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read burst-last depth-3 same-ID queue-head burst-length runtime validation semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read burst-last depth-3 same-ID queue-head multi-beat read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data',
        'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data',
        'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read burst-last depth-3 same-ID queue-head multi-beat read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat depth-3 same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat depth-3 same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat depth-3 same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat depth-3 same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data',
        'capacity/status read single-beat depth-3 same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat depth-3 same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat depth-3 same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat depth-3 same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat depth-3 same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data',
        'capacity/status read single-beat depth-3 same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat depth-3 same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data',
        'capacity/status read single-beat same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data',
        'capacity/status read single-beat same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read single-beat multi-group same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read single-beat multi-group same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read single-beat multi-group same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat multi-group same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data',
        'capacity/status read single-beat multi-group same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read single-beat multi-group same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read single-beat multi-group same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read single-beat multi-group same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read single-beat multi-group same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data',
        'capacity/status read single-beat multi-group same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read single-beat multi-group same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

for my $case_name (qw(
    read_single_multi_depth3
    read_single_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_read_data_case_args($case_name);
    subtest "CLI check JSON and semantic JSON support-account $case{owner} .ppif separately" => sub {
        assert_ppif_strict_json_support_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_last_beat_read_data_case_args($case_name);
    subtest "CLI check JSON and semantic JSON support-account $case{owner} .ppif separately" => sub {
        assert_ppif_strict_json_support_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
    read_burst_multi_depth3_runtime_assertion
    read_burst_mixed_depth3_depth2_runtime_assertion
)) {
    my %case = queue_head_depth3_last_beat_burst_length_case_args($case_name);
    subtest "CLI check JSON and semantic JSON support-account $case{owner} .ppif separately" => sub {
        assert_ppif_strict_json_support_case(%case);
    };
}

for my $case_name (qw(
    read_burst_multi_depth3
    read_burst_mixed_depth3_depth2
)) {
    my %case = queue_head_depth3_multi_beat_read_data_case_args($case_name);
    subtest "CLI check JSON and semantic JSON support-account $case{owner} .ppif separately" => sub {
        assert_ppif_strict_json_support_case(%case);
    };
}

subtest 'CLI check JSON and semantic JSON support-account read last-beat same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read last-beat same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read last-beat same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data',
        'capacity/status read last-beat same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read last-beat same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read last-beat same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read last-beat same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data',
        'capacity/status read last-beat same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read last-beat same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read last-beat same-ID queue-head burst-length .ppif separately' => sub {
    my $policy_path = sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read last-beat same-ID queue-head burst-length --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read last-beat same-ID queue-head burst-length check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head burst-length check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length',
        'capacity/status read last-beat same-ID queue-head burst-length check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read last-beat same-ID queue-head burst-length --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read last-beat same-ID queue-head burst-length semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head burst-length semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length',
        'capacity/status read last-beat same-ID queue-head burst-length semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read last-beat same-ID queue-head burst-length semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read last-beat same-ID queue-head burst-length runtime .ppif separately' => sub {
    my $policy_path = sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read last-beat same-ID queue-head burst-length runtime --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length runtime --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read last-beat same-ID queue-head burst-length runtime check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head burst-length runtime check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read last-beat same-ID queue-head burst-length runtime check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read last-beat same-ID queue-head burst-length runtime --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read last-beat same-ID queue-head burst-length runtime --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read last-beat same-ID queue-head burst-length runtime semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read last-beat same-ID queue-head burst-length runtime semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion',
        'capacity/status read last-beat same-ID queue-head burst-length runtime semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read last-beat same-ID queue-head burst-length runtime semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read multi-beat same-ID queue-head read-data .ppif separately' => sub {
    my $policy_path = sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status read multi-beat same-ID queue-head read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read multi-beat same-ID queue-head read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read multi-beat same-ID queue-head read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-beat same-ID queue-head read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data',
        'capacity/status read multi-beat same-ID queue-head read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status read multi-beat same-ID queue-head read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read multi-beat same-ID queue-head read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read multi-beat same-ID queue-head read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status read multi-beat same-ID queue-head read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data',
        'capacity/status read multi-beat same-ID queue-head read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read multi-beat same-ID queue-head read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account write same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_write_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status write same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status write same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_same_id_queue_head_response_demux',
        'capacity/status write same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status write same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status write same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status write same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_same_id_queue_head_response_demux',
        'capacity/status write same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status write same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account write depth-3 same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status write depth-3 same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write depth-3 same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status write depth-3 same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write depth-3 same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux',
        'capacity/status write depth-3 same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status write depth-3 same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status write depth-3 same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status write depth-3 same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write depth-3 same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux',
        'capacity/status write depth-3 same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status write depth-3 same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account write multi-group same-ID queue-head response-demux .ppif separately' => sub {
    my $policy_path = sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, 'capacity/status write multi-group same-ID queue-head response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status write multi-group same-ID queue-head response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status write multi-group same-ID queue-head response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write multi-group same-ID queue-head response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux',
        'capacity/status write multi-group same-ID queue-head response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, 'capacity/status write multi-group same-ID queue-head response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status write multi-group same-ID queue-head response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status write multi-group same-ID queue-head response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($policy_path),
        'capacity/status write multi-group same-ID queue-head response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux',
        'capacity/status write multi-group same-ID queue-head response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status write multi-group same-ID queue-head response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account auto-ID lifecycle .ppif separately' => sub {
    my $lifecycle_path = sample_capacity_auto_id_lifecycle_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $lifecycle_path],
    );
    ok($success, 'capacity/status auto-ID lifecycle --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status auto-ID lifecycle --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status auto-ID lifecycle check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($lifecycle_path),
        'capacity/status auto-ID lifecycle check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_auto_id_lifecycle',
        'capacity/status auto-ID lifecycle check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $lifecycle_path],
    );
    ok($semantic_success, 'capacity/status auto-ID lifecycle --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status auto-ID lifecycle --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status auto-ID lifecycle semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($lifecycle_path),
        'capacity/status auto-ID lifecycle semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_auto_id_lifecycle',
        'capacity/status auto-ID lifecycle semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status auto-ID lifecycle semantic JSON records the generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account response-demux .ppif separately' => sub {
    my $demux_path = sample_capacity_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $demux_path],
    );
    ok($success, 'capacity/status response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_response_demux',
        'capacity/status response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $demux_path],
    );
    ok($semantic_success, 'capacity/status response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_response_demux',
        'capacity/status response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status response-demux semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read response-demux .ppif separately' => sub {
    my $demux_path = sample_capacity_read_response_demux_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $demux_path],
    );
    ok($success, 'capacity/status read response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status read response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_response_demux',
        'capacity/status read response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $demux_path],
    );
    ok($semantic_success, 'capacity/status read response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status read response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_response_demux',
        'capacity/status read response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read response-demux semantic JSON records the generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account burst-last read response-demux .ppif separately' => sub {
    my $demux_path = sample_capacity_read_response_demux_burst_last_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $demux_path],
    );
    ok($success, 'capacity/status burst-last read response-demux --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status burst-last read response-demux --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status burst-last read response-demux check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status burst-last read response-demux check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_response_demux_burst_last',
        'capacity/status burst-last read response-demux check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $demux_path],
    );
    ok($semantic_success, 'capacity/status burst-last read response-demux --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status burst-last read response-demux --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status burst-last read response-demux semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($demux_path),
        'capacity/status burst-last read response-demux semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_response_demux_burst_last',
        'capacity/status burst-last read response-demux semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status burst-last read response-demux semantic JSON records the generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account read-data .ppif separately' => sub {
    my $read_data_path = sample_capacity_read_data_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $read_data_path],
    );
    ok($success, 'capacity/status read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data',
        'capacity/status read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $read_data_path],
    );
    ok($semantic_success, 'capacity/status read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data',
        'capacity/status read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account last-beat read-data .ppif separately' => sub {
    my $read_data_path = sample_capacity_read_data_last_beat_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $read_data_path],
    );
    ok($success, 'capacity/status last-beat read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status last-beat read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status last-beat read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status last-beat read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_last_beat',
        'capacity/status last-beat read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $read_data_path],
    );
    ok($semantic_success, 'capacity/status last-beat read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status last-beat read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status last-beat read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status last-beat read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_last_beat',
        'capacity/status last-beat read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status last-beat read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account burst-length read-data .ppif separately' => sub {
    my $read_data_path = sample_capacity_read_data_burst_length_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $read_data_path],
    );
    ok($success, 'capacity/status burst-length read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status burst-length read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status burst-length read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status burst-length read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_burst_length',
        'capacity/status burst-length read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $read_data_path],
    );
    ok($semantic_success, 'capacity/status burst-length read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status burst-length read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status burst-length read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status burst-length read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_burst_length',
        'capacity/status burst-length read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status burst-length read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account runtime-assertion burst-length read-data .ppif separately' => sub {
    my $read_data_path = sample_capacity_read_data_burst_length_runtime_assertion_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $read_data_path],
    );
    ok($success, 'capacity/status runtime-assertion burst-length read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status runtime-assertion burst-length read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status runtime-assertion burst-length read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status runtime-assertion burst-length read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_burst_length_runtime_assertion',
        'capacity/status runtime-assertion burst-length read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $read_data_path],
    );
    ok($semantic_success, 'capacity/status runtime-assertion burst-length read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status runtime-assertion burst-length read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status runtime-assertion burst-length read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status runtime-assertion burst-length read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_burst_length_runtime_assertion',
        'capacity/status runtime-assertion burst-length read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status runtime-assertion burst-length read-data semantic JSON records the unchanged generated module',
    );
};

subtest 'CLI check JSON and semantic JSON support-account multi-beat read-data .ppif separately' => sub {
    my $read_data_path = sample_capacity_read_data_multi_beat_ppif_path();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $read_data_path],
    );
    ok($success, 'capacity/status multi-beat read-data --check --json succeeds');
    is(join('', @{$stderr_buf || []}), '', 'capacity/status multi-beat read-data --check --json keeps stderr clean');
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, 'capacity/status multi-beat read-data check JSON reports success');
    is(
        $check_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status multi-beat read-data check JSON reports the public .ppif source path',
    );
    is(
        $check_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_multi_beat',
        'capacity/status multi-beat read-data check JSON support accounting names the PPIF corpus entry',
    );

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $read_data_path],
    );
    ok($semantic_success, 'capacity/status multi-beat read-data --emit-semantic-json succeeds');
    is(join('', @{$semantic_stderr || []}), '', 'capacity/status multi-beat read-data --emit-semantic-json keeps stderr clean');
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, 'capacity/status multi-beat read-data semantic JSON reports success');
    is(
        $semantic_report->{source}{resolved_path},
        File::Spec->rel2abs($read_data_path),
        'capacity/status multi-beat read-data semantic JSON reports the public .ppif source path',
    );
    is(
        $semantic_report->{support_accounting}{entry_id},
        'intent.ppif_axi_manager_capacity_status_read_data_multi_beat',
        'capacity/status multi-beat read-data semantic JSON support accounting names the PPIF corpus entry',
    );
    is(
        $semantic_report->{semantic}{module}{name},
        'axi0_capacity_status',
        'capacity/status multi-beat read-data semantic JSON records the unchanged generated module',
    );
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

    SKIP: {
        my $skip_reason = external_systemverilog_validation_skip_reason();
        skip $skip_reason, 4 if defined $skip_reason;

        my $verify_outdir = File::Spec->catdir($tempdir, 'verify-out');
        my $verify_hdl = File::Spec->catfile($tempdir, 'verify-bundle.sv');
        my ($verify_success, undef, undef, undef, $verify_stderr) = run(
            command => ['./bin/fsmgen', '--quiet', '--outdir', $verify_outdir, '--output', $verify_hdl, '--verify-hdl', $bundle_path],
        );
        ok($verify_success, 'bundle --verify-hdl validates the aggregate wrapper/top HDL');
        is(join('', @{$verify_stderr || []}), '', 'bundle --verify-hdl keeps stderr clean');
        ok(-f $verify_hdl, 'bundle --verify-hdl writes the requested HDL output');
        ok(-f File::Spec->catfile($verify_outdir, 'axi_aw_w_valid_ready_bundle.fsm'), 'bundle --verify-hdl keeps wrapper/top review artifact in --outdir');
    }
};

done_testing();

sub external_systemverilog_validation_skip_reason {
    my @missing_tools = missing_systemverilog_validation_tools();
    return undef unless @missing_tools;
    return 'External SystemVerilog validation tools are not installed: ' . join(', ', @missing_tools);
}

sub sample_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_valid_ready.ppif');
}

sub sample_bundle_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_aw_w_valid_ready_bundle.ppif');
}

sub sample_capacity_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status.ppif');
}

sub sample_capacity_id_family_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_id_family.ppif');
}

sub sample_capacity_transaction_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_transaction_envelope.ppif');
}

sub sample_capacity_dynamic_transaction_id_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_transaction_id.ppif');
}

sub sample_capacity_dynamic_write_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_write_response_demux.ppif');
}

sub sample_capacity_dynamic_write_response_demux_multi_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif');
}

sub sample_capacity_dynamic_read_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_response_demux.ppif');
}

sub sample_capacity_dynamic_read_response_demux_multi_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif');
}

sub sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last.ppif');
}

sub sample_capacity_dynamic_read_response_demux_burst_last_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_response_demux_burst_last.ppif');
}

sub sample_capacity_dynamic_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data.ppif');
}

sub sample_capacity_dynamic_read_data_last_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_last_beat.ppif');
}

sub sample_capacity_dynamic_read_data_multi_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi.ppif');
}

sub sample_capacity_dynamic_read_data_multi_last_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi_last_beat.ppif');
}

sub sample_capacity_dynamic_read_data_multi_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length.ppif');
}

sub sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_dynamic_read_data_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_burst_length.ppif');
}

sub sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_dynamic_read_data_multi_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi_beat.ppif');
}

sub sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat.ppif');
}

sub sample_capacity_transaction_dispatch_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_transaction_event_dispatch.ppif');
}

sub sample_capacity_same_id_reject_policy_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_same_id_reject_policy.ppif');
}

sub sample_capacity_same_id_issue_order_queue_policy_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif');
}

sub sample_capacity_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data.ppif');
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data.ppif');
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data.ppif');
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data.ppif');
}

sub sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif');
}

sub sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif');
}

sub sample_capacity_write_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_write_multi_depth3_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_write_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_write_mixed_auto_id_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif');
}

sub sample_capacity_auto_id_lifecycle_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_auto_id_lifecycle.ppif');
}

sub sample_capacity_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_response_demux.ppif');
}

sub sample_capacity_read_response_demux_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_response_demux.ppif');
}

sub sample_capacity_read_response_demux_burst_last_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_response_demux_burst_last.ppif');
}

sub sample_capacity_read_data_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_data.ppif');
}

sub sample_capacity_read_data_last_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_data_last_beat.ppif');
}

sub sample_capacity_read_data_burst_length_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_data_burst_length.ppif');
}

sub sample_capacity_read_data_burst_length_runtime_assertion_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_data_burst_length_runtime_assertion.ppif');
}

sub sample_capacity_read_data_multi_beat_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_read_data_multi_beat.ppif');
}

sub sample_ppif {
    return slurp(sample_ppif_path());
}

sub sample_bundle_ppif {
    return slurp(sample_bundle_ppif_path());
}

sub sample_capacity_ppif {
    return slurp(sample_capacity_ppif_path());
}

sub sample_capacity_id_family_ppif {
    return slurp(sample_capacity_id_family_ppif_path());
}

sub sample_capacity_transaction_ppif {
    return slurp(sample_capacity_transaction_ppif_path());
}

sub sample_capacity_dynamic_transaction_id_ppif {
    return slurp(sample_capacity_dynamic_transaction_id_ppif_path());
}

sub sample_capacity_dynamic_write_response_demux_ppif {
    return slurp(sample_capacity_dynamic_write_response_demux_ppif_path());
}

sub sample_capacity_dynamic_write_response_demux_multi_ppif {
    return slurp(sample_capacity_dynamic_write_response_demux_multi_ppif_path());
}

sub sample_capacity_dynamic_read_response_demux_ppif {
    return slurp(sample_capacity_dynamic_read_response_demux_ppif_path());
}

sub sample_capacity_dynamic_read_response_demux_multi_ppif {
    return slurp(sample_capacity_dynamic_read_response_demux_multi_ppif_path());
}

sub sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif {
    return slurp(sample_capacity_dynamic_read_response_demux_multi_burst_last_ppif_path());
}

sub sample_capacity_dynamic_read_response_demux_burst_last_ppif {
    return slurp(sample_capacity_dynamic_read_response_demux_burst_last_ppif_path());
}

sub sample_capacity_dynamic_read_data_ppif {
    return slurp(sample_capacity_dynamic_read_data_ppif_path());
}

sub sample_capacity_dynamic_read_data_last_beat_ppif {
    return slurp(sample_capacity_dynamic_read_data_last_beat_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_last_beat_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_last_beat_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_burst_length_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_burst_length_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_dynamic_read_data_burst_length_ppif {
    return slurp(sample_capacity_dynamic_read_data_burst_length_ppif_path());
}

sub sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_dynamic_read_data_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_beat_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_beat_ppif_path());
}

sub sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif {
    return slurp(sample_capacity_dynamic_read_data_multi_transaction_multi_beat_ppif_path());
}

sub sample_capacity_transaction_dispatch_ppif {
    return slurp(sample_capacity_transaction_dispatch_ppif_path());
}

sub sample_capacity_same_id_reject_policy_ppif {
    return slurp(sample_capacity_same_id_reject_policy_ppif_path());
}

sub sample_capacity_same_id_issue_order_queue_policy_ppif {
    return slurp(sample_capacity_same_id_issue_order_queue_policy_ppif_path());
}

sub sample_capacity_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_multi_group_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_multi_group_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_multi_group_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_multi_group_last_beat_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_multi_group_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_mixed_auto_id_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_burst_last_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_depth3_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_ppif_path());
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif {
    return slurp(sample_capacity_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data_ppif_path());
}

sub sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_depth3_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_single_beat_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_last_beat_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif {
    return slurp(sample_capacity_read_last_beat_same_id_queue_head_burst_length_ppif_path());
}

sub sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_last_beat_same_id_queue_head_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif {
    return slurp(sample_capacity_read_multi_beat_same_id_queue_head_read_data_ppif_path());
}

sub sample_capacity_write_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_write_multi_depth3_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_multi_depth3_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_write_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_write_mixed_auto_id_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_mixed_auto_id_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif {
    return slurp(sample_capacity_write_multi_group_same_id_queue_head_response_demux_ppif_path());
}

sub sample_capacity_auto_id_lifecycle_ppif {
    return slurp(sample_capacity_auto_id_lifecycle_ppif_path());
}

sub sample_capacity_response_demux_ppif {
    return slurp(sample_capacity_response_demux_ppif_path());
}

sub sample_capacity_read_response_demux_ppif {
    return slurp(sample_capacity_read_response_demux_ppif_path());
}

sub sample_capacity_read_response_demux_burst_last_ppif {
    return slurp(sample_capacity_read_response_demux_burst_last_ppif_path());
}

sub sample_capacity_read_data_ppif {
    return slurp(sample_capacity_read_data_ppif_path());
}

sub sample_capacity_read_data_last_beat_ppif {
    return slurp(sample_capacity_read_data_last_beat_ppif_path());
}

sub sample_capacity_read_data_burst_length_ppif {
    return slurp(sample_capacity_read_data_burst_length_ppif_path());
}

sub sample_capacity_read_data_burst_length_runtime_assertion_ppif {
    return slurp(sample_capacity_read_data_burst_length_runtime_assertion_ppif_path());
}

sub sample_capacity_read_data_multi_beat_ppif {
    return slurp(sample_capacity_read_data_multi_beat_ppif_path());
}

sub sample_capacity_read_response_demux_base_ppif {
    my $source = sample_capacity_read_response_demux_ppif();
    $source =~ s/\n    \(response-demux\n      \(read\n        \(response-event axi0_read_complete\)\n        \(response-scope single-beat\)\n        \(transaction-completion generated\)\)\)//;
    $source =~ s/axi_manager_capacity_status_read_response_demux/axi_manager_capacity_status_read_response_demux_base/;
    $source =~ s/axi-manager-capacity-status-read-response-demux/axi-manager-capacity-status-read-response-demux-base/;
    return $source;
}

sub capacity_ppif_with_objects {
    my @objects = @_;
    return join("\n",
        '(protocol-platform-intent p',
        '  (profile axi4)',
        '  (source',
        '    (object axi-manager-capacity-status)',
        '    (anchor (document d) (section A1.1) (page p)))',
        @objects,
        ')',
        '',
    );
}

sub valid_ready_object {
    return join("\n",
        '  (valid-ready-channel axi_aw',
        '    (channel AW)',
        '    (role manager-to-subordinate)',
        '    (clock clk)',
        '    (reset (rst_n active_low async))',
        '    (valid awvalid)',
        '    (ready awready)',
        '    (payload (awaddr width 32)))',
    );
}

sub manager_capacity_object {
    my ($name) = @_;
    $name //= 'axi0';
    return join("\n",
        "  (manager-capacity-status $name",
        '    (clock clk)',
        '    (reset (rst_n active_low async))',
        '    (read-max-pending 4)',
        '    (write-max-pending 2)',
        '    (submit-policy try)',
        '    (read-submit axi0_read_submit)',
        '    (read-complete axi0_read_complete)',
        '    (write-submit axi0_write_submit)',
        '    (write-complete axi0_write_complete))',
    );
}

sub manager_capacity_object_without {
    my ($line_to_remove) = @_;
    my $object = manager_capacity_object();
    $object =~ s/^\s*\Q$line_to_remove\E\n//m;
    return $object;
}

sub manager_capacity_object_with {
    my ($replacement) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\(submit-policy try\)/$replacement/;
    return $object;
}

sub manager_capacity_object_with_status {
    my ($status_line) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\)\z/\n    (status $status_line))/;
    return $object;
}

sub manager_capacity_object_with_id_families {
    my ($families) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\)\z/\n    (id-families $families))/;
    return $object;
}

sub manager_capacity_object_with_transactions {
    my ($transactions) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\)\z/\n    (transactions $transactions))/;
    return $object;
}

sub manager_capacity_object_with_id_families_and_transactions {
    my ($families, $transactions) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\)\z/\n    (id-families $families)\n    (transactions $transactions))/;
    return $object;
}

sub manager_capacity_object_with_same_id_ordering {
    my ($ordering) = @_;
    my $object = manager_capacity_object_with_id_families_and_transactions(
        default_manager_id_families(),
        default_manager_transactions(),
    );
    $object =~ s/\)\z/\n    (same-id-ordering $ordering))/;
    return $object;
}

sub manager_capacity_object_with_duplicate_same_id_ordering {
    my $object = manager_capacity_object_with_id_families_and_transactions(
        default_manager_id_families(),
        default_manager_transactions(),
    );
    $object =~ s/\)\z/\n    (same-id-ordering (read (concrete-id-reuse reject)))\n    (same-id-ordering (write (concrete-id-reuse reject))))/;
    return $object;
}

sub manager_capacity_object_with_id_families_transactions_and_same_id_ordering {
    my ($families, $transactions, $ordering) = @_;
    my $object = manager_capacity_object_with_id_families_and_transactions($families, $transactions);
    $object =~ s/\)\z/\n    (same-id-ordering $ordering))/;
    return $object;
}

sub manager_capacity_object_with_id_families_transactions_same_id_ordering_and_response_demux {
    my ($families, $transactions, $ordering, $demux) = @_;
    my $object = manager_capacity_object_with_id_families_transactions_and_same_id_ordering(
        $families,
        $transactions,
        $ordering,
    );
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub default_manager_id_families {
    return '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))';
}

sub default_manager_transactions {
    return join(' ',
        '(write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))',
        '(write w1 (tag wr1) (request axi0_w1_request) (completion axi0_w1_complete) (id auto))',
        '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3)))',
    );
}

sub manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle {
    my ($families, $transactions, $lifecycle) = @_;
    my $object = manager_capacity_object_with_id_families_and_transactions($families, $transactions);
    $object =~ s/\)\z/\n    (auto-id-lifecycle $lifecycle))/;
    return $object;
}

sub manager_capacity_object_with_auto_id_lifecycle {
    my ($lifecycle) = @_;
    return manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
        default_manager_id_families(),
        default_manager_transactions(),
        $lifecycle,
    );
}

sub manager_capacity_object_with_transactions_and_auto_id_lifecycle {
    my ($transactions, $lifecycle) = @_;
    my $object = manager_capacity_object_with_transactions($transactions);
    $object =~ s/\)\z/\n    (auto-id-lifecycle $lifecycle))/;
    return $object;
}

sub manager_capacity_object_with_duplicate_auto_id_lifecycle {
    my $object = manager_capacity_object_with_id_families_and_transactions(
        default_manager_id_families(),
        default_manager_transactions(),
    );
    $object =~ s/\)\z/\n    (auto-id-lifecycle (write (pool 0)))\n    (auto-id-lifecycle (write (pool 1))))/;
    return $object;
}

sub manager_capacity_object_with_response_demux {
    my ($demux) = @_;
    my $object = manager_capacity_object_with_auto_id_lifecycle('(write (pool 0 1))');
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub manager_capacity_object_with_read_response_demux {
    my ($demux) = @_;
    my $object = manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
        default_manager_id_families(),
        default_manager_read_auto_transactions(),
        '(read (pool 0 1))',
    );
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub manager_capacity_object_with_read_data {
    my ($read_data) = @_;
    my $object = manager_capacity_object_with_read_response_demux(
        '(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))',
    );
    $object =~ s/\)\z/\n    (read-data $read_data))/;
    return $object;
}

sub manager_capacity_object_with_read_data_after_response_demux {
    my ($demux, $read_data) = @_;
    my $object = manager_capacity_object_with_read_response_demux($demux);
    $object =~ s/\)\z/\n    (read-data $read_data))/;
    return $object;
}

sub manager_capacity_object_with_duplicate_read_data {
    my $object = manager_capacity_object_with_read_response_demux(
        '(read (response-event axi0_read_complete) (response-scope single-beat) (transaction-completion generated))',
    );
    my $read_data = default_manager_read_data_clause();
    $object =~ s/\)\z/\n    (read-data $read_data)\n    (read-data $read_data))/;
    return $object;
}

sub manager_capacity_object_with_read_data_only {
    my ($read_data) = @_;
    my $object = manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
        default_manager_id_families(),
        default_manager_read_auto_transactions(),
        '(read (pool 0 1))',
    );
    $object =~ s/\)\z/\n    (read-data $read_data))/;
    return $object;
}

sub manager_capacity_object_with_mixed_response_demux {
    my ($demux) = @_;
    my $object = manager_capacity_object_with_id_families_transactions_and_auto_id_lifecycle(
        default_manager_id_families(),
        default_manager_mixed_auto_transactions(),
        '(write (pool 0 1)) (read (pool 0 1))',
    );
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub manager_capacity_object_with_duplicate_response_demux {
    my $object = manager_capacity_object_with_auto_id_lifecycle('(write (pool 0 1))');
    $object =~ s/\)\z/\n    (response-demux (write (response-event axi0_write_complete) (transaction-completion generated)))\n    (response-demux (write (response-event axi0_write_complete) (transaction-completion generated))))/;
    return $object;
}

sub manager_capacity_object_with_response_demux_only {
    my ($demux) = @_;
    my $object = manager_capacity_object();
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub manager_capacity_object_with_id_families_transactions_and_response_demux {
    my ($families, $transactions, $demux) = @_;
    my $object = manager_capacity_object_with_id_families_and_transactions($families, $transactions);
    $object =~ s/\)\z/\n    (response-demux $demux))/;
    return $object;
}

sub manager_capacity_object_with_id_families_transactions_and_read_data {
    my ($families, $transactions, $read_data) = @_;
    my $object = manager_capacity_object_with_id_families_and_transactions($families, $transactions);
    $object =~ s/\)\z/\n    (read-data $read_data))/;
    return $object;
}

sub default_manager_read_auto_transactions {
    return join(' ',
        '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id auto))',
        '(read r1 (tag rd1) (request axi0_r1_request) (completion axi0_r1_complete) (id auto))',
    );
}

sub default_manager_mixed_auto_transactions {
    return join(' ',
        '(write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))',
        '(write w1 (tag wr1) (request axi0_w1_request) (completion axi0_w1_complete) (id auto))',
        '(read r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id auto))',
        '(read r1 (tag rd1) (request axi0_r1_request) (completion axi0_r1_complete) (id auto))',
    );
}

sub default_manager_read_data_clause {
    return join(' ',
        '(read',
        '(capture-scope single-beat)',
        '(completion-source response-demux)',
        '(data-signal rdata (width 32))',
        '(status-signal rresp (width 2))',
        '(interleaving single-beat-by-rid)',
        '(transaction r0 (data-output r0_data) (status-output r0_resp))',
        '(transaction r1 (data-output r1_data) (status-output r1_resp))',
        ')',
    );
}

sub read_data_clause_with_burst_length {
    my ($burst_length) = @_;
    my $clause = default_manager_read_data_clause();
    $clause =~ s/\s+\(transaction r0/ $burst_length (transaction r0/
        or die "Could not insert burst-length clause into read-data fixture\n";
    return $clause;
}

sub last_beat_manager_read_data_clause {
    return join(' ',
        '(read',
        '(capture-scope last-beat)',
        '(completion-source response-demux)',
        '(data-signal rdata (width 32))',
        '(status-signal rresp (width 2))',
        '(status-policy last-beat)',
        '(interleaving last-beat-by-rid)',
        '(transaction r0 (data-output r0_last_data) (status-output r0_last_resp))',
        '(transaction r1 (data-output r1_last_data) (status-output r1_last_resp))',
        ')',
    );
}

sub last_beat_read_data_clause_with_burst_length {
    my ($burst_length) = @_;
    my $clause = last_beat_manager_read_data_clause();
    $clause =~ s/\s+\(transaction r0/ $burst_length (transaction r0/
        or die "Could not insert burst-length clause into last-beat read-data fixture\n";
    return $clause;
}

sub multi_beat_manager_read_data_clause {
    my ($burst_length) = @_;
    $burst_length //= burst_length_clause_with('(validation runtime-assertion)');
    return join(' ',
        '(read',
        '(capture-scope multi-beat)',
        '(completion-source response-demux)',
        '(data-signal rdata (width 32))',
        '(status-signal rresp (width 2))',
        '(status-policy per-beat)',
        '(status-aggregation (policy worst-observed))',
        '(interleaving multi-beat-by-rid)',
        $burst_length,
        '(transaction r0 (data-output-prefix r0_beat_data) (status-output-prefix r0_beat_resp) (status-aggregate-output r0_resp) (valid-mask-output r0_beat_valid) (length-output r0_read_beats))',
        '(transaction r1 (data-output-prefix r1_beat_data) (status-output-prefix r1_beat_resp) (status-aggregate-output r1_resp) (valid-mask-output r1_beat_valid) (length-output r1_read_beats))',
        ')',
    );
}

sub multi_beat_read_data_clause_without {
    my ($clause_to_remove) = @_;
    my $clause = multi_beat_manager_read_data_clause();
    $clause =~ s/\s+\Q$clause_to_remove\E//
        or die "Could not remove multi-beat read-data clause '$clause_to_remove'\n";
    return $clause;
}

sub multi_beat_read_data_clause_without_status_aggregation {
    my $clause = multi_beat_read_data_clause_without('(status-aggregation (policy worst-observed))');
    $clause =~ s/\s+\(status-aggregate-output r0_resp\)//
        or die "Could not remove r0 scalar aggregate output from multi-beat read-data fixture\n";
    $clause =~ s/\s+\(status-aggregate-output r1_resp\)//
        or die "Could not remove r1 scalar aggregate output from multi-beat read-data fixture\n";
    return $clause;
}

sub multi_beat_read_data_clause_with {
    my ($replacement) = @_;
    my $clause = multi_beat_manager_read_data_clause();
    my ($head) = $replacement =~ /\A\((\S+)/;
    my %default = (
        'status-policy'      => '(status-policy per-beat)',
        'status-aggregation' => '(status-aggregation (policy worst-observed))',
        'interleaving'       => '(interleaving multi-beat-by-rid)',
        'transaction'        => '(transaction r0 (data-output-prefix r0_beat_data) (status-output-prefix r0_beat_resp) (status-aggregate-output r0_resp) (valid-mask-output r0_beat_valid) (length-output r0_read_beats))',
    );
    die "Unknown multi-beat read-data replacement clause '$replacement'\n"
        unless defined $head && exists $default{$head};
    my $target = quotemeta $default{$head};
    $clause =~ s/$target/$replacement/;
    return $clause;
}

sub default_manager_burst_length_clause {
    return join(' ',
        '(burst-length',
        '(source arlen)',
        '(signal arlen (width 8))',
        '(encoding axlen-plus-one)',
        '(capture request)',
        '(max-beats 16)',
        '(validation report-only)',
        ')',
    );
}

sub burst_length_clause_without {
    my ($clause_to_remove) = @_;
    my $clause = default_manager_burst_length_clause();
    $clause =~ s/\s+\Q$clause_to_remove\E//
        or die "Could not remove burst-length clause '$clause_to_remove'\n";
    return $clause;
}

sub burst_length_clause_with {
    my ($replacement) = @_;
    my $clause = default_manager_burst_length_clause();
    my ($head) = $replacement =~ /\A\((\S+)/;
    my %default = (
        'source'     => '(source arlen)',
        'signal'     => '(signal arlen (width 8))',
        'encoding'   => '(encoding axlen-plus-one)',
        'capture'    => '(capture request)',
        'max-beats'  => '(max-beats 16)',
        'validation' => '(validation report-only)',
    );
    die "Unknown burst-length replacement clause '$replacement'\n"
        unless defined $head && exists $default{$head};
    my $target = quotemeta $default{$head};
    $clause =~ s/$target/$replacement/;
    return $clause;
}

sub burst_length_clause_with_extra {
    my ($extra) = @_;
    my $clause = default_manager_burst_length_clause();
    $clause =~ s/\)\z/$extra)/;
    return $clause;
}

sub last_beat_manager_read_data_clause_without_status_policy {
    my $clause = last_beat_manager_read_data_clause();
    $clause =~ s/\s+\(status-policy last-beat\)//;
    return $clause;
}

sub last_beat_read_data_clause_with {
    my ($replacement) = @_;
    my $clause = last_beat_manager_read_data_clause();
    my ($head) = $replacement =~ /\A\((\S+)/;
    my %default = (
        'capture-scope'     => '(capture-scope last-beat)',
        'completion-source' => '(completion-source response-demux)',
        'data-signal'       => '(data-signal rdata (width 32))',
        'status-signal'     => '(status-signal rresp (width 2))',
        'status-policy'     => '(status-policy last-beat)',
        'status-aggregation' => '(interleaving last-beat-by-rid)',
        'interleaving'      => '(interleaving last-beat-by-rid)',
        'transaction'       => '(transaction r0 (data-output r0_last_data) (status-output r0_last_resp))',
    );
    die "Unknown last-beat read-data replacement clause '$replacement'\n"
        unless defined $head && exists $default{$head};
    my $target = quotemeta $default{$head};
    if ($head eq 'status-aggregation') {
        $clause =~ s/$target/$replacement $default{'interleaving'}/;
    } else {
        $clause =~ s/$target/$replacement/;
    }
    return $clause;
}

sub read_data_clause_with {
    my ($replacement) = @_;
    my $clause = default_manager_read_data_clause();
    my ($head) = $replacement =~ /\A\((\S+)/;
    my %default = (
        'capture-scope'     => '(capture-scope single-beat)',
        'completion-source' => '(completion-source response-demux)',
        'data-signal'       => '(data-signal rdata (width 32))',
        'status-signal'     => '(status-signal rresp (width 2))',
        'status-policy'     => '(interleaving single-beat-by-rid)',
        'status-aggregation' => '(interleaving single-beat-by-rid)',
        'interleaving'      => '(interleaving single-beat-by-rid)',
        'transaction'       => '(transaction r0 (data-output r0_data) (status-output r0_resp))',
    );
    die "Unknown read-data replacement clause '$replacement'\n"
        unless defined $head && exists $default{$head};
    my $target = quotemeta $default{$head};
    if ($head eq 'status-policy' || $head eq 'status-aggregation') {
        $clause =~ s/$target/$replacement $default{'interleaving'}/;
    } else {
        $clause =~ s/$target/$replacement/;
    }
    return $clause;
}

sub assert_dynamic_transaction_id_report {
    my ($transactions, $owner) = @_;

    is(scalar(@$transactions), 2, "$owner reports both dynamic transaction-ID entries");
    is_deeply(
        $transactions->[0]{id},
        {
            policy                => 'dynamic',
            family                => 'write',
            family_width          => 4,
            request_id_source     => 'axi0_awid',
            response_id_signal    => 'axi0_bid',
            ownership             => 'user_supplied',
            implementation_status => 'selected_not_generated',
        },
        "$owner reports write dynamic ID metadata ownership",
    );
    is_deeply(
        $transactions->[1]{id},
        {
            policy                => 'dynamic',
            family                => 'read',
            family_width          => 4,
            request_id_source     => 'axi0_arid',
            response_id_signal    => 'axi0_rid',
            ownership             => 'user_supplied',
            implementation_status => 'selected_not_generated',
        },
        "$owner reports read dynamic ID metadata ownership",
    );
}

sub assert_dynamic_write_response_demux_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $write = $demux->{write};

    is(scalar(@{$report->{transactions}}), 1, "$owner reports one dynamic write transaction");
    is_deeply(
        $report->{transactions}[0]{id},
        {
            policy                => 'dynamic',
            family                => 'write',
            family_width          => 4,
            request_id_source     => 'axi0_awid',
            response_id_signal    => 'axi0_bid',
            ownership             => 'user_supplied',
            implementation_status => 'generated_capture_matching',
        },
        "$owner reports generated capture/matching dynamic ID ownership",
    );
    is($demux->{mode}, 'bounded_dynamic_write_bid_demux_contract', "$owner marks dynamic write BID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks dynamic response-demux behavior generated");
    is($write->{mode}, 'bounded_dynamic_write_bid_demux_contract', "$owner marks write dynamic demux mode");
    ok($write->{generated_behavior}, "$owner marks write dynamic demux behavior generated");
    is($write->{response_event}, 'axi0_write_complete', "$owner reports the raw write response event");
    is($write->{response_event_role}, 'raw_accepted_write_response', "$owner reports the response-event role");
    is($write->{response_id_signal}, 'axi0_bid', "$owner reports BID as the response ID signal");
    is($write->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($write->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($write->{transaction_completion_semantics}, 'matched_dynamic_id', "$owner reports matched dynamic ID completion semantics");
    is_deeply($write->{dynamic_transactions}, [qw(w0)], "$owner reports the covered dynamic write transaction");
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux)], "$owner reports generated dynamic demux rule");
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete)], "$owner reports generated dynamic completion pulse");
    is_deeply(
        $write->{generated_assertions},
        [qw(axi0_w0_dynamic_request_not_busy axi0_write_dynamic_response_active_match axi0_w0_dynamic_completion_active)],
        "$owner reports generated dynamic assertions",
    );
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
        },
        "$owner reports dynamic capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported dynamic-read, same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_dynamic_write_response_demux_multi_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $write = $demux->{write};

    is(scalar(@{$report->{transactions}}), 2, "$owner reports two dynamic write transactions");
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        "$owner reports generated capture/matching dynamic ID ownership for both writes",
    );
    is($demux->{mode}, 'bounded_multi_dynamic_write_bid_demux_contract', "$owner marks multiple dynamic write BID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks multiple dynamic response-demux behavior generated");
    is($write->{mode}, 'bounded_multi_dynamic_write_bid_demux_contract', "$owner marks write multiple dynamic demux mode");
    ok($write->{generated_behavior}, "$owner marks write multiple dynamic demux behavior generated");
    is($write->{response_event}, 'axi0_write_complete', "$owner reports the raw write response event");
    is($write->{response_event_role}, 'raw_accepted_write_response', "$owner reports the response-event role");
    is($write->{response_id_signal}, 'axi0_bid', "$owner reports BID as the response ID signal");
    is($write->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($write->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($write->{transaction_completion_semantics}, 'matched_dynamic_id', "$owner reports matched dynamic ID completion semantics");
    is_deeply($write->{dynamic_transactions}, [qw(w0 w1)], "$owner reports the covered dynamic write transactions");
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], "$owner reports generated dynamic demux rules");
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], "$owner reports generated dynamic completion pulses");
    is_deeply(
        $write->{generated_assertions},
        [qw(
            axi0_w0_dynamic_request_not_busy
            axi0_w1_dynamic_request_not_busy
            axi0_write_dynamic_request_onehot0
            axi0_w0_dynamic_request_no_active_same_id
            axi0_w1_dynamic_request_no_active_same_id
            axi0_w0_w1_write_dynamic_active_id_unique
            axi0_write_dynamic_response_active_match
            axi0_w0_w1_write_dynamic_response_unique_match
            axi0_w0_dynamic_completion_active
            axi0_w1_dynamic_completion_active
        )],
        "$owner reports generated multiple dynamic assertions",
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
                },
                {
                    transaction        => 'w1',
                    selected_id_signal => 'axi0_w1_dynamic_id_q',
                    busy_signal        => 'axi0_w1_dynamic_busy_q',
                    capture_rule       => 'axi0_w1_dynamic_id_capture',
                    release_rule       => 'axi0_w1_dynamic_id_release',
                },
            ],
        },
        "$owner reports multiple dynamic capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported dynamic-read, same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_dynamic_read_response_demux_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};

    is(scalar(@{$report->{transactions}}), 1, "$owner reports one dynamic read transaction");
    is_deeply(
        $report->{transactions}[0]{id},
        {
            policy                => 'dynamic',
            family                => 'read',
            family_width          => 4,
            request_id_source     => 'axi0_arid',
            response_id_signal    => 'axi0_rid',
            ownership             => 'user_supplied',
            implementation_status => 'generated_capture_matching',
        },
        "$owner reports generated capture/matching dynamic read ID ownership",
    );
    is($demux->{mode}, 'bounded_dynamic_read_rid_demux_contract', "$owner marks dynamic read RID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks dynamic read response-demux behavior generated");
    is($read->{mode}, 'bounded_dynamic_read_rid_demux_contract', "$owner marks read dynamic demux mode");
    ok($read->{generated_behavior}, "$owner marks read dynamic demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response', "$owner reports the response-event role");
    is($read->{response_scope}, 'single_beat', "$owner reports the selected single-beat response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_single_beat', "$owner reports matched dynamic read ID completion semantics");
    is_deeply($read->{dynamic_transactions}, [qw(r0)], "$owner reports the covered dynamic read transaction");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux)], "$owner reports generated dynamic read demux rule");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete)], "$owner reports generated dynamic read completion pulse");
    is_deeply(
        $read->{generated_assertions},
        [qw(axi0_r0_dynamic_request_not_busy axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)],
        "$owner reports generated dynamic read assertions",
    );
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
        },
        "$owner reports dynamic read capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_dynamic_read_response_demux_multi_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};

    is(scalar(@{$report->{transactions}}), 2, "$owner reports two dynamic read transactions");
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        "$owner reports generated capture/matching dynamic ID ownership for both reads",
    );
    is($demux->{mode}, 'bounded_multi_dynamic_read_rid_demux_contract', "$owner marks multiple dynamic read RID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks multiple dynamic read response-demux behavior generated");
    is($read->{mode}, 'bounded_multi_dynamic_read_rid_demux_contract', "$owner marks read multiple dynamic demux mode");
    ok($read->{generated_behavior}, "$owner marks read multiple dynamic demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response', "$owner reports the response-event role");
    is($read->{response_scope}, 'single_beat', "$owner reports the selected single-beat response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_single_beat', "$owner reports matched dynamic read ID completion semantics");
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], "$owner reports the covered dynamic read transactions");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated dynamic read demux rules");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated dynamic read completion pulses");
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_not_busy
            axi0_r1_dynamic_request_not_busy
            axi0_read_dynamic_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_read_dynamic_response_active_match
            axi0_r0_r1_read_dynamic_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
        )],
        "$owner reports generated multiple dynamic read assertions",
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
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                },
            ],
        },
        "$owner reports multiple dynamic read capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_dynamic_read_response_demux_multi_burst_last_report {
    my ($report, $owner, %args) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};
    my $expected_residue = $args{residue} // [qw(same_id_ordering read_data_interleaving bursts)];

    is(scalar(@{$report->{transactions}}), 2, "$owner reports two dynamic read RLAST transactions");
    is_deeply(
        [map { $_->{id}{implementation_status} } @{$report->{transactions}}],
        [qw(generated_capture_matching generated_capture_matching)],
        "$owner reports generated capture/matching dynamic ID ownership for both RLAST reads",
    );
    is($demux->{mode}, 'bounded_multi_dynamic_read_rid_rlast_demux_contract', "$owner marks multiple dynamic read RID/RLAST-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks multiple dynamic read RLAST response-demux behavior generated");
    is($read->{mode}, 'bounded_multi_dynamic_read_rid_rlast_demux_contract', "$owner marks read multiple dynamic RLAST demux mode");
    ok($read->{generated_behavior}, "$owner marks read multiple dynamic RLAST demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response beat event");
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', "$owner reports the response-event role");
    is($read->{response_scope}, 'burst_last', "$owner reports the selected burst-last response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{last_signal}, 'axi0_rlast', "$owner reports RLAST as the last signal");
    is($read->{last_signal_direction}, 'generated_input', "$owner reports RLAST direction as generated input");
    is($read->{last_signal_width}, 1, "$owner reports RLAST width");
    is($read->{transaction_completion_source}, 'generated_dynamic_demux_last_beat', "$owner reports generated dynamic last-beat demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_and_last_signal', "$owner reports matched dynamic ID and last-signal completion semantics");
    is($read->{beat_valid_output}, 'none', "$owner reports no per-beat valid output");
    is($read->{burst_length_source}, 'rlast_only', "$owner reports RLAST-only burst boundary");
    is($read->{burst_length_validation}, 'not_generated', "$owner reports no burst-length validation");
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], "$owner reports the covered dynamic read RLAST transactions");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated dynamic RLAST demux rules");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated dynamic RLAST completion pulses");
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_not_busy
            axi0_r1_dynamic_request_not_busy
            axi0_read_dynamic_request_onehot0
            axi0_r0_dynamic_request_no_active_same_id
            axi0_r1_dynamic_request_no_active_same_id
            axi0_r0_r1_read_dynamic_active_id_unique
            axi0_read_dynamic_response_active_match
            axi0_r0_r1_read_dynamic_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_dynamic_completion_active
        )],
        "$owner reports generated multiple dynamic RLAST assertions",
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
                },
                {
                    transaction        => 'r1',
                    selected_id_signal => 'axi0_r1_dynamic_id_q',
                    busy_signal        => 'axi0_r1_dynamic_busy_q',
                    capture_rule       => 'axi0_r1_dynamic_id_capture',
                    release_rule       => 'axi0_r1_dynamic_id_release',
                },
            ],
        },
        "$owner reports multiple dynamic read RLAST capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        $expected_residue,
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_dynamic_read_response_demux_burst_last_report {
    my ($report, $owner, %args) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};

    is(scalar(@{$report->{transactions}}), 1, "$owner reports one dynamic read RLAST transaction");
    is_deeply(
        $report->{transactions}[0]{id},
        {
            policy                => 'dynamic',
            family                => 'read',
            family_width          => 4,
            request_id_source     => 'axi0_arid',
            response_id_signal    => 'axi0_rid',
            ownership             => 'user_supplied',
            implementation_status => 'generated_capture_matching',
        },
        "$owner reports generated capture/matching dynamic read RLAST ID ownership",
    );
    is($demux->{mode}, 'bounded_dynamic_read_rid_rlast_demux_contract', "$owner marks dynamic read RID/RLAST-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks dynamic read RLAST response-demux behavior generated");
    is($read->{mode}, 'bounded_dynamic_read_rid_rlast_demux_contract', "$owner marks read dynamic RLAST demux mode");
    ok($read->{generated_behavior}, "$owner marks read dynamic RLAST demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response beat event");
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', "$owner reports the response-event role");
    is($read->{response_scope}, 'burst_last', "$owner reports the selected burst-last response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{last_signal}, 'axi0_rlast', "$owner reports RLAST as the last signal");
    is($read->{last_signal_direction}, 'generated_input', "$owner reports RLAST direction as generated input");
    is($read->{last_signal_width}, 1, "$owner reports RLAST width");
    is($read->{transaction_completion_source}, 'generated_dynamic_demux_last_beat', "$owner reports generated dynamic last-beat demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_and_last_signal', "$owner reports matched dynamic ID and last-signal completion semantics");
    is($read->{beat_valid_output}, 'none', "$owner reports no per-beat valid output");
    is($read->{burst_length_source}, 'rlast_only', "$owner reports RLAST-only burst boundary");
    is($read->{burst_length_validation}, 'not_generated', "$owner reports no burst-length validation");
    is_deeply($read->{dynamic_transactions}, [qw(r0)], "$owner reports the covered dynamic read RLAST transaction");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux)], "$owner reports generated dynamic RLAST demux rule");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete)], "$owner reports generated dynamic RLAST completion pulse");
    is_deeply(
        $read->{generated_assertions},
        [qw(axi0_r0_dynamic_request_not_busy axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)],
        "$owner reports generated dynamic RLAST assertions",
    );
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
        },
        "$owner reports dynamic read RLAST capture state and rule ownership",
    );
    is_deeply(
        $demux->{residue},
        $args{residue} || [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_write_auto_id_lifecycle_report {
    my ($lifecycle, $owner) = @_;
    is($lifecycle->{mode}, 'bounded_pool_contract', "$owner marks bounded-pool auto-ID lifecycle mode");
    ok($lifecycle->{generated_behavior}, "$owner marks generated behavior true");
    is($lifecycle->{max_pool_entries_per_family}, 4, "$owner publishes the bounded pool-entry cap");
    is_deeply(
        $lifecycle->{residue},
        [qw(response_demux)],
        "$owner lists only unshipped response-demux behavior as auto-ID lifecycle residue",
    );
    is(scalar(@{$lifecycle->{families}}), 1, "$owner publishes one lifecycle family");
    my $write = $lifecycle->{families}[0];
    is($write->{family}, 'write', "$owner reports the write family");
    is($write->{request_id_signal}, 'axi0_awid', "$owner reports the write request ID signal");
    is($write->{request_id_direction}, 'generated_output', "$owner reports generated request ID direction");
    is($write->{response_id_signal}, 'axi0_bid', "$owner reports the write response ID signal");
    is($write->{response_id_direction}, 'generated_input', "$owner reports generated response ID direction");
    is_deeply($write->{pool}, [0, 1], "$owner reports the write pool in author order");
    is($write->{allocator}, 'first_free_pool_order', "$owner reports the allocator contract");
    is($write->{transaction_lifetime}, 'single_active', "$owner reports the transaction lifetime contract");
    is($write->{release}, 'transaction_completion_event', "$owner reports the release contract");
    is($write->{no_id_available}, 'runtime_assertion', "$owner reports the no-ID behavior");
    is_deeply($write->{auto_transactions}, [qw(w0 w1)], "$owner reports auto-ID transactions in source order");
    is_deeply(
        [map { $_->{selected_id_signal} } @{$write->{transaction_state}}],
        [qw(axi0_w0_auto_id_q axi0_w1_auto_id_q)],
        "$owner reports generated selected-ID state",
    );
    is_deeply(
        $write->{transaction_state}[0]{allocation_rules},
        [qw(axi0_w0_auto_id_alloc_0 axi0_w0_auto_id_alloc_1)],
        "$owner reports generated allocation rules",
    );
    is($write->{transaction_state}[0]{release_rule}, 'axi0_w0_auto_id_release', "$owner reports generated release rule");
}

sub assert_write_response_demux_report {
    my ($demux, $owner) = @_;
    is($demux->{mode}, 'bounded_write_bid_demux_contract', "$owner marks bounded write BID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks generated behavior true");
    is($demux->{write}{response_event}, 'axi0_write_complete', "$owner reports the write response event");
    is($demux->{write}{response_id_signal}, 'axi0_bid', "$owner reports the write response ID signal");
    is($demux->{write}{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($demux->{write}{transaction_completion_source}, 'generated_demux', "$owner reports generated transaction-completion ownership");
    is_deeply($demux->{write}{auto_transactions}, [qw(w0 w1)], "$owner reports write auto-ID transactions in source order");
    is_deeply($demux->{write}{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], "$owner reports generated demux rules");
    is_deeply($demux->{write}{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], "$owner reports generated completion pulse signals");
    is_deeply(
        $demux->{write}{generated_assertions},
        [qw(axi0_write_response_demux_active_match axi0_w0_w1_write_response_demux_unique_match)],
        "$owner reports generated response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux read_data_interleaving bursts)],
        "$owner removes generated write BID demux and covered same-ID avoidance from response-demux residue",
    );
}

sub assert_read_response_demux_report {
    my ($demux, $owner) = @_;
    is($demux->{mode}, 'bounded_response_demux_contract', "$owner marks bounded response-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks top-level generated behavior true for read demux");
    is($demux->{read}{mode}, 'bounded_read_rid_demux_contract', "$owner marks bounded read RID-demux contract mode");
    ok($demux->{read}{generated_behavior}, "$owner marks read generated behavior true");
    is($demux->{read}{response_event}, 'axi0_read_complete', "$owner reports the raw read response event");
    is($demux->{read}{response_event_role}, 'raw_accepted_read_response', "$owner reports the read response-event role");
    is($demux->{read}{response_scope}, 'single_beat', "$owner reports single-beat read response scope");
    is($demux->{read}{response_id_signal}, 'axi0_rid', "$owner reports the read response ID signal");
    is($demux->{read}{response_id_direction}, 'generated_input', "$owner reports read response ID direction as generated input");
    is($demux->{read}{transaction_completion_source}, 'generated_demux', "$owner reports generated read transaction-completion ownership");
    is_deeply($demux->{read}{auto_transactions}, [qw(r0 r1)], "$owner reports read auto-ID transactions in source order");
    is_deeply($demux->{read}{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated read demux rules");
    is_deeply($demux->{read}{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated read completion pulse signals");
    is_deeply(
        $demux->{read}{generated_assertions},
        [qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)],
        "$owner reports generated read response-demux assertions",
    );
    is_deeply($demux->{residue}, [qw(read_data_interleaving bursts)], "$owner removes generated read RID demux behavior from residue");
}

sub assert_read_response_demux_burst_last_report {
    my ($demux, $owner, $multi_beat_by_rid_covered, $bounded_burst_output_covered) = @_;
    is($demux->{mode}, 'bounded_response_demux_contract', "$owner marks bounded response-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks top-level generated behavior true for burst-last behavior");
    my $read = $demux->{read};
    is($read->{mode}, 'bounded_read_rid_demux_contract', "$owner marks bounded read RID-demux contract mode");
    ok($read->{generated_behavior}, "$owner marks read generated behavior true");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response beat event");
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', "$owner reports the beat-level response-event role");
    is($read->{response_scope}, 'burst_last', "$owner reports burst-last read response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports the read response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports read response ID direction as generated input");
    is($read->{last_signal}, 'axi0_rlast', "$owner reports the RLAST signal");
    is($read->{last_signal_direction}, 'generated_input', "$owner reports RLAST direction as generated input");
    is($read->{last_signal_width}, 1, "$owner reports one-bit RLAST width");
    is($read->{transaction_completion_source}, 'generated_demux_last_beat', "$owner reports generated last-beat completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_rid_and_last_signal', "$owner reports last-beat completion semantics");
    is($read->{beat_valid_output}, 'none', "$owner reports no separate beat-valid output");
    is($read->{burst_length_source}, 'rlast_only', "$owner reports RLAST-only burst length source");
    is($read->{burst_length_validation}, 'not_generated', "$owner reports deferred burst length validation");
    is_deeply($read->{auto_transactions}, [qw(r0 r1)], "$owner reports read auto-ID transactions in source order");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports selected transaction completion names");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated burst-last read demux rules");
    is_deeply(
        $read->{generated_assertions},
        [qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)],
        "$owner reports generated burst-last read demux assertions",
    );
    my @residue;
    push @residue, 'read_data_interleaving' unless $multi_beat_by_rid_covered;
    push @residue, 'bursts' unless $bounded_burst_output_covered;
    is_deeply($demux->{residue}, \@residue, "$owner reports remaining read response-demux residue");
}

sub assert_rlast_report_prose_alignment {
    my ($report, $owner) = @_;
    my @rules = @{$report->{enforced_static_rules} || []};
    my $stale_rule = join('', 'remains report-only until generated ', 'RLAST completion behavior');
    ok(
        (grep { /response_scope burst_last requires one-bit last_signal metadata and generates matched-RID-and-RLAST last-beat completion behavior/ } @rules),
        "$owner reports generated RLAST completion in static-rule prose",
    );
    ok(
        !(grep { index($_, $stale_rule) >= 0 } @rules),
        "$owner removes stale report-only RLAST static-rule prose",
    );

    my ($id_residue) = grep {
        ref($_) eq 'HASH'
            && ($_->{id} // '') eq 'axi_id_ordering_and_response_matching'
    } @{$report->{unsupported_residue} || []};
    ok($id_residue, "$owner reports AXI ID/order unsupported residue");
    like(
        $id_residue->{detail},
        qr/generated burst-last RLAST response-demux completion, structural last-beat read-data metadata, generated last-beat read-data RDATA\/RRESP capture, generated last-beat read-data RDATA\/RRESP capture from generated read burst-last concrete same-ID queue-head response-demux including multiple independent depth-2 queue-head groups with no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion beat-count\/RLAST validation metadata, plus the selected single depth-3 queue-head group with no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion beat-count\/RLAST validation metadata, plus selected multiple\/mixed depth-3 queue-head groups with no burst_length metadata, report-only raw-ARLEN burst-length metadata, runtime-assertion beat-count\/RLAST validation metadata, or runtime-assertion multi-beat output-bank metadata, generated raw-ARLEN burst-length capture including report-only and runtime-validation generated read burst-last concrete same-ID queue-head read-data contracts with one or more independent depth-2 queue-head groups, the selected single depth-3 report-only and runtime-validation groups, selected multiple\/mixed depth-3 report-only and runtime-validation groups, and the selected same-family mixed auto-ID plus depth-2 concrete queue-head report-only and runtime-validation groups, explicit runtime-assertion beat-count\/RLAST validation for auto-ID, selected dynamic read-data, and bounded read burst-last concrete same-ID queue-head read-data contracts including one or more independent depth-2 queue-head groups plus the selected single depth-3 group, selected multiple\/mixed depth-3 groups, and the selected same-family mixed auto-ID plus depth-2 concrete queue-head group, generated multi-beat read-data output-bank behavior for the covered auto-ID multi-beat-by-RID subset, selected dynamic single-active and bounded multiple all-dynamic read demux subset, and bounded read burst-last concrete same-ID queue-head subset including multiple independent depth-2 queue-head groups plus the selected single depth-3 runtime-validation queue-head group, selected multiple\/mixed depth-3 runtime-validation queue-head groups, and the selected same-family mixed auto-ID plus depth-2 concrete queue-head runtime-validation group, bounded burst payload\/output behavior through that per-beat output bank, and generated scalar RRESP aggregation behavior are supported/,
        "$owner reports generated burst-last, last-beat, queue-head last-beat including multi-group scalar runtime validation, queue-head report-only/raw runtime ARLEN, non-queue-head and queue-head beat-count, multi-beat output-bank, bounded burst output, and scalar aggregation behavior as supported",
    );
    like(
        $id_residue->{detail},
        qr/multiple independent or mixed-depth read single-beat, read burst-last, and write response-demux queue groups/,
        "$owner reports bounded multiple and mixed-depth queue-head response-demux groups as supported",
    );
    like(
        $id_residue->{detail},
        qr/selected single-group and multiple\/mixed read single-beat depth-3 scalar read-data queue-head shapes/,
        "$owner reports selected read single-beat depth-3 queue-head read-data shapes as supported",
    );
    like(
        $id_residue->{detail},
        qr/selected single-group and multiple\/mixed read burst-last depth-3 scalar last-beat read-data, report-only raw-ARLEN burst-length, runtime beat-count\/RLAST validation, and runtime-validation multi-beat output-bank queue-head shapes/,
        "$owner reports selected read burst-last depth-3 queue-head response-demux and read-data as supported",
    );
    like(
        $id_residue->{detail},
        qr/generated single-beat read-data RDATA\/RRESP capture from generated read single-beat concrete same-ID queue-head response-demux including multiple independent depth-2 queue-head groups, the selected single depth-3 queue-head group, and selected multiple\/mixed depth-3 queue-head groups/,
        "$owner reports selected single and multiple/mixed depth-3 queue-head read-data capture as supported",
    );
    like(
        $id_residue->{detail},
        qr/generated last-beat read-data RDATA\/RRESP capture from generated read burst-last concrete same-ID queue-head response-demux including multiple independent depth-2 queue-head groups with no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion beat-count\/RLAST validation metadata, plus the selected single depth-3 queue-head group with no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion beat-count\/RLAST validation metadata, plus selected multiple\/mixed depth-3 queue-head groups with no burst_length metadata, report-only raw-ARLEN burst-length metadata, runtime-assertion beat-count\/RLAST validation metadata, or runtime-assertion multi-beat output-bank metadata/,
        "$owner reports selected depth-3 burst-last queue-head read-data capture as supported",
    );
    my $stale_metadata = join('', 'report-only burst-last ', 'RLAST response-demux metadata');
    my $stale_tracking = join('', 'generated burst/last-beat tracking ', 'remain outside');
    my $stale_queue_head_read_data = 'read-data consumption of burst-last or multi-beat concrete same-ID queue-head demux';
    my $stale_queue_head_burst_length = 'burst-length metadata with queue-head read-data';
    my $stale_multi_group = 'deeper/multiple-group concrete same-ID issue-order queues';
    my $stale_multi_group_burst_length_boundary = join('', 'report-only or runtime-validation last-beat read-data ', 'over multiple queue groups');
    my $stale_runtime_multi_group_scalar = join('', 'runtime-validation last-beat read-data ', 'over multiple queue groups');
    ok(index($id_residue->{detail}, $stale_metadata) < 0, "$owner removes stale report-only residue prose");
    ok(index($id_residue->{detail}, $stale_tracking) < 0, "$owner removes stale burst tracking residue prose");
    ok(index($id_residue->{detail}, $stale_queue_head_read_data) < 0, "$owner removes stale burst-last queue-head read-data residue prose");
    ok(index($id_residue->{detail}, $stale_queue_head_burst_length) < 0, "$owner removes stale queue-head burst-length residue prose");
    ok(index($id_residue->{detail}, $stale_multi_group) < 0, "$owner removes stale broad multiple-group residue prose");
    ok(index($id_residue->{detail}, $stale_multi_group_burst_length_boundary) < 0, "$owner removes stale report-only multi-group raw ARLEN residue prose");
    ok(index($id_residue->{detail}, $stale_runtime_multi_group_scalar) < 0, "$owner removes stale runtime-validation multi-group scalar last-beat residue prose");
    ok(index($id_residue->{detail}, 'last-beat-only read-data over multiple queue groups') < 0, "$owner removes stale scalar multi-group last-beat residue prose");
    ok(index($id_residue->{detail}, 'queue-head runtime burst-length beat-count/RLAST validation') < 0, "$owner removes stale queue-head runtime validation residue prose");
    ok(index($id_residue->{detail}, 'burst-length/runtime validation over same-family mixed auto-ID plus concrete queue-head response-demux') < 0, "$owner removes stale mixed report-only burst-length residue prose");
    ok(index($id_residue->{detail}, 'read-data over multiple read single-beat queue-head groups') < 0, "$owner removes stale single-beat multi-group read-data residue prose");
    ok(index($id_residue->{detail}, 'read burst-last read-data consumption over multiple or mixed depth-3 queue-head groups,') < 0, "$owner removes stale multiple/mixed depth-3 burst-last read-data residue prose");
    ok(index($id_residue->{detail}, 'read burst-last read-data consumption over multiple or mixed depth-3 queue-head groups with burst_length metadata') < 0, "$owner removes stale multiple/mixed depth-3 report-only burst-length residue prose");
    ok(index($id_residue->{detail}, 'read burst-last read-data consumption over multiple or mixed depth-3 queue-head groups with runtime validation or multi-beat payload') < 0, "$owner removes stale multiple/mixed depth-3 runtime-validation residue prose");
    ok(index($id_residue->{detail}, 'read burst-last multi-beat payload over multiple or mixed depth-3 queue-head groups') < 0, "$owner removes stale multi-beat multiple/mixed depth-3 burst-last read-data residue prose");
}

sub assert_read_data_report {
    my ($read_data, $owner, $expected_completion_validity, %args) = @_;
    $expected_completion_validity //= 'generated_read_response_demux_completion_pulse';
    my @transactions = @{$args{transactions} // [qw(r0 r1)]};
    my @completion_signals = map { "axi0_${_}_complete" } @transactions;
    my @data_outputs = map { "axi0_${_}_rdata" } @transactions;
    my @status_outputs = map { "axi0_${_}_rresp" } @transactions;
    my @generated_outputs = map { ("axi0_${_}_rdata", "axi0_${_}_rresp") } @transactions;
    my @generated_rules = map { "axi0_${_}_read_data_capture" } @transactions;

    is($read_data->{mode}, 'bounded_single_beat_read_data_contract', "$owner marks bounded single-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner marks generated behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'single_beat', "$owner reports single-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, $expected_completion_validity, "$owner reports generated demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal");
    is($read->{data_signal_width}, 32, "$owner reports RDATA width");
    is($read->{data_signal_direction}, 'generated_input', "$owner reports RDATA generated-input direction");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP status signal");
    is($read->{status_signal_width}, 2, "$owner reports RRESP status width");
    is($read->{status_signal_direction}, 'generated_input', "$owner reports RRESP generated-input direction");
    is($read->{interleaving_policy}, 'single_beat_by_rid', "$owner reports single-beat-by-RID interleaving policy");
    is_deeply(
        [map { $_->{transaction} } @{$read->{transactions}}],
        \@transactions,
        "$owner reports read-data transaction bindings in source order",
    );
    is_deeply(
        [map { $_->{completion_signal} } @{$read->{transactions}}],
        \@completion_signals,
        "$owner binds read-data validity to generated demux completion pulses",
    );
    is_deeply(
        [map { $_->{data_output} } @{$read->{transactions}}],
        \@data_outputs,
        "$owner reports transaction data outputs",
    );
    is_deeply(
        [map { $_->{status_output} } @{$read->{transactions}}],
        \@status_outputs,
        "$owner reports transaction status outputs",
    );
    is_deeply(
        [map { $_->{data_width} } @{$read->{transactions}}],
        [(32) x @transactions],
        "$owner reports inherited transaction data widths",
    );
    is_deeply(
        [map { $_->{status_width} } @{$read->{transactions}}],
        [(2) x @transactions],
        "$owner reports inherited transaction status widths",
    );
    is_deeply(
        $read->{generated_inputs},
        [qw(axi0_rdata axi0_rresp)],
        "$owner reports generated read-data source inputs",
    );
    is_deeply(
        $read->{generated_outputs},
        \@generated_outputs,
        "$owner reports generated read-data capture outputs",
    );
    is_deeply(
        $read->{generated_rules},
        \@generated_rules,
        "$owner reports generated read-data capture rules",
    );
    is_deeply(
        $read_data->{residue},
        [qw(rlast_completion bursts multi_beat_read_data_reassembly)],
        "$owner reports only RLAST, burst, and reassembly residue",
    );
}

sub assert_read_data_last_beat_report {
    my ($read_data, $owner, $expected_completion_validity, %args) = @_;
    $expected_completion_validity //= 'generated_read_response_demux_last_beat_completion_pulse';
    my @transactions = @{$args{transactions} // [qw(r0 r1)]};
    my @completion_signals = map { "axi0_${_}_complete" } @transactions;
    my @data_outputs = map { "axi0_${_}_last_rdata" } @transactions;
    my @status_outputs = map { "axi0_${_}_last_rresp" } @transactions;
    my @generated_outputs = map { ("axi0_${_}_last_rdata", "axi0_${_}_last_rresp") } @transactions;
    my @generated_rules = map { "axi0_${_}_read_data_capture" } @transactions;

    is($read_data->{mode}, 'bounded_last_beat_read_data_contract', "$owner marks bounded last-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner marks generated behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'last_beat', "$owner reports last-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, $expected_completion_validity, "$owner reports generated last-beat demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal");
    is($read->{data_signal_width}, 32, "$owner reports RDATA width");
    is($read->{data_signal_direction}, 'generated_input', "$owner reports RDATA generated-input direction");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP signal");
    is($read->{status_signal_width}, 2, "$owner reports RRESP width");
    is($read->{status_signal_direction}, 'generated_input', "$owner reports RRESP generated-input direction");
    is($read->{status_policy}, 'last_beat', "$owner reports last-beat status policy");
    is($read->{status_aggregation}, 'none', "$owner reports no RRESP aggregation");
    is($read->{interleaving_policy}, 'last_beat_by_rid', "$owner reports last-beat-by-RID interleaving policy");
    is($read->{burst_length_source}, 'rlast_only', "$owner reports RLAST-only burst length source");
    is($read->{burst_length_validation}, 'not_generated', "$owner reports deferred burst length validation");
    is($read->{beat_storage}, 'none', "$owner reports no beat storage");
    is($read->{valid_output}, 'none', "$owner reports no valid output");
    is($read->{length_output}, 'none', "$owner reports no length output");
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], \@transactions, "$owner reports last-beat transaction bindings");
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], \@completion_signals, "$owner binds validity to generated last-beat completion pulses");
    is_deeply([map { $_->{data_output} } @{$read->{transactions}}], \@data_outputs, "$owner reports last-beat data outputs");
    is_deeply([map { $_->{status_output} } @{$read->{transactions}}], \@status_outputs, "$owner reports last-beat status outputs");
    is_deeply([map { $_->{data_width} } @{$read->{transactions}}], [(32) x scalar(@transactions)], "$owner reports inherited last-beat data widths");
    is_deeply([map { $_->{status_width} } @{$read->{transactions}}], [(2) x scalar(@transactions)], "$owner reports inherited last-beat status widths");
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp)], "$owner reports generated RDATA/RRESP inputs");
    is_deeply(
        $read->{generated_outputs},
        \@generated_outputs,
        "$owner reports generated last-beat data/status outputs",
    );
    is_deeply(
        $read->{generated_rules},
        \@generated_rules,
        "$owner reports generated last-beat capture rules",
    );
    is_deeply(
        $read_data->{residue},
        [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)],
        "$owner reports last-beat read-data residue",
    );
}

sub assert_read_data_burst_length_report {
    my ($read_data, $owner, $validation, $expected_completion_validity, %args) = @_;
    $validation //= 'report_only';
    $expected_completion_validity //= 'generated_read_response_demux_last_beat_completion_pulse';
    my $runtime_validation = $validation eq 'runtime_assertion';
    my @transactions = @{$args{transactions} // [qw(r0 r1)]};
    my @completion_signals = map { "axi0_${_}_complete" } @transactions;
    my @data_outputs = map { "axi0_${_}_last_rdata" } @transactions;
    my @status_outputs = map { "axi0_${_}_last_rresp" } @transactions;
    my @generated_outputs = map { ("axi0_${_}_last_rdata", "axi0_${_}_last_rresp") } @transactions;
    my @read_data_rules = map { "axi0_${_}_read_data_capture" } @transactions;
    my @burst_length_storage = map { "axi0_${_}_arlen_q" } @transactions;
    my @burst_length_rules = map { "axi0_${_}_burst_length_capture" } @transactions;
    my @expected_beat_count_storage = map { "axi0_${_}_expected_beats_q" } @transactions;
    my @beat_count_storage = map { "axi0_${_}_read_beat_count_q" } @transactions;
    my @beat_count_init_rules = map { "axi0_${_}_beat_count_init" } @transactions;
    my @beat_count_increment_rules = map { "axi0_${_}_read_beat_count" } @transactions;
    my @beat_count_rules = map { ("axi0_${_}_beat_count_init", "axi0_${_}_read_beat_count") } @transactions;
    my @beat_count_assertions = map {
        (
            "axi0_${_}_arlen_within_max",
            "axi0_${_}_read_beat_before_expected_count",
            "axi0_${_}_rlast_on_expected_beat",
            "axi0_${_}_expected_final_beat_has_rlast",
        )
    } @transactions;

    is($read_data->{mode}, 'bounded_last_beat_read_data_contract', "$owner marks bounded last-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner keeps generated last-beat read-data behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'last_beat', "$owner reports last-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, $expected_completion_validity, "$owner reports generated last-beat demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal");
    is($read->{data_signal_width}, 32, "$owner reports RDATA width");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP signal");
    is($read->{status_signal_width}, 2, "$owner reports RRESP width");
    is($read->{status_policy}, 'last_beat', "$owner reports last-beat status policy");
    is($read->{status_aggregation}, 'none', "$owner reports no RRESP aggregation");
    is($read->{interleaving_policy}, 'last_beat_by_rid', "$owner reports last-beat-by-RID interleaving policy");
    is($read->{burst_length_source}, 'arlen_signal', "$owner reports ARLEN as the burst-length source");
    is($read->{burst_length_signal}, 'axi0_arlen', "$owner reports the ARLEN signal");
    is($read->{burst_length_signal_direction}, 'generated_input', "$owner reports generated input direction");
    is($read->{burst_length_signal_width}, 8, "$owner reports ARLEN width");
    is($read->{burst_length_encoding}, 'axlen_plus_one', "$owner reports AXI LEN+1 encoding");
    is($read->{burst_length_capture}, 'transaction_request', "$owner reports request-bound length capture");
    is($read->{max_beats}, 16, "$owner reports max-beats");
    ok($read->{burst_length_generated_behavior}, "$owner reports burst-length generation as true");
    is($read->{burst_length_validation}, $validation, "$owner reports burst-length validation mode");
    is($read->{beat_storage}, 'none', "$owner reports no beat storage");
    is($read->{valid_output}, 'none', "$owner reports no valid output");
    is($read->{length_output}, 'none', "$owner reports no length output");
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], \@transactions, "$owner reports last-beat transaction bindings");
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], \@completion_signals, "$owner binds validity to generated last-beat completion pulses");
    is_deeply([map { $_->{data_output} } @{$read->{transactions}}], \@data_outputs, "$owner reports last-beat data outputs");
    is_deeply([map { $_->{status_output} } @{$read->{transactions}}], \@status_outputs, "$owner reports last-beat status outputs");
    is_deeply([map { $_->{burst_length_storage} } @{$read->{transactions}}], \@burst_length_storage, "$owner reports per-transaction raw ARLEN storage");
    is_deeply([map { $_->{burst_length_capture_rule} } @{$read->{transactions}}], \@burst_length_rules, "$owner reports per-transaction burst-length capture rules");
    if ($runtime_validation) {
        ok($read->{beat_count_validation_generated_behavior}, "$owner reports generated beat-count validation behavior");
        is($read->{expected_beat_count_encoding}, 'arlen_plus_one', "$owner reports expected beat-count encoding");
        is($read->{beat_count_match_source}, 'response_demux_matched_read_beat', "$owner reports matched read-beat source");
        is($read->{beat_count_width}, 5, "$owner reports beat-count storage width");
        is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], \@expected_beat_count_storage, "$owner reports per-transaction expected-beat storage");
        is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], \@beat_count_storage, "$owner reports per-transaction beat-count storage");
        is_deeply([map { $_->{beat_count_init_rule} } @{$read->{transactions}}], \@beat_count_init_rules, "$owner reports beat-count init rules");
        is_deeply([map { $_->{beat_count_increment_rule} } @{$read->{transactions}}], \@beat_count_increment_rules, "$owner reports beat-count increment rules");
        is_deeply(
            $read->{transactions}[0]{beat_count_assertions},
            [
                "axi0_$transactions[0]_arlen_within_max",
                "axi0_$transactions[0]_read_beat_before_expected_count",
                "axi0_$transactions[0]_rlast_on_expected_beat",
                "axi0_$transactions[0]_expected_final_beat_has_rlast",
            ],
            "$owner reports first transaction beat-count assertions",
        );
    } else {
        ok(!exists $read->{beat_count_validation_generated_behavior}, "$owner keeps report-only validation free of beat-count behavior flag");
        ok(!exists $read->{generated_beat_count_storage}, "$owner keeps report-only validation free of generated beat-count storage");
    }
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp axi0_arlen)], "$owner adds ARLEN to generated read-data inputs");
    is_deeply($read->{generated_burst_length_inputs}, [qw(axi0_arlen)], "$owner reports generated burst-length input");
    is_deeply($read->{generated_burst_length_storage}, \@burst_length_storage, "$owner reports generated burst-length storage");
    is_deeply($read->{generated_burst_length_rules}, \@burst_length_rules, "$owner reports generated burst-length capture rules");
    if ($runtime_validation) {
        is_deeply($read->{generated_expected_beat_count_storage}, \@expected_beat_count_storage, "$owner reports generated expected-beat storage");
        is_deeply($read->{generated_beat_count_storage}, \@beat_count_storage, "$owner reports generated beat-count storage");
        is_deeply($read->{generated_beat_count_rules}, \@beat_count_rules, "$owner reports generated beat-count rules");
        is_deeply(
            $read->{generated_beat_count_assertions},
            \@beat_count_assertions,
            "$owner reports generated beat-count assertions",
        );
    }
    is_deeply(
        $read->{generated_outputs},
        \@generated_outputs,
        "$owner keeps generated last-beat outputs stable",
    );
    my @expected_rules = (@read_data_rules, @burst_length_rules);
    push @expected_rules, @beat_count_rules
        if $runtime_validation;
    is_deeply(
        $read->{generated_rules},
        \@expected_rules,
        "$owner reports generated last-beat and burst-length capture rules",
    );
    my @expected_residue = $runtime_validation
        ? qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation)
        : qw(generated_beat_count_validation multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation);
    is_deeply(
        $read_data->{residue},
        \@expected_residue,
        "$owner reports explicit burst-length residue",
    );
}

sub assert_read_data_multi_beat_report {
    my ($read_data, $owner, %args) = @_;
    my $completion_validity = $args{completion_validity} // 'generated_read_response_demux_last_beat_completion_pulse';

    is($read_data->{mode}, 'bounded_multi_beat_read_data_contract', "$owner marks bounded multi-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner keeps generated validation behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'multi_beat', "$owner reports multi-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, $completion_validity, "$owner reports generated last-beat demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal metadata");
    is($read->{data_signal_width}, 32, "$owner reports RDATA width metadata");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP signal metadata");
    is($read->{status_signal_width}, 2, "$owner reports RRESP width metadata");
    is($read->{status_policy}, 'per_beat', "$owner reports per-beat status policy");
    is($read->{status_aggregation}, 'worst_observed', "$owner reports selected scalar RRESP aggregation policy");
    ok($read->{status_aggregation_generated_behavior}, "$owner reports generated scalar RRESP aggregation behavior");
    is($read->{status_aggregate_output}, 'per_transaction_scalar', "$owner reports per-transaction scalar RRESP aggregate shape");
    is($read->{status_aggregate_output_width}, 2, "$owner reports scalar RRESP aggregate width");
    is($read->{interleaving_policy}, 'multi_beat_by_rid', "$owner reports multi-beat-by-RID interleaving");
    is($read->{burst_length_source}, 'arlen_signal', "$owner reports ARLEN as the burst-length source");
    is($read->{burst_length_signal}, 'axi0_arlen', "$owner reports the ARLEN signal");
    is($read->{burst_length_signal_direction}, 'generated_input', "$owner reports ARLEN input direction");
    is($read->{burst_length_signal_width}, 8, "$owner reports ARLEN width");
    is($read->{burst_length_encoding}, 'axlen_plus_one', "$owner reports AXI LEN+1 encoding");
    is($read->{burst_length_capture}, 'transaction_request', "$owner reports request-bound length capture");
    is($read->{max_beats}, 16, "$owner reports max-beats");
    ok($read->{burst_length_generated_behavior}, "$owner reports raw-ARLEN capture generation");
    is($read->{burst_length_validation}, 'runtime_assertion', "$owner reports runtime validation");
    ok($read->{beat_count_validation_generated_behavior}, "$owner reports generated beat-count validation behavior");
    is($read->{expected_beat_count_encoding}, 'arlen_plus_one', "$owner reports expected beat-count encoding");
    is($read->{beat_count_match_source}, 'response_demux_matched_read_beat', "$owner reports beat-count match source");
    is($read->{beat_match_source}, 'response_demux_matched_read_beat', "$owner reports reassembly beat-match source");
    is($read->{beat_count_width}, 5, "$owner reports beat-count width");
    is($read->{beat_storage}, 'per_transaction_generated', "$owner reports selected beat-storage shape");
    is($read->{output_shape}, 'per_beat_output_bank', "$owner reports per-beat output-bank shape");
    is($read->{valid_output}, 'per_transaction_valid_mask', "$owner reports valid-mask output shape");
    is($read->{length_output}, 'per_transaction_beat_count', "$owner reports length-output shape");
    ok($read->{multi_beat_reassembly_generated_behavior}, "$owner reports generated multi-beat reassembly/output behavior");

    my @transactions = @{$args{transactions} || [qw(r0 r1)]};
    my (%data_outputs, %status_outputs, %capture_rules);
    for my $transaction (@transactions) {
        $data_outputs{$transaction} = [map { "axi0_${transaction}_beat_rdata_$_" } 0 .. 15];
        $status_outputs{$transaction} = [map { "axi0_${transaction}_beat_rresp_$_" } 0 .. 15];
        $capture_rules{$transaction} = [map { "axi0_${transaction}_read_beat_${_}_capture" } 0 .. 15];
    }

    my @multi_beat_outputs = map {
        my $transaction = $_;
        (
            @{$data_outputs{$transaction}},
            @{$status_outputs{$transaction}},
            "axi0_${transaction}_rresp",
            "axi0_${transaction}_beat_valid",
            "axi0_${transaction}_read_beats",
        );
    } @transactions;
    my @multi_beat_data_outputs = map { @{$data_outputs{$_}} } @transactions;
    my @multi_beat_status_outputs = map { @{$status_outputs{$_}} } @transactions;
    my @multi_beat_capture_rules = map { @{$capture_rules{$_}} } @transactions;
    my @status_aggregate_outputs = map { "axi0_${_}_rresp" } @transactions;
    my @status_aggregate_init_rules = map { "axi0_${_}_read_data_output_init" } @transactions;
    my @status_aggregate_update_rules = map { "axi0_${_}_rresp_aggregate" } @transactions;
    my @burst_length_storage = map { "axi0_${_}_arlen_q" } @transactions;
    my @burst_length_rules = map { "axi0_${_}_burst_length_capture" } @transactions;
    my @expected_beat_count_storage = map { "axi0_${_}_expected_beats_q" } @transactions;
    my @beat_count_storage = map { "axi0_${_}_read_beat_count_q" } @transactions;
    my @beat_count_rules = map { ("axi0_${_}_beat_count_init", "axi0_${_}_read_beat_count") } @transactions;
    my @generated_rules = (
        @burst_length_rules,
        @beat_count_rules,
        @status_aggregate_init_rules,
        map {
            my $transaction = $_;
            (@{$capture_rules{$transaction}}, "axi0_${transaction}_rresp_aggregate");
        } @transactions,
    );

    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], \@transactions, "$owner reports multi-beat transaction bindings");
    is_deeply([map { $_->{data_output_prefix} } @{$read->{transactions}}], [map { "axi0_${_}_beat_rdata" } @transactions], "$owner reports data output prefixes");
    is_deeply([map { $_->{status_output_prefix} } @{$read->{transactions}}], [map { "axi0_${_}_beat_rresp" } @transactions], "$owner reports status output prefixes");
    is_deeply([map { $_->{status_aggregate_output} } @{$read->{transactions}}], \@status_aggregate_outputs, "$owner reports scalar RRESP aggregate outputs");
    is_deeply([map { $_->{status_aggregate_output_width} } @{$read->{transactions}}], [(2) x scalar(@transactions)], "$owner reports scalar RRESP aggregate output widths");
    is_deeply($read->{transactions}[0]{generated_data_outputs}, $data_outputs{$transactions[0]}, "$owner reports first transaction generated data lane names");
    is_deeply($read->{transactions}[0]{generated_status_outputs}, $status_outputs{$transactions[0]}, "$owner reports first transaction generated status lane names");
    is_deeply([map { $_->{valid_mask_output} } @{$read->{transactions}}], [map { "axi0_${_}_beat_valid" } @transactions], "$owner reports valid-mask outputs");
    is_deeply([map { $_->{valid_mask_width} } @{$read->{transactions}}], [(16) x scalar(@transactions)], "$owner reports valid-mask widths");
    is_deeply([map { $_->{length_output} } @{$read->{transactions}}], [map { "axi0_${_}_read_beats" } @transactions], "$owner reports length outputs");
    is_deeply([map { $_->{length_output_width} } @{$read->{transactions}}], [(5) x scalar(@transactions)], "$owner reports length-output widths");
    is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], \@expected_beat_count_storage, "$owner reports expected-beat storage");
    is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], \@beat_count_storage, "$owner reports beat-count storage");
    is_deeply([map { $_->{multi_beat_output_init_rule} } @{$read->{transactions}}], \@status_aggregate_init_rules, "$owner reports multi-beat output init rules");
    is_deeply($read->{transactions}[0]{multi_beat_capture_rules}, $capture_rules{$transactions[0]}, "$owner reports first transaction multi-beat capture rules");
    is_deeply([map { $_->{status_aggregate_init_rule} } @{$read->{transactions}}], \@status_aggregate_init_rules, "$owner reports scalar aggregate init rule ownership");
    is_deeply([map { $_->{status_aggregate_update_rule} } @{$read->{transactions}}], \@status_aggregate_update_rules, "$owner reports scalar aggregate update rules");
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp axi0_arlen)], "$owner reports generated payload and ARLEN inputs");
    is_deeply($read->{generated_outputs}, \@multi_beat_outputs, "$owner reports generated output-bank and scalar aggregate outputs");
    is_deeply($read->{generated_status_aggregate_outputs}, \@status_aggregate_outputs, "$owner reports generated scalar aggregate outputs");
    is_deeply($read->{generated_multi_beat_data_outputs}, \@multi_beat_data_outputs, "$owner reports generated multi-beat data outputs");
    is_deeply($read->{generated_multi_beat_status_outputs}, \@multi_beat_status_outputs, "$owner reports generated multi-beat status outputs");
    is_deeply($read->{generated_multi_beat_valid_outputs}, [map { "axi0_${_}_beat_valid" } @transactions], "$owner reports generated multi-beat valid-mask outputs");
    is_deeply($read->{generated_multi_beat_length_outputs}, [map { "axi0_${_}_read_beats" } @transactions], "$owner reports generated multi-beat length outputs");
    is_deeply($read->{generated_burst_length_storage}, \@burst_length_storage, "$owner reports generated burst-length storage");
    is_deeply($read->{generated_beat_count_rules}, \@beat_count_rules, "$owner reports generated beat-count rules");
    is_deeply($read->{generated_multi_beat_output_init_rules}, \@status_aggregate_init_rules, "$owner reports generated multi-beat output init rules");
    is_deeply($read->{generated_multi_beat_capture_rules}, \@multi_beat_capture_rules, "$owner reports generated multi-beat capture rules");
    is_deeply($read->{generated_status_aggregate_init_rules}, \@status_aggregate_init_rules, "$owner reports generated scalar aggregate init rules");
    is_deeply($read->{generated_status_aggregate_update_rules}, \@status_aggregate_update_rules, "$owner reports generated scalar aggregate update rules");
    is_deeply(
        $read->{generated_rules},
        \@generated_rules,
        "$owner reports generated rules with output init, per-lane capture, and scalar aggregate update rules",
    );
    is_deeply($read_data->{residue}, [], "$owner removes generated scalar RRESP aggregation behavior from read-data residue");
}

sub assert_same_id_ordering_report {
    my ($ordering, $owner, $response_demux_covered, $family_name, $multi_beat_by_rid_covered, $bounded_burst_output_covered) = @_;
    $family_name //= 'write';
    is($ordering->{mode}, 'auto_id_same_id_avoidance', "$owner marks same-ID avoidance mode");
    ok($ordering->{generated_behavior}, "$owner marks same-ID ordering generated behavior true");
    is($ordering->{strategy}, 'avoid_same_id_concurrency', "$owner reports same-ID avoidance strategy");
    my @residue = qw(concrete_id_same_id_ordering per_id_issue_order_queues);
    push @residue, 'read_response_demux' unless $family_name eq 'read' && $response_demux_covered;
    push @residue, 'read_data_interleaving' unless $multi_beat_by_rid_covered;
    push @residue, 'bursts' unless $bounded_burst_output_covered;
    is_deeply(
        $ordering->{residue},
        \@residue,
        "$owner reports broader same-ID ordering residue",
    );
    ok(@{$ordering->{source_anchors}}, "$owner carries source anchors into same-ID ordering metadata");
    is(scalar(@{$ordering->{families}}), 1, "$owner reports one same-ID ordering family");
    assert_same_id_ordering_family($ordering->{families}[0], $owner, $family_name, $response_demux_covered);
}

sub assert_same_id_reject_policy_report {
    my ($ordering, $owner) = @_;

    assert_same_id_reuse_policy_report($ordering, $owner, {
        policy      => 'reject',
        enforcement => 'static_validation',
    });
}

sub assert_same_id_issue_order_queue_policy_report {
    my ($ordering, $owner) = @_;

    assert_same_id_reuse_policy_report($ordering, $owner, {
        policy                => 'issue_order_queue',
        enforcement           => 'admitted_request_boundary',
        implementation_status => 'admitted_request_pulses_generated',
        admitted_request_boundary => {
            pending_storage         => 'axi0_pending_reads_q',
            max_pending             => 4,
            completion_fanin        => 'axi0_r0_complete',
            selected_request_events => [qw(axi0_r0_request)],
            generated_pulses        => [
                {
                    transaction   => 'r0',
                    tag           => 'rd0',
                    concrete_id   => 3,
                    request_event => 'axi0_r0_request',
                    pulse         => 'axi0_r0_admitted_request_pulse_q',
                    rule          => 'axi0_r0_admitted_request',
                    guard         => '(& axi0_r0_request (| (< axi0_pending_reads_q 4) axi0_r0_complete))',
                },
            ],
            generated_assertions => [],
        },
    });
}

sub assert_boolean_capacity_accounting {
    my ($report, $owner, %args) = @_;
    my $direction = $args{direction};
    my $dispatch = transaction_dispatch_entry($report, $direction);
    my $accounting = $dispatch->{request_accounting};

    is($accounting->{mode}, 'boolean_fanin', "$owner reports boolean request fan-in accounting");
    is(
        $accounting->{capacity_owner},
        "generated_scheduler_or_status_rules.${direction}_capacity_matrix",
        "$owner reports the capacity matrix owner",
    );
    is($accounting->{completion_accounting_mode}, 'boolean_fanin', "$owner reports boolean completion fan-in accounting");

    my $matrix = capacity_matrix_entry($report, $direction);
    is($matrix->{accounting_mode}, 'boolean_submit', "$owner reports boolean capacity-matrix accounting");
    is($matrix->{completion_accounting_mode}, 'boolean_fanin', "$owner reports boolean capacity-matrix completion accounting");
    is($matrix->{rule_count}, $args{rule_count}, "$owner reports the boolean capacity-matrix rule count");
    ok(!exists($matrix->{counted_request_events}), "$owner omits counted request events");
    ok(!exists($matrix->{request_count_expression}), "$owner omits counted request expression");
}

sub assert_counted_same_id_capacity_accounting {
    my ($report, $owner, %args) = @_;
    my $direction = $args{direction};
    my $dispatch = transaction_dispatch_entry($report, $direction);
    my $accounting = $dispatch->{request_accounting};

    is($accounting->{mode}, 'counted_same_id_selected_requests', "$owner reports counted same-ID selected-request accounting");
    is_deeply($accounting->{counted_request_events}, $args{counted_request_events}, "$owner reports counted request events");
    is_deeply($accounting->{counted_request_terms}, $args{counted_request_terms}, "$owner reports counted request terms");
    is_deeply($accounting->{counted_request_groups}, $args{counted_request_groups}, "$owner reports counted request groups");
    is_deeply(
        $accounting->{selected_same_id_request_events},
        $args{counted_request_events},
        "$owner reports selected same-ID request events",
    );
    is($accounting->{request_count_expression}, $args{request_count_expression}, "$owner reports request count expression");
    my $max_pending = _max_pending_from_counted_rule_count($args{rule_count}, scalar(@{$args{counted_request_terms}}));
    my ($evaluation_expression, $evaluation_terms, $evaluation_width) = counted_request_evaluation_contract(
        max_pending => $max_pending,
        terms       => $args{counted_request_terms},
    );
    is_deeply($accounting->{request_count_evaluation_terms}, $evaluation_terms, "$owner reports exact-width request count evaluation terms");
    is($accounting->{request_count_evaluation_expression}, $evaluation_expression, "$owner reports exact-width request count evaluation expression");
    is($accounting->{request_count_evaluation_width}, $evaluation_width, "$owner reports request count evaluation width");
    is($accounting->{maximum_request_count}, scalar(@{$args{counted_request_terms}}), "$owner reports maximum request count");
    is(
        $accounting->{capacity_owner},
        "generated_scheduler_or_status_rules.${direction}_capacity_matrix",
        "$owner reports counted capacity owner",
    );
    is($accounting->{completion_accounting_mode}, 'boolean_fanin', "$owner keeps completion accounting boolean");
    is($accounting->{over_capacity_policy}, 'reject_current_request_set', "$owner reports over-capacity rejection policy");

    my $matrix = capacity_matrix_entry($report, $direction);
    is($matrix->{accounting_mode}, 'counted_submit', "$owner reports counted capacity-matrix accounting");
    is($matrix->{completion_accounting_mode}, 'boolean_fanin', "$owner reports counted matrix completion accounting");
    is($matrix->{rule_count}, $args{rule_count}, "$owner reports exact-count capacity-matrix rule count");
    is_deeply($matrix->{counted_request_events}, $args{counted_request_events}, "$owner mirrors counted request events into the matrix report");
    is_deeply($matrix->{counted_request_terms}, $args{counted_request_terms}, "$owner mirrors counted request terms into the matrix report");
    is_deeply($matrix->{counted_request_groups}, $args{counted_request_groups}, "$owner mirrors counted request groups into the matrix report");
    is_deeply(
        $matrix->{selected_same_id_request_events},
        $args{counted_request_events},
        "$owner mirrors selected same-ID request events into the matrix report",
    );
    is($matrix->{request_count_expression}, $args{request_count_expression}, "$owner mirrors request count expression into the matrix report");
    is_deeply($matrix->{request_count_evaluation_terms}, $evaluation_terms, "$owner mirrors exact-width request count evaluation terms into the matrix report");
    is($matrix->{request_count_evaluation_expression}, $evaluation_expression, "$owner mirrors exact-width request count evaluation expression into the matrix report");
    is($matrix->{request_count_evaluation_width}, $evaluation_width, "$owner mirrors request count evaluation width into the matrix report");
    is($matrix->{maximum_request_count}, scalar(@{$args{counted_request_terms}}), "$owner mirrors maximum request count into the matrix report");
    is($matrix->{over_capacity_policy}, 'reject_current_request_set', "$owner mirrors over-capacity policy into the matrix report");
}

sub assert_counted_admitted_request_boundary {
    my ($boundary, $owner, %args) = @_;

    is($boundary->{guard_source}, 'counted_request_set_capacity_fit', "$owner reports counted admitted guard source");
    is($boundary->{accounting_mode}, 'counted_capacity_storage_and_completion_fanin', "$owner reports counted admitted accounting mode");
    is($boundary->{request_assertion_scope}, 'concrete_id_group', "$owner reports group-local request assertion scope");
    is($boundary->{pending_storage}, $args{pending_storage}, "$owner reports admitted guard pending storage");
    is($boundary->{max_pending}, $args{max_pending}, "$owner reports admitted guard max-pending bound");
    is($boundary->{completion_fanin}, $args{completion_fanin}, "$owner reports admitted guard completion fan-in");
    is($boundary->{request_count_expression}, $args{request_count_expression}, "$owner reports admitted request-count expression");
    my ($evaluation_expression, $evaluation_terms, $evaluation_width) = counted_request_evaluation_contract(
        max_pending => $args{max_pending},
        terms       => $boundary->{counted_request_terms},
    );
    is_deeply($boundary->{request_count_evaluation_terms}, $evaluation_terms, "$owner reports exact-width admitted request-count evaluation terms");
    is($boundary->{request_count_evaluation_expression}, $evaluation_expression, "$owner reports exact-width admitted request-count evaluation expression");
    is($boundary->{request_count_evaluation_width}, $evaluation_width, "$owner reports admitted request-count evaluation width");
    is_deeply($boundary->{generated_assertions}, $args{generated_assertions}, "$owner reports group-local admitted request assertions");
    my $zero = sized_decimal_literal($evaluation_width, 0);
    like(
        $boundary->{request_set_fit_expression},
        qr/\Q(<= $evaluation_expression $zero)\E/,
        "$owner request-set fit expression can reject non-empty over-capacity request sets",
    );
    for my $pulse (@{$boundary->{generated_pulses} || []}) {
        is(
            $pulse->{guard},
            "(& $pulse->{request_event} $boundary->{request_set_fit_expression})",
            "$owner gates $pulse->{transaction} admitted pulse with the counted request-set fit expression",
        );
        unlike($pulse->{guard}, qr/can_accept/, "$owner admitted request guard does not consume can_accept");
    }
}

sub counted_request_evaluation_contract {
    my (%args) = @_;
    my $terms = $args{terms} || [];
    my $term_count = scalar(@$terms);
    my $width = _count_width($args{max_pending} > $term_count ? $args{max_pending} : $term_count);
    my @evaluation_terms = map { zero_extend_one_bit_expr($_, $width) } @$terms;
    my $expression = @evaluation_terms == 1
        ? $evaluation_terms[0]
        : '(+ ' . join(' ', @evaluation_terms) . ')';
    return ($expression, \@evaluation_terms, $width);
}

sub zero_extend_one_bit_expr {
    my ($expr, $width) = @_;
    return $expr unless defined($width) && $width > 1;
    return '(concat ' . ($width - 1) . "'b" . ('0' x ($width - 1)) . " $expr)";
}

sub sized_decimal_literal {
    my ($width, $value) = @_;
    return "${width}'d$value";
}

sub _count_width {
    my ($max_value) = @_;
    my $width = 1;
    my $limit = 2;
    while ($limit <= $max_value) {
        ++$width;
        $limit *= 2;
    }
    return $width;
}

sub _max_pending_from_counted_rule_count {
    my ($rule_count, $term_count) = @_;
    return int($rule_count / (2 * ($term_count + 1)) - 1);
}

sub transaction_dispatch_entry {
    my ($report, $direction) = @_;
    my %by_direction = map { $_->{direction} => $_ } @{$report->{transaction_event_dispatch}{directions} || []};
    return $by_direction{$direction};
}

sub capacity_matrix_entry {
    my ($report, $direction) = @_;
    my %by_direction = map { $_->{direction} => $_ } @{$report->{generated_scheduler_or_status_rules} || []};
    return $by_direction{$direction};
}

sub assert_same_id_queue_head_response_demux_report {
    my ($demux, $owner, %args) = @_;
    my $expected_residue = $args{residue} // [qw(read_data_interleaving bursts)];
    my $expected_queues = $args{queues} // [
        {
            concrete_id          => 3,
            transactions         => [qw(r0 r1)],
            depth                => 2,
            dequeue_event_source => 'queue_head_response_demux',
        },
    ];
    my $expected_completion_signals = $args{completion_signals} // [qw(axi0_r0_complete axi0_r1_complete)];
    my $expected_rules = $args{generated_rules} // [qw(axi0_r0_response_demux axi0_r1_response_demux)];
    my $expected_assertions = $args{generated_assertions} // [
        qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)
    ];

    is($demux->{mode}, 'bounded_response_demux_contract', "$owner marks bounded response-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks top-level generated behavior true");
    my $read = $demux->{read};
    is($read->{mode}, 'bounded_read_rid_queue_head_demux_contract', "$owner marks queue-head read demux mode");
    ok($read->{generated_behavior}, "$owner marks read generated behavior true");
    is($read->{implementation_status}, 'generated', "$owner reports generated status");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', "$owner reports beat-level response role");
    is($read->{response_scope}, 'burst_last', "$owner reports burst-last scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports RID direction");
    is($read->{last_signal}, 'axi0_rlast', "$owner reports RLAST signal");
    is($read->{last_signal_direction}, 'generated_input', "$owner reports RLAST direction");
    is($read->{last_signal_width}, 1, "$owner reports one-bit RLAST");
    is($read->{transaction_completion_source}, 'generated_queue_head_demux', "$owner reports queue-head transaction completion source");
    is($read->{transaction_completion_semantics}, 'matched_concrete_id_queue_head_and_last_signal', "$owner reports queue-head last-beat semantics");
    is($read->{queue_state_representation}, 'compact_onehot_transaction_slots', "$owner reports queue state representation");
    is_deeply(
        $read->{same_id_issue_order_queues},
        $expected_queues,
        "$owner reports duplicate concrete-ID queue group",
    );
    ok($read->{generated_queue_behavior}, "$owner reports generated queue behavior");
    is($read->{generated_queue_behavior_boundary}, 'generated_read_burst_last_queue_head_demux', "$owner reports generated queue boundary");
    ok(!exists($read->{selected_completion_signals}), "$owner no longer reports selected completion signal names");
    is_deeply($read->{generated_completion_signals}, $expected_completion_signals, "$owner reports generated completion signal names");
    is_deeply($read->{generated_rules}, $expected_rules, "$owner reports generated response-demux rules");
    is_deeply(
        $read->{generated_assertions},
        $expected_assertions,
        "$owner reports generated response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        $expected_residue,
        "$owner removes generated queue-head demux behavior from residue",
    );
}

sub assert_same_id_read_single_beat_queue_head_response_demux_report {
    my ($demux, $owner, %args) = @_;
    my $expected_queues = $args{queues} // [
        {
            concrete_id          => 3,
            transactions         => [qw(r0 r1)],
            depth                => 2,
            dequeue_event_source => 'queue_head_response_demux',
        },
    ];
    my $expected_completion_signals = $args{completion_signals} // [qw(axi0_r0_complete axi0_r1_complete)];
    my $expected_rules = $args{generated_rules} // [qw(axi0_r0_response_demux axi0_r1_response_demux)];
    my $expected_assertions = $args{generated_assertions} // [
        qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)
    ];

    is($demux->{mode}, 'bounded_response_demux_contract', "$owner marks bounded response-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks top-level generated behavior true");
    my $read = $demux->{read};
    is($read->{mode}, 'bounded_read_rid_queue_head_demux_contract', "$owner marks queue-head read demux mode");
    ok($read->{generated_behavior}, "$owner marks read generated behavior true");
    is($read->{implementation_status}, 'generated', "$owner reports generated status");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response', "$owner reports single-beat response role");
    is($read->{response_scope}, 'single_beat', "$owner reports single-beat scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports RID direction");
    ok(!exists($read->{last_signal}), "$owner omits RLAST signal for single-beat queue-head demux");
    ok(!exists($read->{last_signal_width}), "$owner omits RLAST width for single-beat queue-head demux");
    is($read->{transaction_completion_source}, 'generated_queue_head_demux', "$owner reports queue-head transaction completion source");
    is($read->{transaction_completion_semantics}, 'matched_concrete_id_queue_head', "$owner reports queue-head single-beat semantics");
    is($read->{queue_state_representation}, 'compact_onehot_transaction_slots', "$owner reports queue state representation");
    is_deeply(
        $read->{same_id_issue_order_queues},
        $expected_queues,
        "$owner reports duplicate concrete read-ID queue group",
    );
    ok($read->{generated_queue_behavior}, "$owner reports generated queue behavior");
    is($read->{generated_queue_behavior_boundary}, 'generated_read_single_beat_queue_head_demux', "$owner reports generated read single-beat queue boundary");
    ok(!exists($read->{selected_completion_signals}), "$owner no longer reports selected completion signal names");
    is_deeply($read->{generated_completion_signals}, $expected_completion_signals, "$owner reports generated completion signal names");
    is_deeply($read->{generated_rules}, $expected_rules, "$owner reports generated response-demux rules");
    is_deeply(
        $read->{generated_assertions},
        $expected_assertions,
        "$owner reports generated response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_data_interleaving bursts)],
        "$owner removes generated queue-head demux behavior from residue",
    );
}

sub assert_same_id_write_queue_head_response_demux_report {
    my ($demux, $owner, %args) = @_;

    my $expected_queues = $args{queues} // [
        {
            concrete_id          => 3,
            transactions         => [qw(w0 w1)],
            depth                => 2,
            dequeue_event_source => 'queue_head_response_demux',
        },
    ];
    my $expected_completion_signals = $args{completion_signals} // [qw(axi0_w0_complete axi0_w1_complete)];
    my $expected_rules = $args{generated_rules} // [qw(axi0_w0_response_demux axi0_w1_response_demux)];
    my $expected_assertions = $args{generated_assertions} // [
        qw(axi0_write_response_demux_active_match axi0_w0_w1_write_response_demux_unique_match)
    ];

    is($demux->{mode}, 'bounded_write_bid_demux_contract', "$owner keeps write-only top-level response-demux mode");
    ok($demux->{generated_behavior}, "$owner marks top-level generated behavior true");
    my $write = $demux->{write};
    is($write->{mode}, 'bounded_write_bid_queue_head_demux_contract', "$owner marks queue-head write demux mode");
    ok($write->{generated_behavior}, "$owner marks write generated behavior true");
    is($write->{implementation_status}, 'generated', "$owner reports generated status");
    is($write->{response_event}, 'axi0_write_complete', "$owner reports raw write response event");
    is($write->{response_event_role}, 'raw_accepted_write_response', "$owner reports write response role");
    is($write->{response_id_signal}, 'axi0_bid', "$owner reports BID signal");
    is($write->{response_id_direction}, 'generated_input', "$owner reports BID direction");
    is($write->{transaction_completion_source}, 'generated_queue_head_demux', "$owner reports queue-head transaction completion source");
    is($write->{transaction_completion_semantics}, 'matched_concrete_id_queue_head', "$owner reports queue-head write semantics");
    is($write->{queue_state_representation}, 'compact_onehot_transaction_slots', "$owner reports queue state representation");
    is_deeply(
        $write->{same_id_issue_order_queues},
        $expected_queues,
        "$owner reports duplicate concrete write-ID queue group",
    );
    ok($write->{generated_queue_behavior}, "$owner reports generated queue behavior");
    is($write->{generated_queue_behavior_boundary}, 'generated_write_bid_queue_head_demux', "$owner reports generated write queue boundary");
    ok(!exists($write->{selected_completion_signals}), "$owner no longer reports selected completion signal names");
    is_deeply($write->{generated_completion_signals}, $expected_completion_signals, "$owner reports generated completion signal names");
    is_deeply($write->{generated_rules}, $expected_rules, "$owner reports generated response-demux rules");
    is_deeply(
        $write->{generated_assertions},
        $expected_assertions,
        "$owner reports generated response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux read_data_interleaving bursts)],
        "$owner removes generated queue-head demux behavior from residue",
    );
}

sub same_id_response_demux_assertions {
    my ($family, @transactions) = @_;
    my @assertions = ("axi0_${family}_response_demux_active_match");
    for my $left_index (0 .. $#transactions - 1) {
        for my $right_index ($left_index + 1 .. $#transactions) {
            push @assertions,
                "axi0_$transactions[$left_index]_$transactions[$right_index]_${family}_response_demux_unique_match";
        }
    }
    return \@assertions;
}

sub assert_ppif_queue_head_adapter_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($args{source}->(), $sample_path);

    is($result->{report}{source_object}{id}, $args{object_id}, "$args{owner} source object id is preserved");
    is($result->{report}{source_object}{intent_name}, $args{intent_name}, "$args{owner} source intent name is preserved");
    $args{report_assertion}->(
        $result->{report}{response_demux},
        "$args{owner} adapter report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    my $policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{$args{policy_family}};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} adapter report lists generated queue depths");
    is_deeply($result->{report}{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_schedule_json_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $sample_path],
    );

    ok($success, "$args{owner} --emit-schedule-json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --emit-schedule-json keeps stderr clean");
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "$args{owner} keeps the capacity/status report schema");
    is($report->{source_object}{intent_name}, $args{intent_name}, "$args{owner} report carries the PPIF top-level intent name");
    $args{report_assertion}->(
        $report->{response_demux},
        "$args{owner} CLI report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    my $policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{$args{policy_family}};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} CLI report lists generated queue depths");
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_verify_hdl_case {
    my (%args) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, "$args{artifact_stem}.sv");

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $args{path}->()],
    );

    ok($success, "$args{owner} --verify-hdl succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --verify-hdl keeps stderr clean");
    ok(-f $hdl, "$args{owner} --output writes generated HDL");
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+$args{id_signal}\b/, "$args{owner} HDL exposes generated ID input");
    if ($args{expects_rlast}) {
        like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, "$args{owner} HDL exposes generated RLAST input");
    }
    else {
        unlike($sv, qr/\baxi0_rlast\b/, "$args{owner} HDL does not expose RLAST");
    }
    like($sv, $args{completion_output_pattern}, "$args{owner} HDL exposes the final generated completion output");
    like($sv, $args{slot_state_pattern}, "$args{owner} HDL exposes the selected queue slot state");
    like($sv, $args{demux_guard_pattern}, "$args{owner} HDL lowers the selected concrete-ID head match guard");
}

sub assert_ppif_queue_head_read_data_adapter_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($args{source}->(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    my $tx = $args{final_transaction};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', "$args{owner} sample still uses the capacity/status generator");
    is($result->{report}{source_object}{id}, $args{object_id}, "$args{owner} source object id is preserved");
    is($result->{report}{source_object}{intent_name}, $args{intent_name}, "$args{owner} source intent name is preserved");
    like($isf, $args{isf_demux_rule_pattern}, "$args{owner} sample emits generated $tx queue-head demux rule");
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$args{owner} sample generates RDATA input");
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$args{owner} sample generates RRESP input");
    like($isf, qr/\(output axi0_${tx}_rdata \(width 32\)\)/, "$args{owner} sample declares $tx data output");
    like($isf, qr/\(output axi0_${tx}_rresp \(width 2\)\)/, "$args{owner} sample declares $tx status output");
    like(
        $isf,
        qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_rdata axi0_rdata\)\s+\(axi0_${tx}_rresp axi0_rresp\)\)/,
        "$args{owner} sample captures $tx payload under generated completion",
    );
    like(
        $fsm,
        qr/\(-axi0_${tx}_read_data_capture\s+<axi0_${tx}_complete\s+\(<- \(axi0_${tx}_rdata> axi0_rdata\)\)\s+\(<- \(axi0_${tx}_rresp> axi0_rresp\)\)/,
        "$args{owner} sample lowers $tx capture rule into generated .fsm",
    );
    unlike($isf, qr/\baxi0_rlast\b/, "$args{owner} sample does not generate or consume RLAST");
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        "$args{owner} adapter response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_report(
        $result->{report}{read_data},
        "$args{owner} adapter read-data report",
        'generated_queue_head_response_demux_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} adapter report lists generated queue depths");
    is_deeply($result->{report}{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_read_data_schedule_json_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $sample_path],
    );

    ok($success, "$args{owner} --emit-schedule-json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --emit-schedule-json keeps stderr clean");
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "$args{owner} keeps the capacity/status report schema");
    is($report->{source_object}{intent_name}, $args{intent_name}, "$args{owner} report carries the PPIF top-level intent name");
    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $report->{response_demux},
        "$args{owner} CLI response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_report(
        $report->{read_data},
        "$args{owner} CLI read-data report",
        'generated_queue_head_response_demux_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} CLI report lists generated queue depths");
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_read_data_verify_hdl_case {
    my (%args) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, "$args{artifact_stem}.sv");
    my $tx = $args{final_transaction};

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $args{path}->()],
    );

    ok($success, "$args{owner} --verify-hdl succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --verify-hdl keeps stderr clean");
    ok(-f $hdl, "$args{owner} --output writes generated HDL");
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, "$args{owner} HDL exposes generated RID input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, "$args{owner} HDL exposes generated RDATA input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, "$args{owner} HDL exposes generated RRESP input");
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_${tx}_rdata\b/, "$args{owner} HDL exposes $tx captured data output");
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${tx}_rresp\b/, "$args{owner} HDL exposes $tx captured status output");
    like($sv, qr/assign\s+axi0_${tx}_read_data_capture_en\s*=\s*axi0_${tx}_complete\s*;/, "$args{owner} HDL guards $tx capture with generated completion");
    like($sv, $args{hdl_demux_guard_pattern}, "$args{owner} HDL keeps the selected concrete RID queue-head demux guard");
    like($sv, qr/axi0_${tx}_rdata_next\s*=\s*axi0_rdata\s*;/, "$args{owner} HDL captures RDATA into $tx output");
    like($sv, qr/axi0_${tx}_rresp_next\s*=\s*axi0_rresp\s*;/, "$args{owner} HDL captures RRESP into $tx output");
    unlike($sv, qr/\baxi0_rlast\b/, "$args{owner} HDL does not expose RLAST");
}

sub assert_ppif_queue_head_last_beat_read_data_adapter_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($args{source}->(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    my $tx = $args{final_transaction};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', "$args{owner} sample still uses the capacity/status generator");
    is($result->{report}{source_object}{id}, $args{object_id}, "$args{owner} source object id is preserved");
    is($result->{report}{source_object}{intent_name}, $args{intent_name}, "$args{owner} source intent name is preserved");
    like($isf, $args{isf_demux_rule_pattern}, "$args{owner} sample emits generated $tx RLAST-gated queue-head demux rule");
    like($isf, qr/\(input axi0_rlast\)/, "$args{owner} sample generates RLAST input");
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$args{owner} sample generates RDATA input");
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$args{owner} sample generates RRESP input");
    like($isf, qr/\(output axi0_${tx}_last_rdata \(width 32\)\)/, "$args{owner} sample declares $tx last data output");
    like($isf, qr/\(output axi0_${tx}_last_rresp \(width 2\)\)/, "$args{owner} sample declares $tx last status output");
    like(
        $isf,
        qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/,
        "$args{owner} sample captures $tx last payload under generated completion",
    );
    like(
        $fsm,
        qr/\(-axi0_${tx}_read_data_capture\s+<axi0_${tx}_complete\s+\(<- \(axi0_${tx}_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_${tx}_last_rresp> axi0_rresp\)\)/,
        "$args{owner} sample lowers $tx last capture rule into generated .fsm",
    );
    unlike($isf, qr/\baxi0_arlen\b/, "$args{owner} sample does not generate ARLEN capture");
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        "$args{owner} adapter response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        "$args{owner} adapter read-data report",
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} adapter report lists generated queue depths");
    is_deeply($result->{report}{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_last_beat_read_data_schedule_json_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $sample_path],
    );

    ok($success, "$args{owner} --emit-schedule-json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --emit-schedule-json keeps stderr clean");
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "$args{owner} keeps the capacity/status report schema");
    is($report->{source_object}{intent_name}, $args{intent_name}, "$args{owner} report carries the PPIF top-level intent name");
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        "$args{owner} CLI response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_last_beat_report(
        $report->{read_data},
        "$args{owner} CLI read-data report",
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} CLI report lists generated queue depths");
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_last_beat_read_data_verify_hdl_case {
    my (%args) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, "$args{artifact_stem}.sv");
    my $tx = $args{final_transaction};

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $args{path}->()],
    );

    ok($success, "$args{owner} --verify-hdl succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --verify-hdl keeps stderr clean");
    ok(-f $hdl, "$args{owner} --output writes generated HDL");
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, "$args{owner} HDL exposes generated RID input");
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, "$args{owner} HDL exposes generated RLAST input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, "$args{owner} HDL exposes generated RDATA input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, "$args{owner} HDL exposes generated RRESP input");
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_${tx}_last_rdata\b/, "$args{owner} HDL exposes $tx captured last data output");
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${tx}_last_rresp\b/, "$args{owner} HDL exposes $tx captured last status output");
    like($sv, qr/assign\s+axi0_${tx}_read_data_capture_en\s*=\s*axi0_${tx}_complete\s*;/, "$args{owner} HDL guards $tx last capture with generated completion");
    like($sv, $args{hdl_demux_guard_pattern}, "$args{owner} HDL keeps the selected RLAST-gated concrete RID queue-head demux guard");
    like($sv, qr/axi0_${tx}_last_rdata_next\s*=\s*axi0_rdata\s*;/, "$args{owner} HDL captures RDATA into $tx last output");
    like($sv, qr/axi0_${tx}_last_rresp_next\s*=\s*axi0_rresp\s*;/, "$args{owner} HDL captures RRESP into $tx last output");
    unlike($sv, qr/\baxi0_arlen\b/, "$args{owner} HDL does not expose ARLEN");
}

sub assert_ppif_queue_head_last_beat_burst_length_adapter_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($args{source}->(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    my $tx = $args{final_transaction};
    my $validation = $args{runtime_validation} ? 'runtime_assertion' : 'report_only';

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', "$args{owner} sample still uses the capacity/status generator");
    is($result->{report}{source_object}{id}, $args{object_id}, "$args{owner} source object id is preserved");
    is($result->{report}{source_object}{intent_name}, $args{intent_name}, "$args{owner} source intent name is preserved");
    like($isf, $args{isf_demux_rule_pattern}, "$args{owner} sample emits generated $tx RLAST-gated queue-head demux rule");
    like($isf, qr/\(input axi0_rlast\)/, "$args{owner} sample generates RLAST input");
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$args{owner} sample generates RDATA input");
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$args{owner} sample generates RRESP input");
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, "$args{owner} sample generates ARLEN input");
    like($isf, qr/\(output axi0_${tx}_last_rdata \(width 32\)\)/, "$args{owner} sample declares $tx last data output");
    like($isf, qr/\(output axi0_${tx}_last_rresp \(width 2\)\)/, "$args{owner} sample declares $tx last status output");
    like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "$args{owner} sample declares $tx raw ARLEN storage");
    like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "$args{owner} sample captures $tx raw ARLEN under request");
    like(
        $isf,
        qr/\(rule axi0_${tx}_read_data_capture axi0_${tx}_complete\s+\(axi0_${tx}_last_rdata axi0_rdata\)\s+\(axi0_${tx}_last_rresp axi0_rresp\)\)/,
        "$args{owner} sample captures $tx last payload under generated completion",
    );
    like(
        $fsm,
        qr/\(-axi0_${tx}_burst_length_capture\s+<axi0_${tx}_request\s+\(<- \(axi0_${tx}_arlen_q axi0_arlen\)\)\s+\)/,
        "$args{owner} sample lowers $tx raw ARLEN capture rule into generated .fsm",
    );
    if ($args{runtime_validation}) {
        like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "$args{owner} runtime sample declares $tx expected-beat storage");
        like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "$args{owner} runtime sample declares $tx beat-count storage");
        like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\b/, "$args{owner} runtime sample initializes $tx expected-beat state on request");
        like($isf, qr/\(rule axi0_${tx}_read_beat_count\b/, "$args{owner} runtime sample increments $tx matched read-beat count");
    } else {
        unlike($isf, qr/\bexpected_beats_q\b/, "$args{owner} report-only sample does not generate expected-beat storage");
        unlike($isf, qr/\bread_beat_count_q\b/, "$args{owner} report-only sample does not generate beat-count storage");
    }
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        "$args{owner} adapter response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        "$args{owner} adapter read-data report",
        $validation,
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} adapter report lists generated queue depths");
    is_deeply($result->{report}{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_last_beat_burst_length_schedule_json_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $validation = $args{runtime_validation} ? 'runtime_assertion' : 'report_only';
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $sample_path],
    );

    ok($success, "$args{owner} --emit-schedule-json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --emit-schedule-json keeps stderr clean");
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "$args{owner} keeps the capacity/status report schema");
    is($report->{source_object}{intent_name}, $args{intent_name}, "$args{owner} report carries the PPIF top-level intent name");
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        "$args{owner} CLI response-demux report",
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_burst_length_report(
        $report->{read_data},
        "$args{owner} CLI read-data report",
        $validation,
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} CLI report lists generated queue depths");
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_last_beat_burst_length_verify_hdl_case {
    my (%args) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, "$args{artifact_stem}.sv");
    my $tx = $args{final_transaction};

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $args{path}->()],
    );

    ok($success, "$args{owner} --verify-hdl succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --verify-hdl keeps stderr clean");
    ok(-f $hdl, "$args{owner} --output writes generated HDL");
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, "$args{owner} HDL exposes generated RID input");
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, "$args{owner} HDL exposes generated RLAST input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, "$args{owner} HDL exposes generated RDATA input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, "$args{owner} HDL exposes generated RRESP input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, "$args{owner} HDL exposes generated ARLEN input");
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_${tx}_last_rdata\b/, "$args{owner} HDL exposes $tx captured last data output");
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${tx}_last_rresp\b/, "$args{owner} HDL exposes $tx captured last status output");
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_${tx}_arlen_q\b/, "$args{owner} HDL declares $tx raw ARLEN storage");
    like($sv, qr/assign\s+axi0_${tx}_burst_length_capture_en\s*=\s*axi0_${tx}_request\s*;/, "$args{owner} HDL guards $tx ARLEN capture with request");
    like($sv, qr/axi0_${tx}_arlen_q_next\s*=\s*axi0_arlen\s*;/, "$args{owner} HDL captures raw ARLEN into $tx storage");
    like($sv, qr/assign\s+axi0_${tx}_read_data_capture_en\s*=\s*axi0_${tx}_complete\s*;/, "$args{owner} HDL guards $tx last capture with generated completion");
    like($sv, $args{hdl_demux_guard_pattern}, "$args{owner} HDL keeps the selected RLAST-gated concrete RID queue-head demux guard");
    like($sv, qr/axi0_${tx}_last_rdata_next\s*=\s*axi0_rdata\s*;/, "$args{owner} HDL captures RDATA into $tx last output");
    like($sv, qr/axi0_${tx}_last_rresp_next\s*=\s*axi0_rresp\s*;/, "$args{owner} HDL captures RRESP into $tx last output");
    if ($args{runtime_validation}) {
        like($sv, qr/\breg\s+\[4:0\]\s+axi0_${tx}_expected_beats_q\b/, "$args{owner} HDL declares $tx expected-beat storage");
        like($sv, qr/\breg\s+\[4:0\]\s+axi0_${tx}_read_beat_count_q\b/, "$args{owner} HDL declares $tx beat-count storage");
        like($sv, qr/assign\s+axi0_${tx}_beat_count_init_en\s*=\s*axi0_${tx}_request\s*;/, "$args{owner} HDL guards $tx beat-count init with request");
        like($sv, qr/assign\s+axi0_${tx}_read_beat_count_en\s*=/, "$args{owner} HDL emits $tx beat-count increment enable");
    } else {
        unlike($sv, qr/\bexpected_beats_q\b/, "$args{owner} report-only HDL does not declare expected-beat storage");
        unlike($sv, qr/\bread_beat_count_q\b/, "$args{owner} report-only HDL does not declare beat-count storage");
    }
}

sub assert_ppif_queue_head_multi_beat_read_data_adapter_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my $result = FSM::Adapter::IAL2::PPIF->new()->parse_source($args{source}->(), $sample_path);
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    my $tx = $args{final_transaction};

    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', "$args{owner} sample still uses the capacity/status generator");
    is($result->{report}{source_object}{id}, $args{object_id}, "$args{owner} source object id is preserved");
    is($result->{report}{source_object}{intent_name}, $args{intent_name}, "$args{owner} source intent name is preserved");
    like($isf, $args{isf_demux_rule_pattern}, "$args{owner} sample emits generated $tx RLAST-gated queue-head demux rule");
    like($isf, qr/\(input axi0_rlast\)/, "$args{owner} sample generates RLAST input");
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$args{owner} sample generates RDATA input");
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$args{owner} sample generates RRESP input");
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, "$args{owner} sample generates ARLEN input");
    like($isf, qr/\(output axi0_${tx}_beat_rdata_0 \(width 32\)\)/, "$args{owner} sample declares $tx beat 0 data output");
    like($isf, qr/\(output axi0_${tx}_beat_rresp_0 \(width 2\)\)/, "$args{owner} sample declares $tx beat 0 status output");
    like($isf, qr/\(output axi0_${tx}_rresp \(width 2\)\)/, "$args{owner} sample declares $tx scalar aggregate status output");
    like($isf, qr/\(output axi0_${tx}_beat_valid \(width 16\)\)/, "$args{owner} sample declares $tx valid-mask output");
    like($isf, qr/\(output axi0_${tx}_read_beats \(width 5\)\)/, "$args{owner} sample declares $tx length output");
    like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "$args{owner} sample declares $tx raw ARLEN storage");
    like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "$args{owner} sample declares $tx expected-beat storage");
    like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "$args{owner} sample declares $tx beat-count storage");
    like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "$args{owner} sample captures $tx raw ARLEN under request");
    like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\b/, "$args{owner} sample initializes $tx expected-beat state on request");
    like($isf, qr/\(rule axi0_${tx}_read_beat_count\b/, "$args{owner} sample increments $tx matched read-beat count");
    like(
        $isf,
        qr/\(rule axi0_${tx}_read_data_output_init axi0_${tx}_request[\s\S]*\(axi0_${tx}_beat_rdata_0 32'd0\)[\s\S]*\(axi0_${tx}_rresp 2'd0\)[\s\S]*\(axi0_${tx}_beat_valid 16'b0\)[\s\S]*\(axi0_${tx}_read_beats 5'd0\)\)/,
        "$args{owner} sample clears $tx output bank and aggregate on request",
    );
    like(
        $isf,
        qr/\(rule axi0_${tx}_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_${tx}_q\)\) \(! axi0_${tx}_request\) \(== axi0_${tx}_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_${tx}_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_${tx}_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_${tx}_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_${tx}_read_beats 5'd1\)\)/,
        "$args{owner} sample captures $tx lane 0 payload, status, valid mask, and length",
    );
    like(
        $isf,
        qr/\(rule axi0_${tx}_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_${tx}_q\)\) \(! axi0_${tx}_request\) \(< axi0_${tx}_rresp axi0_rresp\)\)\s+\(axi0_${tx}_rresp axi0_rresp\)\)/,
        "$args{owner} sample updates $tx scalar aggregate on matched beat",
    );
    like(
        $fsm,
        qr/\(-axi0_${tx}_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_${tx}_q\)\) \(! axi0_${tx}_request\) \(== axi0_${tx}_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_${tx}_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_${tx}_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_${tx}_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_${tx}_read_beats> 5'd1\)\)/,
        "$args{owner} sample lowers $tx lane 0 payload, status, valid mask, and length into generated .fsm",
    );
    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        "$args{owner} adapter response-demux report",
        residue => [],
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        "$args{owner} adapter read-data report",
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} adapter report lists generated queue depths");
    is_deeply($result->{report}{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_multi_beat_read_data_schedule_json_case {
    my (%args) = @_;
    my $sample_path = $args{path}->();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--emit-schedule-json', $sample_path],
    );

    ok($success, "$args{owner} --emit-schedule-json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --emit-schedule-json keeps stderr clean");
    my $report = decode_json(join('', @{$stdout_buf || []}));
    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', "$args{owner} keeps the capacity/status report schema");
    is($report->{source_object}{intent_name}, $args{intent_name}, "$args{owner} report carries the PPIF top-level intent name");
    assert_same_id_queue_head_response_demux_report(
        $report->{response_demux},
        "$args{owner} CLI response-demux report",
        residue => [],
        queues => $args{queues},
        completion_signals => $args{completion_signals},
        generated_rules => $args{generated_rules},
        generated_assertions => $args{generated_assertions},
    );
    assert_read_data_multi_beat_report(
        $report->{read_data},
        "$args{owner} CLI read-data report",
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => $args{transactions},
    );
    my $policy = $report->{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$policy->{generated_queues} || []}], $args{queue_depths}, "$args{owner} CLI report lists generated queue depths");
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], "$args{owner} keeps the generated .fsm artifact name stable");
}

sub assert_ppif_queue_head_multi_beat_read_data_verify_hdl_case {
    my (%args) = @_;
    my $tempdir = tempdir(CLEANUP => 1);
    my $hdl = File::Spec->catfile($tempdir, "$args{artifact_stem}.sv");
    my $tx = $args{final_transaction};

    my ($success, undef, undef, undef, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--quiet', '--verify-hdl', '--output', $hdl, $args{path}->()],
    );

    ok($success, "$args{owner} --verify-hdl succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --verify-hdl keeps stderr clean");
    ok(-f $hdl, "$args{owner} --output writes generated HDL");
    my $sv = slurp($hdl);
    like($sv, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, "$args{owner} HDL exposes generated RID input");
    like($sv, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, "$args{owner} HDL exposes generated RLAST input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, "$args{owner} HDL exposes generated RDATA input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, "$args{owner} HDL exposes generated RRESP input");
    like($sv, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, "$args{owner} HDL exposes generated ARLEN input");
    like($sv, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_${tx}_beat_rdata_0\b/, "$args{owner} HDL exposes $tx beat 0 data output");
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${tx}_beat_rresp_0\b/, "$args{owner} HDL exposes $tx beat 0 status output");
    like($sv, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_${tx}_rresp\b/, "$args{owner} HDL exposes $tx scalar aggregate status output");
    like($sv, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_${tx}_beat_valid\b/, "$args{owner} HDL exposes $tx valid-mask output");
    like($sv, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_${tx}_read_beats\b/, "$args{owner} HDL exposes $tx length output");
    like($sv, qr/\breg\s+\[7:0\]\s+axi0_${tx}_arlen_q\b/, "$args{owner} HDL declares $tx raw ARLEN storage");
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_${tx}_expected_beats_q\b/, "$args{owner} HDL declares $tx expected-beat storage");
    like($sv, qr/\breg\s+\[4:0\]\s+axi0_${tx}_read_beat_count_q\b/, "$args{owner} HDL declares $tx beat-count storage");
    like($sv, qr/assign\s+axi0_${tx}_burst_length_capture_en\s*=\s*axi0_${tx}_request\s*;/, "$args{owner} HDL guards $tx ARLEN capture with request");
    like($sv, qr/assign\s+axi0_${tx}_beat_count_init_en\s*=\s*axi0_${tx}_request\s*;/, "$args{owner} HDL guards $tx beat-count init with request");
    like($sv, qr/assign\s+axi0_${tx}_read_beat_count_en\s*=/, "$args{owner} HDL emits $tx beat-count increment enable");
    like($sv, qr/assign\s+axi0_${tx}_read_data_output_init_en\s*=\s*axi0_${tx}_request\s*;/, "$args{owner} HDL guards $tx output-bank clear with request");
    like($sv, qr/assign\s+axi0_${tx}_read_beat_0_capture_en\s*=/, "$args{owner} HDL emits $tx lane 0 capture enable");
    like($sv, $args{hdl_demux_guard_pattern}, "$args{owner} HDL keeps the selected RLAST-gated concrete RID queue-head demux guard");
    like($sv, qr/axi0_${tx}_arlen_q_next\s*=\s*axi0_arlen\s*;/, "$args{owner} HDL captures raw ARLEN into $tx storage");
    like($sv, qr/axi0_${tx}_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, "$args{owner} HDL captures RDATA into $tx beat 0 output");
    like($sv, qr/axi0_${tx}_beat_rresp_0_next\s*=\s*axi0_rresp\s*;/, "$args{owner} HDL captures RRESP into $tx beat 0 output");
    like($sv, qr/axi0_${tx}_beat_valid_next\s*=\s*16'b1\s*;/, "$args{owner} HDL marks $tx beat 0 valid");
    like($sv, qr/axi0_${tx}_read_beats_next\s*=\s*5'd1\s*;/, "$args{owner} HDL reports $tx first beat length");
    like($sv, qr/axi0_${tx}_rresp_next\s*=\s*axi0_rresp\s*;/, "$args{owner} HDL updates $tx scalar aggregate from current RRESP");
}

sub assert_ppif_strict_json_support_case {
    my (%args) = @_;
    my $policy_path = $args{path}->();
    my ($success, undef, undef, $stdout_buf, $stderr_buf) = run(
        command => ['./bin/fsmgen', '--strict', '--check', '--json', $policy_path],
    );
    ok($success, "$args{owner} --check --json succeeds");
    is(join('', @{$stderr_buf || []}), '', "$args{owner} --check --json keeps stderr clean");
    my $check_report = decode_json(join('', @{$stdout_buf || []}));
    ok($check_report->{success}, "$args{owner} check JSON reports success");
    is($check_report->{source}{resolved_path}, File::Spec->rel2abs($policy_path), "$args{owner} check JSON reports the public .ppif source path");
    is($check_report->{support_accounting}{entry_id}, $args{entry_id}, "$args{owner} check JSON support accounting names the PPIF corpus entry");

    my ($semantic_success, undef, undef, $semantic_stdout, $semantic_stderr) = run(
        command => ['./bin/fsmgen', '--strict', '--emit-semantic-json', $policy_path],
    );
    ok($semantic_success, "$args{owner} --emit-semantic-json succeeds");
    is(join('', @{$semantic_stderr || []}), '', "$args{owner} --emit-semantic-json keeps stderr clean");
    my $semantic_report = decode_json(join('', @{$semantic_stdout || []}));
    ok($semantic_report->{success}, "$args{owner} semantic JSON reports success");
    is($semantic_report->{source}{resolved_path}, File::Spec->rel2abs($policy_path), "$args{owner} semantic JSON reports the public .ppif source path");
    is($semantic_report->{support_accounting}{entry_id}, $args{entry_id}, "$args{owner} semantic JSON support accounting names the PPIF corpus entry");
    is($semantic_report->{semantic}{module}{name}, 'axi0_capacity_status', "$args{owner} semantic JSON records the unchanged generated module");
}

sub queue_head_depth3_read_data_case_args {
    my ($case_name) = @_;
    my %cases = (
        read_single_multi_depth3 => {
            owner => 'read single-beat multi-depth-3 same-ID queue-head read-data',
            path => \&sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_read_data_ppif_path,
            source => \&sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data',
            object_id => 'axi-manager-capacity-status-read-single-beat-multi-depth3-same-id-queue-head-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            transactions => [qw(r0 r1 r2 r3 r4 r5)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_single_beat_multi_depth3_same_id_queue_head_read_data',
            final_transaction => 'r5',
            isf_demux_rule_pattern => qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_single_mixed_depth3_depth2 => {
            owner => 'read single-beat mixed depth-3/depth-2 same-ID queue-head read-data',
            path => \&sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path,
            source => \&sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data',
            object_id => 'axi-manager-capacity-status-read-single-beat-mixed-depth3-depth2-same-id-queue-head-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            transactions => [qw(r0 r1 r2 r3 r4)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data',
            final_transaction => 'r4',
            isf_demux_rule_pattern => qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
    );
    return %{$cases{$case_name}};
}

sub queue_head_depth3_last_beat_read_data_case_args {
    my ($case_name) = @_;
    my %cases = (
        read_burst_multi_depth3 => {
            owner => 'read burst-last multi-depth-3 same-ID queue-head read-data',
            path => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_read_data_ppif_path,
            source => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data',
            object_id => 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            transactions => [qw(r0 r1 r2 r3 r4 r5)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_burst_last_multi_depth3_same_id_queue_head_read_data',
            final_transaction => 'r5',
            isf_demux_rule_pattern => qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_burst_mixed_depth3_depth2 => {
            owner => 'read burst-last mixed depth-3/depth-2 same-ID queue-head read-data',
            path => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_ppif_path,
            source => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data',
            object_id => 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            transactions => [qw(r0 r1 r2 r3 r4)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data',
            final_transaction => 'r4',
            isf_demux_rule_pattern => qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
    );
    return %{$cases{$case_name}};
}

sub queue_head_depth3_last_beat_burst_length_case_args {
    my ($case_name) = @_;
    my %cases = (
        read_burst_multi_depth3 => {
            owner => 'read burst-last multi-depth-3 same-ID queue-head burst-length',
            path => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_ppif_path,
            source => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length',
            object_id => 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-burst-length',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            transactions => [qw(r0 r1 r2 r3 r4 r5)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_burst_last_multi_depth3_same_id_queue_head_burst_length',
            final_transaction => 'r5',
            isf_demux_rule_pattern => qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_burst_mixed_depth3_depth2 => {
            owner => 'read burst-last mixed depth-3/depth-2 same-ID queue-head burst-length',
            path => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_ppif_path,
            source => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length',
            object_id => 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-burst-length',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            transactions => [qw(r0 r1 r2 r3 r4)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length',
            final_transaction => 'r4',
            isf_demux_rule_pattern => qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
        read_burst_multi_depth3_runtime_assertion => {
            owner => 'read burst-last multi-depth-3 same-ID queue-head runtime-validation burst-length',
            path => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif_path,
            source => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion',
            object_id => 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-burst-length-runtime-assertion',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            transactions => [qw(r0 r1 r2 r3 r4 r5)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion',
            final_transaction => 'r5',
            runtime_validation => 1,
            isf_demux_rule_pattern => qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_burst_mixed_depth3_depth2_runtime_assertion => {
            owner => 'read burst-last mixed depth-3/depth-2 same-ID queue-head runtime-validation burst-length',
            path => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_ppif_path,
            source => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion',
            object_id => 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-burst-length-runtime-assertion',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            transactions => [qw(r0 r1 r2 r3 r4)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion',
            final_transaction => 'r4',
            runtime_validation => 1,
            isf_demux_rule_pattern => qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
    );
    return %{$cases{$case_name}};
}

sub queue_head_depth3_multi_beat_read_data_case_args {
    my ($case_name) = @_;
    my %cases = (
        read_burst_multi_depth3 => {
            owner => 'read burst-last multi-depth-3 same-ID queue-head multi-beat read-data',
            path => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_ppif_path,
            source => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data',
            object_id => 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-multi-beat-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            transactions => [qw(r0 r1 r2 r3 r4 r5)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data',
            final_transaction => 'r5',
            isf_demux_rule_pattern => qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_burst_mixed_depth3_depth2 => {
            owner => 'read burst-last mixed depth-3/depth-2 same-ID queue-head multi-beat read-data',
            path => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_ppif_path,
            source => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data',
            object_id => 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-multi-beat-read-data',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data',
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            transactions => [qw(r0 r1 r2 r3 r4)],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data',
            final_transaction => 'r4',
            isf_demux_rule_pattern => qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
    );
    return %{$cases{$case_name}};
}

sub queue_head_depth3_case_args {
    my ($case_name) = @_;
    my %cases = (
        read_single_multi_depth3 => {
            owner => 'read single-beat multi-depth-3 same-ID queue-head response-demux',
            path => \&sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_read_single_beat_multi_depth3_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-read-single-beat-multi-depth3-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux',
            policy_family => 'read',
            report_assertion => \&assert_same_id_read_single_beat_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_single_beat_multi_depth3_same_id_queue_head_response_demux',
            id_signal => 'axi0_rid',
            expects_rlast => 0,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_r5_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_read_id5_same_id_issue_order_slot2_r5_q\b/,
            demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_single_mixed_depth3_depth2 => {
            owner => 'read single-beat mixed depth-3/depth-2 same-ID queue-head response-demux',
            path => \&sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-read-single-beat-mixed-depth3-depth2-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux',
            policy_family => 'read',
            report_assertion => \&assert_same_id_read_single_beat_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux',
            id_signal => 'axi0_rid',
            expects_rlast => 0,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_r4_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_read_id5_same_id_issue_order_slot1_r4_q\b/,
            demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
        read_burst_multi_depth3 => {
            owner => 'read burst-last multi-depth-3 same-ID queue-head response-demux',
            path => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_read_burst_last_multi_depth3_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux',
            policy_family => 'read',
            report_assertion => \&assert_same_id_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4 r5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4 r5)),
            artifact_stem => 'axi_read_burst_last_multi_depth3_same_id_queue_head_response_demux',
            id_signal => 'axi0_rid',
            expects_rlast => 1,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_r5_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_read_id5_same_id_issue_order_slot2_r5_q\b/,
            demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/,
        },
        read_burst_mixed_depth3_depth2 => {
            owner => 'read burst-last mixed depth-3/depth-2 same-ID queue-head response-demux',
            path => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux',
            policy_family => 'read',
            report_assertion => \&assert_same_id_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(r0 r1 r2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(r3 r4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
            generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('read', qw(r0 r1 r2 r3 r4)),
            artifact_stem => 'axi_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux',
            id_signal => 'axi0_rid',
            expects_rlast => 1,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_r4_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_read_id5_same_id_issue_order_slot1_r4_q\b/,
            demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/,
        },
        write_multi_depth3 => {
            owner => 'write multi-depth-3 same-ID queue-head response-demux',
            path => \&sample_capacity_write_multi_depth3_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_write_multi_depth3_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-write-multi-depth3-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux',
            policy_family => 'write',
            report_assertion => \&assert_same_id_write_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(w0 w1 w2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(w3 w4 w5)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 3],
            completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete axi0_w4_complete axi0_w5_complete)],
            generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux axi0_w4_response_demux axi0_w5_response_demux)],
            generated_assertions => same_id_response_demux_assertions('write', qw(w0 w1 w2 w3 w4 w5)),
            artifact_stem => 'axi_write_multi_depth3_same_id_queue_head_response_demux',
            id_signal => 'axi0_bid',
            expects_rlast => 0,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_w5_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_write_id5_same_id_issue_order_slot2_w5_q\b/,
            demux_guard_pattern => qr/axi0_write_complete\s*&\s*\(axi0_bid\s*==\s*4'd5\)\s*&\s*axi0_write_id5_same_id_issue_order_slot0_w5_q/,
        },
        write_mixed_depth3_depth2 => {
            owner => 'write mixed depth-3/depth-2 same-ID queue-head response-demux',
            path => \&sample_capacity_write_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif_path,
            source => \&sample_capacity_write_mixed_depth3_depth2_same_id_queue_head_response_demux_ppif,
            intent_name => 'axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux',
            object_id => 'axi-manager-capacity-status-write-mixed-depth3-depth2-same-id-queue-head-response-demux',
            entry_id => 'intent.ppif_axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux',
            policy_family => 'write',
            report_assertion => \&assert_same_id_write_queue_head_response_demux_report,
            queues => [
                { concrete_id => 3, transactions => [qw(w0 w1 w2)], depth => 3, dequeue_event_source => 'queue_head_response_demux' },
                { concrete_id => 5, transactions => [qw(w3 w4)], depth => 2, dequeue_event_source => 'queue_head_response_demux' },
            ],
            queue_depths => [3, 2],
            completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete axi0_w4_complete)],
            generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux axi0_w4_response_demux)],
            generated_assertions => same_id_response_demux_assertions('write', qw(w0 w1 w2 w3 w4)),
            artifact_stem => 'axi_write_mixed_depth3_depth2_same_id_queue_head_response_demux',
            id_signal => 'axi0_bid',
            expects_rlast => 0,
            completion_output_pattern => qr/\boutput\s+reg\s+axi0_w4_complete\b/,
            slot_state_pattern => qr/\breg\s+axi0_write_id5_same_id_issue_order_slot1_w4_q\b/,
            demux_guard_pattern => qr/axi0_write_complete\s*&\s*\(axi0_bid\s*==\s*4'd5\)\s*&\s*axi0_write_id5_same_id_issue_order_slot0_w4_q/,
        },
    );
    return %{$cases{$case_name}};
}

sub assert_same_id_reuse_policy_report {
    my ($ordering, $owner, $expected) = @_;

    is($ordering->{mode}, 'concrete_id_reuse_policy', "$owner marks policy-only same-ID ordering mode");
    ok(!$ordering->{generated_behavior}, "$owner marks policy-only generated behavior false");
    ok(!exists($ordering->{families}), "$owner does not report generated same-ID avoidance families");
    is_deeply(
        $ordering->{residue},
        [qw(concrete_id_same_id_ordering per_id_issue_order_queues)],
        "$owner keeps concrete same-ID ordering and per-ID queues as residue",
    );
    ok(@{$ordering->{source_anchors}}, "$owner carries source anchors into policy metadata");
    is_deeply(
        [sort keys %{$ordering->{concrete_id_reuse_policy}}],
        ['read'],
        "$owner reports the selected read concrete-ID reuse policy",
    );
    my $read = $ordering->{concrete_id_reuse_policy}{read};
    is($read->{policy}, $expected->{policy}, "$owner reports concrete-ID reuse policy");
    is($read->{enforcement}, $expected->{enforcement}, "$owner reports concrete-ID reuse enforcement");
    if (exists $expected->{implementation_status}) {
        is($read->{implementation_status}, $expected->{implementation_status}, "$owner reports implementation status");
    } else {
        ok(!exists($read->{implementation_status}), "$owner omits implementation status for generated or fully enforced policy");
    }
    ok(!$read->{accepted_same_id_reuse}, "$owner reports same-ID reuse is not accepted");
    ok(!$read->{generated_queue_behavior}, "$owner reports no generated queue behavior");
    if (exists $expected->{admitted_request_boundary}) {
        assert_same_id_admitted_request_boundary(
            $read->{admitted_request_boundary},
            $owner,
            $expected->{admitted_request_boundary},
        );
    } else {
        ok(!exists($read->{admitted_request_boundary}), "$owner omits admitted request boundary for policy");
    }
}

sub assert_same_id_admitted_request_boundary {
    my ($boundary, $owner, $expected) = @_;

    is($boundary->{guard_source}, 'capacity_storage_and_completion_fanin', "$owner reports admitted guard source");
    is($boundary->{pending_storage}, $expected->{pending_storage}, "$owner reports admitted guard pending storage");
    is($boundary->{max_pending}, $expected->{max_pending}, "$owner reports admitted guard max-pending bound");
    is($boundary->{completion_fanin}, $expected->{completion_fanin}, "$owner reports admitted guard completion fan-in");
    is_deeply($boundary->{selected_request_events}, $expected->{selected_request_events}, "$owner reports selected request events");
    is_deeply($boundary->{generated_assertions}, $expected->{generated_assertions}, "$owner reports admitted request assertions");
    is_deeply($boundary->{generated_pulses}, $expected->{generated_pulses}, "$owner reports admitted request pulses");
    for my $pulse (@{$boundary->{generated_pulses} || []}) {
        unlike($pulse->{guard}, qr/can_accept/, "$owner admitted request guard does not consume can_accept");
    }
}

sub assert_same_id_ordering_family {
    my ($family, $owner, $family_name, $response_demux_covered) = @_;
    my %expected = (
        write => {
            auto_transactions   => [qw(w0 w1)],
            selected_id_signals => [qw(axi0_w0_auto_id_q axi0_w1_auto_id_q)],
            busy_signals        => [qw(axi0_w0_auto_id_busy_q axi0_w1_auto_id_busy_q)],
            generated_assertions => [qw(axi0_w0_w1_auto_id_unique_active_id)],
        },
        read => {
            auto_transactions   => [qw(r0 r1)],
            selected_id_signals => [qw(axi0_r0_auto_id_q axi0_r1_auto_id_q)],
            busy_signals        => [qw(axi0_r0_auto_id_busy_q axi0_r1_auto_id_busy_q)],
            generated_assertions => [qw(axi0_r0_r1_auto_id_unique_active_id)],
        },
    );
    my $expect = $expected{$family_name};

    is($family->{family}, $family_name, "$owner reports the $family_name same-ID family");
    is($family->{strategy}, 'avoid_same_id_concurrency', "$owner reports family same-ID avoidance strategy");
    is($family->{enforcement}, 'allocator_free_id_guard', "$owner reports allocator free-ID enforcement");
    is($family->{assertion_enforcement}, 'runtime_assertion', "$owner reports runtime assertion enforcement");
    if ($response_demux_covered) {
        ok($family->{response_demux_covered}, "$owner reports response-demux coverage");
    } else {
        ok(!$family->{response_demux_covered}, "$owner reports response-demux coverage");
    }
    is_deeply($family->{auto_transactions}, $expect->{auto_transactions}, "$owner reports covered auto-ID transactions");
    is_deeply($family->{selected_id_signals}, $expect->{selected_id_signals}, "$owner reports selected-ID signals");
    is_deeply($family->{busy_signals}, $expect->{busy_signals}, "$owner reports busy signals");
    is_deeply($family->{generated_assertions}, $expect->{generated_assertions}, "$owner reports same-ID avoidance assertion");
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
