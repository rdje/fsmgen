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
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(=> axi0_r0_request \(< axi0_arlen 8'd16\)\)/, 'runtime-assertion PPIF lowers r0 ARLEN bound assertion into generated .fsm');
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
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(=> axi0_r0_request \(< axi0_arlen 8'd16\)\)/, 'multi-beat PPIF lowers runtime validation assertions');
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
            qr/requires \(id auto\) or \(id \(value N\)\)/],
        ['manager transaction concrete ID too wide',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id (value 16)))',
            )),
            qr/concrete read ID value 16 does not fit width 4/],
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

sub sample_capacity_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status.ppif');
}

sub sample_capacity_id_family_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_id_family.ppif');
}

sub sample_capacity_transaction_ppif_path {
    return File::Spec->catfile($FindBin::Bin, '..', 'ppif', 'axi_manager_capacity_status_transaction_envelope.ppif');
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
        qr/generated burst-last RLAST response-demux completion, structural last-beat read-data metadata, generated last-beat read-data RDATA\/RRESP capture, generated raw-ARLEN burst-length capture, explicit runtime-assertion beat-count\/RLAST validation, generated multi-beat read-data output-bank behavior for the covered auto-ID multi-beat-by-RID subset, bounded burst payload\/output behavior through that per-beat output bank, and generated scalar RRESP aggregation behavior are supported/,
        "$owner reports generated burst-last, last-beat, raw ARLEN, beat-count, multi-beat output-bank, bounded burst output, and scalar aggregation behavior as supported",
    );
    my $stale_metadata = join('', 'report-only burst-last ', 'RLAST response-demux metadata');
    my $stale_tracking = join('', 'generated burst/last-beat tracking ', 'remain outside');
    ok(index($id_residue->{detail}, $stale_metadata) < 0, "$owner removes stale report-only residue prose");
    ok(index($id_residue->{detail}, $stale_tracking) < 0, "$owner removes stale burst tracking residue prose");
}

sub assert_read_data_report {
    my ($read_data, $owner) = @_;
    is($read_data->{mode}, 'bounded_single_beat_read_data_contract', "$owner marks bounded single-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner marks generated behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'single_beat', "$owner reports single-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, 'generated_read_response_demux_completion_pulse', "$owner reports generated demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal");
    is($read->{data_signal_width}, 32, "$owner reports RDATA width");
    is($read->{data_signal_direction}, 'generated_input', "$owner reports RDATA generated-input direction");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP status signal");
    is($read->{status_signal_width}, 2, "$owner reports RRESP status width");
    is($read->{status_signal_direction}, 'generated_input', "$owner reports RRESP generated-input direction");
    is($read->{interleaving_policy}, 'single_beat_by_rid', "$owner reports single-beat-by-RID interleaving policy");
    is_deeply(
        [map { $_->{transaction} } @{$read->{transactions}}],
        [qw(r0 r1)],
        "$owner reports read-data transaction bindings in source order",
    );
    is_deeply(
        [map { $_->{completion_signal} } @{$read->{transactions}}],
        [qw(axi0_r0_complete axi0_r1_complete)],
        "$owner binds read-data validity to generated demux completion pulses",
    );
    is_deeply(
        [map { $_->{data_output} } @{$read->{transactions}}],
        [qw(axi0_r0_rdata axi0_r1_rdata)],
        "$owner reports transaction data outputs",
    );
    is_deeply(
        [map { $_->{status_output} } @{$read->{transactions}}],
        [qw(axi0_r0_rresp axi0_r1_rresp)],
        "$owner reports transaction status outputs",
    );
    is_deeply(
        [map { $_->{data_width} } @{$read->{transactions}}],
        [32, 32],
        "$owner reports inherited transaction data widths",
    );
    is_deeply(
        [map { $_->{status_width} } @{$read->{transactions}}],
        [2, 2],
        "$owner reports inherited transaction status widths",
    );
    is_deeply(
        $read->{generated_inputs},
        [qw(axi0_rdata axi0_rresp)],
        "$owner reports generated read-data source inputs",
    );
    is_deeply(
        $read->{generated_outputs},
        [qw(axi0_r0_rdata axi0_r0_rresp axi0_r1_rdata axi0_r1_rresp)],
        "$owner reports generated read-data capture outputs",
    );
    is_deeply(
        $read->{generated_rules},
        [qw(axi0_r0_read_data_capture axi0_r1_read_data_capture)],
        "$owner reports generated read-data capture rules",
    );
    is_deeply(
        $read_data->{residue},
        [qw(rlast_completion bursts multi_beat_read_data_reassembly)],
        "$owner reports only RLAST, burst, and reassembly residue",
    );
}

