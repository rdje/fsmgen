package FSM::VIAL::LifecycleControl;

use strict;
use warnings;

use bytes ();
use Digest::SHA qw(sha256_hex);
use Exporter 'import';
use JSON::PP ();
use Math::BigInt;
use Scalar::Util qw(blessed reftype);

use FSM::Support::VIALSemanticFamilyContract qw(
    validate_vial_semantic_family_collection
    validate_vial_semantic_family_stage
);

our @EXPORT_OK = qw(
    build_vial_lifecycle_control_contract
    build_vial_lifecycle_execution_records
    build_vial_lifecycle_semantic_family
    validate_vial_lifecycle_result
);

my %LIMIT = (
    lifecycle_programs_per_package => 1_024,
    dependency_records_per_lifecycle => 64,
    service_records_per_lifecycle => 1,
    deadline_records_per_lifecycle => 64,
    expanded_records_per_lifecycle => 256,
    expanded_records_per_catalog => 65_536,
    condition_terms_per_lifecycle => 256,
    condition_depth => 16,
    all_operands => 64,
    logical_cycles => 2_147_483_647,
    identifier_bytes => 128,
);

my @EFFECT_KINDS = qw(
    complete deadline drain failure finalize ready service_start service_stop
    shutdown stimulus_start
);
my @CAPABILITIES = qw(
    vial.family.lifecycle_control.deadline.v1
    vial.family.lifecycle_control.v1
    vial.semantic_family_envelope.v2
);
my @LIFECYCLE_RESULT_KEYS = qw(
    schema schema_version lifecycle_id fixture_id domain_id status entered_at
    dependency_results readiness_result service_results stimulus_start_result
    completion_result drain_result shutdown_result finalize_result
    deadline_results failure_result source_map
);
my @TIME_KEYS = qw(domain_id cycle phase ordinal);
my @POINT_RESULT_KEYS = qw(record_id status reached_at);
my @DEPENDENCY_RESULT_KEYS = qw(record_id status reached_at);
my @SERVICE_RESULT_KEYS = qw(
    record_id status started_at ready_at quiescent_at stopped_at diagnostic_ids
);
my @DEADLINE_RESULT_KEYS = qw(
    record_id status started_at ended_at max_cycles last_cycle_inclusive
);
my @FAILURE_RESULT_KEYS = qw(
    record_id primary_diagnostic_id cleanup_status cleanup_deadline_cycle
    diagnostic_ids
);
my @SOURCE_MAP_KEYS = qw(
    schema schema_version source_map_id semantic_id semantic_path
    bridge_fact_paths execution_paths plan_paths result_paths source_locations
);
my @LOCATION_KEYS = qw(
    source_name start_byte end_byte_exclusive start_line start_column
    end_line end_column
);

sub build_vial_lifecycle_control_contract {
    return _clone({
        schema => 'fsmgen.vial_lifecycle_control_contract.v1',
        schema_version => 1,
        status => 'source_semantic_binding_execution_plan_and_result_contract_implemented',
        family_id => 'lifecycle_control',
        revision => 1,
        semantic_payload_schema => 'fsmgen.vial_lifecycle_control.v1',
        result_schema => 'fsmgen.vial_lifecycle_result.v1',
        capabilities => [@CAPABILITIES],
        effect_kinds => [@EFFECT_KINDS],
        result_keys => [@LIFECYCLE_RESULT_KEYS],
        limits => {%LIMIT},
        diagnostics => [qw(
            VIAL_BIND_REFERENCE_ERROR
            VIAL_LIFECYCLE_CLEANUP_TIMEOUT
            VIAL_LIFECYCLE_DEADLINE_EXPIRED
            VIAL_LIFECYCLE_DRAIN_INCOMPLETE
            VIAL_LIFECYCLE_SERVICE_ERROR
            VIAL_LIMIT_ERROR
            VIAL_PARSE_ERROR
            VIAL_SEMANTIC_ERROR
        )],
        explicit_nonclaims => [qw(
            backend_emission backend_runtime complete_result_manifest
            cross_backend_parity methodology_support support_promotion
        )],
    });
}

sub build_vial_lifecycle_semantic_family {
    my ($args) = @_;
    _internal_invocation($args, [qw(
        form package package_index family_index expanded_nodes_before
    )],
        'lifecycle semantic construction');
    my $form = $args->{form};
    my $package = $args->{package};
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        'lifecycle semantic construction requires one resolved package',
        _location($form), '/',
    ) unless ref($package) eq 'HASH' && !blessed($package);
    die "expanded_nodes_before must be a bounded nonnegative integer\n"
        unless _integer(
            $args->{expanded_nodes_before}, 0,
            $LIMIT{expanded_records_per_catalog},
        );

    my $family_path = "/packages/$args->{package_index}/intent_families/$args->{family_index}";
    my $items = _form($form, 'family', 4, undef, $family_path);
    my $family_id = _identifier($items->[1], "$family_path/family_id");
    _source_fail(
        'VIAL_FAMILY_UNSUPPORTED', 'semantic',
        "intent family '$family_id' is not implemented by the lifecycle compiler",
        _location($items->[1]), "$family_path/family_id",
    ) unless $family_id eq 'lifecycle_control';
    my $revision_items = _form(
        $items->[2], 'revision', 2, 2, "$family_path/revision",
    );
    my $revision = _positive_integer(
        $revision_items->[1], "$family_path/revision",
    );
    _source_fail(
        'VIAL_FAMILY_REVISION_MISMATCH', 'semantic',
        "lifecycle_control revision $revision is not implemented; revision 1 is required",
        _location($revision_items->[1]), "$family_path/revision",
    ) unless $revision eq '1';

    my @programs = @{$items}[3 .. $#{$items}];
    _source_fail(
        'VIAL_LIMIT_ERROR', 'limit',
        "lifecycle_control exceeds the $LIMIT{lifecycle_programs_per_package}-program package limit",
        _location($form), "$family_path/nodes",
    ) if @programs > $LIMIT{lifecycle_programs_per_package};
    my @fixtures = @{$package->{fixtures} || []};
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        'lifecycle program count exceeds the package fixture count',
        _location($form), "$family_path/nodes",
    ) if @programs > @fixtures;
    my %fixture = map { $_->{name} => $_ } @fixtures;
    my (%owned_fixture, @nodes);
    for my $program_index (0 .. $#programs) {
        my $program_path = "$family_path/lifecycles/$program_index";
        my $expanded = _build_program({
            node => $programs[$program_index],
            path => $program_path,
            family_path => $family_path,
            family_semantic_id => "$package->{semantic_id}::intent_family::lifecycle_control",
            fixture_by_name => \%fixture,
            owned_fixture => \%owned_fixture,
        });
        push @nodes, @{$expanded};
        _source_fail(
            'VIAL_LIMIT_ERROR', 'limit',
            "lifecycle_control exceeds the $LIMIT{expanded_records_per_catalog}-record connected-catalog limit",
            _location($programs[$program_index]), "$family_path/nodes",
        ) if $args->{expanded_nodes_before} + @nodes
            > $LIMIT{expanded_records_per_catalog};
    }

    my $family = {
        semantic_id => "$package->{semantic_id}::intent_family::lifecycle_control",
        family_id => 'lifecycle_control',
        revision => 1,
        semantic_path => $family_path,
        source_span => _location($form),
        nodes => \@nodes,
    };
    return validate_vial_semantic_family_collection(
        'semantic_family', [$family],
    )->[0];
}

