#!/usr/bin/env perl

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use File::Spec;
use FindBin;
use JSON::PP ();
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'perl');

use FSM::Support::VIALSemanticFamilyContract qw(
    build_vial_semantic_family_contract
    project_vial_semantic_family_plan
    validate_vial_semantic_family_chain
    validate_vial_semantic_family_collection
    validate_vial_semantic_family_stage
    vial_semantic_family_contract_keys
);
use FSM::VIAL::Backend::ResultProducer;
use FSM::VIAL::Backend::SVPortableVerilator;
use FSM::VIAL::ExecutionBuilderV2;
use FSM::VIAL::ExecutionIR;
use FSM::VIAL::ExecutionReport;
use FSM::VIAL::Parser;
use FSM::VIAL::PlanBuilder;

my $repo_root = File::Spec->catdir($FindBin::Bin, '..');
my $vial_name = 'vial/ahb_subordinate_base_output_arbitration.vial';
my $hial_name = 'ppif/ahb_lite_subordinate.ppif';
my $v1_source = slurp_raw(repo_path($vial_name));
my $v2_source = to_v2($v1_source);
my $hial_source = slurp_raw(repo_path($hial_name));
my $json = JSON::PP->new->canonical->utf8;

sub repo_path {
    my ($relative) = @_;
    return File::Spec->catfile($repo_root, split m{/}, $relative);
}

sub slurp_raw {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Cannot close $path: $!";
    return $text;
}

sub to_v2 {
    my ($source) = @_;
    my $converted = $source;
    $converted =~ s/\(version 1\)/\(version 2\)/
        or die 'version selector was not found';
    $converted =~ s/\n    \(fixtures/\n    (intents)\n    (fixtures/
        or die 'fixture section was not found';
    return $converted;
}

sub plan_args {
    my ($semantic_ir, $version) = @_;
    return {
        semantic_ir => $semantic_ir,
        hial_source => {
            source_id => $hial_name,
            format => 'ppif',
            text => $hial_source,
        },
        fixture_id => 'base_output_arbitration',
        scenario_ids => [],
        execution_profile => "core_directed_single_clock_execution_v$version",
        replay_manifest => undef,
        native_extension_catalog => [],
    };
}

subtest 'v1 execution and plan identities remain byte-exact' => sub {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $v1_source,
        source_name => $vial_name,
    });
    my $result = FSM::VIAL::PlanBuilder->build(plan_args($semantic_ir, 1));
    ok($result->{ok}, 'v1 plan still builds');
    is(sha256_hex($json->encode($result->{execution_ir}->as_hashref)),
        '7d54be68bc691e3c05c4c94405f0ad278b9206032f8b9cde5dc3d7bf13714509',
        'v1 ExecutionIR retains its pre-v2 byte identity');
    is(sha256_hex($json->encode($result->{plan})),
        'eaa8cc70fa25a4382921f40112c0f3f50aec4045caccff2e6a8f98cfbc1c0942',
        'v1 plan retains its pre-v2 byte identity');
    is($result->{plan}{plan_id},
        'plan/e236297c8b434a9b374d1800112841e00327bdbd5d8d9130440bd20681fbed6e',
        'v1 content-addressed plan identity remains exact');
    is_deeply([sort keys %{$result->{execution_ir}->as_hashref}],
        [sort @{FSM::VIAL::ExecutionIR->top_level_keys}],
        'v1 ExecutionIR gains no v2 family field');
    is_deeply([sort keys %{$result->{plan}}],
        [sort @{FSM::VIAL::ExecutionReport->top_level_keys}],
        'v1 plan gains no v2 family field');

    my $v1_result_boundary = FSM::VIAL::Backend::ResultProducer->produce({
        execution_ir => $result->{execution_ir},
        trace_validation => {ok => JSON::PP::true, records => []},
        negotiation => {}, tool_profile => {},
        backend_manifest_id => 'backend/v1-boundary',
        compile_id => 'compile/v1-boundary',
        simulation_id => 'simulation/v1-boundary',
        generated_artifact_sha256s => [],
        transcript_sha256 => '0' x 64,
    });
    is($v1_result_boundary->{diagnostics}[0]{code}, 'VIAL_RESULT_TRACE_ERROR',
        'the result guard admits v1 and reaches ordinary trace validation');
};

