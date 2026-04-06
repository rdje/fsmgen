package FSM::IR::IntentHIR;

=head1 NAME

FSM::IR::IntentHIR - Explicit forward semantic intent summary for C<.fsm> generation

=head1 DESCRIPTION

Represents the semantic intent layer in the forward compiler. This package owns
the root identity, system contract, state and standalone-DT families,
signal-boundary summaries, and bounded composition child summaries that later
lowering steps consume.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    confess "FSM::IR::IntentHIR requires 'module_name'"
        unless defined($args{module_name}) && $args{module_name} ne '';

    return bless {
        module_name => $args{module_name},
        source_root_kind => $args{source_root_kind} // 'fsm',
        regular_state_names => [@{$args{regular_state_names} || []}],
        standalone_dt_names => [@{$args{standalone_dt_names} || []}],
        signal_names => [@{$args{signal_names} || []}],
        signal_analysis => _clone($args{signal_analysis} || {}),
        explicit_system_contract => _clone($args{explicit_system_contract}),
        system_contract => _clone($args{system_contract} || {}),
        requires_implicit_system_ports => ($args{requires_implicit_system_ports} ? 1 : 0),
        standalone_dt_enable_families => _clone($args{standalone_dt_enable_families} || []),
        standalone_dt_module_enable_family => _clone($args{standalone_dt_module_enable_family} || {}),
        parameter_names => [@{$args{parameter_names} || []}],
        symbol_contract => _clone($args{symbol_contract}),
        composition_child_count => $args{composition_child_count},
        composition_children => _clone($args{composition_children}),
        composition_generated_child_count => $args{composition_generated_child_count},
        composition_generated_fsm_child_count => $args{composition_generated_fsm_child_count},
        composition_generated_dt_child_count => $args{composition_generated_dt_child_count},
        composition_generated_children => _clone($args{composition_generated_children}),
        composition_standalone_dt_child_count => $args{composition_standalone_dt_child_count},
        composition_standalone_dt_block_count => $args{composition_standalone_dt_block_count},
        composition_standalone_dt_multi_drive_target_count => $args{composition_standalone_dt_multi_drive_target_count},
        composition_standalone_dt_children => _clone($args{composition_standalone_dt_children}),
        composition_lane => $args{composition_lane},
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub regular_state_names ($self) { return $self->{regular_state_names} }
sub standalone_dt_names ($self) { return $self->{standalone_dt_names} }
sub signal_names ($self) { return $self->{signal_names} }
sub signal_analysis ($self) { return $self->{signal_analysis} }
sub explicit_system_contract ($self) { return $self->{explicit_system_contract} }
sub system_contract ($self) { return $self->{system_contract} }
sub requires_implicit_system_ports ($self) { return $self->{requires_implicit_system_ports} }
sub standalone_dt_enable_families ($self) { return $self->{standalone_dt_enable_families} }
sub standalone_dt_module_enable_family ($self) { return $self->{standalone_dt_module_enable_family} }
sub parameter_names ($self) { return $self->{parameter_names} }
sub symbol_contract ($self) { return $self->{symbol_contract} }
sub composition_child_count ($self) { return $self->{composition_child_count} }
sub composition_children ($self) { return $self->{composition_children} }
sub composition_generated_child_count ($self) { return $self->{composition_generated_child_count} }
sub composition_generated_fsm_child_count ($self) { return $self->{composition_generated_fsm_child_count} }
sub composition_generated_dt_child_count ($self) { return $self->{composition_generated_dt_child_count} }
sub composition_generated_children ($self) { return $self->{composition_generated_children} }
sub composition_standalone_dt_child_count ($self) { return $self->{composition_standalone_dt_child_count} }
sub composition_standalone_dt_block_count ($self) { return $self->{composition_standalone_dt_block_count} }
sub composition_standalone_dt_multi_drive_target_count ($self) { return $self->{composition_standalone_dt_multi_drive_target_count} }
sub composition_standalone_dt_children ($self) { return $self->{composition_standalone_dt_children} }
sub composition_lane ($self) { return $self->{composition_lane} }

sub system_contract_from_input ($class, $intent_hir, $default = undef) {
    my $system_contract = (
        blessed($intent_hir) && $intent_hir->can('system_contract')
            ? $intent_hir->system_contract
            : ref($intent_hir) eq 'HASH'
                ? $intent_hir->{system_contract}
                : undef
    );

    return _clone($system_contract)
        if ref($system_contract) eq 'HASH';

    return _clone($default)
        if ref($default) eq 'HASH';

    return {};
}

sub signal_analysis_entries ($self, $direction) {
    return [] unless defined($direction) && length($direction);
    my $signal_analysis = $self->signal_analysis;
    return [] unless ref($signal_analysis) eq 'HASH';
    return _clone($signal_analysis->{$direction} || []);
}

sub signal_analysis_entries_from_input ($class, $intent_hir, $direction) {
    return [] unless defined($direction) && length($direction);

    my $entries = (
        blessed($intent_hir) && $intent_hir->can('signal_analysis_entries')
            ? $intent_hir->signal_analysis_entries($direction)
            : ref($intent_hir) eq 'HASH' && ref($intent_hir->{signal_analysis}) eq 'HASH'
                ? $intent_hir->{signal_analysis}{$direction}
                : undef
    );

    return [] unless ref($entries) eq 'ARRAY';
    return _clone($entries);
}

sub composition_children_from_input ($class, $intent_hir) {
    my $children = (
        blessed($intent_hir) && $intent_hir->can('composition_children')
            ? $intent_hir->composition_children
            : ref($intent_hir) eq 'HASH'
                ? $intent_hir->{composition_children}
                : undef
    );

    return undef unless ref($children) eq 'ARRAY';
    return _clone($children);
}

sub composition_children_by_instance ($self) {
    my %children_by_instance;

    for my $child (@{$self->composition_children || []}) {
        next unless ref($child) eq 'HASH';
        my $instance_name = $child->{instance_name} || next;
        $children_by_instance{$instance_name} = _clone($child);
    }

    return \%children_by_instance;
}

sub composition_children_by_instance_from_input ($class, $intent_hir) {
    my $children = $class->composition_children_from_input($intent_hir);
    return undef unless ref($children) eq 'ARRAY';

    my %children_by_instance;
    for my $child (@$children) {
        next unless ref($child) eq 'HASH';
        my $instance_name = $child->{instance_name} || next;
        $children_by_instance{$instance_name} = _clone($child);
    }

    return \%children_by_instance;
}

sub composition_child ($self, $instance_name) {
    return undef unless defined($instance_name) && length($instance_name);
    return _clone($self->composition_children_by_instance->{$instance_name});
}

sub composition_child_from_input ($class, $intent_hir, $instance_name) {
    return undef unless defined($instance_name) && length($instance_name);
    my $children_by_instance = $class->composition_children_by_instance_from_input($intent_hir);
    return undef unless ref($children_by_instance) eq 'HASH';
    return _clone($children_by_instance->{$instance_name});
}

sub as_hashref ($self) {
    my $regular_state_names = [@{$self->regular_state_names || []}];
    my $standalone_dt_names = [@{$self->standalone_dt_names || []}];
    my $signal_names = [@{$self->signal_names || []}];
    my $parameter_names = [@{$self->parameter_names || []}];

    my $result = {
        module_name => $self->module_name,
        source_root_kind => $self->source_root_kind,
        regular_state_count => scalar(@$regular_state_names),
        regular_state_names => $regular_state_names,
        state_count => scalar(@$regular_state_names),
        standalone_dt_count => scalar(@$standalone_dt_names),
        standalone_dt_names => $standalone_dt_names,
        signal_count => scalar(@$signal_names),
        signal_names => $signal_names,
        signal_analysis => _clone($self->signal_analysis || {}),
        explicit_system_contract => _clone($self->explicit_system_contract),
        system_contract => _clone($self->system_contract || {}),
        requires_implicit_system_ports => ($self->requires_implicit_system_ports ? 1 : 0),
        standalone_dt_enable_families => _clone($self->standalone_dt_enable_families || []),
        standalone_dt_module_enable_family => _clone($self->standalone_dt_module_enable_family || {}),
        parameter_count => scalar(@$parameter_names),
        parameter_names => $parameter_names,
        symbol_contract => _clone($self->symbol_contract),
    };

    $result->{composition_child_count} = $self->composition_child_count
        if defined $self->composition_child_count;
    $result->{composition_children} = _clone($self->composition_children)
        if defined $self->composition_children;
    $result->{composition_generated_child_count} = $self->composition_generated_child_count
        if defined $self->composition_generated_child_count;
    $result->{composition_generated_fsm_child_count} = $self->composition_generated_fsm_child_count
        if defined $self->composition_generated_fsm_child_count;
    $result->{composition_generated_dt_child_count} = $self->composition_generated_dt_child_count
        if defined $self->composition_generated_dt_child_count;
    $result->{composition_generated_children} = _clone($self->composition_generated_children)
        if defined $self->composition_generated_children;
    $result->{composition_standalone_dt_child_count} = $self->composition_standalone_dt_child_count
        if defined $self->composition_standalone_dt_child_count;
    $result->{composition_standalone_dt_block_count} = $self->composition_standalone_dt_block_count
        if defined $self->composition_standalone_dt_block_count;
    $result->{composition_standalone_dt_multi_drive_target_count} = $self->composition_standalone_dt_multi_drive_target_count
        if defined $self->composition_standalone_dt_multi_drive_target_count;
    $result->{composition_standalone_dt_children} = _clone($self->composition_standalone_dt_children)
        if defined $self->composition_standalone_dt_children;
    $result->{composition_lane} = $self->composition_lane
        if defined $self->composition_lane;

    return $result;
}

sub _clone ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }

    return $value;
}