sub _build_program {
    my ($args) = @_;
    my $node = $args->{node};
    my $path = $args->{path};
    my $items = _form($node, 'lifecycle', 14, 14, $path);
    my $name = _identifier($items->[1], "$path/name");
    my (%namespace, %first_location);
    _declare(\%namespace, \%first_location, $name, $items->[1], "$path/name");

    my $fixture_items = _form($items->[2], 'fixture', 2, 2, "$path/fixture");
    my $fixture_name = _identifier($fixture_items->[1], "$path/fixture");
    my $fixture = $args->{fixture_by_name}{$fixture_name};
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'resolve',
        "lifecycle '$name' names unknown package fixture '$fixture_name'",
        _location($fixture_items->[1]), "$path/fixture",
    ) unless $fixture;
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        "fixture '$fixture_name' has more than one lifecycle program",
        _location($fixture_items->[1]), "$path/fixture",
    ) if $args->{owned_fixture}{$fixture->{semantic_id}}++;

    my $domain_items = _form($items->[3], 'domain', 2, 2, "$path/domain");
    my $domain_name = _identifier($domain_items->[1], "$path/domain");
    my %domain = map { $_->{name} => $_ } @{$fixture->{dut}{domains} || []};
    my $domain = $domain{$domain_name};
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'resolve',
        "lifecycle '$name' names unknown fixture domain '$domain_name'",
        _location($domain_items->[1]), "$path/domain",
    ) unless $domain;

    my $dependency_items = _form(
        $items->[4], 'dependencies', 1, undef, "$path/dependencies",
    );
    my @dependency_nodes = @{$dependency_items}[1 .. $#{$dependency_items}];
    _bounded_source_count(
        scalar(@dependency_nodes), 'dependency records',
        $LIMIT{dependency_records_per_lifecycle}, $items->[4], "$path/dependencies",
    );
    my @dependencies;
    for my $index (0 .. $#dependency_nodes) {
        my $record_path = "$path/dependencies/$index";
        my $record = _form(
            $dependency_nodes[$index], 'dependency', 3, 3, $record_path,
        );
        my $record_name = _identifier($record->[1], "$record_path/name");
        _declare(\%namespace, \%first_location, $record_name,
            $record->[1], "$record_path/name");
        my $when = _form($record->[2], 'when', 2, 2, "$record_path/when");
        push @dependencies, {
            name => $record_name, node => $dependency_nodes[$index],
            condition_node => $when->[1], path => $record_path,
        };
    }

    my $readiness = _parse_point(
        $items->[5], 'readiness', "$path/readiness",
        \%namespace, \%first_location,
    );
    my $service_items = _form($items->[6], 'services', 1, undef, "$path/services");
    my @service_nodes = @{$service_items}[1 .. $#{$service_items}];
    _bounded_source_count(
        scalar(@service_nodes), 'service records',
        $LIMIT{service_records_per_lifecycle}, $items->[6], "$path/services",
    );
    my @services;
    for my $index (0 .. $#service_nodes) {
        push @services, _parse_service(
            $service_nodes[$index], "$path/services/$index",
            \%namespace, \%first_location, $fixture,
        );
    }
    my $stimulus = _parse_point(
        $items->[7], 'stimulus_start', "$path/stimulus_start",
        \%namespace, \%first_location,
    );
    my $completion = _parse_point(
        $items->[8], 'completion', "$path/completion",
        \%namespace, \%first_location,
    );
    my $drain = _parse_point(
        $items->[9], 'drain', "$path/drain",
        \%namespace, \%first_location,
    );
    my $shutdown = _parse_point(
        $items->[10], 'shutdown', "$path/shutdown",
        \%namespace, \%first_location,
    );
    my $finalize = _parse_point(
        $items->[11], 'finalize', "$path/finalize",
        \%namespace, \%first_location,
    );

    my $deadline_items = _form(
        $items->[12], 'deadlines', 2, undef, "$path/deadlines",
    );
    my @deadline_nodes = @{$deadline_items}[1 .. $#{$deadline_items}];
    _bounded_source_count(
        scalar(@deadline_nodes), 'deadline records',
        $LIMIT{deadline_records_per_lifecycle}, $items->[12], "$path/deadlines",
    );
    my @deadlines;
    for my $index (0 .. $#deadline_nodes) {
        my $record_path = "$path/deadlines/$index";
        my $record = _form($deadline_nodes[$index], 'deadline', 5, 5, $record_path);
        my $record_name = _identifier($record->[1], "$record_path/name");
        _declare(\%namespace, \%first_location, $record_name,
            $record->[1], "$record_path/name");
        my $from = _form($record->[2], 'from', 2, 2, "$record_path/from");
        my $until = _form($record->[3], 'until', 2, 2, "$record_path/until");
        my $within = _form($record->[4], 'within', 2, 2, "$record_path/within");
        my $max_cycles = _positive_integer($within->[1], "$record_path/within");
        _source_fail(
            'VIAL_LIMIT_ERROR', 'limit',
            "deadline '$record_name' exceeds the $LIMIT{logical_cycles}-cycle limit",
            _location($within->[1]), "$record_path/within",
        ) if Math::BigInt->new($max_cycles)->bcmp($LIMIT{logical_cycles}) > 0;
        push @deadlines, {
            name => $record_name, node => $deadline_nodes[$index],
            from_node => $from->[1], until_node => $until->[1],
            max_cycles => 0 + $max_cycles, path => $record_path,
        };
    }
    my $failure = _parse_failure(
        $items->[13], "$path/failure", \%namespace, \%first_location,
    );

    my $base = "$args->{family_semantic_id}::lifecycle::$name";
    my $entered_id = "${base}::milestone::entered";
    my $sealed_id = "${base}::milestone::result_sealed";
    for my $record (@dependencies) {
        $record->{semantic_id} = join('::', $base, 'dependency', $record->{name});
    }
    for my $record (@services) {
        $record->{semantic_id} = join('::', $base, 'service', $record->{name});
    }
    for my $record_kind (
        [$readiness, 'readiness'], [$stimulus, 'stimulus_start'],
        [$completion, 'completion'], [$drain, 'drain'],
        [$shutdown, 'shutdown'], [$finalize, 'finalize'],
    ) {
        my ($record, $kind) = @{$record_kind};
        $record->{semantic_id} = join('::', $base, $kind, $record->{name});
    }
    for my $record (@deadlines) {
        $record->{semantic_id} = join('::', $base, 'deadline', $record->{name});
    }
    $failure->{semantic_id} = join('::', $base, 'failure', $failure->{name});

    my %dependency = map { $_->{name} => $_->{semantic_id} } @dependencies;
    my %point = map { $_->{name} => $_->{semantic_id} }
        ($readiness, $stimulus, $completion, $drain, $shutdown, $finalize);
    my %service;
    for my $record (@services) {
        $service{$record->{name}} = {
            map { ($_ => "$record->{semantic_id}::milestone::$_") }
                qw(started ready quiescent stopped)
        };
    }
    my $condition_context = {
        lifecycle_name => $name,
        dependency => \%dependency,
        point => \%point,
        service => \%service,
        domain => {map { $_->{name} => $_->{semantic_id} }
            @{$fixture->{dut}{domains} || []}},
        entered_id => $entered_id,
        term_count => 0,
    };

    for my $record (@dependencies) {
        $record->{condition} = _condition(
            $record->{condition_node}, "$record->{path}/when", $condition_context, 1,
        );
    }
    for my $record (@services) {
        for my $kind (qw(start ready quiescent stop)) {
            my $source_node = $record->{"${kind}_condition_node"};
            $record->{"${kind}_additional"} = defined($source_node)
                ? _condition(
                    $source_node, "$record->{path}/${kind}_requires",
                    $condition_context, 1,
                ) : undef;
        }
    }
    for my $record ($readiness, $stimulus, $completion, $drain, $shutdown, $finalize) {
        $record->{additional_condition} = defined($record->{condition_node})
            ? _condition(
                $record->{condition_node}, "$record->{path}/requires",
                $condition_context, 1,
            ) : undef;
    }
    for my $record (@deadlines) {
        $record->{from} = _milestone(
            $record->{from_node}, "$record->{path}/from", $condition_context,
        );
        $record->{until} = _milestone(
            $record->{until_node}, "$record->{path}/until", $condition_context,
        );
    }

    my @dependency_ids = map { $_->{semantic_id} } @dependencies;
    my @service_ready = map { $service{$_->{name}}{ready} } @services;
    my @service_quiescent = map { $service{$_->{name}}{quiescent} } @services;
    my @service_stopped = map { $service{$_->{name}}{stopped} } @services;
    my %graph;
    _add_edges(\%graph, [$entered_id], $_->{semantic_id}) for @dependencies;
    for my $record (@dependencies) {
        _add_condition_edges(\%graph, $record->{condition}, $record->{semantic_id});
    }
    for my $record (@services) {
        my $milestone = $service{$record->{name}};
        _add_edges(\%graph, [$entered_id, @dependency_ids], $milestone->{started});
        _add_condition_edges(\%graph, $record->{start_additional}, $milestone->{started});
        _add_edges(\%graph, [$milestone->{started}], $milestone->{ready});
        _add_condition_edges(\%graph, $record->{ready_additional}, $milestone->{ready});
        _add_edges(\%graph, [$completion->{semantic_id}], $milestone->{quiescent});
        _add_condition_edges(\%graph, $record->{quiescent_additional}, $milestone->{quiescent});
        _add_edges(\%graph, [$shutdown->{semantic_id}], $milestone->{stopped});
        _add_condition_edges(\%graph, $record->{stop_additional}, $milestone->{stopped});
    }
    _add_edges(\%graph, [$entered_id, @dependency_ids, @service_ready], $readiness->{semantic_id});
    _add_condition_edges(\%graph, $readiness->{additional_condition}, $readiness->{semantic_id});
    _add_edges(\%graph, [$readiness->{semantic_id}], $stimulus->{semantic_id});
    _add_condition_edges(\%graph, $stimulus->{additional_condition}, $stimulus->{semantic_id});
    _add_edges(\%graph, [$stimulus->{semantic_id}], $completion->{semantic_id});
    _add_condition_edges(\%graph, $completion->{additional_condition}, $completion->{semantic_id});
    _add_edges(\%graph, [$completion->{semantic_id}, @service_quiescent], $drain->{semantic_id});
    _add_condition_edges(\%graph, $drain->{additional_condition}, $drain->{semantic_id});
    _add_edges(\%graph, [$drain->{semantic_id}], $shutdown->{semantic_id});
    _add_condition_edges(\%graph, $shutdown->{additional_condition}, $shutdown->{semantic_id});
    _add_edges(\%graph, [$shutdown->{semantic_id}, @service_stopped], $finalize->{semantic_id});
    _add_condition_edges(\%graph, $finalize->{additional_condition}, $finalize->{semantic_id});
    _assert_acyclic(\%graph, $node, $path);

    my $full_deadlines = 0;
    for my $record (@deadlines) {
        my $from_id = $record->{from}{reference_id};
        my $until_id = $record->{until}{reference_id};
        _source_fail(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            "deadline '$record->{name}' does not follow a monotone lifecycle path",
            _location($record->{node}), $record->{path},
        ) unless $from_id ne $until_id
            && _reachable(\%graph, $from_id, $until_id);
        ++$full_deadlines
            if $from_id eq $entered_id && $until_id eq $finalize->{semantic_id};
    }
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        'lifecycle requires exactly one full deadline from lifecycle entry through finalize',
        _location($items->[12]), "$path/deadlines",
    ) unless $full_deadlines == 1;

    my @records;
    push @records, map { +{
        %$_, kind => 'dependency', condition => $_->{condition},
        intrinsic_after => [],
        additional_after => _condition_references($_->{condition}), detail => {},
    } } @dependencies;
    for my $record (@services) {
        my $start = _all(
            _configured_condition(),
            map { _reference_condition('dependency_satisfied', $_) } @dependency_ids,
            _optional($record->{start_additional}),
        );
        my $ready = _all(
            _reference_condition('service_started', $service{$record->{name}}{started}),
            _optional($record->{ready_additional}),
        );
        my $quiescent = _all(
            _reference_condition('lifecycle_point', $completion->{semantic_id}),
            _terminal_condition('transactions_terminal'),
            _terminal_condition('scoreboards_empty'),
            _optional($record->{quiescent_additional}),
        );
        my $stop = _all(
            _reference_condition('lifecycle_point', $shutdown->{semantic_id}),
            _optional($record->{stop_additional}),
        );
        my @additional = map { @{_condition_references($_)} }
            grep { defined } @{$record}{qw(
                start_additional ready_additional quiescent_additional stop_additional
            )};
        push @records, {
            %{$record}, kind => 'service', condition => $start,
            intrinsic_after => [@dependency_ids],
            additional_after => _unique_ids(\@additional),
            detail => {
                target => 'fixture_background', cancellation => $record->{cancellation},
                start_condition => $start, ready_condition => $ready,
                quiescent_condition => $quiescent, stop_condition => $stop,
            },
        };
    }
    my @point_specs = (
        [$readiness, [@dependency_ids, @service_ready], [
            map { _reference_condition('dependency_satisfied', $_) } @dependency_ids,
            map { _reference_condition('service_ready', $_) } @service_ready,
        ]],
        [$stimulus, [$readiness->{semantic_id}], [
            _reference_condition('lifecycle_point', $readiness->{semantic_id}),
        ]],
        [$completion, [$stimulus->{semantic_id}], [
            _reference_condition('lifecycle_point', $stimulus->{semantic_id}),
            _terminal_condition('scenarios_terminal'),
        ]],
        [$drain, [$completion->{semantic_id}, @service_quiescent], [
            _reference_condition('lifecycle_point', $completion->{semantic_id}),
            _terminal_condition('transactions_terminal'),
            _terminal_condition('scoreboards_empty'),
            map { _reference_condition('service_quiescent', $_) } @service_quiescent,
        ]],
        [$shutdown, [$drain->{semantic_id}], [
            _reference_condition('lifecycle_point', $drain->{semantic_id}),
        ]],
        [$finalize, [$shutdown->{semantic_id}, @service_stopped], [
            _reference_condition('lifecycle_point', $shutdown->{semantic_id}),
            map { _reference_condition('service_stopped', $_) } @service_stopped,
        ]],
    );
    for my $spec (@point_specs) {
        my ($record, $intrinsic_ids, $intrinsic_conditions) = @{$spec};
        my @conditions = (@{$intrinsic_conditions},
            _optional($record->{additional_condition}));
        my $condition = _all(@conditions);
        push @records, {
            %{$record}, condition => $condition,
            intrinsic_after => $intrinsic_ids,
            additional_after => _condition_references($record->{additional_condition}),
            detail => {},
        };
    }
    push @records, map { +{
        %$_, kind => 'deadline', condition => undef,
        intrinsic_after => [$_->{from}{reference_id}], additional_after => [],
        detail => {
            from => $_->{from}, until => $_->{until},
            max_cycles => $_->{max_cycles},
            last_cycle_inclusive => JSON::PP::true,
        },
    } } @deadlines;
    push @records, {
        %{$failure}, kind => 'failure', condition => undef,
        intrinsic_after => [], additional_after => [],
        detail => {
            disposition => $failure->{disposition}, cleanup => $failure->{cleanup},
            cleanup_max_cycles => $failure->{cleanup_max_cycles},
            diagnostics => $failure->{diagnostics},
        },
    };
    _bounded_source_count(
        scalar(@records), 'expanded lifecycle records',
        $LIMIT{expanded_records_per_lifecycle}, $node, $path,
    );

    my @semantic_nodes;
    for my $rank (0 .. $#records) {
        my $record = $records[$rank];
        my $intrinsic = _unique_ids($record->{intrinsic_after});
        my %intrinsic = map { $_ => 1 } @{$intrinsic};
        my $additional = [grep { !$intrinsic{$_} }
            @{_unique_ids($record->{additional_after})}];
        push @semantic_nodes, _semantic_node({
            record => $record, rank => $rank,
            lifecycle_id => $base, fixture_id => $fixture->{semantic_id},
            domain_id => $domain->{semantic_id}, entered_id => $entered_id,
            sealed_id => $sealed_id, intrinsic_after => $intrinsic,
            additional_after => $additional,
        });
    }
    return \@semantic_nodes;
}

sub _parse_point {
    my ($node, $head, $path, $namespace, $locations) = @_;
    my $items = _form($node, $head, 2, 3, $path);
    my $name = _identifier($items->[1], "$path/name");
    _declare($namespace, $locations, $name, $items->[1], "$path/name");
    my $condition_node;
    if (@{$items} == 3) {
        my $requires = _form($items->[2], 'requires', 2, 2, "$path/requires");
        $condition_node = $requires->[1];
    }
    return {
        name => $name, node => $node, condition_node => $condition_node,
        path => $path, kind => $head,
    };
}

sub _parse_service {
    my ($node, $path, $namespace, $locations, $fixture) = @_;
    my $items = _form($node, 'service', 3, 8, $path);
    my $name = _identifier($items->[1], "$path/name");
    _declare($namespace, $locations, $name, $items->[1], "$path/name");
    my $target = _form($items->[2], 'target', 2, 2, "$path/target");
    my $target_name = _identifier($target->[1], "$path/target");
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse',
        "service target must be fixture_background, not '$target_name'",
        _location($target->[1]), "$path/target",
    ) unless $target_name eq 'fixture_background';
    my $background_count = scalar(@{$fixture->{instances}{model_instances} || []})
        + scalar(@{$fixture->{instances}{scoreboard_instances} || []})
        + scalar(@{$fixture->{coverage}{coverpoints} || []})
        + scalar(@{$fixture->{coverage}{crosses} || []});
    _source_fail(
        'VIAL_SEMANTIC_ERROR', 'semantic',
        "service '$name' targets an empty fixture_background aggregate",
        _location($node), $path,
    ) unless $background_count;

    my %rank = (
        start_requires => 0, ready_requires => 1, quiescent_requires => 2,
        stop_requires => 3, cancellation => 4,
    );
    my (%seen, %condition_node);
    my $last = -1;
    my $cancellation = 'cooperative';
    for my $offset (3 .. $#{$items}) {
        my $clause = $items->[$offset];
        my $head = _head($clause);
        _source_fail(
            'VIAL_PARSE_ERROR', 'parse',
            "unknown or reordered service clause '$head'",
            _location($clause), $path,
        ) unless exists($rank{$head}) && $rank{$head} > $last && !$seen{$head}++;
        $last = $rank{$head};
        my $clause_items = _form($clause, $head, 2, 2, "$path/$head");
        if ($head eq 'cancellation') {
            my $policy = _identifier($clause_items->[1], "$path/cancellation");
            _source_fail(
                'VIAL_PARSE_ERROR', 'parse',
                "service cancellation must be cooperative, not '$policy'",
                _location($clause_items->[1]), "$path/cancellation",
            ) unless $policy eq 'cooperative';
            $cancellation = $policy;
        }
        else {
            (my $kind = $head) =~ s/_requires\z//;
            $condition_node{"${kind}_condition_node"} = $clause_items->[1];
        }
    }
    for my $suffix (qw(started ready quiescent stopped)) {
        _declare($namespace, $locations, "${name}_$suffix", $items->[1], "$path/name");
    }
    return {
        name => $name, node => $node, path => $path,
        cancellation => $cancellation, %condition_node,
    };
}

