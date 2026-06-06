package FSM::Composition::ChildExportBuilder;

=head1 NAME

FSM::Composition::ChildExportBuilder - Builder for composition child export summaries

=head1 DESCRIPTION

Builds the bounded composition child-export family used by the active
composition pipeline. This package owns the unified realized-child export
surface plus the narrower generated-child and standalone-DT child views that
later intent/module-info/reporting consumers reuse.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::IR::LoweredRTLIR;
use FSM::IR::StructuralRTLIRBuilder;

sub build_child_exports ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "ChildExportBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';
    my $structural_rtl_ir_input = $args{structural_rtl_ir}
        // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
            $composition_plan,
            $target_language,
        );
    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->coerce(
        $structural_rtl_ir_input,
        $target_language,
    );

    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;
    my %instances_by_name = map {
        (($_->instance_name // '') => $_)
    } @{$composition_plan->instances || []};
    my @children;

    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        my $planned_instance = $instances_by_name{$instance->{instance_name} // ''};
        my $child_info = $planned_instance ? ($planned_instance->module_info || {}) : {};
        my $intent_hir = _module_intent_hir($child_info);
        my $lowered_rtl_ir = _module_lowered_rtl_ir($child_info);
        my $child_structural_rtl_ir = _module_structural_rtl_ir($child_info);
        my $kind = $instance->{kind} || ($planned_instance ? ($planned_instance->kind || '') : '');

        push @children, {
            kind => $kind,
            instance_name => ($instance->{instance_name} // ''),
            module_name => ($instance->{module_name} // ''),
            source_name => ($instance->{source_name} // $instance->{module_name} // ''),
            source_root_kind => (
                $intent_hir->{source_root_kind}
                    // $child_info->{source_root_kind}
                    // ($kind eq 'dtc' ? 'dt'
                        : ($kind eq 'fsmc' ? 'fsm'
                            : ($kind eq 'rtl' ? 'rtl' : 'unknown_root')))
            ),
            regular_state_count => ($intent_hir->{regular_state_count} || 0),
            standalone_dt_count => ($intent_hir->{standalone_dt_count} || 0),
            output_drive_family_count => ($lowered_rtl_ir->{output_drive_family_count} || 0),
            standalone_dt_multi_drive_target_count => ($lowered_rtl_ir->{standalone_dt_multi_drive_target_count} || 0),
            parameter_override_count => scalar(@{$instance->{parameter_overrides} || []}),
            parameter_overrides => _clone($instance->{parameter_overrides} || []),
            intent_hir => $intent_hir,
            lowered_rtl_ir => $lowered_rtl_ir,
            structural_rtl_ir => $child_structural_rtl_ir,
        };
    }

    return {
        child_count => scalar(@children),
        children => \@children,
    };
}

sub build_generated_child_exports ($class, %args) {
    my $composition_child_exports = $args{composition_child_exports}
        // $class->build_child_exports(%args);
    my @children;
    my $fsm_child_count = 0;
    my $dt_child_count = 0;

    for my $child (@{$composition_child_exports->{children} || []}) {
        my $kind = $child->{kind} || '';
        next unless $kind eq 'fsmc' || $kind eq 'dtc';

        push @children, {
            kind => $kind,
            instance_name => $child->{instance_name},
            module_name => $child->{module_name},
            source_name => $child->{source_name},
            source_root_kind => $child->{source_root_kind},
            regular_state_count => ($child->{regular_state_count} || 0),
            standalone_dt_count => ($child->{standalone_dt_count} || 0),
            output_drive_family_count => ($child->{output_drive_family_count} || 0),
            standalone_dt_multi_drive_target_count => ($child->{standalone_dt_multi_drive_target_count} || 0),
            parameter_override_count => ($child->{parameter_override_count} || 0),
            parameter_overrides => _clone($child->{parameter_overrides} || []),
            intent_hir => _clone($child->{intent_hir} || {}),
            lowered_rtl_ir => _clone($child->{lowered_rtl_ir} || {}),
            structural_rtl_ir => _clone($child->{structural_rtl_ir} || {}),
        };

        $fsm_child_count++ if $kind eq 'fsmc';
        $dt_child_count++ if $kind eq 'dtc';
    }

    return {
        child_count => scalar(@children),
        fsm_child_count => $fsm_child_count,
        dt_child_count => $dt_child_count,
        children => \@children,
    };
}

sub build_standalone_dt_child_exports ($class, %args) {
    my $composition_child_exports = $args{composition_child_exports}
        // $class->build_child_exports(%args);
    my @children;
    my $block_count = 0;
    my $multi_drive_target_count = 0;

    for my $child (@{$composition_child_exports->{children} || []}) {
        next unless (($child->{kind} || '') eq 'dtc');

        my $intent_hir = $child->{intent_hir} || {};
        my $lowered_rtl_ir = $child->{lowered_rtl_ir} || {};
        my @enable_families = map {
            +{
                dt_name => $_->{dt_name},
                enable_signal => $_->{enable_signal},
            }
        } @{$intent_hir->{standalone_dt_enable_families} || []};

        my $module_enable_family = $intent_hir->{standalone_dt_module_enable_family} || {};
        my @multi_drive_targets = map {
            my $assertion = $_->{multi_drive_assertion} || {};
            +{
                signal_name => $_->{signal_name},
                multiplexer_type => $_->{multiplexer_type},
                dt_names => [@{$_->{dt_names} || []}],
                rhs_values => [@{$_->{rhs_values} || []}],
                dt_enable_signals => [@{$_->{dt_enable_signals} || []}],
                lhs_enable_signals => [@{$_->{lhs_enable_signals} || []}],
                multi_drive_assertion => {
                    %{$assertion},
                    input_enable_signals => [@{$assertion->{input_enable_signals} || []}],
                },
            }
        } @{FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_targets_from_input($lowered_rtl_ir)};

        my $standalone_dt_count = $child->{standalone_dt_count} || 0;
        my $child_multi_drive_target_count = $child->{standalone_dt_multi_drive_target_count} || 0;

        push @children, {
            instance_name => $child->{instance_name},
            module_name => $child->{module_name},
            source_name => $child->{source_name},
            intent_hir => _clone($intent_hir),
            lowered_rtl_ir => _clone($lowered_rtl_ir),
            structural_rtl_ir => _clone($child->{structural_rtl_ir} || {}),
            standalone_dt_count => $standalone_dt_count,
            standalone_dt_names => [@{$intent_hir->{standalone_dt_names} || []}],
            standalone_dt_enable_families => \@enable_families,
            standalone_dt_module_enable_family => {
                dt_names => [@{$module_enable_family->{dt_names} || []}],
                enable_signals => [@{$module_enable_family->{enable_signals} || []}],
            },
            standalone_dt_multi_drive_target_count => $child_multi_drive_target_count,
            standalone_dt_multi_drive_targets => \@multi_drive_targets,
        };

        $block_count += $standalone_dt_count;
        $multi_drive_target_count += $child_multi_drive_target_count;
    }

    return {
        child_count => scalar(@children),
        block_count => $block_count,
        multi_drive_target_count => $multi_drive_target_count,
        children => \@children,
    };
}

sub _module_intent_hir ($module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone($module_info->{intent_hir} || {});
}

sub _module_lowered_rtl_ir ($module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone($module_info->{lowered_rtl_ir} || {});
}

sub _module_structural_rtl_ir ($module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone($module_info->{structural_rtl_ir} || {});
}

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

__END__

=head1 METHODS

=head2 build_child_exports

Builds the unified realized-child export surface for one composition plan.

=head2 build_generated_child_exports

Builds the narrower generated-child view over the unified realized-child export
surface.

=head2 build_standalone_dt_child_exports

Builds the standalone-DT-specific child export view over the unified
realized-child export surface.

=head2 _module_intent_hir

Clones the child semantic IR payload from one child C<module_info> hash.

=head2 _module_lowered_rtl_ir

Clones the child lowered RTL IR payload from one child C<module_info> hash.

=head2 _module_structural_rtl_ir

Clones the child structural RTL IR payload from one child C<module_info> hash.

=head2 _clone

Recursively clones hash and array payloads used in child export structures.

=cut
