#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Adapter::ISF;
use FSM::HDL::FlattenedDT;
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;
use FSM::Pipeline::SourceFrontend;
use FSM::Scheduler::ISF;

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
