package FSM::IR::IntentHIRBuilder;

=head1 NAME

FSM::IR::IntentHIRBuilder - Builder for bounded forward Intent HIR surfaces

=head1 DESCRIPTION

Owns the bounded forward Intent HIR construction paths that have been extracted
out of the mixed pipeline coordinator. Right now this package builds the
composition-top semantic summary from an already-built composition plan plus
the surrounding structural and child-export inputs.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::ChildExportBuilder;
use FSM::IR::IntentHIR;
use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIRBuilder;

sub build_from_composition_plan ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "IntentHIRBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';

    my $composition_child_exports = $args{composition_child_exports}
        // FSM::Composition::ChildExportBuilder->build_child_exports(
            composition_plan => $composition_plan,
            target_language => $target_language,
        );
    my $generated_child_exports = $args{generated_child_exports}
        // FSM::Composition::ChildExportBuilder->build_generated_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $standalone_dt_child_exports = $args{standalone_dt_child_exports}
        // FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
            composition_child_exports => $composition_child_exports,
        );
    my $structural_rtl_ir = $args{structural_rtl_ir}
        // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
            $composition_plan,
            $target_language,
        );

    my $port_metadata = FSM::IR::StructuralRTLIR->port_metadata_from_input($structural_rtl_ir);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) eq 'HASH'
        ? $structural_rtl_ir
        : ref($structural_rtl_ir)
            ? $structural_rtl_ir->as_hashref
            : {};

    return FSM::IR::IntentHIR->new(
        module_name => ($structural_rtl_ir_hash->{module_name} // $composition_plan->top_name // ''),
        source_root_kind => 'top',
        regular_state_names => [],
        standalone_dt_names => [],
        signal_names => $port_metadata->{signal_names},
        signal_analysis => $port_metadata->{signal_analysis},
        explicit_system_contract => undef,
        system_contract => {},
        requires_implicit_system_ports => 0,
        standalone_dt_enable_families => [],
        standalone_dt_module_enable_family => {},
        parameter_names => [],
        composition_child_count => $composition_child_exports->{child_count},
        composition_children => $composition_child_exports->{children},
        composition_generated_child_count => $generated_child_exports->{child_count},
        composition_generated_fsm_child_count => $generated_child_exports->{fsm_child_count},
        composition_generated_dt_child_count => $generated_child_exports->{dt_child_count},
        composition_generated_children => $generated_child_exports->{children},
        composition_standalone_dt_child_count => $standalone_dt_child_exports->{child_count},
        composition_standalone_dt_block_count => $standalone_dt_child_exports->{block_count},
        composition_standalone_dt_multi_drive_target_count => $standalone_dt_child_exports->{multi_drive_target_count},
        composition_standalone_dt_children => $standalone_dt_child_exports->{children},
        composition_lane => $composition_plan->lane,
    );
}

1;

__END__

=head1 METHODS

=head2 build_from_composition_plan

Builds the bounded composition-top L<FSM::IR::IntentHIR> object from an
already-built composition plan plus optional explicit structural and
child-export inputs.

=cut
