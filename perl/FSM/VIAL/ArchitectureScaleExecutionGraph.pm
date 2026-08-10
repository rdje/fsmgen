package FSM::VIAL::ArchitectureScaleExecutionGraph;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use File::Basename qw(basename);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::Scheduler::ISF;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $FAMILY = 'execution_graph_v1';
my $HIAL_SOURCE = 'generated/vial-scale/execution_graph/vial_architecture_scale.isf';
my $VIAL_SOURCE = 'generated/vial-scale/execution_graph/vial_architecture_scale.vial';
my $REFERENCE_HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $REFERENCE_HIAL_BYTES = 1_326;
my $REFERENCE_HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $EVALUATION_SCHEMA = 'fsmgen.vial_architecture_scale_execution_evaluation.v1';
my $EXECUTION_PROFILE = 'core_directed_single_clock_execution_v1';
my $ARCHITECTURE_SCALE_CAPABILITY =
    'hial_vial.bridge_qualification.architecture_scale_v1';
my @CONSTRUCT_KEYS = qw(level primary_axis reference_hial_text);
my @REQUIRED_CONSTRUCT_KEYS = qw(level primary_axis);
my @EVALUATE_KEYS = qw(construction);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version workload_identity family level primary_axis
    requested_counts observed_outcome metrics semantic_ir_sha256
    bridge_manifest_sha256 plan_sha256 diagnostics contract_discrepancies
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_known_required_keys(
        $raw, \@CONSTRUCT_KEYS, \@REQUIRED_CONSTRUCT_KEYS,
        'execution construction',
    );

    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    my %owned_axis = map { $_ => 1 } qw(
        bindings scenarios operations_per_scenario operations_total
        fibers_total simultaneously_live_fibers
    );
    confess "execution-graph gate slice does not own the requested shape\n"
        unless defined($axis) && $owned_axis{$axis}
            && defined($level) && $level eq 'gate_candidate_v1';
    my $axis_contract = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{$FAMILY}{axes}{$axis};
    my $requested = $axis_contract->{levels}{$level};
    my $inputs;
    if ($axis eq 'bindings') {
        confess "reference_hial_text is accepted only for checked-AHB execution gates\n"
            if defined $raw->{reference_hial_text};
        my $binding_count = $requested->{bindings};
        my $event_count = $binding_count - 6;
        confess "execution binding gate has no valid ordinal-event construction\n"
            unless $event_count > 0;
        $inputs = [
            _input($HIAL_SOURCE, 'hial_source', _render_hial($event_count)),
            _input($VIAL_SOURCE, 'vial_source', _render_vial($event_count)),
        ];
    }
    else {
        _validate_reference_hial($raw->{reference_hial_text});
        $inputs = [
            _input(
                $REFERENCE_HIAL_SOURCE, 'hial_source',
                $raw->{reference_hial_text},
            ),
            _input(
                $VIAL_SOURCE, 'vial_source',
                _render_ahb_vial($axis, $requested->{$axis}),
            ),
        ];
    }

    return FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => $inputs,
    });
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'execution build');
    my $inputs = _canonical_inputs($args[0]{construction});
    return _build_execution($inputs);
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'execution evaluation');
    my $construction = _validated_construction($args[0]{construction});
    my $spec = $construction->{specification};
    my $inputs = _canonical_inputs($construction);
    my $first = _build_execution($inputs);
    return _rejected_evaluation($construction, $first->{diagnostics})
        unless $first->{ok};

    my @oracle_errors;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $second = _build_execution($inputs);
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_DETERMINISM_ERROR',
        'independent execution binding did not reproduce byte-equal plan output',
        '/plan',
    ) unless $second->{ok}
        && $canonical->encode($second->{plan}) eq $canonical->encode($first->{plan});

    my $ir = $first->{execution_ir}->as_hashref;
    my $plan_json = $canonical->encode($first->{plan});
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    my $manifest = $inputs->{bridge_manifest}->as_hashref;
    my $observed_bindings = $ir->{resource_summary}{bindings};
    my $event_count = scalar(@{$ir->{bindings}{events}});
    push @oracle_errors, _axis_oracle_errors(
        $spec, $construction, $ir, $first->{plan}, $inputs,
    );
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_TARGET_ERROR',
        'target or methodology spelling escaped into the target-neutral plan',
        '/plan',
    ) if $plan_json =~ /(?:systemverilog|\buvm\b|\bvhdl\b|target_name|build_phase|objection)/i;

    return _evaluation({
        ok => @oracle_errors ? JSON::PP::false : JSON::PP::true,
        status => @oracle_errors ? 'oracle_failure' : 'accepted',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        metrics => {
            bindings => 0 + $observed_bindings,
            execution_events => $event_count,
            execution_types => scalar(@{$ir->{type_table}}),
            selected_scenarios => scalar(@{$ir->{scenarios}}),
            expanded_operations_per_scenario => _maximum_operation_count($ir),
            expanded_operations_total => 0 + $ir->{operation_graph}{total_operation_count},
            total_fibers => 0 + $ir->{operation_graph}{total_fiber_count},
            simultaneous_live_fibers =>
                0 + $ir->{operation_graph}{maximum_simultaneous_live_fibers},
            source_map_records => scalar(@{$ir->{source_map}}),
            serialized_plan_bytes => bytes::length($plan_json),
        },
        semantic_ir_sha256 => sha256_hex($canonical->encode($semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($manifest)),
        plan_sha256 => sha256_hex($plan_json),
        diagnostics => \@oracle_errors,
        contract_discrepancies => [],
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub _canonical_inputs($raw) {
    my $construction = _validated_construction($raw);
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');
    return _canonical_ahb_inputs($construction, $hial, $vial)
        unless $construction->{specification}{primary_axis} eq 'bindings';
    my $adapter = FSM::Adapter::ISF->new();
    my $actor = $adapter->parse_source($hial->{content}, basename($hial->{relative_path}));
    my $scheduler = FSM::Scheduler::ISF->new();
    my $schedule_report = JSON::PP->new->decode($scheduler->report($actor));
    my $lowered = $scheduler->lower($actor);
    my $artifact_name = $actor->{actor_name} . '.fsm';
    $artifact_name = $actor->{actor_name} . '_top.fsm'
        unless exists $lowered->{files}{$artifact_name};
    my $ial0_text = $lowered->{files}{$artifact_name};
    confess "ordinary IAL1 lowering did not emit '$artifact_name'\n"
        unless defined $ial0_text;
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record($hial->{content}, $hial->{relative_path}),
        actor => $actor,
        schedule_report => $schedule_report,
        generated_ial0 => _source_record($ial0_text, undef, $artifact_name),
        backend_names => _backend_names($actor),
    });
    confess "canonical architecture-scale bridge construction failed\n"
        unless $bridge->{ok};

    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    confess "binding gate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "binding gate must contain one scenario\n" unless @scenario_ids == 1;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        private_qualification => 1,
        arguments => {
            semantic_ir => $semantic_ir,
            bridge_manifest => $bridge->{manifest},
            fixture_id => $fixture->{semantic_id},
            scenario_ids => \@scenario_ids,
            execution_profile => $EXECUTION_PROFILE,
            replay_manifest => undef,
            native_extension_catalog => [],
        },
    };
}