sub _parse_failure {
    my ($node, $path, $namespace, $locations) = @_;
    my $items = _form($node, 'failure', 2, 6, $path);
    my $name = _identifier($items->[1], "$path/name");
    _declare($namespace, $locations, $name, $items->[1], "$path/name");
    my %rank = (disposition => 0, cleanup => 1, cleanup_within => 2, diagnostics => 3);
    my %seen;
    my $last = -1;
    my %result = (
        disposition => 'fail', cleanup => 'finalize',
        cleanup_max_cycles => 256, diagnostics => 'all',
    );
    for my $offset (2 .. $#{$items}) {
        my $clause = $items->[$offset];
        my $head = _head($clause);
        _source_fail(
            'VIAL_PARSE_ERROR', 'parse',
            "unknown or reordered failure clause '$head'",
            _location($clause), $path,
        ) unless exists($rank{$head}) && $rank{$head} > $last && !$seen{$head}++;
        $last = $rank{$head};
        my $clause_items = _form($clause, $head, 2, 2, "$path/$head");
        if ($head eq 'cleanup_within') {
            my $cycles = _positive_integer($clause_items->[1], "$path/$head");
            _source_fail(
                'VIAL_LIMIT_ERROR', 'limit',
                "failure cleanup exceeds the $LIMIT{logical_cycles}-cycle limit",
                _location($clause_items->[1]), "$path/$head",
            ) if Math::BigInt->new($cycles)->bcmp($LIMIT{logical_cycles}) > 0;
            $result{cleanup_max_cycles} = 0 + $cycles;
            next;
        }
        my $value = _identifier($clause_items->[1], "$path/$head");
        my %allowed = (
            disposition => {fail => 1}, cleanup => {finalize => 1},
            diagnostics => {first => 1, all => 1},
        );
        _source_fail(
            'VIAL_PARSE_ERROR', 'parse',
            "failure $head value '$value' is not supported",
            _location($clause_items->[1]), "$path/$head",
        ) unless $allowed{$head}{$value};
        $result{$head} = $value;
    }
    return {name => $name, node => $node, path => $path, %result};
}

