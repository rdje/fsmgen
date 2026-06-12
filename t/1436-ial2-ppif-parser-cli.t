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
        ['manager transaction duplicate concrete ID assertion event',
            capacity_ppif_with_objects(manager_capacity_object_with_id_families_and_transactions(
                '(write (width 4) (request-id awid) (response-id bid)) (read (width 4) (request-id arid) (response-id rid))',
                '(read r0 (tag rd0) (request axi0_read_submit) (completion axi0_read_complete) (id (value 3))) (read r1 (tag rd1) (request axi0_read_submit) (completion axi0_read_complete) (id (value 4)))',
            )),
            qr/concrete ID assertions require unique request events; event 'axi0_read_submit' is shared by transactions 'r0' and 'r1'/],
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