sub _canonical_ahb_inputs($construction, $hial, $vial) {
    my $ppif = FSM::Adapter::IAL2::PPIF->new()->parse_source(
        $hial->{content}, $hial->{relative_path},
    );
    my $ial1_text = $ppif->{generated_ial1}{text};
    my $actor = FSM::Adapter::ISF->new()->parse_source(
        $ial1_text, $ppif->{generated_ial1}{name},
    );
    my $bridge = FSM::HIAL::VIALBridge::Builder->build_ial2_via_ial1({
        profile => 'core_single_unit_v1',
        authored_source => _source_record(
            $hial->{content}, $hial->{relative_path},
        ),
        generated_ial1 => {
            source => _source_record(
                $ial1_text, undef, $ppif->{generated_ial1}{name},
            ),
            actor => $actor,
            schedule_report => $ppif->{generated_ial1_schedule_report},
        },
        generated_ial0 => _source_record(
            $ppif->{generated_ial0}{files}{'ahb_lite_subordinate.fsm'},
            undef, 'ahb_lite_subordinate.fsm',
        ),
        backend_names => _backend_names($actor),
    });
    confess "canonical checked-AHB bridge construction failed\n"
        unless $bridge->{ok};

    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
    my $semantic = $semantic_ir->as_hashref;
    confess "checked-AHB execution gate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "checked-AHB execution gate must contain at least one scenario\n"
        unless @scenario_ids;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        private_qualification => 0,
        arguments => {
            semantic_ir => $semantic_ir,
            bridge_manifest => $bridge->{manifest},
            fixture_id => $fixture->{semantic_id},
            scenario_ids => \@scenario_ids,
            execution_profile => $EXECUTION_PROFILE,
            replay_manifest => undef,
            native_extension_catalog => [],
        },
    };
}