subtest 'empty-intents v2 binds through the unchanged HIAL bridge into versioned private carriers' => sub {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $v2_source,
        source_name => $vial_name,
    });
    my $first = FSM::VIAL::PlanBuilder->build(plan_args($semantic_ir, 2));
    ok($first->{ok}, 'base-v2 plan builds through the private v2 wrapper');
    diag($json->encode($first->{diagnostics})) unless $first->{ok};
    is($first->{bridge_manifest}->schema,
        'fsmgen.hial_vial_bridge_manifest.v1',
        'unchanged HIAL facts keep bridge schema version one');
    is($first->{execution_ir}->schema, 'fsmgen.vial_execution_ir.v2',
        'v2 execution uses its distinct private schema');
    is($first->{execution_ir}->schema_version, 2,
        'v2 execution carries schema version two');
    is($first->{execution_ir}->profile,
        'core_directed_single_clock_execution_v2',
        'v2 execution uses the exact base execution profile');
    is($first->{plan}{schema}, 'fsmgen.vial_plan.v2',
        'v2 plan uses its distinct schema');
    is($first->{plan}{schema_version}, 2,
        'v2 plan carries schema version two');
    is_deeply([sort keys %{$first->{execution_ir}->as_hashref}],
        [sort @{FSM::VIAL::ExecutionIR->top_level_keys_v2}],
        'v2 ExecutionIR has the exact additive family carrier');
    is_deeply([sort keys %{$first->{plan}}],
        [sort @{FSM::VIAL::ExecutionReport->top_level_keys_v2}],
        'v2 plan has the exact additive family carrier');
    is_deeply($first->{execution_ir}->semantic_families, [],
        'no family is invented for the empty-intents base');
    is_deeply($first->{plan}{semantic_families}, [],
        'the sanitized v2 plan keeps the family carrier empty');
    is($first->{execution_ir}->resource_summary->{semantic_family_nodes}, 0,
        'the resource summary counts zero semantic-family nodes');
    is($first->{plan}{semantic_identity}{semantic_ir_id},
        'semantic/' . sha256_hex($json->encode($semantic_ir->as_hashref)),
        'v2 planning identifies the authored v2 SemanticIR, not its base projection');

    my %capability = map { $_->{capability_id} => 1 }
        @{$first->{plan}{capability_ledger}};
    ok($capability{'vial.source.v2'} && $capability{'vial.semantic_ir.v2'}
        && $capability{'vial.execution_ir.v2'} && $capability{'vial.plan.v2'}
        && $capability{'vial.semantic_family_envelope.v2'},
        'v2 private carriers state every implemented base capability');
    ok(!$capability{'vial.source.v1'} && !$capability{'vial.semantic_ir.v1'}
        && !$capability{'vial.execution_ir.v1'} && !$capability{'vial.plan.v1'},
        'v2 private carriers do not mislabel their versioned boundaries as v1');

    my $second = FSM::VIAL::PlanBuilder->build({
        native_extension_catalog => [], replay_manifest => undef,
        execution_profile => 'core_directed_single_clock_execution_v2',
        scenario_ids => [], fixture_id => 'base_output_arbitration',
        hial_source => {
            text => $hial_source, format => 'ppif', source_id => $hial_name,
        },
        semantic_ir => $semantic_ir,
    });
    is($json->encode($second->{plan}), $json->encode($first->{plan}),
        'v2 plan bytes are independent of invocation-key order');
    my $copy = $first->{execution_ir}->semantic_families;
    push @{$copy}, {mutated => 1};
    is_deeply($first->{execution_ir}->semantic_families, [],
        'v2 ExecutionIR family access is defensive');

    my $result = FSM::VIAL::Backend::ResultProducer->produce({
        execution_ir => $first->{execution_ir},
        trace_validation => {ok => JSON::PP::true, records => []},
        negotiation => {}, tool_profile => {},
        backend_manifest_id => 'backend/private-v2-boundary',
        compile_id => 'compile/private-v2-boundary',
        simulation_id => 'simulation/private-v2-boundary',
        generated_artifact_sha256s => [],
        transcript_sha256 => '0' x 64,
    });
    ok(!$result->{ok}, 'the v1 result producer rejects a v2 ExecutionIR');
    is($result->{diagnostics}[0]{code}, 'VIAL_RESULT_VERSION_UNSUPPORTED',
        'result rejection names the unsupported version boundary');
    is($result->{manifest}, undef,
        'result rejection cannot emit a mislabeled v1 manifest');

    my $emission = FSM::VIAL::Backend::SVPortableVerilator->emit({
        execution_ir => $first->{execution_ir},
        bridge_manifest => $first->{bridge_manifest},
        backend_inputs => $first->{backend_inputs},
        artifact_root => '.artifacts/test/vial-v2-boundary',
        backend_profile => 'sv_portable_verilator',
    });
    ok(!$emission->{ok}, 'the v1 portable backend rejects a v2 ExecutionIR');
    is($emission->{diagnostics}[0]{code}, 'VIAL_BACKEND_UNSUPPORTED',
        'backend rejection remains capability negotiation');
    is_deeply($emission->{artifacts}, [],
        'backend version rejection happens before artifact allocation');
};

