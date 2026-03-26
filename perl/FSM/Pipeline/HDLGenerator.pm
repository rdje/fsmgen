#!/usr/bin/perl

package FSM::Pipeline::HDLGenerator;
use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin";
use FSM::Backend::GeneratedModuleEmitter;
use FSM::Debug;
use FSM::Adapter::FSMGenFull;
use FSM::Composition::FailureReportBuilder;
use FSM::Composition::Parser;
use FSM::Composition::ProvenanceReportBuilder;
use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Extension::Loader;
use FSM::Extension::Registry;
use FSM::IR::IntentHIR;
use FSM::IR::IntentHIRBuilder;
use FSM::IR::LoweredRTLIR;
use FSM::IR::LoweredRTLIRBuilder;
use FSM::IR::StructuralRTLIR;
use FSM::IR::StructuralRTLIRBuilder;
use FSM::IR::StructuralRTLIR::ConnectionExpr qw(
    signal_ref_expr
    signal_ref_binding
    update_binding_signal_ref
    binding_expr
    expr_signal_name
);
use FSM::Pipeline::SourceGenerationOrchestrator;
use FSM::SourceClassifier;
use FSM::SourcePathResolver;
use Lispish;
use Data::Dumper;

=head1 NAME

FSM::Pipeline::HDLGenerator - Complete FSM to HDL generation pipeline

=head1 DESCRIPTION

This module encapsulates the entire FSM processing pipeline from parsing
the FSM file through generating HDL code. It provides a clean interface
that separates the processing logic from the command line interface.

=head1 SYNOPSIS

    use FSM::Pipeline::HDLGenerator;
    
    my $pipeline = FSM::Pipeline::HDLGenerator->new(
        debug_level => 2,
        target_language => 'systemverilog'
    );
    
    my $result = $pipeline->generate_hdl_from_file($fsm_file);
    
    print "HDL Code:\n";
    print $result->{hdl_code};

=cut

sub new ($class, %args) {
    fsm_trace_enter('Initialize HDLGenerator pipeline', 2);
    my $source_path_resolver = $args{source_path_resolver}
        // FSM::SourcePathResolver->new(
            extra_search_paths => ($args{source_search_paths} || []),
        );
    my $extension_loader = $args{extension_loader}
        // FSM::Extension::Loader->new();
    my $extension_registry = $args{extension_registry};
    unless ($extension_registry) {
        my $config_module_names = $extension_loader->module_names_from_config_files(
            $args{extension_config_files} || [],
        );
        my @extension_module_names = (
            @{ $args{extension_modules} || [] },
            @$config_module_names,
        );
        my $loaded_extensions = $extension_loader->load_modules(
            \@extension_module_names,
        );
        my @extensions = (
            @{ $args{extensions} || [] },
            @$loaded_extensions,
        );
        $extension_registry = FSM::Extension::Registry->new(
            extensions => \@extensions,
        );
    }
    my $self = bless {
        debug_level => $args{debug_level} // 0,
        target_language => $args{target_language} // 'systemverilog',
        quiet => $args{quiet} // 0,
        source_path_resolver => $source_path_resolver,
        rtl_interface_loader => $args{rtl_interface_loader}
            // FSM::Composition::RTLInterfaceLoader->new(
                debug => ($args{debug_level} // 0) > 0,
                path_resolver => $source_path_resolver,
            ),
        extension_loader => $extension_loader,
        extension_registry => $extension_registry,
    }, $class;
    
    # Initialize debug system
    set_fsm_debug_level($self->{debug_level});
    
    fsm_debug("HDL generation pipeline initialized", 1);
    fsm_debug("  Debug level: $self->{debug_level}", 1);
    fsm_debug("  Target language: $self->{target_language}", 1);
    
    fsm_trace_exit('HDLGenerator pipeline initialized', 2);
    return $self;
}

sub generate_hdl_from_file ($self, $fsm_file) {
    return FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $self,
        fsm_file => $fsm_file,
    );
}

sub parse_fsm_file ($self, $fsm_file) {
    fsm_trace_enter('Parse FSM file with Lispish', 2);
    fsm_debug("Parsing FSM file with Lispish parser", 1);
    
    my $raw_ast = Lispish::multi($fsm_file);
    
    unless ($raw_ast) {
        fsm_trace_decision(0, "Lispish parser returned undefined AST for '$fsm_file'", 1);
        Carp::confess "Error: Failed to parse FSM file with Lispish\n";
    }
    
    # Debug: Dump the raw AST if debug mode is enabled
    if ($self->{debug_level} > 0) {
        fsm_debug("Raw AST structure:", 2);
        if ($self->{debug_level} >= 3) {
            # Only dump full AST at very detailed level to avoid overwhelming output
            $Data::Dumper::Maxdepth = 0;
            $Data::Dumper::Indent = 1;
            my $dumped = Dumper($raw_ast);
            fsm_debug("Full raw AST dump:\n$dumped", 3);
        }
    }
    
    fsm_debug("FSM file parsed successfully", 1);
    fsm_trace_exit('FSM file parsed', 2);
    return $raw_ast;
}

