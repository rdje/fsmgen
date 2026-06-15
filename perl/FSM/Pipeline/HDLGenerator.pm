#!/usr/bin/perl

package FSM::Pipeline::HDLGenerator;
use v5.20;
use strict;
use warnings;
use feature qw(signatures);
no warnings 'experimental::signatures';

use Carp qw(confess);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin";
use Scalar::Util qw(blessed reftype);
use FSM::Debug;
use FSM::Composition::RTLInterfaceLoader;
use FSM::Extension::Loader;
use FSM::Extension::Registry;
use FSM::Pipeline::SourceGenerationOrchestrator;
use FSM::SourcePathResolver;

my @SUPPORTED_EXTENSION_HOOK_METHODS = qw(
    after_parse_source
    after_generate_result
);

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

sub new ($class, @constructor_args) {
    my $constructor_class = _constructor_receiver_arg($class);
    my %args = _constructor_arg_list(@constructor_args);
    my $legacy_debug_level = _legacy_debug_constructor_arg($args{debug});
    my $requested_debug_level = _debug_level_constructor_arg(
        exists $args{debug_level} ? $args{debug_level} : $legacy_debug_level,
    );
    return with_fsm_debug_state(
        { debug_level => $requested_debug_level },
        sub {
            fsm_trace_enter('Initialize HDLGenerator pipeline', 2);
            my $source_search_paths = _source_search_paths_constructor_arg(
                $args{source_search_paths},
            );
            my $target_language = _target_language_constructor_arg(
                $args{target_language},
            );
            my $strict_mode = _boolean_constructor_arg(
                'strict_mode',
                $args{strict_mode},
            );
            my $quiet = _boolean_constructor_arg(
                'quiet',
                $args{quiet},
            );
            my $source_path_resolver = _object_injection_constructor_arg(
                'source_path_resolver',
                $args{source_path_resolver},
                qw(normalized_search_paths),
            );
            $source_path_resolver //= FSM::SourcePathResolver->new(
                extra_search_paths => $source_search_paths,
            );
            my $extension_loader = _object_injection_constructor_arg(
                'extension_loader',
                $args{extension_loader},
                qw(module_names_from_config_files load_modules),
            );
            $extension_loader //= FSM::Extension::Loader->new();
            my $extension_registry = _object_injection_constructor_arg(
                'extension_registry',
                $args{extension_registry},
                qw(after_parse_source after_generate_result),
            );
            unless (defined $extension_registry) {
                my $extension_config_files = _array_ref_constructor_arg(
                    'extension_config_files',
                    $args{extension_config_files},
                );
                my $extension_modules = _array_ref_constructor_arg(
                    'extension_modules',
                    $args{extension_modules},
                );
                my $direct_extensions = _extension_objects_constructor_arg(
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
            my $rtl_interface_loader = _object_injection_constructor_arg(
                'rtl_interface_loader',
                $args{rtl_interface_loader},
                qw(load_interface),
            );
            $rtl_interface_loader //= FSM::Composition::RTLInterfaceLoader->new(
                debug => $requested_debug_level > 0,
                path_resolver => $source_path_resolver,
            );
            my $self = bless {
                __fsmgen_hdl_generator_facade_instance => 1,
                debug_level => $requested_debug_level,
                target_language => $target_language,
                quiet => $quiet,
                strict_mode => $strict_mode,
                source_path_resolver => $source_path_resolver,
                rtl_interface_loader => $rtl_interface_loader,
                extension_loader => $extension_loader,
                extension_registry => $extension_registry,
            }, $constructor_class;

            fsm_debug("HDL generation pipeline initialized", 1);
            fsm_debug("  Debug level: $self->{debug_level}", 1);
            fsm_debug("  Target language: $self->{target_language}", 1);

            fsm_trace_exit('HDLGenerator pipeline initialized', 2);
            return $self;
        },
    );
}
sub _constructor_receiver_arg ($value) {
    confess "FSM::Pipeline::HDLGenerator expects new(...) invocant to be the FSM::Pipeline::HDLGenerator class name"
        unless defined($value) && !ref($value) && $value eq __PACKAGE__;

    return $value;
}
sub _constructor_arg_list (@constructor_args) {
    confess "FSM::Pipeline::HDLGenerator expects new(...) arguments after the class invocant to be option/value pairs"
        if @constructor_args % 2;

    my (%args, %seen_args, %duplicate_args);
    my @remaining = @constructor_args;
    while (@remaining) {
        my ($arg_name, $value) = splice @remaining, 0, 2;
        confess "FSM::Pipeline::HDLGenerator expects new(...) option names to be scalar non-empty strings before constructor option-name validation"
            unless defined($arg_name) && !ref($arg_name) && $arg_name =~ /\S/;
        $duplicate_args{$arg_name} = 1 if $seen_args{$arg_name};
        $seen_args{$arg_name} = 1;
        $args{$arg_name} = $value;
    }

    _constructor_duplicate_arg_names(%duplicate_args);
    _constructor_arg_names(%args);
    return %args;
}
sub _constructor_duplicate_arg_names (%duplicate_args) {
    my @duplicates = sort keys %duplicate_args;
    confess "FSM::Pipeline::HDLGenerator does not accept duplicate constructor option(s): "
        . join(', ', @duplicates)
        if @duplicates;

    return;
}
sub _constructor_arg_names (%args) {
    my %supported = map { $_ => 1 } qw(
        debug_level
        target_language
        quiet
        strict_mode
        source_search_paths
        extensions
        debug
        source_path_resolver
        extension_loader
        extension_registry
        rtl_interface_loader
        extension_config_files
        extension_modules
    );
    my @unsupported = sort grep { !$supported{$_} } keys %args;
    confess "FSM::Pipeline::HDLGenerator does not accept unsupported constructor option(s): "
        . join(', ', @unsupported)
        if @unsupported;

    return;
}