sub _condition {
    my ($node, $path, $ctx, $depth) = @_;
    _source_fail(
        'VIAL_LIMIT_ERROR', 'limit',
        "condition exceeds the $LIMIT{condition_depth}-level nesting limit",
        _location($node), $path,
    ) if $depth > $LIMIT{condition_depth};
    ++$ctx->{term_count};
    _source_fail(
        'VIAL_LIMIT_ERROR', 'limit',
        "lifecycle conditions exceed the $LIMIT{condition_terms_per_lifecycle}-term limit",
        _location($node), $path,
    ) if $ctx->{term_count} > $LIMIT{condition_terms_per_lifecycle};
    my $items = _form($node, _head($node), 1, undef, $path);
    my $kind = _head($node);
    if ($kind eq 'all') {
        _source_fail(
            'VIAL_PARSE_ERROR', 'parse', 'all condition requires at least one operand',
            _location($node), $path,
        ) if @{$items} < 2;
        _source_fail(
            'VIAL_LIMIT_ERROR', 'limit',
            "all condition exceeds the $LIMIT{all_operands}-operand limit",
            _location($node), $path,
        ) if @{$items} - 1 > $LIMIT{all_operands};
        return {
            kind => 'all', reference_id => undef, domain_id => undef,
            operands => [map {
                _condition($items->[$_], "$path/operands/" . ($_ - 1), $ctx, $depth + 1)
            } 1 .. $#{$items}],
        };
    }
    my %zero = map { $_ => 1 } qw(
        configured scenarios_terminal transactions_terminal scoreboards_empty
    );
    return _terminal_condition($kind) if $zero{$kind} && @{$items} == 1;
    if ($kind eq 'reset_inactive') {
        _source_fail('VIAL_PARSE_ERROR', 'parse',
            'reset_inactive condition requires one domain identifier',
            _location($node), $path) unless @{$items} == 2;
        my $name = _identifier($items->[1], "$path/domain");
        _source_fail('VIAL_SEMANTIC_ERROR', 'resolve',
            "reset_inactive names unknown lifecycle fixture domain '$name'",
            _location($items->[1]), "$path/domain") unless $ctx->{domain}{$name};
        return {
            kind => 'reset_inactive', reference_id => undef,
            domain_id => $ctx->{domain}{$name}, operands => [],
        };
    }
    my %reference_kind = (
        dependency_satisfied => 'dependency', lifecycle_point => 'point',
        service_started => 'started', service_ready => 'ready',
        service_quiescent => 'quiescent', service_stopped => 'stopped',
    );
    if (exists $reference_kind{$kind}) {
        _source_fail('VIAL_PARSE_ERROR', 'parse',
            "$kind condition requires one identifier",
            _location($node), $path) unless @{$items} == 2;
        my $name = _identifier($items->[1], "$path/reference");
        my $reference_id;
        if ($kind eq 'dependency_satisfied') {
            $reference_id = $ctx->{dependency}{$name};
        }
        elsif ($kind eq 'lifecycle_point') {
            $reference_id = $ctx->{point}{$name};
        }
        else {
            $reference_id = $ctx->{service}{$name}{$reference_kind{$kind}}
                if $ctx->{service}{$name};
        }
        _source_fail('VIAL_SEMANTIC_ERROR', 'resolve',
            "$kind names unknown lifecycle record '$name'",
            _location($items->[1]), "$path/reference") unless $reference_id;
        return _reference_condition($kind, $reference_id);
    }
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', "unknown lifecycle condition '$kind'",
        _location($node), $path,
    );
}

sub _milestone {
    my ($node, $path, $ctx) = @_;
    my $kind = _head($node);
    if ($kind eq 'lifecycle_entered') {
        _form($node, $kind, 1, 1, $path);
        return _reference_condition($kind, $ctx->{entered_id});
    }
    my %allowed = map { $_ => 1 } qw(
        dependency_satisfied lifecycle_point service_started service_ready
        service_quiescent service_stopped
    );
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', "unknown lifecycle milestone '$kind'",
        _location($node), $path,
    ) unless $allowed{$kind};
    return _condition($node, $path, $ctx, 1);
}

sub _semantic_node {
    my ($args) = @_;
    my $record = $args->{record};
    my $kind = $record->{kind};
    my $semantic_id = $record->{semantic_id};
    my %effect_for = (
        readiness => ['ready'], service => [qw(service_start service_stop)],
        stimulus_start => ['stimulus_start'], completion => ['complete'],
        drain => ['drain'], shutdown => ['shutdown'], finalize => ['finalize'],
        deadline => ['deadline'], failure => ['failure'], dependency => [],
    );
    my %diagnostic_for = (
        service => 'VIAL_LIFECYCLE_SERVICE_ERROR',
        deadline => 'VIAL_LIFECYCLE_DEADLINE_EXPIRED',
        drain => 'VIAL_LIFECYCLE_DRAIN_INCOMPLETE',
        failure => 'VIAL_LIFECYCLE_CLEANUP_TIMEOUT',
    );
    my $result_type = 'type/vial_lifecycle_record_result_v1';
    my $payload = {
        schema => 'fsmgen.vial_lifecycle_control.v1', schema_version => 1,
        lifecycle_id => $args->{lifecycle_id}, fixture_id => $args->{fixture_id},
        domain_id => $args->{domain_id}, record_kind => $kind,
        record_id => $semantic_id, condition => _clone($record->{condition}),
        intrinsic_after => _clone($args->{intrinsic_after}),
        additional_after => _clone($args->{additional_after}),
        detail => _clone($record->{detail}),
    };
    return {
        schema => 'fsmgen.vial_semantic_family.v2', schema_version => 2,
        stage => 'semantic', semantic_id => $semantic_id,
        family_id => 'lifecycle_control', revision => 1,
        node_id => $semantic_id, node_kind => $kind,
        scope => {kind => 'fixture', owner_id => $args->{fixture_id}},
        lifetime => {
            start => $kind eq 'service' ? 'service_started' : 'lifecycle_entered',
            end => $kind eq 'service' ? 'service_stopped' : 'result_sealed',
            cancellation => $kind eq 'service' ? 'cooperative' : 'required',
        },
        order => {
            domain_id => $args->{domain_id}, phase => 'check', rank => $args->{rank},
            before => [], after => _unique_ids([
                @{$args->{intrinsic_after}}, @{$args->{additional_after}},
            ]),
        },
        ports => [
            {
                port_id => "${semantic_id}::port::fixture", name => 'fixture',
                direction => 'input', type_id => 'type/vial_fixture_ref_v1',
                cardinality => 'one', required => JSON::PP::true,
            },
            {
                port_id => "${semantic_id}::port::domain", name => 'domain',
                direction => 'input', type_id => 'type/vial_domain_ref_v1',
                cardinality => 'one', required => JSON::PP::true,
            },
            {
                port_id => "${semantic_id}::port::result", name => 'result',
                direction => 'output', type_id => $result_type,
                cardinality => 'one', required => JSON::PP::false,
            },
        ],
        effects => [map { +{
            effect_id => "${semantic_id}::effect::$_", kind => $_,
            target_id => $args->{fixture_id}, visibility => 'result',
        } } @{$effect_for{$kind}}],
        failure => {
            policy => 'fail_scope',
            diagnostic_code => $diagnostic_for{$kind}
                || 'VIAL_LIFECYCLE_DEADLINE_EXPIRED',
            scope => 'fixture',
        },
        result => {kind => 'lifecycle_record', type_id => $result_type,
            required => JSON::PP::true},
        semantic_path => $record->{path}, source_span => _location($record->{node}),
        payload => $payload,
    };
}

