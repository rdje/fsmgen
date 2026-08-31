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
