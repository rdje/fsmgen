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
ok($built->{ok}, 'checked VIAL/HIAL fixture reaches complete native UVM structure inputs');
diag(JSON::PP->new->canonical(1)->encode($built->{diagnostics})) unless $built->{ok};
my $emission = emit_backend();
ok($emission->{ok}, 'complete native UVM structure emission succeeds');
diag(JSON::PP->new->canonical(1)->encode($emission->{diagnostics})) unless $emission->{ok};

subtest 'closed graph and capability boundary identify the selected slice exactly' => sub {
    is(scalar(@{$emission->{artifacts}}), 14, 'closed graph has fourteen artifacts');
    is(scalar(grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}}), 10,
        'closed graph has ten generated SystemVerilog sources');
    is($emission->{backend_manifest}{emitter_revision}, 4, 'emitter revision is four');
    is($emission->{backend_manifest}{limits}{generated_source_artifacts}, 10,
        'manifest records the ten-source limit');
    is($emission->{backend_manifest}{limits}{total_artifacts}, 14,
        'manifest records the fourteen-artifact limit');

    my %required = map { $_ => 1 } @{$emission->{negotiation}{required}};
    ok($required{complete_component_topology_v1}, 'topology capability is required');
    ok($required{root_owned_lifecycle_v1}, 'root lifecycle capability is required');
    ok($required{ordered_notification_interception_v1},
        'ordered notification capability is required');
    ok($required{typed_stimulus_sequences_v1}, 'typed stimulus capability is required');
    ok($required{analysis_tlm_wiring_v1}, 'analysis TLM capability is required');
    ok($required{scoped_factory_configuration_v1},
        'factory/configuration capability is required');
    ok($required{ral_preview_v1}, 'RAL-preview capability is required');
    ok($required{constrained_decision_replay_v1},
        'constrained-decision replay capability is required');
    is($emission->{negotiation}{negotiation_scope},
        'native_uvm_checking_results_v1', 'negotiation scope is exact');
    is_deeply(
        $emission->{backend_manifest}{capability_evidence}{public_authoring_boundary},
        {
            execution_events => 'public_vial_v1',
            portable_scenarios_transactions_decisions => 'public_vial_v1',
            coverage_models_scoreboards_faults_expectations => 'public_vial_v1',
            bound_sva_translation => 'generated_review_structure',
            structured_result_collection => 'generated_review_structure_not_result_manifest',
            native_interceptor_tables => 'private_typed_preview',
            native_role_substitution => 'private_typed_preview',
            native_ral => 'private_typed_preview',
            native_constraint_solving => 'private_typed_preview_not_executed',
        },
        'public events and private interceptor preview are distinguished',
    );
    is($emission->{backend_manifest}{capability_evidence}{fixture_compile}, 'not_run',
        'complete structures do not imply fixture compilation');
    is($emission->{backend_manifest}{capability_evidence}{runtime}, 'not_run',
        'complete structures do not imply runtime');
    is($emission->{backend_manifest}{result}{status}, 'not_produced',
        'complete structures do not invent a result');
};

