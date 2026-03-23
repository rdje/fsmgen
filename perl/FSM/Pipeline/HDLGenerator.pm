#!/usr/bin/perl

package FSM::Pipeline::HDLGenerator;
use v5.20;
use strict;
use warnings;
use Carp qw(confess);
use Scalar::Util qw(blessed);
use feature qw(signatures postderef);
no warnings 'experimental::signatures';

use FindBin;
use File::Basename qw(dirname);
use File::Spec;
use lib "$FindBin::Bin";
use FSM::Debug;
use FSM::HDL::FlattenedDT;
use FSM::Adapter::FSMGenFull;
use FSM::Composition::Parser;
use FSM::Composition::Net;
use FSM::Composition::Port;
use FSM::Composition::Plan;
use FSM::Composition::PortsBlock;
use FSM::Composition::RealizedInstance;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Extension::Context;
use FSM::Extension::Loader;
use FSM::Extension::Registry;
use FSM::IR::IntentHIR;
use FSM::IR::LoweredRTLIR;
use FSM::IR::StructuralRTLIR;
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
    
    # Step 2: Convert raw AST to semantic FSM module
    my $fsm_module = $self->create_fsm_module($raw_ast);
    
    # Step 3: Extract forward semantic intent and analyze from that IR
    my $intent_hir = $self->build_intent_hir($fsm_module);
    my $module_info = $self->analyze_fsm_module($fsm_module, $intent_hir);
    
    # Step 4: Generate HDL code
    my $hdl_code = $self->generate_hdl_code($fsm_module);
    $self->enrich_module_info_from_generated_analysis($module_info, $fsm_module);
    my $structural_rtl_ir = $self->build_structural_rtl_ir($module_info, $fsm_module);
    $module_info->{structural_rtl_ir} = $structural_rtl_ir->as_hashref;
    $hdl_code = $self->augment_generated_hdl_with_standalone_dt_assertions($hdl_code, $module_info);
    
    # Step 5: Gather statistics
    my $statistics = $self->gather_statistics($fsm_module);
    
    fsm_debug("HDL generation pipeline completed successfully", 1);
    
    my $result = {
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
    my $header = $source_info->{header} // '?top:name';
    my $composition_spec = $source_info->{composition_spec}
        || $self->parse_composition_source($raw_ast);

    my $composition_plan = $self->build_composition_plan($composition_spec, $fsm_file, $header);
    my $structural_rtl_ir = $self->build_composition_structural_rtl_ir($composition_plan);
    my $composition_child_exports = $self->build_composition_child_exports($composition_plan, $structural_rtl_ir);
    my $generated_child_exports = $self->build_composition_generated_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    my $standalone_dt_child_exports = $self->build_composition_standalone_dt_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    my $intent_hir = $self->build_composition_intent_hir(
        $composition_plan,
        $composition_child_exports,
        $generated_child_exports,
        $standalone_dt_child_exports,
        $structural_rtl_ir,
    );
    my $composition_report = $self->build_composition_provenance_report(
        $composition_plan,
        $structural_rtl_ir,
        $intent_hir,
    );
    my $lowered_rtl_ir = $self->build_composition_lowered_rtl_ir($composition_plan, $structural_rtl_ir, $intent_hir);
    my $hdl_code = $self->generate_composition_hdl_code($composition_plan, $structural_rtl_ir);
    my $module_info = $self->build_composition_module_info(
        $composition_plan,
        $composition_report,
        $composition_child_exports,
        $generated_child_exports,
        $intent_hir,
        $lowered_rtl_ir,
        $structural_rtl_ir,
    );
    my $statistics = $self->build_composition_statistics(
        $composition_plan,
        $composition_report,
        $lowered_rtl_ir,
        $structural_rtl_ir,
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
        raw_ast => $raw_ast,
        source_info => $source_info,
    };
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

sub build_composition_plan ($self, $composition_spec, $fsm_file, $header) {
    $self->assert_supported_composition_target($fsm_file, $header);

    my $top = $composition_spec->top;
    my @instances = @{$top->instances || []};
    my @ports_blocks = @{$top->ports_blocks || []};
    my @toplinks = @{$top->toplinks || []};

    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition lane entry is blocked because the current active composition lanes require at least one child instance such as '?fsmc', '?dtc', or '?rtl'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @instances;

    my @realized_instances;
    for my $instance (@instances) {
        if ($instance->kind eq 'fsmc') {
            push @realized_instances, $self->realize_fsmc_child_instance($instance, $composition_spec, $fsm_file, $header);
            next;
        }

        if ($instance->kind eq 'dtc') {
            push @realized_instances, $self->realize_dtc_child_instance($instance, $composition_spec, $fsm_file, $header);
            next;
        }

        if ($instance->kind eq 'rtl') {
            push @realized_instances, $self->realize_rtl_child_instance($instance, $composition_spec, $fsm_file, $header);
            next;
        }

        Carp::confess
            "Composition source '$header' in '$fsm_file' uses unsupported child kind '".$instance->kind."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    my $is_single_child_passthrough = @realized_instances == 1 && !@toplinks;
    my $allows_implicit_explicit_link_ports =
        !$is_single_child_passthrough
        && @toplinks
        && (
            @ports_blocks == 0
            || (@ports_blocks == 1 && !(scalar(@{$ports_blocks[0]->ports || []})))
        );
    my $allows_implicit_c1_ports =
        $is_single_child_passthrough
        && (
            @ports_blocks == 0
            || (@ports_blocks == 1 && !(scalar(@{$ports_blocks[0]->ports || []})))
        );

    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition shape is blocked because the current active composition lanes require exactly one explicit '?ports' block, ".
        "except that the single-child passthrough C1 lane and the explicit-link C2/C3 lanes may now infer the top interface when '?ports' is omitted or empty. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @ports_blocks <= 1;

    my $ports_block = $ports_blocks[0];
    my @ports = $ports_block ? @{$ports_block->ports || []} : ();

    if (!$allows_implicit_c1_ports && !$allows_implicit_explicit_link_ports) {
        Carp::confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but composition shape is blocked because the current active composition lanes require exactly one explicit '?ports' block. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless @ports_blocks == 1;

        Carp::confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but composition shape is blocked because the current active composition lanes require '?ports' to declare at least one explicit top port, ".
            "except that the single-child passthrough C1 lane and the explicit-link C2/C3 lanes may now infer the top interface when '?ports' is omitted or empty. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless @ports;
    }

    my $rtl_instance_count = scalar(grep { $_->kind eq 'rtl' } @realized_instances);
    my $fsmc_instance_count = scalar(grep { $_->kind eq 'fsmc' } @realized_instances);
    my $dtc_instance_count = scalar(grep { $_->kind eq 'dtc' } @realized_instances);
    my $generated_instance_count = scalar(grep { $self->is_generated_child_kind($_->kind) } @realized_instances);
    my $declared_by_name_port_count = scalar(grep { ($_->binding_mode || 'explicit') eq 'connect_by_name' } @ports);

    if (!$declared_by_name_port_count && !$is_single_child_passthrough) {
        @ports = @{
            $self->augment_with_inferred_top_ports_from_explicit_links(
                \@ports,
                \@toplinks,
                \@realized_instances,
                $fsm_file,
                $header,
            )
        };
        @ports = @{
            $self->augment_with_inferred_undeclared_top_inputs(
                \@ports,
                \@realized_instances,
                \@toplinks,
                $fsm_file,
                $header,
            )
        };
        @ports = @{
            $self->augment_with_inferred_undeclared_top_outputs(
                \@ports,
                \@realized_instances,
                \@toplinks,
                $fsm_file,
                $header,
            )
        };
    }

    if (@ports && (!$ports_block || scalar(@{$ports_block->ports || []}) != scalar(@ports))) {
        $ports_block = FSM::Composition::PortsBlock->new(
            name => ($ports_block ? $ports_block->name : undef),
            ports => \@ports,
            raw_ast => ($ports_block ? $ports_block->raw_ast : undef),
        );
    }

    if ($declared_by_name_port_count > 0) {
        return $self->build_c4_composition_plan(
            $composition_spec,
            $top,
            $ports_block,
            \@ports,
            \@toplinks,
            \@realized_instances,
            $generated_instance_count,
            $fsmc_instance_count,
            $dtc_instance_count,
            $rtl_instance_count,
            $fsm_file,
            $header,
        );
    }

    if (@realized_instances == 1 && !@toplinks) {
        return $self->build_c1_composition_plan(
            $composition_spec,
            $ports_block,
            \@ports,
            $realized_instances[0],
            $fsm_file,
            $header,
        );
    }

    if ($rtl_instance_count > 0) {
        return $self->build_c3_composition_plan(
            $composition_spec,
            $top,
            $ports_block,
            \@ports,
            \@toplinks,
            \@realized_instances,
            $generated_instance_count,
            $fsmc_instance_count,
            $dtc_instance_count,
            $rtl_instance_count,
            $fsm_file,
            $header,
        );
    }

    return $self->build_c2_composition_plan(
        $composition_spec,
        $top,
        $ports_block,
        \@ports,
        \@toplinks,
        \@realized_instances,
        $fsm_file,
        $header,
    );
}

sub assert_supported_composition_target ($self, $fsm_file, $header) {
    return if $self->{target_language} =~ /^(?:systemverilog|sv|verilog|v)$/;

    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but composition target support is blocked because the current active composition lanes only emit SystemVerilog/Verilog tops. ".
        "Target language '$self->{target_language}' is not implemented for composition yet. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub realize_fsmc_child_instance ($self, $instance, $composition_spec, $fsm_file, $header) {
    my $source_name = $instance->source_name;
    my $child_ast = $composition_spec->embedded_fsm_sources->{$source_name};
    my $child_source_path;
    my $child_source_info;

    unless ($child_ast) {
        ($child_ast, $child_source_path, $child_source_info) =
            $self->load_external_fsmc_child_source($source_name, $fsm_file, $header);
    }

    my $child_module = $self->create_fsm_module($child_ast);
    my $child_intent_hir = $self->build_intent_hir($child_module);
    my $child_module_info = $self->analyze_fsm_module($child_module, $child_intent_hir);
    my $child_hdl_code = $self->generate_hdl_code($child_module);
    $self->enrich_module_info_from_generated_analysis($child_module_info, $child_module);
    my $child_structural_rtl_ir = $self->build_structural_rtl_ir($child_module_info, $child_module);
    $child_module_info->{structural_rtl_ir} = $child_structural_rtl_ir->as_hashref;
    $child_hdl_code = $self->augment_generated_hdl_with_standalone_dt_assertions($child_hdl_code, $child_module_info);
    my $shared_datapath_source_exports = $self->build_shared_datapath_source_export_metadata($child_module_info);
    $child_module_info->{shared_datapath_source_export_count} = scalar(@$shared_datapath_source_exports);
    $child_module_info->{shared_datapath_source_exports} = $shared_datapath_source_exports;
    $child_hdl_code = $self->augment_generated_child_hdl_with_shared_datapath_exports(
        $child_hdl_code,
        $shared_datapath_source_exports,
    );
    my $child_interface_ports = $self->build_realized_child_interface_ports($child_module_info);

    return FSM::Composition::RealizedInstance->new(
        kind => 'fsmc',
        instance_name => ($instance->name // $child_module->name),
        module_name => $child_module->name,
        source_name => $source_name,
        interface_ports => $child_interface_ports,
        module_info => $child_module_info,
        hdl_code => $child_hdl_code,
    );
}

sub realize_dtc_child_instance ($self, $instance, $composition_spec, $fsm_file, $header) {
    my $source_name = $instance->source_name;
    my $child_ast = $composition_spec->embedded_dt_sources->{$source_name};

    unless ($child_ast) {
        ($child_ast) = $self->load_external_dtc_child_source($source_name, $fsm_file, $header);
    }

    my $child_module = $self->create_fsm_module($child_ast);
    my $child_intent_hir = $self->build_intent_hir($child_module);
    my $child_module_info = $self->analyze_fsm_module($child_module, $child_intent_hir);
    my $child_hdl_code = $self->generate_hdl_code($child_module);
    $self->enrich_module_info_from_generated_analysis($child_module_info, $child_module);
    my $child_structural_rtl_ir = $self->build_structural_rtl_ir($child_module_info, $child_module);
    $child_module_info->{structural_rtl_ir} = $child_structural_rtl_ir->as_hashref;
    $child_hdl_code = $self->augment_generated_hdl_with_standalone_dt_assertions($child_hdl_code, $child_module_info);
    my $child_interface_ports = $self->build_realized_child_interface_ports($child_module_info);

    return FSM::Composition::RealizedInstance->new(
        kind => 'dtc',
        instance_name => ($instance->name // $child_module->name),
        module_name => $child_module->name,
        source_name => $source_name,
        interface_ports => $child_interface_ports,
        module_info => $child_module_info,
        hdl_code => $child_hdl_code,
    );
}

sub load_external_fsmc_child_source ($self, $source_name, $fsm_file, $header) {
    my ($child_source_path) =
        $self->resolve_external_fsmc_child_source_path($source_name, $fsm_file, $header);

    my $child_ast = $self->parse_fsm_file($child_source_path);
    my $child_source_info = $self->classify_source_ast($child_ast);
    my $child_kind = $child_source_info->{kind} // 'unknown';
    return ($child_ast, $child_source_path, $child_source_info) if $child_kind eq 'fsm';

    my $child_header = $child_source_info->{header} // 'unknown root';
    my $kind_note = $child_kind eq 'dt'
        ? "Standalone '?dt:name' roots are shipped as composition children, but '?fsmc' specifically requires an FSM child source. Use '?dtc' for standalone-DT children instead."
        : "The active composition child-FSM contract expects embedded or external child sources rooted at '?fsm:name' or legacy '+fsm' only.";

    Carp::confess
        "Composition source '$header' in '$fsm_file' resolves '?fsmc' child '$source_name' to '$child_source_path', ".
        "but child-source realization is blocked because that resolved file is not an active FSM child source (detected root '$child_header'). ".
        $kind_note." ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub load_external_dtc_child_source ($self, $source_name, $fsm_file, $header) {
    my ($child_source_path) =
        $self->resolve_external_generated_child_source_path($source_name, $fsm_file, $header, '?dtc');

    my $child_ast = $self->parse_fsm_file($child_source_path);
    my $child_source_info = $self->classify_source_ast($child_ast);
    my $child_kind = $child_source_info->{kind} // 'unknown';
    return ($child_ast, $child_source_path, $child_source_info) if $child_kind eq 'dt';

    my $child_header = $child_source_info->{header} // 'unknown root';
    my $kind_note = $child_kind eq 'fsm'
        ? "FSM child roots are shipped as composition children, but '?dtc' specifically requires a standalone-DT child source. Use '?fsmc' for FSM children instead."
        : "The active standalone-DT composition contract currently expects '?dt:name', '?mod:name', or '?module:name' child roots for '?dtc'.";

    Carp::confess
        "Composition source '$header' in '$fsm_file' resolves '?dtc' child '$source_name' to '$child_source_path', ".
        "but child-source realization is blocked because that resolved file is not an active standalone-DT child source (detected root '$child_header'). ".
        $kind_note." ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub resolve_external_fsmc_child_source_path ($self, $source_name, $fsm_file, $header) {
    return $self->resolve_external_generated_child_source_path($source_name, $fsm_file, $header, '?fsmc');
}

sub resolve_external_generated_child_source_path ($self, $source_name, $fsm_file, $header, $child_kind) {
    my @preferred_dirs;
    push @preferred_dirs, dirname($fsm_file) if defined($fsm_file) && $fsm_file =~ m{/};

    my @search_dirs = @{
        $self->{source_path_resolver}->normalized_search_paths(
            preferred_dirs => \@preferred_dirs,
            include_cwd => 1,
        )
    };

    my @candidates;
    if (File::Spec->file_name_is_absolute($source_name)) {
        push @candidates, $source_name;
        push @candidates, "$source_name.fsm" unless $source_name =~ /\.fsm$/i;
    } elsif ($source_name =~ m{/}) {
        for my $dir (@search_dirs) {
            push @candidates, File::Spec->catfile($dir, $source_name);
            push @candidates, File::Spec->catfile($dir, "$source_name.fsm")
                unless $source_name =~ /\.fsm$/i;
        }
    } else {
        my $target_filename = $source_name =~ /\.fsm$/i ? $source_name : "$source_name.fsm";
        push @candidates, map { File::Spec->catfile($_, $target_filename) } @search_dirs;
    }

    my %seen;
    my @searched_paths = grep { !$seen{$_}++ } @candidates;
    for my $candidate (@searched_paths) {
        return ($candidate, \@search_dirs, \@searched_paths) if -f $candidate;
    }

    my $family_label = $child_kind eq '?dtc'
        ? "standalone-DT child source"
        : "child FSM source";
    Carp::confess
        "Composition source '$header' in '$fsm_file' declares '$child_kind' child '$source_name', ".
        "but child-source resolution is blocked because no active $family_label was found either embedded in the same file or in an external '.fsm' file. ".
        "Search roots: ".join(', ', @search_dirs).". ".
        "Searched locations: ".join(', ', @searched_paths).". ".
        "The active composition contract currently allows generated child instances to realize embedded sources or external '.fsm' module files found beside the composition source, through repeated '--path DIR' roots, through 'FSMLIB', or in the current directory. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub realize_rtl_child_instance ($self, $instance, $composition_spec, $fsm_file, $header) {
    my $module_name = $instance->module_name;
    my $loaded = $self->{rtl_interface_loader}->load_interface(
        module_name => $module_name,
        source_file => $fsm_file,
        embedded_raw_ast => $composition_spec ? $composition_spec->raw_ast : undef,
    );

    return FSM::Composition::RealizedInstance->new(
        kind => 'rtl',
        instance_name => ($instance->name // $module_name),
        module_name => $module_name,
        source_name => undef,
        interface_ports => $loaded->{interface_ports},
        module_info => {
            module_name => $module_name,
            metadata_path => $loaded->{metadata_path},
            interface_kind => 'rtl_external',
        },
        hdl_code => undef,
    );
}

sub build_realized_child_interface_ports ($self, $module_info) {
    my %ports;
    my $child_structural_rtl_ir = $self->module_structural_rtl_ir($module_info);
    my $system_contract = $module_info->{system_contract} || {
        clock => 'clk',
        reset => 'rst_n',
        reset_keyword => 'asreset',
        implicit => 1,
    };
    my %system_port_type = (
        ($system_contract->{clock} => 'clock'),
        ($system_contract->{reset} => 'reset'),
    );

    if (ref($child_structural_rtl_ir->{ports}) eq 'ARRAY' && @{$child_structural_rtl_ir->{ports}}) {
        for my $entry (@{$child_structural_rtl_ir->{ports}}) {
            next unless defined($entry->{name}) && length($entry->{name});
            my $type = $entry->{type};
            $type = $system_port_type{$entry->{name}}
                if !defined($type) || $type eq '';
            $type = undef
                if defined($type) && ($type eq 'wire' || $type eq 'logic');

            $ports{$entry->{name}} = FSM::Composition::Port->new(
                name => $entry->{name},
                direction => ($entry->{direction} || 'input'),
                width => $entry->{width} || 1,
                type => $type,
                raw_token => undef,
                origin_kind => 'realized_child_interface_port',
            );
        }
    } else {
        for my $direction (qw(input output)) {
            my $list = $direction eq 'input'
                ? ($module_info->{signal_analysis}{inputs} || [])
                : ($module_info->{signal_analysis}{outputs} || []);

            for my $entry (@$list) {
                $ports{$entry->{name}} = FSM::Composition::Port->new(
                    name => $entry->{name},
                    direction => $direction,
                    width => $entry->{width} || 1,
                    type => $system_port_type{$entry->{name}},
                    raw_token => undef,
                    origin_kind => 'realized_child_interface_port',
                );
            }
        }
    }

    if ($system_contract->{declare_ports}) {
        for my $system_name (keys %system_port_type) {
            $ports{$system_name} //= FSM::Composition::Port->new(
                name => $system_name,
                direction => 'input',
                width => 1,
                type => $system_port_type{$system_name},
                raw_token => undef,
                origin_kind => 'realized_child_interface_port',
            );
        }
    }

    my @ordered_names = sort {
        $self->system_port_sort_key($ports{$a}) <=> $self->system_port_sort_key($ports{$b})
        ||
        $a cmp $b
    } keys %ports;

    return [map { $ports{$_} } @ordered_names];
}

sub system_port_sort_key ($self, $port) {
    return 0 if ($port->type || '') eq 'clock';
    return 1 if ($port->type || '') eq 'reset';
    return 2;
}

sub normalized_interface_type ($self, $type) {
    return defined($type) && length($type) ? $type : 'data';
}

sub clean_enable_name_token ($self, $name) {
    $name = lc($name // '');
    $name =~ s/[^a-zA-Z0-9_]/_/g;
    $name =~ s/__+/_/g;
    $name =~ s/^_+//;
    $name =~ s/_+$//;

    if ($name eq '0') {
        return '0';
    } elsif ($name eq '1') {
        return '1';
    }

    $name =~ s/^(\d)/_$1/;
    return $name;
}

sub shared_datapath_value_enable_name ($self, $signal_name, $rhs_value) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    my $clean_rhs = $self->clean_enable_name_token($rhs_value);
    return "${clean_signal}_${clean_rhs}_shared_en";
}

sub shared_datapath_export_port_name ($self, $family_enable_signal) {
    my $clean_signal = $self->clean_enable_name_token($family_enable_signal);
    return "shared_dp_export_${clean_signal}";
}

sub shared_datapath_source_value_enable_name ($self, $instance_name, $signal_name, $rhs_value) {
    my $clean_instance = $self->clean_enable_name_token($instance_name || 'child');
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    my $clean_rhs = $self->clean_enable_name_token($rhs_value);
    return "${clean_instance}_${clean_signal}_${clean_rhs}_src_en";
}

sub shared_datapath_target_enable_name ($self, $signal_name) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_en";
}

sub shared_datapath_lifted_next_name ($self, $signal_name) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_next";
}

sub shared_datapath_lifted_register_name ($self, $signal_name) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_q";
}

sub shared_datapath_lifted_comb_name ($self, $signal_name) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "${clean_signal}_shared_comb";
}

