package FSM::VIAL::ArchitectureScaleCheckingState;

use v5.20;
use strict;
use warnings;
use bytes ();
use Carp qw(confess);
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::Adapter::IAL2::PPIF;
use FSM::Adapter::ISF;
use FSM::HIAL::VIALBridge::Builder;
use FSM::VIAL::ArchitectureScaleWorkload;
use FSM::VIAL::ExecutionBuilder;
use FSM::VIAL::Parser;

my $FAMILY = 'checking_state_v1';
my $REFERENCE_HIAL_SOURCE = 'ppif/ahb_lite_subordinate.ppif';
my $REFERENCE_HIAL_BYTES = 1_326;
my $REFERENCE_HIAL_SHA256 =
    '9a1d7a591d3ec9a3419b07f05bc83aefa2b213b2cae45f5332f9349ffa27056c';
my $VIAL_SOURCE = 'generated/vial-scale/checking_state/checking_state.vial';
my $EXECUTION_PROFILE = 'core_directed_single_clock_execution_v1';
my $EVALUATION_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_evaluation.v1';
my $PACKED_STATE_SCHEMA =
    'fsmgen.vial_architecture_scale_packed_checking_state.v1';
my $OUTCOME_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_outcome.v1';
my $ORACLE_EVIDENCE_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_oracle_evidence.v1';
my $CLAIMS_SCHEMA =
    'fsmgen.vial_architecture_scale_checking_nonclaims.v1';

my @CONSTRUCT_KEYS = qw(level primary_axis reference_hial_text);
my @CANDIDATE_KEYS = qw(
    level primary_axis reference_hial_text vial_source_text
);
my @EVALUATE_KEYS = qw(construction);
my @VALIDATE_EVALUATION_KEYS = qw(construction evaluation);
my @STAGING_KEYS = qw(construction consumer repository_root);
my @EVALUATION_KEYS = qw(
    ok status schema schema_version evaluation_identity rerun_identity
    workload_identity family level primary_axis requested_counts
    observed_outcome stage_identities metrics packed_state_contract
    outcome_contract oracle_evidence claims explicit_nonclaims diagnostics
);
my @STAGE_IDENTITY_KEYS = qw(
    semantic_ir_sha256 bridge_manifest_sha256 execution_ir_sha256 plan_sha256
);
my @METRIC_KEYS = qw(
    model_instances scalar_model_state_cells scoreboard_instances
    scoreboard_declared_capacity coverpoints bins_and_cross_tuples faults
    random_occurrences serialized_plan_bytes
);
my @PACKED_STATE_KEYS = qw(
    schema schema_version digest_algorithm model_cells scoreboard_fifo
    coverage_vector
);
my @MODEL_PACKING_KEYS = qw(encoding byte_order unknown_state_policy);
my @SCOREBOARD_PACKING_KEYS = qw(
    encoding bytes_per_entry maximum_entries maximum_payload_bytes
    fixed_fields_policy ordering
);
my @COVERAGE_PACKING_KEYS = qw(
    encoding bit_order maximum_entries maximum_vector_bytes comparison
);
my @OUTCOME_KEYS = qw(
    schema schema_version observed_outcome axis_oracle_executed
    selected_count_claimed canonical_stages_completed
);
my @ORACLE_EVIDENCE_KEYS = qw(
    schema schema_version oracle model scoreboard coverage faults random_replay
);
my @CLAIM_KEYS = qw(
    schema schema_version qualification_only capability_claimed support_claimed
    performance_claimed capacity_claimed backend_authority runtime_authority
    axis_level_owned
);

sub construct($class, @args) {
    _exact_invocant($class, 'construct');
    confess __PACKAGE__ . "->construct expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@CONSTRUCT_KEYS, 'checking-state construction');
    my ($axis, $level) = @{$args[0]}{qw(primary_axis level)};
    _selected_contract($axis, $level);
    confess "reference_v1 remains a catalog record and is not a generated checking-state shape\n"
        if $level eq 'reference_v1';
    confess "checking-state foundation does not own any selected axis level\n";
}

sub owned_shapes($class) {
    _exact_invocant($class, 'owned_shapes');
    return [];
}

# Later axis renderers call this boundary from this exact package. It is kept
# private until an axis leaf owns a generated shape, while the foundation test
# can exercise it through a same-package test hook. The caller supplies source
# text, never SemanticIR, bridge, plan, trace, result, or support metadata.
sub _construct_candidate($class, @args) {
    my $caller = caller;
    confess "checking-state candidate construction is private to " . __PACKAGE__ . "\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__
            && defined($caller) && $caller eq __PACKAGE__;
    return _construct_candidate_internal(@args);
}