sub _build_execution($inputs) {
    return FSM::VIAL::ExecutionBuilder->build_architecture_scale_qualification(
        $inputs->{arguments},
    ) if $inputs->{private_qualification};
    return FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
}

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $spec = $raw->{specification};
    confess "construction must be successful and carry one specification hash\n"
        unless $raw->{ok} && ref($spec) eq 'HASH' && !blessed($spec);
    my $invocation = {
        primary_axis => $spec->{primary_axis},
        level => $spec->{level},
    };
    $invocation->{reference_hial_text} = _role_input($raw, 'hial_source')->{content}
        unless $spec->{primary_axis} eq 'bindings';
    my $rebuilt = __PACKAGE__->construct($invocation);
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "construction is not canonical\n"
        unless $rebuilt->{ok}
            && $canonical->encode($rebuilt) eq $canonical->encode($raw);
    return $rebuilt;
}

sub _render_hial($event_count) {
    my @events = map {
        sprintf('(event bridge_event_%08d predicate sample scale_input)', $_)
    } 0 .. $event_count - 1;
    return join('',
        '(actor vial_architecture_scale',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface (input scale_input) (output scale_output))',
        ' (storage (var probe_00000000 (width 1)))',
        ' (verification-bridge',
        ' (domain scale)',
        ' (protocol architecture_scale_probe',
        ' (profile qualification_only)',
        ' (revision 1)',
        ' (role verification)',
        ' (facts (fact scale_evidence_only true)))',
        ' (transaction bridge_anchor',
        ' (fields (field anchor scale_input drive unspecified))',
        ' (events ', join(' ', @events), '))',
        ' (probe probe_00000000 read_only)))',
        "\n",
    );
}

sub _render_vial($event_count) {
    my @events = map { sprintf('bridge_event_%08d', $_) } 0 .. $event_count - 1;
    return join('',
        '(vial (version 1) (package architecture_scale_execution',
        ' (imports)',
        ' (types (type bit_t (logic 1)))',
        ' (transactions (transaction bridge_anchor',
        ' (fields (anchor (type bit_t)))',
        ' (events ', join(' ', @events), ')))',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture binding_gate',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale")',
        ' (domains (domain scale "domain/scale"))',
        ' (endpoints',
        ' (endpoint anchor "endpoint/scale_input" (type bit_t) public_port)',
        ' (endpoint retained "probe/probe_00000000" (type bit_t) verification_probe))',
        ' (transactions (transaction bridge "transaction/bridge_anchor" bridge_anchor)))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios (scenario smoke',
        ' (timeout (cycles scale 16))',
        ' (steps (reset scale 1))))))))',
        "\n",
    );
}

