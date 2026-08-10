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
use FSM::VIAL::ExecutionRandom;
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
my $RANDOM_SEED = 1701;
my $RANDOM_DECISION_ID = 'scale.random_attempt';
my $RANDOM_FIXTURE_ID =
    'architecture_scale_execution::fixture::execution_gate';
my $RANDOM_SCENARIO_ID =
    $RANDOM_FIXTURE_ID . '::scenario::scenario_00000000';
my $RANDOM_CHOICE_ID = $RANDOM_FIXTURE_ID . '::choice::attempt_target';
my $RANDOM_OCCURRENCE_ID = join('/',
    'decision',
    $RANDOM_FIXTURE_ID, $RANDOM_SCENARIO_ID, $RANDOM_DECISION_ID, 0,
);
my $U64_MAX = '18446744073709551615';
# These compact stems and descriptive suffixes are referenced semantic names;
# none is an unreferenced payload or serialized-plan padding field.
my %PLAN_BYTE_RECIPES = (
    gate_candidate_v1 => {
        level => 'gate_candidate_v1',
        serialized_plan_bytes => 1_048_576,
        operation_count => 2_974,
        source => 'generated/vial-scale/execution_graph/plan_bytes.vial',
        fixture_name => 'p',
        scenario_stem => 'sg',
        scenario_suffix => '_exact_mib_serialized_execution_plan_gate',
        scenario_suffix_length => 41,
        endpoint_stem => 'r',
        endpoint_suffix => '_q',
        endpoint_suffix_length => 2,
        coverpoint_name => 'c',
        bin_name => 'asserted',
        domain_name => 'bus',
    },
    qualification_candidate_v1 => {
        level => 'qualification_candidate_v1',
        serialized_plan_bytes => 4_194_304,
        operation_count => 12_166,
        source => 'generated/vial-scale/execution_graph/plan_4m.vial',
        fixture_name => 'qualify_plan',
        scenario_stem => 'sg',
        scenario_suffix => '_4_mib',
        scenario_suffix_length => 6,
        endpoint_stem => 'ready_out',
        endpoint_suffix => '_q',
        endpoint_suffix_length => 2,
        coverpoint_name => 'ready_sampled',
        bin_name => 'asserted',
        domain_name => 'b',
    },
    limit_v1 => {
        level => 'limit_v1',
        serialized_plan_bytes => 16_777_216,
        operation_count => 48_850,
        source => 'generated/vial-scale/execution_graph/p16m.vial',
        fixture_name => 'limit_plan',
        scenario_stem => 'sg',
        scenario_suffix =>
            '_exact_sixteen_mib_execution_plan_limit_with_referenced_checked_ahb_resets_and_ready_out_coverpoint_signal',
        scenario_suffix_length => 106,
        endpoint_stem => 'ready_out',
        endpoint_suffix => '_q',
        endpoint_suffix_length => 2,
        coverpoint_name => 'ready_sampled',
        bin_name => 'asserted1',
        domain_name => 'b',
    },
    over_limit_v1 => {
        level => 'over_limit_v1',
        minimum_bytes => 16_777_217,
        declared_cap_bytes => 16_777_216,
        operation_count => 48_851,
        # Holding every other referenced value fixed makes the source delta
        # exactly one complete reset record. The boundary plan's timeout is
        # already sufficient for the additional one-cycle operation.
        timeout_cycles => 48_851,
        source => 'generated/vial-scale/execution_graph/p16m.vial',
        fixture_name => 'limit_plan',
        scenario_stem => 'sg',
        scenario_suffix =>
            '_exact_sixteen_mib_execution_plan_limit_with_referenced_checked_ahb_resets_and_ready_out_coverpoint_signal',
        scenario_suffix_length => 106,
        endpoint_stem => 'ready_out',
        endpoint_suffix => '_q',
        endpoint_suffix_length => 2,
        coverpoint_name => 'ready_sampled',
        bin_name => 'asserted1',
        domain_name => 'b',
    },
);
my @CHECKED_AHB_FIXED_SOURCE_MAP_PATHS = (
    '/bindings/domains/0',
    map("/bindings/endpoints/$_/relations/0", 0 .. 2),
    '/bindings/probes/0/relations/0',
    map("/bindings/transactions/0/fields/$_/relation", 0 .. 5),
    map("/bindings/events/$_", 0 .. 5),
);
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
        fibers_total simultaneously_live_fibers execution_types
        source_map_records random_attempts serialized_plan_bytes
    );
    my $owned_level = defined($level) && $level eq 'gate_candidate_v1';
    $owned_level = 1 if defined($axis) && $axis eq 'serialized_plan_bytes'
        && defined($level) && ($level eq 'qualification_candidate_v1'
            || $level eq 'limit_v1' || $level eq 'over_limit_v1');
    confess "execution-graph gate slice does not own the requested shape\n"
        unless defined($axis) && $owned_axis{$axis} && $owned_level;
    my $axis_contract = FSM::VIAL::ArchitectureScaleWorkload->catalog
        ->{families}{$FAMILY}{axes}{$axis};
    my $requested = $axis_contract->{levels}{$level};
    my $plan_byte_recipe = $axis eq 'serialized_plan_bytes'
        ? _plan_byte_recipe($level, $requested)
        : undef;
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
    elsif ($axis eq 'execution_types') {
        confess "reference_hial_text is accepted only for checked-AHB execution gates\n"
            if defined $raw->{reference_hial_text};
        $inputs = [
            _input(
                $HIAL_SOURCE, 'hial_source',
                _render_type_hial($requested->{execution_types}),
            ),
            _input(
                $VIAL_SOURCE, 'vial_source',
                _render_type_vial($requested->{execution_types}),
            ),
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
                $axis eq 'serialized_plan_bytes'
                    ? $plan_byte_recipe->{source}
                    : $VIAL_SOURCE,
                'vial_source',
                _render_ahb_vial(
                    $axis, $requested->{$axis}, $plan_byte_recipe,
                ),
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
    return _unexpected_over_limit_acceptance($construction, $inputs, $first)
        if _expects_plan_byte_rejection($spec);

    my @oracle_errors;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $second = _build_execution($inputs);
    push @oracle_errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_DETERMINISM_ERROR',
        'independent execution binding did not reproduce byte-equal plan output',
        '/plan',
    ) unless $second->{ok}
        && $canonical->encode($second->{plan}) eq $canonical->encode($first->{plan});

    my $replayed;
    if ($spec->{primary_axis} eq 'random_attempts') {
        $replayed = eval { _build_replay_execution($inputs, $first->{plan}) };
        push @oracle_errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_REPLAY_ERROR',
            'strict replay construction did not return one accepted plan',
            '/replay',
        ) unless $replayed && $replayed->{ok};
    }

    my $ir = $first->{execution_ir}->as_hashref;
    my $plan_json = $canonical->encode($first->{plan});
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    my $manifest = $inputs->{bridge_manifest}->as_hashref;
    my $observed_bindings = $ir->{resource_summary}{bindings};
    my $event_count = scalar(@{$ir->{bindings}{events}});
    push @oracle_errors, _axis_oracle_errors(
        $spec, $construction, $ir, $first->{plan}, $inputs, $replayed,
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
            random_occurrences => scalar(@{$ir->{randomness}{decisions}}),
            random_attempts => _maximum_random_attempts($ir),
            serialized_bridge_manifest_bytes =>
                bytes::length($canonical->encode($manifest)),
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
    my $axis = $construction->{specification}{primary_axis};
    return _canonical_ahb_inputs($construction, $hial, $vial)
        unless $axis eq 'bindings' || $axis eq 'execution_types';
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
    confess "direct-IAL1 execution gate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "direct-IAL1 execution gate must contain one scenario\n"
        unless @scenario_ids == 1;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
        private_qualification => $axis eq 'bindings' ? 1 : 0,
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

sub _build_replay_execution($inputs, $plan) {
    confess "private qualification does not own execution replay\n"
        if $inputs->{private_qualification};
    my @decisions = @{$plan->{random_decisions} || []};
    confess "execution replay requires at least one generated decision\n"
        unless @decisions;
    my @decision_keys = qw(
        occurrence_id declaration_semantic_id decision_id scenario_id algorithm
        seed type_id distribution value attempt
    );
    my $replay = {
        schema => 'fsmgen.vial_replay.v1',
        schema_version => 1,
        replay_id => undef,
        semantic_ir_id => $plan->{semantic_identity}{semantic_ir_id},
        bridge_manifest_id => $plan->{bridge_identity}{manifest_id},
        fixture_id => $plan->{fixture}{fixture_id},
        scenario_ids => _clone($plan->{fixture}{scenario_ids}),
        algorithm => $decisions[0]{algorithm},
        decisions => [map {
            my $decision = $_;
            +{map { $_ => _clone($decision->{$_}) } @decision_keys}
        } @decisions],
    };
    my $digest = _clone($replay);
    delete $digest->{replay_id};
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    $replay->{replay_id} = 'replay/' . sha256_hex($canonical->encode($digest));

    my %arguments = %{$inputs->{arguments}};
    $arguments{scenario_ids} = _clone($inputs->{arguments}{scenario_ids});
    $arguments{native_extension_catalog} = [];
    $arguments{replay_manifest} = $replay;
    return FSM::VIAL::ExecutionBuilder->build(\%arguments);
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
        unless $spec->{primary_axis} eq 'bindings'
            || $spec->{primary_axis} eq 'execution_types';
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

sub _render_type_hial($type_count) {
    confess "execution-type gate requires at least one type\n"
        unless defined($type_count) && $type_count >= 1;
    my @inputs = map {
        sprintf('(input typed_%08d (width %d))', $_ - 1, $_)
    } 1 .. $type_count;
    return join('',
        '(actor vial_architecture_scale',
        ' (clock clk)',
        ' (reset (rst_n async active_low))',
        ' (interface ', join(' ', @inputs), '))',
        "\n",
    );
}

sub _render_type_vial($type_count) {
    confess "execution-type gate requires at least one type\n"
        unless defined($type_count) && $type_count >= 1;
    my @types = map {
        sprintf('(type width_%08d_t (logic %d))', $_ - 1, $_)
    } 1 .. $type_count;
    my @endpoints = map {
        sprintf(
            '(endpoint typed_%08d "endpoint/typed_%08d" '
                . '(type width_%08d_t) public_port)',
            $_, $_, $_,
        )
    } 0 .. $type_count - 1;
    return join('',
        '(vial (version 1) (package architecture_scale_execution',
        ' (imports)',
        ' (types ', join(' ', @types), ')',
        ' (transactions)',
        ' (models)',
        ' (scoreboards)',
        ' (fixtures (fixture type_gate',
        ' (dut dut',
        ' (unit "unit/vial_architecture_scale")',
        ' (domains (domain scale "domain/default"))',
        ' (endpoints ', join(' ', @endpoints), ')',
        ' (transactions))',
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

sub _plan_byte_recipe($level, $requested) {
    confess "serialized-plan slice does not own the requested byte boundary\n"
        unless defined($level) && !ref($level)
            && exists($PLAN_BYTE_RECIPES{$level})
            && ref($requested) eq 'HASH' && !blessed($requested);
    my $recipe = $PLAN_BYTE_RECIPES{$level};
    if ($level eq 'over_limit_v1') {
        confess "serialized-plan over-limit contract changed\n"
            unless ($requested->{minimum_bytes} // 0)
                    == $recipe->{minimum_bytes}
                && ($requested->{declared_cap_bytes} // 0)
                    == $recipe->{declared_cap_bytes}
                && ($requested->{construction_rule} // '')
                    eq 'first_complete_valid_record_over_boundary';
    }
    else {
        confess "serialized-plan byte boundary changed\n"
            unless ($requested->{serialized_plan_bytes} // 0)
                == $recipe->{serialized_plan_bytes};
    }
    return $recipe;
}

sub _render_ahb_vial($axis, $requested_count, $plan_byte_recipe = undef) {
    my ($scenario_count, $operations_per_scenario, $scenario_timeout_cycles,
        @scenario_actions);
    my $randomness = '(randomness (seed 1701))';
    my $domain_name = 'bus';
    my $scenario_stem = '';
    my $scenario_suffix = '';
    my $endpoint_suffix = '';
    my $endpoint_name = 'ready_out';
    my $coverpoint_name = 'ready_reference';
    my $bin_name = 'asserted';
    my $coverage = '(coverage)';
    my $fixture_name = 'execution_gate';
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
    elsif ($axis eq 'source_map_records') {
        my $fixed_count = scalar(@CHECKED_AHB_FIXED_SOURCE_MAP_PATHS);
        confess "source-map gate cannot subtract its fixed checked-AHB maps\n"
            unless $requested_count > $fixed_count;
        $scenario_count = 1;
        $operations_per_scenario = $requested_count - $fixed_count;
    }
    elsif ($axis eq 'random_attempts') {
        my $target = _random_target_candidate($requested_count);
        $scenario_count = 1;
        $scenario_timeout_cycles = 2;
        @scenario_actions = (
            '(expect selected_random_attempt '
                . '(value_eq (choice attempt_target) ' . $target . '))',
        );
        $randomness = join('',
            '(randomness (seed ', $RANDOM_SEED, ')',
            ' (choice attempt_target (u 64)',
            ' (decision_id "', $RANDOM_DECISION_ID, '")',
            ' (distribution (uniform 0 ', $U64_MAX, '))',
            ' (constraints (value_eq (choice attempt_target) ', $target, '))))',
        );
    }
    elsif ($axis eq 'serialized_plan_bytes') {
        my $recipe = $plan_byte_recipe;
        confess "serialized-plan semantic suffix contract changed\n"
            unless ref($recipe) eq 'HASH' && !blessed($recipe)
                && length($recipe->{scenario_suffix})
                    == $recipe->{scenario_suffix_length}
                && length($recipe->{endpoint_suffix})
                    == $recipe->{endpoint_suffix_length};
        $scenario_count = 1;
        $operations_per_scenario = $recipe->{operation_count};
        $scenario_stem = $recipe->{scenario_stem};
        $scenario_suffix = $recipe->{scenario_suffix};
        $endpoint_suffix = $recipe->{endpoint_suffix};
        $endpoint_name = $recipe->{endpoint_stem};
        $coverpoint_name = $recipe->{coverpoint_name};
        $bin_name = $recipe->{bin_name};
        $fixture_name = $recipe->{fixture_name};
        $domain_name = $recipe->{domain_name};
        $scenario_timeout_cycles = $recipe->{timeout_cycles}
            if defined $recipe->{timeout_cycles};
        $coverage = join('',
            '(coverage (coverpoint ', $coverpoint_name,
            ' (sample ', $domain_name, ')',
            ' (expr (sample ', $endpoint_name, $endpoint_suffix, '))',
            ' (bins (bin ', $bin_name, ' normal (value #b1)))))',
        );
    }
    else {
        confess "checked-AHB renderer does not own axis '$axis'\n";
    }

    my @scenarios;
    for my $scenario_ordinal (0 .. $scenario_count - 1) {
        my $name = $axis eq 'serialized_plan_bytes'
            ? $scenario_stem . $scenario_suffix
            : sprintf('scenario_%08d', $scenario_ordinal);
        my @steps = @scenario_actions
            ? @scenario_actions
            : ("(reset $domain_name 1)") x $operations_per_scenario;
        my $timeout_cycles = defined($scenario_timeout_cycles)
            ? $scenario_timeout_cycles
            : @scenario_actions
                ? $requested_count + 1
                : $operations_per_scenario + 1;
        push @scenarios, join('',
            '(scenario ', $name,
            ' (timeout (cycles ', $domain_name, ' ', $timeout_cycles, '))',
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
        ' (fixtures (fixture ', $fixture_name,
        ' (dut dut',
        ' (unit "unit/ahb_lite_subordinate")',
        ' (domains (domain ', $domain_name, ' "domain/ahb_bus"))',
        ' (endpoints',
        ' (endpoint ', $endpoint_name, $endpoint_suffix,
        ' "endpoint/HREADYOUT" (logic 1) public_port)',
        ' (endpoint response "endpoint/HRESP" (logic 1) public_port)',
        ' (endpoint read_data "endpoint/HRDATA" (logic 32) public_port)',
        ' (endpoint stored_data "probe/reg_data_q" (logic 32) verification_probe))',
        ' (transactions (transaction write "transaction/ahb_write" ahb_write)))',
        ' (instances)',
        ' ', $coverage,
        ' (faults)',
        ' ', $randomness,
        ' (scenarios ', join(' ', @scenarios), ')))))',
        "\n",
    );
}

sub _random_target_candidate($attempt_count) {
    confess "random-attempt gate requires an integer within the shipped attempt limit\n"
        unless defined($attempt_count) && !ref($attempt_count)
            && $attempt_count =~ /\A[1-9][0-9]*\z/
            && $attempt_count <= 1_000_000;
    my $proposal_index = 0;
    my $generated = FSM::VIAL::ExecutionRandom->generate({
        width => 64,
        seed => $RANDOM_SEED,
        occurrence_id => $RANDOM_OCCURRENCE_ID,
        low => 0,
        high => $U64_MAX,
        max_attempts => $attempt_count,
        accept => sub($proposal) {
            return $proposal_index++ == $attempt_count - 1;
        },
    });
    confess "random-attempt target generation did not reach its exact proposal\n"
        unless $generated && $generated->{attempt} == $attempt_count - 1;
    return $generated->{value}->bstr;
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

sub _axis_oracle_errors($spec, $construction, $ir, $plan, $inputs, $replayed) {
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

    if ($axis eq 'execution_types') {
        my $requested = $spec->{requested_counts}{execution_types};
        my $observed = scalar(@{$ir->{type_table}});
        my $manifest = $inputs->{bridge_manifest}->as_hashref;
        my @layers = map { $_->{layer} // '' }
            @{$manifest->{review_route}{stages} || []};
        my ($ial1_capability) = grep {
            ($_->{capability_id} // '') eq 'hial_vial.bridge_source.ial1'
        } @$ledger;
        my ($ahb_capability) = grep {
            ($_->{capability_id} // '') eq 'hial_vial.bridge_protocol.ahb_subordinate_v1'
        } @$ledger;
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_COUNT_ERROR',
            "observed execution type count $observed does not equal requested count $requested",
            '/metrics/execution_types',
        ) unless $observed == $requested;
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_CAPABILITY_ERROR',
            'execution-type gate did not retain only the public direct-IAL1 source capability',
            '/capability_ledger',
        ) unless !$scale_capability && !$ahb_capability
            && $ial1_capability
            && ($ial1_capability->{classification} // '')
                eq 'satisfied_by_execution_profile'
            && ($ial1_capability->{portable_class} // '') eq 'portable';
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_ROUTE_ERROR',
            'execution-type gate did not traverse the ordinary IAL1/IAL0 review route',
            '/bridge_manifest/review_route',
        ) unless ($manifest->{review_route}{authored_layer} // '') eq 'IAL1'
            && join("\0", @layers) eq join("\0", qw(IAL1 IAL0));

        my @widths = map { $_->{semantic_type}{width} // 0 } @{$ir->{type_table}};
        my $types_closed = @widths == $requested
            && join("\0", @widths) eq join("\0", 1 .. $requested)
            && !scalar(grep {
                ($_->{semantic_type}{kind} // '') ne 'scalar'
                    || ($_->{semantic_type}{family} // '') ne 'logic'
                    || ($_->{semantic_type}{state_domain} // '') ne 'four_state'
                    || ($_->{semantic_type}{signed} // 0)
                    || @{$_->{semantic_ids} || []} != 1
                    || @{$_->{carrier_type_ids} || []} != 1
            } @{$ir->{type_table}});
        my @carrier_widths = map { $_->{width} // 0 } @{$manifest->{types}};
        $types_closed &&= @carrier_widths == $requested
            && join("\0", sort { $a <=> $b } @carrier_widths)
                eq join("\0", 1 .. $requested);
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_TYPE_ERROR',
            'execution-type gate did not preserve one exact public four-state scalar relation per width',
            '/type_table',
        ) unless $types_closed;

        my $bindings = $ir->{bindings};
        my $binding_closed = @{$bindings->{endpoints}} == $requested
            && !@{$bindings->{probes}}
            && !@{$bindings->{transactions}}
            && !@{$bindings->{events}}
            && $ir->{resource_summary}{bindings} == $requested + 2
            && @{$manifest->{endpoints}} == $requested + 2
            && !scalar(grep {
                @{$_->{relations} || []} != 1
                    || ($_->{relations}[0]{direction} // '') ne 'drive'
            } @{$bindings->{endpoints}});
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_BINDING_ERROR',
            'execution-type gate did not bind every public data endpoint exactly once',
            '/bindings/endpoints',
        ) unless $binding_closed;
        push @errors, _topology_oracle_errors($ir, 'reset_chain');
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
    if ($axis eq 'source_map_records') {
        my $observed = scalar(@{$ir->{source_map}});
        push @errors, _oracle_error(
            'VIAL_SCALE_EXECUTION_COUNT_ERROR',
            "observed source-map count $observed does not equal requested count $requested",
            '/metrics/source_map_records',
        ) unless $observed == $requested;
        push @errors, _source_map_oracle_errors($ir, $requested);
        push @errors, _topology_oracle_errors($ir, 'reset_chain');
        return @errors;
    }

    if ($axis eq 'random_attempts') {
        push @errors, _random_attempt_oracle_errors(
            $ir, $plan, $replayed, $requested,
        );
        push @errors, _topology_oracle_errors($ir, 'forward_chain');
        return @errors;
    }

    if ($axis eq 'serialized_plan_bytes') {
        push @errors, _plan_byte_oracle_errors(
            $construction, $ir, $plan, $requested,
        );
        push @errors, _topology_oracle_errors($ir, 'reset_chain');
        return @errors;
    }

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

sub _plan_byte_oracle_errors($construction, $ir, $plan, $requested) {
    my @errors;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $plan_json = $canonical->encode($plan);
    my $vial = _role_input($construction, 'vial_source');
    my $spec = $construction->{specification};
    my $recipe = _plan_byte_recipe($spec->{level}, $spec->{requested_counts});
    my $fixture_id =
        "architecture_scale_execution::fixture::$recipe->{fixture_name}";
    my $scenario_name =
        $recipe->{scenario_stem} . $recipe->{scenario_suffix};
    my $scenario_id = "$fixture_id\::scenario\::$scenario_name";
    my $endpoint_name = $recipe->{endpoint_stem} . $recipe->{endpoint_suffix};
    my $endpoint_id = "$fixture_id\::endpoint\::$endpoint_name";
    my $coverpoint_id =
        "$fixture_id\::coverpoint\::$recipe->{coverpoint_name}";
    my $coverage = $ir->{coverage};
    my $coverpoint = ref($coverage->{coverpoints}) eq 'ARRAY'
        && @{$coverage->{coverpoints}} == 1
            ? $coverage->{coverpoints}[0]
            : undef;
    my $bin = $coverpoint && ref($coverpoint->{bins}) eq 'ARRAY'
        && @{$coverpoint->{bins}} == 1
            ? $coverpoint->{bins}[0]
            : undef;
    my $scenario = @{$ir->{scenarios}} == 1 ? $ir->{scenarios}[0] : undef;
    my $graph = $ir->{operation_graph};

    my %records_by_plan_path;
    push @{$records_by_plan_path{$_->{plan_path} // ''}}, $_
        for @{$ir->{source_map}};
    my @fixed_paths = sort grep {
        $_ !~ m{\A/operation_graph/operations/[0-9]+\z}
    } keys %records_by_plan_path;
    my $maps_closed = @{$ir->{source_map}}
            == $recipe->{operation_count} + @CHECKED_AHB_FIXED_SOURCE_MAP_PATHS
        && scalar(keys %records_by_plan_path) == @{$ir->{source_map}}
        && join("\0", @fixed_paths)
            eq join("\0", sort @CHECKED_AHB_FIXED_SOURCE_MAP_PATHS);
    for my $index (0 .. $recipe->{operation_count} - 1) {
        my $records = $records_by_plan_path{"/operation_graph/operations/$index"}
            || [];
        $maps_closed = 0 unless @$records == 1
            && ($records->[0]{semantic_path} // '')
                eq "/packages/0/fixtures/0/scenarios/0/actions/$index";
    }
    for my $record (@{$ir->{source_map}}) {
        my $locations = $record->{source_locations};
        $maps_closed = 0 unless ref($locations) eq 'ARRAY' && @$locations == 1
            && ($locations->[0]{source_name} // '') eq $recipe->{source}
            && ($locations->[0]{start_line} // 0) == 1
            && ($locations->[0]{end_line} // 0) == 1
            && ($locations->[0]{end_byte_exclusive} // -1)
                > ($locations->[0]{start_byte} // -1);
    }

    my $source_closed = ($vial->{relative_path} // '') eq $recipe->{source}
        && $vial->{content} =~ /\A[^\r\n]+\n\z/
        && scalar(() = $vial->{content}
            =~ /\(reset \Q$recipe->{domain_name}\E 1\)/g)
            == $recipe->{operation_count}
        && scalar(() = $vial->{content} =~ /\Q$scenario_name\E/g) == 1
        && scalar(() = $vial->{content} =~ /\(endpoint \Q$endpoint_name\E /g)
            == 1
        && scalar(() = $vial->{content}
            =~ /\(expr \(sample \Q$endpoint_name\E\)\)/g) == 1;

    my $coverage_closed = $coverpoint
        && !@{$coverage->{crosses} || []}
        && ($coverpoint->{semantic_id} // '') eq $coverpoint_id
        && ($coverpoint->{domain_id} // '')
            eq "$fixture_id\::domain\::$recipe->{domain_name}"
        && ($coverpoint->{expression}{kind} // '') eq 'reference'
        && ($coverpoint->{expression}{op} // '') eq 'sample'
        && ($coverpoint->{expression}{semantic_id} // '') eq $endpoint_id
        && ($coverpoint->{expression}{binding_id} // '')
            eq "binding/$fixture_id/endpoint/HREADYOUT"
        && $bin
        && ($bin->{name} // '') eq $recipe->{bin_name}
        && ($bin->{classification} // '') eq 'normal'
        && ($bin->{matcher}{kind} // '') eq 'value'
        && ($bin->{matcher}{value}{width} // 0) == 1
        && ($bin->{matcher}{value}{known_mask} // '') eq '1'
        && ($bin->{matcher}{value}{value_bits} // '') eq '1';

    my $plan_closed = bytes::length($plan_json) == $requested
        && ($construction->{specification}{level} // '') eq $recipe->{level}
        && $scenario
        && ($scenario->{name} // '') eq $scenario_name
        && ($scenario->{scenario_id} // '') eq $scenario_id
        && $scenario->{plan_summary}{operation_count} == $recipe->{operation_count}
        && join("\0", @{$scenario->{plan_summary}{coverpoint_ids} || []})
            eq $coverpoint_id
        && $graph->{total_operation_count} == $recipe->{operation_count}
        && $graph->{total_fiber_count} == 1
        && $graph->{maximum_simultaneous_live_fibers} == 1
        && !@{$ir->{randomness}{decisions} || []}
        && !scalar(grep {
            ($_->{kind} // '') ne 'reset'
                || ($_->{eligible_phase} // '') ne 'drive'
        } @{$graph->{operations}});

    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_PLAN_BYTES_ERROR',
        'serialized-plan construction did not preserve its exact semantic recipe and canonical byte boundary',
        '/metrics/serialized_plan_bytes',
    ) unless $source_closed && $coverage_closed && $maps_closed && $plan_closed;
    return @errors;
}

sub _random_attempt_oracle_errors($ir, $plan, $replayed, $requested) {
    my @errors;
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $target = _random_target_candidate($requested);
    my $decisions = $plan->{random_decisions};
    my $decision = ref($decisions) eq 'ARRAY' && @$decisions == 1
        ? $decisions->[0]
        : undef;
    my $operation = @{$ir->{operation_graph}{operations}} == 1
        ? $ir->{operation_graph}{operations}[0]
        : undef;
    my @references = $operation
        ? _decision_references($operation->{typed_inputs})
        : ();
    my @decision_maps = grep {
        ($_->{plan_path} // '') =~ m{\A/random_decisions/}
    } @{$ir->{source_map}};
    my $expected_value = $decision
        ? FSM::VIAL::ExecutionRandom->normalized_scalar(
            $target, $decision->{type_id}, 'two_state', 0, 64,
        )
        : undef;
    my $expected_distribution = $decision
        ? {
            kind => 'uniform',
            low => FSM::VIAL::ExecutionRandom->normalized_scalar(
                0, $decision->{type_id}, 'two_state', 0, 64,
            ),
            high => FSM::VIAL::ExecutionRandom->normalized_scalar(
                $U64_MAX, $decision->{type_id}, 'two_state', 0, 64,
            ),
        }
        : undef;
    my ($u64_type) = grep {
        ($_->{semantic_type}{kind} // '') eq 'scalar'
            && ($_->{semantic_type}{family} // '') eq 'u'
            && ($_->{semantic_type}{width} // 0) == 64
            && !($_->{semantic_type}{signed} // 0)
            && ($_->{semantic_type}{state_domain} // '') eq 'two_state'
    } @{$ir->{type_table}};
    my $generated_closed = $decision
        && ($decision->{occurrence_id} // '') eq $RANDOM_OCCURRENCE_ID
        && ($decision->{declaration_semantic_id} // '') eq $RANDOM_CHOICE_ID
        && ($decision->{decision_id} // '') eq $RANDOM_DECISION_ID
        && ($decision->{scenario_id} // '') eq $RANDOM_SCENARIO_ID
        && ($decision->{algorithm} // '') eq 'sha256_counter_rejection_v1'
        && ($decision->{seed} // -1) == $RANDOM_SEED
        && ($decision->{attempt} // -1) == $requested - 1
        && ($decision->{origin} // '') eq 'generated'
        && $canonical->encode($decision->{value})
            eq $canonical->encode($expected_value)
        && $canonical->encode($decision->{distribution})
            eq $canonical->encode($expected_distribution)
        && @{$ir->{type_table}} == 8
        && $u64_type
        && ($u64_type->{type_id} // '') eq ($decision->{type_id} // '')
        && join("\0", @{$u64_type->{semantic_ids} || []}) eq $RANDOM_CHOICE_ID
        && !@{$u64_type->{carrier_type_ids} || []}
        && @{$decision->{reference_operation_ids} || []} == 1
        && $operation
        && $decision->{reference_operation_ids}[0] eq $operation->{operation_id}
        && ($operation->{kind} // '') eq 'expect'
        && ($operation->{eligible_phase} // '') eq 'check'
        && @references == 1
        && ($references[0]{occurrence_id} // '') eq $RANDOM_OCCURRENCE_ID
        && $canonical->encode($references[0]{value})
            eq $canonical->encode($expected_value)
        && $ir->{resource_summary}{random_occurrences} == 1
        && @{$ir->{scenarios}} == 1
        && join("\0", @{$ir->{scenarios}[0]{plan_summary}{decision_occurrence_ids} || []})
            eq $RANDOM_OCCURRENCE_ID
        && @decision_maps == 1
        && ($decision_maps[0]{plan_path} // '') eq '/random_decisions/0'
        && ($decision_maps[0]{semantic_path} // '')
            eq '/packages/0/fixtures/0/randomness/choices/0'
        && !@{$decision_maps[0]{bridge_fact_paths} || []}
        && @{$decision_maps[0]{source_locations} || []} == 1
        && ($decision_maps[0]{source_locations}[0]{source_name} // '')
            eq $VIAL_SOURCE
        && ($decision_maps[0]{source_locations}[0]{start_line} // 0) == 1
        && ($decision_maps[0]{source_locations}[0]{end_line} // 0) == 1
        && ($decision_maps[0]{source_locations}[0]{end_byte_exclusive} // -1)
            > ($decision_maps[0]{source_locations}[0]{start_byte} // -1);

    my $replay_closed = $replayed && $replayed->{ok}
        && ref($replayed->{plan}{random_decisions}) eq 'ARRAY'
        && @{$replayed->{plan}{random_decisions}} == 1;
    if ($replay_closed) {
        my $generated_decision = _clone($decision);
        my $replayed_decision = _clone($replayed->{plan}{random_decisions}[0]);
        $replay_closed = 0 unless ($replayed_decision->{origin} // '') eq 'replayed';
        delete $generated_decision->{origin};
        delete $replayed_decision->{origin};
        $replay_closed = 0 unless $canonical->encode($generated_decision)
            eq $canonical->encode($replayed_decision);

        my $generated_plan = _clone($plan);
        my $replayed_plan = _clone($replayed->{plan});
        delete $generated_plan->{plan_id};
        delete $replayed_plan->{plan_id};
        $generated_plan->{random_decisions}[0]{origin} = 'replayed';
        $replay_closed = 0 unless $canonical->encode($generated_plan)
            eq $canonical->encode($replayed_plan);
    }

    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_RANDOM_ERROR',
        'random-attempt gate did not preserve its exact candidate, attempt, operation, and source-map closure',
        '/random_decisions/0',
    ) unless $generated_closed;
    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_REPLAY_ERROR',
        'generated and replayed decisions differ beyond the selected origin field',
        '/replay/random_decisions/0',
    ) unless $replay_closed;
    return @errors;
}

sub _decision_references($value) {
    return () unless defined $value;
    return map { _decision_references($_) } @$value if ref($value) eq 'ARRAY';
    if (ref($value) eq 'HASH') {
        my @own = ($value->{kind} // '') eq 'decision_reference'
            ? ($value)
            : ();
        return (@own, map { _decision_references($value->{$_}) } sort keys %$value);
    }
    return ();
}

sub _source_map_oracle_errors($ir, $requested) {
    my @errors;
    my $graph = $ir->{operation_graph};
    my $operation_count = $requested - scalar(@CHECKED_AHB_FIXED_SOURCE_MAP_PATHS);
    my %records_by_plan_path;
    push @{$records_by_plan_path{$_->{plan_path} // ''}}, $_
        for @{$ir->{source_map}};
    my @fixed_paths = sort grep {
        $_ !~ m{\A/operation_graph/operations/[0-9]+\z}
    } keys %records_by_plan_path;
    my $closed = @{$ir->{source_map}} == $requested
        && scalar(keys %records_by_plan_path) == $requested
        && join("\0", @fixed_paths)
            eq join("\0", sort @CHECKED_AHB_FIXED_SOURCE_MAP_PATHS)
        && @{$ir->{scenarios}} == 1
        && $graph->{total_operation_count} == $operation_count
        && $graph->{total_fiber_count} == 1
        && $graph->{maximum_simultaneous_live_fibers} == 1
        && $ir->{scenarios}[0]{plan_summary}{operation_count} == $operation_count
        && !scalar(grep {
            ($_->{kind} // '') ne 'reset'
                || ($_->{eligible_phase} // '') ne 'drive'
        } @{$graph->{operations}});

    for my $index (0 .. $operation_count - 1) {
        my $plan_path = "/operation_graph/operations/$index";
        my $records = $records_by_plan_path{$plan_path} || [];
        my $record = @$records == 1 ? $records->[0] : undef;
        $closed = 0 unless $record
            && ($record->{semantic_path} // '')
                eq "/packages/0/fixtures/0/scenarios/0/actions/$index"
            && !@{$record->{bridge_fact_paths} || []};
    }
    for my $record (@{$ir->{source_map}}) {
        my $locations = $record->{source_locations};
        $closed = 0 unless ref($locations) eq 'ARRAY' && @$locations == 1;
        next unless ref($locations) eq 'ARRAY' && @$locations == 1;
        my $location = $locations->[0];
        $closed = 0 unless ($location->{source_name} // '') eq $VIAL_SOURCE
            && ($location->{start_line} // 0) == 1
            && ($location->{end_line} // 0) == 1
            && ($location->{start_byte} // -1) >= 0
            && ($location->{end_byte_exclusive} // -1) > $location->{start_byte};
    }

    push @errors, _oracle_error(
        'VIAL_SCALE_EXECUTION_SOURCE_MAP_ERROR',
        'execution source-map gate did not preserve its exact checked-AHB maps, spans, and reset topology',
        '/source_map',
    ) unless $closed;
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
                : ($entry->{kind} // '') eq 'parallel'
                    ? 'react'
                    : ($entry->{kind} // '') eq 'expect' ? 'check' : undef;
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

sub _maximum_random_attempts($ir) {
    my @decisions = @{$ir->{randomness}{decisions} || []};
    return 0 unless @decisions;
    my $maximum = 0;
    for my $decision (@decisions) {
        my $attempts = ($decision->{attempt} // -1) + 1;
        $maximum = $attempts if $attempts > $maximum;
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
    my @probes = ref($actor->{verification_bridge}) eq 'HASH'
        ? map { $_->{name} } @{$actor->{verification_bridge}{probes} || []}
        : ();
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
    my @oracle_errors = _rejection_oracle_errors($spec, $diagnostics);
    my $expected = _expects_plan_byte_rejection($spec) && !@oracle_errors;
    return _evaluation({
        ok => $expected ? JSON::PP::true : JSON::PP::false,
        status => $expected ? 'expected_rejection' : 'oracle_failure',
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
        diagnostics => [@{_clone($diagnostics || [])}, @oracle_errors],
        contract_discrepancies => [],
    });
}

sub _expects_plan_byte_rejection($spec) {
    return ($spec->{primary_axis} // '') eq 'serialized_plan_bytes'
        && ($spec->{level} // '') eq 'over_limit_v1';
}

sub _rejection_oracle_errors($spec, $diagnostics) {
    return (_oracle_error(
        'VIAL_SCALE_EXECUTION_OUTCOME_ERROR',
        'execution construction was rejected before its declared authoritative outcome',
        '/observed_outcome',
    )) unless _expects_plan_byte_rejection($spec);

    my $expected = [{
        schema_version => 1,
        severity => 'error',
        code => 'VIAL_EXECUTION_LIMIT_ERROR',
        phase => 'limit',
        message => 'serialized_plan_bytes exceeds the limit 16777216',
        semantic_path => '/plan',
        source_location => undef,
        bridge_fact_paths => [],
        related => [],
    }];
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    return () if ref($diagnostics) eq 'ARRAY'
        && $canonical->encode($diagnostics) eq $canonical->encode($expected);
    return (_oracle_error(
        'VIAL_SCALE_EXECUTION_DIAGNOSTIC_ERROR',
        'over-limit plan did not return the one exact authoritative byte-cap diagnostic',
        '/diagnostics',
    ));
}

sub _unexpected_over_limit_acceptance($construction, $inputs, $built) {
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $semantic = $inputs->{semantic_ir}->as_hashref;
    my $manifest = $inputs->{bridge_manifest}->as_hashref;
    my $plan_json = $canonical->encode($built->{plan});
    my $spec = $construction->{specification};
    return _evaluation({
        ok => JSON::PP::false,
        status => 'oracle_failure',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $spec->{level},
        primary_axis => $spec->{primary_axis},
        requested_counts => _clone($spec->{requested_counts}),
        observed_outcome => 'accepted',
        metrics => {serialized_plan_bytes => bytes::length($plan_json)},
        semantic_ir_sha256 => sha256_hex($canonical->encode($semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($manifest)),
        plan_sha256 => sha256_hex($plan_json),
        diagnostics => [_oracle_error(
            'VIAL_SCALE_EXECUTION_OUTCOME_ERROR',
            'over-limit plan was accepted but the selected oracle requires rejection',
            '/observed_outcome',
        )],
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