1;

__END__

=head1 METHODS

=head2 new

Constructs a new intent HIR object and clones the supplied semantic payload.

=head2 module_name

Returns the logical module name represented by this intent layer.

=head2 source_root_kind

Returns the authored root kind, such as C<fsm>, C<dt>, or C<top>.

=head2 regular_state_names

Returns the authored regular-state names carried by the semantic layer.

=head2 standalone_dt_names

Returns the standalone decision-tree names carried by the semantic layer.

=head2 signal_names

Returns the authored or inferred top-boundary signal names.

=head2 signal_analysis

Returns the grouped input and output boundary analysis structure.

=head2 explicit_system_contract

Returns the explicitly authored system contract, if one exists.

=head2 system_contract

Returns the effective system contract after semantic defaulting.

=head2 requires_implicit_system_ports

Returns whether implicit shared system ports are still required for this root.

=head2 standalone_dt_enable_families

Returns the semantic standalone-DT enable family summaries.

=head2 standalone_dt_module_enable_family

Returns the module-level standalone-DT enable family summary.

=head2 parameter_names

Returns the semantic parameter-name list carried by the intent layer.

=head2 composition_child_count

Returns the bounded composition child count, when the root is a composition top.

=head2 composition_children

Returns the unified semantic composition child export list.

=head2 composition_generated_child_count

