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
use FSM::Debug;
use FSM::HDL::FlattenedDT;
use FSM::Adapter::FSMGenFull;
use FSM::Pipeline::DirectGenerationOrchestrator;
use FSM::Composition::FailureReportBuilder;
use FSM::Composition::GenerationOrchestrator;
use FSM::Composition::Parser;
use FSM::Composition::ProvenanceReportBuilder;
use FSM::Composition::SharedDatapathCandidateBuilder;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Extension::Context;
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
    fsm_trace_enter("Generate HDL from file '$fsm_file'", 1);
    fsm_debug("Starting HDL generation pipeline for: $fsm_file", 1);
    
    # Step 1: Parse the FSM file
    my $raw_ast = $self->parse_fsm_file($fsm_file);
    my $source_info = $self->classify_source_ast($raw_ast);
    if (($source_info->{kind} // 'unknown') eq 'unknown' && defined($source_info->{header}) && $source_info->{header} =~ /^\?[A-Za-z_][\w-]*:/) {
        my $header = $source_info->{header};
        Carp::confess
            "Unsupported top-level source '$header'. ".
            "The active pipeline supports '?fsm:name', '?dt:name', '?mod:name', '?module:name', '+fsm', and '?top:name'. ".
            "Other tagged source kinds such as '?define:' are out of active support. ".
            "See docs/USER_GUIDE.md for the current supported boundary.\n";
    }
    if ($source_info && $source_info->{kind} eq 'composition') {
        $source_info->{composition_spec} = $self->parse_composition_source($raw_ast);
        $self->dispatch_after_parse_source($fsm_file, $raw_ast, $source_info);
        my $result = $self->generate_composition_from_source($source_info, $raw_ast, $fsm_file);
        return $self->finalize_generation_result($fsm_file, $source_info, $result);
    }
    $self->dispatch_after_parse_source($fsm_file, $raw_ast, $source_info);

    my $result = FSM::Pipeline::DirectGenerationOrchestrator->generate_from_source(
        pipeline => $self,
        raw_ast => $raw_ast,
        source_info => $source_info,
    );

    fsm_debug("HDL generation pipeline completed successfully", 1);
    return $self->finalize_generation_result($fsm_file, $source_info, $result);
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

sub generate_composition_from_source ($self, $source_info, $raw_ast, $fsm_file) {
    return FSM::Composition::GenerationOrchestrator->generate_from_source(
        pipeline => $self,
        source_info => $source_info,
        raw_ast => $raw_ast,
        fsm_file => $fsm_file,
        target_language => ($self->{target_language} // 'systemverilog'),
        source_path_resolver => $self->{source_path_resolver},
        rtl_interface_loader => $self->{rtl_interface_loader},
        statistics_seed => $self->gather_statistics(undef),
    );
}

sub dispatch_after_parse_source ($self, $fsm_file, $raw_ast, $source_info) {
    my $context = FSM::Extension::Context->new(
        stage => 'after_parse_source',
        pipeline => $self,
        source_path => $fsm_file,
        target_language => $self->{target_language},
        source_info => $source_info,
        raw_ast => $raw_ast,
    );

    $self->{extension_registry}->after_parse_source($context);
    return $context;
}

sub finalize_generation_result ($self, $fsm_file, $source_info, $result) {
    my $context = FSM::Extension::Context->new(
        stage => 'after_generate_result',
        pipeline => $self,
        source_path => $fsm_file,
        target_language => $self->{target_language},
        source_info => $source_info,
        result => $result,
    );

    $self->{extension_registry}->after_generate_result($context);

    fsm_trace_exit("HDL generation complete for '$fsm_file'", 1);
    return $result;
}

sub standalone_dt_assertion_metadata ($self, $signal_name, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return {
        kind => 'onehot0',
        target_signal => $signal_name,
        input_count => scalar(@inputs),
        input_enable_signals => \@inputs,
    };
}

sub standalone_dt_assertion_runtime_lines ($self, $module_info) {
    return () unless ($self->{target_language} || '') =~ /^(?:systemverilog|sv)$/;
    return () unless ref($module_info) eq 'HASH';

    my @assertion_lines;
    for my $target (@{$self->module_standalone_dt_multi_drive_targets($module_info)}) {
        next unless ref($target) eq 'HASH';
        my $assertion = $target->{multi_drive_assertion} || {};
        next unless ($assertion->{input_count} || 0) > 1;

        my @inputs = @{$assertion->{input_enable_signals} || []};
        next unless @inputs;

        my $target_signal = $target->{signal_name} || $assertion->{target_signal} || 'unknown_signal';
        push @assertion_lines,
            "    assert (\$onehot0({" . join(', ', @inputs) . "}))"
                . qq{ else \$error("standalone-dt multi-drive conflict: $target_signal");};
    }

    return () unless @assertion_lines;

    return (
        "  `ifndef SYNTHESIS",
        "  always_comb begin",
        @assertion_lines,
        "  end",
        "  `endif",
    );
}

sub augment_generated_hdl_with_standalone_dt_assertions ($self, $hdl_code, $module_info) {
    return $hdl_code unless defined($hdl_code) && length($hdl_code);

    my @assertion_lines = $self->standalone_dt_assertion_runtime_lines($module_info);
    return $hdl_code unless @assertion_lines;

    my $assertion_block = join("\n", '', @assertion_lines);
    if ($hdl_code =~ s/\nendmodule\s*\z/\n$assertion_block\nendmodule/s) {
        return $hdl_code;
    }

    return $hdl_code . "\n$assertion_block\n";
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

sub build_output_drive_family_metadata ($self, $module_info) {
    return [] unless ref($module_info) eq 'HASH';

    my %output_widths = map {
        (($_->{name} // '') => ($_->{width} || 1))
    } @{$module_info->{signal_analysis}{outputs} || []};

    return [] unless %output_widths;

    my $hdl_gen = $self->{hdl_generator};
    my $assignment_analysis = $hdl_gen ? ($hdl_gen->{assignment_analysis} || {}) : {};
    my @drive_families;

    for my $lhs (sort keys %$assignment_analysis) {
        next unless exists $output_widths{$lhs};

        my $lhs_analysis = $assignment_analysis->{$lhs};
        next unless ref($lhs_analysis) eq 'HASH';

        my %driver_blocks;
        my %rhs_values;
        my %driver_enable_signals;
        my %family_enable_signals;
        my %rhs_enable_families;

        for my $rhs (sort keys %{ $lhs_analysis->{rhs_groups} || {} }) {
            my $rhs_group = $lhs_analysis->{rhs_groups}{$rhs};
            next unless ref($rhs_group) eq 'HASH';

            $rhs_values{$rhs} = 1;
            $rhs_enable_families{$rhs} ||= {
                rhs_value => $rhs,
                family_enable_signal => undef,
                driver_blocks => {},
                driver_enable_signals => {},
            };

            my $lhs_level_enable = $rhs_group->{lhs_level_enable};
            if (ref($lhs_level_enable) eq 'HASH' && defined $lhs_level_enable->{name}) {
                $family_enable_signals{$lhs_level_enable->{name}} = 1;
                $rhs_enable_families{$rhs}{family_enable_signal} = $lhs_level_enable->{name};
            }

            for my $dt_enable_info (@{ $rhs_group->{dt_specific_enables} || [] }) {
                next unless ref($dt_enable_info) eq 'HASH';
                $driver_blocks{$dt_enable_info->{dt}} = 1 if defined $dt_enable_info->{dt};
                $driver_enable_signals{$dt_enable_info->{enable_name}} = 1
                    if defined $dt_enable_info->{enable_name};
                $rhs_enable_families{$rhs}{driver_blocks}{$dt_enable_info->{dt}} = 1
                    if defined $dt_enable_info->{dt};
                $rhs_enable_families{$rhs}{driver_enable_signals}{$dt_enable_info->{enable_name}} = 1
                    if defined $dt_enable_info->{enable_name};
            }
        }

        my @driver_blocks = sort keys %driver_blocks;
        my @rhs_values = sort keys %rhs_values;
        next unless @driver_blocks || @rhs_values;

        my $reset_value = $hdl_gen
            ? $hdl_gen->{enable_graph}->get_reset_value_from_ast($lhs_analysis->{lhs_ast})
            : undef;

        push @drive_families, {
            signal_name => $lhs,
            width => $output_widths{$lhs},
            multiplexer_type => ($lhs_analysis->{multiplexer}{type} // 'unknown'),
            default_value => $lhs_analysis->{multiplexer}{default_value},
            reset_value => $reset_value,
            driver_count => scalar(@driver_blocks),
            driver_blocks => \@driver_blocks,
            rhs_values => \@rhs_values,
            driver_enable_signals => [ sort keys %driver_enable_signals ],
            family_enable_signals => [ sort keys %family_enable_signals ],
            rhs_enable_families => [
                map {
                    +{
                        rhs_value => $_->{rhs_value},
                        family_enable_signal => $_->{family_enable_signal},
                        driver_blocks => [ sort keys %{$_->{driver_blocks} || {}} ],
                        driver_enable_signals => [ sort keys %{$_->{driver_enable_signals} || {}} ],
                    }
                } map {
                    $rhs_enable_families{$_}
                } sort keys %rhs_enable_families
            ],
        };
    }

    return \@drive_families;
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
    return unless ref($module_info) eq 'HASH';

    my $output_drive_families = $self->build_output_drive_family_metadata($module_info);

    my @standalone_dt_multi_drive_targets = map {
        +{
            signal_name => $_->{signal_name},
            multiplexer_type => $_->{multiplexer_type},
            dt_names => [@{$_->{driver_blocks} || []}],
            rhs_values => [@{$_->{rhs_values} || []}],
            dt_enable_signals => [@{$_->{driver_enable_signals} || []}],
            lhs_enable_signals => [@{$_->{family_enable_signals} || []}],
            multi_drive_assertion => $self->standalone_dt_assertion_metadata(
                $_->{signal_name},
                $_->{driver_enable_signals},
            ),
        }
    } grep {
        ($_->{driver_count} || 0) > 1
    } @$output_drive_families;

    return FSM::IR::LoweredRTLIR->new(
        module_name => ($module_info->{module_name} // ''),
        source_root_kind => (
            $module_info->{source_root_kind}
                // ($fsm_module && $fsm_module->can('source_root_kind') ? $fsm_module->source_root_kind : 'fsm')
        ),
        target_language => ($self->{target_language} // 'systemverilog'),
        output_drive_families => $output_drive_families,
        standalone_dt_multi_drive_targets => (
            $fsm_module && $fsm_module->can('is_dt_root') && $fsm_module->is_dt_root
                ? \@standalone_dt_multi_drive_targets
                : []
        ),
    );
}

sub build_structural_rtl_ir ($self, $module_info, $fsm_module = undef) {
    return unless ref($module_info) eq 'HASH';

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

            push @ports, {
                name => $signal_name,
                direction => $direction,
                width => ($entry->{width} || 1),
                type => $type,
            };
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
        target_language => ($self->{target_language} // 'systemverilog'),
        ports => \@ports,
        nets => [],
        instances => [],
        auxiliary_assignments => [],
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
    fsm_trace_enter('Generate HDL code from semantic FSM module', 2);
    fsm_debug("Generating HDL code", 1);
    
    # Create HDL generator
    my $hdl_gen = FSM::HDL::FlattenedDT->new(debug => ($self->{debug_level} > 0));
    
    # Determine generator method based on target language
    my $generator_method = $self->get_generator_method();
    
    fsm_debug("Using generator method: $generator_method", 1);
    
    # Generate HDL code
    my $hdl_code;
    eval {
        $hdl_code = $hdl_gen->$generator_method($fsm_module);
    };
    
    if ($@) {
        fsm_trace_decision(0, "HDL backend method '$generator_method' raised exception", 1);
        Carp::confess "Error generating HDL: $@\n";
    }
    
    fsm_debug("HDL code generation completed", 1);
    
    # Store generator for statistics gathering
    $self->{hdl_generator} = $hdl_gen;
    
    fsm_trace_exit("HDL generation complete via '$generator_method'", 2);
    return $hdl_code;
}

sub get_generator_method ($self) {
    fsm_trace_enter('Resolve backend generator method for target language', 4);
    my %language_methods = (
        'vhdl' => 'generate_vhdl',
        'verilog' => 'generate_verilog',
        'v' => 'generate_verilog',
        'systemverilog' => 'generate_systemverilog',
        'sv' => 'generate_systemverilog',
    );
    
    my $method = $language_methods{$self->{target_language}} || 'generate_systemverilog';
    fsm_trace_exit("Generator method resolved => $method", 4);
    return $method;
}

sub gather_statistics ($self, $fsm_module) {
    fsm_trace_enter('Gather pipeline generation statistics', 2);
    fsm_debug("Gathering generation statistics", 1);
    
    my $stats = {
        intermediate_signals => 0,
        global_expressions => 0,
        reused_expressions => [],
        factoring_enabled => 0,
    };
    
    # Get statistics from HDL generator if available
    if ($self->{hdl_generator}) {
        my $hdl_gen = $self->{hdl_generator};
        my $intermediate_signals = $hdl_gen->{intermediate_signals} || {};
        my $global_expressions = $hdl_gen->{global_expressions} || {};
        my $expression_usage = $hdl_gen->{expression_usage} || {};
        
        $stats->{intermediate_signals} = scalar(keys %$intermediate_signals);
        $stats->{global_expressions} = scalar(keys %$global_expressions);
        $stats->{factoring_enabled} = (%$intermediate_signals || %$global_expressions) ? 1 : 0;
        
        # Find reused expressions
        my @reused = grep { $expression_usage->{$_} > 1 } keys %$expression_usage;
        for my $signal_name (sort { $expression_usage->{$b} <=> $expression_usage->{$a} } @reused) {
            my $usage = $expression_usage->{$signal_name};
            my $expression = $intermediate_signals->{$signal_name};
            push @{$stats->{reused_expressions}}, {
                signal => $signal_name,
                expression => $expression,
                usage_count => $usage
            };
        }
        
        # Store raw data for detailed analysis
        $stats->{raw_intermediate_signals} = $intermediate_signals;
        $stats->{raw_global_expressions} = $global_expressions;
        $stats->{raw_expression_usage} = $expression_usage;
    }
    
    fsm_debug("Statistics gathering complete", 1);
    fsm_debug("  Intermediate signals: $stats->{intermediate_signals}", 1);
    fsm_debug("  Global expressions: $stats->{global_expressions}", 1);
    fsm_debug("  Reused expressions: " . scalar(@{$stats->{reused_expressions}}), 1);
    
    fsm_trace_exit('Statistics gathering complete', 2);
    return $stats;
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