subtest 'common semantic-family contract is closed and bounded at every phase' => sub {
    my $contract = build_vial_semantic_family_contract();
    is_deeply([sort keys %{$contract}],
        [sort @{vial_semantic_family_contract_keys()}],
        'machine contract has exactly its declared top-level keys');
    is($contract->{status},
        'private_v2_common_envelope_with_lifecycle_compiler',
        'machine truth names the lifecycle compiler without promoting backends');
    is($contract->{stage_schemas}{source_map}, 'fsmgen.vial_source_map.v2',
        'the common provenance carrier has an exact schema identity');
    is($contract->{limits}{families_per_package}, 256,
        'the SemanticIR family collection retains the source-envelope ceiling');
    is($contract->{limits}{payload_depth_per_node}, 64,
        'the generic family payload has a finite pre-encoding depth ceiling');
    is($contract->{limits}{payload_values_per_node}, 4_096,
        'the generic family payload has a finite value-count ceiling');
    is($contract->{limits}{payload_bytes_per_node}, 262_144,
        'the generic family payload has a finite canonical-byte ceiling');

    my $chain = example_chain();
    my $validated = validate_vial_semantic_family_chain($chain);
    is($validated->{semantic}{family_id}, 'example_family',
        'family identity survives the complete phase chain');
    is_deeply($validated->{result}{semantic}, $validated->{semantic},
        'scope, lifetime, order, ports, effects, failure, result, and provenance survive to result');
    is_deeply($validated->{result}{source_map}{execution_paths},
        ['/semantic_families/0'],
        'result provenance retains the exact execution path');
    is_deeply($validated->{result}{source_map}{plan_paths},
        ['/semantic_families/0'],
        'result provenance retains the exact plan path');
    is_deeply($validated->{result}{source_map}{result_paths},
        ['/semantic_families/0'],
        'result provenance adds the exact result path');

    my $projected = project_vial_semantic_family_plan(
        $chain->{execution}, '/semantic_families/0',
    );
    is_deeply($projected, $validated->{plan},
        'the execution-to-plan projector produces the canonical closed plan envelope');

    my $family = {
        semantic_id => 'family/example', family_id => 'example_family',
        revision => 1,
        semantic_path => '/packages/0/intent_families/0',
        source_span => clone($chain->{semantic}{source_span}),
        nodes => [clone($chain->{semantic})],
    };
    my $families = validate_vial_semantic_family_collection(
        'semantic_family', [$family],
    );
    is($families->[0]{nodes}[0]{node_id}, 'node/example',
        'SemanticIR family validation retains the closed typed node');

    $chain->{semantic}{payload}{value} = 'caller mutation';
    isnt($validated->{semantic}{payload}{value}, 'caller mutation',
        'validated phase chains share no caller-mutable storage');
};

