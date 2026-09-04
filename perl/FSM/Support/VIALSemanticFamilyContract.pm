package FSM::Support::VIALSemanticFamilyContract;

use strict;
use warnings;

use bytes ();
use Exporter 'import';
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Scalar::Util qw(blessed reftype);

our @EXPORT_OK = qw(
    build_vial_semantic_family_contract
    project_vial_semantic_family_plan
    validate_vial_semantic_family_chain
    validate_vial_semantic_family_collection
    validate_vial_semantic_family_stage
    vial_semantic_family_contract_keys
);

my @CONTRACT_KEYS = qw(
    schema_version status contract_source stage_schemas semantic_family_keys
    semantic_node_keys scope_keys lifetime_keys order_keys port_keys
    effect_keys failure_keys result_keys stage_keys binding_keys
    result_stage_keys output_keys observed_effect_keys source_map_keys limits
    explicit_nonclaims
);
my @SEMANTIC_FAMILY_KEYS = qw(
    semantic_id family_id revision semantic_path source_span nodes
);
my @SEMANTIC_NODE_KEYS = qw(
    schema schema_version stage semantic_id family_id revision node_id node_kind
    scope lifetime order ports effects failure result semantic_path source_span
    payload
);
my @SCOPE_KEYS = qw(kind owner_id);
my @LIFETIME_KEYS = qw(start end cancellation);
my @ORDER_KEYS = qw(domain_id phase rank before after);
my @PORT_KEYS = qw(port_id name direction type_id cardinality required);
my @EFFECT_KEYS = qw(effect_id kind target_id visibility);
my @FAILURE_KEYS = qw(policy diagnostic_code scope);
my @RESULT_KEYS = qw(kind type_id required);
my @STAGE_KEYS = qw(
    schema schema_version stage semantic bindings operation_ids
    required_capabilities source_map
);
my @RESULT_STAGE_KEYS = (@STAGE_KEYS, qw(status outputs observed_effects diagnostic_ids));
my @BINDING_KEYS = qw(port_id binding_id bridge_fact_paths type_relation_ids);
my @OUTPUT_KEYS = qw(port_id type_id value);
my @OBSERVED_EFFECT_KEYS = qw(effect_id outcome target_id);
my @SOURCE_MAP_KEYS = qw(
    schema schema_version source_map_id semantic_id semantic_path
    bridge_fact_paths execution_paths plan_paths result_paths source_locations
);
my @LOCATION_KEYS = qw(
    source_name start_byte end_byte_exclusive start_line start_column
    end_line end_column
);
my %STAGE_SCHEMA = (
    semantic => 'fsmgen.vial_semantic_family.v2',
    binding => 'fsmgen.vial_semantic_family_binding.v2',
    execution => 'fsmgen.vial_execution_family.v2',
    plan => 'fsmgen.vial_plan_family.v2',
    result => 'fsmgen.vial_result_family.v2',
);
my %LIMIT = (
    families_per_package => 256,
    nodes_per_family => 4_096,
    ports_per_node => 256,
    effects_per_node => 256,
    order_edges_per_node => 256,
    bindings_per_node => 256,
    operations_per_node => 4_096,
    capabilities_per_node => 256,
    outputs_per_node => 256,
    observed_effects_per_node => 4_096,
    diagnostics_per_node => 256,
    source_paths_per_node => 4_096,
    source_locations_per_node => 256,
    payload_depth_per_node => 64,
    payload_values_per_node => 4_096,
    payload_bytes_per_node => 262_144,
);

sub vial_semantic_family_contract_keys {
    return [@CONTRACT_KEYS];
}

