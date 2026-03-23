package FSM::IR::IntentHIR;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
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

=head1 NAME

FSM::IR::IntentHIR - Explicit forward semantic intent summary for `.fsm` generation

=head1 DESCRIPTION

This module provides the first extracted forward-compiler semantic IR surface used by
the active `.fsm` to HDL pipeline. It is intentionally narrow: root identity, system
contract, state/DT families, signal/interface analysis, and bounded composition
hierarchy summaries such as unified realized-child exports, generated-child exports,
and reusable standalone-DT child exports are captured explicitly so later lowering
work can stop rediscovering them ad hoc inside generation code.

=cut
