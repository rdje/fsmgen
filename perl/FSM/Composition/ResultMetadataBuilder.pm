package FSM::Composition::ResultMetadataBuilder;

=head1 NAME

FSM::Composition::ResultMetadataBuilder - Builder for composition result metadata

=head1 DESCRIPTION

Builds the bounded composition result-metadata family used by the active
composition pipeline. This package owns the success-path C<module_info> and
C<statistics> assembly rules once composition planning, provenance reporting,
child-export projection, and the forward IR layers already exist.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::ChildExportBuilder;
use FSM::IR::StructuralRTLIR;

=head2 build_module_info

Builds the composition C<module_info> hash from one composition plan and the
already-built child-export, provenance, and forward IR surfaces.

=cut

sub build_module_info ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "ResultMetadataBuilder requires a composition_plan";
    my $composition_report = _clone($args{composition_report});
    my $composition_child_exports = _clone($args{composition_child_exports})
        || { child_count => 0, children => [] };
    my $generated_child_exports = _clone($args{generated_child_exports})
        || FSM::Composition::ChildExportBuilder->build_generated_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $standalone_dt_child_exports = _clone($args{standalone_dt_child_exports})
        || FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $intent_hir_hash = _as_hash($args{intent_hir});
    my $lowered_rtl_ir_hash = _as_hash($args{lowered_rtl_ir});
    my $structural_rtl_ir_hash = _as_hash($args{structural_rtl_ir});
    my $port_metadata = _port_metadata($args{structural_rtl_ir});

    return {
        module_name => $intent_hir_hash->{module_name},
        source_root_kind => $intent_hir_hash->{source_root_kind},
        regular_states => [],
        regular_state_count => $intent_hir_hash->{regular_state_count},
        regular_state_names => _clone($intent_hir_hash->{regular_state_names}),
        standalone_dts => [],
        standalone_dt_count => $intent_hir_hash->{standalone_dt_count},
        standalone_dt_names => _clone($intent_hir_hash->{standalone_dt_names}),
        signals => _clone($port_metadata->{signals}),
        signal_count => $intent_hir_hash->{signal_count},
        signal_names => _clone($intent_hir_hash->{signal_names}),
        signal_analysis => _clone($intent_hir_hash->{signal_analysis}),
        explicit_system_contract => _clone($intent_hir_hash->{explicit_system_contract}),
        system_contract => _clone($intent_hir_hash->{system_contract}),
        requires_implicit_system_ports => $intent_hir_hash->{requires_implicit_system_ports},
        parameter_count => $intent_hir_hash->{parameter_count},
        parameter_names => _clone($intent_hir_hash->{parameter_names}),
        symbol_contract => _clone($intent_hir_hash->{symbol_contract}),
        intent_hir => $intent_hir_hash,
        lowered_rtl_ir => $lowered_rtl_ir_hash,
        structural_rtl_ir => $structural_rtl_ir_hash,
        output_drive_family_count => $lowered_rtl_ir_hash->{output_drive_family_count},
        output_drive_families => _clone($lowered_rtl_ir_hash->{output_drive_families}),
        standalone_dt_multi_drive_target_count => $lowered_rtl_ir_hash->{standalone_dt_multi_drive_target_count},
        standalone_dt_multi_drive_targets => _clone($lowered_rtl_ir_hash->{standalone_dt_multi_drive_targets}),
        internal_net_count => (
            exists $lowered_rtl_ir_hash->{internal_net_count}
                ? $lowered_rtl_ir_hash->{internal_net_count}
                : (
                    exists $structural_rtl_ir_hash->{net_count}
                        ? $structural_rtl_ir_hash->{net_count}
                        : scalar(@{$composition_plan->nets || []})
                )
        ),
        internal_net_names => _clone(
            $lowered_rtl_ir_hash->{internal_net_names}
                || [ map { $_->{name} } @{$structural_rtl_ir_hash->{nets} || []} ]
                || [ map { $_->name } @{$composition_plan->nets || []} ]
        ),
        instance_count => (
            exists $lowered_rtl_ir_hash->{instance_count}
                ? $lowered_rtl_ir_hash->{instance_count}
                : (
                    exists $structural_rtl_ir_hash->{instance_count}
                        ? $structural_rtl_ir_hash->{instance_count}
                        : scalar(@{$composition_plan->instances || []})
                )
        ),
        instance_names => _clone(
            $lowered_rtl_ir_hash->{instance_names}
                || [ map { $_->{instance_name} } @{$structural_rtl_ir_hash->{instances} || []} ]
                || [ map { $_->instance_name } @{$composition_plan->instances || []} ]
        ),
        auxiliary_assignment_count => (
            exists $lowered_rtl_ir_hash->{auxiliary_assignment_count}
                ? $lowered_rtl_ir_hash->{auxiliary_assignment_count}
                : (
                    exists $structural_rtl_ir_hash->{auxiliary_assignment_count}
                        ? $structural_rtl_ir_hash->{auxiliary_assignment_count}
                        : scalar(@{$composition_plan->auxiliary_assignments || []})
                )
        ),
        state_count => $intent_hir_hash->{state_count},
        composition_child_count => (
            exists $intent_hir_hash->{composition_child_count}
                ? $intent_hir_hash->{composition_child_count}
                : (
                    exists $structural_rtl_ir_hash->{instance_count}
                        ? $structural_rtl_ir_hash->{instance_count}
                        : scalar(@{$composition_plan->instances || []})
                )
        ),
        composition_children => _clone(
            $intent_hir_hash->{composition_children}
                || $composition_child_exports->{children}
        ),
        composition_net_count => (
            exists $structural_rtl_ir_hash->{net_count}
                ? $structural_rtl_ir_hash->{net_count}
                : scalar(@{$composition_plan->nets || []})
        ),
        composition_resolved_link_count => $composition_report
            ? $composition_report->{resolved_link_count}
            : (
                exists $structural_rtl_ir_hash->{resolved_link_count}
                    ? $structural_rtl_ir_hash->{resolved_link_count}
                    : scalar(@{$composition_plan->resolved_links || []})
            ),
        composition_override_count => $composition_report
            ? $composition_report->{override_count}
            : 0,
        composition_block_count => $composition_report
            ? $composition_report->{block_count}
            : 0,
        composition_generated_child_count => (
            exists $intent_hir_hash->{composition_generated_child_count}
                ? $intent_hir_hash->{composition_generated_child_count}
                : 0
        ),
        composition_generated_fsm_child_count => (
            exists $intent_hir_hash->{composition_generated_fsm_child_count}
                ? $intent_hir_hash->{composition_generated_fsm_child_count}
                : 0
        ),
        composition_generated_dt_child_count => (
            exists $intent_hir_hash->{composition_generated_dt_child_count}
                ? $intent_hir_hash->{composition_generated_dt_child_count}
                : 0
        ),
        composition_generated_children => _clone(
            $intent_hir_hash->{composition_generated_children} || $generated_child_exports->{children} || []
        ),
        composition_standalone_dt_child_count => (
            exists $intent_hir_hash->{composition_standalone_dt_child_count}
                ? $intent_hir_hash->{composition_standalone_dt_child_count}
                : $standalone_dt_child_exports->{child_count}
        ),
        composition_standalone_dt_block_count => (
            exists $intent_hir_hash->{composition_standalone_dt_block_count}
                ? $intent_hir_hash->{composition_standalone_dt_block_count}
                : $standalone_dt_child_exports->{block_count}
        ),
        composition_standalone_dt_multi_drive_target_count => (
            exists $intent_hir_hash->{composition_standalone_dt_multi_drive_target_count}
                ? $intent_hir_hash->{composition_standalone_dt_multi_drive_target_count}
                : $standalone_dt_child_exports->{multi_drive_target_count}
        ),
        composition_standalone_dt_children => _clone(
            $intent_hir_hash->{composition_standalone_dt_children}
                || $standalone_dt_child_exports->{children}
        ),
        composition_shared_datapath_candidate_count => (
            exists $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
                ? $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
                : 0
        ),
        composition_shared_datapath_candidates => _clone(
            $lowered_rtl_ir_hash->{composition_shared_datapath_candidates} || []
        ),
        composition_lane => (
            $intent_hir_hash->{composition_lane}
                // $composition_plan->lane
        ),
        composition_provenance => $composition_report,
    };
}

