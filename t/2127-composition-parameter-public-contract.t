use strict;
use warnings;
use lib 'perl';
use Test::More;
use JSON::PP;
use Lispish;
use FSM::Composition::Parser;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::Plan;
use FSM::Composition::PlanBuilder;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Pipeline::HDLGenerator;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::SourcePathResolver;
use FSM::Support::SerializableCompositionPlanSnapshot qw(build_serializable_composition_plan_snapshot);
use FSM::Support::NormalizedSemanticReport qw(build_normalized_semantic_success_report);
use FSM::Support::NormalizedSemanticReportContract qw(build_normalized_semantic_report_contract);

my $json = JSON::PP->new->canonical;
sub copy { $json->decode($json->encode($_[0])) }
sub check_node {
    my ($contract, $node) = @_;
    my $keys = $contract->{binding_node_keys}{$node->{kind}};
    ok($keys, "actual $node->{kind} binding kind is advertised");
    return unless $keys;
    is_deeply([sort keys %$node], [sort @$keys], 'actual binding has exactly the advertised kind-specific keys');
    check_node($contract, $_) for @{$node->{operands} || $node->{items} || []};
    check_node($contract, $node->{members}{$_}) for @{$node->{member_order} || []};
}
my $path = 't/data/composition-top-instance-bindings.fsm';
my $spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($path));
FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $spec,
    fsm_file => $path, source_path_resolver => FSM::SourcePathResolver->new);
my $plan = FSM::Composition::Plan->new(lane => 'C3', top_name => $spec->top->name, raw_spec => $spec);
my $environment = $plan->parameter_environment;
my $intent = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $plan);
my $structural = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($plan);
my $snapshot = build_serializable_composition_plan_snapshot(composition_plan => $plan);
is($json->encode($snapshot->{parameter_environment}), $json->encode($environment), 'public plan snapshot retains actual resolved source/default/binding products and JSON kinds');
my $report = build_normalized_semantic_success_report(input => $path, source_file => $path,
    result => {composition_plan => $plan, intent_hir => $intent->as_hashref,
        structural_rtl_ir => $structural->as_hashref});
for my $name (qw(intent_hir structural_rtl_ir)) {
    is_deeply($report->{semantic}{forward_ir}{$name}{parameter_environment}, $environment,
        "public $name retains the complete actual environment");
}
is_deeply($report->{semantic}{composition}{plan_snapshot}{parameter_environment}, $environment,
    'embedded public snapshot preserves the environment too');
my $wire = copy($report);
is($json->encode($wire), $json->encode($report), 'complete report round trips through JSON without changing kinds');
is_deeply($environment->{scope}, {kind => 'composition_top', owner => 'top_instance_bindings'}, 'actual lexical scope is explicit');
is_deeply($environment->{declaration_order}, [qw(W SAME ALIAS LANES FRAME)], 'source declaration order stays exact');
is_deeply($environment->{default_bindings}{ALIAS}, {kind => 'parameter', parameter => 'W', token => 'W', suffix => '',
    scope => {kind => 'composition_top', owner => 'top_instance_bindings'}}, 'alias names its immediate declaration');
is_deeply($environment->{default_bindings}{W}, {kind => 'static_symbol', token => 'C',
    scope => {kind => 'composition_top', owner => 'top_instance_bindings'}, value_payload => {kind => 'scalar', payload => '16'}},
    'same-valued static default remains a static lookup');
is($environment->{parameters}{LANES}{value_width}, 16, 'two authored octets form the expected packed default width');
is_deeply($environment->{parameters}{FRAME}{value_payload}{member_order}, [qw(tag data)], 'map fields retain authored order');

subtest 'schema describes actual optional fields without source admission' => sub {
    my $contract = build_normalized_semantic_report_contract()->{composition_parameter_contract};
    ok($contract, 'public normalized semantic discovery exposes the shared parameter contract');
    return unless $contract;
    is($contract->{schema_version}, 1, 'schema version is explicit');
    is($contract->{contract_source}, 'FSM::Support::CompositionParameterContract', 'schema owner is explicit');
    is_deeply([sort keys %$environment], [sort @{$contract->{environment_keys}}], 'actual environment has exactly the published key family');
    is_deeply($contract->{environment_paths}, [
        'semantic.forward_ir.intent_hir.parameter_environment',
        'semantic.forward_ir.structural_rtl_ir.parameter_environment',
        'semantic.composition.plan_snapshot.parameter_environment'], 'only actual environment products are advertised');
    ok(JSON::PP::is_bool($contract->{public_source_planning_supported}) && !$contract->{public_source_planning_supported},
        'discovery explicitly denies pending source planning');
    for my $name (@{$environment->{declaration_order}}) {
        is_deeply([sort keys %{$environment->{default_sources}{$name}}], [sort @{$contract->{default_source_keys}}], 'actual authored source schema matches');
        my $value = $environment->{parameters}{$name};
        my %allowed = map {$_ => 1} (@{$contract->{parameter_value_keys}}, @{$contract->{parameter_value_optional_keys}});
        is_deeply([grep {!$allowed{$_}} keys %$value], [], 'actual normalized value has no unadvertised fields');
    }
    check_node($contract, $_) for values %{$environment->{default_bindings}};
    for my $child (@{$spec->top->instances}) {
        for my $override (@{$child->parameter_overrides}) {
            check_node($contract, $override->{binding_expression}) if exists $override->{binding_expression};
        }
    }
    my $original = copy($contract);
    $contract->{binding_node_keys}{parameter}[0] = 'WRONG';
    is_deeply(build_normalized_semantic_report_contract()->{composition_parameter_contract}, $original,
        'nested schema getters return independent structures');
};