sub build_vial_semantic_family_contract {
    return _clone({
        schema_version => 1,
        status => 'private_v2_common_envelope_and_registry_shipped_no_implemented_family',
        contract_source => __PACKAGE__,
        stage_schemas => {%STAGE_SCHEMA, source_map => 'fsmgen.vial_source_map.v2'},
        semantic_family_keys => [@SEMANTIC_FAMILY_KEYS],
        semantic_node_keys => [@SEMANTIC_NODE_KEYS],
        scope_keys => [@SCOPE_KEYS],
        lifetime_keys => [@LIFETIME_KEYS],
        order_keys => [@ORDER_KEYS],
        port_keys => [@PORT_KEYS],
        effect_keys => [@EFFECT_KEYS],
        failure_keys => [@FAILURE_KEYS],
        result_keys => [@RESULT_KEYS],
        stage_keys => [@STAGE_KEYS],
        binding_keys => [@BINDING_KEYS],
        result_stage_keys => [@RESULT_STAGE_KEYS],
        output_keys => [@OUTPUT_KEYS],
        observed_effect_keys => [@OBSERVED_EFFECT_KEYS],
        source_map_keys => [@SOURCE_MAP_KEYS],
        limits => {%LIMIT},
        explicit_nonclaims => [qw(
            backend_adapter backend_emission compatibility_adapter
            complete_result_manifest family_grammar family_implementation
            migration parity public_v2_tooling runtime_support
            support_classification
        )],
    });
}

sub project_vial_semantic_family_plan {
    my ($record, $plan_path) = @_;
    my $execution = validate_vial_semantic_family_stage('execution', $record);
    _trace_path($plan_path, 'semantic-family plan path');
    my $projected = _clone($execution);
    $projected->{schema} = $STAGE_SCHEMA{plan};
    $projected->{stage} = 'plan';
    $projected->{source_map}{plan_paths} = [$plan_path];
    my $identity = _clone($projected->{source_map});
    $identity->{source_map_id} = undef;
    $projected->{source_map}{source_map_id} =
        'source-map/' . sha256_hex(_canonical_json($identity));
    return validate_vial_semantic_family_stage('plan', $projected);
}

sub validate_vial_semantic_family_collection {
    my ($stage, $records) = @_;
    _fail("unknown semantic-family collection stage '$stage'")
        unless defined($stage)
            && ($stage eq 'semantic_family' || exists($STAGE_SCHEMA{$stage}));
    _fail('semantic-family collection must be an unblessed array')
        unless ref($records) eq 'ARRAY' && !blessed($records);
    if ($stage eq 'semantic_family') {
        _limit(
            'families_per_package', scalar(@{$records}),
            'SemanticIR intent-family collection',
        );
        my @validated = map { _validate_family($_) } @{$records};
        my (%family_id, %semantic_id);
        for my $family (@validated) {
            _fail("semantic-family collection repeats family_id '$family->{family_id}'")
                if $family_id{$family->{family_id}}++;
            _fail("semantic-family collection repeats semantic_id '$family->{semantic_id}'")
                if $semantic_id{$family->{semantic_id}}++;
        }
        return \@validated;
    }
    _limit('nodes_per_family', scalar(@{$records}), 'semantic-family collection');
    my @validated = map {
        validate_vial_semantic_family_stage($stage, $_)
    } @{$records};
    my %semantic_id;
    for my $record (@validated) {
        my $id = $record->{semantic}{semantic_id};
        _fail("semantic-family collection repeats semantic_id '$id'")
            if $semantic_id{$id}++;
    }
    return \@validated;
}

