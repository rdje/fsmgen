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
use FSM::SourceClassifier;
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
    my $self = bless {
        debug_level => $args{debug_level} // 0,
        target_language => $args{target_language} // 'systemverilog',
        quiet => $args{quiet} // 0,
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
    $self->assert_supported_source_kind($source_info, $fsm_file);
    
    # Step 2: Convert raw AST to semantic FSM module
    my $fsm_module = $self->create_fsm_module($raw_ast);
    
    # Step 3: Analyze FSM module
    my $module_info = $self->analyze_fsm_module($fsm_module);
    
    # Step 4: Generate HDL code
    my $hdl_code = $self->generate_hdl_code($fsm_module);
    
    # Step 5: Gather statistics
    my $statistics = $self->gather_statistics($fsm_module);
    
    fsm_debug("HDL generation pipeline completed successfully", 1);
    
    my $result = {
        fsm_module => $fsm_module,
        module_info => $module_info,
        hdl_code => $hdl_code,
        statistics => $statistics,
        raw_ast => $raw_ast,
        source_info => $source_info,
    };
    fsm_trace_exit("HDL generation complete for '$fsm_file'", 1);
    return $result;
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

sub assert_supported_source_kind ($self, $source_info, $fsm_file) {
    return unless $source_info && $source_info->{kind} eq 'composition';

    my $header = $source_info->{header} // '?top:name';
    fsm_trace_decision(0, "Detected composition source '$header' before FSM-only adapter boundary", 1);
    Carp::confess
        "Composition source '$header' in '$fsm_file' is recognized, but the active composition pipeline is not implemented yet. ".
        "Route '?top:name' inputs through the upcoming R6 composition path described in docs/COMPOSITION_SCOPE.md.\n";
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

sub analyze_fsm_module ($self, $fsm_module) {
    fsm_trace_enter('Analyze FSM module structure and signals', 2);
    fsm_debug("Analyzing FSM module structure", 1);
    
    my $module_name = $fsm_module->name;
    my @all_states = @{$fsm_module->states};
    my %all_signals = %{$fsm_module->signals};
    
    # Separate regular states from standalone DTs
    my @regular_states = grep { $_->name !~ /^-/ } @all_states;
    my @standalone_dts = grep { $_->name =~ /^-/ } @all_states;
    
    fsm_debug("Module analysis:", 1);
    fsm_debug("  Module name: $module_name", 1);
    fsm_debug("  Regular states: " . scalar(@regular_states), 1);
    fsm_debug("  Standalone DTs: " . scalar(@standalone_dts), 1);
    fsm_debug("  Total signals: " . scalar(keys %all_signals), 1);
    
    # Analyze signals in detail
    my %signal_analysis = $self->analyze_signals(\%all_signals);
    
    my $result = {
        module_name => $module_name,
        regular_states => \@regular_states,
        standalone_dts => \@standalone_dts,
        signals => \%all_signals,
        signal_analysis => \%signal_analysis,
        state_count => scalar(@regular_states),
        signal_count => scalar(keys %all_signals),
    };
    fsm_trace_exit('FSM module analysis complete', 2);
    return $result;
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