sub _render_ahb_vial($axis, $requested_count) {
    my ($scenario_count, $operations_per_scenario, @scenario_actions);
    if ($axis eq 'scenarios') {
        ($scenario_count, $operations_per_scenario) = ($requested_count, 1);
    }
    elsif ($axis eq 'operations_per_scenario') {
        ($scenario_count, $operations_per_scenario) = (1, $requested_count);
    }
    elsif ($axis eq 'operations_total') {
        $scenario_count = 32;
        confess "total-operation gate is not divisible by its scenario fanout\n"
            if $requested_count % $scenario_count;
        $operations_per_scenario = int($requested_count / $scenario_count);
    }
    elsif ($axis eq 'fibers_total') {
        $scenario_count = 1;
        @scenario_actions = _total_fiber_actions($requested_count);
    }
    elsif ($axis eq 'simultaneously_live_fibers') {
        $scenario_count = 1;
        @scenario_actions = (_live_fiber_action($requested_count));
    }
    else {
        confess "checked-AHB renderer does not own axis '$axis'\n";
    }

    my @scenarios;
    for my $scenario_ordinal (0 .. $scenario_count - 1) {
        my $name = sprintf('scenario_%08d', $scenario_ordinal);
        my @steps = @scenario_actions
            ? @scenario_actions
            : ('(reset bus 1)') x $operations_per_scenario;
        my $timeout_cycles = @scenario_actions
            ? $requested_count + 1
            : $operations_per_scenario + 1;
        push @scenarios, join('',
            '(scenario ', $name,
            ' (timeout (cycles bus ', $timeout_cycles, '))',
            ' (steps ', join(' ', @steps), '))',
        );
    }
    return join('',
        '(vial (version 1) (package architecture_scale_execution',
        ' (imports)',
        ' (types',
        ' (enum htrans_t (logic 2) (idle #b00) (nonseq #b10))',
        ' (type address_t (logic 32))',
        ' (type data_t (logic 32)))',
        ' (transactions (transaction ahb_write',
        ' (fields',
        ' (address (type address_t))',
        ' (transfer (type htrans_t))',
        ' (write bool)',
        ' (size (logic 3))',
        ' (data (type data_t))',
        ' (wait_cycles (u 4)))',
        ' (events requested accepted captured held completed error)))',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture execution_gate',
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain bus "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ready_out "endpoint/HREADYOUT" (logic 1) public_port)',
        ' (endpoint response "endpoint/HRESP" (logic 1) public_port)',
        ' (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)',
        ' (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))',
        ' (transactions (transaction write "transaction/ahb_write" ahb_write)))',
        ' (instances)',
        ' (coverage)',
        ' (faults)',
        ' (randomness (seed 1701))',
        ' (scenarios ', join(' ', @scenarios), ')))))',
        "\n",
    );
}

sub _total_fiber_actions($requested_count) {
    confess "total-fiber gate requires at least three fibers\n"
        unless defined($requested_count) && $requested_count >= 3;
    my $remaining = $requested_count - 1;
    my @group_sizes;
    while ($remaining) {
        my $group_size = $remaining > 31 ? 31 : $remaining;
        if ($group_size == 1) {
            confess "total-fiber gate cannot form a final singleton parallel group\n"
                unless @group_sizes && $group_sizes[-1] > 2;
            --$group_sizes[-1];
            ++$remaining;
            ++$group_size;
        }
        push @group_sizes, $group_size;
        $remaining -= $group_size;
    }

    my @actions;
    for my $group_ordinal (0 .. $#group_sizes) {
        my @fibers = map {
            sprintf(
                '(fiber total_%08d_%08d (reset bus 1))',
                $group_ordinal, $_,
            )
        } 0 .. $group_sizes[$group_ordinal] - 1;
        push @actions, '(parallel all ' . join(' ', @fibers) . ')';
    }
    return @actions;
}

sub _live_fiber_action($requested_count) {
    confess "live-fiber gate requires at least four fibers\n"
        unless defined($requested_count) && $requested_count >= 4;
    my $descendant_count = $requested_count - 1;
    my $outer_count = int(($descendant_count + 255) / 256);
    $outer_count = 2 if $outer_count < 2;
    confess "live-fiber gate exceeds the outer parallel fanout\n"
        if $outer_count > 256;

    my $nested_remaining = $descendant_count - $outer_count;
    my @outer_fibers;
    for my $outer_ordinal (0 .. $outer_count - 1) {
        my $nested_count = $nested_remaining > 255 ? 255 : $nested_remaining;
        confess "live-fiber gate would require a singleton nested parallel\n"
            if $nested_count == 1;
        my $action = '(reset bus 1)';
        if ($nested_count) {
            my @nested_fibers = map {
                sprintf(
                    '(fiber live_%08d_%08d (reset bus 1))',
                    $outer_ordinal, $_,
                )
            } 0 .. $nested_count - 1;
            $action = '(parallel all ' . join(' ', @nested_fibers) . ')';
            $nested_remaining -= $nested_count;
        }
        push @outer_fibers, sprintf(
            '(fiber live_outer_%08d %s)', $outer_ordinal, $action,
        );
    }
    confess "live-fiber gate did not consume its exact descendant count\n"
        if $nested_remaining;
    return '(parallel all ' . join(' ', @outer_fibers) . ')';
}