sub build_vial_lifecycle_execution_records {
    my ($args) = @_;
    _internal_invocation(
        $args, [qw(semantic execution bridge)], 'lifecycle execution construction',
    );
    my ($semantic, $execution, $bridge) = @{$args}{qw(semantic execution bridge)};
    die "lifecycle execution construction requires plain semantic, execution, and bridge hashes\n"
        unless ref($semantic) eq 'HASH' && !blessed($semantic)
            && ref($execution) eq 'HASH' && !blessed($execution)
            && ref($bridge) eq 'HASH' && !blessed($bridge);
    my $selected_fixture = $execution->{fixture}{fixture_id};
    my @semantic_nodes;
    for my $package (@{$semantic->{packages} || []}) {
        for my $family (@{$package->{intent_families} || []}) {
            next unless $family->{family_id} eq 'lifecycle_control';
            push @semantic_nodes, grep {
                $_->{scope}{owner_id} eq $selected_fixture
            } @{$family->{nodes}};
        }
    }

    my $unit_binding = $execution->{bindings}{unit};
    my ($unit_index) = grep {
        $bridge->{units}[$_]{unit_id} eq $unit_binding->{unit_id}
    } 0 .. $#{$bridge->{units} || []};
    _execution_fail(
        'VIAL_BIND_REFERENCE_ERROR', 'binding',
        'selected lifecycle fixture has no bridge unit fact', '/semantic_families',
        @semantic_nodes ? $semantic_nodes[0]{source_span} : undef,
    ) if @semantic_nodes && !defined($unit_index);
    my %execution_domain = map { $_->{semantic_id} => $_ }
        @{$execution->{domains} || []};
    my %bridge_domain_index = map {
        ($bridge->{domains}[$_]{domain_id} => $_)
    } 0 .. $#{$bridge->{domains} || []};

    my @records;
    for my $index (0 .. $#semantic_nodes) {
        my $node = $semantic_nodes[$index];
        my $domain = $execution_domain{$node->{order}{domain_id}};
        _execution_fail(
            'VIAL_BIND_REFERENCE_ERROR', 'binding',
            'lifecycle coordination domain is unavailable in the selected execution',
            "/semantic_families/$index/semantic/order/domain_id",
            $node->{source_span},
        ) unless $domain;
        my $domain_index = $bridge_domain_index{$domain->{domain_id}};
        _execution_fail(
            'VIAL_BIND_REFERENCE_ERROR', 'binding',
            'lifecycle coordination domain has no bridge domain fact',
            "/semantic_families/$index/semantic/order/domain_id",
            $node->{source_span},
        ) unless defined($domain_index);
        my %port = map { $_->{name} => $_ } @{$node->{ports}};
        my $bindings = [
            {
                port_id => $port{fixture}{port_id},
                binding_id => $unit_binding->{binding_id},
                bridge_fact_paths => ["/units/$unit_index"],
                type_relation_ids => ['type-relation/lifecycle_fixture_identity_v1'],
            },
            {
                port_id => $port{domain}{port_id},
                binding_id => $domain->{binding_id},
                bridge_fact_paths => ["/domains/$domain_index"],
                type_relation_ids => ['type-relation/lifecycle_domain_identity_v1'],
            },
        ];
        my $execution_path = "/semantic_families/$index";
        my $source_map = {
            schema => 'fsmgen.vial_source_map.v2', schema_version => 2,
            source_map_id => undef, semantic_id => $node->{semantic_id},
            semantic_path => $node->{semantic_path},
            bridge_fact_paths => ["/units/$unit_index", "/domains/$domain_index"],
            execution_paths => [$execution_path], plan_paths => [], result_paths => [],
            source_locations => [_clone($node->{source_span})],
        };
        _seal_source_map($source_map);
        my $record = {
            schema => 'fsmgen.vial_execution_family.v2', schema_version => 2,
            stage => 'execution', semantic => _clone($node), bindings => $bindings,
            operation_ids => _operation_ids($node),
            required_capabilities => [@CAPABILITIES], source_map => $source_map,
        };
        push @records, validate_vial_semantic_family_stage('execution', $record);
    }
    return validate_vial_semantic_family_collection('execution', \@records);
}

sub _operation_ids {
    my ($node) = @_;
    my %steps = (
        dependency => [qw(evaluate commit)],
        service => [qw(start ready quiescent stop)],
        readiness => [qw(evaluate commit)],
        stimulus_start => [qw(evaluate commit)],
        completion => [qw(evaluate commit)],
        drain => [qw(evaluate commit)],
        shutdown => [qw(evaluate commit)],
        finalize => [qw(evaluate commit)],
        deadline => [qw(start check close)],
        failure => [qw(latch cancel cleanup seal)],
    );
    return [map { "operation/$node->{semantic_id}/$_" }
        @{$steps{$node->{node_kind}}}];
}