sub _construct_candidate_internal(@args) {
    my $caller = caller;
    confess "checking-state candidate internals are private to " . __PACKAGE__ . "\n"
        unless defined($caller) && $caller eq __PACKAGE__;
    confess "checking-state candidate construction expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    my $raw = $args[0];
    _confess_exact_keys($raw, \@CANDIDATE_KEYS, 'checking-state candidate');
    my ($axis, $level) = @{$raw}{qw(primary_axis level)};
    _selected_contract($axis, $level);
    confess "reference_v1 remains a catalog record and is not a generated checking-state shape\n"
        if $level eq 'reference_v1';
    _validate_reference_hial($raw->{reference_hial_text});

    my $constructed = FSM::VIAL::ArchitectureScaleWorkload->construct({
        family => $FAMILY,
        level => $level,
        primary_axis => $axis,
        backend_profile => undef,
        tool_profile => undef,
        inputs => [
            _input(
                $REFERENCE_HIAL_SOURCE, 'hial_source',
                $raw->{reference_hial_text},
            ),
            _input($VIAL_SOURCE, 'vial_source', $raw->{vial_source_text}),
        ],
    });
    confess "checking-state candidate source did not fit the construction contract\n"
        unless $constructed->{ok};
    return $constructed;
}

sub build($class, @args) {
    _exact_invocant($class, 'build');
    confess __PACKAGE__ . "->build expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state build');
    my $inputs = _canonical_inputs($args[0]{construction});
    return FSM::VIAL::ExecutionBuilder->build($inputs->{arguments});
}

sub evaluate($class, @args) {
    _exact_invocant($class, 'evaluate');
    confess __PACKAGE__ . "->evaluate expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@EVALUATE_KEYS, 'checking-state evaluation');
    my $construction = _validated_construction($args[0]{construction});

    my $first_inputs = _canonical_inputs_from_construction($construction);
    my $first = FSM::VIAL::ExecutionBuilder->build($first_inputs->{arguments});
    confess "checking-state foundation source did not produce canonical ExecutionIR\n"
        unless $first->{ok};
    my $second_inputs = _canonical_inputs_from_construction($construction);
    my $second = FSM::VIAL::ExecutionBuilder->build($second_inputs->{arguments});
    confess "checking-state foundation rerun did not produce canonical ExecutionIR\n"
        unless $second->{ok};

    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $first_semantic = $first_inputs->{semantic_ir}->as_hashref;
    my $second_semantic = $second_inputs->{semantic_ir}->as_hashref;
    my $first_bridge = $first_inputs->{bridge_manifest}->as_hashref;
    my $second_bridge = $second_inputs->{bridge_manifest}->as_hashref;
    my $first_execution = $first->{execution_ir}->as_hashref;
    my $second_execution = $second->{execution_ir}->as_hashref;
    my @diagnostics;
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed SemanticIR',
        '/stage_identities/semantic_ir_sha256',
    ) unless $canonical->encode($second_semantic)
        eq $canonical->encode($first_semantic);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the bridge manifest',
        '/stage_identities/bridge_manifest_sha256',
    ) unless $canonical->encode($second_bridge)
        eq $canonical->encode($first_bridge);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed ExecutionIR',
        '/stage_identities/execution_ir_sha256',
    ) unless $canonical->encode($second_execution)
        eq $canonical->encode($first_execution);
    push @diagnostics, _oracle_error(
        'VIAL_SCALE_CHECKING_DETERMINISM_ERROR',
        'independent canonical checking-state route changed the execution plan',
        '/stage_identities/plan_sha256',
    ) unless $canonical->encode($second->{plan})
        eq $canonical->encode($first->{plan});

    my $stage_identities = {
        semantic_ir_sha256 => sha256_hex($canonical->encode($first_semantic)),
        bridge_manifest_sha256 => sha256_hex($canonical->encode($first_bridge)),
        execution_ir_sha256 => sha256_hex($canonical->encode($first_execution)),
        plan_sha256 => sha256_hex($canonical->encode($first->{plan})),
    };
    my $rerun_identity = 'rerun/' . sha256_hex(
        $canonical->encode({
            workload_identity => $construction->{workload_identity},
            stage_identities => $stage_identities,
        }),
    );
    my $resources = $first_execution->{resource_summary};
    my $specification = $construction->{specification};
    return _evaluation({
        ok => @diagnostics ? JSON::PP::false : JSON::PP::true,
        status => @diagnostics ? 'oracle_failure' : 'foundation_validated',
        schema => $EVALUATION_SCHEMA,
        schema_version => 1,
        evaluation_identity => undef,
        rerun_identity => $rerun_identity,
        workload_identity => $construction->{workload_identity},
        family => $FAMILY,
        level => $specification->{level},
        primary_axis => $specification->{primary_axis},
        requested_counts => _clone($specification->{requested_counts}),
        observed_outcome => 'accepted_not_axis_evaluated',
        stage_identities => $stage_identities,
        metrics => {
            model_instances => 0 + $resources->{model_instances},
            scalar_model_state_cells => 0 + $resources->{scalar_state_cells},
            scoreboard_instances => 0 + $resources->{scoreboard_instances},
            scoreboard_declared_capacity =>
                0 + $resources->{scoreboard_declared_capacity},
            coverpoints => 0 + $resources->{coverpoints},
            bins_and_cross_tuples =>
                0 + $resources->{coverage_bins_and_cross_tuples},
            faults => 0 + $resources->{faults},
            random_occurrences => 0 + $resources->{random_occurrences},
            serialized_plan_bytes =>
                bytes::length($canonical->encode($first->{plan})),
        },
        packed_state_contract => _packed_state_contract(),
        outcome_contract => {
            schema => $OUTCOME_SCHEMA,
            schema_version => 1,
            observed_outcome => 'accepted_not_axis_evaluated',
            axis_oracle_executed => JSON::PP::false,
            selected_count_claimed => JSON::PP::false,
            canonical_stages_completed => [qw(semantic bridge execution_ir plan)],
        },
        oracle_evidence => {
            schema => $ORACLE_EVIDENCE_SCHEMA,
            schema_version => 1,
            oracle => 'none',
            model => undef,
            scoreboard => undef,
            coverage => undef,
            faults => undef,
            random_replay => undef,
        },
        claims => {
            schema => $CLAIMS_SCHEMA,
            schema_version => 1,
            qualification_only => JSON::PP::true,
            capability_claimed => JSON::PP::false,
            support_claimed => JSON::PP::false,
            performance_claimed => JSON::PP::false,
            capacity_claimed => JSON::PP::false,
            backend_authority => JSON::PP::false,
            runtime_authority => JSON::PP::false,
            axis_level_owned => JSON::PP::false,
        },
        explicit_nonclaims => _clone($specification->{explicit_nonclaims}),
        diagnostics => \@diagnostics,
    });
}