subtest 'topology owns context, logical time, lifecycle, and one root objection' => sub {
    my $types = artifact('uvm_types_package')->{content};
    like($types, qr/typedef enum int unsigned \{.*VIAL_LIFECYCLE_FINALIZED = 6/s,
        'lifecycle state family is closed and typed');
    like($types, qr/function void transition_lifecycle\(/,
        'execution context owns checked lifecycle transitions');

    my $components = artifact('uvm_component_foundations')->{content};
    like($components, qr/class fsmgen_vial_agent_base extends uvm_agent;/,
        'agent base owns the shared execution context');
    like($components, qr/uvm_config_db#\(fsmgen_vial_execution_context\)::get/,
        'component foundations retrieve the exact shared context type');

    my $fixture = artifact('uvm_fixture_package')->{content};
    for my $shape (
        [monitor => qr/class base_output_arbitration_monitor extends fsmgen_vial_component_base;/],
        [agent => qr/class base_output_arbitration_agent extends fsmgen_vial_agent_base;/],
        [controller => qr/class base_output_arbitration_controller extends fsmgen_vial_component_base;/],
        [result_collector => qr/class base_output_arbitration_result_collector extends fsmgen_vial_component_base;/],
        [environment => qr/class base_output_arbitration_env extends fsmgen_vial_env_base;/],
        [test => qr/class base_output_arbitration_test extends fsmgen_vial_test_base;/],
    ) {
        like($fixture, $shape->[1], "$shape->[0] structure is emitted");
    }
    like($fixture, qr/class base_output_arbitration_sequencer extends uvm_sequencer#/,
        'selected stimulus creates a typed sequencer');
    like($fixture, qr/class base_output_arbitration_driver_base extends uvm_driver#/,
        'selected stimulus creates a typed driver base');
    like($fixture, qr/driver\.seq_item_port\.connect\(sequencer\.seq_item_export\);/,
        'active agent connects its driver and sequencer explicitly');
    like($fixture, qr/\@\(cfg\.vif\.monitor_cb\)/,
        'monitor samples only through the selected clocking block');
    like($fixture, qr/context\.set_logical_time\(sampled_cycle, VIAL_SAMPLE_PHASE, 0\)/,
        'monitor records deterministic sample logical time');
    like($fixture, qr/context\.set_logical_time\(0, VIAL_DRIVE_PHASE, 0\)/,
        'controller records deterministic drive logical time');
    for my $transition (
        [CONSTRUCTED => 'CONFIGURED'], [CONFIGURED => 'READY'], [READY => 'RUNNING'],
        [RUNNING => 'DRAINING'], [DRAINING => 'COMPLETED'], [COMPLETED => 'FINALIZED'],
    ) {
        like(
            $fixture,
            qr/transition_lifecycle\(VIAL_LIFECYCLE_$transition->[0], VIAL_LIFECYCLE_$transition->[1]\)/,
            "lifecycle transition $transition->[0] to $transition->[1] is explicit",
        );
    }
    is(scalar(() = $fixture =~ /\bphase\.raise_objection\s*\(/g), 1,
        'root test raises exactly one objection');
    is(scalar(() = $fixture =~ /\bphase\.drop_objection\s*\(/g), 1,
        'root test drops exactly one objection');
    my $outside_fixture = join '', map { $_->{content} }
        grep { $_->{language} eq 'systemverilog' && $_->{role} ne 'uvm_fixture_package' }
        @{$emission->{artifacts}};
    unlike($outside_fixture, qr/\bphase\.(?:raise|drop)_objection\s*\(/,
        'no child or support source owns an objection');
    unlike($fixture, qr/\b(?:phase\.jump|set_automatic_phase_objection)\s*\(/,
        'lifecycle uses neither phase jumps nor automatic objections');
};

subtest 'notification/interception record is ordered, cancellable, immutable, and bounded' => sub {
    my $notification = artifact('uvm_notification_interception')->{content};
    like($notification, qr/class base_output_arbitration_notification_payload extends uvm_object;/,
        'typed notification payload is emitted');
    like($notification, qr/class base_output_arbitration_notification_dispatcher extends uvm_event_callback#\(base_output_arbitration_notification_payload\);/,
        'dispatcher uses the selected typed UVM callback API');
    like($notification, qr/uvm_event#\(base_output_arbitration_notification_payload\) event_h;/,
        'channel uses the selected typed UVM event API');
    like($notification, qr/event_h\.add_callback\(dispatcher_h\);/,
        'dispatcher is registered through the UVM event API');
    like($notification, qr/virtual function bit pre_trigger\(/,
        'interception occurs before event commit');
    like($notification, qr/virtual function void post_trigger\(/,
        'successful event commit is recorded after trigger');

    like($notification, qr/effective_payload = data\.clone_payload\("effective"\);/,
        'interceptors mutate only an effective payload clone');
    like($notification, qr/pending\.push_back\(data\.clone_payload\("queued"\)\);/,
        'queued reentrancy also takes a defensive payload clone');
    unlike($notification, qr/\bdata\.[a-z_][a-z0-9_]*\s*=(?!=)/i,
        'original payload fields are never assigned by dispatch');

    like($notification, qr/non-idempotent duplicate interceptor identity/,
        'duplicate semantic identity must be idempotent');
    like($notification, qr/duplicate interceptor rank/,
        'duplicate registration rank fails closed');
    like($notification, qr/ordered_interceptors\.insert\(insert_index, candidate\);/,
        'registration is inserted in stable compiled order');
    like($notification, qr/if \(cancelled\) begin\s+skipped_count\+\+;\s+continue;/s,
        'cancellation deterministically skips later interceptors');
    like($notification, qr/return 1'b1;/,
        'cancelled pre-trigger prevents event commit');

    like($notification, qr/if \(reentrancy == VIAL_REENTRANCY_REJECT\)/,
        'reject reentrancy is explicit');
    like($notification, qr/pending\.size\(\) >= queue_bound/,
        'queued reentrancy is bounded');
    like($notification, qr/occurrence_count >= occurrence_bound/,
        'notification occurrences are bounded');
    like($notification, qr/current = pending\.size\(\) \? pending\.pop_front\(\) : null;/,
        'queued occurrences drain iteratively without target-stack recursion');
    is(scalar(() = $notification =~ /\.configure\([^\n]+, 16, 4096\);/g), 6,
        'all six selected channels have exact queue and occurrence bounds');
    is(scalar(() = $notification =~ /VIAL_REENTRANCY_QUEUE, 16, 4096\);/g), 3,
        'three selected channels exercise queue policy');
    is(scalar(() = $notification =~ /VIAL_REENTRANCY_REJECT, 16, 4096\);/g), 3,
        'three selected channels exercise reject policy');
    is(scalar(() = $notification =~ /, 10, VIAL_FILTER_ALWAYS, VIAL_EFFECT_OBSERVE\)\);/g), 6,
        'every channel has the stable rank-ten observer');
    is(scalar(() = $notification =~ /, 20, VIAL_FILTER_RESPONSE_ERROR, VIAL_EFFECT_CANCEL\)\);/g), 1,
        'completed channel has the rank-twenty error cancellation');
    is(scalar(() = $notification =~ /, 30, VIAL_FILTER_ALWAYS, VIAL_EFFECT_APPEND_DIAGNOSTIC\)\);/g), 1,
        'completed channel has the rank-thirty diagnostic');

    my @event = qw(requested accepted captured held completed error);
    for my $name (@event) {
        like($notification,
            qr/base_output_arbitration_notification_channel ${name}_notification;/,
            "selected '$name' event has one typed channel");
    }
};