=head2 build_statistics

Builds the composition C<statistics> hash from one composition plan and the
already-built provenance and forward IR surfaces.

=cut

sub build_statistics ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "ResultMetadataBuilder requires a composition_plan";
    my $composition_report = _clone($args{composition_report});
    my $intent_hir_hash = _as_hash($args{intent_hir});
    my $lowered_rtl_ir_hash = _as_hash($args{lowered_rtl_ir});
    my $structural_rtl_ir_hash = _as_hash($args{structural_rtl_ir});
    my $stats = _clone($args{statistics_seed} || _default_statistics_seed());

    $stats->{composition_child_count} = exists $structural_rtl_ir_hash->{instance_count}
        ? $structural_rtl_ir_hash->{instance_count}
        : scalar(@{$composition_plan->instances || []});
    $stats->{composition_top_port_count} = exists $structural_rtl_ir_hash->{port_count}
        ? $structural_rtl_ir_hash->{port_count}
        : scalar(@{$composition_plan->ports || []});
    $stats->{composition_net_count} = exists $structural_rtl_ir_hash->{net_count}
        ? $structural_rtl_ir_hash->{net_count}
        : scalar(@{$composition_plan->nets || []});
    $stats->{composition_resolved_link_count} = $composition_report
        ? $composition_report->{resolved_link_count}
        : (
            exists $structural_rtl_ir_hash->{resolved_link_count}
                ? $structural_rtl_ir_hash->{resolved_link_count}
                : scalar(@{$composition_plan->resolved_links || []})
        );
    $stats->{composition_override_count} = $composition_report
        ? $composition_report->{override_count}
        : 0;
    $stats->{composition_block_count} = $composition_report
        ? $composition_report->{block_count}
        : 0;
    $stats->{composition_shared_datapath_candidate_count} = (
        exists $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
            ? $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
            : scalar(@{_shared_datapath_candidates($composition_plan)})
    );
    $stats->{composition_lane} = $intent_hir_hash->{composition_lane} // $composition_plan->lane;
    $stats->{composition_provenance} = $composition_report if $composition_report;

    return $stats;
}