Returns the generated-child count summary for composition tops.

=head2 composition_generated_fsm_child_count

Returns the generated FSM child count summary for composition tops.

=head2 composition_generated_dt_child_count

Returns the generated standalone-DT child count summary for composition tops.

=head2 composition_generated_children

Returns the generated-child semantic export subset.

=head2 composition_standalone_dt_child_count

Returns the reusable standalone-DT child count summary for composition tops.

=head2 composition_standalone_dt_block_count

Returns the bounded standalone-DT block count summary for reusable children.

=head2 composition_standalone_dt_multi_drive_target_count

Returns the standalone-DT grouped multi-drive target count summary for reusable
children.

=head2 composition_standalone_dt_children

Returns the reusable standalone-DT child semantic export subset.

=head2 composition_lane

Returns the active composition lane label for composition tops.

=head2 system_contract_from_input

Extracts a cloned system-contract hash from either an intent object or an
intent-style hash payload, with an optional default fallback.

=head2 signal_analysis_entries

Returns the grouped signal-analysis entries for one boundary direction.

=head2 signal_analysis_entries_from_input

Extracts cloned grouped signal-analysis entries from either an intent object or
an intent-style hash payload.

=head2 composition_children_from_input

Extracts the unified composition child export list from either an intent object
or an intent-style hash payload.

=head2 composition_children_by_instance

Returns the unified composition child export list indexed by instance name.

=head2 composition_children_by_instance_from_input

Extracts a unified composition child export index from either an intent object
or an intent-style hash payload.

=head2 composition_child

Returns one unified composition child export entry by instance name.

=head2 composition_child_from_input

Extracts one unified composition child export entry by instance name from an
intent object or intent-style hash payload.

=head2 as_hashref

Serializes the intent layer into the exported hash shape used by downstream
pipeline and embedding surfaces.

=head2 _clone

Recursively clones nested hashes and arrays used by the intent layer.

=cut
