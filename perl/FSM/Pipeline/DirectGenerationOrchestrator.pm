package FSM::Pipeline::DirectGenerationOrchestrator;

=head1 NAME

FSM::Pipeline::DirectGenerationOrchestrator - Orchestrator for bounded direct-root generation

=head1 DESCRIPTION

Owns the bounded non-composition generation orchestration that was still inline
in C<FSM::Pipeline::HDLGenerator>. This package takes parsed direct-root
source, drives semantic module creation plus forward-IR extraction, invokes the
existing direct HDL backend path, and returns the bounded direct-generation
result surface consumed by the outer pipeline.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';

sub generate_from_source ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "DirectGenerationOrchestrator requires a pipeline";
    my $raw_ast = $args{raw_ast}
        or confess "DirectGenerationOrchestrator requires a raw_ast";
    my $source_info = $args{source_info}
        || $pipeline->classify_source_ast($raw_ast);

    my $fsm_module = $pipeline->create_fsm_module($raw_ast);
    my $intent_hir = $pipeline->build_intent_hir($fsm_module);
    my $module_info = $pipeline->analyze_fsm_module($fsm_module, $intent_hir);

    my $hdl_code = $pipeline->generate_hdl_code($fsm_module);
    $pipeline->enrich_module_info_from_generated_analysis($module_info, $fsm_module);
    my $structural_rtl_ir = $pipeline->build_structural_rtl_ir($module_info, $fsm_module);
    $module_info->{structural_rtl_ir} = $structural_rtl_ir->as_hashref;
    $hdl_code = $pipeline->augment_generated_hdl_with_standalone_dt_assertions($hdl_code, $module_info);

    my $statistics = $pipeline->gather_statistics($fsm_module);

    return {
        fsm_module => $fsm_module,
        intent_hir => $intent_hir->as_hashref,
        lowered_rtl_ir => $module_info->{lowered_rtl_ir},
        structural_rtl_ir => $module_info->{structural_rtl_ir},
        module_info => $module_info,
        hdl_code => $hdl_code,
        statistics => $statistics,
        raw_ast => $raw_ast,
        source_info => $source_info,
    };
}

1;

__END__

=head1 METHODS

=head2 generate_from_source

Builds the bounded direct-root generation result surface from parsed source
input, driving semantic module creation, forward-IR extraction, direct HDL
generation, module-info enrichment, and statistics collection.

=cut
