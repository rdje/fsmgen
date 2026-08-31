use strict;
use warnings;

use Test::More;

use lib 'perl';

use FSM::VIAL::ArchitectureScaleCapPolicy qw(
    assert_architecture_scale_cap_policy
    build_architecture_scale_cap_policy
);
use FSM::VIAL::ArchitectureScaleWorkload;

my $policy = build_architecture_scale_cap_policy();
is(
    $policy->{schema},
    'fsmgen.vial_architecture_scale_cap_policy.v1',
    'the selected cap policy has one versioned schema',
);
is(
    $policy->{decision},
    'docs/decisions/0093-architecture-scale-caps-are-component-ceilings-with-explicit-route-authority.md',
    'the machine policy names its rationale authority',
);
is(
    $policy->{selection}{numeric_caps},
    'retain_all_selected_component_ceilings',
    'selection retains every component-local hard ceiling',
);
is(
    $policy->{selection}{workload_levels},
    'unchanged',
    'selection does not rewrite measured workload levels',
);
is(
    $policy->{selection}{route_truth},
    'publish_component_ceiling_earliest_authority_and_measured_boundary',
    'selection keeps component, earliest-route, and measured-boundary truth distinct',
);
is(
    $policy->{groups}{semantic_action_cardinality}{current_enforcement},
    'capacity_reserved_before_action_form_and_repeat_copy_multiplication',
    'action-cardinality policy records the hardened admission point',
);
is(
    $policy->{groups}{semantic_action_cardinality}{selected_treatment},
    'retain_early_reservation_and_terminal_defense',
    'action-cardinality policy retains both early and terminal enforcement',
);
is(
    $policy->{groups}{semantic_repeat_layering}{current_enforcement},
    'compact_body_then_bounded_copy_reservation',
    'repeat policy records bounded copy reservation after compact-body checking',
);
is(
    $policy->{groups}{semantic_repeat_layering}{selected_treatment},
    'retain_intrinsic_repeat_ceiling_and_overflow_safe_action_layering',
    'repeat policy retains its intrinsic ceiling and overflow-safe action layer',
);
is(
    $policy->{groups}{semantic_parser_admission}{current_enforcement},
    'source_bytes_before_lex_and_direct_import_fanout_before_recursion',
    'parser policy records byte admission and direct fan-out preflight',
);
is(
    $policy->{groups}{semantic_parser_admission}{selected_treatment},
    'retain_early_preflight_and_per_edge_terminal_defense',
    'parser policy retains both direct preflight and terminal edge defense',
);
ok(
    scalar(grep { $_ eq 't/1693-vial-parser-source-byte-cap-order.t' }
        @{$policy->{groups}{semantic_parser_admission}{evidence}}),
    'parser policy cites the exact source-byte admission witness',
);
is(
    $policy->{groups}{semantic_action_shape}{current_enforcement},
    'parallel_depth_and_fiber_count_before_join_value_resolution',
    'action-shape policy records parallel cap admission before join resolution',
);
is(
    $policy->{groups}{semantic_action_shape}{selected_treatment},
    'retain_shape_preflight_before_semantic_resolution',
    'action-shape policy retains structural preflight before semantic resolution',
);
is(
    $policy->{groups}{semantic_declaration_cardinality}{current_enforcement},
    'per_section_before_later_section_shape_parsing',
    'declaration policy records per-section admission before later shapes',
);
is(
    $policy->{groups}{semantic_declaration_cardinality}{selected_treatment},
    'retain_per_section_preflight_before_dependent_parsing',
    'declaration policy retains per-section preflight before dependent parsing',
);
is(
    $policy->{groups}{semantic_service_scalar}{current_enforcement},
    'before_dependent_reference_resolution',
    'service-scalar policy records admission before dependent resolution',
);
is(
    $policy->{groups}{semantic_service_scalar}{selected_treatment},
    'retain_scalar_preflight_before_dependent_resolution',
    'service-scalar policy retains scalar preflight before dependent resolution',
);
is(
    $policy->{groups}{semantic_type_shape}{current_enforcement},
    'length_field_count_and_depth_before_inner_type_resolution',
    'type-shape policy records all shape checks before inner-type resolution',
);
is(
    $policy->{groups}{semantic_type_shape}{selected_treatment},
    'retain_shape_preflight_before_recursive_resolution',
    'type-shape policy retains preflight before recursive resolution',
);
is(
    $policy->{groups}{bridge_normalized_collections}{current_enforcement},
    'raw_collection_cardinality_before_normalization_and_distinct_types_before_materialization_remaining_collections_terminal',
    'bridge policy records raw-collection and distinct-type preflight plus remaining checks',
);
ok(
    scalar(grep { $_ eq 't/1694-hial-vial-bridge-configuration-cap-order.t' }
        @{$policy->{groups}{bridge_normalized_collections}{evidence}}),
    'bridge policy cites the exact configuration-admission witness',
);
ok(
    scalar(grep { $_ eq 't/1695-hial-vial-bridge-endpoint-cap-order.t' }
        @{$policy->{groups}{bridge_normalized_collections}{evidence}}),
    'bridge policy cites the exact endpoint-admission witness',
);
ok(
    scalar(grep { $_ eq 't/1696-hial-vial-bridge-observation-cap-order.t' }
        @{$policy->{groups}{bridge_normalized_collections}{evidence}}),
    'bridge policy cites the exact observation-admission witness',
);
ok(
    scalar(grep { $_ eq 't/1697-hial-vial-bridge-probe-cap-order.t' }
        @{$policy->{groups}{bridge_normalized_collections}{evidence}}),
    'bridge policy cites the exact probe-admission witness',
);
ok(
    scalar(grep { $_ eq 't/1698-hial-vial-bridge-type-cap-order.t' }
        @{$policy->{groups}{bridge_normalized_collections}{evidence}}),
    'bridge policy cites the exact type-admission witness',
);

