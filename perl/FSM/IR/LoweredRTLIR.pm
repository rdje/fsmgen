package FSM::IR::LoweredRTLIR;

=head1 NAME

FSM::IR::LoweredRTLIR - Explicit forward lowered RTL summary for C<.fsm> generation

=head1 DESCRIPTION

Represents the normalized lowered RTL layer in the forward compiler. This
package owns generated output-drive families, standalone-DT grouped multi-drive
targets, bounded composition shared-datapath summaries, and a few structural
accounting facts that later structural lowering and reporting consume.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
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
        composition_shared_datapath_candidates => _clone($args{composition_shared_datapath_candidates}),
        internal_net_names => _clone($args{internal_net_names}),
        instance_names => _clone($args{instance_names}),
        auxiliary_assignment_count => $args{auxiliary_assignment_count},
    }, $class;
}

sub module_name ($self) { return $self->{module_name} }
sub source_root_kind ($self) { return $self->{source_root_kind} }
sub target_language ($self) { return $self->{target_language} }
sub output_drive_families ($self) { return _clone($self->{output_drive_families}) }
sub standalone_dt_multi_drive_targets ($self) { return _clone($self->{standalone_dt_multi_drive_targets}) }
sub composition_shared_datapath_candidates ($self) { return _clone($self->{composition_shared_datapath_candidates}) }
sub internal_net_names ($self) { return _clone($self->{internal_net_names}) }
sub instance_names ($self) { return _clone($self->{instance_names}) }
sub auxiliary_assignment_count ($self) { return $self->{auxiliary_assignment_count} }

sub output_drive_families_from_input ($class, $lowered_rtl_ir) {
    my $output_drive_families = (
        blessed($lowered_rtl_ir) && $lowered_rtl_ir->can('output_drive_families')
            ? $lowered_rtl_ir->output_drive_families
            : ref($lowered_rtl_ir) eq 'HASH'
                ? $lowered_rtl_ir->{output_drive_families}
                : undef
    );

    return [] unless ref($output_drive_families) eq 'ARRAY';
    return _clone($output_drive_families);
}

sub output_drive_families_by_signal ($self) {
    my %families_by_signal;

    for my $family (@{$self->output_drive_families || []}) {
        next unless ref($family) eq 'HASH';
        my $signal_name = $family->{signal_name} || next;
        $families_by_signal{$signal_name} = _clone($family);
    }

    return \%families_by_signal;
}

sub output_drive_families_by_signal_from_input ($class, $lowered_rtl_ir) {
    my $output_drive_families = $class->output_drive_families_from_input($lowered_rtl_ir);
    my %families_by_signal;

    for my $family (@$output_drive_families) {
        next unless ref($family) eq 'HASH';
        my $signal_name = $family->{signal_name} || next;
        $families_by_signal{$signal_name} = _clone($family);
    }

    return \%families_by_signal;
}

sub output_drive_family ($self, $signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    return _clone($self->output_drive_families_by_signal->{$signal_name});
}

sub output_drive_family_from_input ($class, $lowered_rtl_ir, $signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    my $families_by_signal = $class->output_drive_families_by_signal_from_input($lowered_rtl_ir);
    return _clone($families_by_signal->{$signal_name});
}

sub standalone_dt_multi_drive_targets_from_input ($class, $lowered_rtl_ir) {
    my $targets = (
        blessed($lowered_rtl_ir) && $lowered_rtl_ir->can('standalone_dt_multi_drive_targets')
            ? $lowered_rtl_ir->standalone_dt_multi_drive_targets
            : ref($lowered_rtl_ir) eq 'HASH'
                ? $lowered_rtl_ir->{standalone_dt_multi_drive_targets}
                : undef
    );

    return [] unless ref($targets) eq 'ARRAY';
    return _clone($targets);
}

sub standalone_dt_multi_drive_targets_by_signal ($self) {
    my %targets_by_signal;

    for my $target (@{$self->standalone_dt_multi_drive_targets || []}) {
        next unless ref($target) eq 'HASH';
        my $signal_name = $target->{signal_name} || next;
        $targets_by_signal{$signal_name} = _clone($target);
    }

    return \%targets_by_signal;
}

