package FSM::IR::StructuralRTLIRBuilder;

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(normalized_binding);

sub build_from_composition_plan ($class, $composition_plan, $target_language = 'systemverilog') {
    confess "StructuralRTLIRBuilder requires a composition plan"
        unless $composition_plan;

    return FSM::IR::StructuralRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => ($target_language // 'systemverilog'),
        ports => [
            map {
                +{
                    name => $_->name,
                    direction => $_->direction,
                    width => $_->width,
                    type => $_->type,
                    binding_mode => $_->binding_mode,
                    origin_kind => $_->origin_kind,
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
                            +{
                                name => $_->name,
                                direction => $_->direction,
                                width => $_->width,
                                type => $_->type,
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

=head1 NAME

FSM::IR::StructuralRTLIRBuilder - Builder/coercion helpers for forward StructuralRTLIR

=head1 DESCRIPTION

This module owns the active construction and coercion helpers for the extracted
forward C<StructuralRTLIR> layer. It currently covers composition-top
construction from C<FSM::Composition::Plan> plus object/hash coercion for later
pipeline and backend consumers, so the pipeline coordinator no longer owns that
structural assembly code directly.

=cut