sub _validate_reference_hial($text) {
    confess "checked-AHB reference text is required for this execution gate\n"
        unless defined($text) && !ref($text);
    confess "checked-AHB reference byte length changed\n"
        unless bytes::length($text) == $REFERENCE_HIAL_BYTES;
    confess "checked-AHB reference identity changed\n"
        unless sha256_hex($text) eq $REFERENCE_HIAL_SHA256;
}

sub _axis_oracle_errors($spec, $construction, $ir, $plan, $inputs) {
    my @errors;
    my $axis = $spec->{primary_axis};
    my $ledger = $plan->{capability_ledger};
    my ($scale_capability) = grep {
        ($_->{capability_id} // '') eq $ARCHITECTURE_SCALE_CAPABILITY
    } @$ledger;
    if ($axis eq 'bindings') {
        my $requested = $spec->{requested_counts}{bindings};
        my $observed = $ir->{resource_summary}{bindings};
        my $events = scalar(@{$ir->{bindings}{events}});
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_COUNT_ERROR',
            "observed binding count $observed does not equal requested count $requested",
            '/metrics/bindings',
        ) unless $observed == $requested;
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_EVENT_ERROR',
            'binding gate does not contain the exact ordinal private-event family',
            '/metrics/execution_events',
        ) unless $events == $requested - 6
            && _ordinal_events($ir->{bindings}{events});
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_CAPABILITY_ERROR',
            'private architecture-scale evidence is not isolated in the capability ledger',
            '/capability_ledger',
        ) unless $scale_capability
            && ($scale_capability->{classification} // '') eq 'qualification_only'
            && ($scale_capability->{portable_class} // '') eq 'private_nonportable'
            && join("\0", @{$scale_capability->{origins} || []}) eq 'bridge_manifest';
        return @errors;
    }

    my ($ahb_capability) = grep {
        ($_->{capability_id} // '') eq 'hial_vial.bridge_protocol.ahb_subordinate_v1'
    } @$ledger;
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_CAPABILITY_ERROR',
        'checked-AHB execution gate did not retain only the public bridge capability',
        '/capability_ledger',
    ) unless !$scale_capability
        && $ahb_capability
        && ($ahb_capability->{classification} // '') eq 'satisfied_by_execution_profile'
        && ($ahb_capability->{portable_class} // '') eq 'portable';

    my @layers = map { $_->{layer} // '' }
        @{$inputs->{bridge_manifest}->as_hashref->{review_route}{stages} || []};
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_ROUTE_ERROR',
        'execution topology gate did not traverse the frozen IAL2/IAL1/IAL0 review route',
        '/bridge_manifest/review_route',
    ) unless join("\0", @layers) eq join("\0", qw(IAL2 IAL1 IAL0));

    my $requested = $spec->{requested_counts}{$axis};
    if ($axis eq 'fibers_total' || $axis eq 'simultaneously_live_fibers') {
        my $observed = $axis eq 'fibers_total'
            ? $ir->{operation_graph}{total_fiber_count}
            : $ir->{operation_graph}{maximum_simultaneous_live_fibers};
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_COUNT_ERROR',
            "observed $axis count $observed does not equal requested count $requested",
            "/metrics/$axis",
        ) unless $observed == $requested;
        push @errors, _fiber_oracle_errors($ir, $axis, $requested);
        push @errors, _topology_oracle_errors($ir, 'fiber_tree');
        return @errors;
    }

    my $observed = $axis eq 'scenarios'
        ? scalar(@{$ir->{scenarios}})
        : $axis eq 'operations_per_scenario'
            ? _maximum_operation_count($ir)
            : $ir->{operation_graph}{total_operation_count};
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_COUNT_ERROR',
        "observed $axis count $observed does not equal requested count $requested",
        "/metrics/$axis",
    ) unless $observed == $requested;

    my ($expected_scenarios, $expected_per_scenario) = $axis eq 'scenarios'
        ? ($requested, 1)
        : $axis eq 'operations_per_scenario'
            ? (1, $requested)
            : (32, 32);
    my @per_scenario = map {
        0 + $_->{plan_summary}{operation_count}
    } @{$ir->{scenarios}};
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_ISOLATION_ERROR',
        'execution topology gate did not preserve its selected scenario/operation isolation recipe',
        '/operation_graph',
    ) unless @per_scenario == $expected_scenarios
        && !scalar(grep { $_ != $expected_per_scenario } @per_scenario)
        && $ir->{operation_graph}{total_fiber_count} == $expected_scenarios
        && $ir->{operation_graph}{maximum_simultaneous_live_fibers} == 1;

    push @errors, _topology_oracle_errors($ir, 'reset_chain');
    return @errors;
}

