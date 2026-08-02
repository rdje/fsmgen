#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::VIAL::Backend::SVUVMAccellera2020_3_1;
use FSM::VIAL::Backend::SVUVMStaticValidator;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $profile = 'sv_uvm_emit.accellera_2020_3_1';
my $vial_id = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_id = 'ppif/ahb_lite_subordinate.ppif';
my $built = build_plan();
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches native UVM checking/result inputs');
diag(JSON::PP->new->canonical(1)->encode($built->{diagnostics})) unless $built->{ok};
my $emission = emit_backend();
ok($emission->{ok}, 'native UVM checking/result emission succeeds');
diag(JSON::PP->new->canonical(1)->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'public coverage and deterministic models preserve selected ExecutionIR intent' => sub {
    my $checking = artifact('uvm_checking_results')->{content};
    my $fixture = artifact('uvm_fixture_package')->{content};

    like($checking, qr/package base_output_arbitration_checking_pkg;/,
        'one dedicated checking/result package is emitted');
    like($checking,
        qr/covergroup stall_seen_cg with function sample\(bit stalled\);/,
        'public stall coverpoint emits a sampled covergroup');
    like($checking, qr/bins not_stalled = \{1'b0\};/,
        'false public bin is emitted exactly');
    like($checking, qr/bins stalled = \{1'b1\};/,
        'true public bin is emitted exactly');
    like($checking, qr/stall_seen_cg\.sample\(ready_out === 1'b0\);/,
        'coverpoint expression retains same-ready-low meaning');
    like($fixture,
        qr/coverage_collector\.sample_ready\(cfg\.vif\.monitor_cb\.HREADYOUT, vial_context\.logical_time\);/,
        'monitor samples coverage at the selected observation point');

    like($checking,
        qr/class base_output_arbitration_event_counter_model extends uvm_component;/,
        'one reusable deterministic event-counter component is emitted');
    like($checking, qr/bit \[31:0\] count;/,
        'model state retains its selected unsigned 32-bit type');
    like($checking, qr/if \(count == 32'hffffffff\).*event-counter model overflow/s,
        'model addition fails visibly at its exact overflow boundary');
    for my $instance (qw(accepts completions)) {
        like($fixture,
            qr/configure\("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::model_instance::$instance"/,
            "model instance '$instance' retains its public semantic identity");
    }
    like($fixture,
        qr/if \(\(cfg\.vif\.monitor_cb\.HSEL && cfg\.vif\.monitor_cb\.HREADY && \(cfg\.vif\.monitor_cb\.HTRANS === 2'h2\)\)\) begin\s+item = sample_payload\("event\/ahb_write\/accepted".*accepts_model\.observe_event/s,
        'partial-nibble-known accepted predicate now executes and feeds its model');
    like($fixture,
        qr/notifications\.completed_notification\.trigger_notification\(item\);\s+completions_model\.observe_event/s,
        'completed notification feeds the completion model');
};

subtest 'bounded scoreboard consumes public expectation and completion data' => sub {
    my $checking = artifact('uvm_checking_results')->{content};
    my $fixture = artifact('uvm_fixture_package')->{content};

    like($checking,
        qr/class base_output_arbitration_write_scoreboard extends uvm_component;/,
        'typed in-order scoreboard component is emitted');
    like($checking, qr/localparam int unsigned CAPACITY = 4;/,
        'scoreboard retains its exact public capacity');
    like($checking,
        qr/uvm_analysis_imp#\(base_output_arbitration_ahb_write_item, base_output_arbitration_write_scoreboard\) actual_export;/,
        'scoreboard has one typed actual analysis implementation');
    like($checking, qr/expected_queue\.size\(\) >= CAPACITY.*actual_queue\.size\(\) >= CAPACITY/s,
        'both scoreboard queues fail closed at the selected capacity');
    like($checking, qr/if \(expected\.compare\(actual\)\).*match_count\+\+/s,
        'in-order heads use the item same-value comparison path');
    like($checking, qr/function bit check_empty\(\);/,
        'public scoreboard_check emits an explicit no-pending-data check');

    for my $assignment (
        qr/expected\.address = 32'h00000000;/,
        qr/expected\.transfer = 2'h2;/,
        qr/expected\.write = 1'h1;/,
        qr/expected\.size = 3'h2;/,
        qr/expected\.data = 32'hcafebabe;/,
        qr/expected\.wait_cycles = 4'h2;/,
    ) {
        like($checking, $assignment,
            'immutable public scoreboard expectation retains one selected field');
    }
    like($fixture,
        qr/writes_scoreboard\.enqueue_expected\(expected\);.*success_sequence\.start\(sequencer\);.*writes_scoreboard\.check_empty\(\)/s,
        'controller orders public enqueue/start/check operations');
    like($fixture,
        qr/agent\.driver\.driven_ap\.connect\(writes_scoreboard\.actual_export\);/,
        'completion-returning driver stream feeds actual scoreboard data');
};

subtest 'declared fault, property, diagnostic, and result structures remain honest' => sub {
    my $services = artifact('uvm_stimulus_services')->{content};
    my $checking = artifact('uvm_checking_results')->{content};
    my $fixture = artifact('uvm_fixture_package')->{content};

    like($services, qr/request\.size = 3'h2;/,
        'unsupported scenario retains its immutable pre-fault field');
    like($checking,
        qr/class base_output_arbitration_fault_controller extends uvm_component;/,
        'declared substitution fault emits a typed controller');
    like($checking, qr/remaining_drive_intervals = 1;/,
        'fault retains its exact one-drive-interval duration');
    like($checking, qr/transaction\.size = 3'h7;/,
        'fault applies the exact public substitute value');
    like($fixture,
        qr/faults\.arm\(\);\s+unsupported_size_sequence = .*unsupported_size_sequence\.start\(sequencer\);/s,
        'public inject operation arms before the selected scenario start');
    like($fixture,
        qr/faults\.apply_next_drive\(request\);\s+drive_item\(request\);/,
        'driver applies the substitution before committing the transaction');

    like($checking,
        qr/class base_output_arbitration_property_checker extends uvm_component;/,
        'property expectation component is emitted');
    like($fixture,
        qr/properties\.record\("ahb_subordinate_base_output_arbitration::fixture::base_output_arbitration::expectation::two_error_cycles"/,
        'public error-count expectation is emitted with exact identity');
    like($checking,
        qr/virtual function void do_copy\(uvm_object rhs\);.*diagnostic_id = rhs_item\.diagnostic_id/s,
        'structured diagnostic cloning is explicit and defensive');
    like($fixture,
        qr/uvm_analysis_imp_vial_diagnostic#\(base_output_arbitration_diagnostic, base_output_arbitration_result_collector\) diagnostic_export;/,
        'result collector owns one typed diagnostic sink');
    like($fixture,
        qr/snapshot\.expectation_count = properties\.expectation_count;.*snapshot\.fault_record_count = faults\.record_count;/s,
        'result snapshot collects every selected checking-family count');

    is($emission->{backend_manifest}{capability_evidence}{runtime}, 'not_run',
        'runtime remains explicitly not run');
    is($emission->{backend_manifest}{capability_evidence}{result}, 'not_produced',
        'emitted result collection does not invent a runtime result manifest');
    is_deeply($emission->{backend_manifest}{capability_evidence}
        {deferred_to_later_emission_slices}, [],
        'all semantic families selected for this emission sequence are now present');
    ok((grep { /verification-probe-backed expectations remain source-mapped/ }
        @{$emission->{backend_manifest}{limitations}}),
        'probe-backed runtime expectation boundary remains explicit');
};

subtest 'bound SVA checker retains selected temporal and HIAL binding facts' => sub {
    my $checker = artifact('bound_sva_checker')->{content};
    like($checker, qr/module base_output_arbitration_sva_checker \(/,
        'separate SVA checker module is emitted');
    like($checker,
        qr/\(select && ready_in && transfer == 2'h2\) \|-> ##\[1:256\] ready_out;/,
        'selected completion window is explicit');
    like($checker,
        qr/selected_completion_bound: assert property \(started_transfer_completes_within_256\)/,
        'temporal property is asserted');
    like($checker,
        qr/bind ahb_lite_subordinate base_output_arbitration_sva_checker base_output_arbitration_sva_checker_i/,
        'checker binds to the exact generated HIAL module');
    for my $binding (
        qr/\.clock\(clk\)/,
        qr/\.reset\(rst_n\)/,
        qr/\.select\(HSEL\)/,
        qr/\.ready_in\(HREADY\)/,
        qr/\.transfer\(HTRANS\)/,
        qr/\.ready_out\(HREADYOUT\)/,
    ) {
        like($checker, $binding, 'checker retains one exact bridge binding');
    }
};

subtest 'graph, source maps, static checks, and capabilities survive revision five closure' => sub {
    is($emission->{backend_manifest}{emitter_revision}, 5,
        'checking/results graph is retained by emitter revision five');
    is(scalar(@{$emission->{artifacts}}), 16,
        'graph contains sixteen exact artifacts');
    is(scalar(grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}}), 10,
        'graph contains ten generated SystemVerilog sources');
    is(scalar(@{$emission->{source_map}{entries}}), 75,
        'all selected generated structures have seventy-five map entries');
    is(scalar(@{$emission->{static_validation}{checks}}), 14,
        'fourteen static structure checks pass');

    my %role;
    push @{$role{$_->{role}}}, $_ for @{$emission->{source_map}{entries}};
    for my $expected (qw(
        structured_diagnostic_record normalized_result_snapshot_structure
        functional_coverage_collector deterministic_event_counter_model
        bounded_in_order_scoreboard public_scoreboard_expectation
        declared_substitution_fault_controller property_expectation_collector
        bound_sva_checker public_temporal_property
        analysis_checking_result_connections
    )) {
        ok($role{$expected} && @{$role{$expected}},
            "source map covers '$expected'");
    }

    my %required = map { $_ => 1 } @{$emission->{negotiation}{required}};
    for my $capability (qw(
        functional_coverage_v1 bound_sva_properties_v1
        deterministic_event_models_v1 bounded_in_order_scoreboard_v1
        declared_substitution_fault_v1 structured_diagnostic_result_collection_v1
    )) {
        ok($required{$capability}, "negotiation requires '$capability'");
    }
};

subtest 'static negative oracles reject checking, SVA, and fault wiring loss' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}};

    my @missing = grep { $_->{role} ne 'uvm_checking_results' } @source;
    static_failure(\@missing, 'VIAL_UVM_STATIC_REQUIRED_ROLE_ERROR',
        'missing checking/result package');

    my @capacity = map { clone($_) } @source;
    artifact_in(\@capacity, 'uvm_checking_results')->{content}
        =~ s/localparam int unsigned CAPACITY = 4;/localparam int unsigned CAPACITY = 5;/
        or die "scoreboard-capacity mutation did not apply\n";
    static_failure(\@capacity, 'VIAL_UVM_STATIC_CHECKING_SHAPE_ERROR',
        'wrong scoreboard capacity');

    my @sva = map { clone($_) } @source;
    artifact_in(\@sva, 'bound_sva_checker')->{content}
        =~ s/##\[1:256\]/##[2:256]/
        or die "SVA-window mutation did not apply\n";
    static_failure(\@sva, 'VIAL_UVM_STATIC_SVA_SHAPE_ERROR',
        'wrong temporal window');

    my @fault = map { clone($_) } @source;
    artifact_in(\@fault, 'uvm_fixture_package')->{content}
        =~ s/faults\.apply_next_drive\(request\);/faults.skip_next_drive(request);/
        or die "fault-application mutation did not apply\n";
    static_failure(\@fault, 'VIAL_UVM_STATIC_SERVICE_WIRING_ERROR',
        'missing driver fault application');
};

done_testing;

sub build_plan {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => slurp_raw(repo_path(split m{/}, $vial_id)),
        source_name => $vial_id,
        source_catalog => {},
    });
    return FSM::VIAL::PlanBuilder->build({
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_id,
            text => slurp_raw(repo_path(split m{/}, $hial_id)),
            format => 'ppif',
        },
        fixture_id => undef,
        scenario_ids => [],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
}

sub emit_backend {
    return FSM::VIAL::Backend::SVUVMAccellera2020_3_1->emit({
        execution_ir => $built->{execution_ir},
        bridge_manifest => $built->{bridge_manifest},
        backend_inputs => $built->{backend_inputs},
        artifact_root => '.artifacts/test/vial-native-uvm-checking-results',
        backend_profile => $profile,
    });
}

sub artifact {
    my ($role) = @_;
    return artifact_in($emission->{artifacts}, $role);
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @artifact = grep { $_->{role} eq $role } @$artifacts;
    die "artifact role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub static_failure {
    my ($artifacts, $code, $label) = @_;
    my $result = FSM::VIAL::Backend::SVUVMStaticValidator->validate({
        backend_profile => $profile,
        artifacts => $artifacts,
    });
    ok(!$result->{ok}, "$label fails closed");
    ok((grep { $_->{code} eq $code } @{$result->{diagnostics}}),
        "$label has exact diagnostic");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return {map { $_ => clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return [map { clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "cannot read $path: $!\n";
    local $/;
    my $text = <$fh>;
    close $fh or die "cannot close $path: $!\n";
    return $text;
}

sub repo_path {
    return File::Spec->catfile($FindBin::Bin, '..', @_);
}