sub validate_evaluation($class, @args) {
    _exact_invocant($class, 'validate_evaluation');
    confess __PACKAGE__ . "->validate_evaluation expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys(
        $args[0], \@VALIDATE_EVALUATION_KEYS,
        'checking-state evaluation validation',
    );
    _validated_construction($args[0]{construction});
    _validate_evaluation_shape($args[0]{evaluation});
    my $rebuilt = __PACKAGE__->evaluate({
        construction => $args[0]{construction},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "checking-state evaluation is not canonical\n"
        unless $canonical->encode($rebuilt)
            eq $canonical->encode($args[0]{evaluation});
    return _clone($rebuilt);
}

sub with_staging($class, @args) {
    _exact_invocant($class, 'with_staging');
    confess __PACKAGE__ . "->with_staging expects one closed hash\n"
        unless @args == 1 && ref($args[0]) eq 'HASH' && !blessed($args[0]);
    _confess_exact_keys($args[0], \@STAGING_KEYS, 'checking-state staging');
    my $construction = _validated_construction($args[0]{construction});
    return FSM::VIAL::ArchitectureScaleWorkload->with_staging({
        repository_root => $args[0]{repository_root},
        construction => $construction,
        consumer => $args[0]{consumer},
    });
}

sub evaluation_keys($class) {
    _exact_invocant($class, 'evaluation_keys');
    return [@EVALUATION_KEYS];
}

sub _selected_contract($axis, $level) {
    my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
    my $family = $catalog->{families}{$FAMILY};
    confess "unknown checking-state primary axis\n"
        unless defined($axis) && !ref($axis) && exists $family->{axes}{$axis};
    confess "unknown checking-state level\n"
        unless defined($level) && !ref($level)
            && exists $family->{axes}{$axis}{levels}{$level};
    return $family->{axes}{$axis}{levels}{$level};
}

sub _canonical_inputs($raw) {
    return _canonical_inputs_from_construction(_validated_construction($raw));
}

sub _canonical_inputs_from_construction($construction) {
    my $hial = _role_input($construction, 'hial_source');
    my $vial = _role_input($construction, 'vial_source');

    # Decision 0073 preserves the ordinary product order: authored VIAL first,
    # then the canonical checked-AHB bridge, then public execution binding.
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $vial->{content},
        source_name => $vial->{relative_path},
        source_catalog => {},
    });
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

    my $semantic = $semantic_ir->as_hashref;
    confess "checking-state candidate must contain exactly one package and fixture\n"
        unless @{$semantic->{packages}} == 1
            && @{$semantic->{packages}[0]{fixtures}} == 1;
    my $fixture = $semantic->{packages}[0]{fixtures}[0];
    my @scenario_ids = map { $_->{semantic_id} } @{$fixture->{scenarios}};
    confess "checking-state candidate must contain at least one scenario\n"
        unless @scenario_ids;
    return {
        semantic_ir => $semantic_ir,
        bridge_manifest => $bridge->{manifest},
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

sub _validated_construction($raw) {
    confess "construction must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    my $specification = $raw->{specification};
    confess "construction must be successful and carry one specification hash\n"
        unless $raw->{ok}
            && ref($specification) eq 'HASH' && !blessed($specification);
    my $rebuilt = _construct_candidate_internal({
        primary_axis => $specification->{primary_axis},
        level => $specification->{level},
        reference_hial_text => _role_input($raw, 'hial_source')->{content},
        vial_source_text => _role_input($raw, 'vial_source')->{content},
    });
    my $canonical = JSON::PP->new->canonical(1)->allow_nonref(1);
    confess "construction is not canonical\n"
        unless $canonical->encode($rebuilt) eq $canonical->encode($raw);
    return $rebuilt;
}

sub _packed_state_contract() {
    return {
        schema => $PACKED_STATE_SCHEMA,
        schema_version => 1,
        digest_algorithm => 'sha256',
        model_cells => {
            encoding => 'fixed_width_packed_scalar_v1',
            byte_order => 'big_endian',
            unknown_state_policy => 'reject',
        },
        scoreboard_fifo => {
            encoding => 'uint32_big_endian_fifo_v1',
            bytes_per_entry => 4,
            maximum_entries => 1_000_000,
            maximum_payload_bytes => 4_000_000,
            fixed_fields_policy => 'reconstruct_and_compare_complete_transaction_v1',
            ordering => 'fifo',
        },
        coverage_vector => {
            encoding => 'one_bit_per_static_bin_or_tuple_v1',
            bit_order => 'least_significant_bit_first',
            maximum_entries => 1_000_000,
            maximum_vector_bytes => 125_000,
            comparison => 'byte_equal_independently_derived_expected_vector_v1',
        },
    };
}

sub _validate_evaluation_shape($raw) {
    confess "checking-state evaluation must be one unblessed hash\n"
        unless ref($raw) eq 'HASH' && !blessed($raw);
    _confess_exact_keys($raw, \@EVALUATION_KEYS, 'checking-state evaluation');
    _confess_exact_keys(
        $raw->{stage_identities}, \@STAGE_IDENTITY_KEYS,
        'checking-state stage identities',
    );
    _confess_exact_keys($raw->{metrics}, \@METRIC_KEYS, 'checking-state metrics');
    _confess_exact_keys(
        $raw->{packed_state_contract}, \@PACKED_STATE_KEYS,
        'checking-state packed-state contract',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{model_cells}, \@MODEL_PACKING_KEYS,
        'checking-state model packing',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{scoreboard_fifo}, \@SCOREBOARD_PACKING_KEYS,
        'checking-state scoreboard packing',
    );
    _confess_exact_keys(
        $raw->{packed_state_contract}{coverage_vector}, \@COVERAGE_PACKING_KEYS,
        'checking-state coverage packing',
    );
    _confess_exact_keys(
        $raw->{outcome_contract}, \@OUTCOME_KEYS,
        'checking-state outcome contract',
    );
    _confess_exact_keys(
        $raw->{oracle_evidence}, \@ORACLE_EVIDENCE_KEYS,
        'checking-state oracle evidence',
    );
    _confess_exact_keys($raw->{claims}, \@CLAIM_KEYS, 'checking-state claims');
    confess "checking-state evaluation schema is invalid\n"
        unless ($raw->{schema} // '') eq $EVALUATION_SCHEMA
            && ($raw->{schema_version} // 0) == 1;
    confess "checking-state packed-state schema is invalid\n"
        unless ($raw->{packed_state_contract}{schema} // '') eq $PACKED_STATE_SCHEMA
            && ($raw->{packed_state_contract}{schema_version} // 0) == 1;
    confess "checking-state outcome schema is invalid\n"
        unless ($raw->{outcome_contract}{schema} // '') eq $OUTCOME_SCHEMA
            && ($raw->{outcome_contract}{schema_version} // 0) == 1;
    confess "checking-state oracle-evidence schema is invalid\n"
        unless ($raw->{oracle_evidence}{schema} // '') eq $ORACLE_EVIDENCE_SCHEMA
            && ($raw->{oracle_evidence}{schema_version} // 0) == 1;
    confess "checking-state foundation cannot carry axis oracle evidence\n"
        unless ($raw->{oracle_evidence}{oracle} // '') eq 'none'
            && !defined($raw->{oracle_evidence}{model})
            && !defined($raw->{oracle_evidence}{scoreboard})
            && !defined($raw->{oracle_evidence}{coverage})
            && !defined($raw->{oracle_evidence}{faults})
            && !defined($raw->{oracle_evidence}{random_replay});
    confess "checking-state nonclaim schema is invalid\n"
        unless ($raw->{claims}{schema} // '') eq $CLAIMS_SCHEMA
            && ($raw->{claims}{schema_version} // 0) == 1;
    confess "checking-state evaluation identity is invalid\n"
        unless ($raw->{evaluation_identity} // '')
            =~ m{\Achecking-evaluation/[0-9a-f]{64}\z};
    confess "checking-state rerun identity is invalid\n"
        unless ($raw->{rerun_identity} // '') =~ m{\Arerun/[0-9a-f]{64}\z};
    confess "checking-state evaluation contains an invalid stage identity\n"
        if grep { ($raw->{stage_identities}{$_} // '') !~ /\A[0-9a-f]{64}\z/ }
            @STAGE_IDENTITY_KEYS;
    return 1;
}

sub _evaluation($value) {
    # Validate the complete closed projection before and after attaching its
    # own content identity. No identity may authenticate bytes outside it.
    $value->{evaluation_identity} =
        'checking-evaluation/' . ('0' x 64)
        unless defined $value->{evaluation_identity};
    _validate_evaluation_shape($value);
    my $canonical = JSON::PP->new->canonical(1)->utf8(1);
    my $identity_projection = _clone($value);
    $identity_projection->{evaluation_identity} = undef;
    $value->{evaluation_identity} = 'checking-evaluation/'
        . sha256_hex($canonical->encode($identity_projection));
    _validate_evaluation_shape($value);
    return _clone($value);
}

sub _validate_reference_hial($text) {
    confess "checked-AHB reference text is required for checking-state construction\n"
        unless defined($text) && !ref($text);
    confess "checked-AHB reference byte length changed\n"
        unless bytes::length($text) == $REFERENCE_HIAL_BYTES;
    confess "checked-AHB reference identity changed\n"
        unless sha256_hex($text) eq $REFERENCE_HIAL_SHA256;
}

sub _source_record($text, $repository_path, $artifact_name = undef) {
    $artifact_name //= $repository_path || 'generated';
    $artifact_name =~ s{.*/}{};
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

sub _backend_names($actor) {
    my @clock_names = defined($actor->{clock}) ? ($actor->{clock}) : ();
    my @reset_names = ref($actor->{reset}) eq 'HASH'
        ? ($actor->{reset}{name}) : ();
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

sub _role_input($construction, $role) {
    confess "construction inputs must be an array\n"
        unless ref($construction->{inputs}) eq 'ARRAY';
    my @matches = grep { ref($_) eq 'HASH' && ($_->{role} || '') eq $role }
        @{$construction->{inputs}};
    confess "construction must contain exactly one $role input\n"
        unless @matches == 1;
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

sub _oracle_error($code, $message, $path) {
    return {
        code => $code,
        severity => 'error',
        message => $message,
        path => $path,
    };
}

sub _confess_exact_keys($value, $keys, $label) {
    confess "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @$keys;
    my @unknown = sort grep { !$expected{$_} } keys %$value;
    my @missing = grep { !exists($value->{$_}) } @$keys;
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
    confess "checking-state projection contains an unsupported reference\n"
        if ref($value);
    return $value;
}

1;
