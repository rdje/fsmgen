#!/usr/bin/perl

package FSM::Pipeline::HDLGenerator;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Carp qw(confess);
use FindBin;
use lib "$FindBin::Bin";
use FSM::Debug;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Extension::Loader;
use FSM::Extension::Registry;
use FSM::Pipeline::SourceGenerationOrchestrator;
use FSM::SourcePathResolver;

=head1 NAME

FSM::Pipeline::HDLGenerator - Complete FSM to HDL generation pipeline

=head1 DESCRIPTION

This module is the thin public facade for the active FSMGen generation
pipeline. It owns shared pipeline configuration plus the public
C<generate_hdl_from_file(...)> entrypoint, while the real work lives in
explicit frontend, orchestrator, builder, and backend-owner packages.

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
    my $requested_debug_level = $args{debug_level} // 0;
    return with_fsm_debug_state(
        { debug_level => $requested_debug_level },
        sub {
            fsm_trace_enter('Initialize HDLGenerator pipeline', 2);
            my $source_path_resolver = $args{source_path_resolver}
                // FSM::SourcePathResolver->new(
                    extra_search_paths => ($args{source_search_paths} || []),
                );
            my $extension_loader = $args{extension_loader}
                // FSM::Extension::Loader->new();
            my $extension_registry = $args{extension_registry};
            unless ($extension_registry) {
                my $extension_config_files = _array_ref_constructor_arg(
                    'extension_config_files',
                    $args{extension_config_files},
                );
                my $extension_modules = _array_ref_constructor_arg(
                    'extension_modules',
                    $args{extension_modules},
                );
                my $direct_extensions = _array_ref_constructor_arg(
                    'extensions',
                    $args{extensions},
                );
                my $config_module_names = $extension_loader->module_names_from_config_files(
                    $extension_config_files,
                );
                my @extension_module_names = (
                    @$extension_modules,
                    @$config_module_names,
                );
                my $loaded_extensions = $extension_loader->load_modules(
                    \@extension_module_names,
                );
                my @extensions = (
                    @$direct_extensions,
                    @$loaded_extensions,
                );
                $extension_registry = FSM::Extension::Registry->new(
                    extensions => \@extensions,
                );
            }
            my $self = bless {
                debug_level => $requested_debug_level,
                target_language => $args{target_language} // 'systemverilog',
                quiet => $args{quiet} // 0,
                strict_mode => $args{strict_mode} // 0,
                source_path_resolver => $source_path_resolver,
                rtl_interface_loader => $args{rtl_interface_loader}
                    // FSM::Composition::RTLInterfaceLoader->new(
                        debug => $requested_debug_level > 0,
                        path_resolver => $source_path_resolver,
                    ),
                extension_loader => $extension_loader,
                extension_registry => $extension_registry,
            }, $class;

            fsm_debug("HDL generation pipeline initialized", 1);
            fsm_debug("  Debug level: $self->{debug_level}", 1);
            fsm_debug("  Target language: $self->{target_language}", 1);

            fsm_trace_exit('HDLGenerator pipeline initialized', 2);
            return $self;
        },
    );
}

sub _array_ref_constructor_arg ($arg_name, $value) {
    return [] unless defined $value;
    return $value if ref($value) eq 'ARRAY';

    confess "FSM::Pipeline::HDLGenerator expects '$arg_name' to be an array reference";
}

sub generate_hdl_from_file ($self, $fsm_file) {
    return with_fsm_debug_state(
        { debug_level => ($self->{debug_level} // 0) },
        sub {
            return FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
                pipeline => $self,
                fsm_file => $fsm_file,
            );
        },
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
- strict_mode: Enable strict support-tier enforcement (default: 0)

=head2 generate_hdl_from_file($fsm_file)

Processes an FSM file through the complete pipeline and returns results.

Returns a hashref with:
- fsm_module: The parsed FSM module object
- intent_hir: The extracted forward semantic intent IR summary for direct generated roots
- module_info: Analysis of the FSM structure
- hdl_code: Generated HDL code
- statistics: Generation statistics
- raw_ast: Original parsed AST

=head1 ARCHITECTURE NOTE

The active runtime path now goes through explicit owner packages:

1. source frontend,
2. source/direct/composition orchestrators,
3. forward-IR builders,
4. generated-module or structural backend emitters,
5. result metadata helpers.

C<FSM::Pipeline::HDLGenerator> now remains as the public facade that wires
those owners together through shared pipeline configuration and the top-level
C<generate_hdl_from_file(...)> entrypoint.

=cut
