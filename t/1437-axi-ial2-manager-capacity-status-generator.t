#!/usr/bin/env perl
use strict;
use warnings;
BEGIN {
    require Data::Dumper;
    $Data::Dumper::Maxdepth = 4;
}
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::Adapter::FSMGenFull;
use FSM::Backend::GeneratedModuleEmitter;
use FSM::HDL::FlattenedDT;
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;
use FSM::IR::IntentHIRBuilder;
use FSM::Pipeline::GeneratedModuleInfoBuilder;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;
use Lispish;

subtest 'AXI manager capacity/status generator emits reviewable IAL1 before IAL0' => sub {
    my $result = generate_sample();

    is($result->{layer}, 'IAL2', 'result identifies the source layer');
    is($result->{kind}, 'protocol_intent.axi_manager_capacity_status', 'result identifies the generator kind');
    is($result->{mode}, 'capacity-status-shell', 'first slice is explicitly a capacity/status shell');

    my $isf = $result->{generated_ial1}{text};
    is($result->{generated_ial1}{name}, 'axi0_capacity_status.isf', 'IAL1 artifact is named');
    like($isf, qr/\A\(actor axi0_capacity_status\b/, 'generated IAL1 is reviewable .isf text');
    like($isf, qr/\(reset \(rst_n async active_low\)\)/, 'generated IAL1 carries reset binding');
    like($isf, qr/\(input axi0_read_submit\)/, 'generated IAL1 exposes abstract read submit event');
    like($isf, qr/\(input axi0_read_complete\)/, 'generated IAL1 exposes abstract read completion event');
    like($isf, qr/\(output axi0_pending_reads \(width 3\)\)/, 'generated IAL1 exposes read pending status width');
    like($isf, qr/\(output axi0_pending_writes \(width 2\)\)/, 'generated IAL1 exposes write pending status width');
    like($isf, qr/\(var axi0_pending_reads_q \(width 3\)\)/, 'generated IAL1 declares read pending storage');
    like($isf, qr/\(var axi0_pending_writes_q \(width 2\)\)/, 'generated IAL1 declares write pending storage');
    unlike($isf, qr/\(output can_accept\)|\(var can_accept\b/, 'generated IAL1 does not expose a bare can_accept signal');

    my $actor = FSM::Adapter::ISF->new()->parse_source($isf, $result->{generated_ial1}{name});
    my $lowered = FSM::Scheduler::ISF->new()->lower($actor);
    is_deeply(
        sorted([keys %{$result->{generated_ial0}{files}}]),
        ['axi0_capacity_status.fsm'],
        'generator exposes the generated IAL0 .fsm file map',
    );
    is(
        $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'},
        $lowered->{files}{'axi0_capacity_status.fsm'},
        'generated IAL0 text is produced by the public IAL1 scheduler path',
    );
};

subtest 'generated capacity matrix captures acceptance, full, decrement, slots, and same-cycle behavior' => sub {
    my $fsm = generate_sample()->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($fsm, qr/\(\+size[\s\S]*\(axi0_pending_reads_q 3\)/, 'scheduled .fsm declares read pending counter width');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_pending_writes_q 2\)/, 'scheduled .fsm declares write pending counter width');
    like(
        $fsm,
        qr/\(-read_submit_only_occ3\s+<\(& axi0_read_submit \(! axi0_read_complete\) \(== axi0_pending_reads_q 3\)\)[\s\S]*\(<- \(axi0_pending_reads_q 4\)\)[\s\S]*\(<- \(axi0_read_full> 1\)\)[\s\S]*\(<- \(axi0_read_can_accept> 1\)\)/,
        'read submit from one slot below full increments and remains accepted',
    );
    like(
        $fsm,
        qr/\(-read_submit_only_occ4\s+<\(& axi0_read_submit \(! axi0_read_complete\) \(== axi0_pending_reads_q 4\)\)[\s\S]*\(<- \(axi0_pending_reads_q 4\)\)[\s\S]*\(<- \(axi0_read_slots_available> 0\)\)[\s\S]*\(<- \(axi0_read_full> 1\)\)[\s\S]*\(<- \(axi0_read_can_accept> 0\)\)/,
        'read submit at full holds count and blocks acceptance',
    );
    like(
        $fsm,
        qr/\(-read_complete_only_occ1\s+<\(& \(! axi0_read_submit\) axi0_read_complete \(== axi0_pending_reads_q 1\)\)[\s\S]*\(<- \(axi0_pending_reads_q 0\)\)[\s\S]*\(<- \(axi0_pending_reads> 0\)\)[\s\S]*\(<- \(axi0_read_slots_available> 4\)\)/,
        'read completion decrements pending and refreshes slots',
    );
    like(
        $fsm,
        qr/\(-read_submit_complete_occ2\s+<\(& axi0_read_submit axi0_read_complete \(== axi0_pending_reads_q 2\)\)[\s\S]*\(<- \(axi0_pending_reads_q 2\)\)[\s\S]*\(<- \(axi0_pending_reads> 2\)\)/,
        'same-cycle read submit and completion preserves count',
    );
    like(
        $fsm,
        qr/\(-write_submit_only_occ2\s+<\(& axi0_write_submit \(! axi0_write_complete\) \(== axi0_pending_writes_q 2\)\)[\s\S]*\(<- \(axi0_pending_writes_q 2\)\)[\s\S]*\(<- \(axi0_write_can_accept> 0\)\)/,
        'write full depth blocks submit-only acceptance',
    );
    like(
        $fsm,
        qr/\(-write_submit_complete_occ2\s+<\(& axi0_write_submit axi0_write_complete \(== axi0_pending_writes_q 2\)\)[\s\S]*\(<- \(axi0_pending_writes_q 2\)\)[\s\S]*\(<- \(axi0_write_can_accept> 1\)\)/,
        'write full depth accepts submit when a completion occurs in the same cycle',
    );
};

subtest 'report publishes capacity, status outputs, source anchors, artifacts, and residue' => sub {
    my $report = generate_sample()->{report};

    is($report->{schema}, 'fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1', 'report schema is versioned');
    is($report->{layering}{direct_ial2_to_ial0}, 0, 'report rejects direct IAL2-to-IAL0 lowering');
    is($report->{manager}{name}, 'axi0', 'manager name is reported');
    is($report->{manager}{protocol}, 'axi4', 'protocol is reported');
    is($report->{capacity}{read}{max_pending}, 4, 'read max pending is reported');
    is($report->{capacity}{read}{counter_width}, 3, 'read counter width is reported');
    is($report->{capacity}{write}{max_pending}, 2, 'write max pending is reported');
    is($report->{capacity}{write}{counter_width}, 2, 'write counter width is reported');
    is($report->{status_outputs}{read_can_accept}, 'axi0_read_can_accept', 'read can_accept status binding is reported');
    is($report->{abstract_events}{read_submit}, 'axi0_read_submit', 'read submit event is reported');
    is($report->{source_object}{id}, 'axi-manager-capacity-status', 'source object id is reported');
    is($report->{source_object}{intent_name}, 'axi_manager_capacity_status', 'source intent name is reported');
    is_deeply(
        $report->{source_object}{anchors},
        [
            { document => 'IHI0022_L_2025-08', section => 'A1.1' },
            { document => 'IHI0022_L_2025-08', section => 'A1.2' },
            { document => 'IHI0022_L_2025-08', section => 'A5.1' },
        ],
        'source anchors are reported',
    );
    is($report->{generated_artifacts}{ial1}{name}, 'axi0_capacity_status.isf', 'IAL1 artifact is reported');
    is_deeply($report->{generated_artifacts}{ial0}{files}, ['axi0_capacity_status.fsm'], 'IAL0 artifacts are reported');
    is_deeply(
        $report->{blocked_reason_vocabulary},
        [qw(none max_pending_reached unsupported_transaction_kind)],
        'capacity-only blocked reason vocabulary is report-only metadata',
    );

    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{blocking_or_queued_policy}, 'blocking/queued policies remain residue');
    ok($residue{axi_id_ordering_and_response_matching}, 'ID/order/response behavior remains residue');
    ok($residue{profile_aliases_and_full_manager_behavior}, 'profile aliases and full manager behavior remain residue');
    ok($residue{vhdl_backend_or_reroute}, 'VHDL remains residue');
};

subtest 'optional ID-family metadata is report-only and statically validated' => sub {
    my $base = generate_sample();
    my $with_ids = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_id_families());

    is(
        $with_ids->{generated_ial1}{text},
        $base->{generated_ial1}{text},
        'ID-family metadata does not alter generated IAL1 text',
    );
    is_deeply(
        $with_ids->{generated_ial0}{files},
        $base->{generated_ial0}{files},
        'ID-family metadata does not alter generated IAL0 text',
    );

    my $id_families = $with_ids->{report}{id_families};
    is_deeply([sort keys %$id_families], [qw(read write)], 'report publishes read/write ID-family entries');
    is($id_families->{write}{width}, 4, 'write ID width is reported');
    ok($id_families->{write}{present}, 'positive-width write ID family is present');
    is($id_families->{write}{request_id_signal}, 'axi0_awid', 'write request ID signal is reported');
    is($id_families->{write}{response_id_signal}, 'axi0_bid', 'write response ID signal is reported');
    is($id_families->{read}{request_id_signal}, 'axi0_arid', 'read request ID signal is reported');
    is($id_families->{read}{response_id_signal}, 'axi0_rid', 'read response ID signal is reported');
    is_deeply(
        $id_families->{write}{source_anchors},
        sample_contract()->{source}{anchors},
        'ID-family report carries source anchors',
    );

    my $zero_contract = sample_contract_with_id_families();
    for my $family (qw(read write)) {
        $zero_contract->{id_families}{$family} = { width => 0 };
    }
    my $zero_report = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($zero_contract)->{report};
    is($zero_report->{id_families}{read}{width}, 0, 'zero-width read family is reported');
    ok(!$zero_report->{id_families}{read}{present}, 'zero-width read family is absent');
    ok(!exists $zero_report->{id_families}{read}{request_id_signal}, 'zero-width read family omits request ID signal');
    ok(!exists $zero_report->{id_families}{write}{response_id_signal}, 'zero-width write family omits response ID signal');
};

subtest 'optional transaction-envelope metadata emits concrete ID assertions' => sub {
    my $with_transactions = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_transactions());
    my $isf = $with_transactions->{generated_ial1}{text};

    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'concrete read request ID signal is generated as an IAL1 input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'concrete read response ID signal is generated as an IAL1 input');
    unlike($isf, qr/\(input axi0_awid\b/, 'auto-ID write request signal is not generated as an unused input');
    unlike($isf, qr/\(input axi0_bid\b/, 'auto-ID write response signal is not generated as an unused input');
    like($isf, qr/\(transaction axi0_id_response_checks/, 'generated IAL1 adds an assertion-only concrete ID transaction');
    like(
        $isf,
        qr/\(assert \(=> axi0_read_submit \(== axi0_arid 3\)\) "axi0 r0 request ID matches concrete ID"\)/,
        'generated IAL1 asserts the concrete request ID when the read request fires',
    );
    like(
        $isf,
        qr/\(assert \(=> axi0_read_complete \(== axi0_rid 3\)\) "axi0 r0 response ID matches concrete ID"\)/,
        'generated IAL1 asserts the concrete response ID when the read response fires',
    );

    my $fsm = $with_transactions->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_arid 4\)[\s\S]*\(axi0_rid 4\)/, 'generated IAL0 sizes the concrete ID assertion inputs');
    like(
        $fsm,
        qr/\(\+assert[\s\S]*\(axi0_id_response_checks_assert_0 assert \(=> axi0_read_submit \(== axi0_arid 3\)\) "axi0 r0 request ID matches concrete ID"\)/,
        'generated IAL0 carries the request ID assertion',
    );
    like(
        $fsm,
        qr/\(\+assert[\s\S]*\(axi0_id_response_checks_assert_1 assert \(=> axi0_read_complete \(== axi0_rid 3\)\) "axi0 r0 response ID matches concrete ID"\)/,
        'generated IAL0 carries the response ID assertion',
    );

    my $transactions = $with_transactions->{report}{transactions};
    is(scalar(@$transactions), 2, 'report publishes two transaction-envelope entries');
    is($transactions->[0]{kind}, 'write', 'write transaction kind is reported');
    is($transactions->[0]{name}, 'w0', 'write transaction name is reported');
    is($transactions->[0]{tag}, 'wr0', 'write transaction tag is reported');
    is($transactions->[0]{request_event}, 'axi0_write_submit', 'write request event is structural metadata');
    is($transactions->[0]{completion_event}, 'axi0_write_complete', 'write completion event is structural metadata');
    is_deeply($transactions->[0]{id}, { policy => 'auto' }, 'write transaction reports auto ID policy');

    is($transactions->[1]{kind}, 'read', 'read transaction kind is reported');
    is($transactions->[1]{name}, 'r0', 'read transaction name is reported');
    is($transactions->[1]{tag}, 'rd0', 'read transaction tag is reported');
    is($transactions->[1]{request_event}, 'axi0_read_submit', 'read request event is structural metadata');
    is($transactions->[1]{completion_event}, 'axi0_read_complete', 'read completion event is structural metadata');
    is($transactions->[1]{id}{policy}, 'concrete', 'read transaction reports concrete ID policy');
    is($transactions->[1]{id}{value}, 3, 'read transaction reports concrete ID value');
    is($transactions->[1]{id}{family}, 'read', 'read transaction reports matching ID family');
    is($transactions->[1]{id}{family_width}, 4, 'read transaction reports matching ID family width');
    ok($transactions->[1]{id}{fits}, 'read transaction reports concrete ID as fitting the family width');
    is_deeply(
        $transactions->[1]{source_anchors},
        sample_contract()->{source}{anchors},
        'transaction report carries source anchors',
    );

    my $engine = $with_transactions->{report}{id_response_rule_engine};
    is($engine->{mode}, 'concrete_id_assertions', 'report exposes concrete-ID assertion mode');
    is_deeply($engine->{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'report lists only the used concrete-ID inputs');
    is(scalar(@{$engine->{checks}}), 2, 'report exposes request and response concrete-ID checks');
    is_deeply(
        [map { $_->{phase} } @{$engine->{checks}}],
        [qw(request response)],
        'report orders concrete-ID checks by request then response',
    );
    is_deeply(
        [map { $_->{id_signal} } @{$engine->{checks}}],
        [qw(axi0_arid axi0_rid)],
        'report binds concrete-ID checks to request and response ID signals',
    );
    is_deeply(
        [map { $_->{id_value} } @{$engine->{checks}}],
        [3, 3],
        'report binds both concrete-ID checks to the concrete transaction ID value',
    );
    is_deeply(
        $engine->{residue},
        [qw(auto_id_allocation id_release same_id_ordering response_demux)],
        'report keeps dynamic ID behavior as residue',
    );

    my $sv_assertions = sv_assertion_block_for_result($with_transactions);
    my $request_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_read_submit) |-> (axi0_arid == 3))) else $error("axi0 r0 request ID matches concrete ID");';
    my $response_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_read_complete) |-> (axi0_rid == 3))) else $error("axi0 r0 response ID matches concrete ID");';
    like($sv_assertions, qr/\Q$request_assert\E/, 'SystemVerilog assertion backend emits the request concrete-ID property');
    like($sv_assertions, qr/\Q$response_assert\E/, 'SystemVerilog assertion backend emits the response concrete-ID property');
};

subtest 'dynamic transaction-ID metadata reports selected user ownership without generated behavior' => sub {
    my $base = generate_sample();
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_transaction_id());
    my $isf = $result->{generated_ial1}{text};

    is(
        $result->{generated_ial1}{text},
        $base->{generated_ial1}{text},
        'dynamic transaction-ID metadata leaves generated IAL1 unchanged',
    );
    is_deeply(
        $result->{generated_ial0}{files},
        $base->{generated_ial0}{files},
        'dynamic transaction-ID metadata leaves generated IAL0 unchanged',
    );
    unlike($isf, qr/\(input axi0_awid\b/, 'dynamic write request ID signal is not generated before capture behavior is owned');
    unlike($isf, qr/\(input axi0_bid\b/, 'dynamic write response ID signal is not generated before response matching is owned');
    unlike($isf, qr/\(input axi0_arid\b/, 'dynamic read request ID signal is not generated before capture behavior is owned');
    unlike($isf, qr/\(input axi0_rid\b/, 'dynamic read response ID signal is not generated before response matching is owned');
    ok(!exists $result->{report}{id_response_rule_engine}, 'dynamic metadata does not emit a concrete-ID assertion engine');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-dynamic-transaction-id', 'dynamic transaction-ID source object id is preserved');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_dynamic_transaction_id', 'dynamic transaction-ID source intent name is preserved');
    assert_dynamic_transaction_id_report($result->{report}{transactions}, 'generator report');
    my %residue = map { $_->{id} => 1 } @{$result->{report}{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, 'dynamic behavior boundary remains explicit unsupported residue');
};

subtest 'dynamic write response-demux captures AWID and matches BID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_write_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_w0_request\)/, 'dynamic write demux declares the per-transaction write request event');
    like($isf, qr/\(input axi0_write_complete\)/, 'dynamic write demux declares the raw write response event');
    like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'dynamic write demux declares AWID as the captured request ID input');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'dynamic write demux declares BID as the matched response ID input');
    unlike($isf, qr/\(input axi0_w0_complete\b/, 'dynamic write demux does not treat generated completion as an input');
    like($isf, qr/\(output axi0_w0_complete\)/, 'dynamic write demux exposes the matched completion pulse as an output');
    like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'dynamic write demux allocates selected dynamic ID state');
    like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'dynamic write demux allocates single-active busy state');
    like(
        $isf,
        qr/\(rule axi0_w0_dynamic_id_capture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) axi0_w0_complete\)\) \(! axi0_w0_dynamic_busy_q\)\)\s+\(axi0_w0_dynamic_id_q axi0_awid\)\s+\(axi0_w0_dynamic_busy_q 1\)\)/,
        'dynamic write demux captures AWID only for admitted not-busy requests',
    );
    like(
        $isf,
        qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)\s+\(pulse axi0_w0_complete\)\)/,
        'dynamic write demux pulses completion only for matching active BID responses',
    );
    like(
        $isf,
        qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) axi0_w0_complete\)\) axi0_w0_complete axi0_w0_dynamic_busy_q\)\s+\(axi0_w0_dynamic_id_q axi0_awid\)\s+\(axi0_w0_dynamic_busy_q 1\)\)/,
        'dynamic write demux recaptures AWID on same-cycle matched completion and admitted request',
    );
    like(
        $isf,
        qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)\s+\(axi0_w0_dynamic_busy_q 0\)\)/,
        'dynamic write demux releases the single-active busy state only without a same-cycle request',
    );
    like($isf, qr/"axi0 write dynamic request is idle or releasing active captured ID"/, 'dynamic write demux emits idle-or-releasing assertion');
    like($isf, qr/"axi0 write dynamic response matches active captured ID"/, 'dynamic write demux emits active BID-match assertion');
    like($isf, qr/"axi0 w0 dynamic completion releases active captured ID"/, 'dynamic write demux emits active-completion assertion');

    assert_dynamic_write_response_demux_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_awid 4\)/, 'scheduled .fsm declares AWID width');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_bid 4\)/, 'scheduled .fsm declares BID width');
    like($fsm, qr/\(-axi0_w0_dynamic_id_capture\s+<\(& \(& axi0_w0_request/, 'scheduled .fsm lowers the dynamic capture rule');
    like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled .fsm lowers the dynamic BID match rule');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled .fsm lowers the dynamic release-recapture rule');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled .fsm lowers the dynamic release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_awid\b/, 'SystemVerilog declares AWID as a 4-bit input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog declares BID as a 4-bit input');
    like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_dynamic_id_q\b/, 'SystemVerilog declares selected dynamic ID state');
    like($hdl, qr/\breg\s+axi0_w0_dynamic_busy_q\b/, 'SystemVerilog declares dynamic busy state');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers the dynamic BID-match guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 write dynamic request is idle or releasing active captured ID/, 'assertion backend emits idle-or-releasing dynamic assertion');
    like($sv_assertions, qr/axi0 write dynamic response matches active captured ID/, 'assertion backend emits active BID-match dynamic assertion');
    like($sv_assertions, qr/axi0 w0 dynamic completion releases active captured ID/, 'assertion backend emits completion-active dynamic assertion');
};

subtest 'multiple dynamic write response-demux captures AWID and matches BID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_write_response_demux_multi());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_w0_request\)/, 'multiple dynamic write demux declares w0 request event');
    like($isf, qr/\(input axi0_w1_request\)/, 'multiple dynamic write demux declares w1 request event');
    like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'multiple dynamic write demux declares AWID input');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'multiple dynamic write demux declares BID input');
    like($isf, qr/\(output axi0_w0_complete\)/, 'multiple dynamic write demux exposes w0 matched completion');
    like($isf, qr/\(output axi0_w1_complete\)/, 'multiple dynamic write demux exposes w1 matched completion');
    like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'multiple dynamic write demux allocates w0 selected ID state');
    like($isf, qr/\(var axi0_w1_dynamic_id_q \(width 4\)\)/, 'multiple dynamic write demux allocates w1 selected ID state');
    like($isf, qr/\(rule axi0_w0_dynamic_id_capture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) \(! axi0_w0_dynamic_busy_q\) \(! \(& axi0_w1_request/, 'multiple dynamic write demux gates w0 capture against sibling request');
    like($isf, qr/\(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)/, 'multiple dynamic write demux gates w0 capture against active sibling ID');
    like($isf, qr/\(rule axi0_w1_dynamic_id_capture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) \(! axi0_w1_dynamic_busy_q\) \(! \(& axi0_w0_request/, 'multiple dynamic write demux gates w1 capture against sibling request');
    like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'multiple dynamic write demux matches w0 BID');
    like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'multiple dynamic write demux matches w1 BID');
    like($isf, qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w0_complete axi0_w0_dynamic_busy_q \(! \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\) \(! \(& axi0_w1_dynamic_busy_q \(== axi0_w1_dynamic_id_q axi0_awid\)\)\)\)\s+\(axi0_w0_dynamic_id_q axi0_awid\)\s+\(axi0_w0_dynamic_busy_q 1\)\)/, 'multiple dynamic write demux recaptures w0 on same-cycle release with sibling guards');
    like($isf, qr/\(rule axi0_w1_dynamic_id_release_recapture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w1_complete axi0_w1_dynamic_busy_q \(! \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\) \(! \(& axi0_w0_dynamic_busy_q \(== axi0_w0_dynamic_id_q axi0_awid\)\)\)\)\s+\(axi0_w1_dynamic_id_q axi0_awid\)\s+\(axi0_w1_dynamic_busy_q 1\)\)/, 'multiple dynamic write demux recaptures w1 on same-cycle release with sibling guards');
    like($isf, qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)\s+\(axi0_w0_dynamic_busy_q 0\)\)/, 'multiple dynamic write demux releases w0 only without same-cycle own request');
    like($isf, qr/\(rule axi0_w1_dynamic_id_release \(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)\s+\(axi0_w1_dynamic_busy_q 0\)\)/, 'multiple dynamic write demux releases w1 only without same-cycle own request');
    like($isf, qr/"axi0 write dynamic request is idle or releasing active captured ID"/, 'multiple dynamic write demux emits idle-or-releasing request assertions');
    like($isf, qr/"axi0 write dynamic requests are mutually exclusive"/, 'multiple dynamic write demux emits request onehot assertion');
    like($isf, qr/"axi0 write dynamic active IDs are unique"/, 'multiple dynamic write demux emits active-ID uniqueness assertion');
    like($isf, qr/"axi0 write dynamic response matches at most one captured ID"/, 'multiple dynamic write demux emits response unique-match assertion');

    assert_dynamic_write_response_demux_multi_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled .fsm lowers multi dynamic w0 BID match');
    like($fsm, qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_dynamic_busy_q \(== axi0_bid axi0_w1_dynamic_id_q\)\)/, 'scheduled .fsm lowers multi dynamic w1 BID match');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled .fsm lowers multi dynamic w0 release-recapture');
    like($fsm, qr/\(-axi0_w1_dynamic_id_release_recapture\s+<\(& \(& axi0_w1_request/, 'scheduled .fsm lowers multi dynamic w1 release-recapture');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled .fsm lowers multi dynamic w0 release-only rule');
    like($fsm, qr/\(-axi0_w1_dynamic_id_release\s+<\(& axi0_w1_complete axi0_w1_dynamic_busy_q \(! axi0_w1_request\)\)/, 'scheduled .fsm lowers multi dynamic w1 release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_awid\b/, 'SystemVerilog declares AWID for multiple dynamic write');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog declares BID for multiple dynamic write');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic w0 BID match');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w1_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w1_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic w1 BID match');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 write dynamic requests are mutually exclusive/, 'assertion backend emits multi dynamic request onehot assertion');
    like($sv_assertions, qr/axi0 write dynamic active IDs are unique/, 'assertion backend emits multi dynamic active-ID assertion');
    like($sv_assertions, qr/axi0 write dynamic response matches at most one captured ID/, 'assertion backend emits multi dynamic response unique-match assertion');
};

subtest 'mixed dynamic/static write response-demux captures AWID and matches static BID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_mixed_dynamic_static_write_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_w0_request\)/, 'mixed dynamic/static write demux declares dynamic request event');
    like($isf, qr/\(input axi0_w1_request\)/, 'mixed dynamic/static write demux declares static request event');
    like($isf, qr/\(input axi0_awid \(width 4\)\)/, 'mixed dynamic/static write demux declares AWID');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'mixed dynamic/static write demux declares BID');
    like($isf, qr/\(output axi0_w0_complete\)/, 'mixed dynamic/static write demux exposes dynamic completion');
    like($isf, qr/\(output axi0_w1_complete\)/, 'mixed dynamic/static write demux exposes static completion');
    like($isf, qr/\(var axi0_w0_dynamic_id_q \(width 4\)\)/, 'mixed dynamic/static write demux allocates dynamic selected-ID state');
    like($isf, qr/\(var axi0_w0_dynamic_busy_q \(width 1\)\)/, 'mixed dynamic/static write demux allocates dynamic busy state');
    like($isf, qr/\(var axi0_w1_static_busy_q \(width 1\)\)/, 'mixed dynamic/static write demux allocates static busy state');
    like($isf, qr/\(rule axi0_w0_dynamic_id_capture\b/, 'mixed dynamic/static write demux emits dynamic capture rule');
    like($isf, qr/\(! \(& axi0_w1_request/, 'mixed dynamic/static write demux gates dynamic capture against static request');
    like($isf, qr/\(! \(== axi0_awid 4'd3\)\)/, 'mixed dynamic/static write demux gates dynamic capture against static concrete ID');
    like($isf, qr/\(axi0_w0_dynamic_id_q axi0_awid\)/, 'mixed dynamic/static write demux captures dynamic AWID');
    like($isf, qr/\(axi0_w0_dynamic_busy_q 1\)/, 'mixed dynamic/static write demux marks dynamic request busy');
    like($isf, qr/\(rule axi0_w1_static_busy_capture\b/, 'mixed dynamic/static write demux emits static capture rule');
    like($isf, qr/\(& \(& axi0_w1_request/, 'mixed dynamic/static write demux captures admitted static request');
    like($isf, qr/\(! axi0_w1_static_busy_q\)/, 'mixed dynamic/static write demux requires static transaction idle');
    like($isf, qr/\(! \(& axi0_w0_request/, 'mixed dynamic/static write demux gates static capture against dynamic request');
    like($isf, qr/\(axi0_w1_static_busy_q 1\)/, 'mixed dynamic/static write demux marks static request busy');
    like(
        $isf,
        qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)\s+\(pulse axi0_w0_complete\)\)/,
        'mixed dynamic/static write demux pulses dynamic completion on matching active BID',
    );
    like(
        $isf,
        qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_static_busy_q \(== axi0_bid 4'd3\)\)\s+\(pulse axi0_w1_complete\)\)/,
        'mixed dynamic/static write demux pulses static completion on matching concrete BID',
    );
    like(
        $isf,
        qr/\(rule axi0_w0_dynamic_id_release_recapture \(& \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w0_complete axi0_w0_dynamic_busy_q \(! \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\) \(! \(== axi0_awid 4'd3\)\)\)\s+\(axi0_w0_dynamic_id_q axi0_awid\)\s+\(axi0_w0_dynamic_busy_q 1\)\)/,
        'mixed dynamic/static write demux recaptures dynamic ID on same-cycle dynamic completion',
    );
    like(
        $isf,
        qr/\(rule axi0_w1_static_busy_release_recapture \(& \(& axi0_w1_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\) axi0_w1_complete axi0_w1_static_busy_q \(! \(& axi0_w0_request \(\| \(< axi0_pending_writes_q 2\) \(\| axi0_w0_complete axi0_w1_complete\)\)\)\)\)\s+\(axi0_w1_static_busy_q 1\)\)/,
        'mixed dynamic/static write demux recaptures static busy on same-cycle static completion',
    );
    like(
        $isf,
        qr/\(rule axi0_w0_dynamic_id_release \(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)\s+\(axi0_w0_dynamic_busy_q 0\)\)/,
        'mixed dynamic/static write demux releases dynamic busy only without same-cycle dynamic request',
    );
    like(
        $isf,
        qr/\(rule axi0_w1_static_busy_release \(& axi0_w1_complete axi0_w1_static_busy_q \(! axi0_w1_request\)\)\s+\(axi0_w1_static_busy_q 0\)\)/,
        'mixed dynamic/static write demux releases static busy only without same-cycle static request',
    );
    like($isf, qr/"axi0 write dynamic request is idle or releasing active captured ID"/, 'mixed dynamic/static write demux emits dynamic idle-or-releasing assertion');
    like($isf, qr/"axi0 write static request is idle or releasing active concrete ID"/, 'mixed dynamic/static write demux emits static idle-or-releasing assertion');
    like($isf, qr/"axi0 write mixed dynamic\/static requests are mutually exclusive"/, 'mixed dynamic/static write demux emits mixed request onehot assertion');
    like($isf, qr/"axi0 w0 dynamic request does not use static concrete ID"/, 'mixed dynamic/static write demux emits dynamic request static-ID reservation assertion');
    like($isf, qr/"axi0 write mixed dynamic\/static response matches active transaction"/, 'mixed dynamic/static write demux emits active response assertion');
    like($isf, qr/"axi0 write mixed dynamic\/static response matches at most one transaction"/, 'mixed dynamic/static write demux emits unique response assertion');
    like($isf, qr/"axi0 w1 static completion releases active concrete ID"/, 'mixed dynamic/static write demux emits static completion-active assertion');

    assert_mixed_dynamic_static_write_response_demux_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_dynamic_busy_q \(== axi0_bid axi0_w0_dynamic_id_q\)\)/, 'scheduled .fsm lowers mixed dynamic BID match');
    like($fsm, qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_static_busy_q \(== axi0_bid 4'd3\)\)/, 'scheduled .fsm lowers mixed static BID match');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release_recapture\s+<\(& \(& axi0_w0_request/, 'scheduled .fsm lowers mixed dynamic release-recapture');
    like($fsm, qr/\(-axi0_w1_static_busy_release_recapture\s+<\(& \(& axi0_w1_request/, 'scheduled .fsm lowers mixed static release-recapture');
    like($fsm, qr/\(-axi0_w0_dynamic_id_release\s+<\(& axi0_w0_complete axi0_w0_dynamic_busy_q \(! axi0_w0_request\)\)/, 'scheduled .fsm lowers mixed dynamic release-only rule');
    like($fsm, qr/\(-axi0_w1_static_busy_release\s+<\(& axi0_w1_complete axi0_w1_static_busy_q \(! axi0_w1_request\)\)/, 'scheduled .fsm lowers mixed static release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_dynamic_id_q\b/, 'SystemVerilog declares mixed dynamic ID state');
    like($hdl, qr/\breg\s+axi0_w1_static_busy_q\b/, 'SystemVerilog declares mixed static busy state');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_dynamic_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_dynamic_id_q\)/, 'SystemVerilog lowers mixed dynamic BID-match guard');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w1_static_busy_q\s*&\s*\(axi0_bid\s*==\s*4'd3\)/, 'SystemVerilog lowers mixed static BID-match guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 write mixed dynamic\/static requests are mutually exclusive/, 'assertion backend emits mixed request onehot assertion');
    like($sv_assertions, qr/axi0 w0 dynamic request does not use static concrete ID/, 'assertion backend emits request static-ID reservation assertion');
    like($sv_assertions, qr/axi0 write mixed dynamic\/static response matches at most one transaction/, 'assertion backend emits response unique-match assertion');
};

subtest 'mixed dynamic/static read response-demux captures ARID and matches static RID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_mixed_dynamic_static_read_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'mixed dynamic/static read demux declares dynamic request event');
    like($isf, qr/\(input axi0_r1_request\)/, 'mixed dynamic/static read demux declares static request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'mixed dynamic/static read demux declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'mixed dynamic/static read demux declares RID');
    like($isf, qr/\(output axi0_r0_complete\)/, 'mixed dynamic/static read demux exposes dynamic completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'mixed dynamic/static read demux exposes static completion');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'mixed dynamic/static read demux allocates dynamic selected-ID state');
    like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'mixed dynamic/static read demux allocates dynamic busy state');
    like($isf, qr/\(var axi0_r1_static_busy_q \(width 1\)\)/, 'mixed dynamic/static read demux allocates static busy state');
    like($isf, qr/\(rule axi0_r0_dynamic_id_capture\b/, 'mixed dynamic/static read demux emits dynamic capture rule');
    like($isf, qr/\(! \(& axi0_r1_request/, 'mixed dynamic/static read demux gates dynamic capture against static request');
    like($isf, qr/\(! \(== axi0_arid 4'd3\)\)/, 'mixed dynamic/static read demux gates dynamic capture against static concrete ID');
    like($isf, qr/\(axi0_r0_dynamic_id_q axi0_arid\)/, 'mixed dynamic/static read demux captures dynamic ARID');
    like($isf, qr/\(axi0_r0_dynamic_busy_q 1\)/, 'mixed dynamic/static read demux marks dynamic request busy');
    like($isf, qr/\(rule axi0_r1_static_busy_capture\b/, 'mixed dynamic/static read demux emits static capture rule');
    like($isf, qr/\(& \(& axi0_r1_request/, 'mixed dynamic/static read demux captures admitted static request');
    like($isf, qr/\(! axi0_r1_static_busy_q\)/, 'mixed dynamic/static read demux requires static transaction idle');
    like($isf, qr/\(! \(& axi0_r0_request/, 'mixed dynamic/static read demux gates static capture against dynamic request');
    like($isf, qr/\(axi0_r1_static_busy_q 1\)/, 'mixed dynamic/static read demux marks static request busy');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\s+\(pulse axi0_r0_complete\)\)/,
        'mixed dynamic/static read demux pulses dynamic completion on matching active RID',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\s+\(pulse axi0_r1_complete\)\)/,
        'mixed dynamic/static read demux pulses static completion on matching concrete RID',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_static_busy_release \(& axi0_r1_complete axi0_r1_static_busy_q\)\s+\(axi0_r1_static_busy_q 0\)\)/,
        'mixed dynamic/static read demux releases static busy state on generated completion',
    );
    like($isf, qr/"axi0 read mixed dynamic\/static requests are mutually exclusive"/, 'mixed dynamic/static read demux emits mixed request onehot assertion');
    like($isf, qr/"axi0 r0 dynamic request does not use static concrete ID"/, 'mixed dynamic/static read demux emits dynamic request static-ID reservation assertion');
    like($isf, qr/"axi0 read mixed dynamic\/static response matches active transaction"/, 'mixed dynamic/static read demux emits active response assertion');
    like($isf, qr/"axi0 read mixed dynamic\/static response matches at most one transaction"/, 'mixed dynamic/static read demux emits unique response assertion');
    like($isf, qr/"axi0 r1 static completion releases active concrete ID"/, 'mixed dynamic/static read demux emits static completion-active assertion');

    assert_mixed_dynamic_static_read_response_demux_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled .fsm lowers mixed dynamic RID match');
    like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)/, 'scheduled .fsm lowers mixed static RID match');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares mixed read dynamic ID state');
    like($hdl, qr/\breg\s+axi0_r1_static_busy_q\b/, 'SystemVerilog declares mixed read static busy state');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers mixed dynamic RID-match guard');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)/, 'SystemVerilog lowers mixed static RID-match guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'assertion backend emits mixed read request onehot assertion');
    like($sv_assertions, qr/axi0 r0 dynamic request does not use static concrete ID/, 'assertion backend emits mixed read request static-ID reservation assertion');
    like($sv_assertions, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'assertion backend emits mixed read response unique-match assertion');
};

subtest 'mixed dynamic/static read burst-last response-demux gates completion with RLAST' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_mixed_dynamic_static_read_response_demux_burst_last());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'mixed dynamic/static read RLAST demux declares dynamic request event');
    like($isf, qr/\(input axi0_r1_request\)/, 'mixed dynamic/static read RLAST demux declares static request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'mixed dynamic/static read RLAST demux declares ARID');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'mixed dynamic/static read RLAST demux declares RID');
    like($isf, qr/\(input axi0_rlast\)/, 'mixed dynamic/static read RLAST demux declares RLAST');
    like($isf, qr/\(output axi0_r0_complete\)/, 'mixed dynamic/static read RLAST demux exposes dynamic completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'mixed dynamic/static read RLAST demux exposes static completion');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'mixed dynamic/static read RLAST demux allocates dynamic selected-ID state');
    like($isf, qr/\(var axi0_r1_static_busy_q \(width 1\)\)/, 'mixed dynamic/static read RLAST demux allocates static busy state');
    like($isf, qr/\(! \(== axi0_arid 4'd3\)\)/, 'mixed dynamic/static read RLAST demux gates dynamic capture against static concrete ID');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/,
        'mixed dynamic/static read RLAST demux pulses dynamic completion on matching final beat',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/,
        'mixed dynamic/static read RLAST demux pulses static completion on matching final beat',
    );
    like(
        $isf,
        qr/\(assert \(\| \(! axi0_read_complete\) \(\| \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\) \(& axi0_r1_static_busy_q \(== axi0_rid 4'd3\)\)\)\) "axi0 read mixed dynamic\/static response matches active transaction"\)/,
        'mixed dynamic/static read RLAST demux keeps raw RID active-match assertion',
    );
    like($isf, qr/"axi0 read mixed dynamic\/static response matches at most one transaction"/, 'mixed dynamic/static read RLAST demux emits raw response unique-match assertion');
    like($isf, qr/"axi0 r1 static completion releases active concrete ID"/, 'mixed dynamic/static read RLAST demux emits static completion-active assertion');

    assert_mixed_dynamic_static_read_rlast_response_demux_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled .fsm lowers mixed dynamic RID/RLAST match');
    like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_static_busy_q \(== axi0_rid 4'd3\) axi0_rlast\)/, 'scheduled .fsm lowers mixed static RID/RLAST match');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog declares ARID for mixed read RLAST');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID for mixed read RLAST');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog declares RLAST for mixed read RLAST');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers mixed dynamic RID/RLAST guard');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_static_busy_q\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers mixed static RID/RLAST guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read mixed dynamic\/static requests are mutually exclusive/, 'assertion backend emits mixed read RLAST request onehot assertion');
    like($sv_assertions, qr/axi0 read mixed dynamic\/static response matches at most one transaction/, 'assertion backend emits mixed read RLAST response unique-match assertion');
};

subtest 'dynamic read response-demux captures ARID and matches single-beat RID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read demux declares the per-transaction read request event');
    like($isf, qr/\(input axi0_read_complete\)/, 'dynamic read demux declares the raw read response event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read demux declares ARID as the captured request ID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read demux declares RID as the matched response ID input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read demux does not treat generated completion as an input');
    like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read demux exposes the matched completion pulse as an output');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'dynamic read demux allocates selected dynamic ID state');
    like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'dynamic read demux allocates single-active busy state');
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) \(! axi0_r0_dynamic_busy_q\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/,
        'dynamic read demux captures ARID only for admitted not-busy requests',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\s+\(pulse axi0_r0_complete\)\)/,
        'dynamic read demux pulses completion only for matching active RID responses',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) axi0_r0_complete axi0_r0_dynamic_busy_q\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/,
        'dynamic read demux recaptures ARID on same-cycle matched completion and admitted request',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)\s+\(axi0_r0_dynamic_busy_q 0\)\)/,
        'dynamic read demux releases the single-active busy state only without a same-cycle request',
    );
    like($isf, qr/"axi0 read dynamic request is idle or releasing active captured ID"/, 'dynamic read demux emits idle-or-releasing assertion');
    like($isf, qr/"axi0 read dynamic response matches active captured ID"/, 'dynamic read demux emits active RID-match assertion');
    like($isf, qr/"axi0 r0 dynamic completion releases active captured ID"/, 'dynamic read demux emits active-completion assertion');

    assert_dynamic_read_response_demux_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_arid 4\)/, 'scheduled .fsm declares ARID width');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rid 4\)/, 'scheduled .fsm declares RID width');
    like($fsm, qr/\(-axi0_r0_dynamic_id_capture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers the dynamic read capture rule');
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled .fsm lowers the dynamic RID match rule');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers the dynamic read release-recapture rule');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled .fsm lowers the dynamic read release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog declares ARID as a 4-bit input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID as a 4-bit input');
    like($hdl, qr/\breg\s+\[3:0\]\s+axi0_r0_dynamic_id_q\b/, 'SystemVerilog declares selected dynamic read ID state');
    like($hdl, qr/\breg\s+axi0_r0_dynamic_busy_q\b/, 'SystemVerilog declares dynamic read busy state');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers the dynamic RID-match guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'assertion backend emits idle-or-releasing dynamic read assertion');
    like($sv_assertions, qr/axi0 read dynamic response matches active captured ID/, 'assertion backend emits active RID-match dynamic assertion');
    like($sv_assertions, qr/axi0 r0 dynamic completion releases active captured ID/, 'assertion backend emits completion-active dynamic read assertion');
};

subtest 'multiple dynamic read response-demux captures ARID and matches single-beat RID' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_response_demux_multi());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read demux declares r0 request event');
    like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read demux declares r1 request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read demux declares ARID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read demux declares RID input');
    like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read demux exposes r0 matched completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read demux exposes r1 matched completion');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read demux allocates r0 selected ID state');
    like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read demux allocates r1 selected ID state');
    like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) \(! axi0_r0_dynamic_busy_q\) \(! \(& axi0_r1_request/, 'multiple dynamic read demux gates r0 capture against sibling request');
    like($isf, qr/\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multiple dynamic read demux gates r0 capture against active sibling ID');
    like($isf, qr/\(rule axi0_r1_dynamic_id_capture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) \(! axi0_r1_dynamic_busy_q\) \(! \(& axi0_r0_request/, 'multiple dynamic read demux gates r1 capture against sibling request');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'multiple dynamic read demux matches r0 RID');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'multiple dynamic read demux matches r1 RID');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/, 'multiple dynamic read demux recaptures r0 on same-cycle release with sibling guards');
    like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_dynamic_busy_q \(! \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r1_dynamic_id_q axi0_arid\)\s+\(axi0_r1_dynamic_busy_q 1\)\)/, 'multiple dynamic read demux recaptures r1 on same-cycle release with sibling guards');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)\s+\(axi0_r0_dynamic_busy_q 0\)\)/, 'multiple dynamic read demux releases r0 only without same-cycle own request');
    like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)\s+\(axi0_r1_dynamic_busy_q 0\)\)/, 'multiple dynamic read demux releases r1 only without same-cycle own request');
    like($isf, qr/"axi0 read dynamic request is idle or releasing active captured ID"/, 'multiple dynamic read demux emits idle-or-releasing request assertions');
    like($isf, qr/"axi0 read dynamic requests are mutually exclusive"/, 'multiple dynamic read demux emits request onehot assertion');
    like($isf, qr/"axi0 read dynamic active IDs are unique"/, 'multiple dynamic read demux emits active-ID uniqueness assertion');
    like($isf, qr/"axi0 read dynamic response matches at most one captured ID"/, 'multiple dynamic read demux emits response unique-match assertion');

    assert_dynamic_read_response_demux_multi_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)/, 'scheduled .fsm lowers multi dynamic r0 RID match');
    like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)/, 'scheduled .fsm lowers multi dynamic r1 RID match');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers multi dynamic r0 release-recapture');
    like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled .fsm lowers multi dynamic r1 release-recapture');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled .fsm lowers multi dynamic r0 release-only rule');
    like($fsm, qr/\(-axi0_r1_dynamic_id_release\s+<\(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'scheduled .fsm lowers multi dynamic r1 release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog declares ARID for multiple dynamic read');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID for multiple dynamic read');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic r0 RID match');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)/, 'SystemVerilog lowers multi dynamic r1 RID match');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read dynamic requests are mutually exclusive/, 'assertion backend emits multi dynamic read request onehot assertion');
    like($sv_assertions, qr/axi0 read dynamic active IDs are unique/, 'assertion backend emits multi dynamic read active-ID assertion');
    like($sv_assertions, qr/axi0 read dynamic response matches at most one captured ID/, 'assertion backend emits multi dynamic read response unique-match assertion');
};

subtest 'multiple dynamic read response-demux captures ARID and completes on burst-last RID/RLAST' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_response_demux_multi_burst_last());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'multiple dynamic read RLAST demux declares r0 request event');
    like($isf, qr/\(input axi0_r1_request\)/, 'multiple dynamic read RLAST demux declares r1 request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'multiple dynamic read RLAST demux declares ARID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'multiple dynamic read RLAST demux declares RID input');
    like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic read RLAST demux declares RLAST input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'multiple dynamic read RLAST demux treats r0 completion as generated');
    unlike($isf, qr/\(input axi0_r1_complete\b/, 'multiple dynamic read RLAST demux treats r1 completion as generated');
    like($isf, qr/\(output axi0_r0_complete\)/, 'multiple dynamic read RLAST demux exposes r0 matched last-beat completion');
    like($isf, qr/\(output axi0_r1_complete\)/, 'multiple dynamic read RLAST demux exposes r1 matched last-beat completion');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read RLAST demux allocates r0 selected ID state');
    like($isf, qr/\(var axi0_r1_dynamic_id_q \(width 4\)\)/, 'multiple dynamic read RLAST demux allocates r1 selected ID state');
    like($isf, qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) \(! axi0_r0_dynamic_busy_q\) \(! \(& axi0_r1_request/, 'multiple dynamic read RLAST demux gates r0 capture against sibling request');
    like($isf, qr/\(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)/, 'multiple dynamic read RLAST demux gates r0 capture against active sibling ID');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic read RLAST demux pulses r0 completion only on matching last beat');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic read RLAST demux pulses r1 completion only on matching last beat');
    like($isf, qr/\(assert \(\| \(! axi0_read_complete\) \(\| \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\) \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\)\) "axi0 read dynamic response matches active captured ID"\)/, 'multiple dynamic read RLAST demux keeps active-response assertion on raw RID match');
    like($isf, qr/"axi0 read dynamic response matches at most one captured ID"/, 'multiple dynamic read RLAST demux emits raw RID unique-match assertion');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r0_complete axi0_r0_dynamic_busy_q \(! \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r1_dynamic_busy_q \(== axi0_r1_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/, 'multiple dynamic read RLAST demux recaptures r0 on same-cycle final completion with sibling guards');
    like($isf, qr/\(rule axi0_r1_dynamic_id_release_recapture \(& \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\) axi0_r1_complete axi0_r1_dynamic_busy_q \(! \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)\) \(! \(& axi0_r0_dynamic_busy_q \(== axi0_r0_dynamic_id_q axi0_arid\)\)\)\)\s+\(axi0_r1_dynamic_id_q axi0_arid\)\s+\(axi0_r1_dynamic_busy_q 1\)\)/, 'multiple dynamic read RLAST demux recaptures r1 on same-cycle final completion with sibling guards');
    like($isf, qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)\s+\(axi0_r0_dynamic_busy_q 0\)\)/, 'multiple dynamic read RLAST demux releases r0 busy state only without same-cycle r0 request');
    like($isf, qr/\(rule axi0_r1_dynamic_id_release \(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)\s+\(axi0_r1_dynamic_busy_q 0\)\)/, 'multiple dynamic read RLAST demux releases r1 busy state only without same-cycle r1 request');

    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_arid 4\)/, 'scheduled .fsm declares ARID width for multiple dynamic RLAST demux');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rid 4\)/, 'scheduled .fsm declares RID width for multiple dynamic RLAST demux');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rlast 1\)/, 'scheduled .fsm declares RLAST width for multiple dynamic RLAST demux');
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled .fsm lowers multi dynamic r0 RID/RLAST match');
    like($fsm, qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)/, 'scheduled .fsm lowers multi dynamic r1 RID/RLAST match');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers multi dynamic RLAST r0 release-recapture');
    like($fsm, qr/\(-axi0_r1_dynamic_id_release_recapture\s+<\(& \(& axi0_r1_request/, 'scheduled .fsm lowers multi dynamic RLAST r1 release-recapture');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled .fsm lowers multi dynamic RLAST r0 release-only guard');
    like($fsm, qr/\(-axi0_r1_dynamic_id_release\s+<\(& axi0_r1_complete axi0_r1_dynamic_busy_q \(! axi0_r1_request\)\)/, 'scheduled .fsm lowers multi dynamic RLAST r1 release-only guard');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog declares ARID for multiple dynamic RLAST demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID for multiple dynamic RLAST demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog declares RLAST for multiple dynamic read demux');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi dynamic r0 RID/RLAST guard');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r1_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r1_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers multi dynamic r1 RID/RLAST guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read dynamic requests are mutually exclusive/, 'assertion backend emits multi dynamic RLAST request onehot assertion');
    like($sv_assertions, qr/axi0 read dynamic active IDs are unique/, 'assertion backend emits multi dynamic RLAST active-ID assertion');
    like($sv_assertions, qr/axi0 read dynamic response matches at most one captured ID/, 'assertion backend emits multi dynamic RLAST raw response unique-match assertion');
};

subtest 'dynamic read response-demux captures ARID and matches burst-last RID/RLAST' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_response_demux_burst_last());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read RLAST demux declares the per-transaction read request event');
    like($isf, qr/\(input axi0_read_complete\)/, 'dynamic read RLAST demux declares the raw read response beat event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read RLAST demux declares ARID as the captured request ID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read RLAST demux declares RID as the matched response ID input');
    like($isf, qr/\(input axi0_rlast\)/, 'dynamic read RLAST demux declares RLAST as the generated last-signal input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read RLAST demux does not treat generated completion as an input');
    like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read RLAST demux exposes the matched last-beat completion pulse as an output');
    like($isf, qr/\(var axi0_r0_dynamic_id_q \(width 4\)\)/, 'dynamic read RLAST demux allocates selected dynamic ID state');
    like($isf, qr/\(var axi0_r0_dynamic_busy_q \(width 1\)\)/, 'dynamic read RLAST demux allocates single-active busy state');
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_capture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) \(! axi0_r0_dynamic_busy_q\)\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/,
        'dynamic read RLAST demux captures ARID only for admitted not-busy requests',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/,
        'dynamic read RLAST demux pulses completion only for matching active RID last beats',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) axi0_r0_complete axi0_r0_dynamic_busy_q\)\s+\(axi0_r0_dynamic_id_q axi0_arid\)\s+\(axi0_r0_dynamic_busy_q 1\)\)/,
        'dynamic read RLAST demux recaptures ARID on same-cycle matched last-beat completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_release \(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)\s+\(axi0_r0_dynamic_busy_q 0\)\)/,
        'dynamic read RLAST demux release-only excludes same-cycle requests',
    );
    like(
        $isf,
        qr/\(assert \(\| \(! axi0_read_complete\) \(& axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\) "axi0 read dynamic response matches active captured ID"\)/,
        'dynamic read RLAST demux keeps active-response assertion on raw RID match without RLAST gating',
    );
    like($isf, qr/"axi0 read dynamic request is idle or releasing active captured ID"/, 'dynamic read RLAST demux emits idle-or-releasing assertion');
    like($isf, qr/"axi0 r0 dynamic completion releases active captured ID"/, 'dynamic read RLAST demux emits active-completion assertion');

    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'generator report');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_arid 4\)/, 'scheduled .fsm declares ARID width for dynamic RLAST demux');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rid 4\)/, 'scheduled .fsm declares RID width for dynamic RLAST demux');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rlast 1\)/, 'scheduled .fsm declares RLAST width for dynamic RLAST demux');
    like($fsm, qr/\(-axi0_r0_dynamic_id_capture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers the dynamic RLAST capture rule');
    like($fsm, qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)/, 'scheduled .fsm lowers the dynamic RID/RLAST match rule');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release_recapture\s+<\(& \(& axi0_r0_request/, 'scheduled .fsm lowers the dynamic RLAST release-recapture rule');
    like($fsm, qr/\(-axi0_r0_dynamic_id_release\s+<\(& axi0_r0_complete axi0_r0_dynamic_busy_q \(! axi0_r0_request\)\)/, 'scheduled .fsm lowers the dynamic RLAST release-only rule');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_arid\b/, 'SystemVerilog declares ARID as a 4-bit input for dynamic RLAST demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID as a 4-bit input for dynamic RLAST demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog declares RLAST as a one-bit input for dynamic RLAST demux');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_dynamic_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_dynamic_id_q\)\s*&\s*axi0_rlast/, 'SystemVerilog lowers the dynamic RID/RLAST last-beat guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read dynamic request is idle or releasing active captured ID/, 'assertion backend emits idle-or-releasing dynamic RLAST assertion');
    like($sv_assertions, qr/axi0 read dynamic response matches active captured ID/, 'assertion backend emits raw active RID-match dynamic RLAST assertion');
    like($sv_assertions, qr/axi0 r0 dynamic completion releases active captured ID/, 'assertion backend emits completion-active dynamic RLAST assertion');
};

subtest 'dynamic read-data contract consumes generated dynamic single-beat read demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_r0_request\)/, 'dynamic read-data declares the dynamic read request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'dynamic read-data declares ARID as the captured request ID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'dynamic read-data declares RID as the response ID input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic read-data declares RRESP as a generated input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic read-data keeps generated completion internal');
    like($isf, qr/\(output axi0_r0_complete\)/, 'dynamic read-data exposes matched dynamic completion output');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'dynamic read-data declares scalar data output');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'dynamic read-data declares scalar status output');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\s+\(pulse axi0_r0_complete\)\)/,
        'dynamic read-data keeps generated single-beat dynamic RID demux',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_dynamic_id_release_recapture \(& \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\) axi0_r0_complete axi0_r0_dynamic_busy_q\)/,
        'dynamic read-data keeps generated single-beat release-recapture demux state',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'dynamic read-data captures scalar payload under generated dynamic completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/,
        'scheduled .fsm lowers dynamic read-data capture assignments',
    );

    assert_dynamic_read_response_demux_report($result->{report}, 'generator dynamic read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'generator dynamic read-data report',
        'generated_dynamic_read_response_demux_completion_pulse',
        transactions => [qw(r0)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes RDATA for dynamic read-data');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes RRESP for dynamic read-data');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_rdata\b/, 'SystemVerilog exposes dynamic read-data scalar data output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog guards dynamic read-data capture with generated completion');
    like($hdl, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures dynamic RDATA into scalar output');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures dynamic RRESP into scalar output');
};

subtest 'dynamic last-beat read-data contract consumes generated dynamic RLAST read demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_last_beat());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_rlast\)/, 'dynamic last-beat read-data declares RLAST as the last signal');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'dynamic last-beat read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'dynamic last-beat read-data declares RRESP as a generated input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'dynamic last-beat read-data keeps generated completion internal');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'dynamic last-beat read-data declares scalar last data output');
    like($isf, qr/\(output axi0_r0_last_rresp \(width 2\)\)/, 'dynamic last-beat read-data declares scalar last status output');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/,
        'dynamic last-beat read-data keeps generated RID/RLAST demux',
    );
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'dynamic last-beat read-data captures scalar payload under generated dynamic last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'dynamic last-beat read-data does not enable dynamic burst-length capture');
    like(
        $fsm,
        qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/,
        'scheduled .fsm lowers dynamic last-beat read-data capture assignments',
    );

    assert_dynamic_read_response_demux_burst_last_report($result->{report}, 'generator dynamic last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'generator dynamic last-beat read-data report',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes RLAST for dynamic last-beat read-data');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_last_rdata\b/, 'SystemVerilog exposes dynamic last-beat scalar data output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog guards dynamic last-beat read-data capture with generated completion');
    like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures dynamic last-beat RDATA into scalar output');
    like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures dynamic last-beat RRESP into scalar output');
};

subtest 'multiple dynamic read-data contract consumes generated dynamic single-beat read demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_multi());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\)\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic read-data keeps generated r0 RID demux');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic read-data keeps generated r1 RID demux');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multiple dynamic read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multiple dynamic read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'multiple dynamic read-data declares r0 scalar data output');
    like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'multiple dynamic read-data declares r1 scalar data output');
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/,
        'multiple dynamic read-data captures r1 scalar payload under generated dynamic completion',
    );
    like(
        $fsm,
        qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/,
        'scheduled .fsm lowers r1 multiple dynamic read-data capture assignments',
    );

    assert_dynamic_read_response_demux_multi_report($result->{report}, 'generator multiple dynamic read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'generator multiple dynamic read-data report',
        'generated_dynamic_read_response_demux_completion_pulse',
        transactions => [qw(r0 r1)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_rdata\b/, 'SystemVerilog exposes r1 dynamic read-data scalar data output');
    like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 dynamic read-data capture with generated completion');
    like($hdl, qr/axi0_r1_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 dynamic RDATA into scalar output');
    like($hdl, qr/axi0_r1_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 dynamic RRESP into scalar output');
};

subtest 'multiple dynamic last-beat read-data contract consumes generated dynamic RLAST read demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_multi_last_beat());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic last-beat read-data keeps generated r0 RID/RLAST demux');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic last-beat read-data keeps generated r1 RID/RLAST demux');
    like($isf, qr/\(input axi0_rlast\)/, 'multiple dynamic last-beat read-data declares RLAST');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares RDATA as a generated input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares r0 scalar last data output');
    like($isf, qr/\(output axi0_r1_last_rdata \(width 32\)\)/, 'multiple dynamic last-beat read-data declares r1 scalar last data output');
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/,
        'multiple dynamic last-beat read-data captures r1 scalar payload under generated dynamic completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'multiple dynamic last-beat read-data does not enable dynamic burst-length capture');
    like(
        $fsm,
        qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/,
        'scheduled .fsm lowers r1 multiple dynamic last-beat read-data capture assignments',
    );

    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'generator multiple dynamic last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'generator multiple dynamic last-beat read-data report',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_last_rdata\b/, 'SystemVerilog exposes r1 dynamic last-beat scalar data output');
    like($hdl, qr/assign\s+axi0_r1_read_data_capture_en\s*=\s*axi0_r1_complete\s*;/, 'SystemVerilog guards r1 dynamic last-beat read-data capture with generated completion');
    like($hdl, qr/axi0_r1_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 dynamic last-beat RDATA into scalar output');
    like($hdl, qr/axi0_r1_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures r1 dynamic last-beat RRESP into scalar output');
};

subtest 'multiple dynamic report-only burst-length read-data contract captures ARLEN per transaction' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_multi_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic burst-length read-data keeps generated r0 RID/RLAST demux');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic burst-length read-data keeps generated r1 RID/RLAST demux');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multiple dynamic burst-length read-data declares ARLEN');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data allocates r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'multiple dynamic burst-length read-data allocates r1 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'multiple dynamic burst-length read-data captures r0 raw ARLEN under request');
    like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'multiple dynamic burst-length read-data captures r1 raw ARLEN under request');
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/,
        'multiple dynamic burst-length read-data keeps r1 payload capture under generated dynamic last-beat completion',
    );
    unlike($isf, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'multiple dynamic burst-length read-data keeps runtime validation ungenerated');
    like(
        $fsm,
        qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/,
        'scheduled .fsm lowers r1 multiple dynamic raw ARLEN capture',
    );

    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'generator multiple dynamic burst-length read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator multiple dynamic burst-length read-data report',
        'report_only',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input');
    like($hdl, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 raw ARLEN capture with transaction request');
    like($hdl, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures r1 raw ARLEN into storage');
    unlike($hdl, qr/read_beat_count_q|expected_beats_q|arlen_within_max/, 'SystemVerilog keeps multiple dynamic report-only burst-length runtime validation ungenerated');
};

subtest 'multiple dynamic runtime burst-length read-data contract validates each transaction' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_multi_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic runtime read-data keeps generated r0 RID/RLAST demux');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic runtime read-data keeps generated r1 RID/RLAST demux');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'multiple dynamic runtime read-data allocates r0 expected-beat storage');
    like($isf, qr/\(var axi0_r1_expected_beats_q \(width 5\)\)/, 'multiple dynamic runtime read-data allocates r1 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'multiple dynamic runtime read-data allocates r0 beat-count storage');
    like($isf, qr/\(var axi0_r1_read_beat_count_q \(width 5\)\)/, 'multiple dynamic runtime read-data allocates r1 beat-count storage');
    like($isf, qr/\(rule axi0_r1_beat_count_init axi0_r1_request\s+\(axi0_r1_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r1_read_beat_count_q 0\)\)/, 'multiple dynamic runtime read-data initializes r1 expected count and counter on request');
    like($isf, qr/\(rule axi0_r1_read_beat_count \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\)\)\s+\(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/, 'multiple dynamic runtime read-data increments r1 on raw matched RID beat');
    like($isf, qr/axi0 r1 ARLEN is within configured max beats/, 'multiple dynamic runtime read-data emits r1 ARLEN bound assertion');
    like($isf, qr/axi0 r1 RLAST appears only on the expected final read beat/, 'multiple dynamic runtime read-data emits r1 early-RLAST assertion');
    like($isf, qr/axi0 r1 expected final read beat has RLAST/, 'multiple dynamic runtime read-data emits r1 missing-RLAST assertion');
    like(
        $fsm,
        qr/\(-axi0_r1_read_beat_count\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\)\)\s+\(<- \(axi0_r1_read_beat_count_q \(\+ axi0_r1_read_beat_count_q 5'd1\)\)\)/,
        'scheduled .fsm lowers r1 multiple dynamic runtime beat-count increment',
    );

    assert_dynamic_read_response_demux_multi_burst_last_report($result->{report}, 'generator multiple dynamic runtime read-data response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator multiple dynamic runtime read-data report',
        'runtime_assertion',
        'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_expected_beats_q\b/, 'SystemVerilog declares r1 multiple dynamic expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r1_read_beat_count_q\b/, 'SystemVerilog declares r1 multiple dynamic beat-count storage');
    like($hdl, qr/assign\s+axi0_r1_beat_count_init_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 multiple dynamic beat-count init with request');
    like($hdl, qr/assign\s+axi0_r1_read_beat_count_en\s*=/, 'SystemVerilog emits r1 multiple dynamic beat-count increment enable');
    like($hdl, qr/axi0_r1_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes r1 multiple dynamic expected count from ARLEN+1');
};

subtest 'multiple dynamic multi-beat read-data contract emits output banks for each transaction' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_dynamic_read_data_multi_transaction_multi_beat());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_dynamic_busy_q \(== axi0_rid axi0_r0_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r0_complete\)\)/, 'multiple dynamic multi-beat read-data keeps generated r0 RID/RLAST demux');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/, 'multiple dynamic multi-beat read-data keeps generated r1 RID/RLAST demux');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multiple dynamic multi-beat read-data emits r0 first RDATA lane');
    like($isf, qr/\(output axi0_r1_beat_rdata_15 \(width 32\)\)/, 'multiple dynamic multi-beat read-data emits r1 final RDATA lane');
    like($isf, qr/\(output axi0_r1_beat_rresp_15 \(width 2\)\)/, 'multiple dynamic multi-beat read-data emits r1 final RRESP lane');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'multiple dynamic multi-beat read-data emits r0 valid mask');
    like($isf, qr/\(output axi0_r1_beat_valid \(width 16\)\)/, 'multiple dynamic multi-beat read-data emits r1 valid mask');
    like($isf, qr/\(output axi0_r1_read_beats \(width 5\)\)/, 'multiple dynamic multi-beat read-data emits r1 length output');
    like($isf, qr/\(output axi0_r1_rresp \(width 2\)\)/, 'multiple dynamic multi-beat read-data emits r1 scalar RRESP aggregate');
    like($isf, qr/\(rule axi0_r1_read_data_output_init axi0_r1_request\s+\(axi0_r1_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r1_beat_valid 16'b0\)\s+\(axi0_r1_read_beats 5'd0\)\)/, 'multiple dynamic multi-beat read-data clears r1 output bank on request');
    like($isf, qr/\(rule axi0_r1_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(axi0_r1_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r1_beat_valid 16'b0000000000000001\)\s+\(axi0_r1_read_beats 5'd1\)\)/, 'multiple dynamic multi-beat read-data captures r1 first matched beat lane');
    like($isf, qr/\(rule axi0_r1_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'multiple dynamic multi-beat read-data updates r1 scalar RRESP aggregate on worse status');

    assert_dynamic_read_response_demux_multi_burst_last_report(
        $result->{report},
        'generator multiple dynamic multi-beat read-data response-demux report',
        residue => [qw(same_id_ordering)],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'generator multiple dynamic multi-beat read-data report',
        completion_validity => 'generated_dynamic_read_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1)],
    );

    like($fsm, qr/\(-axi0_r1_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(== axi0_r1_read_beat_count_q 5'd0\)\)\s+\(<- \(axi0_r1_beat_rdata_0> axi0_rdata\)\)/, 'scheduled .fsm lowers r1 first-beat lane capture');
    like($fsm, qr/\(-axi0_r1_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r1_dynamic_busy_q \(== axi0_rid axi0_r1_dynamic_id_q\)\)\) \(! axi0_r1_request\) \(< axi0_r1_rresp axi0_rresp\)\)/, 'scheduled .fsm lowers r1 scalar RRESP aggregation');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r1_beat_rdata_0\b/, 'SystemVerilog exposes r1 first dynamic multi-beat RDATA lane');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_beat_rresp_15\b/, 'SystemVerilog exposes r1 final dynamic multi-beat RRESP lane');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r1_beat_valid\b/, 'SystemVerilog exposes r1 dynamic multi-beat valid mask');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r1_read_beats\b/, 'SystemVerilog exposes r1 dynamic multi-beat length');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r1_rresp\b/, 'SystemVerilog exposes r1 dynamic scalar RRESP aggregate');
    like($hdl, qr/assign\s+axi0_r1_read_beat_0_capture_en\s*=/, 'SystemVerilog emits r1 first-lane capture enable');
    like($hdl, qr/axi0_r1_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures r1 first-lane RDATA');
    like($hdl, qr/axi0_r1_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog captures r1 valid mask for first beat');
    like($hdl, qr/axi0_r1_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog captures r1 length for first beat');
    like($hdl, qr/assign\s+axi0_r1_rresp_aggregate_en\s*=/, 'SystemVerilog emits r1 scalar RRESP aggregate enable');
};

subtest 'transaction event dispatch fans per-transaction events into capacity rules' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_transaction_event_dispatch());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_w0_request\)/, 'generated IAL1 declares first write transaction request event');
    like($isf, qr/\(input axi0_w1_request\)/, 'generated IAL1 declares second write transaction request event');
    like($isf, qr/\(input axi0_r0_request\)/, 'generated IAL1 declares read transaction request event');
    like($isf, qr/\(input axi0_arid \(width 4\)\)/, 'generated IAL1 declares concrete read request ID input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'generated IAL1 declares concrete read response ID input');
    unlike($isf, qr/\(input axi0_write_submit\)/, 'generated IAL1 omits unused legacy write submit event');
    unlike($isf, qr/\(input axi0_awid\b/, 'generated IAL1 omits auto-ID write request ID input');
    like(
        $isf,
        qr/\(rule write_submit_only_occ0 \(& \(\| axi0_w0_request axi0_w1_request\) \(! \(\| axi0_w0_complete axi0_w1_complete\)\) \(== axi0_pending_writes_q 0\)\)/,
        'write submit-only guard uses OR fan-in for multi-transaction request and completion events',
    );
    like(
        $isf,
        qr/\(rule read_submit_only_occ0 \(& axi0_r0_request \(! axi0_r0_complete\) \(== axi0_pending_reads_q 0\)\)/,
        'single read transaction keeps scalar guard compatibility',
    );

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like(
        $fsm,
        qr/\(-write_submit_only_occ0\s+<\(& \(\| axi0_w0_request axi0_w1_request\) \(! \(\| axi0_w0_complete axi0_w1_complete\)\) \(== axi0_pending_writes_q 0\)\)/,
        'generated IAL0 preserves the write OR fan-in guard',
    );

    my $dispatch = $result->{report}{transaction_event_dispatch};
    is($dispatch->{mode}, 'per_transaction_event_fanin', 'report marks transaction event fan-in mode');
    my %direction = map { $_->{direction} => $_ } @{$dispatch->{directions}};
    is_deeply(
        $direction{write}{request_events},
        [qw(axi0_w0_request axi0_w1_request)],
        'report lists write request fan-in events',
    );
    is($direction{write}{request_fanin}, '(| axi0_w0_request axi0_w1_request)', 'report exposes write request fan-in expression');
    is($direction{write}{completion_fanin}, '(| axi0_w0_complete axi0_w1_complete)', 'report exposes write completion fan-in expression');
    is_deeply($direction{read}{request_events}, ['axi0_r0_request'], 'report lists scalar read request event');
    is($direction{read}{request_fanin}, 'axi0_r0_request', 'report keeps scalar read request fan-in');
    assert_boolean_capacity_accounting($result->{report}, 'dispatch write accounting report', direction => 'write', rule_count => 12);
    assert_boolean_capacity_accounting($result->{report}, 'dispatch read accounting report', direction => 'read', rule_count => 20);

    my $engine = $result->{report}{id_response_rule_engine};
    is($engine->{mode}, 'concrete_id_assertions', 'dispatch report also exposes concrete-ID assertion mode');
    is_deeply($engine->{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'dispatch report lists concrete-ID inputs');
    is_deeply(
        [map { $_->{event} } @{$engine->{checks}}],
        [qw(axi0_r0_request axi0_r0_complete)],
        'dispatch report binds concrete-ID assertions to per-transaction events',
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_w0_request\b/, 'generated SystemVerilog declares transaction event input');
    like($hdl, qr/\baxi0_w0_request\s*\|\s*axi0_w1_request\b/, 'generated SystemVerilog lowers request OR fan-in');
    like($hdl, qr/\baxi0_w0_complete\s*\|\s*axi0_w1_complete\b/, 'generated SystemVerilog lowers completion OR fan-in');

    my $sv_assertions = sv_assertion_block_for_result($result);
    my $request_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_r0_request) |-> (axi0_arid == 3))) else $error("axi0 r0 request ID matches concrete ID");';
    my $response_assert = 'assert property (@(posedge clk) disable iff (!rst_n) ((axi0_r0_complete) |-> (axi0_rid == 3))) else $error("axi0 r0 response ID matches concrete ID");';
    like($sv_assertions, qr/\Q$request_assert\E/, 'assertion backend emits the per-transaction request concrete-ID property');
    like($sv_assertions, qr/\Q$response_assert\E/, 'assertion backend emits the per-transaction response concrete-ID property');
};

subtest 'same-ID reject policy reports static concrete-ID reuse selection without generated queue behavior' => sub {
    my $base = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_transaction_event_dispatch());
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_reject_policy());

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
    unlike(
        $result->{generated_ial1}{text},
        qr/\bsame_id_ordering_checks\b/,
        'policy-only same-ID selection does not generate auto-ID same-ID checks',
    );

    my $ordering = $result->{report}{same_id_ordering};
    assert_same_id_reject_policy_report($ordering, 'generator report');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-same-id-reject-policy', 'report preserves policy sample object id');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_reject_policy', 'report preserves policy sample intent name');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release same_id_ordering response_demux)],
        'policy-only selection keeps generated same-ID queue behavior as ID/response residue',
    );
};

subtest 'same-ID issue-order queue policy generates admitted request pulses without generated queue behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_issue_order_queue_policy());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'same-ID issue-order queue declares internal admitted request pulse storage');
    like($isf, qr/\(rule axi0_r0_admitted_request \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) axi0_r0_complete\)\)\s+\(pulse axi0_r0_admitted_request_pulse_q\)\)/, 'same-ID issue-order queue emits a capacity-derived admitted request pulse rule');
    unlike(
        $isf,
        qr/\bsame_id_ordering_checks\b/,
        'single selected concrete request does not need a same-ID request mutual-exclusion assertion',
    );
    like($result->{generated_ial0}{files}{'axi0_capacity_status.fsm'}, qr/\(<1 \(axi0_r0_admitted_request_pulse_q 1\)\)/, 'scheduled .fsm lowers the admitted request pulse as a one-cycle pulse');

    my $ordering = $result->{report}{same_id_ordering};
    assert_same_id_issue_order_queue_policy_report($ordering, 'generator report');
    is($result->{report}{source_object}{id}, 'axi-manager-capacity-status-same-id-issue-order-queue-policy', 'report preserves issue-order queue policy sample object id');
    is($result->{report}{source_object}{intent_name}, 'axi_manager_capacity_status_same_id_issue_order_queue_policy', 'report preserves issue-order queue policy sample intent name');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release same_id_ordering response_demux)],
        'admitted-pulse issue-order queue selection keeps queue behavior as ID/response residue',
    );
};

subtest 'same-ID issue-order queue admitted request pulses assert selected request mutual exclusion' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_issue_order_queue_policy_two_concrete_reads());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'first concrete read gets an admitted request pulse storage var');
    like($isf, qr/\(var axi0_r1_admitted_request_pulse_q \(width 1\)\)/, 'second concrete read gets an admitted request pulse storage var');
    like($isf, qr/\(rule axi0_r0_admitted_request \(& axi0_r0_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)/, 'first admitted request guard uses read completion fan-in');
    like($isf, qr/\(rule axi0_r1_admitted_request \(& axi0_r1_request \(\| \(< axi0_pending_reads_q 4\) \(\| axi0_r0_complete axi0_r1_complete\)\)\)/, 'second admitted request guard uses read completion fan-in');
    like($isf, qr/\(transaction axi0_same_id_ordering_checks\s+\(assert \(! \(& axi0_r0_request axi0_r1_request\)\) "axi0 read same-ID issue-order queue requests are mutually exclusive"\)/, 'two selected concrete read request events emit one runtime mutual-exclusion assertion');

    my $read = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    my $boundary = $read->{admitted_request_boundary};
    is_deeply($boundary->{selected_request_events}, [qw(axi0_r0_request axi0_r1_request)], 'report lists selected request events in source order');
    is_deeply([map { $_->{pulse} } @{$boundary->{generated_pulses}}], [qw(axi0_r0_admitted_request_pulse_q axi0_r1_admitted_request_pulse_q)], 'report lists generated admitted pulse storage names');
    is_deeply($boundary->{generated_assertions}, [qw(axi0_read_issue_order_queue_request_onehot0)], 'report lists the generated request mutual-exclusion assertion');
    ok(!$read->{accepted_same_id_reuse}, 'admitted request pulses still do not accept same-ID reuse');
    ok(!$read->{generated_queue_behavior}, 'admitted request pulses still do not claim queue behavior');
};

subtest 'same-ID queue-head response-demux generates read queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'queue-head selection keeps first admitted request pulse storage');
    like($isf, qr/\(var axi0_r1_admitted_request_pulse_q \(width 1\)\)/, 'queue-head selection keeps second admitted request pulse storage');
    like($isf, qr/\(output axi0_r0_complete\)/, 'queue-head demux exposes r0 completion as a generated output');
    like($isf, qr/\(output axi0_r1_complete\)/, 'queue-head demux exposes r1 completion as a generated output');
    like($isf, qr/\(input axi0_read_complete\)/, 'raw read response beat becomes a generated demux input');
    unlike($isf, qr/\(input axi0_r0_complete\)/, 'r0 completion is no longer an authored input');
    unlike($isf, qr/\(input axi0_r1_complete\)/, 'r1 completion is no longer an authored input');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'queue-head demux declares slot0 r0 state');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot1_r1_q \(width 1\)\)/, 'queue-head demux declares slot1 r1 state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0\b/, 'queue-head demux emits empty enqueue r0 transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_dequeue_enqueue_r1\b/, 'queue-head demux emits same-cycle dequeue/enqueue transition');
    like($isf, qr/\(priority axi0_read_id3_same_id_issue_order_empty_enqueue_r0 over axi0_read_id3_same_id_issue_order_empty_enqueue_r1\)/, 'queue-head transition priorities are emitted for lowerer conflict resolution');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head demux emits r0 response-demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r1_q\)/, 'queue-head demux emits r1 response-demux rule');
    like($isf, qr/read same-ID issue-order queue enqueue has space or selected dequeue/, 'queue-head demux emits queue capacity assertion');
    like($isf, qr/read same-ID issue-order queue enqueue for r1 does not duplicate a remaining transaction/, 'queue-head demux emits duplicate-after-dequeue assertion');

    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'generator report');
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'same-ID policy reports queue-head response-demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'same-ID policy reports generated response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head behavior accepts same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head behavior claims generated queue behavior');
    is($read_policy->{enforcement}, 'generated_issue_order_queue', 'same-ID policy reports generated issue-order queue enforcement');
    is($read_policy->{implementation_status}, 'generated_read_burst_last_queue_head_demux', 'same-ID policy reports the bounded generated implementation status');
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(per_id_issue_order_queues)],
        'generated same-ID queue behavior leaves only broader per-ID queue residue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates multiple read burst-last queue groups' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_group_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r2_admitted_request_pulse_q \(width 1\)\)/, 'multi-group queue-head demux keeps r2 admitted request pulse storage');
    like($isf, qr/\(var axi0_r3_admitted_request_pulse_q \(width 1\)\)/, 'multi-group queue-head demux keeps r3 admitted request pulse storage');
    like($isf, qr/\(output axi0_r2_complete\)/, 'multi-group queue-head demux exposes r2 completion as a generated output');
    like($isf, qr/\(output axi0_r3_complete\)/, 'multi-group queue-head demux exposes r3 completion as a generated output');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot0_r2_q \(width 1\)\)/, 'multi-group queue-head demux declares slot0 r2 state for RID 5');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot1_r3_q \(width 1\)\)/, 'multi-group queue-head demux declares slot1 r3 state for RID 5');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_empty_enqueue_r2\b/, 'multi-group queue-head demux emits empty enqueue r2 transition');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r2_dequeue_enqueue_r3\b/, 'multi-group queue-head demux emits same-cycle dequeue/enqueue transition for RID 5');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'multi-group queue-head demux emits r2 response-demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'multi-group queue-head demux emits r3 response-demux rule');
    like($isf, qr/\(assert \(! \(& axi0_r0_request axi0_r1_request\)\) "read same-ID issue-order queue requests for concrete ID 3 are mutually exclusive"\)/, 'multi-group queue-head demux emits a group-local request assertion for RID 3');
    like($isf, qr/\(assert \(! \(& axi0_r2_request axi0_r3_request\)\) "read same-ID issue-order queue requests for concrete ID 5 are mutually exclusive"\)/, 'multi-group queue-head demux emits a group-local request assertion for RID 5');
    unlike($isf, qr/\(& axi0_r0_request axi0_r2_request\)/, 'multi-group queue-head demux no longer rejects distinct concrete-ID read requests by assertion');
    unlike($isf, qr/\baxi0_rdata\b/, 'multi-group response-demux-only sample does not generate read-data inputs');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group report',
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
    is($read_policy->{implementation_status}, 'generated_read_burst_last_queue_head_demux', 'multi-group policy keeps read burst-last implementation status');
    assert_counted_admitted_request_boundary(
        $read_policy->{admitted_request_boundary},
        'generator read multi-group admitted boundary',
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
        'multi-group policy reports both generated read queue groups',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'multi-group generated queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
    assert_counted_same_id_capacity_accounting(
        $result->{report},
        'generator read multi-group counted capacity report',
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
    assert_boolean_capacity_accounting($result->{report}, 'generator read multi-group write capacity report', direction => 'write', rule_count => 12);

    my $low_capacity_contract = sample_contract_with_same_id_read_multi_group_queue_head_response_demux();
    $low_capacity_contract->{read_max_pending} = 3;
    my $low_capacity_result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($low_capacity_contract);
    my $low_capacity_isf = $low_capacity_result->{generated_ial1}{text};
    assert_counted_low_capacity_rules(
        $low_capacity_isf,
        'generator read multi-group low-capacity rules',
        direction => 'read',
        max_pending => 3,
        request_count_expression => '(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))',
        counted_request_terms => [
            '(| axi0_r0_request axi0_r1_request)',
            '(| axi0_r2_request axi0_r3_request)',
        ],
        completion_fanin => '(| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)',
        pending_storage => 'axi0_pending_reads_q',
        pending_output => 'axi0_pending_reads',
        slots_output => 'axi0_read_slots_available',
        full_output => 'axi0_read_full',
        can_accept_output => 'axi0_read_can_accept',
    );
    assert_counted_low_capacity_admitted_guard(
        $low_capacity_result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read}{admitted_request_boundary},
        'generator read multi-group low-capacity admitted guard',
        request_count_expression => '(+ (| axi0_r0_request axi0_r1_request) (| axi0_r2_request axi0_r3_request))',
        completion_fanin => '(| axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete)',
        pending_storage => 'axi0_pending_reads_q',
        max_pending => 3,
    );
};

subtest 'same-ID queue-head response-demux generates read single-beat queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat queue-head selection keeps first admitted request pulse storage');
    like($isf, qr/\(var axi0_r1_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat queue-head selection keeps second admitted request pulse storage');
    like($isf, qr/\(output axi0_r0_complete\)/, 'read single-beat queue-head demux exposes r0 completion as a generated output');
    like($isf, qr/\(output axi0_r1_complete\)/, 'read single-beat queue-head demux exposes r1 completion as a generated output');
    like($isf, qr/\(input axi0_read_complete\)/, 'raw read response becomes a generated demux input');
    unlike($isf, qr/\(input axi0_r0_complete\)/, 'r0 completion is no longer an authored input');
    unlike($isf, qr/\(input axi0_r1_complete\)/, 'r1 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'read single-beat queue-head demux declares slot0 r0 state');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot1_r1_q \(width 1\)\)/, 'read single-beat queue-head demux declares slot1 r1 state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0\b/, 'read single-beat queue-head demux emits empty enqueue r0 transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_dequeue_enqueue_r1\b/, 'read single-beat queue-head demux emits same-cycle dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'read single-beat queue-head demux emits r0 response-demux rule without RLAST');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r1_q\)/, 'read single-beat queue-head demux emits r1 response-demux rule without RLAST');
    unlike($isf, qr/non-last response beat does not dequeue/, 'read single-beat queue-head demux omits non-last dequeue assertion');

    assert_same_id_read_single_beat_queue_head_response_demux_report($result->{report}{response_demux}, 'generator report');
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{response_demux_strategy}, 'queue_head_issue_order', 'same-ID read single-beat policy reports queue-head response-demux strategy');
    is($read_policy->{response_demux_implementation_status}, 'generated', 'same-ID read single-beat policy reports generated response-demux status');
    ok($read_policy->{accepted_same_id_reuse}, 'read single-beat queue-head behavior accepts same-ID reuse for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'read single-beat queue-head behavior claims generated queue behavior');
    is($read_policy->{enforcement}, 'generated_issue_order_queue', 'same-ID read single-beat policy reports generated issue-order queue enforcement');
    is($read_policy->{implementation_status}, 'generated_read_single_beat_queue_head_demux', 'same-ID read single-beat policy reports the bounded generated implementation status');
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(per_id_issue_order_queues)],
        'generated read single-beat same-ID queue behavior leaves only broader per-ID queue residue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read single-beat queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read single-beat depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r2_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat depth-3 queue-head selection keeps third admitted request pulse storage');
    like($isf, qr/\(output axi0_r2_complete\)/, 'read single-beat depth-3 queue-head demux exposes r2 completion as a generated output');
    unlike($isf, qr/\(input axi0_r2_complete\)/, 'r2 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat depth-3 queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot2_r2_q \(width 1\)\)/, 'read single-beat depth-3 queue-head demux declares slot2 r2 state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0\b/, 'read single-beat depth-3 queue-head demux emits empty enqueue r0 transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_enqueue_r2\b/, 'read single-beat depth-3 queue-head demux emits fill-third-slot transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_r2_dequeue_r0\b/, 'read single-beat depth-3 queue-head demux emits full-queue dequeue transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_r2_dequeue_enqueue_r0\b/, 'read single-beat depth-3 queue-head demux emits full-queue dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read single-beat depth-3 queue-head demux emits r2 response-demux rule without RLAST');
    like($isf, qr/read same-ID issue-order queue slot 2 is one-hot-or-empty/, 'read single-beat depth-3 queue-head demux emits slot2 one-hot assertion');
    like($isf, qr/read same-ID issue-order queue is compact/, 'read single-beat depth-3 queue-head demux emits generalized compactness assertion');
    like($isf, qr/read same-ID issue-order queue enqueue for r2 does not duplicate a remaining transaction/, 'read single-beat depth-3 queue-head demux emits duplicate-after-dequeue assertion for r2');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 read single-beat report',
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
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{implementation_status}, 'generated_read_single_beat_queue_head_demux', 'depth-3 read single-beat policy reports the generated single-beat implementation status');
    is_deeply(
        [map { $_->{depth} } @{$read_policy->{generated_queues} || []}],
        [3],
        'depth-3 read single-beat policy reports the generated depth-3 queue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read single-beat depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read single-beat multiple depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_r5_complete\)/, 'read single-beat multi-depth-3 queue-head demux exposes r5 completion as a generated output');
    unlike($isf, qr/\(input axi0_r5_complete\)/, 'r5 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat multi-depth-3 queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot2_r5_q \(width 1\)\)/, 'read single-beat multi-depth-3 queue-head demux declares ID 5 slot2 r5 state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_r4_enqueue_r5\b/, 'read single-beat multi-depth-3 queue-head demux emits ID 5 fill-third-slot transition');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_r4_r5_dequeue_r3\b/, 'read single-beat multi-depth-3 queue-head demux emits ID 5 full-queue dequeue transition');
    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'read single-beat multi-depth-3 queue-head demux emits r5 response-demux rule without RLAST');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator read single-beat multi-depth-3 report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$read_policy->{generated_queues} || []}], [3, 3], 'read single-beat multi-depth-3 policy reports both generated depth-3 queues');
    assert_same_id_generated_queue_counts(
        $read_policy,
        'read single-beat multi-depth-3 policy',
        slot_storage     => 18,
        update_rules     => 108,
        queue_assertions => 28,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read single-beat multi-depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read single-beat mixed depth-3/depth-2 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_r4_complete\)/, 'read single-beat mixed-depth queue-head demux exposes r4 completion as a generated output');
    unlike($isf, qr/\(input axi0_r4_complete\)/, 'r4 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat mixed-depth queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot2_r2_q \(width 1\)\)/, 'read single-beat mixed-depth queue-head demux keeps ID 3 depth-3 slot2 state');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot1_r4_q \(width 1\)\)/, 'read single-beat mixed-depth queue-head demux declares ID 5 depth-2 slot1 state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_dequeue_enqueue_r4\b/, 'read single-beat mixed-depth queue-head demux emits ID 5 depth-2 same-cycle dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'read single-beat mixed-depth queue-head demux emits r4 response-demux rule without RLAST');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator read single-beat mixed-depth report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$read_policy->{generated_queues} || []}], [3, 2], 'read single-beat mixed-depth policy reports generated depth-3 then depth-2 queues');
    assert_same_id_generated_queue_counts(
        $read_policy,
        'read single-beat mixed-depth policy',
        slot_storage     => 13,
        update_rules     => 66,
        queue_assertions => 25,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read single-beat mixed-depth queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read burst-last depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r2_admitted_request_pulse_q \(width 1\)\)/, 'read burst-last depth-3 queue-head selection keeps third admitted request pulse storage');
    like($isf, qr/\(output axi0_r2_complete\)/, 'read burst-last depth-3 queue-head demux exposes r2 completion as a generated output');
    unlike($isf, qr/\(input axi0_r2_complete\)/, 'read burst-last depth-3 r2 completion is no longer an authored input');
    like($isf, qr/\(input axi0_rlast\)/, 'read burst-last depth-3 queue-head demux consumes RLAST');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot2_r2_q \(width 1\)\)/, 'read burst-last depth-3 queue-head demux declares slot2 r2 state');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_empty_enqueue_r0\b/, 'read burst-last depth-3 queue-head demux emits empty enqueue r0 transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_enqueue_r2\b/, 'read burst-last depth-3 queue-head demux emits fill-third-slot transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_r2_dequeue_r0\b/, 'read burst-last depth-3 queue-head demux emits full-queue dequeue transition');
    like($isf, qr/\(rule axi0_read_id3_same_id_issue_order_r0_r1_r2_dequeue_enqueue_r0\b/, 'read burst-last depth-3 queue-head demux emits full-queue dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'read burst-last depth-3 queue-head demux emits RLAST-gated r2 response-demux rule');
    like($isf, qr/read same-ID non-last response beat does not dequeue/, 'read burst-last depth-3 queue-head demux emits non-last no-dequeue assertion');
    like($isf, qr/read same-ID issue-order queue slot 2 is one-hot-or-empty/, 'read burst-last depth-3 queue-head demux emits slot2 one-hot assertion');
    like($isf, qr/read same-ID issue-order queue is compact/, 'read burst-last depth-3 queue-head demux emits generalized compactness assertion');
    like($isf, qr/read same-ID issue-order queue enqueue for r2 does not duplicate a remaining transaction/, 'read burst-last depth-3 queue-head demux emits duplicate-after-dequeue assertion for r2');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 read burst-last report',
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
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is($read_policy->{implementation_status}, 'generated_read_burst_last_queue_head_demux', 'depth-3 read burst-last policy reports the generated burst-last implementation status');
    is_deeply(
        [map { $_->{depth} } @{$read_policy->{generated_queues} || []}],
        [3],
        'depth-3 read burst-last policy reports the generated depth-3 queue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read burst-last depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read burst-last multiple depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_r5_complete\)/, 'read burst-last multi-depth-3 queue-head demux exposes r5 completion as a generated output');
    unlike($isf, qr/\(input axi0_r5_complete\)/, 'read burst-last multi-depth-3 r5 completion is no longer an authored input');
    like($isf, qr/\(input axi0_rlast\)/, 'read burst-last multi-depth-3 queue-head demux consumes RLAST');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot2_r5_q \(width 1\)\)/, 'read burst-last multi-depth-3 queue-head demux declares ID 5 slot2 r5 state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_r4_enqueue_r5\b/, 'read burst-last multi-depth-3 queue-head demux emits ID 5 fill-third-slot transition');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_r4_r5_dequeue_r3\b/, 'read burst-last multi-depth-3 queue-head demux emits ID 5 full-queue dequeue transition');
    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'read burst-last multi-depth-3 queue-head demux emits RLAST-gated r5 response-demux rule');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator read burst-last multi-depth-3 report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$read_policy->{generated_queues} || []}], [3, 3], 'read burst-last multi-depth-3 policy reports both generated depth-3 queues');
    assert_same_id_generated_queue_counts(
        $read_policy,
        'read burst-last multi-depth-3 policy',
        slot_storage     => 18,
        update_rules     => 108,
        queue_assertions => 30,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read burst-last multi-depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates read burst-last mixed depth-3/depth-2 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_r4_complete\)/, 'read burst-last mixed-depth queue-head demux exposes r4 completion as a generated output');
    unlike($isf, qr/\(input axi0_r4_complete\)/, 'read burst-last mixed-depth r4 completion is no longer an authored input');
    like($isf, qr/\(input axi0_rlast\)/, 'read burst-last mixed-depth queue-head demux consumes RLAST');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot2_r2_q \(width 1\)\)/, 'read burst-last mixed-depth queue-head demux keeps ID 3 depth-3 slot2 state');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot1_r4_q \(width 1\)\)/, 'read burst-last mixed-depth queue-head demux declares ID 5 depth-2 slot1 state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r3_dequeue_enqueue_r4\b/, 'read burst-last mixed-depth queue-head demux emits ID 5 depth-2 same-cycle dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'read burst-last mixed-depth queue-head demux emits RLAST-gated r4 response-demux rule');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator read burst-last mixed-depth report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    is_deeply([map { $_->{depth} } @{$read_policy->{generated_queues} || []}], [3, 2], 'read burst-last mixed-depth policy reports generated depth-3 then depth-2 queues');
    assert_same_id_generated_queue_counts(
        $read_policy,
        'read burst-last mixed-depth policy',
        slot_storage     => 13,
        update_rules     => 66,
        queue_assertions => 27,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read burst-last mixed-depth queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'read-data contract consumes generated read burst-last depth-3 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_depth3_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'depth-3 burst-last queue-head read-data keeps r2 RLAST-gated concrete demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'depth-3 burst-last queue-head read-data consumes RLAST');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'depth-3 burst-last queue-head read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'depth-3 burst-last queue-head read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r2_last_rdata \(width 32\)\)/, 'depth-3 burst-last queue-head read-data declares r2 last data output');
    like($isf, qr/\(output axi0_r2_last_rresp \(width 2\)\)/, 'depth-3 burst-last queue-head read-data declares r2 last status output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'depth-3 burst-last queue-head read-data guards r2 capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'depth-3 burst-last queue-head read-data does not generate ARLEN capture in this slice');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r2 depth-3 burst-last read-data capture assignments');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 burst-last queue-head read-data response-demux report',
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
        'generator depth-3 burst-last queue-head read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'depth-3 burst-last read-data keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'depth-3 burst-last read-data keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for depth-3 burst-last queue-head read-data demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes generated RLAST input for depth-3 burst-last queue-head read-data demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for depth-3 burst-last queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'SystemVerilog exposes r2 depth-3 burst-last captured data output');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog drives r2 depth-3 burst-last capture from generated completion');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'SystemVerilog keeps RLAST-gated concrete RID 3 depth-3 queue-head demux guard for r2');
    like($hdl, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures depth-3 burst-last RDATA into r2 last output');
    like($hdl, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures depth-3 burst-last RRESP into r2 last output');
};

subtest 'read-data contract consumes generated read burst-last depth-3 same-ID queue-head demux with raw ARLEN burst-length capture' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'depth-3 burst-last queue-head burst-length keeps r2 RLAST-gated concrete demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'depth-3 burst-last queue-head burst-length declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'depth-3 burst-last queue-head burst-length declares r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'depth-3 burst-last queue-head burst-length declares r1 raw ARLEN storage');
    like($isf, qr/\(var axi0_r2_arlen_q \(width 8\)\)/, 'depth-3 burst-last queue-head burst-length declares r2 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'depth-3 burst-last queue-head burst-length captures r0 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'depth-3 burst-last queue-head burst-length captures r1 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r2_burst_length_capture axi0_r2_request\s+\(axi0_r2_arlen_q axi0_arlen\)\)/, 'depth-3 burst-last queue-head burst-length captures r2 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'depth-3 burst-last queue-head burst-length still guards r2 scalar capture with generated last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'depth-3 burst-last queue-head report-only burst-length does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'depth-3 burst-last queue-head report-only burst-length does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r2_burst_length_capture\s+<axi0_r2_request\s+\(<- \(axi0_r2_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r2 depth-3 raw ARLEN capture');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm keeps r2 depth-3 scalar read-data capture');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 burst-last queue-head burst-length response-demux report',
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
        'generator depth-3 burst-last queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for depth-3 queue-head burst-length capture');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r0_arlen_q\b/, 'SystemVerilog declares r0 depth-3 raw ARLEN storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r1_arlen_q\b/, 'SystemVerilog declares r1 depth-3 raw ARLEN storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'SystemVerilog declares r2 depth-3 raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog guards r2 depth-3 ARLEN capture with request');
    like($hdl, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r2 depth-3 storage');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog keeps r2 scalar capture on generated last-beat completion');
    unlike($hdl, qr/\bexpected_beats_q\b/, 'SystemVerilog omits expected-beat storage for depth-3 report-only burst-length');
    unlike($hdl, qr/\bread_beat_count_q\b/, 'SystemVerilog omits beat-count storage for depth-3 report-only burst-length');
};

subtest 'read-data contract consumes generated read burst-last depth-3 same-ID queue-head demux with runtime ARLEN beat-count validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'depth-3 runtime validation keeps r2 RLAST-gated concrete demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'depth-3 runtime validation declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'depth-3 runtime validation declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r1_expected_beats_q \(width 5\)\)/, 'depth-3 runtime validation declares r1 expected-beat storage');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'depth-3 runtime validation declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'depth-3 runtime validation declares r2 beat-count storage');
    like($isf, qr/\(rule axi0_r2_beat_count_init axi0_r2_request\s+\(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r2_read_beat_count_q 0\)\)/, 'depth-3 runtime validation initializes r2 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'depth-3 runtime validation increments r2 count on raw matched RID3 queue-head beat without RLAST qualification');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'depth-3 runtime validation keeps r2 scalar capture under generated last-beat completion',
    );
    like($isf, qr/axi0 r2 ARLEN is within configured max beats/, 'depth-3 runtime validation emits r2 ARLEN bound assertion');
    like($isf, qr/axi0 r2 read beat count is below expected count/, 'depth-3 runtime validation emits r2 over-count assertion');
    like($isf, qr/axi0 r2 RLAST appears only on the expected final read beat/, 'depth-3 runtime validation emits r2 early-RLAST assertion');
    like($isf, qr/axi0 r2 expected final read beat has RLAST/, 'depth-3 runtime validation emits r2 missing-RLAST assertion');
    unlike($isf, qr/\baxi0_r2_beat_rdata_0\b/, 'depth-3 runtime validation does not generate multi-beat r2 lane storage');
    unlike($isf, qr/\baxi0_r2_beat_valid\b/, 'depth-3 runtime validation does not generate r2 multi-beat valid output');

    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_\d+ assert \(\| \(! \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\)\) \(< axi0_r2_read_beat_count_q axi0_r2_expected_beats_q\)\)/, 'scheduled .fsm carries r2 depth-3 over-count assertion on matched beat');
    like($fsm, qr/\(-axi0_r2_beat_count_init\s+<axi0_r2_request\s+\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r2_read_beat_count_q 0\)\)/, 'scheduled .fsm carries r2 depth-3 expected-beat initialization');
    like($fsm, qr/\(-axi0_r2_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r2 depth-3 matched-beat increment');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm keeps r2 scalar last-beat capture');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 runtime validation response-demux report',
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
        'generator depth-3 runtime validation read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'depth-3 runtime validation keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'depth-3 runtime validation keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for depth-3 runtime validation');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'SystemVerilog declares r2 depth-3 expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'SystemVerilog declares r2 depth-3 beat-count storage');
    like($hdl, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes r2 depth-3 expected count from ARLEN+1');
    like($hdl, qr/axi0_r2_read_beat_count_q_next\s*=\s*axi0_r2_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments r2 depth-3 beat count');
    like($hdl, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'SystemVerilog emits r2 depth-3 beat-count increment enable');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog keeps r2 scalar capture on generated last-beat completion');
    unlike($hdl, qr/\baxi0_r2_beat_valid\b/, 'SystemVerilog does not expose r2 multi-beat valid output for scalar runtime validation');
};

subtest 'read-data contract generates depth-3 queue-head multi-beat output-bank payload behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_depth3_queue_head_multi_beat_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'depth-3 multi-beat keeps r2 RLAST-gated concrete demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'depth-3 multi-beat declares ARLEN as a generated width-8 input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'depth-3 multi-beat declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'depth-3 multi-beat declares generated RRESP input');
    like($isf, qr/\(var axi0_r2_arlen_q \(width 8\)\)/, 'depth-3 multi-beat declares r2 raw ARLEN storage');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'depth-3 multi-beat declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'depth-3 multi-beat declares r2 beat-count storage');
    like($isf, qr/\(output axi0_r2_beat_rdata_0 \(width 32\)\)/, 'depth-3 multi-beat declares r2 beat 0 data output');
    like($isf, qr/\(output axi0_r2_beat_rresp_0 \(width 2\)\)/, 'depth-3 multi-beat declares r2 beat 0 status output');
    like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'depth-3 multi-beat declares r2 scalar aggregate status output');
    like($isf, qr/\(output axi0_r2_beat_valid \(width 16\)\)/, 'depth-3 multi-beat declares r2 valid-mask output');
    like($isf, qr/\(output axi0_r2_read_beats \(width 5\)\)/, 'depth-3 multi-beat declares r2 length output');
    like($isf, qr/\(rule axi0_r2_read_data_output_init axi0_r2_request[\s\S]*\(axi0_r2_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r2_rresp 2'd0\)[\s\S]*\(axi0_r2_beat_valid 16'b0\)[\s\S]*\(axi0_r2_read_beats 5'd0\)\)/, 'depth-3 multi-beat clears the r2 output bank and aggregate on request');
    like($isf, qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r2_read_beats 5'd1\)\)/, 'depth-3 multi-beat captures r2 lane 0 under raw matched queue-head beat plus beat index');
    like($isf, qr/\(rule axi0_r2_read_beat_15_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd15\)\)[\s\S]*\(axi0_r2_beat_rdata_15 axi0_rdata\)[\s\S]*\(axi0_r2_beat_rresp_15 axi0_rresp\)[\s\S]*\(axi0_r2_beat_valid 16'b1111111111111111\)[\s\S]*\(axi0_r2_read_beats 5'd16\)\)/, 'depth-3 multi-beat captures the final bounded r2 lane');
    like($isf, qr/\(rule axi0_r2_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)\s+\(axi0_r2_rresp axi0_rresp\)\)/, 'depth-3 multi-beat updates r2 scalar aggregate on raw matched queue-head beat');
    like($fsm, qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r2_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r2_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r2_read_beats> 5'd1\)\)/, 'scheduled .fsm captures depth-3 r2 lane 0 payload, valid mask, and length');
    like($fsm, qr/\(-axi0_r2_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)[\s\S]*\(<- \(axi0_r2_rresp> axi0_rresp\)\)/, 'scheduled .fsm updates depth-3 r2 scalar aggregate');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 multi-beat response-demux report',
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
        'generator depth-3 multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'depth-3 multi-beat keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'depth-3 multi-beat keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes depth-3 multi-beat RDATA input');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, 'SystemVerilog exposes depth-3 r2 per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_beat_rresp_0\b/, 'SystemVerilog exposes depth-3 r2 per-beat status output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'SystemVerilog exposes depth-3 r2 scalar aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, 'SystemVerilog exposes depth-3 r2 valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r2_read_beats\b/, 'SystemVerilog exposes depth-3 r2 length output');
    like($hdl, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog clears depth-3 r2 output bank on request');
    like($hdl, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, 'SystemVerilog emits depth-3 r2 lane 0 capture enable');
    like($hdl, qr/axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'SystemVerilog depth-3 r2 lane capture references RID3 slot-0 transaction identity');
    like($hdl, qr/axi0_r2_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures depth-3 r2 lane 0 data');
    like($hdl, qr/axi0_r2_beat_rresp_0_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures depth-3 r2 lane 0 status');
    like($hdl, qr/axi0_r2_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog sets depth-3 r2 first valid-mask prefix');
    like($hdl, qr/axi0_r2_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog sets depth-3 r2 length after first beat');
    like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates depth-3 r2 scalar aggregate from current RRESP');
};

subtest 'read-data contract consumes generated read single-beat depth-3 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_depth3_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'depth-3 queue-head read-data keeps r2 concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'depth-3 queue-head read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'depth-3 queue-head read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r2_rdata \(width 32\)\)/, 'depth-3 queue-head read-data declares r2 data output');
    like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'depth-3 queue-head read-data declares r2 status output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_rdata axi0_rdata\)\s+\(axi0_r2_rresp axi0_rresp\)\)/,
        'depth-3 queue-head read-data guards r2 capture with generated queue-head completion',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'depth-3 queue-head read-data single-beat contract does not generate or consume RLAST');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r2 depth-3 queue-head read-data capture assignments');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 queue-head read-data response-demux report',
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
        'generator depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for depth-3 queue-head read-data demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for depth-3 queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_rdata\b/, 'SystemVerilog exposes r2 depth-3 queue-head captured data output');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog drives r2 depth-3 queue-head read-data capture from generated completion');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/, 'SystemVerilog keeps concrete RID 3 depth-3 queue-head demux guard for r2');
    like($hdl, qr/axi0_r2_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures depth-3 queue-head RDATA into r2 output');
    like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures depth-3 queue-head RRESP into r2 output');
};

subtest 'same-ID queue-head response-demux generates read single-beat multi-group queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_multi_group_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_r0_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat multi-group queue-head selection keeps first admitted request pulse storage');
    like($isf, qr/\(var axi0_r3_admitted_request_pulse_q \(width 1\)\)/, 'read single-beat multi-group queue-head selection keeps final admitted request pulse storage');
    like($isf, qr/\(output axi0_r0_complete\)/, 'read single-beat multi-group queue-head demux exposes r0 completion as a generated output');
    like($isf, qr/\(output axi0_r3_complete\)/, 'read single-beat multi-group queue-head demux exposes r3 completion as a generated output');
    like($isf, qr/\(input axi0_read_complete\)/, 'raw read response remains the generated demux input');
    unlike($isf, qr/\(input axi0_r2_complete\)/, 'r2 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'read single-beat multi-group queue-head demux does not generate or consume RLAST');
    unlike($isf, qr/\baxi0_rdata\b/, 'read single-beat multi-group response-demux-only sample does not generate read-data inputs');
    like($isf, qr/\(var axi0_read_id3_same_id_issue_order_slot0_r0_q \(width 1\)\)/, 'read single-beat multi-group queue-head demux declares concrete ID 3 slot state');
    like($isf, qr/\(var axi0_read_id5_same_id_issue_order_slot0_r2_q \(width 1\)\)/, 'read single-beat multi-group queue-head demux declares concrete ID 5 slot state');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_empty_enqueue_r2\b/, 'read single-beat multi-group queue-head demux emits ID 5 empty enqueue transition');
    like($isf, qr/\(rule axi0_read_id5_same_id_issue_order_r2_dequeue_enqueue_r3\b/, 'read single-beat multi-group queue-head demux emits ID 5 same-cycle dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'read single-beat multi-group queue-head demux emits r2 response-demux rule without RLAST');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'read single-beat multi-group queue-head demux emits r3 response-demux rule without RLAST');
    like($isf, qr/\(assert \(! \(& axi0_r0_request axi0_r1_request\)\) "read same-ID issue-order queue requests for concrete ID 3 are mutually exclusive"\)/, 'read single-beat multi-group queue-head demux emits a group-local request assertion for RID 3');
    like($isf, qr/\(assert \(! \(& axi0_r2_request axi0_r3_request\)\) "read same-ID issue-order queue requests for concrete ID 5 are mutually exclusive"\)/, 'read single-beat multi-group queue-head demux emits a group-local request assertion for RID 5');
    unlike($isf, qr/\(& axi0_r0_request axi0_r2_request\)/, 'read single-beat multi-group queue-head demux no longer rejects distinct concrete-ID read requests by assertion');
    unlike($isf, qr/non-last response beat does not dequeue/, 'read single-beat multi-group queue-head demux omits non-last dequeue assertions');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group read single-beat report',
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
    is($read_policy->{implementation_status}, 'generated_read_single_beat_queue_head_demux', 'multi-group read single-beat policy reports the generated single-beat implementation status');
    is_deeply(
        [map { $_->{concrete_id} } @{$read_policy->{generated_queues} || []}],
        [3, 5],
        'multi-group read single-beat policy reports both generated read queue groups',
    );
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(per_id_issue_order_queues)],
        'generated read single-beat multi-group same-ID queue behavior leaves only broader per-ID queue residue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated read single-beat multi-group queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates write queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_write_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_w0_admitted_request_pulse_q \(width 1\)\)/, 'write queue-head selection keeps first admitted request pulse storage');
    like($isf, qr/\(var axi0_w1_admitted_request_pulse_q \(width 1\)\)/, 'write queue-head selection keeps second admitted request pulse storage');
    like($isf, qr/\(output axi0_w0_complete\)/, 'write queue-head demux exposes w0 completion as a generated output');
    like($isf, qr/\(output axi0_w1_complete\)/, 'write queue-head demux exposes w1 completion as a generated output');
    like($isf, qr/\(input axi0_write_complete\)/, 'raw write response becomes a generated demux input');
    unlike($isf, qr/\(input axi0_w0_complete\)/, 'w0 completion is no longer an authored input');
    unlike($isf, qr/\(input axi0_w1_complete\)/, 'w1 completion is no longer an authored input');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot0_w0_q \(width 1\)\)/, 'write queue-head demux declares slot0 w0 state');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot1_w1_q \(width 1\)\)/, 'write queue-head demux declares slot1 w1 state');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_empty_enqueue_w0\b/, 'write queue-head demux emits empty enqueue w0 transition');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_dequeue_enqueue_w1\b/, 'write queue-head demux emits same-cycle dequeue/enqueue transition');
    like($isf, qr/\(priority axi0_write_id3_same_id_issue_order_empty_enqueue_w0 over axi0_write_id3_same_id_issue_order_empty_enqueue_w1\)/, 'write queue-head transition priorities are emitted for lowerer conflict resolution');
    like($isf, qr/\(rule axi0_w0_response_demux \(& axi0_write_complete \(== axi0_bid 4'd3\) axi0_write_id3_same_id_issue_order_slot0_w0_q\)/, 'write queue-head demux emits w0 response-demux rule without RLAST');
    like($isf, qr/\(rule axi0_w1_response_demux \(& axi0_write_complete \(== axi0_bid 4'd3\) axi0_write_id3_same_id_issue_order_slot0_w1_q\)/, 'write queue-head demux emits w1 response-demux rule without RLAST');
    like($isf, qr/write same-ID issue-order queue enqueue has space or selected dequeue/, 'write queue-head demux emits queue capacity assertion');
    like($isf, qr/write same-ID issue-order queue enqueue for w1 does not duplicate a remaining transaction/, 'write queue-head demux emits duplicate-after-dequeue assertion');

    assert_same_id_write_queue_head_response_demux_report($result->{report}{response_demux}, 'generator report');
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'same-ID write policy reports queue-head response-demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'same-ID write policy reports generated response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'write queue-head behavior accepts same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'write queue-head behavior claims generated queue behavior');
    is($write_policy->{enforcement}, 'generated_issue_order_queue', 'same-ID write policy reports generated issue-order queue enforcement');
    is($write_policy->{implementation_status}, 'generated_write_bid_queue_head_demux', 'same-ID write policy reports the bounded generated implementation status');
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(per_id_issue_order_queues)],
        'generated write same-ID queue behavior leaves only broader per-ID queue residue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated write queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates write depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_write_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_w2_admitted_request_pulse_q \(width 1\)\)/, 'write depth-3 queue-head selection keeps third admitted request pulse storage');
    like($isf, qr/\(output axi0_w2_complete\)/, 'write depth-3 queue-head demux exposes w2 completion as a generated output');
    like($isf, qr/\(input axi0_write_complete\)/, 'raw write response remains the generated demux input');
    unlike($isf, qr/\(input axi0_w2_complete\)/, 'w2 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'write depth-3 queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot2_w2_q \(width 1\)\)/, 'write depth-3 queue-head demux declares slot2 w2 state');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_empty_enqueue_w0\b/, 'write depth-3 queue-head demux emits empty enqueue w0 transition');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_w1_enqueue_w2\b/, 'write depth-3 queue-head demux emits fill-third-slot transition');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_w1_w2_dequeue_w0\b/, 'write depth-3 queue-head demux emits full-queue dequeue transition');
    like($isf, qr/\(rule axi0_write_id3_same_id_issue_order_w0_w1_w2_dequeue_enqueue_w0\b/, 'write depth-3 queue-head demux emits full-queue dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_w2_response_demux \(& axi0_write_complete \(== axi0_bid 4'd3\) axi0_write_id3_same_id_issue_order_slot0_w2_q\)/, 'write depth-3 queue-head demux emits w2 response-demux rule without RLAST');
    like($isf, qr/write same-ID issue-order queue slot 2 is one-hot-or-empty/, 'write depth-3 queue-head demux emits slot2 one-hot assertion');
    like($isf, qr/write same-ID issue-order queue is compact/, 'write depth-3 queue-head demux emits generalized compactness assertion');
    like($isf, qr/write same-ID issue-order queue enqueue for w2 does not duplicate a remaining transaction/, 'write depth-3 queue-head demux emits duplicate-after-dequeue assertion for w2');

    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator depth-3 write report',
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
    is($write_policy->{implementation_status}, 'generated_write_bid_queue_head_demux', 'depth-3 write policy reports the generated write implementation status');
    ok($write_policy->{accepted_same_id_reuse}, 'write depth-3 queue-head behavior accepts same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'write depth-3 queue-head behavior claims generated queue behavior');
    is_deeply(
        [map { $_->{depth} } @{$write_policy->{generated_queues} || []}],
        [3],
        'depth-3 write policy reports the generated depth-3 queue',
    );
    my ($queue) = @{$write_policy->{generated_queues} || []};
    is(scalar(@{$queue->{slot_storage} || []}), 9, 'depth-3 write queue report lists 9 queue slot storage signals');
    is(scalar(@{$queue->{generated_update_rules} || []}), 54, 'depth-3 write queue report lists 54 generated update rules');
    is(scalar(@{$queue->{generated_assertions} || []}), 14, 'depth-3 write queue report lists 14 generated queue assertions');
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated write depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates write multiple depth-3 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_write_multi_depth3_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_w5_complete\)/, 'write multi-depth-3 queue-head demux exposes w5 completion as a generated output');
    like($isf, qr/\(input axi0_write_complete\)/, 'raw write response remains the generated demux input');
    unlike($isf, qr/\(input axi0_w5_complete\)/, 'w5 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'write multi-depth-3 queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_write_id5_same_id_issue_order_slot2_w5_q \(width 1\)\)/, 'write multi-depth-3 queue-head demux declares ID 5 slot2 w5 state');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_w3_w4_enqueue_w5\b/, 'write multi-depth-3 queue-head demux emits ID 5 fill-third-slot transition');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_w3_w4_w5_dequeue_w3\b/, 'write multi-depth-3 queue-head demux emits ID 5 full-queue dequeue transition');
    like($isf, qr/\(rule axi0_w5_response_demux \(& axi0_write_complete \(== axi0_bid 4'd5\) axi0_write_id5_same_id_issue_order_slot0_w5_q\)/, 'write multi-depth-3 queue-head demux emits w5 response-demux rule');

    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator write multi-depth-3 report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1 w2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(w3 w4 w5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete axi0_w4_complete axi0_w5_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux axi0_w4_response_demux axi0_w5_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w0_w3_write_response_demux_unique_match
            axi0_w0_w4_write_response_demux_unique_match
            axi0_w0_w5_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
            axi0_w1_w3_write_response_demux_unique_match
            axi0_w1_w4_write_response_demux_unique_match
            axi0_w1_w5_write_response_demux_unique_match
            axi0_w2_w3_write_response_demux_unique_match
            axi0_w2_w4_write_response_demux_unique_match
            axi0_w2_w5_write_response_demux_unique_match
            axi0_w3_w4_write_response_demux_unique_match
            axi0_w3_w5_write_response_demux_unique_match
            axi0_w4_w5_write_response_demux_unique_match
        )],
    );
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is_deeply([map { $_->{depth} } @{$write_policy->{generated_queues} || []}], [3, 3], 'write multi-depth-3 policy reports both generated depth-3 queues');
    assert_same_id_generated_queue_counts(
        $write_policy,
        'write multi-depth-3 policy',
        slot_storage     => 18,
        update_rules     => 108,
        queue_assertions => 28,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated write multi-depth-3 queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates write mixed depth-3/depth-2 queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_write_mixed_depth3_depth2_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_w4_complete\)/, 'write mixed-depth queue-head demux exposes w4 completion as a generated output');
    like($isf, qr/\(input axi0_write_complete\)/, 'raw write response remains the generated demux input');
    unlike($isf, qr/\(input axi0_w4_complete\)/, 'w4 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'write mixed-depth queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot2_w2_q \(width 1\)\)/, 'write mixed-depth queue-head demux keeps ID 3 depth-3 slot2 state');
    like($isf, qr/\(var axi0_write_id5_same_id_issue_order_slot1_w4_q \(width 1\)\)/, 'write mixed-depth queue-head demux declares ID 5 depth-2 slot1 state');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_w3_dequeue_enqueue_w4\b/, 'write mixed-depth queue-head demux emits ID 5 depth-2 same-cycle dequeue/enqueue transition');
    like($isf, qr/\(rule axi0_w4_response_demux \(& axi0_write_complete \(== axi0_bid 4'd5\) axi0_write_id5_same_id_issue_order_slot0_w4_q\)/, 'write mixed-depth queue-head demux emits w4 response-demux rule');

    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator write mixed-depth report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(w0 w1 w2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(w3 w4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete axi0_w4_complete)],
        generated_rules => [qw(axi0_w0_response_demux axi0_w1_response_demux axi0_w2_response_demux axi0_w3_response_demux axi0_w4_response_demux)],
        generated_assertions => [qw(
            axi0_write_response_demux_active_match
            axi0_w0_w1_write_response_demux_unique_match
            axi0_w0_w2_write_response_demux_unique_match
            axi0_w0_w3_write_response_demux_unique_match
            axi0_w0_w4_write_response_demux_unique_match
            axi0_w1_w2_write_response_demux_unique_match
            axi0_w1_w3_write_response_demux_unique_match
            axi0_w1_w4_write_response_demux_unique_match
            axi0_w2_w3_write_response_demux_unique_match
            axi0_w2_w4_write_response_demux_unique_match
            axi0_w3_w4_write_response_demux_unique_match
        )],
    );
    my $write_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write};
    is_deeply([map { $_->{depth} } @{$write_policy->{generated_queues} || []}], [3, 2], 'write mixed-depth policy reports generated depth-3 then depth-2 queues');
    assert_same_id_generated_queue_counts(
        $write_policy,
        'write mixed-depth policy',
        slot_storage     => 13,
        update_rules     => 66,
        queue_assertions => 25,
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated write mixed-depth queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
};

subtest 'same-ID queue-head response-demux generates write multi-group queue state and completion demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_write_multi_group_queue_head_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(var axi0_w0_admitted_request_pulse_q \(width 1\)\)/, 'write multi-group queue-head selection keeps first admitted request pulse storage');
    like($isf, qr/\(var axi0_w3_admitted_request_pulse_q \(width 1\)\)/, 'write multi-group queue-head selection keeps final admitted request pulse storage');
    like($isf, qr/\(output axi0_w0_complete\)/, 'write multi-group queue-head demux exposes w0 completion as a generated output');
    like($isf, qr/\(output axi0_w3_complete\)/, 'write multi-group queue-head demux exposes w3 completion as a generated output');
    like($isf, qr/\(input axi0_write_complete\)/, 'raw write response remains the generated demux input');
    unlike($isf, qr/\(input axi0_w2_complete\)/, 'w2 completion is no longer an authored input');
    unlike($isf, qr/\baxi0_rlast\b/, 'write multi-group queue-head demux does not generate or consume RLAST');
    like($isf, qr/\(var axi0_write_id3_same_id_issue_order_slot0_w0_q \(width 1\)\)/, 'write multi-group queue-head demux declares concrete ID 3 slot state');
    like($isf, qr/\(var axi0_write_id5_same_id_issue_order_slot0_w2_q \(width 1\)\)/, 'write multi-group queue-head demux declares concrete ID 5 slot state');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_empty_enqueue_w2\b/, 'write multi-group queue-head demux emits ID 5 empty enqueue transition');
    like($isf, qr/\(rule axi0_write_id5_same_id_issue_order_w2_dequeue_enqueue_w3\b/, 'write multi-group queue-head demux emits ID 5 same-cycle dequeue/enqueue transition');
    like($isf, qr/\(priority axi0_write_id5_same_id_issue_order_empty_enqueue_w2 over axi0_write_id5_same_id_issue_order_empty_enqueue_w3\)/, 'write multi-group queue-head transition priorities include ID 5 group');
    like($isf, qr/\(rule axi0_w2_response_demux \(& axi0_write_complete \(== axi0_bid 4'd5\) axi0_write_id5_same_id_issue_order_slot0_w2_q\)/, 'write multi-group queue-head demux emits w2 response-demux rule without RLAST');
    like($isf, qr/\(rule axi0_w3_response_demux \(& axi0_write_complete \(== axi0_bid 4'd5\) axi0_write_id5_same_id_issue_order_slot0_w3_q\)/, 'write multi-group queue-head demux emits w3 response-demux rule without RLAST');
    like($isf, qr/write same-ID issue-order queue enqueue has space or selected dequeue/, 'write multi-group queue-head demux emits queue capacity assertions');
    like($isf, qr/write same-ID issue-order queue enqueue for w3 does not duplicate a remaining transaction/, 'write multi-group queue-head demux emits duplicate-after-dequeue assertions for the second group');

    assert_same_id_write_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group write report',
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
        'same-ID write multi-group policy reports group-local admitted-request onehot assertions',
    );
    assert_counted_admitted_request_boundary(
        $write_policy->{admitted_request_boundary},
        'generator write multi-group admitted boundary',
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
    is($write_policy->{response_demux_strategy}, 'queue_head_issue_order', 'same-ID write multi-group policy reports queue-head response-demux strategy');
    is($write_policy->{response_demux_implementation_status}, 'generated', 'same-ID write multi-group policy reports generated response-demux status');
    ok($write_policy->{accepted_same_id_reuse}, 'write multi-group queue-head behavior accepts same-ID reuse for the covered shape');
    ok($write_policy->{generated_queue_behavior}, 'write multi-group queue-head behavior claims generated queue behavior');
    is($write_policy->{enforcement}, 'generated_issue_order_queue', 'same-ID write multi-group policy reports generated issue-order queue enforcement');
    is($write_policy->{implementation_status}, 'generated_write_bid_queue_head_demux', 'same-ID write multi-group policy reports the bounded generated implementation status');
    is_deeply(
        [map { $_->{concrete_id} } @{$write_policy->{generated_queues} || []}],
        [3, 5],
        'same-ID write multi-group policy reports both generated write queue groups',
    );
    is_deeply(
        $result->{report}{same_id_ordering}{residue},
        [qw(per_id_issue_order_queues)],
        'generated write multi-group same-ID queue behavior leaves only broader per-ID queue residue',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(auto_id_allocation id_release)],
        'generated write multi-group queue-head behavior removes same-ID and response-demux residue from ID/response report',
    );
    assert_counted_same_id_capacity_accounting(
        $result->{report},
        'generator write multi-group counted capacity report',
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
    assert_boolean_capacity_accounting($result->{report}, 'generator write multi-group read capacity report', direction => 'read', rule_count => 20);

    my $low_capacity_contract = sample_contract_with_same_id_write_multi_group_queue_head_response_demux();
    $low_capacity_contract->{write_max_pending} = 3;
    my $low_capacity_result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($low_capacity_contract);
    my $low_capacity_isf = $low_capacity_result->{generated_ial1}{text};
    assert_counted_low_capacity_rules(
        $low_capacity_isf,
        'generator write multi-group low-capacity rules',
        direction => 'write',
        max_pending => 3,
        request_count_expression => '(+ (| axi0_w0_request axi0_w1_request) (| axi0_w2_request axi0_w3_request))',
        counted_request_terms => [
            '(| axi0_w0_request axi0_w1_request)',
            '(| axi0_w2_request axi0_w3_request)',
        ],
        completion_fanin => '(| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)',
        pending_storage => 'axi0_pending_writes_q',
        pending_output => 'axi0_pending_writes',
        slots_output => 'axi0_write_slots_available',
        full_output => 'axi0_write_full',
        can_accept_output => 'axi0_write_can_accept',
    );
    assert_counted_low_capacity_admitted_guard(
        $low_capacity_result->{report}{same_id_ordering}{concrete_id_reuse_policy}{write}{admitted_request_boundary},
        'generator write multi-group low-capacity admitted guard',
        request_count_expression => '(+ (| axi0_w0_request axi0_w1_request) (| axi0_w2_request axi0_w3_request))',
        completion_fanin => '(| axi0_w0_complete axi0_w1_complete axi0_w2_complete axi0_w3_complete)',
        pending_storage => 'axi0_pending_writes_q',
        max_pending => 3,
    );
};

subtest 'auto-ID lifecycle generates bounded request-ID drive behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_auto_id_lifecycle());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(output axi0_awid \(width 4\)\)/, 'auto-ID lifecycle drives the write request ID as a generated output');
    unlike($isf, qr/\(input axi0_awid\b/, 'auto-ID lifecycle does not treat generated write request ID as an input');
    unlike($isf, qr/\(input axi0_bid\b/, 'auto-ID lifecycle does not add unused write response ID input');
    like($isf, qr/\(var axi0_w0_auto_id_q \(width 4\)\)/, 'auto-ID lifecycle declares selected-ID state for w0');
    like($isf, qr/\(var axi0_w0_auto_id_busy_q \(width 1\)\)/, 'auto-ID lifecycle declares busy state for w0');
    like($isf, qr/\(var axi0_w1_auto_id_q \(width 4\)\)/, 'auto-ID lifecycle declares selected-ID state for w1');
    like($isf, qr/\(priority axi0_w0_auto_id_alloc_0 over axi0_w0_auto_id_alloc_1\)/, 'auto-ID lifecycle emits generated priority for first-free pool order');
    like($isf, qr/\(rule axi0_w0_auto_id_alloc_0\b[\s\S]*\(axi0_w0_auto_id_q 0\)[\s\S]*\(axi0_w0_auto_id_busy_q 1\)[\s\S]*\(axi0_awid 0\)\)/, 'auto-ID lifecycle allocates pool ID 0 to w0');
    like($isf, qr/\(rule axi0_w0_auto_id_alloc_1\b[\s\S]*\(axi0_w0_auto_id_q 1\)[\s\S]*\(axi0_awid 1\)\)/, 'auto-ID lifecycle allocates pool ID 1 to w0 when earlier IDs are unavailable');
    like($isf, qr/\(rule axi0_w0_auto_id_release \(& axi0_w0_complete axi0_w0_auto_id_busy_q\)[\s\S]*\(axi0_w0_auto_id_busy_q 0\)\)/, 'auto-ID lifecycle releases w0 busy state on completion');
    like($isf, qr/"axi0 w0 auto ID available"/, 'auto-ID lifecycle emits no-ID-available runtime assertion');
    like($isf, qr/"axi0 write auto ID requests are mutually exclusive"/, 'auto-ID lifecycle emits same-family request mutual-exclusion assertion');
    like($isf, qr/"axi0 write auto ID active selected IDs are unique"/, 'auto-ID lifecycle emits same-ID avoidance runtime assertion');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_awid 4\)/, 'scheduled .fsm declares AWID width');
    like($fsm, qr/\(\+size[\s\S]*\(axi0_w0_auto_id_q 4\)/, 'scheduled .fsm declares selected-ID storage width');
    like($fsm, qr/\(-axi0_w0_auto_id_alloc_0\b[\s\S]*\(<- \(axi0_awid> 0\)\)/, 'scheduled .fsm drives AWID from allocation rule');
    like($fsm, qr/\(-axi0_w0_auto_id_release\b[\s\S]*\(<- \(axi0_w0_auto_id_busy_q 0\)\)/, 'scheduled .fsm lowers completion release rule');
    like($fsm, qr/\(\+assert[\s\S]*axi0 w0 auto ID available/, 'scheduled .fsm carries auto-ID runtime assertions');

    my $lifecycle = $result->{report}{auto_id_lifecycle};
    is($lifecycle->{mode}, 'bounded_pool_contract', 'report marks bounded-pool auto-ID lifecycle mode');
    ok($lifecycle->{generated_behavior}, 'report marks generated behavior true');
    is($lifecycle->{max_pool_entries_per_family}, 4, 'report publishes the bounded pool-entry cap');
    is_deeply(
        $lifecycle->{residue},
        [qw(response_demux)],
        'report removes shipped request-ID drive, release, and same-ID avoidance behavior from residue',
    );
    is(scalar(@{$lifecycle->{families}}), 1, 'report publishes only the listed lifecycle family');
    my $write = $lifecycle->{families}[0];
    is($write->{family}, 'write', 'write lifecycle family is reported');
    is($write->{request_id_signal}, 'axi0_awid', 'write request ID signal is reported');
    is($write->{request_id_direction}, 'generated_output', 'write request ID direction is generated output');
    is($write->{response_id_signal}, 'axi0_bid', 'write response ID signal is reported');
    is($write->{response_id_direction}, 'generated_input', 'write response ID direction is generated input');
    is_deeply($write->{pool}, [0, 1], 'write lifecycle pool preserves author order');
    is($write->{allocator}, 'first_free_pool_order', 'allocator contract is reported');
    is($write->{transaction_lifetime}, 'single_active', 'transaction lifetime contract is reported');
    is($write->{release}, 'transaction_completion_event', 'release contract is reported');
    is($write->{no_id_available}, 'runtime_assertion', 'no-ID behavior is reported as a generated runtime assertion');
    is_deeply($write->{auto_transactions}, [qw(w0 w1)], 'write lifecycle lists auto-ID transactions in source order');
    is_deeply(
        [map { $_->{selected_id_signal} } @{$write->{transaction_state}}],
        [qw(axi0_w0_auto_id_q axi0_w1_auto_id_q)],
        'report lists generated selected-ID state per auto transaction',
    );
    is_deeply(
        $write->{transaction_state}[0]{allocation_rules},
        [qw(axi0_w0_auto_id_alloc_0 axi0_w0_auto_id_alloc_1)],
        'report lists generated allocation rules per pool value',
    );
    is($write->{transaction_state}[0]{release_rule}, 'axi0_w0_auto_id_release', 'report lists generated release rule');

    my $engine = $result->{report}{id_response_rule_engine};
    is_deeply($engine->{id_signal_inputs}, [qw(axi0_arid axi0_rid)], 'auto-ID lifecycle leaves response ID inputs to concrete checks only');
    is_deeply($engine->{residue}, [qw(same_id_ordering response_demux)], 'ID/response rule-engine residue reflects shipped auto-ID lifecycle behavior');

    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator report', 0);

    my $priority = $result->{generated_ial1_schedule_report}{priority_resolutions};
    ok((grep { ($_->{target} // '') eq 'axi0_awid' && ($_->{winner} // '') eq 'axi0_w0_auto_id_alloc_0' } @$priority), 'schedule report records generated allocation priority for AWID');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[3:0\]\s+axi0_awid\b/, 'SystemVerilog declares AWID as a generated 4-bit output');
    like($hdl, qr/\breg\s+\[3:0\]\s+axi0_w0_auto_id_q\b/, 'SystemVerilog declares selected-ID state');
    like($hdl, qr/\breg\s+axi0_w0_auto_id_busy_q\b/, 'SystemVerilog declares busy state');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 w0 auto ID available/, 'SystemVerilog assertion backend emits the no-ID-available check');
    like($sv_assertions, qr/axi0 write auto ID requests are mutually exclusive/, 'SystemVerilog assertion backend emits same-family mutual-exclusion check');
    like($sv_assertions, qr/axi0 write auto ID active selected IDs are unique/, 'SystemVerilog assertion backend emits same-ID avoidance check');
};

subtest 'response-demux contract generates bounded write BID demux behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_write_complete\)/, 'response-demux declares the raw write response event as an input');
    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'response-demux declares BID as a generated-width IAL1 input');
    unlike($isf, qr/\(input axi0_w0_complete\b/, 'response-demux does not treat w0 completion as an authored event input');
    unlike($isf, qr/\(input axi0_w1_complete\b/, 'response-demux does not treat w1 completion as an authored event input');
    like($isf, qr/\(output axi0_w0_complete\)/, 'response-demux exposes w0 completion as a generated pulse output');
    like($isf, qr/\(output axi0_w1_complete\)/, 'response-demux exposes w1 completion as a generated pulse output');
    like(
        $isf,
        qr/\(rule axi0_w0_response_demux \(& axi0_write_complete axi0_w0_auto_id_busy_q \(== axi0_bid axi0_w0_auto_id_q\)\)\s+\(pulse axi0_w0_complete\)\)/,
        'response-demux emits a guarded pulse rule for w0',
    );
    like(
        $isf,
        qr/\(rule axi0_w1_response_demux \(& axi0_write_complete axi0_w1_auto_id_busy_q \(== axi0_bid axi0_w1_auto_id_q\)\)\s+\(pulse axi0_w1_complete\)\)/,
        'response-demux emits a guarded pulse rule for w1',
    );
    like($isf, qr/"axi0 write response matches active auto-ID transaction"/, 'response-demux emits unmatched/inactive response assertion');
    like($isf, qr/"axi0 write response matches at most one auto-ID transaction"/, 'response-demux emits ambiguous-match assertion');
    like($isf, qr/"axi0 write auto ID active selected IDs are unique"/, 'response-demux keeps same-ID avoidance assertion');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_bid 4\)/, 'scheduled .fsm declares BID width');
    like(
        $fsm,
        qr/\(-axi0_w0_response_demux\s+<\(& axi0_write_complete axi0_w0_auto_id_busy_q \(== axi0_bid axi0_w0_auto_id_q\)\)[\s\S]*\(<1 \(axi0_w0_complete> 1\)\)/,
        'scheduled .fsm lowers w0 demux completion as a one-cycle pulse',
    );
    like(
        $fsm,
        qr/\(-axi0_w1_response_demux\s+<\(& axi0_write_complete axi0_w1_auto_id_busy_q \(== axi0_bid axi0_w1_auto_id_q\)\)[\s\S]*\(<1 \(axi0_w1_complete> 1\)\)/,
        'scheduled .fsm lowers w1 demux completion as a one-cycle pulse',
    );
    like($fsm, qr/\(-axi0_w0_auto_id_release\s+<\(& axi0_w0_complete axi0_w0_auto_id_busy_q\)/, 'auto-ID release remains driven by generated w0 completion pulse');
    like($fsm, qr/\(-write_complete_only_occ1\s+<\(& \(! \(\| axi0_w0_request axi0_w1_request\)\) \(\| axi0_w0_complete axi0_w1_complete\)/, 'write capacity release remains driven by generated completion pulse fan-in');

    assert_write_response_demux_report($result->{report}{response_demux}, 'generator report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator report', 1);
    is_deeply(
        $result->{report}{auto_id_lifecycle}{residue},
        [],
        'auto-ID lifecycle report removes response_demux and same-ID residue when generated demux and same-ID avoidance are covered',
    );
    is_deeply(
        $result->{report}{id_response_rule_engine}{residue},
        [qw(same_id_ordering)],
        'ID/response rule-engine removes response demux behavior from residue',
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_bid\b/, 'SystemVerilog declares BID as a 4-bit input');
    like($hdl, qr/\boutput\s+reg\s+axi0_w0_complete\b/, 'SystemVerilog declares generated w0 completion output');
    like($hdl, qr/\boutput\s+reg\s+axi0_w1_complete\b/, 'SystemVerilog declares generated w1 completion output');
    like($hdl, qr/axi0_write_complete\s*&\s*axi0_w0_auto_id_busy_q\s*&\s*\(axi0_bid\s*==\s*axi0_w0_auto_id_q\)/, 'SystemVerilog lowers the w0 BID demux guard');
    like($hdl, qr/axi0_w0_complete_pulse_delay_pipe\s*<=\s*axi0_w0_complete_1_en;/, 'SystemVerilog lowers w0 completion as delayed pulse logic');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 write response matches active auto-ID transaction/, 'assertion backend emits active-match response-demux assertion');
    like($sv_assertions, qr/axi0 write response matches at most one auto-ID transaction/, 'assertion backend emits unique-match response-demux assertion');
    like($sv_assertions, qr/axi0 write auto ID active selected IDs are unique/, 'assertion backend emits same-ID avoidance assertion');
};

subtest 'read response-demux contract generates bounded read RID demux behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_response_demux());
    my $isf = $result->{generated_ial1}{text};

    like($isf, qr/\(input axi0_read_complete\)/, 'read response-demux declares the raw read response event as an input');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'read response-demux declares RID as a generated-width IAL1 input');
    unlike($isf, qr/\(input axi0_r0_complete\b/, 'read response-demux does not treat r0 completion as an authored event input');
    unlike($isf, qr/\(input axi0_r1_complete\b/, 'read response-demux does not treat r1 completion as an authored event input');
    like($isf, qr/\(output axi0_r0_complete\)/, 'read response-demux exposes r0 completion as a generated pulse output');
    like($isf, qr/\(output axi0_r1_complete\)/, 'read response-demux exposes r1 completion as a generated pulse output');
    like(
        $isf,
        qr/\(rule axi0_r0_response_demux \(& axi0_read_complete axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\s+\(pulse axi0_r0_complete\)\)/,
        'read response-demux emits a guarded pulse rule for r0',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_auto_id_busy_q \(== axi0_rid axi0_r1_auto_id_q\)\)\s+\(pulse axi0_r1_complete\)\)/,
        'read response-demux emits a guarded pulse rule for r1',
    );
    like($isf, qr/"axi0 read response matches active auto-ID transaction"/, 'read response-demux emits unmatched/inactive response assertion');
    like($isf, qr/"axi0 read response matches at most one auto-ID transaction"/, 'read response-demux emits ambiguous-match assertion');
    like($isf, qr/"axi0 read auto ID active selected IDs are unique"/, 'read response-demux keeps same-ID avoidance assertion');

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/\(\+size[\s\S]*\(axi0_rid 4\)/, 'scheduled .fsm declares RID width');
    like(
        $fsm,
        qr/\(-axi0_r0_response_demux\s+<\(& axi0_read_complete axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)[\s\S]*\(<1 \(axi0_r0_complete> 1\)\)/,
        'scheduled .fsm lowers r0 demux completion as a one-cycle pulse',
    );
    like(
        $fsm,
        qr/\(-axi0_r1_response_demux\s+<\(& axi0_read_complete axi0_r1_auto_id_busy_q \(== axi0_rid axi0_r1_auto_id_q\)\)[\s\S]*\(<1 \(axi0_r1_complete> 1\)\)/,
        'scheduled .fsm lowers r1 demux completion as a one-cycle pulse',
    );
    like($fsm, qr/\(-axi0_r0_auto_id_release\s+<\(& axi0_r0_complete axi0_r0_auto_id_busy_q\)/, 'auto-ID release is driven by generated r0 completion pulse');
    like($fsm, qr/\(-read_complete_only_occ1\s+<\(& \(! \(\| axi0_r0_request axi0_r1_request\)\) \(\| axi0_r0_complete axi0_r1_complete\)/, 'read capacity release is driven by generated completion pulse fan-in');

    assert_read_response_demux_report($result->{report}{response_demux}, 'generator report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator report', 1, 'read');
    is_deeply(
        $result->{report}{auto_id_lifecycle}{residue},
        [],
        'read auto-ID lifecycle report removes response_demux and same-ID residue when generated demux and same-ID avoidance are covered',
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog declares RID as a 4-bit input');
    like($hdl, qr/\boutput\s+reg\s+axi0_r0_complete\b/, 'SystemVerilog declares generated r0 completion output');
    like($hdl, qr/\boutput\s+reg\s+axi0_r1_complete\b/, 'SystemVerilog declares generated r1 completion output');
    like($hdl, qr/axi0_read_complete\s*&\s*axi0_r0_auto_id_busy_q\s*&\s*\(axi0_rid\s*==\s*axi0_r0_auto_id_q\)/, 'SystemVerilog lowers the r0 RID demux guard');

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read response matches active auto-ID transaction/, 'assertion backend emits active-match read response-demux assertion');
    like($sv_assertions, qr/axi0 read response matches at most one auto-ID transaction/, 'assertion backend emits unique-match read response-demux assertion');
    like($sv_assertions, qr/axi0 read auto ID active selected IDs are unique/, 'assertion backend emits read same-ID avoidance assertion');
};

subtest 'burst-last read response-demux generates RLAST-gated completion behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_response_demux_burst_last());
    my $isf = $result->{generated_ial1}{text};

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
    like(
        $isf,
        qr/\(rule axi0_r1_response_demux \(& axi0_read_complete axi0_r1_auto_id_busy_q \(== axi0_rid axi0_r1_auto_id_q\) axi0_rlast\)\s+\(pulse axi0_r1_complete\)\)/s,
        'burst-last behavior emits RLAST-gated r1 completion rule',
    );

    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    like($fsm, qr/axi0_rlast/, 'burst-last behavior lowers RLAST into generated IAL0');
    like($fsm, qr/-axi0_r0_response_demux <\(& axi0_read_complete axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\) axi0_rlast\)/, 'burst-last behavior lowers RLAST-gated r0 rule to IAL0');

    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator burst-last report');
    assert_rlast_report_prose_alignment($result->{report}, 'generator burst-last report');
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator burst-last report', 1, 'read');
    is_deeply(
        $result->{report}{auto_id_lifecycle}{residue},
        [],
        'burst-last behavior removes generated read demux from auto-ID lifecycle residue',
    );

    my $sv_assertions = sv_assertion_block_for_result($result);
    like($sv_assertions, qr/axi0 read response matches active auto-ID transaction/, 'assertion backend emits burst-last active-match assertion');
    like($sv_assertions, qr/axi0 read response matches at most one auto-ID transaction/, 'assertion backend emits burst-last unique-match assertion');
};

subtest 'read-data contract generates single-beat capture behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'read-data behavior declares RDATA as a generated 32-bit input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'read-data behavior declares RRESP as a generated 2-bit input');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'read-data behavior declares r0 data output with inherited width');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'read-data behavior declares r0 status output with inherited width');
    like($isf, qr/\(output axi0_r1_rdata \(width 32\)\)/, 'read-data behavior declares r1 data output with inherited width');
    like($isf, qr/\(output axi0_r1_rresp \(width 2\)\)/, 'read-data behavior declares r1 status output with inherited width');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'read-data behavior emits r0 normal capture assignments guarded by generated completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/,
        'read-data behavior emits r1 normal capture assignments guarded by generated completion',
    );
    unlike($isf, qr/\(rule axi0_r0_read_data_capture\b[\s\S]*\(pulse axi0_r0_rdata\)/, 'read-data capture does not pulse payload outputs');
    like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r0 capture assignments');
    like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r1 capture assignments');

    assert_read_response_demux_report($result->{report}{response_demux}, 'generator read-data report');
    assert_read_data_report($result->{report}{read_data}, 'generator report');
    is_deeply(
        $result->{report}{response_demux}{residue},
        [qw(read_data_interleaving bursts)],
        'read-data behavior keeps broader response-demux interleaving and burst residue',
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog declares RDATA as a 32-bit input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog declares RRESP as a 2-bit input');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_rdata\b/, 'SystemVerilog declares r0 captured data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'SystemVerilog declares r0 captured status output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog drives r0 capture from generated completion');
    like($hdl, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures RDATA into r0 data output');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures RRESP into r0 status output');
};

subtest 'read-data contract consumes generated read single-beat same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head read-data contract keeps r0 concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r1_q\)/, 'queue-head read-data contract keeps r1 concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'queue-head read-data contract declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'queue-head read-data contract declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r0_rdata \(width 32\)\)/, 'queue-head read-data contract declares r0 data output');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'queue-head read-data contract declares r0 status output');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_rdata axi0_rdata\)\s+\(axi0_r0_rresp axi0_rresp\)\)/,
        'queue-head read-data contract guards r0 capture with generated queue-head completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_rdata axi0_rdata\)\s+\(axi0_r1_rresp axi0_rresp\)\)/,
        'queue-head read-data contract guards r1 capture with generated queue-head completion',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'queue-head read-data single-beat contract does not generate or consume RLAST');
    like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r0 queue-head read-data capture assignments');
    like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r1 queue-head read-data capture assignments');

    assert_same_id_read_single_beat_queue_head_response_demux_report($result->{report}{response_demux}, 'generator queue-head read-data response-demux report');
    assert_read_data_report(
        $result->{report}{read_data},
        'generator queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head read-data behavior keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head read-data behavior keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for queue-head demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_rdata\b/, 'SystemVerilog exposes r0 queue-head captured data output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog drives r0 queue-head read-data capture from generated completion');
    like($hdl, qr/axi0_r0_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures queue-head RDATA into r0 output');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures queue-head RRESP into r0 output');
};

subtest 'read-data contract consumes generated read single-beat multi-group same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_multi_group_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'multi-group queue-head read-data keeps r0 concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'multi-group queue-head read-data keeps r3 concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-group queue-head read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-group queue-head read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r2_rdata \(width 32\)\)/, 'multi-group queue-head read-data declares r2 data output');
    like($isf, qr/\(output axi0_r3_rresp \(width 2\)\)/, 'multi-group queue-head read-data declares r3 status output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_rdata axi0_rdata\)\s+\(axi0_r2_rresp axi0_rresp\)\)/,
        'multi-group queue-head read-data guards r2 capture with generated queue-head completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r3_read_data_capture axi0_r3_complete\s+\(axi0_r3_rdata axi0_rdata\)\s+\(axi0_r3_rresp axi0_rresp\)\)/,
        'multi-group queue-head read-data guards r3 capture with generated queue-head completion',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'multi-group queue-head read-data single-beat contract does not generate or consume RLAST');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r2 multi-group queue-head read-data capture assignments');
    like($fsm, qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r3 multi-group queue-head read-data capture assignments');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group queue-head read-data response-demux report',
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
        'generator multi-group queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for multi-group queue-head demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for multi-group queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r3_rdata\b/, 'SystemVerilog exposes r3 multi-group queue-head captured data output');
    like($hdl, qr/assign\s+axi0_r3_read_data_capture_en\s*=\s*axi0_r3_complete\s*;/, 'SystemVerilog drives r3 multi-group queue-head read-data capture from generated completion');
    like($hdl, qr/axi0_r3_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-group queue-head RDATA into r3 output');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r3_q/, 'SystemVerilog keeps concrete RID 5 queue-head demux guard for r3');
};

subtest 'read-data contract consumes generated read single-beat multiple depth-3 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'multi-depth-3 queue-head read-data keeps r2 concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'multi-depth-3 queue-head read-data keeps r5 concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-depth-3 queue-head read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-depth-3 queue-head read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r5_rdata \(width 32\)\)/, 'multi-depth-3 queue-head read-data declares r5 data output');
    like($isf, qr/\(output axi0_r5_rresp \(width 2\)\)/, 'multi-depth-3 queue-head read-data declares r5 status output');
    like(
        $isf,
        qr/\(rule axi0_r5_read_data_capture axi0_r5_complete\s+\(axi0_r5_rdata axi0_rdata\)\s+\(axi0_r5_rresp axi0_rresp\)\)/,
        'multi-depth-3 queue-head read-data guards r5 capture with generated queue-head completion',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'multi-depth-3 queue-head read-data single-beat contract does not generate or consume RLAST');
    like($fsm, qr/\(-axi0_r5_read_data_capture\s+<axi0_r5_complete\s+\(<- \(axi0_r5_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r5_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r5 multi-depth-3 queue-head read-data capture assignments');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $result->{report}{read_data},
        'generator multi-depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4 r5)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for multi-depth-3 queue-head read-data demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for multi-depth-3 queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r5_rdata\b/, 'SystemVerilog exposes r5 multi-depth-3 queue-head captured data output');
    like($hdl, qr/assign\s+axi0_r5_read_data_capture_en\s*=\s*axi0_r5_complete\s*;/, 'SystemVerilog drives r5 multi-depth-3 queue-head read-data capture from generated completion');
    like($hdl, qr/axi0_r5_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-depth-3 queue-head RDATA into r5 output');
    like($hdl, qr/axi0_r5_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures multi-depth-3 queue-head RRESP into r5 output');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/, 'SystemVerilog keeps concrete RID 5 depth-3 queue-head demux guard for r5');
};

subtest 'read-data contract consumes generated read single-beat mixed depth-3/depth-2 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'mixed-depth queue-head read-data keeps r2 concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'mixed-depth queue-head read-data keeps r4 concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'mixed-depth queue-head read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'mixed-depth queue-head read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r4_rdata \(width 32\)\)/, 'mixed-depth queue-head read-data declares r4 data output');
    like($isf, qr/\(output axi0_r4_rresp \(width 2\)\)/, 'mixed-depth queue-head read-data declares r4 status output');
    like(
        $isf,
        qr/\(rule axi0_r4_read_data_capture axi0_r4_complete\s+\(axi0_r4_rdata axi0_rdata\)\s+\(axi0_r4_rresp axi0_rresp\)\)/,
        'mixed-depth queue-head read-data guards r4 capture with generated queue-head completion',
    );
    unlike($isf, qr/\baxi0_rlast\b/, 'mixed-depth queue-head read-data single-beat contract does not generate or consume RLAST');
    like($fsm, qr/\(-axi0_r4_read_data_capture\s+<axi0_r4_complete\s+\(<- \(axi0_r4_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r4_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r4 mixed-depth queue-head read-data capture assignments');

    assert_same_id_read_single_beat_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator mixed-depth queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    assert_read_data_report(
        $result->{report}{read_data},
        'generator mixed-depth queue-head read-data report',
        'generated_queue_head_response_demux_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for mixed-depth queue-head read-data demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for mixed-depth queue-head read-data capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r4_rdata\b/, 'SystemVerilog exposes r4 mixed-depth queue-head captured data output');
    like($hdl, qr/assign\s+axi0_r4_read_data_capture_en\s*=\s*axi0_r4_complete\s*;/, 'SystemVerilog drives r4 mixed-depth queue-head read-data capture from generated completion');
    like($hdl, qr/axi0_r4_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures mixed-depth queue-head RDATA into r4 output');
    like($hdl, qr/axi0_r4_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures mixed-depth queue-head RRESP into r4 output');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/, 'SystemVerilog keeps concrete RID 5 depth-2 queue-head demux guard for r4');
};

subtest 'read-data contract consumes generated read burst-last same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_last_beat_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head last-beat read-data keeps r0 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r1_q\)/, 'queue-head last-beat read-data keeps r1 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'queue-head last-beat read-data declares RLAST as a generated input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'queue-head last-beat read-data declares RDATA as a generated input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'queue-head last-beat read-data declares RRESP as a generated input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'queue-head last-beat read-data declares r0 last data output');
    like($isf, qr/\(output axi0_r0_last_rresp \(width 2\)\)/, 'queue-head last-beat read-data declares r0 last status output');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'queue-head last-beat read-data guards r0 capture with generated queue-head last-beat completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/,
        'queue-head last-beat read-data guards r1 capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'queue-head last-beat read-data does not generate ARLEN capture in this slice');
    like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r0 queue-head last-beat read-data capture assignments');
    like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r1 queue-head last-beat read-data capture assignments');

    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'generator queue-head last-beat read-data response-demux report');
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'generator queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head last-beat read-data behavior keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head last-beat read-data behavior keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for queue-head last-beat demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes generated RLAST input for queue-head last-beat demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input for queue-head last-beat capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_last_rdata\b/, 'SystemVerilog exposes r0 queue-head last-beat captured data output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog drives r0 queue-head last-beat capture from generated completion');
    like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures queue-head last-beat RDATA into r0 output');
    like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures queue-head last-beat RRESP into r0 output');
};

subtest 'read-data multi-group queue-head last-beat contract generates scalar capture behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_group_queue_head_last_beat_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'multi-group queue-head last-beat read-data emits r2 RID5 response-demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'multi-group queue-head last-beat read-data emits r3 RID5 response-demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'multi-group queue-head last-beat read-data declares RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-group queue-head last-beat read-data declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-group queue-head last-beat read-data declares generated RRESP input');
    like($isf, qr/\(output axi0_r2_last_rdata \(width 32\)\)/, 'multi-group queue-head last-beat read-data declares r2 scalar data output');
    like($isf, qr/\(output axi0_r2_last_rresp \(width 2\)\)/, 'multi-group queue-head last-beat read-data declares r2 scalar status output');
    like($isf, qr/\(output axi0_r3_last_rdata \(width 32\)\)/, 'multi-group queue-head last-beat read-data declares r3 scalar data output');
    like($isf, qr/\(output axi0_r3_last_rresp \(width 2\)\)/, 'multi-group queue-head last-beat read-data declares r3 scalar status output');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'multi-group queue-head last-beat read-data guards r2 scalar capture with generated queue-head last-beat completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r3_read_data_capture axi0_r3_complete\s+\(axi0_r3_last_rdata axi0_rdata\)\s+\(axi0_r3_last_rresp axi0_rresp\)\)/,
        'multi-group queue-head last-beat read-data guards r3 scalar capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'multi-group queue-head last-beat read-data does not generate ARLEN capture');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r2 multi-group queue-head last-beat capture assignments');
    like($fsm, qr/\(-axi0_r3_read_data_capture\s+<axi0_r3_complete\s+\(<- \(axi0_r3_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r3_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r3 multi-group queue-head last-beat capture assignments');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group queue-head last-beat response-demux report',
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
        'generator multi-group queue-head last-beat read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for multi-group queue-head last-beat demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes generated RLAST input for multi-group queue-head last-beat demux');
    unlike($hdl, qr/\baxi0_arlen\b/, 'SystemVerilog omits ARLEN for multi-group queue-head scalar last-beat capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_last_rdata\b/, 'SystemVerilog exposes r2 multi-group queue-head last-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_last_rresp\b/, 'SystemVerilog exposes r2 multi-group queue-head last-beat status output');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog drives r2 multi-group last-beat capture from generated completion');
    like($hdl, qr/axi0_r2_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-group r2 last-beat RDATA');
    like($hdl, qr/axi0_r2_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures multi-group r2 last-beat RRESP');
};

subtest 'read-data contract consumes generated read burst-last multiple depth-3 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'burst-last multi-depth-3 queue-head read-data keeps r2 RLAST-gated demux rule');
    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'burst-last multi-depth-3 queue-head read-data keeps r5 RLAST-gated demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'burst-last multi-depth-3 queue-head read-data declares RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'burst-last multi-depth-3 queue-head read-data declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'burst-last multi-depth-3 queue-head read-data declares generated RRESP input');
    like($isf, qr/\(output axi0_r5_last_rdata \(width 32\)\)/, 'burst-last multi-depth-3 queue-head read-data declares r5 scalar data output');
    like($isf, qr/\(output axi0_r5_last_rresp \(width 2\)\)/, 'burst-last multi-depth-3 queue-head read-data declares r5 scalar status output');
    like(
        $isf,
        qr/\(rule axi0_r5_read_data_capture axi0_r5_complete\s+\(axi0_r5_last_rdata axi0_rdata\)\s+\(axi0_r5_last_rresp axi0_rresp\)\)/,
        'burst-last multi-depth-3 queue-head read-data guards r5 scalar capture with generated last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'burst-last multi-depth-3 queue-head read-data does not generate ARLEN capture');
    like($fsm, qr/\(-axi0_r5_read_data_capture\s+<axi0_r5_complete\s+\(<- \(axi0_r5_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r5_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r5 burst-last multi-depth-3 capture assignments');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator burst-last multi-depth-3 queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'generator burst-last multi-depth-3 queue-head read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4 r5)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for burst-last multi-depth-3 queue-head demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes generated RLAST input for burst-last multi-depth-3 queue-head demux');
    unlike($hdl, qr/\baxi0_arlen\b/, 'SystemVerilog omits ARLEN for burst-last multi-depth-3 scalar last-beat capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r5_last_rdata\b/, 'SystemVerilog exposes r5 burst-last multi-depth-3 last-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r5_last_rresp\b/, 'SystemVerilog exposes r5 burst-last multi-depth-3 last-beat status output');
    like($hdl, qr/assign\s+axi0_r5_read_data_capture_en\s*=\s*axi0_r5_complete\s*;/, 'SystemVerilog drives r5 burst-last multi-depth-3 capture from generated completion');
    like($hdl, qr/axi0_r5_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures burst-last multi-depth-3 r5 last-beat RDATA');
    like($hdl, qr/axi0_r5_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures burst-last multi-depth-3 r5 last-beat RRESP');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r5_q/, 'SystemVerilog keeps RLAST-gated RID 5 depth-3 queue-head demux guard for r5');
};

subtest 'read-data contract consumes generated read burst-last mixed depth-3/depth-2 same-ID queue-head demux' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/, 'burst-last mixed-depth queue-head read-data keeps r2 RLAST-gated demux rule');
    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'burst-last mixed-depth queue-head read-data keeps r4 RLAST-gated demux rule');
    like($isf, qr/\(input axi0_rlast\)/, 'burst-last mixed-depth queue-head read-data declares RLAST input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'burst-last mixed-depth queue-head read-data declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'burst-last mixed-depth queue-head read-data declares generated RRESP input');
    like($isf, qr/\(output axi0_r4_last_rdata \(width 32\)\)/, 'burst-last mixed-depth queue-head read-data declares r4 scalar data output');
    like($isf, qr/\(output axi0_r4_last_rresp \(width 2\)\)/, 'burst-last mixed-depth queue-head read-data declares r4 scalar status output');
    like(
        $isf,
        qr/\(rule axi0_r4_read_data_capture axi0_r4_complete\s+\(axi0_r4_last_rdata axi0_rdata\)\s+\(axi0_r4_last_rresp axi0_rresp\)\)/,
        'burst-last mixed-depth queue-head read-data guards r4 scalar capture with generated last-beat completion',
    );
    unlike($isf, qr/\baxi0_arlen\b/, 'burst-last mixed-depth queue-head read-data does not generate ARLEN capture');
    like($fsm, qr/\(-axi0_r4_read_data_capture\s+<axi0_r4_complete\s+\(<- \(axi0_r4_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r4_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r4 burst-last mixed-depth capture assignments');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator burst-last mixed-depth queue-head read-data response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    assert_read_data_last_beat_report(
        $result->{report}{read_data},
        'generator burst-last mixed-depth queue-head read-data report',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, 'SystemVerilog exposes generated RID input for burst-last mixed-depth queue-head demux');
    like($hdl, qr/\binput\s+(?:wire\s+)?axi0_rlast\b/, 'SystemVerilog exposes generated RLAST input for burst-last mixed-depth queue-head demux');
    unlike($hdl, qr/\baxi0_arlen\b/, 'SystemVerilog omits ARLEN for burst-last mixed-depth scalar last-beat capture');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r4_last_rdata\b/, 'SystemVerilog exposes r4 burst-last mixed-depth last-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r4_last_rresp\b/, 'SystemVerilog exposes r4 burst-last mixed-depth last-beat status output');
    like($hdl, qr/assign\s+axi0_r4_read_data_capture_en\s*=\s*axi0_r4_complete\s*;/, 'SystemVerilog drives r4 burst-last mixed-depth capture from generated completion');
    like($hdl, qr/axi0_r4_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures burst-last mixed-depth r4 last-beat RDATA');
    like($hdl, qr/axi0_r4_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures burst-last mixed-depth r4 last-beat RRESP');
    like($hdl, qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd5\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id5_same_id_issue_order_slot0_r4_q/, 'SystemVerilog keeps RLAST-gated RID 5 depth-2 queue-head demux guard for r4');
};

subtest 'read-data burst-last multi-depth-3 queue-head contract generates raw ARLEN burst-length capture' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'burst-last multi-depth-3 queue-head burst-length emits r5 RID5 response-demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'burst-last multi-depth-3 queue-head burst-length declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r5_arlen_q \(width 8\)\)/, 'burst-last multi-depth-3 queue-head burst-length declares r5 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r5_burst_length_capture axi0_r5_request\s+\(axi0_r5_arlen_q axi0_arlen\)\)/, 'burst-last multi-depth-3 queue-head burst-length captures r5 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r5_read_data_capture axi0_r5_complete\s+\(axi0_r5_last_rdata axi0_rdata\)\s+\(axi0_r5_last_rresp axi0_rresp\)\)/,
        'burst-last multi-depth-3 queue-head burst-length still guards r5 scalar capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'burst-last multi-depth-3 queue-head report-only burst-length does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'burst-last multi-depth-3 queue-head report-only burst-length does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r5_burst_length_capture\s+<axi0_r5_request\s+\(<- \(axi0_r5_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r5 multi-depth-3 raw ARLEN capture');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator burst-last multi-depth-3 queue-head burst-length response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator burst-last multi-depth-3 queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4 r5)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for burst-last multi-depth-3 burst-length capture');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r5_arlen_q\b/, 'SystemVerilog declares r5 multi-depth-3 raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r5_burst_length_capture_en\s*=\s*axi0_r5_request\s*;/, 'SystemVerilog guards r5 multi-depth-3 ARLEN capture with request');
    like($hdl, qr/axi0_r5_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r5 multi-depth-3 storage');
    like($hdl, qr/assign\s+axi0_r5_read_data_capture_en\s*=\s*axi0_r5_complete\s*;/, 'SystemVerilog keeps r5 scalar capture on generated last-beat completion');
    unlike($hdl, qr/\bexpected_beats_q\b/, 'SystemVerilog omits expected-beat storage for burst-last multi-depth-3 report-only burst-length');
    unlike($hdl, qr/\bread_beat_count_q\b/, 'SystemVerilog omits beat-count storage for burst-last multi-depth-3 report-only burst-length');
};

subtest 'read-data burst-last mixed depth-3/depth-2 queue-head contract generates raw ARLEN burst-length capture' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'burst-last mixed-depth queue-head burst-length emits r4 RID5 response-demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'burst-last mixed-depth queue-head burst-length declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r4_arlen_q \(width 8\)\)/, 'burst-last mixed-depth queue-head burst-length declares r4 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r4_burst_length_capture axi0_r4_request\s+\(axi0_r4_arlen_q axi0_arlen\)\)/, 'burst-last mixed-depth queue-head burst-length captures r4 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r4_read_data_capture axi0_r4_complete\s+\(axi0_r4_last_rdata axi0_rdata\)\s+\(axi0_r4_last_rresp axi0_rresp\)\)/,
        'burst-last mixed-depth queue-head burst-length still guards r4 scalar capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'burst-last mixed-depth queue-head report-only burst-length does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'burst-last mixed-depth queue-head report-only burst-length does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r4_burst_length_capture\s+<axi0_r4_request\s+\(<- \(axi0_r4_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r4 mixed-depth raw ARLEN capture');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator burst-last mixed-depth queue-head burst-length response-demux report',
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator burst-last mixed-depth queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for burst-last mixed-depth burst-length capture');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r4_arlen_q\b/, 'SystemVerilog declares r4 mixed-depth raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r4_burst_length_capture_en\s*=\s*axi0_r4_request\s*;/, 'SystemVerilog guards r4 mixed-depth ARLEN capture with request');
    like($hdl, qr/axi0_r4_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r4 mixed-depth storage');
    like($hdl, qr/assign\s+axi0_r4_read_data_capture_en\s*=\s*axi0_r4_complete\s*;/, 'SystemVerilog keeps r4 scalar capture on generated last-beat completion');
    unlike($hdl, qr/\bexpected_beats_q\b/, 'SystemVerilog omits expected-beat storage for burst-last mixed-depth report-only burst-length');
    unlike($hdl, qr/\bread_beat_count_q\b/, 'SystemVerilog omits beat-count storage for burst-last mixed-depth report-only burst-length');
};

subtest 'read-data burst-last multi-depth-3 queue-head contract generates runtime beat-count validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(var axi0_r5_expected_beats_q \(width 5\)\)/, 'burst-last multi-depth-3 runtime validation declares r5 expected-beat storage');
    like($isf, qr/\(var axi0_r5_read_beat_count_q \(width 5\)\)/, 'burst-last multi-depth-3 runtime validation declares r5 beat-count storage');
    like($isf, qr/\(rule axi0_r5_beat_count_init axi0_r5_request\s+\(axi0_r5_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r5_read_beat_count_q 0\)\)/, 'burst-last multi-depth-3 runtime validation initializes r5 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r5_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)\) \(! axi0_r5_request\)\)\s+\(axi0_r5_read_beat_count_q \(\+ axi0_r5_read_beat_count_q 5'd1\)\)\)/, 'burst-last multi-depth-3 runtime validation increments r5 count on raw matched RID5 queue-head beat');
    like($fsm, qr/\(-axi0_r5_beat_count_init\s+<axi0_r5_request\s+\(<- \(axi0_r5_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r5_read_beat_count_q 0\)\)/, 'scheduled .fsm carries r5 multi-depth-3 expected-beat initialization');
    like($fsm, qr/\(-axi0_r5_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)\) \(! axi0_r5_request\)\)\s+\(<- \(axi0_r5_read_beat_count_q \(\+ axi0_r5_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r5 multi-depth-3 matched-beat increment');

    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator burst-last multi-depth-3 queue-head runtime-validation read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4 r5)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r5_expected_beats_q\b/, 'SystemVerilog declares r5 multi-depth-3 expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r5_read_beat_count_q\b/, 'SystemVerilog declares r5 multi-depth-3 beat-count storage');
    like($hdl, qr/axi0_r5_read_beat_count_q_next\s*=\s*axi0_r5_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments r5 multi-depth-3 beat count');
    like($hdl, qr/assign\s+axi0_r5_read_beat_count_en\s*=/, 'SystemVerilog emits r5 multi-depth-3 beat-count increment enable');
};

subtest 'read-data burst-last mixed depth-3/depth-2 queue-head contract generates runtime beat-count validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(var axi0_r4_expected_beats_q \(width 5\)\)/, 'burst-last mixed-depth runtime validation declares r4 expected-beat storage');
    like($isf, qr/\(var axi0_r4_read_beat_count_q \(width 5\)\)/, 'burst-last mixed-depth runtime validation declares r4 beat-count storage');
    like($isf, qr/\(rule axi0_r4_beat_count_init axi0_r4_request\s+\(axi0_r4_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r4_read_beat_count_q 0\)\)/, 'burst-last mixed-depth runtime validation initializes r4 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r4_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)\) \(! axi0_r4_request\)\)\s+\(axi0_r4_read_beat_count_q \(\+ axi0_r4_read_beat_count_q 5'd1\)\)\)/, 'burst-last mixed-depth runtime validation increments r4 count on raw matched RID5 queue-head beat');
    like($fsm, qr/\(-axi0_r4_beat_count_init\s+<axi0_r4_request\s+\(<- \(axi0_r4_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r4_read_beat_count_q 0\)\)/, 'scheduled .fsm carries r4 mixed-depth expected-beat initialization');
    like($fsm, qr/\(-axi0_r4_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)\) \(! axi0_r4_request\)\)\s+\(<- \(axi0_r4_read_beat_count_q \(\+ axi0_r4_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r4 mixed-depth matched-beat increment');

    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator burst-last mixed-depth queue-head runtime-validation read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r4_expected_beats_q\b/, 'SystemVerilog declares r4 mixed-depth expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r4_read_beat_count_q\b/, 'SystemVerilog declares r4 mixed-depth beat-count storage');
    like($hdl, qr/axi0_r4_read_beat_count_q_next\s*=\s*axi0_r4_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments r4 mixed-depth beat count');
    like($hdl, qr/assign\s+axi0_r4_read_beat_count_en\s*=/, 'SystemVerilog emits r4 mixed-depth beat-count increment enable');
};

subtest 'read-data burst-last multi-depth-3 queue-head contract generates multi-beat output-bank behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_multi_beat_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r5_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r5_q\)/, 'multi-depth-3 multi-beat emits r5 RID5 RLAST-gated queue-head demux rule');
    like($isf, qr/\(output axi0_r5_beat_rdata_0 \(width 32\)\)/, 'multi-depth-3 multi-beat declares r5 beat 0 data output');
    like($isf, qr/\(output axi0_r5_beat_rresp_0 \(width 2\)\)/, 'multi-depth-3 multi-beat declares r5 beat 0 status output');
    like($isf, qr/\(output axi0_r5_rresp \(width 2\)\)/, 'multi-depth-3 multi-beat declares r5 scalar aggregate status output');
    like($isf, qr/\(output axi0_r5_beat_valid \(width 16\)\)/, 'multi-depth-3 multi-beat declares r5 valid-mask output');
    like($isf, qr/\(output axi0_r5_read_beats \(width 5\)\)/, 'multi-depth-3 multi-beat declares r5 length output');
    like($isf, qr/\(var axi0_r5_expected_beats_q \(width 5\)\)/, 'multi-depth-3 multi-beat keeps r5 expected-beat storage');
    like($isf, qr/\(var axi0_r5_read_beat_count_q \(width 5\)\)/, 'multi-depth-3 multi-beat keeps r5 beat-count storage');
    like($isf, qr/\(rule axi0_r5_read_data_output_init axi0_r5_request[\s\S]*\(axi0_r5_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r5_rresp 2'd0\)[\s\S]*\(axi0_r5_beat_valid 16'b0\)[\s\S]*\(axi0_r5_read_beats 5'd0\)\)/, 'multi-depth-3 multi-beat clears r5 output bank and aggregate on request');
    like($isf, qr/\(rule axi0_r5_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)\) \(! axi0_r5_request\) \(== axi0_r5_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r5_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r5_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r5_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r5_read_beats 5'd1\)\)/, 'multi-depth-3 multi-beat captures r5 lane 0 with RID5 matched queue-head beat');
    like($isf, qr/\(rule axi0_r5_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)\) \(! axi0_r5_request\) \(< axi0_r5_rresp axi0_rresp\)\)\s+\(axi0_r5_rresp axi0_rresp\)\)/, 'multi-depth-3 multi-beat updates r5 scalar aggregate on RID5 matched beat');
    like($fsm, qr/\(-axi0_r5_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r5_q\)\) \(! axi0_r5_request\) \(== axi0_r5_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r5_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r5_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r5_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r5_read_beats> 5'd1\)\)/, 'scheduled .fsm captures multi-depth-3 r5 lane 0 payload, valid mask, and length');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-depth-3 queue-head multi-beat response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4 r5)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete axi0_r5_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux axi0_r5_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r0_r5_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r1_r5_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r2_r5_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
            axi0_r3_r5_read_response_demux_unique_match
            axi0_r4_r5_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'generator multi-depth-3 queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4 r5)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r5_beat_rdata_0\b/, 'SystemVerilog exposes multi-depth-3 r5 per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r5_rresp\b/, 'SystemVerilog exposes multi-depth-3 r5 scalar aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r5_beat_valid\b/, 'SystemVerilog exposes multi-depth-3 r5 valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r5_read_beats\b/, 'SystemVerilog exposes multi-depth-3 r5 length output');
    like($hdl, qr/assign\s+axi0_r5_read_data_output_init_en\s*=\s*axi0_r5_request\s*;/, 'SystemVerilog drives multi-depth-3 r5 output-bank clear from request');
    like($hdl, qr/assign\s+axi0_r5_read_beat_0_capture_en\s*=/, 'SystemVerilog emits multi-depth-3 r5 lane 0 capture enable');
    like($hdl, qr/axi0_read_id5_same_id_issue_order_slot0_r5_q/, 'SystemVerilog multi-depth-3 lane capture references RID5 slot-0 transaction identity');
    like($hdl, qr/axi0_r5_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-depth-3 r5 lane 0 data');
    like($hdl, qr/axi0_r5_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates multi-depth-3 r5 scalar aggregate from current RRESP');
};

subtest 'read-data burst-last mixed depth-3/depth-2 queue-head contract generates multi-beat output-bank behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_multi_beat_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r4_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r4_q\)/, 'mixed-depth multi-beat emits r4 RID5 RLAST-gated queue-head demux rule');
    like($isf, qr/\(output axi0_r4_beat_rdata_0 \(width 32\)\)/, 'mixed-depth multi-beat declares r4 beat 0 data output');
    like($isf, qr/\(output axi0_r4_beat_rresp_0 \(width 2\)\)/, 'mixed-depth multi-beat declares r4 beat 0 status output');
    like($isf, qr/\(output axi0_r4_rresp \(width 2\)\)/, 'mixed-depth multi-beat declares r4 scalar aggregate status output');
    like($isf, qr/\(output axi0_r4_beat_valid \(width 16\)\)/, 'mixed-depth multi-beat declares r4 valid-mask output');
    like($isf, qr/\(output axi0_r4_read_beats \(width 5\)\)/, 'mixed-depth multi-beat declares r4 length output');
    like($isf, qr/\(var axi0_r4_expected_beats_q \(width 5\)\)/, 'mixed-depth multi-beat keeps r4 expected-beat storage');
    like($isf, qr/\(var axi0_r4_read_beat_count_q \(width 5\)\)/, 'mixed-depth multi-beat keeps r4 beat-count storage');
    like($isf, qr/\(rule axi0_r4_read_data_output_init axi0_r4_request[\s\S]*\(axi0_r4_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r4_rresp 2'd0\)[\s\S]*\(axi0_r4_beat_valid 16'b0\)[\s\S]*\(axi0_r4_read_beats 5'd0\)\)/, 'mixed-depth multi-beat clears r4 output bank and aggregate on request');
    like($isf, qr/\(rule axi0_r4_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)\) \(! axi0_r4_request\) \(== axi0_r4_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r4_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r4_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r4_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r4_read_beats 5'd1\)\)/, 'mixed-depth multi-beat captures r4 lane 0 with RID5 matched queue-head beat');
    like($isf, qr/\(rule axi0_r4_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)\) \(! axi0_r4_request\) \(< axi0_r4_rresp axi0_rresp\)\)\s+\(axi0_r4_rresp axi0_rresp\)\)/, 'mixed-depth multi-beat updates r4 scalar aggregate on RID5 matched beat');
    like($fsm, qr/\(-axi0_r4_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r4_q\)\) \(! axi0_r4_request\) \(== axi0_r4_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r4_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r4_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r4_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r4_read_beats> 5'd1\)\)/, 'scheduled .fsm captures mixed-depth r4 lane 0 payload, valid mask, and length');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator mixed-depth queue-head multi-beat response-demux report',
        residue => [],
        queues => [
            {
                concrete_id          => 3,
                transactions         => [qw(r0 r1 r2)],
                depth                => 3,
                dequeue_event_source => 'queue_head_response_demux',
            },
            {
                concrete_id          => 5,
                transactions         => [qw(r3 r4)],
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
            },
        ],
        completion_signals => [qw(axi0_r0_complete axi0_r1_complete axi0_r2_complete axi0_r3_complete axi0_r4_complete)],
        generated_rules => [qw(axi0_r0_response_demux axi0_r1_response_demux axi0_r2_response_demux axi0_r3_response_demux axi0_r4_response_demux)],
        generated_assertions => [qw(
            axi0_read_response_demux_active_match
            axi0_r0_r1_read_response_demux_unique_match
            axi0_r0_r2_read_response_demux_unique_match
            axi0_r0_r3_read_response_demux_unique_match
            axi0_r0_r4_read_response_demux_unique_match
            axi0_r1_r2_read_response_demux_unique_match
            axi0_r1_r3_read_response_demux_unique_match
            axi0_r1_r4_read_response_demux_unique_match
            axi0_r2_r3_read_response_demux_unique_match
            axi0_r2_r4_read_response_demux_unique_match
            axi0_r3_r4_read_response_demux_unique_match
        )],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'generator mixed-depth queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3 r4)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r4_beat_rdata_0\b/, 'SystemVerilog exposes mixed-depth r4 per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r4_rresp\b/, 'SystemVerilog exposes mixed-depth r4 scalar aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r4_beat_valid\b/, 'SystemVerilog exposes mixed-depth r4 valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r4_read_beats\b/, 'SystemVerilog exposes mixed-depth r4 length output');
    like($hdl, qr/assign\s+axi0_r4_read_data_output_init_en\s*=\s*axi0_r4_request\s*;/, 'SystemVerilog drives mixed-depth r4 output-bank clear from request');
    like($hdl, qr/assign\s+axi0_r4_read_beat_0_capture_en\s*=/, 'SystemVerilog emits mixed-depth r4 lane 0 capture enable');
    like($hdl, qr/axi0_read_id5_same_id_issue_order_slot0_r4_q/, 'SystemVerilog mixed-depth lane capture references RID5 slot-0 transaction identity');
    like($hdl, qr/axi0_r4_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures mixed-depth r4 lane 0 data');
    like($hdl, qr/axi0_r4_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates mixed-depth r4 scalar aggregate from current RRESP');
};

subtest 'read-data multi-group queue-head last-beat contract generates raw ARLEN burst-length capture' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_group_queue_head_last_beat_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'multi-group queue-head burst-length emits r2 RID5 response-demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-group queue-head burst-length declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r2_arlen_q \(width 8\)\)/, 'multi-group queue-head burst-length declares r2 raw ARLEN storage');
    like($isf, qr/\(var axi0_r3_arlen_q \(width 8\)\)/, 'multi-group queue-head burst-length declares r3 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r2_burst_length_capture axi0_r2_request\s+\(axi0_r2_arlen_q axi0_arlen\)\)/, 'multi-group queue-head burst-length captures r2 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r3_burst_length_capture axi0_r3_request\s+\(axi0_r3_arlen_q axi0_arlen\)\)/, 'multi-group queue-head burst-length captures r3 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'multi-group queue-head burst-length still guards r2 scalar capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'multi-group queue-head report-only burst-length does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'multi-group queue-head report-only burst-length does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r2_burst_length_capture\s+<axi0_r2_request\s+\(<- \(axi0_r2_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r2 multi-group raw ARLEN capture');
    like($fsm, qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(axi0_r2_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r2_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm keeps r2 multi-group scalar read-data capture');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group queue-head burst-length response-demux report',
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
        'generator multi-group queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for multi-group queue-head burst-length capture');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, 'SystemVerilog declares r2 multi-group raw ARLEN storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r3_arlen_q\b/, 'SystemVerilog declares r3 multi-group raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog guards r2 multi-group ARLEN capture with request');
    like($hdl, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r2 multi-group storage');
    like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, 'SystemVerilog keeps r2 scalar capture on generated last-beat completion');
    unlike($hdl, qr/\bexpected_beats_q\b/, 'SystemVerilog omits expected-beat storage for multi-group report-only burst-length');
    unlike($hdl, qr/\bread_beat_count_q\b/, 'SystemVerilog omits beat-count storage for multi-group report-only burst-length');
};

subtest 'read-data multi-group queue-head last-beat contract generates beat-count and RLAST runtime validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_group_queue_head_last_beat_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'multi-group queue-head runtime validation emits r2 RID5 response-demux rule');
    like($isf, qr/\(rule axi0_r3_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r3_q\)/, 'multi-group queue-head runtime validation emits r3 RID5 response-demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-group queue-head runtime validation declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'multi-group queue-head runtime validation declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r3_expected_beats_q \(width 5\)\)/, 'multi-group queue-head runtime validation declares r3 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'multi-group queue-head runtime validation declares r2 beat-count storage');
    like($isf, qr/\(var axi0_r3_read_beat_count_q \(width 5\)\)/, 'multi-group queue-head runtime validation declares r3 beat-count storage');
    like($isf, qr/\(rule axi0_r2_burst_length_capture axi0_r2_request\s+\(axi0_r2_arlen_q axi0_arlen\)\)/, 'multi-group queue-head runtime validation captures r2 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r2_beat_count_init axi0_r2_request\s+\(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r2_read_beat_count_q 0\)\)/, 'multi-group queue-head runtime validation initializes r2 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'multi-group queue-head runtime validation increments r2 count on raw matched RID5 queue-head beat');
    like($isf, qr/\(rule axi0_r3_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r3_q\)\) \(! axi0_r3_request\)\)\s+\(axi0_r3_read_beat_count_q \(\+ axi0_r3_read_beat_count_q 5'd1\)\)\)/, 'multi-group queue-head runtime validation increments r3 count on raw matched RID5 queue-head beat');
    like(
        $isf,
        qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(axi0_r2_last_rdata axi0_rdata\)\s+\(axi0_r2_last_rresp axi0_rresp\)\)/,
        'multi-group queue-head runtime validation still guards r2 scalar capture with generated queue-head last-beat completion',
    );
    like($isf, qr/axi0 r2 ARLEN is within configured max beats/, 'multi-group queue-head runtime validation emits r2 ARLEN bound assertion');
    like($isf, qr/axi0 r2 read beat count is below expected count/, 'multi-group queue-head runtime validation emits r2 over-count assertion');
    like($isf, qr/axi0 r2 RLAST appears only on the expected final read beat/, 'multi-group queue-head runtime validation emits r2 early-RLAST assertion');
    like($isf, qr/axi0 r2 expected final read beat has RLAST/, 'multi-group queue-head runtime validation emits r2 missing-RLAST assertion');
    like($fsm, qr/\(-axi0_r2_beat_count_init\s+<axi0_r2_request\s+\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r2_read_beat_count_q 0\)\)/, 'scheduled .fsm carries r2 multi-group expected-beat initialization');
    like($fsm, qr/\(-axi0_r2_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r2 multi-group matched-beat increment');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group queue-head runtime validation response-demux report',
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
        'generator multi-group queue-head runtime validation read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for multi-group queue-head runtime validation');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, 'SystemVerilog declares r2 multi-group expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r3_expected_beats_q\b/, 'SystemVerilog declares r3 multi-group expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, 'SystemVerilog declares r2 multi-group beat-count storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r3_read_beat_count_q\b/, 'SystemVerilog declares r3 multi-group beat-count storage');
    like($hdl, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes r2 multi-group expected count from ARLEN+1');
    like($hdl, qr/axi0_r2_read_beat_count_q_next\s*=\s*axi0_r2_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments r2 multi-group beat count');
    like($hdl, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, 'SystemVerilog emits r2 multi-group beat-count increment enable');
};

subtest 'read-data queue-head last-beat contract generates raw ARLEN burst-length capture' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_last_beat_queue_head_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head burst-length read-data keeps r0 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(rule axi0_r1_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r1_q\)/, 'queue-head burst-length read-data keeps r1 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'queue-head burst-length read-data declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'queue-head burst-length read-data declares r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'queue-head burst-length read-data declares r1 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'queue-head burst-length read-data captures r0 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'queue-head burst-length read-data captures r1 raw ARLEN on request');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'queue-head burst-length read-data still guards r0 payload capture with generated queue-head last-beat completion',
    );
    unlike($isf, qr/\bexpected_beats_q\b/, 'queue-head report-only burst-length read-data does not generate expected-beat storage');
    unlike($isf, qr/\bread_beat_count_q\b/, 'queue-head report-only burst-length read-data does not generate beat-count storage');
    like($fsm, qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r0 queue-head raw ARLEN capture');
    like($fsm, qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r1 queue-head raw ARLEN capture');
    like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm keeps r0 queue-head last-beat read-data capture assignments');

    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'generator queue-head burst-length response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator queue-head burst-length read-data report',
        'report_only',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head burst-length behavior keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head burst-length behavior keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for queue-head burst-length capture');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r0_arlen_q\b/, 'SystemVerilog declares r0 queue-head raw ARLEN storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r1_arlen_q\b/, 'SystemVerilog declares r1 queue-head raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r0_burst_length_capture_en\s*=\s*axi0_r0_request\s*;/, 'SystemVerilog guards r0 queue-head ARLEN capture with request event');
    like($hdl, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 queue-head ARLEN capture with request event');
    like($hdl, qr/axi0_r0_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r0 queue-head storage');
    like($hdl, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r1 queue-head storage');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog keeps r0 queue-head read-data capture on generated last-beat completion');
    like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog still captures queue-head last-beat RDATA');
    like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog still captures queue-head last-beat RRESP');
};

subtest 'read-data queue-head last-beat contract generates beat-count and RLAST runtime validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_last_beat_queue_head_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head runtime validation keeps r0 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'queue-head runtime validation declares ARLEN as a generated width-8 input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'queue-head runtime validation keeps r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'queue-head runtime validation declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'queue-head runtime validation declares r0 beat-count storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'queue-head runtime validation preserves request-bound r0 raw ARLEN capture');
    like($isf, qr/\(rule axi0_r0_beat_count_init axi0_r0_request\s+\(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r0_read_beat_count_q 0\)\)/, 'queue-head runtime validation initializes r0 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'queue-head runtime validation increments r0 count on raw matched queue-head read beat without RLAST qualification');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'queue-head runtime validation keeps r0 payload capture on generated queue-head last-beat completion',
    );
    like($isf, qr/axi0 r0 ARLEN is within configured max beats/, 'queue-head runtime validation emits r0 ARLEN bound assertion');
    like($isf, qr/axi0 r0 read beat count is below expected count/, 'queue-head runtime validation emits r0 over-count assertion');
    like($isf, qr/axi0 r0 RLAST appears only on the expected final read beat/, 'queue-head runtime validation emits r0 early-RLAST assertion');
    like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'queue-head runtime validation emits r0 missing-RLAST assertion');
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(\| \(! axi0_r0_request\) \(< axi0_arlen 8'd16\)\)/, 'scheduled .fsm carries r0 queue-head ARLEN bound assertion');
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_1 assert \(\| \(! \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\)\) \(< axi0_r0_read_beat_count_q axi0_r0_expected_beats_q\)\)/, 'scheduled .fsm carries r0 queue-head over-count assertion on matched beat');
    like($fsm, qr/\(-axi0_r0_beat_count_init\s+<axi0_r0_request\s+\(<- \(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r0_read_beat_count_q 0\)\)/, 'scheduled .fsm carries r0 queue-head expected-beat initialization');
    like($fsm, qr/\(-axi0_r0_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\)\)\s+\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r0 queue-head matched-beat increment');

    assert_same_id_queue_head_response_demux_report($result->{report}{response_demux}, 'generator queue-head runtime validation response-demux report');
    assert_read_data_burst_length_report(
        $result->{report}{read_data},
        'generator queue-head runtime validation read-data report',
        'runtime_assertion',
        'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head runtime validation keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head runtime validation keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog exposes generated ARLEN input for queue-head runtime validation');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'SystemVerilog declares r0 queue-head expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'SystemVerilog declares r0 queue-head beat-count storage');
    like($hdl, qr/axi0_r0_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes r0 queue-head expected count from ARLEN+1');
    like($hdl, qr/axi0_r0_read_beat_count_q_next\s*=\s*axi0_r0_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments r0 queue-head beat count');
    like($hdl, qr/assign\s+axi0_r0_read_beat_count_en\s*=/, 'SystemVerilog emits r0 queue-head beat-count increment enable');
};

subtest 'read-data queue-head multi-beat contract generates output-bank payload behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_beat_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r0_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r0_q\)/, 'queue-head multi-beat keeps r0 RLAST-gated concrete queue-head demux rule');
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'queue-head multi-beat declares ARLEN as a generated width-8 input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'queue-head multi-beat declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'queue-head multi-beat declares generated RRESP input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'queue-head multi-beat declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'queue-head multi-beat declares r0 beat-count storage');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'queue-head multi-beat declares r0 beat 0 data output');
    like($isf, qr/\(output axi0_r0_beat_rresp_0 \(width 2\)\)/, 'queue-head multi-beat declares r0 beat 0 status output');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'queue-head multi-beat declares scalar r0 aggregate status output');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'queue-head multi-beat declares r0 valid-mask output');
    like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'queue-head multi-beat declares r0 length output');
    like($isf, qr/\(rule axi0_r0_read_data_output_init axi0_r0_request[\s\S]*\(axi0_r0_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r0_rresp 2'd0\)[\s\S]*\(axi0_r0_beat_valid 16'b0\)[\s\S]*\(axi0_r0_read_beats 5'd0\)\)/, 'queue-head multi-beat clears output bank and initializes scalar aggregate on request');
    like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r0_read_beats 5'd1\)\)/, 'queue-head multi-beat captures lane 0 with raw matched queue-head beat and current beat index');
    like($isf, qr/\(rule axi0_r0_read_beat_1_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd1\)\)[\s\S]*\(axi0_r0_beat_rdata_1 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_1 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000011\)[\s\S]*\(axi0_r0_read_beats 5'd2\)\)/, 'queue-head multi-beat captures lane 1 with constant prefix valid mask');
    like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'queue-head multi-beat updates scalar aggregate on raw matched queue-head beat');
    like($fsm, qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r0_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd1\)\)/, 'scheduled .fsm captures queue-head lane 0 payload, valid mask, and length');
    like($fsm, qr/\(-axi0_r0_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r0_q\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'scheduled .fsm updates queue-head scalar aggregate under matched-beat max guard');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator queue-head multi-beat response-demux report',
        residue => [],
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        'generator queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
    );
    my $read_policy = $result->{report}{same_id_ordering}{concrete_id_reuse_policy}{read};
    ok($read_policy->{accepted_same_id_reuse}, 'queue-head multi-beat keeps same-ID reuse accepted for the covered shape');
    ok($read_policy->{generated_queue_behavior}, 'queue-head multi-beat keeps generated queue behavior true');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes queue-head multi-beat RDATA input');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_beat_rdata_0\b/, 'SystemVerilog exposes queue-head per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'SystemVerilog exposes queue-head scalar aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r0_beat_valid\b/, 'SystemVerilog exposes queue-head valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r0_read_beats\b/, 'SystemVerilog exposes queue-head length output');
    like($hdl, qr/assign\s+axi0_r0_read_data_output_init_en\s*=\s*axi0_r0_request\s*;/, 'SystemVerilog drives queue-head output-bank clear from request');
    like($hdl, qr/assign\s+axi0_r0_read_beat_0_capture_en\s*=/, 'SystemVerilog emits queue-head lane 0 capture enable');
    like($hdl, qr/axi0_read_id3_same_id_issue_order_slot0_r0_q/, 'SystemVerilog queue-head lane capture references slot-0 transaction identity');
    like($hdl, qr/axi0_r0_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures queue-head lane 0 data');
    like($hdl, qr/axi0_r0_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog sets queue-head first valid-mask prefix');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates queue-head scalar aggregate from current RRESP');
};

subtest 'read-data multi-group queue-head multi-beat contract generates output-bank payload behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_same_id_read_multi_group_queue_head_read_data());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd5\) axi0_rlast axi0_read_id5_same_id_issue_order_slot0_r2_q\)/, 'multi-group queue-head multi-beat emits r2 RID5 response-demux rule');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-group queue-head multi-beat declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-group queue-head multi-beat declares generated RRESP input');
    like($isf, qr/\(var axi0_r2_expected_beats_q \(width 5\)\)/, 'multi-group queue-head multi-beat declares r2 expected-beat storage');
    like($isf, qr/\(var axi0_r2_read_beat_count_q \(width 5\)\)/, 'multi-group queue-head multi-beat declares r2 beat-count storage');
    like($isf, qr/\(output axi0_r2_beat_rdata_0 \(width 32\)\)/, 'multi-group queue-head multi-beat declares r2 beat 0 data output');
    like($isf, qr/\(output axi0_r2_beat_rresp_0 \(width 2\)\)/, 'multi-group queue-head multi-beat declares r2 beat 0 status output');
    like($isf, qr/\(output axi0_r2_rresp \(width 2\)\)/, 'multi-group queue-head multi-beat declares r2 scalar aggregate output');
    like($isf, qr/\(output axi0_r2_beat_valid \(width 16\)\)/, 'multi-group queue-head multi-beat declares r2 valid-mask output');
    like($isf, qr/\(output axi0_r2_read_beats \(width 5\)\)/, 'multi-group queue-head multi-beat declares r2 length output');
    like($isf, qr/\(rule axi0_r2_read_data_output_init axi0_r2_request[\s\S]*\(axi0_r2_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r2_rresp 2'd0\)[\s\S]*\(axi0_r2_beat_valid 16'b0\)[\s\S]*\(axi0_r2_read_beats 5'd0\)\)/, 'multi-group queue-head multi-beat clears r2 output bank and aggregate on request');
    like($isf, qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r2_read_beats 5'd1\)\)/, 'multi-group queue-head multi-beat captures r2 lane 0 with RID5 matched queue-head beat');
    like($isf, qr/\(rule axi0_r2_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)\s+\(axi0_r2_rresp axi0_rresp\)\)/, 'multi-group queue-head multi-beat updates r2 scalar aggregate on RID5 matched beat');
    like($fsm, qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd5\) axi0_read_id5_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r2_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r2_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r2_read_beats> 5'd1\)\)/, 'scheduled .fsm captures multi-group r2 lane 0 payload, valid mask, and length');

    assert_same_id_queue_head_response_demux_report(
        $result->{report}{response_demux},
        'generator multi-group queue-head multi-beat response-demux report',
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
        'generator multi-group queue-head multi-beat read-data report',
        completion_validity => 'generated_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2 r3)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, 'SystemVerilog exposes multi-group r2 per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r2_rresp\b/, 'SystemVerilog exposes multi-group r2 scalar aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, 'SystemVerilog exposes multi-group r2 valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r2_read_beats\b/, 'SystemVerilog exposes multi-group r2 length output');
    like($hdl, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, 'SystemVerilog drives multi-group r2 output-bank clear from request');
    like($hdl, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, 'SystemVerilog emits multi-group r2 lane 0 capture enable');
    like($hdl, qr/axi0_read_id5_same_id_issue_order_slot0_r2_q/, 'SystemVerilog multi-group lane capture references RID5 slot-0 transaction identity');
    like($hdl, qr/axi0_r2_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures multi-group r2 lane 0 data');
    like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates multi-group r2 scalar aggregate from current RRESP');
};

subtest 'last-beat read-data contract generates capture behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_data_last_beat());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'last-beat read-data declares RDATA as a generated 32-bit input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'last-beat read-data declares RRESP as a generated 2-bit input');
    like($isf, qr/\(output axi0_r0_last_rdata \(width 32\)\)/, 'last-beat read-data declares r0 last data output with inherited width');
    like($isf, qr/\(output axi0_r0_last_rresp \(width 2\)\)/, 'last-beat read-data declares r0 last status output with inherited width');
    like(
        $isf,
        qr/\(rule axi0_r0_read_data_capture axi0_r0_complete\s+\(axi0_r0_last_rdata axi0_rdata\)\s+\(axi0_r0_last_rresp axi0_rresp\)\)/,
        'last-beat read-data emits r0 capture assignments guarded by generated last-beat completion',
    );
    like(
        $isf,
        qr/\(rule axi0_r1_read_data_capture axi0_r1_complete\s+\(axi0_r1_last_rdata axi0_rdata\)\s+\(axi0_r1_last_rresp axi0_rresp\)\)/,
        'last-beat read-data emits r1 capture assignments guarded by generated last-beat completion',
    );
    unlike($isf, qr/\(rule axi0_r0_read_data_capture\b[\s\S]*\(pulse axi0_r0_last_rdata\)/, 'last-beat read-data capture does not pulse payload outputs');
    like($fsm, qr/\(-axi0_r0_read_data_capture\s+<axi0_r0_complete\s+\(<- \(axi0_r0_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r0_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r0 last-beat capture assignments');
    like($fsm, qr/\(-axi0_r1_read_data_capture\s+<axi0_r1_complete\s+\(<- \(axi0_r1_last_rdata> axi0_rdata\)\)\s+\(<- \(axi0_r1_last_rresp> axi0_rresp\)\)/, 'scheduled .fsm carries r1 last-beat capture assignments');

    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator last-beat read-data report');
    assert_read_data_last_beat_report($result->{report}{read_data}, 'generator last-beat read-data report');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog declares last-beat RDATA input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog declares last-beat RRESP input');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_last_rdata\b/, 'SystemVerilog declares r0 last-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_last_rresp\b/, 'SystemVerilog declares r0 last-beat status output');
    like($hdl, qr/assign\s+axi0_r0_read_data_capture_en\s*=\s*axi0_r0_complete\s*;/, 'SystemVerilog drives r0 last-beat capture from generated completion');
    like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures last-beat RDATA into r0 data output');
    like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog captures last-beat RRESP into r0 status output');
};

subtest 'burst-length metadata generates raw ARLEN capture on last-beat read-data contracts' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_data_burst_length());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'burst-length ARLEN signal is generated as a width-8 IAL1 input');
    like($isf, qr/\(var axi0_r0_arlen_q \(width 8\)\)/, 'burst-length read-data declares r0 raw ARLEN storage');
    like($isf, qr/\(var axi0_r1_arlen_q \(width 8\)\)/, 'burst-length read-data declares r1 raw ARLEN storage');
    like($isf, qr/\(rule axi0_r0_burst_length_capture axi0_r0_request\s+\(axi0_r0_arlen_q axi0_arlen\)\)/, 'burst-length read-data captures r0 raw ARLEN on request');
    like($isf, qr/\(rule axi0_r1_burst_length_capture axi0_r1_request\s+\(axi0_r1_arlen_q axi0_arlen\)\)/, 'burst-length read-data captures r1 raw ARLEN on request');
    like($fsm, qr/\(-axi0_r0_burst_length_capture\s+<axi0_r0_request\s+\(<- \(axi0_r0_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r0 raw ARLEN capture');
    like($fsm, qr/\(-axi0_r1_burst_length_capture\s+<axi0_r1_request\s+\(<- \(axi0_r1_arlen_q axi0_arlen\)\)\s+\)/, 'scheduled .fsm carries r1 raw ARLEN capture');

    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator burst-length report');
    assert_read_data_burst_length_report($result->{report}{read_data}, 'generator burst-length report');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog declares generated ARLEN input');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r0_arlen_q\b/, 'SystemVerilog declares r0 raw ARLEN storage');
    like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r1_arlen_q\b/, 'SystemVerilog declares r1 raw ARLEN storage');
    like($hdl, qr/assign\s+axi0_r0_burst_length_capture_en\s*=\s*axi0_r0_request\s*;/, 'SystemVerilog guards r0 ARLEN capture with request event');
    like($hdl, qr/assign\s+axi0_r1_burst_length_capture_en\s*=\s*axi0_r1_request\s*;/, 'SystemVerilog guards r1 ARLEN capture with request event');
    like($hdl, qr/axi0_r0_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r0 storage');
    like($hdl, qr/axi0_r1_arlen_q_next\s*=\s*axi0_arlen\s*;/, 'SystemVerilog captures raw ARLEN into r1 storage');
    like($hdl, qr/axi0_r0_last_rdata_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog still captures last-beat RDATA');
    like($hdl, qr/axi0_r0_last_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog still captures last-beat RRESP');
};

subtest 'runtime-assertion burst-length metadata generates beat-count and RLAST validation' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_data_burst_length_runtime_assertion());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'runtime validation declares r0 expected-beat storage');
    like($isf, qr/\(var axi0_r0_read_beat_count_q \(width 5\)\)/, 'runtime validation declares r0 beat-count storage');
    like($isf, qr/\(rule axi0_r0_beat_count_init axi0_r0_request\s+\(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_r0_read_beat_count_q 0\)\)/, 'runtime validation initializes r0 expected count and beat counter on request');
    like($isf, qr/\(rule axi0_r0_read_beat_count \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\)\)\s+\(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'runtime validation increments r0 beat count on matched response beat');
    like($isf, qr/axi0 r0 ARLEN is within configured max beats/, 'runtime validation emits r0 ARLEN bound assertion');
    like($isf, qr/axi0 r0 RLAST appears only on the expected final read beat/, 'runtime validation emits r0 early-RLAST assertion');
    like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'runtime validation emits r0 missing-RLAST assertion');
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(\| \(! axi0_r0_request\) \(< axi0_arlen 8'd16\)\)/, 'scheduled .fsm carries r0 ARLEN bound assertion');
    like($fsm, qr/\(<- \(axi0_r0_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)/, 'scheduled .fsm carries r0 expected-beat initialization');
    like($fsm, qr/\(<- \(axi0_r0_read_beat_count_q \(\+ axi0_r0_read_beat_count_q 5'd1\)\)\)/, 'scheduled .fsm carries r0 beat-count increment');

    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator runtime validation report');
    assert_read_data_burst_length_report($result->{report}{read_data}, 'generator runtime validation report', 'runtime_assertion');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_expected_beats_q\b/, 'SystemVerilog declares r0 expected-beat storage');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'SystemVerilog declares r0 beat-count storage');
    like($hdl, qr/axi0_r0_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, 'SystemVerilog initializes expected count from ARLEN+1');
    like($hdl, qr/axi0_r0_read_beat_count_q_next\s*=\s*axi0_r0_read_beat_count_q\s*\+\s*5'd1\s*;/, 'SystemVerilog increments beat count with a width-clean literal');
};

subtest 'multi-beat read-data contract generates output-bank payload behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_read_data_multi_beat());
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};

    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, 'multi-beat contract keeps generated ARLEN input');
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, 'multi-beat contract declares generated RDATA input');
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, 'multi-beat contract declares generated RRESP input');
    like($isf, qr/\(var axi0_r0_expected_beats_q \(width 5\)\)/, 'multi-beat contract keeps r0 expected-beat storage');
    like($isf, qr/\(rule axi0_r0_beat_count_init axi0_r0_request\b/, 'multi-beat contract keeps r0 beat-count initialization');
    like($isf, qr/axi0 r0 expected final read beat has RLAST/, 'multi-beat contract keeps RLAST validation assertions');
    like($isf, qr/\(output axi0_r0_beat_rdata_0 \(width 32\)\)/, 'multi-beat contract declares r0 beat 0 data output');
    like($isf, qr/\(output axi0_r0_beat_rresp_0 \(width 2\)\)/, 'multi-beat contract declares r0 beat 0 status output');
    like($isf, qr/\(output axi0_r0_rresp \(width 2\)\)/, 'multi-beat contract declares scalar r0 aggregate status output');
    like($isf, qr/\(output axi0_r0_beat_valid \(width 16\)\)/, 'multi-beat contract declares r0 valid-mask output');
    like($isf, qr/\(output axi0_r0_read_beats \(width 5\)\)/, 'multi-beat contract declares r0 length output');
    like($isf, qr/\(rule axi0_r0_read_data_output_init axi0_r0_request[\s\S]*\(axi0_r0_beat_rdata_0 32'd0\)[\s\S]*\(axi0_r0_rresp 2'd0\)[\s\S]*\(axi0_r0_beat_valid 16'b0\)[\s\S]*\(axi0_r0_read_beats 5'd0\)\)/, 'multi-beat contract clears output bank and initializes scalar aggregate on request');
    like($isf, qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r0_read_beats 5'd1\)\)/, 'multi-beat contract captures lane 0 with matched beat and current beat index');
    like($isf, qr/\(rule axi0_r0_read_beat_1_capture \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd1\)\)[\s\S]*\(axi0_r0_beat_rdata_1 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_1 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000011\)[\s\S]*\(axi0_r0_read_beats 5'd2\)\)/, 'multi-beat contract captures lane 1 with constant prefix valid mask');
    like($isf, qr/\(rule axi0_r0_rresp_aggregate \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)\s+\(axi0_r0_rresp axi0_rresp\)\)/, 'multi-beat contract updates scalar aggregate when the current beat RRESP is worse');
    like($fsm, qr/\(axi0_read_data_beat_count_checks_assert_0 assert \(\| \(! axi0_r0_request\) \(< axi0_arlen 8'd16\)\)/, 'scheduled .fsm keeps runtime validation assertions');
    like($fsm, qr/\(-axi0_r0_read_data_output_init\s+<axi0_r0_request[\s\S]*\(<- \(axi0_r0_beat_rdata_0> 32'd0\)\)[\s\S]*\(<- \(axi0_r0_rresp> 2'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd0\)\)/, 'scheduled .fsm clears output bank and initializes scalar aggregate on request');
    like($fsm, qr/\(-axi0_r0_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r0_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r0_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r0_read_beats> 5'd1\)\)/, 'scheduled .fsm captures lane 0 payload, valid mask, and length');
    like($fsm, qr/\(-axi0_r0_rresp_aggregate\s+<\(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(< axi0_r0_rresp axi0_rresp\)\)[\s\S]*\(<- \(axi0_r0_rresp> axi0_rresp\)\)/, 'scheduled .fsm updates scalar aggregate under matched-beat max guard');

    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator multi-beat report', 1, 1);
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator multi-beat report', 1, 'read', 1, 1);
    assert_read_data_multi_beat_report($result->{report}{read_data}, 'generator multi-beat report');

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, 'SystemVerilog keeps generated ARLEN input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, 'SystemVerilog exposes generated RDATA input');
    like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, 'SystemVerilog exposes generated RRESP input');
    like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r0_read_beat_count_q\b/, 'SystemVerilog keeps beat-count storage');
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r0_beat_rdata_0\b/, 'SystemVerilog exposes per-beat data output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_beat_rresp_0\b/, 'SystemVerilog exposes per-beat status output');
    like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+axi0_r0_rresp\b/, 'SystemVerilog exposes scalar r0 aggregate status output');
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r0_beat_valid\b/, 'SystemVerilog exposes valid-mask output');
    like($hdl, qr/\boutput\s+reg\s+\[4:0\]\s+axi0_r0_read_beats\b/, 'SystemVerilog exposes length output');
    like($hdl, qr/assign\s+axi0_r0_read_data_output_init_en\s*=\s*axi0_r0_request\s*;/, 'SystemVerilog drives output-bank clear from request');
    like($hdl, qr/assign\s+axi0_r0_rresp_aggregate_en\s*=/, 'SystemVerilog emits scalar aggregate update enable');
    like($hdl, qr/assign\s+axi0_r0_read_beat_0_capture_en\s*=/, 'SystemVerilog emits lane 0 capture enable');
    like($hdl, qr/axi0_r0_beat_rdata_0_next\s*=\s*32'd0\s*;/, 'SystemVerilog clears lane 0 data');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*2'd0\s*;/, 'SystemVerilog initializes scalar aggregate to OKAY');
    like($hdl, qr/axi0_r0_rresp_next\s*=\s*axi0_rresp\s*;/, 'SystemVerilog updates scalar aggregate from current RRESP');
    like($hdl, qr/axi0_r0_rresp\s*<\s*axi0_rresp/, 'SystemVerilog preserves scalar aggregate max comparison');
    like($hdl, qr/axi0_r0_beat_rdata_0_next\s*=\s*axi0_rdata\s*;/, 'SystemVerilog captures lane 0 data');
    like($hdl, qr/axi0_r0_beat_valid_next\s*=\s*16'b1\s*;/, 'SystemVerilog sets first valid-mask prefix');
    like($hdl, qr/axi0_r0_read_beats_next\s*=\s*5'd1\s*;/, 'SystemVerilog sets first length value');
};

subtest 'multi-beat read-data without scalar aggregation remains valid' => sub {
    my $contract = sample_contract_with_read_data_multi_beat();
    delete $contract->{read_data}{read}{status_aggregation};
    delete $_->{status_aggregate_output} for @{$contract->{read_data}{read}{transactions}};

    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($contract);
    my $read_data = $result->{report}{read_data};
    my $read = $read_data->{read};

    is($read->{status_aggregation}, 'none', 'no-aggregation multi-beat contract keeps status_aggregation none');
    ok(!exists($read->{status_aggregation_generated_behavior}), 'no-aggregation multi-beat contract has no scalar aggregation generated flag');
    ok(!exists($read->{status_aggregate_output}), 'no-aggregation multi-beat contract has no scalar aggregate output shape');
    is_deeply($read_data->{residue}, [qw(rresp_aggregation)], 'no-aggregation multi-beat contract keeps broad RRESP aggregation residue');
    assert_read_response_demux_burst_last_report($result->{report}{response_demux}, 'generator no-aggregation multi-beat report', 1, 1);
    assert_same_id_ordering_report($result->{report}{same_id_ordering}, 'generator no-aggregation multi-beat report', 1, 'read', 1, 1);
    my @r0_status_outputs = map { "axi0_r0_beat_rresp_$_" } 0 .. 15;
    my @r1_status_outputs = map { "axi0_r1_beat_rresp_$_" } 0 .. 15;
    is_deeply(
        $read->{generated_multi_beat_status_outputs},
        [@r0_status_outputs, @r1_status_outputs],
        'no-aggregation multi-beat contract still reports generated per-beat status outputs',
    );
};

subtest 'mixed read/write response-demux keeps write behavior and adds read behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract_with_mixed_response_demux());
    my $isf = $result->{generated_ial1}{text};
    my $demux = $result->{report}{response_demux};

    like($isf, qr/\(input axi0_bid \(width 4\)\)/, 'mixed response-demux still declares BID for write behavior');
    like($isf, qr/\(output axi0_w0_complete\)/, 'mixed response-demux still exposes write completion as a generated output');
    like($isf, qr/\(rule axi0_w0_response_demux\b[\s\S]*\(pulse axi0_w0_complete\)\)/, 'mixed response-demux still emits write pulse rules');
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, 'mixed response-demux declares RID for read behavior');
    like($isf, qr/\(output axi0_r0_complete\)/, 'mixed response-demux exposes read completion as a generated output');
    like($isf, qr/\(rule axi0_r0_response_demux\b[\s\S]*\(pulse axi0_r0_complete\)\)/, 'mixed response-demux emits read pulse rules');

    is($demux->{mode}, 'bounded_response_demux_contract', 'mixed report uses the combined response-demux contract mode');
    ok($demux->{generated_behavior}, 'mixed report keeps top-level generated behavior true');
    is($demux->{write}{mode}, 'bounded_write_bid_demux_contract', 'mixed report keeps write BID-demux mode');
    ok($demux->{write}{generated_behavior}, 'mixed report keeps write generated behavior true');
    is_deeply($demux->{write}{auto_transactions}, [qw(w0 w1)], 'mixed report keeps write auto transactions');
    is_deeply($demux->{write}{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], 'mixed report lists generated write demux rules');
    is($demux->{read}{mode}, 'bounded_read_rid_demux_contract', 'mixed report keeps read RID-demux mode');
    ok($demux->{read}{generated_behavior}, 'mixed report marks read generated behavior true');
    is_deeply($demux->{read}{auto_transactions}, [qw(r0 r1)], 'mixed report keeps read auto transactions');
    is_deeply($demux->{read}{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], 'mixed report lists generated read demux rules');
    is_deeply($demux->{read}{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], 'mixed report lists generated read completion signals');
    is_deeply(
        $demux->{read}{generated_assertions},
        [qw(axi0_read_response_demux_active_match axi0_r0_r1_read_response_demux_unique_match)],
        'mixed report lists generated read demux assertions',
    );
    is_deeply(
        $demux->{residue},
        [qw(read_data_interleaving bursts)],
        'mixed report keeps only read data/interleaving and burst residue',
    );
    is_deeply(
        $result->{report}{auto_id_lifecycle}{residue},
        [],
        'mixed report removes response_demux lifecycle residue after both generated families are covered',
    );
    my %same_id_families = map { $_->{family} => $_ } @{$result->{report}{same_id_ordering}{families}};
    is_deeply(sorted([keys %same_id_families]), [qw(read write)], 'mixed same-ID report carries write and read families');
    assert_same_id_ordering_family($same_id_families{write}, 'generator report mixed write', 'write', 1);
    assert_same_id_ordering_family($same_id_families{read}, 'generator report mixed read', 'read', 1);
};

subtest 'mixed auto-ID and same-ID queue-head response-demux combines generated families' => sub {
    my @cases = (
        {
            owner    => 'generator mixed read single-beat',
            family   => 'read',
            contract => sample_contract_with_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux(),
            request_id_signal  => 'axi0_arid',
            response_id_signal => 'axi0_rid',
            response_event     => 'axi0_read_complete',
            first_transaction  => 'r0',
            second_transaction => 'r1',
            third_transaction  => 'r2',
            completion_prefix  => 'r',
            boundary           => 'generated_read_single_beat_queue_head_demux',
            scope              => 'single_beat',
        },
        {
            owner    => 'generator mixed read burst-last',
            family   => 'read',
            contract => sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux(),
            request_id_signal  => 'axi0_arid',
            response_id_signal => 'axi0_rid',
            response_event     => 'axi0_read_complete',
            first_transaction  => 'r0',
            second_transaction => 'r1',
            third_transaction  => 'r2',
            completion_prefix  => 'r',
            boundary           => 'generated_read_burst_last_queue_head_demux',
            scope              => 'burst_last',
            last_signal        => 'axi0_rlast',
        },
        {
            owner    => 'generator mixed write',
            family   => 'write',
            contract => sample_contract_with_write_mixed_auto_id_same_id_queue_head_response_demux(),
            request_id_signal  => 'axi0_awid',
            response_id_signal => 'axi0_bid',
            response_event     => 'axi0_write_complete',
            first_transaction  => 'w0',
            second_transaction => 'w1',
            third_transaction  => 'w2',
            completion_prefix  => 'w',
            boundary           => 'generated_write_bid_queue_head_demux',
        },
    );

    for my $case (@cases) {
        my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($case->{contract});
        my $isf = $result->{generated_ial1}{text};
        my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
        my $owner = $case->{owner};
        my $request_id_signal = $case->{request_id_signal};
        my $response_id_signal = $case->{response_id_signal};
        my $first_transaction = $case->{first_transaction};
        my $second_transaction = $case->{second_transaction};
        my $third_transaction = $case->{third_transaction};

        like($isf, qr/\(output \Q$request_id_signal\E \(width 4\)\)/, "$owner exposes the shared request ID as a generated output");
        like($isf, qr/\(input \Q$response_id_signal\E \(width 4\)\)/, "$owner exposes the response ID as a generated input");
        like($isf, qr/\(rule axi0_${first_transaction}_response_demux\b/, "$owner emits auto-ID response-demux rule");
        like($isf, qr/\(pulse axi0_${first_transaction}_complete\)/, "$owner emits auto-ID response-demux pulse");
        like($isf, qr/\(rule axi0_${second_transaction}_response_demux\b/, "$owner emits first concrete queue-head response-demux rule");
        like($isf, qr/\(pulse axi0_${second_transaction}_complete\)/, "$owner emits first concrete queue-head response-demux pulse");
        like($isf, qr/\(rule axi0_${third_transaction}_response_demux\b/, "$owner emits second concrete queue-head response-demux rule");
        like($isf, qr/\(pulse axi0_${third_transaction}_complete\)/, "$owner emits second concrete queue-head response-demux pulse");
        like($isf, qr/\(rule axi0_${second_transaction}_concrete_request_id_drive \(& axi0_${second_transaction}_request \(! axi0_${first_transaction}_request\)\)\s+\(\Q$request_id_signal\E 4'd3\)\)/, "$owner drives concrete request ID through the generated request-ID output");
        like($isf, qr/\(rule axi0_${first_transaction}_auto_id_alloc_0\b/, "$owner emits the first auto-ID allocation rule");
        like($isf, qr/\(! axi0_${second_transaction}_request\)/, "$owner guards auto-ID allocation against the first concrete request");
        like($isf, qr/\(! axi0_${third_transaction}_request\)/, "$owner guards auto-ID allocation against the second concrete request");

        assert_mixed_auto_id_queue_head_response_demux_report(
            $result->{report},
            $owner,
            $case,
        );
        is_deeply(
            $result->{report}{id_response_rule_engine}{id_signal_inputs},
            [$response_id_signal],
            "$owner reports only the response ID as an effective concrete-ID input",
        );

        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[3:0\]\s+\Q$request_id_signal\E\b/, "$owner SystemVerilog exposes generated request ID output");
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+\Q$response_id_signal\E\b/, "$owner SystemVerilog exposes response ID input");
    }
};

subtest 'mixed auto-ID and same-ID queue-head read-data consumes combined completions' => sub {
    my @cases = (
        {
            owner    => 'generator mixed read-data single-beat',
            contract => sample_contract_with_read_single_beat_mixed_auto_id_same_id_queue_head_read_data(),
            boundary => 'generated_read_single_beat_queue_head_demux',
            scope    => 'single_beat',
            output_data    => 'axi0_r2_rdata',
            output_status  => 'axi0_r2_rresp',
            demux_rule_pattern => qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/,
            report_assertion => \&assert_read_data_report,
            report_assertion_args => ['generated_mixed_auto_id_queue_head_response_demux_completion_pulse'],
        },
        {
            owner    => 'generator mixed read-data burst-last',
            contract => sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_read_data(),
            boundary => 'generated_read_burst_last_queue_head_demux',
            scope    => 'burst_last',
            last_signal => 'axi0_rlast',
            output_data    => 'axi0_r2_last_rdata',
            output_status  => 'axi0_r2_last_rresp',
            demux_rule_pattern => qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/,
            report_assertion => \&assert_read_data_last_beat_report,
            report_assertion_args => ['generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
        },
        {
            owner    => 'generator mixed read-data burst-last report-only burst-length',
            contract => sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length(),
            boundary => 'generated_read_burst_last_queue_head_demux',
            scope    => 'burst_last',
            last_signal => 'axi0_rlast',
            output_data    => 'axi0_r2_last_rdata',
            output_status  => 'axi0_r2_last_rresp',
            demux_rule_pattern => qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/,
            report_assertion => \&assert_read_data_burst_length_report,
            report_assertion_args => ['report_only', 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
            burst_length => 1,
        },
        {
            owner    => 'generator mixed read-data burst-last runtime burst-length',
            contract => sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion(),
            boundary => 'generated_read_burst_last_queue_head_demux',
            scope    => 'burst_last',
            last_signal => 'axi0_rlast',
            output_data    => 'axi0_r2_last_rdata',
            output_status  => 'axi0_r2_last_rresp',
            demux_rule_pattern => qr/\(rule axi0_r2_response_demux \(& axi0_read_complete \(== axi0_rid 4'd3\) axi0_rlast axi0_read_id3_same_id_issue_order_slot0_r2_q\)/,
            hdl_demux_guard_pattern => qr/axi0_read_complete\s*&\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_rlast\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q/,
            report_assertion => \&assert_read_data_burst_length_report,
            report_assertion_args => ['runtime_assertion', 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse'],
            burst_length => 1,
            runtime_validation => 1,
        },
    );

    for my $case (@cases) {
        my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($case->{contract});
        my $isf = $result->{generated_ial1}{text};
        my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
        my $owner = $case->{owner};

        like($isf, qr/\(output axi0_arid \(width 4\)\)/, "$owner exposes generated ARID output");
        like($isf, qr/\(input axi0_rid \(width 4\)\)/, "$owner exposes generated RID input");
        like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$owner declares RDATA as a generated input");
        like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$owner declares RRESP as a generated input");
        if ($case->{last_signal}) {
            like($isf, qr/\(input axi0_rlast\)/, "$owner declares RLAST as a generated input");
        } else {
            unlike($isf, qr/\baxi0_rlast\b/, "$owner omits RLAST for single-beat capture");
        }
        if ($case->{burst_length}) {
            like($isf, qr/\(input axi0_arlen \(width 8\)\)/, "$owner declares ARLEN as a generated input");
            for my $tx (qw(r0 r1 r2)) {
                like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "$owner declares $tx raw ARLEN storage");
                like($isf, qr/\(rule axi0_${tx}_burst_length_capture axi0_${tx}_request\s+\(axi0_${tx}_arlen_q axi0_arlen\)\)/, "$owner captures $tx raw ARLEN on request");
                like(
                    $fsm,
                    qr/\(-axi0_${tx}_burst_length_capture\s+<axi0_${tx}_request\s+\(<- \(axi0_${tx}_arlen_q axi0_arlen\)\)\s+\)/,
                    "$owner lowers $tx raw ARLEN capture into generated .fsm",
                );
            }
            if ($case->{runtime_validation}) {
                for my $tx (qw(r0 r1 r2)) {
                    like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "$owner declares $tx expected-beat storage");
                    like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "$owner declares $tx beat-count storage");
                    like($isf, qr/\(rule axi0_${tx}_beat_count_init axi0_${tx}_request\s+\(axi0_${tx}_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\s+\(axi0_${tx}_read_beat_count_q 0\)\)/, "$owner initializes $tx expected count and beat counter on request");
                    like($isf, qr/\(rule axi0_${tx}_read_beat_count\b[\s\S]*\(axi0_${tx}_read_beat_count_q \(\+ axi0_${tx}_read_beat_count_q 5'd1\)\)\)/, "$owner increments $tx beat count on matched read beat");
                }
                like(
                    $isf,
                    qr/\(rule axi0_r2_read_beat_count \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/,
                    "$owner increments r2 count on raw matched queue-head read beat without RLAST qualification",
                );
                like($fsm, qr/\(-axi0_r2_beat_count_init\s+<axi0_r2_request\s+\(<- \(axi0_r2_expected_beats_q \(\+ axi0_arlen\[4:0\] 5'd1\)\)\)\s+\(<- \(axi0_r2_read_beat_count_q 0\)\)/, "$owner lowers r2 expected-beat initialization");
                like($fsm, qr/\(-axi0_r2_read_beat_count\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\)\)\s+\(<- \(axi0_r2_read_beat_count_q \(\+ axi0_r2_read_beat_count_q 5'd1\)\)\)/, "$owner lowers r2 matched-beat increment");
                my @beat_count_assertions = $fsm =~ /axi0_read_data_beat_count_checks_assert_/g;
                is(scalar(@beat_count_assertions), 12, "$owner lowers four beat-count/RLAST assertions per covered transaction");
            }
        }

        like($isf, qr/\(rule axi0_r0_response_demux\b/, "$owner emits auto-ID response-demux rule");
        like($isf, $case->{demux_rule_pattern}, "$owner emits concrete queue-head response-demux rule");
        like($isf, qr/\(output \Q$case->{output_data}\E \(width 32\)\)/, "$owner declares final transaction data output");
        like($isf, qr/\(output \Q$case->{output_status}\E \(width 2\)\)/, "$owner declares final transaction status output");
        like(
            $isf,
            qr/\(rule axi0_r2_read_data_capture axi0_r2_complete\s+\(\Q$case->{output_data}\E axi0_rdata\)\s+\(\Q$case->{output_status}\E axi0_rresp\)\)/,
            "$owner guards final transaction scalar capture with combined generated completion",
        );
        like(
            $fsm,
            qr/\(-axi0_r2_read_data_capture\s+<axi0_r2_complete\s+\(<- \(\Q$case->{output_data}\E> axi0_rdata\)\)\s+\(<- \(\Q$case->{output_status}\E> axi0_rresp\)\)/,
            "$owner lowers final transaction capture assignments into generated .fsm",
        );

        assert_mixed_auto_id_queue_head_response_demux_report(
            $result->{report},
            "$owner response-demux report",
            {
                family            => 'read',
                completion_prefix => 'r',
                boundary          => $case->{boundary},
                scope             => $case->{scope},
                ($case->{last_signal} ? (last_signal => $case->{last_signal}) : ()),
            },
        );
        $case->{report_assertion}->(
            $result->{report}{read_data},
            "$owner read-data report",
            @{$case->{report_assertion_args}},
            transactions => [qw(r0 r1 r2)],
        );

        my $hdl = hdl_for('axi0_capacity_status', $fsm);
        like($hdl, qr/\boutput\s+reg\s+\[3:0\]\s+axi0_arid\b/, "$owner SystemVerilog exposes generated ARID output");
        like($hdl, qr/\binput\s+(?:wire\s+)?\[3:0\]\s+axi0_rid\b/, "$owner SystemVerilog exposes generated RID input");
        like($hdl, qr/\binput\s+(?:wire\s+)?\[31:0\]\s+axi0_rdata\b/, "$owner SystemVerilog exposes generated RDATA input");
        like($hdl, qr/\binput\s+(?:wire\s+)?\[1:0\]\s+axi0_rresp\b/, "$owner SystemVerilog exposes generated RRESP input");
        like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+\Q$case->{output_data}\E\b/, "$owner SystemVerilog exposes captured data output");
        like($hdl, qr/\boutput\s+reg\s+\[1:0\]\s+\Q$case->{output_status}\E\b/, "$owner SystemVerilog exposes captured status output");
        like($hdl, qr/assign\s+axi0_r2_read_data_capture_en\s*=\s*axi0_r2_complete\s*;/, "$owner SystemVerilog drives capture from generated completion");
        like($hdl, qr/\Q$case->{output_data}\E_next\s*=\s*axi0_rdata\s*;/, "$owner SystemVerilog captures RDATA into final transaction output");
        like($hdl, qr/\Q$case->{output_status}\E_next\s*=\s*axi0_rresp\s*;/, "$owner SystemVerilog captures RRESP into final transaction output");
        if ($case->{burst_length}) {
            like($hdl, qr/\binput\s+(?:wire\s+)?\[7:0\]\s+axi0_arlen\b/, "$owner SystemVerilog exposes generated ARLEN input");
            like($hdl, qr/\breg\s+\[7:0\]\s+axi0_r2_arlen_q\b/, "$owner SystemVerilog declares r2 raw ARLEN storage");
            like($hdl, qr/assign\s+axi0_r2_burst_length_capture_en\s*=\s*axi0_r2_request\s*;/, "$owner SystemVerilog guards r2 ARLEN capture with request");
            like($hdl, qr/axi0_r2_arlen_q_next\s*=\s*axi0_arlen\s*;/, "$owner SystemVerilog captures raw ARLEN into r2 storage");
            if ($case->{runtime_validation}) {
                like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_expected_beats_q\b/, "$owner SystemVerilog declares r2 expected-beat storage");
                like($hdl, qr/\breg\s+\[4:0\]\s+axi0_r2_read_beat_count_q\b/, "$owner SystemVerilog declares r2 beat-count storage");
                like($hdl, qr/axi0_r2_expected_beats_q_next\s*=\s*axi0_arlen\[4:0\]\s*\+\s*5'd1\s*;/, "$owner SystemVerilog initializes r2 expected count from ARLEN+1");
                like($hdl, qr/axi0_r2_read_beat_count_q_next\s*=\s*axi0_r2_read_beat_count_q\s*\+\s*5'd1\s*;/, "$owner SystemVerilog increments r2 beat count");
                like($hdl, qr/assign\s+axi0_r2_read_beat_count_en\s*=/, "$owner SystemVerilog emits r2 beat-count increment enable");
            } else {
                unlike($hdl, qr/\bexpected_beats_q\b/, "$owner report-only HDL omits expected-beat storage");
                unlike($hdl, qr/\bread_beat_count_q\b/, "$owner report-only HDL omits beat-count storage");
            }
        }
        like($hdl, $case->{hdl_demux_guard_pattern}, "$owner SystemVerilog keeps the concrete queue-head demux guard");
    }
};

subtest 'mixed auto-ID and same-ID queue-head multi-beat read-data generates output-bank behavior' => sub {
    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(
        sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data(),
    );
    my $isf = $result->{generated_ial1}{text};
    my $fsm = $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'};
    my $owner = 'generator mixed read-data burst-last multi-beat output-bank';

    like($isf, qr/\(output axi0_arid \(width 4\)\)/, "$owner exposes generated ARID output");
    like($isf, qr/\(input axi0_rid \(width 4\)\)/, "$owner exposes generated RID input");
    like($isf, qr/\(input axi0_rlast\)/, "$owner declares RLAST as a generated input");
    like($isf, qr/\(input axi0_arlen \(width 8\)\)/, "$owner declares ARLEN as a generated input");
    like($isf, qr/\(input axi0_rdata \(width 32\)\)/, "$owner declares RDATA as a generated input");
    like($isf, qr/\(input axi0_rresp \(width 2\)\)/, "$owner declares RRESP as a generated input");

    for my $tx (qw(r0 r1 r2)) {
        like($isf, qr/\(output axi0_${tx}_beat_rdata_0 \(width 32\)\)/, "$owner declares $tx beat 0 data output");
        like($isf, qr/\(output axi0_${tx}_beat_rresp_0 \(width 2\)\)/, "$owner declares $tx beat 0 status output");
        like($isf, qr/\(output axi0_${tx}_rresp \(width 2\)\)/, "$owner declares $tx scalar aggregate status output");
        like($isf, qr/\(output axi0_${tx}_beat_valid \(width 16\)\)/, "$owner declares $tx valid-mask output");
        like($isf, qr/\(output axi0_${tx}_read_beats \(width 5\)\)/, "$owner declares $tx length output");
        like($isf, qr/\(var axi0_${tx}_arlen_q \(width 8\)\)/, "$owner declares $tx raw ARLEN storage");
        like($isf, qr/\(var axi0_${tx}_expected_beats_q \(width 5\)\)/, "$owner declares $tx expected-beat storage");
        like($isf, qr/\(var axi0_${tx}_read_beat_count_q \(width 5\)\)/, "$owner declares $tx beat-count storage");
        like($isf, qr/\(rule axi0_${tx}_read_data_output_init axi0_${tx}_request[\s\S]*\(axi0_${tx}_beat_rdata_0 32'd0\)[\s\S]*\(axi0_${tx}_rresp 2'd0\)[\s\S]*\(axi0_${tx}_beat_valid 16'b0\)[\s\S]*\(axi0_${tx}_read_beats 5'd0\)\)/, "$owner clears $tx output bank on request");
    }

    like(
        $isf,
        qr/\(rule axi0_r0_read_beat_0_capture \(& \(& axi0_read_complete \(& axi0_r0_auto_id_busy_q \(== axi0_rid axi0_r0_auto_id_q\)\)\) \(! axi0_r0_request\) \(== axi0_r0_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r0_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r0_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r0_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r0_read_beats 5'd1\)\)/,
        "$owner captures r0 auto-ID lane 0 payload with matched RID",
    );
    like(
        $isf,
        qr/\(rule axi0_r2_read_beat_0_capture \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(axi0_r2_beat_rdata_0 axi0_rdata\)[\s\S]*\(axi0_r2_beat_rresp_0 axi0_rresp\)[\s\S]*\(axi0_r2_beat_valid 16'b0000000000000001\)[\s\S]*\(axi0_r2_read_beats 5'd1\)\)/,
        "$owner captures r2 queue-head lane 0 payload with matched RID",
    );
    like(
        $isf,
        qr/\(rule axi0_r2_rresp_aggregate \(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(< axi0_r2_rresp axi0_rresp\)\)\s+\(axi0_r2_rresp axi0_rresp\)\)/,
        "$owner updates r2 scalar aggregate on matched queue-head beat",
    );
    like(
        $fsm,
        qr/\(-axi0_r2_read_beat_0_capture\s+<\(& \(& axi0_read_complete \(& \(== axi0_rid 4'd3\) axi0_read_id3_same_id_issue_order_slot0_r2_q\)\) \(! axi0_r2_request\) \(== axi0_r2_read_beat_count_q 5'd0\)\)[\s\S]*\(<- \(axi0_r2_beat_rdata_0> axi0_rdata\)\)[\s\S]*\(<- \(axi0_r2_beat_rresp_0> axi0_rresp\)\)[\s\S]*\(<- \(axi0_r2_beat_valid> 16'b0000000000000001\)\)[\s\S]*\(<- \(axi0_r2_read_beats> 5'd1\)\)/,
        "$owner lowers r2 queue-head lane 0 capture into generated .fsm",
    );

    my @beat_count_assertions = $fsm =~ /axi0_read_data_beat_count_checks_assert_/g;
    is(scalar(@beat_count_assertions), 12, "$owner lowers four beat-count/RLAST assertions per covered transaction");

    assert_mixed_auto_id_queue_head_response_demux_report(
        $result->{report},
        "$owner response-demux report",
        {
            family            => 'read',
            completion_prefix => 'r',
            boundary          => 'generated_read_burst_last_queue_head_demux',
            scope             => 'burst_last',
            last_signal       => 'axi0_rlast',
            demux_residue     => [],
        },
    );
    assert_read_data_multi_beat_report(
        $result->{report}{read_data},
        "$owner read-data report",
        completion_validity => 'generated_mixed_auto_id_queue_head_response_demux_last_beat_completion_pulse',
        transactions => [qw(r0 r1 r2)],
    );

    my $hdl = hdl_for('axi0_capacity_status', $fsm);
    like($hdl, qr/\boutput\s+reg\s+\[31:0\]\s+axi0_r2_beat_rdata_0\b/, "$owner SystemVerilog exposes r2 beat 0 data output");
    like($hdl, qr/\boutput\s+reg\s+\[15:0\]\s+axi0_r2_beat_valid\b/, "$owner SystemVerilog exposes r2 valid-mask output");
    like($hdl, qr/assign\s+axi0_r2_read_data_output_init_en\s*=\s*axi0_r2_request\s*;/, "$owner SystemVerilog guards r2 output-bank clear with request");
    like($hdl, qr/assign\s+axi0_r2_read_beat_0_capture_en\s*=/, "$owner SystemVerilog emits r2 lane 0 capture enable");
    like($hdl, qr/assign\s+intermediate_and_axi0_read_id3_same_id_issue_order_sl_etc_\d+\s*=\s*\(axi0_rid\s*==\s*4'd3\)\s*&\s*axi0_read_id3_same_id_issue_order_slot0_r2_q\s*;/, "$owner SystemVerilog factors the r2 queue-head RID/slot match");
    like($hdl, qr/assign\s+intermediate_and_axi0_read_complete_intermediate_and__etc_\d+\s*=\s*axi0_read_complete\s*&\s*intermediate_and_axi0_read_id3_same_id_issue_order_sl_etc_\d+\s*;/, "$owner SystemVerilog combines read completion with the r2 queue-head match");
    like($hdl, qr/assign\s+intermediate_and_intermediate_and_axi0_read_complete__etc_\d+\s*=\s*intermediate_and_axi0_read_complete_intermediate_and__etc_\d+\s*&\s*!axi0_r2_request\s*&\s*\(~\|axi0_r2_read_beat_count_q\)\s*;/, "$owner SystemVerilog gates r2 lane 0 capture with the matched beat");
    like($hdl, qr/axi0_r2_rresp_next\s*=\s*axi0_rresp\s*;/, "$owner SystemVerilog updates r2 scalar aggregate");
};

subtest 'schedule report and HDL expose generated storage and status surface' => sub {
    my $result = generate_sample();
    my $report = $result->{generated_ial1_schedule_report};
    assert_actor_storage($report, 'axi0_pending_reads_q', 3);
    assert_actor_storage($report, 'axi0_pending_writes_q', 2);

    my $hdl = hdl_for('axi0_capacity_status', $result->{generated_ial0}{files}{'axi0_capacity_status.fsm'});
    like($hdl, qr/\bmodule\s+axi0_capacity_status\b/, 'generated .fsm reaches SystemVerilog generation');
    like($hdl, qr/\baxi0_pending_reads_q\b/, 'generated HDL contains read pending counter storage');
    like($hdl, qr/\baxi0_read_can_accept\b/, 'generated HDL contains read can_accept status output');
    like($hdl, qr/\baxi0_read_slots_available\b/, 'generated HDL contains read slots status output');
    unlike($hdl, qr/\bmodule\s+.*can_accept\b/, 'generated HDL keeps can_accept namespaced at the public surface');
};

subtest 'single-slot capacity remains representable' => sub {
    my $contract = sample_contract();
    $contract->{read_max_pending} = 1;
    $contract->{write_max_pending} = 1;
    $contract->{actor_name} = 'axi0_single_slot_capacity';

    my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate($contract);
    my $isf = $result->{generated_ial1}{text};
    like($isf, qr/\(output axi0_pending_reads\)/, 'single-slot pending read status uses one bit');
    like($isf, qr/\(var axi0_pending_reads_q \(width 1\)\)/, 'single-slot read storage uses one bit');
    like(
        $result->{generated_ial0}{files}{'axi0_single_slot_capacity.fsm'},
        qr/\(-read_submit_only_occ1[\s\S]*\(<- \(axi0_read_can_accept> 0\)\)/,
        'single-slot full submit is rejected by can_accept',
    );
};

subtest 'malformed contract objects fail closed and no direct lower-to-fsm entrypoint is exposed' => sub {
    my $generator = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new();
    ok(!$generator->can('lower_to_fsm'), 'generator exposes no direct IAL2-to-.fsm method');

    my @cases = (
        ['missing read depth', sub { my $c = sample_contract(); delete $c->{read_max_pending}; $c }, qr/missing required positive integer field 'read_max_pending'/],
        ['zero write depth', sub { my $c = sample_contract(); $c->{write_max_pending} = 0; $c }, qr/write_max_pending.*positive integer/],
        ['unsupported policy', sub { my $c = sample_contract(); $c->{submit_policy} = 'blocking'; $c }, qr/submit_policy must be try/],
        ['unsupported protocol', sub { my $c = sample_contract(); $c->{protocol} = 'axi5'; $c }, qr/protocol must be axi4/],
        ['duplicate status name', sub { my $c = sample_contract(); $c->{status}{write_full} = 'axi0_read_full'; $c }, qr/duplicates signal 'axi0_read_full'/],
        ['bare can_accept collision', sub { my $c = sample_contract(); $c->{status}{read_can_accept} = 'can_accept'; $c }, qr/collides with reserved scheduler signal 'can_accept'/],
        ['unsupported ID field', sub { my $c = sample_contract(); $c->{id_width} = 4; $c }, qr/unsupported field 'id_width'/],
        ['ID-family width too large', sub { my $c = sample_contract_with_id_families(); $c->{id_families}{read}{width} = 33; $c }, qr/id_families\.read\.width.*0\.\.32/],
        ['ID-family positive width missing response signal', sub { my $c = sample_contract_with_id_families(); delete $c->{id_families}{write}{response_id_signal}; $c }, qr/id_families\.write positive width requires field 'response_id_signal'/],
        ['ID-family zero width with signal', sub { my $c = sample_contract_with_id_families(); $c->{id_families}{read}{width} = 0; delete $c->{id_families}{read}{response_id_signal}; $c }, qr/id_families\.read zero width must not include field 'request_id_signal'/],
        ['ID-family signal collision', sub { my $c = sample_contract_with_id_families(); $c->{id_families}{write}{request_id_signal} = 'clk'; $c }, qr/duplicates signal 'clk'/],
        ['transactions not array', sub { my $c = sample_contract_with_id_families(); $c->{transactions} = {}; $c }, qr/field 'transactions' must be an array reference/],
        ['duplicate transaction tag', sub { my $c = sample_contract_with_transactions(); $c->{transactions}[1]{tag} = 'wr0'; $c }, qr/duplicates transaction tag 'wr0'/],
        ['write transaction bound to read direction-level event', sub { my $c = sample_contract_with_transactions(); $c->{transactions}[0]{request_event} = 'axi0_read_submit'; $c }, qr/write request_event must not reference read direction-level event 'axi0_read_submit'/],
        ['duplicate write dispatch request event', sub { my $c = sample_contract_with_transaction_event_dispatch(); $c->{transactions}[1]{request_event} = 'axi0_w0_request'; $c }, qr/write request_event 'axi0_w0_request' is reused by transactions 'w0' and 'w1' while using per-transaction dispatch/],
        ['transaction event collides with status output', sub { my $c = sample_contract_with_transaction_event_dispatch(); $c->{transactions}[2]{request_event} = 'axi0_read_full'; $c }, qr/duplicates signal 'axi0_read_full'/],
        ['transaction ID unsupported policy', sub { my $c = sample_contract_with_transactions(); $c->{transactions}[0]{id} = { policy => 'user' }; $c }, qr/transactions\[0\]\.id policy must be auto or dynamic/],
        ['concrete transaction ID without family metadata', sub { my $c = sample_contract(); $c->{transactions} = [sample_contract_with_transactions()->{transactions}[1]]; $c }, qr/concrete ID requires id_families metadata/],
        ['concrete transaction ID too wide', sub { my $c = sample_contract_with_transactions(); $c->{transactions}[1]{id}{value} = 16; $c }, qr/concrete read ID value 16 does not fit width 4/],
        ['concrete transaction ID with zero-width family', sub { my $c = sample_contract_with_transactions(); $c->{id_families}{read} = { width => 0 }; $c }, qr/concrete read ID is not allowed when read ID-family width is 0/],
        ['dynamic transaction ID without family metadata', sub {
            my $c = sample_contract();
            $c->{transactions} = [
                {
                    kind             => 'read',
                    name             => 'r0',
                    tag              => 'rd0',
                    request_event    => 'axi0_read_submit',
                    completion_event => 'axi0_read_complete',
                    id               => { policy => 'dynamic' },
                },
            ];
            $c;
        }, qr/dynamic ID requires id_families metadata/],
        ['dynamic transaction ID with value', sub { my $c = sample_contract_with_dynamic_transaction_id(); $c->{transactions}[0]{id}{value} = 0; $c }, qr/transactions\[0\]\.id dynamic policy must not include value/],
        ['dynamic transaction ID with zero-width family', sub { my $c = sample_contract_with_dynamic_transaction_id(); $c->{id_families}{read} = { width => 0 }; $c }, qr/dynamic read ID requires positive read ID-family width/],
        ['concrete transaction same-family same-ID reuse', sub {
            my $c = sample_contract_with_transaction_event_dispatch();
            push @{$c->{transactions}}, {
                kind             => 'read',
                name             => 'r1',
                tag              => 'rd1',
                request_event    => 'axi0_r1_request',
                completion_event => 'axi0_r1_complete',
                id               => { value => 3 },
            };
            $c;
        }, qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; concrete same-ID reuse requires a selected same-ID ordering policy or per-ID issue-order queue/],
        ['same-ID policy unsupported family', sub { my $c = sample_contract_with_same_id_reject_policy(); $c->{same_id_ordering_policy} = { address => { concrete_id_reuse => 'reject' } }; $c }, qr/same_id_ordering_policy has unsupported family 'address'/],
        ['same-ID policy missing concrete reuse clause', sub { my $c = sample_contract_with_same_id_reject_policy(); delete $c->{same_id_ordering_policy}{read}{concrete_id_reuse}; $c }, qr/same_id_ordering_policy\.read is missing required field 'concrete_id_reuse'/],
        ['same-ID policy unsupported scoreboard value', sub { my $c = sample_contract_with_same_id_reject_policy(); $c->{same_id_ordering_policy}{read}{concrete_id_reuse} = 'scoreboard'; $c }, qr/same_id_ordering_policy\.read\.concrete_id_reuse must be reject or issue-order-queue in this slice/],
        ['same-ID policy explicit reject blocks concrete same-ID reuse', sub {
            my $c = sample_contract_with_same_id_reject_policy();
            push @{$c->{transactions}}, {
                kind             => 'read',
                name             => 'r1',
                tag              => 'rd1',
                request_event    => 'axi0_r1_request',
                completion_event => 'axi0_r1_complete',
                id               => { value => 3 },
            };
            $c;
        }, qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering\.read concrete-id-reuse reject policy rejects concrete same-ID reuse/],
        ['same-ID issue-order queue policy selected but not generated blocks concrete same-ID reuse', sub {
            my $c = sample_contract_with_same_id_issue_order_queue_policy();
            push @{$c->{transactions}}, {
                kind             => 'read',
                name             => 'r1',
                tag              => 'rd1',
                request_event    => 'axi0_r1_request',
                completion_event => 'axi0_r1_complete',
                id               => { value => 3 },
            };
            $c;
        }, qr/concrete read ID value 3 is reused by transactions 'r0' and 'r1'; selected same-id-ordering\.read concrete-id-reuse issue-order-queue policy is selected_not_generated, so concrete same-ID reuse remains unsupported until generated issue-order queue behavior ships/],
        ['duplicate concrete ID assertion event', sub {
            my $c = sample_contract_with_transactions();
            push @{$c->{transactions}}, {
                kind             => 'read',
                name             => 'r1',
                tag              => 'rd1',
                request_event    => 'axi0_read_submit',
                completion_event => 'axi0_read_complete',
                id               => { value => 4 },
            };
            $c;
        }, qr/concrete ID assertions require unique request events; event 'axi0_read_submit' is shared by transactions 'r0' and 'r1'/],
        ['dynamic transaction ID blocks same-family auto lifecycle behavior', sub { my $c = sample_contract_with_dynamic_transaction_id(); $c->{auto_id_lifecycle} = { read => { pool => [0] } }; $c }, qr/auto_id_lifecycle\.read cannot be combined with dynamic read transaction ID metadata/],
        ['dynamic read response demux requires generated completion distinct from raw response event', sub { my $c = sample_contract_with_dynamic_transaction_id(); $c->{response_demux} = { read => { response_event => 'axi0_read_complete', response_scope => 'single-beat', transaction_completion => 'generated' } }; $c }, qr/response_demux\.read generated transaction completion signal 'axi0_read_complete' must be distinct from response_event 'axi0_read_complete'/],
        ['dynamic transaction ID blocks same-family same-ID ordering behavior', sub { my $c = sample_contract_with_dynamic_transaction_id(); $c->{same_id_ordering_policy} = { read => { concrete_id_reuse => 'issue-order-queue' } }; $c }, qr/same_id_ordering_policy\.read cannot be combined with dynamic read transaction ID metadata/],
        ['dynamic write response demux rejects unsupported mixed write transaction counts', sub {
            my $c = sample_contract_with_dynamic_write_response_demux();
            push @{$c->{transactions}}, {
                kind             => 'write',
                name             => 'w1',
                tag              => 'wr1',
                request_event    => 'axi0_w1_request',
                completion_event => 'axi0_w1_complete',
                id               => { value => 1 },
            };
            push @{$c->{transactions}}, {
                kind             => 'write',
                name             => 'w2',
                tag              => 'wr2',
                request_event    => 'axi0_w2_request',
                completion_event => 'axi0_w2_complete',
                id               => { value => 2 },
            };
            $c;
        }, qr/response_demux\.write mixed dynamic\/static ID matching supports exactly one dynamic write transaction and one concrete static write transaction/],
        ['dynamic read-data rejects incomplete multiple dynamic read RLAST coverage', sub {
            my $c = sample_contract_with_dynamic_read_response_demux_multi_burst_last();
            $c->{read_data} = {
                read => {
                    capture_scope => 'last-beat',
                    completion_source => 'response-demux',
                    data_signal => 'axi0_rdata',
                    data_width => 32,
                    status_signal => 'axi0_rresp',
                    status_width => 2,
                    status_policy => 'last-beat',
                    interleaving => 'last-beat-by-rid',
                    transactions => [
                        {
                            transaction => 'r0',
                            data_output => 'axi0_r0_last_rdata',
                            status_output => 'axi0_r0_last_rresp',
                        },
                    ],
                },
            };
            $c;
        }, qr/read_data\.read transaction coverage is missing read response_demux dynamic transaction\(s\): r1/],
        ['dynamic read response demux rejects mixed read transaction ownership', sub {
            my $c = sample_contract_with_dynamic_read_response_demux();
            push @{$c->{transactions}}, {
                kind             => 'read',
                name             => 'r1',
                tag              => 'rd1',
                request_event    => 'axi0_r1_request',
                completion_event => 'axi0_r1_complete',
                id               => { value => 1 },
            };
            $c;
        }, qr/response_demux\.read dynamic ID matching requires every read transaction to use dynamic IDs/],
        ['dynamic read RLAST response demux requires width-1 last signal', sub {
            my $c = sample_contract_with_dynamic_read_response_demux_burst_last();
            $c->{response_demux}{read}{last_signal_width} = 2;
            $c;
        }, qr/response_demux\.read\.last_signal_width must be 1 in this slice/],
        ['auto lifecycle unsupported field', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{auto_id_lifecycle}{write}{policy} = 'first-free'; $c }, qr/auto_id_lifecycle\.write unsupported field 'policy'/],
        ['auto lifecycle without ID-family metadata', sub {
            my $c = sample_contract();
            $c->{transactions} = [
                {
                    kind             => 'write',
                    name             => 'w0',
                    tag              => 'wr0',
                    request_event    => 'axi0_write_submit',
                    completion_event => 'axi0_write_complete',
                    id               => { policy => 'auto' },
                },
            ];
            $c->{auto_id_lifecycle} = { write => { pool => [0] } };
            $c;
        }, qr/auto_id_lifecycle requires id_families metadata/],
        ['auto lifecycle without transaction metadata', sub { my $c = sample_contract_with_id_families(); $c->{auto_id_lifecycle} = { write => { pool => [0] } }; $c }, qr/auto_id_lifecycle requires transactions metadata/],
        ['auto lifecycle zero-width ID family', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{id_families}{write} = { width => 0 }; $c }, qr/auto_id_lifecycle\.write requires positive ID-family width/],
        ['auto lifecycle listed family without auto transaction', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{auto_id_lifecycle} = { read => { pool => [0] } }; $c }, qr/auto_id_lifecycle\.read requires at least one auto-ID transaction in the read family/],
        ['auto lifecycle pool too large', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{auto_id_lifecycle}{write}{pool} = [0, 1, 2, 3, 4]; $c }, qr/auto_id_lifecycle\.write\.pool supports 1\.\.4 ID values/],
        ['auto lifecycle duplicate pool value', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{auto_id_lifecycle}{write}{pool} = [0, 0]; $c }, qr/auto_id_lifecycle\.write\.pool duplicates ID value 0/],
        ['auto lifecycle pool value exceeds width', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{id_families}{write}{width} = 1; $c->{auto_id_lifecycle}{write}{pool} = [2]; $c }, qr/auto_id_lifecycle\.write\.pool value 2 does not fit width 1/],
        ['response demux unsupported family', sub { my $c = sample_contract_with_auto_id_lifecycle(); $c->{response_demux} = { address => {} }; $c }, qr/response_demux has unsupported family 'address'/],
        ['response demux missing response event', sub { my $c = sample_contract_with_response_demux(); delete $c->{response_demux}{write}{response_event}; $c }, qr/response_demux\.write is missing required field 'response_event'/],
        ['response demux invalid transaction completion mode', sub { my $c = sample_contract_with_response_demux(); $c->{response_demux}{write}{transaction_completion} = 'authored'; $c }, qr/response_demux\.write\.transaction_completion must be generated/],
        ['response demux response event mismatch', sub { my $c = sample_contract_with_response_demux(); $c->{response_demux}{write}{response_event} = 'axi0_other_write_complete'; $c }, qr/response_demux\.write\.response_event must equal write_complete event 'axi0_write_complete'/],
        ['read response demux missing scope', sub { my $c = sample_contract_with_read_response_demux(); delete $c->{response_demux}{read}{response_scope}; $c }, qr/response_demux\.read is missing required field 'response_scope'/],
        ['read response demux unsupported scope', sub { my $c = sample_contract_with_read_response_demux(); $c->{response_demux}{read}{response_scope} = 'burst'; $c }, qr/response_demux\.read\.response_scope must be single-beat or burst-last/],
        ['read response demux response event mismatch', sub { my $c = sample_contract_with_read_response_demux(); $c->{response_demux}{read}{response_event} = 'axi0_other_read_complete'; $c }, qr/response_demux\.read\.response_event must equal read_complete event 'axi0_read_complete'/],
        ['read response demux invalid transaction completion mode', sub { my $c = sample_contract_with_read_response_demux(); $c->{response_demux}{read}{transaction_completion} = 'authored'; $c }, qr/response_demux\.read\.transaction_completion must be generated/],
        ['read response demux burst-last missing last signal', sub { my $c = sample_contract_with_read_response_demux_burst_last(); delete $c->{response_demux}{read}{last_signal}; $c }, qr/burst-last requires field 'last_signal'/],
        ['read response demux burst-last missing last signal width', sub { my $c = sample_contract_with_read_response_demux_burst_last(); delete $c->{response_demux}{read}{last_signal_width}; $c }, qr/burst-last requires field 'last_signal_width'/],
        ['read response demux burst-last non-one-bit last signal', sub { my $c = sample_contract_with_read_response_demux_burst_last(); $c->{response_demux}{read}{last_signal_width} = 2; $c }, qr/last_signal_width must be 1/],
        ['read response demux single-beat with last signal', sub { my $c = sample_contract_with_read_response_demux(); $c->{response_demux}{read}{last_signal} = 'axi0_rlast'; $c->{response_demux}{read}{last_signal_width} = 1; $c }, qr/last_signal is only supported with response_scope burst-last/],
        ['read response demux last signal collides with response ID', sub { my $c = sample_contract_with_read_response_demux_burst_last(); $c->{response_demux}{read}{last_signal} = 'axi0_rid'; $c }, qr/duplicates signal 'axi0_rid'/],
        ['read response demux without read auto lifecycle metadata', sub {
            my $c = sample_contract_with_response_demux();
            $c->{response_demux} = {
                read => {
                    response_event => 'axi0_read_complete',
                    response_scope => 'single-beat',
                    transaction_completion => 'generated',
                },
            };
            $c;
        }, qr/response_demux\.read requires read auto_id_lifecycle metadata or selected same-id-ordering\.read concrete-id-reuse issue-order-queue with a duplicate concrete-ID group/],
        ['same-ID queue-head response demux without duplicate concrete ID group', sub {
            my $c = sample_contract_with_same_id_issue_order_queue_policy();
            $c->{response_demux} = {
                read => {
                    response_event => 'axi0_read_complete',
                    response_scope => 'single-beat',
                    transaction_completion => 'generated',
                },
            };
            $c;
        }, qr/response_demux\.read concrete same-ID queue-head demux requires at least one duplicate concrete read ID group/],
        ['read data unsupported family', sub { my $c = sample_contract_with_read_response_demux(); $c->{read_data} = { write => {} }; $c }, qr/read_data has unsupported family 'write'/],
        ['read data without read response demux', sub {
            my $c = sample_contract_with_read_auto_id_lifecycle();
            $c->{read_data} = sample_contract_with_read_data()->{read_data};
            $c;
        }, qr/read_data requires generated read response_demux metadata/],
        ['read data with burst-last response demux', sub {
            my $c = sample_contract_with_read_response_demux_burst_last();
            $c->{read_data} = sample_contract_with_read_data()->{read_data};
            $c;
        }, qr/read_data requires response_demux\.read\.response_scope single_beat/],
        ['last-beat read data with single-beat response demux', sub {
            my $c = sample_contract_with_read_data_last_beat();
            $c->{response_demux} = sample_contract_with_read_response_demux()->{response_demux};
            $c;
        }, qr/capture_scope last-beat requires response_demux\.read\.response_scope burst_last/],
        ['last-beat read data missing status policy', sub { my $c = sample_contract_with_read_data_last_beat(); delete $c->{read_data}{read}{status_policy}; $c }, qr/capture_scope last-beat requires status_policy last-beat/],
        ['last-beat read data bad status policy', sub { my $c = sample_contract_with_read_data_last_beat(); $c->{read_data}{read}{status_policy} = 'aggregate'; $c }, qr/capture_scope last-beat requires status_policy last-beat/],
        ['single-beat read data with status policy', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{status_policy} = 'last-beat'; $c }, qr/status_policy is only supported with capture_scope last-beat/],
        ['single-beat read data with burst length', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{burst_length} = sample_contract_with_read_data_burst_length()->{read_data}{read}{burst_length}; $c }, qr/burst_length is only supported with capture_scope last-beat/],
        ['single-beat read data with status aggregation', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{status_aggregation} = { policy => 'worst-observed' }; $c }, qr/status_aggregation is only supported with capture_scope multi-beat/],
        ['read data unsupported capture scope', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{capture_scope} = 'burst'; $c }, qr/read_data\.read\.capture_scope must be single-beat, last-beat, or multi-beat/],
        ['read data unsupported completion source', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{completion_source} = 'read-complete'; $c }, qr/read_data\.read\.completion_source must be response-demux/],
        ['read data zero data width', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{data_width} = 0; $c }, qr/read_data\.read\.data_width.*positive integer/],
        ['read data bad status width', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{status_width} = 1; $c }, qr/read_data\.read\.status_width must be 2/],
        ['last-beat read data bad interleaving', sub { my $c = sample_contract_with_read_data_last_beat(); $c->{read_data}{read}{interleaving} = 'single-beat-by-rid'; $c }, qr/interleaving must be last-beat-by-rid for capture_scope last-beat/],
        ['burst-length unsupported source', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{source} = 'beats'; $c }, qr/burst_length\.source must be arlen/],
        ['burst-length bad signal width', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{signal_width} = 4; $c }, qr/burst_length\.signal_width must be 8/],
        ['burst-length unsupported encoding', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{encoding} = 'raw'; $c }, qr/burst_length\.encoding must be axlen-plus-one/],
        ['burst-length unsupported capture boundary', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{capture} = 'response'; $c }, qr/burst_length\.capture must be request/],
        ['burst-length oversized max beats', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{max_beats} = 257; $c }, qr/burst_length\.max_beats must be in 1\.\.256/],
        ['burst-length unsupported validation mode', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{validation} = 'generated'; $c }, qr/burst_length\.validation must be report-only or runtime-assertion/],
        ['burst-length signal collision', sub { my $c = sample_contract_with_read_data_burst_length(); $c->{read_data}{read}{burst_length}{signal} = 'axi0_rid'; $c }, qr/duplicates signal 'axi0_rid'/],
        ['multi-beat read data with report-only validation', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{burst_length}{validation} = 'report-only'; $c }, qr/capture_scope multi-beat requires burst_length\.validation runtime-assertion/],
        ['multi-beat read data with single-beat response demux', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{response_demux} = sample_contract_with_read_response_demux()->{response_demux}; $c }, qr/capture_scope multi-beat requires response_demux\.read\.response_scope burst_last/],
        ['multi-beat read data missing status policy', sub { my $c = sample_contract_with_read_data_multi_beat(); delete $c->{read_data}{read}{status_policy}; $c }, qr/capture_scope multi-beat requires status_policy per-beat/],
        ['multi-beat read data bad status aggregation policy', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{status_aggregation}{policy} = 'last-beat'; $c }, qr/status_aggregation\.policy must be worst-observed/],
        ['multi-beat read data aggregate output without aggregation', sub { my $c = sample_contract_with_read_data_multi_beat(); delete $c->{read_data}{read}{status_aggregation}; $c }, qr/status_aggregate_output requires read_data\.read\.status_aggregation/],
        ['multi-beat read data missing status aggregate output', sub { my $c = sample_contract_with_read_data_multi_beat(); delete $c->{read_data}{read}{transactions}[0]{status_aggregate_output}; $c }, qr/read_data\.read\.transactions\[0\] is missing required field 'status_aggregate_output'/],
        ['multi-beat read data bad interleaving', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{interleaving} = 'last-beat-by-rid'; $c }, qr/interleaving must be multi-beat-by-rid for capture_scope multi-beat/],
        ['multi-beat read data legacy transaction output', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{transactions}[0]{data_output} = 'axi0_r0_last_rdata'; $c }, qr/read_data\.read\.transactions\[0\] unsupported field 'data_output'/],
        ['multi-beat read data missing valid mask', sub { my $c = sample_contract_with_read_data_multi_beat(); delete $c->{read_data}{read}{transactions}[0]{valid_mask_output}; $c }, qr/read_data\.read\.transactions\[0\] is missing required field 'valid_mask_output'/],
        ['multi-beat read data lane collision', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{transactions}[1]{data_output_prefix} = 'axi0_r0_beat_rdata'; $c }, qr/duplicates signal 'axi0_r0_beat_rdata_0'/],
        ['multi-beat read data valid-mask collision', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{transactions}[0]{valid_mask_output} = 'axi0_rid'; $c }, qr/duplicates signal 'axi0_rid'/],
        ['multi-beat read data aggregate output collision', sub { my $c = sample_contract_with_read_data_multi_beat(); $c->{read_data}{read}{transactions}[0]{status_aggregate_output} = 'axi0_rid'; $c }, qr/duplicates signal 'axi0_rid'/],
        ['read data unknown transaction', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{transactions}[0]{transaction} = 'r2'; $c }, qr/read_data\.read transaction 'r2' is not covered/],
        ['read data missing covered transaction', sub { my $c = sample_contract_with_read_data(); pop @{$c->{read_data}{read}{transactions}}; $c }, qr/read_data\.read transaction coverage is missing read response_demux auto transaction\(s\): r1/],
        ['read data output collision', sub { my $c = sample_contract_with_read_data(); $c->{read_data}{read}{transactions}[0]{data_output} = 'axi0_rid'; $c }, qr/duplicates signal 'axi0_rid'/],
        ['response demux without ID-family metadata', sub { my $c = sample_contract(); $c->{response_demux} = { write => { response_event => 'axi0_write_complete', transaction_completion => 'generated' } }; $c }, qr/response_demux requires id_families metadata/],
        ['response demux without transaction metadata', sub { my $c = sample_contract_with_id_families(); $c->{response_demux} = { write => { response_event => 'axi0_write_complete', transaction_completion => 'generated' } }; $c }, qr/response_demux requires transactions metadata/],
        ['response demux without auto lifecycle metadata', sub { my $c = sample_contract_with_transactions(); $c->{response_demux} = { write => { response_event => 'axi0_write_complete', transaction_completion => 'generated' } }; $c }, qr/response_demux\.write requires write auto_id_lifecycle metadata or selected same-id-ordering\.write concrete-id-reuse issue-order-queue with a duplicate concrete-ID group/],
        ['response demux without write auto lifecycle metadata', sub {
            my $c = sample_contract_with_response_demux();
            $c->{transactions}[2]{id} = { policy => 'auto' };
            $c->{auto_id_lifecycle} = { read => { pool => [0] } };
            $c;
        }, qr/response_demux\.write requires write auto_id_lifecycle metadata or selected same-id-ordering\.write concrete-id-reuse issue-order-queue with a duplicate concrete-ID group/],
        ['bad source anchors', sub { my $c = sample_contract(); $c->{source}{anchors} = {}; $c }, qr/source\.anchors must be an array reference/],
    );

    for my $case (@cases) {
        my ($label, $build, $pattern) = @$case;
        my $ok = eval { $generator->generate($build->()); 1 };
        ok(!$ok, "$label is rejected");
        like($@, $pattern, "$label diagnostic is targeted");
    }
};

done_testing();

sub generate_sample {
    return FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate(sample_contract());
}

sub sample_contract {
    return {
        name              => 'axi0',
        intent_name       => 'axi_manager_capacity_status',
        protocol          => 'axi4',
        submit_policy     => 'try',
        clock             => 'clk',
        reset             => { signal => 'rst_n', active_low => 1, async => 1 },
        read_max_pending  => 4,
        write_max_pending => 2,
        read_submit       => 'axi0_read_submit',
        read_complete     => 'axi0_read_complete',
        write_submit      => 'axi0_write_submit',
        write_complete    => 'axi0_write_complete',
        status            => {
            read_can_accept      => 'axi0_read_can_accept',
            write_can_accept     => 'axi0_write_can_accept',
            read_full            => 'axi0_read_full',
            write_full           => 'axi0_write_full',
            pending_reads        => 'axi0_pending_reads',
            pending_writes       => 'axi0_pending_writes',
            read_slots_available => 'axi0_read_slots_available',
            write_slots_available => 'axi0_write_slots_available',
        },
        source => {
            object_id => 'axi-manager-capacity-status',
            anchors => [
                { document => 'IHI0022_L_2025-08', section => 'A1.1' },
                { document => 'IHI0022_L_2025-08', section => 'A1.2' },
                { document => 'IHI0022_L_2025-08', section => 'A5.1' },
            ],
        },
    };
}

sub sample_contract_with_id_families {
    my $contract = sample_contract();
    $contract->{id_families} = {
        write => {
            width => 4,
            request_id_signal => 'axi0_awid',
            response_id_signal => 'axi0_bid',
        },
        read => {
            width => 4,
            request_id_signal => 'axi0_arid',
            response_id_signal => 'axi0_rid',
        },
    };
    return $contract;
}

sub sample_contract_with_transactions {
    my $contract = sample_contract_with_id_families();
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_write_submit',
            completion_event => 'axi0_write_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_read_submit',
            completion_event => 'axi0_read_complete',
            id               => { value => 3 },
        },
    ];
    return $contract;
}

sub sample_contract_with_dynamic_transaction_id {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_transaction_id';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-transaction-id';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_write_submit',
            completion_event => 'axi0_write_complete',
            id               => { policy => 'dynamic' },
        },
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_read_submit',
            completion_event => 'axi0_read_complete',
            id               => { policy => 'dynamic' },
        },
    ];
    return $contract;
}

sub sample_contract_with_dynamic_write_response_demux {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_write_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-write-response-demux';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_w0_request',
            completion_event => 'axi0_w0_complete',
            id               => { policy => 'dynamic' },
        },
    ];
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_write_response_demux_multi {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_write_response_demux_multi';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-write-response-demux-multi';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_w0_request',
            completion_event => 'axi0_w0_complete',
            id               => { policy => 'dynamic' },
        },
        {
            kind             => 'write',
            name             => 'w1',
            tag              => 'wr1',
            request_event    => 'axi0_w1_request',
            completion_event => 'axi0_w1_complete',
            id               => { policy => 'dynamic' },
        },
    ];
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_mixed_dynamic_static_write_response_demux {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_mixed_dynamic_static_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-mixed-dynamic-static-response-demux';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_w0_request',
            completion_event => 'axi0_w0_complete',
            id               => { policy => 'dynamic' },
        },
        {
            kind             => 'write',
            name             => 'w1',
            tag              => 'wr1',
            request_event    => 'axi0_w1_request',
            completion_event => 'axi0_w1_complete',
            id               => { value => 3 },
        },
    ];
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_mixed_dynamic_static_read_response_demux {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux';
    $contract->{transactions} = [
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { policy => 'dynamic' },
        },
        {
            kind             => 'read',
            name             => 'r1',
            tag              => 'rd1',
            request_event    => 'axi0_r1_request',
            completion_event => 'axi0_r1_complete',
            id               => { value => 3 },
        },
    ];
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_mixed_dynamic_static_read_response_demux_burst_last {
    my $contract = sample_contract_with_mixed_dynamic_static_read_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_burst_last';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-mixed-dynamic-static-response-demux-burst-last';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_dynamic_read_response_demux {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-response-demux';
    $contract->{transactions} = [
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { policy => 'dynamic' },
        },
    ];
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_response_demux_multi {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_response_demux_multi';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-response-demux-multi';
    $contract->{transactions} = [
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { policy => 'dynamic' },
        },
        {
            kind             => 'read',
            name             => 'r1',
            tag              => 'rd1',
            request_event    => 'axi0_r1_request',
            completion_event => 'axi0_r1_complete',
            id               => { policy => 'dynamic' },
        },
    ];
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_response_demux_multi_burst_last {
    my $contract = sample_contract_with_dynamic_read_response_demux_multi();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_response_demux_multi_burst_last';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-response-demux-multi-burst-last';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_dynamic_read_response_demux_burst_last {
    my $contract = sample_contract_with_dynamic_read_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_response_demux_burst_last';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-response-demux-burst-last';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_dynamic_read_data {
    my $contract = sample_contract_with_dynamic_read_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data';
    $contract->{read_data} = {
        read => {
            capture_scope => 'single-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            interleaving => 'single-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_rdata',
                    status_output => 'axi0_r0_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_data_last_beat {
    my $contract = sample_contract_with_dynamic_read_response_demux_burst_last();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_last_beat';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-last-beat';
    $contract->{read_data} = {
        read => {
            capture_scope => 'last-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            status_policy => 'last-beat',
            interleaving => 'last-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_last_rdata',
                    status_output => 'axi0_r0_last_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_data_multi {
    my $contract = sample_contract_with_dynamic_read_response_demux_multi();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_multi';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-multi';
    $contract->{read_data} = {
        read => {
            capture_scope => 'single-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            interleaving => 'single-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_rdata',
                    status_output => 'axi0_r0_rresp',
                },
                {
                    transaction => 'r1',
                    data_output => 'axi0_r1_rdata',
                    status_output => 'axi0_r1_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_data_multi_last_beat {
    my $contract = sample_contract_with_dynamic_read_response_demux_multi_burst_last();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_multi_last_beat';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-multi-last-beat';
    $contract->{read_data} = {
        read => {
            capture_scope => 'last-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            status_policy => 'last-beat',
            interleaving => 'last-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_last_rdata',
                    status_output => 'axi0_r0_last_rresp',
                },
                {
                    transaction => 'r1',
                    data_output => 'axi0_r1_last_rdata',
                    status_output => 'axi0_r1_last_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_data_multi_burst_length {
    my $contract = sample_contract_with_dynamic_read_data_multi_last_beat();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length';
    $contract->{read_data}{read}{burst_length} = {
        source       => 'arlen',
        signal       => 'axi0_arlen',
        signal_width => 8,
        encoding     => 'axlen-plus-one',
        capture      => 'request',
        max_beats    => 16,
        validation   => 'report-only',
    };
    return $contract;
}

sub sample_contract_with_dynamic_read_data_multi_burst_length_runtime_assertion {
    my $contract = sample_contract_with_dynamic_read_data_multi_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_multi_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-multi-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_dynamic_read_data_multi_transaction_multi_beat {
    my $contract = sample_contract_with_dynamic_read_data_multi_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_dynamic_read_data_multi_transaction_multi_beat';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-dynamic-read-data-multi-transaction-multi-beat';
    $contract->{read_data}{read}{capture_scope} = 'multi-beat';
    $contract->{read_data}{read}{status_policy} = 'per-beat';
    $contract->{read_data}{read}{status_aggregation} = {
        policy => 'worst-observed',
    };
    $contract->{read_data}{read}{interleaving} = 'multi-beat-by-rid';
    $contract->{read_data}{read}{transactions} = [
        {
            transaction             => 'r0',
            data_output_prefix      => 'axi0_r0_beat_rdata',
            status_output_prefix    => 'axi0_r0_beat_rresp',
            status_aggregate_output => 'axi0_r0_rresp',
            valid_mask_output       => 'axi0_r0_beat_valid',
            length_output           => 'axi0_r0_read_beats',
        },
        {
            transaction             => 'r1',
            data_output_prefix      => 'axi0_r1_beat_rdata',
            status_output_prefix    => 'axi0_r1_beat_rresp',
            status_aggregate_output => 'axi0_r1_rresp',
            valid_mask_output       => 'axi0_r1_beat_valid',
            length_output           => 'axi0_r1_read_beats',
        },
    ];
    return $contract;
}

sub sample_contract_with_transaction_event_dispatch {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_transaction_event_dispatch';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-transaction-event-dispatch';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_w0_request',
            completion_event => 'axi0_w0_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'write',
            name             => 'w1',
            tag              => 'wr1',
            request_event    => 'axi0_w1_request',
            completion_event => 'axi0_w1_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { value => 3 },
        },
    ];
    return $contract;
}

sub sample_contract_with_same_id_reject_policy {
    my $contract = sample_contract_with_transaction_event_dispatch();
    $contract->{intent_name} = 'axi_manager_capacity_status_same_id_reject_policy';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-same-id-reject-policy';
    $contract->{same_id_ordering_policy} = {
        read => {
            concrete_id_reuse => 'reject',
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_issue_order_queue_policy {
    my $contract = sample_contract_with_transaction_event_dispatch();
    $contract->{intent_name} = 'axi_manager_capacity_status_same_id_issue_order_queue_policy';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-same-id-issue-order-queue-policy';
    $contract->{same_id_ordering_policy} = {
        read => {
            concrete_id_reuse => 'issue-order-queue',
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_issue_order_queue_policy_two_concrete_reads {
    my $contract = sample_contract_with_same_id_issue_order_queue_policy();
    push @{$contract->{transactions}}, {
        kind             => 'read',
        name             => 'r1',
        tag              => 'rd1',
        request_event    => 'axi0_r1_request',
        completion_event => 'axi0_r1_complete',
        id               => { value => 4 },
    };
    return $contract;
}

sub sample_contract_with_same_id_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_issue_order_queue_policy();
    $contract->{intent_name} = 'axi_manager_capacity_status_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-same-id-queue-head-response-demux';
    push @{$contract->{transactions}}, {
        kind             => 'read',
        name             => 'r1',
        tag              => 'rd1',
        request_event    => 'axi0_r1_request',
        completion_event => 'axi0_r1_complete',
        id               => { value => 3 },
    };
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'burst-last',
            last_signal => 'axi0_rlast',
            last_signal_width => 1,
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_read_multi_group_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-group-same-id-queue-head-response-demux';
    push @{$contract->{transactions}},
        {
            kind             => 'read',
            name             => 'r2',
            tag              => 'rd2',
            request_event    => 'axi0_r2_request',
            completion_event => 'axi0_r2_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'read',
            name             => 'r3',
            tag              => 'rd3',
            request_event    => 'axi0_r3_request',
            completion_event => 'axi0_r3_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_issue_order_queue_policy();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-same-id-queue-head-response-demux';
    push @{$contract->{transactions}}, {
        kind             => 'read',
        name             => 'r1',
        tag              => 'rd1',
        request_event    => 'axi0_r1_request',
        completion_event => 'axi0_r1_complete',
        id               => { value => 3 },
    };
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-depth3-same-id-queue-head-response-demux';
    $contract->{read_max_pending} = 3;
    push @{$contract->{transactions}}, {
        kind             => 'read',
        name             => 'r2',
        tag              => 'rd2',
        request_event    => 'axi0_r2_request',
        completion_event => 'axi0_r2_complete',
        id               => { value => 3 },
    };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-multi-depth3-same-id-queue-head-response-demux';
    $contract->{read_max_pending} = 6;
    push @{$contract->{transactions}},
        {
            kind             => 'read',
            name             => 'r3',
            tag              => 'rd3',
            request_event    => 'axi0_r3_request',
            completion_event => 'axi0_r3_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'read',
            name             => 'r4',
            tag              => 'rd4',
            request_event    => 'axi0_r4_request',
            completion_event => 'axi0_r4_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'read',
            name             => 'r5',
            tag              => 'rd5',
            request_event    => 'axi0_r5_request',
            completion_event => 'axi0_r5_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-mixed-depth3-depth2-same-id-queue-head-response-demux';
    $contract->{read_max_pending} = 5;
    push @{$contract->{transactions}},
        {
            kind             => 'read',
            name             => 'r3',
            tag              => 'rd3',
            request_event    => 'axi0_r3_request',
            completion_event => 'axi0_r3_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'read',
            name             => 'r4',
            tag              => 'rd4',
            request_event    => 'axi0_r4_request',
            completion_event => 'axi0_r4_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-response-demux';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-response-demux';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-response-demux';
    $contract->{response_demux}{read}{response_scope} = 'burst-last';
    $contract->{response_demux}{read}{last_signal} = 'axi0_rlast';
    $contract->{response_demux}{read}{last_signal_width} = 1;
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_depth3_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_last_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}}, {
        transaction   => 'r2',
        data_output   => 'axi0_r2_last_rdata',
        status_output => 'axi0_r2_last_rresp',
    };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_last_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_last_rdata',
            status_output => 'axi0_r2_last_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_last_rdata',
            status_output => 'axi0_r3_last_rresp',
        },
        {
            transaction   => 'r4',
            data_output   => 'axi0_r4_last_rdata',
            status_output => 'axi0_r4_last_rresp',
        },
        {
            transaction   => 'r5',
            data_output   => 'axi0_r5_last_rdata',
            status_output => 'axi0_r5_last_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_last_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_last_rdata',
            status_output => 'axi0_r2_last_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_last_rdata',
            status_output => 'axi0_r3_last_rresp',
        },
        {
            transaction   => 'r4',
            data_output   => 'axi0_r4_last_rdata',
            status_output => 'axi0_r4_last_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length {
    my $contract = sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length}
        = sample_contract_with_same_id_read_last_beat_queue_head_burst_length()->{read_data}{read}{burst_length};
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length {
    my $contract = sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length}
        = sample_contract_with_same_id_read_last_beat_queue_head_burst_length()->{read_data}{read}{burst_length};
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length_runtime_assertion {
    my $contract = sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length_runtime_assertion {
    my $contract = sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_multi_beat_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_multi_depth3_queue_head_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_multi_depth3_same_id_queue_head_multi_beat_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-multi-depth3-same-id-queue-head-multi-beat-read-data';
    $contract->{read_data} = sample_contract_with_read_data_multi_beat()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction             => 'r2',
            data_output_prefix      => 'axi0_r2_beat_rdata',
            status_output_prefix    => 'axi0_r2_beat_rresp',
            status_aggregate_output => 'axi0_r2_rresp',
            valid_mask_output       => 'axi0_r2_beat_valid',
            length_output           => 'axi0_r2_read_beats',
        },
        {
            transaction             => 'r3',
            data_output_prefix      => 'axi0_r3_beat_rdata',
            status_output_prefix    => 'axi0_r3_beat_rresp',
            status_aggregate_output => 'axi0_r3_rresp',
            valid_mask_output       => 'axi0_r3_beat_valid',
            length_output           => 'axi0_r3_read_beats',
        },
        {
            transaction             => 'r4',
            data_output_prefix      => 'axi0_r4_beat_rdata',
            status_output_prefix    => 'axi0_r4_beat_rresp',
            status_aggregate_output => 'axi0_r4_rresp',
            valid_mask_output       => 'axi0_r4_beat_valid',
            length_output           => 'axi0_r4_read_beats',
        },
        {
            transaction             => 'r5',
            data_output_prefix      => 'axi0_r5_beat_rdata',
            status_output_prefix    => 'axi0_r5_beat_rresp',
            status_aggregate_output => 'axi0_r5_rresp',
            valid_mask_output       => 'axi0_r5_beat_valid',
            length_output           => 'axi0_r5_read_beats',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_multi_beat_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_mixed_depth3_depth2_queue_head_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_depth3_depth2_same_id_queue_head_multi_beat_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-depth3-depth2-same-id-queue-head-multi-beat-read-data';
    $contract->{read_data} = sample_contract_with_read_data_multi_beat()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction             => 'r2',
            data_output_prefix      => 'axi0_r2_beat_rdata',
            status_output_prefix    => 'axi0_r2_beat_rresp',
            status_aggregate_output => 'axi0_r2_rresp',
            valid_mask_output       => 'axi0_r2_beat_valid',
            length_output           => 'axi0_r2_read_beats',
        },
        {
            transaction             => 'r3',
            data_output_prefix      => 'axi0_r3_beat_rdata',
            status_output_prefix    => 'axi0_r3_beat_rresp',
            status_aggregate_output => 'axi0_r3_rresp',
            valid_mask_output       => 'axi0_r3_beat_valid',
            length_output           => 'axi0_r3_read_beats',
        },
        {
            transaction             => 'r4',
            data_output_prefix      => 'axi0_r4_beat_rdata',
            status_output_prefix    => 'axi0_r4_beat_rresp',
            status_aggregate_output => 'axi0_r4_rresp',
            valid_mask_output       => 'axi0_r4_beat_valid',
            length_output           => 'axi0_r4_read_beats',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length {
    my $contract = sample_contract_with_same_id_read_burst_last_depth3_queue_head_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length}
        = sample_contract_with_same_id_read_last_beat_queue_head_burst_length()->{read_data}{read}{burst_length};
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length_runtime_assertion {
    my $contract = sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_same_id_read_burst_last_depth3_queue_head_multi_beat_read_data {
    my $contract = sample_contract_with_same_id_read_burst_last_depth3_queue_head_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_depth3_same_id_queue_head_multi_beat_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-depth3-same-id-queue-head-multi-beat-read-data';
    $contract->{read_data} = sample_contract_with_read_data_multi_beat()->{read_data};
    push @{$contract->{read_data}{read}{transactions}}, {
        transaction             => 'r2',
        data_output_prefix      => 'axi0_r2_beat_rdata',
        status_output_prefix    => 'axi0_r2_beat_rresp',
        status_aggregate_output => 'axi0_r2_rresp',
        valid_mask_output       => 'axi0_r2_beat_valid',
        length_output           => 'axi0_r2_read_beats',
    };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_depth3_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_single_beat_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_depth3_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-depth3-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_single_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}}, {
        transaction   => 'r2',
        data_output   => 'axi0_r2_rdata',
        status_output => 'axi0_r2_rresp',
    };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_single_beat_multi_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_multi_depth3_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-multi-depth3-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_single_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_rdata',
            status_output => 'axi0_r2_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_rdata',
            status_output => 'axi0_r3_rresp',
        },
        {
            transaction   => 'r4',
            data_output   => 'axi0_r4_rdata',
            status_output => 'axi0_r4_rresp',
        },
        {
            transaction   => 'r5',
            data_output   => 'axi0_r5_rdata',
            status_output => 'axi0_r5_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_single_beat_mixed_depth3_depth2_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_mixed_depth3_depth2_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-mixed-depth3-depth2-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_single_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_rdata',
            status_output => 'axi0_r2_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_rdata',
            status_output => 'axi0_r3_rresp',
        },
        {
            transaction   => 'r4',
            data_output   => 'axi0_r4_rdata',
            status_output => 'axi0_r4_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_multi_group_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_read_single_beat_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-multi-group-same-id-queue-head-response-demux';
    $contract->{read_max_pending} = 4;
    push @{$contract->{transactions}},
        {
            kind             => 'read',
            name             => 'r2',
            tag              => 'rd2',
            request_event    => 'axi0_r2_request',
            completion_event => 'axi0_r2_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'read',
            name             => 'r3',
            tag              => 'rd3',
            request_event    => 'axi0_r3_request',
            completion_event => 'axi0_r3_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_single_beat_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-same-id-queue-head-read-data';
    $contract->{read_data} = {
        read => {
            capture_scope     => 'single-beat',
            completion_source => 'response-demux',
            data_signal       => 'axi0_rdata',
            data_width        => 32,
            status_signal     => 'axi0_rresp',
            status_width      => 2,
            interleaving      => 'single-beat-by-rid',
            transactions      => [
                {
                    transaction   => 'r0',
                    data_output   => 'axi0_r0_rdata',
                    status_output => 'axi0_r0_rresp',
                },
                {
                    transaction   => 'r1',
                    data_output   => 'axi0_r1_rdata',
                    status_output => 'axi0_r1_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_read_single_beat_multi_group_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_single_beat_multi_group_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_multi_group_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-multi-group-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_single_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_rdata',
            status_output => 'axi0_r2_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_rdata',
            status_output => 'axi0_r3_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_last_beat_queue_head_read_data {
    my $contract = sample_contract_with_same_id_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-read-data';
    $contract->{read_data} = {
        read => {
            capture_scope     => 'last-beat',
            completion_source => 'response-demux',
            data_signal       => 'axi0_rdata',
            data_width        => 32,
            status_signal     => 'axi0_rresp',
            status_width      => 2,
            status_policy     => 'last-beat',
            interleaving      => 'last-beat-by-rid',
            transactions      => [
                {
                    transaction   => 'r0',
                    data_output   => 'axi0_r0_last_rdata',
                    status_output => 'axi0_r0_last_rresp',
                },
                {
                    transaction   => 'r1',
                    data_output   => 'axi0_r1_last_rdata',
                    status_output => 'axi0_r1_last_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_read_last_beat_queue_head_burst_length {
    my $contract = sample_contract_with_same_id_read_last_beat_queue_head_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length} = {
        source       => 'arlen',
        signal       => 'axi0_arlen',
        signal_width => 8,
        encoding     => 'axlen-plus-one',
        capture      => 'request',
        max_beats    => 16,
        validation   => 'report-only',
    };
    return $contract;
}

sub sample_contract_with_same_id_read_last_beat_queue_head_burst_length_runtime_assertion {
    my $contract = sample_contract_with_same_id_read_last_beat_queue_head_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-last-beat-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_same_id_read_multi_beat_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_last_beat_queue_head_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-beat-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_read_data_multi_beat()->{read_data};
    return $contract;
}

sub sample_contract_with_same_id_read_multi_group_queue_head_read_data {
    my $contract = sample_contract_with_same_id_read_multi_group_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-group-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_read_data_multi_beat()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction             => 'r2',
            data_output_prefix      => 'axi0_r2_beat_rdata',
            status_output_prefix    => 'axi0_r2_beat_rresp',
            status_aggregate_output => 'axi0_r2_rresp',
            valid_mask_output       => 'axi0_r2_beat_valid',
            length_output           => 'axi0_r2_read_beats',
        },
        {
            transaction             => 'r3',
            data_output_prefix      => 'axi0_r3_beat_rdata',
            status_output_prefix    => 'axi0_r3_beat_rresp',
            status_aggregate_output => 'axi0_r3_rresp',
            valid_mask_output       => 'axi0_r3_beat_valid',
            length_output           => 'axi0_r3_read_beats',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_multi_group_queue_head_last_beat_read_data {
    my $contract = sample_contract_with_same_id_read_multi_group_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-group-last-beat-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_last_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}},
        {
            transaction   => 'r2',
            data_output   => 'axi0_r2_last_rdata',
            status_output => 'axi0_r2_last_rresp',
        },
        {
            transaction   => 'r3',
            data_output   => 'axi0_r3_last_rdata',
            status_output => 'axi0_r3_last_rresp',
        };
    return $contract;
}

sub sample_contract_with_same_id_read_multi_group_queue_head_last_beat_burst_length {
    my $contract = sample_contract_with_same_id_read_multi_group_queue_head_last_beat_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-group-last-beat-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length}
        = sample_contract_with_same_id_read_last_beat_queue_head_burst_length()->{read_data}{read}{burst_length};
    return $contract;
}

sub sample_contract_with_same_id_read_multi_group_queue_head_last_beat_burst_length_runtime_assertion {
    my $contract = sample_contract_with_same_id_read_multi_group_queue_head_last_beat_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-multi-group-last-beat-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_same_id_write_queue_head_response_demux {
    my $contract = sample_contract_with_transaction_event_dispatch();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-same-id-queue-head-response-demux';
    $contract->{transactions}[0]{id} = { value => 3 };
    $contract->{transactions}[1]{id} = { value => 3 };
    $contract->{same_id_ordering_policy} = {
        write => {
            concrete_id_reuse => 'issue-order-queue',
        },
    };
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_same_id_write_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_write_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-depth3-same-id-queue-head-response-demux';
    $contract->{write_max_pending} = 3;
    splice @{$contract->{transactions}}, 2, 0, {
        kind             => 'write',
        name             => 'w2',
        tag              => 'wr2',
        request_event    => 'axi0_w2_request',
        completion_event => 'axi0_w2_complete',
        id               => { value => 3 },
    };
    return $contract;
}

sub sample_contract_with_same_id_write_multi_depth3_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_write_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_multi_depth3_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-multi-depth3-same-id-queue-head-response-demux';
    $contract->{write_max_pending} = 6;
    $contract->{transactions}[3]{id} = { value => 4 };
    push @{$contract->{transactions}},
        {
            kind             => 'write',
            name             => 'w3',
            tag              => 'wr3',
            request_event    => 'axi0_w3_request',
            completion_event => 'axi0_w3_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'write',
            name             => 'w4',
            tag              => 'wr4',
            request_event    => 'axi0_w4_request',
            completion_event => 'axi0_w4_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'write',
            name             => 'w5',
            tag              => 'wr5',
            request_event    => 'axi0_w5_request',
            completion_event => 'axi0_w5_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_write_mixed_depth3_depth2_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_write_depth3_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_mixed_depth3_depth2_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-mixed-depth3-depth2-same-id-queue-head-response-demux';
    $contract->{write_max_pending} = 5;
    $contract->{transactions}[3]{id} = { value => 4 };
    push @{$contract->{transactions}},
        {
            kind             => 'write',
            name             => 'w3',
            tag              => 'wr3',
            request_event    => 'axi0_w3_request',
            completion_event => 'axi0_w3_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'write',
            name             => 'w4',
            tag              => 'wr4',
            request_event    => 'axi0_w4_request',
            completion_event => 'axi0_w4_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_same_id_write_multi_group_queue_head_response_demux {
    my $contract = sample_contract_with_same_id_write_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-write-multi-group-same-id-queue-head-response-demux';
    $contract->{write_max_pending} = 4;
    $contract->{transactions}[2]{id} = { value => 4 };
    push @{$contract->{transactions}},
        {
            kind             => 'write',
            name             => 'w2',
            tag              => 'wr2',
            request_event    => 'axi0_w2_request',
            completion_event => 'axi0_w2_complete',
            id               => { value => 5 },
        },
        {
            kind             => 'write',
            name             => 'w3',
            tag              => 'wr3',
            request_event    => 'axi0_w3_request',
            completion_event => 'axi0_w3_complete',
            id               => { value => 5 },
        };
    return $contract;
}

sub sample_contract_with_auto_id_lifecycle {
    my $contract = sample_contract_with_transaction_event_dispatch();
    $contract->{intent_name} = 'axi_manager_capacity_status_auto_id_lifecycle';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-auto-id-lifecycle';
    $contract->{auto_id_lifecycle} = {
        write => {
            pool => [0, 1],
        },
    };
    return $contract;
}

sub sample_contract_with_response_demux {
    my $contract = sample_contract_with_auto_id_lifecycle();
    $contract->{intent_name} = 'axi_manager_capacity_status_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-response-demux';
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_read_auto_id_lifecycle {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_response_demux_base';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-response-demux-base';
    $contract->{transactions} = [
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'read',
            name             => 'r1',
            tag              => 'rd1',
            request_event    => 'axi0_r1_request',
            completion_event => 'axi0_r1_complete',
            id               => { policy => 'auto' },
        },
    ];
    $contract->{auto_id_lifecycle} = {
        read => {
            pool => [0, 1],
        },
    };
    return $contract;
}

sub sample_contract_with_read_response_demux {
    my $contract = sample_contract_with_read_auto_id_lifecycle();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-response-demux';
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_read_response_demux_burst_last {
    my $contract = sample_contract_with_read_auto_id_lifecycle();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_response_demux_burst_last';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-response-demux-burst-last';
    $contract->{response_demux} = {
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'burst-last',
            last_signal => 'axi0_rlast',
            last_signal_width => 1,
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_read_data {
    my $contract = sample_contract_with_read_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-data';
    $contract->{read_data} = {
        read => {
            capture_scope => 'single-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            interleaving => 'single-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_rdata',
                    status_output => 'axi0_r0_rresp',
                },
                {
                    transaction => 'r1',
                    data_output => 'axi0_r1_rdata',
                    status_output => 'axi0_r1_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_read_data_last_beat {
    my $contract = sample_contract_with_read_response_demux_burst_last();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_data_last_beat';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-data-last-beat';
    $contract->{read_data} = {
        read => {
            capture_scope => 'last-beat',
            completion_source => 'response-demux',
            data_signal => 'axi0_rdata',
            data_width => 32,
            status_signal => 'axi0_rresp',
            status_width => 2,
            status_policy => 'last-beat',
            interleaving => 'last-beat-by-rid',
            transactions => [
                {
                    transaction => 'r0',
                    data_output => 'axi0_r0_last_rdata',
                    status_output => 'axi0_r0_last_rresp',
                },
                {
                    transaction => 'r1',
                    data_output => 'axi0_r1_last_rdata',
                    status_output => 'axi0_r1_last_rresp',
                },
            ],
        },
    };
    return $contract;
}

sub sample_contract_with_read_data_burst_length {
    my $contract = sample_contract_with_read_data_last_beat();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_data_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-data-burst-length';
    $contract->{read_data}{read}{burst_length} = {
        source       => 'arlen',
        signal       => 'axi0_arlen',
        signal_width => 8,
        encoding     => 'axlen-plus-one',
        capture      => 'request',
        max_beats    => 16,
        validation   => 'report-only',
    };
    return $contract;
}

sub sample_contract_with_read_data_burst_length_runtime_assertion {
    my $contract = sample_contract_with_read_data_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_data_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-data-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_read_data_multi_beat {
    my $contract = sample_contract_with_read_data_burst_length_runtime_assertion();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_data_multi_beat';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-data-multi-beat';
    $contract->{read_data}{read}{capture_scope} = 'multi-beat';
    $contract->{read_data}{read}{status_policy} = 'per-beat';
    $contract->{read_data}{read}{status_aggregation} = {
        policy => 'worst-observed',
    };
    $contract->{read_data}{read}{interleaving} = 'multi-beat-by-rid';
    $contract->{read_data}{read}{transactions} = [
        {
            transaction             => 'r0',
            data_output_prefix      => 'axi0_r0_beat_rdata',
            status_output_prefix    => 'axi0_r0_beat_rresp',
            status_aggregate_output => 'axi0_r0_rresp',
            valid_mask_output       => 'axi0_r0_beat_valid',
            length_output           => 'axi0_r0_read_beats',
        },
        {
            transaction             => 'r1',
            data_output_prefix      => 'axi0_r1_beat_rdata',
            status_output_prefix    => 'axi0_r1_beat_rresp',
            status_aggregate_output => 'axi0_r1_rresp',
            valid_mask_output       => 'axi0_r1_beat_valid',
            length_output           => 'axi0_r1_read_beats',
        },
    ];
    return $contract;
}

sub sample_contract_with_mixed_response_demux {
    my $contract = sample_contract_with_id_families();
    $contract->{intent_name} = 'axi_manager_capacity_status_mixed_response_demux';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-mixed-response-demux';
    $contract->{transactions} = [
        {
            kind             => 'write',
            name             => 'w0',
            tag              => 'wr0',
            request_event    => 'axi0_w0_request',
            completion_event => 'axi0_w0_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'write',
            name             => 'w1',
            tag              => 'wr1',
            request_event    => 'axi0_w1_request',
            completion_event => 'axi0_w1_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'read',
            name             => 'r0',
            tag              => 'rd0',
            request_event    => 'axi0_r0_request',
            completion_event => 'axi0_r0_complete',
            id               => { policy => 'auto' },
        },
        {
            kind             => 'read',
            name             => 'r1',
            tag              => 'rd1',
            request_event    => 'axi0_r1_request',
            completion_event => 'axi0_r1_complete',
            id               => { policy => 'auto' },
        },
    ];
    $contract->{auto_id_lifecycle} = {
        write => { pool => [0, 1] },
        read  => { pool => [0, 1] },
    };
    $contract->{response_demux} = {
        write => {
            response_event => 'axi0_write_complete',
            transaction_completion => 'generated',
        },
        read => {
            response_event => 'axi0_read_complete',
            response_scope => 'single-beat',
            transaction_completion => 'generated',
        },
    };
    return $contract;
}

sub sample_contract_with_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux {
    return sample_contract_with_mixed_auto_id_same_id_queue_head_response_demux(
        family => 'read',
        response_scope => 'single-beat',
    );
}

sub sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux {
    return sample_contract_with_mixed_auto_id_same_id_queue_head_response_demux(
        family => 'read',
        response_scope => 'burst-last',
        last_signal => 'axi0_rlast',
    );
}

sub sample_contract_with_read_single_beat_mixed_auto_id_same_id_queue_head_read_data {
    my $contract = sample_contract_with_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-single-beat-mixed-auto-id-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_single_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}}, {
        transaction   => 'r2',
        data_output   => 'axi0_r2_rdata',
        status_output => 'axi0_r2_rresp',
    };
    return $contract;
}

sub sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_read_data {
    my $contract = sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-auto-id-same-id-queue-head-read-data';
    $contract->{read_data} = sample_contract_with_same_id_read_last_beat_queue_head_read_data()->{read_data};
    push @{$contract->{read_data}{read}{transactions}}, {
        transaction   => 'r2',
        data_output   => 'axi0_r2_last_rdata',
        status_output => 'axi0_r2_last_rresp',
    };
    return $contract;
}

sub sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length {
    my $contract = sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_read_data();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-auto-id-same-id-queue-head-burst-length';
    $contract->{read_data}{read}{burst_length}
        = sample_contract_with_read_data_burst_length()->{read_data}{read}{burst_length};
    return $contract;
}

sub sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion {
    my $contract = sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length();
    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-auto-id-same-id-queue-head-burst-length-runtime-assertion';
    $contract->{read_data}{read}{burst_length}{validation} = 'runtime-assertion';
    return $contract;
}

sub sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data {
    my $contract = sample_contract_with_read_burst_last_mixed_auto_id_same_id_queue_head_burst_length_runtime_assertion();
    my $read_data = sample_contract_with_read_data_multi_beat()->{read_data};

    $contract->{intent_name} = 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_multi_beat_read_data';
    $contract->{source}{object_id} = 'axi-manager-capacity-status-read-burst-last-mixed-auto-id-same-id-queue-head-multi-beat-read-data';
    $read_data->{read}{transactions} = [
        map {
            {
                transaction             => $_,
                data_output_prefix      => "axi0_${_}_beat_rdata",
                status_output_prefix    => "axi0_${_}_beat_rresp",
                status_aggregate_output => "axi0_${_}_rresp",
                valid_mask_output       => "axi0_${_}_beat_valid",
                length_output           => "axi0_${_}_read_beats",
            }
        } qw(r0 r1 r2)
    ];
    $contract->{read_data} = $read_data;
    return $contract;
}

sub sample_contract_with_write_mixed_auto_id_same_id_queue_head_response_demux {
    return sample_contract_with_mixed_auto_id_same_id_queue_head_response_demux(
        family => 'write',
    );
}

sub sample_contract_with_mixed_auto_id_same_id_queue_head_response_demux {
    my (%args) = @_;
    my $family = $args{family};
    my $contract = sample_contract_with_id_families();
    my $read = $family eq 'read';
    my $prefix = $read ? 'r' : 'w';
    my $tag_prefix = $read ? 'rd' : 'wr';
    my $submit = $read ? 'read' : 'write';
    my $response_event = $read ? 'axi0_read_complete' : 'axi0_write_complete';

    $contract->{intent_name} = $read
        ? ($args{response_scope} // '') eq 'burst-last'
            ? 'axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux'
            : 'axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux'
        : 'axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux';
    $contract->{source}{object_id} = $read
        ? ($args{response_scope} // '') eq 'burst-last'
            ? 'axi-manager-capacity-status-read-burst-last-mixed-auto-id-same-id-queue-head-response-demux'
            : 'axi-manager-capacity-status-read-single-beat-mixed-auto-id-same-id-queue-head-response-demux'
        : 'axi-manager-capacity-status-write-mixed-auto-id-same-id-queue-head-response-demux';
    $contract->{read_max_pending} = $read ? 4 : 2;
    $contract->{write_max_pending} = $read ? 2 : 4;
    $contract->{transactions} = [
        {
            kind             => $family,
            name             => "${prefix}0",
            tag              => "${tag_prefix}0",
            request_event    => "axi0_${prefix}0_request",
            completion_event => "axi0_${prefix}0_complete",
            id               => { policy => 'auto' },
        },
        {
            kind             => $family,
            name             => "${prefix}1",
            tag              => "${tag_prefix}1",
            request_event    => "axi0_${prefix}1_request",
            completion_event => "axi0_${prefix}1_complete",
            id               => { value => 3 },
        },
        {
            kind             => $family,
            name             => "${prefix}2",
            tag              => "${tag_prefix}2",
            request_event    => "axi0_${prefix}2_request",
            completion_event => "axi0_${prefix}2_complete",
            id               => { value => 3 },
        },
    ];
    $contract->{auto_id_lifecycle} = {
        $family => { pool => [0, 1] },
    };
    $contract->{same_id_ordering_policy} = {
        $family => {
            concrete_id_reuse => 'issue-order-queue',
        },
    };
    my %demux = (
        response_event => $response_event,
        transaction_completion => 'generated',
    );
    if ($read) {
        $demux{response_scope} = $args{response_scope};
        if (($args{response_scope} // '') eq 'burst-last') {
            $demux{last_signal} = $args{last_signal};
            $demux{last_signal_width} = 1;
        }
    }
    $contract->{response_demux} = {
        $family => \%demux,
    };
    return $contract;
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
        [qw(axi0_w0_dynamic_request_idle_or_releasing axi0_write_dynamic_response_active_match axi0_w0_dynamic_completion_active)],
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
            release_recapture_rule => 'axi0_w0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_write',
            release_recapture_source => 'generated_dynamic_demux_completion',
            release_recapture_transaction => 'w0',
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
    is($write->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($write->{transaction_completion_semantics}, 'matched_dynamic_id', "$owner reports matched dynamic ID completion semantics");
    is_deeply($write->{dynamic_transactions}, [qw(w0 w1)], "$owner reports the covered dynamic write transactions");
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], "$owner reports generated dynamic demux rules");
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], "$owner reports generated dynamic completion pulses");
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

sub assert_mixed_dynamic_static_write_response_demux_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $write = $demux->{write};

    is(scalar(@{$report->{transactions}}), 2, "$owner reports dynamic and static write transactions");
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', "$owner reports generated capture/matching for the dynamic write");
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
        "$owner reports concrete static write ID metadata",
    );
    ok($report->{transactions}[1]{id}{fits}, "$owner reports concrete static write ID fits the family width");
    is($demux->{mode}, 'bounded_mixed_dynamic_static_write_bid_demux_contract', "$owner marks mixed dynamic/static write BID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks mixed dynamic/static response-demux behavior generated");
    is($write->{mode}, 'bounded_mixed_dynamic_static_write_bid_demux_contract', "$owner marks write mixed dynamic/static demux mode");
    ok($write->{generated_behavior}, "$owner marks write mixed dynamic/static demux behavior generated");
    is($write->{response_event}, 'axi0_write_complete', "$owner reports the raw write response event");
    is($write->{response_event_role}, 'raw_accepted_write_response', "$owner reports the response-event role");
    is($write->{response_id_signal}, 'axi0_bid', "$owner reports BID as the response ID signal");
    is($write->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($write->{transaction_completion_source}, 'generated_mixed_dynamic_static_demux', "$owner reports generated mixed dynamic/static demux completion ownership");
    is($write->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id', "$owner reports mixed dynamic/static completion semantics");
    is_deeply($write->{dynamic_transactions}, [qw(w0)], "$owner reports the dynamic write transaction");
    is_deeply($write->{static_transactions}, [qw(w1)], "$owner reports the static write transaction");
    is_deeply($write->{mixed_transactions}, { dynamic => 'w0', static => 'w1' }, "$owner reports mixed transaction roles");
    is_deeply(
        $write->{static_id_reservation},
        {
            transaction            => 'w1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        "$owner reports static-ID reservation policy",
    );
    is_deeply($write->{generated_rules}, [qw(axi0_w0_response_demux axi0_w1_response_demux)], "$owner reports generated mixed demux rules");
    is_deeply($write->{generated_completion_signals}, [qw(axi0_w0_complete axi0_w1_complete)], "$owner reports generated mixed completion pulses");
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
        "$owner reports generated mixed dynamic/static assertions",
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
        "$owner reports dynamic capture state and mixed ownership",
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
        "$owner reports static capture state and mixed ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported dynamic-read, same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_mixed_dynamic_static_read_response_demux_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};

    is(scalar(@{$report->{transactions}}), 2, "$owner reports dynamic and static read transactions");
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', "$owner reports generated capture/matching for the dynamic read");
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
        "$owner reports concrete static read ID metadata",
    );
    ok($report->{transactions}[1]{id}{fits}, "$owner reports concrete static read ID fits the family width");
    is($demux->{mode}, 'bounded_mixed_dynamic_static_read_rid_demux_contract', "$owner marks mixed dynamic/static read RID-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks mixed dynamic/static read response-demux behavior generated");
    is($read->{mode}, 'bounded_mixed_dynamic_static_read_rid_demux_contract', "$owner marks read mixed dynamic/static demux mode");
    ok($read->{generated_behavior}, "$owner marks read mixed dynamic/static demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response', "$owner reports the response-event role");
    is($read->{response_scope}, 'single_beat', "$owner reports single-beat response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{transaction_completion_source}, 'generated_mixed_dynamic_static_read_demux', "$owner reports generated mixed dynamic/static read demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_single_beat', "$owner reports mixed dynamic/static read completion semantics");
    is_deeply($read->{dynamic_transactions}, [qw(r0)], "$owner reports the dynamic read transaction");
    is_deeply($read->{static_transactions}, [qw(r1)], "$owner reports the static read transaction");
    is_deeply($read->{mixed_transactions}, { dynamic => 'r0', static => 'r1' }, "$owner reports mixed read transaction roles");
    is_deeply(
        $read->{static_id_reservation},
        {
            transaction            => 'r1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        "$owner reports static-ID reservation policy",
    );
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated mixed read demux rules");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated mixed read completion pulses");
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_not_busy
            axi0_r1_static_request_not_busy
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_not_static_id
            axi0_r0_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
        )],
        "$owner reports generated mixed dynamic/static read assertions",
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
        },
        "$owner reports dynamic read capture state and mixed ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_mixed_dynamic_static_read_rlast_response_demux_report {
    my ($report, $owner) = @_;
    my $demux = $report->{response_demux};
    my $read = $demux->{read};

    is(scalar(@{$report->{transactions}}), 2, "$owner reports dynamic and static read transactions");
    is($report->{transactions}[0]{id}{implementation_status}, 'generated_capture_matching', "$owner reports generated capture/matching for the dynamic read");
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
        "$owner reports concrete static read ID metadata",
    );
    ok($report->{transactions}[1]{id}{fits}, "$owner reports concrete static read ID fits the family width");
    is($demux->{mode}, 'bounded_mixed_dynamic_static_read_rid_rlast_demux_contract', "$owner marks mixed dynamic/static read RID/RLAST-demux contract mode");
    ok($demux->{generated_behavior}, "$owner marks mixed dynamic/static read RLAST response-demux behavior generated");
    is($read->{mode}, 'bounded_mixed_dynamic_static_read_rid_rlast_demux_contract', "$owner marks read mixed dynamic/static RLAST demux mode");
    ok($read->{generated_behavior}, "$owner marks read mixed dynamic/static RLAST demux behavior generated");
    is($read->{response_event}, 'axi0_read_complete', "$owner reports the raw read response event");
    is($read->{response_event_role}, 'raw_accepted_read_response_beat', "$owner reports raw response-beat event role");
    is($read->{response_scope}, 'burst_last', "$owner reports burst-last response scope");
    is($read->{response_id_signal}, 'axi0_rid', "$owner reports RID as the response ID signal");
    is($read->{response_id_direction}, 'generated_input', "$owner reports response ID direction as generated input");
    is($read->{last_signal}, 'axi0_rlast', "$owner reports RLAST");
    is($read->{last_signal_direction}, 'generated_input', "$owner reports RLAST direction as generated input");
    is($read->{last_signal_width}, 1, "$owner reports one-bit RLAST");
    is($read->{transaction_completion_source}, 'generated_mixed_dynamic_static_read_demux_last_beat', "$owner reports generated mixed dynamic/static read last-beat completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_or_static_concrete_id_and_last_signal', "$owner reports mixed dynamic/static read RLAST completion semantics");
    is($read->{beat_valid_output}, 'none', "$owner reports no beat-valid output");
    is($read->{burst_length_source}, 'rlast_only', "$owner reports RLAST-only burst length source");
    is($read->{burst_length_validation}, 'not_generated', "$owner keeps burst-length validation ungenerated");
    is_deeply($read->{dynamic_transactions}, [qw(r0)], "$owner reports the dynamic read transaction");
    is_deeply($read->{static_transactions}, [qw(r1)], "$owner reports the static read transaction");
    is_deeply($read->{mixed_transactions}, { dynamic => 'r0', static => 'r1' }, "$owner reports mixed read transaction roles");
    is_deeply(
        $read->{static_id_reservation},
        {
            transaction            => 'r1',
            concrete_id            => 3,
            concrete_id_literal    => "4'd3",
            dynamic_capture_policy => 'dynamic_id_must_not_equal_static_concrete_id',
        },
        "$owner reports static-ID reservation policy",
    );
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated mixed read RLAST demux rules");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated mixed read RLAST completion pulses");
    is_deeply(
        $read->{generated_assertions},
        [qw(
            axi0_r0_dynamic_request_not_busy
            axi0_r1_static_request_not_busy
            axi0_read_mixed_dynamic_static_request_onehot0
            axi0_r0_dynamic_request_not_static_id
            axi0_r0_dynamic_active_not_static_id
            axi0_read_mixed_dynamic_static_response_active_match
            axi0_r0_r1_read_mixed_dynamic_static_response_unique_match
            axi0_r0_dynamic_completion_active
            axi0_r1_static_completion_active
        )],
        "$owner reports generated mixed dynamic/static read RLAST assertions",
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
        },
        "$owner reports dynamic read RLAST capture state and mixed ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
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
        [qw(axi0_r0_dynamic_request_idle_or_releasing axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)],
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
            release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_read',
            release_recapture_source => 'generated_dynamic_demux_completion',
            release_recapture_transaction => 'r0',
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
    is($read->{response_scope}, 'single_beat', "$owner reports the selected single-beat response scope");
    is($read->{transaction_completion_source}, 'generated_dynamic_demux', "$owner reports generated dynamic demux completion ownership");
    is($read->{transaction_completion_semantics}, 'matched_dynamic_id_single_beat', "$owner reports matched dynamic read ID completion semantics");
    is_deeply($read->{dynamic_transactions}, [qw(r0 r1)], "$owner reports the covered dynamic read transactions");
    is_deeply($read->{generated_rules}, [qw(axi0_r0_response_demux axi0_r1_response_demux)], "$owner reports generated dynamic read demux rules");
    is_deeply($read->{generated_completion_signals}, [qw(axi0_r0_complete axi0_r1_complete)], "$owner reports generated dynamic read completion pulses");
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
    my ($report, $owner) = @_;
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
        [qw(axi0_r0_dynamic_request_idle_or_releasing axi0_read_dynamic_response_active_match axi0_r0_dynamic_completion_active)],
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
            release_recapture_rule => 'axi0_r0_dynamic_id_release_recapture',
            same_cycle_release_recapture_policy => 'single_active_dynamic_read',
            release_recapture_source => 'generated_dynamic_demux_last_beat_completion',
            release_recapture_transaction => 'r0',
        },
        "$owner reports dynamic read RLAST release-recapture capture ownership",
    );
    is_deeply(
        $demux->{residue},
        [qw(same_id_ordering read_data_interleaving bursts)],
        "$owner keeps unsupported same-ID, read-data, and burst residue explicit",
    );
    my %residue = map { $_->{id} => 1 } @{$report->{unsupported_residue}};
    ok($residue{dynamic_transaction_id_behavior}, "$owner keeps future dynamic behavior residue visible");
}

sub assert_mixed_auto_id_queue_head_response_demux_report {
    my ($report, $owner, $case) = @_;
    my $demux = $report->{response_demux};
    my $family = $case->{family};
    my $entry = $demux->{$family};
    my $prefix = $case->{completion_prefix};
    my @transactions = map { "${prefix}$_" } 0 .. 2;

    is(
        $demux->{mode},
        $family eq 'write' ? 'bounded_write_bid_demux_contract' : 'bounded_response_demux_contract',
        "$owner reports top-level response-demux mode",
    );
    ok($demux->{generated_behavior}, "$owner reports generated response-demux behavior");
    is(
        $entry->{mode},
        $family eq 'write'
            ? 'bounded_write_bid_mixed_auto_id_queue_head_demux_contract'
            : 'bounded_read_rid_mixed_auto_id_queue_head_demux_contract',
        "$owner reports mixed family response-demux mode",
    );
    is($entry->{transaction_completion_source}, 'generated_demux_and_queue_head_demux', "$owner reports combined completion source");
    is($entry->{generated_queue_behavior_boundary}, $case->{boundary}, "$owner reports queue-head generated boundary");
    is_deeply($entry->{auto_transactions}, [$transactions[0]], "$owner reports the auto-ID transaction");
    is_deeply($entry->{generated_rules}, [map { "axi0_${_}_response_demux" } @transactions], "$owner reports combined response-demux rules");
    is_deeply($entry->{generated_completion_signals}, [map { "axi0_${_}_complete" } @transactions], "$owner reports combined completion signals");
    is_deeply(
        $entry->{generated_assertions},
        [
            "axi0_${family}_response_demux_active_match",
            "axi0_$transactions[0]_$transactions[1]_${family}_response_demux_unique_match",
            "axi0_$transactions[0]_$transactions[2]_${family}_response_demux_unique_match",
            "axi0_$transactions[1]_$transactions[2]_${family}_response_demux_unique_match",
        ],
        "$owner reports combined response-demux assertions",
    );
    is_deeply(
        $entry->{same_id_issue_order_queues},
        [
            {
                concrete_id          => 3,
                depth                => 2,
                dequeue_event_source => 'queue_head_response_demux',
                transactions         => [@transactions[1, 2]],
            },
        ],
        "$owner reports the concrete same-ID queue-head group",
    );
    if ($family eq 'read') {
        is($entry->{response_scope}, $case->{scope}, "$owner reports read response scope");
        if ($case->{last_signal}) {
            is($entry->{last_signal}, $case->{last_signal}, "$owner reports RLAST signal");
        } else {
            ok(!exists($entry->{last_signal}), "$owner omits RLAST for single-beat response demux");
        }
        my $expected_residue = $case->{demux_residue} // [qw(read_data_interleaving bursts)];
        is_deeply($demux->{residue}, $expected_residue, "$owner reports read residue");
    } else {
        is_deeply($demux->{residue}, [qw(read_response_demux read_data_interleaving bursts)], "$owner reports write residue");
    }
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
    is_deeply(
        $demux->{residue},
        [qw(read_data_interleaving bursts)],
        "$owner removes generated read RID demux behavior from residue",
    );
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

sub assert_counted_low_capacity_rules {
    my ($isf, $owner, %args) = @_;
    my $direction = $args{direction};
    my ($request_expr, undef, $request_width) = counted_request_evaluation_contract(
        max_pending => $args{max_pending},
        terms       => $args{counted_request_terms},
    );
    my $one = sized_decimal_literal($request_width, 1);
    my $two = sized_decimal_literal($request_width, 2);
    my $complete = $args{completion_fanin};
    my $pending_storage = $args{pending_storage};
    my $pending_output = $args{pending_output};
    my $slots_output = $args{slots_output};
    my $full_output = $args{full_output};
    my $can_accept_output = $args{can_accept_output};

    my $fits_one_request_at_occ2 = quotemeta(
        "  (rule ${direction}_counted_req1_nocomplete_occ2 (& (== $request_expr $one) (! $complete) (== $pending_storage 2))"
    );
    like(
        $isf,
        qr/$fits_one_request_at_occ2[\s\S]*\(\Q$pending_storage\E 3\)[\s\S]*\(\Q$pending_output\E 3\)[\s\S]*\(\Q$slots_output\E 0\)[\s\S]*\(\Q$full_output\E 1\)[\s\S]*\(\Q$can_accept_output\E 1\)\)/,
        "$owner accepts one counted request into the final slot",
    );

    my $rejects_two_requests_at_occ2 = quotemeta(
        "  (rule ${direction}_counted_req2_nocomplete_occ2 (& (== $request_expr $two) (! $complete) (== $pending_storage 2))"
    );
    like(
        $isf,
        qr/$rejects_two_requests_at_occ2[\s\S]*\(\Q$pending_storage\E 2\)[\s\S]*\(\Q$pending_output\E 2\)[\s\S]*\(\Q$slots_output\E 1\)[\s\S]*\(\Q$full_output\E 0\)[\s\S]*\(\Q$can_accept_output\E 0\)\)/,
        "$owner rejects an over-capacity counted request set without changing pending",
    );
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

sub assert_counted_low_capacity_admitted_guard {
    my ($boundary, $owner, %args) = @_;
    my $request_expr = $boundary->{request_count_evaluation_expression};
    my $request_width = $boundary->{request_count_evaluation_width};
    my $complete = $args{completion_fanin};
    my $pending_storage = $args{pending_storage};
    my $max_pending = $args{max_pending};
    my $one_slot_left = $max_pending - 1;

    like(
        $boundary->{request_set_fit_expression},
        qr/\Q(& (== $pending_storage $one_slot_left) (! $complete) (<= $request_expr @{[sized_decimal_literal($request_width, 1)]}))\E/,
        "$owner allows only one request when one slot is available without completion",
    );
    like(
        $boundary->{request_set_fit_expression},
        qr/\Q(& (== $pending_storage $one_slot_left) $complete (<= $request_expr @{[sized_decimal_literal($request_width, 2)]}))\E/,
        "$owner credits one completion only when the queue is nonempty",
    );
    like(
        $boundary->{request_set_fit_expression},
        qr/\Q(& (== $pending_storage $max_pending) (! $complete) (<= $request_expr @{[sized_decimal_literal($request_width, 0)]}))\E/,
        "$owner rejects every request at full occupancy without completion",
    );
    like(
        $boundary->{request_set_fit_expression},
        qr/\Q(& (== $pending_storage $max_pending) $complete (<= $request_expr @{[sized_decimal_literal($request_width, 1)]}))\E/,
        "$owner admits at most one request at full occupancy with one completion",
    );
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
    is_deeply($read->{generated_rules}, $expected_rules, "$owner reports generated queue-head demux rules");
    is_deeply(
        $read->{generated_assertions},
        $expected_assertions,
        "$owner reports generated queue-head response-demux assertions",
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
        "$owner reports duplicate concrete-ID queue group",
    );
    ok($read->{generated_queue_behavior}, "$owner reports generated queue behavior");
    is($read->{generated_queue_behavior_boundary}, 'generated_read_single_beat_queue_head_demux', "$owner reports generated queue boundary");
    ok(!exists($read->{selected_completion_signals}), "$owner no longer reports selected completion signal names");
    is_deeply($read->{generated_completion_signals}, $expected_completion_signals, "$owner reports generated completion signal names");
    is_deeply($read->{generated_rules}, $expected_rules, "$owner reports generated queue-head demux rules");
    is_deeply(
        $read->{generated_assertions},
        $expected_assertions,
        "$owner reports generated queue-head response-demux assertions",
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
    is_deeply($write->{generated_rules}, $expected_rules, "$owner reports generated queue-head demux rules");
    is_deeply(
        $write->{generated_assertions},
        $expected_assertions,
        "$owner reports generated queue-head response-demux assertions",
    );
    is_deeply(
        $demux->{residue},
        [qw(read_response_demux read_data_interleaving bursts)],
        "$owner removes generated queue-head demux behavior from residue",
    );
}

sub assert_same_id_generated_queue_counts {
    my ($policy, $owner, %expected) = @_;

    my ($slot_storage_count, $update_rule_count, $queue_assertion_count) = (0, 0, 0);
    for my $queue (@{$policy->{generated_queues} || []}) {
        $slot_storage_count += scalar(@{$queue->{slot_storage} || []});
        $update_rule_count += scalar(@{$queue->{generated_update_rules} || []});
        $queue_assertion_count += scalar(@{$queue->{generated_assertions} || []});
    }

    is($slot_storage_count, $expected{slot_storage}, "$owner reports expected queue slot storage count");
    is($update_rule_count, $expected{update_rules}, "$owner reports expected queue update rule count");
    is($queue_assertion_count, $expected{queue_assertions}, "$owner reports expected queue assertion count");
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
    my @supported_fragments = (
        [
            'generated burst-last RLAST response-demux completion',
            "$owner reports generated burst-last completion behavior as supported",
        ],
        [
            'generated scalar single-beat dynamic read-data RDATA/RRESP capture',
            "$owner reports dynamic single-beat read-data capture as supported",
        ],
        [
            'generated scalar last-beat dynamic read-data RDATA/RRESP capture',
            "$owner reports dynamic last-beat read-data capture as supported",
        ],
        [
            'generated bounded multiple all-dynamic read single-beat RID response demux including same-cycle release-and-recapture',
            "$owner reports bounded multiple dynamic read single-beat recapture as supported",
        ],
        [
            'multiple independent or mixed-depth read single-beat, read burst-last, and write response-demux queue groups',
            "$owner reports bounded multiple and mixed-depth queue-head response-demux groups as supported",
        ],
        [
            'selected single-group and multiple/mixed read single-beat depth-3 scalar read-data queue-head shapes',
            "$owner reports selected read single-beat depth-3 queue-head read-data shapes as supported",
        ],
        [
            join(
                '',
                'selected single-group and multiple/mixed read burst-last depth-3 scalar last-beat read-data, ',
                'report-only raw-ARLEN burst-length, runtime beat-count/RLAST validation, ',
                'and runtime-validation multi-beat output-bank queue-head shapes',
            ),
            "$owner reports selected read burst-last depth-3 queue-head response-demux and read-data as supported",
        ],
        [
            join(
                '',
                'generated single-beat read-data RDATA/RRESP capture from generated read single-beat concrete ',
                'same-ID queue-head response-demux including multiple independent depth-2 queue-head groups, ',
                'the selected single depth-3 queue-head group, and selected multiple/mixed depth-3 queue-head groups',
            ),
            "$owner reports selected single and multiple/mixed depth-3 queue-head read-data capture as supported",
        ],
        [
            join(
                '',
                'generated last-beat read-data RDATA/RRESP capture from generated read burst-last concrete ',
                'same-ID queue-head response-demux including multiple independent depth-2 queue-head groups ',
                'with no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion ',
                'beat-count/RLAST validation metadata, plus the selected single depth-3 queue-head group with ',
                'no burst_length metadata, report-only raw-ARLEN burst-length metadata, or runtime-assertion ',
                'beat-count/RLAST validation metadata, plus selected multiple/mixed depth-3 queue-head groups ',
                'with no burst_length metadata, report-only raw-ARLEN burst-length metadata, runtime-assertion ',
                'beat-count/RLAST validation metadata, or runtime-assertion multi-beat output-bank metadata',
            ),
            "$owner reports selected depth-3 burst-last queue-head read-data capture as supported",
        ],
        [
            'generated single-active and bounded multiple all-dynamic read-data runtime-validation multi-beat output-bank behavior',
            "$owner reports single-active and bounded multiple dynamic multi-beat output-bank behavior as supported",
        ],
        [
            join(
                '',
                'generated multi-beat read-data output-bank behavior for the covered auto-ID multi-beat-by-RID subset, ',
                'selected dynamic single-active and bounded multiple all-dynamic read demux subset, and bounded read burst-last concrete same-ID ',
                'queue-head subset including multiple independent depth-2 queue-head groups plus the selected ',
                'single depth-3 runtime-validation queue-head group, selected multiple/mixed depth-3 runtime-validation ',
                'queue-head groups, and the selected same-family mixed auto-ID plus depth-2 concrete queue-head ',
                'runtime-validation group',
            ),
            "$owner reports generated multi-beat output-bank behavior as supported",
        ],
        [
            'bounded burst payload/output behavior through that per-beat output bank, and generated scalar RRESP aggregation behavior are supported',
            "$owner reports bounded burst output and scalar aggregation behavior as supported",
        ],
    );
    for my $fragment (@supported_fragments) {
        ok(index($id_residue->{detail}, $fragment->[0]) >= 0, $fragment->[1]);
    }
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
    ok($read_data->{generated_behavior}, "$owner keeps last-beat read-data capture generated");
    my $read = $read_data->{read};
    is($read->{capture_scope}, 'last_beat', "$owner reports last-beat capture scope");
    is($read->{completion_source}, 'response_demux', "$owner reports response-demux completion source");
    is($read->{completion_validity}, $expected_completion_validity, "$owner reports generated last-beat demux pulse validity");
    is($read->{data_signal}, 'axi0_rdata', "$owner reports RDATA signal");
    is($read->{status_signal}, 'axi0_rresp', "$owner reports RRESP signal");
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
        "$owner reports explicit burst-length read-data residue",
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
    my @beat_count_init_rules = map { "axi0_${_}_beat_count_init" } @transactions;
    my @beat_count_increment_rules = map { "axi0_${_}_read_beat_count" } @transactions;
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
    is_deeply([map { $_->{completion_signal} } @{$read->{transactions}}], [map { "axi0_${_}_complete" } @transactions], "$owner binds bank validity to generated last-beat completion pulses");
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
    is_deeply([map { $_->{burst_length_storage} } @{$read->{transactions}}], \@burst_length_storage, "$owner reports per-transaction raw ARLEN storage");
    is_deeply([map { $_->{expected_beat_count_storage} } @{$read->{transactions}}], \@expected_beat_count_storage, "$owner reports expected-beat storage");
    is_deeply([map { $_->{beat_count_storage} } @{$read->{transactions}}], \@beat_count_storage, "$owner reports beat-count storage");
    is_deeply([map { $_->{beat_count_init_rule} } @{$read->{transactions}}], \@beat_count_init_rules, "$owner reports beat-count init rules");
    is_deeply([map { $_->{beat_count_increment_rule} } @{$read->{transactions}}], \@beat_count_increment_rules, "$owner reports beat-count increment rules");
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
    is_deeply($read->{generated_burst_length_inputs}, [qw(axi0_arlen)], "$owner reports generated burst-length input");
    is_deeply($read->{generated_burst_length_storage}, \@burst_length_storage, "$owner reports generated burst-length storage");
    is_deeply($read->{generated_burst_length_rules}, \@burst_length_rules, "$owner reports generated burst-length capture rules");
    is_deeply($read->{generated_expected_beat_count_storage}, \@expected_beat_count_storage, "$owner reports generated expected-beat storage");
    is_deeply($read->{generated_beat_count_storage}, \@beat_count_storage, "$owner reports generated beat-count storage");
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
    is_deeply(
        $read_data->{residue},
        [],
        "$owner removes generated scalar RRESP aggregation behavior from read-data residue",
    );
}

sub assert_same_id_ordering_report {
    my ($ordering, $owner, $response_demux_covered, $family_name, $multi_beat_by_rid_covered, $bounded_burst_output_covered) = @_;
    $family_name //= 'write';
    is($ordering->{mode}, 'auto_id_same_id_avoidance', "$owner marks same-ID avoidance mode");
    ok($ordering->{generated_behavior}, "$owner marks same-ID ordering generated behavior true");
    is($ordering->{strategy}, 'avoid_same_id_concurrency', "$owner reports the avoidance strategy");
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
    is($family->{strategy}, 'avoid_same_id_concurrency', "$owner reports the family strategy");
    is($family->{enforcement}, 'allocator_free_id_guard', "$owner reports allocator free-ID enforcement");
    is($family->{assertion_enforcement}, 'runtime_assertion', "$owner reports runtime assertion enforcement");
    if ($response_demux_covered) {
        ok($family->{response_demux_covered}, "$owner reports response-demux coverage");
    } else {
        ok(!$family->{response_demux_covered}, "$owner reports response-demux coverage");
    }
    is_deeply($family->{auto_transactions}, $expect->{auto_transactions}, "$owner reports same-ID covered transactions");
    is_deeply($family->{selected_id_signals}, $expect->{selected_id_signals}, "$owner reports selected-ID signals");
    is_deeply($family->{busy_signals}, $expect->{busy_signals}, "$owner reports busy signals");
    is_deeply($family->{generated_assertions}, $expect->{generated_assertions}, "$owner reports same-ID avoidance assertion");
}

sub assert_actor_storage {
    my ($report, $name, $width) = @_;
    my ($entry) = grep { $_->{name} eq $name } @{$report->{inferred_storage} || []};

    ok($entry, "schedule report includes actor storage '$name'");
    is($entry->{role}, 'actor_storage', "actor storage '$name' reports actor_storage role") if $entry;
    is($entry->{width}, $width, "actor storage '$name' reports width") if $entry;
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
    ok($fsm_module, 'capacity/status scheduled .fsm parses through the normal .fsm frontend');

    return FSM::HDL::FlattenedDT->new(debug => 0)->generate_systemverilog($fsm_module);
}

sub sv_assertion_block_for_result {
    my ($result) = @_;
    my ($fsm_name) = sort keys %{$result->{generated_ial0}{files}};
    (my $module_name = $fsm_name) =~ s/\.fsm\z//;

    my $tempdir = tempdir(CLEANUP => 1);
    my $fsm_path = File::Spec->catfile($tempdir, $fsm_name);
    write_file($fsm_path, $result->{generated_ial0}{files}{$fsm_name});

    my $module = FSM::Adapter::FSMGenFull->new(debug => 0)->parse_fsm(Lispish::multi($fsm_path));
    my $intent = FSM::IR::IntentHIRBuilder->build_from_fsm_module(fsm_module => $module);
    my $info = FSM::Pipeline::GeneratedModuleInfoBuilder->build_from_fsm_module(
        fsm_module => $module,
        intent_hir => $intent,
    );

    return join("\n", FSM::Backend::GeneratedModuleEmitter->immediate_assertion_runtime_lines(
        module_info     => $info,
        target_language => 'systemverilog',
    ));
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>', $path or die "Cannot open $path for write: $!";
    print {$fh} $content or die "Cannot write $path: $!";
    close $fh or die "Cannot close $path: $!";
}

sub sorted {
    my ($values) = @_;
    return [sort @{$values || []}];
}