sub validate_vial_lifecycle_result {
    my ($record, $plan_records) = @_;
    _exact_hash($record, \@LIFECYCLE_RESULT_KEYS, 'lifecycle result');
    die "lifecycle result schema is invalid\n"
        unless ($record->{schema} || '') eq 'fsmgen.vial_lifecycle_result.v1'
            && _integer($record->{schema_version}, 1, 1);
    _id($record->{lifecycle_id}, 'lifecycle_id');
    _id($record->{fixture_id}, 'fixture_id');
    _id($record->{domain_id}, 'domain_id');
    my $expected = _expected_result_contract($record, $plan_records);
    die "lifecycle result status is invalid\n"
        unless ($record->{status} || '') =~ /\A(?:pass|fail|timeout|cancelled|error)\z/;
    my $entered = _optional_time($record->{entered_at}, $record->{domain_id});
    my $dependencies = _result_array(
        $record->{dependency_results}, \@DEPENDENCY_RESULT_KEYS,
        'dependency result', sub {
            die "dependency result status is invalid\n"
                unless ($_[0]{status} || '') =~ /\A(?:pending|satisfied)\z/;
            $_[0]{reached_at} = _optional_time($_[0]{reached_at}, $record->{domain_id});
        },
    );
    _assert_exact_result_ids(
        $dependencies, $expected->{by_kind}{dependency}, 'dependency results',
    );
    my $point = sub {
        my ($value, $label) = @_;
        _exact_hash($value, \@POINT_RESULT_KEYS, $label);
        _id($value->{record_id}, "$label record_id");
        die "$label status is invalid\n"
            unless ($value->{status} || '') =~ /\A(?:pending|reached|failed|cancelled)\z/;
        my $copy = _clone($value);
        $copy->{reached_at} = _optional_time($value->{reached_at}, $record->{domain_id});
        return $copy;
    };
    my $services = _result_array(
        $record->{service_results}, \@SERVICE_RESULT_KEYS, 'service result', sub {
            die "service result status is invalid\n"
                unless ($_[0]{status} || '') =~ /\A(?:pending|started|ready|quiescent|stopped|failed|cancelled)\z/;
            $_[0]{$_} = _optional_time($_[0]{$_}, $record->{domain_id})
                for qw(started_at ready_at quiescent_at stopped_at);
            $_[0]{diagnostic_ids} = _id_array($_[0]{diagnostic_ids}, 'service diagnostic_ids');
        },
    );
    _assert_exact_result_ids(
        $services, $expected->{by_kind}{service}, 'service results',
    );
    my $deadlines = _result_array(
        $record->{deadline_results}, \@DEADLINE_RESULT_KEYS, 'deadline result', sub {
            die "deadline result status is invalid\n"
                unless ($_[0]{status} || '') =~ /\A(?:pending|met|expired|cancelled)\z/;
            $_[0]{started_at} = _optional_time($_[0]{started_at}, $record->{domain_id});
            $_[0]{ended_at} = _optional_time($_[0]{ended_at}, $record->{domain_id});
            die "deadline max_cycles is invalid\n"
                unless _integer($_[0]{max_cycles}, 1, $LIMIT{logical_cycles});
            _boolean($_[0]{last_cycle_inclusive}, 'deadline last_cycle_inclusive');
            die "deadline result must retain inclusive last-cycle semantics\n"
                unless $_[0]{last_cycle_inclusive};
        },
    );
    die "lifecycle result requires at least one deadline result\n"
        unless @{$deadlines};
    _assert_exact_result_ids(
        $deadlines, $expected->{by_kind}{deadline}, 'deadline results',
    );
    for my $deadline (@{$deadlines}) {
        my $expected_cycles = $expected->{plan_by_id}{$deadline->{record_id}}
            {semantic}{payload}{detail}{max_cycles};
        die "deadline result changes its planned max_cycles\n"
            unless $deadline->{max_cycles} == $expected_cycles;
        _assert_deadline_interval($deadline);
    }
    _exact_hash($record->{failure_result}, \@FAILURE_RESULT_KEYS, 'failure result');
    my $failure = _clone($record->{failure_result});
    _id($failure->{record_id}, 'failure result record_id');
    die "failure cleanup_status is invalid\n"
        unless ($failure->{cleanup_status} || '') =~ /\A(?:not_required|pending|finalized|expired)\z/;
    _optional_id($failure->{primary_diagnostic_id}, 'primary_diagnostic_id');
    die "cleanup_deadline_cycle is invalid\n"
        if defined($failure->{cleanup_deadline_cycle})
            && !_integer($failure->{cleanup_deadline_cycle}, 0, $LIMIT{logical_cycles});
    $failure->{diagnostic_ids} = _id_array($failure->{diagnostic_ids}, 'failure diagnostic_ids');
    my $readiness = $point->(
        $record->{readiness_result}, 'readiness result',
    );
    my $stimulus_start = $point->(
        $record->{stimulus_start_result}, 'stimulus-start result',
    );
    my $completion = $point->(
        $record->{completion_result}, 'completion result',
    );
    my $drain = $point->($record->{drain_result}, 'drain result');
    my $shutdown = $point->($record->{shutdown_result}, 'shutdown result');
    my $finalize = $point->($record->{finalize_result}, 'finalize result');
    my %point_result = (
        readiness => $readiness, stimulus_start => $stimulus_start,
        completion => $completion, drain => $drain, shutdown => $shutdown,
        finalize => $finalize,
    );
    for my $kind (sort keys %point_result) {
        my $expected_id = $expected->{by_kind}{$kind}[0];
        die "$kind result does not match its planned record\n"
            unless $point_result{$kind}{record_id} eq $expected_id;
    }
    die "failure result does not match its planned record\n"
        unless $failure->{record_id} eq $expected->{by_kind}{failure}[0];
    _assert_pass_complete({
        status => $record->{status}, entered_at => $entered,
        dependencies => $dependencies, services => $services,
        points => [$readiness, $stimulus_start, $completion, $drain,
            $shutdown, $finalize],
        deadlines => $deadlines, failure => $failure,
    });
    die "lifecycle result source_map must be a non-empty array\n"
        unless ref($record->{source_map}) eq 'ARRAY' && !blessed($record->{source_map})
            && @{$record->{source_map}};
    my $source_map = [map {
        _result_source_map($_, $record->{lifecycle_id})
    } @{$record->{source_map}}];
    _assert_complete_result_source_maps($source_map, $expected);
    return _clone({
        %{$record}, schema_version => 1, entered_at => $entered,
        dependency_results => $dependencies,
        readiness_result => $readiness,
        service_results => $services,
        stimulus_start_result => $stimulus_start,
        completion_result => $completion,
        drain_result => $drain,
        shutdown_result => $shutdown,
        finalize_result => $finalize,
        deadline_results => $deadlines, failure_result => $failure,
        source_map => $source_map,
    });
}

sub _expected_result_contract {
    my ($result, $plan_records) = @_;
    die "lifecycle result validation requires a non-empty plan-record array\n"
        unless ref($plan_records) eq 'ARRAY' && !blessed($plan_records)
            && @{$plan_records};
    my (%by_kind, %plan_by_id);
    for my $record (@{$plan_records}) {
        my $plan = validate_vial_semantic_family_stage('plan', $record);
        my $semantic = $plan->{semantic};
        die "lifecycle result plan context contains another semantic family\n"
            unless $semantic->{family_id} eq 'lifecycle_control'
                && $semantic->{revision} == 1;
        my $payload = $semantic->{payload};
        die "lifecycle result identity disagrees with its plan context\n"
            unless $payload->{lifecycle_id} eq $result->{lifecycle_id}
                && $payload->{fixture_id} eq $result->{fixture_id}
                && $payload->{domain_id} eq $result->{domain_id};
        my $id = $semantic->{semantic_id};
        die "lifecycle result plan context repeats a semantic identity\n"
            if $plan_by_id{$id};
        $plan_by_id{$id} = $plan;
        push @{$by_kind{$semantic->{node_kind}}}, $id;
    }
    my %allowed = map { $_ => 1 } qw(
        dependency service readiness stimulus_start completion drain shutdown
        finalize deadline failure
    );
    my @unknown = sort grep { !$allowed{$_} } keys %by_kind;
    die "lifecycle result plan context contains unknown record kind '$unknown[0]'\n"
        if @unknown;
    for my $kind (qw(readiness stimulus_start completion drain shutdown finalize failure)) {
        die "lifecycle result plan context requires exactly one $kind record\n"
            unless @{$by_kind{$kind} || []} == 1;
    }
    die "lifecycle result plan context requires at least one deadline record\n"
        unless @{$by_kind{deadline} || []};
    $by_kind{dependency} ||= [];
    $by_kind{service} ||= [];
    return {by_kind => \%by_kind, plan_by_id => \%plan_by_id};
}

sub _assert_exact_result_ids {
    my ($results, $expected_ids, $label) = @_;
    my @actual = sort map { $_->{record_id} } @{$results};
    my @expected = sort @{$expected_ids};
    die "$label do not exactly cover the planned records\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
}

sub _assert_complete_result_source_maps {
    my ($source_maps, $expected) = @_;
    my %seen;
    for my $source_map (@{$source_maps}) {
        my $id = $source_map->{semantic_id};
        my $plan = $expected->{plan_by_id}{$id};
        die "lifecycle result source map names an unplanned semantic identity\n"
            unless $plan;
        die "lifecycle result source map repeats a semantic identity\n"
            if $seen{$id}++;
        my $planned = $plan->{source_map};
        for my $key (qw(
            semantic_path bridge_fact_paths execution_paths plan_paths
            source_locations
        )) {
            die "lifecycle result source map changes planned $key\n"
                unless _canonical_json($source_map->{$key})
                    eq _canonical_json($planned->{$key});
        }
    }
    my @actual = sort keys %seen;
    my @expected = sort keys %{$expected->{plan_by_id}};
    die "lifecycle result source maps do not exactly cover the planned records\n"
        unless _canonical_json(\@actual) eq _canonical_json(\@expected);
}

sub _assert_pass_complete {
    my ($result) = @_;
    return unless $result->{status} eq 'pass';
    die "passing lifecycle result has no lifecycle-entry time\n"
        unless defined($result->{entered_at});
    die "passing lifecycle result retains an unsatisfied dependency\n"
        if grep { $_->{status} ne 'satisfied' || !defined($_->{reached_at}) }
            @{$result->{dependencies}};
    die "passing lifecycle result retains an incomplete service\n"
        if grep {
            $_->{status} ne 'stopped'
                || grep { !defined($_) } @{$_}{qw(
                    started_at ready_at quiescent_at stopped_at
                )}
        }
            @{$result->{services}};
    die "passing lifecycle result retains an unreached lifecycle point\n"
        if grep { $_->{status} ne 'reached' || !defined($_->{reached_at}) }
            @{$result->{points}};
    die "passing lifecycle result retains an unmet deadline\n"
        if grep {
            $_->{status} ne 'met'
                || !defined($_->{started_at}) || !defined($_->{ended_at})
        } @{$result->{deadlines}};
    my $failure = $result->{failure};
    die "passing lifecycle result retains a failure cause\n"
        if defined($failure->{primary_diagnostic_id})
            || defined($failure->{cleanup_deadline_cycle})
            || $failure->{cleanup_status} ne 'not_required'
            || @{$failure->{diagnostic_ids}};
    _assert_pass_chronology($result);
}