sub shared_datapath_raw_source_name ($self, $instance_name, $signal_name) {
    my $clean_instance = $self->clean_enable_name_token($instance_name || 'child');
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "shared_dp_raw_${clean_instance}_${clean_signal}";
}

sub shared_datapath_same_value_conflict_name ($self, $signal_name, $rhs_value) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    my $clean_rhs = $self->clean_enable_name_token($rhs_value);
    return "${clean_signal}_${clean_rhs}_multi_src_conflict";
}

sub shared_datapath_multi_value_conflict_name ($self, $signal_name) {
    my $clean_signal = $self->clean_enable_name_token($signal_name);
    return "${clean_signal}_multi_value_conflict";
}

sub shared_datapath_assertion_metadata ($self, $result_signal, $input_enable_signals) {
    my @inputs = grep {
        defined($_) && length($_)
    } @{$input_enable_signals || []};

    return {
        kind => 'onehot0',
        result_signal => $result_signal,
        input_count => scalar(@inputs),
        input_enable_signals => \@inputs,
    };
}

sub shared_datapath_assertion_runtime_lines ($self, $candidate) {
    return () unless ($self->{target_language} || '') =~ /^(?:systemverilog|sv)$/;
    return () unless ref($candidate) eq 'HASH';

    my @assertion_lines;
    my $signal_name = $candidate->{signal_name} || 'unknown_signal';

    for my $family (@{$candidate->{aggregate_enable_families} || []}) {
        next unless ref($family) eq 'HASH';
        my $assertion = $family->{same_value_assertion} || {};
        next unless ($assertion->{input_count} || 0) > 1;
        my $result_signal = $assertion->{result_signal} || next;
        my $rhs_value = $family->{rhs_value} // 'unknown_value';

        push @assertion_lines,
            "      assert (!$result_signal)"
                . qq{ else \$error("shared-datapath same-value conflict: $signal_name $rhs_value");};
    }

    my $multi_value_assertion = $candidate->{multi_value_assertion} || {};
    if (($multi_value_assertion->{input_count} || 0) > 1) {
        my $result_signal = $multi_value_assertion->{result_signal} || '';
        if (length $result_signal) {
            push @assertion_lines,
                "      assert (!$result_signal)"
                    . qq{ else \$error("shared-datapath multi-value conflict: $signal_name");};
        }
    }

    return () unless @assertion_lines;

    return (
        "    `ifndef SYNTHESIS",
        "    always_comb begin",
        @assertion_lines,
        "    end",
        "    `endif",
    );
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
    for my $target (@{$module_info->{standalone_dt_multi_drive_targets} || []}) {
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

sub build_shared_datapath_source_export_metadata ($self, $module_info) {
    my %seen;
    my @exports;

    for my $drive_family (@{$self->module_output_drive_families($module_info)}) {
        next unless ref($drive_family) eq 'HASH';
        my $signal_name = $drive_family->{signal_name} || next;

        for my $rhs_family (@{$drive_family->{rhs_enable_families} || []}) {
            next unless ref($rhs_family) eq 'HASH';
            my $family_enable_signal = $rhs_family->{family_enable_signal} || next;
            my $rhs_value = $rhs_family->{rhs_value};
            my $key = join "\x1E", $signal_name, ($rhs_value // ''), $family_enable_signal;
            next if $seen{$key}++;

            push @exports, {
                signal_name => $signal_name,
                rhs_value => $rhs_value,
                source_signal => $family_enable_signal,
                port_name => $self->shared_datapath_export_port_name($family_enable_signal),
            };
        }
    }

    @exports = sort {
        ($a->{signal_name} // '') cmp ($b->{signal_name} // '')
            ||
        (($a->{rhs_value} // '') cmp ($b->{rhs_value} // ''))
            ||
        (($a->{port_name} // '') cmp ($b->{port_name} // ''))
    } @exports;

    return \@exports;
}

sub augment_generated_child_hdl_with_shared_datapath_exports ($self, $hdl_code, $exports) {
    return $hdl_code unless defined($hdl_code) && length($hdl_code);
    return $hdl_code unless @{$exports || []};

    my @port_lines = map {
        "  output  wire " . $_->{port_name}
    } @{$exports || []};

    my $patched = $hdl_code;
    my $port_block = join(",\n", @port_lines);
    my $header_replaced = ($patched =~ s/\n\);\n\n/\n,\n$port_block\n\);\n\n/s);
    Carp::confess("Failed to inject shared-datapath export ports into generated child HDL\n")
        unless $header_replaced;

    my $assign_block = "\n  // Shared-datapath source-enable exports\n"
        . join('', map {
            "  assign " . $_->{port_name} . " = " . $_->{source_signal} . ";\n"
        } @{$exports || []});

    my $endmodule_replaced = ($patched =~ s/\nendmodule\s*\z/$assign_block . "endmodule\n"/se);
    Carp::confess("Failed to inject shared-datapath export assignments into generated child HDL\n")
        unless $endmodule_replaced;

    return $patched;
}

sub shared_datapath_storage_class ($self, $contributors) {
    my %types = map {
        my $output_drive_family = $self->shared_datapath_contributor_output_drive_family($_);
        my $type = $output_drive_family->{multiplexer_type} // 'unknown';
        ($type => 1);
    } @{$contributors || []};

    return 'registered' if keys(%types) == 1 && $types{flop};
    return 'combinational' if keys(%types) == 1 && $types{comb};
    return 'unknown' if !keys(%types) || (keys(%types) == 1 && $types{unknown});
    return 'mixed';
}

sub shared_datapath_peer_read_policy ($self, $storage_class, $peer_input_endpoints, $top_output_signals = undef) {
    return undef unless @{$peer_input_endpoints || []};

    return {
        peer_read_policy => 'registered_loopback',
    } if ($storage_class || '') eq 'registered';

    return {
        peer_read_policy => 'top_output_only',
        peer_read_block_reason =>
            'combinational shared families must stay top-facing and are not internalized into lifted state',
    } if ($storage_class || '') eq 'combinational' && @{$top_output_signals || []};

    return {
        peer_read_policy => 'top_local_only',
        peer_read_block_reason =>
            'combinational shared families may lift only into top-local combinational carriers and are not internalized into lifted state',
    } if ($storage_class || '') eq 'combinational';

    return undef;
}

sub shared_datapath_contributor_output_drive_family ($self, $contributor) {
    return {} unless ref($contributor) eq 'HASH';
    return $contributor->{output_drive_family} if ref($contributor->{output_drive_family}) eq 'HASH';
    return $contributor->{drive_intent} if ref($contributor->{drive_intent}) eq 'HASH';
    return {};
}

sub shared_datapath_drive_intent_from_output_drive_family ($self, $output_drive_family) {
    return {} unless ref($output_drive_family) eq 'HASH';

    return {
        multiplexer_type => ($output_drive_family->{multiplexer_type} // 'unknown'),
        default_value => $output_drive_family->{default_value},
        reset_value => $output_drive_family->{reset_value},
        driver_count => ($output_drive_family->{driver_count} || 0),
        driver_blocks => [@{$output_drive_family->{driver_blocks} || []}],
        rhs_values => [@{$output_drive_family->{rhs_values} || []}],
        driver_enable_signals => [@{$output_drive_family->{driver_enable_signals} || []}],
        family_enable_signals => [@{$output_drive_family->{family_enable_signals} || []}],
        rhs_enable_families => [
            map {
                +{
                    rhs_value => $_->{rhs_value},
                    family_enable_signal => $_->{family_enable_signal},
                    driver_blocks => [@{$_->{driver_blocks} || []}],
                    driver_enable_signals => [@{$_->{driver_enable_signals} || []}],
                }
            } @{$output_drive_family->{rhs_enable_families} || []}
        ],
    };
}

sub is_generated_child_kind ($self, $kind) {
    return $kind eq 'fsmc' || $kind eq 'dtc';
}

sub system_interface_ports ($self, $ports) {
    return [
        grep {
            my $type = $_->type || '';
            $type eq 'clock' || $type eq 'reset';
        } @{$ports || []}
    ];
}

sub system_port_names_from_endpoints ($self, $candidate_endpoints) {
    my %names;
    for my $endpoint (@{$candidate_endpoints || []}) {
        my $port = $endpoint->{port} or next;
        my $type = $port->type || '';
        next unless $type eq 'clock' || $type eq 'reset';
        $names{$port->name} = 1;
    }
    return sort keys %names;
}

sub index_ports_by_name ($self, $ports) {
    my %ports;

    for my $port (@{$ports || []}) {
        $ports{$port->name} = $port;
    }

    return \%ports;
}

sub assert_unique_top_ports ($self, $ports_block, $fsm_file, $header) {
    my %top_ports_by_name;
    for my $port (@{$ports_block->ports}) {
        Carp::confess
            "Composition source '$header' in '$fsm_file' declares duplicate top port '".$port->name."' in '?ports', ".
            "but composition shape is blocked because the active composition lanes require each top port name to be unique. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $top_ports_by_name{$port->name};

        $top_ports_by_name{$port->name} = $port;
    }

    return \%top_ports_by_name;
}

sub build_c1_composition_plan ($self, $composition_spec, $ports_block, $ports, $realized_instance, $fsm_file, $header) {
    my $child_port_info = $self->index_ports_by_name($realized_instance->interface_ports);
    my @effective_ports = @{$ports || []};

    if (@effective_ports) {
        $self->assert_c1_port_exposure_matches_child($ports_block, $realized_instance, $child_port_info, $fsm_file, $header);
    } else {
        @effective_ports = @{$self->infer_c1_ports_from_child_interface($realized_instance, $fsm_file, $header)};
    }

    my @port_bindings = map {
        {
            port_name => $_->name,
            signal_name => $_->name,
        }
    } @effective_ports;
    my @resolved_links = map {
        my $port = $_;
        FSM::Composition::Link->new(
            source => ($port->direction eq 'input' ? $port->name : $realized_instance->instance_name.'.'.$port->name),
            target => ($port->direction eq 'input' ? $realized_instance->instance_name.'.'.$port->name : $port->name),
            raw_token => undef,
            origin_kind => ($port->binding_mode || 'explicit') eq 'implicit_passthrough'
                ? 'inferred_c1_passthrough_link'
                : 'declared_c1_passthrough_link',
        );
    } @effective_ports;

    my $planned_instance = $self->clone_realized_instance_with_bindings($realized_instance, \@port_bindings);

    return FSM::Composition::Plan->new(
        lane => 'C1',
        top_name => $composition_spec->top->name,
        ports => \@effective_ports,
        links => [],
        resolved_links => \@resolved_links,
        nets => [],
        instances => [$planned_instance],
        raw_spec => $composition_spec,
    );
}

sub infer_c1_ports_from_child_interface ($self, $realized_instance, $fsm_file, $header) {
    my @child_ports = @{$realized_instance->interface_ports || []};

    Carp::confess
        "Composition source '$header' in '$fsm_file' omits explicit top-port declarations in the single-child passthrough C1 lane, ".
        "but realized child instance '".$realized_instance->instance_name."' exposes no ports to infer. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @child_ports;

    return [
        map {
            FSM::Composition::Port->new(
                name => $_->name,
                direction => $_->direction,
                width => $_->width,
                type => $_->type,
                raw_token => undef,
                binding_mode => 'implicit_passthrough',
                origin_kind => 'inferred_c1_passthrough_port',
            )
        } @child_ports
    ];
}

sub augment_with_inferred_top_ports_from_explicit_links ($self, $ports, $toplinks, $realized_instances, $fsm_file, $header) {
    my @ports = @{$ports || []};
    my %declared_by_name = map { $_->name => $_ } @ports;
    my %instances_by_name;
    my %child_ports_by_instance;
    my %inferred_specs;

    for my $instance (@{$realized_instances || []}) {
        $instances_by_name{$instance->instance_name} = $instance;
        $child_ports_by_instance{$instance->instance_name} = $self->index_ports_by_name($instance->interface_ports);
    }

    for my $toplink (@{$toplinks || []}) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            my $target = $link->target || '';

            my ($source_top_name) = $source =~ /^(\w+)$/;
            my ($target_top_name) = $target =~ /^(\w+)$/;
            my $source_is_top = defined $source_top_name;
            my $target_is_top = defined $target_top_name;

            if ($source_is_top && !$declared_by_name{$source_top_name} && $target =~ /^\w+\.\w+$/) {
                my $child_endpoint = $self->resolve_composition_endpoint(
                    $target,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                $self->record_inferred_top_port_from_explicit_link(
                    \%inferred_specs,
                    $source_top_name,
                    'input',
                    $child_endpoint,
                    $source.' -> '.$target,
                    $fsm_file,
                    $header,
                );
            }

            if ($target_is_top && !$declared_by_name{$target_top_name} && $source =~ /^\w+\.\w+$/) {
                my $child_endpoint = $self->resolve_composition_endpoint(
                    $source,
                    {},
                    \%instances_by_name,
                    \%child_ports_by_instance,
                    $fsm_file,
                    $header,
                );
                $self->record_inferred_top_port_from_explicit_link(
                    \%inferred_specs,
                    $target_top_name,
                    'output',
                    $child_endpoint,
                    $source.' -> '.$target,
                    $fsm_file,
                    $header,
                );
            }
        }
    }

    my @inferred_ports = map {
        FSM::Composition::Port->new(
            name => $_->{name},
            direction => $_->{direction},
            width => $_->{width},
            type => $_->{type},
            raw_token => undef,
            binding_mode => 'explicit',
            origin_kind => 'inferred_explicit_toplink_port',
        )
    } values %inferred_specs;

    @inferred_ports = sort {
        $self->system_port_sort_key($a) <=> $self->system_port_sort_key($b)
        ||
        $a->name cmp $b->name
    } @inferred_ports;

    return [@ports, @inferred_ports];
}

sub record_inferred_top_port_from_explicit_link ($self, $inferred_specs, $top_name, $direction, $child_endpoint, $evidence, $fsm_file, $header) {
    my $width = $child_endpoint->{port}->width;
    my $type = $self->normalized_interface_type($child_endpoint->{port}->type);
    my $existing = $inferred_specs->{$top_name};

    if ($existing) {
        if ($existing->{direction} ne $direction) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because that same top endpoint is used as both an input and an output across explicit links. ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on one direction. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($existing->{width} != $width) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on width (".$existing->{width}." vs $width). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($existing->{type} ne $type) {
            my $seen = join(', ', @{$existing->{evidence}}, $evidence);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$top_name', ".
                "but explicit top-link port inference is blocked because the linked child endpoints disagree on interface type ('".$existing->{type}."' vs '$type'). ".
                "Seen explicit link evidence: $seen. ".
                "The current bounded convention-over-configuration slice only infers a missing top port when all explicit top-link uses of that endpoint agree on type metadata too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        push @{$existing->{evidence}}, $evidence;
        return;
    }

    $inferred_specs->{$top_name} = {
        name => $top_name,
        direction => $direction,
        width => $width,
        type => $type,
        evidence => [$evidence],
    };
}

sub augment_with_inferred_undeclared_top_inputs ($self, $ports, $realized_instances, $toplinks, $fsm_file, $header) {
    my @ports = @{$ports || []};
    my %declared_by_name = map { $_->name => $_ } @ports;
    my %port_groups;
    my %explicitly_linked_child_input_names;
    my %same_name_undeclared_top_input_links;

    for my $toplink (@{$toplinks || []}) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            my $target = $link->target || '';
            my ($target_port_name) = $target =~ /^\w+\.(\w+)$/;
            next unless defined $target_port_name;
            my $source_is_child_endpoint = $source =~ /^\w+\.\w+$/;
            my ($source_top_port_name) = $source =~ /^(\w+)$/;
            my $source_is_declared_top_port = defined($source_top_port_name) && $declared_by_name{$source_top_port_name};
            if (defined($source_top_port_name) && !$source_is_declared_top_port && $source_top_port_name eq $target_port_name) {
                $same_name_undeclared_top_input_links{$target_port_name} = 1;
                next;
            }
            next unless $source_is_child_endpoint || $source_is_declared_top_port;
            $explicitly_linked_child_input_names{$target_port_name} = 1;
        }
    }

    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @{$port_groups{$port->name}}, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }

    my @inferred_ports;
    for my $port_name (sort keys %port_groups) {
        next if $declared_by_name{$port_name};
        next if $explicitly_linked_child_input_names{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @candidates;
        next unless @input_candidates;
        next unless @input_candidates == @candidates;

        my %widths = map { $_->{port}->width => 1 } @input_candidates;
        if (keys(%widths) > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @input_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-input inference is blocked because same-name child inputs disagree on width. ".
                "Seen child inputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top inputs when all same-name child inputs agree exactly on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %types = map { $self->normalized_interface_type($_->{port}->type) => 1 } @input_candidates;
        if (keys(%types) > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.$self->normalized_interface_type($_->{port}->type).']'
            } @input_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-input inference is blocked because same-name child inputs disagree on interface type. ".
                "Seen child inputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top inputs when all same-name child inputs agree exactly on type metadata too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $template = $input_candidates[0]{port};
        push @inferred_ports, FSM::Composition::Port->new(
            name => $template->name,
            direction => 'input',
            width => $template->width,
            type => $self->normalized_interface_type($template->type),
            raw_token => undef,
            binding_mode => $same_name_undeclared_top_input_links{$template->name}
                ? 'explicit'
                : 'implicit_fanout',
            origin_kind => 'inferred_undeclared_top_input_port',
        );
    }

    @inferred_ports = sort {
        $self->system_port_sort_key($a) <=> $self->system_port_sort_key($b)
        ||
        $a->name cmp $b->name
    } @inferred_ports;

    return [@ports, @inferred_ports];
}

sub augment_with_inferred_undeclared_top_outputs ($self, $ports, $realized_instances, $toplinks, $fsm_file, $header) {
    my @ports = @{$ports || []};
    my %declared_by_name = map { $_->name => $_ } @ports;
    my %port_groups;
    my %explicitly_linked_child_output_endpoints;

    for my $toplink (@{$toplinks || []}) {
        for my $link (@{$toplink->links || []}) {
            my $source = $link->source || '';
            next unless $source =~ /^(\w+)\.(\w+)$/;
            $explicitly_linked_child_output_endpoints{"$1.$2"} = 1;
        }
    }

    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @{$port_groups{$port->name}}, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }

    my @inferred_ports;
    for my $port_name (sort keys %port_groups) {
        next if $declared_by_name{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @candidates;
        next unless @output_candidates;
        next unless @output_candidates == @candidates;

        my @top_facing_output_candidates = grep {
            !$explicitly_linked_child_output_endpoints{$_->{instance_name}.'.'.$_->{port}->name}
        } @output_candidates;
        next unless @top_facing_output_candidates;

        if (@top_facing_output_candidates > 1) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @top_facing_output_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits top port '$port_name', ".
                "but undeclared top-output inference is blocked because several same-name child outputs remain unconsumed by explicit links. ".
                "Seen child outputs: $candidates. ".
                "The current bounded inference slice only infers undeclared top outputs when exactly one same-name child output remains top-facing. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $template = $top_facing_output_candidates[0]{port};
        my $source_endpoint = $top_facing_output_candidates[0]{instance_name}.'.'.$template->name;
        push @inferred_ports, FSM::Composition::Port->new(
            name => $template->name,
            direction => 'output',
            width => $template->width,
            type => $self->normalized_interface_type($template->type),
            raw_token => $source_endpoint,
            binding_mode => 'implicit_unique_output',
            origin_kind => 'inferred_undeclared_top_output_port',
        );
    }

    @inferred_ports = sort {
        $self->system_port_sort_key($a) <=> $self->system_port_sort_key($b)
        ||
        $a->name cmp $b->name
    } @inferred_ports;

    return [@ports, @inferred_ports];
}

sub assert_c1_port_exposure_matches_child ($self, $ports_block, $realized_instance, $child_port_info, $fsm_file, $header) {
    my $top_ports_by_name = $self->assert_unique_top_ports($ports_block, $fsm_file, $header);

    for my $child_port_name (sort keys %$child_port_info) {
        Carp::confess
            "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
            "but C1 passthrough exposure is blocked because the current active C1 lane requires every child port to be explicitly exposed in '?ports'. ".
            "Missing top exposure for child port '$child_port_name' on instance '".$realized_instance->instance_name."'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $top_ports_by_name->{$child_port_name};
    }

    for my $port (@{$ports_block->ports}) {
        my $child_port = $child_port_info->{$port->name};
        Carp::confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."', ".
            "but C1 passthrough exposure is blocked because the realized child interface has no port with that name. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $child_port;

        Carp::confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."' with width ".$port->width.", ".
            "but C1 passthrough exposure is blocked because child port '".$port->name."' has width ".$child_port->width.".".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port->width == $child_port->width;

        Carp::confess
            "Composition source '$header' in '$fsm_file' declares top port '".$port->name."' as ".$port->direction.", ".
            "but C1 passthrough exposure is blocked because child port '".$port->name."' is ".$child_port->direction.".".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port->direction eq $child_port->direction;
    }
}

sub build_c2_composition_plan ($self, $composition_spec, $top, $ports_block, $ports, $toplinks, $realized_instances, $fsm_file, $header) {
    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but C2 lane selection is blocked because the current active C2 lane requires at least two generated child instances such as '?fsmc' or '?dtc'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @{$realized_instances || []} >= 2;

    Carp::confess
        "Composition source '$header' in '$fsm_file' mixes '?rtl' children into the generated-child-only C2 lane. ".
        "The active mixed external-RTL lane is C3 instead. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        if grep { !$self->is_generated_child_kind($_->kind) } @{$realized_instances || []};

    return $self->build_explicit_link_composition_plan(
        'C2',
        $composition_spec,
        $top,
        $ports_block,
        $ports,
        $toplinks,
        $realized_instances,
        $fsm_file,
        $header,
    );
}

sub build_c3_composition_plan ($self, $composition_spec, $top, $ports_block, $ports, $toplinks, $realized_instances, $generated_instance_count, $fsmc_instance_count, $dtc_instance_count, $rtl_instance_count, $fsm_file, $header) {
    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but the current active C3 lane requires at least one '?rtl' child and otherwise allows any number of generated children ('?fsmc' or '?dtc') beside those external RTL children. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $rtl_instance_count >= 1;

    return $self->build_explicit_link_composition_plan(
        'C3',
        $composition_spec,
        $top,
        $ports_block,
        $ports,
        $toplinks,
        $realized_instances,
        $fsm_file,
        $header,
    );
}

sub build_c4_composition_plan ($self, $composition_spec, $top, $ports_block, $ports, $toplinks, $realized_instances, $generated_instance_count, $fsmc_instance_count, $dtc_instance_count, $rtl_instance_count, $fsm_file, $header) {
    my $declared_by_name_port_count = scalar(grep { ($_->binding_mode || 'explicit') eq 'connect_by_name' } @{$ports || []});
    Carp::confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane requires at least one '=port' declaration inside '?ports'. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless $declared_by_name_port_count;

    Carp::confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane requires at least one realized child instance. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @{$realized_instances || []} >= 1;

    Carp::confess
        "Composition source '$header' in '$fsm_file' requests declared connect-by-name, ".
        "but the current active C4 lane only extends the already shipped child-realization sets: ".
        "one or more generated children ('?fsmc' / '?dtc'), one or more '?rtl' children, or any mixture of those generated and external RTL children. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless ($generated_instance_count >= 1)
            || ($rtl_instance_count >= 1);

    my @links = map { @{$_->links || []} } @{$toplinks || []};
    push @links, @{$self->build_declared_by_name_links($ports, $realized_instances, $fsm_file, $header)};

    return $self->build_linked_composition_plan(
        'C4',
        $composition_spec,
        $top,
        $ports_block,
        $ports,
        \@links,
        $realized_instances,
        $fsm_file,
        $header,
    );
}

sub build_explicit_link_composition_plan ($self, $lane, $composition_spec, $top, $ports_block, $ports, $toplinks, $realized_instances, $fsm_file, $header) {
    my @links = map { @{$_->links || []} } @{$toplinks || []};
    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized and parsed into typed composition IR, ".
        "but explicit-link lane entry is blocked because the current active $lane lane requires explicit '?toplink' wiring. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
        unless @links;

    return $self->build_linked_composition_plan(
        $lane,
        $composition_spec,
        $top,
        $ports_block,
        $ports,
        \@links,
        $realized_instances,
        $fsm_file,
        $header,
    );
}

sub build_declared_by_name_links ($self, $ports, $realized_instances, $fsm_file, $header) {
    my @links;
    my @candidate_endpoints;
    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @candidate_endpoints, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }
    my @system_port_names = $self->system_port_names_from_endpoints(\@candidate_endpoints);
    my %system_port_names = map { $_ => 1 } @system_port_names;

    for my $top_port (@{$ports || []}) {
        next unless ($top_port->binding_mode || 'explicit') eq 'connect_by_name';

        Carp::confess
            "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
            "but declared connect-by-name is blocked because the shared system ports '".join("' and '", @system_port_names)."' already use the dedicated system-input contract and must not be declared with '=port' connect-by-name syntax. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $system_port_names{$top_port->name};

        my @same_name_candidates = grep { $_->{port}->name eq $top_port->name } @candidate_endpoints;
        my @direction_incompatible_candidates = grep {
            $_->{port}->direction ne $top_port->direction
        } @same_name_candidates;
        if (@direction_incompatible_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because same-name child endpoints include incompatible directions for a top ".$top_port->direction." port. ".
                "Seen same-name child endpoints: $candidates. ".
                "The active C4 lane currently keeps top-boundary connect-by-name direction-strict even when several same-name child ports exist. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my @width_incompatible_candidates = grep {
            $_->{port}->width != $top_port->width
        } @same_name_candidates;
        if (@width_incompatible_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because same-name child endpoints do not all match the declared width ".$top_port->width.". ".
                "Seen same-name child endpoints: $candidates. ".
                "The current active composition lanes require exact width agreement. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if ($top_port->direction eq 'input') {
            push @links, map {
                FSM::Composition::Link->new(
                    source => $top_port->name,
                    target => $_->{instance_name}.'.'.$_->{port}->name,
                    raw_token => '=byname:'.$top_port->name,
                    origin_kind => 'declared_connect_by_name_link',
                )
            } @same_name_candidates;
            next;
        }

        if (@same_name_candidates > 1) {
            my $candidates = join(', ', map { $_->{instance_name}.'.'.$_->{port}->name } @same_name_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because that name resolves ambiguously to multiple compatible child endpoints: $candidates. ".
                "The current active C4 lane requires exactly one compatible child output for each '=port' top output declaration. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        if (@same_name_candidates == 1) {
            my $match = $same_name_candidates[0];
            push @links, FSM::Composition::Link->new(
                source => $match->{instance_name}.'.'.$match->{port}->name,
                target => $top_port->name,
                raw_token => '=byname:'.$top_port->name,
                origin_kind => 'declared_connect_by_name_link',
            );
            next;
        }

        if (@same_name_candidates) {
            my $candidates = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @same_name_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
                "but declared connect-by-name is blocked because no compatible child endpoint matches its declared direction/width (".$top_port->direction.", width=".$top_port->width."). ".
                "Seen same-name child endpoints: $candidates. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        Carp::confess
            "Composition source '$header' in '$fsm_file' marks top port '".$top_port->name."' for declared connect-by-name, ".
            "but declared connect-by-name is blocked because no realized child endpoint with that name exists. ".
            "The current active C4 lane requires each '=port' declaration to match one or more child inputs for top inputs, or exactly one child output for top outputs. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
    }

    return \@links;
}

sub build_linked_composition_plan ($self, $lane, $composition_spec, $top, $ports_block, $ports, $links, $realized_instances, $fsm_file, $header) {
    my $top_ports_by_name = $self->assert_unique_top_ports($ports_block, $fsm_file, $header);
    my %instances_by_name;
    my %child_ports_by_instance;
    my %bindings_by_instance;
    my %reserved_targets;
    my %system_top_ports;
    my @system_auto_links;

    for my $instance (@{$realized_instances || []}) {
        Carp::confess
            "Composition source '$header' in '$fsm_file' declares duplicate child instance name '".$instance->instance_name."', ".
            "but composition shape is blocked because the active composition lanes require each realized child instance name to be unique. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if $instances_by_name{$instance->instance_name};

        $instances_by_name{$instance->instance_name} = $instance;
        $child_ports_by_instance{$instance->instance_name} = $self->index_ports_by_name($instance->interface_ports);
        $bindings_by_instance{$instance->instance_name} = {
            map { $_->name => undef } @{$instance->interface_ports}
        };
    }

    my @resolved_links_input = @{$links || []};
    if ($lane eq 'C2' || $lane eq 'C3') {
        push @resolved_links_input, @{
            $self->build_implicit_top_input_links(
                $ports,
                $links,
                $realized_instances,
                $fsm_file,
                $header,
            )
        };
        push @resolved_links_input, @{
            $self->build_implicit_top_output_links(
                $ports,
                $links,
                $realized_instances,
                $fsm_file,
                $header,
            )
        };
        push @resolved_links_input, @{
            $self->build_implicit_internal_same_name_links(
                $ports,
                $links,
                $realized_instances,
                $fsm_file,
                $header,
            )
        };
    }

    for my $instance (@{$realized_instances || []}) {
        for my $system_port ($self->system_interface_ports($instance->interface_ports)->@*) {
            my $system_port_name = $system_port->name;
            my $top_port = $top_ports_by_name->{$system_port_name} or next;
            my $child_port = $child_ports_by_instance{$instance->instance_name}{$system_port_name} or next;

            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top port '$system_port_name' as ".$top_port->direction.", ".
                "but the current active $lane lane requires '$system_port_name' to be an input when auto-wiring child system ports. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port->direction eq 'input';

            Carp::confess
                "Composition source '$header' in '$fsm_file' realizes child port '".$instance->instance_name.".$system_port_name' as ".$child_port->direction.", ".
                "but the current active $lane lane expects child system ports to be inputs. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $child_port->direction eq 'input';

            $bindings_by_instance{$instance->instance_name}{$system_port_name} = $system_port_name;
            $reserved_targets{"child:".$instance->instance_name.".$system_port_name"} = "auto top input '$system_port_name'";
            $system_top_ports{$system_port_name} = 1;
            push @system_auto_links, FSM::Composition::Link->new(
                source => $system_port_name,
                target => $instance->instance_name.'.'.$system_port_name,
                raw_token => undef,
                origin_kind => 'auto_system_port_link',
            );
        }
    }

    my @resolved_links;
    my %links_by_source;
    my %source_endpoint_by_key;

    for my $link (@resolved_links_input) {
        my $source = $self->resolve_composition_endpoint(
            $link->source,
            $top_ports_by_name,
            \%instances_by_name,
            \%child_ports_by_instance,
            $fsm_file,
            $header,
        );
        my $target = $self->resolve_composition_endpoint(
            $link->target,
            $top_ports_by_name,
            \%instances_by_name,
            \%child_ports_by_instance,
            $fsm_file,
            $header,
        );

        $self->assert_explicit_link_roles($source, $target, $fsm_file, $header);

        Carp::confess
            "Composition source '$header' in '$fsm_file' links '".$source->{raw}."' (width ".$source->{port}->width.") to '".$target->{raw}."' (width ".$target->{port}->width."), ".
            "but explicit link is blocked because the current active composition lanes require exact width agreement. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->width == $target->{port}->width;

        my $target_key = $target->{key};
        if ($reserved_targets{$target_key}) {
            Carp::confess
                "Composition source '$header' in '$fsm_file' assigns explicit link driver '".$source->{raw}."' to target '".$target->{raw}."', ".
                "but explicit link is blocked because that target is already driven by ".$reserved_targets{$target_key}.". ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }
        $reserved_targets{$target_key} = "explicit link '".$source->{raw}."'";

        my $source_key = $source->{key};
        $source_endpoint_by_key{$source_key} = $source;
        push @{$links_by_source{$source_key}}, {
            link => $link,
            source => $source,
            target => $target,
        };
        push @resolved_links, {
            link => $link,
            source => $source,
            target => $target,
        };
    }

    my @nets;
    my %carrier_signal_by_source;

    for my $source_key (sort keys %links_by_source) {
        my $source = $source_endpoint_by_key{$source_key};
        my @group = @{$links_by_source{$source_key}};

        if ($source->{kind} eq 'top_port') {
            for my $resolved_link (@group) {
                Carp::confess
                    "Composition source '$header' in '$fsm_file' links top input '".$source->{raw}."' directly to top output '".$resolved_link->{target}{raw}."', ".
                    "but explicit-link topology is blocked because the current active $lane lane only supports top inputs driving child inputs. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    if $resolved_link->{target}{kind} eq 'top_port';
            }
            $carrier_signal_by_source{$source_key} = $source->{port}->name;
            next;
        }

        my @top_output_targets = grep { $_->{target}{kind} eq 'top_port' } @group;
        Carp::confess
            "Composition source '$header' in '$fsm_file' drives multiple top outputs from '".$source->{raw}."', ".
            "but explicit-link topology is blocked because the current active $lane lane supports at most one top-output target per resolved source. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            if @top_output_targets > 1;

        my $carrier_signal_name;
        if (@top_output_targets == 1) {
            $carrier_signal_name = $top_output_targets[0]{target}{port}->name;
        } else {
            my $preferred_net_name;
            if (@group) {
                my @implicit_internal_names = map {
                    $_->{link}->raw_token =~ /^=implicit-internal:(\w+)$/ ? $1 : ()
                } @group;
                if (@implicit_internal_names == @group) {
                    my %names = map { $_ => 1 } @implicit_internal_names;
                    $preferred_net_name = $implicit_internal_names[0] if keys(%names) == 1;
                }
            }

            my $net_name = $self->allocate_composition_net_name($source, $top_ports_by_name, \@nets, $preferred_net_name);
            push @nets, FSM::Composition::Net->new(
                name => $net_name,
                width => $source->{port}->width,
                source => $source->{raw},
                targets => [map { $_->{target}{raw} } @group],
            );
            $carrier_signal_name = $net_name;
        }
        $carrier_signal_by_source{$source_key} = $carrier_signal_name;
        $bindings_by_instance{$source->{instance_name}}{$source->{port}->name} = $carrier_signal_name;
    }

    my %top_port_usage;
    for my $resolved_link (@resolved_links) {
        my $source = $resolved_link->{source};
        my $target = $resolved_link->{target};
        my $carrier_signal_name = $carrier_signal_by_source{$source->{key}};

        if ($source->{kind} eq 'top_port') {
            $top_port_usage{$source->{port}->name}{source} = 1;
        }

        if ($target->{kind} eq 'top_port') {
            $top_port_usage{$target->{port}->name}{target} = 1;
            next;
        }

        $bindings_by_instance{$target->{instance_name}}{$target->{port}->name} = $carrier_signal_name;
    }

    for my $top_port_name (sort keys %{$top_ports_by_name || {}}) {
        my $top_port = $top_ports_by_name->{$top_port_name};
        next if $system_top_ports{$top_port_name};

        if ($top_port->direction eq 'input') {
            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top input '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?toplink' usage for every non-system top input. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port_usage{$top_port_name}{source};
        } else {
            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top output '$top_port_name', ".
                "but explicit-link top wiring is blocked because the current active $lane lane requires explicit '?toplink' usage for every top output. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $top_port_usage{$top_port_name}{target};
        }
    }

    my @planned_instances;
    for my $instance (@{$realized_instances || []}) {
        my @port_bindings;
        for my $port (@{$instance->interface_ports}) {
            my $signal_name = $bindings_by_instance{$instance->instance_name}{$port->name};

            Carp::confess
                "Composition source '$header' in '$fsm_file' leaves child port '".$instance->instance_name.".".$port->name."' unconnected, ".
                "but realized child wiring is blocked because the current active $lane lane requires every realized child port to be wired explicitly, through declared connect-by-name, or through the shared system-input contract. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless defined $signal_name;

            push @port_bindings, {
                port_name => $port->name,
                signal_name => $signal_name,
            };
        }

        push @planned_instances, $self->clone_realized_instance_with_bindings($instance, \@port_bindings);
    }

    my $composition_plan = FSM::Composition::Plan->new(
        lane => $lane,
        top_name => $top->name,
        ports => $ports,
        links => $links,
        resolved_links => [@system_auto_links, @resolved_links_input],
        nets => \@nets,
        instances => \@planned_instances,
        auxiliary_assignments => [],
        shared_datapath_candidates => [],
        raw_spec => $composition_spec,
    );

    return $self->augment_with_shared_datapath_runtime_support($composition_plan);
}

sub build_implicit_top_input_links ($self, $ports, $explicit_links, $realized_instances, $fsm_file, $header) {
    my @links;
    my %system_port_names = map { $_ => 1 } $self->system_port_names_from_endpoints([
        map {
            my $instance = $_;
            map {
                {
                    instance_name => $instance->instance_name,
                    port => $_,
                }
            } @{$instance->interface_ports || []}
        } @{$realized_instances || []}
    ]);
    my %explicit_sources = map { (($_->source || '') => 1) } @{$explicit_links || []};
    my %explicit_targets = map { (($_->target || '') => 1) } @{$explicit_links || []};
    my @candidate_endpoints = map {
        my $instance = $_;
        map {
            {
                instance_name => $instance->instance_name,
                port => $_,
            }
        } @{$instance->interface_ports || []}
    } @{$realized_instances || []};

    for my $top_port (@{$ports || []}) {
        my $binding_mode = $top_port->binding_mode || 'explicit';
        next unless $binding_mode eq 'implicit_fanout' || ($binding_mode eq 'explicit' && ($top_port->direction || '') eq 'input');
        next if $system_port_names{$top_port->name};

        my @same_name_candidates = grep { $_->{port}->name eq $top_port->name } @candidate_endpoints;
        if ($binding_mode eq 'explicit' && @same_name_candidates) {
            my @direction_incompatible_candidates = grep {
                ($_->{port}->direction || '') ne 'input'
            } @same_name_candidates;
            if (@direction_incompatible_candidates) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.']'
                } @same_name_candidates);
                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."', ".
                    "but same-name top-input convention is blocked because same-name child endpoints include incompatible directions. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring for that family if the mixed-direction naming is intentional. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }

            my @width_incompatible_candidates = grep {
                $_->{port}->width != $top_port->width
            } @same_name_candidates;
            if (@width_incompatible_candidates) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.']'
                } @same_name_candidates);
                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."' with width ".$top_port->width.", ".
                    "but same-name top-input convention is blocked because same-name child inputs do not all match that width. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring or align the interface widths. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }

            my $declared_type = $self->normalized_interface_type($top_port->type);
            my @type_incompatible_candidates = grep {
                $self->normalized_interface_type($_->{port}->type) ne $declared_type
            } @same_name_candidates;
            if (@type_incompatible_candidates) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.$self->normalized_interface_type($_->{port}->type).']'
                } @same_name_candidates);
                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top input '".$top_port->name."' with interface type '$declared_type', ".
                    "but same-name top-input convention is blocked because same-name child inputs do not all match that type metadata. ".
                    "Seen same-name child endpoints: $candidates. ".
                    "Use explicit '?toplink' wiring or align the interface types. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }
        }

        next if $binding_mode eq 'explicit' && ($explicit_sources{$top_port->name} || $explicit_targets{$top_port->name});

        for my $candidate (@same_name_candidates) {
            next unless ($candidate->{port}->direction || '') eq 'input';
            next unless $candidate->{port}->width == $top_port->width;
            next unless $self->normalized_interface_type($candidate->{port}->type)
                eq $self->normalized_interface_type($top_port->type);

            my $target_endpoint = $candidate->{instance_name}.'.'.$candidate->{port}->name;
            next if $binding_mode eq 'explicit' && $explicit_targets{$target_endpoint};

            push @links, FSM::Composition::Link->new(
                source => $top_port->name,
                target => $target_endpoint,
                raw_token => '=implicit:'.$top_port->name,
                origin_kind => $binding_mode eq 'implicit_fanout'
                    ? 'inferred_undeclared_top_input_link'
                    : 'inferred_plain_explicit_top_input_link',
            );
        }
    }

    return \@links;
}

sub build_implicit_top_output_links ($self, $ports, $explicit_links, $realized_instances, $fsm_file, $header) {
    my @links;
    my %explicit_sources = map { (($_->source || '') => 1) } @{$explicit_links || []};
    my %explicit_targets = map { (($_->target || '') => 1) } @{$explicit_links || []};
    my %port_groups;

    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @{$port_groups{$port->name}}, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }

    for my $top_port (@{$ports || []}) {
        my $binding_mode = $top_port->binding_mode || 'explicit';
        next unless $binding_mode eq 'implicit_unique_output' || ($binding_mode eq 'explicit' && ($top_port->direction || '') eq 'output');

        if ($binding_mode eq 'explicit') {
            next if $explicit_sources{$top_port->name} || $explicit_targets{$top_port->name};

            my @same_name_candidates = @{$port_groups{$top_port->name} || []};
            my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @same_name_candidates;
            next if @input_candidates;

            my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @same_name_candidates;
            my @top_facing_output_candidates = grep {
                !$explicit_sources{$_->{instance_name}.'.'.$_->{port}->name}
            } @output_candidates;

            if (@top_facing_output_candidates > 1) {
                my $candidates = join(', ', map {
                    $_->{instance_name}.'.'.$_->{port}->name.
                    '['.$_->{port}->direction.', width='.$_->{port}->width.']'
                } @top_facing_output_candidates);
                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."', ".
                    "but same-name top-output convention is blocked because several same-name child outputs remain top-facing. ".
                    "Seen child outputs: $candidates. ".
                    "Use explicit '?toplink' wiring if that ambiguity is intentional. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
            }

            if (@top_facing_output_candidates == 1) {
                my $candidate = $top_facing_output_candidates[0];
                my $candidate_type = $self->normalized_interface_type($candidate->{port}->type);
                my $declared_type = $self->normalized_interface_type($top_port->type);

                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."' with width ".$top_port->width.", ".
                    "but same-name top-output convention is blocked because the remaining top-facing child output '".$candidate->{instance_name}.'.'.$candidate->{port}->name."' has width ".$candidate->{port}->width.". ".
                    "Use explicit '?toplink' wiring or align the interface widths. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    unless $candidate->{port}->width == $top_port->width;

                Carp::confess
                    "Composition source '$header' in '$fsm_file' declares top output '".$top_port->name."' with interface type '$declared_type', ".
                    "but same-name top-output convention is blocked because the remaining top-facing child output '".$candidate->{instance_name}.'.'.$candidate->{port}->name."' has interface type '$candidate_type'. ".
                    "Use explicit '?toplink' wiring or align the interface types. ".
                    "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                    unless $candidate_type eq $declared_type;

                push @links, FSM::Composition::Link->new(
                    source => $candidate->{instance_name}.'.'.$candidate->{port}->name,
                    target => $top_port->name,
                    raw_token => '=implicit:'.$top_port->name,
                    origin_kind => 'inferred_plain_explicit_top_output_link',
                );
            }

            next;
        }

        my $source_endpoint = $top_port->raw_token;
        Carp::confess
            "Composition source '$header' in '$fsm_file' inferred undeclared top output '".$top_port->name."', ".
            "but the planner lost the unique source endpoint needed to bind it deterministically. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless defined $source_endpoint && $source_endpoint =~ /^\w+\.\w+$/;

        push @links, FSM::Composition::Link->new(
            source => $source_endpoint,
            target => $top_port->name,
            raw_token => '=implicit:'.$top_port->name,
            origin_kind => 'inferred_undeclared_top_output_link',
        );
    }

    return \@links;
}

sub build_implicit_internal_same_name_links ($self, $ports, $explicit_links, $realized_instances, $fsm_file, $header) {
    my @links;
    my %declared_top_ports = map { $_->name => $_ } @{$ports || []};
    my %system_port_names = map { $_ => 1 } $self->system_port_names_from_endpoints([
        map {
            my $instance = $_;
            map {
                {
                    instance_name => $instance->instance_name,
                    port => $_,
                }
            } @{$instance->interface_ports || []}
        } @{$realized_instances || []}
    ]);
    my %explicit_child_endpoints;
    my %port_groups;

    for my $link (@{$explicit_links || []}) {
        for my $endpoint ($link->source, $link->target) {
            next unless defined $endpoint && $endpoint =~ /^(\w+)\.(\w+)$/;
            $explicit_child_endpoints{"$1.$2"} = 1;
        }
    }

    for my $instance (@{$realized_instances || []}) {
        for my $port (@{$instance->interface_ports || []}) {
            push @{$port_groups{$port->name}}, {
                instance_name => $instance->instance_name,
                port => $port,
            };
        }
    }

    for my $port_name (sort keys %port_groups) {
        next if $system_port_names{$port_name};

        my @candidates = @{$port_groups{$port_name}};
        next if grep { $explicit_child_endpoints{$_->{instance_name}.'.'.$_->{port}->name} } @candidates;

        my @input_candidates = grep { ($_->{port}->direction || '') eq 'input' } @candidates;
        my @output_candidates = grep { ($_->{port}->direction || '') eq 'output' } @candidates;
        next unless @input_candidates && @output_candidates;

        my $declared_top_port = $declared_top_ports{$port_name};
        if ($declared_top_port && ($declared_top_port->direction || '') ne 'output') {
            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top port '$port_name' as ".$declared_top_port->direction.", ".
                "but same-name child ports include one driving output and one or more consuming inputs. ".
                "The current bounded convention-over-configuration slice only allows that same-name internal carrier family to be re-exported through an explicit top output, not through a top input of the same name. ".
                "Keep '$port_name' internal by omitting the top port, or declare '$port_name' as an output if it should be re-exported. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %widths = map { $_->{port}->width => 1 } @candidates;
        if (keys(%widths) > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because same-name child ports disagree on width. ".
                "Seen child ports: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when all participating child ports agree exactly on width. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my %types = map { $self->normalized_interface_type($_->{port}->type) => 1 } @candidates;
        if (keys(%types) > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.', type='.$self->normalized_interface_type($_->{port}->type).']'
            } @candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because same-name child ports disagree on interface type. ".
                "Seen child ports: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when all participating child ports agree exactly on resolved interface type too. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $resolved_width = $candidates[0]{port}->width;
        my $resolved_type = $self->normalized_interface_type($candidates[0]{port}->type);
        if ($declared_top_port) {
            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top output '$port_name' with width ".$declared_top_port->width.", ".
                "but explicit top-output re-export is blocked because the same-name internal-carrier family resolves to width $resolved_width. ".
                "The current bounded convention-over-configuration slice only re-exports an inferred same-name internal carrier when the explicit top output matches the child-side width exactly. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $declared_top_port->width == $resolved_width;

            my $declared_top_type = $self->normalized_interface_type($declared_top_port->type);
            Carp::confess
                "Composition source '$header' in '$fsm_file' declares top output '$port_name' with interface type '$declared_top_type', ".
                "but explicit top-output re-export is blocked because the same-name internal-carrier family resolves to interface type '$resolved_type'. ".
                "The current bounded convention-over-configuration slice only re-exports an inferred same-name internal carrier when the explicit top output matches the child-side type metadata exactly. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
                unless $declared_top_type eq $resolved_type;
        }

        if (@output_candidates > 1) {
            my $seen = join(', ', map {
                $_->{instance_name}.'.'.$_->{port}->name.
                '['.$_->{port}->direction.', width='.$_->{port}->width.']'
            } @output_candidates);
            Carp::confess
                "Composition source '$header' in '$fsm_file' omits explicit same-name internal wiring for '$port_name', ".
                "but undeclared internal-carrier inference is blocked because several same-name child outputs remain available for same-name child inputs. ".
                "Seen child outputs: $seen. ".
                "The current bounded inference slice only infers internal same-name carriers when exactly one same-name child output remains available. ".
                "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
        }

        my $source = $output_candidates[0];
        my $source_endpoint = $source->{instance_name}.'.'.$source->{port}->name;
        if ($declared_top_port) {
            push @links, FSM::Composition::Link->new(
                source => $source_endpoint,
                target => $declared_top_port->name,
                raw_token => '=implicit-internal:'.$port_name,
                origin_kind => 'inferred_internal_carrier_reexport_link',
            );
        }
        for my $target (@input_candidates) {
            push @links, FSM::Composition::Link->new(
                source => $source_endpoint,
                target => $target->{instance_name}.'.'.$target->{port}->name,
                raw_token => '=implicit-internal:'.$port_name,
                origin_kind => 'inferred_internal_carrier_link',
            );
        }
    }

    return \@links;
}

sub clone_realized_instance_with_bindings ($self, $instance, $port_bindings) {
    return FSM::Composition::RealizedInstance->new(
        kind => $instance->kind,
        instance_name => $instance->instance_name,
        module_name => $instance->module_name,
        source_name => $instance->source_name,
        interface_ports => $instance->interface_ports,
        port_bindings => $port_bindings || [],
        module_info => $instance->module_info,
        hdl_code => $instance->hdl_code,
    );
}

sub ensure_composition_net ($self, $nets, $name, $width = 1) {
    return unless defined($name) && length($name);
    return if grep { ($_->name || '') eq $name } @{$nets || []};

    push @{$nets || []}, FSM::Composition::Net->new(
        name => $name,
        width => $width,
        source => undef,
        targets => [],
    );
}

sub ensure_instance_port_binding ($self, $instance, $port_name, $signal_name) {
    return unless $instance && defined($port_name) && length($port_name);
    return unless defined($signal_name) && length($signal_name);

    for my $binding (@{$instance->{port_bindings} || []}) {
        next unless ($binding->{port_name} || '') eq $port_name;
        return if ($binding->{signal_name} || '') eq $signal_name;
    }

    push @{$instance->{port_bindings}}, {
        port_name => $port_name,
        signal_name => $signal_name,
    };
}

sub set_instance_port_binding ($self, $instance, $port_name, $signal_name) {
    return unless $instance && defined($port_name) && length($port_name);
    return unless defined($signal_name) && length($signal_name);

    for my $binding (@{$instance->{port_bindings} || []}) {
        next unless ($binding->{port_name} || '') eq $port_name;
        $binding->{signal_name} = $signal_name;
        return;
    }

    push @{$instance->{port_bindings}}, {
        port_name => $port_name,
        signal_name => $signal_name,
    };
}

sub composition_system_signal_names ($self, $composition_plan) {
    my ($clock_name, $reset_name);
    for my $port (@{$composition_plan->ports || []}) {
        my $type = $port->type || '';
        $clock_name ||= $port->name if $type eq 'clock';
        $reset_name ||= $port->name if $type eq 'reset';
    }

    if ((!defined($clock_name) || !length($clock_name)) || (!defined($reset_name) || !length($reset_name))) {
        for my $instance (@{$composition_plan->instances || []}) {
            my %bindings = map {
                (($_->{port_name} || '') => ($_->{signal_name} || ''))
            } @{$instance->port_bindings || []};

            for my $port (@{$instance->interface_ports || []}) {
                my $bound_signal = $bindings{$port->name} || next;
                my $type = $port->type || '';
                $clock_name ||= $bound_signal if $type eq 'clock';
                $reset_name ||= $bound_signal if $type eq 'reset';
            }
        }
    }

    return ($clock_name, $reset_name);
}

sub composition_shared_datapath_candidates_for_plan ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    return [] unless $composition_plan;

    if ($composition_plan->can('shared_datapath_candidates')
        && ref($composition_plan->shared_datapath_candidates) eq 'ARRAY'
        && @{$composition_plan->shared_datapath_candidates})
    {
        return $composition_plan->shared_datapath_candidates;
    }

    my $shared_datapath_candidates = $self->build_composition_shared_datapath_candidates(
        $composition_plan,
        $structural_rtl_ir,
        $intent_hir,
    );
    $composition_plan->{shared_datapath_candidates} = $shared_datapath_candidates;
    return $shared_datapath_candidates;
}

sub augment_with_shared_datapath_runtime_support ($self, $composition_plan) {
    return $composition_plan unless $composition_plan;

    my $nets = $composition_plan->{nets} ||= [];
    $composition_plan->{auxiliary_assignments} ||= [];
    my $shared_datapath_candidates = $self->composition_shared_datapath_candidates_for_plan($composition_plan);
    return $composition_plan unless @{$shared_datapath_candidates || []};

    my %needed_exports;
    for my $candidate (@{$shared_datapath_candidates || []}) {
        next unless ref($candidate) eq 'HASH';
        my $signal_name = $candidate->{signal_name} || next;

        for my $family (@{$candidate->{aggregate_enable_families} || []}) {
            next unless ref($family) eq 'HASH';
            my $rhs_value = $family->{rhs_value};

            for my $contributor (@{$family->{contributors} || []}) {
                next unless ref($contributor) eq 'HASH';
                my $endpoint = $contributor->{endpoint} || '';
                my ($instance_name) = $endpoint =~ /^(\w+)\./;
                next unless defined $instance_name;
                $needed_exports{join "\x1E", $instance_name, $signal_name, ($rhs_value // '')} = 1;
            }
        }
    }

    for my $instance (@{$composition_plan->{instances} || []}) {
        next unless ($instance->kind || '') eq 'fsmc';

        for my $export (@{$instance->module_info->{shared_datapath_source_exports} || []}) {
            next unless ref($export) eq 'HASH';
            my $signal_name = $export->{signal_name} || next;
            my $rhs_value = $export->{rhs_value};
            next unless $needed_exports{join "\x1E", $instance->instance_name, $signal_name, ($rhs_value // '')};
            my $source_enable_signal = $self->shared_datapath_source_value_enable_name(
                $instance->instance_name,
                $signal_name,
                $rhs_value,
            );

            $self->ensure_composition_net($nets, $source_enable_signal, 1);
            $self->ensure_instance_port_binding($instance, $export->{port_name}, $source_enable_signal);
        }
    }

    my @helper_assignments;
    my @assertion_sections;
    my @lifted_runtime_sections;
    my ($clock_name, $reset_name) = $self->composition_system_signal_names($composition_plan);
    my %instances_by_name = map {
        (($_->instance_name || '') => $_)
    } @{$composition_plan->{instances} || []};

    for my $candidate (@{$shared_datapath_candidates || []}) {
        next unless ref($candidate) eq 'HASH';

        $self->ensure_composition_net($nets, $candidate->{aggregate_target_enable_signal}, 1);
        $self->ensure_composition_net($nets, $candidate->{multi_value_conflict_signal}, 1);

        my @aggregate_value_enables;
        for my $family (@{$candidate->{aggregate_enable_families} || []}) {
            next unless ref($family) eq 'HASH';
            my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
            my @source_enable_signals = map {
                $_->{source_enable_signal}
            } grep {
                ref($_) eq 'HASH'
            } @{$family->{contributors} || []};

            $self->ensure_composition_net($nets, $aggregate_enable_signal, 1);
            $self->ensure_composition_net($nets, $family->{same_value_conflict_signal}, 1);

            push @aggregate_value_enables, $aggregate_enable_signal;
            push @helper_assignments,
                "  assign $aggregate_enable_signal = "
                    . $self->shared_datapath_or_expression(\@source_enable_signals) . ";",
                "  assign $family->{same_value_conflict_signal} = "
                    . $self->shared_datapath_conflict_expression(\@source_enable_signals) . ";";
        }

        push @helper_assignments,
            "  assign $candidate->{aggregate_target_enable_signal} = "
                . $self->shared_datapath_or_expression(\@aggregate_value_enables) . ";",
            "  assign $candidate->{multi_value_conflict_signal} = "
                . $self->shared_datapath_conflict_expression(\@aggregate_value_enables) . ";";

        my @candidate_assertion_lines = $self->shared_datapath_assertion_runtime_lines($candidate);
        push @assertion_sections, @candidate_assertion_lines if @candidate_assertion_lines;

        my %planned_reexports = map {
            ($_ => 1)
        } @{$candidate->{planned_reexport_top_output_signals} || []};
        my %preserved_top_outputs = map {
            ($_ => 1)
        } @{$candidate->{top_output_signals} || []};
        my $runtime_mode =
            (($candidate->{storage_class} || '') eq 'registered')
            && (($candidate->{peer_read_policy} || '') eq 'registered_loopback')
            && ($candidate->{loopback_allowed} || 0)
            && defined($candidate->{reset_value}) && length($candidate->{reset_value})
            && defined($clock_name) && length($clock_name)
            && defined($reset_name) && length($reset_name)
                ? (%planned_reexports
                    ? 'registered_shared_reexport'
                    : 'registered_shared_internal')
            : (($candidate->{storage_class} || '') eq 'registered')
                && !($candidate->{peer_input_count} || 0)
                && scalar(keys %preserved_top_outputs) > 1
                && defined($candidate->{reset_value}) && length($candidate->{reset_value})
                && defined($clock_name) && length($clock_name)
                && defined($reset_name) && length($reset_name)
                    ? 'registered_shared_public_fanout'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && (($candidate->{peer_read_policy} || '') eq 'top_output_only')
                && %preserved_top_outputs
                    ? 'combinational_shared_reexport'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && !($candidate->{peer_input_count} || 0)
                && scalar(keys %preserved_top_outputs) > 1
                    ? 'combinational_shared_public_fanout'
            : (($candidate->{storage_class} || '') eq 'combinational')
                && (($candidate->{peer_read_policy} || '') eq 'top_local_only')
                    ? 'combinational_shared_internal'
                    : ''
                ;
        my $can_lift_runtime = length($runtime_mode) ? 1 : 0;

        next unless $can_lift_runtime;

        my $signal_name = $candidate->{signal_name} || next;
        my $width = $candidate->{width} || 1;
        my $lifted_next_signal = $self->shared_datapath_lifted_next_name($signal_name);
        my $lifted_register_signal = $self->shared_datapath_lifted_register_name($signal_name);
        my $lifted_comb_signal = $self->shared_datapath_lifted_comb_name($signal_name);
        my $width_decl = $width > 1 ? sprintf("[%d:0] ", $width - 1) : '';

        $candidate->{lifted_runtime_kind} = $runtime_mode;
        my @runtime_lines;
        if ($runtime_mode eq 'combinational_shared_reexport'
            || $runtime_mode eq 'combinational_shared_internal'
            || $runtime_mode eq 'combinational_shared_public_fanout')
        {
            $candidate->{lifted_runtime_signal} = $lifted_comb_signal;
            @runtime_lines = (
                "    logic ${width_decl}${lifted_comb_signal};",
                "",
                "    always_comb begin",
                "      ${lifted_comb_signal} = 1'b0;",
            );

            for my $family (@{$candidate->{aggregate_enable_families} || []}) {
                next unless ref($family) eq 'HASH';
                my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
                my $rhs_value = $family->{rhs_value} // next;
                push @runtime_lines,
                    "      if ($aggregate_enable_signal) begin",
                    "        ${lifted_comb_signal} = $rhs_value;",
                    "      end";
            }

            push @runtime_lines, "    end";
        } else {
            $candidate->{lifted_runtime_next_signal} = $lifted_next_signal;
            $candidate->{lifted_runtime_signal} = $lifted_register_signal;
            $candidate->{lifted_runtime_reset_value} = $candidate->{reset_value};

            @runtime_lines = (
                "    logic ${width_decl}${lifted_next_signal};",
                "    logic ${width_decl}${lifted_register_signal};",
                "",
                "    always_comb begin",
                "      ${lifted_next_signal} = ${lifted_register_signal};",
            );

            for my $family (@{$candidate->{aggregate_enable_families} || []}) {
                next unless ref($family) eq 'HASH';
                my $aggregate_enable_signal = $family->{aggregate_enable_signal} || next;
                my $rhs_value = $family->{rhs_value} // next;
                push @runtime_lines,
                    "      if ($aggregate_enable_signal) begin",
                    "        ${lifted_next_signal} = $rhs_value;",
                    "      end";
            }

            push @runtime_lines,
                "    end",
                "",
                "    always_ff @(posedge $clock_name or negedge $reset_name) begin",
                "      if (!$reset_name) begin",
                "        ${lifted_register_signal} <= $candidate->{reset_value};",
                "      end else begin",
                "        ${lifted_register_signal} <= ${lifted_next_signal};",
                "      end",
                "    end";
        }

        for my $contributor (@{$candidate->{contributors} || []}) {
            next unless ref($contributor) eq 'HASH';
            my ($instance_name, $port_name) = ($contributor->{endpoint} || '') =~ /^(\w+)\.(\w+)$/;
            next unless defined($instance_name) && defined($port_name);
            my $instance = $instances_by_name{$instance_name} || next;
            my $raw_signal = $self->shared_datapath_raw_source_name($instance_name, $signal_name);
            $self->ensure_composition_net($nets, $raw_signal, $width);
            $self->set_instance_port_binding($instance, $port_name, $raw_signal);
        }

        for my $peer_input (@{$candidate->{peer_input_endpoints} || []}) {
            next unless ref($peer_input) eq 'HASH';
            my ($instance_name, $port_name) = ($peer_input->{endpoint} || '') =~ /^(\w+)\.(\w+)$/;
            next unless defined($instance_name) && defined($port_name);
            my $instance = $instances_by_name{$instance_name} || next;
            my $lifted_signal = ($runtime_mode eq 'combinational_shared_reexport'
                || $runtime_mode eq 'combinational_shared_internal'
                || $runtime_mode eq 'combinational_shared_public_fanout')
                ? $lifted_comb_signal
                : $lifted_register_signal;
            $self->set_instance_port_binding($instance, $port_name, $lifted_signal);
        }

        if ($runtime_mode eq 'registered_shared_reexport') {
            for my $top_output_signal (sort keys %planned_reexports) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_register_signal;";
            }
        }

        if ($runtime_mode eq 'registered_shared_public_fanout') {
            for my $top_output_signal (sort keys %preserved_top_outputs) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_register_signal;";
            }
        }

        if ($runtime_mode eq 'combinational_shared_reexport'
            || $runtime_mode eq 'combinational_shared_public_fanout')
        {
            for my $top_output_signal (sort keys %preserved_top_outputs) {
                push @runtime_lines, "    assign $top_output_signal = $lifted_comb_signal;";
            }
        }

        push @lifted_runtime_sections, @runtime_lines;
    }

    my @auxiliary_lines;
    push @auxiliary_lines, @helper_assignments if @helper_assignments;
    if (@assertion_sections) {
        push @auxiliary_lines, "" if @auxiliary_lines;
        push @auxiliary_lines, @assertion_sections;
    }
    if (@lifted_runtime_sections) {
        push @auxiliary_lines, "" if @auxiliary_lines;
        push @auxiliary_lines, @lifted_runtime_sections;
    }

    $composition_plan->{auxiliary_assignments} = \@auxiliary_lines;
    $composition_plan->{shared_datapath_candidates} = $shared_datapath_candidates;
    return $composition_plan;
}

sub resolve_composition_endpoint ($self, $endpoint, $top_ports_by_name, $instances_by_name, $child_ports_by_instance, $fsm_file, $header) {
    if ($endpoint =~ /^(\w+)\.(\w+)$/) {
        my ($instance_name, $port_name) = ($1, $2);
        my $instance = $instances_by_name->{$instance_name};
        Carp::confess
            "Composition source '$header' in '$fsm_file' references child endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because no realized child instance named '$instance_name' exists. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $instance;

        my $port = $child_ports_by_instance->{$instance_name}{$port_name};
        Carp::confess
            "Composition source '$header' in '$fsm_file' references child endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because instance '$instance_name' has no port named '$port_name'. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        return {
            raw => $endpoint,
            key => "child:$instance_name.$port_name",
            kind => 'child_port',
            instance_name => $instance_name,
            instance => $instance,
            port_name => $port_name,
            port => $port,
        };
    }

    if ($endpoint =~ /^(\w+)$/) {
        my $port_name = $1;
        my $port = $top_ports_by_name->{$port_name};
        Carp::confess
            "Composition source '$header' in '$fsm_file' references top-level endpoint '$endpoint', ".
            "but explicit link endpoint resolution is blocked because '?ports' declares no top port with that name. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $port;

        return {
            raw => $endpoint,
            key => "top:$port_name",
            kind => 'top_port',
            port_name => $port_name,
            port => $port,
        };
    }

    Carp::confess
        "Composition source '$header' in '$fsm_file' uses explicit endpoint '$endpoint', ".
        "but explicit link endpoint resolution is blocked because that syntax is unsupported. ".
        "The current active composition lanes accept only top-port names or 'instance.port' child endpoints. ".
        "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n";
}

sub assert_explicit_link_roles ($self, $source, $target, $fsm_file, $header) {
    if ($source->{kind} eq 'top_port') {
        Carp::confess
            "Composition source '$header' in '$fsm_file' uses top port '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because that top port is declared as ".$source->{port}->direction." instead of input. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->direction eq 'input';
    } else {
        Carp::confess
            "Composition source '$header' in '$fsm_file' uses child endpoint '".$source->{raw}."' as an explicit link source, ".
            "but explicit link is blocked because that child port is ".$source->{port}->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $source->{port}->direction eq 'output';
    }

    if ($target->{kind} eq 'top_port') {
        Carp::confess
            "Composition source '$header' in '$fsm_file' uses top port '".$target->{raw}."' as an explicit link target, ".
            "but explicit link is blocked because that top port is declared as ".$target->{port}->direction." instead of output. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{port}->direction eq 'output';
    } else {
        Carp::confess
            "Composition source '$header' in '$fsm_file' uses child endpoint '".$target->{raw}."' as an explicit link target, ".
            "but explicit link is blocked because that child port is ".$target->{port}->direction." instead of input. ".
            "See docs/COMPOSITION_SCOPE.md and docs/COMPOSITION_LEGACY_MAPPING.md.\n"
            unless $target->{port}->direction eq 'input';
    }
}

sub allocate_composition_net_name ($self, $source, $top_ports_by_name, $existing_nets, $preferred_name = undef) {
    my $base_name = $preferred_name // ("comp_link_" . $source->{instance_name} . "_" . $source->{port_name});
    $base_name =~ s/\W+/_/g;
    my %reserved = map { $_ => 1 } keys %{$top_ports_by_name || {}};
    $reserved{$_->name} = 1 for @{$existing_nets || []};

    my $candidate = $base_name;
    my $suffix = 0;
    while ($reserved{$candidate}) {
        $suffix++;
        $candidate = $base_name . "_" . $suffix;
    }

    return $candidate;
}

sub generate_composition_hdl_code ($self, $composition_plan, $structural_rtl_ir = undef) {
    my @segments = map { $_->hdl_code } @{$composition_plan->instances};
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    push @segments, $self->emit_composition_top_module($structural_rtl_ir);
    return join("\n\n", grep { defined && length } @segments) . "\n";
}

sub emit_composition_top_module ($self, $structural_rtl_ir) {
    my $structural = blessed($structural_rtl_ir) && $structural_rtl_ir->can('as_hashref')
        ? $structural_rtl_ir->as_hashref
        : $structural_rtl_ir;

    my $top_name = $structural->{module_name};
    my @ports = @{$structural->{ports} || []};
    my @nets = @{$structural->{nets} || []};
    my @instances = @{$structural->{instances} || []};
    my @auxiliary_assignments = @{$structural->{auxiliary_assignments} || []};

    my @port_lines = map {
        my $width = ($_->{width} || 1) > 1 ? sprintf("[%d:0] ", $_->{width} - 1) : '';
        sprintf("    %s %s%s", $_->{direction}, $width, $_->{name});
    } @ports;

    my @net_lines = map {
        my $width = ($_->{width} || 1) > 1 ? sprintf("[%d:0] ", $_->{width} - 1) : '';
        sprintf("    wire %s%s;", $width, $_->{name})
    } @nets;

    my @instance_blocks = map {
        my $instance = $_;
        my @connection_lines = map {
            sprintf("        .%s(%s)", $_->{port_name}, $_->{signal_name})
        } @{$instance->{port_bindings} || []};

        join("\n",
            "    ".$instance->{module_name}." ".$instance->{instance_name}." (",
            join(",\n", @connection_lines),
            "    );",
        );
    } @instances;

    my @body_lines = (
        "module $top_name (",
        join(",\n", @port_lines),
        ");",
    );

    push @body_lines, "", @net_lines if @net_lines;
    push @body_lines, "", @auxiliary_assignments if @auxiliary_assignments;
    push @body_lines, "", join("\n\n", @instance_blocks), "" if @instance_blocks;
    push @body_lines, "endmodule";

    return join("\n", @body_lines);
}

sub build_composition_structural_rtl_ir ($self, $composition_plan) {
    return FSM::IR::StructuralRTLIR->new(
        module_name => ($composition_plan->top_name // ''),
        source_root_kind => 'top',
        target_language => ($self->{target_language} // 'systemverilog'),
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
                        map {
                            +{
                                port_name => $_->{port_name},
                                signal_name => $_->{signal_name},
                            }
                        } @{$_->port_bindings || []}
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

sub build_composition_port_metadata ($self, $composition_plan, $structural_rtl_ir = undef) {
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my (@inputs, @outputs, @multi_bit, @single_bit);
    my %signals;
    my @signal_names;

    for my $port (@{$structural_rtl_ir_hash->{ports} || []}) {
        my $entry = {
            name => $port->{name},
            width => $port->{width},
            direction => $port->{direction},
        };

        push @signal_names, $port->{name};

        if (($port->{direction} || '') eq 'output') {
            push @outputs, $entry;
        } else {
            push @inputs, $entry;
        }

        if (($port->{width} || 0) > 1) {
            push @multi_bit, $entry;
        } else {
            push @single_bit, $entry;
        }

        $signals{$port->{name}} = {
            width => $port->{width},
            direction => $port->{direction},
        };
    }

    return {
        signals => \%signals,
        signal_names => \@signal_names,
        signal_analysis => {
            inputs => \@inputs,
            outputs => \@outputs,
            multi_bit => \@multi_bit,
            single_bit => \@single_bit,
        },
    };
}

sub build_composition_intent_hir (
    $self,
    $composition_plan,
    $composition_child_exports = undef,
    $generated_child_exports = undef,
    $standalone_dt_child_exports = undef,
    $structural_rtl_ir = undef,
) {
    $composition_child_exports //= $self->build_composition_child_exports($composition_plan);
    $generated_child_exports //= $self->build_composition_generated_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    $standalone_dt_child_exports //= $self->build_composition_standalone_dt_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $port_metadata = $self->build_composition_port_metadata($composition_plan, $structural_rtl_ir);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};

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

sub build_composition_lowered_rtl_ir ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $shared_datapath_candidates = $self->composition_shared_datapath_candidates_for_plan(
        $composition_plan,
        $structural_rtl_ir,
        $intent_hir,
    );
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
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
        target_language => ($self->{target_language} // 'systemverilog'),
        output_drive_families => [],
        standalone_dt_multi_drive_targets => [],
        composition_shared_datapath_candidates => $shared_datapath_candidates,
        internal_net_names => $internal_net_names,
        instance_names => $instance_names,
        auxiliary_assignment_count => scalar(@{$structural_rtl_ir_hash->{auxiliary_assignments} || []}),
    );
}

sub build_composition_module_info (
    $self,
    $composition_plan,
    $composition_report = undef,
    $composition_child_exports = undef,
    $generated_child_exports = undef,
    $intent_hir = undef,
    $lowered_rtl_ir = undef,
    $structural_rtl_ir = undef,
) {
    $composition_child_exports //= $self->build_composition_child_exports($composition_plan);
    $generated_child_exports //= $self->build_composition_generated_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    my $standalone_dt_child_exports = $self->build_composition_standalone_dt_child_exports(
        $composition_plan,
        $composition_child_exports,
    );
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    $intent_hir //= $self->build_composition_intent_hir(
        $composition_plan,
        $composition_child_exports,
        $generated_child_exports,
        $standalone_dt_child_exports,
        $structural_rtl_ir,
    );
    $lowered_rtl_ir //= $self->build_composition_lowered_rtl_ir($composition_plan, $structural_rtl_ir, $intent_hir);
    my $port_metadata = $self->build_composition_port_metadata($composition_plan, $structural_rtl_ir);
    my $intent_hir_hash = $intent_hir->as_hashref;
    my $lowered_rtl_ir_hash = $lowered_rtl_ir->as_hashref;
    my $structural_rtl_ir_hash = $structural_rtl_ir->as_hashref;

    return {
        module_name => $intent_hir_hash->{module_name},
        source_root_kind => $intent_hir_hash->{source_root_kind},
        regular_states => [],
        regular_state_count => $intent_hir_hash->{regular_state_count},
        regular_state_names => $intent_hir_hash->{regular_state_names},
        standalone_dts => [],
        standalone_dt_count => $intent_hir_hash->{standalone_dt_count},
        standalone_dt_names => $intent_hir_hash->{standalone_dt_names},
        signals => $port_metadata->{signals},
        signal_count => $intent_hir_hash->{signal_count},
        signal_names => $intent_hir_hash->{signal_names},
        signal_analysis => $intent_hir_hash->{signal_analysis},
        explicit_system_contract => $intent_hir_hash->{explicit_system_contract},
        system_contract => $intent_hir_hash->{system_contract},
        requires_implicit_system_ports => $intent_hir_hash->{requires_implicit_system_ports},
        parameter_count => $intent_hir_hash->{parameter_count},
        parameter_names => $intent_hir_hash->{parameter_names},
        intent_hir => $intent_hir_hash,
        lowered_rtl_ir => $lowered_rtl_ir_hash,
        structural_rtl_ir => $structural_rtl_ir_hash,
        output_drive_family_count => $lowered_rtl_ir_hash->{output_drive_family_count},
        output_drive_families => $lowered_rtl_ir_hash->{output_drive_families},
        standalone_dt_multi_drive_target_count => $lowered_rtl_ir_hash->{standalone_dt_multi_drive_target_count},
        standalone_dt_multi_drive_targets => $lowered_rtl_ir_hash->{standalone_dt_multi_drive_targets},
        internal_net_count => (
            exists $lowered_rtl_ir_hash->{internal_net_count}
                ? $lowered_rtl_ir_hash->{internal_net_count}
                : scalar(@{$composition_plan->nets || []})
        ),
        internal_net_names => (
            $lowered_rtl_ir_hash->{internal_net_names}
                || [ map { $_->name } @{$composition_plan->nets || []} ]
        ),
        instance_count => (
            exists $lowered_rtl_ir_hash->{instance_count}
                ? $lowered_rtl_ir_hash->{instance_count}
                : scalar(@{$composition_plan->instances || []})
        ),
        instance_names => (
            $lowered_rtl_ir_hash->{instance_names}
                || [ map { $_->instance_name } @{$composition_plan->instances || []} ]
        ),
        auxiliary_assignment_count => (
            exists $lowered_rtl_ir_hash->{auxiliary_assignment_count}
                ? $lowered_rtl_ir_hash->{auxiliary_assignment_count}
                : scalar(@{$composition_plan->auxiliary_assignments || []})
        ),
        state_count => $intent_hir_hash->{state_count},
        composition_child_count => (
            exists $intent_hir_hash->{composition_child_count}
                ? $intent_hir_hash->{composition_child_count}
                : (
                    exists $structural_rtl_ir_hash->{instance_count}
                        ? $structural_rtl_ir_hash->{instance_count}
                        : scalar(@{$composition_plan->instances})
                )
        ),
        composition_children => (
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
        composition_generated_children => (
            $intent_hir_hash->{composition_generated_children} || []
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
        composition_standalone_dt_children => (
            $intent_hir_hash->{composition_standalone_dt_children}
                || $standalone_dt_child_exports->{children}
        ),
        composition_shared_datapath_candidate_count => (
            exists $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
                ? $lowered_rtl_ir_hash->{composition_shared_datapath_candidate_count}
                : 0
        ),
        composition_shared_datapath_candidates => (
            $lowered_rtl_ir_hash->{composition_shared_datapath_candidates} || []
        ),
        composition_lane => $composition_plan->lane,
        composition_provenance => $composition_report,
    };
}

sub build_composition_child_exports ($self, $composition_plan, $structural_rtl_ir = undef) {
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my %instances_by_name = map {
        (($_->instance_name // '') => $_)
    } @{$composition_plan->instances || []};
    my @children;

    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        my $planned_instance = $instances_by_name{$instance->{instance_name} // ''};
        my $child_info = $planned_instance ? ($planned_instance->module_info || {}) : {};
        my $intent_hir = $self->module_intent_hir($child_info);
        my $lowered_rtl_ir = $self->module_lowered_rtl_ir($child_info);
        my $child_structural_rtl_ir = $self->module_structural_rtl_ir($child_info);
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

sub build_composition_generated_child_exports ($self, $composition_plan, $composition_child_exports = undef) {
    $composition_child_exports //= $self->build_composition_child_exports($composition_plan);
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
            intent_hir => _clone_structured_value($child->{intent_hir} || {}),
            lowered_rtl_ir => _clone_structured_value($child->{lowered_rtl_ir} || {}),
            structural_rtl_ir => _clone_structured_value($child->{structural_rtl_ir} || {}),
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

sub build_composition_standalone_dt_child_exports ($self, $composition_plan, $composition_child_exports = undef) {
    $composition_child_exports //= $self->build_composition_child_exports($composition_plan);
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
        } @{$lowered_rtl_ir->{standalone_dt_multi_drive_targets} || []};

        my $standalone_dt_count = $child->{standalone_dt_count} || 0;
        my $child_multi_drive_target_count = $child->{standalone_dt_multi_drive_target_count} || 0;

        push @children, {
            instance_name => $child->{instance_name},
            module_name => $child->{module_name},
            source_name => $child->{source_name},
            intent_hir => _clone_structured_value($intent_hir),
            lowered_rtl_ir => _clone_structured_value($lowered_rtl_ir),
            structural_rtl_ir => _clone_structured_value($child->{structural_rtl_ir} || {}),
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

sub build_composition_shared_datapath_candidates ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my %top_output_by_name = map {
        ((($_->{name}) || '') => $_)
    } grep {
        ((($_->{direction}) || '') eq 'output')
    } @{$structural_rtl_ir_hash->{ports} || []};
    my %child_by_instance = map {
        ((($_->{instance_name}) || '') => $_)
    } @{$self->composition_child_exports_for_context($composition_plan, $intent_hir)};

    my %candidate_groups;
    my %peer_input_groups;
    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        next unless (($instance->{kind} || '') eq 'fsmc');

        my %bindings = map {
            (($_->{port_name} || '') => ($_->{signal_name} || ''))
        } @{$instance->{port_bindings} || []};
        my $child = $child_by_instance{$instance->{instance_name}} || {};
        my %drive_family_by_signal = map {
            (($_->{signal_name} || '') => $_)
        } @{$child->{lowered_rtl_ir}{output_drive_families} || []};

        for my $port (@{$instance->{interface_ports} || []}) {
            next unless (($port->{direction} || '') eq 'output');

            my $normalized_type = $self->normalized_interface_type($port->{type});
            my $key = join "\x1E",
                ($port->{name} // ''),
                ($port->{width} // 1),
                $normalized_type;

            my $drive_family = $drive_family_by_signal{$port->{name}} || {};
            my $output_drive_family = ref($drive_family) eq 'HASH'
                ? _clone_structured_value($drive_family)
                : {};
            push @{$candidate_groups{$key}{contributors}}, {
                kind => ($child->{kind} // $instance->{kind}),
                instance_name => ($child->{instance_name} // $instance->{instance_name}),
                module_name => ($child->{module_name} // $instance->{module_name}),
                source_name => ($child->{source_name} // $instance->{source_name}),
                endpoint => (($instance->{instance_name} // 'unknown').'.'.($port->{name} // 'unknown')),
                bound_signal => $bindings{$port->{name}},
                intent_hir => ($child->{intent_hir} || {}),
                lowered_rtl_ir => ($child->{lowered_rtl_ir} || {}),
                structural_rtl_ir => ($child->{structural_rtl_ir} || {}),
                output_drive_family => $output_drive_family,
                drive_intent => $self->shared_datapath_drive_intent_from_output_drive_family($output_drive_family),
            };
            $candidate_groups{$key}{signal_name} = $port->{name};
            $candidate_groups{$key}{width} = $port->{width} || 1;
            $candidate_groups{$key}{interface_type} = $normalized_type;
        }

        for my $port (@{$instance->{interface_ports} || []}) {
            next unless (($port->{direction} || '') eq 'input');

            my $normalized_type = $self->normalized_interface_type($port->{type});
            my $key = join "\x1E",
                ($port->{name} // ''),
                ($port->{width} // 1),
                $normalized_type;

            push @{$peer_input_groups{$key}}, {
                instance_name => ($child->{instance_name} // $instance->{instance_name}),
                module_name => ($child->{module_name} // $instance->{module_name}),
                endpoint => (($instance->{instance_name} // 'unknown').'.'.($port->{name} // 'unknown')),
                bound_signal => $bindings{$port->{name}},
            };
        }
    }

    my @candidates;
    for my $key (sort keys %candidate_groups) {
        my $group = $candidate_groups{$key};
        my @contributors = sort {
            ($a->{instance_name} // '') cmp ($b->{instance_name} // '')
                ||
            ($a->{module_name} // '') cmp ($b->{module_name} // '')
                ||
            ($a->{endpoint} // '') cmp ($b->{endpoint} // '')
        } @{$group->{contributors} || []};
        next unless @contributors >= 2;

        my %top_output_signals;
        for my $contributor (@contributors) {
            my $bound_signal = $contributor->{bound_signal} || '';
            next unless length $bound_signal;
            $top_output_signals{$bound_signal} = 1 if exists $top_output_by_name{$bound_signal};
        }

        my %candidate_carriers = map {
            my $bound_signal = $_->{bound_signal} || '';
            length($bound_signal) ? ($bound_signal => 1) : ();
        } @contributors;

        my @peer_input_endpoints = sort {
            ($a->{instance_name} // '') cmp ($b->{instance_name} // '')
                ||
            ($a->{module_name} // '') cmp ($b->{module_name} // '')
                ||
            ($a->{endpoint} // '') cmp ($b->{endpoint} // '')
        } grep {
            my $bound_signal = $_->{bound_signal} || '';
            length($bound_signal) && $candidate_carriers{$bound_signal}
        } @{$peer_input_groups{$key} || []};
        my $storage_class = $self->shared_datapath_storage_class(\@contributors);
        my %reset_values = map {
            my $output_drive_family = $self->shared_datapath_contributor_output_drive_family($_);
            my $reset_value = $output_drive_family->{reset_value};
            defined($reset_value) && length($reset_value)
                ? ($reset_value => 1)
                : ();
        } @contributors;
        my $reset_value = keys(%reset_values) == 1
            ? (sort keys %reset_values)[0]
            : undef;
        my $default_lifted_visibility = (@peer_input_endpoints && $storage_class eq 'registered')
            ? 'internal'
            : (@peer_input_endpoints && $storage_class eq 'combinational' && !keys(%top_output_signals))
                ? 'top_local'
                : 'top_output';
        my @planned_reexport_top_output_signals = $default_lifted_visibility eq 'internal'
            ? sort keys %top_output_signals
            : ();
        my $peer_read_policy = $self->shared_datapath_peer_read_policy(
            $storage_class,
            \@peer_input_endpoints,
            [sort keys %top_output_signals],
        );

        my %aggregate_families_by_rhs;
        for my $contributor (@contributors) {
            my $output_drive_family = $self->shared_datapath_contributor_output_drive_family($contributor);
            for my $rhs_family (@{$output_drive_family->{rhs_enable_families} || []}) {
                next unless ref($rhs_family) eq 'HASH';
                my $rhs_value = $rhs_family->{rhs_value};
                next unless defined $rhs_value;

                my $aggregate = ($aggregate_families_by_rhs{$rhs_value} ||= {
                    rhs_value => $rhs_value,
                    aggregate_enable_signal => $self->shared_datapath_value_enable_name($group->{signal_name}, $rhs_value),
                    contributors => [],
                });

                push @{$aggregate->{contributors}}, {
                    endpoint => $contributor->{endpoint},
                    family_enable_signal => $rhs_family->{family_enable_signal},
                    source_enable_signal => $self->shared_datapath_source_value_enable_name(
                        $contributor->{instance_name},
                        $group->{signal_name},
                        $rhs_value,
                    ),
                    driver_blocks => [@{$rhs_family->{driver_blocks} || []}],
                    driver_enable_signals => [@{$rhs_family->{driver_enable_signals} || []}],
                };
            }
        }

        my @aggregate_enable_families = map {
            my $family = $aggregate_families_by_rhs{$_};
            my $same_value_conflict_signal = $self->shared_datapath_same_value_conflict_name(
                $group->{signal_name},
                $family->{rhs_value},
            );
            +{
                rhs_value => $family->{rhs_value},
                aggregate_enable_signal => $family->{aggregate_enable_signal},
                same_value_conflict_signal => $same_value_conflict_signal,
                same_value_assertion => $self->shared_datapath_assertion_metadata(
                    $same_value_conflict_signal,
                    [
                        map {
                            $_->{source_enable_signal}
                        } @{$family->{contributors} || []}
                    ],
                ),
                contributor_count => scalar(@{$family->{contributors} || []}),
                contributors => $family->{contributors},
            }
        } sort keys %aggregate_families_by_rhs;

        my $multi_value_conflict_signal = $self->shared_datapath_multi_value_conflict_name($group->{signal_name});

        push @candidates, {
            signal_name => $group->{signal_name},
            width => $group->{width},
            interface_type => $group->{interface_type},
            storage_class => $storage_class,
            reset_value => $reset_value,
            contributor_count => scalar(@contributors),
            contributors => \@contributors,
            top_output_signals => [ sort keys %top_output_signals ],
            peer_input_count => scalar(@peer_input_endpoints),
            peer_input_endpoints => \@peer_input_endpoints,
            default_lifted_visibility => $default_lifted_visibility,
            planned_reexport_top_output_signals => \@planned_reexport_top_output_signals,
            loopback_allowed => (@peer_input_endpoints && $storage_class eq 'registered') ? 1 : 0,
            (%{$peer_read_policy || {}}),
            aggregate_target_enable_signal => $self->shared_datapath_target_enable_name($group->{signal_name}),
            multi_value_conflict_signal => $multi_value_conflict_signal,
            multi_value_assertion => $self->shared_datapath_assertion_metadata(
                $multi_value_conflict_signal,
                [
                    map {
                        $_->{aggregate_enable_signal}
                    } @aggregate_enable_families
                ],
            ),
            aggregate_enable_family_count => scalar(@aggregate_enable_families),
            aggregate_enable_families => \@aggregate_enable_families,
        };
    }

    return \@candidates;
}

sub build_composition_statistics ($self, $composition_plan, $composition_report = undef, $lowered_rtl_ir = undef, $structural_rtl_ir = undef) {
    my $stats = $self->gather_statistics(undef);
    my $lowered_rtl_ir_hash = ref($lowered_rtl_ir) ? $lowered_rtl_ir->as_hashref : {};
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    $stats->{composition_child_count} = exists $structural_rtl_ir_hash->{instance_count}
        ? $structural_rtl_ir_hash->{instance_count}
        : scalar(@{$composition_plan->instances});
    $stats->{composition_top_port_count} = exists $structural_rtl_ir_hash->{port_count}
        ? $structural_rtl_ir_hash->{port_count}
        : scalar(@{$composition_plan->ports});
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
            : scalar(@{$self->composition_shared_datapath_candidates_for_plan($composition_plan) || []})
    );
    $stats->{composition_lane} = $composition_plan->lane;
    $stats->{composition_provenance} = $composition_report if $composition_report;
    return $stats;
}

sub build_composition_provenance_report ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};

    my @ports = map {
        my $origin_kind = $_->{origin_kind} || 'unknown_port_origin';
        +{
            name => $_->{name},
            direction => $_->{direction},
            width => $_->{width},
            type => $_->{type},
            origin_kind => $origin_kind,
            origin_category => $self->composition_provenance_category($origin_kind),
            origin_label => $self->composition_provenance_label($origin_kind),
        }
    } @{$structural_rtl_ir_hash->{ports} || []};

    my @resolved_links = map {
        my $origin_kind = $_->{origin_kind} || 'unknown_link_origin';
        my $source_context = $self->composition_provenance_endpoint_context($composition_plan, $_->{source}, $structural_rtl_ir, $intent_hir);
        my $target_context = $self->composition_provenance_endpoint_context($composition_plan, $_->{target}, $structural_rtl_ir, $intent_hir);
        +{
            source => $_->{source},
            target => $_->{target},
            origin_kind => $origin_kind,
            origin_category => $self->composition_provenance_category($origin_kind),
            origin_label => $self->composition_provenance_label($origin_kind),
            source_context => $source_context,
            target_context => $target_context,
        }
    } @{$structural_rtl_ir_hash->{resolved_links} || []};

    my %port_origin_counts;
    my %port_category_counts;
    my %port_origin_examples;
    for my $entry (@ports) {
        $port_origin_counts{$entry->{origin_kind}}++;
        $port_category_counts{$entry->{origin_category}}++;
        $port_origin_examples{$entry->{origin_kind}} //= $self->composition_port_example_summary($entry);
    }

    my %resolved_link_origin_counts;
    my %resolved_link_category_counts;
    my %resolved_link_origin_examples;
    for my $entry (@resolved_links) {
        $resolved_link_origin_counts{$entry->{origin_kind}}++;
        $resolved_link_category_counts{$entry->{origin_category}}++;
        $resolved_link_origin_examples{$entry->{origin_kind}} //= $self->composition_link_example_summary($entry);
    }

    my @override_events = @{$self->build_composition_override_events($composition_plan, $structural_rtl_ir, $intent_hir)};
    my %override_kind_counts;
    my %override_kind_examples;
    for my $event (@override_events) {
        $override_kind_counts{$event->{kind}}++;
        $override_kind_examples{$event->{kind}} //= $self->composition_override_example_summary($event);
    }

    my @block_events = @{$self->build_composition_block_events($composition_plan, $structural_rtl_ir, $intent_hir)};
    my %block_kind_counts;
    my %block_kind_examples;
    for my $event (@block_events) {
        $block_kind_counts{$event->{kind}}++;
        $block_kind_examples{$event->{kind}} //= $self->composition_block_example_summary($event);
    }

    return {
        lane => $composition_plan->lane,
        top_port_count => scalar(@ports),
        resolved_link_count => scalar(@resolved_links),
        override_count => scalar(@override_events),
        block_count => scalar(@block_events),
        ports => \@ports,
        resolved_links => \@resolved_links,
        override_events => \@override_events,
        block_events => \@block_events,
        port_origin_counts => \%port_origin_counts,
        port_category_counts => \%port_category_counts,
        port_origin_examples => \%port_origin_examples,
        resolved_link_origin_counts => \%resolved_link_origin_counts,
        resolved_link_category_counts => \%resolved_link_category_counts,
        resolved_link_origin_examples => \%resolved_link_origin_examples,
        override_kind_counts => \%override_kind_counts,
        block_kind_counts => \%block_kind_counts,
        override_kind_examples => \%override_kind_examples,
        block_kind_examples => \%block_kind_examples,
        ordered_port_origins => [
            sort {
                $self->composition_provenance_sort_key($a) <=> $self->composition_provenance_sort_key($b)
                ||
                $self->composition_provenance_label($a) cmp $self->composition_provenance_label($b)
            } keys %port_origin_counts
        ],
        ordered_resolved_link_origins => [
            sort {
                $self->composition_provenance_sort_key($a) <=> $self->composition_provenance_sort_key($b)
                ||
                $self->composition_provenance_label($a) cmp $self->composition_provenance_label($b)
            } keys %resolved_link_origin_counts
        ],
        ordered_override_kinds => [
            sort { $self->composition_override_label($a) cmp $self->composition_override_label($b) }
            keys %override_kind_counts
        ],
        ordered_block_kinds => [
            sort { $self->composition_block_label($a) cmp $self->composition_block_label($b) }
            keys %block_kind_counts
        ],
    };
}

sub composition_child_exports_for_context ($self, $composition_plan, $intent_hir = undef) {
    my $intent_hir_hash = ref($intent_hir) eq 'HASH'
        ? $intent_hir
        : (ref($intent_hir) && $intent_hir->can('as_hashref')
            ? $intent_hir->as_hashref
            : {});

    if (ref($intent_hir_hash->{composition_children}) eq 'ARRAY') {
        return _clone_structured_value($intent_hir_hash->{composition_children});
    }

    return $self->build_composition_child_exports($composition_plan)->{children} || [];
}

sub composition_provenance_endpoint_context ($self, $composition_plan, $endpoint, $structural_rtl_ir = undef, $intent_hir = undef) {
    return undef unless defined $endpoint && length $endpoint;

    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my %top_port_by_name = map {
        ((($_->{name}) || '') => $_)
    } @{$structural_rtl_ir_hash->{ports} || []};
    my %child_by_instance = map {
        ((($_->{instance_name}) || '') => $_)
    } @{$self->composition_child_exports_for_context($composition_plan, $intent_hir)};

    if (my $top_port = $top_port_by_name{$endpoint}) {
        return {
            kind => 'top_port',
            name => $top_port->{name},
            endpoint => $top_port->{name},
            direction => $top_port->{direction},
            width => $top_port->{width},
            type => $top_port->{type},
        };
    }

    my ($instance_name, $port_name) = $endpoint =~ /^(\w+)\.(\w+)$/;
    return {
        kind => 'raw_endpoint',
        endpoint => $endpoint,
    } unless defined $port_name;

    my ($structural_instance) = grep {
        ((($_->{instance_name}) || '') eq $instance_name)
    } @{$structural_rtl_ir_hash->{instances} || []};
    my $child = $child_by_instance{$instance_name};

    return {
        kind => 'raw_endpoint',
        endpoint => $endpoint,
    } unless $child || $structural_instance;

    my ($port) = grep {
        ((($_->{name}) || '') eq $port_name)
    } @{($structural_instance || {})->{interface_ports} || []};

    my $instance_kind = $child->{kind}
        // $structural_instance->{kind}
        // '';
    my $source_root_kind = $child->{source_root_kind}
        // ($instance_kind eq 'dtc' ? 'dt'
            : ($instance_kind eq 'fsmc' ? 'fsm'
                : ($instance_kind eq 'rtl' ? 'rtl' : 'unknown_root')));

    return {
        kind => 'child_endpoint',
        endpoint => $endpoint,
        instance_name => ($child->{instance_name} // $structural_instance->{instance_name} // $instance_name),
        instance_kind => $instance_kind,
        module_name => ($child->{module_name} // $structural_instance->{module_name}),
        source_name => ($child->{source_name} // $structural_instance->{source_name}),
        port_name => $port_name,
        direction => $port ? $port->{direction} : undef,
        width => $port ? $port->{width} : undef,
        type => $port ? $port->{type} : undef,
        source_root_kind => $source_root_kind,
        regular_state_count => ($child->{regular_state_count} || 0),
        standalone_dt_count => ($child->{standalone_dt_count} || 0),
        output_drive_family_count => ($child->{output_drive_family_count} || 0),
        intent_hir => ($child->{intent_hir} || {}),
        lowered_rtl_ir => ($child->{lowered_rtl_ir} || {}),
        structural_rtl_ir => ($child->{structural_rtl_ir} || {}),
    };
}

sub composition_provenance_endpoint_example_label ($self, $context, $fallback = undef) {
    return $fallback // '' unless ref($context) eq 'HASH';

    if (($context->{kind} || '') eq 'top_port') {
        return $context->{name} || $context->{endpoint} || ($fallback // '');
    }

    if (($context->{kind} || '') eq 'child_endpoint') {
        my $root_kind = $context->{source_root_kind} || 'unknown_root';
        my @details = ('?' . $root_kind);

        if ($root_kind eq 'fsm') {
            push @details, 'states: ' . ($context->{regular_state_count} || 0);
        } elsif ($root_kind eq 'dt') {
            push @details, 'blocks: ' . ($context->{standalone_dt_count} || 0);
        }

        if ($root_kind eq 'fsm' || $root_kind eq 'dt') {
            push @details, 'output drive families: ' . ($context->{output_drive_family_count} || 0);
        }

        return ($context->{endpoint} || $fallback || 'unknown_endpoint')
            . ' (' . join(', ', @details) . ')';
    }

    return $context->{endpoint} || $fallback || '';
}

sub composition_port_example_summary ($self, $entry) {
    return '' unless ref($entry) eq 'HASH';
    return $entry->{name} // '';
}

sub composition_link_example_summary ($self, $entry) {
    return '' unless ref($entry) eq 'HASH';

    my $source = $self->composition_provenance_endpoint_example_label(
        $entry->{source_context},
        $entry->{source},
    );
    my $target = $self->composition_provenance_endpoint_example_label(
        $entry->{target_context},
        $entry->{target},
    );

    return '' unless length($source) || length($target);
    return $source . ' -> ' . $target;
}

sub composition_signal_family_contexts ($self, $composition_plan, $signal_name, $direction = undef, $structural_rtl_ir = undef, $intent_hir = undef) {
    return [] unless defined $signal_name && length $signal_name;

    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my @contexts;
    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        for my $port (@{$instance->{interface_ports} || []}) {
            next unless (($port->{name} || '') eq $signal_name);
            next if defined $direction && length $direction && (($port->{direction} || '') ne $direction);

            my $context = $self->composition_provenance_endpoint_context(
                $composition_plan,
                (($instance->{instance_name} || 'unknown') . '.' . ($port->{name} || 'unknown')),
                $structural_rtl_ir,
                $intent_hir,
            );
            push @contexts, $context if $context;
        }
    }

    @contexts = sort {
        ($a->{endpoint} || '') cmp ($b->{endpoint} || '')
            ||
        ($a->{instance_name} || '') cmp ($b->{instance_name} || '')
    } @contexts;

    return \@contexts;
}

sub build_composition_override_events ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    my @events;
    my %same_name_endpoints;
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my @resolved_links = @{$structural_rtl_ir_hash->{resolved_links} || []};

    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        for my $port (@{$instance->{interface_ports} || []}) {
            push @{$same_name_endpoints{$port->{name}}}, {
                instance_name => $instance->{instance_name},
                port => $port,
            };
        }
    }

    for my $top_port (@{$structural_rtl_ir_hash->{ports} || []}) {
        next unless (($top_port->{binding_mode} || 'explicit') eq 'explicit');
        my $type = $top_port->{type} || '';
        next if $type eq 'clock' || $type eq 'reset';

        my @same_name_candidates = @{$same_name_endpoints{$top_port->{name}} || []};
        next unless @same_name_candidates;

        my @touching_explicit_toplinks = grep {
            ((($_->{origin_kind}) || '') eq 'declared_explicit_toplink')
            && (
                ((($_->{source}) || '') eq $top_port->{name})
                || ((($_->{target}) || '') eq $top_port->{name})
            )
        } @resolved_links;
        next unless @touching_explicit_toplinks;
        my $example_link = $touching_explicit_toplinks[0];
        my $source_context = $self->composition_provenance_endpoint_context($composition_plan, $example_link->{source}, $structural_rtl_ir, $intent_hir);
        my $target_context = $self->composition_provenance_endpoint_context($composition_plan, $example_link->{target}, $structural_rtl_ir, $intent_hir);

        if (($top_port->{direction} || '') eq 'input') {
            my @compatible = grep {
                (($_->{port}{direction} || '') eq 'input')
                && $_->{port}{width} == $top_port->{width}
                && $self->normalized_interface_type($_->{port}{type})
                    eq $self->normalized_interface_type($top_port->{type})
            } @same_name_candidates;

            next unless @compatible == @same_name_candidates;

            push @events, {
                kind => 'explicit_toplink_overrides_same_name_top_input_convention',
                top_port_name => $top_port->{name},
                lane => $composition_plan->lane,
                top_port_context => $self->composition_provenance_endpoint_context($composition_plan, $top_port->{name}, $structural_rtl_ir, $intent_hir),
                source_context => $source_context,
                target_context => $target_context,
            };
            next;
        }

        next unless (($top_port->{direction} || '') eq 'output');

        my @input_candidates = grep { (($_->{port}{direction} || '') eq 'input') } @same_name_candidates;
        next if @input_candidates;

        my @compatible_output_candidates = grep {
            (($_->{port}{direction} || '') eq 'output')
            && $_->{port}{width} == $top_port->{width}
            && $self->normalized_interface_type($_->{port}{type})
                eq $self->normalized_interface_type($top_port->{type})
        } @same_name_candidates;

        next unless @compatible_output_candidates == @same_name_candidates;
        next unless @compatible_output_candidates == 1;

        push @events, {
            kind => 'explicit_toplink_overrides_same_name_top_output_convention',
            top_port_name => $top_port->{name},
            lane => $composition_plan->lane,
            top_port_context => $self->composition_provenance_endpoint_context($composition_plan, $top_port->{name}, $structural_rtl_ir, $intent_hir),
            source_context => $source_context,
            target_context => $target_context,
        };
    }

    my %seen_reexports;
    for my $resolved_link (@resolved_links) {
        next unless (($resolved_link->{origin_kind} || '') eq 'inferred_internal_carrier_reexport_link');
        my $top_port_name = $resolved_link->{target};
        next if $seen_reexports{$top_port_name}++;

        push @events, {
            kind => 'explicit_top_output_reexports_internal_carrier',
            top_port_name => $top_port_name,
            source => $resolved_link->{source},
            lane => $composition_plan->lane,
            top_port_context => $self->composition_provenance_endpoint_context($composition_plan, $top_port_name, $structural_rtl_ir, $intent_hir),
            source_context => ($self->composition_signal_family_contexts($composition_plan, $top_port_name, 'output', $structural_rtl_ir, $intent_hir)->[0]),
        };
    }

    return \@events;
}

sub build_composition_block_events ($self, $composition_plan, $structural_rtl_ir = undef, $intent_hir = undef) {
    my @events;
    $structural_rtl_ir //= $self->build_composition_structural_rtl_ir($composition_plan);
    my $structural_rtl_ir_hash = ref($structural_rtl_ir) ? $structural_rtl_ir->as_hashref : {};
    my %declared_top_ports = map { (($_->{name} || '') => $_) } @{$structural_rtl_ir_hash->{ports} || []};
    my @declared_links = @{$structural_rtl_ir_hash->{declared_links} || []};
    my @resolved_links = @{$structural_rtl_ir_hash->{resolved_links} || []};
    my %port_groups;

    for my $instance (@{$structural_rtl_ir_hash->{instances} || []}) {
        for my $port (@{$instance->{interface_ports} || []}) {
            push @{$port_groups{$port->{name}}}, {
                instance_name => $instance->{instance_name},
                port => $port,
            };
        }
    }

    my %explicitly_linked_child_input_names;
    my %explicitly_linked_child_output_endpoints;
    for my $link (@declared_links) {
        my $source = $link->{source} || '';
        my $target = $link->{target} || '';

        my ($target_instance, $target_port_name) = $target =~ /^(\w+)\.(\w+)$/;
        if (defined $target_port_name) {
            my $source_is_child_endpoint = $source =~ /^\w+\.\w+$/;
            my $source_is_declared_top_port = exists $declared_top_ports{$source};
            if ($source_is_child_endpoint || $source_is_declared_top_port) {
                $explicitly_linked_child_input_names{$target_port_name} = 1;
            }
        }

        my ($source_instance, $source_port_name) = $source =~ /^(\w+)\.(\w+)$/;
        if (defined $source_port_name) {
            $explicitly_linked_child_output_endpoints{"$source_instance.$source_port_name"} = 1;
        }
    }

    for my $port_name (sort keys %port_groups) {
        next if $declared_top_ports{$port_name};
        my @candidates = @{$port_groups{$port_name}};
        next unless @candidates;

        my @input_candidates = grep { (($_->{port}{direction} || '') eq 'input') } @candidates;
        if (@input_candidates && @input_candidates == @candidates && $explicitly_linked_child_input_names{$port_name}) {
            my %widths = map { $_->{port}{width} => 1 } @input_candidates;
            my %types = map { $self->normalized_interface_type($_->{port}{type}) => 1 } @input_candidates;
            if (keys(%widths) == 1 && keys(%types) == 1) {
                push @events, {
                    kind => 'explicit_child_links_block_undeclared_top_input_inference',
                    signal_name => $port_name,
                    lane => $composition_plan->lane,
                    candidate_contexts => $self->composition_signal_family_contexts($composition_plan, $port_name, 'input', $structural_rtl_ir, $intent_hir),
                };
            }
            next;
        }

        my @output_candidates = grep { (($_->{port}{direction} || '') eq 'output') } @candidates;
        if (@output_candidates && @output_candidates == @candidates && @output_candidates == 1) {
            my $endpoint = $output_candidates[0]{instance_name}.'.'.$output_candidates[0]{port}{name};
            if ($explicitly_linked_child_output_endpoints{$endpoint}) {
                push @events, {
                    kind => 'explicit_child_links_block_undeclared_top_output_inference',
                    signal_name => $port_name,
                    lane => $composition_plan->lane,
                    candidate_contexts => $self->composition_signal_family_contexts($composition_plan, $port_name, 'output', $structural_rtl_ir, $intent_hir),
                };
                next;
            }
        }
    }

    my %internal_carrier_family;
    my %reexported_internal_carrier_family;
    for my $link (@resolved_links) {
        my $raw_token = $link->{raw_token} || '';
        my ($family_name) = $raw_token =~ /^=implicit-internal:(\w+)$/;
        next unless defined $family_name;

        if (($link->{origin_kind} || '') eq 'inferred_internal_carrier_link') {
            $internal_carrier_family{$family_name} = 1;
        } elsif (($link->{origin_kind} || '') eq 'inferred_internal_carrier_reexport_link') {
            $reexported_internal_carrier_family{$family_name} = 1;
        }
    }

    for my $family_name (sort keys %internal_carrier_family) {
        next if $reexported_internal_carrier_family{$family_name};
        push @events, {
            kind => 'inferred_internal_carrier_kept_internal_by_default',
            signal_name => $family_name,
            lane => $composition_plan->lane,
            candidate_contexts => (
                @{$self->composition_signal_family_contexts($composition_plan, $family_name, 'output', $structural_rtl_ir, $intent_hir)}
                    ? $self->composition_signal_family_contexts($composition_plan, $family_name, 'output', $structural_rtl_ir, $intent_hir)
                    : $self->composition_signal_family_contexts($composition_plan, $family_name, undef, $structural_rtl_ir, $intent_hir)
            ),
        };
    }

    return \@events;
}

sub composition_provenance_category ($self, $origin_kind) {
    return 'declared' if $origin_kind =~ /^declared_/;
    return 'inferred' if $origin_kind =~ /^inferred_/;
    return 'auto' if $origin_kind =~ /^auto_/;
    return 'realized' if $origin_kind =~ /^realized_/;
    return 'declared' if $origin_kind =~ /^rtlif_/;
    return 'other';
}

sub composition_provenance_sort_key ($self, $origin_kind) {
    my %rank = (
        declared => 0,
        inferred => 1,
        auto => 2,
        realized => 3,
        other => 4,
    );

    return $rank{$self->composition_provenance_category($origin_kind)};
}

sub composition_provenance_label ($self, $origin_kind) {
    my %labels = (
        declared_explicit_port => 'declared explicit top port',
        declared_connect_by_name_port => 'declared connect-by-name top port',
        declared_explicit_toplink => 'declared explicit toplink',
        declared_connect_by_name_link => 'declared connect-by-name link',
        declared_c1_passthrough_link => 'declared single-child passthrough link',
        inferred_c1_passthrough_port => 'inferred single-child passthrough top port',
        inferred_c1_passthrough_link => 'inferred single-child passthrough link',
        inferred_explicit_toplink_port => 'inferred top port from explicit toplink',
        inferred_undeclared_top_input_port => 'inferred undeclared top input',
        inferred_undeclared_top_output_port => 'inferred undeclared top output',
        inferred_plain_explicit_top_input_link => 'inferred plain explicit top-input convention link',
        inferred_plain_explicit_top_output_link => 'inferred plain explicit top-output convention link',
        inferred_undeclared_top_input_link => 'inferred undeclared top-input link',
        inferred_undeclared_top_output_link => 'inferred undeclared top-output link',
        inferred_internal_carrier_link => 'inferred internal carrier link',
        inferred_internal_carrier_reexport_link => 'inferred internal carrier re-export link',
        auto_system_port_link => 'auto system-port link',
        realized_child_interface_port => 'realized child interface port',
        rtlif_declared_port => 'declared rtlif port',
    );

    return $labels{$origin_kind} if defined $labels{$origin_kind};

    (my $label = $origin_kind) =~ s/_/ /g;
    return $label;
}

sub composition_override_label ($self, $kind) {
    my %labels = (
        explicit_toplink_overrides_same_name_top_input_convention => 'explicit toplink overrides same-name top-input convention',
        explicit_toplink_overrides_same_name_top_output_convention => 'explicit toplink overrides same-name top-output convention',
        explicit_top_output_reexports_internal_carrier => 'explicit top output re-exports internal carrier',
    );

    return $labels{$kind} if defined $labels{$kind};

    (my $label = $kind) =~ s/_/ /g;
    return $label;
}

sub composition_override_example_summary ($self, $event) {
    return '' unless $event && ref($event) eq 'HASH';

    if ($event->{source_context} || $event->{target_context}) {
        return $self->composition_link_example_summary({
            source => $event->{source},
            target => $event->{top_port_name},
            source_context => $event->{source_context},
            target_context => $event->{target_context} || $event->{top_port_context},
        });
    }

    if (defined $event->{top_port_name} && length $event->{top_port_name}) {
        return "Top port '$event->{top_port_name}'";
    }

    if (defined $event->{signal_name} && length $event->{signal_name}) {
        return "Signal name '$event->{signal_name}'";
    }

    return '';
}

sub composition_block_label ($self, $kind) {
    my %labels = (
        explicit_child_links_block_undeclared_top_input_inference => 'explicit child links block undeclared top-input inference',
        explicit_child_links_block_undeclared_top_output_inference => 'explicit child links block undeclared top-output inference',
        inferred_internal_carrier_kept_internal_by_default => 'inferred internal carrier kept internal by default',
    );

    return $labels{$kind} if defined $labels{$kind};

    (my $label = $kind) =~ s/_/ /g;
    return $label;
}

sub composition_block_example_summary ($self, $event) {
    return '' unless $event && ref($event) eq 'HASH';

    if (ref($event->{candidate_contexts}) eq 'ARRAY' && @{$event->{candidate_contexts}}) {
        return $self->composition_provenance_endpoint_example_label($event->{candidate_contexts}[0]);
    }

    if (defined $event->{signal_name} && length $event->{signal_name}) {
        return "Signal name '$event->{signal_name}'";
    }

    if (defined $event->{top_port_name} && length $event->{top_port_name}) {
        return "Top port '$event->{top_port_name}'";
    }

    return '';
}

sub build_composition_failure_report ($self, $error_text) {
    return undef unless defined $error_text && length $error_text;

    my $summary_text = $error_text;
    $summary_text =~ s/\n\s*at\s+\S.*\z//s;

    my %report;

    if ($summary_text =~ /Composition top '([^']+)'/s) {
        $report{top_name} = $1;
    }
    elsif ($summary_text =~ /Composition source '\?top:([^']+)'/s) {
        $report{top_name} = $1;
    }

    if ($summary_text =~ /Composition references external RTL module '([^']+)'/s) {
        $report{rtl_module_name} = $1;
    }

    if ($summary_text =~ /\b(?:the\s+)?(?:current\s+)?active\s+(C[1-4])\s+lane\b/is) {
        $report{lane} = uc($1);
    }

    my $construct = $self->composition_failure_construct_excerpt($summary_text);
    if ($construct) {
        $report{construct} = $construct->{token};
        $report{construct_summary} = $construct->{summary};
    }

    my $artifact = $self->composition_failure_artifact_excerpt($summary_text);
    if ($artifact) {
        $report{artifact_label} = $artifact->{label};
        $report{artifact_value} = $artifact->{value};
        $report{artifact_summary} = $artifact->{summary};
    }

    my $context = $self->composition_failure_context_excerpt($summary_text);
    if ($context) {
        unless (
            defined($report{artifact_value})
            && length($report{artifact_value})
            && $context->{label} eq 'Metadata'
            && $context->{value} eq $report{artifact_value}
        ) {
            $report{context_label} = $context->{label};
            $report{context_value} = $context->{value};
            $report{context_summary} = $context->{summary};
        }
    }

    if ($summary_text =~ /\b(?:but )?([A-Za-z0-9?'\-\/][A-Za-z0-9?'\-\/ ]+?) is blocked because\b/s) {
        my $blocked_boundary = $1;
        $blocked_boundary =~ s/\s+/ /g;
        $blocked_boundary =~ s/^\s+|\s+$//g;
        $report{blocked_boundary} = $blocked_boundary;
        $report{blocked_boundary_label} = $self->composition_failure_boundary_label($blocked_boundary);
    }

    if ($summary_text =~ /\bis blocked because\s+(.+)\z/s) {
        my $reason = $self->composition_failure_reason_excerpt($1);
        $report{blocked_reason} = $reason if defined $reason && length $reason;
    }

    return undef unless $report{blocked_boundary};
    return \%report;
}

sub composition_failure_boundary_label ($self, $blocked_boundary) {
    return '' unless defined $blocked_boundary && length $blocked_boundary;

    my $label = $blocked_boundary;
    $label =~ s/^\s+|\s+$//g;
    $label =~ s/^composition //i;
    return $label;
}

sub composition_failure_reason_excerpt ($self, $reason_text) {
    return '' unless defined $reason_text && length $reason_text;

    my $reason = $reason_text;
    $reason =~ s/\s+/ /g;
    $reason =~ s/^\s+|\s+$//g;
    $reason =~ s/^declared interface metadata '[^']+'\s+//;
    $reason =~ s/\s+in declared interface metadata '[^']+'//g;
    $reason =~ s/\s*See docs\/.*\z//i;
    $reason =~ s/,\s+except that the single-child passthrough C1 lane and the explicit-link C2\/C3 lanes may now infer the top interface when '\?ports' is omitted or empty//g;

    if (
        $reason =~ /\A(.+?)\.\s+Seen same-name child endpoints:\s+(.+?)\.\s+(?:The active|The current|Use '\?toplink'|Use '\?ports'|Use '\?fsmc'|Use '\?dtc'|Standalone '\?dt:name' roots|FSM child roots are shipped as composition children).*\z/s
    ) {
        my ($headline, $seen) = ($1, $2);
        $headline =~ s/^\s+|\s+$//g;
        $seen =~ s/^\s+|\s+$//g;
        return "$headline. Seen same-name child endpoints: $seen";
    }

    $reason =~ s/\.\s+(?:Search roots:|Seen |The active |The current |Use '\?toplink'|Use '\?ports'|Use '\?fsmc'|Use '\?dtc'|Standalone '\?dt:name' roots|FSM child roots are shipped as composition children).*\z//;
    $reason =~ s/\.\z//;
    $reason =~ s/^\s+|\s+$//g;
    return $reason;
}

sub composition_failure_construct_excerpt ($self, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/declared connect-by-name|=port/s, '=port', '=port' ],
        [ qr/requests declared connect-by-name/s, '=port', '=port' ],
        [ qr/Composition references external RTL module|RTL interface metadata|contains embedded '\?rtlif:/s, '?rtl', '?rtl' ],
        [ qr/explicit '\?ports' block|'\?ports' to declare at least one explicit top port/s, '?ports', '?ports' ],
        [ qr/explicit link|explicit-link|nested '\?toplink' item|contains '\?toplink' token/s, '?toplink', '?toplink' ],
        [ qr/contains child '\?toplink(?::[^']+)?'/s, '?toplink', '?toplink' ],
        [ qr/omits top port|declares top port|declares duplicate top port|marks top port|uses top port|nested '\?ports' item|contains '\?ports' token|contains '\?ports' mapping directive/s, '?ports', '?ports' ],
        [ qr/contains child '\?ports(?::[^']+)?'/s, '?ports', '?ports' ],
        [ qr/contains child '\?rtl:[^']+'/s, '?rtl', '?rtl' ],
        [ qr/contains child '\?fsmc(?::[^']+)?'/s, '?fsmc', '?fsmc' ],
        [ qr/\?fsmc' child|active FSM child source/s, '?fsmc', '?fsmc' ],
        [ qr/contains child '\?dtc(?::[^']+)?'/s, '?dtc', '?dtc' ],
        [ qr/\?dtc' child|standalone-DT child source/s, '?dtc', '?dtc' ],
    );

    for my $entry (@patterns) {
        my ($pattern, $token, $summary) = @$entry;
        next unless $summary_text =~ $pattern;
        return {
            token => $token,
            summary => $summary,
        };
    }

    return undef;
}

sub composition_failure_artifact_excerpt ($self, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/resolves '\?(?:fsmc|dtc)' child '[^']+' to '([^']+)'/s, sub { return ('Child source file', "'$_[0]'"); } ],
        [ qr/declared interface metadata '([^']+)'/s, sub { return ('RTL metadata file', "'$_[0]'"); } ],
    );

    for my $entry (@patterns) {
        my ($pattern, $builder) = @$entry;
        next unless $summary_text =~ $pattern;
        my ($label, $value) = $builder->($1);
        return {
            label => $label,
            value => $value,
            summary => "$label $value",
        };
    }

    return undef;
}

sub composition_failure_context_excerpt ($self, $summary_text) {
    return undef unless defined $summary_text && length $summary_text;

    my @patterns = (
        [ qr/contains a child entry that is empty or missing its header/s, sub { return ('Child entry', "'missing header'"); } ],
        [ qr/contains a child entry that does not begin with a string header/s, sub { return ('Child entry', "'non-string header'"); } ],
        [ qr/contains a nested '(\?(?:ports|toplink))' item/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains '(\?(?:fsmc|dtc))' child without a name/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/contains '\?(?:fsmc|dtc|rtl)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/declares duplicate child instance name '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/declares '\?(?:fsmc|dtc|rtl)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/resolves '\?(?:fsmc|dtc)' child '([^']+)'/s, sub { return ('Child', "'$_[0]'"); } ],
        [ qr/mapping directive '([^']+)'/s, sub { return ('Mapping directive', "'$_[0]'"); } ],
        [ qr/contains multiple embedded '(\?rtlif:[^']+)' roots/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/does not contain a '(\?rtlif:[^']+)' root/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/under '(\?rtlif:[^']+)'/s, sub { return ('RTL root', "'$_[0]'"); } ],
        [ qr/references child endpoint '([^']+)'/s, sub { return ('Child endpoint', "'$_[0]'"); } ],
        [ qr/uses child endpoint '([^']+)'/s, sub { return ('Child endpoint', "'$_[0]'"); } ],
        [ qr/links top input '([^']+)' directly to top output '([^']+)'/s, sub {
            return ('Top port', "'$_[0]'");
        } ],
        [ qr/drives multiple top outputs from '([^']+)'/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/links '[^']+' \(width \d+\) to '([^']+)' \(width \d+\)/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/assigns explicit link driver '[^']+' to target '([^']+)'/s, sub {
            return $_[0] =~ /\./
                ? ('Child endpoint', "'$_[0]'")
                : ('Top port', "'$_[0]'");
        } ],
        [ qr/references top-level endpoint '([^']+)'/s, sub { return ('Top endpoint', "'$_[0]'"); } ],
        [ qr/uses explicit endpoint '([^']+)'/s, sub { return ('Endpoint', "'$_[0]'"); } ],
        [ qr/declares duplicate top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/omits top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/declares top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/marks top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/uses top port '([^']+)'/s, sub { return ('Top port', "'$_[0]'"); } ],
        [ qr/leaves child port '([^']+)'/s, sub { return ('Child port', "'$_[0]'"); } ],
        [ qr/child port '([^']+)'/s, sub { return ('Child port', "'$_[0]'"); } ],
        [ qr/repeats port '([^']+)'/s, sub { return ('RTL port', "'$_[0]'"); } ],
        [ qr/instance '([^']+)' has no port named '([^']+)'/s, sub { return ('Child endpoint', "'$_[0].$_[1]'"); } ],
        [ qr/token '([^']+)'/s, sub { return ('Token', "'$_[0]'"); } ],
        [ qr/declared interface metadata '([^']+)'/s, sub { return ('Metadata', "'$_[0]'"); } ],
        [ qr/RTL interface metadata '([^']+)'/s, sub { return ('Metadata', "'$_[0]'"); } ],
    );

    for my $entry (@patterns) {
        my ($pattern, $formatter) = @$entry;
        next unless my @captures = ($summary_text =~ $pattern);
        my ($label, $value) = $formatter->(@captures);
        next unless defined $label && defined $value;
        return {
            label => $label,
            value => $value,
            summary => "$label $value",
        };
    }

    return undef;
}