sub classify_source_ast ($self, $raw_ast) {
    return FSM::SourceClassifier::classify_source_ast($raw_ast);
}

sub parse_composition_source ($self, $raw_ast) {
    my $parser = FSM::Composition::Parser->new(
        debug => ($self->{debug_level} > 0),
    );
    return $parser->parse_source($raw_ast);
}

sub create_fsm_module ($self, $raw_ast) {
    fsm_trace_enter('Build semantic FSM module from raw AST', 2);
    fsm_debug("Creating semantic FSM module from raw AST", 1);
    
    # Create FSMGen adapter to convert to semantic AST
    my $adapter = FSM::Adapter::FSMGenFull->new(debug => ($self->{debug_level} > 0));
    
    # Parse the raw AST
    my $fsm_module;
    eval {
        $fsm_module = $adapter->parse_fsm($raw_ast);
    };
    
    if ($@) {
        fsm_trace_decision(0, 'Adapter parse_fsm() raised exception', 1);
        Carp::confess "Error parsing FSM with adapter: $@\n";
    }
    
    unless ($fsm_module) {
        fsm_trace_decision(0, 'Adapter parse_fsm() returned undefined module', 1);
        Carp::confess "Error: Failed to create FSM module\n";
    }
    
    # Debug: Dump the parsed FSM module structure if debug mode is enabled
    if ($self->{debug_level} > 1 && $fsm_module) {
        fsm_debug("Semantic FSM module created successfully", 1);
        if ($self->{debug_level} >= 3) {
            # Only dump full module at very detailed level
            $Data::Dumper::Maxdepth = 0;
            $Data::Dumper::Indent = 1;
            my $dumped = Dumper($fsm_module);
            fsm_debug("Full FSM module AST dump:\n$dumped", 3);
        }
    }
    
    fsm_debug("FSM module created successfully", 1);
    fsm_trace_exit('Semantic FSM module created', 2);
    return $fsm_module;
}