sub _assert_deadline_interval {
    my ($deadline) = @_;
    return unless $deadline->{status} eq 'met';
    die "met deadline result requires start and end times\n"
        unless defined($deadline->{started_at}) && defined($deadline->{ended_at});
    die "met deadline result ends before it starts\n"
        if _time_compare($deadline->{ended_at}, $deadline->{started_at}) < 0;
    my $last_cycle = Math::BigInt->new($deadline->{started_at}{cycle})
        ->badd($deadline->{max_cycles})->bdec;
    die "met deadline result exceeds its inclusive planned window\n"
        if Math::BigInt->new($deadline->{ended_at}{cycle})->bcmp($last_cycle) > 0;
}

sub _assert_pass_chronology {
    my ($result) = @_;
    my $entered = $result->{entered_at};
    _assert_not_before($_->{reached_at}, $entered,
        'dependency satisfaction precedes lifecycle entry')
        for @{$result->{dependencies}};
    for my $service (@{$result->{services}}) {
        _assert_not_before($service->{started_at}, $entered,
            'service start precedes lifecycle entry');
        _assert_not_before($service->{started_at}, $_->{reached_at},
            'service start precedes dependency satisfaction')
            for @{$result->{dependencies}};
        _assert_not_before($service->{ready_at}, $service->{started_at},
            'service readiness precedes service start');
    }
    my ($readiness, $stimulus, $completion, $drain, $shutdown, $finalize)
        = @{$result->{points}};
    _assert_not_before($readiness->{reached_at}, $_->{reached_at},
        'readiness precedes dependency satisfaction')
        for @{$result->{dependencies}};
    _assert_not_before($readiness->{reached_at}, $_->{ready_at},
        'readiness precedes service readiness')
        for @{$result->{services}};
    _assert_not_before($stimulus->{reached_at}, $readiness->{reached_at},
        'stimulus start precedes readiness');
    _assert_not_before($completion->{reached_at}, $stimulus->{reached_at},
        'completion precedes stimulus start');
    for my $service (@{$result->{services}}) {
        _assert_not_before($service->{quiescent_at}, $completion->{reached_at},
            'service quiescence precedes completion');
        _assert_not_before($drain->{reached_at}, $service->{quiescent_at},
            'drain precedes service quiescence');
    }
    _assert_not_before($drain->{reached_at}, $completion->{reached_at},
        'drain precedes completion');
    _assert_not_before($shutdown->{reached_at}, $drain->{reached_at},
        'shutdown precedes drain');
    for my $service (@{$result->{services}}) {
        _assert_not_before($service->{stopped_at}, $shutdown->{reached_at},
            'service stop precedes shutdown');
        _assert_not_before($finalize->{reached_at}, $service->{stopped_at},
            'finalize precedes service stop');
    }
    _assert_not_before($finalize->{reached_at}, $shutdown->{reached_at},
        'finalize precedes shutdown');
}

sub _assert_not_before {
    my ($later, $earlier, $message) = @_;
    die "$message\n" if _time_compare($later, $earlier) < 0;
}

sub _time_compare {
    my ($left, $right) = @_;
    return $left->{cycle} <=> $right->{cycle}
        || $left->{ordinal} <=> $right->{ordinal};
}

sub _result_source_map {
    my ($value, $lifecycle_id) = @_;
    _exact_hash($value, \@SOURCE_MAP_KEYS, 'lifecycle result source map');
    die "lifecycle result source-map schema is invalid\n"
        unless ($value->{schema} || '') eq 'fsmgen.vial_source_map.v2'
            && _integer($value->{schema_version}, 2, 2);
    _id($value->{source_map_id}, 'lifecycle result source_map_id');
    _id($value->{semantic_id}, 'lifecycle result source-map semantic_id');
    die "lifecycle result source map names an unrelated semantic identity\n"
        unless index($value->{semantic_id}, "${lifecycle_id}::") == 0;
    my $semantic_path = _path($value->{semantic_path}, 'semantic_path');
    my $bridge = _path_array($value->{bridge_fact_paths}, 'bridge_fact_paths');
    my $execution = _path_array($value->{execution_paths}, 'execution_paths');
    my $plan = _path_array($value->{plan_paths}, 'plan_paths');
    my $result = _path_array($value->{result_paths}, 'result_paths');
    die "lifecycle result source map has incomplete phase paths\n"
        unless @{$execution} && @{$plan} && @{$result};
    die "lifecycle result source_locations must be a non-empty array\n"
        unless ref($value->{source_locations}) eq 'ARRAY'
            && !blessed($value->{source_locations}) && @{$value->{source_locations}};
    my $locations = [map { _result_location($_) } @{$value->{source_locations}}];
    my $validated = {
        schema => $value->{schema}, schema_version => 2,
        source_map_id => undef, semantic_id => $value->{semantic_id},
        semantic_path => $semantic_path, bridge_fact_paths => $bridge,
        execution_paths => $execution, plan_paths => $plan,
        result_paths => $result, source_locations => $locations,
    };
    my $expected = 'source-map/' . sha256_hex(_canonical_json($validated));
    die "lifecycle result source_map_id is not content-derived\n"
        unless $value->{source_map_id} eq $expected;
    $validated->{source_map_id} = $expected;
    return $validated;
}

sub _result_location {
    my ($value) = @_;
    _exact_hash($value, \@LOCATION_KEYS, 'lifecycle result source location');
    die "lifecycle result source_name must be repository-relative\n"
        unless defined($value->{source_name}) && !ref($value->{source_name})
            && length($value->{source_name})
            && $value->{source_name} !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' }
                split(m{/}, $value->{source_name}, -1);
    for my $key (qw(start_byte end_byte_exclusive start_line start_column end_line end_column)) {
        die "lifecycle result source location $key is invalid\n"
            unless _integer($value->{$key}, 0, $LIMIT{logical_cycles});
    }
    die "lifecycle result source location byte interval is inverted\n"
        if $value->{end_byte_exclusive} < $value->{start_byte};
    die "lifecycle result source location lines and columns are one-based\n"
        unless $value->{start_line} && $value->{start_column}
            && $value->{end_line} && $value->{end_column};
    return _clone({map {
        $_ => $_ eq 'source_name' ? $value->{$_} : 0 + $value->{$_}
    } @LOCATION_KEYS});
}

sub _result_array {
    my ($values, $keys, $label, $validate) = @_;
    die "$label collection must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    my (%id, @result);
    for my $value (@{$values}) {
        _exact_hash($value, $keys, $label);
        my $copy = _clone($value);
        _id($copy->{record_id}, "$label record_id");
        die "$label record_id is duplicated\n" if $id{$copy->{record_id}}++;
        $validate->($copy);
        push @result, $copy;
    }
    return \@result;
}

sub _optional_time {
    my ($value, $domain_id) = @_;
    return undef unless defined $value;
    _exact_hash($value, \@TIME_KEYS, 'lifecycle logical time');
    die "lifecycle logical time changes coordination domain\n"
        unless $value->{domain_id} eq $domain_id;
    die "lifecycle logical time cycle is invalid\n"
        unless _integer($value->{cycle}, 0, $LIMIT{logical_cycles});
    die "lifecycle logical time phase must be check\n"
        unless ($value->{phase} || '') eq 'check';
    die "lifecycle logical time ordinal is invalid\n"
        unless _integer($value->{ordinal}, 0, $LIMIT{expanded_records_per_catalog});
    return _clone({%{$value}, cycle => 0 + $value->{cycle}, ordinal => 0 + $value->{ordinal}});
}

sub _declare {
    my ($namespace, $locations, $name, $node, $path) = @_;
    if ($namespace->{$name}++) {
        _source_fail(
            'VIAL_SEMANTIC_ERROR', 'semantic',
            "lifecycle identifier '$name' is duplicated",
            _location($node), $path,
            [{message => 'first declaration', source_location => _clone($locations->{$name})}],
        );
    }
    $locations->{$name} = _location($node);
}

sub _configured_condition {
    return _terminal_condition('configured');
}

sub _terminal_condition {
    my ($kind) = @_;
    return {kind => $kind, reference_id => undef, domain_id => undef, operands => []};
}

sub _reference_condition {
    my ($kind, $id) = @_;
    return {kind => $kind, reference_id => $id, domain_id => undef, operands => []};
}