my $catalog = FSM::VIAL::ArchitectureScaleWorkload->catalog;
my @catalog_axes;
for my $family (sort keys %{$catalog->{families}}) {
    push @catalog_axes,
        map { "$family/$_" } sort keys %{$catalog->{families}{$family}{axes}};
}
my @policy_axes;
for my $family (sort keys %{$policy->{axis_groups}}) {
    push @policy_axes,
        map { "$family/$_" } sort keys %{$policy->{axis_groups}{$family}};
}
is_deeply(
    \@policy_axes,
    \@catalog_axes,
    'every selected workload axis has exactly one cap-policy group',
);

ok(
    assert_architecture_scale_cap_policy($policy),
    'the complete declared-value, group, interaction, profile, and envelope contract validates',
);

my $missing_axis = build_architecture_scale_cap_policy();
delete $missing_axis->{axis_groups}{semantic_catalog_v1}{imports};
my $missing_ok = eval {
    assert_architecture_scale_cap_policy($missing_axis);
    1;
};
ok(!$missing_ok, 'axis-coverage mutation fails closed');
like($@, qr/policy axis coverage contradicts the workload catalog/, 'axis mutation is diagnosable');

my $relevelled = build_architecture_scale_cap_policy();
$relevelled->{selection}{workload_levels} = 'rewritten';
my $relevelled_ok = eval {
    assert_architecture_scale_cap_policy($relevelled);
    1;
};
ok(!$relevelled_ok, 'workload re-levelling mutation fails closed');
like($@, qr/selection field 'workload_levels' contradicts decision 0093/, 'selection mutation is diagnosable');

my $first = build_architecture_scale_cap_policy();
$first->{axis_groups}{semantic_catalog_v1}{imports} = 'mutated';
my $second = build_architecture_scale_cap_policy();
is(
    $second->{axis_groups}{semantic_catalog_v1}{imports},
    'semantic_parser_admission',
    'returned policy data is defensive',
);

done_testing;
