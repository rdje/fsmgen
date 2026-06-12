#!/usr/bin/env perl
use strict;
use warnings;
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
        ['concrete transaction ID without family metadata', sub { my $c = sample_contract(); $c->{transactions} = [sample_contract_with_transactions()->{transactions}[1]]; $c }, qr/concrete ID requires id_families metadata/],
        ['concrete transaction ID too wide', sub { my $c = sample_contract_with_transactions(); $c->{transactions}[1]{id}{value} = 16; $c }, qr/concrete read ID value 16 does not fit width 4/],
        ['concrete transaction ID with zero-width family', sub { my $c = sample_contract_with_transactions(); $c->{id_families}{read} = { width => 0 }; $c }, qr/concrete read ID is not allowed when read ID-family width is 0/],
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