sub assert_read_data_last_beat_report {
    my ($read_data, $owner) = @_;
    is($read_data->{mode}, 'bounded_last_beat_read_data_contract', "$owner marks bounded last-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner marks generated behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'last_beat', "$owner reports last-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, 'generated_read_response_demux_last_beat_completion_pulse', "$owner reports generated last-beat demux pulse validity");
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
    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], [qw(r0 r1)], "$owner reports last-beat transaction bindings");
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], [qw(axi0_r0_complete axi0_r1_complete)], "$owner binds validity to generated last-beat completion pulses");
    is_deeply([map { $_->{data_output} } @{$read->{transactions}}], [qw(axi0_r0_last_rdata axi0_r1_last_rdata)], "$owner reports last-beat data outputs");
    is_deeply([map { $_->{status_output} } @{$read->{transactions}}], [qw(axi0_r0_last_rresp axi0_r1_last_rresp)], "$owner reports last-beat status outputs");
    is_deeply([map { $_->{data_width} } @{$read->{transactions}}], [32, 32], "$owner reports inherited last-beat data widths");
    is_deeply([map { $_->{status_width} } @{$read->{transactions}}], [2, 2], "$owner reports inherited last-beat status widths");
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp)], "$owner reports generated RDATA/RRESP inputs");
    is_deeply(
        $read->{generated_outputs},
        [qw(axi0_r0_last_rdata axi0_r0_last_rresp axi0_r1_last_rdata axi0_r1_last_rresp)],
        "$owner reports generated last-beat data/status outputs",
    );
    is_deeply(
        $read->{generated_rules},
        [qw(axi0_r0_read_data_capture axi0_r1_read_data_capture)],
        "$owner reports generated last-beat capture rules",
    );
    is_deeply(
        $read_data->{residue},
        [qw(multi_beat_read_data_reassembly per_beat_outputs rresp_aggregation arlen_or_beat_count_validation)],
        "$owner reports last-beat read-data residue",
    );
}