sub _array_ref_constructor_arg ($arg_name, $value) {
    return [] unless defined $value;
    return $value if ref($value) eq 'ARRAY';

    confess "FSM::Pipeline::HDLGenerator expects '$arg_name' to be an array reference";
}
sub _source_search_paths_constructor_arg ($value) {
    my $paths = _array_ref_constructor_arg('source_search_paths', $value);
    for my $index (0 .. $#$paths) {
        my $path = $paths->[$index];
        confess "FSM::Pipeline::HDLGenerator expects 'source_search_paths' entries to be scalar non-empty filesystem search roots"
            unless defined($path) && !ref($path) && $path =~ /\S/;
    }

    return $paths;
}
sub _extension_objects_constructor_arg ($arg_name, $value) {
    my $extensions = _array_ref_constructor_arg($arg_name, $value);
    for my $extension (@$extensions) {
        confess "FSM::Pipeline::HDLGenerator accepts only blessed extension objects in '$arg_name'"
            unless blessed($extension);
        confess "FSM::Pipeline::HDLGenerator expects each object in '$arg_name' to provide at least one supported typed-extension hook method: "
            . join(', ', @SUPPORTED_EXTENSION_HOOK_METHODS)
            unless _object_has_supported_extension_hook($extension);
    }

    return $extensions;
}
sub _object_has_supported_extension_hook ($extension) {
    for my $hook_method (@SUPPORTED_EXTENSION_HOOK_METHODS) {
        return 1 if UNIVERSAL::can($extension, $hook_method);
    }

    return 0;
}
sub _object_injection_constructor_arg ($arg_name, $value, @methods) {
    return undef unless defined $value;
    die "FSM::Pipeline::HDLGenerator expects non-public owner-injection constructor option '$arg_name' to be a blessed object providing required owner methods\n"
        unless _blessed_object_with_methods($value, @methods);

    return $value;
}
sub _boolean_constructor_arg ($arg_name, $value) {
    return 0 unless defined $value;
    confess "FSM::Pipeline::HDLGenerator expects '$arg_name' to be a scalar boolean 0 or 1"
        if ref($value);
    confess "FSM::Pipeline::HDLGenerator expects '$arg_name' to be a scalar boolean 0 or 1"
        unless $value =~ /\A\s*[01]\s*\z/;

    return int($value);
}
sub _debug_level_constructor_arg ($value) {
    return 0 unless defined $value;
    confess "FSM::Pipeline::HDLGenerator expects 'debug_level' to be a scalar integer in the range 0..4"
        if ref($value);
    confess "FSM::Pipeline::HDLGenerator expects 'debug_level' to be a scalar integer in the range 0..4"
        unless $value =~ /\A\s*\d+\s*\z/;

    my $debug_level = int($value);
    confess "FSM::Pipeline::HDLGenerator expects 'debug_level' to be a scalar integer in the range 0..4"
        if $debug_level < 0 || $debug_level > 4;

    return $debug_level;
}
sub _legacy_debug_constructor_arg ($value) {
    return undef unless defined $value;
    return _boolean_constructor_arg('debug', $value) ? 1 : 0;
}
sub _target_language_constructor_arg ($value) {
    return 'systemverilog' unless defined $value;
    confess "FSM::Pipeline::HDLGenerator expects 'target_language' to be a scalar string"
        if ref($value);

    my %valid = map { $_ => 1 } qw(systemverilog sv verilog v vhdl);
    return $value if $valid{$value};

    confess "FSM::Pipeline::HDLGenerator expects 'target_language' to be one of: systemverilog, sv, verilog, v, vhdl";
}