subtest 'incomplete, contradictory, parser-shaped, and untraceable envelopes fail before allocation' => sub {
    my $missing = example_chain();
    delete $missing->{semantic}{lifetime}{end};
    contract_failure('missing lifetime field', qr/lifetime is missing key 'end'/,
        sub { validate_vial_semantic_family_stage('semantic', $missing->{semantic}) });

    my $contradictory = example_chain();
    $contradictory->{execution}{semantic}{order}{phase} = 'changed';
    contract_failure('cross-phase semantic mutation', qr/changes semantic meaning/,
        sub { validate_vial_semantic_family_chain($contradictory) });

    my $unbound = example_chain();
    $unbound->{binding}{bindings} = [];
    contract_failure('required unbound port', qr/required semantic-family port .* is unbound/,
        sub { validate_vial_semantic_family_stage('binding', $unbound->{binding}) });

    my $unproved = example_chain();
    $unproved->{binding}{bindings}[0]{type_relation_ids} = [];
    contract_failure('binding without type proof', qr/has no type relation proof/,
        sub { validate_vial_semantic_family_stage('binding', $unproved->{binding}) });

    my $unmapped = example_chain();
    $unmapped->{binding}{source_map}{bridge_fact_paths} = ['/endpoints/0'];
    seal_source_map($unmapped->{binding}{source_map});
    contract_failure('binding with incomplete bridge provenance',
        qr/does not match binding bridge facts/,
        sub { validate_vial_semantic_family_stage('binding', $unmapped->{binding}) });

    my $parser_payload = example_chain();
    $parser_payload->{semantic}{payload} = {node_kind => 'list', raw => '(target)'};
    contract_failure('parser-form payload', qr/contains a lexer\/parser node/,
        sub { validate_vial_semantic_family_stage('semantic', $parser_payload->{semantic}) });

    my $deep_payload = example_chain();
    my $nested = {value => 'leaf'};
    $nested = {value => $nested} for 1 .. 65;
    $deep_payload->{semantic}{payload} = $nested;
    contract_failure('over-deep payload', qr/payload depth limit/,
        sub { validate_vial_semantic_family_stage('semantic', $deep_payload->{semantic}) });

    my $lost_span = example_chain();
    $lost_span->{execution}{source_map}{source_locations}[0]{start_byte}++;
    contract_failure('lost authored provenance', qr/loses the authored source span/,
        sub { validate_vial_semantic_family_stage('execution', $lost_span->{execution}) });

    my $unsorted = example_chain();
    $unsorted->{execution}{required_capabilities} = [qw(z.capability a.capability)];
    contract_failure('nondeterministic capability order', qr/must be lexically sorted/,
        sub { validate_vial_semantic_family_stage('execution', $unsorted->{execution}) });

    contract_failure('unknown empty collection stage', qr/unknown semantic-family collection stage/,
        sub { validate_vial_semantic_family_collection('invented', []) });

    my $empty_family = {
        %{example_chain()->{semantic}},
    };
    $empty_family = {
        semantic_id => 'family/empty', family_id => 'empty_family', revision => 1,
        semantic_path => '/packages/0/intent_families/0',
        source_span => clone($empty_family->{source_span}), nodes => [],
    };
    contract_failure('empty typed family', qr/must contain at least one typed semantic node/,
        sub { validate_vial_semantic_family_collection('semantic_family', [$empty_family]) });

    my $forged_map = example_chain();
    $forged_map->{execution}{source_map}{source_map_id} = 'source-map/forged';
    contract_failure('forged source-map identity', qr/is not content-derived/,
        sub { validate_vial_semantic_family_stage('execution', $forged_map->{execution}) });

    my $missing_result = example_chain();
    $missing_result->{result}{outputs} = [];
    contract_failure('missing required typed result', qr/omits its required typed output/,
        sub { validate_vial_semantic_family_stage('result', $missing_result->{result}) });

    my $missing_effect = example_chain();
    $missing_effect->{result}{observed_effects} = [];
    contract_failure('missing result-visible effect', qr/omits result-visible effect/,
        sub { validate_vial_semantic_family_stage('result', $missing_effect->{result}) });
};