sub assert_read_data_burst_length_report {
    my ($read_data, $owner, $validation) = @_;
    $validation //= 'report_only';
    my $runtime_validation = $validation eq 'runtime_assertion';

    is($read_data->{mode}, 'bounded_last_beat_read_data_contract', "$owner marks bounded last-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner keeps generated last-beat read-data behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'last_beat', "$owner reports last-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, 'generated_read_response_demux_last_beat_completion_pulse', "$owner reports generated last-beat demux pulse validity");
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
    is_deeply([map { $_->{burst_length_storage} } @{$read->{transactions}}], [qw(axi0_r0_arlen_q axi0_r1_arlen_q)], "$owner reports per-transaction raw ARLEN storage");
    is_deeply([map { $_->{burst_length_capture_rule} } @{$read->{transactions}}], [qw(axi0_r0_burst_length_capture axi0_r1_burst_length_capture)], "$owner reports per-transaction burst-length capture rules");
    if ($runtime_validation) {
        ok($read->{beat_count_validation_generated_behavior}, "$owner reports generated beat-count validation behavior");
        is($read->{expected_beat_count_encoding}, 'arlen_plus_one', "$owner reports expected beat-count encoding");
        is($read->{beat_count_match_source}, 'response_demux_matched_read_beat', "$owner reports matched read-beat source");
        is($read->{beat_count_width}, 5, "$owner reports beat-count storage width");
        is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], [qw(axi0_r0_expected_beats_q axi0_r1_expected_beats_q)], "$owner reports per-transaction expected-beat storage");
        is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], [qw(axi0_r0_read_beat_count_q axi0_r1_read_beat_count_q)], "$owner reports per-transaction beat-count storage");
        is_deeply([map { $_->{beat_count_init_rule} } @{$read->{transactions}}], [qw(axi0_r0_beat_count_init axi0_r1_beat_count_init)], "$owner reports beat-count init rules");
        is_deeply([map { $_->{beat_count_increment_rule} } @{$read->{transactions}}], [qw(axi0_r0_read_beat_count axi0_r1_read_beat_count)], "$owner reports beat-count increment rules");
        is_deeply(
            $read->{transactions}[0]{beat_count_assertions},
            [qw(axi0_r0_arlen_within_max axi0_r0_read_beat_before_expected_count axi0_r0_rlast_on_expected_beat axi0_r0_expected_final_beat_has_rlast)],
            "$owner reports r0 beat-count assertions",
        );
    } else {
        ok(!exists $read->{beat_count_validation_generated_behavior}, "$owner keeps report-only validation free of beat-count behavior flag");
        ok(!exists $read->{generated_beat_count_storage}, "$owner keeps report-only validation free of generated beat-count storage");
    }
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp axi0_arlen)], "$owner adds ARLEN to generated read-data inputs");
    is_deeply($read->{generated_burst_length_inputs}, [qw(axi0_arlen)], "$owner reports generated burst-length input");
    is_deeply($read->{generated_burst_length_storage}, [qw(axi0_r0_arlen_q axi0_r1_arlen_q)], "$owner reports generated burst-length storage");
    is_deeply($read->{generated_burst_length_rules}, [qw(axi0_r0_burst_length_capture axi0_r1_burst_length_capture)], "$owner reports generated burst-length capture rules");
    if ($runtime_validation) {
        is_deeply($read->{generated_expected_beat_count_storage}, [qw(axi0_r0_expected_beats_q axi0_r1_expected_beats_q)], "$owner reports generated expected-beat storage");
        is_deeply($read->{generated_beat_count_storage}, [qw(axi0_r0_read_beat_count_q axi0_r1_read_beat_count_q)], "$owner reports generated beat-count storage");
        is_deeply($read->{generated_beat_count_rules}, [qw(axi0_r0_beat_count_init axi0_r0_read_beat_count axi0_r1_beat_count_init axi0_r1_read_beat_count)], "$owner reports generated beat-count rules");
        is_deeply(
            $read->{generated_beat_count_assertions},
            [qw(axi0_r0_arlen_within_max axi0_r0_read_beat_before_expected_count axi0_r0_rlast_on_expected_beat axi0_r0_expected_final_beat_has_rlast axi0_r1_arlen_within_max axi0_r1_read_beat_before_expected_count axi0_r1_rlast_on_expected_beat axi0_r1_expected_final_beat_has_rlast)],
            "$owner reports generated beat-count assertions",
        );
    }
    is_deeply(
        $read->{generated_outputs},
        [qw(axi0_r0_last_rdata axi0_r0_last_rresp axi0_r1_last_rdata axi0_r1_last_rresp)],
        "$owner keeps generated last-beat outputs stable",
    );
    my @expected_rules = qw(axi0_r0_read_data_capture axi0_r1_read_data_capture axi0_r0_burst_length_capture axi0_r1_burst_length_capture);
    push @expected_rules, qw(axi0_r0_beat_count_init axi0_r0_read_beat_count axi0_r1_beat_count_init axi0_r1_read_beat_count)
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
    my ($read_data, $owner) = @_;

    is($read_data->{mode}, 'bounded_multi_beat_read_data_contract', "$owner marks bounded multi-beat read-data contract mode");
    ok($read_data->{generated_behavior}, "$owner keeps generated validation behavior true");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'multi_beat', "$owner reports multi-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, 'generated_read_response_demux_last_beat_completion_pulse', "$owner reports generated last-beat demux pulse validity");
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

    my @r0_data_outputs = map { "axi0_r0_beat_rdata_$_" } 0 .. 15;
    my @r1_data_outputs = map { "axi0_r1_beat_rdata_$_" } 0 .. 15;
    my @r0_status_outputs = map { "axi0_r0_beat_rresp_$_" } 0 .. 15;
    my @r1_status_outputs = map { "axi0_r1_beat_rresp_$_" } 0 .. 15;
    my @multi_beat_outputs = (
        @r0_data_outputs,
        @r0_status_outputs,
        qw(axi0_r0_rresp axi0_r0_beat_valid axi0_r0_read_beats),
        @r1_data_outputs,
        @r1_status_outputs,
        qw(axi0_r1_rresp axi0_r1_beat_valid axi0_r1_read_beats),
    );
    my @r0_capture_rules = map { "axi0_r0_read_beat_${_}_capture" } 0 .. 15;
    my @r1_capture_rules = map { "axi0_r1_read_beat_${_}_capture" } 0 .. 15;
    my @multi_beat_capture_rules = (@r0_capture_rules, @r1_capture_rules);
    my @status_aggregate_outputs = qw(axi0_r0_rresp axi0_r1_rresp);
    my @status_aggregate_init_rules = qw(axi0_r0_read_data_output_init axi0_r1_read_data_output_init);
    my @status_aggregate_update_rules = qw(axi0_r0_rresp_aggregate axi0_r1_rresp_aggregate);

    is_deeply([map { $_->{transaction} } @{$read->{transactions}}], [qw(r0 r1)], "$owner reports multi-beat transaction bindings");
    is_deeply([map { $_->{data_output_prefix} } @{$read->{transactions}}], [qw(axi0_r0_beat_rdata axi0_r1_beat_rdata)], "$owner reports data output prefixes");
    is_deeply([map { $_->{status_output_prefix} } @{$read->{transactions}}], [qw(axi0_r0_beat_rresp axi0_r1_beat_rresp)], "$owner reports status output prefixes");
    is_deeply([map { $_->{status_aggregate_output} } @{$read->{transactions}}], [qw(axi0_r0_rresp axi0_r1_rresp)], "$owner reports scalar RRESP aggregate outputs");
    is_deeply([map { $_->{status_aggregate_output_width} } @{$read->{transactions}}], [2, 2], "$owner reports scalar RRESP aggregate output widths");
    is_deeply($read->{transactions}[0]{generated_data_outputs}, \@r0_data_outputs, "$owner reports r0 generated data lane names");
    is_deeply($read->{transactions}[0]{generated_status_outputs}, \@r0_status_outputs, "$owner reports r0 generated status lane names");
    is_deeply([map { $_->{valid_mask_output} } @{$read->{transactions}}], [qw(axi0_r0_beat_valid axi0_r1_beat_valid)], "$owner reports valid-mask outputs");
    is_deeply([map { $_->{valid_mask_width} } @{$read->{transactions}}], [16, 16], "$owner reports valid-mask widths");
    is_deeply([map { $_->{length_output} } @{$read->{transactions}}], [qw(axi0_r0_read_beats axi0_r1_read_beats)], "$owner reports length outputs");
    is_deeply([map { $_->{length_output_width} } @{$read->{transactions}}], [5, 5], "$owner reports length-output widths");
    is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], [qw(axi0_r0_expected_beats_q axi0_r1_expected_beats_q)], "$owner reports expected-beat storage");
    is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], [qw(axi0_r0_read_beat_count_q axi0_r1_read_beat_count_q)], "$owner reports beat-count storage");
    is_deeply([map { $_->{multi_beat_output_init_rule} } @{$read->{transactions}}], [qw(axi0_r0_read_data_output_init axi0_r1_read_data_output_init)], "$owner reports multi-beat output init rules");
    is_deeply($read->{transactions}[0]{multi_beat_capture_rules}, \@r0_capture_rules, "$owner reports r0 multi-beat capture rules");
    is_deeply([map { $_->{status_aggregate_init_rule} } @{$read->{transactions}}], \@status_aggregate_init_rules, "$owner reports scalar aggregate init rule ownership");
    is_deeply([map { $_->{status_aggregate_update_rule} } @{$read->{transactions}}], \@status_aggregate_update_rules, "$owner reports scalar aggregate update rules");
    is_deeply($read->{generated_inputs}, [qw(axi0_rdata axi0_rresp axi0_arlen)], "$owner reports generated payload and ARLEN inputs");
    is_deeply($read->{generated_outputs}, \@multi_beat_outputs, "$owner reports generated output-bank and scalar aggregate outputs");
    is_deeply($read->{generated_status_aggregate_outputs}, \@status_aggregate_outputs, "$owner reports generated scalar aggregate outputs");
    is_deeply($read->{generated_multi_beat_data_outputs}, [@r0_data_outputs, @r1_data_outputs], "$owner reports generated multi-beat data outputs");
    is_deeply($read->{generated_multi_beat_status_outputs}, [@r0_status_outputs, @r1_status_outputs], "$owner reports generated multi-beat status outputs");
    is_deeply($read->{generated_multi_beat_valid_outputs}, [qw(axi0_r0_beat_valid axi0_r1_beat_valid)], "$owner reports generated multi-beat valid-mask outputs");
    is_deeply($read->{generated_multi_beat_length_outputs}, [qw(axi0_r0_read_beats axi0_r1_read_beats)], "$owner reports generated multi-beat length outputs");
    is_deeply($read->{generated_burst_length_storage}, [qw(axi0_r0_arlen_q axi0_r1_arlen_q)], "$owner reports generated burst-length storage");
    is_deeply($read->{generated_beat_count_rules}, [qw(axi0_r0_beat_count_init axi0_r0_read_beat_count axi0_r1_beat_count_init axi0_r1_read_beat_count)], "$owner reports generated beat-count rules");
    is_deeply($read->{generated_multi_beat_output_init_rules}, [qw(axi0_r0_read_data_output_init axi0_r1_read_data_output_init)], "$owner reports generated multi-beat output init rules");
    is_deeply($read->{generated_multi_beat_capture_rules}, \@multi_beat_capture_rules, "$owner reports generated multi-beat capture rules");
    is_deeply($read->{generated_status_aggregate_init_rules}, \@status_aggregate_init_rules, "$owner reports generated scalar aggregate init rules");
    is_deeply($read->{generated_status_aggregate_update_rules}, \@status_aggregate_update_rules, "$owner reports generated scalar aggregate update rules");
    is_deeply(
        $read->{generated_rules},
        [
            qw(axi0_r0_burst_length_capture axi0_r1_burst_length_capture axi0_r0_beat_count_init axi0_r0_read_beat_count axi0_r1_beat_count_init axi0_r1_read_beat_count axi0_r0_read_data_output_init axi0_r1_read_data_output_init),
            @r0_capture_rules,
            'axi0_r0_rresp_aggregate',
            @r1_capture_rules,
            'axi0_r1_rresp_aggregate',
        ],
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

sub assert_same_id_queue_head_response_demux_report {
    my ($demux, $owner) = @_;

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
        [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        "$owner reports duplicate concrete-ID queue group",
    );
    ok($read->{generated_queue_behavior}, "$owner reports generated queue behavior");
    is($read->{generated_queue_behavior_boundary}, 'generated_read_burst_last_queue_head_demux', "$owner reports generated queue boundary");
    ok(!exists($read->{selected_completion_signals}), "$owner no longer reports selected completion signal names");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated completion signal names");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated response-demux rules");
    is_deeply(
        $read->{generated_assertions},
        [qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)],
        "$owner reports generated response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_data_interleaving bursts)],
        "$owner removes generated queue-head demux behavior from residue",
    );
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