sub standalone_dt_assertion_runtime_lines ($self, $module_info) {
    return FSM::Backend::GeneratedModuleEmitter->standalone_dt_assertion_runtime_lines(
        module_info => $module_info,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub augment_generated_hdl_with_standalone_dt_assertions ($self, $hdl_code, $module_info) {
    return FSM::Backend::GeneratedModuleEmitter->augment_with_standalone_dt_assertions(
        hdl_code => $hdl_code,
        module_info => $module_info,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub shared_datapath_or_expression ($self, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return "1'b0" unless @inputs;
    return $inputs[0] if @inputs == 1;
    return join(' | ', @inputs);
}

sub shared_datapath_conflict_expression ($self, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return "1'b0" if @inputs < 2;

    my @pairs;
    for my $i (0 .. $#inputs - 1) {
        for my $j ($i + 1 .. $#inputs) {
            push @pairs, "($inputs[$i] & $inputs[$j])";
        }
    }

    return join(' | ', @pairs);
}

sub composition_shared_datapath_candidates_for_plan ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    return FSM::Composition::SharedDatapathCandidateBuilder->candidates_for_plan(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub build_composition_intent_hir (
    $self,
    $composition_plan,
    $composition_child_exports = undef,
    $generated_child_exports = undef,
    $standalone_dt_child_exports = undef,
    $structural_rtl_ir = undef,
) {
    return FSM::IR::IntentHIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        composition_child_exports => $composition_child_exports,
        generated_child_exports => $generated_child_exports,
        standalone_dt_child_exports => $standalone_dt_child_exports,
        structural_rtl_ir => $structural_rtl_ir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub build_composition_lowered_rtl_ir ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    return FSM::IR::LoweredRTLIRBuilder->build_from_composition_plan(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub composition_provenance_endpoint_context ($self, $composition_plan, $endpoint, $structural_rtl_ir = undef, $intent_hir = undef) {
    $intent_hir //= $self->build_composition_intent_hir(
        $composition_plan,
        undef,
        undef,
        undef,
        $structural_rtl_ir,
    );
    return FSM::Composition::ProvenanceReportBuilder->endpoint_context(
        composition_plan => $composition_plan,
        endpoint => $endpoint,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub composition_provenance_endpoint_example_label ($self, $context, $fallback = undef) {
    return FSM::Composition::ProvenanceReportBuilder->endpoint_example_label($context, $fallback);
}

sub composition_port_example_summary ($self, $entry) {
    return FSM::Composition::ProvenanceReportBuilder->port_example_summary($entry);
}

sub composition_link_example_summary ($self, $entry) {
    return FSM::Composition::ProvenanceReportBuilder->link_example_summary($entry);
}

sub composition_signal_family_contexts ($self, $composition_plan, $signal_name, $direction = undef, $structural_rtl_ir = undef, $intent_hir = undef) {
    $intent_hir //= $self->build_composition_intent_hir(
        $composition_plan,
        undef,
        undef,
        undef,
        $structural_rtl_ir,
    );
    return FSM::Composition::ProvenanceReportBuilder->signal_family_contexts(
        composition_plan => $composition_plan,
        signal_name => $signal_name,
        direction => $direction,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub build_composition_override_events ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    $intent_hir //= $self->build_composition_intent_hir(
        $composition_plan,
        undef,
        undef,
        undef,
        $structural_rtl_ir,
    );
    return FSM::Composition::ProvenanceReportBuilder->build_override_events(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub build_composition_block_events ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    $intent_hir //= $self->build_composition_intent_hir(
        $composition_plan,
        undef,
        undef,
        undef,
        $structural_rtl_ir,
    );
    return FSM::Composition::ProvenanceReportBuilder->build_block_events(
        composition_plan => $composition_plan,
        structural_rtl_ir => $structural_rtl_ir,
        intent_hir => $intent_hir,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub composition_provenance_category ($self, $origin_kind) {
    return FSM::Composition::ProvenanceReportBuilder->provenance_category($origin_kind);
}

sub composition_provenance_sort_key ($self, $origin_kind) {
    return FSM::Composition::ProvenanceReportBuilder->provenance_sort_key($origin_kind);
}

sub composition_provenance_label ($self, $origin_kind) {
    return FSM::Composition::ProvenanceReportBuilder->provenance_label($origin_kind);
}

sub composition_override_label ($self, $kind) {
    return FSM::Composition::ProvenanceReportBuilder->override_label($kind);
}

sub composition_override_example_summary ($self, $event) {
    return FSM::Composition::ProvenanceReportBuilder->override_example_summary($event);
}

sub composition_block_label ($self, $kind) {
    return FSM::Composition::ProvenanceReportBuilder->block_label($kind);
}

sub composition_block_example_summary ($self, $event) {
    return FSM::Composition::ProvenanceReportBuilder->block_example_summary($event);
}

sub build_composition_failure_report ($self, $error_text) {
    return FSM::Composition::FailureReportBuilder->build_report($error_text);
}

sub build_intent_hir ($self, $fsm_module) {
    return FSM::IR::IntentHIRBuilder->build_from_fsm_module(
        fsm_module => $fsm_module,
    );
}

sub analyze_fsm_module ($self, $fsm_module, $intent_hir = undef) {
    $intent_hir //= $self->build_intent_hir($fsm_module);

    my @all_states = @{$fsm_module->states};
    my %all_signals = %{$fsm_module->signals};

    my @regular_states = grep {
        $_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/
    } @all_states;
    my @standalone_dts = grep {
        $_->can('is_regular_state') ? !$_->is_regular_state : $_->name =~ /^-/
    } @all_states;

    my $intent_hir_hash = $intent_hir->as_hashref;

    return {
        module_name => $intent_hir_hash->{module_name},
        source_root_kind => $intent_hir_hash->{source_root_kind},
        regular_states => \@regular_states,
        regular_state_count => $intent_hir_hash->{regular_state_count},
        regular_state_names => $intent_hir_hash->{regular_state_names},
        state_count => $intent_hir_hash->{state_count},
        standalone_dts => \@standalone_dts,
        standalone_dt_count => $intent_hir_hash->{standalone_dt_count},
        standalone_dt_names => $intent_hir_hash->{standalone_dt_names},
        signals => \%all_signals,
        signal_count => $intent_hir_hash->{signal_count},
        signal_names => $intent_hir_hash->{signal_names},
        signal_analysis => $intent_hir_hash->{signal_analysis},
        explicit_system_contract => $intent_hir_hash->{explicit_system_contract},
        system_contract => $intent_hir_hash->{system_contract},
        requires_implicit_system_ports => $intent_hir_hash->{requires_implicit_system_ports},
        standalone_dt_enable_families => $intent_hir_hash->{standalone_dt_enable_families},
        standalone_dt_module_enable_family => $intent_hir_hash->{standalone_dt_module_enable_family},
        parameter_count => $intent_hir_hash->{parameter_count},
        parameter_names => $intent_hir_hash->{parameter_names},
        intent_hir => $intent_hir_hash,
    };
}

sub module_output_drive_families ($self, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my $output_drive_families = FSM::IR::LoweredRTLIR->output_drive_families_from_input(
        $module_info->{lowered_rtl_ir}
    );
    if (@$output_drive_families) {
        return $output_drive_families;
    }

    return $module_info->{output_drive_families} || [];
}

sub module_intent_hir ($self, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{intent_hir} || {});
}

sub module_lowered_rtl_ir ($self, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{lowered_rtl_ir} || {});
}

sub module_structural_rtl_ir ($self, $module_info) {
    return {} unless ref($module_info) eq 'HASH';
    return _clone_structured_value($module_info->{structural_rtl_ir} || {});
}

sub module_standalone_dt_multi_drive_targets ($self, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my $standalone_dt_multi_drive_targets = FSM::IR::LoweredRTLIR->standalone_dt_multi_drive_targets_from_input(
        $module_info->{lowered_rtl_ir}
    );
    if (@$standalone_dt_multi_drive_targets) {
        return $standalone_dt_multi_drive_targets;
    }

    return $module_info->{standalone_dt_multi_drive_targets} || [];
}

sub build_lowered_rtl_ir ($self, $module_info, $fsm_module) {
    return FSM::IR::LoweredRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => ($self->{target_language} // 'systemverilog'),
        hdl_generator => $self->{hdl_generator},
    );
}

sub build_structural_rtl_ir ($self, $module_info, $fsm_module = undef) {
    return FSM::IR::StructuralRTLIRBuilder->build_from_generated_module_info(
        module_info => $module_info,
        fsm_module => $fsm_module,
        target_language => ($self->{target_language} // 'systemverilog'),
    );
}

sub enrich_module_info_from_generated_analysis ($self, $module_info, $fsm_module) {
    return $module_info unless ref($module_info) eq 'HASH';
    my $lowered_rtl_ir = $self->build_lowered_rtl_ir($module_info, $fsm_module);
    my $lowered_rtl_ir_hash = $lowered_rtl_ir->as_hashref;

    $module_info->{output_drive_family_count} = $lowered_rtl_ir_hash->{output_drive_family_count};
    $module_info->{output_drive_families} = $lowered_rtl_ir_hash->{output_drive_families};
    $module_info->{standalone_dt_multi_drive_target_count} = $lowered_rtl_ir_hash->{standalone_dt_multi_drive_target_count};
    $module_info->{standalone_dt_multi_drive_targets} = $lowered_rtl_ir_hash->{standalone_dt_multi_drive_targets};
    $module_info->{lowered_rtl_ir} = $lowered_rtl_ir_hash;
    return $module_info;
}

sub _clone_structured_value ($value) {
    return undef unless defined $value;

    if (ref($value) eq 'HASH') {
        return {
            map { $_ => _clone_structured_value($value->{$_}) } sort keys %$value
        };
    }

    if (ref($value) eq 'ARRAY') {
        return [ map { _clone_structured_value($_) } @$value ];
    }

    return $value;
}

sub generate_hdl_code ($self, $fsm_module) {
    my $backend_result = FSM::Backend::GeneratedModuleEmitter->emit_from_fsm_module(
        fsm_module => $fsm_module,
        target_language => ($self->{target_language} // 'systemverilog'),
        debug_level => ($self->{debug_level} // 0),
    );
    $self->{hdl_generator} = $backend_result->{hdl_generator};
    return $backend_result->{hdl_code};
}

sub get_generator_method ($self) {
    return FSM::Backend::GeneratedModuleEmitter->generator_method_for_target(
        $self->{target_language},
    );
}

sub gather_statistics ($self, $fsm_module) {
    return FSM::Backend::GeneratedModuleEmitter->statistics_from_generator(
        $self->{hdl_generator},
    );
}

1;

__END__

=head1 METHODS

=head2 new(%args)

Creates a new HDL generation pipeline.

Arguments:
- debug_level: Debug verbosity level (0-3, default: 0)
- target_language: Target HDL language (default: 'systemverilog')
- quiet: Suppress informational messages (default: 0)

=head2 generate_hdl_from_file($fsm_file)

Processes an FSM file through the complete pipeline and returns results.

Returns a hashref with:
- fsm_module: The parsed FSM module object
- intent_hir: The extracted forward semantic intent IR summary for direct generated roots
- module_info: Analysis of the FSM structure
- hdl_code: Generated HDL code
- statistics: Generation statistics
- raw_ast: Original parsed AST

=head1 PIPELINE STAGES

The pipeline consists of these stages:

1. **Parse FSM File** - Uses Lispish to parse the .fsm file
2. **Create FSM Module** - Uses FSMGenFull adapter to create semantic AST
3. **Analyze FSM Module** - Analyzes states, signals, and structure
4. **Generate HDL Code** - Uses appropriate HDL generator
5. **Gather Statistics** - Collects generation metrics

=cut