subtest 'unsupported family and wrong execution profile remain atomic' => sub {
    my $semantic_ir = FSM::VIAL::Parser->parse_source({
        text => $v2_source, source_name => $vial_name,
    });
    my $good = FSM::VIAL::PlanBuilder->build(plan_args($semantic_ir, 2));
    my $bad = FSM::VIAL::ExecutionBuilderV2->build({
        semantic_ir => $semantic_ir,
        bridge_manifest => $good->{bridge_manifest},
        fixture_id => $semantic_ir->as_hashref->{packages}[0]{fixtures}[0]{semantic_id},
        scenario_ids => [map { $_->{semantic_id} }
            @{$semantic_ir->as_hashref->{packages}[0]{fixtures}[0]{scenarios}}],
        execution_profile => 'core_directed_single_clock_execution_v1',
        replay_manifest => undef,
        native_extension_catalog => [],
    });
    ok(!$bad->{ok}, 'wrong v2 execution profile fails closed');
    is($bad->{diagnostics}[0]{schema},
        'fsmgen.vial_execution_diagnostic.v2',
        'v2 execution rejection uses a distinct diagnostic identity');
    is($bad->{diagnostics}[0]{code}, 'VIAL_CAPABILITY_ERROR',
        'wrong profile is a capability failure');
    is($bad->{execution_ir}, undef, 'failure returns no partial ExecutionIR');
    is($bad->{plan}, undef, 'failure returns no partial plan');

    my $family_source = $v2_source;
    $family_source =~ s/\(intents\)/\(intents (family unknown (revision 1) (node))\)/
        or die 'intent section was not found';
    my $checked = FSM::VIAL::Parser->check_source({
        text => $family_source, source_name => $vial_name,
    });
    ok(!$checked->{ok}, 'unregistered source family still fails before SemanticIR allocation');
    is($checked->{diagnostics}[0]{code}, 'VIAL_FAMILY_UNSUPPORTED',
        'the later registry remains the sole family-admission owner');
    is($checked->{semantic_report}, undef, 'unsupported family returns no partial semantic report');
};

done_testing();

