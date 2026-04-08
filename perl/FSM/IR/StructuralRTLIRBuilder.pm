package FSM::IR::StructuralRTLIRBuilder;

=head1 NAME

FSM::IR::StructuralRTLIRBuilder - Builder and coercion helpers for forward StructuralRTLIR

=head1 DESCRIPTION

Builds and coerces the extracted forward C<StructuralRTLIR> layer. The current
shipped scope covers composition-top structural construction from
C<FSM::Composition::Plan>, bounded direct-root structural construction from
generated module analysis, and object/hash coercion for downstream pipeline and
backend consumers.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

sub build_from_generated_module_info ($class, %args) {
    my $module_info = $args{module_info}
        or confess "StructuralRTLIRBuilder requires a module_info";
    my $target_language = $args{target_language} // 'systemverilog';
    my $fsm_module = $args{fsm_module};

    my @ports;
    my %seen_ports;
    for my $bucket (
        [ inputs => 'input' ],
        [ outputs => 'output' ],
    ) {
        my ($analysis_key, $direction) = @$bucket;
        for my $entry (@{$module_info->{signal_analysis}{$analysis_key} || []}) {
            my $signal_name = $entry->{name};
            my $signal = ref($module_info->{signals}) eq 'HASH'
                ? $module_info->{signals}{$signal_name}
                : undef;
            my $type = (ref($signal) && $signal->can('type')) ? $signal->type : undef;
            my $signed = (ref($signal) && $signal->can('signed')) ? $signal->signed : 0;
            my $state_model = (ref($signal) && $signal->can('state_model')) ? $signal->state_model : undef;

            my $port_entry = {
                name => $signal_name,
                direction => $direction,
                width => ($entry->{width} || 1),
                signed => $signed ? 1 : 0,
                type => $type,
            };
            $port_entry->{state_model} = $state_model if defined $state_model;
            push @ports, $port_entry;
            $seen_ports{$signal_name} = 1;
        }
    }

    my $system_contract = $module_info->{system_contract} || {};
    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{clock}) && length($system_contract->{clock})
        && !$seen_ports{$system_contract->{clock}}) {
        push @ports, {
            name => $system_contract->{clock},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'clock',
        };
        $seen_ports{$system_contract->{clock}} = 1;
    }

    if (($module_info->{requires_implicit_system_ports} || $module_info->{explicit_system_contract})
        && defined($system_contract->{reset}) && length($system_contract->{reset})
        && !$seen_ports{$system_contract->{reset}}) {
        push @ports, {
            name => $system_contract->{reset},
            direction => 'input',
            width => 1,
            signed => 0,
            type => 'reset',
        };
        $seen_ports{$system_contract->{reset}} = 1;
    }

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($module_info->{module_name} // ''),
        source_root_kind => (
            $module_info->{source_root_kind}
                // ($fsm_module && $fsm_module->can('source_root_kind') ? $fsm_module->source_root_kind : 'fsm')
        ),
        target_language => $target_language,
        ports => \@ports,
        nets => [],
        instances => [],
        auxiliary_assignments => [],
    );
}

sub build_from_composition_plan ($class, $composition_plan, $target_language = 'systemverilog') {
    confess "StructuralRTLIRBuilder requires a composition plan"
        unless $composition_plan;

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => ($target_language // 'systemverilog'),
        ports => [
            map {
                do {
                    my $port_entry = {
                    name => $_->name,
                    direction => $_->direction,
                    width => $_->width,
                    signed => ($_->can('signed') ? $_->signed : 0),
                    type => $_->type,
                    binding_mode => $_->binding_mode,
                    origin_kind => $_->origin_kind,
                    };
                    my $state_model = $_->can('state_model') ? $_->state_model : undef;
                    $port_entry->{state_model} = $state_model if defined $state_model;
                    $port_entry;
                }
            } @{$composition_plan->ports || []}
        ],
        nets => [
            map {
                +{
                    name => $_->name,
                    width => $_->width,
                    source => $_->source,
                    targets => [@{$_->targets || []}],
                }
            } @{$composition_plan->nets || []}
        ],
        instances => [
            map {
                +{
                    kind => $_->kind,
                    instance_name => $_->instance_name,
                    module_name => $_->module_name,
                    source_name => $_->source_name,
                    interface_ports => [
                        map {
                            do {
                                my $interface_entry = {
                                name => $_->name,
                                direction => $_->direction,
                                width => $_->width,
                                signed => ($_->can('signed') ? $_->signed : 0),
                                type => $_->type,
                                };
                                my $state_model = $_->can('state_model') ? $_->state_model : undef;
                                $interface_entry->{state_model} = $state_model if defined $state_model;
                                $interface_entry;
                            }
                        } @{$_->interface_ports || []}
                    ],
                    port_bindings => [
                        map { normalized_binding($_) } @{$_->port_bindings || []}
                    ],
                }
            } @{$composition_plan->instances || []}
        ],
        declared_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->links || []}
        ],
        resolved_links => [
            map {
                +{
                    source => $_->source,
                    target => $_->target,
                    origin_kind => $_->origin_kind,
                    raw_token => $_->raw_token,
                }
            } @{$composition_plan->resolved_links || []}
        ],
        auxiliary_assignments => [@{$composition_plan->auxiliary_assignments || []}],
    );
}

sub coerce ($class, $structural_rtl_ir, $default_target_language = 'systemverilog') {
    return $structural_rtl_ir
        if blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref');

    my $structural_rtl_ir_hash = ref($structural_rtl_ir) eq 'HASH'
        ? $structural_rtl_ir
        : {};

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($structural_rtl_ir_hash->{module_name} // ''),
        source_root_kind => ($structural_rtl_ir_hash->{source_root_kind} // 'fsm'),
        target_language => ($structural_rtl_ir_hash->{target_language} // ($default_target_language // 'systemverilog')),
        ports => ($structural_rtl_ir_hash->{ports} || []),
        nets => ($structural_rtl_ir_hash->{nets} || []),
        instances => ($structural_rtl_ir_hash->{instances} || []),
        declared_links => ($structural_rtl_ir_hash->{declared_links} || []),
        resolved_links => ($structural_rtl_ir_hash->{resolved_links} || []),
        auxiliary_assignments => ($structural_rtl_ir_hash->{auxiliary_assignments} || []),
    );
}

1;

__END__

=head1 METHODS

=head2 build_from_generated_module_info

Builds a structural RTL IR object from generated direct-root module analysis,
preserving the module boundary ports and system-interface ports currently
materialized in the bounded direct structural slice.

=head2 build_from_composition_plan

Builds a structural RTL IR object from a realized composition plan, preserving
top ports, nets, instances, links, bindings, and auxiliary assignments.

=head2 coerce

Coerces a structural hash payload or existing structural object into a
C<FSM::IR::StructuralRTLIR> instance.

=cut