sub build_intent_hir ($self, $fsm_module) {
    fsm_trace_enter('Analyze FSM module structure and signals', 2);
    fsm_debug("Analyzing FSM module structure", 1);
    
    my $module_name = $fsm_module->name;
    my @all_states = @{$fsm_module->states};
    my %all_signals = %{$fsm_module->signals};
    
    # Separate encoded states from DT-like blocks, including dedicated reset-state blocks.
    my @regular_states = grep {
        $_->can('is_regular_state') ? $_->is_regular_state : $_->name !~ /^-/
    } @all_states;
    my @standalone_dts = grep {
        $_->can('is_regular_state') ? !$_->is_regular_state : $_->name =~ /^-/
    } @all_states;
    
    fsm_debug("Module analysis:", 1);
    fsm_debug("  Module name: $module_name", 1);
    fsm_debug("  Regular states: " . scalar(@regular_states), 1);
    fsm_debug("  Standalone DTs: " . scalar(@standalone_dts), 1);
    fsm_debug("  Total signals: " . scalar(keys %all_signals), 1);
    
    # Analyze signals in detail
    my %signal_analysis = $self->analyze_signals(\%all_signals);
    my $standalone_dt_enable_metadata = $self->build_standalone_dt_enable_metadata(\@all_states);
    my @parameter_names = sort keys %{ $fsm_module->parameters || {} };

    my $intent_hir = FSM::IR::IntentHIR->new(
        module_name => $module_name,
        source_root_kind => (
            $fsm_module->can('source_root_kind')
                ? $fsm_module->source_root_kind
                : 'fsm'
        ),
        regular_state_names => [ map { $_->name } @regular_states ],
        standalone_dt_names => $standalone_dt_enable_metadata->{standalone_dt_names},
        signal_names => [ sort keys %all_signals ],
        signal_analysis => \%signal_analysis,
        explicit_system_contract => (
            $fsm_module->can('explicit_system_contract')
                ? $fsm_module->explicit_system_contract
                : undef
        ),
        system_contract => (
            $fsm_module->can('effective_system_contract')
                ? $fsm_module->effective_system_contract
                : {
                    clock => 'clk',
                    reset => 'rst_n',
                    reset_keyword => 'asreset',
                    implicit => 1,
                }
        ),
        requires_implicit_system_ports => (
            $fsm_module->can('requires_implicit_system_ports')
                ? $fsm_module->requires_implicit_system_ports
                : 1
        ),
        standalone_dt_enable_families => $standalone_dt_enable_metadata->{standalone_dt_enable_families},
        standalone_dt_module_enable_family => $standalone_dt_enable_metadata->{standalone_dt_module_enable_family},
        parameter_names => \@parameter_names,
    );
    fsm_trace_exit('FSM module analysis complete', 2);
    return $intent_hir;
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

sub build_standalone_dt_enable_metadata ($self, $all_states) {
    my @standalone_dt_blocks = sort {
        $a->name cmp $b->name
    } grep {
        ref($_) && $_->can('is_standalone_dt') && $_->is_standalone_dt
    } @{$all_states || []};

    my @enable_families = map {
        my $dt_name = $_->name;
        my $enable_signal = $dt_name;
        $enable_signal =~ s/^-//;
        $enable_signal .= '_en';

        {
            dt_name => $dt_name,
            enable_signal => $enable_signal,
        };
    } @standalone_dt_blocks;

    my @dt_names = map { $_->{dt_name} } @enable_families;
    my @enable_signals = map { $_->{enable_signal} } @enable_families;

    return {
        standalone_dt_count => scalar(@enable_families),
        standalone_dt_names => \@dt_names,
        standalone_dt_enable_families => \@enable_families,
        standalone_dt_module_enable_family => {
            dt_names => \@dt_names,
            enable_signals => \@enable_signals,
        },
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

    my $lowered_rtl_ir = $module_info->{lowered_rtl_ir};
    if (ref($lowered_rtl_ir) eq 'HASH' && ref($lowered_rtl_ir->{output_drive_families}) eq 'ARRAY') {
        return $lowered_rtl_ir->{output_drive_families};
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

    my $lowered_rtl_ir = $module_info->{lowered_rtl_ir};
    if (ref($lowered_rtl_ir) eq 'HASH' && ref($lowered_rtl_ir->{standalone_dt_multi_drive_targets}) eq 'ARRAY') {
        return $lowered_rtl_ir->{standalone_dt_multi_drive_targets};
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

sub analyze_signals ($self, $signals) {
    fsm_trace_enter('Analyze signal roles, width, and direction', 3);
    fsm_debug("Analyzing signal properties", 2);
    
    my %analysis = (
        inputs => [],
        outputs => [],
        multi_bit => [],
        single_bit => [],
    );
    
    for my $sig_name (sort keys %$signals) {
        my $signal = $signals->{$sig_name};
        my $width = $signal->width || 1;
        my $dir = $self->determine_signal_direction($signal, $sig_name);
        
        fsm_debug("Processing signal '$sig_name'", 2);
        fsm_debug("  Signal object type: " . ref($signal), 3);
        fsm_debug("  Width method available: " . ($signal->can('width') ? 'YES' : 'NO'), 3);
        if ($signal->can('width')) {
            my $raw_width = $signal->width;
            fsm_debug("  Raw width value: " . (defined($raw_width) ? $raw_width : 'UNDEF'), 3);
        }
        fsm_debug("  Final computed width: $width", 2);
        
        # Categorize signals
        if ($dir eq 'output') {
            push @{$analysis{outputs}}, {
                name => $sig_name,
                width => $width,
                signal => $signal
            };
        } else {
            push @{$analysis{inputs}}, {
                name => $sig_name,
                width => $width,
                signal => $signal
            };
        }
        
        if ($width > 1) {
            push @{$analysis{multi_bit}}, {
                name => $sig_name,
                width => $width,
                direction => $dir
            };
            fsm_debug("*** Multi-bit signal detected: $sig_name with width $width ***", 2);
        } else {
            push @{$analysis{single_bit}}, {
                name => $sig_name,
                direction => $dir
            };
            fsm_debug("Single-bit signal: $sig_name", 3);
        }
    }
    
    fsm_debug("Signal analysis complete:", 2);
    fsm_debug("  Input signals: " . scalar(@{$analysis{inputs}}), 2);
    fsm_debug("  Output signals: " . scalar(@{$analysis{outputs}}), 2);
    fsm_debug("  Multi-bit signals: " . scalar(@{$analysis{multi_bit}}), 2);
    fsm_debug("  Single-bit signals: " . scalar(@{$analysis{single_bit}}), 2);
    
    fsm_trace_exit('Signal analysis complete', 3);
    return %analysis;
}

sub determine_signal_direction ($self, $signal, $sig_name) {
    fsm_trace_enter("Determine signal direction for '$sig_name'", 4);
    # Try to determine signal direction
    if ($signal->can('get_attribute')) {
        my $signal_role = $signal->get_attribute('signal_role');
        if (defined $signal_role && $signal_role eq 'OUTPUT') {
            fsm_trace_decision(1, "Signal '$sig_name' signal_role reports OUTPUT", 4);
            fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
            return "output";
        }
        if (defined $signal_role && $signal_role eq 'INPUT') {
            fsm_trace_decision(1, "Signal '$sig_name' signal_role reports INPUT", 4);
            fsm_trace_exit("Direction resolved for '$sig_name' => input", 4);
            return "input";
        }
    }

    if ($signal->can('is_output') && $signal->is_output) {
        fsm_trace_decision(1, "Signal '$sig_name' is_output accessor reports true", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return "output";
    } elsif ($signal->can('attributes') && $signal->attributes && $signal->attributes->{is_output}) {
        fsm_trace_decision(1, "Signal '$sig_name' attributes->{is_output} is true", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return "output";
    } elsif ($sig_name =~ />$/ || ($sig_name =~ /^p/ && $sig_name !~ /^p(ready|rdata)$/)) {
        fsm_trace_decision(1, "Signal '$sig_name' inferred output by naming policy", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => output", 4);
        return "output";
    } else {
        fsm_trace_decision(1, "Signal '$sig_name' defaulted to input direction", 4);
        fsm_trace_exit("Direction resolved for '$sig_name' => input", 4);
        return "input";
    }
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