sub _fiber_oracle_errors($ir, $axis, $requested) {
    my @errors;
    my $graph = $ir->{operation_graph};
    my $scenario = @{$ir->{scenarios}} == 1 ? $ir->{scenarios}[0] : undef;
    my @parallel = grep { ($_->{kind} // '') eq 'parallel' } @{$graph->{operations}};
    my @reset = grep { ($_->{kind} // '') eq 'reset' } @{$graph->{operations}};
    my %fiber = $scenario
        ? map { $_->{fiber_id} => $_ } @{$scenario->{fibers}}
        : ();
    my %operation = map { $_->{operation_id} => $_ } @{$graph->{operations}};
    my %operations_by_fiber;
    push @{$operations_by_fiber{$_->{fiber_id}}}, $_ for @{$graph->{operations}};
    my @roots = grep { !defined($_->{parent_fiber_id}) } values %fiber;
    my $root = @roots == 1 ? $roots[0] : undef;
    my $closed = $scenario
        && scalar(keys %fiber) == $requested
        && $scenario->{plan_summary}{fiber_count} == $requested
        && $root
        && !scalar(grep { !exists($fiber{$_->{fiber_id}}) } @{$graph->{operations}})
        && !scalar(grep {
            defined($_->{parent_fiber_id}) && !exists($fiber{$_->{parent_fiber_id}})
        } values %fiber)
        && !scalar(grep {
            ($_->{effects}[0]{join} // '') ne 'all'
        } @parallel);
    my %child_root_count;
    for my $parallel (@parallel) {
        for my $child_root_id (@{$parallel->{effects}[0]{child_root_operation_ids} || []}) {
            ++$child_root_count{$child_root_id};
            my $child_root = $operation{$child_root_id};
            my $child_fiber = $child_root ? $fiber{$child_root->{fiber_id}} : undef;
            $closed = 0 unless $child_fiber
                && defined($child_fiber->{parent_fiber_id})
                && $child_fiber->{parent_fiber_id} eq $parallel->{fiber_id};
        }
    }
    for my $entry (grep { defined($_->{parent_fiber_id}) } values %fiber) {
        my $operations = $operations_by_fiber{$entry->{fiber_id}} || [];
        $closed = 0 unless @$operations
            && ($child_root_count{$operations->[0]{operation_id}} // 0) == 1;
    }
    $closed = 0 unless scalar(keys %child_root_count) == $requested - 1;

    if ($closed && $axis eq 'fibers_total') {
        my @group_sizes = map {
            scalar(@{$_->{effects}[0]{child_root_operation_ids} || []})
        } @parallel;
        my @root_operations = @{$operations_by_fiber{$root->{fiber_id}} || []};
        $closed = @parallel == 5
            && @reset == 127
            && @{$graph->{operations}} == 132
            && $graph->{maximum_simultaneous_live_fibers} == 32
            && join("\0", @group_sizes) eq join("\0", qw(31 31 31 31 3))
            && @root_operations == @parallel
            && !scalar(grep {
                defined($_->{parent_fiber_id})
                    && $_->{parent_fiber_id} ne $root->{fiber_id}
            } values %fiber)
            && !scalar(grep {
                $_->{fiber_id} ne $root->{fiber_id}
                    && @{$operations_by_fiber{$_->{fiber_id}} || []} != 1
            } values %fiber);
        for my $index (0 .. $#root_operations) {
            my @expected = $index == $#root_operations
                ? ()
                : ($root_operations[$index + 1]{operation_id});
            $closed = 0 unless join("\0", @{$root_operations[$index]{successor_ids}})
                eq join("\0", @expected);
        }
    }
    elsif ($closed && $axis eq 'simultaneously_live_fibers') {
        my @child_counts = sort { $a <=> $b } map {
            scalar(@{$_->{effects}[0]{child_root_operation_ids} || []})
        } @parallel;
        my @root_children = grep {
            defined($_->{parent_fiber_id})
                && $_->{parent_fiber_id} eq $root->{fiber_id}
        } values %fiber;
        my @nested_parents = grep {
            scalar(@{$operations_by_fiber{$_->{fiber_id}} || []}) == 1
                && ($operations_by_fiber{$_->{fiber_id}}[0]{kind} // '') eq 'parallel'
        } @root_children;
        my @nested_children = @nested_parents == 1 ? grep {
            defined($_->{parent_fiber_id})
                && $_->{parent_fiber_id} eq $nested_parents[0]{fiber_id}
        } values %fiber : ();
        $closed = @parallel == 2
            && @reset == 30
            && @{$graph->{operations}} == 32
            && $graph->{total_fiber_count} == 32
            && @{$operations_by_fiber{$root->{fiber_id}} || []} == 1
            && @root_children == 2
            && @nested_parents == 1
            && @nested_children == 29
            && join("\0", @child_counts) eq join("\0", qw(2 29));
    }
    else {
        $closed = 0;
    }

    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_FIBER_ERROR',
        'execution fiber gate did not preserve its exact bounded parallel-tree recipe',
        '/operation_graph/fibers',
    ) unless $closed;
    return @errors;
}

sub _topology_oracle_errors($ir, $mode) {
    my @errors;
    my $graph = $ir->{operation_graph};
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_LOGICAL_TIME_ERROR',
        'execution gate changed the selected logical-time or tie-break order',
        '/operation_graph',
    ) unless join("\0", @{$graph->{phase_order}}) eq join("\0", qw(drive sample react check))
        && join("\0", @{$graph->{tie_break_order}})
            eq join("\0", qw(domain_rank static_operation_rank local_emission_index semantic_id));

    my %operation = map { $_->{operation_id} => $_ } @{$graph->{operations}};
    my $chain_ok = 1;
    for my $scenario (@{$ir->{scenarios}}) {
        my $ids = $scenario->{operation_ids};
        for my $index (0 .. $#$ids) {
            my $entry = $operation{$ids->[$index]};
            $chain_ok = 0 unless $entry
                && $entry->{static_rank} == $index
                && ($entry->{scenario_id} // '') eq $scenario->{scenario_id};
            next unless $entry;
            my $expected_phase = ($entry->{kind} // '') eq 'reset'
                ? 'drive'
                : ($entry->{kind} // '') eq 'parallel' ? 'react' : undef;
            $chain_ok = 0 unless defined($expected_phase)
                && ($entry->{eligible_phase} // '') eq $expected_phase;
            if ($mode eq 'reset_chain') {
                my @expected_successors = $index == $#$ids
                    ? ()
                    : ($ids->[$index + 1]);
                $chain_ok = 0 unless ($entry->{kind} // '') eq 'reset'
                    && join("\0", @{$entry->{successor_ids}})
                        eq join("\0", @expected_successors);
            }
            else {
                for my $successor_id (@{$entry->{successor_ids}}) {
                    my $successor = $operation{$successor_id};
                    $chain_ok = 0 unless $successor
                        && ($successor->{scenario_id} // '') eq $scenario->{scenario_id}
                        && $successor->{static_rank} > $entry->{static_rank};
                }
            }
        }
    }
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_TOPOLOGY_ERROR',
        'execution gate operation IDs, ranks, phases, or successor chains are not closed',
        '/operation_graph/operations',
    ) unless $chain_ok && scalar(keys %operation) == @{$graph->{operations}};

    my %operation_map_count;
    for my $record (@{$ir->{source_map}}) {
        $operation_map_count{$1}++
            if ($record->{plan_path} // '')
                =~ m{\A/operation_graph/operations/([0-9]+)\z};
    }
    my $source_map_closed = keys(%operation_map_count) == @{$graph->{operations}};
    for my $index (0 .. $#{$graph->{operations}}) {
        $source_map_closed = 0
            unless ($operation_map_count{$index} // 0) == 1;
    }
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_SOURCE_MAP_ERROR',
        'execution operation source maps are not a unique globally indexed projection',
        '/source_map',
    ) unless $source_map_closed;
    return @errors;
}

sub _maximum_operation_count($ir) {
    my $maximum = 0;
    for my $scenario (@{$ir->{scenarios}}) {
        my $count = 0 + $scenario->{plan_summary}{operation_count};
        $maximum = $count if $count > $maximum;
    }
    return $maximum;
}

sub _ordinal_events($events) {
    for my $index (0 .. $#$events) {
        return 0 unless ($events->[$index]{name} // '')
            eq sprintf('bridge_event_%08d', $index);
    }
    return 1;
}

sub _backend_names($actor) {
    my @clock_names = defined($actor->{clock}) ? ($actor->{clock}) : ();
    my @reset_names = ref($actor->{reset}) eq 'HASH' ? ($actor->{reset}{name}) : ();
    my @endpoints = (@clock_names, @reset_names);
    push @endpoints, map { $_->{name} } @{$actor->{interface}{inputs} || []};
    push @endpoints, map { $_->{name} } @{$actor->{interface}{outputs} || []};
    my @probes = map { $_->{name} } @{$actor->{verification_bridge}{probes} || []};
    my %endpoint = map { $_ => $_ } @endpoints;
    my %probe = map { $_ => $_ } @probes;
    return {
        map {
            $_ => {
                unit => $actor->{actor_name},
                endpoints => {%endpoint},
                configurations => {},
                probes => {%probe},
            }
        } qw(systemverilog vhdl)
    };
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= basename($repository_path || 'generated');
    my $lines = length($text)
        ? (() = $text =~ /\n/g) + ($text =~ /\n\z/ ? 0 : 1)
        : 0;
    return {
        text => $text,
        repository_path => $repository_path,
        artifact_name => $artifact_name,
        content_sha256 => sha256_hex($text),
        byte_length => bytes::length($text),
        line_count => $lines,
    };
}

sub _role_input($construction, $role) {
    my @matches = grep { ($_->{role} || '') eq $role } @{$construction->{inputs}};
    confess "construction must contain exactly one $role input\n" unless @matches == 1;
    return $matches[0];
}

sub _input($relative_path, $role, $content) {
    return {
        relative_path => $relative_path,
        role => $role,
        encoding => 'utf-8',
        content => $content,
    };
}

sub _rejected_evaluation($construction, $diagnostics) {
    my $spec = $construction->{specification};
    return _evaluation({
        ok => JSON::PP::false,
        status => 'unexpected_rejection',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'rejected',
        metrics => {},
        semantic_ir_sha256 => undef,
        bridge_manifest_sha256 => undef,
        plan_sha256 => undef,
        diagnostics => _clone($diagnostics || []),
        contract_discrepancies => [],
    });
}

sub _oracle_error($code, $message, $path) {
    return {code => $code, severity => 'error', message => $message, path => $path};
}

sub _evaluation($value) {
    my %expected = map { $_ => 1 } @EVALUATION_KEYS;
    confess "execution evaluation has unknown key(s)\n"
        if grep { !$expected{$_} } keys %$value;
    confess "execution evaluation is missing key(s)\n"
        if grep { !exists($value->{$_}) } @EVALUATION_KEYS;
    return _clone($value);
}

sub _confess_exact_keys($value, $keys, $label) {
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _confess_known_required_keys($value, $known, $required, $label) {
    my %known = map { $_ => 1 } @$known;
    my @unknown = sort grep { !$known{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$required;
    confess "$label has unknown key '$unknown[0]'\n" if @unknown;
    confess "$label is missing key '$missing[0]'\n" if @missing;
}

sub _exact_invocant($class, $method) {
    confess __PACKAGE__ . "->$method requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    confess 'execution evaluation contains an unsupported reference' if ref($value);
    return $value;
}

1;