subtest 'complete source maps cover every new structure and selected channel' => sub {
    my %role;
    push @{$role{$_->{role}}}, $_ for @{$emission->{source_map}{entries}};
    for my $expected (qw(
        uvm_agent_foundation typed_notification_payload typed_interceptor_record
        ordered_notification_dispatcher bounded_notification_channel
        generated_notification_registry timed_interface_monitor
        active_timed_interface_agent root_owned_lifecycle_controller
        closed_result_collector_structure fixture_environment_foundation
        fixture_test_foundation
    )) {
        ok($role{$expected} && @{$role{$expected}}, "source map covers '$expected'");
    }
    is(scalar(@{$role{notification_channel_instance} || []}), 6,
        'source map contains one entry for every selected notification channel');
    is_deeply(
        [sort map { $_->{generated_symbol} } @{$role{notification_channel_instance}}],
        [sort map { "${_}_notification" } qw(requested accepted captured held completed error)],
        'notification channel source-map symbols are exact',
    );
};

subtest 'static negative oracles fail at exact topology and notification boundaries' => sub {
    my @source = map { clone($_) }
        grep { $_->{language} eq 'systemverilog' } @{$emission->{artifacts}};

    my @missing = grep { $_->{role} ne 'uvm_notification_interception' } @source;
    static_failure(\@missing, 'VIAL_UVM_STATIC_REQUIRED_ROLE_ERROR',
        'missing notification source role');

    my @pre_trigger = map { clone($_) } @source;
    artifact_in(\@pre_trigger, 'uvm_notification_interception')->{content}
        =~ s/\bpre_trigger\b/pre_intercept/ or die "pre-trigger mutation did not apply\n";
    static_failure(\@pre_trigger, 'VIAL_UVM_STATIC_NOTIFICATION_SHAPE_ERROR',
        'missing pre-trigger interception');

    my @queue = map { clone($_) } @source;
    artifact_in(\@queue, 'uvm_notification_interception')->{content}
        =~ s/pending\.size\(\) >= queue_bound/pending.size() >= 0/
        or die "queue-bound mutation did not apply\n";
    static_failure(\@queue, 'VIAL_UVM_STATIC_NOTIFICATION_SHAPE_ERROR',
        'missing queue bound');

    my @driver_connection = map { clone($_) } @source;
    artifact_in(\@driver_connection, 'uvm_fixture_package')->{content}
        =~ s/driver\.seq_item_port\.connect\(sequencer\.seq_item_export\);/\/\/ removed driver connection/
        or die "driver-connection mutation did not apply\n";
    static_failure(\@driver_connection, 'VIAL_UVM_STATIC_SERVICE_WIRING_ERROR',
        'missing active-agent connection');

    my @objection = map { clone($_) } @source;
    artifact_in(\@objection, 'uvm_fixture_package')->{content}
        =~ s/(phase\.raise_objection\([^\n]+\);)/$1\n      phase.raise_objection(this, "child");/
        or die "objection mutation did not apply\n";
    static_failure(\@objection, 'VIAL_UVM_STATIC_OBJECTION_POLICY_ERROR',
        'duplicate objection ownership');

    my @jump = map { clone($_) } @source;
    artifact_in(\@jump, 'uvm_fixture_package')->{content}
        =~ s/(phase\.raise_objection\([^\n]+\);)/$1\n      phase.jump(phase);/
        or die "phase-jump mutation did not apply\n";
    static_failure(\@jump, 'VIAL_UVM_STATIC_OBJECTION_POLICY_ERROR',
        'phase jump');
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
        artifact_root => '.artifacts/test/vial-native-uvm-topology-lifecycle-notification',
        backend_profile => $profile,
    });
}

sub artifact {
    my ($role) = @_;
    my @artifact = grep { $_->{role} eq $role } @{$emission->{artifacts}};
    die "artifact role '$role' is not unique\n" unless @artifact == 1;
    return $artifact[0];
}

sub artifact_in {
    my ($artifacts, $role) = @_;
    my @artifact = grep { $_->{role} eq $role } @$artifacts;
    die "test fixture role '$role' is not unique\n" unless @artifact == 1;
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
