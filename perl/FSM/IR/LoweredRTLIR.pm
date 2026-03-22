package FSM::IR::LoweredRTLIR;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

sub new ($class, %args) {
    confess "FSM::IR::LoweredRTLIR requires 'module_name'"
        unless defined($args{module_name}) && $args{module_name} ne '';

    return bless {
        module_name => $args{module_name},
        source_root_kind => $args{source_root_kind} // 'fsm',
        target_language => $args{target_language} // 'systemverilog',
        output_drive_families => _clone($args{output_drive_families} || []),
        standalone_dt_multi_drive_targets => _clone($args{standalone_dt_multi_drive_targets} || []),
        internal_net_names => _clone($args{internal_net_names}),
        instance_names => _clone($args{instance_names}),
        auxiliary_assignment_count => $args{auxiliary_assignment_count},
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub target_language ($self) { return $self->{target_language} }
sub output_drive_families ($self) { return $self->{output_drive_families} }
sub standalone_dt_multi_drive_targets ($self) { return $self->{standalone_dt_multi_drive_targets} }
sub internal_net_names ($self) { return $self->{internal_net_names} }
sub instance_names ($self) { return $self->{instance_names} }
sub auxiliary_assignment_count ($self) { return $self->{auxiliary_assignment_count} }

sub as_hashref ($self) {
    my $output_drive_families = _clone($self->output_drive_families || []);
    my $standalone_dt_multi_drive_targets = _clone($self->standalone_dt_multi_drive_targets || []);
    my $internal_net_names = _clone($self->internal_net_names);
    my $instance_names = _clone($self->instance_names);

    my $result = {
        module_name => $self->module_name,
        source_root_kind => $self->source_root_kind,
        target_language => $self->target_language,
        output_drive_family_count => scalar(@$output_drive_families),
        output_drive_families => $output_drive_families,
        standalone_dt_multi_drive_target_count => scalar(@$standalone_dt_multi_drive_targets),
        standalone_dt_multi_drive_targets => $standalone_dt_multi_drive_targets,
    };

    if (defined $internal_net_names) {
        $result->{internal_net_count} = scalar(@{$internal_net_names || []});
        $result->{internal_net_names} = $internal_net_names;
    }

    if (defined $instance_names) {
        $result->{instance_count} = scalar(@{$instance_names || []});
        $result->{instance_names} = $instance_names;
    }

    $result->{auxiliary_assignment_count} = $self->auxiliary_assignment_count
        if defined $self->auxiliary_assignment_count;

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

FSM::IR::LoweredRTLIR - Explicit forward lowered RTL summary for `.fsm` generation

=head1 DESCRIPTION

This module provides the first extracted forward lowered-RTL summary surface used by
the active `.fsm` to HDL pipeline. It currently captures generated output-drive
families and standalone-DT grouped multi-drive targets so later lowering and
recovery-oriented work can consume one explicit normalized layer instead of
re-deriving that structure from mixed pipeline state.

=cut