=head2 _port_metadata

Projects structural top-port metadata from one structural RTL IR input.

=cut

sub _port_metadata ($input) {
    return {
        signals => {},
        signal_names => [],
        signal_analysis => [],
    } unless defined $input;

    return FSM::IR::StructuralRTLIR->port_metadata_from_input($input);
}

=head2 _shared_datapath_candidates

Returns the already-attached shared-datapath candidates carried by one
composition plan.

=cut

sub _shared_datapath_candidates ($composition_plan) {
    return [] unless $composition_plan;
    return [] unless $composition_plan->can('shared_datapath_candidates');
    return $composition_plan->shared_datapath_candidates || [];
}

=head2 _as_hash

Normalizes object-or-hash forward IR inputs into cloned hash payloads.

=cut

sub _as_hash ($value) {
    return {} unless defined $value;
    if (ref($value) && ref($value) ne 'HASH' && $value->can('as_hashref')) {
        return _clone($value->as_hashref);
    }
    return _clone($value) if ref($value) eq 'HASH';
    return {};
}

=head2 _default_statistics_seed

Builds the bounded non-generated composition statistics seed used before
composition-specific counters are filled in.

=cut

sub _default_statistics_seed () {
    return {
        intermediate_signals => 0,
        global_expressions => 0,
        reused_expressions => [],
        factoring_enabled => 0,
    };
}

=head2 _clone

Recursively clones hash and array payloads used in result-metadata structures.

=cut

sub _clone ($value) {
    return undef unless defined $value;
    if (ref($value) eq 'HASH') {
        return { map { $_ => _clone($value->{$_}) } sort keys %$value };
    }
    if (ref($value) eq 'ARRAY') {
        return [ map { _clone($_) } @$value ];
    }
    return $value;
}

1;