sub validate_vial_semantic_family_stage {
    my ($stage, $record) = @_;
    _fail("unknown semantic-family stage '$stage'")
        unless defined($stage) && exists($STAGE_SCHEMA{$stage});
    if ($stage eq 'semantic') {
        return _validate_semantic_node($record);
    }

    my $keys = $stage eq 'result' ? \@RESULT_STAGE_KEYS : \@STAGE_KEYS;
    _exact_hash($record, $keys, "$stage semantic-family record");
    _fail("$stage semantic-family schema is invalid")
        unless $record->{schema} eq $STAGE_SCHEMA{$stage}
            && _integer($record->{schema_version}, 2, 2)
            && $record->{stage} eq $stage;
    my $semantic = _validate_semantic_node($record->{semantic});
    my $bindings = _bindings($record->{bindings}, $semantic);
    my $operation_ids = _id_array(
        $record->{operation_ids}, 'operation_ids', $LIMIT{operations_per_node},
    );
    my $capabilities = _sorted_id_array(
        $record->{required_capabilities}, 'required_capabilities',
        $LIMIT{capabilities_per_node},
    );
    _fail('binding-stage operation_ids must be empty')
        if $stage eq 'binding' && @{$operation_ids};
    my $source_map = _source_map(
        $record->{source_map}, $semantic, $bindings, $stage,
    );

    my $validated = {
        schema => $record->{schema}, schema_version => 2, stage => $stage,
        semantic => $semantic, bindings => $bindings,
        operation_ids => $operation_ids,
        required_capabilities => $capabilities,
        source_map => $source_map,
    };
    if ($stage eq 'result') {
        _fail('result semantic-family status is invalid')
            unless defined($record->{status}) && !ref($record->{status})
                && $record->{status} =~ /\A(?:pass|fail|timeout|cancelled|unsupported|error)\z/;
        $validated->{status} = $record->{status};
        $validated->{outputs} = _outputs($record->{outputs}, $semantic);
        $validated->{observed_effects} = _observed_effects(
            $record->{observed_effects}, $semantic,
        );
        $validated->{diagnostic_ids} = _id_array(
            $record->{diagnostic_ids}, 'diagnostic_ids',
            $LIMIT{diagnostics_per_node},
        );
        _fail('passing semantic-family result must not carry diagnostics')
            if $record->{status} eq 'pass' && @{$validated->{diagnostic_ids}};
        _fail('passing semantic-family result omits its required typed output')
            if $record->{status} eq 'pass' && $semantic->{result}{required}
                && !grep {
                    $_->{type_id} eq $semantic->{result}{type_id}
                } @{$validated->{outputs}};
        my %observed = map { $_->{effect_id} => 1 }
            @{$validated->{observed_effects}};
        for my $effect (@{$semantic->{effects}}) {
            next unless $effect->{visibility} eq 'result'
                && !$observed{$effect->{effect_id}};
            _fail("passing semantic-family result omits result-visible effect '$effect->{effect_id}'");
        }
    }
    return _clone($validated);
}

sub validate_vial_semantic_family_chain {
    my ($chain) = @_;
    _exact_hash($chain, [qw(semantic binding execution plan result)],
        'semantic-family chain');
    my $semantic = validate_vial_semantic_family_stage('semantic', $chain->{semantic});
    my %stage;
    $stage{$_} = validate_vial_semantic_family_stage($_, $chain->{$_})
        for qw(binding execution plan result);
    my $semantic_json = _canonical_json($semantic);
    for my $name (qw(binding execution plan result)) {
        _fail("$name semantic-family record changes semantic meaning")
            unless _canonical_json($stage{$name}{semantic}) eq $semantic_json;
    }
    my $binding_json = _canonical_json($stage{binding}{bindings});
    for my $name (qw(execution plan result)) {
        _fail("$name semantic-family record changes binding meaning")
            unless _canonical_json($stage{$name}{bindings}) eq $binding_json;
    }
    _fail('plan semantic-family record changes execution operation identity')
        unless _canonical_json($stage{plan}{operation_ids})
            eq _canonical_json($stage{execution}{operation_ids});
    _fail('result semantic-family record changes execution operation identity')
        unless _canonical_json($stage{result}{operation_ids})
            eq _canonical_json($stage{execution}{operation_ids});
    _fail('plan semantic-family record changes required capabilities')
        unless _canonical_json($stage{plan}{required_capabilities})
            eq _canonical_json($stage{execution}{required_capabilities});
    _fail('result semantic-family record changes required capabilities')
        unless _canonical_json($stage{result}{required_capabilities})
            eq _canonical_json($stage{execution}{required_capabilities});
    my %execution_capability = map { $_ => 1 }
        @{$stage{execution}{required_capabilities}};
    _fail('execution semantic-family record loses a binding capability')
        if grep { !$execution_capability{$_} }
            @{$stage{binding}{required_capabilities}};
    _trace_progression(\%stage);
    return _clone({semantic => $semantic, %stage});
}

