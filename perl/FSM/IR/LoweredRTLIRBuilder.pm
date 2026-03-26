package FSM::IR::LoweredRTLIRBuilder;

=head1 NAME

FSM::IR::LoweredRTLIRBuilder - Builder for bounded forward LoweredRTLIR surfaces

=head1 DESCRIPTION

Owns the bounded forward Lowered RTL IR construction paths that have been
extracted out of the mixed pipeline coordinator. Right now this package builds
the composition-top lowered summary from an already-built composition plan plus
the surrounding structural, semantic, and shared-datapath inputs.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::IR::LoweredRTLIR;
use FSM::IR::StructuralRTLIRBuilder;

sub build_from_composition_plan ($class, %args) {
    my $composition_plan = $args{composition_plan}
        or confess "LoweredRTLIRBuilder requires a composition_plan";
    my $target_language = $args{target_language} // 'systemverilog';

    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->coerce(
        $args{structural_rtl_ir}
            // FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
                $composition_plan,
                $target_language,
            ),
        $target_language,
    );
    my $shared_datapath_candidates = $args{shared_datapath_candidates}
        // FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
            composition_plan => $composition_plan,
            structural_rtl_ir => $structural_rtl_ir,
            intent_hir => $args{intent_hir},
            target_language => $target_language,
        );
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;
    my $internal_net_names = [
        map { $_->{name} }
        @{$structural_rtl_ir_hash->{nets} || []}
    ];
    my $instance_names = [
        map { $_->{instance_name} }
        @{$structural_rtl_ir_hash->{instances} || []}
    ];

    return FSM::IR::LoweredRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => $target_language,
        output_drive_families => [],
        standalone_dt_multi_drive_targets => [],
        composition_shared_datapath_candidates => $shared_datapath_candidates,
        internal_net_names => $internal_net_names,
        instance_names => $instance_names,
        auxiliary_assignment_count => scalar(@{$structural_rtl_ir_hash->{auxiliary_assignments} || []}),
    );
}

1;

__END__

=head1 METHODS

=head2 build_from_composition_plan

Builds the bounded composition-top L<FSM::IR::LoweredRTLIR> object from an
already-built composition plan plus optional explicit structural, semantic,
and shared-datapath inputs.

=cut