sub example_chain {
    my $location = {
        source_name => 'vial/example.vial', start_byte => 10,
        end_byte_exclusive => 42, start_line => 2, start_column => 3,
        end_line => 2, end_column => 35,
    };
    my $semantic = {
        schema => 'fsmgen.vial_semantic_family.v2', schema_version => 2,
        stage => 'semantic', semantic_id => 'family/example/node/example',
        family_id => 'example_family', revision => 1,
        node_id => 'node/example', node_kind => 'example_node',
        scope => {kind => 'scenario', owner_id => 'scenario/example'},
        lifetime => {start => 'activation', end => 'completion', cancellation => 'cooperative'},
        order => {
            domain_id => 'domain/example', phase => 'react', rank => 0,
            before => [], after => [],
        },
        ports => [
            {
                port_id => 'port/request', name => 'request', direction => 'input',
                type_id => 'type/request', cardinality => 'one', required => JSON::PP::true,
            },
            {
                port_id => 'port/response', name => 'response', direction => 'output',
                type_id => 'type/response', cardinality => 'one', required => JSON::PP::true,
            },
        ],
        effects => [{
            effect_id => 'effect/notify', kind => 'notify',
            target_id => 'port/response', visibility => 'result',
        }],
        failure => {
            policy => 'fail_scope', diagnostic_code => 'VIAL_EXAMPLE_FAILURE',
            scope => 'scenario',
        },
        result => {kind => 'response', type_id => 'type/response', required => JSON::PP::true},
        semantic_path => '/packages/0/intent_families/0/nodes/0',
        source_span => clone($location), payload => {value => 'typed_example'},
    };
    my $bindings = [
        {
            port_id => 'port/request', binding_id => 'binding/request',
            bridge_fact_paths => ['/endpoints/0'],
            type_relation_ids => ['type-relation/request'],
        },
        {
            port_id => 'port/response', binding_id => 'binding/response',
            bridge_fact_paths => ['/endpoints/1'],
            type_relation_ids => ['type-relation/response'],
        },
    ];
    my $capabilities = [qw(
        vial.family.example_family.r1.semantic
        vial.semantic_family_envelope.v2
    )];
    my %schema = (
        binding => 'fsmgen.vial_semantic_family_binding.v2',
        execution => 'fsmgen.vial_execution_family.v2',
        plan => 'fsmgen.vial_plan_family.v2',
        result => 'fsmgen.vial_result_family.v2',
    );
    my %paths = (
        binding => [[], [], []],
        execution => [['/semantic_families/0'], [], []],
        plan => [['/semantic_families/0'], ['/semantic_families/0'], []],
        result => [['/semantic_families/0'], ['/semantic_families/0'], ['/semantic_families/0']],
    );
    my %stage;
    for my $name (qw(binding execution plan result)) {
        my ($execution_paths, $plan_paths, $result_paths) = @{$paths{$name}};
        $stage{$name} = {
            schema => $schema{$name}, schema_version => 2, stage => $name,
            semantic => clone($semantic), bindings => clone($bindings),
            operation_ids => $name eq 'binding' ? [] : ['operation/example'],
            required_capabilities => clone($capabilities),
            source_map => {
                schema => 'fsmgen.vial_source_map.v2', schema_version => 2,
                source_map_id => undef, semantic_id => $semantic->{semantic_id},
                semantic_path => $semantic->{semantic_path},
                bridge_fact_paths => ['/endpoints/0', '/endpoints/1'],
                execution_paths => clone($execution_paths),
                plan_paths => clone($plan_paths), result_paths => clone($result_paths),
                source_locations => [clone($location)],
            },
        };
    }
    seal_source_map($stage{binding}{source_map});
    seal_source_map($stage{execution}{source_map});
    seal_source_map($stage{result}{source_map});
    $stage{plan} = project_vial_semantic_family_plan(
        $stage{execution}, '/semantic_families/0',
    );
    $stage{result}{status} = 'pass';
    $stage{result}{outputs} = [{
        port_id => 'port/response', type_id => 'type/response',
        value => {kind => 'example', value => 7},
    }];
    $stage{result}{observed_effects} = [{
        effect_id => 'effect/notify', outcome => 'applied',
        target_id => 'port/response',
    }];
    $stage{result}{diagnostic_ids} = [];
    return {semantic => $semantic, %stage};
}

sub seal_source_map {
    my ($source_map) = @_;
    $source_map->{source_map_id} = undef;
    $source_map->{source_map_id} = 'source-map/'
        . sha256_hex($json->encode($source_map));
}

sub contract_failure {
    my ($label, $pattern, $code) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok, "$label fails closed");
    like($@, $pattern, "$label names the rejected invariant");
}

sub clone {
    my ($value) = @_;
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if ref($value) eq 'JSON::PP::Boolean';
    return {map { $_ => clone($value->{$_}) } sort keys %{$value}}
        if ref($value) eq 'HASH';
    return [map { clone($_) } @{$value}] if ref($value) eq 'ARRAY';
    return $value;
}