sub _validate_family {
    my ($record) = @_;
    _exact_hash($record, \@SEMANTIC_FAMILY_KEYS, 'SemanticIR intent-family record');
    _id($record->{semantic_id}, 'family semantic_id');
    _identifier($record->{family_id}, 'family_id');
    _integer($record->{revision}, 1, 2_147_483_647)
        or _fail('family revision must be a positive bounded integer');
    _path($record->{semantic_path}, 'family semantic_path');
    my $span = _location($record->{source_span});
    _fail('family nodes must be an unblessed array')
        unless ref($record->{nodes}) eq 'ARRAY' && !blessed($record->{nodes});
    _fail('family nodes must contain at least one typed semantic node')
        unless @{$record->{nodes}};
    _limit('nodes_per_family', scalar(@{$record->{nodes}}), 'family nodes');
    my @nodes = map { _validate_semantic_node($_) } @{$record->{nodes}};
    my (%node_id, %semantic_id);
    for my $node (@nodes) {
        _fail('family node repeats node_id') if $node_id{$node->{node_id}}++;
        _fail('family node repeats semantic_id')
            if $semantic_id{$node->{semantic_id}}++;
        _fail('family node contradicts containing family identity')
            unless $node->{family_id} eq $record->{family_id}
                && $node->{revision} == $record->{revision}
                && index($node->{semantic_path}, $record->{semantic_path} . '/') == 0;
        _fail('family node source span falls outside its family source span')
            unless $node->{source_span}{source_name} eq $span->{source_name}
                && $node->{source_span}{start_byte} >= $span->{start_byte}
                && $node->{source_span}{end_byte_exclusive}
                    <= $span->{end_byte_exclusive};
    }
    return _clone({%{$record}, revision => 0 + $record->{revision},
        source_span => $span, nodes => \@nodes});
}

sub _validate_semantic_node {
    my ($record) = @_;
    _exact_hash($record, \@SEMANTIC_NODE_KEYS, 'semantic-family semantic record');
    _fail('semantic-family semantic schema is invalid')
        unless $record->{schema} eq $STAGE_SCHEMA{semantic}
            && _integer($record->{schema_version}, 2, 2)
            && $record->{stage} eq 'semantic';
    _id($record->{semantic_id}, 'semantic_id');
    _identifier($record->{family_id}, 'family_id');
    _integer($record->{revision}, 1, 2_147_483_647)
        or _fail('semantic-family revision must be a positive bounded integer');
    _id($record->{node_id}, 'node_id');
    _identifier($record->{node_kind}, 'node_kind');
    _path($record->{semantic_path}, 'semantic_path');
    my $span = _location($record->{source_span});
    my $scope = _scope($record->{scope});
    my $lifetime = _lifetime($record->{lifetime});
    my $order = _order($record->{order});
    my $ports = _ports($record->{ports});
    my $effects = _effects($record->{effects});
    my $failure = _failure($record->{failure});
    my $result = _result_contract($record->{result});
    _fail('semantic-family payload must be one unblessed hash')
        unless ref($record->{payload}) eq 'HASH' && !blessed($record->{payload});
    _bounded_plain($record->{payload}, 'payload', 1);
    return _clone({
        schema => $record->{schema}, schema_version => 2, stage => 'semantic',
        semantic_id => $record->{semantic_id}, family_id => $record->{family_id},
        revision => 0 + $record->{revision}, node_id => $record->{node_id},
        node_kind => $record->{node_kind}, scope => $scope,
        lifetime => $lifetime, order => $order, ports => $ports,
        effects => $effects, failure => $failure, result => $result,
        semantic_path => $record->{semantic_path}, source_span => $span,
        payload => _clone($record->{payload}),
    });
}

sub _scope {
    my ($value) = @_;
    _exact_hash($value, \@SCOPE_KEYS, 'semantic-family scope');
    _fail('semantic-family scope kind is invalid')
        unless defined($value->{kind}) && !ref($value->{kind})
            && $value->{kind} =~ /\A(?:catalog|package|fixture|scenario|fiber)\z/;
    _id($value->{owner_id}, 'scope owner_id');
    return _clone($value);
}

sub _lifetime {
    my ($value) = @_;
    _exact_hash($value, \@LIFETIME_KEYS, 'semantic-family lifetime');
    _identifier($value->{start}, 'lifetime start');
    _identifier($value->{end}, 'lifetime end');
    _fail('semantic-family lifetime cancellation is invalid')
        unless defined($value->{cancellation}) && !ref($value->{cancellation})
            && $value->{cancellation} =~ /\A(?:forbidden|cooperative|required)\z/;
    _fail('semantic-family lifetime must have distinct start and end seams')
        if $value->{start} eq $value->{end};
    return _clone($value);
}

