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
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub target_language ($self) { return $self->{target_language} }
sub output_drive_families ($self) { return $self->{output_drive_families} }
sub standalone_dt_multi_drive_targets ($self) { return $self->{standalone_dt_multi_drive_targets} }

sub as_hashref ($self) {
    my $output_drive_families = _clone($self->output_drive_families || []);
    my $standalone_dt_multi_drive_targets = _clone($self->standalone_dt_multi_drive_targets || []);

    return {
        module_name => $self->module_name,
        source_root_kind => $self->source_root_kind,
        target_language => $self->target_language,
        output_drive_family_count => scalar(@$output_drive_families),
        output_drive_families => $output_drive_families,
        standalone_dt_multi_drive_target_count => scalar(@$standalone_dt_multi_drive_targets),
        standalone_dt_multi_drive_targets => $standalone_dt_multi_drive_targets,
    };
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
