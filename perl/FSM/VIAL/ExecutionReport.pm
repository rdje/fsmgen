package FSM::VIAL::ExecutionReport;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use JSON::PP ();
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FSM::VIAL::ExecutionIR;

my @TOP_LEVEL_KEYS = qw(
    schema schema_version profile plan_id status semantic_identity
    bridge_identity fixture bindings logical_time scenarios random_decisions
    capability_ledger native_extensions resource_summary source_map diagnostics
);

sub top_level_keys($class) {
    confess "$class->top_level_keys requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    return [@TOP_LEVEL_KEYS];
}

sub build($class, @args) {
    confess __PACKAGE__ . "->build requires the exact class invocant\n"
        unless defined($class) && !ref($class) && $class eq __PACKAGE__;
    confess __PACKAGE__ . "->build expects one exact FSM::VIAL::ExecutionIR object\n"
        unless @args == 1 && blessed($args[0])
            && ref($args[0]) eq 'FSM::VIAL::ExecutionIR';
    my $data = $args[0]->as_hashref;
    my $bindings = _plan_bindings($data->{bindings});
    my $plan = {
        schema => 'fsmgen.vial_plan.v1',
        schema_version => 1,
        profile => $data->{profile},
        plan_id => $data->{plan_id},
        status => 'bound_target_neutral',
        semantic_identity => _clone($data->{semantic_identity}),
        bridge_identity => _clone($data->{bridge_identity}),
        fixture => _clone($data->{fixture}),
        bindings => $bindings,
        logical_time => {
            domains => [map {
                {
                    domain_id => $_->{semantic_id},
                    binding_id => $_->{binding_id},
                    active_edge => $_->{active_edge},
                    reset_kind => $_->{reset_kind},
                    reset_polarity => $_->{reset_polarity},
                }
            } @{$data->{domains}}],
            phase_order => [qw(drive sample react check)],
            tie_break_order => [qw(domain_rank static_operation_rank local_emission_index semantic_id)],
            scenario_cycle_origin => 0,
            timeout_last_cycle_inclusive => JSON::PP::true,
        },
        scenarios => [map { _clone($_->{plan_summary}) } @{$data->{scenarios}}],
        random_decisions => _clone($data->{randomness}{decisions}),
        capability_ledger => _clone($data->{capability_ledger}),
        native_extensions => _clone($data->{native_extensions}),
        resource_summary => _clone($data->{resource_summary}),
        source_map => _clone($data->{source_map}),
        diagnostics => [],
    };
    return _clone($plan);
}

sub _plan_bindings($bindings) {
    my $copy = _clone($bindings);
    for my $event (@{$copy->{events}}) {
        delete $event->{expression};
    }
    return $copy;
}

sub _clone($value) {
    return undef unless defined $value;
    return $value ? JSON::PP::true : JSON::PP::false
        if blessed($value) && $value->isa('JSON::PP::Boolean');
    return {map { $_ => _clone($value->{$_}) } sort keys %$value}
        if ref($value) eq 'HASH';
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return $value;
}

1;