sub standalone_dt_multi_drive_targets_by_signal_from_input ($class, $lowered_rtl_ir) {
    my $targets = $class->standalone_dt_multi_drive_targets_from_input($lowered_rtl_ir);
    my %targets_by_signal;

    for my $target (@$targets) {
        next unless ref($target) eq 'HASH';
        my $signal_name = $target->{signal_name} || next;
        $targets_by_signal{$signal_name} = _clone($target);
    }

    return \%targets_by_signal;
}

sub standalone_dt_multi_drive_target ($self, $signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    return _clone($self->standalone_dt_multi_drive_targets_by_signal->{$signal_name});
}

sub standalone_dt_multi_drive_target_from_input ($class, $lowered_rtl_ir, $signal_name) {
    return undef unless defined($signal_name) && length($signal_name);
    my $targets_by_signal = $class->standalone_dt_multi_drive_targets_by_signal_from_input($lowered_rtl_ir);
    return _clone($targets_by_signal->{$signal_name});
}

sub as_hashref ($self) {
    my $output_drive_families = _clone($self->output_drive_families || []);
    my $standalone_dt_multi_drive_targets = _clone($self->standalone_dt_multi_drive_targets || []);
    my $composition_shared_datapath_candidates = _clone($self->composition_shared_datapath_candidates);
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

    if (defined $composition_shared_datapath_candidates) {
        $result->{composition_shared_datapath_candidate_count}
            = scalar(@{$composition_shared_datapath_candidates || []});
        $result->{composition_shared_datapath_candidates}
            = $composition_shared_datapath_candidates;
    }

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

=head1 METHODS

=head2 new

Constructs a new lowered RTL IR object and clones the supplied lowered payload.

=head2 module_name

Returns the logical module name represented by this lowered layer.

=head2 source_root_kind

Returns the authored root kind that produced this lowered layer.

=head2 target_language

Returns the active backend target language attached to the lowered layer.

=head2 output_drive_families

Returns the normalized generated output-drive family list.

=head2 standalone_dt_multi_drive_targets

Returns the normalized standalone-DT grouped multi-drive target list.

=head2 composition_shared_datapath_candidates

Returns the bounded lowered shared-datapath candidate list for composition
tops.

=head2 internal_net_names

Returns the bounded internal net-name list exported by the lowered layer.

=head2 instance_names

Returns the bounded realized instance-name list exported by the lowered layer.

=head2 auxiliary_assignment_count

Returns the bounded auxiliary assignment count exported by the lowered layer.

=head2 output_drive_families_from_input

Extracts the output-drive family list from a lowered object or lowered-style
hash payload.

=head2 output_drive_families_by_signal

Returns the output-drive family list indexed by signal name.

=head2 output_drive_families_by_signal_from_input

Extracts a signal-indexed output-drive family map from a lowered object or
lowered-style hash payload.

=head2 output_drive_family

Returns one output-drive family entry by signal name.

=head2 output_drive_family_from_input

Extracts one output-drive family entry by signal name from a lowered object or
lowered-style hash payload.

=head2 standalone_dt_multi_drive_targets_from_input

Extracts the standalone-DT grouped multi-drive target list from a lowered
object or lowered-style hash payload.

=head2 standalone_dt_multi_drive_targets_by_signal

Returns the standalone-DT grouped multi-drive target list indexed by signal
name.

=head2 standalone_dt_multi_drive_targets_by_signal_from_input

Extracts a signal-indexed standalone-DT grouped multi-drive target map from a
lowered object or lowered-style hash payload.

=head2 standalone_dt_multi_drive_target

Returns one standalone-DT grouped multi-drive target entry by signal name.

=head2 standalone_dt_multi_drive_target_from_input

Extracts one standalone-DT grouped multi-drive target entry by signal name from
a lowered object or lowered-style hash payload.

=head2 as_hashref

Serializes the lowered layer into the exported hash shape used by downstream
pipeline and embedding surfaces.

=head2 _clone

Recursively clones nested hashes and arrays used by the lowered layer.

=cut