subtest 'actual realized children expose scoped binding extensions' => sub {
    my $source = 't/data/composition-top-child-bindings.fsm';
    my $child_spec = FSM::Composition::Parser->new->parse_source(scalar Lispish::multi($source));
    my $resolver = FSM::SourcePathResolver->new;
    FSM::Composition::PackageImportResolver->resolve_imports(composition_spec => $child_spec,
        fsm_file => $source, source_path_resolver => $resolver);
    my $instances = FSM::Composition::PlanBuilder->realize_instances(
        pipeline => FSM::Pipeline::HDLGenerator->new(quiet => 1), composition_spec => $child_spec,
        instances => $child_spec->top->instances, fsm_file => $source, source_path_resolver => $resolver,
        rtl_interface_loader => FSM::Composition::RTLInterfaceLoader->new(path_resolver => $resolver));
    my $child_plan = FSM::Composition::Plan->new(top_name => $child_spec->top->name,
        instances => $instances, raw_spec => $child_spec);
    my $child_ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan($child_plan);
    my $child_intent = FSM::IR::IntentHIRBuilder->build_from_composition_plan(composition_plan => $child_plan);
    my $public = build_normalized_semantic_success_report(input => $source, source_file => $source,
        result => {composition_plan => $child_plan, structural_rtl_ir => $child_ir->as_hashref, intent_hir => $child_intent->as_hashref});
    for my $rows ($public->{semantic}{composition}{children},
                  $public->{semantic}{forward_ir}{intent_hir}{composition_children},
                  $public->{semantic}{forward_ir}{structural_rtl_ir}{instances}) {
        is(scalar(@$rows), 3, 'FSM, DT and RTL child records all survive the public projection');
        for my $child (@$rows) {
            my %overrides = map {$_->{name} => $_} @{$child->{parameter_overrides}};
            is_deeply($overrides{WIDTH}{binding_expression}, {kind => 'parameter', parameter => 'W', token => 'W', suffix => '',
                scope => {kind => 'composition_top', owner => 'child_bindings'}}, 'actual validated WIDTH override selects top W');
            is($overrides{WIDTH}{value_text}, '16', 'actual child validation cache accompanies the symbolic reference');
        }
    }
    my $before = $json->encode($child_ir->as_hashref);
    $public->{semantic}{forward_ir}{structural_rtl_ir}{instances}[0]{parameter_overrides}[0]{binding_expression}{scope}{owner} = 'WRONG';
    is($json->encode($child_ir->as_hashref), $before, 'public binding mutation cannot alter the actual structural owner');
};

my $original = copy($environment);
if ($snapshot->{parameter_environment}) {
    $snapshot->{parameter_environment}{default_bindings}{ALIAS}{scope}{owner} = 'WRONG';
    $snapshot->{parameter_environment}{default_sources}{W}{expression} = 'WRONG';
    is_deeply($plan->parameter_environment, $original, 'snapshot cannot mutate source or scoped binding owner');
}
$report->{semantic}{forward_ir}{intent_hir}{parameter_environment}{parameters}{W}{value_text} = 'WRONG';
is_deeply($intent->parameter_environment, $original, 'public report cannot mutate the actual IR');
my $hash_input = {parameter_environment => copy($original)};
my $hash_snapshot = build_serializable_composition_plan_snapshot(composition_plan => $hash_input);
if ($hash_snapshot->{parameter_environment}) {
    $hash_snapshot->{parameter_environment}{declaration_order}[0] = 'WRONG';
    is_deeply($hash_input->{parameter_environment}, $original, 'hash-backed snapshot also detaches nested fields');
}
my $static = build_serializable_composition_plan_snapshot(composition_plan => FSM::Composition::Plan->new(top_name => 'static'));
is_deeply($static, {
    composition_plan_snapshot_schema_version => 1,
    report_source => 'FSM::Support::SerializableCompositionPlanSnapshot',
    contract_source => 'FSM::Support::SerializableCompositionPlanSnapshot',
    present => JSON::PP::true, source_object_class => 'FSM::Composition::Plan', lane => undef, top_name => 'static',
    summary => {map {$_ => 0} qw(port_count link_count resolved_link_count net_count instance_count auxiliary_assignment_count shared_datapath_candidate_count)},
    map {$_ => []} qw(top_ports links resolved_links nets instances auxiliary_assignments shared_datapath_candidates)
}, 'complete ordinary snapshot remains unchanged');
done_testing;
