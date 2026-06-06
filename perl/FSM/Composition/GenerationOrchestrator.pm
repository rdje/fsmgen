package FSM::Composition::GenerationOrchestrator;

=head1 NAME

FSM::Composition::GenerationOrchestrator - Orchestrator for bounded composition generation

=head1 DESCRIPTION

Owns the remaining bounded composition generation orchestration that was still
inline in the mixed pipeline coordinator. This package takes an already-parsed
composition source, drives plan construction plus forward-IR assembly, emits
the structural top HDL text, and returns the bounded composition result
surface consumed by the outer pipeline.

=cut

use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures);
no warnings 'experimental::signatures';
use Storable qw(dclone);

use FSM::Backend::GeneratedModuleEmitter;
use FSM::Backend::VHDL::StructuralRTLIREmitter;
use FSM::Backend::VerilogFamily::StructuralRTLIREmitter;
use FSM::Composition::ChildExportBuilder;
use FSM::Composition::PackageImportResolver;
use FSM::Composition::PlanBuilder;
use FSM::Composition::ProvenanceReportBuilder;
use FSM::Composition::ResultMetadataBuilder;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::LoweredRTLIRBuilder;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::Pipeline::SourceFrontend;

sub generate_from_source ($class, %args) {
    my $pipeline = $args{pipeline}
        or confess "GenerationOrchestrator requires a pipeline";
    my $fsm_file = $args{fsm_file}
        or confess "GenerationOrchestrator requires an fsm_file";
    my $source_info = _clone($args{source_info} || {});
    my $raw_ast = $args{raw_ast};
    my $target_language = $args{target_language} // ($pipeline->{target_language} // 'systemverilog');
    my $header = $args{header} // ($source_info->{header} // '?top:name');
    my $composition_spec = $args{composition_spec}
        || $source_info->{composition_spec}
        || FSM::Pipeline::SourceFrontend->parse_composition_source(
            raw_ast => $raw_ast,
            debug_level => ($pipeline->{debug_level} // 0),
        );
    my $source_path_resolver = $args{source_path_resolver} // $pipeline->{source_path_resolver};
    my $rtl_interface_loader = $args{rtl_interface_loader} // $pipeline->{rtl_interface_loader};
    my $statistics_seed = $args{statistics_seed}
        // FSM::Backend::GeneratedModuleEmitter->statistics_from_generator(undef);

    $source_info->{composition_spec} = _clone($composition_spec);

    my $resolved_package_imports = $args{resolved_package_imports}
        || $source_info->{resolved_package_imports}
        || FSM::Composition::PackageImportResolver->resolve_imports(
            composition_spec => $composition_spec,
            fsm_file => $fsm_file,
            source_path_resolver => $source_path_resolver,
            debug_level => ($pipeline->{debug_level} // 0),
        );

    my $composition_plan = FSM::Composition::PlanBuilder->build_plan(
        pipeline => $pipeline,
        composition_spec => $composition_spec,
        fsm_file => $fsm_file,
        header => $header,
        target_language => $target_language,
        source_path_resolver => $source_path_resolver,
        rtl_interface_loader => $rtl_interface_loader,
    );
    my $structural_rtl_ir = FSM::IR::StructuralRTLIRBuilder->build_from_composition_plan(
        $composition_plan,
        $target_language,
    );
    my $composition_child_exports = FSM::Composition::ChildExportBuilder->build_child_exports(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => $target_language,
    );
    my $generated_child_exports = FSM::Composition::ChildExportBuilder->build_generated_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $standalone_dt_child_exports = FSM::Composition::ChildExportBuilder->build_standalone_dt_child_exports(
        composition_child_exports => $composition_child_exports,
    );
    my $intent_hir = FSM::IR::IntentHIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => $target_language,
    );
    my $composition_report = FSM::Composition::ProvenanceReportBuilder->build_report(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $target_language,
    );
    my $lowered_rtl_ir = FSM::IR::LoweredRTLIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => $target_language,
    );

    my @child_segments = grep { defined && length } map { $_->hdl_code } @{$composition_plan->instances};
    my @segments = @child_segments;
    if (($target_language // '') eq 'vhdl') {
        confess
            "Composition target support is blocked because generated-child VHDL composition is outside the first structural-top leaf. ".
            "Target language 'vhdl' is not implemented for this composition shape yet. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if @child_segments
                && !_is_bounded_standalone_dt_vhdl_top($composition_plan)
                && !_is_bounded_generated_fsm_c2_vhdl_top($composition_plan);
        push @segments, FSM::Backend::VHDL::StructuralRTLIREmitter->emit_module($structural_rtl_ir);
    } else {
        push @segments, FSM::Backend::VerilogFamily::StructuralRTLIREmitter->emit_module($structural_rtl_ir);
    }
    my $hdl_code = join("\n\n", grep { defined && length } @segments) . "\n";

    my $module_info = FSM::Composition::ResultMetadataBuilder->build_module_info(
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
    );
    my $statistics = FSM::Composition::ResultMetadataBuilder->build_statistics(
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        intent_hir => $intent_hir,
        lowered_rtl_ir => $lowered_rtl_ir,
        structural_rtl_ir => $structural_rtl_ir,
        statistics_seed => $statistics_seed,
    );

    return {
        fsm_module => undef,
        composition_spec => $composition_spec,
        composition_plan => $composition_plan,
        composition_report => $composition_report,
        intent_hir => $intent_hir->as_hashref,
        lowered_rtl_ir => $lowered_rtl_ir->as_hashref,
        structural_rtl_ir => $structural_rtl_ir->as_hashref,
        module_info => $module_info,
        hdl_code => $hdl_code,
        statistics => $statistics,
        resolved_package_imports => _clone($resolved_package_imports),
        raw_ast => _clone($raw_ast),
        source_info => $source_info,
    };
}
sub _clone ($value) {
    return undef unless defined $value;
    return [map { _clone($_) } @$value] if ref($value) eq 'ARRAY';
    return {map { $_ => _clone($value->{$_}) } keys %$value} if ref($value) eq 'HASH';
    return dclone($value) if ref($value);
    return $value;
}

sub _is_bounded_standalone_dt_vhdl_top ($composition_plan) {
    my @instances = @{$composition_plan->instances || []};
    return 0 unless @instances == 1;
    return 0 unless ($instances[0]->kind // '') eq 'dtc';
    return 0 if @{$composition_plan->nets || []};
    return 0 if @{$composition_plan->auxiliary_assignments || []};
    return 0 if @{$instances[0]->parameter_overrides || []};
    return 1;
}

sub _is_bounded_generated_fsm_c2_vhdl_top ($composition_plan) {
    return 0 unless ($composition_plan->lane // '') eq 'C2';
    my @instances = @{$composition_plan->instances || []};
    my @nets = @{$composition_plan->nets || []};
    my @ports = @{$composition_plan->ports || []};
    return 0 unless @instances == 2;
    return 0 unless @nets == 3;
    return 0 unless @ports == 3;
    return 0 if @{$composition_plan->auxiliary_assignments || []};

    for my $instance (@instances) {
        return 0 unless ($instance->kind // '') eq 'fsmc';
        return 0 if @{$instance->parameter_overrides || []};
    }

    for my $entry (@nets, @ports) {
        my $width = ref($entry) eq 'HASH' ? ($entry->{width} // 0) : $entry->width;
        return 0 unless $width == 1;
    }

    return 1;
}

1;

__END__

=head1 METHODS

=head2 generate_from_source

Builds the bounded composition generation result surface from parsed source
inputs, driving plan construction, forward-IR assembly, structural HDL
emission, and result-metadata assembly.

=cut