sub _all {
    my @conditions = grep { defined } @_;
    return {kind => 'all', reference_id => undef, domain_id => undef,
        operands => _clone(\@conditions)};
}

sub _optional {
    return defined($_[0]) ? ($_[0]) : ();
}

sub _condition_references {
    my ($condition) = @_;
    return [] unless defined $condition;
    my @ids;
    push @ids, $condition->{reference_id} if defined $condition->{reference_id};
    push @ids, @{_condition_references($_)} for @{$condition->{operands}};
    return _unique_ids(\@ids);
}

sub _add_condition_edges {
    my ($graph, $condition, $target) = @_;
    _add_edges($graph, _condition_references($condition), $target)
        if defined $condition;
}

sub _add_edges {
    my ($graph, $sources, $target) = @_;
    $graph->{$target} ||= {};
    for my $source (@{$sources}) {
        $graph->{$source} ||= {};
        $graph->{$source}{$target} = 1;
    }
}

sub _assert_acyclic {
    my ($graph, $node, $path) = @_;
    my (%active, %done);
    my $visit;
    $visit = sub {
        my ($id) = @_;
        return 1 if $active{$id};
        return 0 if $done{$id};
        $active{$id} = 1;
        for my $next (sort keys %{$graph->{$id} || {}}) {
            return 1 if $visit->($next);
        }
        delete $active{$id};
        $done{$id} = 1;
        return 0;
    };
    for my $id (sort keys %{$graph}) {
        if ($visit->($id)) {
            _source_fail(
                'VIAL_SEMANTIC_ERROR', 'semantic',
                'lifecycle dependency graph contains a cycle',
                _location($node), $path,
            );
        }
    }
}

sub _reachable {
    my ($graph, $start, $target) = @_;
    my %seen = ($start => 1);
    my @todo = ($start);
    while (@todo) {
        my $current = shift @todo;
        return 1 if $current eq $target;
        for my $next (sort keys %{$graph->{$current} || {}}) {
            next if $seen{$next}++;
            push @todo, $next;
        }
    }
    return 0;
}

sub _seal_source_map {
    my ($source_map) = @_;
    my $identity = _clone($source_map);
    $identity->{source_map_id} = undef;
    $source_map->{source_map_id} = 'source-map/'
        . sha256_hex(_canonical_json($identity));
}

sub _unique_ids {
    my ($values) = @_;
    my %seen;
    return [grep { defined($_) && !$seen{$_}++ } @{$values || []}];
}

sub _bounded_source_count {
    my ($count, $label, $limit, $node, $path) = @_;
    _source_fail(
        'VIAL_LIMIT_ERROR', 'limit', "$label exceed the $limit-entry limit",
        _location($node), $path,
    ) if $count > $limit;
}

sub _form {
    my ($node, $expected_head, $minimum, $maximum, $path) = @_;
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected a list form', _location($node), $path,
    ) unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'list';
    my $items = $node->{items};
    my $actual = _head($node);
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse',
        "expected '$expected_head' form, found '$actual'", _location($node), $path,
    ) unless $actual eq $expected_head;
    if (@{$items} < $minimum || (defined($maximum) && @{$items} > $maximum)) {
        my $expected = defined($maximum) && $minimum == $maximum
            ? "$minimum items" : "at least $minimum items";
        _source_fail(
            'VIAL_PARSE_ERROR', 'parse',
            "$expected_head form requires $expected", _location($node), $path,
        );
    }
    return $items;
}

sub _head {
    my ($node) = @_;
    return '' unless ref($node) eq 'HASH'
        && ($node->{node_kind} || '') eq 'list'
        && ref($node->{items}) eq 'ARRAY' && @{$node->{items}};
    return _atom($node->{items}[0]);
}

sub _identifier {
    my ($node, $path) = @_;
    my $value = _atom($node);
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected an unqualified identifier',
        _location($node), $path,
    ) unless ($node->{atom_kind} || '') eq 'identifier'
        && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    _source_fail(
        'VIAL_LIMIT_ERROR', 'limit',
        "identifier exceeds the $LIMIT{identifier_bytes}-byte component limit",
        _location($node), $path,
    ) if bytes::length($value) > $LIMIT{identifier_bytes};
    return $value;
}

sub _positive_integer {
    my ($node, $path) = @_;
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected a literal positive integer',
        _location($node), $path,
    ) unless ($node->{atom_kind} || '') eq 'integer';
    my $raw = $node->{value};
    my $value = $raw =~ /\A0[bB]/ ? Math::BigInt->from_bin($raw)
        : $raw =~ /\A0[xX]/ ? Math::BigInt->from_hex($raw)
        : Math::BigInt->new($raw);
    _source_fail(
        'VIAL_PARSE_ERROR', 'parse', 'expected a literal positive integer',
        _location($node), $path,
    ) if $value->is_nan || !$value->is_pos;
    return $value->bstr;
}

sub _atom {
    my ($node) = @_;
    return '' unless ref($node) eq 'HASH' && ($node->{node_kind} || '') eq 'atom';
    return defined($node->{value}) ? $node->{value} : '';
}

sub _location {
    my ($node) = @_;
    return _clone($node->{span})
        if ref($node) eq 'HASH' && ref($node->{span}) eq 'HASH';
    return {
        source_name => 'vial/input.vial', start_byte => 0, end_byte_exclusive => 0,
        start_line => 1, start_column => 1, end_line => 1, end_column => 1,
    };
}

sub _source_fail {
    my ($code, $phase, $message, $location, $path, $notes) = @_;
    $message =~ s/[\r\n]+/ /g;
    die bless({
        schema => 'fsmgen.vial_diagnostic.v2', schema_version => 2,
        severity => 'error', code => $code, phase => $phase, message => $message,
        semantic_path => $path, source_location => _clone($location),
        notes => _clone($notes || []),
    }, 'FSM::VIAL::Diagnostic');
}

sub _execution_fail {
    my ($code, $phase, $message, $path, $location) = @_;
    die bless({code => $code, phase => $phase, message => $message,
        semantic_path => $path, source_location => _clone($location)},
        'FSM::VIAL::LifecycleControl::ExecutionDiagnostic');
}

sub _internal_invocation {
    my ($args, $keys, $label) = @_;
    die "$label requires one closed unblessed hash\n"
        unless ref($args) eq 'HASH' && !blessed($args);
    _exact_hash($args, $keys, $label);
}

sub _exact_hash {
    my ($value, $keys, $label) = @_;
    die "$label must be one unblessed hash\n"
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    die "$label has unknown key '$unknown[0]'\n" if @unknown;
    die "$label is missing key '$missing[0]'\n" if @missing;
}

sub _id {
    my ($value, $label) = @_;
    die "$label must be a stable non-empty identity\n"
        unless defined($value) && !ref($value) && length($value)
            && $value !~ /[\s\x00]/;
}

sub _optional_id {
    my ($value, $label) = @_;
    _id($value, $label) if defined $value;
}

sub _id_array {
    my ($values, $label) = @_;
    die "$label must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    my %seen;
    return [map {
        _id($_, $label);
        die "$label repeats an identity\n" if $seen{$_}++;
        $_;
    } @{$values}];
}

sub _path {
    my ($value, $label) = @_;
    die "lifecycle result $label must be an absolute semantic path\n"
        unless defined($value) && !ref($value) && $value =~ m{\A/}
            && $value !~ /[\x00\r\n]/ && $value !~ /~(?:[^01]|\z)/;
    return $value;
}

sub _path_array {
    my ($values, $label) = @_;
    die "lifecycle result $label must be an unblessed array\n"
        unless ref($values) eq 'ARRAY' && !blessed($values);
    my %seen;
    return [map {
        my $path = _path($_, $label);
        die "lifecycle result $label repeats a path\n" if $seen{$path}++;
        $path;
    } @{$values}];
}

sub _boolean {
    my ($value, $label) = @_;
    return if blessed($value) && $value->isa('JSON::PP::Boolean');
    die "$label must be a JSON boolean\n"
        unless defined($value) && !ref($value) && ($value eq '0' || $value eq '1');
}

sub _integer {
    my ($value, $minimum, $maximum) = @_;
    return 0 unless defined($value) && !ref($value)
        && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
    return $value >= $minimum && $value <= $maximum;
}

sub _canonical_json {
    return JSON::PP->new->canonical->utf8->encode($_[0]);
}

sub _clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    my $type = ref($value) ? (reftype($value) || '') : '';
    return {map { $_ => _clone($value->{$_}) } sort keys %{$value}}
        if $type eq 'HASH';
    return [map { _clone($_) } @{$value}] if $type eq 'ARRAY';
    die "lifecycle contract contains unsupported reference type '$type'\n"
        if ref($value);
    return $value;
}

1;