sub generate_hdl_from_file ($self, @generation_args) {
    my $pipeline = _generation_receiver_arg($self);
    my $generation_source_path = _generation_arg_list(@generation_args);
    return with_fsm_debug_state(
        { debug_level => ($pipeline->{debug_level} // 0) },
        sub {
            return _generate_hdl_from_ppif_file($pipeline, $generation_source_path)
                if $generation_source_path =~ /\.ppif\z/i;
            return _generate_hdl_from_isf_file($pipeline, $generation_source_path)
                if $generation_source_path =~ /\.isf\z/i;
            return FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
                pipeline => $pipeline,
                fsm_file => $generation_source_path,
            );
        },
    );
}
sub _generation_receiver_arg ($value) {
    my $receiver_error = "FSM::Pipeline::HDLGenerator expects generate_hdl_from_file(...) invocant to be a blessed FSM::Pipeline::HDLGenerator object constructed by new(...) with valid facade state";
    confess $receiver_error
        unless blessed($value) && blessed($value) eq __PACKAGE__ && (reftype($value) || '') eq 'HASH';
    confess $receiver_error
        unless defined($value->{__fsmgen_hdl_generator_facade_instance})
            && !ref($value->{__fsmgen_hdl_generator_facade_instance})
            && $value->{__fsmgen_hdl_generator_facade_instance} eq '1';
    confess $receiver_error
        unless _generation_receiver_state_is_valid($value);

    return $value;
}
sub _generation_receiver_state_is_valid ($value) {
    return 0 unless _debug_level_state_value($value->{debug_level});
    return 0 unless _target_language_state_value($value->{target_language});
    return 0 unless _boolean_state_value($value->{quiet});
    return 0 unless _boolean_state_value($value->{strict_mode});
    return 0 unless _blessed_object_with_methods(
        $value->{source_path_resolver},
        qw(normalized_search_paths),
    );
    return 0 unless _blessed_object_with_methods(
        $value->{rtl_interface_loader},
        qw(load_interface),
    );
    return 0 unless _blessed_object_with_methods(
        $value->{extension_loader},
        qw(module_names_from_config_files load_modules),
    );
    return 0 unless _blessed_object_with_methods(
        $value->{extension_registry},
        qw(after_parse_source after_generate_result),
    );

    return 1;
}
sub _debug_level_state_value ($value) {
    return defined($value) && !ref($value) && $value =~ /\A[0-4]\z/;
}
sub _target_language_state_value ($value) {
    return 0 unless defined($value) && !ref($value);
    my %valid = map { $_ => 1 } qw(systemverilog sv verilog v vhdl);
    return $valid{$value} ? 1 : 0;
}
sub _boolean_state_value ($value) {
    return defined($value) && !ref($value) && $value =~ /\A[01]\z/;
}
sub _blessed_object_with_methods ($value, @methods) {
    return 0 unless blessed($value);
    for my $method (@methods) {
        return 0 unless UNIVERSAL::can($value, $method);
    }

    return 1;
}
sub _generation_arg_list (@generation_args) {
    confess "FSM::Pipeline::HDLGenerator expects generate_hdl_from_file(...) arguments after the object invocant to contain exactly one source-path argument"
        unless @generation_args == 1;

    return _generation_source_path_arg($generation_args[0]);
}
sub _generation_source_path_arg ($value) {
    confess "FSM::Pipeline::HDLGenerator expects generate_hdl_from_file(...) argument to be a scalar filesystem path to a supported .fsm, .isf, or .ppif source root"
        unless defined($value) && !ref($value) && length($value) && $value =~ /\.(?:fsm|isf|ppif)\z/i;

    return $value;
}
sub _generate_hdl_from_isf_file ($pipeline, $isf_path) {
    require FSM::Adapter::ISF;
    require FSM::Scheduler::ISF;

    my $adapter = FSM::Adapter::ISF->new();
    my $scheduler = FSM::Scheduler::ISF->new();
    my $actor = $adapter->parse_file($isf_path);
    my $lowered = $scheduler->lower($actor);
    my $files = $lowered->{files} || {};
    my $entry_basename = exists $files->{"$actor->{actor_name}_top.fsm"}
        ? "$actor->{actor_name}_top.fsm"
        : exists $files->{"$actor->{actor_name}.fsm"}
            ? "$actor->{actor_name}.fsm"
            : undef;

    confess "ISF lowering emitted no generated .fsm HDL entry artifact\n"
        unless defined($entry_basename) && exists $files->{$entry_basename};

    my $entry_path = _write_generated_fsm_files($files, $entry_basename);
    my $result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline,
        fsm_file => $entry_path,
    );
    _annotate_public_source_info($result, 'isf', $isf_path, $entry_basename);
    return $result;
}
sub _generate_hdl_from_ppif_file ($pipeline, $ppif_path) {
    require FSM::Adapter::IAL2::PPIF;

    my $ppif_result = FSM::Adapter::IAL2::PPIF->new()->parse_file($ppif_path);
    my $files = $ppif_result->{generated_ial0}{files} || {};
    my $entry_basename;

    if (($ppif_result->{kind} // '') eq 'protocol_intent.valid_ready_bundle') {
        $entry_basename = $ppif_result->{report}{generated_artifacts}{hdl_entry}{entry_artifact};
    }
    else {
        my $artifact_files = $ppif_result->{report}{generated_artifacts}{ial0}{files} || [];
        $entry_basename = $artifact_files->[0];
    }

    confess "PPIF lowering emitted no generated .fsm HDL entry artifact\n"
        unless defined($entry_basename) && exists $files->{$entry_basename};

    my $entry_path = _write_generated_fsm_files($files, $entry_basename);
    my $result = FSM::Pipeline::SourceGenerationOrchestrator->generate_from_file(
        pipeline => $pipeline,
        fsm_file => $entry_path,
    );
    _annotate_public_source_info($result, 'ppif', $ppif_path, $entry_basename);
    $result->{protocol_intent_report} = $ppif_result->{report};
    return $result;
}
sub _write_generated_fsm_files ($files, $entry_basename) {
    my $dir = tempdir(CLEANUP => 1);
    for my $name (sort keys %$files) {
        my $path = File::Spec->catfile($dir, $name);
        open my $fh, '>', $path or confess "Cannot write generated temporary .fsm artifact '$path': $!";
        print {$fh} $files->{$name};
        close $fh or confess "Cannot close generated temporary .fsm artifact '$path': $!";
    }

    return File::Spec->catfile($dir, $entry_basename);
}
sub _annotate_public_source_info ($result, $kind, $source_path, $entry_artifact) {
    $result->{source_info} ||= {};
    $result->{source_info}{kind} = $kind;
    $result->{source_info}{public_source_path} = $source_path;
    $result->{source_info}{generated_hdl_entry_artifact} = $entry_artifact;
    return $result;
}

1;

__END__

=head1 METHODS

=head2 new(%args)

Creates a new HDL generation pipeline.

Arguments:
- debug_level: Debug verbosity level (0-4, default: 0)
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