sub _order {
    my ($value) = @_;
    _exact_hash($value, \@ORDER_KEYS, 'semantic-family order');
    _id($value->{domain_id}, 'order domain_id');
    _identifier($value->{phase}, 'order phase');
    _integer($value->{rank}, 0, 2_147_483_647)
        or _fail('semantic-family order rank must be a bounded nonnegative integer');
    my $before = _id_array($value->{before}, 'order before', $LIMIT{order_edges_per_node});
    my $after = _id_array($value->{after}, 'order after', $LIMIT{order_edges_per_node});
    my %before = map { $_ => 1 } @{$before};
    _fail('semantic-family order repeats an identity across before and after')
        if grep { $before{$_} } @{$after};
    return _clone({%{$value}, rank => 0 + $value->{rank}, before => $before, after => $after});
}

sub _ports {
    my ($records) = @_;
    _array($records, 'semantic-family ports');
    _limit('ports_per_node', scalar(@{$records}), 'semantic-family ports');
    my (%id, %name);
    return [map {
        _exact_hash($_, \@PORT_KEYS, 'semantic-family port');
        _id($_->{port_id}, 'port_id');
        _identifier($_->{name}, 'port name');
        _fail('semantic-family port direction is invalid')
            unless ($_->{direction} // '') =~ /\A(?:input|output|inout)\z/;
        _id($_->{type_id}, 'port type_id');
        _fail('semantic-family port cardinality is invalid')
            unless ($_->{cardinality} // '') =~ /\A(?:one|optional|many)\z/;
        _boolean($_->{required}, 'port required');
        _fail('semantic-family port identity or name is duplicated')
            if $id{$_->{port_id}}++ || $name{$_->{name}}++;
        _clone($_);
    } @{$records}];
}

sub _effects {
    my ($records) = @_;
    _array($records, 'semantic-family effects');
    _limit('effects_per_node', scalar(@{$records}), 'semantic-family effects');
    my %id;
    return [map {
        _exact_hash($_, \@EFFECT_KEYS, 'semantic-family effect');
        _id($_->{effect_id}, 'effect_id');
        _identifier($_->{kind}, 'effect kind');
        _id($_->{target_id}, 'effect target_id');
        _fail('semantic-family effect visibility is invalid')
            unless ($_->{visibility} // '') =~ /\A(?:internal|observable|result)\z/;
        _fail('semantic-family effect identity is duplicated') if $id{$_->{effect_id}}++;
        _clone($_);
    } @{$records}];
}

sub _failure {
    my ($value) = @_;
    _exact_hash($value, \@FAILURE_KEYS, 'semantic-family failure');
    _fail('semantic-family failure policy is invalid')
        unless ($value->{policy} // '') =~ /\A(?:reject|fail_node|fail_scope|cancel_scope)\z/;
    _fail('semantic-family diagnostic code is invalid')
        unless ($value->{diagnostic_code} // '') =~ /\AVIAL_[A-Z0-9_]+\z/;
    _fail('semantic-family failure scope is invalid')
        unless ($value->{scope} // '') =~ /\A(?:node|fiber|scenario|fixture|catalog)\z/;
    return _clone($value);
}

sub _result_contract {
    my ($value) = @_;
    _exact_hash($value, \@RESULT_KEYS, 'semantic-family result contract');
    _identifier($value->{kind}, 'result kind');
    _id($value->{type_id}, 'result type_id');
    _boolean($value->{required}, 'result required');
    return _clone($value);
}

sub _bindings {
    my ($records, $semantic) = @_;
    _array($records, 'semantic-family bindings');
    _limit('bindings_per_node', scalar(@{$records}), 'semantic-family bindings');
    my %port = map { $_->{port_id} => $_ } @{$semantic->{ports}};
    my %bound;
    my @validated = map {
        _exact_hash($_, \@BINDING_KEYS, 'semantic-family binding');
        _fail("semantic-family binding names unknown port '$_->{port_id}'")
            unless $port{$_->{port_id}};
        _id($_->{binding_id}, 'binding_id');
        _fail('semantic-family port is bound more than once') if $bound{$_->{port_id}}++;
        my $bridge = _path_array($_->{bridge_fact_paths}, 'bridge_fact_paths');
        my $relations = _id_array($_->{type_relation_ids}, 'type_relation_ids', 256);
        _fail('semantic-family binding has no bridge fact path') unless @{$bridge};
        _fail('semantic-family binding has no type relation proof')
            unless @{$relations};
        _clone({%{$_}, bridge_fact_paths => $bridge, type_relation_ids => $relations});
    } @{$records};
    _fail("required semantic-family port '$_->{port_id}' is unbound")
        for grep { $_->{required} && !$bound{$_->{port_id}} } @{$semantic->{ports}};
    return \@validated;
}

sub _source_map {
    my ($value, $semantic, $bindings, $stage) = @_;
    _exact_hash($value, \@SOURCE_MAP_KEYS, 'semantic-family source map');
    _fail('semantic-family source-map schema is invalid')
        unless $value->{schema} eq 'fsmgen.vial_source_map.v2'
            && _integer($value->{schema_version}, 2, 2);
    _id($value->{source_map_id}, 'source_map_id');
    _fail('semantic-family source map changes semantic identity or path')
        unless $value->{semantic_id} eq $semantic->{semantic_id}
            && $value->{semantic_path} eq $semantic->{semantic_path};
    my $bridge = _path_array($value->{bridge_fact_paths}, 'bridge_fact_paths');
    my (%bridge_seen, @binding_bridge);
    for my $binding (@{$bindings}) {
        for my $path (@{$binding->{bridge_fact_paths}}) {
            push @binding_bridge, $path unless $bridge_seen{$path}++;
        }
    }
    _fail('semantic-family source map does not match binding bridge facts')
        unless _canonical_json($bridge) eq _canonical_json(\@binding_bridge);
    my $execution = _path_array($value->{execution_paths}, 'execution_paths');
    my $plan = _path_array($value->{plan_paths}, 'plan_paths');
    my $result = _path_array($value->{result_paths}, 'result_paths');
    _fail('binding semantic-family source map contains downstream paths')
        if $stage eq 'binding' && (@{$execution} || @{$plan} || @{$result});
    _fail('execution semantic-family source map has no execution path')
        if $stage eq 'execution' && !@{$execution};
    _fail('execution semantic-family source map contains later paths')
        if $stage eq 'execution' && (@{$plan} || @{$result});
    _fail('plan semantic-family source map has incomplete phase paths')
        if $stage eq 'plan' && (!@{$execution} || !@{$plan} || @{$result});
    _fail('result semantic-family source map has incomplete phase paths')
        if $stage eq 'result' && (!@{$execution} || !@{$plan} || !@{$result});
    _array($value->{source_locations}, 'source_locations');
    _fail('semantic-family source map must retain at least one source location')
        unless @{$value->{source_locations}};
    _limit(
        'source_locations_per_node', scalar(@{$value->{source_locations}}),
        'semantic-family source locations',
    );
    my @locations = map { _location($_) } @{$value->{source_locations}};
    _fail('semantic-family source map loses the authored source span')
        unless _canonical_json($locations[0]) eq _canonical_json($semantic->{source_span});
    my $validated = _clone({%{$value}, schema_version => 2,
        bridge_fact_paths => $bridge, execution_paths => $execution,
        plan_paths => $plan, result_paths => $result,
        source_locations => \@locations});
    my $source_map_id = $validated->{source_map_id};
    $validated->{source_map_id} = undef;
    my $expected = 'source-map/' . sha256_hex(_canonical_json($validated));
    _fail('semantic-family source_map_id is not content-derived')
        unless $source_map_id eq $expected;
    $validated->{source_map_id} = $source_map_id;
    return $validated;
}

sub _outputs {
    my ($records, $semantic) = @_;
    _array($records, 'semantic-family outputs');
    _limit('outputs_per_node', scalar(@{$records}), 'semantic-family outputs');
    my %port = map { $_->{port_id} => $_ } @{$semantic->{ports}};
    my %seen;
    return [map {
        _exact_hash($_, \@OUTPUT_KEYS, 'semantic-family output');
        _fail('semantic-family output names an unavailable output port')
            unless $port{$_->{port_id}}
                && $port{$_->{port_id}}{direction} =~ /\A(?:output|inout)\z/
                && $port{$_->{port_id}}{type_id} eq $_->{type_id};
        _fail('semantic-family output port is duplicated') if $seen{$_->{port_id}}++;
        _bounded_plain($_->{value}, 'output value', 0);
        _clone($_);
    } @{$records}];
}

sub _observed_effects {
    my ($records, $semantic) = @_;
    _array($records, 'semantic-family observed effects');
    _limit('observed_effects_per_node', scalar(@{$records}), 'semantic-family observed effects');
    my %effect = map { $_->{effect_id} => $_ } @{$semantic->{effects}};
    return [map {
        _exact_hash($_, \@OBSERVED_EFFECT_KEYS, 'semantic-family observed effect');
        _fail('semantic-family observed effect changes declared effect identity')
            unless $effect{$_->{effect_id}}
                && $effect{$_->{effect_id}}{target_id} eq $_->{target_id};
        _fail('semantic-family observed effect outcome is invalid')
            unless ($_->{outcome} // '') =~ /\A(?:applied|skipped|failed|cancelled)\z/;
        _clone($_);
    } @{$records}];
}

sub _trace_progression {
    my ($stage) = @_;
    my @names = qw(binding execution plan result);
    my $bridge = _canonical_json($stage->{binding}{source_map}{bridge_fact_paths});
    for my $name (@names[1 .. $#names]) {
        _fail("$name semantic-family source map changes bridge fact paths")
            unless _canonical_json($stage->{$name}{source_map}{bridge_fact_paths}) eq $bridge;
    }
    my $execution = _canonical_json($stage->{execution}{source_map}{execution_paths});
    for my $name (qw(plan result)) {
        _fail("$name semantic-family source map changes execution paths")
            unless _canonical_json($stage->{$name}{source_map}{execution_paths}) eq $execution;
    }
    _fail('result semantic-family source map changes plan paths')
        unless _canonical_json($stage->{result}{source_map}{plan_paths})
            eq _canonical_json($stage->{plan}{source_map}{plan_paths});
}

sub _location {
    my ($value) = @_;
    _exact_hash($value, \@LOCATION_KEYS, 'source location');
    _relative_source_name($value->{source_name});
    for my $key (qw(start_byte end_byte_exclusive start_line start_column end_line end_column)) {
        _integer($value->{$key}, 0, 2_147_483_647)
            or _fail("source location $key must be a bounded nonnegative integer");
    }
    _fail('source location byte interval is inverted')
        if $value->{end_byte_exclusive} < $value->{start_byte};
    _fail('source location lines and columns are one-based')
        if !$value->{start_line} || !$value->{start_column}
            || !$value->{end_line} || !$value->{end_column};
    return _clone({map { $_ => $_ eq 'source_name' ? $value->{$_} : 0 + $value->{$_} } @LOCATION_KEYS});
}

sub _trace_path {
    my ($value, $label) = @_;
    _fail("$label must be an absolute semantic path")
        unless defined($value) && !ref($value) && $value =~ m{\A/}
            && $value !~ /[\x00\r\n]/ && $value !~ /~(?:[^01]|\z)/;
    return $value;
}

sub _path { return _trace_path(@_); }

sub _path_array {
    my ($values, $label) = @_;
    _array($values, $label);
    _limit('source_paths_per_node', scalar(@{$values}), $label);
    my %seen;
    return [map {
        _trace_path($_, $label);
        _fail("$label repeats a path") if $seen{$_}++;
        $_;
    } @{$values}];
}

sub _id_array {
    my ($values, $label, $limit) = @_;
    _array($values, $label);
    _fail("$label exceeds its $limit-entry limit") if @{$values} > $limit;
    my %seen;
    return [map {
        _id($_, $label);
        _fail("$label repeats an identity") if $seen{$_}++;
        $_;
    } @{$values}];
}

sub _sorted_id_array {
    my ($values, $label, $limit) = @_;
    my $result = _id_array($values, $label, $limit);
    _fail("$label must be lexically sorted")
        unless _canonical_json($result) eq _canonical_json([sort @{$result}]);
    return $result;
}

sub _id {
    my ($value, $label) = @_;
    _fail("$label must be a stable non-empty identity")
        unless defined($value) && !ref($value) && length($value)
            && $value !~ /[\s\x00]/;
    return $value;
}

sub _identifier {
    my ($value, $label) = @_;
    _fail("$label must be an unqualified identifier")
        unless defined($value) && !ref($value)
            && $value =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
    return $value;
}

sub _relative_source_name {
    my ($value) = @_;
    _fail('source_name must be repository-relative')
        unless defined($value) && !ref($value) && length($value)
            && $value !~ m{(?:\A/|\A~|\A[A-Za-z]:|://|\\|\x00)}
            && !grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split(m{/}, $value, -1);
}

sub _boolean {
    my ($value, $label) = @_;
    return if blessed($value) && $value->isa('JSON::PP::Boolean');
    _fail("$label must be a JSON boolean")
        unless defined($value) && !ref($value) && ($value eq '0' || $value eq '1');
}

sub _integer {
    my ($value, $minimum, $maximum) = @_;
    return 0 unless defined($value) && !ref($value) && $value =~ /\A(?:0|[1-9][0-9]*)\z/;
    return $value >= $minimum && $value <= $maximum;
}

sub _array {
    my ($value, $label) = @_;
    _fail("$label must be an unblessed array")
        unless ref($value) eq 'ARRAY' && !blessed($value);
}

sub _limit {
    my ($key, $count, $label) = @_;
    _fail("$label exceeds the $LIMIT{$key}-entry $key limit")
        if $count > $LIMIT{$key};
}

sub _exact_hash {
    my ($value, $keys, $label) = @_;
    _fail("$label must be one unblessed hash")
        unless ref($value) eq 'HASH' && !blessed($value);
    my %expected = map { $_ => 1 } @{$keys};
    my @unknown = sort grep { !$expected{$_} } keys %{$value};
    my @missing = grep { !exists($value->{$_}) } @{$keys};
    _fail("$label has unknown key '$unknown[0]'") if @unknown;
    _fail("$label is missing key '$missing[0]'") if @missing;
}

sub _bounded_plain {
    my ($value, $label, $reject_parser_residue) = @_;
    my $count = 0;
    _bounded_plain_value(
        $value, $label, 0, \$count, $reject_parser_residue,
    );
    _limit('payload_values_per_node', $count, $label);
    _limit(
        'payload_bytes_per_node', bytes::length(_canonical_json($value)),
        $label,
    );
}

sub _bounded_plain_value {
    my ($value, $label, $depth, $count, $reject_parser_residue) = @_;
    _fail("$label exceeds the $LIMIT{payload_depth_per_node}-level payload depth limit")
        if $depth > $LIMIT{payload_depth_per_node};
    ++${$count};
    _limit('payload_values_per_node', ${$count}, $label);
    return unless ref($value);
    return if blessed($value) && $value->isa('JSON::PP::Boolean');
    _fail("$label contains blessed data") if blessed($value);
    my $type = reftype($value) || '';
    if ($type eq 'HASH') {
        _fail("$label contains a lexer/parser node")
            if $reject_parser_residue
                && (exists($value->{node_kind}) || exists($value->{atom_kind})
                    || exists($value->{raw}));
        _bounded_plain_value(
            $value->{$_}, "$label/$_", $depth + 1, $count,
            $reject_parser_residue,
        ) for sort keys %{$value};
        return;
    }
    if ($type eq 'ARRAY') {
        _bounded_plain_value(
            $value->[$_], "$label/$_", $depth + 1, $count,
            $reject_parser_residue,
        ) for 0 .. $#{$value};
        return;
    }
    _fail("$label contains unsupported reference type '$type'");
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
    _fail('semantic-family envelope contains a non-JSON reference') if ref($value);
    return $value;
}

sub _fail {
    die "VIAL semantic-family contract: $_[0]\n";
}

1;
